-- Restpunkte aus dem Audit vom 12.11.2026:
--   1. Einladungscodes: höchstens 10 Fehlversuche je Nutzer und Stunde. Ein ungültiger Code liefert
--      null statt eines Fehlers – ein Fehler rollte die Transaktion samt Zähler zurück.
--   2. Löscht ein Eigentümer sein Konto, gehen geteilte Kategorien an das dienstälteste Mitglied
--      (editor vor viewer) über, statt für alle zu verschwinden. Nicht geteilte werden wie bisher gelöscht.

-- ---------------------------------------------------------------------------------------------
-- 1. Fehlversuche beim Einlösen
-- ---------------------------------------------------------------------------------------------

create table public.invite_attempts (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  failures integer not null default 0,
  window_start timestamptz not null default now()
);

-- Nur accept_category_invite (security definer) liest und schreibt; Clients sehen nichts.
alter table public.invite_attempts enable row level security;
create policy invite_attempts_none on public.invite_attempts for all to authenticated using (false) with check (false);
revoke all on public.invite_attempts from anon, authenticated;

-- Gibt die Kategorie zurück oder null (Code unbekannt, abgelaufen, schon benutzt).
-- Fehler: P0064 cloud_required (Eigentümer ohne Abo, Code bleibt gültig), P0065 too_many_attempts.
create or replace function public.accept_category_invite(p_code text) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_invite public.category_invites;
  v_attempts public.invite_attempts;
begin
  if auth.uid() is null then
    raise exception 'Nicht angemeldet' using errcode = 'insufficient_privilege';
  end if;
  select * into v_attempts from public.invite_attempts a where a.user_id = auth.uid() for update;
  if found and v_attempts.failures >= 10 and v_attempts.window_start > now() - interval '1 hour' then
    raise exception 'too_many_attempts' using errcode = 'P0065';
  end if;
  select * into v_invite from public.category_invites i where i.code = upper(trim(p_code)) for update;
  if not found or v_invite.accepted_at is not null or v_invite.expires_at < now() then
    insert into public.invite_attempts as a (user_id, failures, window_start) values (auth.uid(), 1, now())
      on conflict (user_id) do update set
        failures = case when a.window_start > now() - interval '1 hour' then a.failures + 1 else 1 end,
        window_start = case when a.window_start > now() - interval '1 hour' then a.window_start else now() end;
    return null;
  end if;
  if not public.owner_has_plus(v_invite.category_id) then
    raise exception 'cloud_required' using errcode = 'P0064';
  end if;
  insert into public.category_members (category_id, user_id, role, sort)
    values (v_invite.category_id, auth.uid(), v_invite.role, public.next_category_sort(auth.uid()))
    on conflict (category_id, user_id) do nothing;
  update public.category_invites set accepted_by = auth.uid(), accepted_at = now() where code = v_invite.code;
  delete from public.invite_attempts where user_id = auth.uid();
  return v_invite.category_id;
end $$;

revoke execute on function public.accept_category_invite(text) from public, anon;
grant execute on function public.accept_category_invite(text) to authenticated;

-- ---------------------------------------------------------------------------------------------
-- 2. Übergabe beim Löschen eines Kontos
-- ---------------------------------------------------------------------------------------------

-- Läuft vor dem Löschen des Profils (Cascade aus auth.users). guard_category_update lässt den
-- Wechsel des Eigentümers zu, weil delete-account ohne Nutzer-JWT löscht (auth.uid() ist null).
create function public.hand_over_categories() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_category uuid;
  v_heir uuid;
begin
  for v_category in select c.id from public.categories c where c.owner_id = old.id loop
    v_heir := null;
    select m.user_id into v_heir
    from public.category_members m
    where m.category_id = v_category and m.user_id <> old.id
    order by (m.role = 'editor') desc, m.created_at, m.user_id
    limit 1;
    if v_heir is not null then
      update public.categories set owner_id = v_heir where id = v_category;
      update public.category_members set role = 'owner' where category_id = v_category and user_id = v_heir;
      perform public.mark_members_changed(v_category);
    end if;
  end loop;
  return old;
end $$;

revoke execute on function public.hand_over_categories() from public, anon, authenticated;

create trigger profiles_hand_over before delete on public.profiles
  for each row execute function public.hand_over_categories();
