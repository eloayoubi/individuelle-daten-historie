-- Schreibwege aus Meilenstein 1: create_category, reorder_categories, Schutz-Trigger, Rechte je Rolle.
-- Eigene Transaktion, rollt am Ende zurück. Nutzer: Demo (…001, owner), Anna (…002, editor bei
-- Miete, viewer bei Auto), Neu (…004, ohne Kategorien).

begin;

insert into auth.users (id, email) values ('00000000-0000-4000-8000-000000000004', 'neu@kostenkurve.test');

set local role authenticated;

-- ---------------------------------------------------------------------------------------------
-- Demo (owner): Vorlage anlegen, Reihenfolge, Feldtyp-Schutz, archivieren
-- ---------------------------------------------------------------------------------------------
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000001';

do $$
declare
  v_category uuid;
  v_field uuid;
  v_entry uuid;
begin
  v_category := public.create_category(
    'Wasser', 'drop', 'blue', 'wasser',
    '[{"name": "Wasserzähler", "fields": [
        {"name": "Zählerstand", "kind": "number", "role": "meter_reading", "unit": "m³"},
        {"name": "Wasser & Abwasser", "kind": "currency", "role": "unit_price", "unit": "€/m³"},
        {"name": "Kündigungsfrist", "kind": "choice", "choices": ["1 Monat", "3 Monate"]}
      ]}]'::jsonb
  );
  assert public.category_role(v_category) = 'owner', 'Anlegerin ist owner';
  assert (select template_key from public.categories where id = v_category) = 'wasser', 'Vorlage gemerkt';
  assert (select count(*) from public.trackers where category_id = v_category) = 1, 'Tracker angelegt';
  assert (
    select array_agg(f.name order by f.sort) from public.fields f join public.trackers t on t.id = f.tracker_id where t.category_id = v_category
  ) = array['Zählerstand', 'Wasser & Abwasser', 'Kündigungsfrist'], 'Felder in Vorlagen-Reihenfolge';
  assert (select choices from public.fields f join public.trackers t on t.id = f.tracker_id where t.category_id = v_category and f.kind = 'choice')
    = array['1 Monat', '3 Monate'], 'Auswahlwerte übernommen';
  assert (select sort from public.category_members where category_id = v_category and user_id = auth.uid()) = 3, 'Neue Kategorie ans Ende (nach 0, 1, 2)';

  -- Ein ungültiges Feld: nichts bleibt halb angelegt.
  begin
    perform public.create_category('Kaputt', 'star', 'gray', null, '[{"name": "T", "fields": [{"name": "F", "kind": "text", "role": "meter_reading"}]}]'::jsonb);
    raise exception 'Ungültige Kombination aus Feldtyp und Zeitverhalten angenommen';
  exception when check_violation then null;
  end;
  assert not exists (select 1 from public.categories where name = 'Kaputt'), 'Kategorie ohne gültige Felder nicht angelegt';

  begin
    perform public.create_category('Kaputt', 'star', 'gray', null, '{"name": "kein Array"}'::jsonb);
    raise exception 'p_trackers ohne Liste angenommen';
  exception when invalid_parameter_value then null;
  end;

  -- Eigene Reihenfolge.
  perform public.reorder_categories(array['10000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001']::uuid[]);
  assert (select sort from public.category_members where category_id = '10000000-0000-4000-8000-000000000003' and user_id = auth.uid()) = 0, 'Auto zuerst';
  assert (select sort from public.category_members where category_id = '10000000-0000-4000-8000-000000000001' and user_id = auth.uid()) = 1, 'Strom danach';

  -- Feldtyp mit gespeicherten Werten: Text → Auswahl geht, Text → Zahl nicht.
  insert into public.fields (tracker_id, name, kind) values ('20000000-0000-4000-8000-000000000001', 'Zählernummer', 'text') returning id into v_field;
  insert into public.entries (tracker_id, occurred_on) values ('20000000-0000-4000-8000-000000000001', '2026-10-01') returning id into v_entry;
  insert into public.entry_values (entry_id, field_id, txt) values (v_entry, v_field, '1ESY1160554321');
  update public.fields set kind = 'choice' where id = v_field;
  begin
    update public.fields set kind = 'number' where id = v_field;
    raise exception 'Feldtyp trotz Werten in andere Spalte geändert';
  exception when check_violation then null;
  end;
  -- Ohne Werte ist jeder passende Typ erlaubt.
  insert into public.fields (tracker_id, name, kind) values ('20000000-0000-4000-8000-000000000001', 'Notiz', 'text') returning id into v_field;
  update public.fields set kind = 'number', role = 'snapshot' where id = v_field;

  -- Felder bleiben in ihrem Tracker.
  begin
    update public.fields set tracker_id = '20000000-0000-4000-8000-000000000002' where id = v_field;
    raise exception 'Feld in anderen Tracker verschoben';
  exception when check_violation then null;
  end;

  -- Archivieren und wiederherstellen.
  update public.categories set archived_at = now() where id = v_category;
  assert found, 'owner archiviert';
  update public.categories set archived_at = null where id = v_category;
  assert found, 'owner stellt wieder her';
