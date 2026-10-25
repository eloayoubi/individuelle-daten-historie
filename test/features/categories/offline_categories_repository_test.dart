import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/utils/json_store.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/categories/data/offline_categories_repository.dart';

/// Server zum Abschalten: ohne Netz wirft jeder Aufruf, mit [reject] lehnt er Einträge ab,
/// mit [gate] hält er Einträge an, bis es aufgeht (langsames Netz).
class _Remote extends MockCategoriesRepository {
  var online = true;
  var reject = false;
  var saves = 0;
  Completer<void>? gate;

  /// Tracker, in die der Server gerade nicht schreiben lässt (Abo abgelaufen, nur noch Leserechte).
  final held = <String>{};

  /// Hält den nächsten Abruf an, nachdem er den Stand gelesen hat (Antwort unterwegs).
  Completer<void>? fetchGate;

  Future<void> _net() async {
    if (!online) throw Exception('offline');
  }

  @override
  Future<List<Category>> loadCategories() async {
    await _net();
    final snapshot = await super.loadCategories();
    final wait = fetchGate;
    fetchGate = null;
    await wait?.future;
    return snapshot;
  }

  @override
  Future<Category?> loadCategory(String id) async {
    await _net();
    return super.loadCategory(id);
  }

  @override
  Future<void> saveEntry(String trackerId, Entry entry) async {
    await _net();
    await gate?.future;
    if (reject) throw const WriteRejected('22P02');
    if (held.contains(trackerId)) throw const WriteHeld('42501');
    saves++;
    return super.saveEntry(trackerId, entry);
  }

  @override
  Future<void> deleteEntry(String trackerId, String entryId) async {
    await _net();
    return super.deleteEntry(trackerId, entryId);
  }
}

