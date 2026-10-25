part of 'tracker_cubit.dart';

enum TrackerStatus { loading, ready, missing, failure }

enum TrackerEventKind { failed }

/// Einmaliges Ereignis für Toasts. Bewusst nicht `const`.
class TrackerEvent {
  TrackerEvent(this.kind);

  final TrackerEventKind kind;
}

class TrackerState extends Equatable {
  const TrackerState({
    this.status = TrackerStatus.loading,
    this.category,
    this.tracker,
    this.metrics = const [],
    this.metric,
    this.history,
    this.currentValues = const [],
    this.contract = const [],
    this.missingPrice = false,
    this.includedInName,
    this.event,
  });

  final TrackerStatus status;
  final Category? category;
  final Tracker? tracker;

  /// Kennzahlen, die der Tracker hergibt (leer: nur Einträge, kein Graph).
  final List<HistoryMetric> metrics;
  final HistoryMetric? metric;
  final TrackerHistory? history;
  final List<CurrentValue> currentValues;

  /// Vertrag eines Versorgungszählers: aktueller Wert je Preis (Preise ohne Wert fehlen).
  final List<CurrentValue> contract;

  /// Verbrauch bekannt, aber noch kein Arbeitspreis – ohne ihn gibt es keine Kosten.
  final bool missingPrice;

  /// Kategorie, in deren Kosten dieser Tracker steckt.
  final String? includedInName;
  final TrackerEvent? event;

  /// Neueste zuerst, ohne reine Detail-Einträge (die zeigt „Details“) und ohne Preisänderungen
  /// eines Versorgungszählers (die zeigt der Vertrag).
  List<Entry> get entries => [
    for (final e in tracker?.records ?? const <Entry>[])
      if (!tracker!.isPriceChange(e)) e,
  ]..sort((a, b) => b.date.compareTo(a.date));

  /// Alle Werte eines Preises, neueste zuerst.
  List<Entry> priceHistory(FieldDefinition field) => [
    for (final e in tracker?.entries ?? const <Entry>[])
      if (e.values.containsKey(field.id)) e,
  ]..sort((a, b) => b.date.compareTo(a.date));

  /// [event] gilt nur für genau einen Zustand und fällt beim nächsten weg.
  TrackerState copyWith({HistoryMetric? metric, TrackerHistory? history, TrackerEvent? event}) => TrackerState(
    status: status,
    category: category,
    tracker: tracker,
    metrics: metrics,
    metric: metric ?? this.metric,
    history: history ?? this.history,
    currentValues: currentValues,
    contract: contract,
    missingPrice: missingPrice,
    includedInName: includedInName,
    event: event,
  );

  @override
  List<Object?> get props => [status, category, tracker, metrics, metric, history, currentValues, contract, missingPrice, includedInName, event];
}
