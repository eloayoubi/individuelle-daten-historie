import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/utils/dashboard_figures.dart';
import 'package:kostenkurve/features/categories/cubit/category_detail_cubit.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/category_templates.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/l10n/generated/app_localizations.dart';

void main() {
  blocTest<CategoryDetailCubit, CategoryDetailState>(
    'lädt die Kategorie',
    build: () => CategoryDetailCubit(MockCategoriesRepository(), 'c-strom'),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<CategoryDetailState>().having((s) => s.status, 'status', CategoryDetailStatus.ready).having((s) => s.category?.name, 'name', 'Strom'),
    ],
  );

  blocTest<CategoryDetailCubit, CategoryDetailState>(
    'rechnet je Tracker die Kosten des Jahres bis heute',
    build: () => CategoryDetailCubit(MockCategoriesRepository(), 'c-internet', now: () => DateTime(2026, 10, 22)),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<CategoryDetailState>()
          .having((s) => s.yearToDate['t-glasfaser']?.value, 'Glasfaser', greaterThan(400))
          .having((s) => s.yearToDate['t-handy']?.value, 'Handy', greaterThan(140)),
    ],
  );

  blocTest<CategoryDetailCubit, CategoryDetailState>(
    'setzt ein Detail und lädt neu',
    build: () => CategoryDetailCubit(MockCategoriesRepository(), 'c-internet', now: () => DateTime(2026, 10, 22)),
    act: (cubit) async {
      await cubit.load();
      final handy = cubit.state.category!.trackers.firstWhere((t) => t.id == 't-handy');
      await cubit.saveDetail(handy, handy.detailFields.single, 'Telekom');
      await pumpEventQueue();
    },
    skip: 1,
    expect: () => [
      isA<CategoryDetailState>().having((s) => s.category?.trackers.firstWhere((t) => t.id == 't-handy').detailValue('f-handy-anbieter'), 'Anbieter', 'Telekom'),
    ],
  );

  blocTest<CategoryDetailCubit, CategoryDetailState>(
    'löscht die Kategorie und meldet es, ohne vorher „fehlt“ zu zeigen',
    build: () => CategoryDetailCubit(MockCategoriesRepository(), 'c-strom'),
    act: (cubit) async {
      await cubit.load();
      await cubit.delete();
      await pumpEventQueue();
    },
    skip: 1,
    expect: () => [isA<CategoryDetailState>().having((s) => s.event?.kind, 'event', CategoryDetailEventKind.deleted).having((s) => s.status, 'status', CategoryDetailStatus.ready)],
  );

  blocTest<CategoryDetailCubit, CategoryDetailState>(
    'stellt eine archivierte Kategorie wieder her',
    build: () => CategoryDetailCubit(MockCategoriesRepository(), 'c-strom'),
    act: (cubit) async {
      await cubit.archive();
      await cubit.load();
      expect(cubit.state.category!.isArchived, isTrue);
      await cubit.restore();
      await pumpEventQueue();
    },
    verify: (cubit) {
      expect(cubit.state.category!.isArchived, isFalse);
    },
  );

  blocTest<CategoryDetailCubit, CategoryDetailState>(
    'meldet eine fehlende Kategorie',
    build: () => CategoryDetailCubit(MockCategoriesRepository(), 'gibt-es-nicht'),
    act: (cubit) => cubit.load(),
    expect: () => [isA<CategoryDetailState>().having((s) => s.status, 'status', CategoryDetailStatus.missing)],
  );

  blocTest<CategoryDetailCubit, CategoryDetailState>(
    'legt einen Tracker an und zeigt ihn nach dem Neuladen',
    build: () => CategoryDetailCubit(MockCategoriesRepository(), 'c-wasser'),
    act: (cubit) async {
      await cubit.load();
      await cubit.addTracker('  Warmwasser ');
      await pumpEventQueue();
    },
    skip: 1,
    expect: () => [
      isA<CategoryDetailState>().having((s) => s.event?.kind, 'event', CategoryDetailEventKind.trackerAdded),
      isA<CategoryDetailState>().having((s) => s.category?.trackers.map((t) => t.name), 'trackers', ['Kaltwasser', 'Warmwasser']),
    ],
  );

  blocTest<CategoryDetailCubit, CategoryDetailState>(
    'legt einen weiteren Zähler wie den ersten an und benennt den bisherigen',
    build: () => CategoryDetailCubit(MockCategoriesRepository(), 'c-wasser'),
    act: (cubit) async {
      await cubit.load();
      final tracker = cubit.state.category!.trackers.single;
      await cubit.addMeter(tracker, name: ' Bad warm ', group: 'Warmwasser', first: (name: 'Bad kalt', group: 'Kaltwasser'));
      await pumpEventQueue();
    },
    skip: 1,
    verify: (cubit) {
      final meters = cubit.state.category!.trackers.single.meters;
      expect([for (final m in meters) (m.name, m.meterGroup, m.unit)], [('Bad kalt', 'Kaltwasser', 'm³'), ('Bad warm', 'Warmwasser', 'm³')]);
      expect(cubit.state.figures.where((f) => f.metric.isMeters).map((f) => f.metric.group), ['Kaltwasser', 'Warmwasser']);
    },
  );

  blocTest<CategoryDetailCubit, CategoryDetailState>(
    'ändert Name und Gruppe eines Zählers',
    build: () => CategoryDetailCubit(MockCategoriesRepository(), 'c-wasser'),
    act: (cubit) async {
      await cubit.load();
      final meter = cubit.state.category!.trackers.single.meter!;
      await cubit.updateMeter(meter, name: 'Küche', group: ' ');
      await pumpEventQueue();
    },
    skip: 1,
    verify: (cubit) {
      final meter = cubit.state.category!.trackers.single.meter!;
      expect((meter.name, meter.meterGroup, meter.role), ('Küche', null, FieldRole.meterReading));
    },
  );

  blocTest<CategoryDetailCubit, CategoryDetailState>(
    'ändert Name, Symbol und Farbe',
    build: () => CategoryDetailCubit(MockCategoriesRepository(), 'c-strom'),
    act: (cubit) async {
      await cubit.load();
      await cubit.updateAppearance(name: 'Strom Wohnung ', icon: CategoryIcon.star, swatch: CategorySwatch.yellow);
      await pumpEventQueue();
    },
    skip: 1,
    expect: () => [
      isA<CategoryDetailState>().having((s) => (s.category?.name, s.category?.icon, s.category?.swatch), 'look', ('Strom Wohnung', CategoryIcon.star, CategorySwatch.yellow)),
    ],
  );

  blocTest<CategoryDetailCubit, CategoryDetailState>(
    'legt ein Abo aus dem Bauplan an: Preis ab „seit“, Art als Detail',
    build: () => CategoryDetailCubit(MockCategoriesRepository(), 'c-abos', now: () => DateTime(2026, 10, 26)),
    act: (cubit) async {
      await cubit.load();
      final item = CategoryTemplates.item(lookupAppLocalizations(const Locale('de')), 'abos')!;
      await cubit.addItem(item, ItemDraft(name: ' Disney+ ', group: 'Streaming', amount: 89.9, interval: 12, since: DateTime(2026, 3, 15, 9)));
      await pumpEventQueue();
    },
    skip: 1,
    // Das Ereignis gilt nur für einen Zustand, das Neuladen danach räumt es wieder ab.
    expect: () => contains(
      isA<CategoryDetailState>()
          .having((s) => s.event?.kind, 'event', CategoryDetailEventKind.itemAdded)
          .having((s) => s.event?.name, 'name', 'Disney+'),
    ),
    verify: (cubit) {
      final disney = cubit.state.category!.trackers.last;
      expect(disney.name, 'Disney+');
      expect(disney.group, 'Streaming');
      final (price, value) = disney.currentAmount(DateTime(2026, 10, 26))!;
      expect((price.name, price.intervalMonths, price.unit, value), ('Preis', 12, '€/Jahr', 89.9));
      expect(disney.records.single.date, DateTime.utc(2026, 3, 15));
      expect(disney.detailFields.map((f) => f.name), ['Kündbar bis', 'Art']);
    },
  );

  blocTest<CategoryDetailCubit, CategoryDetailState>(
    'legt ein Abo ohne Preis und ohne Art an',
    build: () => CategoryDetailCubit(MockCategoriesRepository(), 'c-abos'),
    act: (cubit) async {
      await cubit.load();
      final item = CategoryTemplates.item(lookupAppLocalizations(const Locale('de')), 'abos')!;
      await cubit.addItem(item, ItemDraft(name: 'Kletterhalle', interval: 1, since: DateTime(2026, 10, 1)));
      await pumpEventQueue();
    },
    skip: 1,
    verify: (cubit) {
      final tracker = cubit.state.category!.trackers.last;
      expect(tracker.name, 'Kletterhalle');
      expect(tracker.entries, isEmpty);
      expect(tracker.group, isNull);
      expect(tracker.fields, hasLength(3));
    },
  );

  blocTest<CategoryDetailCubit, CategoryDetailState>(
    'archiviert die Kategorie',
    build: () => CategoryDetailCubit(MockCategoriesRepository(), 'c-abos'),
    act: (cubit) async {
      await cubit.load();
      await cubit.archive();
      await pumpEventQueue();
    },
    skip: 1,
    expect: () => [
      isA<CategoryDetailState>().having((s) => s.event?.kind, 'event', CategoryDetailEventKind.archived),
      isA<CategoryDetailState>().having((s) => s.category?.isArchived, 'archived', isTrue),
    ],
  );

  blocTest<CategoryDetailCubit, CategoryDetailState>(
    'archiviert einen Tracker',
    build: () => CategoryDetailCubit(MockCategoriesRepository(), 'c-internet'),
    act: (cubit) async {
      await cubit.load();
      await cubit.archiveTracker('t-handy');
      await pumpEventQueue();
    },
    skip: 1,
    expect: () => [
      isA<CategoryDetailState>().having((s) => s.event?.kind, 'event', CategoryDetailEventKind.trackerArchived),
      isA<CategoryDetailState>().having((s) => s.category?.trackers.map((t) => t.id), 'trackers', ['t-glasfaser']),
    ],
  );

  group('Übersicht', () {
    blocTest<CategoryDetailCubit, CategoryDetailState>(
      'rechnet Kosten und Verbrauch im Jahr und wechselt den Zeitraum',
      build: () => CategoryDetailCubit(MockCategoriesRepository(), 'c-strom', now: () => DateTime(2026, 10, 22)),
      act: (cubit) async {
        await cubit.load();
        cubit.setPeriod(DashboardPeriod.lastYear);
      },
      expect: () => [
        isA<CategoryDetailState>()
            .having((s) => s.span, 'span', DateSpan(DateTime.utc(2026), DateTime.utc(2026, 10, 23)))
            .having((s) => s.figures.map((f) => f.metric), 'Kennzahlen', const [
              DashboardMetric.cost(),
              DashboardMetric.field(trackerId: 't-strom', fieldId: 'f-strom-stand'),
            ])
            .having((s) => s.figures.every((f) => (f.value ?? 0) > 0), 'Werte', isTrue),
        isA<CategoryDetailState>()
            .having((s) => s.period, 'period', DashboardPeriod.lastYear)
            .having((s) => s.span, 'span', DateSpan(DateTime.utc(2025), DateTime.utc(2026))),
      ],
    );

    blocTest<CategoryDetailCubit, CategoryDetailState>(
      'eigener Zeitraum schließt den letzten Tag ein, auch rückwärts gewählt',
      build: () => CategoryDetailCubit(MockCategoriesRepository(), 'c-strom', now: () => DateTime(2026, 10, 22)),
      act: (cubit) async {
        await cubit.load();
        cubit.setPeriod(DashboardPeriod.custom, from: DateTime.utc(2026, 3, 31), to: DateTime.utc(2026, 3, 1));
      },
      skip: 1,
      expect: () => [isA<CategoryDetailState>().having((s) => s.span, 'span', DateSpan(DateTime.utc(2026, 3), DateTime.utc(2026, 4)))],
    );

    blocTest<CategoryDetailCubit, CategoryDetailState>(
      'gewählte Kennzahlen und weggeklicktes „Tracker hinzufügen“ landen im Dashboard der Kategorie',
      build: () => CategoryDetailCubit(MockCategoriesRepository(), 'c-strom', now: () => DateTime(2026, 10, 22)),
      act: (cubit) async {
        await cubit.load();
        await cubit.setMetrics(const [DashboardMetric.field(trackerId: 't-strom', fieldId: 'f-strom-ap')]);
        await pumpEventQueue();
        await cubit.hideAddTracker();
        await pumpEventQueue();
      },
      verify: (cubit) {
        final dashboard = cubit.state.category!.dashboard;
        expect(dashboard.metrics, const [DashboardMetric.field(trackerId: 't-strom', fieldId: 'f-strom-ap')]);
        expect(dashboard.showAddTracker, isFalse);
        expect(cubit.state.figures.single.value, closeTo(0.329, 1e-9));
      },
    );
  });
}
