-- Kern: Profile, Kategorien, Mitglieder, Tracker, Felder, Einträge, Werte – alles mit RLS.
--
-- Sichtbarkeit hängt an der Kategorie: Wer Mitglied ist (owner/editor/viewer), sieht die Kategorie
-- mit allem darunter. owner und editor dürfen schreiben, nur owner teilt und löscht.

-- ---------------------------------------------------------------------------------------------
-- Hilfsfunktionen
-- ---------------------------------------------------------------------------------------------

create function public.set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

-- ---------------------------------------------------------------------------------------------
-- Profile (ein Eintrag je Auth-Nutzer, auch anonyme)
-- ---------------------------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default '' check (char_length(display_name) <= 60),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id) values (new.id) on conflict (id) do nothing;
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------------------------
-- Kategorien und Mitglieder
-- ---------------------------------------------------------------------------------------------

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 60),
  -- Schlüssel aus der App (CategoryIcon/CategorySwatch), bewusst Text: neue Symbole ohne Migration.
  icon text not null default 'star' check (icon ~ '^[a-z]{1,20}$'),
  swatch text not null default 'indigo' check (swatch ~ '^[a-z]{1,20}$'),
  -- Aus welcher Vorlage die Kategorie entstand (strom, miete, …), null bei eigenen.
  template_key text check (template_key ~ '^[a-z_]{1,40}$'),
  sort integer not null default 0,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index categories_owner_idx on public.categories (owner_id);

create trigger categories_updated_at before update on public.categories
  for each row execute function public.set_updated_at();

