-- Schreibwege für Kategorien, Tracker und Felder (Meilenstein 1):
-- - Reihenfolge je Mitglied (jeder sortiert geteilte Kategorien für sich)
-- - create_category: Kategorie + Tracker + Felder in einer Transaktion (Vorlagen)
-- - reorder_categories: eigene Reihenfolge speichern
-- - Schutz-Trigger: Eigentümer und Zuordnungen bleiben fest, Archivieren nur durch den owner,
--   Feldtyp mit gespeicherten Werten nur innerhalb derselben Wertspalte ändern.

-- ---------------------------------------------------------------------------------------------
-- Reihenfolge je Mitglied
-- ---------------------------------------------------------------------------------------------

alter table public.category_members add column sort integer not null default 0;

-- Nächste freie Position in der Reihenfolge eines Nutzers.
create function public.next_category_sort(p_user uuid) returns integer
language sql stable security definer set search_path = '' as $$
  select coalesce(max(m.sort), -1) + 1 from public.category_members m where m.user_id = p_user
$$;

create or replace function public.add_category_owner() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.category_members (category_id, user_id, role, sort)
  values (new.id, new.owner_id, 'owner', public.next_category_sort(new.owner_id));
  return new;
end $$;

-- Wie bisher, neue Mitglieder kommen ans Ende ihrer eigenen Reihenfolge.
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
  insert into public.category_members (category_id, user_id, role, sort)
    values (v_invite.category_id, auth.uid(), v_invite.role, public.next_category_sort(auth.uid()))
    on conflict (category_id, user_id) do nothing;
  update public.category_invites set accepted_by = auth.uid(), accepted_at = now() where code = v_invite.code;
  return v_invite.category_id;
end $$;

-- Eigene Reihenfolge: Position = Index in p_ids. Fremde Zeilen bleiben unberührt.
create function public.reorder_categories(p_ids uuid[]) returns void
language sql security definer set search_path = '' as $$
  update public.category_members m set sort = x.pos - 1
  from unnest(p_ids) with ordinality as x (id, pos)
  where m.category_id = x.id and m.user_id = auth.uid()
$$;

-- ---------------------------------------------------------------------------------------------
-- Kategorie mit Trackern und Feldern anlegen
-- ---------------------------------------------------------------------------------------------

-- p_trackers: [{"name": "Stromzähler", "fields": [{"name", "kind", "role", "unit", "consumption_unit",
--   "factor", "interval_months", "choices", "formula"}]}]. Läuft mit den Rechten des Aufrufers (RLS);
-- scheitert ein Feld an einem Check, bleibt nichts halb angelegt.
create function public.create_category(
  p_name text,
  p_icon text,
  p_swatch text,
  p_template_key text default null,
  p_trackers jsonb default '[]'
) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare
  v_category uuid;
  v_tracker uuid;
  t record;
begin
  if jsonb_typeof(p_trackers) <> 'array' then
    raise exception 'p_trackers muss eine Liste sein' using errcode = 'invalid_parameter_value';
  end if;

  insert into public.categories (owner_id, name, icon, swatch, template_key)
    values (auth.uid(), p_name, p_icon, p_swatch, p_template_key)
    returning id into v_category;

  for t in select value, ordinality from jsonb_array_elements(p_trackers) with ordinality loop
    insert into public.trackers (category_id, name, sort)
      values (v_category, t.value ->> 'name', t.ordinality - 1)
      returning id into v_tracker;

    insert into public.fields (tracker_id, name, kind, role, unit, consumption_unit, factor, interval_months, choices, formula, sort)
    select
      v_tracker,
      f.value ->> 'name',
      (f.value ->> 'kind')::public.field_kind,
      coalesce((f.value ->> 'role')::public.field_role, 'info'),
      nullif(f.value ->> 'unit', ''),
      nullif(f.value ->> 'consumption_unit', ''),
      coalesce((f.value ->> 'factor')::numeric, 1),
      coalesce((f.value ->> 'interval_months')::smallint, 1),
      coalesce(array(select jsonb_array_elements_text(f.value -> 'choices')), '{}'),
      f.value ->> 'formula',
      f.ordinality - 1
    from jsonb_array_elements(coalesce(t.value -> 'fields', '[]')) with ordinality as f;
  end loop;

  return v_category;
end $$;

revoke execute on function public.create_category(text, text, text, text, jsonb) from anon;
revoke execute on function public.reorder_categories(uuid[]) from anon;

-- ---------------------------------------------------------------------------------------------
-- Schutz-Trigger (gelten für angemeldete Nutzer; Server-Code ohne auth.uid() darf alles)
-- ---------------------------------------------------------------------------------------------

create function public.guard_category_update() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then
    return new;
  end if;
  if new.owner_id is distinct from old.owner_id then
    raise exception 'Der Eigentümer einer Kategorie lässt sich nicht ändern' using errcode = 'insufficient_privilege';
  end if;
  if new.archived_at is distinct from old.archived_at and not public.is_category_owner(old.id) then
    raise exception 'Nur der Eigentümer kann archivieren oder wiederherstellen' using errcode = 'insufficient_privilege';
  end if;
  return new;
end $$;

create trigger categories_guard before update on public.categories
  for each row execute function public.guard_category_update();

create function public.guard_tracker_update() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.category_id is distinct from old.category_id then
    raise exception 'Tracker lassen sich nicht in eine andere Kategorie verschieben' using errcode = 'check_violation';
  end if;
  return new;
end $$;

create trigger trackers_guard before update on public.trackers
  for each row execute function public.guard_tracker_update();

-- In welcher Wertspalte ein Feldtyp speichert (wie FieldKindRules.storage in der App).
create function public.field_storage(p_kind public.field_kind) returns text
language sql immutable set search_path = '' as $$
  select case p_kind
    when 'number' then 'num'
    when 'currency' then 'num'
    when 'percent' then 'num'
    when 'text' then 'txt'
    when 'choice' then 'txt'
    when 'date' then 'dat'
    when 'toggle' then 'flag'
    else 'none'
  end
$$;

create function public.guard_field_update() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.tracker_id is distinct from old.tracker_id then
    raise exception 'Felder lassen sich nicht in einen anderen Tracker verschieben' using errcode = 'check_violation';
  end if;
  if public.field_storage(new.kind) <> public.field_storage(old.kind)
     and exists (select 1 from public.entry_values v where v.field_id = old.id) then
    raise exception 'Der Feldtyp passt nicht zu den gespeicherten Werten' using errcode = 'check_violation';
  end if;
  return new;
end $$;

create trigger fields_guard before update on public.fields
  for each row execute function public.guard_field_update();
