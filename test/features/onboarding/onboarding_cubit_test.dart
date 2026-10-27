import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/utils/json_store.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
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

  test('zurück: von den Vorlagen zum Willkommen, Auswahl bleibt; nach dem Anlegen nicht mehr', () async {
    final cubit = OnboardingCubit(MockCategoriesRepository(seed: const []), MemoryJsonStore());
    await cubit.load();
    cubit
      ..next()
      ..toggle('miete')
      ..back();
    expect(cubit.state.step, OnboardingStep.welcome);
    expect(cubit.state.selected, contains('miete'));
    cubit.back();
    expect(cubit.state.step, OnboardingStep.welcome);

    cubit.next();
    await cubit.create(templates);
    cubit.back();
    expect(cubit.state.step, OnboardingStep.reminders);
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

  test('nach einem Fehler legt Wiederholen nur noch die fehlenden Vorlagen an', () async {
    final repo = _FailOnce(failAt: 2);
    final cubit = OnboardingCubit(repo, MemoryJsonStore());
    await cubit.load();
    await cubit.create(templates);
    expect(cubit.state.step, isNot(OnboardingStep.reminders));
    await cubit.create(templates);
    expect(cubit.state.step, OnboardingStep.reminders);
    final keys = [for (final c in await repo.loadCategories()) c.templateKey];
    expect(keys, ['strom', 'heizung', 'wasser']);
    await cubit.close();
  });
}

/// Scheitert genau einmal beim [failAt]-ten Anlegen (wie ein Netzfehler mitten im Onboarding).
class _FailOnce extends MockCategoriesRepository {
  _FailOnce({required this.failAt}) : super(seed: const []);

  final int failAt;
  var _calls = 0;

  @override
  Future<String> createCategory(CategoryDraft draft) {
    _calls++;
    if (_calls == failAt) throw StateError('offline');
    return super.createCategory(draft);
  }
}
