-- Kostenkurve Cloud: Schreiben nur mit Abo (eigenes oder das des Eigentümers der Kategorie); Lesen,
-- Löschen und Verlassen auch ohne. Eigene Transaktion, rollt am Ende zurück.
-- Nutzer: Demo (…001, owner, Cloud-Abo aus dem Seed), Anna (…002, ohne Abo, editor bei Miete),
-- Ohne (…005, ohne Abo, mit einer Kategorie aus der Testphase).

begin;

insert into auth.users (id, email) values ('00000000-0000-4000-8000-000000000005', 'ohne@kostenkurve.test');
-- Wie früher angelegt (vor der Cloud-Pflicht), daher als Server ohne RLS.
insert into public.categories (id, owner_id, name, icon, swatch) values
  ('10000000-0000-4000-8000-000000000005', '00000000-0000-4000-8000-000000000005', 'Strom alt', 'bolt', 'orange');
insert into public.trackers (id, category_id, name) values
  ('20000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000005', 'Zähler');
insert into public.fields (id, tracker_id, name, kind, role, unit, sort) values
  ('30000000-0000-4000-8000-000000000105', '20000000-0000-4000-8000-000000000005', 'Zählerstand', 'number', 'meter_reading', 'kWh', 0);

set local role authenticated;

-- ---------------------------------------------------------------------------------------------
-- Ohne Abo: lesen und löschen ja, anlegen und ändern nein
-- ---------------------------------------------------------------------------------------------
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000005';

do $$
begin
  assert (select count(*) from public.categories) = 1, 'Eigene Kategorie ohne Abo lesbar';
  assert not public.can_edit_category('10000000-0000-4000-8000-000000000005'), 'owner ohne Abo darf nicht ändern';

  begin
    perform public.create_category('Neu', 'star', 'gray');
    raise exception 'Kategorie ohne Abo angelegt';
  exception when insufficient_privilege then null;
  end;

  begin
    insert into public.entries (tracker_id, occurred_on) values ('20000000-0000-4000-8000-000000000005', '2026-10-25');
    raise exception 'Eintrag ohne Abo angelegt';
  exception when insufficient_privilege then null;
  end;

  -- Die Offline-Warteschlange der App sendet über save_entry: ebenso abgelehnt.
  begin
    perform public.save_entry(gen_random_uuid(), '20000000-0000-4000-8000-000000000005', '2026-10-25',
      p_values => '[{"field_id": "30000000-0000-4000-8000-000000000105", "num": 100}]'::jsonb);
    raise exception 'save_entry ohne Abo angenommen';
  exception when insufficient_privilege then null;
  end;

  -- Ändern trifft ohne Recht keine Zeile.
  update public.categories set name = 'Umbenannt' where id = '10000000-0000-4000-8000-000000000005';
  assert (select name from public.categories where id = '10000000-0000-4000-8000-000000000005') = 'Strom alt', 'Umbenennen ohne Abo wirkt nicht';

  -- Hilfsfunktionen sind nicht direkt abfragbar.
  begin
    perform public.has_cloud('10000000-0000-4000-8000-000000000001');
    raise exception 'has_cloud direkt aufrufbar';
  exception when insufficient_privilege then null;
  end;

  -- Löschen bleibt (DSGVO Art. 17).
  delete from public.categories where id = '10000000-0000-4000-8000-000000000005';
  assert (select count(*) from public.categories) = 0, 'Eigene Kategorie ohne Abo gelöscht';
end $$;

-- ---------------------------------------------------------------------------------------------
-- Anna ohne eigenes Abo: schreibt mit Demos Abo in Miete mit, legt aber nichts Eigenes an
-- ---------------------------------------------------------------------------------------------
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000002';

do $$
begin
  assert not public.has_plus(), 'Anna hat kein Abo';
  assert public.can_edit_category('10000000-0000-4000-8000-000000000002'), 'Demos Abo reicht für Anna';
  insert into public.entries (tracker_id, occurred_on) values ('20000000-0000-4000-8000-000000000002', '2026-10-25');

  begin
    perform public.create_category('Annas', 'star', 'gray');
    raise exception 'Anna hat ohne Abo eine Kategorie angelegt';
  exception when insufficient_privilege then null;
  end;
end $$;

-- ---------------------------------------------------------------------------------------------
-- Demos Abo endet: niemand schreibt mehr in ihre Kategorien, Lesen bleibt; Teilen und Beitreten
-- brauchen ein laufendes Abo
-- ---------------------------------------------------------------------------------------------
reset role;
update public.entitlements set valid_until = now() - interval '1 day' where user_id = '00000000-0000-4000-8000-000000000001';
insert into public.category_invites (code, category_id, role, created_by) values
  ('CLOUDTEST1', '10000000-0000-4000-8000-000000000001', 'editor', '00000000-0000-4000-8000-000000000001');
set local role authenticated;

do $$
begin
  assert not public.can_edit_category('10000000-0000-4000-8000-000000000002'), 'Ohne Demos Abo schreibt Anna nicht mehr';
  assert (select count(*) from public.entries where tracker_id = '20000000-0000-4000-8000-000000000002') > 0, 'Anna liest weiter';
end $$;

set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000001';

do $$
begin
  assert not public.has_plus(), 'Demos Abo ist abgelaufen';
  assert (select count(*) from public.categories) = 3, 'Demo liest weiter (Export, Umzug aufs Gerät)';

  begin
    perform public.create_category_invite('10000000-0000-4000-8000-000000000002');
    raise exception 'Einladung ohne Abo erstellt';
  exception when sqlstate 'P0064' then null;
  end;

  begin
    insert into public.entries (tracker_id, occurred_on) values ('20000000-0000-4000-8000-000000000001', '2026-10-25');
    raise exception 'Eintrag nach Abo-Ende angelegt';
  exception when insufficient_privilege then null;
  end;
end $$;

set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000005';

do $$
begin
  begin
    perform public.accept_category_invite('CLOUDTEST1');
    raise exception 'Beitritt ohne Abo des Eigentümers';
  exception when sqlstate 'P0064' then null;
  end;
end $$;

-- Der Code bleibt gültig (Prüfung als Server, Einladungen sieht nur der owner).
reset role;
do $$
begin
  assert (select accepted_at from public.category_invites where code = 'CLOUDTEST1') is null, 'Code bleibt gültig';
end $$;

rollback;
