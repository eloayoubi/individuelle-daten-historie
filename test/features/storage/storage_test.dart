import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/utils/ids.dart';
import 'package:kostenkurve/core/utils/json_store.dart';
import 'package:kostenkurve/features/auth/data/auth_repository.dart';
import 'package:kostenkurve/features/auth/data/mock_auth_repository.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/local_categories_repository.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/plus/data/plus_repository.dart';
import 'package:kostenkurve/features/storage/cubit/storage_cubit.dart';
import 'package:kostenkurve/features/storage/data/storage_categories_repository.dart';
import 'package:kostenkurve/features/storage/data/storage_mode.dart';
import 'package:kostenkurve/features/storage/data/storage_transfer.dart';

const _meter = FieldDraft(name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'kWh');
const _price = FieldDraft(name: 'Arbeitspreis', kind: FieldKind.currency, role: FieldRole.unitPrice, unit: '€/kWh');

/// Eine Kategorie mit Zähler und Wasser, zwei Einträge; Wasser steckt in einer zweiten Kategorie.
Future<({String strom, String miete, String zaehler, String stand})> _fill(CategoriesRepository repo) async {
  final miete = await repo.createCategory(const CategoryDraft(name: 'Miete', icon: CategoryIcon.house, swatch: CategorySwatch.brown));
  final strom = await repo.createCategory(
    const CategoryDraft(
      name: 'Strom',
      icon: CategoryIcon.bolt,
      swatch: CategorySwatch.orange,
      templateKey: 'strom',
      trackers: [
        TrackerDraft(name: 'Hauptzähler', fields: [_meter, _price]),
        TrackerDraft(name: 'Wasser', fields: [_meter]),
      ],
    ),
  );
  final category = (await repo.loadCategory(strom))!;
  final zaehler = category.trackers.first;
  final stand = zaehler.fields.first.id;
  await repo.saveEntry(zaehler.id, Entry(id: 'e1', date: DateTime.utc(2026, 1, 1), values: {stand: 1000, zaehler.fields[1].id: 0.32}));
  await repo.saveEntry(zaehler.id, Entry(id: 'e2', date: DateTime.utc(2026, 2, 1), values: {stand: 1200}));
  await repo.setTrackerIncludedIn(category.trackers[1].id, miete);
  await repo.setTrackerIcon(category.trackers[1].id, CategoryIcon.drop);
  await repo.setCategoryArchived(miete, archived: true);
  return (strom: strom, miete: miete, zaehler: zaehler.id, stand: stand);
}

/// Server, der beim ersten Eintrag die Verbindung verliert.
class _FlakyCloud extends MockCategoriesRepository {
  _FlakyCloud() : super(seed: const []);

  var failNext = true;
  var created = 0;

  @override
  Future<String> createCategory(CategoryDraft draft) {
    created++;
    return super.createCategory(draft);
  }

  @override
  Future<void> saveEntry(String trackerId, Entry entry) async {
    if (failNext) {
      failNext = false;
      throw Exception('offline');
    }
    return super.saveEntry(trackerId, entry);
  }
}

/// Prüft Einträge wie `save_entry`: mindestens ein Wert, nur Felder des Trackers, und eine Id, die
/// schon in einem anderen Tracker liegt, ist abgelehnt.
class _StrictCloud extends MockCategoriesRepository {
  _StrictCloud() : super(seed: const []);

  var failNext = false;

  @override
  Future<void> saveEntry(String trackerId, Entry entry) async {
    if (failNext) {
      failNext = false;
      throw Exception('offline');
    }
    final trackers = [for (final c in await loadCategories()) ...c.trackers];
    final tracker = trackers.firstWhere((t) => t.id == trackerId);
    if (entry.values.isEmpty) throw const WriteRejected('Ein Eintrag braucht mindestens einen Wert');
    if (entry.values.keys.any((f) => !tracker.fields.any((d) => d.id == f))) throw const WriteRejected('Feld gehört nicht zum Tracker');
    if (trackers.any((t) => t.id != trackerId && t.entries.any((e) => e.id == entry.id))) throw const WriteRejected('Der Eintrag gehört zu einem anderen Tracker');
    return super.saveEntry(trackerId, entry);
  }
}

/// Datei da, aber nicht lesbar (strikter Speicher).
class _UnreadableStore implements JsonStore {
  var writes = 0;

  @override
  Future<Object?> read() async => throw const FormatException('kaputt');

  @override
  Future<void> write(Object? json) async => writes++;
}

