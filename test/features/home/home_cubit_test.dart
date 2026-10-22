import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/home/cubit/home_cubit.dart';
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
    'meldet jedes Antippen als eigenes Ereignis',
    build: () => HomeCubit(MockCategoriesRepository(), now: now),
    act: (cubit) => cubit
      ..capture('t-strom')
      ..capture('t-strom'),
    expect: () => [
      isA<HomeState>().having((s) => s.event?.kind, 'event', HomeEventKind.captureSoon),
      isA<HomeState>().having((s) => s.event?.kind, 'event', HomeEventKind.captureSoon),
    ],
  );
}
