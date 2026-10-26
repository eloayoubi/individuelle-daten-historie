import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/models/tracking.dart';
import 'package:kostenkurve/core/utils/cost_engine.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

const meter = FieldDefinition(id: 'stand', name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'kWh');
const price = FieldDefinition(id: 'ap', name: 'Arbeitspreis', kind: FieldKind.currency, role: FieldRole.unitPrice);

Entry reading(DateTime date, num value, {bool change = false}) => Entry(id: 'r$date', date: date, values: {'stand': value}, meterChange: change);

Entry bill(DateTime from, DateTime to, num value) => Entry(id: 'b$from$to', date: to, values: {'stand': value}, periodStart: from, periodEnd: to);

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

    test('Zählerwechsel an einem Tag: Endstand des alten und Anfangsstand des neuen Zählers', () {
      final entries = [
        reading(d(2026, 1, 1), 4000),
        Entry(id: 'alt', date: d(2026, 6, 1), values: const {'stand': 5000}),
        Entry(id: 'neu', date: d(2026, 6, 1), values: const {'stand': 0}, meterChange: true),
        reading(d(2026, 7, 1), 300),
      ];
      for (final order in [entries, entries.reversed.toList()]) {
        final engine = CostEngine(Tracker(id: 't', name: 'Strom', fields: const [meter], entries: order), today: d(2026, 7, 1));
        expect(engine.consumption(d(2026, 1, 1), d(2026, 6, 1)), closeTo(1000, 1e-9));
        expect(engine.consumption(d(2026, 6, 1), d(2026, 7, 1)), closeTo(300, 1e-9));
      }
    });

    test('füllt einen Zählerwechsel ohne Endstand je zur Hälfte mit den Nachbarn', () {
      final t = Tracker(
        id: 't',
        name: 'Strom',
        fields: const [meter],
        entries: [
          reading(d(2026, 1, 1), 0),
          reading(d(2026, 1, 11), 100), // 10 pro Tag
          reading(d(2026, 1, 21), 0, change: true), // Verbrauch 11.–20. unbekannt
          reading(d(2026, 1, 31), 200), // 20 pro Tag
        ],
      );
      final engine = CostEngine(t, today: d(2026, 1, 31));
      expect(engine.consumption(d(2026, 1, 11), d(2026, 1, 16)), closeTo(50, 1e-9));
      expect(engine.consumption(d(2026, 1, 16), d(2026, 1, 21)), closeTo(100, 1e-9));
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

    test('zählen voll für den Monat, in dem sie eingetragen werden – auch bis heute', () {
      final t = Tracker(
        id: 't',
        name: 'Wohnung',
        fields: const [FieldDefinition(id: 'miete', name: 'Miete', kind: FieldKind.currency, role: FieldRole.recurringCost)],
        entries: [
          Entry(id: 'm', date: d(2026, 10, 26), values: const {'miete': 1400}),
          // Zwei Änderungen in einem Monat: die letzte gilt für den ganzen Monat.
          Entry(id: 'm2', date: d(2026, 12, 10), values: const {'miete': 1450}),
          Entry(id: 'm3', date: d(2026, 12, 20), values: const {'miete': 1500}),
        ],
      );
      final engine = CostEngine(t, today: d(2026, 10, 26));
      expect(engine.cost(d(2026, 10, 1), d(2026, 10, 27)), closeTo(1400, 1e-9));
      expect(engine.costInMonth(2026, 9), 0);
      expect(engine.costInMonth(2026, 12), closeTo(1500, 1e-9));
      expect(engine.costInYear(2026), closeTo(2 * 1400 + 1500, 1e-9));
    });

    test('einmalige Beträge zählen am Tag, ab morgen mit dem Tagesdurchschnitt', () {
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
      expect(engine.cost(d(2026, 7, 2), d(2026, 7, 12)), closeTo(10, 1e-9));
    });

    test('heute eingetragene Beträge zählen bis heute und in die Prognose', () {
      final t = Tracker(
        id: 't',
        name: 'Spiele',
        fields: const [FieldDefinition(id: 'preis', name: 'Preis', kind: FieldKind.currency, role: FieldRole.oneOffCost)],
        entries: [
          Entry(id: 'a', date: d(2026, 10, 22), values: const {'preis': 80}),
          Entry(id: 'b', date: d(2026, 10, 22), values: const {'preis': 20}),
        ],
      );
      final engine = CostEngine(t, today: d(2026, 10, 22));
      expect(engine.cost(d(2026, 1, 1), d(2026, 10, 23)), closeTo(100, 1e-9));
      expect(engine.costInYear(2027), closeTo(100, 1e-9));
    });

    test('künftig datierte einmalige Beträge zählen an ihrem Tag zusätzlich zum Durchschnitt', () {
      final t = Tracker(
        id: 't',
        name: 'Auto',
        fields: const [FieldDefinition(id: 'tanken', name: 'Tanken', kind: FieldKind.currency, role: FieldRole.oneOffCost)],
        entries: [
          Entry(id: 'a', date: d(2026, 3, 10), values: const {'tanken': 365}),
          Entry(id: 'b', date: d(2026, 8, 1), values: const {'tanken': 50}),
        ],
      );
      final engine = CostEngine(t, today: d(2026, 7, 1));
      expect(engine.cost(d(2026, 8, 1), d(2026, 8, 2)), closeTo(1 + 50, 1e-9));
      expect(engine.cost(d(2026, 8, 2), d(2026, 8, 3)), closeTo(1, 1e-9));
    });

    test('Prognose einmaliger Beträge mit Zeitraum nach dem Zahltag, nicht nach dem Zeitraum', () {
      final t = Tracker(
        id: 't',
        name: 'Versicherung',
        fields: const [FieldDefinition(id: 'beitrag', name: 'Beitrag', kind: FieldKind.currency, role: FieldRole.oneOffCost)],
        entries: [Entry(id: 'a', date: d(2026, 1, 1), values: const {'beitrag': 1200}, periodStart: d(2026, 1, 1), periodEnd: d(2026, 12, 31))],
      );
      final engine = CostEngine(t, today: d(2026, 10, 25));
      expect(engine.costInYear(2027), closeTo(1200 / 365 * 365, 1e-9));
      expect(engine.costInYear(2026), closeTo(1200, 1e-9));
      // Bis heute nach dem Zeitraum verteilt.
      expect(engine.cost(d(2026, 1, 1), d(2026, 2, 1)), closeTo(1200 / 365 * 31, 1e-9));
    });
  });

  group('Rechnungen', () {
    Tracker strom(List<Entry> entries) => Tracker(id: 't', name: 'Strom', fields: const [meter, price], entries: entries);

    test('verteilt den Verbrauch der Rechnung auf ihre Tage', () {
      // 01.04.–30.09.: 183 Tage.
      final engine = CostEngine(strom([bill(d(2026, 4, 1), d(2026, 9, 30), 508)]), today: d(2026, 10, 25));
      expect(engine.consumption(d(2026, 4, 1), d(2026, 10, 1)), closeTo(508, 1e-9));
      expect(engine.consumption(d(2026, 4, 1), d(2026, 5, 1)), closeTo(508 / 183 * 30, 1e-9));
      expect(engine.hasMeter, isTrue);
      expect(engine.lastReading, d(2026, 10, 1));
    });

    test('teilt eine Rechnung über den Jahreswechsel tagesgenau', () {
      // 92 Tage 2025, 90 Tage 2026 – 10 pro Tag.
      final engine = CostEngine(strom([bill(d(2025, 10, 1), d(2026, 3, 31), 1820)]), today: d(2026, 4, 1));
      expect(engine.consumption(d(2025, 10, 1), d(2026, 1, 1)), closeTo(920, 1e-9));
      expect(engine.consumption(d(2026, 1, 1), d(2026, 4, 1)), closeTo(900, 1e-9));
    });

    test('Rechnung über einen Tag', () {
      final engine = CostEngine(strom([bill(d(2026, 5, 10), d(2026, 5, 10), 12)]), today: d(2026, 5, 11));
      expect(engine.consumption(d(2026, 5, 10), d(2026, 5, 11)), closeTo(12, 1e-9));
    });

    test('füllt die Lücke zwischen zwei Rechnungen je zur Hälfte mit den Nachbarn', () {
      final engine = CostEngine(
        strom([bill(d(2026, 1, 1), d(2026, 1, 10), 100), bill(d(2026, 1, 21), d(2026, 1, 30), 200)]),
        today: d(2026, 2, 1),
      );
      // 5 Tage × 10 aus der vorigen, 5 Tage × 20 aus der nächsten Rechnung.
      expect(engine.consumption(d(2026, 1, 11), d(2026, 1, 16)), closeTo(50, 1e-9));
      expect(engine.consumption(d(2026, 1, 16), d(2026, 1, 21)), closeTo(100, 1e-9));
    });

    test('Lücke mit ungerader Länge: der mittlere Tag zählt zur vorigen Rechnung', () {
      final engine = CostEngine(
        strom([bill(d(2026, 1, 1), d(2026, 1, 10), 100), bill(d(2026, 1, 14), d(2026, 1, 23), 200)]),
        today: d(2026, 2, 1),
      );
      expect(engine.consumption(d(2026, 1, 11), d(2026, 1, 14)), closeTo(10 + 10 + 20, 1e-9));
    });

    test('Rechnung hat Vorrang vor Zählerständen', () {
      // Stände: 60 Tage, 600 kWh. Rechnung für Februar: 56 kWh; der Rest (544) verteilt sich auf
      // die übrigen 32 Tage, so stimmt die Summe zwischen den Ständen.
      final engine = CostEngine(
        strom([reading(d(2026, 1, 1), 0), reading(d(2026, 3, 2), 600), bill(d(2026, 2, 1), d(2026, 2, 28), 56)]),
        today: d(2026, 3, 2),
      );
      expect(engine.consumption(d(2026, 2, 1), d(2026, 3, 1)), closeTo(56, 1e-9));
      expect(engine.consumption(d(2026, 1, 1), d(2026, 2, 1)), closeTo(544 / 32 * 31, 1e-9));
      expect(engine.consumption(d(2026, 1, 1), d(2026, 3, 2)), closeTo(600, 1e-9));
    });

    test('Rechnung mit mehr Verbrauch als zwischen den Ständen: übrige Tage zählen nichts', () {
      final engine = CostEngine(
        strom([reading(d(2026, 1, 1), 0), reading(d(2026, 3, 2), 100), bill(d(2026, 2, 1), d(2026, 2, 28), 280)]),
        today: d(2026, 3, 2),
      );
      expect(engine.consumption(d(2026, 1, 1), d(2026, 2, 1)), 0);
      expect(engine.consumption(d(2026, 2, 1), d(2026, 3, 1)), closeTo(280, 1e-9));
    });

    test('bei überlappenden Rechnungen gilt die später endende', () {
      final engine = CostEngine(
        strom([bill(d(2026, 1, 16), d(2026, 2, 14), 60), bill(d(2026, 1, 1), d(2026, 1, 31), 310)]),
        today: d(2026, 2, 15),
      );
      expect(engine.consumption(d(2026, 1, 16), d(2026, 2, 1)), closeTo(32, 1e-9));
    });

    test('Rechnung beim Gas ohne Umrechnungsfaktor', () {
      const gas = FieldDefinition(id: 'stand', name: 'Gas', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'm³', consumptionUnit: 'kWh', factor: 10);
      final t = Tracker(id: 't', name: 'Gas', fields: const [gas, price], entries: [bill(d(2026, 1, 1), d(2026, 1, 10), 1000)]);
      expect(CostEngine(t, today: d(2026, 1, 11)).consumption(d(2026, 1, 1), d(2026, 1, 11)), closeTo(1000, 1e-9));
    });

    test('Prognose nach der letzten Rechnung mit dem Schnitt', () {
      final engine = CostEngine(strom([bill(d(2026, 4, 1), d(2026, 9, 30), 508)]), today: d(2026, 10, 25));
      expect(engine.consumption(d(2027, 1, 1), d(2027, 1, 2)), closeTo(508 / 183, 1e-9));
    });

    test('Preisänderung mitten in der Rechnung', () {
      final engine = CostEngine(
        strom([
          bill(d(2026, 1, 1), d(2026, 1, 10), 100),
          Entry(id: 'p1', date: d(2025, 1, 1), values: const {'ap': 0.30}),
          Entry(id: 'p2', date: d(2026, 1, 6), values: const {'ap': 0.40}),
        ]),
        today: d(2026, 1, 11),
      );
      expect(engine.cost(d(2026, 1, 1), d(2026, 1, 11)), closeTo(50 * 0.30 + 50 * 0.40, 1e-9));
    });

    test('Auto: Stand mit Zeitraum bleibt Stand', () {
      const km = FieldDefinition(id: 'stand', name: 'Kilometerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'km');
      const tank = FieldDefinition(id: 'tank', name: 'Tanken', kind: FieldKind.currency, role: FieldRole.oneOffCost);
      final t = Tracker(
        id: 't',
        name: 'Auto',
        fields: const [km, tank],
        entries: [
          reading(d(2026, 1, 1), 1000),
          Entry(id: 'r2', date: d(2026, 1, 11), values: const {'stand': 1500, 'tank': 60}, periodStart: d(2025, 12, 1), periodEnd: d(2025, 12, 31)),
        ],
      );
      expect(CostEngine(t, today: d(2026, 1, 11)).consumption(d(2026, 1, 1), d(2026, 1, 11)), closeTo(500, 1e-9));
    });
  });
}
