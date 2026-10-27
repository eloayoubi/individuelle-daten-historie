# Kostenkurve

Zählerstände, Verträge und Kosten an einem Ort – mit Verlauf, Jahresvergleich und Prognose. Nutzer legen eigene Kategorien an (oder starten mit Vorlagen wie Strom, Miete, Auto), definieren ihre Felder selbst (Text, Zahl, Betrag, Prozent, Datum, Formel …) und tragen Werte mit Datum ein. Daraus rechnet die App Verbrauch, Kosten und eine Prognose fürs nächste Jahr; Kategorien lassen sich mit dem Partner teilen.

Produkt, Analyse und Fahrplan: [docs/IMPLEMENTIERUNGSPLAN.md](docs/IMPLEMENTIERUNGSPLAN.md) · Backend: [supabase/README.md](supabase/README.md) · **Supabase verbinden und TestFlight: [docs/SETUP.md](docs/SETUP.md)**

| | |
|---|---|
| Plattformen | iOS (nur iPhone, Hochformat) und Android |
| Bundle-ID | `de.eloayoubi.kostenkurve` |
| Sprachen | Deutsch (Vorlage) und Englisch |
| Design | Apples Designsprache (HIG, iOS 26): Systemfarben, große Titel, gruppierte Karten, CupertinoIcons, Glas-Tab-Leiste – hell und dunkel |

## Stack

| Bereich | Wahl |
|---|---|
| Zustand | `flutter_bloc` – Cubits für reinen Zustand, Blocs nur bei echter Event-Logik; `equatable` für States |
| DI | `get_it`, Zugriff nur über `lookup<T>()` aus `core/di/lookup.dart`, Registrierung in `configureDependencies()` |
| L10n | `flutter gen-l10n`, ARB in `lib/l10n/` (`app_de.arb` = Vorlage), Zugriff über `context.l10n` |
| Theme | `AppColors` + `AppTextStyles` als `ThemeExtension`, Zugriff über `context.colors` / `context.textStyles`; `AppTheme.light` / `AppTheme.night`, Umschalter über `AppearanceCubit` über dem `MaterialApp` |
| Schriften | Inter Tight (Überschriften, Zahlen) + Inter (Text, mit `opsz`-Achse) als gebündelte Variable Fonts in `assets/fonts/` (OFL) – kein `google_fonts`, rendert offline |
| Speicher | Lokal auf dem Gerät (kostenlos, ohne Konto) oder Supabase-Cloud (Postgres + RLS + RPC + Edge Functions) mit Konto und Abo „Kostenkurve Cloud“, 2 €/Monat |
| Tests | `flutter_test`, `bloc_test`, `mocktail` |
| Lints | `flutter_lints` + `prefer_single_quotes`, `prefer_const_constructors`, `prefer_const_declarations`, `require_trailing_commas`, `always_declare_return_types`, `avoid_print` |
| Release | Fastlane (`ios/fastlane`), GitHub Actions (`testflight.yml`, `supabase.yml`) |

## Struktur

