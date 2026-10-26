import 'package:equatable/equatable.dart';

import '../models/tracking.dart';
import 'cost_engine.dart';
import 'formulas.dart';

/// Zeitraum der Kennzahlen; „bis heute“, wo er noch läuft.
enum DashboardPeriod { thisMonth, lastMonth, thisYear, lastYear, last12Months, all, custom }

/// Tage in `[from, to)`, jeweils UTC-Mitternacht.
class DateSpan extends Equatable {
  DateSpan(DateTime from, DateTime to) : from = CostEngine.day(from), to = CostEngine.day(to);

  final DateTime from;
  final DateTime to;

  int get days => to.difference(from).inDays;

  /// Letzter enthaltener Tag (für die Anzeige).
  DateTime get last => to.subtract(const Duration(days: 1));

  @override
  List<Object?> get props => [from, to];
}

/// Eine ausgerechnete Kennzahl: Wert im Zeitraum und im Zeitraum davor (zum Vergleich).
class DashboardFigure extends Equatable {
  const DashboardFigure({required this.metric, this.tracker, this.field, this.summary, this.value, this.previous, this.meterCount = 0});

  final DashboardMetric metric;

  /// Tracker der Kennzahl; `null` bei den Kosten der ganzen Kategorie und mehreren Zählern.
  final Tracker? tracker;

  /// Feld der Kennzahl; bei mehreren Zählern der erste (für die Einheit).
  final FieldDefinition? field;
  final FieldSummary? summary;

  /// `null`, wenn es im Zeitraum nichts zusammenzufassen gibt.
  final double? value;
  final double? previous;

  /// Bei mehreren Zählern: wie viele zusammengezählt sind.
  final int meterCount;

  /// Verbrauch aus Zählerständen (Differenz eines Zählerstands) – in der Verbrauchseinheit.
  bool get isConsumption => field?.role == FieldRole.meterReading && summary == FieldSummary.difference;

  /// Veränderung zum Zeitraum davor als Anteil; `null` ohne Vergleich.
  double? get change {
    final v = value, p = previous;
    if (v == null || p == null || p.abs() < 1e-9) return null;
    return (v - p) / p.abs();
  }

  @override
  List<Object?> get props => [metric, tracker?.id, field, summary, value, previous, meterCount];
}

/// Kennzahlen im Dashboard einer Kategorie: welche es gibt, welche gezeigt werden und ihre Werte.
///
/// - **Kosten** rechnet die [CostEngine] wie überall in der App; die der ganzen Kategorie lassen
///   Tracker aus, deren Kosten schon in einer anderen (aktiven) Kategorie stecken.
/// - **Felder** fassen ihre Werte nach [FieldDefinition.effectiveSummary] zusammen:
///   - `sum` addiert die Werte im Zeitraum; wiederkehrende Beträge und Abschläge zählen je
///     Monatserstem im Zeitraum voll (12 €/Monat vom 1. bis 15. Juni = 12 €, vom 16. Juni bis
///     15. Juli = 12 € für Juli).
///   - `difference` ist neuer minus alter Wert: Wert am Ende minus Wert am Anfang, zwischen zwei
///     Einträgen linear verteilt, vor dem ersten und nach dem letzten gilt der nächste bekannte
///     Wert. Bei einem Zählerstand ist das der Verbrauch der [CostEngine] – mit Umrechnung,
///     Zählerwechsel und geschätzten Tagen seit dem letzten Ablesen.
/// - **Mehrere Zähler** zählen ihren Verbrauch zusammen: alle Zähler der Kategorie, die einer
///   Gruppe (Kaltwasser) oder eine eigene Auswahl – jeweils nur Zähler mit derselben
///   Verbrauchseinheit wie der erste.
///   - `average`, `min`, `max` über die Einträge im Zeitraum; `latest` ist der zuletzt eingetragene
///     Wert bis zum Ende des Zeitraums.
/// - Formel-Felder werden vorher je Eintrag ausgerechnet ([Formulas.apply]).
abstract final class DashboardFigures {
  /// Was sich als Kennzahl wählen lässt: Kosten der Kategorie, bei mehreren Trackern die Kosten je
  /// Tracker, bei mehreren Zählern ihr Verbrauch zusammen und je Gruppe, dazu jedes Feld mit Zahlen
  /// und Verlauf. Eigene Summen kommen aus der Wahl ([shown]).
  static List<DashboardMetric> options(Category category) {
    final meters = allMeters(category);
    return [
      if (category.trackers.isNotEmpty) const DashboardMetric.cost(),
      if (category.trackers.length > 1)
        for (final t in category.trackers)
          if (_hasCost(t)) DashboardMetric.cost(trackerId: t.id),
      if (meters.length > 1) ...[const DashboardMetric.meters(), for (final g in groups(category)) DashboardMetric.meters(group: g)],
      for (final t in category.trackers)
        for (final f in t.fields)
          if (f.effectiveSummary != null) DashboardMetric.field(trackerId: t.id, fieldId: f.id),
    ];
  }

