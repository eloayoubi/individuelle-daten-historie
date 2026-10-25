import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/di/lookup.dart';
import 'package:kostenkurve/features/account/view/account_page.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/storage/view/cloud_paused_page.dart';

import '../../support/pump_app.dart';

/// Cloud mit zwei noch nicht gesendeten Einträgen.
class _Waiting extends MockCategoriesRepository {
  var pending = 2;

  @override
  SyncState get syncState => SyncState(pending: pending);
}

void main() {
  late _Waiting cloud;

  setUp(() async {
    await ensureMockDependencies();
    cloud = _Waiting();
    getIt
      ..unregister<CategoriesRepository>()
      ..registerSingleton<CategoriesRepository>(cloud);
  });

  testWidgets('abmelden mit wartenden Einträgen: Rückfrage warnt', (t) async {
    await pumpPage(t, const CloudPausedPage());
    await t.tap(find.text('Abmelden'));
    await t.pumpAndSettle();
    expect(find.textContaining('2 Einträge sind noch nicht gesendet'), findsOneWidget);
  });

  testWidgets('abmelden ohne wartende Einträge: keine Warnung', (t) async {
    cloud.pending = 0;
    await pumpPage(t, const CloudPausedPage());
    await t.tap(find.text('Abmelden'));
    await t.pumpAndSettle();
    expect(find.text('Abmelden?'), findsOneWidget);
    expect(find.textContaining('noch nicht gesendet'), findsNothing);
  });

  testWidgets('Konto löschen mit wartenden Einträgen: Rückfrage warnt', (t) async {
    await pumpPage(t, const AccountPage(), size: const Size(390, 1400));
    await t.tap(find.text('Konto löschen'));
    await t.pumpAndSettle();
    expect(find.textContaining('2 Einträge sind noch nicht gesendet'), findsOneWidget);
  });
}
