-- Härtung aus dem Audit vom 12.11.2026: Beleg-Pfade gehören zum Eintrag, „Kosten enthalten in“ nur für
-- eigene oder geteilte Kategorien, Funktionen nicht für anon, kein TRUNCATE.
-- Eigene Transaktion, rollt am Ende zurück. Nutzer: Demo (…001, owner mit Abo), Anna (…002, editor bei
-- Miete …002, viewer bei Auto …003, kein Mitglied bei Strom …001).

begin;

grant usage on schema storage to authenticated;
grant select, insert, delete on storage.objects to authenticated;

-- ---------------------------------------------------------------------------------------------
-- Rechte
-- ---------------------------------------------------------------------------------------------
do $$
declare
  v_open text;
begin
  select string_agg(p.oid::regprocedure::text, ', ') into v_open
  from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.prokind in ('f', 'p') and has_function_privilege('anon', p.oid, 'execute');
  assert v_open is null, 'anon darf ausführen: ' || v_open;

  -- Policies und RPCs laufen als authenticated weiter.
  assert has_function_privilege('authenticated', 'public.entry_category(uuid)', 'execute'), 'authenticated: entry_category';
  assert has_function_privilege('authenticated', 'public.can_edit_category(uuid)', 'execute'), 'authenticated: can_edit_category';
  assert has_function_privilege('authenticated', 'public.accept_category_invite(text)', 'execute'), 'authenticated: accept_category_invite';
  assert has_function_privilege('authenticated', 'public.path_entry(text)', 'execute'), 'authenticated: path_entry';
  -- Was schon gesperrt war, bleibt gesperrt.
  assert not has_function_privilege('authenticated', 'public.has_cloud(uuid)', 'execute'), 'has_cloud bleibt gesperrt';
  assert not has_function_privilege('authenticated', 'public.publish_app_build(text, integer, text)', 'execute'), 'publish_app_build bleibt gesperrt';

  assert not has_table_privilege('authenticated', 'public.categories', 'truncate'), 'authenticated: kein TRUNCATE';
  assert not has_table_privilege('anon', 'public.entries', 'truncate'), 'anon: kein TRUNCATE';
end $$;

-- Eine Funktion, die eine spätere Migration anlegt, ist für anon ebenfalls zu.
create function public.audit_probe() returns integer language sql as $$ select 1 $$;
do $$
begin
  assert not has_function_privilege('anon', 'public.audit_probe()', 'execute'), 'neue Funktion: anon gesperrt';
  assert has_function_privilege('authenticated', 'public.audit_probe()', 'execute'), 'neue Funktion: authenticated darf';
end $$;

set local role authenticated;

-- ---------------------------------------------------------------------------------------------
-- Demo: Beleg nur mit dem Pfad des Eintrags
-- ---------------------------------------------------------------------------------------------
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000001';

do $$
declare
  v_entry uuid := (select id from public.entries where tracker_id = '20000000-0000-4000-8000-000000000001' order by occurred_on desc limit 1);
  v_other uuid := gen_random_uuid();
