import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/theme/app_theme.dart';
import 'package:kostenkurve/core/widgets/widgets.dart';
import 'package:kostenkurve/features/categories/cubit/field_editor_cubit.dart';
import 'package:kostenkurve/features/categories/data/category_templates.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/categories/view/add_category_sheet.dart';
import 'package:kostenkurve/features/categories/view/categories_page.dart';
import 'package:kostenkurve/features/categories/view/category_detail_page.dart';
import 'package:kostenkurve/features/categories/view/category_setup_page.dart';
import 'package:kostenkurve/features/categories/view/field_editor_page.dart';
import 'package:kostenkurve/features/entries/cubit/entry_form_cubit.dart';
import 'package:kostenkurve/features/entries/cubit/tracker_cubit.dart';
import 'package:kostenkurve/features/entries/view/entry_form_page.dart';
import 'package:kostenkurve/features/entries/view/tracker_page.dart';
import 'package:kostenkurve/features/home/view/home_page.dart';
import 'package:kostenkurve/features/home/view/widgets/quick_add_sheet.dart';
import 'package:kostenkurve/features/settings/view/settings_page.dart';
import 'package:kostenkurve/features/shell/view/shell_page.dart';
import 'package:kostenkurve/l10n/generated/app_localizations.dart';

import 'support/pump_app.dart';

