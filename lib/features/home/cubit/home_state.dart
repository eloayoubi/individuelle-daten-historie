part of 'home_cubit.dart';

enum HomeStatus { loading, ready, failure }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.loading,
    this.overview,
    this.radar,
    this.radarExpanded = false,
    this.sync = const SyncState(),
    this.pinned = const [],
    this.reordering = false,
  });

  /// So viele Funde zeigt die Übersicht, bis „Alle“ angetippt ist.
  static const radarPreview = 3;

  final HomeStatus status;
  final HomeOverview? overview;

  /// Funde des Radars ohne die ausgeblendeten; `null`, solange nichts geladen ist.
  final Radar? radar;

  /// Alle Funde zeigen statt der ersten [radarPreview].
  final bool radarExpanded;

  /// Funde, die die Übersicht gerade zeigt.
  List<Finding> get shownFindings {
    final all = radar?.findings ?? const <Finding>[];
    return radarExpanded || all.length <= radarPreview ? all : all.sublist(0, radarPreview);
  }

  /// Offline erfasste Einträge, die noch warten oder abgelehnt wurden.
  final SyncState sync;

  /// Ids der Kategorien unter „Kategorien“, in dieser Reihenfolge (je Gerät gespeichert).
  final List<String> pinned;

  /// Verschiebe-Modus der Kategorien (nach langem Halten), bis „Fertig“.
  final bool reordering;

  /// Gewählte Kategorien, die es noch gibt (nicht archiviert), in der gewählten Reihenfolge.
  List<CategorySummary> get shown {
    final byId = {for (final s in overview?.categories ?? const <CategorySummary>[]) s.category.id: s};
    return [for (final id in pinned) ?byId[id]];
  }

  HomeState copyWith({HomeStatus? status, HomeOverview? overview, Radar? radar, bool? radarExpanded, SyncState? sync, List<String>? pinned, bool? reordering}) => HomeState(
    status: status ?? this.status,
    overview: overview ?? this.overview,
    radar: radar ?? this.radar,
    radarExpanded: radarExpanded ?? this.radarExpanded,
    sync: sync ?? this.sync,
    pinned: pinned ?? this.pinned,
    reordering: reordering ?? this.reordering,
  );

  @override
  List<Object?> get props => [status, overview, radar, radarExpanded, sync, pinned, reordering];
}
