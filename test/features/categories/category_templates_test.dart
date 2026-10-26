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
    expect(roles('versicherung'), contains(FieldRole.recurringCost));
    final gas = de.firstWhere((t) => t.key == 'heizung').trackers.single.fields.first;
    expect((gas.unit, gas.consumptionUnit, gas.factor), ('m³', 'kWh', CategoryTemplates.gasFactor));
  });

  test('Abos starten leer, jedes Abo entsteht aus dem Bauplan mit Preis, Kündbar bis und Art', () {
    final abos = de.firstWhere((t) => t.key == 'abos');
    expect(abos.trackers, isEmpty);
    final item = abos.item!;
    expect(item.add, 'Abo hinzufügen');
    expect(item.groupNames, containsAllInOrder(['Streaming', 'Musik & Hörbücher', 'Fitness & Sport']));
    expect(item.groups.first.suggestions, containsAll(['Netflix', 'Disney+', 'YouTube Premium']));
    expect(item.groups.expand((g) => g.suggestions), contains('Fitnessstudio'));

    final yearly = item.draftFields(interval: 12);
    expect([for (final f in yearly) (f.kind, f.role)], [
      (FieldKind.currency, FieldRole.recurringCost),
      (FieldKind.date, FieldRole.deadline),
      (FieldKind.choice, FieldRole.info),
    ]);
    expect((yearly.first.intervalMonths, yearly.first.unit), (12, '€/Jahr'));
    expect(item.draftFields(interval: 1).first.unit, '€/Monat');
    expect(yearly.last.choices, item.groupNames);
    for (final f in yearly) {
      expect(f.kind.roles, contains(f.role), reason: f.name);
    }
    expect(CategoryTemplates.item(lookupAppLocalizations(const Locale('de')), 'abos'), item);
  });

  test('Versicherungen: Bauplan ohne Art, Beitrag jährlich; andere Vorlagen ohne Bauplan', () {
    final l = lookupAppLocalizations(const Locale('de'));
    final item = CategoryTemplates.item(l, 'versicherung')!;
    expect(item.defaultInterval, 12);
    expect(item.groupNames, isEmpty);
    expect([for (final f in item.draftFields(interval: 12)) f.role], [FieldRole.recurringCost, FieldRole.info, FieldRole.deadline]);
    expect(CategoryTemplates.item(l, 'strom'), isNull);
    expect(CategoryTemplates.item(l, null), isNull);
  });

  test('Deutsch und Englisch haben dieselbe Struktur', () {
    expect([for (final t in en) t.key], [for (final t in de) t.key]);
    for (final (i, t) in de.indexed) {
      expect([for (final tr in en[i].trackers) tr.fields.length], [for (final tr in t.trackers) tr.fields.length]);
      expect(en[i].name, isNot(isEmpty));
      expect(en[i].item?.draftFields(interval: 1).length, t.item?.draftFields(interval: 1).length);
      expect([for (final g in en[i].item?.groups ?? <ItemGroup>[]) g.suggestions.isNotEmpty], [for (final g in t.item?.groups ?? <ItemGroup>[]) g.suggestions.isNotEmpty]);
    }
    expect(en.first.name, 'Electricity');
  });
}
