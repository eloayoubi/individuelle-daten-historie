import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../../../core/models/tracking.dart';
import '../../../core/utils/cost_engine.dart';

/// Kosten einer Kategorie im gewählten Jahr gegen das Vorjahr.
class YearComparison extends Equatable {
  const YearComparison({required this.category, required this.total, required this.previous, double? sameTotal, double? samePrevious})
    : sameTotal = sameTotal ?? total,
      samePrevious = samePrevious ?? previous;

  final Category category;

  /// Ganzes Jahr – im laufenden Jahr bis Dezember hochgerechnet.
  final double total;
  final double previous;

  /// Nur Tracker, die das ganze Vorjahr erfasst waren: Wer unterjährig angefangen hat, würde
  /// sonst ein volles Jahr mit ein paar Monaten vergleichen.
  final double sameTotal;
  final double samePrevious;

  double? get change => _change(sameTotal, samePrevious);

  @override
  List<Object?> get props => [category, total, previous, sameTotal, samePrevious];
}

double? _change(double now, double before) => before.abs() < 0.01 ? null : (now - before) / before;

/// Verbrauch eines Zählers im gewählten Jahr gegen denselben Zeitraum im Vorjahr.
class ConsumptionComparison extends Equatable {
  const ConsumptionComparison({required this.category, required this.tracker, required this.value, required this.previous, required this.unit});

  final Category category;
  final Tracker tracker;
  final double value;
  final double previous;
  final String unit;

  double? get change => previous.abs() < 0.01 ? null : (value - previous) / previous;

  @override
  List<Object?> get props => [category, tracker, value, previous, unit];
}

/// Prognose einer Kategorie mit Spanne.
class CategoryForecast extends Equatable {
  const CategoryForecast({required this.category, required this.total, required this.range});

  final Category category;
  final double total;
  final double range;

  @override
  List<Object?> get props => [category, total, range];
}

/// Ein Zähler, dessen Verbrauch sich gegenüber dem Vorjahr merklich ändert und so in die Prognose einfließt.
class TrendNote extends Equatable {
  const TrendNote({required this.category, required this.tracker, required this.trend});

  final Category category;
  final Tracker tracker;

  /// Verhältnis zum Vorjahr (0,95 = 5 % weniger).
  final double trend;

  @override
  List<Object?> get props => [category, tracker, trend];
}

/// Abschlags-Check: gezahlte Abschläge im Jahr gegen die gerechneten Kosten.
class InstalmentCheck extends Equatable {
  const InstalmentCheck({required this.category, required this.tracker, required this.paid, required this.cost, required this.monthly});

  final Category category;
  final Tracker tracker;
  final double paid;
  final double cost;

  /// Aktueller Abschlag je Monat.
  final double monthly;

  /// Positiv = Guthaben, negativ = Nachzahlung.
  double get balance => paid - cost;

  /// Abschlag, der die Kosten genau deckt (auf ganze Euro aufgerundet).
  double get suggestedMonthly => (cost / 12).ceilToDouble();

  @override
  List<Object?> get props => [category, tracker, paid, cost, monthly];
}

/// Kosten eines Trackers, die in einer anderen Kategorie stecken.
class IncludedNote extends Equatable {
  const IncludedNote({required this.tracker, required this.category, required this.into, required this.cost});

  final Tracker tracker;
  final Category category;
  final Category into;
  final double cost;

  @override
  List<Object?> get props => [tracker, category, into, cost];
}

/// Alles für den Auswertungs-Tab eines Jahres – aus den Rohdaten mit der [CostEngine].
class Insights extends Equatable {
  const Insights({
    required this.year,
    required this.today,
    required this.months,
    this.firstMonth = 0,
    required this.total,
    required this.previousTotal,
    required this.comparisons,
    required this.consumption,
    required this.instalments,
    required this.included,
    this.forecast,
    this.forecastRange = 0,
    this.forecastParts = const CostParts(),
    this.categoryForecasts = const [],
    this.trends = const [],
  });

  final int year;
  final DateTime today;

  /// Je Monat: Kosten je Kategorie-Id.
  final List<Map<String, double>> months;

  /// Erster Monat (0 = Januar) mit Daten, wenn erst in diesem Jahr angefangen; davor keine Balken.
  final int firstMonth;
  final double total;
  final double previousTotal;
  final List<YearComparison> comparisons;
  final List<ConsumptionComparison> consumption;
  final List<InstalmentCheck> instalments;
  final List<IncludedNote> included;

  /// Prognose fürs nächste Jahr – nur, wenn das laufende Jahr gewählt ist.
  final double? forecast;
  final double forecastRange;
  final CostParts forecastParts;
  final List<CategoryForecast> categoryForecasts;
  final List<TrendNote> trends;

  bool get isCurrentYear => year == today.year;

  bool get isEmpty => comparisons.isEmpty;

  double? get change => _change(
    comparisons.fold(0.0, (sum, c) => sum + c.sameTotal),
    comparisons.fold(0.0, (sum, c) => sum + c.samePrevious),
  );

  /// Monate nach dem laufenden sind hochgerechnet.
  bool isProjected(int monthIndex) => isCurrentYear && monthIndex + 1 > today.month;

  double monthTotal(int monthIndex) => months[monthIndex].values.fold(0.0, (a, b) => a + b);

  static int _firstMonth(List<Category> categories, int year) {
    DateTime? first;
    for (final c in categories) {
      for (final t in c.trackers) {
        for (final e in t.entries) {
          final d = e.hasPeriod ? e.periodStart! : e.date;
          if (first == null || d.isBefore(first)) first = d;
        }
      }
    }
    return first == null || first.year != year ? 0 : first.month - 1;
  }

