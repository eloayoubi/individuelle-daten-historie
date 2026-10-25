import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/models/tracking.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

const meter = FieldDefinition(id: 'stand', name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'kWh');
const price = FieldDefinition(id: 'ap', name: 'Arbeitspreis', kind: FieldKind.currency, role: FieldRole.unitPrice);
const base = FieldDefinition(id: 'gp', name: 'Grundpreis', kind: FieldKind.currency, role: FieldRole.recurringCost);
const km = FieldDefinition(id: 'stand', name: 'Kilometerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'km');
const tank = FieldDefinition(id: 'tank', name: 'Tanken', kind: FieldKind.currency, role: FieldRole.oneOffCost);

Entry reading(DateTime date, num value) => Entry(id: 'r$date', date: date, values: {'stand': value});

Entry bill(DateTime from, DateTime to, num value) => Entry(id: 'b$to', date: to, values: {'stand': value}, periodStart: from, periodEnd: to);

void main() {
  group('Versorgungszähler', () {
    test('Zähler mit Arbeitspreis ist Versorgungszähler, Auto nicht', () {
      expect(const Tracker(id: 't', name: 'Strom', fields: [meter, price]).isUtilityMeter, isTrue);
      expect(const Tracker(id: 't', name: 'Auto', fields: [km, tank]).isUtilityMeter, isFalse);
      expect(const Tracker(id: 't', name: 'Preis', fields: [price]).isUtilityMeter, isFalse);
    });

    test('Rechnung: Zeitraum und Wert im Zählerfeld', () {
      const strom = Tracker(id: 't', name: 'Strom', fields: [meter, price]);
      final b = bill(d(2026, 4, 1), d(2026, 9, 30), 508);
      expect(strom.isBill(b), isTrue);
      expect(strom.isReading(b), isFalse);
      final r = reading(d(2026, 9, 30), 508);
      expect(strom.isBill(r), isFalse);
      expect(strom.isReading(r), isTrue);
      const auto = Tracker(id: 't', name: 'Auto', fields: [km, tank]);
      expect(auto.isBill(b), isFalse);
      expect(auto.isReading(b), isTrue);
    });

    test('Preisänderung trägt nur Preise', () {
      const strom = Tracker(id: 't', name: 'Strom', fields: [meter, price, base]);
      expect(strom.isPriceChange(Entry(id: 'p', date: d(2026, 1, 1), values: const {'ap': 0.32, 'gp': 12})), isTrue);
      expect(strom.isPriceChange(Entry(id: 'p', date: d(2026, 1, 1), values: const {'ap': 0.32, 'stand': 100})), isFalse);
      expect(strom.isPriceChange(Entry(id: 'p', date: d(2026, 1, 1))), isFalse);
      expect(strom.rateFields, [price, base]);
    });

    test('readsFromBills folgt dem neuesten Zählereintrag', () {
      final first = [reading(d(2026, 1, 1), 1000), bill(d(2026, 1, 2), d(2026, 6, 30), 900)];
      expect(Tracker(id: 't', name: 'Strom', fields: const [meter, price], entries: first).readsFromBills, isTrue);
      expect(Tracker(id: 't', name: 'Strom', fields: const [meter, price], entries: [...first, reading(d(2026, 7, 15), 2000)]).readsFromBills, isFalse);
      expect(const Tracker(id: 't', name: 'Strom', fields: [meter, price]).readsFromBills, isFalse);
    });
  });
}
