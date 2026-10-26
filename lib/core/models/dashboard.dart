import 'package:equatable/equatable.dart';

/// Wie die Werte eines Felds über einen Zeitraum zusammengefasst werden – Grundlage der Kennzahlen
/// im Dashboard einer Kategorie. Welche zu einem Feld passen, steht in `FieldRoleSummaries`.
enum FieldSummary {
  /// Alle Werte im Zeitraum addiert (Tanken, Nachzahlungen); wiederkehrende Beträge anteilig je Tag.
  sum,

  /// Neuer minus alter Wert: Wert am Ende des Zeitraums minus Wert am Anfang (Verbrauch aus
  /// Zählerständen, gefahrene Kilometer).
  difference,

  /// Mittel der Werte im Zeitraum.
  average,

  /// Der Wert, der am Ende des Zeitraums gilt.
  latest,

  /// Kleinster Wert im Zeitraum.
  min,

  /// Größter Wert im Zeitraum.
  max,
}

/// Eine Kennzahl im Dashboard: Kosten (der ganzen Kategorie oder eines Trackers) oder ein Feld,
/// zusammengefasst nach seiner Einstellung ([FieldSummary]).
class DashboardMetric extends Equatable {
  /// Kosten – ohne [trackerId] die der ganzen Kategorie.
  const DashboardMetric.cost({this.trackerId}) : fieldId = null;

  const DashboardMetric.field({required String this.trackerId, required String this.fieldId});

  final String? trackerId;
  final String? fieldId;

  bool get isCost => fieldId == null;

  Map<String, Object?> toJson() => {'tracker': trackerId, if (fieldId != null) 'field': fieldId};

  static DashboardMetric? fromJson(Object? json) => switch (json) {
    {'tracker': final String tracker, 'field': final String field} => DashboardMetric.field(trackerId: tracker, fieldId: field),
    {'field': _} => null,
    {'tracker': final String? tracker} => DashboardMetric.cost(trackerId: tracker),
    _ => null,
  };

  /// Gleiche Kennzahl mit neuen Ids (Umzug zwischen Gerät und Cloud); `null`, wenn es sie dort nicht gibt.
  DashboardMetric? remap(Map<String, String> trackers, Map<String, String> fields) {
    final tracker = trackerId == null ? null : trackers[trackerId];
    if (trackerId != null && tracker == null) return null;
    if (fieldId == null) return DashboardMetric.cost(trackerId: tracker);
    final field = fields[fieldId];
    return field == null ? null : DashboardMetric.field(trackerId: tracker!, fieldId: field);
  }

  @override
  List<Object?> get props => [trackerId, fieldId];
}

/// Aufbau der Übersicht einer Kategorie – gilt für alle Mitglieder.
class CategoryDashboard extends Equatable {
  const CategoryDashboard({this.metrics, this.showAddTracker = true});

  /// Gewählte Kennzahlen in Reihenfolge; `null` = die App wählt (Kosten, Verbrauch je Zähler).
  final List<DashboardMetric>? metrics;

  /// „Tracker hinzufügen“ unter „Wert eintragen“ zeigen; weggeklickt geht es über „Bearbeiten“.
  final bool showAddTracker;

  bool get isDefault => metrics == null && showAddTracker;

  CategoryDashboard copyWith({List<DashboardMetric>? Function()? metrics, bool? showAddTracker}) =>
      CategoryDashboard(metrics: metrics == null ? this.metrics : metrics(), showAddTracker: showAddTracker ?? this.showAddTracker);

  Map<String, Object?> toJson() => {
    if (metrics case final list?) 'metrics': [for (final m in list) m.toJson()],
    if (!showAddTracker) 'showAddTracker': false,
  };

  static CategoryDashboard fromJson(Object? json) {
    if (json is! Map) return const CategoryDashboard();
    return CategoryDashboard(
      metrics: switch (json['metrics']) {
        final List list => [for (final m in list) ?DashboardMetric.fromJson(m)],
        _ => null,
      },
      showAddTracker: json['showAddTracker'] != false,
    );
  }

  /// Gleicher Aufbau mit neuen Ids (Umzug); Kennzahlen ohne Gegenstück fallen weg.
  CategoryDashboard remap(Map<String, String> trackers, Map<String, String> fields) =>
      CategoryDashboard(metrics: metrics == null ? null : [for (final m in metrics!) ?m.remap(trackers, fields)], showAddTracker: showAddTracker);

  @override
  List<Object?> get props => [metrics, showAddTracker];
}