create table public.category_members (
  category_id uuid not null references public.categories (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role public.member_role not null default 'viewer',
  created_at timestamptz not null default now(),
  primary key (category_id, user_id)
);

create index category_members_user_idx on public.category_members (user_id);

-- Wer eine Kategorie anlegt, ist ihr owner.
create function public.add_category_owner() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.category_members (category_id, user_id, role) values (new.id, new.owner_id, 'owner');
  return new;
end $$;

create trigger categories_add_owner
  after insert on public.categories
  for each row execute function public.add_category_owner();

-- Rolle des angemeldeten Nutzers in einer Kategorie (null = kein Mitglied).
-- security definer, damit die Policies auf category_members nicht rekursiv werden.
create function public.category_role(p_category uuid) returns public.member_role
language sql stable security definer set search_path = '' as $$
  select m.role from public.category_members m where m.category_id = p_category and m.user_id = auth.uid()
$$;

create function public.is_category_member(p_category uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select public.category_role(p_category) is not null
$$;

create function public.can_edit_category(p_category uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce(public.category_role(p_category) in ('owner', 'editor'), false)
$$;

create function public.is_category_owner(p_category uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce(public.category_role(p_category) = 'owner', false)
$$;

-- ---------------------------------------------------------------------------------------------
-- Tracker, Felder, Einträge, Werte
-- ---------------------------------------------------------------------------------------------

create table public.trackers (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.categories (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 60),
  sort integer not null default 0,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index trackers_category_idx on public.trackers (category_id);

create trigger trackers_updated_at before update on public.trackers
  for each row execute function public.set_updated_at();

create table public.fields (
  id uuid primary key default gen_random_uuid(),
  tracker_id uuid not null references public.trackers (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 60),
  kind public.field_kind not null,
  role public.field_role not null default 'info',
  unit text check (char_length(unit) <= 20),
  consumption_unit text check (char_length(consumption_unit) <= 20),
  -- Zählerstand → Verbrauch (Gas: Brennwert × Zustandszahl).
  factor numeric not null default 1 check (factor > 0),
  -- Wiederkehrende Beträge: alle wie viele Monate fällig.
  interval_months smallint not null default 1 check (interval_months between 1 and 120),
  choices text[] not null default '{}',
  formula text check (char_length(formula) <= 500),
  sort integer not null default 0,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  constraint fields_formula_needs_kind check ((kind = 'formula') = (formula is not null)),
  -- Welche Feldtypen zu welchem Zeitverhalten passen.
  constraint fields_role_fits_kind check (
    case role
      when 'meter_reading' then kind = 'number'
      when 'unit_price' then kind in ('currency', 'formula')
      when 'recurring_cost' then kind in ('currency', 'formula')
      when 'one_off_cost' then kind in ('currency', 'formula')
      when 'deadline' then kind = 'date'
      when 'snapshot' then kind in ('number', 'currency', 'percent', 'formula')
      else true
    end
  )
);

create index fields_tracker_idx on public.fields (tracker_id);

create table public.entries (
  id uuid primary key default gen_random_uuid(),
  tracker_id uuid not null references public.trackers (id) on delete cascade,
  occurred_on date not null,
  -- Abrechnungszeitraum, z. B. bei der Nebenkostenabrechnung.
  period_start date,
  period_end date,
  note text check (char_length(note) <= 1000),
  -- Neuer Zähler ab diesem Eintrag.
  meter_change boolean not null default false,
  created_by uuid default auth.uid() references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint entries_period_order check (period_start is null or period_end is null or period_end >= period_start)
);

create index entries_tracker_date_idx on public.entries (tracker_id, occurred_on);

create trigger entries_updated_at before update on public.entries
  for each row execute function public.set_updated_at();

-- Typisierte Werte (genau eine Spalte gesetzt) – so lassen sich Verläufe direkt abfragen.
create table public.entry_values (
  entry_id uuid not null references public.entries (id) on delete cascade,
  field_id uuid not null references public.fields (id) on delete cascade,
  num numeric,
  txt text check (char_length(txt) <= 500),
  dat date,
  flag boolean,
  primary key (entry_id, field_id),
  constraint entry_values_one_value check (num_nonnulls(num, txt, dat, flag) = 1)
);

create index entry_values_field_idx on public.entry_values (field_id);

-- Feld und Eintrag gehören zum selben Tracker, und die Wertspalte passt zum Feldtyp.
create function public.check_entry_value() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_kind public.field_kind;
  v_field_tracker uuid;
  v_entry_tracker uuid;
  v_fits boolean;
begin
  select f.kind, f.tracker_id into v_kind, v_field_tracker from public.fields f where f.id = new.field_id;
  select e.tracker_id into v_entry_tracker from public.entries e where e.id = new.entry_id;
  if v_field_tracker is distinct from v_entry_tracker then
    raise exception 'Feld % gehört nicht zum Tracker des Eintrags', new.field_id using errcode = 'check_violation';
  end if;
  -- Als Zuweisung, weil plpgsql ein CASE direkt im IF am ersten THEN abschneidet.
  v_fits := case v_kind
    when 'number' then new.num is not null
    when 'currency' then new.num is not null
    when 'percent' then new.num is not null
    when 'text' then new.txt is not null
    when 'choice' then new.txt is not null
    when 'date' then new.dat is not null
    when 'toggle' then new.flag is not null
    else false -- Formeln werden berechnet, nicht gespeichert.
  end;
  if not v_fits then
    raise exception 'Wert passt nicht zum Feldtyp %', v_kind using errcode = 'check_violation';
  end if;
  return new;
end $$;

create trigger entry_values_check
  before insert or update on public.entry_values
  for each row execute function public.check_entry_value();

-- Kategorie eines Trackers bzw. Eintrags (für die Policies).
create function public.tracker_category(p_tracker uuid) returns uuid
language sql stable security definer set search_path = '' as $$
  select t.category_id from public.trackers t where t.id = p_tracker
$$;

create function public.entry_category(p_entry uuid) returns uuid
language sql stable security definer set search_path = '' as $$
  select t.category_id from public.entries e join public.trackers t on t.id = e.tracker_id where e.id = p_entry
$$;

-- ---------------------------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------------------------

alter table public.categories enable row level security;
alter table public.category_members enable row level security;
alter table public.trackers enable row level security;
alter table public.fields enable row level security;
alter table public.entries enable row level security;
alter table public.entry_values enable row level security;

-- Profile: das eigene und die der Mitglieder gemeinsamer Kategorien (für „Geteilt mit Anna“).
create policy profiles_select on public.profiles for select to authenticated using (
  id = auth.uid()
  or exists (
    select 1
    from public.category_members mine
    join public.category_members theirs on theirs.category_id = mine.category_id
    where mine.user_id = auth.uid() and theirs.user_id = profiles.id
  )
);
create policy profiles_update on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- owner_id zusätzlich: Beim Anlegen (insert … returning) legt der Trigger die Mitgliedschaft erst danach an.
create policy categories_select on public.categories for select to authenticated using (owner_id = auth.uid() or public.is_category_member(id));
create policy categories_insert on public.categories for insert to authenticated with check (owner_id = auth.uid());
create policy categories_update on public.categories for update to authenticated
  using (public.can_edit_category(id)) with check (public.can_edit_category(id));
create policy categories_delete on public.categories for delete to authenticated using (public.is_category_owner(id));

-- Mitglieder: sichtbar für alle Mitglieder; owner ändert Rollen und entfernt, jeder darf selbst gehen.
-- Neue Mitglieder kommen nur über den Trigger (owner) oder accept_category_invite().
create policy members_select on public.category_members for select to authenticated using (public.is_category_member(category_id));
create policy members_update on public.category_members for update to authenticated
  using (public.is_category_owner(category_id) and user_id <> auth.uid())
  with check (public.is_category_owner(category_id) and role <> 'owner');
create policy members_delete on public.category_members for delete to authenticated using (
  role <> 'owner' and (user_id = auth.uid() or public.is_category_owner(category_id))
);

create policy trackers_select on public.trackers for select to authenticated using (public.is_category_member(category_id));
create policy trackers_write on public.trackers for all to authenticated
  using (public.can_edit_category(category_id)) with check (public.can_edit_category(category_id));

create policy fields_select on public.fields for select to authenticated using (public.is_category_member(public.tracker_category(tracker_id)));
create policy fields_write on public.fields for all to authenticated
  using (public.can_edit_category(public.tracker_category(tracker_id)))
  with check (public.can_edit_category(public.tracker_category(tracker_id)));

create policy entries_select on public.entries for select to authenticated using (public.is_category_member(public.tracker_category(tracker_id)));
create policy entries_write on public.entries for all to authenticated
  using (public.can_edit_category(public.tracker_category(tracker_id)))
  with check (public.can_edit_category(public.tracker_category(tracker_id)));

create policy entry_values_select on public.entry_values for select to authenticated using (public.is_category_member(public.entry_category(entry_id)));
create policy entry_values_write on public.entry_values for all to authenticated
  using (public.can_edit_category(public.entry_category(entry_id)))
  with check (public.can_edit_category(public.entry_category(entry_id)));
