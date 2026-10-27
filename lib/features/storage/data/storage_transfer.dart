import 'dart:async';

import '../../../core/utils/ids.dart';
import '../../../core/utils/json_store.dart';
import '../../categories/data/categories_repository.dart';
import '../../categories/data/local_categories_repository.dart';

/// Umzug der Daten zwischen Gerät und Cloud.
///
/// **Hoch** ([upload]): jede Kategorie per `create_category` neu anlegen, Tracker und Felder über
/// ihre Reihenfolge zuordnen, Einträge unter einer aus Tracker und Geräte-Id abgeleiteten Id senden
/// (`save_entry` ist ein Upsert), danach „enthalten in“ und Archiv setzen. Ein Journal merkt sich je
/// Konto jede angelegte Kategorie: Bricht der Umzug ab, legt der nächste Versuch mit demselben Konto
/// nichts doppelt an (nur ein Absturz genau zwischen Anlegen und Merken kann eine Kategorie doppeln)
/// und ergänzt, was lokal seitdem dazukam. Erst wenn jeder Eintrag oben ist, wird das Gerät geleert.
///
/// **Runter** ([download]): alle sichtbaren Kategorien als eigene Kopie aufs Gerät (ohne Mitglieder
/// und Belege); gleiche Ids werden ersetzt, andere lokale Kategorien bleiben.
class StorageTransfer {
  StorageTransfer({required this.local, required this.remote, required this.cloud, required this.journal, required this.userId});

  final LocalCategoriesRepository local;

  /// Supabase direkt, ohne Warteschlange: Jeder Schritt ist bestätigt, bevor der nächste kommt.
  final CategoriesRepository remote;

  /// Cloud mit Offline-Schicht: liest auch ohne Netz aus dem Cache und kennt wartende Einträge.
  final CategoriesRepository cloud;
  /// Welche lokalen Kategorien schon in der Cloud angelegt sind (für einen abgebrochenen Umzug):
  /// `{"userId": "…", "categories": {"<lokal>": {"id", "trackers", "fields"}}}`.
  final JsonStore journal;

  /// Angemeldetes Konto; das Journal eines anderen Kontos gilt nicht.
  final String? Function() userId;

  /// Gleichzeitig gesendete Einträge.
  static const parallel = 6;

  Future<bool> localHasData() async => (await local.loadCategories()).isNotEmpty;

  Future<bool> cloudHasData() async => (await remote.loadCategories()).isNotEmpty;

  Future<void> upload() async {
    final categories = await local.loadCategories();
    final created = await _readJournal();
    final categoryIds = <String, String>{};
    final trackerIds = <String, String>{};
    final fieldIds = <String, String>{};
    for (final c in categories) {
      final mapped = await _ensure(c, created[c.id]);
      created[c.id] = mapped;
      await journal.write({'userId': userId(), 'categories': created});
      categoryIds[c.id] = mapped['id']! as String;
      trackerIds.addAll((mapped['trackers']! as Map).cast<String, String>());
      fieldIds.addAll((mapped['fields']! as Map).cast<String, String>());
    }

    // Die Cloud-Id leitet sich aus neuem Tracker und Geräte-Id ab: Nach einem Umzug aufs Gerät liegt
    // die alte Kopie mit den ursprünglichen Ids noch in der Cloud, `save_entry` lehnte sie für den
    // neuen Tracker ab. Wiederholen trifft dieselben Ids.
    final expected = <String, Set<String>>{};
    final writes = <Future<void> Function()>[];
    for (final c in categories) {
      for (final t in c.trackers) {
        final tracker = trackerIds[t.id]!;
        for (final e in t.entries) {
          // Werte archivierter Felder haben kein Gegenstück mehr und bleiben weg; ein Eintrag ganz
          // ohne Werte (nur noch Datum und Notiz) wird ausgelassen, statt den Umzug zu blockieren –
          // er geht dabei verloren, hatte aber nichts mehr, was die App zeigt oder rechnet.
          final values = {for (final MapEntry(:key, :value) in e.values.entries) ?fieldIds[key]: value};
          if (values.isEmpty) continue;
          final id = derivedId(tracker, e.id);
          (expected[categoryIds[c.id]!] ??= {}).add(id);
          writes.add(() => remote.saveEntry(tracker, e.copyWith(id: id, values: values)));
        }
      }
    }
    for (var i = 0; i < writes.length; i += parallel) {
      await Future.wait([for (final write in writes.skip(i).take(parallel)) write()]);
    }

    for (final c in categories) {
      for (final t in c.trackers) {
        if (t.includedIn case final target? when categoryIds.containsKey(target)) await remote.setTrackerIncludedIn(trackerIds[t.id]!, categoryIds[target]);
        if (t.icon != null) await remote.setTrackerIcon(trackerIds[t.id]!, t.icon);
      }
      if (!c.dashboard.isDefault) await remote.updateDashboard(categoryIds[c.id]!, c.dashboard.remap(trackerIds, fieldIds));
      if (c.isArchived) await remote.setCategoryArchived(categoryIds[c.id]!, archived: true);
    }

    // Das Gerät hat oft die einzige Kopie: erst leeren, wenn jeder Eintrag oben angekommen ist.
    for (final MapEntry(key: id, value: entries) in expected.entries) {
      final uploaded = await remote.loadCategory(id);
      final found = {for (final t in uploaded?.trackers ?? const <Tracker>[]) for (final e in t.entries) e.id};
      if (!found.containsAll(entries)) throw StateError('transfer_incomplete $id');
    }
    await local.clear();
    await journal.write(null);
  }

