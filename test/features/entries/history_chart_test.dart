import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/entries/data/tracker_history.dart';
import 'package:kostenkurve/features/entries/view/widgets/history_chart.dart';

import '../../support/pump_app.dart';

TrackerHistory history(int months) => TrackerHistory(
  metric: HistoryMetric.cost,
  unit: '',
  months: [for (var i = 0; i < months; i++) HistoryMonth(month: DateTime.utc(2026, 8 + i), value: 10.0 + i)],
  thisYear: 0,
  lastYearToDate: null,
  forecastNextYear: 0,
  currentValues: const [],
);

void main() {
  setUpAll(ensureMockDependencies);

  testWidgets('weniger Monate nach dem Löschen: kein Absturz, der letzte Monat ist gewählt', (tester) async {
    Widget chart(TrackerHistory h) => HistoryChart(history: h, color: Colors.orange, format: (v) => '$v');
    await pumpPage(tester, chart(history(3)));
    await tester.tap(find.byType(GestureDetector).first, warnIfMissed: false);
    await pumpPage(tester, chart(history(2)));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('11.0'), findsOneWidget);
  });
}
