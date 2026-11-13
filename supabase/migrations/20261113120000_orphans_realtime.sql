-- Offene Punkte aus dem Audit vom 12.11.2026:
--   1. Realtime meldete gelöschte Zeilen an jeden angemeldeten Abonnenten – RLS filtert DELETE nicht,
--      die Ids (Kategorie, Nutzer, Eintrag) fremder Haushalte gingen so an alle. DELETE wird nicht mehr
--      veröffentlicht; damit Mitglieder Löschungen trotzdem sofort sehen, bekommt jedes eine eigene
--      Marke (change_marks), deren Änderung RLS-gefiltert nur an es selbst geht.
--   2. Beleg-Dateien: Die App entfernt sie beim Löschen selbst. Scheitert das (kein Netz, alter
--      Client), blieb die Datei im Bucket, die Zeile war per Cascade weg – und ohne Kategorie darf sie
--      niemand mehr löschen. Jeder gelöschte Beleg landet jetzt in einer Warteschlange, die die Edge
--      Function purge-attachments abarbeitet.
--   3. Einladungscodes 12 statt 10 Zeichen (48 statt 40 Bit).

-- ---------------------------------------------------------------------------------------------
-- 1. Realtime ohne DELETE, Löschungen über eine Marke je Mitglied
-- ---------------------------------------------------------------------------------------------

create table public.change_marks (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  changed_at timestamptz not null default now()
);

alter table public.change_marks enable row level security;

create policy change_marks_select on public.change_marks for select to authenticated using (user_id = auth.uid());

-- Geschrieben wird nur von den Triggern unten.
revoke insert, update, delete, truncate on public.change_marks from anon, authenticated;

-- Marke aller Mitglieder von [p_category] setzen. Nur Mitglieder, deren Profil es noch gibt: Beim
-- Löschen eines Kontos laufen die Trigger für dessen Zeilen, das Profil ist dann schon weg.
create function public.mark_members_changed(p_category uuid) returns void
language sql security definer set search_path = '' as $$
  insert into public.change_marks (user_id, changed_at)
  select m.user_id, clock_timestamp()
  from public.category_members m
  join public.profiles p on p.id = m.user_id
  where m.category_id = p_category
  on conflict (user_id) do update set changed_at = excluded.changed_at
$$;

create function public.mark_deleted() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_category uuid;
begin
  case tg_table_name
    when 'categories' then v_category := old.id;
    when 'category_members' then v_category := old.category_id;
    when 'trackers' then v_category := old.category_id;
    when 'fields' then v_category := public.tracker_category(old.tracker_id);
    when 'entries' then v_category := public.tracker_category(old.tracker_id);
    when 'entry_values' then v_category := public.entry_category(old.entry_id);
  end case;
  -- Per Cascade gelöscht: Die Zeile darüber ist schon weg, deren eigener Trigger hat gemeldet.
  if v_category is not null then
    perform public.mark_members_changed(v_category);
  end if;
  return old;
end $$;

revoke execute on function public.mark_members_changed(uuid) from public, anon, authenticated;
revoke execute on function public.mark_deleted() from public, anon, authenticated;

-- Kategorie und Mitgliedschaft vor dem Löschen: Danach gäbe es die Mitglieder nicht mehr – auch das
-- entfernte Mitglied soll erfahren, dass die Kategorie für es weg ist.
create trigger categories_mark_deleted before delete on public.categories for each row execute function public.mark_deleted();
create trigger category_members_mark_deleted before delete on public.category_members for each row execute function public.mark_deleted();
create trigger trackers_mark_deleted after delete on public.trackers for each row execute function public.mark_deleted();
create trigger fields_mark_deleted after delete on public.fields for each row execute function public.mark_deleted();
create trigger entries_mark_deleted after delete on public.entries for each row execute function public.mark_deleted();
create trigger entry_values_mark_deleted after delete on public.entry_values for each row execute function public.mark_deleted();

alter publication supabase_realtime add table public.change_marks;
alter publication supabase_realtime set (publish = 'insert, update');

-- ---------------------------------------------------------------------------------------------
-- 2. Warteschlange für Dateien gelöschter Belege
-- ---------------------------------------------------------------------------------------------

-- Ohne Policy: nur die Service-Role (purge-attachments) liest und leert.
create table public.storage_orphans (
  path text primary key,
  queued_at timestamptz not null default now()
);

alter table public.storage_orphans enable row level security;

revoke all on public.storage_orphans from anon, authenticated;
grant select, insert, update, delete on public.storage_orphans to service_role;

create function public.queue_storage_orphan() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.storage_orphans (path) values (old.storage_path) on conflict (path) do nothing;
  return old;
end $$;

revoke execute on function public.queue_storage_orphan() from public, anon, authenticated;

create trigger attachments_queue_orphan after delete on public.attachments
for each row execute function public.queue_storage_orphan();

-- ---------------------------------------------------------------------------------------------
-- 3. Einladungscodes: 12 Hex-Zeichen
-- ---------------------------------------------------------------------------------------------

alter table public.category_invites
  alter column code set default upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12));