```
lib/
  main.dart              DI, dann runApp
  app/app.dart           MaterialApp, Themes, Locales; darüber Darstellung, Erinnerungen, Konto, Cloud-Abo,
                         Speicherort; Einladungslinks öffnen das Beitreten-Sheet; StartGate und Onboarding vor der Shell
  app/launch_splash.dart Startanimation (Lottie) über der App: Die Kachel des nativen Splashs wird zum Icon
  core/
    core.dart            Sammel-Import für Features
    di/                  lookup.dart, injection.dart (configureDependencies)
    theme/               color_config, text_styles, dimensions, app_theme
    extensions/          context (colors, textStyles, l10n), format (€, %, Datum), category (Icons)
    models/tracking.dart Kategorie → Tracker → Felder → Einträge (gemeinsam für alle Features)
    utils/cost_engine.dart  Verbrauch, Kosten und Prognose je Tracker, Tag für Tag
    widgets/             AppText, AppCard, AppButton, AppIconButton, AppChip, AppHeader, SectionHeader,
                         AppSheet, AppToast, PlaceholderPage, AppListGroup/AppListRow, AppIconTile,
                         AppSegmented, AppPressable, GlassSurface, AppTextField, AppSwitch, AppDialog,
                         AppShare (Teilen-Sheet mit iPad-Ursprung), AppKeyboardBar (Fertig-Leiste über dem
                         Zahlenblock auf iOS, im App-builder)
    network/             SupabaseApi (rpc, invoke, table, stream, onChanges, upload/download/remove),
                         SecureSessionStorage (Sitzung im Schlüsselbund)
    config/              Werte aus --dart-define (SUPABASE_URL, SUPABASE_ANON_KEY)
  features/<feature>/
    cubit/               Cubit + State (part-Datei); einmalige Ereignisse als `event` im State,
                         die View reagiert per BlocListener
    data/                x_repository.dart (Interface), mock_x_repository.dart, supabase_x_repository.dart
    view/                Page + feature-eigene Widgets
  l10n/                  app_de.arb (Vorlage), app_en.arb, generated/ (eingecheckt, vom Analyzer ausgeschlossen)
```

Features heute:

- `storage`: Speicherort lokal oder Cloud – Start-Bildschirm mit der Wahl, `StartGate` (Start, „Cloud pausiert“, App), `StorageCategoriesRepository` (Weiche), `StorageTransfer` (Umzug hoch und runter, wiederholbar), `StorageCubit`, Umzugs-Overlay.
- `shell`: Tab-Leiste, `ShellCubit`.
- `onboarding`: erster Start ohne Kategorien – Willkommen, Vorlagen wählen, Erinnerungen.
- `home`: Übersicht.
- `categories`: Kategorien-Tab, Vorlagen, Anlegen, Detailseite (je Tracker Verlauf, Wert eintragen und Details wie Anbieter oder Vertragsende), „Felder und Einstellungen“ je Tracker, Feld-Editor; dazu das Repository mit allen Schreibwegen: lokal `LocalCategoriesRepository` (Datei auf dem Gerät, Logik aus `MemoryCategoriesRepository`), in der Cloud die Offline-Schicht (`OfflineCategoriesRepository`: Cache zum Lesen, Warteschlange für Einträge, beides je Konto) vor Supabase.
- `entries`: Eingabe-Formular aus den Feldern eines Trackers (mit Abrechnungszeitraum für Nachzahlungen), Verlauf je Tracker mit Graph, aktuelle Werte und Einträge („von Anna“ in geteilten Kategorien).
- `attachments`: Belege (Fotos, PDFs) an Einträgen – Hochladen mit Plus, Ansehen für alle Mitglieder.
- `reminders`: lokale Benachrichtigungen ans Ablesen und an Stichtage (`flutter_local_notifications`), an- und ausschaltbar in den Einstellungen.
- `insights`: Auswertung des Jahres: Kosten je Monat und Kategorie, Jahresvergleich, Verbrauch, Prognose mit Spanne und Erklärung, Abschlags-Check, „Was wäre wenn“ mit neuen Preisen.
- `sharing`: Kategorie teilen (Code, Link, QR), Mitglieder und Rollen, Einladung annehmen, Einladungslinks.
- `plus`: Kostenkurve Cloud (technisch weiter `plus`) – Paywall „lokal kostenlos, Cloud 2 €/Monat“, StoreKit 2 (`in_app_purchase`), Stand aus `entitlements`.
- `account`: Konto-Seite (Name, abmelden, löschen; anonymes Testkonto sichern).
- `legal`: Datenschutz, Nutzungsbedingungen, Impressum aus `assets/legal/` (Markdown, DE/EN).
- `settings`: Speicherort (Cloud aktivieren, anmelden, aufs Gerät holen), Konto und Abo, Darstellung, Erinnerungen, Datenexport (CSV + JSON), Rechtliches; Bewertungsbitte nach dem 3. Eintrag.
- `auth`: Registrieren und Anmelden (Apple, 8-stelliger E-Mail-Code, kein Passwort) – `AuthPage` und `AuthRepository`.
- `update`: Pflicht-Update – `ForceUpdateGate` legt über die ganze App „Neue Version verfügbar“ (Lottie-Animation, Link zu TestFlight), sobald `app_releases` einen neueren Build für den Vertriebsweg nennt (TestFlight oder App Store, aus `package_info_plus`). Nur Release-Builds; Debug, Simulator und Android nie. Geprüft beim Start und bei jeder Rückkehr in die App, ohne Netz bleibt alles offen.

