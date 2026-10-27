-- Teilbeträge: fields.part_of, create_category mit part_of, Schutz-Trigger.
-- Eigene Transaktion, rollt am Ende zurück. Nutzer: Demo (…001, owner).

begin;

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000001';

do $$
declare
  v_category uuid;
  v_tracker uuid;
  v_other uuid;
  v_warm uuid;
  v_kalt uuid;
begin
  v_category := public.create_category(
    'Miete', 'house', 'brown', 'miete',
    '[{"name": "Wohnung", "fields": [
        {"name": "Warmmiete", "kind": "currency", "role": "recurring_cost", "unit": "€/Monat"},
        {"name": "Kaltmiete", "kind": "currency", "role": "recurring_cost", "unit": "€/Monat", "part_of": 0},
        {"name": "Heizkosten", "kind": "currency", "role": "recurring_cost", "unit": "€/Monat", "part_of": 0},
        {"name": "Vermieter", "kind": "text"}
      ]},
      {"name": "Garage", "fields": [{"name": "Miete", "kind": "currency", "role": "recurring_cost"}]}]'::jsonb
  );
  select id into v_tracker from public.trackers where category_id = v_category and name = 'Wohnung';
  select id into v_warm from public.fields where tracker_id = v_tracker and name = 'Warmmiete';
  select id into v_kalt from public.fields where tracker_id = v_tracker and name = 'Kaltmiete';
  assert (
    select array_agg(coalesce((select p.name from public.fields p where p.id = f.part_of), '-') order by f.sort)
    from public.fields f where f.tracker_id = v_tracker
  ) = array['-', 'Warmmiete', 'Warmmiete', '-'], 'Teilbeträge per Position übernommen';

  -- Nur Beträge.
  begin
    update public.fields set part_of = v_warm where tracker_id = v_tracker and name = 'Vermieter';
    raise exception 'Text als Teilbetrag angenommen';
  exception when check_violation then null;
  end;

  -- Nur im selben Tracker.
  select f.id into v_other from public.fields f join public.trackers t on t.id = f.tracker_id where t.category_id = v_category and t.name = 'Garage';
  begin
    update public.fields set part_of = v_warm where id = v_other;
    raise exception 'Teilbetrag aus einem anderen Tracker angenommen';
  exception when check_violation then null;
  end;

  -- Nur eine Ebene: kein Teil eines Teils, ein Gesamtfeld wird nicht selbst Teil.
  begin
    update public.fields set part_of = v_kalt where tracker_id = v_tracker and name = 'Heizkosten';
    raise exception 'Teil eines Teilbetrags angenommen';
  exception when check_violation then null;
  end;
  begin
    update public.fields set part_of = v_kalt where id = v_warm;
    raise exception 'Gesamtfeld als Teilbetrag angenommen';
  exception when check_violation then null;
  end;

  -- Lösen geht; ein gelöschtes Gesamtfeld gibt seine Teile frei.
  update public.fields set part_of = null where id = v_kalt;
  assert (select part_of from public.fields where id = v_kalt) is null, 'Teilbetrag gelöst';
  delete from public.fields where id = v_warm;
  assert (select part_of from public.fields where tracker_id = v_tracker and name = 'Heizkosten') is null, 'Teile ohne Gesamtfeld frei';
end $$;

rollback;
