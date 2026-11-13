# Sicherheits-Audit und Fehlersuche – 12.11.2026

Fünf Durchgänge, jeder nur lesend: Datenbank (RLS, RPCs, Rechte), Edge Functions, App (Sitzung, Offline, Umzug, Links, Export), Rechenlogik (mit 3000 Zufalls-Trackern), Build und Repository. Jeder Befund wurde am Code nachgeprüft, bevor etwas geändert wurde. Kein kritischer Befund.

## Behoben

| # | Schwere | Befund | Korrektur |
|---|---|---|---|
| 1 | Hoch | Jeder Link `de.eloayoubi.kostenkurve://…#access_token=…` galt als Anmeldung: Wer ihn verschickt, meldet den Empfänger im eigenen Konto an, dessen Einträge landen dort. Nebenbei löste jeder Einladungslink einen Code-Tausch aus. | `detectSessionInUri: false` – angemeldet wird nur per E-Mail-Code oder Apple (`supabase_api.dart`) |
| 2 | Mittel | Sandbox-Käufe zählten ohne gesetztes Secret als Abo in Produktion. | Standard ist jetzt „nein“; Freigabe einzelner Konten über `APPLE_SANDBOX_USERS` (`_shared/store_env.ts`) |
| 3 | Mittel | Beleg-Zeilen nahmen jeden Pfad an, der dem Muster entsprach. Beim Löschen des Kontos entfernt `delete-account` mit Service-Role alle Pfade aus den eigenen Zeilen – auch einen fremden. | Trigger bindet `storage_path` an Eintrag und Kategorie; Hochladen nur unter einem vorhandenen Eintrag (Migration `20261112120000`) |
| 4 | Mittel | CSV-Export schrieb Namen und Notizen unverändert; `=HYPERLINK(…)` eines Mitglieds würde in Excel ausgeführt. | Textzellen, die mit `= + - @` beginnen, bekommen ein Apostroph (`data_export.dart`) |
| 5 | Mittel | Umzug aufs Gerät nahm ohne Netz den Cache und meldete Erfolg; bei einem anonymen Konto wurde danach das Konto gelöscht. | `download` bricht ab, wenn der Stand nicht vom Server kam (`storage_transfer.dart`) |
| 6 | Mittel | Ein unlesbarer Eintrag in der Offline-Warteschlange verwarf alle wartenden Einträge. | Je Eintrag gelesen, nur der kaputte fällt weg (`offline_categories_repository.dart`) |
| 7 | Mittel | `Infinity`, `NaN`, `1e999` galten als gültige Zahl und ließen sich speichern; Anzeige und Export scheitern daran. `1,234.5` wurde auf Deutsch zu 1,2345. | `parseNumber` und `parseDecimal` liefern dafür `null` (`numbers.dart`) |
| 8 | Niedrig–Mittel | „Kosten enthalten in“ nahm jede existierende Kategorie-Id an, auch fremde. | Trigger verlangt Mitgliedschaft (Migration) |
| 9 | Niedrig | Funktionen in `public` waren über das Standardrecht von PUBLIC auch für `anon` ausführbar; TRUNCATE für `authenticated`. | Entzogen, Standardrechte für künftige Funktionen angepasst (Migration) |
| 10 | Niedrig | Entferntes Mitglied konnte seine alten Beleg-Zeilen noch löschen. | Policy verlangt Mitgliedschaft (Migration) |
| 11 | Niedrig | Pflicht-Update öffnete jede Adresse aus `app_releases.url`. | Nur `https` bei `testflight.apple.com` / `apps.apple.com`, sonst der feste Link |
| 12 | Niedrig | Erinnerungen des vorigen Kontos blieben nach dem Abmelden geplant. | Plan wird bei Kontowechsel geleert (`reminder_service.dart`) |
| 13 | Niedrig | Erinnerungstext zählte über die Zeitumstellung einen Tag zu wenig. | Tage in UTC (`reminder_planner.dart`) |
| 14 | Niedrig | Release-Build ohne Supabase-Werte startete still mit den Mocks (Abo ohne Kauf). | Bricht beim Start ab (`injection.dart`) |
| 15 | Niedrig | Einladungscode aus dem Link ungeprüft ins Beitreten-Sheet. | Nur `[A-Z0-9]{4,16}` |
| 16 | Niedrig | Apple-Benachrichtigung: innere Transaktion nicht gegen App und Umgebung geprüft, keine Größengrenze, Fehlertexte im Log. | Geprüft, 64 KB, nur Fehlername im Log |
| 17 | Niedrig | Alte Exportdateien (alle Daten im Klartext) blieben im temporären Ordner. | Vor jedem Export gelöscht |
| 18 | Mittel (nur Konfiguration) | `config.toml`: Registrierung mit Passwort ohne Bestätigung der Adresse. | `enable_confirmations` und `secure_password_change` an – **wirkt erst nach `supabase config push`** |