**Rechnen:** Rechenlogik liegt in `core/utils/`:

- `cost_engine.dart`: Verbrauch, Kosten nach Herkunft, Trend, Spanne, Abschläge.
- `formula.dart`: eigener Parser für Formel-Felder.
- `formulas.dart`: Formel-Werte je Eintrag (`verbrauch`, `tage`, `monate`, Feld-Kurznamen).
- `dashboard_figures.dart`: Kennzahlen der Kategorie-Übersicht je Zeitraum (Dieser Monat … Gesamt, eigener Zeitraum) mit Vergleich zum Zeitraum davor. Jedes Feld mit Zahlen hat eine Auswertung (`FieldSummary`: Summe, Differenz = neuer minus alter Wert, Durchschnitt, letzter, kleinster, größter Wert), Standard aus dem Zeitverhalten. Welche Kennzahlen eine Kategorie zeigt, steht in `Category.dashboard` (für alle Mitglieder), ohne Wahl Kosten und Verbrauch je Gruppe von Zählern (Kaltwasser, Warmwasser) bzw. je Zähler; dazu wählbar alle Zähler zusammen und eigene Summen (`DashboardMetric.meters`).

Ein Tracker kann seine Kosten einer anderen Kategorie zuordnen (`includedIn`, z. B. Wasser in den Nebenkosten): gezeigt, nie doppelt gezählt.

