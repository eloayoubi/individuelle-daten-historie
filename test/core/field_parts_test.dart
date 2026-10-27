import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/models/tracking_codec.dart';
import 'package:kostenkurve/core/utils/cost_engine.dart';
import 'package:kostenkurve/features/categories/cubit/field_editor_cubit.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/category_templates.dart';
import 'package:kostenkurve/features/categories/data/memory_categories_repository.dart';
import 'package:kostenkurve/features/entries/cubit/entry_form_cubit.dart';
import 'package:kostenkurve/features/insights/data/what_if.dart';
import 'package:kostenkurve/l10n/generated/app_localizations.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

const warm = FieldDefinition(id: 'warm', name: 'Warmmiete', kind: FieldKind.currency, role: FieldRole.recurringCost, unit: '€/Monat');
const kalt = FieldDefinition(id: 'kalt', name: 'Kaltmiete', kind: FieldKind.currency, role: FieldRole.recurringCost, unit: '€/Monat', partOf: 'warm');
const betrieb = FieldDefinition(id: 'bk', name: 'Betriebskosten', kind: FieldKind.currency, role: FieldRole.recurringCost, unit: '€/Monat', partOf: 'warm');
const heiz = FieldDefinition(id: 'hk', name: 'Heizkosten', kind: FieldKind.currency, role: FieldRole.recurringCost, unit: '€/Monat', partOf: 'warm');
const settlement = FieldDefinition(id: 'nz', name: 'Nachzahlung / Guthaben', kind: FieldKind.currency, role: FieldRole.oneOffCost, unit: '€');

Tracker wohnung({List<FieldDefinition> fields = const [warm, kalt, betrieb, heiz, settlement], List<Entry> entries = const []}) =>
    Tracker(id: 't-wohnung', name: 'Wohnung', fields: fields, entries: entries);

