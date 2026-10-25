-- Kostenkurve Plus: apply_plus_transaction (aufgerufen von den Edge Functions verify-purchase und
-- app-store-notifications) speichert Abos und berechnet den Abo-Stand. Eigene Transaktion, rollt am Ende
-- zurück. Nutzer: Demo (…001), Anna (…002), Fremd (…003, nur hier angelegt).

begin;

insert into auth.users (id, email) values ('00000000-0000-4000-8000-000000000003', 'fremd@kostenkurve.test');
-- Ohne Demos Cloud-Abo aus dem Seed: Hier bestimmen nur die Käufe den Stand.
delete from public.entitlements where user_id = '00000000-0000-4000-8000-000000000001';

-- ---------------------------------------------------------------------------------------------
-- Service-Role, wie die Edge Functions nach der Prüfung der Apple-Signatur
-- ---------------------------------------------------------------------------------------------
set local role service_role;

-- Demo: Kauf, doppelte und ältere Meldungen, Erstattung, neues Abo, Benachrichtigung ohne Nutzer
do $$
declare
  v_demo constant uuid := '00000000-0000-4000-8000-000000000001';
  v_month constant timestamptz := now() + interval '30 days';
  v_year constant timestamptz := now() + interval '365 days';
  v_result jsonb;
begin
  v_result := public.apply_plus_transaction(v_demo, 'test-orig-1', 'test-tx-1', 'de.eloayoubi.kostenkurve.plus.monthly',
    v_month, null, 'Sandbox', now() - interval '3 hours');
  assert v_result = jsonb_build_object('plus', true, 'valid_until', v_month), 'Kauf gibt Plus bis zum Ablaufdatum';
  assert (select (tier, valid_until, source) from public.entitlements where user_id = v_demo)
    = ('plus'::public.plan_tier, v_month, 'app_store'::text), 'Abo-Stand gespeichert';
  assert (select user_id from public.store_transactions where original_transaction_id = 'test-orig-1') = v_demo, 'Abo gehört Demo';

  -- App und Apple melden denselben Kauf: ändert nichts.
  v_result := public.apply_plus_transaction(v_demo, 'test-orig-1', 'test-tx-1', 'de.eloayoubi.kostenkurve.plus.monthly',
    v_month, null, 'Sandbox', now() - interval '3 hours');
  assert v_result = jsonb_build_object('plus', true, 'valid_until', v_month), 'Wiederholung liefert denselben Stand';
  assert (select count(*) from public.store_transactions where user_id = v_demo) = 1, 'Ein Abo';

  -- Älter signiert (verspätete Meldung): ignoriert, auch mit Erstattung.
  v_result := public.apply_plus_transaction(v_demo, 'test-orig-1', 'test-tx-0', 'de.eloayoubi.kostenkurve.plus.monthly',
    v_month, now() - interval '4 hours', 'Sandbox', now() - interval '4 hours');
  assert (select transaction_id from public.store_transactions where original_transaction_id = 'test-orig-1') = 'test-tx-1', 'Ältere Signatur ignoriert';
  assert (select revoked_at from public.store_transactions where original_transaction_id = 'test-orig-1') is null, 'Nicht erstattet';
  assert (v_result ->> 'plus')::boolean, 'Plus bleibt';

  -- Früherer Abo-Zeitraum, aber neuer signiert (alte Verlängerung aus der App): ignoriert.
  v_result := public.apply_plus_transaction(v_demo, 'test-orig-1', 'test-tx-0', 'de.eloayoubi.kostenkurve.plus.monthly',
    now() - interval '1 day', null, 'Sandbox', now() - interval '2 hours');
  assert (select (transaction_id, expires_at) from public.store_transactions where original_transaction_id = 'test-orig-1')
    = ('test-tx-1'::text, v_month), 'Früherer Zeitraum ignoriert';
  assert v_result = jsonb_build_object('plus', true, 'valid_until', v_month), 'Ablaufdatum bleibt';

  -- Erstattet: kein Plus mehr, die Zeile in entitlements bleibt (free).
  v_result := public.apply_plus_transaction(v_demo, 'test-orig-1', 'test-tx-1', 'de.eloayoubi.kostenkurve.plus.monthly',
    v_month, now() - interval '1 hour', 'Sandbox', now() - interval '1 hour');
  assert v_result = '{"plus": false, "valid_until": null}'::jsonb, 'Erstattung nimmt Plus';
  assert (select tier from public.entitlements where user_id = v_demo) = 'free', 'Abo-Stand free, Zeile bleibt';
  assert (select revoked_at from public.store_transactions where original_transaction_id = 'test-orig-1') is not null, 'Erstattung gespeichert';

  -- Neues Jahresabo (neue original_transaction_id): wieder Plus.
  v_result := public.apply_plus_transaction(v_demo, 'test-orig-2', 'test-tx-2', 'de.eloayoubi.kostenkurve.plus.yearly',
    v_year, null, 'Production', now() - interval '10 minutes');
  assert v_result = jsonb_build_object('plus', true, 'valid_until', v_year), 'Jahresabo gibt Plus';

  -- Verlängerung per Benachrichtigung ohne appAccountToken: trifft das gespeicherte Abo.
  v_result := public.apply_plus_transaction(null, 'test-orig-2', 'test-tx-3', 'de.eloayoubi.kostenkurve.plus.yearly',
    v_year + interval '365 days', null, 'Production', now());
  assert (select (user_id, transaction_id) from public.store_transactions where original_transaction_id = 'test-orig-2')
    = (v_demo, 'test-tx-3'::text), 'Verlängerung ohne Nutzer gespeichert';
  assert v_result = jsonb_build_object('plus', true, 'valid_until', v_year + interval '365 days'), 'Plus verlängert';

  -- Unbekanntes Abo ohne Nutzer oder für ein gelöschtes Konto: nichts gespeichert.
  v_result := public.apply_plus_transaction(null, 'test-orig-x', 'test-tx-x', 'de.eloayoubi.kostenkurve.plus.monthly',
    v_month, null, 'Sandbox', now());
  assert v_result = '{"plus": false, "valid_until": null}'::jsonb, 'Unbekanntes Abo ohne Nutzer';
  v_result := public.apply_plus_transaction('00000000-0000-4000-8000-0000000000ff', 'test-orig-x', 'test-tx-x', 'de.eloayoubi.kostenkurve.plus.monthly',
    v_month, null, 'Sandbox', now());
  assert v_result = '{"plus": false, "valid_until": null}'::jsonb, 'Unbekannter Nutzer';
  assert not exists (select 1 from public.store_transactions where original_transaction_id = 'test-orig-x'), 'Nichts gespeichert';

  -- Fremdes Produkt: abgelehnt.
  begin
    perform public.apply_plus_transaction(v_demo, 'test-orig-9', 'test-tx-9', 'de.eloayoubi.kostenkurve.tip',
      v_month, null, 'Sandbox', now());
    raise exception 'Unbekanntes Produkt angenommen';
  exception when sqlstate 'P0063' then null;
  end;
