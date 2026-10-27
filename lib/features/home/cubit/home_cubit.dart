import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/json_store.dart';
import '../../categories/data/categories_repository.dart';
import '../data/home_categories_store.dart';
import '../data/home_overview.dart';

part 'home_state.dart';

/// Lädt alle Kategorien und rechnet daraus die Übersicht: Kosten bis heute, Prognose fürs
/// nächste Jahr, die gewählten Kategorien und was als Nächstes ansteht – dazu den Stand der
/// Offline-Warteschlange.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._categories, {HomeCategoriesStore? pins, DateTime Function()? now})
    : _pins = pins ?? HomeCategoriesStore(MemoryJsonStore()),
      _now = now ?? DateTime.now,
      super(const HomeState()) {
    // Neue oder geänderte Kategorien (z. B. aus dem Kategorien-Tab) sofort übernehmen.
    _subscription = _categories.changes.listen((_) => load());
  }

  final CategoriesRepository _categories;
  final HomeCategoriesStore _pins;
  final DateTime Function() _now;
  late final StreamSubscription<void> _subscription;
  bool _pinsLoaded = false;

  Future<void> load() async {
    // Vorhandene Übersicht bleibt beim Neuladen stehen; nur nach einem Fehler wieder „lädt“.
    if (state.overview == null && state.status != HomeStatus.loading) emit(state.copyWith(status: HomeStatus.loading));
    try {
      final pinned = _pinsLoaded ? state.pinned : await _pins.load();
      _pinsLoaded = true;
      final categories = [for (final c in await _categories.loadCategories()) if (!c.isArchived) c];
      if (isClosed) return;
      emit(state.copyWith(status: HomeStatus.ready, overview: HomeOverview.build(categories, _now()), sync: _categories.syncState, pinned: pinned));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(status: HomeStatus.failure, sync: _categories.syncState));
    }
  }

  /// Kategorien der Übersicht festlegen (Auswahl unter „Kategorie hinzufügen“ bzw. „Bearbeiten“).
  Future<void> setPinned(List<String> ids) async {
    emit(state.copyWith(pinned: [...ids], reordering: false));
    await _pins.save(ids);
  }

  /// Verschiebe-Modus an (langes Halten) bzw. aus („Fertig“).
  void setReordering(bool on) => emit(state.copyWith(reordering: on && state.shown.length > 1));

  /// Gezeigte Kategorie von [oldIndex] nach [newIndex] (Zielposition nach dem Herausnehmen, wie
  /// `onReorderItem`). Gewählte, gerade archivierte Kategorien bleiben hinten in der Auswahl.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final shown = [for (final s in state.shown) s.category.id];
    if (oldIndex < 0 || oldIndex >= shown.length) return;
    final moved = shown.removeAt(oldIndex);
    shown.insert(newIndex.clamp(0, shown.length), moved);
    final ids = [...shown, for (final id in state.pinned) if (!shown.contains(id)) id];
    emit(state.copyWith(pinned: ids));
    await _pins.save(ids);
  }

  /// Hinweis auf abgelehnte Einträge ausblenden.
  void acknowledgeRejected() => _categories.acknowledgeRejected();

  /// Zurückgehaltene Einträge aufgeben (nach Rückfrage in der Ansicht).
  Future<void> discardHeld() => _categories.discardHeld();

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
