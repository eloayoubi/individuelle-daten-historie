-- Härtung: Mitglieder-Zeilen ändern nur die Rolle, created_by an Einträgen kommt vom Server.
-- Eigene Transaktion, rollt am Ende zurück. Nutzer: Demo (…001, owner), Anna (…002, editor bei
-- Miete, viewer bei Auto).

begin;

set local role authenticated;

-- ---------------------------------------------------------------------------------------------
-- Demo (owner): Rolle ändern ja, Mitglied umhängen oder fremde Reihenfolge nein
-- ---------------------------------------------------------------------------------------------
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000001';

do $$
begin
  update public.category_members set role = 'viewer'
  where category_id = '10000000-0000-4000-8000-000000000002' and user_id = '00000000-0000-4000-8000-000000000002';
  assert found, 'owner ändert die Rolle';
  update public.category_members set role = 'editor'
  where category_id = '10000000-0000-4000-8000-000000000002' and user_id = '00000000-0000-4000-8000-000000000002';

  begin
    update public.category_members set user_id = '00000000-0000-4000-8000-000000000001'
    where category_id = '10000000-0000-4000-8000-000000000003' and user_id = '00000000-0000-4000-8000-000000000002';
    raise exception 'Mitglied auf einen anderen Nutzer umgehängt';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.category_members set category_id = '10000000-0000-4000-8000-000000000001'
    where category_id = '10000000-0000-4000-8000-000000000003' and user_id = '00000000-0000-4000-8000-000000000002';
    raise exception 'Mitglied in eine andere Kategorie verschoben';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.category_members set sort = 9
    where category_id = '10000000-0000-4000-8000-000000000003' and user_id = '00000000-0000-4000-8000-000000000002';
    raise exception 'Fremde Reihenfolge geändert';
  exception when insufficient_privilege then null;
  end;

  -- Die eigene Reihenfolge weiter über reorder_categories.
  perform public.reorder_categories(array['10000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001']::uuid[]);
  assert (select sort from public.category_members where category_id = '10000000-0000-4000-8000-000000000003' and user_id = auth.uid()) = 0, 'Eigene Reihenfolge per RPC';
end $$;

-- ---------------------------------------------------------------------------------------------
-- Anna (editor bei Miete): created_by ist immer sie selbst und bleibt
-- ---------------------------------------------------------------------------------------------
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000002';

do $$
declare
  v_id uuid := 'bbbbbbbb-0000-4000-8000-000000000001';
  v_demo uuid := '00000000-0000-4000-8000-000000000001';
begin
  insert into public.entries (id, tracker_id, occurred_on, created_by) values (v_id, '20000000-0000-4000-8000-000000000002', '2026-10-01', v_demo);
  assert (select created_by from public.entries where id = v_id) = auth.uid(), 'Fremdes created_by beim Anlegen überschrieben';

  begin
    update public.entries set created_by = v_demo where id = v_id;
    raise exception 'created_by geändert';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.entries set created_by = null where id = v_id;
    raise exception 'created_by geleert';
  exception when insufficient_privilege then null;
  end;

  update public.entries set note = 'geändert' where id = v_id;
  assert (select (note, created_by) from public.entries where id = v_id) = ('geändert'::text, auth.uid()), 'Andere Spalten bleiben änderbar';

  perform public.save_entry(v_id, '20000000-0000-4000-8000-000000000002', '2026-10-02', null, false,
    '[{"field_id": "30000000-0000-4000-8000-000000000005", "num": 950}]'::jsonb);
  assert (select created_by from public.entries where id = v_id) = auth.uid(), 'save_entry lässt created_by stehen';
end $$;

-- ---------------------------------------------------------------------------------------------
-- Konto gelöscht: created_by wird leer, der Schutz verhindert das nicht
-- ---------------------------------------------------------------------------------------------
reset role;

do $$
begin
  delete from auth.users where id = '00000000-0000-4000-8000-000000000002';
  assert not exists (select 1 from public.entries where created_by = '00000000-0000-4000-8000-000000000002'), 'Keine Einträge mehr mit Annas Id';
  assert exists (select 1 from public.entries where id = 'bbbbbbbb-0000-4000-8000-000000000001' and created_by is null), 'Eintrag bleibt ohne Urheberin';
end $$;

rollback;
