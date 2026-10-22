-- Smoke-Test über Seed-Daten: RLS je Rolle, Teilen per Einladung, Wertprüfung, Belege nur mit Plus.
-- Läuft in einer Transaktion und rollt am Ende zurück. Nutzer wechseln über die JWT-Claim-Einstellung
-- (`set local request.jwt.claim.sub`), die auth.uid() liest – wie in Supabase.
--
-- Nutzer: Demo (…001, owner), Anna (…002, editor bei Miete, viewer bei Auto), Fremd (…003).

begin;

insert into auth.users (id, email) values ('00000000-0000-4000-8000-000000000003', 'fremd@kostenkurve.test');

set local role authenticated;

-- ---------------------------------------------------------------------------------------------
-- Demo: sieht alles Eigene, legt an, Werte werden geprüft
-- ---------------------------------------------------------------------------------------------
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000001';

do $$
declare
  v_category uuid;
  v_entry uuid;
begin
  assert (select count(*) from public.categories) = 3, 'Demo sieht ihre drei Kategorien';
  assert (select count(*) from public.entries) > 50, 'Demo sieht ihre Einträge';
  assert (select count(*) from public.profiles) = 2, 'Demo sieht sich und Anna';

  insert into public.categories (name, icon, swatch) values ('Wasser', 'drop', 'blue') returning id into v_category;
  assert public.category_role(v_category) = 'owner', 'Wer anlegt, ist owner';

  insert into public.entries (tracker_id, occurred_on) values ('20000000-0000-4000-8000-000000000001', '2026-10-20') returning id into v_entry;
  insert into public.entry_values (entry_id, field_id, num) values (v_entry, '30000000-0000-4000-8000-000000000001', 47100);

  begin
    insert into public.entry_values (entry_id, field_id, txt) values (v_entry, '30000000-0000-4000-8000-000000000002', 'falsch');
    raise exception 'Text in einem Betragsfeld wurde angenommen';
  exception when check_violation then null;
  end;

  begin
    insert into public.entry_values (entry_id, field_id, num) values (v_entry, '30000000-0000-4000-8000-000000000005', 1);
    raise exception 'Feld eines anderen Trackers wurde angenommen';
  exception when check_violation then null;
  end;

  begin
    insert into public.fields (tracker_id, name, kind, role) values ('20000000-0000-4000-8000-000000000001', 'Kaputt', 'text', 'meter_reading');
    raise exception 'Zählerstand als Textfeld wurde angenommen';
  exception when check_violation then null;
  end;
end $$;

-- ---------------------------------------------------------------------------------------------
-- Anna: editor bei Miete, viewer bei Auto, Strom unsichtbar
-- ---------------------------------------------------------------------------------------------
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000002';

do $$
begin
  assert (select count(*) from public.categories) = 2, 'Anna sieht nur die beiden geteilten Kategorien';
  assert not exists (select 1 from public.trackers where id = '20000000-0000-4000-8000-000000000001'), 'Strom ist nicht geteilt';
  assert (select display_name from public.profiles where id = '00000000-0000-4000-8000-000000000001') = 'Demo', 'Anna sieht, wer teilt';

  insert into public.entries (tracker_id, occurred_on) values ('20000000-0000-4000-8000-000000000002', '2026-10-01');

  begin
    insert into public.entries (tracker_id, occurred_on) values ('20000000-0000-4000-8000-000000000003', '2026-10-01');
    raise exception 'viewer durfte schreiben';
  exception when insufficient_privilege then null;
  end;

  delete from public.categories where id = '10000000-0000-4000-8000-000000000002';
  assert not found, 'editor durfte die Kategorie löschen';

  begin
    perform public.create_category_invite('10000000-0000-4000-8000-000000000002');
    raise exception 'editor durfte einladen';
  exception when insufficient_privilege then null;
  end;
end $$;

-- ---------------------------------------------------------------------------------------------
-- Fremd: sieht nichts
-- ---------------------------------------------------------------------------------------------
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000003';

