-- Symbol je Tracker: trackers.icon. Eigene Transaktion, rollt am Ende zurück. Nutzer: Demo (…001, owner).

begin;

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000001';

do $$
declare
  v_category uuid;
  v_tracker uuid;
begin
  v_category := public.create_category('Abos', 'play', 'pink', null, '[{"name": "Stremio", "fields": []}]'::jsonb);
  select id into v_tracker from public.trackers where category_id = v_category;
  assert (select icon from public.trackers where id = v_tracker) is null, 'ohne Wahl das Symbol der Kategorie';

  update public.trackers set icon = 'film' where id = v_tracker;
  assert (select icon from public.trackers where id = v_tracker) = 'film', 'Symbol änderbar';

  update public.trackers set icon = null where id = v_tracker;
  assert (select icon from public.trackers where id = v_tracker) is null, 'zurück zum Symbol der Kategorie';

  begin
    update public.trackers set icon = 'Film!' where id = v_tracker;
    raise exception 'Ungültiges Symbol angenommen';
  exception when check_violation then null;
  end;
end $$;

rollback;
