# Kostenkurve – Hinweise für Claude-Code-Sitzungen

Projektüberblick, Struktur, Code-Regeln und Commit-Konvention stehen in der `README.md`, Produkt und Fahrplan in `docs/IMPLEMENTIERUNGSPLAN.md`, das Backend in `supabase/README.md`. Hier nur, was jede Sitzung (lokal oder in der Cloud) zusätzlich wissen muss.

## Branches und Worktrees

Jede Sitzung arbeitet auf einem eigenen Branch in einem eigenen Worktree – so bearbeiten parallele Agenten nie dieselben Dateien. Der Hauptordner `individuelle-daten-historie` bleibt auf `main`: dort nicht arbeiten, kein `git checkout`/`git switch`.

- **Ort:** Worktrees nur unter `.claude/worktrees/<thema>` im Repo (gitignored). **Nie** einen eigenen Ordner neben dem Repo oder sonst in `IdeaProjects` anlegen (früher `../kk-…`).
- **Anlegen** – Branch-Namen `feature/…`, `fix/…`, `chore/…`, `ci/…`, `docs/…`:

  ```sh
  git fetch origin
  git worktree add -b feature/<thema> .claude/worktrees/<thema> origin/main
  cd .claude/worktrees/<thema> && flutter pub get
  ```

  Für App-Läufe zusätzlich `.env.local` aus dem Hauptordner kopieren. Hat die Claude-App die Sitzung schon in einem eigenen Worktree gestartet, diesen nehmen.

## Nach jeder Implementierung: nach `main` mergen und aufräumen

Ist eine Aufgabe fertig umgesetzt, landet sie ohne Nachfrage auf `main` – committen, mergen, pushen, aufräumen. Nicht bei reinen Fragen, Analysen oder Plänen, und nicht, wenn der Nutzer sagt, dass er selbst committet.

1. **Prüfen:** bei Dart-Änderungen `flutter analyze && flutter test`, bei neuen Migrationen `supabase/scripts/test_local.sh`. Schlägt etwas fehl und lässt sich nicht beheben: nicht committen, dem Nutzer melden.
2. **Nur eigene Dateien stagen:** `git status` ansehen, die in dieser Sitzung geänderten Dateien einzeln mit `git add <pfad>` aufnehmen (kein `git add -A`/`git add .`). Fremde, nicht committete Änderungen nicht stagen, stashen oder verwerfen.
3. **Committen** auf dem eigenen Branch. Betreff: Neues für Nutzer auf Deutsch ohne Präfix (landet im TestFlight-Testhinweis), Internes mit `chore:`/`ci:`/`test:`/`docs:`.
4. **Nach `main` mergen und pushen** – im eigenen Worktree, nicht im Hauptordner:

   ```sh
   git fetch origin
   git switch --detach origin/main
   git merge --no-ff <branch> -m "Merge <branch>"
   git push origin HEAD:main
   ```

   Merge-Konflikte, die nicht eindeutig sind: `git merge --abort && git switch <branch>`, den Nutzer fragen. Push abgelehnt, weil `main` inzwischen weiter ist: ab `git fetch` wiederholen.
5. **Aufräumen** – Pflicht, gleich nach dem Push:

   ```sh
   main_dir=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
   cd "$main_dir"
   git worktree remove .claude/worktrees/<thema>
   git pull --ff-only                  # Hauptordner auf den neuen Stand von main
   git branch -d <branch>
   git push origin --delete <branch>   # nur wenn der Branch gepusht war
   ```

   Einen Worktree, den die Claude-App angelegt hat, nicht selbst entfernen – den räumt die App beim Archivieren weg; die Branches trotzdem löschen. Danach zeigen `git worktree list` und `git branch -a` nichts mehr von dieser Sitzung.
6. **Melden:** Branch, Merge-Commit und dass aufgeräumt ist.

**Cloud-Sitzungen** starten auf einem vorgegebenen Branch und dürfen keine Branches löschen. Dort per Pull Request über die REST-API mergen – GitHub löscht den Branch danach selbst („Automatically delete head branches“ ist an):