end $$;

-- ---------------------------------------------------------------------------------------------
-- Anna: editor bei Miete (umbenennen, Tracker anlegen), viewer bei Auto (nur lesen)
-- ---------------------------------------------------------------------------------------------
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000002';

do $$
begin
  update public.categories set name = 'Miete Wohnung' where id = '10000000-0000-4000-8000-000000000002';
  assert found, 'editor benennt um';

  begin
    update public.categories set archived_at = now() where id = '10000000-0000-4000-8000-000000000002';
    raise exception 'editor durfte archivieren';
  exception when insufficient_privilege then null;
  end;

  begin
    update public.categories set owner_id = auth.uid() where id = '10000000-0000-4000-8000-000000000002';
    raise exception 'editor hat sich zum Eigentümer gemacht';
  exception when insufficient_privilege then null;
  end;

  insert into public.trackers (category_id, name, sort) values ('10000000-0000-4000-8000-000000000002', 'Garage', 1);
  begin
    update public.trackers set category_id = '10000000-0000-4000-8000-000000000003' where name = 'Garage';
    raise exception 'Tracker in andere Kategorie verschoben';
  exception when check_violation or insufficient_privilege then null;
  end;

  begin
    insert into public.fields (tracker_id, name, kind) values ('20000000-0000-4000-8000-000000000003', 'Notiz', 'text');
    raise exception 'viewer legte ein Feld an';
  exception when insufficient_privilege then null;
  end;

  update public.fields set name = 'Gekapert' where id = '30000000-0000-4000-8000-000000000008';
  assert not found, 'viewer änderte ein Feld';

  -- Annas Reihenfolge berührt Demos nicht.
  perform public.reorder_categories(array['10000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000002']::uuid[]);
  assert (select sort from public.category_members where category_id = '10000000-0000-4000-8000-000000000003' and user_id = auth.uid()) = 0, 'Anna sortiert für sich';
  assert (select sort from public.category_members where category_id = '10000000-0000-4000-8000-000000000002' and user_id = '00000000-0000-4000-8000-000000000001') = 1, 'Demos Reihenfolge unverändert';
end $$;

-- ---------------------------------------------------------------------------------------------
-- Neu: erste eigene Kategorie, fremde bleiben unerreichbar
-- ---------------------------------------------------------------------------------------------
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000004';

do $$
declare
  v_category uuid;
begin
  v_category := public.create_category('Abos', 'play', 'pink', 'abos', '[]'::jsonb);
  assert (select sort from public.category_members where category_id = v_category and user_id = auth.uid()) = 0, 'Erste Kategorie an Position 0';
  assert (select count(*) from public.categories) = 1, 'Nur die eigene sichtbar';

  begin
    insert into public.trackers (category_id, name) values ('10000000-0000-4000-8000-000000000001', 'Fremd');
    raise exception 'Tracker in fremder Kategorie angelegt';
  exception when insufficient_privilege then null;
  end;
end $$;

-- ---------------------------------------------------------------------------------------------
-- Ohne Anmeldung (anon) keine RPCs
-- ---------------------------------------------------------------------------------------------
set local role anon;

do $$
begin
  begin
    perform public.create_category('Anonym', 'star', 'gray');
    raise exception 'anon durfte eine Kategorie anlegen';
  exception when insufficient_privilege then null;
  end;
end $$;

rollback;