void main() {
  late _Remote remote;
  late MemoryJsonStore cache;
  late MemoryJsonStore queue;
  late OfflineCategoriesRepository repo;

  final reading = Entry(id: 'neu-1', date: DateTime.utc(2026, 10, 20), values: const {'f-strom-stand': 47100});

  Future<Tracker> strom(CategoriesRepository r) async => (await r.loadCategory('c-strom'))!.trackers.single;

  setUp(() {
    remote = _Remote();
    cache = MemoryJsonStore();
    queue = MemoryJsonStore();
    repo = OfflineCategoriesRepository(remote, cache: cache, queue: queue, retryEvery: const Duration(hours: 1));
  });

  test('liest ohne Netz aus dem Cache des letzten Abrufs', () async {
    await repo.loadCategories();
    remote.online = false;
    final fresh = OfflineCategoriesRepository(remote, cache: cache, queue: queue);
    expect(await fresh.loadCategories(), hasLength(MockCategoriesRepository.categories.length));
    expect((await fresh.loadCategory('c-auto'))?.name, 'Auto');
  });

  test('ohne Netz und ohne Cache gibt es einen Fehler', () async {
    remote.online = false;
    await expectLater(repo.loadCategories(), throwsException);
  });

  test('ein offline erfasster Eintrag erscheint sofort und wartet in der Warteschlange', () async {
    await repo.loadCategories();
    remote.online = false;
    await repo.saveEntry('t-strom', reading);
    // Der Sendeversuch im Hintergrund scheitert noch offline.
    await pumpEventQueue();
    expect(repo.syncState, const SyncState(pending: 1));
    expect((await strom(repo)).entries.last, reading);
    expect((await strom(remote..online = true)).entries.where((e) => e.id == 'neu-1'), isEmpty);
    expect((await queue.read())! as Map, containsPair('writes', hasLength(1)));
  });

  test('mit Netz ist ein Eintrag nach dem Speichern schon auf dem Server', () async {
    await repo.loadCategories();
    await repo.saveEntry('t-strom', reading);
    // Kein Warten auf den Hintergrund: Das Formular entscheidet direkt danach über „offline“.
    expect(repo.syncState, const SyncState());
    expect(remote.saves, 1);
  });

  test('hängt das Netz, wartet Speichern höchstens sendWait', () async {
    final slow = OfflineCategoriesRepository(
      remote,
      cache: cache,
      queue: queue,
      retryEvery: const Duration(hours: 1),
      sendWait: const Duration(milliseconds: 20),
    );
    await slow.loadCategories();
    remote.gate = Completer<void>();
    await slow.saveEntry('t-strom', reading).timeout(const Duration(seconds: 1));
    expect(slow.syncState.pending, 1);
    remote.gate!.complete();
    await slow.sync();
    expect(slow.syncState, const SyncState());
    expect(remote.saves, 1);
  });

  test('während gesendet wird, zeigen alle Ansichten den Eintrag sofort – ohne aufs Netz zu warten', () async {
    await repo.loadCategories();
    remote.gate = Completer<void>();
    final shown = Completer<(List<Category>, Tracker)>();
    final subscription = repo.changes.listen((_) async {
      if (shown.isCompleted) return;
      final all = await repo.loadCategories();
      final one = await strom(repo);
      if (!shown.isCompleted) shown.complete((all, one));
    });
    final saving = repo.saveEntry('t-strom', reading);
    final (all, one) = await shown.future.timeout(const Duration(seconds: 1));
    expect(all.firstWhere((c) => c.id == 'c-strom').trackers.single.entries.last, reading);
    expect(one.entries.last, reading);
    expect(remote.saves, 0);
    remote.gate!.complete();
    await saving;
    expect(repo.syncState, const SyncState());
    await subscription.cancel();
  });

  test('ein gesendeter Eintrag steht im Cache, auch ohne neuen Abruf', () async {
    await repo.loadCategories();
    await repo.saveEntry('t-strom', reading);
    remote.online = false;
    final restarted = OfflineCategoriesRepository(remote, cache: cache, queue: queue);
    expect((await strom(restarted)).entries.last, reading);
  });

  test('wird nachgesendet, sobald wieder Netz da ist – auch nach einem Neustart', () async {
    await repo.loadCategories();
    remote.online = false;
    await repo.saveEntry('t-strom', reading);
    await pumpEventQueue();

    remote.online = true;
    final restarted = OfflineCategoriesRepository(remote, cache: cache, queue: queue);
    await restarted.sync();
    expect(restarted.syncState, const SyncState());
    expect(remote.saves, 1);
    expect((await strom(remote)).entries.last.id, 'neu-1');
    expect((await queue.read())! as Map, containsPair('writes', isEmpty));
  });

  test('mehrfaches Senden schadet nicht: die Id kommt vom Gerät', () async {
    await repo.saveEntry('t-strom', reading);
    await repo.saveEntry('t-strom', reading);
    await repo.sync();
    expect((await strom(remote)).entries.where((e) => e.id == 'neu-1'), hasLength(1));
  });

  test('eine neuere Änderung ersetzt die wartende, Löschen gewinnt', () async {
    remote.online = false;
    await repo.saveEntry('t-strom', reading);
    await repo.saveEntry('t-strom', Entry(id: 'neu-1', date: reading.date, values: const {'f-strom-stand': 47200}));
    await pumpEventQueue();
    expect(repo.syncState.pending, 1);
    await repo.deleteEntry('t-strom', 'neu-1');
    await pumpEventQueue();
    expect(repo.syncState.pending, 1);
    remote.online = true;
    await repo.sync();
    expect((await strom(remote)).entries.where((e) => e.id == 'neu-1'), isEmpty);
  });

  test('vom Server abgelehnt: verworfen und gezählt, bis der Nutzer es bestätigt', () async {
    remote.reject = true;
    final changes = <void>[];
    repo.changes.listen(changes.add);
    await repo.saveEntry('t-strom', reading);
    await repo.sync();
    expect(repo.syncState, const SyncState(rejected: 1));
    repo.acknowledgeRejected();
    expect(repo.syncState, const SyncState());
    await pumpEventQueue();
    expect(changes, isNotEmpty);
  });

  test('gerade nicht erlaubt: bleibt in der Warteschlange, die übrigen Einträge gehen trotzdem raus', () async {
    await repo.loadCategories();
    remote.held.add('t-strom');
    await repo.saveEntry('t-strom', reading);
    final gas = Entry(id: 'neu-2', date: DateTime.utc(2026, 10, 20), values: const {'f-gas-stand': 900});
    await repo.saveEntry('t-gas', gas);
    await repo.sync();
    expect(remote.saves, 1, reason: 'Der Gas-Eintrag wartet nicht auf den abgelehnten Strom-Eintrag');
    expect(repo.syncState, const SyncState(held: 1), reason: 'Zurückgehalten ist nicht „wartet auf Verbindung“');
    expect(repo.isWaiting('neu-1'), isTrue);
    expect(repo.isWaiting('neu-2'), isFalse);
    expect((await queue.read())! as Map, containsPair('writes', hasLength(1)));

    remote.held.clear();
    await repo.sync();
    expect(repo.syncState, const SyncState());
    expect(remote.saves, 2);
  });

  test('zurückgehaltene Einträge lassen sich verwerfen', () async {
    await repo.loadCategories();
    remote.held.add('t-strom');
    await repo.saveEntry('t-strom', reading);
    expect(repo.syncState, const SyncState(held: 1));
    await repo.discardHeld();
    expect(repo.syncState, const SyncState());
    expect(repo.isWaiting('neu-1'), isFalse);
    expect((await queue.read())! as Map, containsPair('writes', isEmpty));
    expect((await strom(repo)).entries.map((e) => e.id), isNot(contains('neu-1')));
  });

  test('ein Abruf, der vor dem Senden begann, wirft den gesendeten Eintrag nicht wieder aus dem Cache', () async {
    await repo.loadCategories();
    final answer = remote.fetchGate = Completer<void>();
    final loading = repo.loadCategories();
    await pumpEventQueue();
    await repo.saveEntry('t-strom', reading);
    expect(repo.syncState, const SyncState());
    answer.complete();
    final loaded = await loading;
    expect(loaded.firstWhere((c) => c.id == 'c-strom').trackers.single.entries.last, reading);
    remote.online = false;
    expect((await strom(repo)).entries.last, reading);
  });

  test('Cache und Warteschlange eines anderen Kontos gelten nicht', () async {
    var user = 'a';
    final mine = OfflineCategoriesRepository(remote, cache: cache, queue: queue, userId: () => user, retryEvery: const Duration(hours: 1));
    await mine.loadCategories();
    remote.online = false;
    await mine.saveEntry('t-strom', reading);
    await pumpEventQueue();
    user = 'b';
    final other = OfflineCategoriesRepository(remote, cache: cache, queue: queue, userId: () => user);
    await expectLater(other.loadCategories(), throwsException);
    expect(other.syncState.pending, 0);
    // Wechsel während die App läuft: alter Stand wird verworfen.
    await expectLater(mine.loadCategories(), throwsException);
    expect(mine.syncState.pending, 0);
  });

  test('Kontowechsel über den Strom: alter Stand sofort weg, Ansichten laden neu', () async {
    var user = 'a';
    final switches = StreamController<Object?>();
    final mine = OfflineCategoriesRepository(remote, cache: cache, queue: queue, userId: () => user, accountChanges: switches.stream);
    await mine.loadCategories();
    final changes = <void>[];
    mine.changes.listen(changes.add);
    // Gleiches Konto (z. B. Name geändert): nichts passiert.
    switches.add(null);
    await pumpEventQueue();
    expect(changes, isEmpty);
    user = 'b';
    switches.add(null);
    await pumpEventQueue();
    expect(changes, hasLength(1));
    expect(await cache.read(), isNull);
    await switches.close();
  });

  test('abmelden: Cache weg, wartende Einträge bleiben fürs selbe Konto', () async {
    String? user = 'a';
    final accounts = StreamController<Object?>();
    final mine = OfflineCategoriesRepository(remote, cache: cache, queue: queue, userId: () => user, accountChanges: accounts.stream, retryEvery: const Duration(hours: 1));
    await mine.loadCategories();
    remote.online = false;
    await mine.saveEntry((await strom(mine)).id, reading);
    user = null;
    accounts.add(null);
    await pumpEventQueue();
    expect(await cache.read(), isNull);
    expect(mine.syncState.pending, 1);
    await accounts.close();
  });

  test('Kategorien und Felder ändern geht direkt an den Server', () async {
    await repo.updateCategory('c-strom', name: 'Strom Wohnung', icon: CategoryIcon.bolt, swatch: CategorySwatch.orange);
    expect((await remote.loadCategory('c-strom'))?.name, 'Strom Wohnung');
    remote.online = false;
    await expectLater(repo.createTracker('c-strom', 'Zweiter Zähler', sort: 1), completes);
  });
}
