-- Belege (Fotos, PDFs) an Einträgen – nur mit „Kostenkurve Plus“, weil Dateien die meisten
-- Server-Kosten verursachen. Hochladen braucht Plus beim Hochladenden; Mitglieder einer geteilten
-- Kategorie sehen die Belege auch ohne eigenes Abo.

-- Abo-Stand je Nutzer. Schreiben nur mit Service-Role (Edge Function nach Kaufprüfung).
create table public.entitlements (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  tier public.plan_tier not null default 'free',
  valid_until timestamptz,
  -- app_store, play_store oder promo
  source text check (source ~ '^[a-z_]{1,20}$'),
  updated_at timestamptz not null default now()
);

alter table public.entitlements enable row level security;

create policy entitlements_select on public.entitlements for select to authenticated using (user_id = auth.uid());

create function public.has_plus() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.entitlements e
    where e.user_id = auth.uid() and e.tier = 'plus' and (e.valid_until is null or e.valid_until > now())
  )
$$;

create table public.attachments (
  id uuid primary key default gen_random_uuid(),
  entry_id uuid not null references public.entries (id) on delete cascade,
  -- Pfad im Bucket „attachments“: <category_id>/<entry_id>/<datei>
  storage_path text not null unique check (storage_path ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}/[A-Za-z0-9._-]{1,80}$'),
  mime_type text not null check (mime_type in ('image/jpeg', 'image/png', 'image/heic', 'application/pdf')),
  size_bytes integer not null check (size_bytes between 1 and 20971520),
  created_by uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now()
);

create index attachments_entry_idx on public.attachments (entry_id);

alter table public.attachments enable row level security;

create policy attachments_select on public.attachments for select to authenticated using (public.is_category_member(public.entry_category(entry_id)));
create policy attachments_insert on public.attachments for insert to authenticated with check (
  created_by = auth.uid() and public.has_plus() and public.can_edit_category(public.entry_category(entry_id))
);
create policy attachments_delete on public.attachments for delete to authenticated using (
  created_by = auth.uid() or public.is_category_owner(public.entry_category(entry_id))
);

-- Erster Ordner des Pfads als uuid, ungültige Pfade ergeben null statt eines Fehlers.
create function public.path_category(p_name text) returns uuid
language plpgsql immutable set search_path = '' as $$
begin
  return split_part(p_name, '/', 1)::uuid;
exception when invalid_text_representation then
  return null;
end $$;

-- Privater Bucket, 20 MB je Datei.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('attachments', 'attachments', false, 20971520, array['image/jpeg', 'image/png', 'image/heic', 'application/pdf'])
on conflict (id) do nothing;

create policy attachments_files_select on storage.objects for select to authenticated using (
  bucket_id = 'attachments' and public.is_category_member(public.path_category(name))
);
create policy attachments_files_insert on storage.objects for insert to authenticated with check (
  bucket_id = 'attachments' and public.has_plus() and public.can_edit_category(public.path_category(name))
);
create policy attachments_files_delete on storage.objects for delete to authenticated using (
  bucket_id = 'attachments' and public.can_edit_category(public.path_category(name))
);
