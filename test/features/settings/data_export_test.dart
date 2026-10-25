import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/settings/data/data_export.dart';

void main() {
  final categories = MockCategoriesRepository.categories;
  const header = ['Kategorie', 'Tracker', 'Datum', 'Feld', 'Wert', 'Einheit', 'Notiz', 'Von', 'Bis'];
  const de = ExportLabels(header: header, yes: 'Ja', no: 'Nein');

  test('CSV: Semikolon und Dezimalkomma auf Deutsch, eine Zeile je Wert', () {
    final lines = DataExport.csv(categories, de).split('\r\n');
    expect(lines.first, header.join(';'));
    final miete = lines.firstWhere((l) => l.contains('Nebenkostenabrechnung 2024'));
    expect(miete, 'Miete & Nebenkosten;Wohnung;2025-05-20;Nachzahlung / Guthaben;148;€;Nebenkostenabrechnung 2024;2024-01-01;2024-12-31');
    final price = lines.firstWhere((l) => l.startsWith('Wasser;') && l.contains('4,62'));
    expect(price, contains(';4,62;'));
    final values = categories.fold<int>(0, (sum, c) => sum + c.trackers.fold(0, (s, t) => s + t.entries.fold(0, (n, e) => n + e.values.length)));
    expect(lines.where((l) => l.isNotEmpty).length, values + 1);
  });

  test('CSV: Englisch mit Komma, Anführungszeichen wo nötig', () {
    const en = ExportLabels(header: header, yes: 'Yes', no: 'No', decimalSeparator: '.');
    final csv = DataExport.csv(categories, en);
    expect(csv, contains(',4.62,'));
    expect(csv.split('\r\n').first, header.join(','));
  });

  test('JSON: Werte nach Feldnamen, Zeitraum, Rolle', () {
    final json = DataExport.json(categories, DateTime.utc(2026, 10, 22, 12));
    expect(json['app'], 'Kostenkurve');
    expect(json['exportedAt'], '2026-10-22T12:00:00.000Z');
    final miete = (json['categories']! as List).cast<Map<String, Object?>>().firstWhere((c) => c['name'] == 'Miete & Nebenkosten');
    final tracker = (miete['trackers']! as List).single as Map<String, Object?>;
    final entries = (tracker['entries']! as List).cast<Map<String, Object?>>();
    final settlement = entries.firstWhere((e) => e['note'] == 'Nebenkostenabrechnung 2024');
    expect(settlement['values'], {'Nachzahlung / Guthaben': 148});
    expect(settlement['period'], {'from': '2024-01-01', 'to': '2024-12-31'});
    expect(miete['sharedWith'], [
      {'name': 'Anna', 'role': 'editor'},
    ]);
  });

  test('Rechnung: Verbrauch in der Verbrauchseinheit, im JSON als Rechnung markiert', () {
    const meter = FieldDefinition(id: 'stand', name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'm³', consumptionUnit: 'kWh', factor: 10);
    const price = FieldDefinition(id: 'ap', name: 'Arbeitspreis', kind: FieldKind.currency, role: FieldRole.unitPrice, unit: '€/kWh');
    final gas = Category(
      id: 'c',
      name: 'Heizung',
      icon: CategoryIcon.flame,
      swatch: CategorySwatch.red,
      trackers: [
        Tracker(
          id: 't',
          name: 'Gas',
          fields: const [meter, price],
          entries: [Entry(id: 'b', date: DateTime.utc(2026, 9, 30), values: const {'stand': 9000}, periodStart: DateTime.utc(2025, 10), periodEnd: DateTime.utc(2026, 9, 30))],
        ),
      ],
    );
    const labels = ExportLabels(header: header, yes: 'Ja', no: 'Nein', consumption: 'Verbrauch');
    final line = DataExport.csv([gas], labels).split('\r\n')[1];
    expect(line, 'Heizung;Gas;2026-09-30;Verbrauch;9000;kWh;;2025-10-01;2026-09-30');
    final json = DataExport.json([gas], DateTime.utc(2026, 10, 22));
    final entry = ((((json['categories']! as List).single as Map)['trackers'] as List).single as Map)['entries'] as List;
    expect((entry.single as Map)['bill'], isTrue);
  });
}
