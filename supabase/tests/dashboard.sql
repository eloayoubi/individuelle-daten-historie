-- Kennzahlen je Kategorie: fields.summary, categories.dashboard, create_category mit summary.
-- Eigene Transaktion, rollt am Ende zurück. Nutzer: Demo (…001, owner), Anna (…002, editor bei
-- Miete, viewer bei Auto).

begin;

set local role authenticated;

-- ---------------------------------------------------------------------------------------------
-- Demo (owner): Zusammenfassung beim Anlegen, Dashboard setzen, ungültige Werte
-- ---------------------------------------------------------------------------------------------
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000001';

do $$
declare
  v_category uuid;
begin
  v_category := public.create_category(
    'Garten', 'drop', 'green', null,
    '[{"name": "Gartenzähler", "fields": [
        {"name": "Zählerstand", "kind": "number", "role": "meter_reading", "unit": "m³", "summary": "difference"},
        {"name": "Gießen", "kind": "number", "role": "snapshot", "unit": "l"}
      ]}]'::jsonb
  );
  assert (
    select array_agg(coalesce(f.summary, '-') order by f.sort) from public.fields f join public.trackers t on t.id = f.tracker_id where t.category_id = v_category
  ) = array['difference', '-'], 'summary übernommen, ohne Angabe leer';
  assert (select dashboard from public.categories where id = v_category) = '{}'::jsonb, 'Dashboard startet leer (App wählt)';

  update public.categories set dashboard = '{"metrics": [{"tracker": null}], "showAddTracker": false}' where id = v_category;
  assert (select dashboard ->> 'showAddTracker' from public.categories where id = v_category) = 'false', 'Dashboard gespeichert';

  begin
    update public.fields set summary = 'median' where tracker_id in (select id from public.trackers where category_id = v_category);
    raise exception 'Unbekannte Zusammenfassung angenommen';
  exception when check_violation then null;
  end;

  begin
    update public.categories set dashboard = '[]' where id = v_category;
    raise exception 'Dashboard als Liste angenommen';
  exception when check_violation then null;
  end;
end $$;

-- ---------------------------------------------------------------------------------------------
-- Anna: als editor (Miete) darf sie das Dashboard ändern, als viewer (Auto) nicht
-- ---------------------------------------------------------------------------------------------
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000002';

do $$
declare
  v_rows integer;
begin
  update public.categories set dashboard = '{"showAddTracker": false}' where id = '10000000-0000-4000-8000-000000000002';
  get diagnostics v_rows = row_count;
  assert v_rows = 1, 'editor ändert das Dashboard';

  update public.categories set dashboard = '{"showAddTracker": false}' where id = '10000000-0000-4000-8000-000000000003';
  get diagnostics v_rows = row_count;
  assert v_rows = 0, 'viewer ändert das Dashboard nicht';
end $$;

rollback;
