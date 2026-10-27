import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/di/lookup.dart';
import 'package:kostenkurve/core/theme/app_theme.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/categories/view/category_detail_page.dart';
import 'package:kostenkurve/features/categories/view/widgets/meter_sheet.dart';
import 'package:kostenkurve/features/entries/cubit/entry_form_cubit.dart';
import 'package:kostenkurve/features/entries/cubit/tracker_cubit.dart';
import 'package:kostenkurve/features/entries/view/entry_form_page.dart';
import 'package:kostenkurve/features/entries/view/entries_page.dart';
import 'package:kostenkurve/features/entries/view/price_history_page.dart';
import 'package:kostenkurve/features/entries/view/tracker_page.dart';
import 'package:kostenkurve/features/shell/cubit/shell_cubit.dart';
import 'package:kostenkurve/features/shell/view/shell_page.dart';
import 'package:kostenkurve/features/account/cubit/account_cubit.dart';
import 'package:kostenkurve/features/plus/cubit/plus_cubit.dart';
import 'package:kostenkurve/features/reminders/cubit/reminders_cubit.dart';
import 'package:kostenkurve/features/settings/cubit/appearance_cubit.dart';
import 'package:kostenkurve/features/storage/cubit/storage_cubit.dart';
import 'package:kostenkurve/l10n/generated/app_localizations.dart';

import '../../test/support/pump_app.dart';
import '../branding/png_golden_comparator.dart';