### Zweite Runde (13.11.2026)

| # | Schwere | Befund | Korrektur |
|---|---|---|---|
| 19 | Niedrig–Mittel | Realtime meldete gelöschte Zeilen (Ids von Kategorie, Nutzer, Eintrag) an jeden angemeldeten Abonnenten – RLS filtert DELETE nicht. | DELETE wird nicht mehr veröffentlicht; Löschungen kommen über eine Marke je Mitglied an (`change_marks`, Migration `20261113120000`) |
| 20 | Mittel | Scheiterte das Entfernen einer Beleg-Datei beim Löschen, blieb sie im Bucket – ohne Kategorie für niemanden mehr löschbar. Auch bei mehr als 1000 Belegen einer Kategorie. | Jeder gelöschte Beleg landet in `storage_orphans`; die Function `purge-attachments` räumt nach, die App stößt sie nach dem Löschen an |
| 21 | Mittel | Meldete sich ein anderes Konto am Gerät an, gingen die noch nicht gesendeten Einträge des vorigen verloren – auch nach einem Neustart mit dem anderen Konto. | Sie werden je Konto beiseitegelegt und gehen raus, sobald sich das Konto wieder anmeldet (`offline_categories_repository.dart`) |
| 22 | Mittel | Bekam ein Gesamtbetrag mit Teilbeträgen ein anderes Zeitverhalten, zählten weder er noch die Teile: Kosten verschwanden still. | Ein Teilbetrag zählt nur als Teil, wenn das Gesamtfeld dasselbe Zeitverhalten hat (`Tracker.isPart`) |
| 23 | Mittel | Übersicht: Wer Kategorien wählte, verschob oder einen Fund ausblendete, während ein Abruf lief, bekam den Stand von davor zurück. | Der Abruf überschreibt Auswahl und Ausgeblendetes nicht mehr (`home_cubit.dart`) |
| 24 | Mittel | Antworten überholten sich: Kam ein älterer Abruf zuletzt an, zeigten die Ansichten kurz wieder alte Daten. | Die Offline-Schicht übernimmt nur die Antwort des zuletzt gestarteten Abrufs |
| 25 | Niedrig | GitHub Actions hingen an Tags, die sich umhängen lassen. | Auf Commit-SHAs festgelegt |
| 26 | Niedrig | Einladungscode 10 Zeichen. | 12 Zeichen (48 Bit) |
| 27 | Niedrig | PDF wurde ganz eingelesen, bevor die Größe geprüft war. | Größe zuerst |

## Dritte Runde – optionale Punkte (13.11.2026)

| # | Befund | Behebung |
|---|---|---|
| 28 | „Abo hinzufügen“ legte Tracker und Felder in mehreren Aufrufen an; brach einer ab, blieb ein halber Tracker | RPC `create_tracker` legt Tracker und Felder in einer Transaktion an (Migration `20261114120000_tracker_create.sql`); App über `createTrackerWithFields` |
| 29 | Zwei Einträge am selben Tag: Welcher als „letzter“ galt, hing von der Reihenfolge der Antwort ab (und `List.sort` ist in Dart nicht stabil) | Einträge kommen nach Tag, `created_at` und Id sortiert; `EntryOrder.byDate/newestFirst` sortiert mit Index; „letzter“ ist am selben Tag der zuletzt angelegte. Lokal und in der Warteschlange bleibt ein bearbeiteter Eintrag an seiner Stelle |
| 30 | Neue Tracker und Felder bekamen `sort` = Anzahl sichtbarer, nach dem Archivieren doppelt | Trigger `next_sort`: neue Zeilen kommen hinter alle vorhandenen, auch archivierte |
| 31 | Teilen-Seite zeigte eine inzwischen gelöschte Kategorie weiter | `SharingCubit.load` übernimmt auch `null` |
| 32 | Abgewählte Felder kamen über einen Antrieb, bei dem es sie nicht gibt, zurück | `CategorySetupCubit` merkt sich Abwahlen über alle Antriebe (Betrag über Stelle, Art, Rolle und Einheit) |
| 33 | Eintrag löschen ohne Cloud-Abo zählte als „abgelehnt“ und verschwand aus der Warteschlange | Darf die Rolle bearbeiten, fehlt nur das Abo: `WriteHeld`, der Eintrag wartet |

