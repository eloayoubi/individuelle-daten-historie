import '../models/tracking.dart';
import 'formula.dart';

/// Ergebnis der Prüfung eines Formel-Ausdrucks im Editor.
class FormulaCheck {
  const FormulaCheck._(this.formula, this.error);

  final Formula? formula;
  final FormulaException? error;

  bool get isValid => formula != null;
}

/// Formel-Felder eines Trackers: Kurznamen der Felder, Werte je Eintrag, Ergebnisse.
///
/// Eine Formel rechnet je Eintrag. Ihre Namen bekommen dabei diese Werte:
/// - Felder mit Wert im Eintrag: diesen Wert.
/// - Preise, wiederkehrende Beträge, Abschläge und Stammdaten ohne Wert im Eintrag: den zuletzt
///   eingetragenen – sie gelten bis zur nächsten Änderung.
/// - Einmalige Beträge, Momentwerte und Zählerstände ohne Wert im Eintrag: keinen, die Formel liefert
///   dann nichts (sonst zählte eine Tankfüllung bei jedem späteren Eintrag noch einmal).
/// - `verbrauch`: Zählerstand minus vorigen Stand (× Umrechnung); nur in Einträgen mit Stand,
///   nicht beim Zählerwechsel.
/// - `tage`: Tage seit dem vorigen Eintrag (bei Zählern: seit dem vorigen Stand).
/// - `monate`: `tage` / 30,44.
///
/// Formeln rechnen nicht mit anderen Formeln (keine Ketten, keine Kreise).
abstract final class Formulas {
  static const consumption = 'verbrauch';
  static const days = 'tage';
  static const months = 'monate';

  /// Englische Namen für dieselben Werte.
  static const _english = {consumption: 'consumption', days: 'days', months: 'months'};
  static final builtIns = [consumption, days, months, ..._english.values];

  static const _daysPerMonth = 30.4375;

