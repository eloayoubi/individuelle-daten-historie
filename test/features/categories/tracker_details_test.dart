import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/utils/formulas.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/categories/data/tracker_details.dart';

void main() {
  final now = DateTime(2026, 10, 22, 19, 5);
  final today = DateTime.utc(2026, 10, 22);

  late MockCategoriesRepository repo;
  setUp(() => repo = MockCategoriesRepository());

  Future<Tracker> tracker(String categoryId) async => (await repo.loadCategory(categoryId))!.trackers.first;

  group('Tracker', () {
    final strom = MockCategoriesRepository.categories.firstWhere((c) => c.id == 'c-strom').trackers.single;
    final glasfaser = MockCategoriesRepository.categories.firstWhere((c) => c.id == 'c-internet').trackers.first;

    test('trennt Details von Feldern mit Verlauf', () {
      expect(strom.detailFields.map((f) => f.id), ['f-strom-ende', 'f-strom-anbieter']);
      expect(strom.entryFields.map((f) => f.id), ['f-strom-stand', 'f-strom-ap', 'f-strom-gp', 'f-strom-abschlag']);
    });

    test('reiner Detail-Eintrag fehlt in den Einträgen, gemischter bleibt', () {
      expect(glasfaser.isDetailEntry(glasfaser.entries.firstWhere((e) => e.id == 'e-glasfaser-anbieter')), isTrue);
      expect(glasfaser.records.map((e) => e.id), isNot(contains('e-glasfaser-anbieter')));
      // Älterer Eintrag mit Preis und Vertragsende: bleibt ein Eintrag.
      expect(glasfaser.records.map((e) => e.id), contains('e-glasfaser-1'));
      expect(glasfaser.detailValue('f-glasfaser-anbieter'), 'Telekom');
      expect(glasfaser.detailValue('f-glasfaser-ende'), DateTime.utc(2026, 12, 31));
    });

    test('Notiz macht einen Eintrag zum Eintrag', () {
      final entry = Entry(id: 'x', date: today, values: const {'f-strom-anbieter': 'Neu'}, note: 'Wechsel');
      expect(strom.isDetailEntry(entry), isFalse);
    });
  });

  group('saveDetail', () {
    test('neues Detail landet in einem Eintrag von heute, ein zweites im selben', () async {
      final strom = await tracker('c-strom');
      final provider = strom.fields.firstWhere((f) => f.id == 'f-strom-anbieter');
      final end = strom.fields.firstWhere((f) => f.id == 'f-strom-ende');
      await repo.saveDetail(strom, provider, 'Grünstrom', now: now);
      await repo.saveDetail(await tracker('c-strom'), end, DateTime.utc(2028, 3, 31), now: now);

      final after = await tracker('c-strom');
      final details = after.entries.where((e) => after.isDetailEntry(e) && e.date == today).toList();
      expect(details, hasLength(1));
      expect(details.single.values, {'f-strom-anbieter': 'Grünstrom', 'f-strom-ende': DateTime.utc(2028, 3, 31)});
      expect(after.detailValue('f-strom-anbieter'), 'Grünstrom');
      expect(after.records.length, strom.records.length);
    });

    test('spätere Einträge verlieren ihren Wert, damit der neue gilt', () async {
      final strom = await tracker('c-strom');
      final provider = strom.fields.firstWhere((f) => f.id == 'f-strom-anbieter');
      await repo.saveEntry(strom.id, Entry(id: 'future', date: DateTime.utc(2027, 1, 1), values: const {'f-strom-ap': 0.35, 'f-strom-anbieter': 'Alt'}));
      await repo.saveDetail(await tracker('c-strom'), provider, 'Neu', now: now);

      final after = await tracker('c-strom');
      expect(after.detailValue('f-strom-anbieter'), 'Neu');
      expect(after.entries.firstWhere((e) => e.id == 'future').values, {'f-strom-ap': 0.35});
    });

    test('Entfernen streicht den Wert überall, leere Einträge verschwinden', () async {
      final glasfaser = await tracker('c-internet');
      final provider = glasfaser.fields.firstWhere((f) => f.id == 'f-glasfaser-anbieter');
      final end = glasfaser.fields.firstWhere((f) => f.id == 'f-glasfaser-ende');
      await repo.saveDetail(glasfaser, provider, null, now: now);
      await repo.saveDetail(await tracker('c-internet'), end, null, now: now);

      final after = await tracker('c-internet');
      expect(after.detailValue('f-glasfaser-anbieter'), isNull);
      expect(after.detailValue('f-glasfaser-ende'), isNull);
      expect(after.entries.map((e) => e.id), isNot(contains('e-glasfaser-anbieter')));
      // Der Preis-Eintrag mit dem alten Vertragsende bleibt, nur ohne das Datum.
      expect(after.entries.firstWhere((e) => e.id == 'e-glasfaser-1').values, {'f-glasfaser-preis': 44.99});
    });

    test('Formel-Werte werden nicht mitgespeichert', () async {
      final golf = Formulas.apply(await tracker('c-auto'));
      final inspection = golf.fields.firstWhere((f) => f.id == 'f-golf-tuev');
      await repo.saveDetail(golf, inspection, DateTime.utc(2029, 2, 1), now: now);
      final after = await tracker('c-auto');
      final details = after.entries.where(after.isDetailEntry).single;
      expect(details.values, {'f-golf-tuev': DateTime.utc(2029, 2, 1)});
    });
  });

  test('Detail-Eintrag ist kein „voriger Eintrag“ für Formeln', () async {
    final golf = await tracker('c-auto');
    final inspection = golf.fields.firstWhere((f) => f.id == 'f-golf-tuev');
    final second = golf.entries.firstWhere((e) => e.id == 'e-golf-1');
    await repo.saveEntry(golf.id, Entry(id: 'tuev', date: second.date.subtract(const Duration(days: 1)), values: {inspection.id: DateTime.utc(2029)}));
    final vars = Formulas.variablesByEntry(await tracker('c-auto'));
    expect(vars[second.id]!['tage'], 21);
    expect(vars.containsKey('tuev'), isFalse);
  });
}