Tests: `supabase/tests/tracker_create.sql`, `test/features/audit_optional_test.dart`, Ergänzungen in `category_setup_cubit_test.dart` und `supabase_categories_repository_test.dart`.

## Vierte Runde – Restpunkte (13.11.2026)

| # | Befund | Behebung |
|---|---|---|
| 34 | Einladungscode ohne Zähler für Fehlversuche | Höchstens 10 Fehlversuche je Nutzer und Stunde (`invite_attempts`, Fehler P0065, in der App „Zu viele falsche Codes“). Ein ungültiger Code liefert `null` statt eines Fehlers, sonst rollte der Fehler den Zähler zurück. Ein Treffer setzt ihn zurück |
| 35 | Eigentümer löscht Konto: geteilte Kategorien verschwanden für alle | Trigger `profiles_hand_over`: Geteilte Kategorien gehen an das dienstälteste Mitglied (editor vor viewer). `delete-account` löscht deren Dateien nicht mehr, nur die eigenen Belege darin. Löschtext in der App und Datenschutzerklärung angepasst |
| 36 | Android: Release fiel ohne `key.properties` auf den Debug-Schlüssel zurück; Backup sicherte `flutter_secure_storage`, dessen Schlüssel im Keystore beim Wiederherstellen fehlen | `bundleRelease` bricht ohne `key.properties` ab (`flutter run --release` geht weiter). Backup bleibt an, schließt aber die Secure-Storage-Dateien aus (`backup_rules.xml`, `data_extraction_rules.xml`) |

Migration `20261115120000_invite_attempts_handover.sql`, Test `supabase/tests/invite_attempts_handover.sql`.

## Offen – braucht dich oder eine eigene Aufgabe

| Thema | Warum offen |
|---|---|
| **Zum Start: `APPLE_ALLOW_SANDBOX=false`** und Prüfkonto in `APPLE_SANDBOX_USERS` | Steht in der Testphase bewusst auf `true`. Siehe `docs/SETUP.md`, Schritt 5 |
| **`supabase config push`** | Bringt Punkt 18 und die Mail-Vorlagen nach Produktion; hängt am eigenen SMTP (Implementierungsplan M7) |
| Rechtstexte mit Platzhaltern (`assets/legal/*.md`), `example.com` in den Store-Texten | Braucht deine Angaben (Name, Anschrift, E-Mail, URLs) |
| Secrets der Workflows ohne geschütztes GitHub-Environment | Stellst du in GitHub ein (Settings → Environments, Freigabe erforderlich) |

## Geprüft und in Ordnung

- RLS auf jeder Tabelle, alle `WITH CHECK` vorhanden; kein Zugriff über Kategorien hinweg; `entitlements` nur durch die Service-Role schreibbar.
- Kaufprüfung: Zertifikatskette bis Apples Root, Signatur, App, Produkt, Käufer (`appAccountToken` = angemeldeter Nutzer); keine Wiederverwendung über Konten.
- `delete-account` löscht nur das eigene Konto; kein Aufruf fremder Adressen aus den Funktionen.
- Sitzung im Schlüsselbund, keine Tokens in Logs, kein `print` in `lib/`.
- Workflows: keine Eingaben in `run:`-Zeilen, Build-Nummer und TestFlight-Link vor dem SQL-Aufruf geprüft; keine Geheimnisse im Repository oder in der Historie (Mustersuche).
- Rechenlogik: 3000 Zufalls-Tracker ohne Ausnahme, ohne NaN, ohne negativen Verbrauch; Formel-Parser mit Rangfolge und Rechtsassoziativität korrekt.
