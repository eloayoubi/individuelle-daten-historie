import 'dart:async';

import '../../../core/utils/json_store.dart';
import '../../categories/data/categories_repository.dart';
import '../../categories/data/local_categories_repository.dart';

/// Umzug der Daten zwischen Gerät und Cloud.
///
/// **Hoch** ([upload]): jede Kategorie per `create_category` neu anlegen, Tracker und Felder über
/// ihre Reihenfolge zuordnen, Einträge mit ihren Geräte-Ids senden (`save_entry` ist ein Upsert),
/// danach „enthalten in“ und Archiv setzen. Ein Journal merkt sich jede angelegte Kategorie: Bricht
/// der Umzug ab, legt der nächste Versuch nichts doppelt an. Erst wenn alles oben ist, wird das
/// Gerät geleert.
///
/// **Runter** ([download]): alle sichtbaren Kategorien als eigene Kopie aufs Gerät (ohne Mitglieder
/// und Belege); gleiche Ids werden ersetzt, andere lokale Kategorien bleiben.
class StorageTransfer {
  StorageTransfer({required this.local, required this.remote, required this.cloud, required this.journal});

  final LocalCategoriesRepository local;

  /// Supabase direkt, ohne Warteschlange: Jeder Schritt ist bestätigt, bevor der nächste kommt.
  final CategoriesRepository remote;

  /// Cloud mit Offline-Schicht: liest auch ohne Netz aus dem Cache und kennt wartende Einträge.
  final CategoriesRepository cloud;
  /// Welche lokalen Kategorien schon in der Cloud angelegt sind (für einen abgebrochenen Umzug).
  final JsonStore journal;

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
      var mapped = created[c.id];
      if (mapped == null) {
        mapped = await _create(c);
        created[c.id] = mapped;
        await journal.write(created);
      }
      categoryIds[c.id] = mapped['id']! as String;
      trackerIds.addAll((mapped['trackers']! as Map).cast<String, String>());
      fieldIds.addAll((mapped['fields']! as Map).cast<String, String>());
    }

    final writes = <Future<void> Function()>[
      for (final c in categories)
        for (final t in c.trackers)
          for (final e in t.entries)
            () => remote.saveEntry(
              trackerIds[t.id]!,
              // Werte archivierter Felder haben kein Gegenstück mehr und bleiben weg.
              e.copyWith(values: {for (final MapEntry(:key, :value) in e.values.entries) ?fieldIds[key]: value}),
            ),
    ];
    for (var i = 0; i < writes.length; i += parallel) {
      await Future.wait([for (final write in writes.skip(i).take(parallel)) write()]);
    }

    for (final c in categories) {
      for (final t in c.trackers) {
        if (t.includedIn case final target? when categoryIds.containsKey(target)) await remote.setTrackerIncludedIn(trackerIds[t.id]!, categoryIds[target]);
      }
      if (c.isArchived) await remote.setCategoryArchived(categoryIds[c.id]!, archived: true);
    }

    await local.clear();
    await journal.write(null);
  }

  Future<void> download() async {
    final categories = await cloud.loadCategories();
    await local.merge([
      for (final c in categories)
        Category(id: c.id, name: c.name, icon: c.icon, swatch: c.swatch, trackers: c.trackers, templateKey: c.templateKey, archivedAt: c.archivedAt),
    ]);
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
          for (final t in c.trackers) TrackerDraft(name: t.name, fields: [for (final f in t.fields) FieldDraft.of(f)]),
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
    if (json is! Map) return {};
    return {
      for (final MapEntry(:key, :value) in json.entries)
        if (key is String && value is Map) key: value.cast<String, Object?>(),
    };
  }
}
