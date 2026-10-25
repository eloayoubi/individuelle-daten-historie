-- Kostenkurve Cloud: Lokal auf dem Gerät ist die App kostenlos, die Cloud kostet ein Abo (technisch
-- weiter `plus`, Produkte …plus.monthly/…plus.yearly). Durchgesetzt wird das hier, nicht in der App
-- (OWASP A01 – ein veränderter Client kommt ohne Abo nicht an Schreibrechte):
--
-- - has_cloud(category): Aufrufer oder Eigentümer der Kategorie hat ein laufendes Abo. Das Abo des
--   Eigentümers reicht für den Haushalt, Mitglieder geteilter Kategorien schreiben damit mit.
-- - can_edit_category verlangt zusätzlich has_cloud. Damit gelten alle Schreib-Policies auf Kategorien,
--   Trackern, Feldern, Einträgen, Werten und Belegen – und save_entry/create_category, die mit den
--   Rechten des Aufrufers laufen – nur mit Cloud.
-- - Neue Kategorien und Einladungen brauchen das eigene Abo, Beitreten das des Eigentümers.
-- - Lesen, Kategorien löschen, Verlassen, Reihenfolge und Name bleiben ohne Abo möglich: Export und
--   Umzug aufs Gerät gehen immer (DSGVO Art. 17 und 20).
--
-- Fehler: P0064 cloud_required.

-- Hat der Eigentümer der Kategorie gerade ein Abo?
create function public.owner_has_plus(p_category uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1
    from public.categories c
    join public.entitlements e on e.user_id = c.owner_id
    where c.id = p_category and e.tier = 'plus' and (e.valid_until is null or e.valid_until > now())
  )
$$;

create function public.has_cloud(p_category uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select public.has_plus() or public.owner_has_plus(p_category)
$$;

-- Nur für Policies und Funktionen: Wer eine Kategorie-Id kennt, soll nicht abfragen können, ob deren
-- Eigentümer zahlt.
revoke execute on function public.owner_has_plus(uuid) from public, anon, authenticated;
revoke execute on function public.has_cloud(uuid) from public, anon, authenticated;

create or replace function public.can_edit_category(p_category uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce(public.category_role(p_category) in ('owner', 'editor'), false) and public.has_cloud(p_category)
$$;

-- Neue Kategorien (auch über create_category) nur mit eigenem Abo.
drop policy categories_insert on public.categories;
create policy categories_insert on public.categories for insert to authenticated with check (owner_id = auth.uid() and public.has_plus());

-- Teilen braucht das eigene Abo.
create or replace function public.create_category_invite(p_category uuid, p_role public.member_role default 'editor') returns text
language plpgsql security definer set search_path = '' as $$
declare
  v_code text;
begin
  if not public.is_category_owner(p_category) then
    raise exception 'Nur der Eigentümer kann die Kategorie teilen' using errcode = 'insufficient_privilege';
  end if;
  if not public.has_plus() then
    raise exception 'cloud_required' using errcode = 'P0064';
  end if;
  if p_role = 'owner' then
    raise exception 'Einladungen vergeben nur editor oder viewer' using errcode = 'check_violation';
  end if;
  insert into public.category_invites (category_id, role, created_by)
    values (p_category, p_role, auth.uid())
    returning code into v_code;
  return v_code;
end $$;

-- Beitreten braucht das Abo des Eigentümers; ohne bleibt der Code gültig.
create or replace function public.accept_category_invite(p_code text) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_invite public.category_invites;
begin
  if auth.uid() is null then
    raise exception 'Nicht angemeldet' using errcode = 'insufficient_privilege';
  end if;
  select * into v_invite from public.category_invites i where i.code = upper(trim(p_code)) for update;
  if not found or v_invite.accepted_at is not null or v_invite.expires_at < now() then
    raise exception 'Einladung ungültig oder abgelaufen' using errcode = 'no_data_found';
  end if;
  if not public.owner_has_plus(v_invite.category_id) then
    raise exception 'cloud_required' using errcode = 'P0064';
  end if;
  insert into public.category_members (category_id, user_id, role, sort)
    values (v_invite.category_id, auth.uid(), v_invite.role, public.next_category_sort(auth.uid()))
    on conflict (category_id, user_id) do nothing;
  update public.category_invites set accepted_by = auth.uid(), accepted_at = now() where code = v_invite.code;
  return v_invite.category_id;
end $$;