  /// Gezeigte Kennzahlen: die gewählten, soweit es Tracker, Feld bzw. Zähler noch gibt. Ohne Wahl
  /// die Kosten (wenn etwas kostet) und der Verbrauch:
  /// - mit Gruppen je Gruppe eine Karte (Kaltwasser, Warmwasser), Zähler ohne Gruppe einzeln;
  /// - mehrere Zähler eines Trackers ohne Gruppen zusammen;
  /// - sonst je Zähler, ohne Zähler das erste Feld je Tracker.
  static List<DashboardMetric> shown(Category category) {
    final available = options(category).toSet();
    if (category.dashboard.metrics case final chosen?) {
      return [
        for (final m in chosen)
          if (m.isCustom ? metersOf(category, m).isNotEmpty : available.contains(m)) m,
      ];
    }
    final meters = allMeters(category);
    final groups = DashboardFigures.groups(category);
    final List<DashboardMetric> usage;
    if (groups.isNotEmpty) {
      usage = [
        for (final g in groups) DashboardMetric.meters(group: g),
        for (final (t, f) in meters)
          if (f.meterGroup == null) DashboardMetric.field(trackerId: t.id, fieldId: f.id),
      ];
    } else if (meters.length > 1 && meters.every((m) => m.$1.id == meters.first.$1.id) && metersOf(category, const DashboardMetric.meters()).length == meters.length) {
      usage = [const DashboardMetric.meters()];
    } else if (meters.isNotEmpty) {
      usage = [for (final (t, f) in meters) DashboardMetric.field(trackerId: t.id, fieldId: f.id)];
    } else {
      usage = [
        for (final t in category.trackers)
          if (t.fields.where((f) => f.effectiveSummary != null).firstOrNull case final f?) DashboardMetric.field(trackerId: t.id, fieldId: f.id),
      ];
    }
    return [if (category.trackers.any(_hasCost)) const DashboardMetric.cost(), ...usage];
  }

  /// Alle Zähler der Kategorie mit ihrem Tracker, in Reihenfolge.
  static List<(Tracker, FieldDefinition)> allMeters(Category category) => [
    for (final t in category.trackers)
      for (final f in t.meters) (t, f),
  ];

  /// Gruppen der Zähler (Kaltwasser, Warmwasser) in der Reihenfolge ihres ersten Zählers.
  static List<String> groups(Category category) => {
    for (final (_, f) in allMeters(category))
      if (f.meterGroup case final String g) g,
  }.toList();

  /// Zähler einer Kennzahl über mehrere Zähler – nur die mit der Verbrauchseinheit des ersten.
  static List<(Tracker, FieldDefinition)> metersOf(Category category, DashboardMetric metric) {
    if (!metric.isMeters) return const [];
    final ids = metric.fieldIds?.toSet();
    final chosen = [
      for (final m in allMeters(category))
        if (ids != null ? ids.contains(m.$2.id) : metric.group == null || m.$2.meterGroup == metric.group) m,
    ];
    if (chosen.isEmpty) return const [];
    final unit = chosen.first.$2.usageUnit;
    return [
      for (final m in chosen)
        if (m.$2.usageUnit == unit) m,
    ];
  }

  /// Werte der gezeigten Kennzahlen in [span], zum Vergleich in [previous]. [elsewhere] sind die
  /// übrigen aktiven Kategorien – Kosten, die dort stecken, zählen in der Kategorie-Summe nicht.
  static List<DashboardFigure> build(Category category, DateSpan span, {DateSpan? previous, required DateTime today, Set<String> elsewhere = const {}}) {
    final day = CostEngine.day(today);
    final engines = <String, CostEngine>{};
    final applied = <String, Tracker>{};
    CostEngine engine(Tracker t) => engines[t.id] ??= CostEngine(t, today: day);
    Tracker withFormulas(Tracker t) => applied[t.id] ??= Formulas.apply(t);
    return [
      for (final metric in shown(category))
        if (metric.isCost)
          _cost(category, metric, span, previous, engine, elsewhere)
        else if (metric.isMeters)
          _meters(category, metric, span, previous, engine)
        else if (category.trackers.where((t) => t.id == metric.trackerId).firstOrNull case final tracker?)
          if (tracker.fields.where((f) => f.id == metric.fieldId).firstOrNull case final field?)
            DashboardFigure(
              metric: metric,
              tracker: tracker,
              field: field,
              summary: field.effectiveSummary,
              value: fieldValue(withFormulas(tracker), field, span, engine: engine(tracker)),
              previous: previous == null ? null : fieldValue(withFormulas(tracker), field, previous, engine: engine(tracker)),
            ),
    ];
  }