begin
  assert v_entry is not null, 'Seed: Eintrag am Hauptzähler';

  begin
    insert into public.attachments (entry_id, storage_path, mime_type, size_bytes)
      values (v_entry, '10000000-0000-4000-8000-000000000002/' || v_entry || '/a.jpg', 'image/jpeg', 1200);
    raise exception 'Beleg mit dem Ordner einer anderen Kategorie angenommen';
  exception when check_violation then null;
  end;
  begin
    insert into public.attachments (entry_id, storage_path, mime_type, size_bytes)
      values (v_entry, '10000000-0000-4000-8000-000000000001/' || v_other || '/a.jpg', 'image/jpeg', 1200);
    raise exception 'Beleg mit dem Ordner eines anderen Eintrags angenommen';
  exception when check_violation then null;
  end;
  insert into public.attachments (entry_id, storage_path, mime_type, size_bytes)
    values (v_entry, '10000000-0000-4000-8000-000000000001/' || v_entry || '/a.jpg', 'image/jpeg', 1200);

  begin
    insert into storage.objects (bucket_id, name) values ('attachments', '10000000-0000-4000-8000-000000000001/' || v_other || '/a.jpg');
    raise exception 'Datei unter einem Eintrag angenommen, den es nicht gibt';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into storage.objects (bucket_id, name) values ('attachments', '10000000-0000-4000-8000-000000000002/' || v_entry || '/a.jpg');
    raise exception 'Datei unter einer Kategorie angenommen, zu der der Eintrag nicht gehört';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into storage.objects (bucket_id, name) values ('attachments', '10000000-0000-4000-8000-000000000001/kein-eintrag/a.jpg');
    raise exception 'Datei ohne Eintrags-Ordner angenommen';
  exception when insufficient_privilege then null;
  end;
  insert into storage.objects (bucket_id, name) values ('attachments', '10000000-0000-4000-8000-000000000001/' || v_entry || '/a.jpg');

  -- Eigene Kategorien: „enthalten in“ geht weiter.
  update public.trackers set included_in = '10000000-0000-4000-8000-000000000002' where id = '20000000-0000-4000-8000-000000000001';
  assert found, 'owner ordnet zwischen eigenen Kategorien zu';
  update public.trackers set included_in = null where id = '20000000-0000-4000-8000-000000000001';
end $$;

-- ---------------------------------------------------------------------------------------------
-- Anna: „enthalten in“ nicht auf eine fremde Kategorie
-- ---------------------------------------------------------------------------------------------
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000002';

do $$
begin
  begin
    update public.trackers set included_in = '10000000-0000-4000-8000-000000000001' where id = '20000000-0000-4000-8000-000000000002';
    raise exception 'Zuordnung zu einer Kategorie ohne Mitgliedschaft angenommen';
  exception when insufficient_privilege then null;
  end;
  -- Auto sieht Anna (viewer): dorthin darf sie zuordnen.
  update public.trackers set included_in = '10000000-0000-4000-8000-000000000003' where id = '20000000-0000-4000-8000-000000000002';
  assert found, 'Zuordnung zu einer geteilten Kategorie';
  -- Unverändert speichern prüft nicht erneut (Name ändern, während die Zuordnung steht).
  update public.trackers set name = 'Wohnung' where id = '20000000-0000-4000-8000-000000000002';
  assert found, 'Tracker mit bestehender Zuordnung umbenannt';
end $$;

-- ---------------------------------------------------------------------------------------------
-- Entferntes Mitglied: kein Zugriff mehr auf eigene Beleg-Zeilen
-- ---------------------------------------------------------------------------------------------
reset role;

do $$
declare
  v_entry uuid := (select id from public.entries where tracker_id = '20000000-0000-4000-8000-000000000002' order by occurred_on desc limit 1);
begin
  if v_entry is null then
    insert into public.entries (id, tracker_id, occurred_on) values ('cccccccc-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000002', date '2026-10-01');
    v_entry := 'cccccccc-0000-4000-8000-000000000001';
  end if;
  -- Als Server: Beleg von Anna in Miete, dann Anna aus der Kategorie entfernt.
  insert into public.attachments (id, entry_id, storage_path, mime_type, size_bytes, created_by)
    values ('dddddddd-0000-4000-8000-000000000001', v_entry, '10000000-0000-4000-8000-000000000002/' || v_entry || '/b.jpg', 'image/jpeg', 900, '00000000-0000-4000-8000-000000000002');
  delete from public.category_members where category_id = '10000000-0000-4000-8000-000000000002' and user_id = '00000000-0000-4000-8000-000000000002';
end $$;

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000002';

do $$
begin
  delete from public.attachments where id = 'dddddddd-0000-4000-8000-000000000001';
  assert not found, 'Entferntes Mitglied löscht seinen alten Beleg nicht mehr';
end $$;

set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000001';

do $$
begin
  delete from public.attachments where id = 'dddddddd-0000-4000-8000-000000000001';
  assert found, 'Eigentümer löscht den Beleg';
end $$;

rollback;
