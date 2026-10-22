import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/models/tracking.dart';
import 'package:kostenkurve/core/utils/cost_engine.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

const meter = FieldDefinition(id: 'stand', name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'kWh');
const price = FieldDefinition(id: 'ap', name: 'Arbeitspreis', kind: FieldKind.currency, role: FieldRole.unitPrice);

Entry reading(DateTime date, num value, {bool change = false}) => Entry(id: 'r$date', date: date, values: {'stand': value}, meterChange: change);

void main() {
  group('Zählerstände', () {
    test('verteilt den Verbrauch linear über den Jahreswechsel', () {
      // 61 Tage, 610 kWh → 10 kWh pro Tag.
      final t = Tracker(id: 't', name: 'Strom', fields: const [meter], entries: [reading(d(2025, 12, 1), 1000), reading(d(2026, 1, 31), 1610)]);
      final engine = CostEngine(t, today: d(2026, 2, 1));
      expect(engine.consumption(d(2026, 1, 1), d(2026, 1, 31)), closeTo(300, 1e-9));
      expect(engine.consumption(d(2025, 12, 1), d(2026, 1, 1)), closeTo(310, 1e-9));
    });

    test('zählt vor dem ersten Stand nichts und rechnet danach mit dem Durchschnitt weiter', () {
      final t = Tracker(id: 't', name: 'Strom', fields: const [meter], entries: [reading(d(2026, 1, 1), 0), reading(d(2026, 1, 11), 100)]);
      final engine = CostEngine(t, today: d(2026, 1, 21));
      expect(engine.consumption(d(2025, 12, 1), d(2026, 1, 1)), 0);
      expect(engine.consumption(d(2026, 1, 11), d(2026, 1, 21)), closeTo(100, 1e-9));
      expect(engine.lastReading, d(2026, 1, 11));
    });

    test('übernimmt für die Zukunft die Saison des Vorjahres', () {
      // Januar 20 pro Tag, Februar bis Dezember 5 pro Tag; letzter Stand am 1. Februar 2026.
      final t = Tracker(
        id: 't',
        name: 'Gas',
        fields: const [meter],
        entries: [reading(d(2025, 1, 1), 0), reading(d(2025, 2, 1), 620), reading(d(2026, 1, 1), 620 + 334 * 5), reading(d(2026, 2, 1), 620 + 334 * 5 + 620)],
      );
      final engine = CostEngine(t, today: d(2026, 2, 1));
      expect(engine.consumption(d(2026, 3, 1), d(2026, 4, 1)), closeTo(31 * 5, 1e-9));
      expect(engine.consumption(d(2027, 1, 1), d(2027, 2, 1)), closeTo(31 * 20, 1e-9));
    });

    test('rechnet mit dem Umrechnungsfaktor (Gas: m³ → kWh)', () {
      const gas = FieldDefinition(id: 'stand', name: 'Gas', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'm³', consumptionUnit: 'kWh', factor: 10);
      final t = Tracker(id: 't', name: 'Gas', fields: const [gas], entries: [reading(d(2026, 1, 1), 100), reading(d(2026, 1, 11), 110)]);
      expect(CostEngine(t, today: d(2026, 1, 11)).consumption(d(2026, 1, 1), d(2026, 1, 11)), closeTo(100, 1e-9));
      expect(gas.usageUnit, 'kWh');
    });

    test('füllt den unbekannten Abschnitt bei einem Zählerwechsel mit dem Nachbarn', () {
      final t = Tracker(
        id: 't',
        name: 'Strom',
        fields: const [meter],
        entries: [
          reading(d(2026, 1, 1), 1000),
          reading(d(2026, 2, 1), 1310), // 31 Tage, 10 pro Tag
          reading(d(2026, 3, 1), 5, change: true), // neuer Zähler
          reading(d(2026, 4, 1), 315),
        ],
      );
      final engine = CostEngine(t, today: d(2026, 4, 1));
      expect(engine.consumption(d(2026, 2, 1), d(2026, 3, 1)), closeTo(280, 1e-9));
      expect(engine.consumption(d(2026, 3, 1), d(2026, 4, 1)), closeTo(310, 1e-9));
    });
  });

  group('Kosten', () {
    test('Arbeitspreis gilt ab seinem Datum', () {
      final t = Tracker(
        id: 't',
        name: 'Strom',
        fields: const [meter, price],
        entries: [
          Entry(id: 'p1', date: d(2025, 1, 1), values: const {'ap': 0.30}),
          Entry(id: 'p2', date: d(2026, 1, 15), values: const {'ap': 0.40}),
          reading(d(2025, 12, 1), 1000),
          reading(d(2026, 1, 31), 1610),
        ],
      );
      // 14 Tage × 10 kWh × 0,30 € + 16 Tage × 10 kWh × 0,40 €
      expect(CostEngine(t, today: d(2026, 2, 1)).cost(d(2026, 1, 1), d(2026, 1, 31)), closeTo(42 + 64, 1e-9));
    });

    test('wiederkehrende Beträge ergeben ganze Monate und Jahre', () {
      final t = Tracker(
        id: 't',
        name: 'Wohnung',
        fields: const [
          FieldDefinition(id: 'miete', name: 'Miete', kind: FieldKind.currency, role: FieldRole.recurringCost),
          FieldDefinition(id: 'vers', name: 'Versicherung', kind: FieldKind.currency, role: FieldRole.recurringCost, intervalMonths: 12),
        ],
        entries: [
          Entry(id: 'm', date: d(2026, 1, 1), values: const {'miete': 900, 'vers': 120}),
          Entry(id: 'm2', date: d(2026, 7, 1), values: const {'miete': 950}),
        ],
      );
      final engine = CostEngine(t, today: d(2026, 3, 1));
      expect(engine.cost(d(2026, 1, 1), d(2026, 3, 1)), closeTo(2 * 900 + 2 * 10, 1e-9));
      // Erhöhung im Voraus eingetragen: fließt in die Prognose ein.
      expect(engine.costInYear(2026), closeTo(6 * 900 + 6 * 950 + 120, 1e-9));
      expect(engine.costInYear(2025), 0);
    });

    test('einmalige Beträge zählen am Tag, die Zukunft mit dem Tagesdurchschnitt', () {
      final t = Tracker(
        id: 't',
        name: 'Auto',
        fields: const [FieldDefinition(id: 'tanken', name: 'Tanken', kind: FieldKind.currency, role: FieldRole.oneOffCost)],
        entries: [
          Entry(id: 'a', date: d(2025, 9, 1), values: const {'tanken': 265}),
          Entry(id: 'b', date: d(2026, 3, 10), values: const {'tanken': 100}),
        ],
      );
      final engine = CostEngine(t, today: d(2026, 7, 1));
      expect(engine.cost(d(2026, 3, 1), d(2026, 4, 1)), closeTo(100, 1e-9));
      // 365 € in den letzten 365 Tagen → 1 € pro Tag.
      expect(engine.cost(d(2026, 7, 1), d(2026, 7, 11)), closeTo(10, 1e-9));
    });
  });
}
