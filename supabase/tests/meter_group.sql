-- Gruppen von Zählern: fields.meter_group, create_category mit meter_group.
-- Eigene Transaktion, rollt am Ende zurück. Nutzer: Demo (…001, owner).

begin;

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000001';

do $$
declare
  v_category uuid;
  v_tracker uuid;
begin
  v_category := public.create_category(
    'Wasser', 'drop', 'blue', 'wasser',
    '[{"name": "Wasserzähler", "fields": [
        {"name": "Bad kalt", "kind": "number", "role": "meter_reading", "unit": "m³", "meter_group": "Kaltwasser"},
        {"name": "Bad warm", "kind": "number", "role": "meter_reading", "unit": "m³", "meter_group": " Warmwasser "},
        {"name": "WC", "kind": "number", "role": "meter_reading", "unit": "m³"},
        {"name": "Preis", "kind": "currency", "role": "unit_price", "unit": "€/m³", "meter_group": "Kaltwasser"}
      ]}]'::jsonb
  );
  select id into v_tracker from public.trackers where category_id = v_category;
  assert (
    select array_agg(coalesce(f.meter_group, '-') order by f.sort) from public.fields f where f.tracker_id = v_tracker
  ) = array['Kaltwasser', 'Warmwasser', '-', '-'], 'Gruppe übernommen, getrimmt, nur bei Zählerständen';

  update public.fields set meter_group = 'Garten' where tracker_id = v_tracker and name = 'WC';
  assert (select meter_group from public.fields where tracker_id = v_tracker and name = 'WC') = 'Garten', 'Gruppe änderbar';

  begin
    update public.fields set meter_group = 'Kaltwasser' where tracker_id = v_tracker and name = 'Preis';
    raise exception 'Gruppe bei einem Preis angenommen';
  exception when check_violation then null;
  end;

  begin
    update public.fields set meter_group = '' where tracker_id = v_tracker and name = 'WC';
    raise exception 'Leere Gruppe angenommen';
  exception when check_violation then null;
  end;
end $$;

rollback;
