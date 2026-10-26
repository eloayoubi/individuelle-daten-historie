import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/formulas.dart';
import '../../categories/data/categories_repository.dart';
import '../../categories/data/tracker_details.dart';
import '../data/tracker_history.dart';

part 'tracker_state.dart';

/// Welcher Tracker gezeigt wird – auf Wunsch gleich mit Kosten oder Verbrauch (aus der Übersicht).
class TrackerArgs {
  const TrackerArgs({required this.categoryId, required this.trackerId, this.metric});

  final String categoryId;
  final String trackerId;

  /// Kennzahl beim Öffnen; ohne sie (oder wenn es sie nicht gibt) die übliche.
  final HistoryMetric? metric;
}

/// Verlauf eines Trackers: Kennzahl wählen (Kosten oder Verbrauch), zwölf Monate, Details setzen,
/// aktuelle Werte und alle Einträge. Lädt bei jeder Änderung neu, auch nach offline gespeicherten
/// Einträgen.
class TrackerCubit extends Cubit<TrackerState> {
  TrackerCubit(this._repository, this.args, {DateTime Function()? now}) : _now = now ?? DateTime.now, super(const TrackerState()) {
    _subscription = _repository.changes.listen((_) => load());
  }

  final CategoriesRepository _repository;
  final TrackerArgs args;
  final DateTime Function() _now;
  late final StreamSubscription<void> _subscription;

  /// Der Tracker, wie er gespeichert ist (ohne Formel-Werte) – Grundlage für Details.
  Tracker? _raw;

  Future<void> load() async {
    try {
      final all = await _repository.loadCategories();
      final category = all.where((c) => c.id == args.categoryId).firstOrNull;
      final raw = category?.trackers.where((t) => t.id == args.trackerId).firstOrNull;
      if (isClosed) return;
      if (category == null || raw == null) {
        emit(const TrackerState(status: TrackerStatus.missing));
        return;
      }
      _raw = raw;
      // Formel-Werte gleich mitrechnen, damit Einträge und aktuelle Werte sie zeigen.
      final tracker = Formulas.apply(raw);
      final into = all.where((c) => c.id == raw.includedIn).firstOrNull;
      final metrics = TrackerHistory.metricsFor(tracker);
      // Ohne Preise gibt es noch keine Kosten – dann zuerst den Verbrauch zeigen.
      final missingPrice = _missingPrice(raw, metrics);
      final preferred = missingPrice && metrics.contains(HistoryMetric.consumption) ? HistoryMetric.consumption : metrics.firstOrNull;
      final metric = metrics.contains(state.metric)
          ? state.metric
          : metrics.contains(args.metric)
          ? args.metric
          : preferred;
      emit(
        TrackerState(
          status: TrackerStatus.ready,
          category: category,
          tracker: tracker,
          metrics: metrics,
          metric: metric,
          history: metric == null ? null : TrackerHistory.build(raw, _now(), metric),
          currentValues: TrackerHistory.currentValuesOf(tracker, _now()),
          contract: TrackerHistory.contractOf(tracker, _now()),
          missingPrice: missingPrice,
          today: _now(),
          includedInName: into?.name,
        ),
      );
    } catch (_) {
      if (!isClosed && state.tracker == null) emit(const TrackerState(status: TrackerStatus.failure));
    }
  }

  /// Detail setzen ([value] `null` entfernt es). Gerechnet wird mit dem gespeicherten Tracker, nicht
  /// mit dem um Formel-Werte ergänzten.
  Future<void> saveDetail(FieldDefinition field, Object? value) async {
    final raw = _raw;
    if (raw == null) return;
    try {
      await _repository.saveDetail(raw, field, value, now: _now());
    } catch (_) {
      if (!isClosed) emit(state.copyWith(event: TrackerEvent(TrackerEventKind.failed)));
    }
  }

  /// Versorgungszähler mit Verbrauch, aber ohne Arbeitspreis: Kosten gibt es erst mit Vertrag.
  static bool _missingPrice(Tracker tracker, List<HistoryMetric> metrics) {
    if (!tracker.isUtilityMeter || !metrics.contains(HistoryMetric.consumption)) return false;
    final price = tracker.firstWithRole(FieldRole.unitPrice)!;
    return !tracker.entries.any((e) => e.values.containsKey(price.id));
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
