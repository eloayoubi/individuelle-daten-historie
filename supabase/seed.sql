-- Beispieldaten für die lokale Entwicklung (`supabase db reset`) und `scripts/test_local.sh`.
-- Läuft nie gegen Produktion (`db push` spielt keinen Seed ein).
--
-- Demo besitzt Strom, Miete & Nebenkosten und Auto. Miete ist mit Anna als editor geteilt,
-- Auto als viewer. Die Ids passen zur App (MockAuthRepository.demoUserId).

insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-000000000001', 'demo@kostenkurve.test'),
  ('00000000-0000-4000-8000-000000000002', 'anna@kostenkurve.test');

-- Profile legt der Trigger an, hier nur die Namen.
update public.profiles set display_name = 'Demo' where id = '00000000-0000-4000-8000-000000000001';
update public.profiles set display_name = 'Anna' where id = '00000000-0000-4000-8000-000000000002';

insert into public.categories (id, owner_id, name, icon, swatch, template_key, sort) values
  ('10000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000001', 'Strom', 'bolt', 'orange', 'strom', 0),
  ('10000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000001', 'Miete & Nebenkosten', 'house', 'brown', 'miete', 1),
  ('10000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000001', 'Auto', 'car', 'green', 'auto', 2);

insert into public.category_members (category_id, user_id, role) values
  ('10000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000002', 'editor'),
  ('10000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000002', 'viewer');

insert into public.trackers (id, category_id, name) values
  ('20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Hauptzähler'),
  ('20000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', 'Wohnung'),
  ('20000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000003', 'Golf');

insert into public.fields (id, tracker_id, name, kind, role, unit, interval_months, sort) values
  ('30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'Zählerstand', 'number', 'meter_reading', 'kWh', 1, 0),
  ('30000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000001', 'Arbeitspreis', 'currency', 'unit_price', '€/kWh', 1, 1),
  ('30000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000001', 'Grundpreis', 'currency', 'recurring_cost', '€/Monat', 1, 2),
  ('30000000-0000-4000-8000-000000000004', '20000000-0000-4000-8000-000000000001', 'Vertragsende', 'date', 'deadline', null, 1, 3),
  ('30000000-0000-4000-8000-000000000005', '20000000-0000-4000-8000-000000000002', 'Kaltmiete', 'currency', 'recurring_cost', '€/Monat', 1, 0),
  ('30000000-0000-4000-8000-000000000006', '20000000-0000-4000-8000-000000000002', 'Nebenkosten-Vorauszahlung', 'currency', 'recurring_cost', '€/Monat', 1, 1),
  ('30000000-0000-4000-8000-000000000007', '20000000-0000-4000-8000-000000000002', 'Nachzahlung / Guthaben', 'currency', 'one_off_cost', '€', 1, 2),
  ('30000000-0000-4000-8000-000000000008', '20000000-0000-4000-8000-000000000003', 'Kilometerstand', 'number', 'meter_reading', 'km', 1, 0),
  ('30000000-0000-4000-8000-000000000009', '20000000-0000-4000-8000-000000000003', 'Tanken', 'currency', 'one_off_cost', '€', 1, 1),
  ('30000000-0000-4000-8000-000000000010', '20000000-0000-4000-8000-000000000003', 'Kfz-Versicherung', 'currency', 'recurring_cost', '€/Jahr', 12, 2);

-- Werte mit Datum: (Tracker, Tag, Notiz, Feld, Zahl, Datum). Ein Eintrag je Tracker und Tag.
create temporary table seed_values (tracker uuid, day date, note text, field uuid, num numeric, dat date) on commit drop;

insert into seed_values values
  -- Strom: Anbieterwechsel im April 2025, Vertragsende März 2027
  ('20000000-0000-4000-8000-000000000001', '2024-01-01', null, '30000000-0000-4000-8000-000000000002', 0.389, null),
  ('20000000-0000-4000-8000-000000000001', '2024-01-01', null, '30000000-0000-4000-8000-000000000003', 14.20, null),
  ('20000000-0000-4000-8000-000000000001', '2025-04-01', 'Wechsel zu Ökostrom Plus', '30000000-0000-4000-8000-000000000002', 0.329, null),
  ('20000000-0000-4000-8000-000000000001', '2025-04-01', 'Wechsel zu Ökostrom Plus', '30000000-0000-4000-8000-000000000003', 11.90, null),
  ('20000000-0000-4000-8000-000000000001', '2025-04-01', 'Wechsel zu Ökostrom Plus', '30000000-0000-4000-8000-000000000004', null, '2027-03-31'),
  -- Miete: Erhöhung Juli 2025, neue Vorauszahlung 2026, zwei Abrechnungen
  ('20000000-0000-4000-8000-000000000002', '2024-01-01', null, '30000000-0000-4000-8000-000000000005', 890, null),
  ('20000000-0000-4000-8000-000000000002', '2024-01-01', null, '30000000-0000-4000-8000-000000000006', 210, null),
  ('20000000-0000-4000-8000-000000000002', '2025-05-20', 'Nebenkostenabrechnung 2024', '30000000-0000-4000-8000-000000000007', 148, null),
  ('20000000-0000-4000-8000-000000000002', '2025-07-01', 'Mieterhöhung nach Mietspiegel', '30000000-0000-4000-8000-000000000005', 920, null),
  ('20000000-0000-4000-8000-000000000002', '2026-01-01', null, '30000000-0000-4000-8000-000000000006', 235, null),
  ('20000000-0000-4000-8000-000000000002', '2026-05-18', 'Nebenkostenabrechnung 2025', '30000000-0000-4000-8000-000000000007', -62, null),
  -- Auto: Versicherung jährlich
  ('20000000-0000-4000-8000-000000000003', '2024-01-01', null, '30000000-0000-4000-8000-000000000010', 612, null),
  ('20000000-0000-4000-8000-000000000003', '2026-01-01', null, '30000000-0000-4000-8000-000000000010', 648, null);

-- Strom: monatlich abgelesen, rund 2.460 kWh im Jahr.
insert into seed_values
select '20000000-0000-4000-8000-000000000001', d::date, null, '30000000-0000-4000-8000-000000000001', 41230 + (row_number() over (order by d) - 1) * 205, null
from generate_series('2024-01-12'::date, '2026-09-12'::date, interval '1 month') d;

-- Auto: alle drei Wochen getankt, Kilometerstand im selben Eintrag.
insert into seed_values
select '20000000-0000-4000-8000-000000000003', d::date, null, f.field, case f.field
    when '30000000-0000-4000-8000-000000000008' then 48200 + (row_number() over (partition by f.field order by d) - 1) * 690
    else 58 + ((row_number() over (partition by f.field order by d) - 1) % 5) * 3.4
  end, null
from generate_series('2024-01-05'::date, '2026-10-09'::date, interval '21 days') d,
  (values ('30000000-0000-4000-8000-000000000008'::uuid), ('30000000-0000-4000-8000-000000000009'::uuid)) as f (field);

insert into public.entries (tracker_id, occurred_on, note, created_by)
select tracker, day, max(note), '00000000-0000-4000-8000-000000000001' from seed_values group by tracker, day;

insert into public.entry_values (entry_id, field_id, num, dat)
select e.id, v.field, v.num, v.dat
from seed_values v join public.entries e on e.tracker_id = v.tracker and e.occurred_on = v.day;