/// Jede Seite rendert mit den Mock-Repositories in Hell und Dunkel ohne Fehler.
void main() {
  setUpAll(() async {
    await ensureMockDependencies();
    await loadAppFonts();
  });

  final templates = CategoryTemplates.all(lookupAppLocalizations(const Locale('de')));
  final gas = MockCategoriesRepository.categories.firstWhere((c) => c.id == 'c-heizung').trackers.single;
  final strom = MockCategoriesRepository.categories.firstWhere((c) => c.id == 'c-strom');
  final auto = MockCategoriesRepository.categories.firstWhere((c) => c.id == 'c-auto');

  final pages = <(String, Widget)>[
    ('shell', const ShellView()),
    ('home', const HomePage()),
    ('settings', const SettingsPage()),
    ('placeholder', const PlaceholderPage(title: 'Auswertung', icon: CupertinoIcons.chart_bar_alt_fill, description: 'Kommt bald.')),
    ('categories', const CategoriesPage()),
    ('category detail', const CategoryDetailPage(categoryId: 'c-strom')),
    ('category detail empty', const CategoryDetailPage(categoryId: 'gibt-es-nicht')),
    ('setup from template', CategorySetupPage(template: templates.first)),
    ('setup with two trackers', CategorySetupPage(template: templates.firstWhere((t) => t.key == 'internet'))),
    ('setup custom', const CategorySetupPage()),
    ('field editor new', const FieldEditorPage(args: FieldEditorArgs(trackerId: 't-gas'))),
    ('field editor meter', FieldEditorPage(args: FieldEditorArgs(trackerId: gas.id, field: gas.fields.first, hasValues: true))),
    ('entry form new', EntryFormPage(args: EntryFormArgs(category: strom, tracker: strom.trackers.single))),
    ('entry form edit', EntryFormPage(args: EntryFormArgs(category: strom, tracker: strom.trackers.single, entry: strom.trackers.single.entries[1]))),
    ('entry form car', EntryFormPage(args: EntryFormArgs(category: auto, tracker: auto.trackers.single))),
    ('tracker meter', const TrackerPage(args: TrackerArgs(categoryId: 'c-strom', trackerId: 't-strom'))),
    ('tracker water', const TrackerPage(args: TrackerArgs(categoryId: 'c-wasser', trackerId: 't-wasser'))),
    ('tracker contract', const TrackerPage(args: TrackerArgs(categoryId: 'c-internet', trackerId: 't-glasfaser'))),
    ('tracker missing', const TrackerPage(args: TrackerArgs(categoryId: 'c-strom', trackerId: 'weg'))),
  ];

  for (final (mode, theme) in [('hell', AppTheme.light), ('dunkel', AppTheme.night)]) {
    group(mode, () {
      for (final (name, page) in pages) {
        testWidgets('$name rendert', (t) async {
          await pumpPage(t, page, theme: theme);
          await t.pump(const Duration(seconds: 1));
          expect(t.takeException(), isNull);
        });
      }

      testWidgets('Schnellerfassung: Tracker wählen, Stand eintragen, speichern', (t) async {
        await pumpPage(t, const HomePage(), theme: theme, size: const Size(390, 1200));
        await t.tap(find.bySemanticsLabel('Eintrag erfassen'));
        await t.pumpAndSettle();
        expect(find.byType(QuickAddSheet), findsOneWidget);
        await t.tap(find.text('Kaltwasser').last);
        await t.pumpAndSettle();
        expect(find.byType(EntryFormPage), findsOneWidget);
        expect(find.textContaining('Zuletzt'), findsOneWidget);
        await t.enterText(find.byType(TextField).first, '760');
        await t.pumpAndSettle();
        expect(find.textContaining('m³ seit'), findsOneWidget);
        await t.tap(find.text('Eintrag speichern'));
        await t.pumpAndSettle();
        expect(find.byType(EntryFormPage), findsNothing);
        expect(find.text('Gespeichert.'), findsOneWidget);
        expect(t.takeException(), isNull);
      });

      testWidgets('Verlauf: Kennzahl wechseln und Monat antippen', (t) async {
        await pumpPage(t, const TrackerPage(args: TrackerArgs(categoryId: 'c-strom', trackerId: 't-strom')), theme: theme, size: const Size(390, 1400));
        await t.pumpAndSettle();
        expect(find.text('Kosten'), findsOneWidget);
        await t.tap(find.text('Verbrauch'));
        await t.pumpAndSettle();
        expect(find.textContaining('kWh'), findsWidgets);
        expect(t.takeException(), isNull);
      });

      testWidgets('Tab-Leiste wechselt zu den Einstellungen', (t) async {
        await pumpPage(t, const ShellView(), theme: theme);
        await t.tap(find.text('Einstellungen'));
        await t.pumpAndSettle();
        expect(find.byType(AppSegmented<ThemeMode>), findsOneWidget);
      });

      testWidgets('Kategorie aus der Vorlage anlegen öffnet ihre Detailseite', (t) async {
        await pumpPage(t, const CategoriesPage(), theme: theme);
        await t.tap(find.bySemanticsLabel('Kategorie hinzufügen'));
        await t.pumpAndSettle();
        expect(find.byType(AddCategorySheet), findsOneWidget);
        await t.tap(find.text('Abos & Mitgliedschaften').last);
        await t.pumpAndSettle();
        expect(find.byType(CategorySetupPage), findsOneWidget);
        await t.scrollUntilVisible(find.text('Kategorie anlegen'), 300, scrollable: find.byType(Scrollable).first);
        await t.tap(find.text('Kategorie anlegen'));
        await t.pumpAndSettle();
        expect(find.byType(CategoryDetailPage), findsOneWidget);
        expect(find.text('Streaming'), findsOneWidget);
        expect(t.takeException(), isNull);
      });

      testWidgets('Bearbeiten zeigt die Ziehgriffe', (t) async {
        await pumpPage(t, const CategoriesPage(), theme: theme);
        await t.tap(find.text('Bearbeiten'));
        await t.pumpAndSettle();
        expect(find.byType(ReorderableListView), findsOneWidget);
        expect(find.byIcon(CupertinoIcons.line_horizontal_3), findsWidgets);
        await t.tap(find.text('Fertig'));
        await t.pumpAndSettle();
        expect(find.byType(ReorderableListView), findsNothing);
      });

      testWidgets('Feld-Editor zeigt je nach Typ Einheit, Intervall oder Auswahlwerte', (t) async {
        // Hoch genug, damit alle Abschnitte gebaut werden (ListView baut nur Sichtbares).
        await pumpPage(t, const FieldEditorPage(args: FieldEditorArgs(trackerId: 't-strom')), theme: theme, size: const Size(390, 2600));
        expect(find.text('Einheit'), findsOneWidget);
        await t.tap(find.text('Betrag (€)'));
        await t.pumpAndSettle();
        expect(find.text('Fällig'), findsNothing);
        await t.tap(find.text('Wiederkehrender Betrag'));
        await t.pumpAndSettle();
        expect(find.text('Fällig'), findsOneWidget);
        await t.tap(find.text('Auswahl'));
        await t.pumpAndSettle();
        expect(find.text('Auswahlwerte'), findsOneWidget);
        expect(find.text('Einheit'), findsNothing);
        expect(t.takeException(), isNull);
      });
    });
  }

  testWidgets('englische Texte rendern', (t) async {
    await pumpPage(t, const ShellView(), locale: const Locale('en'));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Overview'), findsWidgets);
    expect(t.takeException(), isNull);
  });
}
