import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/utils/json_store.dart';
import 'package:kostenkurve/features/settings/data/review_prompter.dart';

void main() {
  test('fragt einmal nach dem dritten Eintrag', () async {
    var asked = 0;
    final store = MemoryJsonStore();
    final prompter = StoreReviewPrompter(store, available: () async => true, request: () async => asked++);
    for (var i = 0; i < 6; i++) {
      await prompter.entrySaved();
    }
    expect(asked, 1);
    expect(await store.read(), {'saved': 6, 'asked': true});
  });

  test('ohne Store-Bewertung (Simulator): kein Absturz, gilt trotzdem als gefragt', () async {
    var asked = 0;
    final store = MemoryJsonStore({'saved': 2, 'asked': false});
    final prompter = StoreReviewPrompter(store, available: () async => false, request: () async => asked++);
    await prompter.entrySaved();
    expect(asked, 0);
    expect(await store.read(), {'saved': 3, 'asked': true});
  });

  test('Fehler beim Bewerten stören das Speichern nicht', () async {
    final prompter = StoreReviewPrompter(MemoryJsonStore({'saved': 2, 'asked': false}), available: () async => true, request: () => throw StateError('kein Store'));
    await prompter.entrySaved();
  });
}
