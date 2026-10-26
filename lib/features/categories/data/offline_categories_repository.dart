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
///   in allen Ansichten. Gesendet wird gleich (Speichern wartet bis zu [sendWait] darauf), nach
///   jedem Abruf, beim Zurückkehren in die App ([sync]) und alle [retryEvery], solange etwas
///   wartet. Ein Eintrag hat seine Id schon vom Gerät – mehrfaches Senden ändert nichts
///   (`save_entry` ist ein Upsert).
/// - **Abgelehnt** ([WriteRejected]) wird verworfen und in [syncState] gezählt. **Gerade nicht
///   erlaubt** ([WriteHeld], z. B. Abo abgelaufen) bleibt liegen, die übrigen gehen weiter raus.
///   Bei anderen Fehlern (kein Netz) hält die Warteschlange an und versucht es später erneut.
/// - Kategorien, Tracker und Felder ändern geht nur online (direkt an [_remote]).
/// - Cache und Warteschlange gehören dem angemeldeten Konto; nach einem Wechsel werden sie verworfen.
///   Nach dem Abmelden verschwindet der Cache vom Gerät; noch nicht gesendete Einträge bleiben und
///   gehen raus, sobald sich dasselbe Konto wieder anmeldet.
class OfflineCategoriesRepository implements CategoriesRepository {
  OfflineCategoriesRepository(
    this._remote, {
    required JsonStore cache,
    required JsonStore queue,
    String? Function()? userId,
    Stream<Object?>? accountChanges,
    this.retryEvery = const Duration(seconds: 30),
    this.sendWait = const Duration(seconds: 3),
  }) : _cacheStore = cache,
       _queueStore = queue,
       _userId = userId ?? _noUser {
    _remote.changes.listen((_) => _changes.add(null));
    // Anmelden, Abmelden, Löschen: alte Daten sofort weg, alle Ansichten laden das neue Konto.
    accountChanges?.listen((_) {
      final before = _owner;
      if (_userId() == null) {
        _forgetCache();
      } else {
        _forgetOtherAccount();
      }
      if (_owner != before) _changes.add(null);
    });
  }

  final CategoriesRepository _remote;
  final JsonStore _cacheStore;
  final JsonStore _queueStore;

  /// Cache und Warteschlange gehören einem Konto; nach einem Kontowechsel gelten sie nicht mehr.
  final String? Function() _userId;
  final Duration retryEvery;

  /// So lange wartet Speichern auf den ersten Sendeversuch; danach gilt der Eintrag als offline
  /// gespeichert und wird im Hintergrund weiter gesendet.
  final Duration sendWait;

  static String? _noUser() => null;

  /// Konto, zu dem [_cached] und [_pending] gehören.
  String? _owner;

  final _changes = StreamController<void>.broadcast();
  List<Category>? _cached;
  var _pending = <PendingWrite>[];
  var _rejected = 0;
  Future<void>? _restoring;
  Future<void>? _syncing;
  Timer? _retry;

  /// Laufende Abrufe beim Server und was währenddessen gesendet wurde ([_endFetch]).
  var _fetches = 0;
  final _sentDuringFetch = <PendingWrite>[];

  /// Gerade gespeicherte Einträge, deren erster Sendeversuch noch läuft. Solange zeigen alle
  /// Ansichten den Stand auf dem Gerät, statt aufs Netz zu warten.
  var _sendingNew = 0;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  SyncState get syncState {
    final held = _pending.where((p) => _heldIds.contains(p.entryId)).length;
    return SyncState(pending: _pending.length - held, rejected: _rejected, held: held);
  }

  /// Einträge, die der Server beim letzten Senden zurückgehalten hat ([WriteHeld]).
  var _heldIds = <String>{};

  @override
  Future<List<Category>> loadCategories() async {
    await _restore();
    _forgetOtherAccount();
    if (_sendingNew > 0 && _cached != null) return _overlay(_cached!);
    await sync();
    final mark = _beginFetch();
    try {
      _cached = _endFetch(mark, await _remote.loadCategories());
      _owner = _userId();
      _quietly(_persistCache());
    } catch (_) {
      if (_cached == null) rethrow;
    } finally {
      _fetchDone();
    }
    return _overlay(_cached!);
  }

