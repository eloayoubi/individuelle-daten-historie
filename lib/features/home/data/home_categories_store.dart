import '../../../core/utils/json_store.dart';

/// Welche Kategorien die Übersicht zeigt und in welcher Reihenfolge – als Ids, je Gerät.
/// Anfangs leer: Die Übersicht bietet dann „Kategorie hinzufügen“ an.
class HomeCategoriesStore {
  HomeCategoriesStore(this._store);

  final JsonStore _store;

  Future<List<String>> load() async => switch (await _store.read()) {
    final List<Object?> ids => [for (final id in ids) if (id is String) id],
    _ => const [],
  };

  Future<void> save(List<String> ids) => _store.write(ids);
}
