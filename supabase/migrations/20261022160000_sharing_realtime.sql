-- Meilenstein 4: Änderungen live an alle Mitglieder (Realtime) und Abrechnungszeitraum in save_entry.

-- Realtime schickt Änderungen dieser Tabellen; RLS entscheidet, wer sie bekommt.
alter publication supabase_realtime add table
  public.categories, public.category_members, public.trackers, public.fields, public.entries, public.entry_values;

-- save_entry mit optionalem Abrechnungszeitraum (z. B. Nebenkostenabrechnung für 2025, gezahlt 2026).
-- Neue Parameter hinten mit Default: Aufrufe mit den bisherigen Namen laufen weiter.
drop function public.save_entry(uuid, uuid, date, text, boolean, jsonb);

create function public.save_entry(
  p_id uuid,
  p_tracker uuid,
  p_occurred_on date,
  p_note text default null,
  p_meter_change boolean default false,
  p_values jsonb default '[]',
  p_period_start date default null,
  p_period_end date default null
) returns void
language plpgsql security invoker set search_path = '' as $$
begin
  if jsonb_typeof(p_values) <> 'array' then
    raise exception 'p_values muss eine Liste sein' using errcode = 'invalid_parameter_value';
  end if;
  if jsonb_array_length(p_values) = 0 then
    raise exception 'Ein Eintrag braucht mindestens einen Wert' using errcode = 'check_violation';
  end if;

  insert into public.entries (id, tracker_id, occurred_on, note, meter_change, period_start, period_end)
    values (p_id, p_tracker, p_occurred_on, nullif(trim(p_note), ''), coalesce(p_meter_change, false), p_period_start, p_period_end)
  on conflict (id) do update
    set occurred_on = excluded.occurred_on, note = excluded.note, meter_change = excluded.meter_change,
        period_start = excluded.period_start, period_end = excluded.period_end
    where public.entries.tracker_id = excluded.tracker_id;
  if not found then
    raise exception 'Der Eintrag gehört zu einem anderen Tracker' using errcode = 'check_violation';
  end if;

  delete from public.entry_values v
  where v.entry_id = p_id
    and not exists (select 1 from jsonb_array_elements(p_values) x where (x ->> 'field_id')::uuid = v.field_id);

  insert into public.entry_values (entry_id, field_id, num, txt, dat, flag)
  select p_id, (x ->> 'field_id')::uuid, (x ->> 'num')::numeric, x ->> 'txt', (x ->> 'dat')::date, (x ->> 'flag')::boolean
  from jsonb_array_elements(p_values) x
  on conflict (entry_id, field_id) do update
    set num = excluded.num, txt = excluded.txt, dat = excluded.dat, flag = excluded.flag;
end $$;

revoke execute on function public.save_entry(uuid, uuid, date, text, boolean, jsonb, date, date) from anon;
