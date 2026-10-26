import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/tracker_groups.dart';

void main() {
  const art = FieldDefinition(id: 'art', name: 'Art', kind: FieldKind.choice, choices: ['Streaming', 'Fitness & Sport']);

  Tracker abo(String name, [String? group]) => Tracker(
    id: name,
    name: name,
    fields: const [art],
    entries: [if (group != null) Entry(id: 'e-$name', date: DateTime.utc(2026), values: {'art': group})],
  );

  test('Art ist der Wert des ersten Auswahl-Details, ohne Wert null', () {
    expect(abo('Netflix', 'Streaming').group, 'Streaming');
    expect(abo('Kletterhalle').group, isNull);
    expect(const Tracker(id: 't', name: 'Strom').group, isNull);
  });

  test('gruppiert nach der Reihenfolge der Vorlage, Unbekannte alphabetisch, ohne Art zuletzt', () {
    final groups = groupTrackers(
      [abo('Kletterhalle'), abo('Gym', 'Fitness & Sport'), abo('Netflix', 'Streaming'), abo('Zeit', 'Zeitung'), abo('Disney+', 'Streaming'), abo('Bahn', 'Bahn')],
      order: const ['Streaming', 'Fitness & Sport'],
    );
    // Listen statt Records: Records vergleichen enthaltene Listen nur auf Identität.
    expect([for (final g in groups) [g.name, [for (final t in g.trackers) t.name]]], [
      ['Streaming', ['Netflix', 'Disney+']],
      ['Fitness & Sport', ['Gym']],
      ['Bahn', ['Bahn']],
      ['Zeitung', ['Zeit']],
      [null, ['Kletterhalle']],
    ]);
  });

  test('ohne Arten eine Gruppe ohne Namen', () {
    expect(groupTrackers([abo('A'), abo('B')]), [TrackerGroup(null, [abo('A'), abo('B')])]);
  });
}
