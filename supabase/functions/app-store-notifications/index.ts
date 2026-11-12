// POST /functions/v1/app-store-notifications   (verify_jwt = false – Apple ruft ohne Supabase-Token auf)
// Body: { "signedPayload": "<JWS>" }  – App Store Server Notifications V2
//
// Hält Kostenkurve Plus aktuell, auch wenn der Käufer die App länger nicht öffnet: Kauf, Verlängerung,
// Ablauf, Erstattung und Widerruf. Die Nachricht und die darin signierte Transaktion werden wie in
// verify-purchase geprüft (Apple-Kette, Signatur, App, Umgebung). apply_plus_transaction ordnet das Abo dem
// Nutzer aus appAccountToken zu; fehlt der Token oder gibt es das Konto nicht mehr, wird nur ein schon
// gespeichertes Abo aktualisiert. Andere Produkte und Nachrichten ohne Transaktion (TEST …) werden ignoriert.
// Antwort 200, sobald die Nachricht echt ist und verarbeitet oder ignoriert wurde – sonst wiederholt Apple
// sie tagelang. 500 nur, wenn die Datenbank scheitert (dann soll Apple es erneut versuchen).
// In App Store Connect (App → App-Informationen → App-Store-Server-Benachrichtigungen, Version 2) für
// Produktion und Sandbox eintragen: https://<projekt>.supabase.co/functions/v1/app-store-notifications
// Die Transaktion in der Nachricht muss zur selben App und Umgebung gehören wie die Nachricht selbst.
// Sandbox-Nachrichten, die nicht freigegeben sind (siehe _shared/store_env.ts), werden mit 200 ignoriert.
// Env: APPLE_BUNDLE_ID, APPLE_ALLOW_SANDBOX, APPLE_SANDBOX_USERS (wie verify-purchase).
import { adminClient, error, json } from "../_shared/supabase.ts";
import { JwsError, verifyAppleJws } from "../_shared/apple_jws.ts";
import { BodyTooLarge, BUNDLE_ID, environmentAllowed, errorName, PLUS_PRODUCTS, readJson, UUID } from "../_shared/store_env.ts";

const iso = (ms: unknown) => (typeof ms === "number" ? new Date(ms).toISOString() : null);

Deno.serve(async (req) => {
  if (req.method !== "POST") return error("method_not_allowed", 405);

  let note: Record<string, unknown>;
  let tx: Record<string, unknown> | null = null;
  let environment: unknown;
  try {
    const { signedPayload } = await readJson(req);
    note = await verifyAppleJws(String(signedPayload ?? ""));
    const data = (note.data ?? {}) as Record<string, unknown>;
    if (data.bundleId !== BUNDLE_ID) return error("wrong_app");
    environment = data.environment;
    if (environment !== "Production" && environment !== "Sandbox") return error("wrong_environment");
    if (typeof data.signedTransactionInfo === "string") {
      tx = await verifyAppleJws(data.signedTransactionInfo);
      // Auch die Transaktion ist von Apple signiert – sie muss aber zu dieser Nachricht passen.
      if (tx.bundleId !== BUNDLE_ID) return error("wrong_app");
      if (tx.environment !== environment) return error("wrong_environment");
    }
  } catch (e) {
    if (e instanceof BodyTooLarge) return error("body_too_large", 413);
    console.warn("app-store-notifications: invalid payload", e instanceof JwsError ? e.message : errorName(e));
    return error("invalid_payload");
  }

  const kind = `${note.notificationType}${note.subtype ? `/${note.subtype}` : ""}`;
  const token = String(tx?.appAccountToken ?? "");
  // Echt, aber nicht freigegeben: 200, damit Apple die Nachricht nicht tagelang wiederholt.
  if (!environmentAllowed(environment, UUID.test(token) ? token : null)) {
    console.log("app-store-notifications: ignored", kind, "sandbox");
    return json({ ok: true, ignored: true });
  }
  if (!tx || !PLUS_PRODUCTS.includes(String(tx.productId)) || typeof tx.expiresDate !== "number") {
    console.log("app-store-notifications: ignored", kind, tx?.productId ?? "");
    return json({ ok: true, ignored: true });
  }

  const original = String(tx.originalTransactionId ?? tx.transactionId);
  const { data, error: e } = await adminClient().rpc("apply_plus_transaction", {
    p_user: UUID.test(token) ? token.toLowerCase() : null,
    p_original: original,
    p_transaction: String(tx.transactionId),
    p_product: String(tx.productId),
    p_expires: iso(tx.expiresDate),
    p_revoked: iso(tx.revocationDate),
    p_environment: String(tx.environment),
    p_signed: iso(note.signedDate) ?? iso(tx.signedDate) ?? new Date().toISOString(),
  });
  if (e) {
    console.error("app-store-notifications: apply failed", kind, original, e);
    return error("apply_failed", 500);
  }
  console.log("app-store-notifications:", kind, original, data);
  return json({ ok: true, ...data });
});
