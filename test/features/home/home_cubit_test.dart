import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/utils/json_store.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/home/cubit/home_cubit.dart';
import 'package:kostenkurve/features/home/data/home_categories_store.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategories extends Mock implements CategoriesRepository {}

void main() {
  DateTime now() => DateTime(2026, 10, 22, 9, 30);

  blocTest<HomeCubit, HomeState>(
    'lädt die Übersicht aus den Kategorien',
    build: () => HomeCubit(MockCategoriesRepository(), now: now),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<HomeState>()
          .having((s) => s.status, 'status', HomeStatus.ready)
          .having((s) => s.overview?.categories.length, 'categories', MockCategoriesRepository.categories.length)
          .having((s) => s.overview?.today, 'today', DateTime.utc(2026, 10, 22)),
    ],
  );

  blocTest<HomeCubit, HomeState>(
    'meldet einen Fehler, wenn das Laden scheitert',
    build: () {
      final repo = _MockCategories();
      when(() => repo.changes).thenAnswer((_) => const Stream.empty());
      when(() => repo.syncState).thenReturn(const SyncState());
      when(repo.loadCategories).thenThrow(Exception('offline'));
      return HomeCubit(repo, now: now);
    },
    act: (cubit) => cubit.load(),
    expect: () => [isA<HomeState>().having((s) => s.status, 'status', HomeStatus.failure).having((s) => s.overview, 'overview', isNull)],
  );

  blocTest<HomeCubit, HomeState>(
    'behält die Übersicht, wenn ein späteres Neuladen scheitert',
    build: () {
      final repo = _MockCategories();
      when(() => repo.changes).thenAnswer((_) => const Stream.empty());
      when(() => repo.syncState).thenReturn(const SyncState());
      var calls = 0;
      when(repo.loadCategories).thenAnswer((_) async {
        if (calls++ > 0) throw Exception('offline');
        return MockCategoriesRepository.categories;
      });
      return HomeCubit(repo, now: now);
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.load();
    },
    expect: () => [
      isA<HomeState>().having((s) => s.status, 'status', HomeStatus.ready),
      isA<HomeState>().having((s) => s.status, 'status', HomeStatus.failure).having((s) => s.overview, 'overview', isNotNull),
    ],
  );

  blocTest<HomeCubit, HomeState>(
    'übernimmt den Stand der Offline-Warteschlange',
    build: () {
      final repo = _MockCategories();
      when(() => repo.changes).thenAnswer((_) => const Stream.empty());
      when(repo.loadCategories).thenAnswer((_) async => MockCategoriesRepository.categories);
      when(() => repo.syncState).thenReturn(const SyncState(pending: 2, rejected: 1));
      return HomeCubit(repo, now: now);
    },
    act: (cubit) => cubit.load(),
    expect: () => [isA<HomeState>().having((s) => s.sync, 'sync', const SyncState(pending: 2, rejected: 1))],
  );

  test('blendet abgelehnte Einträge aus', () {
    final repo = _MockCategories();
    when(() => repo.changes).thenAnswer((_) => const Stream.empty());
    HomeCubit(repo, now: now).acknowledgeRejected();
    verify(repo.acknowledgeRejected).called(1);
  });

  blocTest<HomeCubit, HomeState>(
    'blendet archivierte Kategorien aus',
    build: () => HomeCubit(
      MockCategoriesRepository(seed: [MockCategoriesRepository.categories.first.copyWith(archivedAt: () => DateTime.utc(2026)), ...MockCategoriesRepository.categories.skip(1)]),
      now: now,
    ),
    act: (cubit) => cubit.load(),
    expect: () => [isA<HomeState>().having((s) => s.overview?.categories.map((c) => c.category.id), 'ids', isNot(contains('c-strom')))],
  );

  group('Kategorien der Übersicht', () {
    test('anfangs keine gewählt', () async {
      final cubit = HomeCubit(MockCategoriesRepository(), now: now);
      await cubit.load();
      expect(cubit.state.overview?.categories, isNotEmpty);
      expect(cubit.state.shown, isEmpty);
    });

    test('Auswahl zeigt die Kategorien in ihrer Reihenfolge und bleibt gespeichert', () async {
      final pins = HomeCategoriesStore(MemoryJsonStore());
      final cubit = HomeCubit(MockCategoriesRepository(), pins: pins, now: now);
      await cubit.load();
      await cubit.setPinned(['c-internet', 'c-strom', 'gibt-es-nicht']);
      expect(cubit.state.shown.map((s) => s.category.id), ['c-internet', 'c-strom']);

      final again = HomeCubit(MockCategoriesRepository(), pins: pins, now: now);
      await again.load();
      expect(again.state.shown.map((s) => s.category.id), ['c-internet', 'c-strom']);
    });

    test('Verschieben ändert die Reihenfolge, Verschiebe-Modus erst ab zwei Kategorien', () async {
      final pins = HomeCategoriesStore(MemoryJsonStore());
      final cubit = HomeCubit(MockCategoriesRepository(), pins: pins, now: now);
      await cubit.load();
      await cubit.setPinned(['c-strom']);
      cubit.setReordering(true);
      expect(cubit.state.reordering, isFalse);

      await cubit.setPinned(['c-strom', 'c-internet', 'c-abos']);
      cubit.setReordering(true);
      expect(cubit.state.reordering, isTrue);
      await cubit.reorder(0, 2);
      expect(cubit.state.shown.map((s) => s.category.id), ['c-internet', 'c-abos', 'c-strom']);
      expect(await pins.load(), ['c-internet', 'c-abos', 'c-strom']);
      cubit.setReordering(false);
      expect(cubit.state.reordering, isFalse);
    });
  });
}