  /// Kurzname für Formeln: „Kfz-Versicherung“ → `kfz_versicherung`, „Menge (l)“ → `menge_l`.
  static String keyOf(String name) {
    var key = name.toLowerCase().replaceAll('ä', 'ae').replaceAll('ö', 'oe').replaceAll('ü', 'ue').replaceAll('ß', 'ss');
    key = key.replaceAll(RegExp('[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
    if (key.isEmpty) return 'feld';
    return RegExp('^[0-9]').hasMatch(key) ? 'f_$key' : key;
  }

  /// Feld-Id → eindeutiger Kurzname (Doppelte bekommen `_2`, `_3` …; eingebaute Namen sind belegt).
  static Map<String, String> keys(Tracker tracker) {
    final used = {...builtIns};
    return {
      for (final f in tracker.fields)
        f.id: () {
          final base = keyOf(f.name);
          var key = base;
          for (var n = 2; used.contains(key); n++) {
            key = '${base}_$n';
          }
          used.add(key);
          return key;
        }(),
    };
  }

  /// Namen, die eine Formel in diesem Tracker benutzen darf (ohne andere Formeln); die eingebauten
  /// in der App-Sprache ([english]).
  static List<String> available(Tracker tracker, {bool english = false}) {
    final keys = Formulas.keys(tracker);
    final meter = tracker.firstWithRole(FieldRole.meterReading) != null;
    String name(String builtIn) => english ? _english[builtIn]! : builtIn;
    return [
      for (final f in tracker.fields)
        if (f.kind.storage == FieldStorage.number) keys[f.id]!,
      if (meter) name(consumption),
      name(days),
      name(months),
    ];
  }

  /// Ergebnis mit dem neuesten Eintrag, mit dem sich rechnen lässt (Vorschau im Editor).
  static double? preview(Formula formula, Tracker tracker) {
    final variables = variablesByEntry(tracker);
    final sorted = tracker.records..sort((a, b) => b.date.compareTo(a.date));
    for (final e in sorted) {
      if (formula.evaluate(variables[e.id]!, window: _window(tracker, e)) case final double v) return v;
    }
    return null;
  }

  /// Liest den Ausdruck und prüft, ob alle Namen im Tracker vorkommen.
  static FormulaCheck check(String source, Tracker tracker) {
    try {
      final formula = Formula.parse(source);
      final known = {...available(tracker), ...available(tracker, english: true)};
      final unknown = formula.variables.where((v) => !known.contains(v)).firstOrNull;
      if (unknown != null) {
        return FormulaCheck._(null, FormulaException(FormulaErrorKind.unknownVariable, source.toLowerCase().indexOf(unknown).clamp(0, source.length), unknown));
      }
      return FormulaCheck._(formula, null);
    } on FormulaException catch (e) {
      return FormulaCheck._(null, e);
    }
  }

  /// Rechnet alle Formel-Felder für jeden Eintrag und hängt die Ergebnisse an die Einträge an.
  /// Danach sehen Verlauf, Kosten und Prognose Formel-Werte wie eingegebene. Reine Detail-Einträge
  /// bleiben, wie sie sind.
  static Tracker apply(Tracker tracker) {
    final parsed = <FieldDefinition, Formula>{
      for (final f in tracker.fields)
        if (f.kind == FieldKind.formula && f.formula != null)
          if (_tryParse(f.formula!) case final Formula formula) f: formula,
    };
    if (parsed.isEmpty) return tracker;
    final variables = variablesByEntry(tracker);
    return tracker.copyWith(
      entries: [
        for (final e in tracker.entries)
          if (tracker.isDetailEntry(e))
            e
          else
            e.copyWith(
              values: {
                ...e.values,
                for (final MapEntry(key: field, value: formula) in parsed.entries)
                  if (formula.evaluate(variables[e.id]!, window: _window(tracker, e)) case final double v) field.id: v,
              },
            ),
      ],
    );
  }

  /// Formel-Namen mit ihren Werten für jeden Eintrag (Eintrags-Id → Name → Wert).
  /// Ergebnis mit dem neuesten Eintrag, mit Zeiträumen (`summe`/`schnitt`).
  static double? evaluateAt(Formula formula, Tracker tracker, Entry entry) => formula.evaluate(variablesByEntry(tracker)[entry.id] ?? const {}, window: _window(tracker, entry));

  static Map<String, Map<String, double>> variablesByEntry(Tracker tracker) {
    final keys = Formulas.keys(tracker);
    final meter = tracker.firstWithRole(FieldRole.meterReading);
    final numeric = [for (final f in tracker.fields) if (f.kind.storage == FieldStorage.number) f];
    final sorted = [...tracker.entries]..sort((a, b) => a.date.compareTo(b.date));
    final last = <String, double>{};
    DateTime? lastDate;
    (DateTime, double)? lastReading;
    final result = <String, Map<String, double>>{};
    for (final e in sorted) {
      // Details zählen mit ihrem Wert, sind aber kein „voriger Eintrag“ für `tage` und `monate`.
      if (tracker.isDetailEntry(e)) {
        for (final f in numeric) {
          if (e.values[f.id] case final num v) last[f.id] = v.toDouble();
        }
        continue;
      }
      // Rechnung: Der Wert im Zählerfeld ist der Verbrauch im Zeitraum, kein Stand.
      final bill = tracker.isBill(e);
      bool own(FieldDefinition f) => !(bill && f.id == meter?.id);
      final vars = <String, double>{};
      for (final f in numeric) {
        final value = e.values[f.id];
        if (value is num && own(f)) {
          vars[keys[f.id]!] = value.toDouble();
        } else if ((f.isRate || f.role == FieldRole.info) && last.containsKey(f.id)) {
          vars[keys[f.id]!] = last[f.id]!;
        }
      }
      final reading = meter == null || bill ? null : e.values[meter.id];
      if (bill) {
        final d = e.periodEnd!.difference(e.periodStart!).inDays + 1.0;
        vars[days] = vars[_english[days]!] = d;
        vars[months] = vars[_english[months]!] = d / _daysPerMonth;
        vars[consumption] = vars[_english[consumption]!] = e.number(meter!.id)!.toDouble();
      } else {
        final since = reading is num && lastReading != null ? lastReading.$1 : lastDate;
        if (since != null) {
          final d = e.date.difference(since).inDays.toDouble();
          vars[days] = vars[_english[days]!] = d;
          vars[months] = vars[_english[months]!] = d / _daysPerMonth;
        }
        if (meter != null && reading is num && lastReading != null && !e.meterChange) {
          vars[consumption] = vars[_english[consumption]!] = (reading - lastReading.$2) * meter.factor;
        }
      }
      result[e.id] = vars;
      for (final f in numeric) {
        if (e.values[f.id] case final num v when own(f)) last[f.id] = v.toDouble();
      }
      if (reading is num) lastReading = (e.date, reading.toDouble());
      lastDate = e.date;
    }
    return result;
  }

  /// `summe(feld; tage)` / `schnitt(feld; tage)`: Werte des Felds in den [days] Tagen bis zum Eintrag.
  static FormulaWindow _window(Tracker tracker, Entry at) {
    final keys = Formulas.keys(tracker);
    final byKey = {for (final f in tracker.fields) keys[f.id]!: f};
    return (name, days, average) {
      final field = byKey[name];
      if (field == null) return null;
      final from = at.date.subtract(Duration(days: days.round()));
      final values = [
        for (final e in tracker.entries)
          if (e.date.isAfter(from) && !e.date.isAfter(at.date))
            if (e.values[field.id] case final num v) v.toDouble(),
      ];
      if (values.isEmpty) return average ? null : 0;
      final sum = values.fold(0.0, (a, b) => a + b);
      return average ? sum / values.length : sum;
    };
  }

  static Formula? _tryParse(String source) {
    try {
      return Formula.parse(source);
    } on FormulaException {
      return null;
    }
  }
}
