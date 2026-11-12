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

## Offen – braucht dich oder eine eigene Aufgabe

| Thema | Warum offen |
|---|---|
| **Zum Start: `APPLE_ALLOW_SANDBOX=false`** und Prüfkonto in `APPLE_SANDBOX_USERS` | Steht in der Testphase bewusst auf `true`. Siehe `docs/SETUP.md`, Schritt 5 |
| **`supabase config push`** | Bringt Punkt 18 und die Mail-Vorlagen nach Produktion; hängt am eigenen SMTP (Implementierungsplan M7) |
| Rechtstexte mit Platzhaltern (`assets/legal/*.md`), `example.com` in den Store-Texten | Braucht deine Angaben (Name, Anschrift, E-Mail, URLs) |
| Dateien im Bucket bleiben, wenn Eintrag oder Kategorie gelöscht wird | SQL kann Storage nicht löschen; braucht eine Warteschlange und eine geplante Funktion. Betrifft DSGVO Art. 17 und Speicherkosten |
| Realtime meldet gelöschte Zeilen (nur Ids) an alle angemeldeten Abonnenten | Bekanntes Verhalten von `postgres_changes`; Abhilfe wäre der Umbau auf private Broadcast-Kanäle |
| GitHub Actions auf Tags statt Commit-SHAs, Secrets ohne geschütztes Environment | Härtung der Lieferkette; Environment-Schutz stellst du in GitHub ein |
| Einladungscode 40 Bit ohne Zähler für Fehlversuche | Raten ist bei 7 Tagen Gültigkeit praktisch aussichtslos; ein Zähler wäre Zugabe |
| Eigentümer löscht Konto: geteilte Kategorien verschwinden für alle | Dokumentiertes Verhalten; Übergabe der Eigentümerschaft wäre ein Feature |
| Wartende Einträge von Konto A gehen verloren, wenn sich B am selben Gerät anmeldet | Beim Abmelden warnt die App davor; je Konto getrennte Warteschlangen wären der saubere Weg |
| Android: `allowBackup` an, Release fällt ohne `key.properties` auf den Debug-Schlüssel zurück | Backup bewusst gelassen (lokale Daten sind sonst mit dem Handy weg); Android-Release steht noch aus |

## Geprüft und in Ordnung

- RLS auf jeder Tabelle, alle `WITH CHECK` vorhanden; kein Zugriff über Kategorien hinweg; `entitlements` nur durch die Service-Role schreibbar.
- Kaufprüfung: Zertifikatskette bis Apples Root, Signatur, App, Produkt, Käufer (`appAccountToken` = angemeldeter Nutzer); keine Wiederverwendung über Konten.
- `delete-account` löscht nur das eigene Konto; kein Aufruf fremder Adressen aus den Funktionen.
- Sitzung im Schlüsselbund, keine Tokens in Logs, kein `print` in `lib/`.
- Workflows: keine Eingaben in `run:`-Zeilen, Build-Nummer und TestFlight-Link vor dem SQL-Aufruf geprüft; keine Geheimnisse im Repository oder in der Historie (Mustersuche).
- Rechenlogik: 3000 Zufalls-Tracker ohne Ausnahme, ohne NaN, ohne negativen Verbrauch; Formel-Parser mit Rangfolge und Rechtsassoziativität korrekt.
