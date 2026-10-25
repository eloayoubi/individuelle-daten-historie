import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/di/lookup.dart';
import 'package:kostenkurve/core/utils/json_store.dart';
import 'package:kostenkurve/core/theme/app_theme.dart';
import 'package:kostenkurve/core/widgets/widgets.dart';
import 'package:kostenkurve/features/account/view/account_page.dart';
import 'package:kostenkurve/features/auth/data/auth_repository.dart';
import 'package:kostenkurve/features/auth/data/mock_auth_repository.dart';
import 'package:kostenkurve/features/auth/view/auth_page.dart';
import 'package:kostenkurve/features/categories/cubit/field_editor_cubit.dart';
import 'package:kostenkurve/features/categories/data/category_templates.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/categories/view/add_category_sheet.dart';
import 'package:kostenkurve/features/categories/view/categories_page.dart';
import 'package:kostenkurve/features/categories/view/category_detail_page.dart';
import 'package:kostenkurve/features/categories/view/category_setup_page.dart';
import 'package:kostenkurve/features/categories/view/field_editor_page.dart';
import 'package:kostenkurve/features/categories/view/tracker_setup_page.dart';
import 'package:kostenkurve/features/entries/cubit/entry_form_cubit.dart';
import 'package:kostenkurve/features/entries/cubit/tracker_cubit.dart';
import 'package:kostenkurve/features/entries/view/entry_form_page.dart';
import 'package:kostenkurve/features/entries/view/price_history_page.dart';
import 'package:kostenkurve/features/entries/view/tracker_page.dart';
import 'package:kostenkurve/features/home/view/home_page.dart';
import 'package:kostenkurve/features/insights/view/insights_page.dart';
import 'package:kostenkurve/features/home/view/widgets/quick_add_sheet.dart';
import 'package:kostenkurve/features/home/view/widgets/start_card.dart';
import 'package:kostenkurve/features/legal/data/legal_document.dart';
import 'package:kostenkurve/features/legal/view/legal_page.dart';
import 'package:kostenkurve/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:kostenkurve/features/onboarding/view/onboarding_page.dart';
import 'package:kostenkurve/features/plus/cubit/plus_cubit.dart';
import 'package:kostenkurve/features/plus/data/plus_repository.dart';
import 'package:kostenkurve/features/plus/data/plus_store.dart';
import 'package:kostenkurve/features/plus/view/paywall_page.dart';
import 'package:kostenkurve/features/settings/view/settings_page.dart';
import 'package:kostenkurve/features/sharing/view/join_sheet.dart';
import 'package:kostenkurve/features/sharing/view/share_page.dart';
import 'package:kostenkurve/features/shell/view/shell_page.dart';
import 'package:kostenkurve/features/storage/data/storage_mode.dart';
import 'package:kostenkurve/features/storage/view/cloud_paused_page.dart';
import 'package:kostenkurve/features/storage/view/start_page.dart';
import 'package:kostenkurve/l10n/generated/app_localizations.dart';

import 'support/pump_app.dart';

