-- Fehlversuche beim Einlösen von Einladungscodes und Übergabe geteilter Kategorien, wenn der
-- Eigentümer sein Konto löscht. Eigene Transaktion, rollt am Ende zurück. Nutzer: Demo (…001, owner
-- von Strom, Miete, Auto), Anna (…002, editor bei Miete, viewer bei Auto), Ben (…009, neu).

begin;

insert into auth.users (id, email) values ('00000000-0000-4000-8000-000000000009', 'ben@kostenkurve.test');

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000001';
do $$ begin perform set_config('test.invite', public.create_category_invite('10000000-0000-4000-8000-000000000001', 'viewer'), true); end $$;

-- Ben rät: ungültige Codes liefern null, ab dem zehnten Fehlversuch ist für eine Stunde Schluss –
-- auch für einen gültigen Code.
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000009';

do $$
begin
  for i in 1..10 loop
    assert public.accept_category_invite('FALSCH' || i) is null, 'ungültiger Code liefert null';
  end loop;

  begin
    perform public.accept_category_invite(current_setting('test.invite'));
    raise exception 'elfter Versuch nicht gesperrt';
  exception when sqlstate 'P0065' then null;
  end;

  begin
    perform count(*) from public.invite_attempts;
    raise exception 'Fehlversuche für Clients lesbar';
  exception when insufficient_privilege then null;
  end;
end $$;

-- Eine Stunde später: wieder frei, ein Treffer setzt den Zähler zurück.
reset role;
update public.invite_attempts set window_start = now() - interval '61 minutes';
set local role authenticated;

do $$
begin
  assert public.accept_category_invite('NOCHFALSCH') is null, 'neues Fenster, Fehlversuch zählt neu';
  assert public.accept_category_invite(current_setting('test.invite')) = '10000000-0000-4000-8000-000000000001', 'gültiger Code nach Ablauf der Sperre';
end $$;

reset role;
do $$
begin
  assert not exists (select 1 from public.invite_attempts where user_id = '00000000-0000-4000-8000-000000000009'), 'Treffer setzt zurück';
end $$;

-- Übergabe: Ben wird editor bei Auto (später beigetreten als Anna, aber editor vor viewer).
insert into public.category_members (category_id, user_id, role)
  values ('10000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000009', 'editor');
-- Ben ist viewer bei Strom (Einladung oben): Strom geht an ihn.

-- Demo löscht das Konto (delete-account: Service-Role, kein Nutzer-JWT).
set local request.jwt.claim.sub = '';
delete from auth.users where id = '00000000-0000-4000-8000-000000000001';

do $$
begin
  assert (select owner_id from public.categories where id = '10000000-0000-4000-8000-000000000002') = '00000000-0000-4000-8000-000000000002',
    'Miete geht an Anna (einziges weiteres Mitglied)';
  assert (select owner_id from public.categories where id = '10000000-0000-4000-8000-000000000003') = '00000000-0000-4000-8000-000000000009',
    'Auto geht an Ben (editor vor viewer)';
  assert (select owner_id from public.categories where id = '10000000-0000-4000-8000-000000000001') = '00000000-0000-4000-8000-000000000009',
    'Strom geht an Ben (einziges weiteres Mitglied)';
  assert (select role from public.category_members where category_id = '10000000-0000-4000-8000-000000000003'
    and user_id = '00000000-0000-4000-8000-000000000009') = 'owner', 'Erbe ist owner';
  assert (select role from public.category_members where category_id = '10000000-0000-4000-8000-000000000003'
    and user_id = '00000000-0000-4000-8000-000000000002') = 'viewer', 'Anna bleibt viewer';
  assert not exists (select 1 from public.category_members where user_id = '00000000-0000-4000-8000-000000000001'), 'Demo ist überall raus';
  assert exists (select 1 from public.trackers where category_id = '10000000-0000-4000-8000-000000000002'), 'Daten bleiben';
  assert exists (select 1 from public.change_marks where user_id = '00000000-0000-4000-8000-000000000009'), 'Erbe bekommt eine Marke';
end $$;

-- Nicht geteilte Kategorie verschwindet weiterhin mit dem Konto.
insert into public.categories (id, owner_id, name) values ('10000000-0000-4000-8000-000000000099', '00000000-0000-4000-8000-000000000002', 'Privat');
delete from auth.users where id = '00000000-0000-4000-8000-000000000002';

do $$
begin
  assert not exists (select 1 from public.categories where id = '10000000-0000-4000-8000-000000000099'), 'nicht geteilte Kategorie gelöscht';
  assert not exists (select 1 from public.categories where id = '10000000-0000-4000-8000-000000000002'), 'Miete ohne weitere Mitglieder gelöscht';
  assert (select role from public.category_members where category_id = '10000000-0000-4000-8000-000000000003'
    and user_id = '00000000-0000-4000-8000-000000000009') = 'owner', 'Auto bleibt bei Ben';
end $$;

rollback;
