import '../models/tracking.dart';

/// Rechnet Verbrauch und Kosten eines [Tracker]s Tag für Tag.
///
/// - **Zählerstände** ([FieldRole.meterReading]): Zwischen zwei Ständen wird linear verteilt, so
///   ergeben sich auch Kalenderjahre, obwohl selten am 1. Januar abgelesen wird. Nach dem letzten
///   Stand (bis heute und in der Zukunft) gilt der Verbrauch desselben Tages im Vorjahr – so hat
///   die Prognose eine Saison –, ohne Vorjahr der Tagesdurchschnitt der letzten 365 Tage.
///   Vor dem ersten Stand ist nichts bekannt, dort zählt nichts.
/// - **Arbeitspreis** ([FieldRole.unitPrice]) und **wiederkehrende Beträge**
///   ([FieldRole.recurringCost]) gelten ab ihrem Datum bis zur nächsten Änderung. Im Voraus
///   eingetragene Erhöhungen fließen so von selbst in die Prognose ein.
/// - **Einmalige Beträge** ([FieldRole.oneOffCost]) zählen an ihrem Tag; ab heute gilt der
///   Tagesdurchschnitt der letzten 365 Tage (Tanken, Nachzahlungen …).
class CostEngine {
  CostEngine(Tracker tracker, {required DateTime today}) : _today = day(today) {
    _prepareReadings(tracker);
    for (final field in tracker.fields) {
      final timeline = _timeline(tracker, field);
      if (timeline.isEmpty) continue;
      switch (field.role) {
        case FieldRole.unitPrice:
          _unitPrices.addAll(timeline);
        case FieldRole.recurringCost:
          _recurring.add((timeline, field.intervalMonths < 1 ? 1 : field.intervalMonths));
        case FieldRole.oneOffCost:
          for (final (date, value) in timeline) {
            _oneOff[date] = (_oneOff[date] ?? 0) + value;
          }
        case FieldRole.info || FieldRole.snapshot || FieldRole.meterReading || FieldRole.deadline:
          break;
      }
    }
    _unitPrices.sort((a, b) => a.$1.compareTo(b.$1));
    final yearAgo = _today.subtract(const Duration(days: 365));
    final lastYear = _oneOff.entries.where((e) => !e.key.isBefore(yearAgo) && e.key.isBefore(_today));
    _oneOffDaily = lastYear.fold(0.0, (sum, e) => sum + e.value) / 365;
  }

  final DateTime _today;

  /// Stände als (Tag, Wert) und je Abschnitt zwischen zwei Ständen der Tagesverbrauch.
  final _readings = <(DateTime, double)>[];
  final _rates = <double>[];
  double _trailingRate = 0;

  final _unitPrices = <(DateTime, double)>[];
  final _recurring = <(List<(DateTime, double)>, int)>[];
  final _oneOff = <DateTime, double>{};
  double _oneOffDaily = 0;

