import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../categories/data/categories_repository.dart';
import '../data/home_overview.dart';

part 'home_state.dart';

/// Lädt alle Kategorien und rechnet daraus die Übersicht: Kosten bis heute, Prognose fürs
/// nächste Jahr, Kategorien nach Kosten und was als Nächstes ansteht.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._categories, {DateTime Function()? now}) : _now = now ?? DateTime.now, super(const HomeState()) {
    // Neue oder geänderte Kategorien (z. B. aus dem Kategorien-Tab) sofort übernehmen.
    _subscription = _categories.changes.listen((_) => load());
  }

  final CategoriesRepository _categories;
  final DateTime Function() _now;
  late final StreamSubscription<void> _subscription;

  Future<void> load() async {
    // Vorhandene Übersicht bleibt beim Neuladen stehen; nur nach einem Fehler wieder „lädt“.
    if (state.overview == null && state.status != HomeStatus.loading) emit(state.copyWith(status: HomeStatus.loading));
    try {
      final categories = [for (final c in await _categories.loadCategories()) if (!c.isArchived) c];
      if (isClosed) return;
      emit(state.copyWith(status: HomeStatus.ready, overview: HomeOverview.build(categories, _now())));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(status: HomeStatus.failure));
    }
  }

  /// Schnellerfassung aus dem Sheet – das Formular folgt im nächsten Schritt (Meilenstein 2).
  void capture(String trackerId) => emit(state.copyWith(event: HomeEvent(HomeEventKind.captureSoon)));

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
