// Sign in with Apple über die REST-API (https://appleid.apple.com/auth/token und /auth/revoke).
// Das client_secret ist ein ES256-JWT, signiert mit dem Sign-in-with-Apple-Schlüssel (.p8) aus dem
// Apple-Developer-Konto: Header kid = Schlüssel-ID, Claims iss = Team-ID, iat, exp (5 Minuten, Apple erlaubt
// bis 6 Monate), aud = https://appleid.apple.com, sub = client_id (Bundle-ID der App). Nur Web Crypto.
// Env: APPLE_TEAM_ID, APPLE_SIGNIN_KEY_ID, APPLE_SIGNIN_KEY (Inhalt der .p8-Datei), APPLE_BUNDLE_ID
// (Standard de.eloayoubi.kostenkurve). Tokens, Codes und das Secret nie loggen.

export const APPLE_AUTH_URL = "https://appleid.apple.com";

export interface AppleSignInConfig {
  teamId: string;
  keyId: string;
  key: string;
  clientId: string;
}

/// Der Schlüssel in APPLE_SIGNIN_KEY ist kein lesbarer P-256-Schlüssel (PKCS#8).
export class AppleKeyError extends Error {}

/// Konfiguration aus den Secrets, null solange der Apple-Schlüssel nicht eingerichtet ist.
export function appleSignInConfig(): AppleSignInConfig | null {
  const teamId = Deno.env.get("APPLE_TEAM_ID")?.trim();
  const keyId = Deno.env.get("APPLE_SIGNIN_KEY_ID")?.trim();
  const key = Deno.env.get("APPLE_SIGNIN_KEY")?.trim();
  const clientId = Deno.env.get("APPLE_BUNDLE_ID")?.trim() || "de.eloayoubi.kostenkurve";
  if (!teamId || !keyId || !key) return null;
  return { teamId, keyId, key, clientId };
}

const b64url = (bytes: Uint8Array) =>
  btoa(Array.from(bytes, (b) => String.fromCharCode(b)).join("")).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
const b64urlJson = (value: unknown) => b64url(new TextEncoder().encode(JSON.stringify(value)));

/// Privater Schlüssel aus der .p8-Datei (PEM, auch ohne Kopfzeilen oder mit „\n“ statt Zeilenumbrüchen).
async function signingKey(pem: string): Promise<CryptoKey> {
  try {
    const body = pem.replace(/-----(BEGIN|END) PRIVATE KEY-----/g, "").replace(/\\n/g, "").replace(/\s+/g, "");
    const der = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
    return await crypto.subtle.importKey("pkcs8", der, { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"]);
  } catch {
    throw new AppleKeyError("apple_key_invalid");
  }
}

/// client_secret für /auth/token und /auth/revoke. Wirft AppleKeyError, wenn der Schlüssel unlesbar ist.
export async function appleClientSecret(config: AppleSignInConfig, now = Date.now()): Promise<string> {
  const iat = Math.floor(now / 1000);
  const header = b64urlJson({ alg: "ES256", kid: config.keyId });
  const claims = b64urlJson({ iss: config.teamId, iat, exp: iat + 300, aud: APPLE_AUTH_URL, sub: config.clientId });
  const key = await signingKey(config.key);
  // Web Crypto liefert die Signatur roh als r‖s (64 Byte) – genau das Format von JWS ES256.
  const signature = await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, key, new TextEncoder().encode(`${header}.${claims}`));
  return `${header}.${claims}.${b64url(new Uint8Array(signature))}`;
}

/// POST an /auth/<path> mit client_id und client_secret als Formular, höchstens 10 Sekunden.
/// Wirft AppleKeyError (Schlüssel) oder einen Netzwerkfehler (TypeError, TimeoutError).
export async function appleAuthPost(config: AppleSignInConfig, path: "token" | "revoke", params: Record<string, string>): Promise<Response> {
  const body = new URLSearchParams({ client_id: config.clientId, client_secret: await appleClientSecret(config), ...params });
  return await fetch(`${APPLE_AUTH_URL}/auth/${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body,
    signal: AbortSignal.timeout(10_000),
  });
}

/// Fehlercode aus Apples Antwort (z. B. invalid_grant) – nur der Code, nie der Rest der Antwort.
export async function appleErrorCode(res: Response): Promise<string> {
  const body = await res.json().catch(() => null);
  return typeof body?.error === "string" && /^[a-z_]{1,40}$/.test(body.error) ? body.error : "";
}
