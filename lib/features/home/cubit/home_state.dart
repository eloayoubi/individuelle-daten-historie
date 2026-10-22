part of 'home_cubit.dart';

enum HomeStatus { loading, ready, failure }

class HomeState extends Equatable {
  const HomeState({this.status = HomeStatus.loading, this.overview, this.sync = const SyncState()});

  final HomeStatus status;
  final HomeOverview? overview;

  /// Offline erfasste Einträge, die noch warten oder abgelehnt wurden.
  final SyncState sync;

  HomeState copyWith({HomeStatus? status, HomeOverview? overview, SyncState? sync}) =>
      HomeState(status: status ?? this.status, overview: overview ?? this.overview, sync: sync ?? this.sync);

  @override
  List<Object?> get props => [status, overview, sync];
}