```sh
git push origin HEAD
nr=$(gh api repos/eloayoubi/individuelle-daten-historie/pulls -f title="<Betreff>" -f head=<branch> -f base=main --jq .number)
gh api -X PUT repos/eloayoubi/individuelle-daten-historie/pulls/$nr/merge -f merge_method=merge
```

Der Push auf `main` startet nichts: TestFlight-Build und Supabase-Migrationen laufen nur auf ausdrückliche Bitte (Abschnitte unten).

## Wo TestFlight und Migrationen laufen: Mac lokal, Cloud über GitHub

- **Sitzung auf dem Mac des Nutzers** (Arbeitsverzeichnis unter `/Users/…`): alles lokal ausführen – `fastlane beta` und `npx supabase db push`. **Keine** GitHub-Workflows (`testflight.yml`, `supabase.yml`) starten; die Runner bleiben den Cloud-Sitzungen vorbehalten. Ausnahme nur, wenn der Nutzer ausdrücklich den GitHub-Lauf will.
- **Cloud-Sitzung** (kein Mac, Supabase per Proxy gesperrt): über die GitHub-Workflows.

Lokal immer von einem frischen Stand von `origin/main` aus, nicht aus dem Hauptordner (dort liegen oft nicht committete Änderungen anderer Sitzungen): Wegwerf-Worktree im Temp-Verzeichnis – nie in `IdeaProjects` – und danach wieder entfernen (`git worktree remove "$tmp"`), dazu die nicht eingecheckten Dateien aus dem Hauptordner kopieren – `supabase/.temp/` (Projekt-Link), `.env.local` (Supabase-Werte für den Build) und `ios/fastlane/.env` (ASC-Key). Inhalte dieser Dateien nicht ausgeben.

```sh
git fetch origin
tmp=$(mktemp -d)/main
git worktree add --detach "$tmp" origin/main
cp -R supabase/.temp "$tmp/supabase/" && cp .env.local "$tmp/" && cp ios/fastlane/.env "$tmp/ios/fastlane/"
```

## TestFlight-Build ausliefern

Nur wenn der Nutzer ausdrücklich danach fragt: Ein Lauf schickt den Build an die externe TestFlight-Gruppe „Tester“ und benachrichtigt sie.

**Auf dem Mac:** im Worktree von oben `cd "$tmp/ios" && LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 fastlane beta` (optional `changelog:"Neu: …"`, `dry_run:true`, `skip_tests:true`). Läuft 10–20 Minuten, also im Hintergrund starten. Die Lane testet, baut, signiert, lädt hoch, gibt für „Tester“ frei, pusht den Tag `testflight/<nummer>` und setzt das Pflicht-Update (wartet, bis Apple den Build für „Tester“ freigibt; ältere Builds sperren dann mit „Neue Version verfügbar“). Ohne Pflicht-Update: `force_update:false`. Danach den Worktree entfernen.

**In der Cloud:** Der Build läuft auf GitHub Actions (`.github/workflows/testflight.yml` ruft `fastlane beta` auf einem macOS-Runner auf) und baut immer `main` von GitHub. Also erst committen und nach `main` pushen, dann:

```sh
gh workflow run testflight.yml --ref main -f changelog="Neu: … Bitte testen: …"
gh run list --workflow testflight.yml --limit 1
gh run watch <run-id> --exit-status
gh run view <run-id> --log-failed   # bei Fehlern
```

| Eingabe | Bedeutung |
|---|---|
| `changelog` | Testhinweis auf Deutsch, aus Nutzersicht („Neu: …“, „Bitte testen: …“). Leer = Commit-Betreffs seit dem letzten Tag `testflight/<nummer>` (ohne `chore`/`ci`/`test`/`docs`). |
| `build_number` | Leer = höchste Nummer in App Store Connect + 1. |
| `group` | TestFlight-Gruppe, Standard `Tester`. |
| `dry_run` | `-f dry_run=true` baut und signiert nur, lädt nichts hoch. |

Scheitert `gh workflow run`, geht derselbe Start über die REST-API: `gh api -X POST repos/eloayoubi/individuelle-daten-historie/actions/workflows/testflight.yml/dispatches -f ref=main -f "inputs[changelog]=Neu: …"`.