  /// Hat [tracker] einen Eintrag am oder vor [start]?
  static bool _trackedSince(Tracker tracker, DateTime start) =>
      tracker.entries.any((e) => !CostEngine.day(e.hasPeriod ? e.periodStart! : e.date).isAfter(start));

  /// Jahre mit Daten (älteste zuerst), höchstens die letzten drei.
  static List<int> yearsOf(List<Category> categories, DateTime now) {
    var first = now.year;
    for (final c in categories) {
      for (final t in c.trackers) {
        for (final e in t.entries) {
          if (e.date.year < first) first = e.date.year;
        }
      }
    }
    return [for (var y = math.max(first, now.year - 2); y <= now.year; y++) y];
  }

  factory Insights.build(List<Category> categories, DateTime now, int year) {
    final today = CostEngine.day(now);
    final current = year == today.year;
    final tomorrow = today.add(const Duration(days: 1));
    final yearStart = DateTime.utc(year);
    // Verbrauch im laufenden Jahr nur bis heute vergleichen, sonst ganze Jahre.
    final usageEnd = current ? tomorrow : DateTime.utc(year + 1);
    final previousUsageEnd = current ? DateTime.utc(year - 1, today.month, today.day + 1) : DateTime.utc(year);
    final byId = {for (final c in categories) c.id: c};

    final months = List.generate(12, (_) => <String, double>{});
    final comparisons = <YearComparison>[];
    final consumption = <ConsumptionComparison>[];
    final instalments = <InstalmentCheck>[];
    final included = <IncludedNote>[];
    final categoryForecasts = <CategoryForecast>[];
    final trends = <TrendNote>[];
    var forecastParts = const CostParts();
    var rangeSquares = 0.0;

    for (final category in categories) {
      var total = 0.0, previous = 0.0, forecast = 0.0, categoryRange = 0.0, sameTotal = 0.0, samePrevious = 0.0;
      for (final tracker in category.trackers) {
        final engine = CostEngine(tracker, today: today);
        final into = tracker.includedIn == null ? null : byId[tracker.includedIn];
        if (tracker.includedIn != null) {
          if (into != null) included.add(IncludedNote(tracker: tracker, category: category, into: into, cost: engine.costInYear(year)));
        } else {
          var trackerTotal = 0.0;
          for (var m = 1; m <= 12; m++) {
            final v = engine.costInMonth(year, m);
            months[m - 1][category.id] = (months[m - 1][category.id] ?? 0) + v;
            trackerTotal += v;
          }
          final trackerPrevious = engine.costInYear(year - 1);
          total += trackerTotal;
          previous += trackerPrevious;
          if (_trackedSince(tracker, DateTime.utc(year - 1))) {
            sameTotal += trackerTotal;
            samePrevious += trackerPrevious;
          }
          if (current) {
            final parts = engine.parts(DateTime.utc(year + 1), DateTime.utc(year + 2));
            final range = engine.uncertainty(parts);
            forecastParts += parts;
            forecast += parts.total;
            categoryRange += range * range;
            rangeSquares += range * range;
          }
        }
        final meter = tracker.firstWithRole(FieldRole.meterReading);
        if (meter != null && engine.hasMeter) {
          consumption.add(
            ConsumptionComparison(
              category: category,
              tracker: tracker,
              value: engine.consumption(yearStart, usageEnd),
              previous: engine.consumption(DateTime.utc(year - 1), previousUsageEnd),
              unit: meter.usageUnit,
            ),
          );
          // Nur Zähler, deren Kosten hier zählen, prägen die Prognose.
          if (engine.trend case final double trend when current && tracker.includedIn == null && (trend - 1).abs() >= 0.02) {
            trends.add(TrendNote(category: category, tracker: tracker, trend: trend));
          }
        }
        if (engine.hasInstalment) {
          final cost = engine.costInYear(year);
          final paid = engine.paid(yearStart, DateTime.utc(year + 1));
          if (paid > 0) instalments.add(InstalmentCheck(category: category, tracker: tracker, paid: paid, cost: cost, monthly: paid / 12));
        }
      }
      if (total.abs() > 0.004 || previous.abs() > 0.004) {
        comparisons.add(YearComparison(category: category, total: total, previous: previous, sameTotal: sameTotal, samePrevious: samePrevious));
      }
      if (current && forecast.abs() > 0.004) categoryForecasts.add(CategoryForecast(category: category, total: forecast, range: math.sqrt(categoryRange)));
    }

    comparisons.sort((a, b) => b.total.compareTo(a.total));
    categoryForecasts.sort((a, b) => b.total.compareTo(a.total));
    return Insights(
      year: year,
      today: today,
      months: months,
      firstMonth: _firstMonth(categories, year),
      total: comparisons.fold(0.0, (sum, c) => sum + c.total),
      previousTotal: comparisons.fold(0.0, (sum, c) => sum + c.previous),
      comparisons: comparisons,
      consumption: consumption,
      instalments: instalments,
      included: included,
      forecast: current ? forecastParts.total : null,
      forecastRange: math.sqrt(rangeSquares),
      forecastParts: forecastParts,
      categoryForecasts: categoryForecasts,
      trends: trends,
    );
  }

  @override
  List<Object?> get props => [year, today, months, total, previousTotal, comparisons, consumption, instalments, included, forecast, forecastRange, categoryForecasts, trends];
}
