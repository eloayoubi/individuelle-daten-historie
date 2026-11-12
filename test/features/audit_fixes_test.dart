// Regressionstests zum Audit vom 12.11.2026 – je Befund der Fall, der vorher falsch lief.
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/config/app_config.dart';
import 'package:kostenkurve/core/utils/json_store.dart';
import 'package:kostenkurve/core/utils/numbers.dart';
import 'package:kostenkurve/features/categories/cubit/field_editor_cubit.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/local_categories_repository.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/categories/data/offline_categories_repository.dart';
import 'package:kostenkurve/features/reminders/data/notification_gateway.dart';
import 'package:kostenkurve/features/reminders/data/reminder_service.dart';
import 'package:kostenkurve/features/settings/data/data_export.dart';
import 'package:kostenkurve/features/sharing/data/invite_links.dart';
import 'package:kostenkurve/features/storage/data/storage_transfer.dart';
import 'package:kostenkurve/features/update/view/force_update_page.dart';
import 'package:kostenkurve/l10n/generated/app_localizations.dart';

/// Server zum Abschalten: ohne Netz wirft jeder Abruf.
class _Server extends MockCategoriesRepository {
  var online = true;

  @override
  Future<List<Category>> loadCategories() async {
    if (!online) throw Exception('offline');
    return super.loadCategories();
  }

  @override
  Future<void> saveEntry(String trackerId, Entry entry) async {
    if (!online) throw Exception('offline');
    return super.saveEntry(trackerId, entry);
  }
}

