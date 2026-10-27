-- Pflicht-Update: publish_app_build (nur Server) setzt den neuesten Build je Vertriebsweg, lesen darf
-- jeder. Eigene Transaktion, rollt am Ende zurück. Nutzer: Demo (…001).

begin;

-- ---------------------------------------------------------------------------------------------
-- Server (wie `supabase db query --linked` aus der Lane)
-- ---------------------------------------------------------------------------------------------
do $$
begin
  assert public.publish_app_build('testflight', 12, 'https://testflight.apple.com/join/test') = 12, 'erster Build';
  assert public.publish_app_build('testflight', 11) = 12, 'älterer Build senkt die Nummer nicht';
  assert (select url from public.app_releases where channel = 'testflight') = 'https://testflight.apple.com/join/test',
    'ohne neue URL bleibt die alte';
  assert public.publish_app_build('testflight', 13) = 13, 'neuerer Build gilt';
  assert (select count(*) from public.app_releases) = 1, 'eine Zeile je Vertriebsweg';

  begin
    perform public.publish_app_build('beta', 1);
    raise exception 'unbekannter Vertriebsweg angenommen';
  exception when check_violation then null;
  end;
end $$;

-- ---------------------------------------------------------------------------------------------
-- Ohne Konto (Speicherort „Lokal“): lesen ja, schreiben nein
-- ---------------------------------------------------------------------------------------------
set local role anon;

do $$
begin
  assert (select build from public.app_releases where channel = 'testflight') = 13, 'ohne Konto lesbar';

  begin
    update public.app_releases set build = 1;
    raise exception 'anon ändert den Build';
  exception when insufficient_privilege then null;
  end;

  begin
    perform public.publish_app_build('testflight', 99);
    raise exception 'anon veröffentlicht einen Build';
  exception when insufficient_privilege then null;
  end;
end $$;

-- ---------------------------------------------------------------------------------------------
-- Mit Konto: ebenso
-- ---------------------------------------------------------------------------------------------
reset role;
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000001';

do $$
begin
  assert (select build from public.app_releases where channel = 'testflight') = 13, 'mit Konto lesbar';

  begin
    insert into public.app_releases (channel, build) values ('app_store', 1);
    raise exception 'Nutzer legt einen Build an';
  exception when insufficient_privilege then null;
  end;

  begin
    delete from public.app_releases;
    raise exception 'Nutzer löscht den Build';
  exception when insufficient_privilege then null;
  end;

  begin
    perform public.publish_app_build('testflight', 99);
    raise exception 'Nutzer veröffentlicht einen Build';
  exception when insufficient_privilege then null;
  end;
end $$;

rollback;
