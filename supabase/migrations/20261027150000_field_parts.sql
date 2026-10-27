-- Teilbeträge (Warmmiete = Kaltmiete + Betriebskosten + Heizkosten):
--
-- - fields.part_of: Gesamtfeld, in dem dieser Betrag steckt. Ein Teilbetrag zählt nicht extra, er
--   zeigt nur, woraus sich der Gesamtbetrag zusammensetzt. Nur Beträge, nur eine Ebene, beide im
--   selben Tracker. Fehlt das Gesamtfeld (gelöscht oder archiviert), zählt der Teilbetrag selbst.
-- - create_category übernimmt part_of als Position des Gesamtfelds in der Feldliste (ab 0).

alter table public.fields add column part_of uuid references public.fields (id) on delete set null,
  add constraint fields_part_is_amount check (part_of is null or (kind = 'currency' and part_of <> id));

create function public.guard_field_part() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_tracker uuid;
  v_total_part uuid;
begin
  if new.part_of is null then return new; end if;
  select f.tracker_id, f.part_of into v_tracker, v_total_part from public.fields f where f.id = new.part_of;
  if v_tracker is distinct from new.tracker_id then
    raise exception 'Das Gesamtfeld gehört nicht zum Tracker des Teilbetrags' using errcode = 'check_violation';
  end if;
  if v_total_part is not null
     or exists (select 1 from public.fields f where f.part_of = new.id and f.archived_at is null) then
    raise exception 'Teilbeträge haben nur eine Ebene' using errcode = 'check_violation';
  end if;
  return new;
end $$;

create trigger fields_part_guard before insert or update of part_of on public.fields
  for each row execute function public.guard_field_part();

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

    -- Teilbeträge erst, wenn alle Felder Ids haben: Verweis per Position (sort = Position).
    update public.fields part set part_of = total.id
    from jsonb_array_elements(coalesce(t.value -> 'fields', '[]')) with ordinality as f, public.fields total
    where jsonb_typeof(f.value -> 'part_of') = 'number'
      and part.tracker_id = v_tracker and part.sort = f.ordinality - 1
      and total.tracker_id = v_tracker and total.sort = (f.value ->> 'part_of')::int;
  end loop;

  return v_category;
end $$;

revoke execute on function public.create_category(text, text, text, text, jsonb) from anon;
