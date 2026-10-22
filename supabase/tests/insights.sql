-- Meilenstein 3: Abschlag-Felder und „Kosten enthalten in“. Rollt am Ende zurück.

begin;

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000001';

do $$
declare
  v_field uuid;
begin
  -- Abschlag als Betrag geht, als Text nicht.
  insert into public.fields (tracker_id, name, kind, role, unit)
    values ('20000000-0000-4000-8000-000000000001', 'Abschlag', 'currency', 'instalment', '€/Monat')
    returning id into v_field;
  perform public.save_entry('bbbbbbbb-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', '2026-01-01', null, false,
    format('[{"field_id": "%s", "num": 85}]', v_field)::jsonb);
  assert (select num from public.entry_values where field_id = v_field) = 85, 'Abschlag gespeichert';
  begin
    insert into public.fields (tracker_id, name, kind, role) values ('20000000-0000-4000-8000-000000000001', 'Abschlag Text', 'text', 'instalment');
    raise exception 'Abschlag als Text angenommen';
  exception when check_violation then null;
  end;

  -- Formel-Feld: braucht einen Ausdruck und speichert keine Werte.
  insert into public.fields (tracker_id, name, kind, role, formula)
    values ('20000000-0000-4000-8000-000000000001', 'Kosten', 'formula', 'one_off_cost', 'verbrauch * arbeitspreis')
    returning id into v_field;
  begin
    perform public.save_entry(gen_random_uuid(), '20000000-0000-4000-8000-000000000001', '2026-01-02', null, false,
      format('[{"field_id": "%s", "num": 1}]', v_field)::jsonb);
    raise exception 'Wert für ein Formel-Feld angenommen';
  exception when check_violation then null;
  end;

  -- Wasser-Kosten stecken in der Miete; die eigene Kategorie geht nicht.
  update public.trackers set included_in = '10000000-0000-4000-8000-000000000002' where id = '20000000-0000-4000-8000-000000000001';
  assert (select included_in from public.trackers where id = '20000000-0000-4000-8000-000000000001') = '10000000-0000-4000-8000-000000000002', 'Zuordnung gespeichert';
  begin
    update public.trackers set included_in = '10000000-0000-4000-8000-000000000001' where id = '20000000-0000-4000-8000-000000000001';
    raise exception 'Kosten in der eigenen Kategorie angenommen';
  exception when check_violation then null;
  end;
end $$;

-- Fällt die Zielkategorie weg, zählen die Kosten wieder selbst.
reset role;
delete from public.categories where id = '10000000-0000-4000-8000-000000000002';
do $$
begin
  assert (select included_in from public.trackers where id = '20000000-0000-4000-8000-000000000001') is null, 'Zuordnung gelöst';
end $$;

rollback;
