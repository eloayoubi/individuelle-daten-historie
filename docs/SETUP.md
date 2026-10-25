# Kostenkurve – letzte Schritte: Supabase verbinden und TestFlight

Der Code ist fertig (M0–M6). Ohne Backend läuft die App mit Beispieldaten. Hier steht, was einmalig
außerhalb des Repos eingerichtet wird. Geheimnisse gehören nie ins Repo und nie in einen Chat:
Supabase-Werte nur in `.env.local`, App-Store-Schlüssel nur in `ios/fastlane/.env` und unter
`~/.appstoreconnect/private_keys/`.

## A. Supabase (ca. 30 Minuten)

1. **Projekt anlegen** auf supabase.com → *New project*
   - Region **Frankfurt (eu-central-1)**: Die Datenschutzerklärung sagt „Rechenzentrum in der EU (Frankfurt)“.
   - Datenbank-Passwort im Passwort-Manager speichern.
2. **Verknüpfen** (Repo-Wurzel):
   ```sh
   supabase login
   supabase link --project-ref <project-ref>
   ```
3. **Auth-Einstellungen hochladen.** `supabase/config.toml` enthält bereits:
   - anonyme Anmeldung **aus** (lokal braucht kein Konto, die Cloud ein registriertes)
   - manuelles Verknüpfen: nötig, damit anonyme Konten aus der Testphase beim Registrieren ihre Daten behalten
   - Apple als Anbieter mit Client-ID `de.eloayoubi.kostenkurve`
   - E-Mail-Code mit 8 Ziffern (die App nimmt 6 bis 10 an), 10 Minuten gültig, neuer Code frühestens nach 60 s; alle drei Vorlagen aus `supabase/templates/` mit `{{ .Token }}`
   - Redirect `de.eloayoubi.kostenkurve://login-callback`
   ```sh
   supabase config push
   ```
   Danach im Dashboard unter *Authentication* prüfen:
   - *Sign In / Providers*: Anonymous aus, Apple an, „Allow manual linking“ an.
   - *Emails*: Die Vorlagen „Confirm signup“, „Magic Link“ und „Change Email Address“ zeigen den Code.
   - **SMTP (Pflicht für den E-Mail-Code):** Ohne eigenen Anbieter lässt Supabase die Vorlagen nicht ändern – `config push` scheitert dann komplett (siehe `supabase/README.md`, „Auth“), und die Mails enthalten nur einen Link statt des Codes. Der eingebaute Mailversand ist außerdem auf wenige Mails pro Stunde begrenzt. Für echte Nutzer unter *Authentication → Emails → SMTP Settings* einen eigenen Anbieter eintragen, z. B. Resend, Postmark oder Brevo, Absender `no-reply@<deine-domain>`.
4. **Datenbank einspielen.** Erst lokal testen, dann pushen:
   ```sh
   supabase/scripts/test_local.sh
   supabase db push
   ```
5. **Edge Functions deployen**:
   ```sh
   supabase functions deploy verify-purchase app-store-notifications delete-account apple-token health
   supabase secrets set APPLE_BUNDLE_ID=de.eloayoubi.kostenkurve APPLE_ALLOW_SANDBOX=true
   ```
   `APPLE_ALLOW_SANDBOX=true` lässt Käufe aus TestFlight und Sandbox zu. Das kann so bleiben: Apple prüft die App vor der Freigabe mit Sandbox-Käufen.
6. **App verbinden.** `cp .env.local.example .env.local` und zwei Werte eintragen, beide aus *Project Settings → API*:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY` (Publishable Key)
7. **Ausprobieren**:
   ```sh
   flutter run --dart-define-from-file=.env.local
   ```
   Erwartet:
   - Onboarding erscheint, die Vorlagen werden angelegt.
   - Ein Eintrag landet in der Tabelle `entries`.
   - Einstellungen → Konto → „Mit E-Mail sichern“ schickt einen Code.
8. **GitHub-Secrets** (*Settings → Secrets and variables → Actions*) für die Workflows:
   - `SUPABASE_URL`, `SUPABASE_ANON_KEY`
   - `SUPABASE_ACCESS_TOKEN` (*Account → Access Tokens*)
   - `SUPABASE_DB_PASSWORD`

## B. Apple und TestFlight (ca. 1 Stunde, plus Wartezeit bei Apple)

1. **Apple Developer → Identifiers:** App-ID `de.eloayoubi.kostenkurve` mit *Sign in with Apple* (In-App Purchase ist Standard). Xcode legt sie beim ersten Signieren an; dann nur *Sign in with Apple* nachtragen.
2. **App Store Connect → Apps → +:**
   - Name „Kostenkurve – Zählerstände“
   - Primärsprache Deutsch
   - Bundle-ID wie oben
   - SKU z. B. `kostenkurve`
3. **Verträge:** Unter *Business* den Vertrag „Paid Apps“ abschließen und Steuer- und Bankdaten eintragen. Ohne ihn lassen sich keine Abos laden, auch nicht in TestFlight.
4. **Abo „Kostenkurve Cloud“** (*Monetization → Subscriptions*; Produkt-Ids aus der Zeit als „Plus“):
   - Gruppe „Kostenkurve Cloud“ mit dem auto-renewable Produkt `de.eloayoubi.kostenkurve.plus.monthly`, Preis **2 € im Monat** (lokal bleibt die App kostenlos).
   - Ein schon angelegtes `de.eloayoubi.kostenkurve.plus.yearly` nicht mehr anbieten: in keinem Land verfügbar, nicht zur Prüfung einreichen (nicht löschen – die Produkt-Id wäre sonst für immer verbraucht). Laufende Jahresabos erkennt der Server weiter. Liegt es in der Gruppe, **auf derselben Stufe** wie das Monatsabo lassen.
   - Stand 25.10.2026 so eingerichtet: Gruppe und Abo heißen „Kostenkurve Cloud“, Monatsabo 2,00 € (Deutschland, 174 Länder angeglichen), Jahresabo „Plus jährlich (nicht anbieten)“ ohne Länder.
   - Name und Beschreibung (DE und EN), z. B. „Kostenkurve Cloud – Auf allen Geräten, gesichert, mit Teilen und Belegen“, und ein Screenshot der Abo-Seite für die Prüfung (`flutter test tool/screenshots/paywall_review_test.dart --update-goldens` → `build/asc/`).
   - **Familienfreigabe aus** und **Kulanzzeitraum (Billing Grace Period) aus**: Der Server wertet nur `expiresDate` aus.
5. **Server-Benachrichtigungen:**
   - Unter *App Information → App Store Server Notifications* **Version 2** wählen.
   - Für Production und Sandbox dieselbe URL eintragen: `https://<project-ref>.supabase.co/functions/v1/app-store-notifications`
