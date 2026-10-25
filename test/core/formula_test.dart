import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/models/tracking.dart';
import 'package:kostenkurve/core/utils/cost_engine.dart';
import 'package:kostenkurve/core/utils/formula.dart';
import 'package:kostenkurve/core/utils/formulas.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';

double? calc(String source, [Map<String, double> values = const {}]) => Formula.parse(source).evaluate(values);

FormulaException error(String source) {
  try {
    Formula.parse(source);
  } on FormulaException catch (e) {
    return e;
  }
  throw StateError('kein Fehler für $source');
}

void main() {
  group('Formula', () {
    test('Punkt vor Strich, Klammern, Potenz von rechts, Vorzeichen', () {
      expect(calc('1 + 2 * 3'), 7);
      expect(calc('(1 + 2) * 3'), 9);
      expect(calc('2 ^ 3 ^ 2'), 512);
      expect(calc('-2 ^ 2'), -4);
      expect(calc('10 / 4 - -1'), 3.5);
    });

    test('Dezimalkomma, Trenner ; und Komma mit Leerzeichen', () {
      expect(calc('0,329 * 1000'), closeTo(329, 1e-9));
      expect(calc('.5 + 1'), 1.5);
      expect(calc('max(1; 7; 3)'), 7);
      expect(calc('min(4, 2)'), 2);
      expect(calc('runden(2,345; 2)'), closeTo(2.35, 1e-9));
      expect(calc('runden(x,2)', {'x': 1.234}), closeTo(1.23, 1e-9));
    });

    test('Funktionen und Vergleiche, wenn rechnet nur den gewählten Zweig', () {
      expect(calc('abs(-3) + wurzel(9)'), 6);
      expect(calc('wenn(a > 10; 1; 0)', {'a': 12}), 1);
      expect(calc('wenn(a >= 10; 1; fehlt)', {'a': 10}), 1);
      expect(calc('if(a != 1, 5, 6)', {'a': 1}), 6);
      expect(calc('a = 2', {'a': 2}), 1);
    });

    test('Namen sind unabhängig von Groß- und Kleinschreibung, Umlaute erlaubt', () {
      final f = Formula.parse('Verbrauch * Arbeitspreis + grundgebühr');
      expect(f.variables, {'verbrauch', 'arbeitspreis', 'grundgebühr'});
      expect(f.evaluate({'verbrauch': 100, 'arbeitspreis': 0.3, 'grundgebühr': 10}), closeTo(40, 1e-9));
    });

    test('fehlender Name, Division durch null: kein Ergebnis', () {
      expect(calc('a + 1'), isNull);
      expect(calc('1 / (a - a)', {'a': 3}), isNull);
      expect(calc('wurzel(-1)'), isNull);
    });

    test('Fehler mit Art und Stelle', () {
      expect(error('').kind, FormulaErrorKind.empty);
      expect(error('1 + ').kind, FormulaErrorKind.unexpectedEnd);
      expect((error('2 # 3').kind, error('2 # 3').position), (FormulaErrorKind.unexpectedCharacter, 2));
      expect(error('(1 + 2').kind, FormulaErrorKind.missingParenthesis);
      expect(error('1 + 2)').kind, FormulaErrorKind.unexpectedToken);
      expect(error('teile(1)').kind, FormulaErrorKind.unknownFunction);
      expect(error('summe(3; 30)').kind, FormulaErrorKind.argumentCount);
      expect(error('wenn(1; 2)').kind, FormulaErrorKind.argumentCount);
      expect(error('1 < 2 < 3').kind, FormulaErrorKind.unexpectedToken);
      expect(error('${'(' * 60}1${')' * 60}').kind, FormulaErrorKind.tooDeep);
    });
  });

  group('Formulas', () {
    final golf = MockCategoriesRepository.categories.firstWhere((c) => c.id == 'c-auto').trackers.single;

    test('Kurznamen aus Feldnamen, eindeutig, ohne eingebaute', () {
      expect(Formulas.keyOf('Kfz-Versicherung'), 'kfz_versicherung');
      expect(Formulas.keyOf('Menge (l oder kWh)'), 'menge_l_oder_kwh');
      expect(Formulas.keyOf('Größe'), 'groesse');
      expect(Formulas.keyOf('2. Zähler'), 'f_2_zaehler');
      const t = Tracker(
        id: 't',
        name: 'T',
        fields: [
          FieldDefinition(id: 'a', name: 'Preis', kind: FieldKind.currency),
          FieldDefinition(id: 'b', name: 'Preis', kind: FieldKind.currency),
          FieldDefinition(id: 'c', name: 'Verbrauch', kind: FieldKind.number),
        ],
      );
      expect(Formulas.keys(t), {'a': 'preis', 'b': 'preis_2', 'c': 'verbrauch_2'});
    });

    test('verfügbare Namen: Zahlenfelder, dazu verbrauch/tage/monate', () {
      expect(Formulas.available(golf), containsAll(['kilometerstand', 'tanken', 'liter', 'verbrauch', 'tage', 'monate']));
      expect(Formulas.available(golf, english: true), containsAll(['consumption', 'days', 'months']));
      expect(Formulas.available(golf), isNot(contains('verbrauch_2')));
    });

    test('rechnet je Eintrag: Verbrauch seit dem vorigen Stand, Werte von früher gelten weiter', () {
      final vars = Formulas.variablesByEntry(golf);
      final second = golf.entries.firstWhere((e) => e.id == 'e-golf-1');
      expect(vars[second.id]!['verbrauch'], 690);
      expect(vars[second.id]!['consumption'], 690);
      expect(vars[second.id]!['tage'], 21);
      expect(vars[second.id]!['kfz_versicherung'], 612);
      expect(vars['e-golf-p1']!.containsKey('tanken'), isFalse);
    });

    test('Momentwerte und Zählerstände gelten nicht weiter, Preise schon', () {
      const t = Tracker(
        id: 't',
        name: 'Heizöl',
        fields: [
          FieldDefinition(id: 'stand', name: 'Stand', kind: FieldKind.number, role: FieldRole.meterReading),
          FieldDefinition(id: 'liter', name: 'Liter', kind: FieldKind.number, role: FieldRole.snapshot),
          FieldDefinition(id: 'lp', name: 'Literpreis', kind: FieldKind.currency, role: FieldRole.unitPrice),
          FieldDefinition(id: 'kosten', name: 'Kosten', kind: FieldKind.formula, role: FieldRole.oneOffCost, formula: 'liter * literpreis'),
        ],
      );
      final tracker = t.copyWith(
        entries: [
          Entry(id: 'e1', date: DateTime.utc(2026, 3, 1), values: const {'stand': 100, 'liter': 40, 'lp': 1.8}),
          Entry(id: 'e2', date: DateTime.utc(2026, 3, 10), values: const {'lp': 1.9}),
        ],
      );
      final vars = Formulas.variablesByEntry(tracker)['e2']!;
      expect(vars['literpreis'], 1.9);
      expect(vars.containsKey('liter'), isFalse);
      expect(vars.containsKey('stand'), isFalse);
      expect(CostEngine(tracker, today: DateTime.utc(2026, 6, 1)).cost(DateTime.utc(2026, 3, 1), DateTime.utc(2026, 4, 1)), closeTo(72, 1e-9));
    });

    test('hängt Formel-Werte an die Einträge (l/100 km)', () {
      final applied = Formulas.apply(golf);
      final entry = applied.entries.firstWhere((e) => e.id == 'e-golf-1');
      expect(entry.values['f-golf-verbrauch'], closeTo(36 / 690 * 100, 0.05));
      expect(applied.entries.firstWhere((e) => e.id == 'e-golf-0').values.containsKey('f-golf-verbrauch'), isFalse);
    });

    test('Prüfung meldet unbekannte Namen mit Stelle', () {
      final check = Formulas.check('liter / strecke', golf);
      expect(check.isValid, isFalse);
      expect(check.error!.kind, FormulaErrorKind.unknownVariable);
      expect(check.error!.detail, 'strecke');
      expect(check.error!.position, 8);
      expect(Formulas.check('liter / verbrauch * 100', golf).isValid, isTrue);
      expect(Formulas.check('liter / consumption * 100', golf).isValid, isTrue);
    });

    test('summe und schnitt über die letzten Tage bis zum Eintrag', () {
      final tank = Formulas.apply(
        golf.copyWith(
          fields: [
            ...golf.fields,
            const FieldDefinition(id: 'f-monat', name: 'Monat', kind: FieldKind.formula, role: FieldRole.snapshot, formula: 'summe(tanken; 30)'),
            const FieldDefinition(id: 'f-schnitt', name: 'Schnitt', kind: FieldKind.formula, role: FieldRole.snapshot, formula: 'schnitt(liter; 365)'),
          ],
        ),
      );
      final entry = tank.entries.firstWhere((e) => e.id == 'e-golf-10');
      // Alle 21 Tage getankt: in 30 Tagen bis zum Eintrag zwei Tankfüllungen.
      final previous = golf.entries.firstWhere((e) => e.id == 'e-golf-9').values['f-golf-tanken']! as num;
      final own = entry.values['f-golf-tanken']! as num;
      expect(entry.values['f-monat'], closeTo(previous + own, 1e-9));
      expect(entry.values['f-schnitt'], inInclusiveRange(34.5, 40.5));
    });

    test('summe und schnitt über verbrauch und tage', () {
      const t = Tracker(
        id: 't',
        name: 'Auto',
        fields: [
          FieldDefinition(id: 'km', name: 'Kilometerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'km'),
          FieldDefinition(id: 'f1', name: 'Monat', kind: FieldKind.formula, role: FieldRole.snapshot, formula: 'summe(verbrauch; 30)'),
          FieldDefinition(id: 'f2', name: 'Abstand', kind: FieldKind.formula, role: FieldRole.snapshot, formula: 'schnitt(tage; 30)'),
          FieldDefinition(id: 'f3', name: 'Month', kind: FieldKind.formula, role: FieldRole.snapshot, formula: 'sum(consumption; 30)'),
        ],
      );
      final applied = Formulas.apply(
        t.copyWith(
          entries: [
            Entry(id: 'a', date: DateTime.utc(2026, 1, 1), values: const {'km': 1000}),
            Entry(id: 'b', date: DateTime.utc(2026, 1, 11), values: const {'km': 1500}),
            Entry(id: 'c', date: DateTime.utc(2026, 1, 21), values: const {'km': 1800}),
          ],
        ),
      );
      final last = applied.entries.firstWhere((e) => e.id == 'c');
      expect(last.values['f1'], 800);
      expect(last.values['f2'], 10);
      expect(last.values['f3'], 800);
    });

    test('Vorschau rechnet mit dem neuesten passenden Eintrag', () {
      expect(Formulas.preview(Formula.parse('liter * 2'), golf), isNotNull);
      expect(Formulas.preview(Formula.parse('liter * 2'), const Tracker(id: 't', name: 'leer')), isNull);
    });
  });

  group('CostEngine mit Formeln, Trend, Spanne und Abschlag', () {
    DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

    test('Formel mit Rolle einmaliger Betrag zählt als Kosten', () {
      const t = Tracker(
        id: 't',
        name: 'Taxi',
        fields: [
          FieldDefinition(id: 'km', name: 'Kilometer', kind: FieldKind.number, role: FieldRole.snapshot),
          FieldDefinition(id: 'kosten', name: 'Kosten', kind: FieldKind.formula, role: FieldRole.oneOffCost, formula: 'kilometer * 2'),
        ],
      );
      final tracker = t.copyWith(entries: [Entry(id: 'e', date: d(2026, 3, 1), values: const {'km': 12})]);
      expect(CostEngine(tracker, today: d(2026, 6, 1)).cost(d(2026, 1, 1), d(2026, 4, 1)), closeTo(24, 1e-9));
    });

    test('Trend: sinkender Verbrauch drückt die Prognose', () {
      final strom = MockCategoriesRepository.categories.first.trackers.single;
      final engine = CostEngine(strom, today: d(2026, 10, 22));
      expect(engine.trend, isNotNull);
      expect(engine.trend!, lessThan(1));
      expect(engine.consumption(d(2027, 1, 1), d(2028, 1, 1)), lessThan(engine.consumption(d(2025, 1, 1), d(2026, 1, 1))));
    });

    test('Kosten nach Herkunft ergeben zusammen die Kosten, Spanne > 0', () {
      final auto = MockCategoriesRepository.categories.firstWhere((c) => c.id == 'c-auto').trackers.single;
      final engine = CostEngine(auto, today: d(2026, 10, 22));
      final parts = engine.parts(d(2027, 1, 1), d(2028, 1, 1));
      expect(parts.total, closeTo(engine.costInYear(2027), 1e-6));
      expect(parts.fixed, closeTo(648 + 128, 1e-6));
      expect(parts.oneOff, greaterThan(0));
      expect(engine.uncertainty(parts), greaterThan(parts.oneOff * 0.2));
    });

    test('Abschläge sind keine Kosten, werden aber summiert', () {
      final strom = MockCategoriesRepository.categories.first.trackers.single;
      final engine = CostEngine(strom, today: d(2026, 10, 22));
      expect(engine.hasInstalment, isTrue);
      expect(engine.paid(d(2026, 1, 1), d(2027, 1, 1)), closeTo(12 * 85, 1e-6));
      final noInstalment = strom.copyWith(fields: [...strom.fields.where((f) => f.role != FieldRole.instalment)]);
      expect(CostEngine(noInstalment, today: d(2026, 10, 22)).costInYear(2026), closeTo(engine.costInYear(2026), 1e-6));
    });
  });

  group('Rechnungen', () {
    const meter = FieldDefinition(id: 'stand', name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'kWh');
    const price = FieldDefinition(id: 'ap', name: 'Arbeitspreis', kind: FieldKind.currency, role: FieldRole.unitPrice);

    test('Rechnung: verbrauch ist der Rechnungswert, tage die Länge des Zeitraums', () {
      final t = Tracker(
        id: 't',
        name: 'Strom',
        fields: const [meter, price],
        entries: [
          Entry(id: 'p', date: DateTime.utc(2026), values: const {'ap': 0.30}),
          Entry(id: 'b', date: DateTime.utc(2026, 9, 30), values: const {'stand': 508}, periodStart: DateTime.utc(2026, 4), periodEnd: DateTime.utc(2026, 9, 30)),
        ],
      );
      final vars = Formulas.variablesByEntry(t)['b']!;
      expect(vars['verbrauch'], 508);
      expect(vars['tage'], 183);
    });

    test('Stand nach Rechnung rechnet gegen den vorigen Stand', () {
      final t = Tracker(
        id: 't',
        name: 'Strom',
        fields: const [meter, price],
        entries: [
          Entry(id: 'r1', date: DateTime.utc(2026), values: const {'stand': 1000}),
          Entry(id: 'b', date: DateTime.utc(2026, 2, 28), values: const {'stand': 50}, periodStart: DateTime.utc(2026, 2), periodEnd: DateTime.utc(2026, 2, 28)),
          Entry(id: 'r2', date: DateTime.utc(2026, 3), values: const {'stand': 1300}),
        ],
      );
      final vars = Formulas.variablesByEntry(t)['r2']!;
      expect(vars['verbrauch'], 300);
      expect(vars['tage'], 59);
    });
  });
}
