-- Einträge schreiben (Meilenstein 2): save_entry speichert einen Eintrag mit allen Werten als
-- Upsert unter der Id, die das Gerät vergeben hat. So darf die Offline-Warteschlange denselben
-- Eintrag beliebig oft senden – er landet genau einmal, mit dem zuletzt gesendeten Stand.

-- Einträge bleiben in ihrem Tracker (sonst ließen sich Werte an fremde Felder hängen).
create function public.guard_entry_update() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.tracker_id is distinct from old.tracker_id then
    raise exception 'Einträge lassen sich nicht in einen anderen Tracker verschieben' using errcode = 'check_violation';
  end if;
  return new;
end $$;

create trigger entries_guard before update on public.entries
  for each row execute function public.guard_entry_update();

-- p_values: [{"field_id": "…", "num": 47100} | {"txt": "…"} | {"dat": "2027-03-31"} | {"flag": true}].
-- Felder, die im Eintrag fehlen, verlieren ihren Wert (der Eintrag zeigt genau p_values).
-- Läuft mit den Rechten des Aufrufers (RLS), die Wertprüfung übernimmt check_entry_value.
create function public.save_entry(
  p_id uuid,
  p_tracker uuid,
  p_occurred_on date,
  p_note text default null,
  p_meter_change boolean default false,
  p_values jsonb default '[]'
) returns void
language plpgsql security invoker set search_path = '' as $$
begin
  if jsonb_typeof(p_values) <> 'array' then
    raise exception 'p_values muss eine Liste sein' using errcode = 'invalid_parameter_value';
  end if;
  if jsonb_array_length(p_values) = 0 then
    raise exception 'Ein Eintrag braucht mindestens einen Wert' using errcode = 'check_violation';
  end if;

  insert into public.entries (id, tracker_id, occurred_on, note, meter_change)
    values (p_id, p_tracker, p_occurred_on, nullif(trim(p_note), ''), coalesce(p_meter_change, false))
  on conflict (id) do update
    set occurred_on = excluded.occurred_on, note = excluded.note, meter_change = excluded.meter_change
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

revoke execute on function public.save_entry(uuid, uuid, date, text, boolean, jsonb) from anon;
