-- Tracker samt Feldern in einer Transaktion („Abo hinzufügen“) und lückenlose Reihenfolge.
--
-- 1. create_tracker: legt Tracker und Felder gemeinsam an. Bisher waren es mehrere Aufrufe; brach
--    einer ab, blieb ein Tracker ohne (alle) Felder zurück.
-- 2. sort: Neue Tracker und Felder kommen immer hinter alle vorhandenen, auch archivierte. Die App
--    schickt die Anzahl der sichtbaren mit; nach dem Archivieren war die schon vergeben.

create or replace function public.next_sort()
returns trigger
language plpgsql security invoker set search_path = '' as $$
declare
  v_next integer;
begin
  if tg_table_name = 'trackers' then
    select max(sort) + 1 into v_next from public.trackers where category_id = new.category_id;
  else
    select max(sort) + 1 into v_next from public.fields where tracker_id = new.tracker_id;
  end if;
  -- Zeilen, die derselbe Befehl vorher eingefügt hat, sind hier schon sichtbar: Ein Tracker mit
  -- mehreren Feldern in einem insert … select bekommt 0, 1, 2 …
  new.sort := greatest(coalesce(new.sort, 0), coalesce(v_next, 0));
  return new;
end $$;

create trigger trackers_next_sort before insert on public.trackers
  for each row execute function public.next_sort();
create trigger fields_next_sort before insert on public.fields
  for each row execute function public.next_sort();

revoke execute on function public.next_sort() from public, anon, authenticated;

-- Tracker mit Feldern; Feld-JSON wie bei create_category, part_of verweist per Position auf das
-- Gesamtfeld. Gibt {"tracker": id, "fields": [ids in Reihenfolge von p_fields]} zurück.
create or replace function public.create_tracker(
  p_category uuid,
  p_name text,
  p_fields jsonb default '[]'
) returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare
  v_tracker uuid;
  v_ids jsonb;
begin
  if jsonb_typeof(p_fields) <> 'array' then
    raise exception 'p_fields muss eine Liste sein' using errcode = 'invalid_parameter_value';
  end if;

  -- RLS entscheidet, ob der Aufrufer in der Kategorie anlegen darf.
  insert into public.trackers (category_id, name)
    values (p_category, p_name)
    returning id into v_tracker;

  insert into public.fields (tracker_id, name, kind, role, unit, consumption_unit, factor, interval_months, choices, formula, summary, meter_group, sort)
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
    nullif(f.value ->> 'summary', ''),
    case when f.value ->> 'role' = 'meter_reading' then nullif(btrim(f.value ->> 'meter_group'), '') end,
    f.ordinality - 1
  from jsonb_array_elements(p_fields) with ordinality as f
  order by f.ordinality;

  -- Neuer Tracker: sort ist genau die Position in p_fields.
  update public.fields part set part_of = total.id
  from jsonb_array_elements(p_fields) with ordinality as f, public.fields total
  where jsonb_typeof(f.value -> 'part_of') = 'number'
    and part.tracker_id = v_tracker and part.sort = f.ordinality - 1
    and total.tracker_id = v_tracker and total.sort = (f.value ->> 'part_of')::int;

  select coalesce(jsonb_agg(id order by sort), '[]') into v_ids from public.fields where tracker_id = v_tracker;
  return jsonb_build_object('tracker', v_tracker, 'fields', v_ids);
end $$;

revoke execute on function public.create_tracker(uuid, text, jsonb) from public, anon;
grant execute on function public.create_tracker(uuid, text, jsonb) to authenticated;
