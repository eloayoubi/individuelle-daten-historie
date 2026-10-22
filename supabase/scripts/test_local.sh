#!/usr/bin/env bash
# Spielt supabase/migrations/*.sql, seed.sql und tests/*.sql (smoke.sql zuletzt) in eine
# Wegwerf-Postgres-Instanz ein. Ersetzt `supabase start` + `db reset` dort, wo kein Docker
# läuft (Mac, Claude-Cloud-Sitzung, GitHub-Runner). Jede Migration und der Seed laufen wie bei
# `supabase db push` in je einer Transaktion; Tests regeln ihre Transaktionen selbst (rollback).
#
# Nachgestellt wird, was Migrationen von Supabase erwarten:
#   Rollen      anon, authenticated, service_role (bypassrls), authenticator,
#               supabase_auth_admin, supabase_storage_admin
#   auth        auth.users, auth.uid(), auth.role(), auth.email(), auth.jwt() – gelesen aus
#               request.jwt.claims (JSON) oder request.jwt.claim.sub/role/email
#   storage     storage.buckets, storage.objects (RLS an), storage.foldername/filename/extension()
#   extensions  Schema mit pgcrypto und uuid-ossp, im search_path wie auf Supabase
#   realtime    Publikation supabase_realtime
#   public      Standardrechte für anon/authenticated/service_role wie auf Supabase
#
# Postgres: nimmt die neueste gefundene Installation (PGBIN=/pfad/zu/bin erzwingt eine), ab 13.
# Supabase selbst läuft auf 17 – unter 15 scheitert PG-15+-Syntax in Migrationen (Views mit
# security_invoker, unique nulls not distinct, merge); dann `brew install postgresql@17`.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="${TMPDIR:-/tmp}"
DATA="${TMP%/}/kostenkurve-pg-$$"

# Hauptversion der Postgres-Installation in Ordner $1 (leer, wenn keine).
pg_major() {
  "$1/pg_ctl" --version 2>/dev/null |
    awk '{ for (i = 1; i <= NF; i++) if ($i ~ /^[0-9]+(\.[0-9]+)*$/) { split($i, v, "."); print v[1]; exit } }'
}

if [ -z "${PGBIN:-}" ]; then
  best=0
  for dir in /opt/homebrew/opt/postgresql@*/bin /usr/local/opt/postgresql@*/bin \
             /Applications/Postgres.app/Contents/Versions/*/bin /usr/lib/postgresql/*/bin \
             "$(dirname "$(command -v pg_ctl 2>/dev/null || echo /-/-)")"; do
    if [ -x "$dir/pg_ctl" ] && [ -x "$dir/initdb" ] && [ -x "$dir/psql" ]; then
      v="$(pg_major "$dir" || true)"
      if [ "${v:-0}" -gt "$best" ]; then best="$v"; PGBIN="$dir"; fi
    fi
  done
fi
if [ -z "${PGBIN:-}" ] || [ ! -x "$PGBIN/pg_ctl" ]; then
  echo "Postgres nicht gefunden (initdb, pg_ctl, psql) – z. B. brew install postgresql@17 oder PGBIN=… setzen" >&2
  exit 1
fi
MAJOR="$(pg_major "$PGBIN" || true)"
if [ "${MAJOR:-0}" -lt 13 ]; then
  echo "Postgres ${MAJOR:-?} in $PGBIN ist zu alt (mindestens 13)" >&2
  exit 1
fi
echo "Postgres $MAJOR ($PGBIN)"
if [ "$MAJOR" -lt 15 ]; then
  echo "Hinweis: Supabase läuft auf 17 – PG-15+-Syntax scheitert hier (brew install postgresql@17 wird automatisch genommen)" >&2
fi

