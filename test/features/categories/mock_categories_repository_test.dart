import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';

void main() {
  late MockCategoriesRepository repo;
  late int changes;

  setUp(() {
    repo = MockCategoriesRepository();
    changes = 0;
    repo.changes.listen((_) => changes++);
  });

  const draft = CategoryDraft(
    name: 'Wasser Garten',
    icon: CategoryIcon.drop,
    swatch: CategorySwatch.cyan,
    templateKey: 'wasser',
    trackers: [
      TrackerDraft(name: 'Gartenzähler', fields: [FieldDraft(name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'm³')]),
    ],
  );

  test('legt Kategorie mit Trackern und Feldern an und meldet die Änderung', () async {
    final id = await repo.createCategory(draft);
    await pumpEventQueue();
    final created = (await repo.loadCategory(id))!;
    expect(created.name, 'Wasser Garten');
    expect(created.templateKey, 'wasser');
    expect(created.trackers.single.fields.single.role, FieldRole.meterReading);
    expect(created.isOwner, isTrue);
    expect(changes, 1);
    final all = await repo.loadCategories();
    expect(all.indexOf(created), MockCategoriesRepository.categories.length);
  });

  test('archiviert und stellt wieder her', () async {
    await repo.setCategoryArchived('c-strom', archived: true);
    expect((await repo.loadCategory('c-strom'))!.isArchived, isTrue);
    await repo.setCategoryArchived('c-strom', archived: false);
    expect((await repo.loadCategory('c-strom'))!.isArchived, isFalse);
  });

  test('sortiert nach der übergebenen Reihenfolge', () async {
    await repo.reorderCategories(['c-auto', 'c-strom']);
    final ids = [for (final c in await repo.loadCategories()) c.id];
    expect(ids.take(3), ['c-auto', 'c-strom', 'c-heizung']);
  });

  test('legt Tracker und Felder an, ändert und entfernt sie', () async {
    final tracker = await repo.createTracker('c-wasser', 'Warmwasser', sort: 1);
    final field = await repo.createField(tracker, const FieldDraft(name: 'Stand', kind: FieldKind.number, role: FieldRole.meterReading), sort: 0);
    await repo.updateField(field, const FieldDraft(name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'm³'));
    var wasser = (await repo.loadCategory('c-wasser'))!;
    expect(wasser.trackers.last.fields.single.name, 'Zählerstand');
    expect(wasser.trackers.last.fields.single.unit, 'm³');

    await repo.renameTracker(tracker, 'Warmwasserzähler');
    await repo.archiveField(field);
    wasser = (await repo.loadCategory('c-wasser'))!;
    expect(wasser.trackers.last.name, 'Warmwasserzähler');
    expect(wasser.trackers.last.fields, isEmpty);

    await repo.archiveTracker(tracker);
    expect((await repo.loadCategory('c-wasser'))!.trackers, hasLength(1));
  });

  test('ändert Name, Symbol und Farbe', () async {
    await repo.updateCategory('c-strom', name: 'Strom Wohnung', icon: CategoryIcon.star, swatch: CategorySwatch.yellow);
    final strom = (await repo.loadCategory('c-strom'))!;
    expect((strom.name, strom.icon, strom.swatch), ('Strom Wohnung', CategoryIcon.star, CategorySwatch.yellow));
    expect(strom.trackers, isNotEmpty);
  });
}
