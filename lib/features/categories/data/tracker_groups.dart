import 'package:equatable/equatable.dart';

import 'categories_repository.dart';

/// Tracker einer Art ([Tracker.group]), `name` `null` = ohne Art.
class TrackerGroup extends Equatable {
  const TrackerGroup(this.name, this.trackers);

  final String? name;
  final List<Tracker> trackers;

  @override
  List<Object?> get props => [name, trackers];
}

/// Tracker nach ihrer Art gruppiert: Arten in der Reihenfolge von [order] (die Arten der Vorlage),
/// unbekannte danach alphabetisch, Tracker ohne Art zuletzt. Innerhalb einer Art bleibt die
/// Reihenfolge der Tracker.
List<TrackerGroup> groupTrackers(List<Tracker> trackers, {List<String> order = const []}) {
  final byGroup = <String?, List<Tracker>>{};
  for (final t in trackers) {
    (byGroup[t.group] ??= []).add(t);
  }
  int rank(String? name) => name == null ? order.length + 1 : (order.contains(name) ? order.indexOf(name) : order.length);
  final names = byGroup.keys.toList()
    ..sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 || a == null || b == null ? byRank : a.compareTo(b);
    });
  return [for (final name in names) TrackerGroup(name, byGroup[name]!)];
}
