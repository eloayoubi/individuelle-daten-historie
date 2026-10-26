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

/// Eine Kennzahl im Dashboard: Kosten (der ganzen Kategorie oder eines Trackers), ein Feld,
/// zusammengefasst nach seiner Einstellung ([FieldSummary]), oder der Verbrauch mehrerer Zähler
/// zusammen.
class DashboardMetric extends Equatable {
  /// Kosten – ohne [trackerId] die der ganzen Kategorie.
  const DashboardMetric.cost({this.trackerId}) : fieldId = null, isMeters = false, group = null, fieldIds = null, label = null;

  const DashboardMetric.field({required String this.trackerId, required String this.fieldId}) : isMeters = false, group = null, fieldIds = null, label = null;

  /// Verbrauch mehrerer Zähler zusammen: ohne Angabe alle Zähler der Kategorie, mit [group] die
  /// Zähler dieser Gruppe (Kaltwasser), mit [fieldIds] eine eigene Auswahl namens [label].
  const DashboardMetric.meters({this.group, this.fieldIds, this.label}) : trackerId = null, fieldId = null, isMeters = true;

  final String? trackerId;
  final String? fieldId;
  final bool isMeters;
  final String? group;
  final List<String>? fieldIds;
  final String? label;

  bool get isCost => fieldId == null && !isMeters;

  /// Eigene Summe aus gewählten Zählern.
  bool get isCustom => fieldIds != null;

  Map<String, Object?> toJson() => isMeters
      ? {
          'meters': {'group': ?group, 'fields': ?fieldIds, 'label': ?label},
        }
      : {'tracker': trackerId, if (fieldId != null) 'field': fieldId};

  static DashboardMetric? fromJson(Object? json) => switch (json) {
    {'meters': final Map meters} => DashboardMetric.meters(
      group: meters['group'] as String?,
      fieldIds: switch (meters['fields']) {
        final List list => [for (final id in list) id as String],
        _ => null,
      },
      label: meters['label'] as String?,
    ),
    {'tracker': final String tracker, 'field': final String field} => DashboardMetric.field(trackerId: tracker, fieldId: field),
    {'field': _} => null,
    {'tracker': final String? tracker} => DashboardMetric.cost(trackerId: tracker),
    _ => null,
  };

  /// Gleiche Kennzahl mit neuen Ids (Umzug zwischen Gerät und Cloud); `null`, wenn es sie dort nicht gibt.
  DashboardMetric? remap(Map<String, String> trackers, Map<String, String> fields) {
    if (isMeters) {
      if (fieldIds == null) return this;
      final ids = [for (final id in fieldIds!) ?fields[id]];
      return ids.isEmpty ? null : DashboardMetric.meters(group: group, fieldIds: ids, label: label);
    }
    final tracker = trackerId == null ? null : trackers[trackerId];
    if (trackerId != null && tracker == null) return null;
    if (fieldId == null) return DashboardMetric.cost(trackerId: tracker);
    final field = fields[fieldId];
    return field == null ? null : DashboardMetric.field(trackerId: tracker!, fieldId: field);
  }

  @override
  List<Object?> get props => [trackerId, fieldId, isMeters, group, fieldIds, label];
}

/// Aufbau der Übersicht einer Kategorie – gilt für alle Mitglieder.
class CategoryDashboard extends Equatable {
  const CategoryDashboard({this.metrics, this.showAddTracker = true});

  /// Gewählte Kennzahlen in Reihenfolge; `null` = die App wählt (Kosten, Verbrauch je Gruppe von
  /// Zählern bzw. je Zähler).
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
