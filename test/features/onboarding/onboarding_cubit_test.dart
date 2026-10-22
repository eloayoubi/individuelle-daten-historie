import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/utils/json_store.dart';
import 'package:kostenkurve/features/categories/data/category_templates.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:kostenkurve/l10n/generated/app_localizations.dart';

void main() {
  final templates = CategoryTemplates.all(lookupAppLocalizations(const Locale('de')));

  test('ohne Kategorien: Onboarding mit vorgeschlagenen Vorlagen', () async {
    final cubit = OnboardingCubit(MockCategoriesRepository(seed: const []), MemoryJsonStore());
    await cubit.load();
    expect(cubit.state.loaded, isTrue);
    expect(cubit.state.show, isTrue);
    expect(cubit.state.step, OnboardingStep.welcome);
    expect(cubit.state.selected, OnboardingCubit.suggested);
    await cubit.close();
  });

  test('Vorlagen anlegen, Erinnerungen, abschließen', () async {
    final repo = MockCategoriesRepository(seed: const []);
    final store = MemoryJsonStore();
    final cubit = OnboardingCubit(repo, store);
    await cubit.load();
    cubit
      ..next()
      ..toggle('wasser')
      ..toggle('miete');
    expect(cubit.state.step, OnboardingStep.templates);
    expect(cubit.state.selected, {'strom', 'heizung', 'miete'});

    await cubit.create(templates);
    expect(cubit.state.step, OnboardingStep.reminders);
    final created = await repo.loadCategories();
    expect([for (final c in created) c.templateKey], ['strom', 'heizung', 'miete']);
    expect(created.first.trackers, isNotEmpty);

    await cubit.finish();
    expect(cubit.state.show, isFalse);
    expect(await store.read(), {'done': true});
    await cubit.close();
  });

  test('schon Kategorien (anderes Gerät): kein Onboarding, gemerkt', () async {
    final store = MemoryJsonStore();
    final cubit = OnboardingCubit(MockCategoriesRepository(), store);
    await cubit.load();
    expect(cubit.state.show, isFalse);
    expect(await store.read(), {'done': true});
    await cubit.close();
  });

  test('einmal abgeschlossen: nie wieder, auch ohne Kategorien', () async {
    final cubit = OnboardingCubit(MockCategoriesRepository(seed: const []), MemoryJsonStore({'done': true}));
    await cubit.load();
    expect(cubit.state.loaded, isTrue);
    expect(cubit.state.show, isFalse);
    await cubit.close();
  });
}
