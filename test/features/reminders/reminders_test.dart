import 'package:bloc_test/bloc_test.dart';
import 'package:kostenkurve/core/models/tracking.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kostenkurve/core/utils/json_store.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/reminders/cubit/reminders_cubit.dart';
import 'package:kostenkurve/features/reminders/data/notification_gateway.dart';
import 'package:kostenkurve/features/reminders/data/reminder_planner.dart';
import 'package:kostenkurve/features/reminders/data/reminder_service.dart';
import 'package:kostenkurve/l10n/generated/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('de'));
  final now = DateTime(2026, 10, 22, 19, 30);

  setUpAll(() => initializeDateFormatting('de'));

  group('ReminderPlanner', () {
    late List<PlannedReminder> plan;
    setUp(() => plan = ReminderPlanner.plan(MockCategoriesRepository.categories, now, l10n));

    test('überfällige Zähler: nächster 18-Uhr-Termin, je Zähler eine Erinnerung', () {
      final reads = plan.where((r) => r.title.endsWith('ablesen')).toList();
      expect(reads, hasLength(4));
      // Strom (12.9.), Gas (5.9.), Wasser (1.7.) sind über 30 Tage alt; Auto (9.10.) noch nicht.
      final overdue = reads.where((r) => r.at == DateTime(2026, 10, 23, 18));
      expect(overdue.map((r) => r.title), unorderedEquals(['Hauptzähler ablesen', 'Gaszähler ablesen', 'Kaltwasser ablesen']));
      expect(overdue.firstWhere((r) => r.title.startsWith('Kaltwasser')).body, contains('114 Tagen'));
    });

    test('noch nicht fällige Zähler: 30 Tage nach dem letzten Stand', () {
      final auto = plan.firstWhere((r) => r.title == 'Golf ablesen');
      expect(auto.at, DateTime(2026, 11, 8, 18));
    });

    test('Stichtage: 30, 7 und 1 Tag vorher um 9 Uhr, nur künftige', () {
      final glasfaser = plan.where((r) => r.title == 'Vertragsende · Glasfaser 250').map((r) => r.at).toList();
      expect(glasfaser, [DateTime(2026, 12, 1, 9), DateTime(2026, 12, 24, 9), DateTime(2026, 12, 30, 9)]);
      expect(plan.firstWhere((r) => r.title == 'Vertragsende · Glasfaser 250' && r.at.day == 30).body, contains('Morgen'));
    });

    test('sortiert, eindeutige Ids, höchstens 60', () {
      expect(plan.map((r) => r.at).toList(), [...plan.map((r) => r.at)]..sort());
      expect({for (final r in plan) r.id}, hasLength(plan.length));
      expect(plan.length, lessThanOrEqualTo(ReminderPlanner.limit));
    });

    test('ein einzelner Stand erinnert nicht – wie in der Übersicht', () {
      const meter = FieldDefinition(id: 'stand', name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'kWh');
      final category = Category(
        id: 'c',
        name: 'Strom',
        icon: CategoryIcon.bolt,
        swatch: CategorySwatch.orange,
        trackers: [Tracker(id: 't', name: 'Zähler', fields: const [meter], entries: [Entry(id: 'r', date: DateTime.utc(2026, 8, 1), values: const {'stand': 100})])],
      );
      expect(ReminderPlanner.plan([category], now, l10n), isEmpty);
    });

    test('archivierte Kategorien erinnern nicht', () {
      final strom = MockCategoriesRepository.categories.first;
      final archived = strom.copyWith(archivedAt: () => DateTime.utc(2026));
      expect(ReminderPlanner.plan([archived], now, l10n), isEmpty);
    });
  });

  group('ReminderService', () {
    late MemoryNotificationGateway gateway;
    late MemoryJsonStore store;
    late ReminderService service;

    setUp(() {
      gateway = MemoryNotificationGateway();
      store = MemoryJsonStore();
      service = ReminderService(MockCategoriesRepository(), gateway, store, texts: () => l10n, now: () => now, debounce: Duration.zero);
    });

    test('plant erst nach dem Einschalten und merkt sich die Wahl', () async {
      await service.reschedule();
      expect(gateway.scheduled, isEmpty);
      expect(await service.enable(), isTrue);
      expect(gateway.scheduled, isNotEmpty);
      expect(await store.read(), {'enabled': true});
    });

    test('ausschalten entfernt alle', () async {
      await service.enable();
      await service.disable();
      expect(gateway.scheduled, isEmpty);
      expect(await service.isEnabled(), isFalse);
    });

    test('ohne Recht bleibt es aus', () async {
      gateway.granted = false;
      expect(await service.enable(), isFalse);
      expect(await service.isEnabled(), isFalse);
    });

    test('plant nach Änderungen neu', () async {
      final repo = MockCategoriesRepository();
      final s = ReminderService(repo, gateway, store, texts: () => l10n, now: () => now, debounce: Duration.zero)..start();
      await s.enable();
      final before = gateway.scheduled.length;
      await repo.setCategoryArchived('c-internet', archived: true);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await pumpEventQueue();
      expect(gateway.scheduled.length, lessThan(before));
      expect(gateway.scheduled.where((r) => r.title.contains('Glasfaser')), isEmpty);
    });
  });

  group('RemindersCubit', () {
    blocTest<RemindersCubit, RemindersState>(
      'lädt: aus',
      build: () => RemindersCubit(ReminderService(MockCategoriesRepository(), MemoryNotificationGateway(), MemoryJsonStore(), texts: () => l10n)),
      act: (cubit) => cubit.load(),
      expect: () => [const RemindersState(loaded: true)],
    );

    blocTest<RemindersCubit, RemindersState>(
      'einschalten mit Recht',
      build: () => RemindersCubit(ReminderService(MockCategoriesRepository(), MemoryNotificationGateway(), MemoryJsonStore(), texts: () => l10n)),
      act: (cubit) => cubit.setEnabled(true),
      expect: () => [const RemindersState(loaded: true, enabled: true)],
    );

    blocTest<RemindersCubit, RemindersState>(
      'einschalten ohne Recht meldet es',
      build: () => RemindersCubit(ReminderService(MockCategoriesRepository(), MemoryNotificationGateway(granted: false), MemoryJsonStore(), texts: () => l10n)),
      act: (cubit) => cubit.setEnabled(true),
      expect: () => [const RemindersState(loaded: true, denied: true)],
    );

    blocTest<RemindersCubit, RemindersState>(
      'Recht später entzogen: zeigt es beim Laden',
      build: () => RemindersCubit(ReminderService(MockCategoriesRepository(), MemoryNotificationGateway(granted: false), MemoryJsonStore({'enabled': true}), texts: () => l10n)),
      act: (cubit) => cubit.load(),
      expect: () => [const RemindersState(loaded: true, denied: true)],
    );
  });

  test('keine Ablese-Mitteilung bei Rechnungen', () {
    const meter = FieldDefinition(id: 'stand', name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'kWh');
    const price = FieldDefinition(id: 'ap', name: 'Arbeitspreis', kind: FieldKind.currency, role: FieldRole.unitPrice);
    final category = Category(
      id: 'c',
      name: 'Strom',
      icon: CategoryIcon.bolt,
      swatch: CategorySwatch.orange,
      trackers: [
        Tracker(
          id: 't',
          name: 'Zähler',
          fields: const [meter, price],
          entries: [Entry(id: 'b', date: DateTime.utc(2026, 8, 23), values: const {'stand': 508}, periodStart: DateTime.utc(2026, 2, 23), periodEnd: DateTime.utc(2026, 8, 23))],
        ),
      ],
    );
    expect(ReminderPlanner.plan([category], now, l10n).where((r) => r.title.endsWith('ablesen')), isEmpty);
  });
}