void main() {
  group('Zahlen', () {
    double? de(String t) => parseNumber(t, decimalSeparator: ',');
    double? en(String t) => parseNumber(t, decimalSeparator: '.');

    test('Infinity, NaN und Überlauf sind keine Zahl', () {
      for (final text in ['Infinity', '-Infinity', 'NaN', '1e999', '-1e999']) {
        expect(de(text), isNull, reason: text);
        expect(en(text), isNull, reason: text);
      }
      expect(de('1e3'), 1000);
    });

    test('beide Trenner in der falschen Reihenfolge: keine Zahl statt der falschen', () {
      expect(de('1,234.5'), isNull);
      expect(en('1.234,5'), isNull);
      // Die richtige Reihenfolge bleibt.
      expect(de('1.234,5'), 1234.5);
      expect(en('1,234.5'), 1234.5);
    });

    test('Umrechnungsfaktor im Feld-Editor nur endlich', () {
      expect(FieldEditorState.parseDecimal('Infinity'), isNull);
      expect(FieldEditorState.parseDecimal('NaN'), isNull);
      expect(FieldEditorState.parseDecimal('10,35'), 10.35);
    });
  });

  group('CSV-Export', () {
    const header = ['Kategorie', 'Tracker', 'Datum', 'Feld', 'Wert', 'Einheit', 'Notiz', 'Von', 'Bis'];
    const de = ExportLabels(header: header, yes: 'Ja', no: 'Nein');

    test('Text, der wie eine Formel beginnt, wird entschärft – Zahlen bleiben Zahlen', () {
      const amount = FieldDefinition(id: 'betrag', name: 'Betrag', kind: FieldKind.currency, role: FieldRole.oneOffCost, unit: '€');
      const name = FieldDefinition(id: 'name', name: '@Feld', kind: FieldKind.text);
      final category = Category(
        id: 'c',
        name: '=1+1',
        icon: CategoryIcon.doc,
        swatch: CategorySwatch.gray,
        trackers: [
          Tracker(
            id: 't',
            name: '-Zähler',
            fields: const [amount, name],
            entries: [Entry(id: 'e', date: DateTime.utc(2026), values: const {'betrag': -12.5, 'name': '=HYPERLINK("http://x")'}, note: '+49 170')],
          ),
        ],
      );
      final lines = DataExport.csv([category], de).split('\r\n');
      expect(lines[1], "'=1+1;'-Zähler;2026-01-01;Betrag;-12,5;€;'+49 170;;");
      expect(lines[2], "'=1+1;'-Zähler;2026-01-01;'@Feld;\"'=HYPERLINK(\"\"http://x\"\")\";;'+49 170;;");
    });

    test('gewöhnlicher Text bleibt unverändert', () {
      final csv = DataExport.csv(MockCategoriesRepository.categories, de);
      expect(csv, isNot(contains("'")));
    });
  });

  group('Einladungslink', () {
    Uri link(String code) => Uri.parse('${AppConfig.appScheme}://invite?code=$code');

    test('nur Codes aus Buchstaben und Ziffern in üblicher Länge', () {
      expect(InviteLinks.codeOf(link('k7q2m9x4ta')), 'K7Q2M9X4TA');
      expect(InviteLinks.codeOf(link('A' * 17)), isNull);
      expect(InviteLinks.codeOf(link('abc')), isNull);
      expect(InviteLinks.codeOf(link('K7Q2%3Cscript%3E')), isNull);
      expect(InviteLinks.codeOf(link('K7Q2%0AM9X4')), isNull);
      expect(InviteLinks.codeOf(link('')), isNull);
    });
  });

  group('Pflicht-Update', () {
    final fallback = Uri.parse(AppConfig.testFlightUrl);

    test('öffnet nur https-Adressen bei Apple, sonst den festen TestFlight-Link', () {
      expect(ForceUpdatePage.storeUri('https://apps.apple.com/de/app/kostenkurve/id123'), Uri.parse('https://apps.apple.com/de/app/kostenkurve/id123'));
      expect(ForceUpdatePage.storeUri('https://testflight.apple.com/join/abc'), Uri.parse('https://testflight.apple.com/join/abc'));
      for (final url in [null, '', 'tel:+4930123', 'http://apps.apple.com/x', 'https://apps.apple.com.evil.example/x', 'https://evil.example/?apps.apple.com', 'itms-services://?action=x', '::kein-link']) {
        expect(ForceUpdatePage.storeUri(url), fallback, reason: '$url');
      }
    });
  });

  group('Offline-Schicht', () {
    late _Server server;
    late MemoryJsonStore cache;
    late MemoryJsonStore queue;

    Entry reading(String id, int value) => Entry(id: id, date: DateTime.utc(2026, 10, 20), values: {'f-strom-stand': value});

    setUp(() {
      server = _Server();
      cache = MemoryJsonStore();
      queue = MemoryJsonStore();
    });

    OfflineCategoriesRepository repo() => OfflineCategoriesRepository(server, cache: cache, queue: queue, retryEvery: const Duration(hours: 1));

    test('ein unlesbarer Eintrag in der Warteschlange kostet nicht die übrigen', () async {
      final first = repo();
      await first.loadCategories();
      server.online = false;
      await first.saveEntry('t-strom', reading('neu-1', 47100));
      await first.saveEntry('t-strom', reading('neu-2', 47200));
      await pumpEventQueue();
      expect(first.syncState.pending, 2);

      final stored = (await queue.read())! as Map<String, Object?>;
      final writes = [...stored['writes']! as List];
      writes[0] = {...writes[0] as Map, 'op': 'unbekannt'};
      await queue.write({...stored, 'writes': [...writes, 'kein-objekt']});

      final next = repo();
      await next.loadCategories();
      expect(next.syncState.pending, 1);
      final entries = (await next.loadCategory('c-strom'))!.trackers.single.entries;
      expect(entries.map((e) => e.id), contains('neu-2'));
    });

    test('meldet, ob der Stand vom Server kam oder aus dem Cache', () async {
      final offline = repo();
      await offline.loadCategories();
      expect(offline.servedFromServer, isTrue);
      server.online = false;
      await offline.loadCategories();
      expect(offline.servedFromServer, isFalse);
    });

    test('Umzug aufs Gerät bricht ab, wenn nur der Cache antwortet', () async {
      final cloud = repo();
      final local = LocalCategoriesRepository(MemoryJsonStore());
      final transfer = StorageTransfer(local: local, remote: server, cloud: cloud, journal: MemoryJsonStore(), userId: () => 'konto-a');
      await cloud.loadCategories();

      server.online = false;
      await expectLater(transfer.download(), throwsStateError);
      expect(await local.loadCategories(), isEmpty, reason: 'nichts aus dem Cache übernommen');

      server.online = true;
      await transfer.download();
      expect(await local.loadCategories(), hasLength(MockCategoriesRepository.categories.length));
    });
  });

  group('Erinnerungen', () {
    final l10n = lookupAppLocalizations(const Locale('de'));
    final now = DateTime(2026, 10, 22, 9, 30);

    test('nach Abmelden oder Kontowechsel bleibt kein Plan des vorigen Kontos stehen', () async {
      final server = _Server();
      final gateway = MemoryNotificationGateway();
      String? user = 'konto-a';
      final service = ReminderService(server, gateway, MemoryJsonStore(), texts: () => l10n, now: () => now, userId: () => user, debounce: Duration.zero);
      expect(await service.enable(), isTrue);
      expect(gateway.scheduled, isNotEmpty);

      // Gleiches Konto, kurz ohne Netz: Der Plan bleibt.
      server.online = false;
      await service.reschedule();
      expect(gateway.scheduled, isNotEmpty);

      // Abgemeldet: Laden scheitert, der Plan geht trotzdem.
      user = null;
      await service.reschedule();
      expect(gateway.scheduled, isEmpty);

      // Wieder angemeldet und online: neuer Plan.
      user = 'konto-b';
      server.online = true;
      await service.reschedule();
      expect(gateway.scheduled, isNotEmpty);
    });
  });
}
