-- save_entry aus Meilenstein 2: Upsert unter der Geräte-Id, Werte ersetzen, Rechte je Rolle.
-- Eigene Transaktion, rollt am Ende zurück. Nutzer: Demo (…001, owner), Anna (…002, editor bei
-- Miete, viewer bei Auto).

begin;

set local role authenticated;

-- ---------------------------------------------------------------------------------------------
-- Demo: neuer Eintrag, erneut gesendet, geändert, gelöscht
-- ---------------------------------------------------------------------------------------------
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000001';

do $$
declare
  v_id uuid := 'aaaaaaaa-0000-4000-8000-000000000001';
begin
  perform public.save_entry(
    v_id, '20000000-0000-4000-8000-000000000001', '2026-10-20', '  nach dem Urlaub ', false,
    '[{"field_id": "30000000-0000-4000-8000-000000000001", "num": 47100},
      {"field_id": "30000000-0000-4000-8000-000000000002", "num": 0.329}]'::jsonb
  );
  assert (select count(*) from public.entry_values where entry_id = v_id) = 2, 'Zwei Werte gespeichert';
  assert (select note from public.entries where id = v_id) = 'nach dem Urlaub', 'Notiz getrimmt';
  assert (select created_by from public.entries where id = v_id) = auth.uid(), 'Wer erfasst, steht dabei';

  -- Dieselbe Id noch einmal (Warteschlange sendet doppelt): kein zweiter Eintrag.
  perform public.save_entry(
    v_id, '20000000-0000-4000-8000-000000000001', '2026-10-20', 'nach dem Urlaub', false,
    '[{"field_id": "30000000-0000-4000-8000-000000000001", "num": 47100},
      {"field_id": "30000000-0000-4000-8000-000000000002", "num": 0.329}]'::jsonb
  );
  assert (select count(*) from public.entries where id = v_id) = 1, 'Genau ein Eintrag';

  -- Geändert: anderer Stand, Arbeitspreis entfernt, Datum verschoben, Zählerwechsel.
  perform public.save_entry(
    v_id, '20000000-0000-4000-8000-000000000001', '2026-10-21', null, true,
    '[{"field_id": "30000000-0000-4000-8000-000000000001", "num": 5}]'::jsonb
  );
  assert (select num from public.entry_values where entry_id = v_id and field_id = '30000000-0000-4000-8000-000000000001') = 5, 'Stand ersetzt';
  assert not exists (select 1 from public.entry_values where entry_id = v_id and field_id = '30000000-0000-4000-8000-000000000002'), 'Fehlender Wert entfernt';
  assert (select (occurred_on, meter_change, note is null) from public.entries where id = v_id) = ('2026-10-21'::date, true, true), 'Kopfdaten ersetzt';

  -- Leer, falscher Typ, fremdes Feld, anderer Tracker: alles abgelehnt.
  begin
    perform public.save_entry(v_id, '20000000-0000-4000-8000-000000000001', '2026-10-21', null, false, '[]'::jsonb);
    raise exception 'Eintrag ohne Werte angenommen';
  exception when check_violation then null;
  end;
  begin
    perform public.save_entry(gen_random_uuid(), '20000000-0000-4000-8000-000000000001', '2026-10-21', null, false,
      '[{"field_id": "30000000-0000-4000-8000-000000000001", "txt": "viel"}]'::jsonb);
    raise exception 'Text in einem Zahlenfeld angenommen';
  exception when check_violation then null;
  end;
  begin
    perform public.save_entry(gen_random_uuid(), '20000000-0000-4000-8000-000000000001', '2026-10-21', null, false,
      '[{"field_id": "30000000-0000-4000-8000-000000000005", "num": 900}]'::jsonb);
    raise exception 'Feld eines anderen Trackers angenommen';
  exception when check_violation then null;
  end;
  begin
    perform public.save_entry(v_id, '20000000-0000-4000-8000-000000000002', '2026-10-21', null, false,
      '[{"field_id": "30000000-0000-4000-8000-000000000005", "num": 900}]'::jsonb);
    raise exception 'Eintrag in anderen Tracker verschoben';
  exception when check_violation then null;
  end;

  -- Abrechnungszeitraum.
  perform public.save_entry(
    v_id, '20000000-0000-4000-8000-000000000001', '2026-05-20', 'Abrechnung 2025', false,
    '[{"field_id": "30000000-0000-4000-8000-000000000003", "num": 148}]'::jsonb, '2025-01-01', '2025-12-31'
  );
  assert (select (period_start, period_end) from public.entries where id = v_id) = ('2025-01-01'::date, '2025-12-31'::date), 'Zeitraum gespeichert';
  begin
    perform public.save_entry(
      v_id, '20000000-0000-4000-8000-000000000001', '2026-05-20', null, false,
      '[{"field_id": "30000000-0000-4000-8000-000000000003", "num": 148}]'::jsonb, '2025-12-31', '2025-01-01'
    );
    raise exception 'Zeitraum rückwärts angenommen';
  exception when check_violation then null;
  end;

  -- Löschen ist wiederholbar.
  delete from public.entries where id = v_id;
  assert found, 'Eintrag gelöscht';
  delete from public.entries where id = v_id;
  assert not found, 'Zweites Löschen ändert nichts';
end $$;

-- ---------------------------------------------------------------------------------------------
-- Anna: schreibt in Miete (editor), nicht ins Auto (viewer), sieht Strom nicht
-- ---------------------------------------------------------------------------------------------
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000002';

do $$
begin
  perform public.save_entry('aaaaaaaa-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000002', '2026-10-01', 'Mieterhöhung angekündigt', false,
    '[{"field_id": "30000000-0000-4000-8000-000000000005", "num": 950}]'::jsonb);
  assert exists (select 1 from public.entries where id = 'aaaaaaaa-0000-4000-8000-000000000002'), 'editor erfasst';

  begin
    perform public.save_entry(gen_random_uuid(), '20000000-0000-4000-8000-000000000003', '2026-10-01', null, false,
      '[{"field_id": "30000000-0000-4000-8000-000000000009", "num": 60}]'::jsonb);
    raise exception 'viewer durfte erfassen';
  exception when insufficient_privilege then null;
  end;

  begin
    perform public.save_entry(gen_random_uuid(), '20000000-0000-4000-8000-000000000001', '2026-10-01', null, false,
      '[{"field_id": "30000000-0000-4000-8000-000000000001", "num": 1}]'::jsonb);
    raise exception 'Fremde Kategorie beschrieben';
  exception when insufficient_privilege then null;
  end;

  delete from public.entries where tracker_id = '20000000-0000-4000-8000-000000000003';
  assert not found, 'viewer durfte löschen';
end $$;

rollback;
