import 'package:equatable/equatable.dart';

import '../../../core/utils/cost_engine.dart';
import '../../categories/data/categories_repository.dart';

/// Kennzahlen einer Kategorie für die Übersicht.
class CategorySummary extends Equatable {
  const CategorySummary({
    required this.category,
    required this.costToDate,
    required this.costChange,
    required this.monthlyAverage,
    this.usage,
    this.usageUnit = '',
  });

  final Category category;

  /// Kosten seit 1. Januar bis heute.
  final double costToDate;

  /// Veränderung gegenüber dem gleichen Zeitraum im Vorjahr (0.05 = +5 %), `null` ohne Vorjahr.
  final double? costChange;
  final double monthlyAverage;

  /// Verbrauch seit 1. Januar (erster Zähler der Kategorie), `null` ohne Zähler.
  final double? usage;
  final String usageUnit;

  @override
  List<Object?> get props => [category, costToDate, costChange, monthlyAverage, usage, usageUnit];
}

enum ReminderKind { readMeter, deadline }

/// Ein Hinweis unter „Als Nächstes“: Zähler ablesen oder ein Stichtag rückt näher.
class Reminder extends Equatable {
  const Reminder({required this.kind, required this.category, required this.trackerId, required this.trackerName, required this.days, this.fieldName, this.date});

  final ReminderKind kind;
  final Category category;
  final String trackerId;
  final String trackerName;
  final String? fieldName;

  /// Seit dem letzten Stand ([ReminderKind.readMeter]) bzw. bis zum Stichtag ([ReminderKind.deadline]).
  final int days;
  final DateTime? date;

  @override
  List<Object?> get props => [kind, category, trackerId, trackerName, fieldName, days, date];
}

/// Alles, was die Übersicht zeigt – aus den Rohdaten mit der [CostEngine] gerechnet.
class HomeOverview extends Equatable {
  const HomeOverview({
    required this.today,
    required this.costToDate,
    required this.costChange,
    required this.forecast,
    required this.forecastChange,
    required this.monthsThisYear,
    required this.monthsNextYear,
    required this.categories,
    required this.reminders,
  });

  /// Ab so vielen Tagen ohne Stand erinnert die Übersicht ans Ablesen.
  static const readMeterAfterDays = 30;

  /// So weit im Voraus erscheinen Stichtage.
  static const deadlineHorizonDays = 180;

  final DateTime today;
  final double costToDate;
  final double? costChange;

  /// Hochrechnung für das kommende Kalenderjahr.
  final double forecast;

  /// Prognose gegenüber dem laufenden Jahr (Ist bis heute plus Hochrechnung bis Dezember).
  final double? forecastChange;

  /// Kosten je Monat (Januar bis Dezember): laufendes Jahr und Prognose fürs nächste.
  final List<double> monthsThisYear;
  final List<double> monthsNextYear;

  /// Nach Kosten seit Januar absteigend.
  final List<CategorySummary> categories;
  final List<Reminder> reminders;

  int get year => today.year;

  bool get isEmpty => categories.isEmpty;

  factory HomeOverview.build(List<Category> categories, DateTime now) {
    final today = CostEngine.day(now);
    final year = today.year;
    final yearStart = DateTime.utc(year);
    final lastYearStart = DateTime.utc(year - 1);
    final lastYearToday = DateTime.utc(year - 1, today.month, today.day);
    // Heute zählt mit: [Jahresbeginn, morgen).
    final tomorrow = today.add(const Duration(days: 1));
    final lastYearTomorrow = lastYearToday.add(const Duration(days: 1));

    final summaries = <CategorySummary>[];
    final reminders = <Reminder>[];
    final thisYear = List.filled(12, 0.0);
    final nextYear = List.filled(12, 0.0);
    var currentYearTotal = 0.0;
    var lastYearToDate = 0.0;

    for (final category in categories) {
      var costToDate = 0.0, previous = 0.0;
      double? usage;
      var usageUnit = '';
      for (final tracker in category.trackers) {
        final engine = CostEngine(tracker, today: today);
        costToDate += engine.cost(yearStart, tomorrow);
        previous += engine.cost(lastYearStart, lastYearTomorrow);
        currentYearTotal += engine.costInYear(year);
        for (var m = 1; m <= 12; m++) {
          thisYear[m - 1] += engine.costInMonth(year, m);
          nextYear[m - 1] += engine.costInMonth(year + 1, m);
        }
        final meter = tracker.firstWithRole(FieldRole.meterReading);
        if (meter != null && engine.hasMeter) {
          if (usage == null) {
            usage = engine.consumption(yearStart, tomorrow);
            usageUnit = meter.usageUnit;
          }
          final since = today.difference(engine.lastReading!).inDays;
          if (since >= readMeterAfterDays) {
            reminders.add(Reminder(kind: ReminderKind.readMeter, category: category, trackerId: tracker.id, trackerName: tracker.name, days: since));
          }
        }
        for (final field in tracker.withRole(FieldRole.deadline)) {
          final due = _latestDate(tracker, field.id);
          if (due == null) continue;
          final days = CostEngine.day(due).difference(today).inDays;
          if (days >= 0 && days <= deadlineHorizonDays) {
            reminders.add(Reminder(kind: ReminderKind.deadline, category: category, trackerId: tracker.id, trackerName: tracker.name, fieldName: field.name, days: days, date: due));
          }
        }
      }
      lastYearToDate += previous;
      summaries.add(
        CategorySummary(
          category: category,
          costToDate: costToDate,
          costChange: _ratio(costToDate, previous),
          monthlyAverage: costToDate / (today.month - 1 + today.day / _daysInMonth(today)),
          usage: usage,
          usageUnit: usageUnit,
        ),
      );
    }

    summaries.sort((a, b) => b.costToDate.compareTo(a.costToDate));
    // Stichtage nach Nähe, danach überfällige Zähler nach Dauer.
    reminders.sort((a, b) {
      if (a.kind != b.kind) return a.kind == ReminderKind.deadline ? -1 : 1;
      return a.kind == ReminderKind.deadline ? a.days.compareTo(b.days) : b.days.compareTo(a.days);
    });

    final costToDate = summaries.fold(0.0, (sum, s) => sum + s.costToDate);
    final forecast = nextYear.fold(0.0, (a, b) => a + b);
    return HomeOverview(
      today: today,
      costToDate: costToDate,
      costChange: _ratio(costToDate, lastYearToDate),
      forecast: forecast,
      forecastChange: _ratio(forecast, currentYearTotal),
      monthsThisYear: thisYear,
      monthsNextYear: nextYear,
      categories: summaries,
      reminders: reminders,
    );
  }

  static double? _ratio(double now, double before) => before.abs() < 0.01 ? null : (now - before) / before;

  static int _daysInMonth(DateTime d) => DateTime.utc(d.year, d.month + 1, 0).day;

  static DateTime? _latestDate(Tracker tracker, String fieldId) {
    DateTime? latest;
    DateTime? entryDate;
    for (final e in tracker.entries) {
      final value = e.dateValue(fieldId);
      if (value != null && (entryDate == null || e.date.isAfter(entryDate))) {
        latest = value;
        entryDate = e.date;
      }
    }
    return latest;
  }

  @override
  List<Object?> get props => [today, costToDate, costChange, forecast, forecastChange, monthsThisYear, monthsNextYear, categories, reminders];
}
