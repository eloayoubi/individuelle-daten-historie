import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/categories/cubit/category_setup_cubit.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/category_templates.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategories extends Mock implements CategoriesRepository {}

void main() {
  final strom = CategoryTemplates.all(lookupAppLocalizations(const Locale('de'))).first;

  setUpAll(() => registerFallbackValue(const CategoryDraft(name: '', icon: CategoryIcon.star, swatch: CategorySwatch.gray)));

  test('übernimmt Name, Symbol und Farbe der Vorlage', () {
    final state = CategorySetupCubit(MockCategoriesRepository(), strom).state;
    expect((state.name, state.icon, state.swatch), ('Strom', CategoryIcon.bolt, CategorySwatch.orange));
    expect(state.draft.trackers.single.fields, hasLength(strom.trackers.single.fields.length));
  });

  test('eigene Kategorie startet leer und ohne Tracker', () {
    final state = CategorySetupCubit(MockCategoriesRepository(), null).state;
    expect(state.name, isEmpty);
    expect(state.canCreate, isFalse);
    expect(state.draft.trackers, isEmpty);
  });

  blocTest<CategorySetupCubit, CategorySetupState>(
    'legt die Kategorie ohne abgewählte Felder an',
    build: () => CategorySetupCubit(MockCategoriesRepository(), strom),
    act: (cubit) => cubit
      ..toggleField(0, 3) // Abschlag
      ..toggleField(0, 4) // Anbieter
      ..toggleField(0, 4) // doch wieder dabei
      ..setName('  Strom Keller  ')
      ..setSwatch(CategorySwatch.yellow)
      ..create(),
    skip: 5,
    expect: () => [
      isA<CategorySetupState>().having((s) => s.saving, 'saving', isTrue),
      isA<CategorySetupState>()
          .having((s) => s.event?.categoryId, 'id', startsWith('mock-c-'))
          .having((s) => s.event?.name, 'name', 'Strom Keller')
          .having((s) => s.draft.trackers.single.fields.map((f) => f.name), 'fields', isNot(contains('Abschlag')))
          .having((s) => s.draft.trackers.single.fields.map((f) => f.name), 'fields', contains('Anbieter'))
          .having((s) => s.draft.swatch, 'swatch', CategorySwatch.yellow),
    ],
  );

  blocTest<CategorySetupCubit, CategorySetupState>(
    'meldet, wenn das Anlegen scheitert',
    build: () {
      final repo = _MockCategories();
      when(() => repo.createCategory(any())).thenThrow(Exception('offline'));
      return CategorySetupCubit(repo, strom);
    },
    act: (cubit) => cubit.create(),
    expect: () => [
      isA<CategorySetupState>().having((s) => s.saving, 'saving', isTrue),
      isA<CategorySetupState>().having((s) => s.saving, 'saving', isFalse).having((s) => s.event?.categoryId, 'id', isNull).having((s) => s.event, 'event', isNotNull),
    ],
  );
}