/// Prüf-Screenshots für die Nutzerführung (iPhone 6,9″, extra hoch, damit ganze Listen sichtbar sind):
///
/// ```sh
/// flutter test tool/screenshots/ux_review_test.dart --update-goldens
/// ```
///
/// Schreibt nach `build/ux/` (nicht im Git).
void main() {
  useOpaquePngGoldens();
  setUpAll(() async {
    await ensureMockDependencies();
    await loadAppFonts();
    for (final MapEntry(key: family, value: asset) in {
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      for (final f in [
        'CupertinoSystemText',
        'CupertinoSystemDisplay',
        '.SF Pro Text',
        '.SF Pro Display',
      ])
        f: 'assets/fonts/${f.contains('Display') ? 'InterTight' : 'Inter'}.ttf',
    }.entries) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });

  final strom = MockCategoriesRepository.categories.firstWhere(
    (c) => c.id == 'c-strom',
  );
  final auto = MockCategoriesRepository.categories.firstWhere(
    (c) => c.id == 'c-auto',
  );
  final wasser = MockCategoriesRepository.categories.firstWhere((c) => c.id == 'c-wasser');
  final miete = MockCategoriesRepository.categories.firstWhere((c) => c.id == 'c-miete');
  // Wohnung wie aus der Vorlage: Warmmiete, aufteilbar in Kaltmiete, Betriebs- und Heizkosten.
  FieldDefinition rent(String id, String name, {String? partOf}) =>
      FieldDefinition(id: id, name: name, kind: FieldKind.currency, role: FieldRole.recurringCost, unit: '€/Monat', partOf: partOf);
  final flat = Tracker(
    id: 't-warm',
    name: 'Wohnung',
    fields: [
      rent('w', 'Warmmiete'),
      rent('k', 'Kaltmiete', partOf: 'w'),
      rent('b', 'Betriebskosten', partOf: 'w'),
      rent('h', 'Heizkosten', partOf: 'w'),
      const FieldDefinition(id: 'n', name: 'Nachzahlung / Guthaben', kind: FieldKind.currency, role: FieldRole.oneOffCost, unit: '€'),
    ],
  );
  final flatSplit = flat.copyWith(entries: [Entry(id: 'e', date: DateTime.utc(2026), values: const {'w': 1100, 'k': 800, 'b': 180, 'h': 120})]);
  final screens = <String, (Widget Function(), double)>{
    'home': (() => const ShellView(), 932),
    'insights': (() => BlocProvider(create: (_) => ShellCubit()..select(ShellTab.insights), child: const ShellView()), 2400),
    'settings': (() => BlocProvider(create: (_) => ShellCubit()..select(ShellTab.settings), child: const ShellView()), 2000),
    'category_strom': (
      () => const CategoryDetailPage(categoryId: 'c-strom'),
      1600,
    ),
    'tracker_strom': (
      () => const TrackerPage(
        args: TrackerArgs(categoryId: 'c-strom', trackerId: 't-strom'),
      ),
      2600,
    ),
    'tracker_strom_fold': (
      () => const TrackerPage(
        args: TrackerArgs(categoryId: 'c-strom', trackerId: 't-strom'),
      ),
      932,
    ),
    'tracker_auto': (
      () => const TrackerPage(
        args: TrackerArgs(categoryId: 'c-auto', trackerId: 't-golf'),
      ),
      2000,
    ),
    'tracker_bill_only': (() => const TrackerPage(args: TrackerArgs(categoryId: 'c-neu', trackerId: 't-neu')), 1400),
    'category_bill_only': (() => const CategoryDetailPage(categoryId: 'c-neu'), 1400),
    'form_reading': (
      () => EntryFormPage(
        args: EntryFormArgs(category: strom, tracker: strom.trackers.single),
      ),
      932,
    ),
    'form_bill': (
      () => EntryFormPage(
        args: EntryFormArgs(
          category: strom,
          tracker: strom.trackers.single.copyWith(entries: []),
        ),
      ),
      932,
    ),
    'form_contract': (
      () => EntryFormPage(
        args: EntryFormArgs(
          category: strom,
          tracker: strom.trackers.single,
          contract: true,
        ),
      ),
      932,
    ),
    'form_auto': (
      () => EntryFormPage(
        args: EntryFormArgs(category: auto, tracker: auto.trackers.single),
      ),
      1200,
    ),
    'form_miete': (() => EntryFormPage(args: EntryFormArgs(category: miete, tracker: flat)), 1100),
    'form_miete_split': (() => EntryFormPage(args: EntryFormArgs(category: miete, tracker: flatSplit)), 1300),
    'price_history': (() => const PriceHistoryPage(args: TrackerArgs(categoryId: 'c-strom', trackerId: 't-strom'), fieldId: 'f-strom-ap'), 932),
    'entries_all': (() => const EntriesPage(args: TrackerArgs(categoryId: 'c-strom', trackerId: 't-strom')), 1400),
    'category_heizung': (() => const CategoryDetailPage(categoryId: 'c-heizung'), 1400),
    'category_wasser_zaehler': (() => const CategoryDetailPage(categoryId: 'c-zaehler'), 1600),
    'meter_sheet': (() => MeterSheet(category: wasser, tracker: wasser.trackers.single), 1100),
  };

  // Neuer Stromzähler mit nur einer Rechnung, ohne Preise – zeigt die Hinweise für Einsteiger.
  final strom0 = strom.trackers.single;
  final fresh = Category(
    id: 'c-neu',
    name: 'Strom Wohnung',
    icon: CategoryIcon.bolt,
    swatch: CategorySwatch.orange,
    trackers: [
      Tracker(
        id: 't-neu',
        name: 'Zähler',
        fields: strom0.fields,
        entries: [Entry(id: 'b', date: DateTime.utc(2026, 9, 30), values: {strom0.meter!.id: 508}, periodStart: DateTime.utc(2026, 4), periodEnd: DateTime.utc(2026, 9, 30))],
      ),
    ],
  );
  // Wasser mit vier Zählern in zwei Gruppen, ein gemeinsamer Preis.
  FieldDefinition meter(String id, String name, String group) =>
      FieldDefinition(id: id, name: name, kind: FieldKind.number, role: FieldRole.meterReading, unit: 'm³', meterGroup: group);
  final meters = [meter('bk', 'Bad kalt', 'Kaltwasser'), meter('bw', 'Bad warm', 'Warmwasser'), meter('wk', 'WC kalt', 'Kaltwasser'), meter('ww', 'WC warm', 'Warmwasser')];
  final fourMeters = Category(
    id: 'c-zaehler',
    name: 'Wasser',
    icon: CategoryIcon.drop,
    swatch: CategorySwatch.blue,
    templateKey: 'wasser',
    trackers: [
      Tracker(
        id: 't-zaehler',
        name: 'Wasserzähler',
        fields: [...meters, wasser.trackers.single.fields.firstWhere((f) => f.role == FieldRole.unitPrice)],
        entries: [
          Entry(id: 'p', date: DateTime.utc(2026), values: const {'f-wasser-preis': 4.62}),
          for (var m = 1; m <= 10; m++)
            Entry(id: 'r$m', date: DateTime.utc(2026, m, 1), values: {'bk': 100 + m * 2.1, 'bw': 40 + m * 1.2, 'wk': 20 + m * 0.6, 'ww': 8 + m * 0.3}),
        ],
      ),
    ],
  );
  setUp(() {
    getIt
      ..unregister<CategoriesRepository>()
      ..registerLazySingleton<CategoriesRepository>(() => MockCategoriesRepository(seed: [...MockCategoriesRepository.categories, fresh, fourMeters]));
  });

  for (final MapEntry(key: name, value: (page, height)) in screens.entries) {
    testWidgets(name, (t) async {
      t.view.physicalSize = Size(1290, height * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => lookup<AppearanceCubit>()),
            BlocProvider(create: (_) => lookup<RemindersCubit>()..load()),
            BlocProvider(create: (_) => lookup<AccountCubit>()..load()),
            BlocProvider(create: (_) => lookup<PlusCubit>()..load()),
            BlocProvider(create: (_) => lookup<StorageCubit>()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('de'),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(430, height),
                devicePixelRatio: 3,
                padding: const EdgeInsets.only(top: 59, bottom: 34),
              ),
              child: BlocProvider(
                create: (_) => lookup<ShellCubit>(),
                child: Scaffold(body: page()),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 12; i++) {
        await t.pump(const Duration(milliseconds: 150));
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../../build/ux/$name.png'),
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  }
}
