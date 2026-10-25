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
///   Vor dem ersten Stand ist nichts bekannt, dort zählt nichts. Zählerwechsel an einem Tag: der
///   Stand ohne Markierung schließt den alten Zähler ab, der markierte ([Entry.meterChange]) beginnt
///   den neuen.
/// - **Rechnungen** ([Tracker.isBill]): Der Verbrauch im Zeitraum verteilt sich gleichmäßig auf
///   dessen Tage (ohne Umrechnungsfaktor, er steht schon in der Verbrauchseinheit). Eine Rechnung
///   hat Vorrang vor Zählerständen, bei Überschneidung gilt die später endende. Deckt sie nur einen
///   Teil der Tage zwischen zwei Ständen, bekommen die übrigen Tage den Rest des gemessenen
///   Verbrauchs zu gleichen Teilen (Differenz minus Rechnungsverbrauch, mindestens 0).
/// - **Lücken** zwischen bekannten Tagen (zwischen zwei Rechnungen, Zählerwechsel ohne Endstand):
///   die erste Hälfte mit dem Tagesverbrauch davor, die zweite mit dem danach.
/// - **Arbeitspreis** ([FieldRole.unitPrice]) und **wiederkehrende Beträge**
///   ([FieldRole.recurringCost]) gelten ab ihrem Datum bis zur nächsten Änderung. Im Voraus
///   eingetragene Erhöhungen fließen so von selbst in die Prognose ein.
/// - **Einmalige Beträge** ([FieldRole.oneOffCost]) zählen an ihrem Tag – mit Abrechnungszeitraum
///   bis heute verteilt auf dessen Tage; ab morgen gilt der Tagesdurchschnitt dessen, was in den
///   letzten 365 Tagen gezahlt wurde (nach Datum des Eintrags; Tanken, Nachzahlungen …), dazu im
///   Voraus eingetragene Beträge an ihrem Tag.
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
    // Durchschnitt einmaliger Beträge: was in den letzten 365 Tagen gezahlt wurde (nach Zahltag).
    final yearAgo = _today.subtract(const Duration(days: 365));
    var paidLastYear = 0.0;
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
            final paidOn = day(e.date);
            if (paidOn.isAfter(_today)) {
              // Im Voraus eingetragen: zählt an seinem Tag, zusätzlich zum Durchschnitt.
              _oneOffAhead[paidOn] = (_oneOffAhead[paidOn] ?? 0) + value;
              continue;
            }
            // Heute zählt schon mit: ein heute eingetragener Betrag ist bekannt, kein Durchschnitt.
            if (paidOn.isAfter(yearAgo)) paidLastYear += value;
            if (e.hasPeriod) {
              // Abrechnung für einen Zeitraum: gleichmäßig auf dessen Tage.
              final from = day(e.periodStart!), to = day(e.periodEnd!);
              final days = to.difference(from).inDays + 1;
              for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1))) {
                _oneOff[d] = (_oneOff[d] ?? 0) + value / days;
              }
            } else {
              _oneOff[paidOn] = (_oneOff[paidOn] ?? 0) + value;
            }
          }
        case FieldRole.instalment:
          _instalments.add((timeline, field.intervalMonths < 1 ? 1 : field.intervalMonths));
        case FieldRole.info || FieldRole.snapshot || FieldRole.meterReading || FieldRole.deadline:
          break;
      }
    }
    _unitPrices.sort((a, b) => a.$1.compareTo(b.$1));
    _oneOffDaily = paidLastYear / 365;
  }

  final DateTime _today;

  /// Erster bekannter Tag und ab dort je Tag der Verbrauch – aus Zählerständen und Rechnungen.
  DateTime? _first;
  DateTime? _end;
  final _daily = <double>[];
  double _trailingRate = 0;

  double? _trend;

  final _unitPrices = <(DateTime, double)>[];
  final _recurring = <(List<(DateTime, double)>, int)>[];
  final _instalments = <(List<(DateTime, double)>, int)>[];
  /// Einmalige Beträge bis heute je Tag (mit Zeitraum auf dessen Tage verteilt).
  final _oneOff = <DateTime, double>{};

  /// Im Voraus eingetragene einmalige Beträge je Zahltag.
  final _oneOffAhead = <DateTime, double>{};
  double _oneOffDaily = 0;

  /// Datum ohne Uhrzeit in UTC – so verschiebt keine Zeitumstellung die Tage.
  static DateTime day(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  /// Erster Tag nach dem bekannten Verbrauch: Tag des letzten Stands bzw. Tag nach dem Ende der
  /// letzten Rechnung; `null` ohne bekannten Verbrauch.
  DateTime? get lastReading => _end;

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
    d.isAfter(_today) ? _oneOffDaily + (_oneOffAhead[d] ?? 0) : _oneOff[d] ?? 0,
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
    final end = _end!;
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

    // Zählerstände je Tag: Endstand des alten Abschnitts (ohne Wechsel-Markierung) und Anfangsstand
    // des nächsten (beim Zählerwechsel der markierte Stand). Mehrere Stände an einem Tag: der höchste
    // schließt ab, der niedrigste Wechsel-Stand beginnt – unabhängig von der Reihenfolge.
    final ends = <DateTime, double>{}, starts = <DateTime, double>{};
    for (final e in tracker.entries) {
      if (!tracker.isReading(e)) continue;
      final value = e.number(field.id)?.toDouble();
      if (value == null) continue;
      final date = day(e.date);
      if (e.meterChange) {
        starts[date] = math.min(starts[date] ?? value, value);
      } else {
        ends[date] = math.max(ends[date] ?? value, value);
      }
    }
    final dates = {...ends.keys, ...starts.keys}.toList()..sort();
    // Abschnitte [von, bis) zwischen zwei Ständen mit gemessenem Verbrauch; `null`, wenn er unbekannt
    // ist (Zählerwechsel ohne Endstand des alten Zählers, fallender Stand).
    final readings = <(DateTime, DateTime, double?)>[];
    for (var i = 1; i < dates.length; i++) {
      final from = dates[i - 1], to = dates[i];
      final a = starts[from] ?? ends[from]!, b = ends[to];
      readings.add((from, to, b == null || b < a ? null : (b - a) * field.factor));
    }

    // Rechnungen: gleichmäßig auf ihre Tage, die später endende zuletzt – sie gewinnt.
    final bills = [
      for (final e in tracker.entries)
        if (tracker.isBill(e))
          if (e.number(field.id) case final num v) (day(e.periodStart!), day(e.periodEnd!).add(const Duration(days: 1)), v.toDouble()),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    if (readings.isEmpty && bills.isEmpty) return;

    final bounds = [for (final s in readings) ...[s.$1, s.$2], for (final b in bills) ...[b.$1, b.$2]];
    final first = bounds.reduce((a, b) => a.isBefore(b) ? a : b);
    final end = bounds.reduce((a, b) => a.isAfter(b) ? a : b);
    int index(DateTime d) => d.difference(first).inDays;
    final daily = List<double?>.filled(index(end), null);
    for (final (from, to, value) in bills) {
      for (var i = index(from); i < index(to); i++) {
        daily[i] = value / to.difference(from).inDays;
      }
    }
    // Zwischen zwei Ständen: was die Rechnungen nicht abdecken, bekommt den Rest des gemessenen
    // Verbrauchs zu gleichen Teilen – so stimmt die Summe zwischen den Ständen.
    for (final (from, to, measured) in readings) {
      if (measured == null) continue;
      var billed = 0.0, open = 0;
      for (var i = index(from); i < index(to); i++) {
        if (daily[i] case final double v) {
          billed += v;
        } else {
          open++;
        }
      }
      if (open == 0) continue;
      final rate = math.max(0.0, measured - billed) / open;
      for (var i = index(from); i < index(to); i++) {
        daily[i] ??= rate;
      }
    }
    // Lücken (zwischen zwei Rechnungen, Zählerwechsel ohne Endstand): die erste Hälfte mit dem
    // Tagesverbrauch davor, die zweite mit dem danach; der mittlere Tag einer ungeraden Lücke zählt
    // zur ersten Hälfte. Am Rand gilt der eine Nachbar, ohne Nachbarn 0.
    for (var i = 0; i < daily.length; i++) {
      if (daily[i] != null) continue;
      var j = i;
      while (j < daily.length && daily[j] == null) {
        j++;
      }
      final before = i > 0 ? daily[i - 1] : null, after = j < daily.length ? daily[j] : null;
      final middle = i + (j - i + 1) ~/ 2;
      for (var k = i; k < j; k++) {
        daily[k] = (k < middle ? before ?? after : after ?? before) ?? 0;
      }
      i = j;
    }
    _daily.addAll(daily.cast<double>());
    _first = first;
    _end = end;

    // Durchschnitt der letzten 365 bekannten Tage (oder aller, wenn es weniger sind).
    final last = _daily.skip(math.max(0, _daily.length - 365));
    _trailingRate = last.fold(0.0, (sum, v) => sum + v) / last.length;
    _trend = _computeTrend();
  }

  /// Letzte 365 bekannte Tage gegen die 365 davor – nur mit zwei vollen Jahren Verlauf.
  double? _computeTrend() {
    final end = _end!;
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