  /// Ein anderes Konto ist angemeldet: dessen Daten nicht zeigen, wartende Einträge verwerfen.
  void _forgetOtherAccount() {
    final current = _userId();
    if (current == null || _owner == null || current == _owner) return;
    _cached = null;
    _pending = [];
    _owner = current;
    _quietly(_persistQueue());
    _quietly(_cacheStore.write(null));
  }

  /// Abgemeldet: keine Cloud-Daten mehr auf dem Gerät lesbar lassen.
  void _forgetCache() {
    if (_cached == null) return;
    _cached = null;
    _quietly(_cacheStore.write(null));
  }

  @override
  Future<Category?> loadCategory(String id) async {
    await _restore();
    _forgetOtherAccount();
    if (_sendingNew > 0) {
      if (_cached?.where((c) => c.id == id).firstOrNull case final cached?) return _overlay([cached]).single;
    }
    final mark = _beginFetch();
    try {
      final loaded = await _remote.loadCategory(id);
      final fresh = loaded == null ? null : _endFetch(mark, [loaded]).single;
      if (fresh != null && _cached != null) _cached = [for (final c in _cached!) c.id == id ? fresh : c];
      return fresh == null ? null : _overlay([fresh]).single;
    } catch (_) {
      final cached = _cached?.where((c) => c.id == id).firstOrNull;
      if (cached == null) rethrow;
      return _overlay([cached]).single;
    } finally {
      _fetchDone();
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

  @override
  bool isWaiting(String entryId) => _pending.any((p) => p.entryId == entryId);

  @override
  Future<void> discardHeld() async {
    await _restore();
    if (_heldIds.isEmpty) return;
    _pending = [..._pending.where((p) => !_heldIds.contains(p.entryId))];
    _heldIds = {};
    await _persistQueue();
    _changes.add(null);
  }

  // Alles andere nur online.
  @override
  Future<String> createCategory(CategoryDraft draft) => _remote.createCategory(draft);

  @override
  Future<void> updateCategory(String id, {required String name, required CategoryIcon icon, required CategorySwatch swatch}) =>
      _remote.updateCategory(id, name: name, icon: icon, swatch: swatch);

  @override
  Future<void> updateDashboard(String id, CategoryDashboard dashboard) => _remote.updateDashboard(id, dashboard);

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
  Future<void> setTrackerIncludedIn(String id, String? categoryId) => _remote.setTrackerIncludedIn(id, categoryId);

  @override
  Future<String> createField(String trackerId, FieldDraft draft, {required int sort}) => _remote.createField(trackerId, draft, sort: sort);

  @override
  Future<void> updateField(String id, FieldDraft draft) => _remote.updateField(id, draft);

  @override
  Future<void> archiveField(String id) => _remote.archiveField(id);

  @override
  Future<String> createInvite(String categoryId, MemberRole role) => _remote.createInvite(categoryId, role);

  @override
  Future<String> acceptInvite(String code) => _remote.acceptInvite(code);

  @override
  Future<void> setMemberRole(String categoryId, String userId, MemberRole role) => _remote.setMemberRole(categoryId, userId, role);

  @override
  Future<void> removeMember(String categoryId, String userId) => _remote.removeMember(categoryId, userId);

  @override
  Future<void> leaveCategory(String categoryId) => _remote.leaveCategory(categoryId);

  Future<void> _restore() => _restoring ??= () async {
    final current = _userId();
    try {
      if (await _cacheStore.read() case {'userId': final String? owner, 'categories': final List cached} when current == null || owner == current) {
        _cached = [for (final c in cached.cast<Map<String, Object?>>()) TrackingCodec.categoryFrom(c)];
        _owner = owner;
      }
    } catch (_) {
      // Kaputter Cache: beim nächsten Abruf neu.
    }
    try {
      if (await _queueStore.read() case {'userId': final String? owner, 'writes': final List queued} when current == null || owner == current) {
        _pending = [for (final q in queued.cast<Map<String, Object?>>()) PendingWrite.fromJson(q)];
        _owner ??= owner;
      }
    } catch (_) {
      _pending = [];
    }
    _owner ??= current;
    _scheduleRetry();
  }();

  Future<void> _enqueue(PendingWrite write) async {
    await _restore();
    // Neuere Änderung am selben Eintrag ersetzt die ältere.
    _pending = [..._pending.where((p) => p.entryId != write.entryId), write];
    await _persistQueue();
    // Gleich senden und darauf warten, damit der Aufrufer an [syncState] sieht, ob der Eintrag schon
    // auf dem Server ist. Die Ansichten laden derweil vom Gerät und zeigen ihn sofort.
    _sendingNew++;
    _changes.add(null);
    try {
      await sync().timeout(sendWait, onTimeout: () {});
    } finally {
      _sendingNew--;
    }
  }

  Future<void> _flush() async {
    await _restore();
    var sent = false;
    // Gerade nicht erlaubt: bleibt liegen, die übrigen gehen trotzdem raus.
    final held = Set<PendingWrite>.identity();
    while (true) {
      final write = _pending.where((p) => !held.contains(p)).firstOrNull;
      if (write == null) break;
      try {
        switch (write) {
          case PendingSave(:final trackerId, :final entry):
            await _remote.saveEntry(trackerId, entry);
          case PendingDelete(:final trackerId, :final entryId):
            await _remote.deleteEntry(trackerId, entryId);
        }
        // Der Server hat ihn: auch im Cache, damit er ohne neuen Abruf nicht verschwindet.
        if (_cached case final cached?) {
          _cached = _applyAll(cached, [write]);
          _quietly(_persistCache());
        }
        if (_fetches > 0) _sentDuringFetch.add(write);
      } on WriteHeld {
        held.add(write);
        continue;
      } on WriteRejected {
        _rejected++;
      } catch (_) {
        break; // Kein Netz o. Ä.: liegen lassen, später erneut.
      }
      _pending = [..._pending.where((p) => !identical(p, write))];
      sent = true;
      await _persistQueue();
    }
    final heldIds = {for (final w in held) w.entryId};
    final heldChanged = heldIds.length != _heldIds.length || !heldIds.containsAll(_heldIds);
    _heldIds = heldIds;
    _scheduleRetry();
    if (sent || heldChanged) _changes.add(null);
  }

  /// Ein Abruf beginnt: Was ab jetzt gesendet wird, fehlt womöglich in seiner Antwort.
  int _beginFetch() {
    _fetches++;
    return _sentDuringFetch.length;
  }

  /// Wendet auf [fresh] an, was seit [mark] gesendet wurde, damit eine ältere Antwort den gerade
  /// gesendeten Eintrag nicht wieder aus dem Cache wirft.
  List<Category> _endFetch(int mark, List<Category> fresh) => _applyAll(fresh, _sentDuringFetch.sublist(mark));

  void _fetchDone() {
    if (--_fetches == 0) _sentDuringFetch.clear();
  }

  Future<void> _persistQueue() => _queueStore.write({'userId': _owner ?? _userId(), 'writes': [for (final p in _pending) p.toJson()]}).catchError((Object _) {});

  Future<void> _persistCache() => _cacheStore.write({'userId': _owner, 'categories': [for (final c in _cached ?? const <Category>[]) TrackingCodec.category(c)]});

  void _scheduleRetry() {
    if (_pending.isEmpty) {
      _retry?.cancel();
      _retry = null;
    } else {
      _retry ??= Timer.periodic(retryEvery, (_) => _quietly(sync()));
    }
  }

  List<Category> _overlay(List<Category> categories) => _applyAll(categories, _pending);

  static List<Category> _applyAll(List<Category> categories, List<PendingWrite> writes) {
    if (writes.isEmpty) return categories;
    return [for (final c in categories) c.copyWith(trackers: [for (final t in c.trackers) _apply(t, writes)])];
  }

  static Tracker _apply(Tracker tracker, List<PendingWrite> all) {
    final writes = [for (final p in all) if (p.trackerId == tracker.id) p];
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
