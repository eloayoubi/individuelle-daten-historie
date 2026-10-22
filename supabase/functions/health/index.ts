// GET /functions/v1/health
// Antwort: { "ok": true }
//
// Lebenszeichen für Deploy und `supabase functions invoke health`/curl – ohne Anmeldung
// (verify_jwt = false in supabase/config.toml), ohne Datenbankzugriff.
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve((req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  return new Response(JSON.stringify({ ok: true }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
