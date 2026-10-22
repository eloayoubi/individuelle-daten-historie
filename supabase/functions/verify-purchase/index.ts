// POST /functions/v1/verify-purchase   (verify_jwt = true)
// Body: { "jws": "<StoreKit-2-Transaktion von Kostenkurve Plus: serverVerificationData aus in_app_purchase>" }
// Antwort: { "plus": bool, "valid_until": "<ISO-Zeit>" | null }  (Abo-Stand des Nutzers nach der Meldung)
//
// Plus gekauft, verlängert oder wiederhergestellt: Die App schickt die von Apple signierte Transaktion.
// Geprüft werden Kette und Signatur (_shared/apple_jws.ts), App, Umgebung, Abo-Typ, Produkt und Käufer
// (appAccountToken = Nutzer-ID, beim Kauf als applicationUserName mitgeben). apply_plus_transaction
// speichert das Abo und berechnet entitlements neu. Abgelaufene oder erstattete Transaktionen werden auch
// gespeichert (plus = false). Die App beendet die Transaktion (completePurchase) erst nach einer Antwort 200.
// Fehler: 400 invalid_transaction | wrong_app | wrong_environment | not_subscription | unknown_product,
// 401 unauthorized, 403 wrong_user, 500 apply_failed.
// Env: APPLE_BUNDLE_ID (Standard de.eloayoubi.kostenkurve), APPLE_ALLOW_SANDBOX (Standard true –
// TestFlight und App Review kaufen im Sandbox; nach dem Start ggf. auf false).
import { adminClient, corsHeaders, error, json, requireUser } from "../_shared/supabase.ts";
import { JwsError, verifyAppleJws } from "../_shared/apple_jws.ts";

const BUNDLE_ID = Deno.env.get("APPLE_BUNDLE_ID") ?? "de.eloayoubi.kostenkurve";
const ALLOW_SANDBOX = (Deno.env.get("APPLE_ALLOW_SANDBOX") ?? "true") !== "false";
const PLUS_PRODUCTS = ["de.eloayoubi.kostenkurve.plus.monthly", "de.eloayoubi.kostenkurve.plus.yearly"];

const iso = (ms: unknown) => (typeof ms === "number" ? new Date(ms).toISOString() : null);

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return error("method_not_allowed", 405);
  const user = await requireUser(req);
  if (!user) return error("unauthorized", 401);

  let tx: Record<string, unknown>;
  try {
    const { jws } = await req.json();
    tx = await verifyAppleJws(String(jws ?? ""));
  } catch (e) {
    console.warn("verify-purchase: invalid transaction", e instanceof JwsError ? e.message : e);
    return error("invalid_transaction");
  }

  if (tx.bundleId !== BUNDLE_ID) return error("wrong_app");
  if (tx.environment !== "Production" && !(ALLOW_SANDBOX && tx.environment === "Sandbox")) return error("wrong_environment");
  if (tx.type !== "Auto-Renewable Subscription" || typeof tx.expiresDate !== "number") return error("not_subscription");
  if (!PLUS_PRODUCTS.includes(String(tx.productId))) return error("unknown_product");
  if (String(tx.appAccountToken ?? "").toLowerCase() !== user.toLowerCase()) return error("wrong_user", 403);

  const { data, error: e } = await adminClient().rpc("apply_plus_transaction", {
    p_user: user,
    p_original: String(tx.originalTransactionId ?? tx.transactionId),
    p_transaction: String(tx.transactionId),
    p_product: String(tx.productId),
    p_expires: iso(tx.expiresDate),
    p_revoked: iso(tx.revocationDate),
    p_environment: String(tx.environment),
    p_signed: iso(tx.signedDate) ?? new Date().toISOString(),
  });
  if (e) {
    if (e.code === "P0063") return error("unknown_product");
    console.error("verify-purchase: apply failed", e);
    return error("apply_failed", 500);
  }
  return json({ plus: data?.plus === true, valid_until: data?.valid_until ?? null });
});
