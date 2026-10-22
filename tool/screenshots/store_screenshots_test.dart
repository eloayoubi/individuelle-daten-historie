import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/di/lookup.dart';
import 'package:kostenkurve/core/theme/app_theme.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/category_templates.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/categories/view/category_setup_page.dart';
import 'package:kostenkurve/features/entries/cubit/entry_form_cubit.dart';
import 'package:kostenkurve/features/entries/cubit/tracker_cubit.dart';
import 'package:kostenkurve/features/entries/view/entry_form_page.dart';
import 'package:kostenkurve/features/entries/view/tracker_page.dart';
import 'package:kostenkurve/features/shell/cubit/shell_cubit.dart';
import 'package:kostenkurve/features/shell/view/shell_page.dart';
import 'package:kostenkurve/l10n/generated/app_localizations.dart';

import '../../test/support/pump_app.dart';
import '../branding/png_golden_comparator.dart';
import 'demo_data_en.dart';
import 'store_frame.dart';

/// Store-Screenshots für App Store Connect (iPhone 6,9", 1320 × 2868 px), Deutsch und Englisch.
///
/// ```sh
/// flutter test tool/screenshots/store_screenshots_test.dart --update-goldens
/// ```
///
/// Schreibt nach `ios/fastlane/screenshots/<sprache>/`; `cd ios && fastlane metadata` lädt sie hoch.
/// Die Seiten sind die echten Widgets mit den Mock-Daten (englische Namen für en-US), im Rahmen aus
/// `store_frame.dart`. Ohne `--update-goldens` prüft der Lauf nur, ob die Bilder noch aktuell sind.
void main() {
  useOpaquePngGoldens();

  setUpAll(() async {
    await ensureMockDependencies();
    await loadAppFonts();
    await _loadIconAndFallbackFonts();
  });

  for (final language in _Language.values) {
    group(language.folder, () {
      // Jede Aufnahme bekommt frische Beispieldaten, auf Englisch mit englischen Namen.
      setUp(() {
        getIt
          ..unregister<CategoriesRepository>()
          ..registerLazySingleton<CategoriesRepository>(
            () => MockCategoriesRepository(seed: language == _Language.en ? englishDemoCategories() : null),
          );
      });

      for (final (index, shot) in _shots.indexed) {
        final file = '${'${index + 1}'.padLeft(2, '0')}_${shot.name}.png';
        testWidgets(file, (tester) async {
          final l10n = lookupAppLocalizations(language.locale);
          final theme = shot.dark ? AppTheme.night : AppTheme.light;
          await pumpPage(
            tester,
            StoreFrame(
              headline: shot.headline(language),
              subline: shot.subline(language),
              theme: theme,
              screen: shot.page(language, l10n),
            ),
            size: StoreFrame.size,
            locale: language.locale,
          );
          await _settle(tester);
          await shot.prepare?.call(tester);
          await _settle(tester);
          expect(tester.takeException(), isNull);
          await expectLater(find.byKey(StoreFrame.captureKey), matchesGoldenFile('../../ios/fastlane/screenshots/${language.folder}/$file'));
        }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
      }
    });
  }
}

enum _Language {
  de('de-DE', Locale('de')),
  en('en-US', Locale('en'));

  const _Language(this.folder, this.locale);

  /// Ordner für fastlane deliver.
  final String folder;
  final Locale locale;
}

/// Eine Aufnahme: Texte im Rahmen und die Seite im Gerät.
class _Shot {
  const _Shot({required this.name, required this.de, required this.en, required this.page, this.dark = false, this.prepare});

  final String name;

  /// Überschrift und Unterzeile je Sprache.
  final (String, String) de;
  final (String, String) en;
  final Widget Function(_Language language, AppLocalizations l10n) page;
  final bool dark;

  /// Schritte nach dem Laden, z. B. einen Wert eintippen.
  final Future<void> Function(WidgetTester tester)? prepare;

  String headline(_Language language) => (language == _Language.de ? de : en).$1;
  String subline(_Language language) => (language == _Language.de ? de : en).$2;
}

/// Reihenfolge = Reihenfolge im Store. Die ersten drei zählen am meisten (Prognose, Verlauf, Auswertung).
final _shots = <_Shot>[
  _Shot(
    name: 'overview',
    de: ('Alle Kosten.\nEine Kurve.', 'Zählerstände, Verträge und Fixkosten an einem Ort – mit Prognose fürs nächste Jahr.'),
    en: ('All your costs.\nOne curve.', 'Meter readings, contracts and fixed costs in one place – with a forecast for next year.'),
    page: (_, _) => const ShellView(),
  ),
  _Shot(
    name: 'history',
    de: ('Jeder Zähler\nmit Verlauf', 'Verbrauch und Kosten Monat für Monat – im Vergleich zum Vorjahr.'),
    en: ('Every meter,\nwith history', 'Usage and costs month by month – compared with last year.'),
    page: (_, _) => const TrackerPage(args: TrackerArgs(categoryId: 'c-heizung', trackerId: 't-gas')),
  ),
  _Shot(
    name: 'insights',
    de: ('Prognose\nmit Spanne', 'Kosten je Monat und Kategorie, Jahresvergleich und ein Abschlags-Check gegen Nachzahlungen.'),
    en: ('Forecasts\nwith a range', 'Costs per month and category, year-over-year comparison and an instalment check.'),
    page: (_, _) => BlocProvider(create: (_) => ShellCubit()..select(ShellTab.insights), child: const ShellView()),
    dark: true,
  ),
  _Shot(
    name: 'templates',
    de: ('Vorlagen oder\neigene Felder', 'Strom, Heizung, Miete, Auto, Abos … – Felder, Einheiten und Formeln frei anpassbar.'),
    en: ('Templates or\nyour own fields', 'Electricity, heating, rent, car, subscriptions … – fields, units and formulas your way.'),
    page: (_, l10n) {
      final templates = CategoryTemplates.all(l10n);
      return CategorySetupPage(template: templates.where((t) => t.key == 'strom').firstOrNull ?? templates.first);
    },
  ),
  _Shot(
    name: 'entry',
    de: ('In Sekunden\neingetragen', 'Mit letztem Stand und Verbrauch seitdem – auch offline im Keller.'),
    en: ('Logged\nin seconds', 'See your last reading and the usage since – even offline in the basement.'),
    page: (language, _) {
      final strom = (language == _Language.en ? englishDemoCategories() : MockCategoriesRepository.categories).firstWhere((c) => c.id == 'c-strom');
      return EntryFormPage(args: EntryFormArgs(category: strom, tracker: strom.trackers.first, decimalSeparator: language == _Language.de ? ',' : '.'));
    },
    prepare: (tester) => _enterNextReading(tester, MockCategoriesRepository.categories.firstWhere((c) => c.id == 'c-strom').trackers.first),
  ),
];

/// Neuer Zählerstand ins erste Feld: der letzte plus etwa drei Wochen Verbrauch, damit das Formular
/// „+… kWh seit …“ zeigt. Danach ohne Fokus, also ohne Cursor.
Future<void> _enterNextReading(WidgetTester tester, Tracker tracker) async {
  final meter = tracker.fields.where((f) => f.role == FieldRole.meterReading).firstOrNull;
  final last = meter == null ? null : tracker.entries.reversed.map((e) => e.values[meter.id]).whereType<num>().firstOrNull;
  final input = find.byType(EditableText);
  if (last == null || input.evaluate().isEmpty) return;
  await tester.enterText(input.first, '${(last + 186).round()}');
  await tester.pump();
  FocusManager.instance.primaryFocus?.unfocus();
}

/// Lädt Daten und lässt Animationen auslaufen, ohne auf Endlos-Animationen zu warten.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

/// CupertinoIcons und Material-Icons wie in der App; Inter zusätzlich unter den Systemschrift-Namen,
/// die Cupertino- und Material-Widgets auf iOS ohne eigene Schrift benutzen (sonst Platzhalter-Kästchen).
Future<void> _loadIconAndFallbackFonts() async {
  final fonts = <String, String>{
    'packages/cupertino_icons/CupertinoIcons': 'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    for (final family in ['CupertinoSystemText', 'CupertinoSystemDisplay', '.SF Pro Text', '.SF Pro Display', '.SF UI Text', '.SF UI Display', 'Roboto'])
      family: 'assets/fonts/${family.contains('Display') ? 'InterTight' : 'Inter'}.ttf',
  };
  for (final MapEntry(key: family, value: asset) in fonts.entries) {
    try {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    } on Object catch (e) {
      debugPrint('Schrift $family nicht geladen: $e');
    }
  }
}
