import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/insights/cubit/what_if_cubit.dart';
import 'package:kostenkurve/features/insights/data/what_if.dart';

void main() {
  final today = DateTime.utc(2026, 10, 22);
  final categories = MockCategoriesRepository.categories.where((c) => !c.isArchived).toList();
  final strom = categories.firstWhere((c) => c.id == 'c-strom').trackers.single;
  final price = strom.fields.firstWhere((f) => f.role.name == 'unitPrice');

  test('ohne neue Preise: vorher = nachher', () {
    final r = WhatIf.of(strom, today, const {});
    expect(r.before, greaterThan(0));
    expect(r.delta, 0);
  });

  test('höherer Arbeitspreis: Prognose steigt im Verhältnis des Verbrauchs', () {
    final now = WhatIf.current(strom, price, today)!;
    final r = WhatIf.of(strom, today, {price.id: now + 0.10});
    expect(r.after, greaterThan(r.before));
    // Mehrkosten = Verbrauch × 10 ct; plausibel zwischen 100 und 1000 kWh × 0,10 €.
    expect(r.delta, inInclusiveRange(10, 1000));
    final cheaper = WhatIf.of(strom, today, {price.id: now - 0.05});
    expect(cheaper.delta, lessThan(0));
  });

  test('Cubit: nur Tracker mit Preisfeldern, Eingabe in App-Sprache', () {
    final cubit = WhatIfCubit(WhatIfArgs(categories: categories, today: today));
    final s = cubit.state;
    expect(s.options, isNotEmpty);
    expect(s.options.every((o) => o.fields.isNotEmpty && o.tracker.includedIn == null), isTrue);
    expect(s.options.any((o) => o.tracker.id == 't-wasser'), isFalse, reason: 'Wasser steckt in den Nebenkosten');

    cubit.select('t-strom');
    cubit.setInput(price.id, '0,45');
    expect(cubit.state.inputs[price.id], '0,45');
    expect(cubit.state.result!.after, closeTo(WhatIf.of(strom, today, {price.id: 0.45}).after, 1e-6));

    cubit.setInput(price.id, 'abc');
    expect(cubit.state.result!.delta, 0);
    cubit.close();
  });
}