/// Jede Seite rendert mit den Mock-Repositories in Hell und Dunkel ohne Fehler.
void main() {
  setUpAll(() async {
    await ensureMockDependencies();
    await loadAppFonts();
  });
  // Konto-Tests melden das Beispielkonto an, Speicherort-Tests wechseln nach „Lokal“ – danach wieder
  // abgemeldet und in der Mock-Cloud.
  tearDown(() async {
    await lookup<AuthRepository>().signOut();
    // Abmelden in der Cloud führt zum Start-Bildschirm (StorageCubit) – erst danach zurück.
    await Future<void>.delayed(Duration.zero);
    await useMockCloud();
  });

  Widget onboarding() => BlocProvider(
    create: (_) => OnboardingCubit(MockCategoriesRepository(seed: const []), MemoryJsonStore())..load(),
    child: const OnboardingPage(),
  );

  final templates = CategoryTemplates.all(lookupAppLocalizations(const Locale('de')));
  final gas = MockCategoriesRepository.categories.firstWhere((c) => c.id == 'c-heizung').trackers.single;
  final strom = MockCategoriesRepository.categories.firstWhere((c) => c.id == 'c-strom');
  final auto = MockCategoriesRepository.categories.firstWhere((c) => c.id == 'c-auto');
  final miete = MockCategoriesRepository.categories.firstWhere((c) => c.id == 'c-miete');

  final pages = <(String, Widget)>[
    ('shell', const ShellView()),
    ('home', const HomePage()),
    ('home start card', ListView(children: [StartCard(year: 2026, onAdd: () {})])),
    ('settings', const SettingsPage()),
    ('placeholder', const PlaceholderPage(title: 'Auswertung', icon: CupertinoIcons.chart_bar_alt_fill, description: 'Kommt bald.')),
    ('categories', const CategoriesPage()),
    ('category detail', const CategoryDetailPage(categoryId: 'c-strom')),
    ('category detail empty', const CategoryDetailPage(categoryId: 'gibt-es-nicht')),
    ('category detail contracts', const CategoryDetailPage(categoryId: 'c-internet')),
    ('tracker setup', const TrackerSetupPage(categoryId: 'c-strom', trackerId: 't-strom')),
    ('tracker setup missing', const TrackerSetupPage(categoryId: 'c-strom', trackerId: 'weg')),
    ('setup from template', CategorySetupPage(template: templates.first)),
    ('setup with two trackers', CategorySetupPage(template: templates.firstWhere((t) => t.key == 'internet'))),
    ('setup custom', const CategorySetupPage()),
    ('field editor new', const FieldEditorPage(args: FieldEditorArgs(trackerId: 't-gas'))),
    ('field editor meter', FieldEditorPage(args: FieldEditorArgs(trackerId: gas.id, field: gas.fields.first, hasValues: true))),
    ('entry form new', EntryFormPage(args: EntryFormArgs(category: strom, tracker: strom.trackers.single))),
    ('entry form edit', EntryFormPage(args: EntryFormArgs(category: strom, tracker: strom.trackers.single, entry: strom.trackers.single.entries[1]))),
    ('entry form car', EntryFormPage(args: EntryFormArgs(category: auto, tracker: auto.trackers.single))),
    ('entry form bill', EntryFormPage(args: EntryFormArgs(category: strom, tracker: strom.trackers.single.copyWith(entries: [])))),
    ('entry form contract', EntryFormPage(args: EntryFormArgs(category: strom, tracker: strom.trackers.single, contract: true))),
    ('tracker meter', const TrackerPage(args: TrackerArgs(categoryId: 'c-strom', trackerId: 't-strom'))),
    ('tracker water', const TrackerPage(args: TrackerArgs(categoryId: 'c-wasser', trackerId: 't-wasser'))),
    ('tracker contract', const TrackerPage(args: TrackerArgs(categoryId: 'c-internet', trackerId: 't-glasfaser'))),
    ('tracker missing', const TrackerPage(args: TrackerArgs(categoryId: 'c-strom', trackerId: 'weg'))),
    (
      'price history',
      BlocProvider(
        create: (_) => lookup<TrackerCubit>(param1: const TrackerArgs(categoryId: 'c-strom', trackerId: 't-strom'))..load(),
        child: const PriceHistoryPage(fieldId: 'f-strom-ap'),
      ),
    ),
    ('tracker car with formula', const TrackerPage(args: TrackerArgs(categoryId: 'c-auto', trackerId: 't-golf'))),
    ('tracker water included', const TrackerPage(args: TrackerArgs(categoryId: 'c-wasser', trackerId: 't-wasser'))),
    ('insights', const InsightsPage()),
    ('field editor formula', FieldEditorPage(args: FieldEditorArgs(trackerId: auto.trackers.single.id, tracker: auto.trackers.single, field: auto.trackers.single.fields.firstWhere((f) => f.formula != null)))),
    ('entry form settlement', EntryFormPage(args: EntryFormArgs(category: miete, tracker: miete.trackers.single, entry: miete.trackers.single.entries[1]))),
    ('account', const AccountPage()),
    ('share owner', const SharePage(categoryId: 'c-miete')),
    ('share missing', const SharePage(categoryId: 'weg')),
    ('join', const JoinSheet(code: 'K7Q2M9X4TA')),
    ('paywall', const PaywallPage()),
    ('start', const StartPage()),
    ('register', const AuthPage()),
    ('sign in', const AuthPage(mode: AuthMode.signIn)),
    ('cloud paused', const CloudPausedPage()),
    ('privacy', const LegalPage(document: LegalDocument.privacy)),
    ('terms', const LegalPage(document: LegalDocument.terms)),
    ('imprint', const LegalPage(document: LegalDocument.imprint)),
    ('onboarding', onboarding()),
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
        expect(find.textContaining(RegExp(r'^\+.* m³ seit')), findsOneWidget);
        await t.tap(find.text('Eintrag speichern'));
        await t.pumpAndSettle();
        expect(find.byType(EntryFormPage), findsNothing);
        expect(find.text('Gespeichert.'), findsOneWidget);
        expect(t.takeException(), isNull);
      });

      testWidgets('Details: Anbieter in der Kategorie ändern, ohne Eintrag', (t) async {
        // Die Mock-Daten gelten für alle Tests: ein neuer Name je Durchlauf.
        final provider = 'Anbieter $mode';
        await pumpPage(t, const CategoryDetailPage(categoryId: 'c-internet'), theme: theme, size: const Size(390, 1400));
        await t.pumpAndSettle();
        expect(find.text('Feld hinzufügen'), findsNothing);
        await t.tap(find.text('Anbieter').first);
        await t.pumpAndSettle();
        await t.enterText(find.byType(TextField).last, provider);
        await t.tap(find.text('Speichern'));
        await t.pumpAndSettle();
        expect(find.text(provider), findsOneWidget);
        expect(t.takeException(), isNull);
      });

      testWidgets('Bearbeiten führt zu Feldern, getrennt nach Verlauf und Details', (t) async {
        await pumpPage(t, const CategoryDetailPage(categoryId: 'c-strom'), theme: theme, size: const Size(390, 1400));
        await t.pumpAndSettle();
        await t.tap(find.text('Bearbeiten'));
        await t.pumpAndSettle();
        expect(find.byType(TrackerSetupPage), findsOneWidget);
        expect(find.text('Werte mit Verlauf'), findsOneWidget);
        expect(find.text('Details'), findsOneWidget);
        expect(find.text('Feld hinzufügen'), findsOneWidget);
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

      testWidgets('Auswertung: Jahr wechseln, Prognose verschwindet', (t) async {
        await pumpPage(t, const InsightsPage(), theme: theme, size: const Size(390, 2600));
        await t.pumpAndSettle();
        expect(find.text('Prognose 2027'), findsWidgets);
        expect(find.text('Abschlags-Check'), findsOneWidget);
        await t.tap(find.text('2025'));
        await t.pumpAndSettle();
        expect(find.text('Prognose 2027'), findsNothing);
        expect(t.takeException(), isNull);
      });

      testWidgets('Formel-Editor zeigt Vorschau und Fehler live', (t) async {
        final golf = auto.trackers.single;
        await pumpPage(t, FieldEditorPage(args: FieldEditorArgs(trackerId: golf.id, tracker: golf, field: golf.fields.firstWhere((f) => f.formula != null))), theme: theme, size: const Size(390, 2600));
        await t.pumpAndSettle();
        expect(find.textContaining('Mit dem letzten Eintrag'), findsOneWidget);
        final formulaField = find.widgetWithText(TextField, 'runden(liter / verbrauch * 100; 1)');
        await t.enterText(formulaField, 'liter / strecke');
        await t.pumpAndSettle();
        expect(find.text('Unbekannter Name „strecke“.'), findsOneWidget);
        await t.tap(find.text('verbrauch'));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      });

      testWidgets('Konto per E-Mail-Code sichern, dann Einladung erstellen', (t) async {
        await pumpPage(t, const AccountPage(), theme: theme, size: const Size(390, 1400));
        await t.pumpAndSettle();
        expect(find.text('Nur auf diesem Gerät'), findsOneWidget);
        await t.tap(find.text('Mit E-Mail sichern'));
        await t.pumpAndSettle();
        await t.enterText(find.byType(TextField).last, 'elias@example.com');
        await t.pump();
        await t.tap(find.text('Code senden'));
        await t.pumpAndSettle();
        await t.enterText(find.byType(TextField).last, '123456');
        await t.pump();
        await t.tap(find.text('Bestätigen'));
        await t.pumpAndSettle();
        expect(find.textContaining('elias@example.com'), findsOneWidget);

        await pumpPage(t, const SharePage(categoryId: 'c-miete'), theme: theme, size: const Size(390, 1600));
        await t.pumpAndSettle();
        await t.tap(find.text('Einladung erstellen'));
        await t.pumpAndSettle();
        expect(find.text(MockCategoriesRepository.demoInvite), findsOneWidget);
        expect(t.takeException(), isNull);
      });

      testWidgets('Onboarding: Vorlagen wählen, anlegen, Erinnerungen später', (t) async {
        await pumpPage(t, onboarding(), theme: theme, size: const Size(390, 1600));
        await t.pumpAndSettle();
        await t.tap(find.text('Los geht\'s'));
        await t.pumpAndSettle();
        expect(find.text('3 Kategorien anlegen'), findsOneWidget);
        await t.tap(find.text('Wasser'));
        await t.pumpAndSettle();
        await t.tap(find.text('2 Kategorien anlegen'));
        await t.pumpAndSettle();
        expect(find.text('Nichts vergessen'), findsOneWidget);
        await t.tap(find.text('Später'));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      });

      testWidgets('Was wäre wenn: neuer Arbeitspreis ändert die Prognose', (t) async {
        await pumpPage(t, const InsightsPage(), theme: theme, size: const Size(390, 3200));
        await t.pumpAndSettle();
        await t.tap(find.text('Was wäre wenn …'));
        await t.pumpAndSettle();
        expect(find.text('Wie mit heutigen Preisen'), findsOneWidget);
        await t.enterText(find.byType(TextField).first, '0,60');
        await t.pumpAndSettle();
        expect(find.textContaining('mit heutigen Preisen'), findsOneWidget);
        expect(find.text('Wie mit heutigen Preisen'), findsNothing);
        expect(t.takeException(), isNull);
      });

      testWidgets('Start: lokal kostenlos oder Cloud mit Preis, lokal wählen', (t) async {
        await lookup<StorageModeStore>().set(null);
        await pumpPage(t, const StartPage(), theme: theme, size: const Size(390, 1400));
        await t.pumpAndSettle();
        expect(find.text('Kostenlos · ohne Konto'), findsOneWidget);
        expect(find.text('2,00 € im Monat · mit Konto'), findsOneWidget);
        expect(find.text('Ich habe schon ein Konto'), findsOneWidget);
        await t.tap(find.text('Kostenlos lokal starten'));
        await t.pumpAndSettle();
        expect(lookup<StorageModeStore>().mode, StorageMode.local);
        expect(t.takeException(), isNull);
      });

      testWidgets('Registrieren: E-Mail-Code, danach Paywall „lokal kostenlos, Cloud 2 €“', (t) async {
        await lookup<StorageModeStore>().set(null);
        await pumpPage(t, Builder(builder: (context) => AppButton(label: 'los', onPressed: () => AuthPage.open(context))), theme: theme, size: const Size(390, 1400));
        await t.tap(find.text('los'));
        await t.pumpAndSettle();
        expect(find.text('Code senden'), findsOneWidget);
        expect(find.textContaining('Nutzungsbedingungen'), findsOneWidget);
        await t.enterText(find.byType(TextField).first, 'kein-at');
        await t.pump();
        expect(t.widget<AppButton>(find.widgetWithText(AppButton, 'Code senden')).onPressed, isNull);
        await t.enterText(find.byType(TextField).first, 'elias@example.com');
        await t.pump();
        await t.tap(find.text('Code senden'));
        await t.pumpAndSettle();
        expect(find.textContaining('Neuen Code senden ('), findsOneWidget);
        await t.enterText(find.byType(TextField).last, MockAuthRepository.demoCode);
        await t.pump();
        await t.tap(find.text('Bestätigen'));
        await t.pumpAndSettle();
        expect(find.byType(PaywallPage), findsOneWidget);
        expect(find.text('Kostenlos'), findsOneWidget);
        expect(find.text('2,00 €/Monat'), findsOneWidget);
        expect(find.text('Cloud abonnieren – 2,00 €/Monat'), findsOneWidget);
        expect(find.text('Kostenlos lokal nutzen'), findsOneWidget);
        await t.pump(const Duration(seconds: 61));
        expect(t.takeException(), isNull);
      });

      testWidgets('Paywall: Abo abschließen führt in die Cloud', (t) async {
        await lookup<StorageModeStore>().set(StorageMode.local);
        await lookup<AuthRepository>().signInWithApple();
        // Eigenes Abo für diesen Test: Der Mock-Kauf bliebe sonst für alle folgenden aktiv.
        final repo = MockPlusRepository();
        await pumpPage(
          t,
          BlocProvider(create: (_) => PlusCubit(repo, MockPlusStore(repo))..load(), child: const PaywallPage()),
          theme: theme,
          size: const Size(390, 1600),
        );
        await t.pumpAndSettle();
        await t.tap(find.text('Cloud abonnieren – 2,00 €/Monat'));
        await t.pumpAndSettle();
        expect(lookup<StorageModeStore>().mode, StorageMode.cloud);
        expect(t.takeException(), isNull);
      });

      testWidgets('Abo-Seite ohne Konto: erst Konto erstellen, Pflicht-Links', (t) async {
        await pumpPage(t, const PaywallPage(), theme: theme, size: const Size(390, 1600));
        await t.pumpAndSettle();
        expect(find.text('2,00 €/Monat'), findsOneWidget);
        expect(find.text('Konto erstellen'), findsOneWidget);
        expect(find.textContaining('Verlängert sich automatisch'), findsOneWidget);
        expect(find.text('Nutzungsbedingungen'), findsOneWidget);
        expect(find.text('Datenschutz'), findsOneWidget);
        await t.tap(find.text('Datenschutz'));
        await t.pumpAndSettle();
        expect(find.text('Kurz gesagt'), findsOneWidget);
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
