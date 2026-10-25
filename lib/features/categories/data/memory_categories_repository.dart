import 'dart:async';

import 'package:flutter/foundation.dart' show mustCallSuper, protected;

import '../../../core/utils/ids.dart';
import 'categories_repository.dart';

/// Kategorien im Speicher – Grundlage für den lokalen Speicher (`LocalCategoriesRepository`) und
/// den Mock mit den Beispieldaten. Teilen gibt es hier nicht, das braucht die Cloud
/// ([WriteRejected] mit [cloudRequired]).
class MemoryCategoriesRepository implements CategoriesRepository {
  MemoryCategoriesRepository({List<Category> seed = const [], String Function(String kind)? ids}) : items = [...seed], _ids = ids ?? _uuid;

  /// Fehler-Code für alles, was nur in der Cloud geht (Teilen, Einladungen).
  static const cloudRequired = 'cloud_required';

  /// Alle Kategorien in meiner Reihenfolge; Unterklassen lesen und ersetzen sie.
  @protected
  final List<Category> items;
  final String Function(String kind) _ids;
  final _changes = StreamController<void>.broadcast();

  static String _uuid(String _) => newId();

  /// Läuft vor jedem Zugriff, z. B. um die Datei zu laden.
  @protected
  Future<void> ready() async {}

  /// Nach jeder Änderung; Unterklassen speichern hier.
  @protected
  @mustCallSuper
  void changed() => _changes.add(null);

  @protected
  String id(String kind) => _ids(kind);

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<List<Category>> loadCategories() async {
    await ready();
    return List.unmodifiable(items);
  }

  @override
  Future<Category?> loadCategory(String id) async {
    await ready();
    return items.where((c) => c.id == id).firstOrNull;
  }

  @override
  Future<String> createCategory(CategoryDraft draft) async {
    await ready();
    final category = Category(
      id: id('c'),
      name: draft.name,
      icon: draft.icon,
      swatch: draft.swatch,
      templateKey: draft.templateKey,
      trackers: [
        for (final t in draft.trackers) Tracker(id: id('t'), name: t.name, fields: [for (final f in t.fields) f.withId(id('f'))]),
      ],
    );
    // Neue Kategorien ans Ende der aktiven, vor die archivierten.
    final firstArchived = items.indexWhere((c) => c.isArchived);
    items.insert(firstArchived < 0 ? items.length : firstArchived, category);
    changed();
    return category.id;
  }

  @override
  Future<void> updateCategory(String id, {required String name, required CategoryIcon icon, required CategorySwatch swatch}) async {
    await ready();
    updateCategoryWith(id, (c) => c.copyWith(name: name, icon: icon, swatch: swatch));
  }

  @override
  Future<void> setCategoryArchived(String id, {required bool archived}) async {
    await ready();
    final category = items.firstWhere((c) => c.id == id);
    items
      ..remove(category)
      ..add(category.copyWith(archivedAt: () => archived ? DateTime.now().toUtc() : null));
    changed();
  }

  @override
  Future<void> reorderCategories(List<String> ids) async {
    await ready();
    final byId = {for (final c in items) c.id: c};
    final ordered = [for (final id in ids) ?byId[id]];
    items
      ..removeWhere(ordered.contains)
      ..insertAll(0, ordered);
    changed();
  }

  @override
  Future<String> createTracker(String categoryId, String name, {required int sort}) async {
    await ready();
    final tracker = Tracker(id: id('t'), name: name);
    updateCategoryWith(categoryId, (c) => c.copyWith(trackers: [...c.trackers, tracker]));
    return tracker.id;
  }

  @override
  Future<void> renameTracker(String id, String name) async {
    await ready();
    _updateTracker(id, (t) => t.copyWith(name: name));
  }

  @override
  Future<void> setTrackerIncludedIn(String id, String? categoryId) async {
    await ready();
    _updateTracker(id, (t) => t.copyWith(includedIn: () => categoryId));
  }

  @override
  Future<void> archiveTracker(String id) async {
    await ready();
    for (final c in [...items]) {
      if (c.trackers.any((t) => t.id == id)) updateCategoryWith(c.id, (c) => c.copyWith(trackers: [...c.trackers.where((t) => t.id != id)]));
    }
  }

  @override
  Future<String> createField(String trackerId, FieldDraft draft, {required int sort}) async {
    await ready();
    final field = draft.withId(id('f'));
    _updateTracker(trackerId, (t) => t.copyWith(fields: [...t.fields, field]));
    return field.id;
  }

  @override
  Future<void> updateField(String id, FieldDraft draft) async {
    await ready();
    _updateFields((f) => f.id == id ? draft.withId(id) : f);
  }

  @override
  Future<void> archiveField(String id) async {
    await ready();
    for (final c in [...items]) {
      for (final t in c.trackers) {
        if (t.fields.any((f) => f.id == id)) _updateTracker(t.id, (t) => t.copyWith(fields: [...t.fields.where((f) => f.id != id)]));
      }
    }
  }

  @override
  Future<void> saveEntry(String trackerId, Entry entry) async {
    await ready();
    _updateTracker(
      trackerId,
      (t) => t.copyWith(entries: [...t.entries.where((e) => e.id != entry.id), entry]..sort((a, b) => a.date.compareTo(b.date))),
    );
  }

  @override
  Future<void> deleteEntry(String trackerId, String entryId) async {
    await ready();
    _updateTracker(trackerId, (t) => t.copyWith(entries: [...t.entries.where((e) => e.id != entryId)]));
  }

  // Teilen nur in der Cloud.

  @override
  Future<String> createInvite(String categoryId, MemberRole role) async => throw const WriteRejected(cloudRequired);

  @override
  Future<String> acceptInvite(String code) async => throw const WriteRejected(cloudRequired);

  @override
  Future<void> setMemberRole(String categoryId, String userId, MemberRole role) async => throw const WriteRejected(cloudRequired);

  @override
  Future<void> removeMember(String categoryId, String userId) async => throw const WriteRejected(cloudRequired);

  @override
  Future<void> leaveCategory(String categoryId) async => throw const WriteRejected(cloudRequired);

  @override
  SyncState get syncState => const SyncState();

  @override
  Future<void> sync() async {}

  @override
  void acknowledgeRejected() {}

  @protected
  void updateCategoryWith(String id, Category Function(Category) update) {
    final i = items.indexWhere((c) => c.id == id);
    if (i < 0) throw StateError('Kategorie $id fehlt');
    items[i] = update(items[i]);
    changed();
  }

  void _updateTracker(String id, Tracker Function(Tracker) update) {
    final category = items.firstWhere((c) => c.trackers.any((t) => t.id == id), orElse: () => throw StateError('Tracker $id fehlt'));
    updateCategoryWith(category.id, (c) => c.copyWith(trackers: [for (final t in c.trackers) t.id == id ? update(t) : t]));
  }

  void _updateFields(FieldDefinition Function(FieldDefinition) update) {
    for (var i = 0; i < items.length; i++) {
      final c = items[i];
      items[i] = c.copyWith(trackers: [for (final t in c.trackers) t.copyWith(fields: [for (final f in t.fields) update(f)])]);
    }
    changed();
  }
}