6. **Schlüssel für „Mit Apple anmelden“** (für den Token-Widerruf beim Konto löschen, Regel 5.1.1(v)):
   - In *Developer → Keys → +* *Sign in with Apple* wählen, die App-ID als primäre App setzen und die `.p8`-Datei laden.
   - Dann:
     ```sh
     supabase secrets set APPLE_TEAM_ID=<Team-ID> APPLE_SIGNIN_KEY_ID=<Key-ID> APPLE_SIGNIN_KEY="$(cat ~/Downloads/AuthKey_<Key-ID>.p8)"
     ```
   - Ohne diesen Schritt funktioniert alles, nur der Widerruf entfällt.
7. **API-Schlüssel für Fastlane:**
   - *Users and Access → Integrations → App Store Connect API → +*, Rolle **Admin**.
   - Die `.p8`-Datei nach `~/.appstoreconnect/private_keys/AuthKey_<ID>.p8` legen.
   - `ios/fastlane/.env` mit `ASC_KEY_ID` und `ASC_ISSUER_ID` anlegen.
   - Prüfen mit `cd ios && fastlane check`.
   - Für den Workflow ohne Mac: GitHub-Secrets `ASC_KEY_ID`, `ASC_ISSUER_ID` und `ASC_KEY_P8` (Inhalt der `.p8`).
8. **Erster Build:** `cd ios && fastlane beta`. Die Lane:
   - testet
   - baut mit `.env.local`
   - lädt hoch
   - verteilt an die Gruppe „Tester“ (die Gruppe in TestFlight einmal anlegen)
   - setzt den Tag `testflight/<nr>`

**Stand:** App, Abo-Gruppe, Server-Benachrichtigungen und die externe Gruppe „Tester“ sind angelegt. Öffentlicher Testlink: https://testflight.apple.com/join/92YxVdPT

## C. Vor der Einreichung im App Store

- **Platzhalter ersetzen:** In `assets/legal/*.md` stehen Name, Anschrift und E-Mail in eckigen Klammern. Gesetzlich nötig sind Impressum und Verantwortlicher.
- **Datenschutz öffentlich hosten:** Denselben Text aus `assets/legal/privacy_de.md` online stellen, z. B. GitHub Pages oder eine eigene Domain. Diese URL kommt in:
  - `ios/fastlane/metadata/*/privacy_url.txt`
  - `support_url.txt` (Kontaktseite)
  - die Links am Ende von `description.txt`

  `fastlane metadata` bricht ab, solange `example.com` drinsteht.
- **App-Datenschutz („App Privacy“) in App Store Connect:** Kein Tracking. Erfasst werden, verknüpft mit der Person und nur für App-Funktionen:
  - Kontaktdaten: E-Mail, optional
  - Nutzerinhalte: Fotos und sonstige Inhalte
  - Kennungen: Nutzer-ID
  - Käufe: Kaufverlauf
- **Texte und Screenshots hochladen:** `cd ios && fastlane metadata`. Das lädt kein Binary hoch und reicht nichts zur Prüfung ein. Die Kontaktdaten für das Review-Team trägst du in App Store Connect ein.
- **Kategorie** Finanzen (zweite: Dienstprogramme), Altersfreigabe 4+.

## D. Später: Android

- Upload-Schlüssel und `android/key.properties` anlegen (siehe README › Android-Release).
- App in der Play Console anlegen.
- Cloud-Kauf über Google Play Billing ist noch nicht gebaut. Ein im App Store gekauftes Cloud-Abo gilt aber auch auf Android; lokal ist die App dort voll nutzbar.
