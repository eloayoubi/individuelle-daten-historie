import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/category_templates.dart';
import 'package:kostenkurve/l10n/generated/app_localizations.dart';

void main() {
  final de = CategoryTemplates.all(lookupAppLocalizations(const Locale('de')));
  final en = CategoryTemplates.all(lookupAppLocalizations(const Locale('en')));

  test('acht Vorlagen mit eindeutigen Schlüsseln', () {
    expect(de, hasLength(8));
    expect({for (final t in de) t.key}, hasLength(8));
    expect([for (final t in de) t.key], containsAll(['strom', 'heizung', 'wasser', 'miete', 'auto', 'internet', 'versicherung', 'abos']));
  });

  test('jedes Feld passt zu seinem Zeitverhalten (wie der Datenbank-Check)', () {
    for (final template in de) {
      for (final tracker in template.trackers) {
        expect(tracker.name, isNotEmpty);
        expect(tracker.fields, isNotEmpty, reason: '${template.key}/${tracker.name}');
        for (final field in tracker.fields) {
          expect(field.kind.roles, contains(field.role), reason: '${template.key}: ${field.name}');
          expect(field.name.length, inInclusiveRange(1, 60));
          expect(field.unit?.length ?? 0, lessThanOrEqualTo(20));
        }
      }
    }
  });

  test('Kostenvorlagen rechnen: Zähler mit Preis, Verträge mit wiederkehrendem Betrag', () {
    Iterable<FieldRole> roles(String key) => de.firstWhere((t) => t.key == key).trackers.expand((t) => t.fields).map((f) => f.role);
    expect(roles('strom'), containsAll([FieldRole.meterReading, FieldRole.unitPrice, FieldRole.recurringCost, FieldRole.deadline]));
    expect(roles('miete'), containsAll([FieldRole.recurringCost, FieldRole.oneOffCost]));
    expect(roles('abos'), contains(FieldRole.recurringCost));
    final gas = de.firstWhere((t) => t.key == 'heizung').trackers.single.fields.first;
    expect((gas.unit, gas.consumptionUnit, gas.factor), ('m³', 'kWh', CategoryTemplates.gasFactor));
  });

  test('Deutsch und Englisch haben dieselbe Struktur', () {
    expect([for (final t in en) t.key], [for (final t in de) t.key]);
    for (final (i, t) in de.indexed) {
      expect([for (final tr in en[i].trackers) tr.fields.length], [for (final tr in t.trackers) tr.fields.length]);
      expect(en[i].name, isNot(isEmpty));
    }
    expect(en.first.name, 'Electricity');
  });
}
