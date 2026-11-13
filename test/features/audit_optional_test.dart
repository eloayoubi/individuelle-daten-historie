// Regressionstests zu den optionalen Punkten des Audits vom 12.11.2026.
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/utils/json_store.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/memory_categories_repository.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/categories/data/offline_categories_repository.dart';
import 'package:kostenkurve/features/sharing/cubit/sharing_cubit.dart';

class _Server extends MockCategoriesRepository {
  var online = true;

  @override
  Future<void> saveEntry(String trackerId, Entry entry) async {
    if (!online) throw Exception('offline');
    return super.saveEntry(trackerId, entry);
  }
}

void main() {
  final day = DateTime.utc(2026, 11, 1);

  group('Einträge am selben Tag', () {
    test('byDate behält die Reihenfolge des Anlegens, auch bei vielen (List.sort ist nicht stabil)', () {
      final entries = [
        for (var i = 0; i < 80; i++) Entry(id: 'e$i', date: i.isEven ? day : day.add(const Duration(days: 1)), values: const {}),
      ];
      final sorted = entries.byDate();
      expect([for (final e in sorted) e.id], [
        for (var i = 0; i < 80; i += 2) 'e$i',
        for (var i = 1; i < 80; i += 2) 'e$i',
      ]);
      expect(entries.newestFirst().first.id, 'e79');
      expect(entries.newestFirst().last.id, 'e0');
    });

    test('aktueller Betrag: der zuletzt angelegte gilt', () {
      const price = FieldDefinition(id: 'p', name: 'Preis', kind: FieldKind.currency, role: FieldRole.recurringCost);
      final tracker = Tracker(
        id: 't',
        name: 'Abo',
        fields: const [price],
        entries: [
          Entry(id: 'alt', date: day, values: const {'p': 9.99}),
          Entry(id: 'neu', date: day, values: const {'p': 12.99}),
        ],
      );
      expect(tracker.currentAmount(day)!.$2, 12.99);
      expect(tracker.detailValue('p'), 12.99);
    });

    test('lokal: Bearbeiten verschiebt den Eintrag nicht ans Ende des Tages', () async {
      var n = 0;
      final repo = MemoryCategoriesRepository(ids: (kind) => '$kind${n++}');
      final id = await repo.createCategory(const CategoryDraft(name: 'K', icon: CategoryIcon.star, swatch: CategorySwatch.indigo));
      final created = await repo.createTrackerWithFields(
        id,
        const TrackerDraft(name: 'Abo', fields: [FieldDraft(name: 'Preis', kind: FieldKind.currency, role: FieldRole.recurringCost)]),
      );
      final t = created.tracker;
      final f = created.fields.single;
      await repo.saveEntry(t, Entry(id: 'a', date: day, values: {f: 1}));
      await repo.saveEntry(t, Entry(id: 'b', date: day, values: {f: 2}));
      await repo.saveEntry(t, Entry(id: 'a', date: day, values: {f: 3}));
      final entries = (await repo.loadCategory(id))!.trackers.single.entries;
      expect([for (final e in entries) e.id], ['a', 'b']);
    });

    test('offline: wartende Bearbeitung bleibt an ihrer Stelle', () async {
      final server = _Server();
      final repo = OfflineCategoriesRepository(server, cache: MemoryJsonStore(), queue: MemoryJsonStore(), retryEvery: const Duration(hours: 1));
      await repo.loadCategories();
      Entry reading(String id, int value) => Entry(id: id, date: day, values: {'f-strom-stand': value});
      await repo.saveEntry('t-strom', reading('x1', 47100));
      await repo.saveEntry('t-strom', reading('x2', 47200));
      server.online = false;
      await repo.saveEntry('t-strom', reading('x1', 47150));
      final strom = (await repo.loadCategories()).expand((c) => c.trackers).firstWhere((t) => t.id == 't-strom');
      final ids = [for (final e in strom.entries) if (e.date == day) e.id];
      expect(ids, ['x1', 'x2']);
      expect(strom.entries.firstWhere((e) => e.id == 'x1').values['f-strom-stand'], 47150);
    });
  });

  group('Tracker samt Feldern anlegen', () {
    test('lokal: Ids in Reihenfolge, Teilbeträge per Position', () async {
      var n = 0;
      final repo = MemoryCategoriesRepository(ids: (kind) => '$kind${n++}');
      final id = await repo.createCategory(const CategoryDraft(name: 'Abos', icon: CategoryIcon.star, swatch: CategorySwatch.indigo));
      final created = await repo.createTrackerWithFields(
        id,
        const TrackerDraft(
          name: 'Netflix',
          fields: [
            FieldDraft(name: 'Preis', kind: FieldKind.currency, role: FieldRole.recurringCost),
            FieldDraft(name: 'Davon Steuer', kind: FieldKind.currency, role: FieldRole.recurringCost),
            FieldDraft(name: 'Art', kind: FieldKind.choice, choices: ['Streaming']),
          ],
          parts: {1: 0},
        ),
      );
      final tracker = (await repo.loadCategory(id))!.trackers.single;
      expect(tracker.id, created.tracker);
      expect([for (final f in tracker.fields) f.id], created.fields);
      expect([for (final f in tracker.fields) f.name], ['Preis', 'Davon Steuer', 'Art']);
      expect(tracker.fields[1].partOf, created.fields.first);
    });
  });

  group('Teilen', () {
    test('gelöschte Kategorie verschwindet von der Teilen-Seite', () async {
      final repo = MemoryCategoriesRepository();
      final id = await repo.createCategory(const CategoryDraft(name: 'WG', icon: CategoryIcon.star, swatch: CategorySwatch.indigo));
      final cubit = SharingCubit(repo, id);
      await cubit.load();
      expect(cubit.state.category, isNotNull);
      await repo.deleteCategory(id);
      await cubit.load();
      expect(cubit.state.category, isNull);
      expect(cubit.state.loaded, isTrue);
      await cubit.close();
    });
  });
}
