import 'dart:async';

import '../../categories/data/categories_repository.dart';
import 'storage_mode.dart';

/// Weiche vor den Daten: im Speicherort „Lokal“ (und solange keiner gewählt ist) an [local], in der
/// Cloud an [cloud]. Alle Ansichten kennen nur `CategoriesRepository`; ein Wechsel meldet
/// [changes], dann laden sie neu.
class StorageCategoriesRepository implements CategoriesRepository {
  StorageCategoriesRepository({required this.local, required this.cloud, required this.mode});

  final CategoriesRepository local;
  final CategoriesRepository cloud;
  final StorageModeStore mode;

  bool get _isCloud => mode.mode == StorageMode.cloud;

  CategoriesRepository get _active => _isCloud ? cloud : local;

  /// Je Zuhörer ein eigener Strom: Er hört erst beim Abonnieren auf beide Speicher und den
  /// Speicherort (in der Zone des Zuhörers) und hört auf, wenn er kündigt.
  @override
  Stream<void> get changes {
    final subscriptions = <StreamSubscription<Object?>>[];
    late final StreamController<void> controller;
    controller = StreamController<void>(
      onListen: () => subscriptions.addAll([
        local.changes.listen((_) {
          if (!_isCloud) controller.add(null);
        }),
        cloud.changes.listen((_) {
          if (_isCloud) controller.add(null);
        }),
        mode.changes.listen((_) => controller.add(null)),
      ]),
      onCancel: () => Future.wait([for (final s in subscriptions) s.cancel()]),
    );
    return controller.stream;
  }

  @override
  Future<List<Category>> loadCategories() => _active.loadCategories();

  @override
  Future<Category?> loadCategory(String id) => _active.loadCategory(id);

  @override
  Future<String> createCategory(CategoryDraft draft) => _active.createCategory(draft);

  @override
  Future<void> updateCategory(String id, {required String name, required CategoryIcon icon, required CategorySwatch swatch}) =>
      _active.updateCategory(id, name: name, icon: icon, swatch: swatch);

  @override
  Future<void> setCategoryArchived(String id, {required bool archived}) => _active.setCategoryArchived(id, archived: archived);

  @override
  Future<void> reorderCategories(List<String> ids) => _active.reorderCategories(ids);

  @override
  Future<String> createTracker(String categoryId, String name, {required int sort}) => _active.createTracker(categoryId, name, sort: sort);

  @override
  Future<void> renameTracker(String id, String name) => _active.renameTracker(id, name);

  @override
  Future<void> archiveTracker(String id) => _active.archiveTracker(id);

  @override
  Future<void> setTrackerIncludedIn(String id, String? categoryId) => _active.setTrackerIncludedIn(id, categoryId);

  @override
  Future<String> createField(String trackerId, FieldDraft draft, {required int sort}) => _active.createField(trackerId, draft, sort: sort);

  @override
  Future<void> updateField(String id, FieldDraft draft) => _active.updateField(id, draft);

  @override
  Future<void> archiveField(String id) => _active.archiveField(id);

  @override
  Future<void> saveEntry(String trackerId, Entry entry) => _active.saveEntry(trackerId, entry);

  @override
  Future<void> deleteEntry(String trackerId, String entryId) => _active.deleteEntry(trackerId, entryId);

  @override
  SyncState get syncState => _active.syncState;

  @override
  Future<void> sync() => _active.sync();

  @override
  void acknowledgeRejected() => _active.acknowledgeRejected();

  @override
  Future<String> createInvite(String categoryId, MemberRole role) => _active.createInvite(categoryId, role);

  @override
  Future<String> acceptInvite(String code) => _active.acceptInvite(code);

  @override
  Future<void> setMemberRole(String categoryId, String userId, MemberRole role) => _active.setMemberRole(categoryId, userId, role);

  @override
  Future<void> removeMember(String categoryId, String userId) => _active.removeMember(categoryId, userId);

  @override
  Future<void> leaveCategory(String categoryId) => _active.leaveCategory(categoryId);
}
