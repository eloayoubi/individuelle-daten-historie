import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/categories/cubit/category_detail_cubit.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';

void main() {
  blocTest<CategoryDetailCubit, CategoryDetailState>(
    'lädt die Kategorie',
    build: () => CategoryDetailCubit(MockCategoriesRepository(), 'c-strom'),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<CategoryDetailState>().having((s) => s.status, 'status', CategoryDetailStatus.ready).having((s) => s.category?.name, 'name', 'Strom'),
    ],
  );

  blocTest<CategoryDetailCubit, CategoryDetailState>(
    'meldet eine fehlende Kategorie',
    build: () => CategoryDetailCubit(MockCategoriesRepository(), 'gibt-es-nicht'),
    act: (cubit) => cubit.load(),
    expect: () => [isA<CategoryDetailState>().having((s) => s.status, 'status', CategoryDetailStatus.missing)],
  );

  blocTest<CategoryDetailCubit, CategoryDetailState>(
    'legt einen Tracker an und zeigt ihn nach dem Neuladen',
    build: () => CategoryDetailCubit(MockCategoriesRepository(), 'c-wasser'),
    act: (cubit) async {
      await cubit.load();
      await cubit.addTracker('  Warmwasser ');
      await pumpEventQueue();
    },
    skip: 1,
    expect: () => [
      isA<CategoryDetailState>().having((s) => s.event?.kind, 'event', CategoryDetailEventKind.trackerAdded),
      isA<CategoryDetailState>().having((s) => s.category?.trackers.map((t) => t.name), 'trackers', ['Kaltwasser', 'Warmwasser']),
    ],
  );

  blocTest<CategoryDetailCubit, CategoryDetailState>(
    'ändert Name, Symbol und Farbe',
    build: () => CategoryDetailCubit(MockCategoriesRepository(), 'c-strom'),
    act: (cubit) async {
      await cubit.load();
      await cubit.updateAppearance(name: 'Strom Wohnung ', icon: CategoryIcon.star, swatch: CategorySwatch.yellow);
      await pumpEventQueue();
    },
    skip: 1,
    expect: () => [
      isA<CategoryDetailState>().having((s) => (s.category?.name, s.category?.icon, s.category?.swatch), 'look', ('Strom Wohnung', CategoryIcon.star, CategorySwatch.yellow)),
    ],
  );

  blocTest<CategoryDetailCubit, CategoryDetailState>(
    'archiviert die Kategorie',
    build: () => CategoryDetailCubit(MockCategoriesRepository(), 'c-abos'),
    act: (cubit) async {
      await cubit.load();
      await cubit.archive();
      await pumpEventQueue();
    },
    skip: 1,
    expect: () => [
      isA<CategoryDetailState>().having((s) => s.event?.kind, 'event', CategoryDetailEventKind.archived),
      isA<CategoryDetailState>().having((s) => s.category?.isArchived, 'archived', isTrue),
    ],
  );

  blocTest<CategoryDetailCubit, CategoryDetailState>(
    'archiviert einen Tracker',
    build: () => CategoryDetailCubit(MockCategoriesRepository(), 'c-internet'),
    act: (cubit) async {
      await cubit.load();
      await cubit.archiveTracker('t-handy');
      await pumpEventQueue();
    },
    skip: 1,
    expect: () => [
      isA<CategoryDetailState>().having((s) => s.event?.kind, 'event', CategoryDetailEventKind.trackerArchived),
      isA<CategoryDetailState>().having((s) => s.category?.trackers.map((t) => t.id), 'trackers', ['t-glasfaser']),
    ],
  );
}
