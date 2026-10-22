import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../categories/data/categories_repository.dart';
import '../data/tracker_history.dart';

part 'tracker_state.dart';

/// Welcher Tracker gezeigt wird.
class TrackerArgs {
  const TrackerArgs({required this.categoryId, required this.trackerId});

  final String categoryId;
  final String trackerId;
}

/// Verlauf eines Trackers: Kennzahl wählen (Kosten oder Verbrauch), zwölf Monate, aktuelle Werte
/// und alle Einträge. Lädt bei jeder Änderung neu, auch nach offline gespeicherten Einträgen.
class TrackerCubit extends Cubit<TrackerState> {
  TrackerCubit(this._repository, this.args, {DateTime Function()? now}) : _now = now ?? DateTime.now, super(const TrackerState()) {
    _subscription = _repository.changes.listen((_) => load());
  }

  final CategoriesRepository _repository;
  final TrackerArgs args;
  final DateTime Function() _now;
  late final StreamSubscription<void> _subscription;

  Future<void> load() async {
    try {
      final category = await _repository.loadCategory(args.categoryId);
      final tracker = category?.trackers.where((t) => t.id == args.trackerId).firstOrNull;
      if (isClosed) return;
      if (category == null || tracker == null) {
        emit(const TrackerState(status: TrackerStatus.missing));
        return;
      }
      final metrics = TrackerHistory.metricsFor(tracker);
      final metric = metrics.contains(state.metric) ? state.metric : metrics.firstOrNull;
      emit(
        TrackerState(
          status: TrackerStatus.ready,
          category: category,
          tracker: tracker,
          metrics: metrics,
          metric: metric,
          history: metric == null ? null : TrackerHistory.build(tracker, _now(), metric),
          currentValues: TrackerHistory.currentValuesOf(tracker, _now()),
        ),
      );
    } catch (_) {
      if (!isClosed && state.tracker == null) emit(const TrackerState(status: TrackerStatus.failure));
    }
  }

  void selectMetric(HistoryMetric metric) {
    final tracker = state.tracker;
    if (tracker == null || metric == state.metric || !state.metrics.contains(metric)) return;
    emit(state.copyWith(metric: metric, history: TrackerHistory.build(tracker, _now(), metric)));
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
