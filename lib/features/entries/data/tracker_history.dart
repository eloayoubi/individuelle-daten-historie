import 'package:equatable/equatable.dart';

import '../../../core/models/tracking.dart';
import '../../../core/utils/cost_engine.dart';

/// Was der Verlauf zeigt: Kosten oder Verbrauch (Zählerstand).
enum HistoryMetric { cost, consumption }

class HistoryMonth extends Equatable {
  const HistoryMonth({required this.month, required this.value, this.previousYear});

  /// Erster Tag des Monats (UTC).
  final DateTime month;

  /// Bis heute, der laufende Monat also nur zum Teil.
  final double value;

  /// Derselbe Monat ein Jahr früher, `null` ohne Daten.
  final double? previousYear;

  @override
  List<Object?> get props => [month, value, previousYear];
}

/// Der aktuell gültige Wert eines Felds, dazu eine schon eingetragene künftige Änderung.
class CurrentValue extends Equatable {
  const CurrentValue({required this.field, required this.value, required this.since, this.upcoming, this.upcomingFrom});

  final FieldDefinition field;
  final Object value;
  final DateTime since;
  final Object? upcoming;
  final DateTime? upcomingFrom;

  @override
  List<Object?> get props => [field, value, since, upcoming, upcomingFrom];
}

/// Verlauf eines Trackers: zwölf Monate, Jahresvergleich, Prognose und aktuelle Werte.
class TrackerHistory extends Equatable {
  const TrackerHistory({
    required this.metric,
    required this.unit,
    required this.months,
    required this.thisYear,
    required this.lastYearToDate,
    required this.forecastNextYear,
    required this.currentValues,
  });

  final HistoryMetric metric;

  /// Einheit des Verbrauchs (z. B. `kWh`); leer bei Kosten (Euro).
  final String unit;
  final List<HistoryMonth> months;
  final double thisYear;
  final double? lastYearToDate;
  final double forecastNextYear;
  final List<CurrentValue> currentValues;

  bool get hasData => months.any((m) => m.value.abs() > 0.004);

  /// Welche Kennzahlen der Tracker hergibt – Kosten zuerst.
  static List<HistoryMetric> metricsFor(Tracker tracker) {
    final meter = tracker.firstWithRole(FieldRole.meterReading);
    final readings = meter == null ? 0 : tracker.entries.where((e) => e.values.containsKey(meter.id)).length;
    final costs = tracker.fields.any((f) => f.role == FieldRole.recurringCost || f.role == FieldRole.oneOffCost) ||
        (readings >= 2 && tracker.fields.any((f) => f.role == FieldRole.unitPrice));
    return [if (costs) HistoryMetric.cost, if (readings >= 2) HistoryMetric.consumption];
  }

  factory TrackerHistory.build(Tracker tracker, DateTime now, HistoryMetric metric) {
    final today = CostEngine.day(now);
    final tomorrow = today.add(const Duration(days: 1));
    final engine = CostEngine(tracker, today: today);
    double sum(DateTime from, DateTime to) => metric == HistoryMetric.cost ? engine.cost(from, to) : engine.consumption(from, to);

    final months = <HistoryMonth>[];
    for (var i = 11; i >= 0; i--) {
      final start = DateTime.utc(today.year, today.month - i);
      final next = DateTime.utc(start.year, start.month + 1);
      final previous = sum(DateTime.utc(start.year - 1, start.month), DateTime.utc(next.year - 1, next.month));
      months.add(HistoryMonth(month: start, value: sum(start, next.isAfter(tomorrow) ? tomorrow : next), previousYear: previous.abs() > 0.004 ? previous : null));
    }
    final lastYear = sum(DateTime.utc(today.year - 1), DateTime.utc(today.year - 1, today.month, today.day + 1));
    return TrackerHistory(
      metric: metric,
      unit: metric == HistoryMetric.consumption ? tracker.firstWithRole(FieldRole.meterReading)?.usageUnit ?? '' : '',
      months: months,
      thisYear: sum(DateTime.utc(today.year), tomorrow),
      lastYearToDate: lastYear.abs() > 0.004 ? lastYear : null,
      forecastNextYear: sum(DateTime.utc(today.year + 1), DateTime.utc(today.year + 2)),
      currentValues: currentValuesOf(tracker, today),
    );
  }

  /// Letzter Wert je Feld bis heute; bei Preisen und Beträgen auch eine schon eingetragene Änderung.
  static List<CurrentValue> currentValuesOf(Tracker tracker, DateTime today) {
    final sorted = [...tracker.entries]..sort((a, b) => a.date.compareTo(b.date));
    return [
      for (final field in tracker.fields)
        if (field.kind != FieldKind.formula)
          if (_current(sorted, field, today) case final CurrentValue value) value,
    ];
  }

  static CurrentValue? _current(List<Entry> sorted, FieldDefinition field, DateTime today) {
    Entry? current;
    Entry? upcoming;
    for (final e in sorted) {
      if (!e.values.containsKey(field.id)) continue;
      if (e.date.isAfter(today)) {
        upcoming ??= e;
      } else {
        current = e;
      }
    }
    final base = current ?? upcoming;
    if (base == null) return null;
    final showUpcoming = current != null && upcoming != null && (field.role == FieldRole.unitPrice || field.role == FieldRole.recurringCost);
    return CurrentValue(
      field: field,
      value: base.values[field.id]!,
      since: base.date,
      upcoming: showUpcoming ? upcoming.values[field.id] : null,
      upcomingFrom: showUpcoming ? upcoming.date : null,
    );
  }

  @override
  List<Object?> get props => [metric, unit, months, thisYear, lastYearToDate, forecastNextYear, currentValues];
}