  static DashboardFigure _cost(
    Category category,
    DashboardMetric metric,
    DateSpan span,
    DateSpan? previous,
    CostEngine Function(Tracker) engine,
    Set<String> elsewhere,
  ) {
    final tracker = metric.trackerId == null ? null : category.trackers.where((t) => t.id == metric.trackerId).firstOrNull;
    final trackers = tracker != null
        ? [tracker]
        : [
            for (final t in category.trackers)
              if (t.includedIn == null || t.includedIn == category.id || !elsewhere.contains(t.includedIn)) t,
          ];
    double sum(DateSpan s) => trackers.fold(0.0, (total, t) => total + engine(t).cost(s.from, s.to));
    return DashboardFigure(metric: metric, tracker: tracker, value: sum(span), previous: previous == null ? null : sum(previous));
  }

  static DashboardFigure _meters(Category category, DashboardMetric metric, DateSpan span, DateSpan? previous, CostEngine Function(Tracker) engine) {
    final meters = metersOf(category, metric);
    final measured = [
      for (final (t, f) in meters)
        if (engine(t).measuresField(f.id)) (engine(t), f),
    ];
    double? sum(DateSpan s) => measured.isEmpty ? null : measured.fold<double>(0, (total, m) => total + m.$1.consumptionOf(m.$2.id, s.from, s.to));
    return DashboardFigure(
      metric: metric,
      field: meters.firstOrNull?.$2,
      summary: FieldSummary.difference,
      value: sum(span),
      previous: previous == null ? null : sum(previous),
      meterCount: meters.length,
    );
  }

