import 'dart:async';

import '../../../core/models/tracking_codec.dart';
import '../../../core/utils/json_store.dart';
import 'categories_repository.dart';
import 'memory_categories_repository.dart';

/// Speicherort „Lokal“: alle Kategorien in einer Datei auf dem Gerät – ohne Konto, ohne Netz,
/// kostenlos. Gelesen wird einmal beim ersten Zugriff, gespeichert nach jeder Änderung
/// (nacheinander, damit ein älterer Stand nie einen neueren überschreibt).
///
/// Format: `{"version": 1, "categories": [...]}` im JSON von [TrackingCodec].
class LocalCategoriesRepository extends MemoryCategoriesRepository {
  LocalCategoriesRepository(this._store);

  final JsonStore _store;
  var _loaded = false;
  Future<void>? _loading;

  /// Laufende Schreibvorgänge; [_saving] ist der letzte davon.
  var _writes = 0;
  Future<void> _saving = Future.value();

  // Fertige Futures werden nicht aufgehoben: Wer später darauf wartet, liefe in der Zone des ersten
  // Aufrufers weiter (in Widget-Tests eine beendete).
  @override
  Future<void> ready() async {
    if (_loaded) return;
    await (_loading ??= _load().whenComplete(() => _loading = null));
  }

  Future<void> _load() async {
    if (await _store.read() case {'categories': final List saved}) {
      final categories = [for (final c in saved.cast<Map<String, Object?>>()) TrackingCodec.categoryFrom(c)];
      items
        ..clear()
        ..addAll(categories);
    }
    // Nicht lesbar: Der Fehler geht an den Aufrufer, der nächste Zugriff versucht es erneut – nie
    // leer überschreiben.
    _loaded = true;
  }

  @override
  void changed() {
    final snapshot = {
      'version': 1,
      'categories': [for (final c in items) TrackingCodec.category(c)],
    };
    final previous = _writes == 0 ? null : _saving;
    _writes++;
    _saving = (previous == null ? _store.write(snapshot) : previous.then((_) => _store.write(snapshot)))
        .catchError((Object _) {})
        .whenComplete(() => _writes--);
    super.changed();
  }

  /// Kategorien aus der Cloud übernehmen: gleiche Id ersetzt, alles andere bleibt (Umzug aufs Gerät).
  Future<void> merge(List<Category> categories) async {
    await ready();
    final incoming = {for (final c in categories) c.id: c};
    final kept = [for (final c in items) if (!incoming.containsKey(c.id)) c];
    items
      ..clear()
      ..addAll([...categories, ...kept]);
    changed();
    await _saving;
  }

  /// Alles vom Gerät entfernen (nach dem Hochladen in die Cloud).
  Future<void> clear() async {
    await ready();
    items.clear();
    changed();
    await _saving;
  }
}
