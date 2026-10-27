import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/di/lookup.dart';
import 'package:kostenkurve/core/utils/json_store.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:kostenkurve/features/onboarding/view/onboarding_page.dart';
import 'package:kostenkurve/features/storage/data/storage_mode.dart';
import 'package:kostenkurve/features/storage/view/start_gate.dart';

import '../../support/pump_app.dart';

/// Zurückwischen wie überall in iOS: zwischen den Schritten und – lokal gewählt – zurück zur Wahl
/// des Speicherorts.
void main() {
  setUpAll(ensureMockDependencies);
  tearDown(useMockCloud);

  Widget onboarding() => BlocProvider(
    create: (_) => OnboardingCubit(MockCategoriesRepository(seed: const []), MemoryJsonStore())..load(),
    child: const OnboardingPage(),
  );

  /// Vom linken Rand nach rechts wischen.
  Future<void> swipeBack(WidgetTester t) async {
    await t.dragFrom(const Offset(5, 400), const Offset(300, 0));
    await t.pumpAndSettle();
  }

  testWidgets('lokal: vom Willkommen zurück zur Wahl des Speicherorts, dann wieder lokal', (t) async {
    await lookup<StorageModeStore>().set(StorageMode.local);
    await pumpPage(t, StartGate(child: onboarding()), size: const Size(390, 1600));
    await t.pumpAndSettle();
    expect(find.text('Los geht\'s'), findsOneWidget);
    await swipeBack(t);
    expect(find.text('Los geht\'s'), findsNothing);
    expect(lookup<StorageModeStore>().mode, isNull);

    await t.tap(find.text('Kostenlos lokal starten'));
    await t.pumpAndSettle();
    expect(find.text('Los geht\'s'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Vorlagen zurück zum Willkommen; in der Cloud liegt nichts darunter, nach dem Anlegen kein Zurück', (t) async {
    await pumpPage(t, onboarding(), size: const Size(390, 1600));
    await t.pumpAndSettle();
    await t.tap(find.text('Los geht\'s'));
    await t.pumpAndSettle();
    expect(find.text('3 Kategorien anlegen'), findsOneWidget);
    await swipeBack(t);
    expect(find.text('Los geht\'s'), findsOneWidget);

    await swipeBack(t);
    expect(find.text('Los geht\'s'), findsOneWidget);
    expect(lookup<StorageModeStore>().mode, StorageMode.cloud);

    await t.tap(find.text('Los geht\'s'));
    await t.pumpAndSettle();
    expect(find.text('3 Kategorien anlegen'), findsOneWidget);
    await t.tap(find.text('3 Kategorien anlegen'));
    await t.pumpAndSettle();
    expect(find.text('Nichts vergessen'), findsOneWidget);
    await swipeBack(t);
    expect(find.text('Nichts vergessen'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