  /// Datum ohne Uhrzeit in UTC – so verschiebt keine Zeitumstellung die Tage.
  static DateTime day(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  DateTime? get lastReading => _readings.isEmpty ? null : _readings.last.$1;

  bool get hasMeter => _readings.length >= 2;

  /// Verbrauch in `[from, to)`.
  double consumption(DateTime from, DateTime to) => _sum(from, to, _rateOn);

  /// Kosten in `[from, to)`.
  double cost(DateTime from, DateTime to) => _sum(from, to, _costOn);

  double costInYear(int year) => cost(DateTime.utc(year), DateTime.utc(year + 1));

  double costInMonth(int year, int month) => cost(DateTime.utc(year, month), DateTime.utc(year, month + 1));

  double _sum(DateTime from, DateTime to, double Function(DateTime) perDay) {
    var total = 0.0;
    for (var d = day(from); d.isBefore(to); d = d.add(const Duration(days: 1))) {
      total += perDay(d);
    }
    return total;
  }

  double _costOn(DateTime d) {
    var total = _rateOn(d) * _valueAt(_unitPrices, d, beforeFirst: _unitPrices.firstOrNull?.$2 ?? 0);
    for (final (timeline, months) in _recurring) {
      total += _valueAt(timeline, d) / months / _daysInMonth(d);
    }
    return total + (d.isBefore(_today) ? _oneOff[d] ?? 0 : _oneOffDaily);
  }

  double _rateOn(DateTime d) {
    if (!hasMeter || d.isBefore(_readings.first.$1)) return 0;
    if (!d.isBefore(_readings.last.$1)) {
      // Nach dem letzten Stand: derselbe Tag ein (oder zwei …) Jahre früher, damit die Prognose
      // die Saison abbildet (Heizung im Winter). Reicht der Verlauf nicht so weit: Durchschnitt.
      var back = d.subtract(const Duration(days: 365));
      while (!back.isBefore(_readings.last.$1)) {
        back = back.subtract(const Duration(days: 365));
      }
      return back.isBefore(_readings.first.$1) ? _trailingRate : _segmentRate(back);
    }
    return _segmentRate(d);
  }

  /// Tagesverbrauch des Abschnitts, in dem [d] liegt (zwischen erstem und letztem Stand).
  double _segmentRate(DateTime d) {
    // Letzter Stand am oder vor d.
    var lo = 0, hi = _readings.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (_readings[mid].$1.isAfter(d)) {
        hi = mid - 1;
      } else {
        lo = mid;
      }
    }
    return _rates[lo];
  }

  void _prepareReadings(Tracker tracker) {
    final field = tracker.firstWithRole(FieldRole.meterReading);
    if (field == null) return;
    final points = <(DateTime, double, bool)>[
      for (final e in tracker.entries)
        if (e.number(field.id) case final num v) (day(e.date), v.toDouble(), e.meterChange),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    for (final (date, value, _) in points) {
      if (_readings.isNotEmpty && _readings.last.$1 == date) _readings.removeLast();
      _readings.add((date, value));
    }
    final changes = {for (final (date, _, change) in points) if (change) date};
    final rates = <double?>[];
    for (var i = 1; i < _readings.length; i++) {
      final (from, a) = _readings[i - 1];
      final (to, b) = _readings[i];
      // Zählerwechsel: Verbrauch bis zum Ausbau unbekannt, später mit dem Nachbarabschnitt füllen.
      rates.add(changes.contains(to) || b < a ? null : (b - a) * field.factor / to.difference(from).inDays);
    }
    for (var i = 0; i < rates.length; i++) {
      _rates.add(rates[i] ?? _neighbour(rates, i));
    }
    if (_rates.isEmpty) return;
    // Durchschnitt der letzten 365 Tage vor dem letzten Stand (oder des ganzen Verlaufs, wenn kürzer).
    final end = _readings.last.$1;
    final start = end.subtract(const Duration(days: 365));
    var used = 0, total = 0.0;
    for (var i = 0; i < _rates.length; i++) {
      final from = _readings[i].$1.isBefore(start) ? start : _readings[i].$1;
      final to = _readings[i + 1].$1;
      if (!to.isAfter(from)) continue;
      final days = to.difference(from).inDays;
      used += days;
      total += _rates[i] * days;
    }
    _trailingRate = used == 0 ? 0 : total / used;
  }

  static double _neighbour(List<double?> rates, int i) {
    for (var step = 1; step < rates.length; step++) {
      if (i - step >= 0 && rates[i - step] != null) return rates[i - step]!;
      if (i + step < rates.length && rates[i + step] != null) return rates[i + step]!;
    }
    return 0;
  }

  static List<(DateTime, double)> _timeline(Tracker tracker, FieldDefinition field) => [
    for (final e in tracker.entries)
      if (e.number(field.id) case final num v) (day(e.date), v.toDouble()),
  ]..sort((a, b) => a.$1.compareTo(b.$1));

  /// Wert, der an [d] gilt: der letzte am oder vor [d], davor [beforeFirst].
  static double _valueAt(List<(DateTime, double)> timeline, DateTime d, {double beforeFirst = 0}) {
    var value = beforeFirst;
    for (final (date, v) in timeline) {
      if (date.isAfter(d)) break;
      value = v;
    }
    return value;
  }

  static int _daysInMonth(DateTime d) => DateTime.utc(d.year, d.month + 1, 0).day;
}
