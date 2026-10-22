import 'dart:async';

import '../../../core/models/tracking_codec.dart';
import '../../../core/utils/json_store.dart';
import 'categories_repository.dart';

/// Noch nicht gesendete Änderung an einem Eintrag.
sealed class PendingWrite {
  const PendingWrite(this.trackerId, this.entryId);

  final String trackerId;
  final String entryId;

  Map<String, Object?> toJson();

  static PendingWrite fromJson(Map<String, Object?> j) => switch (j['op']) {
    'save' => PendingSave(j['trackerId']! as String, TrackingCodec.entryFrom((j['entry']! as Map).cast<String, Object?>())),
    'delete' => PendingDelete(j['trackerId']! as String, j['entryId']! as String),
    final op => throw FormatException('Unbekannte Änderung $op'),
  };
}

class PendingSave extends PendingWrite {
  PendingSave(String trackerId, this.entry) : super(trackerId, entry.id);

  final Entry entry;

  @override
  Map<String, Object?> toJson() => {'op': 'save', 'trackerId': trackerId, 'entry': TrackingCodec.entry(entry)};
}

class PendingDelete extends PendingWrite {
  const PendingDelete(super.trackerId, super.entryId);

  @override
  Map<String, Object?> toJson() => {'op': 'delete', 'trackerId': trackerId, 'entryId': entryId};
}

/// Offline-Schicht vor dem Supabase-Repository:
///
/// - **Lesen:** Jeder erfolgreiche Abruf landet im Cache; ohne Netz kommt der letzte Stand von dort.
/// - **Einträge schreiben:** gehen zuerst in eine Warteschlange auf dem Gerät und erscheinen sofort
///   in allen Ansichten. Gesendet wird gleich, nach jedem Abruf, beim Zurückkehren in die App
///   ([sync]) und alle [retryEvery], solange etwas wartet. Ein Eintrag hat seine Id schon vom
///   Gerät – mehrfaches Senden ändert nichts (`save_entry` ist ein Upsert).
/// - **Abgelehnt** ([WriteRejected]) wird verworfen und in [syncState] gezählt; bei anderen
///   Fehlern (kein Netz) bleibt die Änderung liegen.
/// - Kategorien, Tracker und Felder ändern geht nur online (direkt an [_remote]).
class OfflineCategoriesRepository implements CategoriesRepository {
  OfflineCategoriesRepository(this._remote, {required JsonStore cache, required JsonStore queue, this.retryEvery = const Duration(seconds: 30)})
    : _cacheStore = cache,
      _queueStore = queue {
    _remote.changes.listen((_) => _changes.add(null));
  }

  final CategoriesRepository _remote;
  final JsonStore _cacheStore;
  final JsonStore _queueStore;
  final Duration retryEvery;

  final _changes = StreamController<void>.broadcast();
  List<Category>? _cached;
  var _pending = <PendingWrite>[];
  var _rejected = 0;
  Future<void>? _restoring;
  Future<void>? _syncing;
  Timer? _retry;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  SyncState get syncState => SyncState(pending: _pending.length, rejected: _rejected);

  @override
  Future<List<Category>> loadCategories() async {
    await _restore();
    await sync();
    try {
      final fresh = await _remote.loadCategories();
      _cached = fresh;
      _quietly(_cacheStore.write([for (final c in fresh) TrackingCodec.category(c)]));
    } catch (_) {
      if (_cached == null) rethrow;
    }
    return _overlay(_cached!);
  }

  @override
  Future<Category?> loadCategory(String id) async {
    await _restore();
    try {
      final fresh = await _remote.loadCategory(id);
      if (fresh != null && _cached != null) _cached = [for (final c in _cached!) c.id == id ? fresh : c];
      return fresh == null ? null : _overlay([fresh]).single;
    } catch (_) {
      final cached = _cached?.where((c) => c.id == id).firstOrNull;
      if (cached == null) rethrow;
      return _overlay([cached]).single;
    }
  }

  @override
  Future<void> saveEntry(String trackerId, Entry entry) => _enqueue(PendingSave(trackerId, entry));

  @override
  Future<void> deleteEntry(String trackerId, String entryId) => _enqueue(PendingDelete(trackerId, entryId));

