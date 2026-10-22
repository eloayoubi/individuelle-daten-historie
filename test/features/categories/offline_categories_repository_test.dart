import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/utils/json_store.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/categories/data/offline_categories_repository.dart';

/// Server zum Abschalten: ohne Netz wirft jeder Aufruf, mit [reject] lehnt er Einträge ab.
class _Remote extends MockCategoriesRepository {
  var online = true;
  var reject = false;
  var saves = 0;

  Future<void> _net() async {
    if (!online) throw Exception('offline');
  }

  @override
  Future<List<Category>> loadCategories() async {
    await _net();
    return super.loadCategories();
  }

  @override
  Future<Category?> loadCategory(String id) async {
    await _net();
    return super.loadCategory(id);
  }

  @override
  Future<void> saveEntry(String trackerId, Entry entry) async {
    await _net();
    if (reject) throw const WriteRejected('42501');
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

  test('Kategorien und Felder ändern geht direkt an den Server', () async {
    await repo.updateCategory('c-strom', name: 'Strom Wohnung', icon: CategoryIcon.bolt, swatch: CategorySwatch.orange);
    expect((await remote.loadCategory('c-strom'))?.name, 'Strom Wohnung');
    remote.online = false;
    await expectLater(repo.createTracker('c-strom', 'Zweiter Zähler', sort: 1), completes);
  });
}
