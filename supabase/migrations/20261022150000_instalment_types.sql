-- Abschlag (Vorauszahlung) als eigenes Zeitverhalten. Eigene Migration: Ein neuer Enum-Wert darf
-- nicht in derselben Transaktion benutzt werden, die ihn anlegt.
alter type public.field_role add value if not exists 'instalment';