  @override
  Future<void> sync() => _syncing ??= _flush().whenComplete(() => _syncing = null);

  @override
  void acknowledgeRejected() {
    if (_rejected == 0) return;
    _rejected = 0;
    _changes.add(null);
  }

  // Alles andere nur online.
  @override
  Future<String> createCategory(CategoryDraft draft) => _remote.createCategory(draft);

  @override
  Future<void> updateCategory(String id, {required String name, required CategoryIcon icon, required CategorySwatch swatch}) =>
      _remote.updateCategory(id, name: name, icon: icon, swatch: swatch);

  @override
  Future<void> setCategoryArchived(String id, {required bool archived}) => _remote.setCategoryArchived(id, archived: archived);

  @override
  Future<void> reorderCategories(List<String> ids) => _remote.reorderCategories(ids);

  @override
  Future<String> createTracker(String categoryId, String name, {required int sort}) => _remote.createTracker(categoryId, name, sort: sort);

  @override
  Future<void> renameTracker(String id, String name) => _remote.renameTracker(id, name);

  @override
  Future<void> archiveTracker(String id) => _remote.archiveTracker(id);

  @override
  Future<String> createField(String trackerId, FieldDraft draft, {required int sort}) => _remote.createField(trackerId, draft, sort: sort);

  @override
  Future<void> updateField(String id, FieldDraft draft) => _remote.updateField(id, draft);

  @override
  Future<void> archiveField(String id) => _remote.archiveField(id);

  Future<void> _restore() => _restoring ??= () async {
    try {
      if (await _cacheStore.read() case final List cached) {
        _cached = [for (final c in cached.cast<Map<String, Object?>>()) TrackingCodec.categoryFrom(c)];
      }
    } catch (_) {
      // Kaputter Cache: beim nächsten Abruf neu.
    }
    try {
      if (await _queueStore.read() case final List queued) {
        _pending = [for (final q in queued.cast<Map<String, Object?>>()) PendingWrite.fromJson(q)];
      }
    } catch (_) {
      _pending = [];
    }
    _scheduleRetry();
  }();

  Future<void> _enqueue(PendingWrite write) async {
    await _restore();
    // Neuere Änderung am selben Eintrag ersetzt die ältere.
    _pending = [..._pending.where((p) => p.entryId != write.entryId), write];
    await _persistQueue();
    _changes.add(null);
    _quietly(sync());
  }

  Future<void> _flush() async {
    await _restore();
    var sent = false;
    while (_pending.isNotEmpty) {
      final write = _pending.first;
      try {
        switch (write) {
          case PendingSave(:final trackerId, :final entry):
            await _remote.saveEntry(trackerId, entry);
          case PendingDelete(:final trackerId, :final entryId):
            await _remote.deleteEntry(trackerId, entryId);
        }
      } on WriteRejected {
        _rejected++;
      } catch (_) {
        break; // Kein Netz o. Ä.: liegen lassen, später erneut.
      }
      _pending = [..._pending.where((p) => !identical(p, write))];
      sent = true;
      await _persistQueue();
    }
    _scheduleRetry();
    if (sent) _changes.add(null);
  }

  Future<void> _persistQueue() => _queueStore.write([for (final p in _pending) p.toJson()]).catchError((Object _) {});

  void _scheduleRetry() {
    if (_pending.isEmpty) {
      _retry?.cancel();
      _retry = null;
    } else {
      _retry ??= Timer.periodic(retryEvery, (_) => _quietly(sync()));
    }
  }

  List<Category> _overlay(List<Category> categories) {
    if (_pending.isEmpty) return categories;
    return [for (final c in categories) c.copyWith(trackers: [for (final t in c.trackers) _apply(t)])];
  }

  Tracker _apply(Tracker tracker) {
    final writes = [for (final p in _pending) if (p.trackerId == tracker.id) p];
    if (writes.isEmpty) return tracker;
    final touched = {for (final w in writes) w.entryId};
    return tracker.copyWith(
      entries: [
        ...tracker.entries.where((e) => !touched.contains(e.id)),
        for (final w in writes)
          if (w case PendingSave(:final entry)) entry,
      ]..sort((a, b) => a.date.compareTo(b.date)),
    );
  }

  static void _quietly(Future<void> future) => unawaited(future.catchError((Object _) {}));
}
