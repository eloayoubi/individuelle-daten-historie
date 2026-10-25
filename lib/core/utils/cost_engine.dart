import 'dart:math' as math;

import '../models/tracking.dart';
import 'formulas.dart';

/// Kosten aufgeteilt nach Herkunft – Grundlage für die erklärte Prognose und ihre Spanne.
class CostParts {
  const CostParts({this.meter = 0, this.fixed = 0, this.oneOff = 0});

  /// Verbrauch × Arbeitspreis.
  final double meter;

  /// Wiederkehrende Beträge (Miete, Grundpreis, Abos, Versicherungen).
  final double fixed;

  /// Einmalige Beträge (Tanken, Nachzahlungen); in der Zukunft als Durchschnitt.
  final double oneOff;

  double get total => meter + fixed + oneOff;

  CostParts operator +(CostParts o) => CostParts(meter: meter + o.meter, fixed: fixed + o.fixed, oneOff: oneOff + o.oneOff);
}


/// Rechnet Verbrauch und Kosten eines [Tracker]s Tag für Tag.
///
/// - **Zählerstände** ([FieldRole.meterReading]): Zwischen zwei Ständen wird linear verteilt, so
///   ergeben sich auch Kalenderjahre, obwohl selten am 1. Januar abgelesen wird. Nach dem letzten
///   Stand (bis heute und in der Zukunft) gilt der Verbrauch desselben Tages im Vorjahr – so hat
///   die Prognose eine Saison –, ohne Vorjahr der Tagesdurchschnitt der letzten 365 Tage.
///   Vor dem ersten Stand ist nichts bekannt, dort zählt nichts.
/// - **Rechnungen** ([Tracker.isBill]): Der Verbrauch im Zeitraum verteilt sich gleichmäßig auf
///   dessen Tage (ohne Umrechnungsfaktor, er steht schon in der Verbrauchseinheit). Eine Rechnung
///   hat Vorrang vor Zählerständen, bei Überschneidung gilt die später endende. Lücken zwischen
///   bekannten Tagen bekommen den Tagesverbrauch davor.
/// - **Arbeitspreis** ([FieldRole.unitPrice]) und **wiederkehrende Beträge**
///   ([FieldRole.recurringCost]) gelten ab ihrem Datum bis zur nächsten Änderung. Im Voraus
///   eingetragene Erhöhungen fließen so von selbst in die Prognose ein.
/// - **Einmalige Beträge** ([FieldRole.oneOffCost]) zählen an ihrem Tag – mit Abrechnungszeitraum
///   verteilt auf dessen Tage; ab morgen gilt der Tagesdurchschnitt der letzten 365 Tage (Tanken,
///   Nachzahlungen …).
/// - **Abschläge** ([FieldRole.instalment]) sind keine Kosten; [paid] summiert sie wie
///   wiederkehrende Beträge für den Abschlags-Check.
/// - **Formel-Felder** werden vorher je Eintrag ausgerechnet ([Formulas.apply]) und zählen dann
///   nach ihrem Zeitverhalten wie eingegebene Werte.
/// - **Trend:** Liegen zwei volle Jahre Zählerstände vor, wird der Vorjahres-Verbrauch der Prognose
///   mit dem Verhältnis der letzten 365 Tage zu den 365 davor angepasst (begrenzt auf −20 … +25 %).
class CostEngine {
  CostEngine(Tracker source, {required DateTime today}) : _today = day(today) {
    final tracker = Formulas.apply(source);
    _prepareConsumption(tracker);
    for (final field in tracker.fields) {
      final timeline = _timeline(tracker, field);
      if (timeline.isEmpty) continue;
      switch (field.role) {
        case FieldRole.unitPrice:
          _unitPrices.addAll(timeline);
        case FieldRole.recurringCost:
          _recurring.add((timeline, field.intervalMonths < 1 ? 1 : field.intervalMonths));
        case FieldRole.oneOffCost:
          for (final e in tracker.entries) {
            final value = e.number(field.id)?.toDouble();
            if (value == null) continue;
            if (e.hasPeriod) {
              // Abrechnung für einen Zeitraum: gleichmäßig auf dessen Tage.
              final from = day(e.periodStart!), to = day(e.periodEnd!);
              final days = to.difference(from).inDays + 1;
              for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1))) {
                _oneOff[d] = (_oneOff[d] ?? 0) + value / days;
              }
            } else {
              final d = day(e.date);
              _oneOff[d] = (_oneOff[d] ?? 0) + value;
            }
          }
        case FieldRole.instalment:
          _instalments.add((timeline, field.intervalMonths < 1 ? 1 : field.intervalMonths));
        case FieldRole.info || FieldRole.snapshot || FieldRole.meterReading || FieldRole.deadline:
          break;
      }
    }
    _unitPrices.sort((a, b) => a.$1.compareTo(b.$1));
    final yearAgo = _today.subtract(const Duration(days: 365));
    // Heute zählt schon mit: ein heute eingetragener Betrag ist bekannt, kein Durchschnitt.
    final lastYear = _oneOff.entries.where((e) => e.key.isAfter(yearAgo) && !e.key.isAfter(_today));
    _oneOffDaily = lastYear.fold(0.0, (sum, e) => sum + e.value) / 365;
  }

  final DateTime _today;

  /// Erster bekannter Tag und ab dort je Tag der Verbrauch – aus Zählerständen und Rechnungen.
  DateTime? _first;
  final _daily = <double>[];
  double _trailingRate = 0;

  double? _trend;

  final _unitPrices = <(DateTime, double)>[];
  final _recurring = <(List<(DateTime, double)>, int)>[];
  final _instalments = <(List<(DateTime, double)>, int)>[];
  final _oneOff = <DateTime, double>{};
  double _oneOffDaily = 0;

  /// Datum ohne Uhrzeit in UTC – so verschiebt keine Zeitumstellung die Tage.
  static DateTime day(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  /// Erster Tag nach dem bekannten Verbrauch: Tag des letzten Stands bzw. Tag nach dem Ende der
  /// letzten Rechnung; `null` ohne bekannten Verbrauch.
  DateTime? get lastReading => _first?.add(Duration(days: _daily.length));

  /// Verbrauch bekannt: ab zwei Zählerständen oder einer Rechnung.
  bool get hasMeter => _daily.isNotEmpty;

  bool get hasInstalment => _instalments.isNotEmpty;

  /// Verhältnis Verbrauch letzte 365 Tage zu den 365 davor, `null` ohne zwei volle Jahre.
  double? get trend => _trend;

  /// Verbrauch in `[from, to)`.
  double consumption(DateTime from, DateTime to) => _sum(from, to, _rateOn);

  /// Kosten in `[from, to)`.
  double cost(DateTime from, DateTime to) => _sum(from, to, _costOn);

  /// Kosten in `[from, to)` nach Herkunft.
  CostParts parts(DateTime from, DateTime to) {
    var meter = 0.0, fixed = 0.0, oneOff = 0.0;
    for (var d = day(from); d.isBefore(to); d = d.add(const Duration(days: 1))) {
      final (m, f, o) = _partsOn(d);
      meter += m;
      fixed += f;
      oneOff += o;
    }
    return CostParts(meter: meter, fixed: fixed, oneOff: oneOff);
  }

  /// Gezahlte Abschläge in `[from, to)`.
  double paid(DateTime from, DateTime to) => _sum(from, to, (d) => _monthly(_instalments, d));

  /// Halbe Breite der Prognose-Spanne für [p]: Verbrauch je nach Trend (mindestens ±5 %, ohne
  /// Trend ±10 %), feste Beträge ±1 %, einmalige ±25 %; unabhängig, daher als Wurzel der Quadrate.
  double uncertainty(CostParts p) {
    final meterShare = _trend == null ? 0.1 : math.max(0.05, (_trend! - 1).abs());
    return math.sqrt(math.pow(p.meter * meterShare, 2) + math.pow(p.fixed * 0.01, 2) + math.pow(p.oneOff * 0.25, 2));
  }

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
    final (meter, fixed, oneOff) = _partsOn(d);
    return meter + fixed + oneOff;
  }

  (double, double, double) _partsOn(DateTime d) => (
    _rateOn(d) * _valueAt(_unitPrices, d, beforeFirst: _unitPrices.firstOrNull?.$2 ?? 0),
    _monthly(_recurring, d),
    d.isAfter(_today) ? _oneOffDaily : _oneOff[d] ?? 0,
  );

  /// Tagesanteil wiederkehrender Beträge (Betrag je Intervall, auf die Tage des Monats verteilt).
  static double _monthly(List<(List<(DateTime, double)>, int)> series, DateTime d) {
    var total = 0.0;
    for (final (timeline, months) in series) {
      total += _valueAt(timeline, d) / months / _daysInMonth(d);
    }
    return total;
  }

  double _rateOn(DateTime d) {
    if (!hasMeter || d.isBefore(_first!)) return 0;
    final end = lastReading!;
    if (!d.isBefore(end)) {
      // Nach dem letzten bekannten Tag: derselbe Tag ein (oder zwei …) Jahre früher, damit die
      // Prognose die Saison abbildet (Heizung im Winter). Reicht der Verlauf nicht so weit: Durchschnitt.
      var back = d.subtract(const Duration(days: 365));
      while (!back.isBefore(end)) {
        back = back.subtract(const Duration(days: 365));
      }
      return back.isBefore(_first!) ? _trailingRate : _segmentRate(back) * (_trend ?? 1);
    }
    return _segmentRate(d);
  }

  /// Tagesverbrauch an [d] (zwischen erstem und letztem bekannten Tag).
  double _segmentRate(DateTime d) => _daily[d.difference(_first!).inDays];

  void _prepareConsumption(Tracker tracker) {
    final field = tracker.meter;
    if (field == null) return;
    // Abschnitte [von, bis) mit festem Tagesverbrauch; später eingefügte überschreiben frühere.
    final sections = <(DateTime, DateTime, double)>[];

    // Zählerstände: linear zwischen zwei Ständen.
    final points = <(DateTime, double, bool)>[
      for (final e in tracker.entries)
        if (tracker.isReading(e))
          if (e.number(field.id) case final num v) (day(e.date), v.toDouble(), e.meterChange),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    final readings = <(DateTime, double)>[];
    for (final (date, value, _) in points) {
      if (readings.isNotEmpty && readings.last.$1 == date) readings.removeLast();
      readings.add((date, value));
    }
    final changes = {for (final (date, _, change) in points) if (change) date};
    final rates = <double?>[];
    for (var i = 1; i < readings.length; i++) {
      final (from, a) = readings[i - 1];
      final (to, b) = readings[i];
      // Zählerwechsel: Verbrauch bis zum Ausbau unbekannt, später mit dem Nachbarabschnitt füllen.
      rates.add(changes.contains(to) || b < a ? null : (b - a) * field.factor / to.difference(from).inDays);
    }
    for (var i = 0; i < rates.length; i++) {
      sections.add((readings[i].$1, readings[i + 1].$1, rates[i] ?? _neighbour(rates, i)));
    }

    // Rechnungen: gleichmäßig auf ihre Tage, die später endende zuletzt – sie gewinnt.
    final bills = [
      for (final e in tracker.entries)
        if (tracker.isBill(e))
          if (e.number(field.id) case final num v) (day(e.periodStart!), day(e.periodEnd!).add(const Duration(days: 1)), v.toDouble()),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    for (final (from, to, value) in bills) {
      sections.add((from, to, value / to.difference(from).inDays));
    }
    if (sections.isEmpty) return;

    final first = sections.map((s) => s.$1).reduce((a, b) => a.isBefore(b) ? a : b);
    final end = sections.map((s) => s.$2).reduce((a, b) => a.isAfter(b) ? a : b);
    final daily = List<double?>.filled(end.difference(first).inDays, null);
    for (final (from, to, rate) in sections) {
      for (var i = from.difference(first).inDays; i < to.difference(first).inDays; i++) {
        daily[i] = rate;
      }
    }
    // Lücken (z. B. zwischen zwei Rechnungen): Tagesverbrauch davor. Der erste Tag ist immer bekannt.
    for (var i = 0; i < daily.length; i++) {
      _daily.add(daily[i] ?? _daily[i - 1]);
    }
    _first = first;

    // Durchschnitt der letzten 365 bekannten Tage (oder aller, wenn es weniger sind).
    final last = _daily.skip(math.max(0, _daily.length - 365));
    _trailingRate = last.fold(0.0, (sum, v) => sum + v) / last.length;
    _trend = _computeTrend();
  }

  /// Letzte 365 bekannte Tage gegen die 365 davor – nur mit zwei vollen Jahren Verlauf.
  double? _computeTrend() {
    final end = lastReading!;
    final middle = end.subtract(const Duration(days: 365));
    final start = end.subtract(const Duration(days: 730));
    if (_first!.isAfter(start)) return null;
    double actual(DateTime from, DateTime to) {
      var sum = 0.0;
      for (var d = from; d.isBefore(to); d = d.add(const Duration(days: 1))) {
        sum += _segmentRate(d);
      }
      return sum;
    }

    final older = actual(start, middle);
    if (older <= 0) return null;
    return (actual(middle, end) / older).clamp(0.8, 1.25);
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