void main() {
  group('LocalCategoriesRepository', () {
    test('speichert in der Datei und lädt beim nächsten Start', () async {
      final store = MemoryJsonStore();
      final ids = await _fill(LocalCategoriesRepository(store));
      await Future<void>.delayed(Duration.zero);

      final restarted = LocalCategoriesRepository(store);
      final categories = await restarted.loadCategories();
      expect(categories.map((c) => c.name), ['Strom', 'Miete']);
      final strom = categories.first;
      expect(strom.trackers.first.entries.map((e) => e.id), ['e1', 'e2']);
      expect(strom.trackers.first.entries.first.values[ids.stand], 1000);
      expect(strom.trackers[1].includedIn, ids.miete);
      expect((strom.trackers.first.icon, strom.trackers[1].icon), (null, CategoryIcon.drop));
      expect(categories.last.isArchived, isTrue);
      expect(strom.id, matches(RegExp(r'^[0-9a-f-]{36}$')), reason: 'Geräte-Ids sind UUIDs wie in der Cloud');
    });

    test('kaputte Datei: Fehler statt leer überschreiben', () async {
      final store = MemoryJsonStore({
        'categories': [
          {'kaputt': true},
        ],
      });
      final repo = LocalCategoriesRepository(store);
      await expectLater(repo.loadCategories(), throwsA(anything));
      expect(await store.read(), isNotNull);
      expect(((await store.read())! as Map)['categories'], isNotEmpty);
    });

    test('Datei nicht lesbar: Fehler, und Ändern überschreibt nichts', () async {
      final store = _UnreadableStore();
      final repo = LocalCategoriesRepository(store);
      await expectLater(repo.loadCategories(), throwsA(anything));
      await expectLater(repo.createCategory(const CategoryDraft(name: 'Neu', icon: CategoryIcon.star, swatch: CategorySwatch.gray)), throwsA(anything));
      expect(store.writes, 0);
    });

    test('Teilen gibt es lokal nicht', () async {
      final repo = LocalCategoriesRepository(MemoryJsonStore());
      expect(() => repo.createInvite('x', MemberRole.editor), throwsA(isA<WriteRejected>()));
      expect(() => repo.acceptInvite('K7Q2M9X4TA'), throwsA(isA<WriteRejected>()));
    });
  });

  group('StorageCategoriesRepository', () {
    test('liest je nach Speicherort, Wechsel meldet eine Änderung', () async {
      final mode = StorageModeStore(MemoryJsonStore());
      final local = LocalCategoriesRepository(MemoryJsonStore());
      final cloud = MockCategoriesRepository();
      final repo = StorageCategoriesRepository(local: local, cloud: cloud, mode: mode);
      expect(await repo.loadCategories(), isEmpty, reason: 'Ohne Wahl: lokal');

      var changes = 0;
      final sub = repo.changes.listen((_) => changes++);
      await mode.set(StorageMode.cloud);
      await Future<void>.delayed(Duration.zero);
      expect(changes, 1);
      expect(await repo.loadCategories(), isNotEmpty);

      await repo.createCategory(const CategoryDraft(name: 'Neu', icon: CategoryIcon.star, swatch: CategorySwatch.gray));
      expect(await local.loadCategories(), isEmpty, reason: 'In der Cloud bleibt das Gerät unberührt');
      await sub.cancel();
    });

    test('Speicherort bleibt über einen Neustart', () async {
      final store = MemoryJsonStore();
      await StorageModeStore(store).set(StorageMode.local);
      final restarted = StorageModeStore(store);
      await restarted.load();
      expect(restarted.mode, StorageMode.local);
    });
  });

  group('StorageTransfer', () {
    test('hoch: neue Ids, Einträge mit ihren Werten, enthalten in und Archiv; Gerät danach leer', () async {
      final local = LocalCategoriesRepository(MemoryJsonStore());
      await _fill(local);
      final cloud = MockCategoriesRepository(seed: const []);
      final journal = MemoryJsonStore();
      final transfer = StorageTransfer(local: local, remote: cloud, cloud: cloud, journal: journal, userId: () => 'konto-a');

      await transfer.upload();

      final categories = await cloud.loadCategories();
      expect(categories.map((c) => c.name), ['Strom', 'Miete']);
      final strom = categories.first;
      final zaehler = strom.trackers.first;
      expect(zaehler.fields.map((f) => f.name), ['Zählerstand', 'Arbeitspreis']);
      expect(zaehler.entries.map((e) => e.id), [derivedId(zaehler.id, 'e1'), derivedId(zaehler.id, 'e2')], reason: 'Ids aus Tracker und Geräte-Id');
      expect(zaehler.entries.first.values, {zaehler.fields[0].id: 1000, zaehler.fields[1].id: 0.32});
      expect(strom.trackers[1].includedIn, categories.last.id);
      expect((strom.trackers.first.icon, strom.trackers[1].icon), (null, CategoryIcon.drop));
      expect(categories.last.isArchived, isTrue);
      expect(strom.templateKey, 'strom');
      expect(await local.loadCategories(), isEmpty);
      expect(await journal.read(), isNull);
    });

    test('abgebrochen: nächster Versuch legt nichts doppelt an', () async {
      final local = LocalCategoriesRepository(MemoryJsonStore());
      await _fill(local);
      final cloud = _FlakyCloud();
      final transfer = StorageTransfer(local: local, remote: cloud, cloud: cloud, journal: MemoryJsonStore(), userId: () => 'konto-a');

      await expectLater(transfer.upload(), throwsA(anything));
      expect(await local.loadCategories(), hasLength(2), reason: 'Gerät bleibt bis zum Erfolg voll');
      expect(cloud.created, 2);

      await transfer.upload();
      expect(cloud.created, 2);
      expect(await cloud.loadCategories(), hasLength(2));
      expect((await cloud.loadCategories()).first.trackers.first.entries, hasLength(2));
    });

    test('Journal eines anderen Kontos gilt nicht', () async {
      final local = LocalCategoriesRepository(MemoryJsonStore());
      await _fill(local);
      final cloud = _FlakyCloud();
      var user = 'konto-a';
      final transfer = StorageTransfer(local: local, remote: cloud, cloud: cloud, journal: MemoryJsonStore(), userId: () => user);
      await expectLater(transfer.upload(), throwsA(anything));
      user = 'konto-b';
      await transfer.upload();
      expect(cloud.created, 4, reason: 'Konto b legt selbst an, statt die Ids von Konto a zu nehmen');
    });

    test('erst runter, dann wieder hoch: Einträge landen trotz alter Kopie in der Cloud', () async {
      final cloud = _StrictCloud();
      await _fill(cloud);
      final local = LocalCategoriesRepository(MemoryJsonStore());
      final transfer = StorageTransfer(local: local, remote: cloud, cloud: cloud, journal: MemoryJsonStore(), userId: () => 'konto-a');
      await transfer.download();

      cloud.failNext = true;
      await expectLater(transfer.upload(), throwsA(anything));
      await transfer.upload();

      final categories = await cloud.loadCategories();
      expect(categories, hasLength(4), reason: 'Die alte Kopie bleibt, die hochgeladene kommt dazu');
      for (final strom in categories.where((c) => c.name == 'Strom')) {
        expect(strom.trackers.first.entries, hasLength(2), reason: 'Wiederholen legt nichts doppelt an');
      }
      expect(await local.loadCategories(), isEmpty);
    });

    test('nach Abbruch lokal ergänzt: neue Tracker und Felder ziehen mit um', () async {
      final local = LocalCategoriesRepository(MemoryJsonStore());
      final ids = await _fill(local);
      final cloud = _StrictCloud()..failNext = true;
      final transfer = StorageTransfer(local: local, remote: cloud, cloud: cloud, journal: MemoryJsonStore(), userId: () => 'konto-a');
      await expectLater(transfer.upload(), throwsA(anything));

      final extra = await local.createField(ids.zaehler, const FieldDraft(name: 'Grundpreis', kind: FieldKind.currency, role: FieldRole.recurringCost, unit: '€'), sort: 2);
      await local.saveEntry(ids.zaehler, Entry(id: 'e3', date: DateTime.utc(2026, 3, 1), values: {ids.stand: 1400, extra: 12.5}));
      final gas = await local.createTracker(ids.strom, 'Gas', sort: 2);
      final gasStand = await local.createField(gas, _meter, sort: 0);
      await local.saveEntry(gas, Entry(id: 'g1', date: DateTime.utc(2026, 3, 1), values: {gasStand: 300}));

      await transfer.upload();

      final strom = (await cloud.loadCategories()).firstWhere((c) => c.name == 'Strom');
      final zaehler = strom.trackers.first;
      expect(zaehler.fields.map((f) => f.name), ['Zählerstand', 'Arbeitspreis', 'Grundpreis']);
      expect(zaehler.entries.last.values, {zaehler.fields[0].id: 1400, zaehler.fields[2].id: 12.5});
      expect(strom.trackers.map((t) => t.name), ['Hauptzähler', 'Wasser', 'Gas']);
      expect(strom.trackers.last.entries.single.values, {strom.trackers.last.fields.single.id: 300});
      expect(await local.loadCategories(), isEmpty);
    });

    test('Journal zeigt auf eine Kategorie, die es in der Cloud nicht mehr gibt: neu anlegen', () async {
      final local = LocalCategoriesRepository(MemoryJsonStore());
      await _fill(local);
      final journal = MemoryJsonStore();
      final gone = _StrictCloud()..failNext = true;
      await expectLater(StorageTransfer(local: local, remote: gone, cloud: gone, journal: journal, userId: () => 'konto-a').upload(), throwsA(anything));

      final cloud = _StrictCloud();
      await StorageTransfer(local: local, remote: cloud, cloud: cloud, journal: journal, userId: () => 'konto-a').upload();
      expect((await cloud.loadCategories()).map((c) => c.name), ['Strom', 'Miete']);
      expect((await cloud.loadCategories()).first.trackers.first.entries, hasLength(2));
    });

    test('Einträge nur mit Werten archivierter Felder bleiben weg, statt den Umzug zu blockieren', () async {
      final local = LocalCategoriesRepository(MemoryJsonStore());
      final ids = await _fill(local);
      final preis = (await local.loadCategory(ids.strom))!.trackers.first.fields[1].id;
      await local.saveEntry(ids.zaehler, Entry(id: 'e3', date: DateTime.utc(2026, 3, 1), values: {preis: 0.35}));
      await local.archiveField(preis);
      final cloud = _StrictCloud();

      await StorageTransfer(local: local, remote: cloud, cloud: cloud, journal: MemoryJsonStore(), userId: () => 'konto-a').upload();

      final zaehler = (await cloud.loadCategories()).first.trackers.first;
      expect(zaehler.entries, hasLength(2));
      expect(await local.loadCategories(), isEmpty);
    });

    test('runter: Cloud-Kategorien als eigene, andere Gerätedaten bleiben', () async {
      final local = LocalCategoriesRepository(MemoryJsonStore());
      await local.createCategory(const CategoryDraft(name: 'Nur hier', icon: CategoryIcon.star, swatch: CategorySwatch.gray));
      final cloud = MockCategoriesRepository();
      final transfer = StorageTransfer(local: local, remote: cloud, cloud: cloud, journal: MemoryJsonStore(), userId: () => 'konto-a');

      await transfer.download();

      final categories = await local.loadCategories();
      expect(categories.map((c) => c.name), containsAll(['Strom', 'Miete & Nebenkosten', 'Nur hier']));
      final miete = categories.firstWhere((c) => c.id == 'c-miete');
      expect(miete.isShared, isFalse);
      expect(miete.myRole, MemberRole.owner);
      expect(miete.trackers.single.entries, isNotEmpty);
    });
  });

  group('StorageCubit', () {
    late StorageModeStore mode;
    late LocalCategoriesRepository local;
    late MockCategoriesRepository cloud;
    late StorageTransfer transfer;

    setUp(() {
      mode = StorageModeStore(MemoryJsonStore());
      local = LocalCategoriesRepository(MemoryJsonStore());
      cloud = MockCategoriesRepository(seed: const []);
      transfer = StorageTransfer(local: local, remote: cloud, cloud: cloud, journal: MemoryJsonStore(), userId: () => 'konto-a');
    });

    test('lokal ohne Konto: sofort, ohne Netz', () async {
      final cubit = StorageCubit(mode, transfer, MockAuthRepository(), MockPlusRepository());
      expect(await cubit.chooseLocal(), StorageEventKind.local);
      expect(cubit.state.mode, StorageMode.local);
      expect(cubit.state.busy, isFalse);
      await cubit.close();
    });

    test('Wahl zurücknehmen: lokal zurück zum Start-Bildschirm, die Cloud bleibt', () async {
      final cubit = StorageCubit(mode, transfer, MockAuthRepository(), MockPlusRepository());
      await cubit.chooseLocal();
      await cubit.backToStart();
      expect(mode.mode, isNull);
      await mode.set(StorageMode.cloud);
      await cubit.backToStart();
      expect(mode.mode, StorageMode.cloud);
      await cubit.close();
    });

    test('Cloud aktivieren: Gerätedaten ziehen um', () async {
      await _fill(local);
      final cubit = StorageCubit(mode, transfer, MockAuthRepository(), MockPlusRepository());
      expect(await cubit.activateCloud(), StorageEventKind.uploaded);
      expect(mode.mode, StorageMode.cloud);
      expect(await cloud.loadCategories(), hasLength(2));
      expect(await local.loadCategories(), isEmpty);
      await cubit.close();
    });

    test('Konto hat schon Daten: erst fragen, „auf dem Gerät lassen“ lädt nichts hoch', () async {
      await _fill(local);
      await cloud.createCategory(const CategoryDraft(name: 'Schon da', icon: CategoryIcon.star, swatch: CategorySwatch.gray));
      final cubit = StorageCubit(mode, transfer, MockAuthRepository(), MockPlusRepository());
      expect(await cubit.activateCloud(), StorageEventKind.askUpload);
      expect(mode.mode, isNull);
      expect(await cubit.activateCloud(upload: false), StorageEventKind.cloud);
      expect(mode.mode, StorageMode.cloud);
      expect(await cloud.loadCategories(), hasLength(1));
      expect(await local.loadCategories(), hasLength(2));
      await cubit.close();
    });

    test('abmelden in der Cloud führt zum Start-Bildschirm', () async {
      final auth = MockAuthRepository();
      await auth.signInWithApple();
      await mode.set(StorageMode.cloud);
      final cubit = StorageCubit(mode, transfer, auth, MockPlusRepository());
      await auth.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(mode.mode, isNull);
      expect(cubit.state.mode, isNull);
      await cubit.close();
    });

    test('Cloud ohne Sitzung beim Start: Start-Bildschirm', () async {
      await mode.set(StorageMode.cloud);
      final cubit = StorageCubit(mode, transfer, MockAuthRepository(), MockPlusRepository());
      await cubit.load();
      expect(mode.mode, isNull);
      await cubit.close();
    });

    test('aufs Gerät holen: Kopie lokal, Konto bleibt angemeldet', () async {
      final auth = MockAuthRepository();
      await auth.signInWithApple();
      await cloud.createCategory(const CategoryDraft(name: 'Strom', icon: CategoryIcon.bolt, swatch: CategorySwatch.orange));
      await mode.set(StorageMode.cloud);
      final cubit = StorageCubit(mode, transfer, auth, MockPlusRepository());
      expect(await cubit.moveToLocal(), StorageEventKind.downloaded);
      expect(mode.mode, StorageMode.local);
      expect((await local.loadCategories()).map((c) => c.name), ['Strom']);
      expect(auth.account.isRegistered, isTrue);
      await cubit.close();
    });

    test('anonymes Testkonto wählt lokal: Daten aufs Gerät, Konto weg', () async {
      final auth = MockAuthRepository(initial: MockAuthRepository.anonymous);
      await cloud.createCategory(const CategoryDraft(name: 'Aus der Testphase', icon: CategoryIcon.star, swatch: CategorySwatch.gray));
      final cubit = StorageCubit(mode, transfer, auth, MockPlusRepository());
      expect(await cubit.chooseLocal(), StorageEventKind.local);
      expect((await local.loadCategories()).map((c) => c.name), ['Aus der Testphase']);
      expect(auth.account, const AccountInfo(userId: null));
      await cubit.close();
    });

    test('anonymes Testkonto mit laufendem Abo bleibt bestehen', () async {
      final auth = MockAuthRepository(initial: MockAuthRepository.anonymous);
      final plus = MockPlusRepository();
      await plus.redeem('jws');
      final cubit = StorageCubit(mode, transfer, auth, plus);
      expect(await cubit.chooseLocal(), StorageEventKind.local);
      expect(auth.account.isSignedIn, isTrue);
      await cubit.close();
    });

    test('Umzug scheitert: Ereignis failed, Speicherort bleibt', () async {
      await _fill(local);
      final flaky = _FlakyCloud();
      final cubit = StorageCubit(mode, StorageTransfer(local: local, remote: flaky, cloud: flaky, journal: MemoryJsonStore(), userId: () => 'konto-a'), MockAuthRepository(), MockPlusRepository());
      expect(await cubit.activateCloud(), StorageEventKind.failed);
      expect(mode.mode, isNull);
      expect(cubit.state.event?.kind, StorageEventKind.failed);
      expect(await local.loadCategories(), hasLength(2));
      await cubit.close();
    });
  });
}
