#!/bin/bash
# SessionStart-Hook, nur in Claude-Code-Cloud-Sitzungen: prüft, ob gh über den
# GitHub-Proxy auf das Repo zugreifen kann, und gibt der Sitzung das Ergebnis
# mit (stdout landet im Kontext). Bricht nie ab, damit die Sitzung startet.
[ "$CLAUDE_CODE_REMOTE" = "true" ] || exit 0

repo="eloayoubi/individuelle-daten-historie"
deploy="TestFlight ausliefern: gh workflow run testflight.yml --ref main -f changelog=\"…\" (Ablauf in CLAUDE.md)."

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub-CLI fehlt in dieser Sitzung. TestFlight nur über die GitHub-App starten (Actions → TestFlight → Run workflow)."
  exit 0
fi

# Kein Hängen beim Sitzungsstart: höchstens 20 s pro Abfrage (timeout gibt es unter Linux).
api() { if command -v timeout >/dev/null 2>&1; then timeout 20 gh api "$@"; else gh api "$@"; fi; }

push=$(api "repos/$repo" --jq '.permissions.push' 2>/dev/null)
workflow=$(api "repos/$repo/actions/workflows/testflight.yml" --jq '.state' 2>/dev/null)
[ "$push" = "true" ] || push="nein"
[ "$workflow" = "active" ] || workflow="nicht erreichbar"

if [ "$push" = "true" ] && [ "$workflow" = "active" ]; then
  echo "GitHub-Zugang ok: gh läuft über den Claude-GitHub-Proxy (nur REST). $deploy"
  echo "Supabase ist aus der Sitzung nicht erreichbar – Migrationen über: gh workflow run supabase.yml --ref main (-f apply=true), siehe CLAUDE.md."
  echo "gh pr / gh issue gehen hier nicht (GraphQL gesperrt) – stattdessen gh api repos/$repo/…"
else
  echo "GitHub-Zugang über gh unvollständig (Schreibrecht: $push, Workflow testflight.yml: $workflow)."
  echo "Den Nutzer auf CLAUDE.md, Abschnitt 'GitHub in Cloud-Sitzungen', hinweisen; bis dahin TestFlight über die GitHub-App starten."
fi
exit 0
