-- Realtime ohne DELETE: Löschungen melden sich über die Marke jedes Mitglieds; gelöschte Belege
-- landen in der Warteschlange für ihre Dateien; Einladungscodes haben 12 Zeichen.
-- Eigene Transaktion, rollt am Ende zurück. Nutzer: Demo (…001, owner), Anna (…002, editor bei Miete
-- …002, viewer bei Auto …003, kein Mitglied bei Strom …001).

begin;

-- ---------------------------------------------------------------------------------------------
-- Veröffentlichung
-- ---------------------------------------------------------------------------------------------
do $$
begin
  assert (select not pubdelete and pubinsert and pubupdate from pg_catalog.pg_publication where pubname = 'supabase_realtime'), 'Realtime veröffentlicht kein DELETE';
  assert exists (select 1 from pg_catalog.pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'change_marks'), 'change_marks wird veröffentlicht';
  assert not has_table_privilege('authenticated', 'public.change_marks', 'insert'), 'Marken schreibt kein Nutzer';
  assert not has_table_privilege('authenticated', 'public.storage_orphans', 'select'), 'Warteschlange liest kein Nutzer';
  assert not has_function_privilege('authenticated', 'public.mark_members_changed(uuid)', 'execute'), 'mark_members_changed gesperrt';
end $$;

-- ---------------------------------------------------------------------------------------------
-- Eintrag in Miete gelöscht: Demo und Anna bekommen die Marke, sonst niemand
-- ---------------------------------------------------------------------------------------------
insert into auth.users (id, email) values ('00000000-0000-4000-8000-000000000007', 'fremd@kostenkurve.test');
insert into public.entries (id, tracker_id, occurred_on) values
  ('eeeeeeee-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000002', date '2026-10-01'),
  ('eeeeeeee-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000001', date '2026-10-01');

do $$
begin
  assert (select count(*) from public.change_marks) = 0, 'anfangs keine Marken';
  delete from public.entries where id = 'eeeeeeee-0000-4000-8000-000000000001';
  assert (select array_agg(user_id order by user_id) from public.change_marks)
    = array['00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000002']::uuid[], 'Marke für beide Mitglieder von Miete';

  delete from public.change_marks;
  -- Strom gehört nur Demo.
  delete from public.entries where id = 'eeeeeeee-0000-4000-8000-000000000002';
  assert (select array_agg(user_id) from public.change_marks) = array['00000000-0000-4000-8000-000000000001']::uuid[], 'Marke nur für Demo';
end $$;

-- Jede sieht nur die eigene Marke.
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000002';
do $$
begin
  assert (select count(*) from public.change_marks) = 0, 'Anna sieht Demos Marke nicht';
  begin
    insert into public.change_marks (user_id) values (auth.uid());
    raise exception 'Nutzerin konnte eine Marke schreiben';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

-- ---------------------------------------------------------------------------------------------
-- Mitglied entfernt und Kategorie gelöscht: auch wer den Zugriff verliert, erfährt es
-- ---------------------------------------------------------------------------------------------
do $$
begin
  delete from public.change_marks;
  delete from public.category_members where category_id = '10000000-0000-4000-8000-000000000003' and user_id = '00000000-0000-4000-8000-000000000002';
  assert exists (select 1 from public.change_marks where user_id = '00000000-0000-4000-8000-000000000002'), 'entferntes Mitglied bekommt die Marke';

  delete from public.change_marks;
  delete from public.categories where id = '10000000-0000-4000-8000-000000000002';
  assert (select count(*) from public.change_marks) = 2, 'Kategorie gelöscht: Marke für alle Mitglieder';
end $$;

-- ---------------------------------------------------------------------------------------------
-- Beleg gelöscht – direkt oder per Cascade: Pfad in der Warteschlange
-- ---------------------------------------------------------------------------------------------
do $$
declare
  v_entry uuid := (select id from public.entries where tracker_id = '20000000-0000-4000-8000-000000000001' order by occurred_on desc limit 1);
  v_path text;
begin
  v_path := '10000000-0000-4000-8000-000000000001/' || v_entry || '/';
  insert into public.attachments (entry_id, storage_path, mime_type, size_bytes, created_by) values
    (v_entry, v_path || 'a.jpg', 'image/jpeg', 100, '00000000-0000-4000-8000-000000000001'),
    (v_entry, v_path || 'b.jpg', 'image/jpeg', 100, '00000000-0000-4000-8000-000000000001');
  delete from public.attachments where storage_path = v_path || 'a.jpg';
  assert (select array_agg(path) from public.storage_orphans) = array[v_path || 'a.jpg'], 'gelöschter Beleg in der Warteschlange';
  delete from public.entries where id = v_entry;
  assert (select count(*) from public.storage_orphans) = 2, 'per Cascade gelöschter Beleg in der Warteschlange';
end $$;

-- ---------------------------------------------------------------------------------------------
-- Konto gelöscht: Die Trigger schreiben keine Marke für ein Profil, das es nicht mehr gibt
-- ---------------------------------------------------------------------------------------------
do $$
begin
  delete from auth.users where id = '00000000-0000-4000-8000-000000000001';
  assert not exists (select 1 from public.change_marks where user_id = '00000000-0000-4000-8000-000000000001'), 'keine Marke für das gelöschte Konto';
  assert not exists (select 1 from public.categories where owner_id = '00000000-0000-4000-8000-000000000001'), 'Kategorien des Kontos sind weg';
end $$;

-- ---------------------------------------------------------------------------------------------
-- Einladungscode: 12 Zeichen
-- ---------------------------------------------------------------------------------------------
do $$
declare
  v_code text;
begin
  insert into auth.users (id, email) values ('00000000-0000-4000-8000-000000000008', 'neu@kostenkurve.test');
  insert into public.categories (id, owner_id, name, icon, swatch) values ('10000000-0000-4000-8000-000000000008', '00000000-0000-4000-8000-000000000008', 'Neu', 'bolt', 'orange');
  insert into public.category_invites (category_id, created_by) values ('10000000-0000-4000-8000-000000000008', '00000000-0000-4000-8000-000000000008') returning code into v_code;
  assert v_code ~ '^[0-9A-F]{12}$', 'Code hat 12 Hex-Zeichen: ' || v_code;
end $$;

rollback;
