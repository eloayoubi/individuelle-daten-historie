-- Pflicht-Update: der neueste Build, den Nutzer laden können, je Vertriebsweg (TestFlight, später
-- App Store). Ältere Builds zeigen „Neue Version verfügbar“ und lassen sich erst nach dem Update
-- weiter benutzen (ForceUpdateGate in der App).
--
-- - Lesen darf jeder, auch ohne Konto: Der Speicherort „Lokal“ hat keins.
-- - Schreiben nur der Server: `fastlane beta` und `fastlane distribute` rufen publish_app_build über
--   die Management-API auf (`supabase db query --linked`), sobald der Build bei den Testern ist.
-- - Die Nummer steigt nur: Wird ein älterer Build noch einmal verteilt, sperrt das niemanden aus.

create table public.app_releases (
  channel text primary key check (channel in ('testflight', 'app_store')),
  build integer not null check (build > 0),
  -- Wo es den Build gibt (öffentlicher TestFlight-Link); ohne nimmt die App ihren eigenen.
  url text,
  released_at timestamptz not null default now()
);

alter table public.app_releases enable row level security;

create policy app_releases_select on public.app_releases for select to anon, authenticated using (true);

-- Ohne Schreib-Policy blockt RLS schon; truncate prüft RLS aber nicht.
revoke insert, update, delete, truncate on public.app_releases from anon, authenticated;

-- Gibt die Nummer zurück, die danach gilt.
create function public.publish_app_build(p_channel text, p_build integer, p_url text default null) returns integer
language sql set search_path = '' as $$
  insert into public.app_releases as r (channel, build, url) values (p_channel, p_build, p_url)
  on conflict (channel) do update set
    build = greatest(r.build, excluded.build),
    url = coalesce(excluded.url, r.url),
    released_at = case when excluded.build > r.build then now() else r.released_at end
  returning build
$$;

revoke execute on function public.publish_app_build(text, integer, text) from public, anon, authenticated;
