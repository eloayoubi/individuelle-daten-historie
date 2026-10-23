import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../entries/data/tracker_history.dart';
import '../data/categories_repository.dart';
import '../data/tracker_details.dart';

part 'category_detail_state.dart';

/// Eine Kategorie mit ihren Trackern: Kennzahl des Jahres je Tracker, Details setzen, Aussehen
/// ändern, Tracker anlegen, umbenennen, archivieren, Kategorie archivieren. Lädt bei jeder
/// Änderung im Repository neu. Auch die Felder-Seite eines Trackers nutzt diesen Cubit.
class CategoryDetailCubit extends Cubit<CategoryDetailState> {
  CategoryDetailCubit(this._repository, this.categoryId, {DateTime Function()? now}) : _now = now ?? DateTime.now, super(const CategoryDetailState()) {
    _subscription = _repository.changes.listen((_) => load());
  }

  final CategoriesRepository _repository;
  final String categoryId;
  final DateTime Function() _now;
  late final StreamSubscription<void> _subscription;

  Future<void> load() async {
    try {
      final category = await _repository.loadCategory(categoryId);
      final others = [for (final c in await _repository.loadCategories()) if (c.id != categoryId && !c.isArchived) c];
      if (isClosed) return;
      final now = _now();
      emit(
        state.copyWith(
          status: category == null ? CategoryDetailStatus.missing : CategoryDetailStatus.ready,
          category: category,
          others: others,
          yearToDate: {
            for (final t in category?.trackers ?? const <Tracker>[])
              if (TrackerHistory.yearToDate(t, now) case final YearToDate value) t.id: value,
          },
        ),
      );
    } catch (_) {
      if (!isClosed) emit(state.copyWith(status: state.category == null ? CategoryDetailStatus.failure : state.status));
    }
  }

  Future<void> updateAppearance({required String name, required CategoryIcon icon, required CategorySwatch swatch}) =>
      _run(() => _repository.updateCategory(categoryId, name: name.trim(), icon: icon, swatch: swatch));

  Future<void> addTracker(String name) =>
      _run(() => _repository.createTracker(categoryId, name.trim(), sort: state.category?.trackers.length ?? 0), success: CategoryDetailEventKind.trackerAdded);

  Future<void> renameTracker(String trackerId, String name) => _run(() => _repository.renameTracker(trackerId, name.trim()));

  /// Name und „Kosten enthalten in“ – nur, was sich geändert hat.
  Future<void> updateTracker(Tracker tracker, {required String name, String? includedIn}) => _run(() async {
    if (name.trim() != tracker.name) await _repository.renameTracker(tracker.id, name.trim());
    if (includedIn != tracker.includedIn) await _repository.setTrackerIncludedIn(tracker.id, includedIn);
  });

  /// Detail setzen ([value] `null` entfernt es).
  Future<void> saveDetail(Tracker tracker, FieldDefinition field, Object? value) => _run(() => _repository.saveDetail(tracker, field, value, now: _now()));

  Future<void> archiveTracker(String trackerId) => _run(() => _repository.archiveTracker(trackerId), success: CategoryDetailEventKind.trackerArchived);

  Future<void> archive() => _run(() => _repository.setCategoryArchived(categoryId, archived: true), success: CategoryDetailEventKind.archived);

  Future<void> _run(Future<void> Function() write, {CategoryDetailEventKind? success}) async {
    try {
      await write();
      if (!isClosed && success != null) emit(state.copyWith(event: CategoryDetailEvent(success)));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(event: CategoryDetailEvent(CategoryDetailEventKind.failed)));
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
