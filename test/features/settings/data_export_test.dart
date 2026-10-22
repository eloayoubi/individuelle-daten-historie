import 'package:flutter_test/flutter_test.dart';
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
}
