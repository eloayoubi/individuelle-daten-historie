-- Werte, an denen die App beim Laden scheitern würde (NaN, Infinity, 'infinity', v. Chr.), und
-- Auswahl-Optionen ohne Grenze. Eigene Transaktion, rollt am Ende zurück. Anna (…002) ist editor bei
-- Miete (Tracker …002, Feld Kaltmiete …005).

begin;

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000002';

do $$
declare
  v_tracker constant uuid := '20000000-0000-4000-8000-000000000002';
  v_field constant uuid := '30000000-0000-4000-8000-000000000005';
  v_entry uuid := gen_random_uuid();
  v_bad text;
begin
  insert into public.entries (id, tracker_id, occurred_on) values (v_entry, v_tracker, '2026-11-01');
  insert into public.entry_values (entry_id, field_id, num) values (v_entry, v_field, 980.5);

  foreach v_bad in array array['NaN', 'Infinity', '-Infinity', '1e18'] loop
    begin
      update public.entry_values set num = v_bad::numeric where entry_id = v_entry and field_id = v_field;
      raise exception 'num % angenommen', v_bad;
    exception when check_violation then null;
    end;
    begin
      update public.fields set factor = v_bad::numeric where id = v_field;
      raise exception 'factor % angenommen', v_bad;
    exception when check_violation then null;
    end;
  end loop;

  foreach v_bad in array array['infinity', '-infinity', '0044-03-15 BC', '1899-12-31', '2200-01-01'] loop
    begin
      update public.entries set occurred_on = v_bad::date where id = v_entry;
      raise exception 'occurred_on % angenommen', v_bad;
    exception when check_violation then null;
    end;
    begin
      update public.entries set period_start = '2026-01-01', period_end = v_bad::date where id = v_entry;
      raise exception 'period_end % angenommen', v_bad;
    exception when check_violation then null;
    end;
  end loop;

  -- Gültige Werte bleiben erlaubt.
  update public.entry_values set num = -123456789012.5 where entry_id = v_entry and field_id = v_field;
  update public.entries set occurred_on = '2000-01-01', period_start = '1999-12-01', period_end = '2000-01-31' where id = v_entry;
  update public.fields set factor = 0.001 where id = v_field;
end $$;

-- Owner (Demo): archived_at 'infinity' scheitert am Check, nicht an der Rolle.
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000001';
do $$
declare
  v_field uuid;
begin
  begin
    update public.categories set archived_at = 'infinity' where id = '10000000-0000-4000-8000-000000000002';
    raise exception 'archived_at infinity angenommen';
  exception when check_violation then null;
  end;
  update public.categories set archived_at = now() where id = '10000000-0000-4000-8000-000000000002';
  update public.categories set archived_at = null where id = '10000000-0000-4000-8000-000000000002';

  -- Über den RPC: Feld-JSON mit factor NaN scheitert ebenfalls.
  begin
    perform public.create_tracker('10000000-0000-4000-8000-000000000001', 'Kaputt', '[{"name": "x", "kind": "number", "factor": "NaN"}]'::jsonb);
    raise exception 'create_tracker mit factor NaN angenommen';
  exception when check_violation then null;
  end;

  -- Auswahl: höchstens 50 Optionen mit 1 bis 60 Zeichen.
  insert into public.fields (tracker_id, name, kind, choices)
    values ('20000000-0000-4000-8000-000000000002', 'Art', 'choice', array['A', 'B']) returning id into v_field;
  begin
    update public.fields set choices = array(select 'Option ' || i from generate_series(1, 51) i) where id = v_field;
    raise exception '51 Optionen angenommen';
  exception when check_violation then null;
  end;
  begin
    update public.fields set choices = array[repeat('x', 61)] where id = v_field;
    raise exception 'Option mit 61 Zeichen angenommen';
  exception when check_violation then null;
  end;
  begin
    update public.fields set choices = array['']::text[] where id = v_field;
    raise exception 'leere Option angenommen';
  exception when check_violation then null;
  end;
  update public.fields set choices = array(select 'Option ' || i from generate_series(1, 50) i) where id = v_field;
end $$;

-- Beleg mit created_at 'infinity' (als Server, die Policy verlangt sonst die Datei im Bucket).
reset role;
do $$
declare
  v_entry uuid := gen_random_uuid();
begin
  insert into public.entries (id, tracker_id, occurred_on) values (v_entry, '20000000-0000-4000-8000-000000000002', '2026-11-01');
  begin
    insert into public.attachments (entry_id, storage_path, mime_type, size_bytes, created_by, created_at)
      values (v_entry, '10000000-0000-4000-8000-000000000002/' || v_entry || '/x.pdf', 'application/pdf', 10,
              '00000000-0000-4000-8000-000000000002', 'infinity');
    raise exception 'Beleg mit created_at infinity angenommen';
  exception when check_violation then null;
  end;
end $$;

rollback;
