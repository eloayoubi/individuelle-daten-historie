import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/di/lookup.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/sharing/view/join_sheet.dart';

import '../../support/pump_app.dart';

/// Server, der Einladungen zählt und mit [error] ablehnt oder bis [gate] wartet.
class _Invites extends MockCategoriesRepository {
  var calls = 0;
  Object? error;
  Completer<void>? gate;

  @override
  Future<String> acceptInvite(String code) async {
    calls++;
    await gate?.future;
    if (error case final e?) throw e;
    return 'c-ferien';
  }
}

void main() {
  late _Invites invites;

  setUp(() async {
    await ensureMockDependencies();
    invites = _Invites();
    getIt
      ..unregister<CategoriesRepository>()
      ..registerSingleton<CategoriesRepository>(invites);
  });

  testWidgets('Eigentümer ohne Cloud-Abo: eigene Meldung statt „Code unbekannt“', (t) async {
    invites.error = const WriteRejected(WriteRejected.cloudRequired);
    await pumpPage(t, const JoinSheet(code: 'K7Q2M9X4TA'));
    await t.tap(find.text('Beitreten'));
    await t.pump();
    expect(find.textContaining('kein Cloud-Abo'), findsOneWidget);
    expect(find.text('Code unbekannt, abgelaufen oder schon benutzt.'), findsNothing);
  });

  testWidgets('Enter auf der Tastatur: nicht mit zu kurzem Code und nicht doppelt', (t) async {
    await pumpPage(t, const JoinSheet());
    await t.enterText(find.byType(EditableText), 'ABC');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pump();
    expect(invites.calls, 0);

    invites.gate = Completer<void>();
    await t.enterText(find.byType(EditableText), 'K7Q2M9X4TA');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pump();
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pump();
    expect(invites.calls, 1);
    invites
      ..error = const WriteRejected('invalid_invite')
      ..gate!.complete();
    await t.pump();
  });
}
