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

## Offen – braucht dich oder eine eigene Aufgabe

| Thema | Warum offen |
|---|---|
| **Zum Start: `APPLE_ALLOW_SANDBOX=false`** und Prüfkonto in `APPLE_SANDBOX_USERS` | Steht in der Testphase bewusst auf `true`. Siehe `docs/SETUP.md`, Schritt 5 |
| **`supabase config push`** | Bringt Punkt 18 und die Mail-Vorlagen nach Produktion; hängt am eigenen SMTP (Implementierungsplan M7) |
| Rechtstexte mit Platzhaltern (`assets/legal/*.md`), `example.com` in den Store-Texten | Braucht deine Angaben (Name, Anschrift, E-Mail, URLs) |
| Secrets der Workflows ohne geschütztes GitHub-Environment | Stellst du in GitHub ein (Settings → Environments, Freigabe erforderlich) |
| „Abo hinzufügen“ legt Tracker und Felder in mehreren Schritten an; scheitert einer, bleibt ein halber Tracker | Bräuchte einen RPC wie `create_category`, der alles in einer Transaktion anlegt |
| Zwei Einträge am selben Tag: Welcher als „letzter“ gilt, hängt von der Reihenfolge der Antwort ab | Bräuchte `created_at` in der Abfrage und eine feste Reihenfolge |
| Neue Tracker und Felder bekommen `sort` = Anzahl sichtbarer; nach dem Archivieren kann das doppelt sein | Kosmetisch; `max(sort) + 1` wäre richtig |
| Teilen-Seite zeigt eine inzwischen gelöschte Kategorie weiter; abgewählte Felder kommen beim Wechsel des Antriebs zurück; Löschen bei abgelaufenem Abo zählt als „abgelehnt“ statt „wartet“ | Niedrig, kein Datenverlust |
| Einladungscode ohne Zähler für Fehlversuche | Raten ist bei 48 Bit und 7 Tagen Gültigkeit aussichtslos; ein Zähler wäre Zugabe |
| Eigentümer löscht Konto: geteilte Kategorien verschwinden für alle | Dokumentiertes Verhalten; Übergabe der Eigentümerschaft wäre ein Feature |
| Android: `allowBackup` an, Release fällt ohne `key.properties` auf den Debug-Schlüssel zurück | Backup bewusst gelassen (lokale Daten sind sonst mit dem Handy weg); Android-Release steht noch aus |

## Geprüft und in Ordnung

- RLS auf jeder Tabelle, alle `WITH CHECK` vorhanden; kein Zugriff über Kategorien hinweg; `entitlements` nur durch die Service-Role schreibbar.
- Kaufprüfung: Zertifikatskette bis Apples Root, Signatur, App, Produkt, Käufer (`appAccountToken` = angemeldeter Nutzer); keine Wiederverwendung über Konten.
- `delete-account` löscht nur das eigene Konto; kein Aufruf fremder Adressen aus den Funktionen.
- Sitzung im Schlüsselbund, keine Tokens in Logs, kein `print` in `lib/`.
- Workflows: keine Eingaben in `run:`-Zeilen, Build-Nummer und TestFlight-Link vor dem SQL-Aufruf geprüft; keine Geheimnisse im Repository oder in der Historie (Mustersuche).
- Rechenlogik: 3000 Zufalls-Tracker ohne Ausnahme, ohne NaN, ohne negativen Verbrauch; Formel-Parser mit Rangfolge und Rechtsassoziativität korrekt.
