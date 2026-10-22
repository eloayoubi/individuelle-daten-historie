import '../../../core/utils/json_store.dart';

/// Bittet nach dem dritten gespeicherten Eintrag einmal um eine Bewertung – dann hat die App
/// gezeigt, wofür sie gut ist. Ob der Dialog erscheint, entscheidet das System (höchstens dreimal
/// im Jahr).
abstract interface class ReviewPrompter {
  Future<void> entrySaved();
}

class StoreReviewPrompter implements ReviewPrompter {
  StoreReviewPrompter(this._store, {required this._available, required this._request, this.after = 3});

  final JsonStore _store;
  final Future<bool> Function() _available;
  final Future<void> Function() _request;
  final int after;

  @override
  Future<void> entrySaved() async {
    try {
      final saved = await _store.read();
      final (count, asked) = switch (saved) {
        {'saved': final int count, 'asked': final bool asked} => (count, asked),
        _ => (0, false),
      };
      final ask = !asked && count + 1 >= after;
      await _store.write({'saved': count + 1, 'asked': asked || ask});
      if (ask && await _available()) await _request();
    } catch (_) {
      // Eine Bewertung ist nie wichtiger als das Speichern.
    }
  }
}

/// Für Tests.
class NoReviewPrompter implements ReviewPrompter {
  const NoReviewPrompter();

  @override
  Future<void> entrySaved() async {}
}
