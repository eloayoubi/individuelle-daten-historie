import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../categories/data/categories_repository.dart';
import '../data/insights.dart';

part 'insights_state.dart';

/// Auswertungs-Tab: Jahr wählen, Kosten je Monat und Kategorie, Jahresvergleich, Verbrauch,
/// Prognose mit Spanne und Abschlags-Check. Lädt bei jeder Änderung neu.
class InsightsCubit extends Cubit<InsightsState> {
  InsightsCubit(this._repository, {DateTime Function()? now}) : _now = now ?? DateTime.now, super(const InsightsState()) {
    _subscription = _repository.changes.listen((_) => load());
  }

  final CategoriesRepository _repository;
  final DateTime Function() _now;
  late final StreamSubscription<void> _subscription;
  List<Category> _categories = const [];

  Future<void> load() async {
    try {
      _categories = [for (final c in await _repository.loadCategories()) if (!c.isArchived) c];
      if (isClosed) return;
      final now = _now();
      final years = Insights.yearsOf(_categories, now);
      final year = years.contains(state.year) ? state.year! : now.year;
      emit(InsightsState(status: InsightsStatus.ready, years: years, year: year, insights: Insights.build(_categories, now, year)));
    } catch (_) {
      if (!isClosed && state.insights == null) emit(const InsightsState(status: InsightsStatus.failure));
    }
  }

  void selectYear(int year) {
    if (year == state.year || !state.years.contains(year)) return;
    emit(state.copyWith(year: year, insights: Insights.build(_categories, _now(), year)));
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
