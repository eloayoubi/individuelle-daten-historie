part of 'home_cubit.dart';

enum HomeStatus { loading, ready, failure }

enum HomeEventKind { captureSoon }

/// Einmaliges Ereignis für Toasts; die Seite reagiert per `BlocListener`.
/// Bewusst nicht `const`: Jede Instanz ist neu, so zeigt auch ein zweites gleiches Ereignis einen Toast.
class HomeEvent {
  HomeEvent(this.kind);

  final HomeEventKind kind;
}

class HomeState extends Equatable {
  const HomeState({this.status = HomeStatus.loading, this.overview, this.event});

  final HomeStatus status;
  final HomeOverview? overview;
  final HomeEvent? event;

  /// [event] gilt nur für genau einen Zustand und fällt beim nächsten weg.
  HomeState copyWith({HomeStatus? status, HomeOverview? overview, HomeEvent? event}) =>
      HomeState(status: status ?? this.status, overview: overview ?? this.overview, event: event);

  @override
  List<Object?> get props => [status, overview, event];
}