Vorher prüfen:
- **Backend:** Neue Dateien in `supabase/migrations/` müssen vor der Auslieferung auf Supabase – erst Migrationen, dann Build.
- **Version:** Versionsname aus `pubspec.yaml` (Teil vor dem `+`). Die Build-Nummer dort wird ignoriert, sie vergibt die Lane. Neuen Versionsnamen nur setzen, wenn der Nutzer es will.
- **Tests:** Die Lane führt `flutter test` aus und bricht bei Fehlern ab; vorher lokal `flutter analyze && flutter test`.

## Supabase-Migrationen einspielen

Nur wenn der Nutzer es will oder ein Build neue Migrationen braucht – die Produktionsdatenbank ändert sich dabei, Migrationen lassen sich nicht automatisch zurückrollen.

**Auf dem Mac:** im Worktree von oben

```sh
cd "$tmp"
supabase/scripts/test_local.sh        # muss grün sein
npx --yes supabase db push --dry-run  # zeigt, was neu ist – ändert nichts
npx --yes supabase db push --yes      # spielt ein
npx --yes supabase migration list     # prüfen: neue Migration hat jetzt auch eine Remote-Spalte
```

Steht im Probelauf mehr als die eigene Migration (z. B. unveröffentlichte aus anderen Sitzungen), dem Nutzer die Liste zeigen und erst nach Rückmeldung einspielen.

**In der Cloud:** über `.github/workflows/supabase.yml` – erst `gh workflow run supabase.yml --ref main` (zeigt im Schritt „Neue Migrationen anzeigen“, was neu ist), dann `gh workflow run supabase.yml --ref main -f apply=true`. Edge Functions: `-f functions="health"`.

Neue Migrationen bekommen einen Zeitstempel nach der letzten in `supabase/migrations/` und müssen mit `supabase/scripts/test_local.sh` durchlaufen. Jede Migration läuft als eine Transaktion: neue Enum-Werte daher in eine eigene `*_types.sql`-Migration vor der, die sie benutzt. Jede neue Tabelle bekommt RLS und Policies sowie einen Fall in `supabase/tests/`. Lokal läuft Postgres 14 (Supabase: 17) – keine PG-15+-Syntax (`security_invoker`, `nulls not distinct`, `merge`) oder vorher `brew install postgresql@17`.

## GitHub in Cloud-Sitzungen

`gh` ist in Cloud-Sitzungen vorinstalliert und braucht kein `gh auth login`: Der GitHub-Proxy von Claude setzt die Zugangsdaten ein. Beim Start prüft `.claude/hooks/cloud-github-check.sh`, ob Lesen, Schreiben und der Workflow erreichbar sind, und meldet das Ergebnis.

- **Nur REST:** `gh workflow run` (immer mit `--ref main`), `gh run list|watch|view`, `gh api repos/eloayoubi/individuelle-daten-historie/…`. `gh pr` und `gh issue` nutzen GraphQL und werden abgelehnt – stattdessen z. B. `gh api repos/eloayoubi/individuelle-daten-historie/pulls -f title=… -f head=<branch> -f base=main`.
- **Pushen:** nur Branches, keine Tags und keine Branch-Löschungen. Den Tag `testflight/<nummer>` setzt die Lane selbst auf dem Runner.

Meldet der Start-Check „unvollständig“, muss der Nutzer den Zugang einmal einrichten: auf dem Mac `gh auth refresh -h github.com -s workflow`, dann im Terminal `claude` starten und `/web-setup` ausführen – oder über die Claude-GitHub-App Zugriff auf `eloayoubi/individuelle-daten-historie` mit „Actions: Read and write“ geben.

## Sonstiges

- Supabase-Werte stehen nur in `.env.local` (gitignored) – nie in den Chat, ins Repo oder in Logs.
- Workflow-Dateien (`.github/workflows/*`) lassen sich nur mit einem GitHub-Token mit `workflow`-Scope pushen; lokal hilft sonst der Push per SSH (`git push git@github.com:eloayoubi/individuelle-daten-historie.git …`).
- Mehrere Sitzungen arbeiten teils im selben Ordner. Vor `git checkout`/`switch` prüfen, ob fremde, nicht committete Änderungen im Arbeitsbaum liegen, und nur die eigenen Dateien committen.