  /// Wert eines Felds in [span] nach seiner Zusammenfassung. [tracker] mit ausgerechneten Formeln;
  /// [engine] (für den Verbrauch des Zählerstands) aus dem Tracker ohne.
  static double? fieldValue(Tracker tracker, FieldDefinition field, DateSpan span, {CostEngine? engine}) {
    final summary = field.effectiveSummary;
    if (summary == null) return null;
    final points = [
      for (final e in tracker.entries)
        if (e.number(field.id) case final num v) (CostEngine.day(e.date), v.toDouble()),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    if (points.isEmpty) return null;
    final inSpan = [
      for (final (d, v) in points)
        if (!d.isBefore(span.from) && d.isBefore(span.to)) v,
    ];
    switch (summary) {
      case FieldSummary.sum:
        if (field.role == FieldRole.recurringCost || field.role == FieldRole.instalment) return _monthly(points, field, span);
        return inSpan.fold<double>(0, (a, b) => a + b);
      case FieldSummary.difference:
        if (field.role == FieldRole.meterReading) {
          final meter = engine ?? CostEngine(tracker, today: DateTime.now());
          return meter.measuresField(field.id) ? meter.consumptionOf(field.id, span.from, span.to) : null;
        }
        return _interpolated(points, span.to) - _interpolated(points, span.from);
      case FieldSummary.average:
        return inSpan.isEmpty ? null : inSpan.fold<double>(0, (a, b) => a + b) / inSpan.length;
      case FieldSummary.latest:
        return [
          for (final (d, v) in points)
            if (d.isBefore(span.to)) v,
        ].lastOrNull;
      case FieldSummary.min:
        return inSpan.isEmpty ? null : inSpan.reduce((a, b) => a < b ? a : b);
      case FieldSummary.max:
        return inSpan.isEmpty ? null : inSpan.reduce((a, b) => a > b ? a : b);
    }
  }

  /// Zeitraum zu [period] mit [today] als letztem Tag laufender Zeiträume. [custom] ist der gewählte
  /// Zeitraum, [firstDay] der Beginn von „Gesamt“.
  static DateSpan span(DashboardPeriod period, DateTime today, {DateSpan? custom, DateTime? firstDay}) {
    final t = CostEngine.day(today);
    final tomorrow = t.add(const Duration(days: 1));
    return switch (period) {
      DashboardPeriod.thisMonth => DateSpan(DateTime.utc(t.year, t.month), tomorrow),
      DashboardPeriod.lastMonth => DateSpan(DateTime.utc(t.year, t.month - 1), DateTime.utc(t.year, t.month)),
      DashboardPeriod.thisYear => DateSpan(DateTime.utc(t.year), tomorrow),
      DashboardPeriod.lastYear => DateSpan(DateTime.utc(t.year - 1), DateTime.utc(t.year)),
      DashboardPeriod.last12Months => DateSpan(_shift(tomorrow, months: -12), tomorrow),
      DashboardPeriod.all => DateSpan(firstDay != null && firstDay.isBefore(t) ? firstDay : t, tomorrow),
      DashboardPeriod.custom => custom ?? DateSpan(DateTime.utc(t.year), tomorrow),
    };
  }

  /// Vergleichszeitraum: derselbe Abschnitt einen Monat bzw. ein Jahr früher, bei eigenem Zeitraum
  /// die gleich vielen Tage direkt davor; „Gesamt“ hat keinen.
  static DateSpan? previous(DashboardPeriod period, DateSpan span) => switch (period) {
    DashboardPeriod.thisMonth || DashboardPeriod.lastMonth => DateSpan(_shift(span.from, months: -1), _shift(span.to, months: -1)),
    DashboardPeriod.thisYear ||
    DashboardPeriod.lastYear ||
    DashboardPeriod.last12Months => DateSpan(_shift(span.from, months: -12), _shift(span.to, months: -12)),
    DashboardPeriod.custom => DateSpan(span.from.subtract(Duration(days: span.days)), span.from),
    DashboardPeriod.all => null,
  };

  /// Erster Tag mit einem Eintrag in [category] (Beginn von „Gesamt“).
  static DateTime? firstDay(Category category) {
    DateTime? first;
    for (final t in category.trackers) {
      for (final e in t.records) {
        final d = CostEngine.day(e.hasPeriod && e.periodStart!.isBefore(e.date) ? e.periodStart! : e.date);
        if (first == null || d.isBefore(first)) first = d;
      }
    }
    return first;
  }

  static bool _hasCost(Tracker t) => t.fields.any((f) => f.role == FieldRole.unitPrice || f.role == FieldRole.recurringCost || f.role == FieldRole.oneOffCost);

  /// Wiederkehrende Beträge je Monat wie in der [CostEngine]: voll an jedem Monatsersten im
  /// Zeitraum (Betrag je Intervall geteilt durch dessen Monate); ein Wert gilt ab dem Monat seines
  /// Datums, mehrere in einem Monat: der letzte.
  static double _monthly(List<(DateTime, double)> points, FieldDefinition field, DateSpan span) {
    final months = field.intervalMonths < 1 || field.role == FieldRole.instalment ? 1 : field.intervalMonths;
    var total = 0.0;
    var i = 0;
    double? current;
    for (var d = DateTime.utc(span.from.year, span.from.month + (span.from.day == 1 ? 0 : 1)); d.isBefore(span.to); d = DateTime.utc(d.year, d.month + 1)) {
      while (i < points.length && !DateTime.utc(points[i].$1.year, points[i].$1.month).isAfter(d)) {
        current = points[i].$2;
        i++;
      }
      if (current != null) total += current / months;
    }
    return total;
  }

  /// Wert an [d], zwischen zwei Einträgen linear; davor der erste, danach der letzte Wert.
  static double _interpolated(List<(DateTime, double)> points, DateTime d) {
    if (!d.isAfter(points.first.$1)) return points.first.$2;
    for (var i = 1; i < points.length; i++) {
      final (to, b) = points[i];
      if (d.isAfter(to)) continue;
      final (from, a) = points[i - 1];
      final days = to.difference(from).inDays;
      return days == 0 ? b : a + (b - a) * d.difference(from).inDays / days;
    }
    return points.last.$2;
  }

  /// [d] um [months] Monate verschoben; der Tag bleibt, höchstens bis Monatsende (31.3. → 28.2.).
  static DateTime _shift(DateTime d, {required int months}) {
    final first = DateTime.utc(d.year, d.month + months);
    final lastDay = DateTime.utc(first.year, first.month + 1, 0).day;
    return DateTime.utc(first.year, first.month, d.day > lastDay ? lastDay : d.day);
  }
}