# Postgres läuft nicht als root: dann als Nutzer postgres (Cloud-Sitzungen, Container).
run_as() { if [ "$(id -u)" = 0 ]; then su postgres -s /bin/bash -c "$*"; else bash -c "$*"; fi; }
# Stoppen wie gestartet – sonst läuft der Server nach einem Fehler weiter und blockiert den Port.
cleanup() { run_as "'$PGBIN/pg_ctl' -D '$DATA' stop -m immediate" >/dev/null 2>&1 || true; rm -rf "$DATA"; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# UTF-8 wie auf Supabase, unabhängig von der Locale der Shell.
LOCALES="$(locale -a 2>/dev/null || true)"
LOC=C
for l in C.UTF-8 C.utf8 en_US.UTF-8 en_US.utf8; do
  case $'\n'"$LOCALES"$'\n' in *$'\n'"$l"$'\n'*) LOC="$l"; break ;; esac
done

mkdir -p "$DATA"
if [ "$(id -u)" = 0 ]; then chown postgres "$DATA"; fi
run_as "'$PGBIN/initdb' -D '$DATA' -U postgres --auth=trust --encoding=UTF8 --locale='$LOC' >/dev/null"
# Nur TCP auf 127.0.0.1, kein Unix-Socket (dessen Pfad wäre unter langem $TMPDIR zu lang).
cat >> "$DATA/postgresql.conf" <<EOF

# test_local.sh: Wegwerf-Instanz
listen_addresses = '127.0.0.1'
unix_socket_directories = ''
wal_level = logical
fsync = off
synchronous_commit = off
full_page_writes = off
EOF

# Ersten freien Port ab 54339 nehmen (TEST_PGPORT=… erzwingt einen). Schnappt ein paralleler
# Lauf den Port zwischen Prüfen und Start weg, geht es beim nächsten weiter.
port_busy() { (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null; }
PORT=""
p="${TEST_PGPORT:-54339}"
while [ "$p" -le "${TEST_PGPORT:-54359}" ]; do
  if ! port_busy "$p"; then
    if run_as "'$PGBIN/pg_ctl' -D '$DATA' -l '$DATA/log.$p' -o '-p $p' -w start" >/dev/null 2>&1; then PORT="$p"; break; fi
    if ! grep -q 'could not bind' "$DATA/log.$p" 2>/dev/null; then
      echo "Postgres startet nicht:" >&2
      cat "$DATA/log.$p" >&2 || true
      exit 1
    fi
  fi
  p=$((p + 1))
done
[ -n "$PORT" ] || { echo "Kein freier Port für Postgres (${TEST_PGPORT:-54339–54359})" >&2; exit 1; }

export PGHOST=127.0.0.1 PGPORT="$PORT" PGUSER=postgres PGDATABASE=postgres PGCLIENTENCODING=UTF8
unset PGSERVICE PGOPTIONS PGPASSWORD
sql() { "$PGBIN/psql" -X -q -v ON_ERROR_STOP=1 "$@" </dev/null; }
# Vorhandene Dateien eines Glob-Musters, nach Namen sortiert (Bytefolge, wie die Versionen).
files() { local f; for f in "$@"; do if [ -e "$f" ]; then printf '%s\n' "$f"; fi; done | LC_ALL=C sort; }

# Supabase-Umgebung nachstellen.
"$PGBIN/psql" -X -q -v ON_ERROR_STOP=1 <<'SQL'
-- Rollen wie auf Supabase; service_role umgeht RLS.
create role anon nologin noinherit;
create role authenticated nologin noinherit;
create role service_role nologin noinherit bypassrls;
create role authenticator login noinherit;
create role supabase_auth_admin nologin noinherit;
create role supabase_storage_admin nologin noinherit;
grant anon, authenticated, service_role to authenticator;

-- Erweiterungen liegen auf Supabase im Schema extensions, das im search_path steht.
create schema extensions;
grant usage on schema extensions to anon, authenticated, service_role;
do $$
declare e text;
begin
  foreach e in array array['pgcrypto', 'uuid-ossp'] loop
    begin
      execute format('create extension if not exists %I with schema extensions', e);
    exception when others then
      raise warning 'Erweiterung % fehlt: %', e, sqlerrm;
    end;
  end loop;
end $$;
alter database postgres set search_path = "$user", public, extensions;

-- auth: Nutzer und JWT-Helfer wie bei Supabase. Tests setzen z. B.
--   select set_config('request.jwt.claims', '{"sub": "…", "role": "authenticated", "is_anonymous": true}', true);
-- oder nur request.jwt.claim.sub, dann `set local role authenticated`.
create schema auth;
grant usage on schema auth to anon, authenticated, service_role;
create table auth.users (
  id uuid primary key,
  aud varchar(255),
  role varchar(255),
  email text,
  phone text,
  is_anonymous boolean not null default false,
  raw_app_meta_data jsonb default '{}'::jsonb,
  raw_user_meta_data jsonb default '{}'::jsonb,
  email_confirmed_at timestamptz,
  last_sign_in_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz
);
create function auth.jwt() returns jsonb language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claim', true), ''),
                  nullif(current_setting('request.jwt.claims', true), ''))::jsonb