void main() {
  group('Kosten', () {
    test('nur die Warmmiete zählt, die Aufteilung nicht extra', () {
      final t = wohnung(
        entries: [
          Entry(id: 'e1', date: d(2026, 1, 1), values: const {'warm': 1100, 'kalt': 800, 'bk': 180, 'hk': 120}),
        ],
      );
      final engine = CostEngine(t, today: d(2026, 6, 1));
      expect(engine.costInMonth(2026, 3), closeTo(1100, 1e-6));
    });

    test('ohne Gesamtfeld (archiviert) zählt ein Teilbetrag selbst', () {
      final t = wohnung(
        fields: const [kalt, heiz],
        entries: [
          Entry(id: 'e1', date: d(2026, 1, 1), values: const {'kalt': 800, 'hk': 120}),
        ],
      );
      expect(t.isPart(kalt), isFalse);
      expect(CostEngine(t, today: d(2026, 6, 1)).costInMonth(2026, 3), closeTo(920, 1e-6));
    });

    test('Teilbeträge lassen sich nicht durchspielen, der aktuelle Betrag ist die Warmmiete', () {
      final t = wohnung(
        fields: const [kalt, warm, heiz],
        entries: [
          Entry(id: 'e1', date: d(2026, 1, 1), values: const {'warm': 1100, 'kalt': 800}),
        ],
      );
      expect(WhatIf.priceFields(t), [warm]);
      expect(t.currentAmount(d(2026, 6, 1))?.$1, warm);
      expect(t.partsOf('warm'), [kalt, heiz]);
    });
  });

  group('Vorlage', () {
    final miete = CategoryTemplates.all(lookupAppLocalizations(const Locale('de'))).firstWhere((t) => t.key == 'miete').trackers.single;

    test('Warmmiete vorn, Kaltmiete, Betriebs- und Heizkosten sind ihre Teile', () {
      expect([for (final f in miete.fields) f.name], ['Warmmiete', 'Kaltmiete', 'Betriebskosten', 'Heizkosten', 'Nachzahlung / Guthaben', 'Vermieter']);
      expect(miete.parts, {1: 0, 2: 0, 3: 0});
    });

    test('abgewählte Felder: Positionen rücken nach, Teile ohne Gesamtfeld zählen selbst', () {
      final ohneKalt = miete.where((i) => i != 1);
      expect(ohneKalt.fields.first.name, 'Warmmiete');
      expect(ohneKalt.parts, {1: 0, 2: 0});
      expect(miete.where((i) => i != 0).parts, isEmpty);
    });

    test('angelegt bekommen die Teile die Id der Warmmiete', () async {
      var n = 0;
      final repo = MemoryCategoriesRepository(ids: (kind) => '$kind${n++}');
      final id = await repo.createCategory(CategoryDraft(name: 'Miete', icon: CategoryIcon.house, swatch: CategorySwatch.brown, trackers: [miete]));
      final fields = (await repo.loadCategory(id))!.trackers.single.fields;
      expect([for (final f in fields) f.partOf], [null, fields.first.id, fields.first.id, fields.first.id, null, null]);
    });

    test('vorhandener Tracker als Vorlage (Umzug): Teile per Position', () {
      expect(TrackerDraft.of(wohnung()).parts, {1: 0, 2: 0, 3: 0});
    });

    test('lokale Datei behält die Aufteilung', () {
      expect(TrackingCodec.trackerFrom(TrackingCodec.tracker(wohnung())).fields, wohnung().fields);
    });
  });

  group('Eintrag', () {
    final category = Category(id: 'c-miete', name: 'Miete', icon: CategoryIcon.house, swatch: CategorySwatch.brown, trackers: [wohnung()]);
    EntryFormCubit form(Tracker t, {Entry? entry}) =>
        EntryFormCubit(MemoryCategoriesRepository(seed: [category]), EntryFormArgs(category: category, tracker: t, entry: entry), now: () => DateTime(2026, 10, 27));

    test('nur Warmmiete: speicherbar, Aufteilung zu', () {
      final cubit = form(wohnung())..setText('warm', '1.100');
      expect(cubit.state.split, isEmpty);
      expect(cubit.state.isPart(kalt), isTrue);
      expect(cubit.state.values, {'warm': 1100});
    });

    test('Aufteilung zu: eingetippte Teile zählen nicht und blockieren nicht', () {
      final cubit = form(wohnung())
        ..setText('warm', '1100')
        ..setSplit('warm', true)
        ..setText('kalt', 'viel')
        ..setSplit('warm', false);
      expect(cubit.state.invalid, isEmpty);
      expect(cubit.state.values, {'warm': 1100});
    });

    test('aufgeteilt ohne Warmmiete: die Summe wird die Warmmiete', () {
      final cubit = form(wohnung())
        ..setSplit('warm', true)
        ..setText('kalt', '800')
        ..setText('bk', '180,5')
        ..setText('hk', '120,25');
      expect(cubit.state.partSum(warm), 1100.75);
      expect(cubit.state.toEntry().values, {'warm': 1100.75, 'kalt': 800, 'bk': 180.5, 'hk': 120.25});
    });

    test('aufgeteilt mit Warmmiete: die eingetragene gilt, auch wenn Positionen fehlen', () {
      final cubit = form(wohnung())
        ..setText('warm', '1100')
        ..setSplit('warm', true)
        ..setText('kalt', '800');
      expect(cubit.state.partSum(warm), 800);
      expect(cubit.state.values, {'warm': 1100, 'kalt': 800});
    });

    test('Mieterhöhung: nur die neue Kaltmiete, die übrigen Teile zählen mit ihrem aktuellen Wert', () {
      final before = Entry(id: 'e1', date: d(2026, 1, 1), values: const {'warm': 1100, 'kalt': 800, 'bk': 180, 'hk': 120});
      final cubit = form(wohnung(entries: [before]));
      expect(cubit.state.split, {'warm'});
      expect(cubit.state.partSum(warm), isNull, reason: 'ohne Eingabe keine Summe');
      expect(cubit.state.canSave, isFalse);
      cubit.setText('kalt', '850');
      expect(cubit.state.values, {'warm': 1150, 'kalt': 850});
    });

    test('aufgeteilter Eintrag öffnet aufgeteilt, ein neuer übernimmt das vom letzten', () {
      final split = Entry(id: 'e1', date: d(2026, 1, 1), values: const {'warm': 1100, 'kalt': 800});
      final t = wohnung(entries: [split]);
      expect(form(t, entry: split).state.split, {'warm'});
      expect(form(t).state.split, {'warm'});
      final later = Entry(id: 'e2', date: d(2026, 7, 1), values: const {'warm': 1150});
      expect(form(wohnung(entries: [split, later])).state.split, isEmpty);
    });

    test('zugeklappt gespeichert: alte Teilbeträge fallen weg', () {
      final split = Entry(id: 'e1', date: d(2026, 1, 1), values: const {'warm': 1100, 'kalt': 800});
      final cubit = form(wohnung(entries: [split]), entry: split)..setSplit('warm', false);
      expect(cubit.state.toEntry().values, {'warm': 1100});
    });
  });

  group('Feld-Editor', () {
    final t = wohnung(fields: const [warm, kalt, settlement, FieldDefinition(id: 'own', name: 'Stellplatz', kind: FieldKind.currency, role: FieldRole.recurringCost)]);

    test('Gesamtfelder zur Wahl: gleiches Zeitverhalten, kein Teilbetrag, nicht das Feld selbst', () {
      final cubit = FieldEditorCubit(MemoryCategoriesRepository(), FieldEditorArgs(trackerId: t.id, tracker: t, field: t.fields.last));
      expect([for (final f in cubit.state.partTotals) f.id], ['warm']);
      cubit.setPartOf('warm');
      expect(cubit.state.draft.partOf, 'warm');
      cubit.setRole(FieldRole.oneOffCost);
      expect([for (final f in cubit.state.partTotals) f.id], ['nz']);
      expect(cubit.state.draft.partOf, isNull);
    });

    test('ein Gesamtfeld mit Teilen wird nicht selbst Teil; ein Teil bleibt beim Bearbeiten Teil', () {
      final total = FieldEditorCubit(MemoryCategoriesRepository(), FieldEditorArgs(trackerId: t.id, tracker: t, field: warm));
      expect(total.state.partTotals, isEmpty);
      final part = FieldEditorCubit(MemoryCategoriesRepository(), FieldEditorArgs(trackerId: t.id, tracker: t, field: kalt))..setName('Grundmiete');
      expect(part.state.draft.partOf, 'warm');
    });
  });
}
