// Gemeinsame Prüfungen für verify-purchase und app-store-notifications: App, Umgebung, Größe des Bodys.
//
// Env:
//   APPLE_BUNDLE_ID       Standard de.eloayoubi.kostenkurve
//   APPLE_ALLOW_SANDBOX   "true": Sandbox-Käufe zählen für alle (TestFlight-Phase). Alles andere – auch
//                         nicht gesetzt – heißt nein: Ein Sandbox-Kauf kostet nichts, jeder mit einem
//                         TestFlight-Build bekäme sonst Kostenkurve Cloud in Produktion geschenkt.
//   APPLE_SANDBOX_USERS   Nutzer-Ids (uuid, mit Komma getrennt), deren Sandbox-Käufe auch ohne
//                         APPLE_ALLOW_SANDBOX zählen – das Konto für Apples App-Prüfung und eigene Tester.

export const BUNDLE_ID = Deno.env.get("APPLE_BUNDLE_ID") ?? "de.eloayoubi.kostenkurve";
export const PLUS_PRODUCTS = ["de.eloayoubi.kostenkurve.plus.monthly", "de.eloayoubi.kostenkurve.plus.yearly"];
export const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const ALLOW_SANDBOX = Deno.env.get("APPLE_ALLOW_SANDBOX") === "true";
const SANDBOX_USERS = new Set(
  (Deno.env.get("APPLE_SANDBOX_USERS") ?? "").split(",").map((id) => id.trim().toLowerCase()).filter((id) => UUID.test(id)),
);

/// Zählt eine Transaktion aus [environment] für [user]? Production immer, Sandbox nur freigegeben.
export function environmentAllowed(environment: unknown, user: string | null): boolean {
  if (environment === "Production") return true;
  if (environment !== "Sandbox") return false;
  return ALLOW_SANDBOX || (user !== null && SANDBOX_USERS.has(user.toLowerCase()));
}

/// Eine signierte Transaktion samt Verlängerungs-Info liegt weit darunter; mehr ist kein echter Aufruf.
export const MAX_BODY_BYTES = 64 * 1024;

export class BodyTooLarge extends Error {
  constructor() {
    super("body_too_large");
    this.name = "BodyTooLarge";
  }
}

/// JSON-Body, höchstens [MAX_BODY_BYTES] – geprüft, bevor Zertifikate und Signaturen gerechnet werden.
export async function readJson(req: Request): Promise<Record<string, unknown>> {
  if (Number(req.headers.get("content-length") ?? 0) > MAX_BODY_BYTES) throw new BodyTooLarge();
  const bytes = new Uint8Array(await req.arrayBuffer());
  if (bytes.byteLength > MAX_BODY_BYTES) throw new BodyTooLarge();
  const body = JSON.parse(new TextDecoder().decode(bytes));
  if (typeof body !== "object" || body === null || Array.isArray(body)) throw new SyntaxError("body is not an object");
  return body as Record<string, unknown>;
}

/// Für Logs: nur die Art des Fehlers. Meldungen von JSON.parse enthalten Stücke des Bodys.
export const errorName = (e: unknown) => (e instanceof Error ? e.name : "unknown");
