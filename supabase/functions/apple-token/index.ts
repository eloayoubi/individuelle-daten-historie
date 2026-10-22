// POST /functions/v1/apple-token   (verify_jwt = true)
// Body: { "code": "<authorizationCode aus dem nativen Apple-Login>" }
// Antwort: { "stored": true } – oder { "stored": false }, solange der Apple-Schlüssel nicht eingerichtet ist.
//
// Nach jeder erfolgreichen Anmeldung oder Verknüpfung mit Apple (signInWithIdToken /
// linkIdentityWithIdToken) schickt die App den Autorisierungscode (5 Minuten gültig, nur einmal
// verwendbar). Die Funktion tauscht ihn bei Apple gegen ein Refresh-Token und speichert es in apple_tokens;
// delete-account widerruft es beim Löschen des Kontos (App Store Review Guideline 5.1.1(v)).
// Fehler: 400 invalid_code | apple_rejected, 401 unauthorized, 405 method_not_allowed,
// 500 apple_key_invalid | store_failed, 502 apple_unreachable. Codes und Tokens werden nie geloggt.
// Env: APPLE_TEAM_ID, APPLE_SIGNIN_KEY_ID, APPLE_SIGNIN_KEY, APPLE_BUNDLE_ID (siehe _shared/apple_client_secret.ts).
import { appleAuthPost, appleErrorCode, AppleKeyError, appleSignInConfig } from "../_shared/apple_client_secret.ts";
import { adminClient, corsHeaders, error, json, requireUser } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return error("method_not_allowed", 405);
  const user = await requireUser(req);
  if (!user) return error("unauthorized", 401);

  const code: string = await req.json().then((b) => (typeof b?.code === "string" ? b.code.trim() : ""), () => "");
  if (!code) return error("invalid_code");

  const config = appleSignInConfig();
  if (!config) return json({ stored: false });

  let res: Response;
  try {
    res = await appleAuthPost(config, "token", { code, grant_type: "authorization_code" });
  } catch (e) {
    if (e instanceof AppleKeyError) {
      console.error("apple-token: APPLE_SIGNIN_KEY unreadable");
      return error("apple_key_invalid", 500);
    }
    console.warn("apple-token: apple unreachable", e instanceof Error ? e.name : "unknown");
    return error("apple_unreachable", 502);
  }
  if (!res.ok) {
    console.warn("apple-token: rejected", res.status, await appleErrorCode(res));
    return error("apple_rejected");
  }
  const refresh: string = await res.json().then((b) => (typeof b?.refresh_token === "string" ? b.refresh_token : ""), () => "");
  if (!refresh) {
    console.warn("apple-token: no refresh token in response", res.status);
    return error("apple_rejected");
  }

  const { error: e } = await adminClient().from("apple_tokens").upsert({ user_id: user, refresh_token: refresh });
  if (e) {
    console.error("apple-token: store failed", e.code);
    return error("store_failed", 500);
  }
  return json({ stored: true });
});
