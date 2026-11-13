-- create_tracker (Tracker samt Feldern in einer Transaktion) und next_sort (hinter allen, auch
-- archivierten). Eigene Transaktion, rollt am Ende zurück. Nutzer: Demo (…001, owner),
-- Anna (…002, editor bei Miete, viewer bei Auto).

begin;

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000001';

do $$
declare
  v_miete constant uuid := '10000000-0000-4000-8000-000000000002';
  v_result jsonb;
  v_tracker uuid;
  v_max integer;
  v_sort integer;
begin
  select max(sort) into v_max from public.trackers where category_id = v_miete;

  v_result := public.create_tracker(v_miete, 'Netflix',
    '[{"name": "Preis", "kind": "currency", "role": "recurring_cost", "unit": "€/Monat"},
      {"name": "Davon Steuer", "kind": "currency", "role": "recurring_cost", "part_of": 0},
      {"name": "Art", "kind": "choice", "choices": ["Streaming", "Musik"]}]'::jsonb);
  v_tracker := (v_result ->> 'tracker')::uuid;

  assert jsonb_array_length(v_result -> 'fields') = 3, 'drei Feld-Ids zurück';
  assert (select sort from public.trackers where id = v_tracker) = coalesce(v_max, -1) + 1, 'neuer Tracker hinten';
  assert (select array_agg(name order by sort) from public.fields where tracker_id = v_tracker)
    = array['Preis', 'Davon Steuer', 'Art'], 'Felder in Reihenfolge 0, 1, 2';
  assert (select array_agg(sort order by sort) from public.fields where tracker_id = v_tracker) = array[0, 1, 2], 'sort lückenlos';
  assert (select id from public.fields where tracker_id = v_tracker and sort = 0) = (v_result -> 'fields' ->> 0)::uuid, 'Ids in Reihenfolge';
  assert (select p.name from public.fields f join public.fields p on p.id = f.part_of where f.tracker_id = v_tracker and f.name = 'Davon Steuer') = 'Preis',
    'Teilbetrag per Position';

  -- Unbekannte Feldart: nichts bleibt zurück, auch kein leerer Tracker.
  begin
    perform public.create_tracker(v_miete, 'Kaputt', '[{"name": "x", "kind": "gibtsnicht"}]'::jsonb);
    raise exception 'ungültige Feldart angenommen';
  exception when invalid_text_representation then null;
  end;
  assert not exists (select 1 from public.trackers where category_id = v_miete and name = 'Kaputt'), 'kein halber Tracker';

  begin
    perform public.create_tracker(v_miete, 'Kaputt', '{"name": "x"}'::jsonb);
    raise exception 'Objekt statt Liste angenommen';
  exception when invalid_parameter_value then null;
  end;

  -- Archivierter letzter Tracker: Der nächste bekommt trotzdem eine neue Nummer.
  update public.trackers set archived_at = now() where id = v_tracker;
  insert into public.trackers (category_id, name, sort) values (v_miete, 'Nach Archiv', 0) returning sort into v_sort;
  assert v_sort = coalesce(v_max, -1) + 2, 'sort hinter dem archivierten';

  -- Felder genauso: App schickt die Anzahl sichtbarer Felder (hier 2 nach Archivieren).
  update public.fields set archived_at = now() where tracker_id = v_tracker and sort = 2;
  insert into public.fields (tracker_id, name, kind, sort) values (v_tracker, 'Neu', 'text', 2) returning sort into v_sort;
  assert v_sort = 3, 'Feld hinter dem archivierten';
end $$;

-- Anna: editor bei Miete darf, viewer bei Auto nicht.
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000002';

do $$
begin
  perform public.create_tracker('10000000-0000-4000-8000-000000000002', 'Von Anna', '[]'::jsonb);
  assert exists (select 1 from public.trackers where name = 'Von Anna'), 'editor legt an';

  begin
    perform public.create_tracker('10000000-0000-4000-8000-000000000003', 'Verboten', '[{"name": "x", "kind": "text"}]'::jsonb);
    raise exception 'viewer legte einen Tracker an';
  exception when insufficient_privilege then null;
  end;
end $$;

-- Nicht angemeldet: kein Aufruf.
set local role anon;
do $$
begin
  perform public.create_tracker('10000000-0000-4000-8000-000000000002', 'Anonym', '[]'::jsonb);
  raise exception 'anon durfte create_tracker aufrufen';
exception when insufficient_privilege then null;
end $$;

rollback;
