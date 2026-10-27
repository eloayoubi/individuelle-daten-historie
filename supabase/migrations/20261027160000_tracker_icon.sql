-- Eigenes Symbol je Tracker (Stremio, Fitnessfirst in den Abos):
--
-- - trackers.icon: Name des Symbols wie categories.icon (`CategoryIcon` in der App); leer = das
--   Symbol der Kategorie. Ändern dürfen owner und editor, wie Name und „Kosten enthalten in“.

alter table public.trackers add column icon text check (icon ~ '^[a-z]{1,20}$');
