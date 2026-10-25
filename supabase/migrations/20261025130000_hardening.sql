-- Härtung nach dem Review:
--
-- - category_members: Angemeldete ändern per update nur die Rolle. Bisher konnte der owner eine
--   Mitglieds-Zeile auf einen beliebigen Nutzer umhängen (ungefragt teilen) oder die Reihenfolge
--   anderer ändern. Die eigene Reihenfolge setzt reorder_categories (security definer).
-- - entries.created_by: kommt beim Anlegen immer vom Server (auth.uid()) und bleibt danach – sonst
--   ließe sich „von Anna“ fälschen. Nur das Löschen eines Kontos leert es (on delete set null).
--
-- Belege eines gelöschten Eintrags: Die Zeilen in attachments verschwinden per Cascade, die
-- Dateien entfernt die App beim Löschen über die Storage-API. In SQL geht das nicht: Supabase
-- lässt storage.objects nicht direkt löschen, und die Datei bliebe im Speicher liegen.

revoke update on public.category_members from authenticated;
grant update (role) on public.category_members to authenticated;

create function public.stamp_entry_creator() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  -- Server-Code ohne Anmeldung (Seed, Service-Role) setzt created_by selbst.
  if auth.uid() is not null then
    new.created_by := auth.uid();
  end if;
  return new;
end $$;

create trigger entries_stamp before insert on public.entries
  for each row execute function public.stamp_entry_creator();

create or replace function public.guard_entry_update() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.tracker_id is distinct from old.tracker_id then
    raise exception 'Einträge lassen sich nicht in einen anderen Tracker verschieben' using errcode = 'check_violation';
  end if;
  -- Leer werden darf created_by nur, wenn das Profil gelöscht ist (on delete set null).
  if new.created_by is distinct from old.created_by
     and not (new.created_by is null and not exists (select 1 from public.profiles p where p.id = old.created_by)) then
    raise exception 'Wer einen Eintrag erfasst hat, lässt sich nicht ändern' using errcode = 'insufficient_privilege';
  end if;
  return new;
end $$;

revoke execute on function public.stamp_entry_creator() from public, anon, authenticated;