**Lokal oder Cloud:** Beim ersten Start wählt der Nutzer den Speicherort (Ablauf, Technik und Sicherheit: [IMPLEMENTIERUNGSPLAN.md, Abschnitt 8](docs/IMPLEMENTIERUNGSPLAN.md#8-lokal-oder-cloud-abo)). Lokal liegt alles in `local_data.json` im App-Support-Ordner, ohne Netz und ohne Konto. In der Cloud entscheidet der Server per RLS, ob geschrieben werden darf (Abo des Schreibenden oder des Eigentümers).

**Offline (Cloud):** Mit Supabase liest die App ohne Netz aus dem Cache des letzten Abrufs. Einträge landen zuerst in einer Warteschlange auf dem Gerät und erscheinen sofort. Gesendet wird gleich, beim Zurückkehren in die App und alle 30 Sekunden, solange etwas wartet. Die Id vergibt das Gerät, daher landet ein Eintrag auch bei doppeltem Senden nur einmal (`save_entry` ist ein Upsert). Lässt der Server einen Eintrag gerade nicht zu (Abo abgelaufen, Rolle geändert), bleibt er liegen und die übrigen gehen weiter raus. Die Übersicht zeigt, was noch wartet oder abgelehnt wurde; Abmelden und Konto löschen warnen vor wartenden Einträgen. Kategorien, Tracker und Felder ändern geht nur online.

Cubits mit Parameter (z. B. die Kategorie-Id) sind per `registerFactoryParam` registriert und kommen über `lookup<T>(param1: …)`. Nach jeder Änderung meldet `CategoriesRepository.changes` ein Ereignis, darauf laden Übersicht, Kategorien-Tab und Detailseite neu.

**Mock oder Supabase:** Ohne dart-defines steht `MockCategoriesRepository` (Beispieldaten aus dem Design) für die Cloud, Konto und Abo sind Mocks (E-Mail-Code `123456`, Kauf schaltet sofort frei); lokal ist auch hier die Datei auf dem Gerät. Mit `SUPABASE_URL` und `SUPABASE_ANON_KEY` registriert `configureDependencies()` die Supabase-Varianten.

## Code-Regeln

- **Keine Hex-Farben, keine `TextStyle(...)`, keine festen Strings in Widgets** – immer `context.colors` / `context.textStyles` / `context.l10n`.
- **Neue Farbe/Textstil:** erst in `core/theme/color_config.dart` bzw. `core/theme/text_styles.dart`, dann benutzen.
- **Neues Feature:** Ordner unter `features/`, Repository (+ Mock + Supabase) und Cubit in `configureDependencies()` registrieren, Page in die Shell.
- **Hauptaktion unten:** Die eine Aktion, für die man auf einen Screen kommt (Wert eintragen, Speichern, Kategorie anlegen), steht als gefüllter Button in `AppActionBar` fest unten. Die Liste darüber trägt Daten und Einstellungen, zweite Aktionen sind `tinted`.
- **Wiederverwenden vor neu bauen:** erst `core/widgets/` durchsehen, dann vorhandene Widgets um Parameter ergänzen, erst dann ein neues Widget.
- Beträge, Mengen und Daten nur über `core/extensions/format_x.dart` formatieren (`context.euros`, `context.amount`, `context.change`, …).
- Rechenlogik (Verbrauch, Kosten, Prognose) gehört in `core/utils/cost_engine.dart` bzw. `features/*/data/`, nicht in Widgets – und bekommt Unit-Tests.

## Entwicklung

```sh
flutter pub get
flutter run                                         # Mock-Daten, kein Backend nötig
flutter run --dart-define-from-file=.env.local      # gegen Supabase (Werte siehe .env.local.example)
flutter analyze && flutter test                     # nach jeder Änderung
flutter gen-l10n                                    # nach ARB-Änderungen (läuft sonst beim Build)
supabase/scripts/test_local.sh                      # Migrationen + Seed + Tests in Wegwerf-Postgres
```

Tests: Cubit-Tests je Feature (`test/features/`), Theme-Extensions und Kosten-Engine (`test/core/`), Smoke-Test aller Seiten mit Mock-Daten in Hell und Dunkel (`test/pages_smoke_test.dart`).

Commit-Betreffs: Nutzer-Sichtbares auf Deutsch ohne Präfix (landet im TestFlight-Testhinweis), Internes mit `chore:` / `ci:` / `test:` / `docs:`. Branches `feature/…`, `fix/…`, `chore/…`; Ablauf bis `main` steht in [CLAUDE.md](CLAUDE.md).

## Store

- **Texte und Screenshots:** `ios/fastlane/metadata/` (DE/EN, Hinweise in `metadata/README.md`), Screenshots `ios/fastlane/screenshots/` (6,9″, je 5). Hochladen: `cd ios && fastlane metadata` (ohne Binary, reicht nichts zur Prüfung ein; bricht ab, solange `example.com`-Platzhalter drin sind).
- **Neu erzeugen:** Icons, Startanimation (`assets/branding/launch_animation.json`, aus `tool/branding/launch_animation.dart`), Animation des Pflicht-Updates (`assets/branding/update_animation.json`, aus `tool/branding/update_animation.dart`) und Splash-Bild `flutter test tool/branding/render_icon_test.dart --update-goldens && dart run flutter_launcher_icons` (danach das `sed` aus `flutter_launcher_icons.yaml`), Splash `dart run flutter_native_splash:create`, Screenshots `flutter test tool/screenshots/store_screenshots_test.dart --update-goldens`.
- **Prüf-Screenshot des Abos:** `flutter test tool/screenshots/paywall_review_test.dart --update-goldens` (Paywall, 1290 × 2796, DE/EN nach `build/asc/`).
- **Rechtstexte:** `assets/legal/*.md` – Platzhalter in eckigen Klammern (Name, Anschrift, E-Mail) vor dem Start ersetzen; dieselben Texte öffentlich hosten (Datenschutz-URL für App Store Connect).

## Android-Release

`android/key.properties` (nicht im Git) mit `storeFile`, `storePassword`, `keyAlias`, `keyPassword`; ohne die Datei signiert Release mit dem Debug-Schlüssel. Schlüssel anlegen:

```sh
keytool -genkey -v -keystore ~/keys/kostenkurve-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
flutter build appbundle --release --dart-define-from-file=.env.local
```

Plus lässt sich auf Android noch nicht kaufen; ein im App Store gekauftes Abo gilt dort trotzdem.

## TestFlight

**Öffentlicher Testlink:** https://testflight.apple.com/join/92YxVdPT (externe Gruppe „Tester“, ohne Teilnehmergrenze). Er nimmt Tester auf, sobald ein Build die Beta-Prüfung von Apple bestanden hat.

```sh
cd ios && fastlane beta                              # testen, bauen, hochladen, an „Tester“ verteilen
cd ios && fastlane beta changelog:"Neu: …"           # eigener Testhinweis
cd ios && fastlane beta dry_run:true                 # nur bauen und signieren
cd ios && fastlane beta skip_tests:true build_number:7
cd ios && fastlane distribute build_number:6         # vorhandenen Build an „Tester“ geben
cd ios && fastlane force_update build_number:12      # Pflicht-Update von Hand nachholen
cd ios && fastlane check                             # API-Key prüfen, letzte/nächste Build-Nummer
```

- **Version** = `version:` in `pubspec.yaml` (Teil vor dem `+`); die **Build-Nummer** vergibt die Lane: höchste in App Store Connect + 1.
- **Testhinweis** = Commit-Betreffs seit dem höchsten Tag `testflight/<nr>` im gebauten Stand, ohne Merges und ohne `chore`/`ci`/`test`/`docs` (vor dem ersten Tag die letzten 15 Commits). Nach dem Upload setzt und pusht die Lane den Tag `testflight/<nr>`.
- **Pflicht-Update:** Ist der Build für „Tester“ freigegeben (die Lane wartet bis zu `FORCE_UPDATE_WAIT` Minuten), trägt sie ihn per `supabase db query --linked` in `app_releases` ein – ältere Builds zeigen dann „Neue Version verfügbar“. Ohne: `fastlane beta force_update:false` (GitHub: Haken `force_update` aus). Lokal braucht das den Login der Supabase-CLI, auf GitHub das Secret `SUPABASE_ACCESS_TOKEN`; scheitert es, warnt die Lane nur.
- **Signieren:** Cloud-Signing – lokal über die in Xcode angemeldete Apple-ID, auf CI (oder mit `ASC_SIGN_WITH_KEY=1`) über den API-Key (Rolle Admin).
- **Lokal nötig:** `ios/fastlane/.env` mit `ASC_KEY_ID`, `ASC_ISSUER_ID` (nicht im Git), Schlüssel unter `~/.appstoreconnect/private_keys/AuthKey_<ID>.p8`, `.env.local` mit den Supabase-Werten. Fastlane braucht eine UTF-8-Locale (`.env.default` setzt sie).
- **Ohne Mac:** GitHub → Actions → TestFlight → Run workflow (`.github/workflows/testflight.yml`, macOS-Runner, dieselbe Lane, nur manueller Start). Secrets: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`.
- **Migrationen:** `.github/workflows/supabase.yml` testet erst mit `test_local.sh` und spielt nur mit `apply=true` ein (Secrets zusätzlich `SUPABASE_ACCESS_TOKEN`, optional `SUPABASE_DB_PASSWORD`). Neue Migrationen immer vor dem Build einspielen.
