import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/categories/cubit/categories_cubit.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategories extends Mock implements CategoriesRepository {}

void main() {
  final seed = MockCategoriesRepository.categories;
  final archived = seed.last.copyWith(archivedAt: () => DateTime.utc(2026, 10, 1));

  blocTest<CategoriesCubit, CategoriesState>(
    'trennt aktive und archivierte Kategorien',
    build: () => CategoriesCubit(MockCategoriesRepository(seed: [...seed.take(seed.length - 1), archived])),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<CategoriesState>()
          .having((s) => s.status, 'status', CategoriesStatus.ready)
          .having((s) => s.active.length, 'active', seed.length - 1)
          .having((s) => s.archived.single.id, 'archived', archived.id),
    ],
  );

  final reorderRepo = MockCategoriesRepository();
  blocTest<CategoriesCubit, CategoriesState>(
    'verschiebt sofort und speichert die neue Reihenfolge',
    build: () => CategoriesCubit(reorderRepo),
    seed: () => CategoriesState(status: CategoriesStatus.ready, active: seed, editing: true),
    act: (cubit) async {
      await cubit.reorder(0, 2);
      await pumpEventQueue();
    },
    // Das Neuladen nach dem Speichern ergibt denselben Stand und erzeugt keinen weiteren Zustand.
    expect: () => [
      isA<CategoriesState>().having((s) => [for (final c in s.active.take(3)) c.id], 'order', ['c-heizung', 'c-wasser', 'c-strom']).having((s) => s.editing, 'editing', isTrue),
    ],
    verify: (_) async => expect([for (final c in (await reorderRepo.loadCategories()).take(3)) c.id], ['c-heizung', 'c-wasser', 'c-strom']),
  );

  blocTest<CategoriesCubit, CategoriesState>(
    'stellt eine archivierte Kategorie wieder her',
    build: () => CategoriesCubit(MockCategoriesRepository(seed: [archived])),
    act: (cubit) async {
      await cubit.load();
      await cubit.restore(cubit.state.archived.single);
      await pumpEventQueue();
    },
    skip: 1,
    expect: () => [
      isA<CategoriesState>().having((s) => s.event?.kind, 'event', CategoriesEventKind.restored).having((s) => s.event?.name, 'name', archived.name),
      isA<CategoriesState>().having((s) => s.active.single.id, 'active', archived.id).having((s) => s.archived, 'archived', isEmpty),
    ],
  );

  blocTest<CategoriesCubit, CategoriesState>(
    'zeigt den Fehler, wenn das erste Laden scheitert',
    build: () {
      final repo = _MockCategories();
      when(() => repo.changes).thenAnswer((_) => const Stream.empty());
      when(repo.loadCategories).thenThrow(Exception('offline'));
      return CategoriesCubit(repo);
    },
    act: (cubit) => cubit.load(),
    expect: () => [isA<CategoriesState>().having((s) => s.status, 'status', CategoriesStatus.failure)],
  );

  blocTest<CategoriesCubit, CategoriesState>(
    'schaltet den Bearbeiten-Modus',
    build: () => CategoriesCubit(MockCategoriesRepository()),
    act: (cubit) => cubit
      ..toggleEditing()
      ..toggleEditing(),
    expect: () => [
      isA<CategoriesState>().having((s) => s.editing, 'editing', isTrue),
      isA<CategoriesState>().having((s) => s.editing, 'editing', isFalse),
    ],
  );
}
