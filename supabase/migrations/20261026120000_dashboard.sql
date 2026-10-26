-- Kennzahlen je Kategorie (eigenes Dashboard):
--
-- - fields.summary: wie die Werte eines Felds über einen Zeitraum zusammengefasst werden – addiert
--   (sum), neuer minus alter Wert (difference, z. B. Verbrauch aus Zählerständen), Durchschnitt,
--   letzter, kleinster oder größter Wert. `null` = passend zum Zeitverhalten (die App entscheidet).
-- - categories.dashboard: welche Kennzahlen die Kategorie zeigt und ob „Tracker hinzufügen“ unter
--   „Wert eintragen“ steht – `{"metrics": [{"tracker": "…", "field": "…"}], "showAddTracker": true}`.
--   Ohne "metrics" wählt die App selbst (Kosten, Verbrauch je Zähler). Gilt für alle Mitglieder;
--   ändern dürfen owner und editor (Policy categories_update).
-- - create_category übernimmt summary aus den Feldern.

alter table public.fields add column summary text
  check (summary in ('sum', 'difference', 'average', 'latest', 'min', 'max'));

alter table public.categories add column dashboard jsonb not null default '{}'::jsonb
  check (jsonb_typeof(dashboard) = 'object' and pg_column_size(dashboard) <= 16384);

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

    insert into public.fields (tracker_id, name, kind, role, unit, consumption_unit, factor, interval_months, choices, formula, summary, sort)
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
      f.ordinality - 1
    from jsonb_array_elements(coalesce(t.value -> 'fields', '[]')) with ordinality as f;
  end loop;

  return v_category;
end $$;

revoke execute on function public.create_category(text, text, text, text, jsonb) from anon;