do $$
begin
  assert (select count(*) from public.categories) = 0, 'Fremde sehen keine Kategorien';
  assert (select count(*) from public.entries) = 0, 'Fremde sehen keine Einträge';
  assert (select count(*) from public.entry_values) = 0, 'Fremde sehen keine Werte';
  assert (select count(*) from public.profiles) = 1, 'Fremde sehen nur sich selbst';

  update public.categories set name = 'Gekapert' where id = '10000000-0000-4000-8000-000000000001';
  assert not found, 'Fremde durften umbenennen';
end $$;

-- ---------------------------------------------------------------------------------------------
-- Teilen: Demo lädt als viewer ein, Fremd löst ein und verlässt die Kategorie wieder
-- ---------------------------------------------------------------------------------------------
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000001';
do $$ begin perform set_config('test.invite', public.create_category_invite('10000000-0000-4000-8000-000000000001', 'viewer'), true); end $$;

set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000003';

do $$
begin
  assert public.accept_category_invite(lower(current_setting('test.invite'))) = '10000000-0000-4000-8000-000000000001', 'Code eingelöst (Groß-/Kleinschreibung egal)';
  assert (select count(*) from public.categories) = 1, 'Strom ist jetzt sichtbar';
  assert public.category_role('10000000-0000-4000-8000-000000000001') = 'viewer', 'als viewer';

  begin
    perform public.accept_category_invite(current_setting('test.invite'));
    raise exception 'Code ließ sich zweimal einlösen';
  exception when no_data_found then null;
  end;

  delete from public.category_members where category_id = '10000000-0000-4000-8000-000000000001' and user_id = auth.uid();
  assert found, 'Mitglieder können eine Kategorie verlassen';
  assert (select count(*) from public.categories) = 0, 'Nach dem Verlassen wieder unsichtbar';
end $$;

-- ---------------------------------------------------------------------------------------------
-- Belege: nur mit Plus, Plus vergibt nur der Server
-- ---------------------------------------------------------------------------------------------
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000001';

do $$
declare
  v_entry uuid := (select id from public.entries where tracker_id = '20000000-0000-4000-8000-000000000001' order by occurred_on desc limit 1);
begin
  begin
    insert into public.attachments (entry_id, storage_path, mime_type, size_bytes)
      values (v_entry, '10000000-0000-4000-8000-000000000001/' || v_entry || '/zaehler.jpg', 'image/jpeg', 1200);
    raise exception 'Beleg ohne Plus angenommen';
  exception when insufficient_privilege then null;
  end;

  begin
    insert into public.entitlements (user_id, tier) values (auth.uid(), 'plus');
    raise exception 'Nutzer konnte sich Plus selbst geben';
  exception when insufficient_privilege then null;
  end;
end $$;

-- Wie die Edge Function nach einer Kaufprüfung (Service-Role, ohne RLS).
reset role;
insert into public.entitlements (user_id, tier, source) values ('00000000-0000-4000-8000-000000000001', 'plus', 'promo');
grant usage on schema storage to authenticated;
grant select, insert, delete on storage.objects to authenticated;
set local role authenticated;

do $$
declare
  v_entry uuid := (select id from public.entries where tracker_id = '20000000-0000-4000-8000-000000000001' order by occurred_on desc limit 1);
begin
  assert public.has_plus(), 'Demo hat jetzt Plus';
  insert into public.attachments (entry_id, storage_path, mime_type, size_bytes)
    values (v_entry, '10000000-0000-4000-8000-000000000001/' || v_entry || '/zaehler.jpg', 'image/jpeg', 1200);
  assert (select count(*) from public.attachments) = 1, 'Beleg mit Plus gespeichert';

  insert into storage.objects (bucket_id, name) values ('attachments', '10000000-0000-4000-8000-000000000001/' || v_entry || '/zaehler.jpg');
  begin
    insert into storage.objects (bucket_id, name) values ('attachments', 'kein-ordner/zaehler.jpg');
    raise exception 'Datei außerhalb einer Kategorie angenommen';
  exception when insufficient_privilege then null;
  end;
end $$;

-- Anna sieht Belege geteilter Kategorien ohne eigenes Abo, aber nicht die aus Strom.
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000002';

do $$
begin
  assert not public.has_plus(), 'Anna hat kein Plus';
  assert (select count(*) from public.attachments) = 0, 'Strom-Belege bleiben privat';
end $$;

rollback;
