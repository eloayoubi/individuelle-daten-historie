-- Meilenstein 3: Abschläge und „Kosten enthalten in“.

-- Abschläge sind Beträge (oder Formeln) – wie wiederkehrende Kosten, zählen aber nicht als Kosten.
alter table public.fields drop constraint fields_role_fits_kind;
alter table public.fields add constraint fields_role_fits_kind check (
  case role
    when 'meter_reading' then kind = 'number'
    when 'unit_price' then kind in ('currency', 'formula')
    when 'recurring_cost' then kind in ('currency', 'formula')
    when 'one_off_cost' then kind in ('currency', 'formula')
    when 'instalment' then kind in ('currency', 'formula')
    when 'deadline' then kind = 'date'
    when 'snapshot' then kind in ('number', 'currency', 'percent', 'formula')
    else true
  end
);

-- Kosten eines Trackers, die schon in einer anderen Kategorie stecken (Wasser in den Nebenkosten):
-- Die App zeigt sie, zählt sie aber in keiner Summe. Fällt die Kategorie weg, zählen sie wieder.
alter table public.trackers add column included_in uuid references public.categories (id) on delete set null;
alter table public.trackers add constraint trackers_included_elsewhere check (included_in is distinct from category_id);
