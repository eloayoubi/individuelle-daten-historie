// POST /functions/v1/purge-attachments   (verify_jwt = true)
// Antwort: { "removed": <Anzahl> }
//
// Entfernt die Dateien gelöschter Belege aus dem Bucket „attachments“. Jede gelöschte Beleg-Zeile – auch
// per Cascade mit Eintrag, Tracker oder Kategorie – schreibt ihren Pfad in storage_orphans (Migration
// 20261113120000). Die App entfernt die Datei beim Löschen zwar selbst; scheitert das, bliebe sie liegen,
// und ohne die Kategorie darf sie kein Nutzer mehr löschen. Diese Funktion räumt mit Service-Role nach.
//
// Die App ruft sie nach dem Löschen eines Eintrags oder einer Kategorie auf. Jeder angemeldete Nutzer darf
// das: Sie nimmt keine Eingaben, gelöscht wird nur, was in der Warteschlange steht und zu keiner Beleg-Zeile
// mehr gehört. Ein Pfad, der inzwischen wieder zu einem Beleg gehört, wird nur aus der Warteschlange genommen.
// Je Aufruf höchstens BATCH Pfade, der Rest beim nächsten Mal.
// Fehler: 401 unauthorized, 405 method_not_allowed, 500 purge_failed.
import { adminClient, corsHeaders, error, json, requireUser } from "../_shared/supabase.ts";

const BUCKET = "attachments";
const BATCH = 40; // Pfade stehen als Filter in der URL – mehr würde sie zu lang machen.
const PATH = /^[0-9a-f-]{36}\/[0-9a-f-]{36}\/[A-Za-z0-9._-]{1,80}$/;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return error("method_not_allowed", 405);
  if (!(await requireUser(req))) return error("unauthorized", 401);

  const admin = adminClient();
  try {
    const { data: queued, error: e1 } = await admin.from("storage_orphans").select("path").order("queued_at").limit(BATCH);
    if (e1) throw e1;
    const paths = (queued ?? []).map((row) => String(row.path));
    if (paths.length === 0) return json({ removed: 0 });

    // Gehört der Pfad wieder zu einem Beleg, bleibt die Datei.
    const { data: used, error: e2 } = await admin.from("attachments").select("storage_path").in("storage_path", paths);
    if (e2) throw e2;
    const inUse = new Set((used ?? []).map((row) => String(row.storage_path)));
    const remove = paths.filter((path) => !inUse.has(path) && PATH.test(path));

    if (remove.length > 0) {
      // Fehlt die Datei schon (die App hat sie selbst entfernt), meldet Storage keinen Fehler.
      const { error: e3 } = await admin.storage.from(BUCKET).remove(remove);
      if (e3) throw e3;
    }
    const { error: e4 } = await admin.from("storage_orphans").delete().in("path", paths);
    if (e4) throw e4;
    console.log("purge-attachments: removed", remove.length, "of", paths.length);
    return json({ removed: remove.length });
  } catch (e) {
    console.error("purge-attachments: failed", e instanceof Error ? e.name : "unknown");
    return error("purge_failed", 500);
  }
});