end $$;

-- Anna: abgelaufen, verlängert; Fremd übernimmt das Abo (gleiche Apple-ID); Promo-Plus bleibt
do $$
declare
  v_anna constant uuid := '00000000-0000-4000-8000-000000000002';
  v_fremd constant uuid := '00000000-0000-4000-8000-000000000003';
  v_result jsonb;
begin
  -- Schon abgelaufen (z. B. beim Wiederherstellen): gespeichert, aber kein Plus.
  v_result := public.apply_plus_transaction(v_anna, 'test-orig-3', 'test-tx-4', 'de.eloayoubi.kostenkurve.plus.monthly',
    now() - interval '1 day', null, 'Sandbox', now() - interval '2 days');
  assert v_result = '{"plus": false, "valid_until": null}'::jsonb, 'Abgelaufen gibt kein Plus';
  assert (select tier from public.entitlements where user_id = v_anna) = 'free', 'Abo-Stand free';
  assert exists (select 1 from public.store_transactions where original_transaction_id = 'test-orig-3'), 'Abgelaufenes Abo gespeichert';

  v_result := public.apply_plus_transaction(v_anna, 'test-orig-3', 'test-tx-5', 'de.eloayoubi.kostenkurve.plus.monthly',
    now() + interval '10 days', null, 'Sandbox', now() - interval '1 day');
  assert (v_result ->> 'plus')::boolean, 'Verlängerung gibt Plus';

  -- Fremd kauft mit derselben Apple-ID: Das Abo wandert, Anna verliert Plus.
  v_result := public.apply_plus_transaction(v_fremd, 'test-orig-3', 'test-tx-6', 'de.eloayoubi.kostenkurve.plus.yearly',
    now() + interval '365 days', null, 'Sandbox', now());
  assert (v_result ->> 'plus')::boolean, 'Fremd hat Plus';
  assert (select user_id from public.store_transactions where original_transaction_id = 'test-orig-3') = v_fremd, 'Abo gehört Fremd';
  assert (select tier from public.entitlements where user_id = v_anna) = 'free', 'Anna hat kein Plus mehr';

  -- Promo-Plus ohne Ende bleibt, auch wenn ein App-Store-Abo abgelaufen ist.
  update public.entitlements set tier = 'plus', valid_until = null, source = 'promo' where user_id = v_anna;
  v_result := public.apply_plus_transaction(v_anna, 'test-orig-4', 'test-tx-7', 'de.eloayoubi.kostenkurve.plus.monthly',
    now() - interval '1 hour', null, 'Sandbox', now());
  assert v_result = '{"plus": true, "valid_until": null}'::jsonb, 'Promo-Plus bleibt';
  assert (select source from public.entitlements where user_id = v_anna) = 'promo', 'Quelle bleibt promo';

  -- Promo mit Ende, App-Store-Abo läuft länger: Das Abo zählt.
  update public.entitlements set valid_until = now() + interval '5 days' where user_id = v_anna;
  v_result := public.apply_plus_transaction(v_anna, 'test-orig-4', 'test-tx-8', 'de.eloayoubi.kostenkurve.plus.monthly',
    now() + interval '30 days', null, 'Sandbox', now());
  assert v_result = jsonb_build_object('plus', true, 'valid_until', now() + interval '30 days'), 'Längeres Abo ersetzt Promo';
  assert (select source from public.entitlements where user_id = v_anna) = 'app_store', 'Quelle app_store';
