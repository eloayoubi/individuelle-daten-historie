import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/models/tracking.dart';
import 'package:kostenkurve/core/utils/json_store.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/home/cubit/home_cubit.dart';
import 'package:kostenkurve/features/radar/data/radar.dart';
import 'package:kostenkurve/features/radar/data/radar_store.dart';
import 'package:kostenkurve/features/radar/view/finding_sheet.dart';
import 'package:kostenkurve/features/radar/view/radar_rows.dart';

import '../../support/pump_app.dart';

void main() {
  DateTime now() => DateTime(2026, 10, 22, 9, 30);

  const price = FieldDefinition(id: 'price', name: 'Preis', kind: FieldKind.currency, role: FieldRole.recurringCost, unit: '€/Monat');
  const cancelBy = FieldDefinition(id: 'cancel', name: 'Kündbar bis', kind: FieldKind.date, role: FieldRole.deadline);

  /// Abo, das am 1.10.2026 teurer wurde und am [due] kündbar ist: zwei Funde.
  Tracker abo(String id, String name, {required double before, required double after, required DateTime due}) => Tracker(
    id: id,
    name: name,
    fields: const [price, cancelBy],
    entries: [
      Entry(id: '$id-1', date: DateTime.utc(2026), values: {'price': before}),
      Entry(id: '$id-2', date: DateTime.utc(2026, 10), values: {'price': after}),
      Entry(id: '$id-3', date: DateTime.utc(2026), values: {'cancel': due}),
    ],
  );

  final abos = Category(
    id: 'c-abos',
    name: 'Abos',
    icon: CategoryIcon.play,
    swatch: CategorySwatch.pink,
    trackers: [
      abo('netflix', 'Netflix', before: 13.99, after: 17.99, due: DateTime.utc(2026, 11, 10)),
      abo('spotify', 'Spotify', before: 10, after: 20, due: DateTime.utc(2026, 11, 20)),
    ],
  );

  group('RadarStore', () {
    test('merkt sich ausgeblendete Funde, jeden nur einmal', () async {
      final json = MemoryJsonStore();
      final store = RadarStore(json);
      expect(await store.load(), isEmpty);
      await store.dismiss('a');
      await store.dismiss('b');
      expect(await store.dismiss('a'), {'a', 'b'});
      expect(await json.read(), ['b', 'a']);
      expect(await RadarStore(json).load(), {'a', 'b'});
    });

    test('behält höchstens die neuesten Kennungen', () async {
      final store = RadarStore(MemoryJsonStore([for (var i = 0; i < RadarStore.maxIds; i++) 'id$i']));
      final ids = await store.dismiss('neu');
      expect(ids, hasLength(RadarStore.maxIds));
      expect(ids, contains('neu'));
      expect(ids, isNot(contains('id0')));
    });

    test('lädt aus einer zu großen Datei nur die neuesten Kennungen', () async {
      final ids = await RadarStore(MemoryJsonStore([for (var i = 0; i < RadarStore.maxIds + 50; i++) 'id$i'])).load();
      expect(ids, hasLength(RadarStore.maxIds));
      expect(ids, contains('id${RadarStore.maxIds + 49}'));
      expect(ids, isNot(contains('id0')));
    });

    test('ignoriert eine beschädigte Datei', () async {
      expect(await RadarStore(MemoryJsonStore({'x': 1})).load(), isEmpty);
      expect(await RadarStore(MemoryJsonStore(['ok', 7, null, '', 'x' * (RadarStore.maxIdLength + 1)])).load(), {'ok'});
    });
  });

  group('HomeCubit', () {
    test('lädt die Funde, zeigt anfangs drei und auf Wunsch alle', () async {
      final cubit = HomeCubit(MockCategoriesRepository(seed: [abos]), now: now);
      await cubit.load();
      expect(cubit.state.radar?.findings, hasLength(4));
      expect(cubit.state.shownFindings.map((f) => (f.kind, f.tracker.id)), [
        (FindingKind.deadline, 'netflix'),
        (FindingKind.deadline, 'spotify'),
        (FindingKind.priceIncrease, 'spotify'),
      ]);
      cubit.setRadarExpanded(true);
      expect(cubit.state.shownFindings, hasLength(4));
      await cubit.close();
    });

    test('Ausblenden entfernt den Fund sofort und bleibt gespeichert', () async {
      final store = RadarStore(MemoryJsonStore());
      final cubit = HomeCubit(MockCategoriesRepository(seed: [abos]), radar: store, now: now);
      await cubit.load();
      final first = cubit.state.radar!.findings.first;
      await cubit.dismissFinding(first.id);
      expect(cubit.state.radar!.findings, hasLength(3));
      expect(cubit.state.radar!.findings, isNot(contains(first)));
      await cubit.close();

      final again = HomeCubit(MockCategoriesRepository(seed: [abos]), radar: store, now: now);
      await again.load();
      expect(again.state.radar!.findings.map((f) => f.id), isNot(contains(first.id)));
      await again.close();
    });

    test('Beispieldaten: jeder Fund hat Betrag, Kennung und Texte', () async {
      final cubit = HomeCubit(MockCategoriesRepository(), now: now);
      await cubit.load();
      final findings = cubit.state.radar!.findings;
      expect({for (final f in findings) f.id}, hasLength(findings.length));
      for (final f in findings) {
        expect(f.amount, greaterThan(0));
        expect(f.amount.isFinite, isTrue);
      }
      await cubit.close();
    });
  });

  group('Ansicht', () {
    final finding = Radar.build([abos], now()).findings.first;

    setUpAll(ensureMockDependencies);

    testWidgets('Zeile nennt Frist und Betrag, Antippen meldet den Fund', (t) async {
      Finding? tapped;
      await pumpPage(t, RadarRows(findings: [finding], onTap: (f) => tapped = f));
      expect(find.text('Netflix: Kündbar bis in 19 Tagen'), findsOneWidget);
      // Zwischen Betrag und € steht ein geschütztes Leerzeichen.
      expect(find.textContaining(RegExp(r'^Es geht um 216\s€ in den nächsten 12 Monaten$')), findsOneWidget);
      expect(find.text('Gerechnet auf deinem Gerät, aus deinen Einträgen.'), findsOneWidget);
      await t.tap(find.text('Netflix: Kündbar bis in 19 Tagen'));
      expect(tapped, finding);
    });

    testWidgets('alle Funde der Beispieldaten haben Zeile und Erklärung, deutsch und englisch', (t) async {
      const reading = FieldDefinition(id: 'reading', name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'kWh');
      const unitPrice = FieldDefinition(id: 'unit', name: 'Arbeitspreis', kind: FieldKind.currency, role: FieldRole.unitPrice, unit: '€/kWh');
      final tracker = abos.trackers.first;
      final findings = [
        ...Radar.build([...MockCategoriesRepository.categories, abos], now()).findings,
        Finding(id: 'u', kind: FindingKind.usageUp, category: abos, tracker: tracker, field: reading, amount: 81, date: DateTime.utc(2026, 10, 20), ratio: 0.3, before: 900, after: 1170),
        Finding(
          id: 'p',
          kind: FindingKind.priceIncrease,
          category: abos,
          tracker: tracker,
          field: unitPrice,
          amount: 182.5,
          date: DateTime.utc(2027),
          ratio: 1 / 6,
          before: 0.3,
          after: 0.35,
          upcoming: true,
        ),
      ];
      expect({for (final f in findings) f.kind}, FindingKind.values.toSet());
      for (final locale in const [Locale('de'), Locale('en')]) {
        await pumpPage(
          t,
          Builder(
            builder: (context) => ListView(
              children: [
                RadarRows(findings: findings, onTap: (_) {}),
                for (final f in findings) Text(context.findingExplanation(f)),
              ],
            ),
          ),
          size: const Size(390, 3000),
          locale: locale,
        );
        expect(t.takeException(), isNull);
        if (locale.languageCode == 'de') {
          expect(find.textContaining(RegExp(r'^Netflix: \+30,0\s% Verbrauch$')), findsOneWidget);
          expect(find.text('Hauptzähler: Guthaben in Sicht'), findsOneWidget);
          expect(find.text('Gaszähler: Nachzahlung droht'), findsOneWidget);
          expect(find.textContaining('Arbeitspreis: 0,30 €/kWh → 0,35 €/kWh, ab 1.1.2027.'), findsOneWidget);
          expect(find.textContaining('In den 90 Tagen bis 20.10.2026 waren es 1.170 kWh, im selben Zeitraum ein Jahr zuvor 900 kWh.'), findsOneWidget);
          expect(find.textContaining('Abschläge 2026:'), findsNWidgets(2));
        }
      }
    });

    testWidgets('Sheet erklärt die Rechnung und bietet bei Fristen die Kündigung an', (t) async {
      FindingAction? action;
      await pumpPage(
        t,
        Builder(
          builder: (context) => TextButton(onPressed: () async => action = await FindingSheet.show(context, finding), child: const Text('auf')),
        ),
      );
      await t.tap(find.text('auf'));
      await t.pumpAndSettle();
      expect(find.text('So gerechnet'), findsOneWidget);
      expect(find.textContaining('Kündbar bis: 10.11.2026.'), findsOneWidget);
      expect(find.text('Verlauf öffnen'), findsOneWidget);
      expect(find.text('Ausblenden'), findsOneWidget);
      await t.tap(find.text('Kündigung vorbereiten'));
      await t.pumpAndSettle();
      expect(action, FindingAction.letter);
    });

    testWidgets('Kündigungsschreiben: Kopieren legt den Text in die Zwischenablage', (t) async {
      String? clipboard;
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') clipboard = (call.arguments as Map)['text'] as String;
        return null;
      });
      addTearDown(() => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      bool? copied;
      await pumpPage(
        t,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => copied = await CancellationSheet.show(context, category: finding.category, tracker: finding.tracker, today: DateTime.utc(2026, 10, 22)),
            child: const Text('auf'),
          ),
        ),
      );
      await t.tap(find.text('auf'));
      await t.pumpAndSettle();
      expect(find.textContaining('Kündigung: Netflix (Abos)'), findsOneWidget);
      expect(find.text('Teilen'), findsOneWidget);
      await t.tap(find.text('Kopieren'));
      await t.pumpAndSettle();
      expect(copied, isTrue);
      expect(clipboard, contains('Kündigung: Netflix (Abos)'));
      expect(clipboard, contains('zum nächstmöglichen Zeitpunkt'));
    });
  });
}
