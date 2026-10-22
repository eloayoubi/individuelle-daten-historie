-- Typen für Felder, Mitgliedsrollen und Abo-Stufen.
-- Neue Enum-Werte immer in eine eigene Migration (ALTER TYPE … ADD VALUE läuft nicht in derselben
-- Transaktion wie Code, der den neuen Wert benutzt).

-- Wie ein Feld eingegeben und angezeigt wird.
create type public.field_kind as enum ('text', 'number', 'currency', 'percent', 'date', 'toggle', 'choice', 'formula');

-- Wie sich ein Feld über die Zeit verhält (siehe lib/core/models/tracking.dart, FieldRole).
create type public.field_role as enum ('info', 'snapshot', 'meter_reading', 'unit_price', 'recurring_cost', 'one_off_cost', 'deadline');

-- Rechte in einer (geteilten) Kategorie.
create type public.member_role as enum ('owner', 'editor', 'viewer');

-- Abo-Stufe: Belege (Fotos/PDFs) gibt es nur mit Plus.
create type public.plan_tier as enum ('free', 'plus');
