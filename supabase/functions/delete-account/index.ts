// POST /functions/v1/delete-account   (verify_jwt = true)
// Antwort: { "deleted": true }
//
// Löscht das Konto des angemeldeten Nutzers endgültig. Zuerst die Dateien im Bucket „attachments“: alles
// unter den eigenen Kategorien (<category_id>/…, auch was Mitglieder dort hochgeladen haben) und die eigenen
// Belege in fremden, geteilten Kategorien. Dann den Auth-Nutzer – das kaskadiert profiles → categories →
// Tracker, Felder, Einträge, Werte, Belege, Mitgliedschaften, Einladungen sowie entitlements und
// store_transactions. Eigene Einträge in fremden Kategorien bleiben (created_by = null).
// Dateien zuerst: Scheitert der Storage, bleibt das Konto bestehen und die App kann es erneut versuchen.
// Vor dem Löschen widerruft die Funktion den Zugang bei Apple (Sign in with Apple, App Store Review
// Guideline 5.1.1(v)), wenn apple-token ein Refresh-Token gespeichert hat und der Apple-Schlüssel
// eingerichtet ist. Scheitert der Widerruf, wird trotzdem gelöscht (geloggt wird nur der Fehlercode).
// Wiederholbar: Ist der Nutzer schon gelöscht (Antwort ging verloren), kommt wieder { "deleted": true }.
// Ein laufendes App-Store-Abo endet dadurch nicht – das kündigt der Nutzer in den iOS-Einstellungen.
// Fehler: 401 unauthorized, 405 method_not_allowed, 500 storage_failed | delete_failed.
// Env (optional, für den Widerruf): APPLE_TEAM_ID, APPLE_SIGNIN_KEY_ID, APPLE_SIGNIN_KEY, APPLE_BUNDLE_ID.
import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { appleAuthPost, appleErrorCode, appleSignInConfig } from "../_shared/apple_client_secret.ts";
import { adminClient, corsHeaders, error, json, requireUser } from "../_shared/supabase.ts";

const BUCKET = "attachments";
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const LIST_PAGE = 100; // Seitengröße von storage list() (Standard der API)
const REMOVE_BATCH = 100;
const PARALLEL = 10;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return error("method_not_allowed", 405);
  const admin = adminClient();

  const user = await requireUser(req);
  if (!user) {
    if (await alreadyDeleted(admin, req)) return json({ deleted: true });
    return error("unauthorized", 401);
  }

  try {
    const paths = new Set<string>();
    for (const category of await column(admin, "categories", "id", "owner_id", user)) {
      for (const path of await listFiles(admin, category)) paths.add(path);
    }
    for (const path of await column(admin, "attachments", "storage_path", "created_by", user)) paths.add(path);
    await removeFiles(admin, [...paths]);
    console.log("delete-account: files removed", paths.size);
  } catch (e) {
    console.error("delete-account: storage cleanup failed", e);
    return error("storage_failed", 500);
  }

  await revokeAppleToken(admin, user);

  const { error: e } = await admin.auth.admin.deleteUser(user);
  if (e && e.status !== 404) {
    console.error("delete-account: delete failed", e);
    return error("delete_failed", 500);
  }
  return json({ deleted: true });
});

/// Sign in with Apple: Refresh-Token bei Apple widerrufen. Blockiert das Löschen nie, loggt nur Codes.
async function revokeAppleToken(admin: SupabaseClient, user: string): Promise<void> {
  const config = appleSignInConfig();
  if (!config) return;
  try {
    const { data, error: e } = await admin.from("apple_tokens").select("refresh_token").eq("user_id", user).maybeSingle();
    if (e) {
      console.warn("delete-account: apple token lookup failed", e.code);
      return;
    }
    if (typeof data?.refresh_token !== "string" || !data.refresh_token) return;
    const res = await appleAuthPost(config, "revoke", { token: data.refresh_token, token_type_hint: "refresh_token" });
    if (res.ok) {
      await res.body?.cancel();
      console.log("delete-account: apple token revoked");
    } else {
      console.warn("delete-account: apple revoke failed", res.status, await appleErrorCode(res));
    }
  } catch (e) {
    console.warn("delete-account: apple revoke failed", e instanceof Error ? e.name : "unknown");
  }
}

/// Token gültig (verify_jwt hat die Signatur geprüft), aber den Nutzer gibt es nicht mehr? Nur eine
/// Auskunft – gelöscht wird ausschließlich nach erfolgreichem getUser() in requireUser.
async function alreadyDeleted(admin: SupabaseClient, req: Request): Promise<boolean> {
  const sub = jwtSubject(req.headers.get("Authorization") ?? "");
  if (!sub) return false;
  const { data, error: e } = await admin.auth.admin.getUserById(sub);
  return !data.user && e?.status === 404;
}

function jwtSubject(authorization: string): string | null {
  const payload = authorization.replace(/^Bearer\s+/i, "").split(".")[1];
  if (!payload) return null;
  try {
    const b64 = payload.replace(/-/g, "+").replace(/_/g, "/");
    const bytes = Uint8Array.from(atob(b64 + "=".repeat((4 - (b64.length % 4)) % 4)), (c) => c.charCodeAt(0));
    const claims = JSON.parse(new TextDecoder().decode(bytes));
    return typeof claims.sub === "string" && UUID.test(claims.sub) ? claims.sub : null;
  } catch {
    return null;
  }
}

/// Alle Werte einer Spalte mit filter = user, seitenweise (PostgREST liefert höchstens max_rows Zeilen).
async function column(admin: SupabaseClient, table: string, col: string, filter: string, user: string): Promise<string[]> {
  const out: string[] = [];
  for (;;) {
    const { data, error: e } = await admin.from(table).select(col).eq(filter, user).order(col).range(out.length, out.length + 999);
    if (e) throw e;
    const rows = (data ?? []) as unknown as Record<string, unknown>[];
    if (rows.length === 0) return out;
    for (const row of rows) out.push(String(row[col]));
  }
}

/// Alle Dateien unter einem Ordner samt Unterordnern (list() liefert je Ebene Dateien und Ordner).
async function listFiles(admin: SupabaseClient, root: string): Promise<string[]> {
  const files: string[] = [];
  let folders = [root];
  while (folders.length > 0) {
    const next: string[] = [];
    for (let i = 0; i < folders.length; i += PARALLEL) {
      const levels = await Promise.all(folders.slice(i, i + PARALLEL).map((folder) => listFolder(admin, folder)));
      for (const level of levels) {
        files.push(...level.files);
        next.push(...level.folders);
      }
    }
    folders = next;
  }
  return files;
}

async function listFolder(admin: SupabaseClient, folder: string): Promise<{ files: string[]; folders: string[] }> {
  const files: string[] = [];
  const folders: string[] = [];
  for (let offset = 0; ; offset += LIST_PAGE) {
    const { data, error: e } = await admin.storage.from(BUCKET).list(folder, { limit: LIST_PAGE, offset });
    if (e) throw e;
    // Ordner haben keine id.
    for (const item of data) (item.id === null ? folders : files).push(`${folder}/${item.name}`);
    if (data.length < LIST_PAGE) return { files, folders };
  }
}

async function removeFiles(admin: SupabaseClient, paths: string[]): Promise<void> {
  for (let i = 0; i < paths.length; i += REMOVE_BATCH) {
    const { error: e } = await admin.storage.from(BUCKET).remove(paths.slice(i, i + REMOVE_BATCH));
    if (e) throw e;
  }
}
