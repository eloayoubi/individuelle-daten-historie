-- Sign in with Apple: Refresh-Token je Nutzer, damit delete-account den Zugang der App bei Apple widerrufen
-- kann (App Store Review Guideline 5.1.1(v)). Nach jeder Anmeldung oder Verknüpfung mit Apple schickt die
-- App den Autorisierungscode an die Edge Function apple-token; die tauscht ihn bei Apple gegen das
-- Refresh-Token und speichert es hier.
--
-- Das Token ist ein Geheimnis: nur die Service-Role liest und schreibt. RLS ist an, Policies gibt es
-- keine, und anon/authenticated haben auch keine Tabellenrechte – nicht einmal auf das eigene Token.
-- Fällt das Konto weg, verschwindet das Token mit dem Profil.

create table public.apple_tokens (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  refresh_token text not null,
  updated_at timestamptz not null default now()
);

create trigger apple_tokens_updated_at before update on public.apple_tokens
  for each row execute function public.set_updated_at();

alter table public.apple_tokens enable row level security;

revoke all on public.apple_tokens from anon, authenticated;
grant select, insert, update, delete on public.apple_tokens to service_role;