end $$;

-- ---------------------------------------------------------------------------------------------
-- Angemeldete Nutzer: lesen nur die eigenen Abos, schreiben nichts
-- ---------------------------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000001';

do $$
begin
  assert public.has_plus(), 'Demo hat Plus';
  assert (select count(*) from public.store_transactions) = 2, 'Demo sieht ihre beiden Abos';
  assert not exists (select 1 from public.store_transactions where user_id <> auth.uid()), 'Nur eigene Abos sichtbar';

  begin
    perform public.apply_plus_transaction(auth.uid(), 'test-orig-5', 'test-tx-9', 'de.eloayoubi.kostenkurve.plus.yearly',
      now() + interval '100 years', null, 'Production', now());
    raise exception 'Nutzer konnte sich Plus selbst geben';
  exception when insufficient_privilege then null;
  end;

  begin
    insert into public.store_transactions (original_transaction_id, user_id, product_id, transaction_id, expires_at, environment, signed_at)
      values ('test-orig-5', auth.uid(), 'de.eloayoubi.kostenkurve.plus.yearly', 'test-tx-9', now() + interval '100 years', 'Production', now());
    raise exception 'Nutzer konnte ein Abo eintragen';
  exception when insufficient_privilege then null;
  end;

  update public.store_transactions set expires_at = now() + interval '100 years';
  assert not found, 'Nutzer konnte sein Abo verlängern';
  delete from public.store_transactions;
  assert not found, 'Nutzer konnte sein Abo löschen';
end $$;

set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000002';

do $$
begin
  assert (select count(*) from public.store_transactions) = 1, 'Anna sieht nur ihr eigenes Abo';
  assert not exists (select 1 from public.store_transactions where user_id = '00000000-0000-4000-8000-000000000001'), 'Abos von Demo bleiben privat';
end $$;

set local role anon;

do $$
begin
  assert (select count(*) from public.store_transactions) = 0, 'anon sieht keine Abos';
  assert not has_function_privilege('anon', 'public.apply_plus_transaction(uuid, text, text, text, timestamptz, timestamptz, text, timestamptz)', 'execute'), 'anon darf nicht';
  assert has_function_privilege('service_role', 'public.apply_plus_transaction(uuid, text, text, text, timestamptz, timestamptz, text, timestamptz)', 'execute'), 'service_role darf';
end $$;

rollback;
