part of 'tracker_cubit.dart';

enum TrackerStatus { loading, ready, missing, failure }

class TrackerState extends Equatable {
  const TrackerState({
    this.status = TrackerStatus.loading,
    this.category,
    this.tracker,
    this.metrics = const [],
    this.metric,
    this.history,
    this.currentValues = const [],
    this.includedInName,
  });

  final TrackerStatus status;
  final Category? category;
  final Tracker? tracker;

  /// Kennzahlen, die der Tracker hergibt (leer: nur Einträge, kein Graph).
  final List<HistoryMetric> metrics;
  final HistoryMetric? metric;
  final TrackerHistory? history;
  final List<CurrentValue> currentValues;

  /// Kategorie, in deren Kosten dieser Tracker steckt.
  final String? includedInName;

  /// Neueste zuerst.
  List<Entry> get entries => [...?tracker?.entries]..sort((a, b) => b.date.compareTo(a.date));

  TrackerState copyWith({HistoryMetric? metric, TrackerHistory? history}) => TrackerState(
    status: status,
    category: category,
    tracker: tracker,
    metrics: metrics,
    metric: metric ?? this.metric,
    history: history ?? this.history,
    currentValues: currentValues,
    includedInName: includedInName,
  );

  @override
  List<Object?> get props => [status, category, tracker, metrics, metric, history, currentValues, includedInName];
}
