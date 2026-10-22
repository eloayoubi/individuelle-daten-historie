-- Kostenkurve Plus über den App Store. Nach dem Kauf schickt die App die von Apple signierte
-- StoreKit-2-Transaktion an die Edge Function verify-purchase; Verlängerung, Ablauf und Erstattung meldet
-- Apple an app-store-notifications. Beide prüfen Signatur, App, Umgebung und Produkt und rufen
-- apply_plus_transaction auf (nur Service-Role): Das speichert den Stand des Abos und berechnet daraus
-- entitlements neu – und damit has_plus().
--
-- Je Abo (original_transaction_id, bleibt über alle Verlängerungen gleich) zählt der neueste Stand.
-- Ältere Signaturen und frühere Abo-Zeiträume (früheres Ablaufdatum) überschreiben nichts, so ändern
-- doppelt, verspätet oder durcheinander gemeldete Transaktionen nichts mehr. Eine Erstattung des
-- laufenden Zeitraums (gleiches Ablaufdatum, neuere Signatur) gilt dagegen sofort.
--
-- Fehler: P0063 plus_unknown_product.

create table public.store_transactions (
  original_transaction_id text primary key,
  -- Käufer: appAccountToken der Transaktion = Nutzer-Id
  user_id uuid not null references public.profiles (id) on delete cascade,
  product_id text not null,
  -- Zuletzt gemeldete Transaktion (Kauf oder Verlängerung)
  transaction_id text not null,
  expires_at timestamptz,
  -- Erstattet oder widerrufen
  revoked_at timestamptz,
  -- Production oder Sandbox (TestFlight, App Review)
  environment text not null,
  -- signedDate von Apple, legt die Reihenfolge der Meldungen fest
  signed_at timestamptz not null,
  updated_at timestamptz not null default now()
);

create index store_transactions_user_idx on public.store_transactions (user_id);

alter table public.store_transactions enable row level security;

-- Lesen nur die eigenen Abos (z. B. „verlängert sich am …“); schreiben nur apply_plus_transaction.
create policy store_transactions_select on public.store_transactions for select to authenticated using (user_id = auth.uid());

-- p_user: Käufer (appAccountToken). null oder unbekannt (Benachrichtigung ohne Token, Konto gelöscht):
-- Dann wird nur ein schon gespeichertes Abo aktualisiert. Gehört das Abo bisher jemand anderem (anderes
-- Konto, gleiche Apple-ID), wandert es mit dem neueren Stand zum Käufer.
-- Liefert den Abo-Stand des Nutzers: {"plus": bool, "valid_until": timestamptz | null}.
create function public.apply_plus_transaction(
  p_user uuid,
  p_original text,
  p_transaction text,
  p_product text,
  p_expires timestamptz,
  p_revoked timestamptz,
  p_environment text,
  p_signed timestamptz
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_owner uuid;
  v_user uuid;
  v_affected uuid;
  v_ent public.entitlements;
begin
  if p_product is null or p_product not in ('de.eloayoubi.kostenkurve.plus.monthly', 'de.eloayoubi.kostenkurve.plus.yearly') then
    raise exception 'plus_unknown_product' using errcode = 'P0063';
  end if;

  select s.user_id into v_owner from public.store_transactions s where s.original_transaction_id = p_original;
  select p.id into v_user from public.profiles p where p.id = p_user;
  v_user := coalesce(v_user, v_owner);
  if v_user is null then
    return jsonb_build_object('plus', false, 'valid_until', null);
  end if;

  -- Meldungen für dieselben Nutzer nacheinander, sonst übersieht die Neuberechnung ein gleichzeitiges Abo.
  perform 1 from public.profiles p where p.id in (v_user, v_owner) order by p.id for no key update;

  insert into public.store_transactions as s
    (original_transaction_id, user_id, product_id, transaction_id, expires_at, revoked_at, environment, signed_at)
  values (p_original, v_user, p_product, p_transaction, p_expires, p_revoked, p_environment, p_signed)
  on conflict (original_transaction_id) do update set
    user_id = excluded.user_id,
    product_id = excluded.product_id,
    transaction_id = excluded.transaction_id,
    expires_at = excluded.expires_at,
    revoked_at = excluded.revoked_at,
    environment = excluded.environment,
    signed_at = excluded.signed_at,
    updated_at = now()
  where excluded.signed_at >= s.signed_at
    and (excluded.expires_at >= s.expires_at or excluded.expires_at is null or s.expires_at is null);

  -- Abo-Stand neu: Plus bis zum spätesten laufenden, nicht erstatteten Abo, sonst free (Zeile bleibt).
  -- Ein aktives Plus aus anderer Quelle (promo, play_store), das mindestens so lange gilt, bleibt stehen.
  for v_affected in select distinct u from unnest(array[v_user, v_owner]) as u where u is not null loop
    insert into public.entitlements as e (user_id, tier, valid_until, source, updated_at)
    select v_affected,
           case when x.until is null then 'free'::public.plan_tier else 'plus'::public.plan_tier end,
           x.until,
           'app_store',
           now()
    from (
      select max(s.expires_at) as until
      from public.store_transactions s
      where s.user_id = v_affected and s.revoked_at is null and s.expires_at > now()
    ) x
    on conflict (user_id) do update set
      tier = excluded.tier,
      valid_until = excluded.valid_until,
      source = excluded.source,
      updated_at = now()
    where not (
      e.source is distinct from 'app_store'
      and e.tier = 'plus'
      and (e.valid_until is null
           or (e.valid_until > now() and e.valid_until >= coalesce(excluded.valid_until, '-infinity'::timestamptz)))
    );
  end loop;

  select * into v_ent from public.entitlements e where e.user_id = v_user;
  return jsonb_build_object(
    'plus', coalesce(v_ent.tier = 'plus' and (v_ent.valid_until is null or v_ent.valid_until > now()), false),
    'valid_until', case when v_ent.tier = 'plus' then v_ent.valid_until end
  );
end $$;

revoke execute on function public.apply_plus_transaction(uuid, text, text, text, timestamptz, timestamptz, text, timestamptz) from public, anon, authenticated;
grant execute on function public.apply_plus_transaction(uuid, text, text, text, timestamptz, timestamptz, text, timestamptz) to service_role;
