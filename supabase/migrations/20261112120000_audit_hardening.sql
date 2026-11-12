-- Härtung nach dem Sicherheits-Audit vom 12.11.2026:
--   1. Belege: storage_path gehört zum Eintrag und zu dessen Kategorie – in der Tabelle und beim
--      Hochladen. Bisher prüfte nur ein Muster den Pfad; delete-account löscht mit Service-Role alle
--      Pfade aus den eigenen Beleg-Zeilen und hätte so fremde Dateien treffen können.
--   2. Belege löschen nur als Mitglied (ein entferntes Mitglied kam noch an seine alten Zeilen).
--   3. „Kosten enthalten in“ nur für Kategorien, in denen man Mitglied ist (der Fremdschlüssel prüft
--      ohne RLS: jede existierende Kategorie-Id ging durch).
--   4. Funktionen in public nicht mehr für PUBLIC und anon ausführbar (bisher nur einzeln für anon
--      entzogen – das Standardrecht von PUBLIC blieb), TRUNCATE nicht für anon und authenticated.

-- ---------------------------------------------------------------------------------------------
-- 1. Belege: Pfad <category_id>/<entry_id>/<datei> passt zum Eintrag
-- ---------------------------------------------------------------------------------------------

-- Zweiter Ordner des Pfads als uuid, ungültige Pfade ergeben null statt eines Fehlers.
create function public.path_entry(p_name text) returns uuid
language plpgsql immutable set search_path = '' as $$
begin
  return split_part(p_name, '/', 2)::uuid;
exception when invalid_text_representation then
  return null;
end $$;

-- Vorhandene Zeilen müssen schon passen (die App baut den Pfad so); sonst bricht die Migration ab,
-- statt eine Regel einzuführen, die für Altbestand nicht gilt.
do $$
begin
  if exists (
    select 1 from public.attachments a
    where public.path_entry(a.storage_path) is distinct from a.entry_id
       or public.path_category(a.storage_path) is distinct from public.entry_category(a.entry_id)
  ) then
    raise exception 'attachments: storage_path passt bei vorhandenen Zeilen nicht zum Eintrag';
  end if;
end $$;

create function public.guard_attachment_path() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if public.path_entry(new.storage_path) is distinct from new.entry_id
     or public.path_category(new.storage_path) is distinct from public.entry_category(new.entry_id) then
    raise exception 'storage_path gehört nicht zu diesem Eintrag' using errcode = '23514';
  end if;
  return new;
end $$;

create trigger attachments_guard_path before insert or update of storage_path, entry_id on public.attachments
for each row execute function public.guard_attachment_path();

-- Hochladen nur unter einem Eintrag, den es in dieser Kategorie gibt – sonst ließen sich beliebig
-- viele Dateien unter <kategorie>/<irgendwas>/ ablegen, die zu keinem Beleg gehören.
drop policy attachments_files_insert on storage.objects;
create policy attachments_files_insert on storage.objects for insert to authenticated with check (
  bucket_id = 'attachments'
  and public.has_plus()
  and public.can_edit_category(public.path_category(name))
  and public.entry_category(public.path_entry(name)) = public.path_category(name)
);

-- ---------------------------------------------------------------------------------------------
-- 2. Beleg-Zeilen löschen nur als Mitglied der Kategorie
-- ---------------------------------------------------------------------------------------------

drop policy attachments_delete on public.attachments;
create policy attachments_delete on public.attachments for delete to authenticated using (
  public.is_category_member(public.entry_category(entry_id))
  and (created_by = auth.uid() or public.is_category_owner(public.entry_category(entry_id)))
);

-- ---------------------------------------------------------------------------------------------
-- 3. „Kosten enthalten in“ nur für eigene oder geteilte Kategorien
-- ---------------------------------------------------------------------------------------------

-- Ohne angemeldeten Nutzer (Service-Role, Migrationen, Seed) gilt die Regel nicht.
create function public.guard_tracker_included_in() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.included_in is not null
     and (tg_op = 'INSERT' or new.included_in is distinct from old.included_in)
     and auth.uid() is not null
     and not public.is_category_member(new.included_in) then
    raise exception 'included_in: keine Kategorie, in der du Mitglied bist' using errcode = '42501';
  end if;
  return new;
end $$;

create trigger trackers_guard_included_in before insert or update of included_in on public.trackers
for each row execute function public.guard_tracker_included_in();

-- ---------------------------------------------------------------------------------------------
-- 4. Rechte: Funktionen nicht für PUBLIC und anon, kein TRUNCATE
-- ---------------------------------------------------------------------------------------------

-- Jede Funktion in public: PUBLIC und anon raus. Wer als authenticated oder service_role bisher
-- ausführen durfte (auch nur über PUBLIC), bekommt das Recht ausdrücklich – Policies und RPCs laufen
-- weiter. Funktionen, die schon für authenticated gesperrt waren (has_cloud …), bleiben gesperrt.
-- anon braucht keine: Die einzige Tabelle für anon (app_releases) hat eine Policy ohne Funktion.
do $$
declare
  f record;
  keep_authenticated boolean;
  keep_service boolean;
begin
  for f in
    select p.oid::regprocedure as signature
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prokind in ('f', 'p')
      and not exists (select 1 from pg_catalog.pg_depend d where d.objid = p.oid and d.deptype = 'e')
  loop
    keep_authenticated := has_function_privilege('authenticated', f.signature, 'execute');
    keep_service := has_function_privilege('service_role', f.signature, 'execute');
    execute format('revoke execute on function %s from public, anon', f.signature);
    if keep_authenticated then execute format('grant execute on function %s to authenticated', f.signature); end if;
    if keep_service then execute format('grant execute on function %s to service_role', f.signature); end if;
  end loop;
end $$;

-- Künftige Funktionen: weder PUBLIC (globales Standardrecht) noch anon. authenticated und service_role
-- behalten ihr Standardrecht im Schema public.
alter default privileges for role postgres revoke execute on functions from public;
alter default privileges for role postgres in schema public revoke execute on functions from anon;

-- TRUNCATE umgeht RLS. PostgREST bietet es nicht an, das Recht braucht trotzdem niemand.
revoke truncate on all tables in schema public from anon, authenticated;
alter default privileges for role postgres in schema public revoke truncate on tables from anon, authenticated;
