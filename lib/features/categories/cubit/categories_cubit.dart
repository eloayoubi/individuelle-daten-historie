import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/categories_repository.dart';

part 'categories_state.dart';

/// Kategorien-Tab: aktive und archivierte Kategorien, Reihenfolge ändern, wiederherstellen.
/// Lädt neu, sobald sich im Repository etwas ändert (z. B. eine neue Kategorie).
class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit(this._repository) : super(const CategoriesState()) {
    _subscription = _repository.changes.listen((_) => load());
  }

  final CategoriesRepository _repository;
  late final StreamSubscription<void> _subscription;

  Future<void> load() async {
    try {
      final all = await _repository.loadCategories();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: CategoriesStatus.ready,
          active: [for (final c in all) if (!c.isArchived) c],
          archived: [for (final c in all) if (c.isArchived) c],
        ),
      );
    } catch (_) {
      if (isClosed) return;
      // Ohne Daten zeigt die Seite den Fehler, sonst bleibt die Liste stehen und ein Toast meldet ihn.
      emit(state.active.isEmpty ? state.copyWith(status: CategoriesStatus.failure) : state.copyWith(event: CategoriesEvent(CategoriesEventKind.failed)));
    }
  }

  void toggleEditing() => emit(state.copyWith(editing: !state.editing));

  /// Verschiebt sofort (optimistisch) und speichert danach; scheitert das Speichern, gilt wieder der Serverstand.
  /// [newIndex] ist die Zielposition nach dem Herausnehmen (wie `onReorderItem`).
  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = [...state.active];
    final moved = list.removeAt(oldIndex);
    list.insert(newIndex.clamp(0, list.length), moved);
    emit(state.copyWith(active: list));
    try {
      await _repository.reorderCategories([for (final c in list) c.id]);
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(event: CategoriesEvent(CategoriesEventKind.failed)));
      await load();
    }
  }

  Future<void> restore(Category category) async {
    try {
      await _repository.setCategoryArchived(category.id, archived: false);
      if (!isClosed) emit(state.copyWith(event: CategoriesEvent(CategoriesEventKind.restored, category.name)));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(event: CategoriesEvent(CategoriesEventKind.failed)));
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
