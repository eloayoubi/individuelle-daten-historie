-- Mehrere Zähler je Tracker (Bad kalt, Bad warm, WC kalt …):
--
-- - fields.meter_group: Gruppe eines Zählerstands (z. B. „Kaltwasser“, „Warmwasser“). Der Verbrauch
--   aller Zählerstände eines Trackers zählt zusammen und mit seinem Arbeitspreis; die Übersicht
--   zeigt ohne eigene Wahl je Gruppe eine Verbrauchskarte. Nur bei Zählerständen, sonst leer.
-- - create_category übernimmt meter_group aus den Feldern.

alter table public.fields add column meter_group text
  check (char_length(meter_group) between 1 and 40),
  add constraint fields_meter_group_on_meter check (meter_group is null or role = 'meter_reading');

create or replace function public.create_category(
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
    from jsonb_array_elements(coalesce(t.value -> 'fields', '[]')) with ordinality as f;
  end loop;

  return v_category;
end $$;

revoke execute on function public.create_category(text, text, text, text, jsonb) from anon;
