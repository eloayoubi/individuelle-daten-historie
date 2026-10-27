part of 'home_cubit.dart';

enum HomeStatus { loading, ready, failure }

class HomeState extends Equatable {
  const HomeState({this.status = HomeStatus.loading, this.overview, this.sync = const SyncState(), this.pinned = const [], this.reordering = false});

  final HomeStatus status;
  final HomeOverview? overview;

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

  HomeState copyWith({HomeStatus? status, HomeOverview? overview, SyncState? sync, List<String>? pinned, bool? reordering}) => HomeState(
    status: status ?? this.status,
    overview: overview ?? this.overview,
    sync: sync ?? this.sync,
    pinned: pinned ?? this.pinned,
    reordering: reordering ?? this.reordering,
  );

  @override
  List<Object?> get props => [status, overview, sync, pinned, reordering];
}