$$;
create function auth.uid() returns uuid language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claim.sub', true), ''),
                  nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')::uuid
$$;
create function auth.role() returns text language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claim.role', true), ''),
                  nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
$$;
create function auth.email() returns text language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claim.email', true), ''),
                  nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
$$;

-- storage: Buckets und Dateien wie im Storage-Schema von Supabase. RLS ist an, die Policies
-- legen die Migrationen an (z. B. (storage.foldername(name))[1] = auth.uid()::text).
create schema storage;
grant usage on schema storage to anon, authenticated, service_role;
create table storage.buckets (
  id text primary key,
  name text not null,
  owner uuid,
  public boolean default false,
  file_size_limit bigint,
  allowed_mime_types text[],
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
create unique index bname on storage.buckets (name);
create table storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text references storage.buckets (id),
  name text,
  owner uuid,
  owner_id text,
  metadata jsonb,
  user_metadata jsonb,
  version text,
  path_tokens text[] generated always as (string_to_array(name, '/')) stored,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  last_accessed_at timestamptz default now()
);
create unique index bucketid_objname on storage.objects (bucket_id, name);
alter table storage.buckets enable row level security;
alter table storage.objects enable row level security;
grant all on storage.buckets, storage.objects to anon, authenticated, service_role;
create function storage.foldername(name text) returns text[] language plpgsql immutable as $$
declare _parts text[];
begin
  select string_to_array(name, '/') into _parts;
  return _parts[1:array_length(_parts, 1) - 1];
end $$;
create function storage.filename(name text) returns text language plpgsql immutable as $$
declare _parts text[];
begin
  select string_to_array(name, '/') into _parts;
  return _parts[array_length(_parts, 1)];
end $$;
create function storage.extension(name text) returns text language plpgsql immutable as $$
declare _parts text[];
begin
  select string_to_array(name, '/') into _parts;
  return reverse(split_part(reverse(_parts[array_length(_parts, 1)]), '.', 1));
end $$;

-- Realtime: Migrationen hängen Tabellen per `alter publication supabase_realtime add table …` an.
create publication supabase_realtime;

-- Standardrechte in public wie auf Supabase (RLS entscheidet, wer was sieht).
grant usage on schema public to anon, authenticated, service_role;
alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to anon, authenticated, service_role;
alter default privileges in schema public grant execute on functions to anon, authenticated, service_role;
SQL

n=0
while IFS= read -r f; do
  echo "→ migrations/$(basename "$f")"
  sql -1 -f "$f"
  n=$((n + 1))
done < <(files "$ROOT"/migrations/*.sql)
seed="ohne seed.sql"
if [ -f "$ROOT/seed.sql" ]; then
  echo "→ seed.sql"
  sql -1 -f "$ROOT/seed.sql"
  seed="Seed"
fi
# Feature-Tests laufen in eigenen Transaktionen (rollback), smoke.sql zuletzt.
t=0
while IFS= read -r f; do
  if [ "$(basename "$f")" = smoke.sql ]; then continue; fi
  echo "→ tests/$(basename "$f")"
  sql -f "$f"
  t=$((t + 1))
done < <(files "$ROOT"/tests/*.sql)
if [ -f "$ROOT/tests/smoke.sql" ]; then
  echo "→ tests/smoke.sql"
  sql -f "$ROOT/tests/smoke.sql"
  t=$((t + 1))
fi
echo "✓ $n Migrationen, $seed und $t Tests ohne Fehler (Postgres $MAJOR)"
