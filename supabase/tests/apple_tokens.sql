-- Sign in with Apple: apple_tokens gehört allein der Service-Role (Edge Functions apple-token und
-- delete-account). Eigene Transaktion, rollt am Ende zurück. Nutzer: Demo (…001), Fremd (…003, nur hier
-- angelegt).

begin;

insert into auth.users (id, email) values ('00000000-0000-4000-8000-000000000003', 'fremd@kostenkurve.test');

do $$
begin
  assert (select relrowsecurity from pg_class where oid = 'public.apple_tokens'::regclass), 'RLS ist an';
  assert not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'apple_tokens'), 'Keine Policies';
end $$;

-- ---------------------------------------------------------------------------------------------
-- Service-Role: speichert, liest und ersetzt Tokens (wie apple-token per Upsert)
-- ---------------------------------------------------------------------------------------------
set local role service_role;

do $$
begin
  insert into public.apple_tokens (user_id, refresh_token) values
    ('00000000-0000-4000-8000-000000000001', 'test-refresh-demo'),
    ('00000000-0000-4000-8000-000000000003', 'test-refresh-fremd');
  insert into public.apple_tokens (user_id, refresh_token) values ('00000000-0000-4000-8000-000000000001', 'test-refresh-demo-2')
    on conflict (user_id) do update set refresh_token = excluded.refresh_token;
  assert (select refresh_token from public.apple_tokens where user_id = '00000000-0000-4000-8000-000000000001') = 'test-refresh-demo-2', 'Upsert ersetzt das Token';
  assert (select count(*) from public.apple_tokens) = 2, 'Service-Role sieht alle Tokens';
  assert has_table_privilege('service_role', 'public.apple_tokens', 'delete'), 'Service-Role darf löschen';
end $$;

-- ---------------------------------------------------------------------------------------------
-- Angemeldet und anonym: kein Zugriff, auch nicht auf das eigene Token
-- ---------------------------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000001';

do $$
begin
  begin
    perform 1 from public.apple_tokens where user_id = auth.uid();
    raise exception 'authenticated konnte sein Token lesen';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.apple_tokens (user_id, refresh_token) values (auth.uid(), 'test-fremdes-token');
    raise exception 'authenticated konnte ein Token schreiben';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.apple_tokens set refresh_token = 'test-fremdes-token' where user_id = auth.uid();
    raise exception 'authenticated konnte sein Token ändern';
  exception when insufficient_privilege then null;
  end;
  begin
    delete from public.apple_tokens where user_id = auth.uid();
    raise exception 'authenticated konnte sein Token löschen';
  exception when insufficient_privilege then null;
  end;
end $$;

set local role anon;

do $$
begin
  begin
    perform 1 from public.apple_tokens;
    raise exception 'anon konnte Tokens lesen';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.apple_tokens (user_id, refresh_token) values ('00000000-0000-4000-8000-000000000001', 'test-fremdes-token');
    raise exception 'anon konnte ein Token schreiben';
  exception when insufficient_privilege then null;
  end;
  begin
    delete from public.apple_tokens;
    raise exception 'anon konnte Tokens löschen';
  exception when insufficient_privilege then null;
  end;
end $$;

-- ---------------------------------------------------------------------------------------------
-- Konto gelöscht (wie auth.admin.deleteUser): Das Token fällt mit dem Profil weg
-- ---------------------------------------------------------------------------------------------
reset role;
delete from auth.users where id = '00000000-0000-4000-8000-000000000003';

do $$
begin
  assert not exists (select 1 from public.apple_tokens where user_id = '00000000-0000-4000-8000-000000000003'), 'Token mit dem Konto gelöscht';
  assert (select refresh_token from public.apple_tokens where user_id = '00000000-0000-4000-8000-000000000001') = 'test-refresh-demo-2', 'Andere Tokens bleiben';
end $$;

rollback;
