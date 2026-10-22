-- Teilen pro Kategorie: Der owner erzeugt einen Einladungscode (Link/QR), die andere Person löst
-- ihn ein und wird editor oder viewer. Codes gelten 7 Tage und nur einmal.

create table public.category_invites (
  -- 10 Hex-Zeichen aus gen_random_uuid() (kryptografischer Zufall, ohne pgcrypto).
  code text primary key default upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10)),
  category_id uuid not null references public.categories (id) on delete cascade,
  role public.member_role not null default 'editor' check (role <> 'owner'),
  created_by uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  expires_at timestamptz not null default now() + interval '7 days',
  accepted_by uuid references public.profiles (id) on delete set null,
  accepted_at timestamptz,
  created_at timestamptz not null default now()
);

create index category_invites_category_idx on public.category_invites (category_id);

alter table public.category_invites enable row level security;

-- Nur der owner sieht und widerruft offene Einladungen; angelegt wird per RPC.
create policy invites_select on public.category_invites for select to authenticated using (public.is_category_owner(category_id));
create policy invites_delete on public.category_invites for delete to authenticated using (public.is_category_owner(category_id));

create function public.create_category_invite(p_category uuid, p_role public.member_role default 'editor') returns text
language plpgsql security definer set search_path = '' as $$
declare
  v_code text;
begin
  if not public.is_category_owner(p_category) then
    raise exception 'Nur der Eigentümer kann die Kategorie teilen' using errcode = 'insufficient_privilege';
  end if;
  if p_role = 'owner' then
    raise exception 'Einladungen vergeben nur editor oder viewer' using errcode = 'check_violation';
  end if;
  insert into public.category_invites (category_id, role, created_by)
    values (p_category, p_role, auth.uid())
    returning code into v_code;
  return v_code;
end $$;

-- Löst einen Code ein und gibt die Kategorie zurück. Schon Mitglied: bleibt bei der bisherigen Rolle.
create function public.accept_category_invite(p_code text) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_invite public.category_invites;
begin
  if auth.uid() is null then
    raise exception 'Nicht angemeldet' using errcode = 'insufficient_privilege';
  end if;
  select * into v_invite from public.category_invites i where i.code = upper(trim(p_code)) for update;
  if not found or v_invite.accepted_at is not null or v_invite.expires_at < now() then
    raise exception 'Einladung ungültig oder abgelaufen' using errcode = 'no_data_found';
  end if;
  insert into public.category_members (category_id, user_id, role)
    values (v_invite.category_id, auth.uid(), v_invite.role)
    on conflict (category_id, user_id) do nothing;
  update public.category_invites set accepted_by = auth.uid(), accepted_at = now() where code = v_invite.code;
  return v_invite.category_id;
end $$;

revoke execute on function public.create_category_invite(uuid, public.member_role) from anon;
revoke execute on function public.accept_category_invite(text) from anon;
