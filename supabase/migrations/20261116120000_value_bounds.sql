-- Security-Audit 14.11.2026: Werte, an denen die App beim Laden scheitert.
--
-- Postgres nimmt in numeric 'NaN' und 'Infinity', in date und timestamptz 'infinity' und Daten vor
-- Christus an. PostgREST liefert sie als Text ("NaN", "infinity", "0044-03-15 BC"), die App erwartet
-- Zahl bzw. ISO-Datum – das Laden der Kategorien scheitert dann für jedes Mitglied. Ein editor konnte so
-- eine geteilte Kategorie für alle unbenutzbar machen ('NaN' > 0 ist in Postgres wahr, der bisherige
-- Check auf factor ließ es durch). Dazu: Auswahl-Optionen ohne Grenze.
--
-- Grenzen großzügig über dem, was die App eingeben lässt (Zahlen 24 Zeichen, Daten ab 2000, Optionen
-- 40 Zeichen). Bestehende Daten in Produktion liegen alle darin (geprüft vor dem Einspielen).

-- abs() < 1e18 schließt NaN (größer als jede Zahl) und ±Infinity mit aus.
alter table public.entry_values add constraint entry_values_num_finite check (abs(num) < 1e18);
alter table public.fields add constraint fields_factor_finite check (factor < 1e9);

alter table public.entries add constraint entries_dates_in_range check (
  occurred_on between '1900-01-01' and '2199-12-31'
  and (period_start is null or period_start between '1900-01-01' and '2199-12-31')
  and (period_end is null or period_end between '1900-01-01' and '2199-12-31')
);
alter table public.entry_values add constraint entry_values_dat_in_range check (dat between '1900-01-01' and '2199-12-31');
alter table public.categories add constraint categories_archived_at_in_range
  check (archived_at between '2000-01-01' and '2200-01-01');
-- created_at kann der Client beim Anlegen eines Belegs mitschicken; die App liest es.
alter table public.attachments add constraint attachments_created_at_in_range
  check (created_at between '2000-01-01' and '2200-01-01');

-- Höchstens 50 Optionen mit je 1 bis 60 Zeichen.
create function public.choices_fit(p_choices text[]) returns boolean
language sql immutable set search_path = '' as $$
  select cardinality(p_choices) <= 50
    and not exists (select 1 from unnest(p_choices) c where c is null or char_length(c) not between 1 and 60)
$$;

alter table public.fields add constraint fields_choices_fit check (public.choices_fit(choices));

-- Supabase-Linter (function_search_path_mutable): einzige Funktion ohne festen search_path.
alter function public.set_updated_at() set search_path = '';