  Future<void> download() async {
    final categories = await cloud.loadCategories();
    await local.merge([
      for (final c in categories)
        Category(
          id: c.id,
          name: c.name,
          icon: c.icon,
          swatch: c.swatch,
          trackers: c.trackers,
          templateKey: c.templateKey,
          archivedAt: c.archivedAt,
          dashboard: c.dashboard,
        ),
    ]);
  }

  /// Kategorie [c] in der Cloud: aus dem Journal eines abgebrochenen Versuchs, ergänzt um Tracker und
  /// Felder, die lokal seitdem dazugekommen sind – oder neu, wenn es sie dort nicht (mehr) gibt.
  Future<Map<String, Object?>> _ensure(Category c, Map<String, Object?>? journaled) async {
    if (journaled == null) return _create(c);
    final existing = await remote.loadCategory(journaled['id']! as String);
    if (existing == null) return _create(c);
    final trackers = {...(journaled['trackers']! as Map).cast<String, String>()};
    final fields = {...(journaled['fields']! as Map).cast<String, String>()};
    for (final (i, t) in c.trackers.indexed) {
      final match = existing.trackers.where((r) => r.id == trackers[t.id]).firstOrNull;
      final tracker = match?.id ?? await remote.createTracker(existing.id, t.name, sort: i);
      trackers[t.id] = tracker;
      for (final (j, f) in t.fields.indexed) {
        if (match != null && match.fields.any((r) => r.id == fields[f.id])) continue;
        // Gesamtfeld vor seinen Teilen (Reihenfolge der Vorlage); fehlt es oben noch, zählt der Teil selbst.
        fields[f.id] = await remote.createField(tracker, FieldDraft.of(f).withPartOf(fields[f.partOf]), sort: j);
      }
    }
    return {'id': existing.id, 'trackers': trackers, 'fields': fields};
  }

  /// Legt [c] mit Trackern und Feldern an und ordnet die neuen Ids über die Reihenfolge zu.
  Future<Map<String, Object?>> _create(Category c) async {
    final id = await remote.createCategory(
      CategoryDraft(
        name: c.name,
        icon: c.icon,
        swatch: c.swatch,
        templateKey: c.templateKey,
        trackers: [
          for (final t in c.trackers) TrackerDraft.of(t),
        ],
      ),
    );
    final created = await remote.loadCategory(id);
    if (created == null || created.trackers.length != c.trackers.length) throw StateError('transfer_mismatch $id');
    final trackers = <String, String>{};
    final fields = <String, String>{};
    for (final (i, t) in c.trackers.indexed) {
      final match = created.trackers[i];
      if (match.fields.length != t.fields.length) throw StateError('transfer_mismatch ${match.id}');
      trackers[t.id] = match.id;
      for (final (j, f) in t.fields.indexed) {
        fields[f.id] = match.fields[j].id;
      }
    }
    return {'id': id, 'trackers': trackers, 'fields': fields};
  }

  Future<Map<String, Map<String, Object?>>> _readJournal() async {
    final json = await journal.read().catchError((Object _) => null);
    if (json case {'userId': final String owner, 'categories': final Map created} when owner == userId()) {
      return {
        for (final MapEntry(:key, :value) in created.entries)
          if (key is String && value is Map) key: value.cast<String, Object?>(),
      };
    }
    return {};
  }
}
