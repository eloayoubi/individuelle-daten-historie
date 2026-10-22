// Prüft eine signierte StoreKit-2-Transaktion (JWS) ohne Netz und ohne Apple-Schlüssel:
// Zertifikatskette im Header (x5c: Blatt → Zwischen-CA → Wurzel) bis zur Apple Root CA - G3,
// dann die Signatur des JWS mit dem Blatt-Schlüssel. Nur WebCrypto, läuft in Deno und Node.
// Vorgehen wie Apples SignedDataVerifier: Wurzel per Fingerabdruck, Marker-OIDs an Blatt und
// Zwischen-CA, Gültigkeit der Zertifikate zum Signaturzeitpunkt (signedDate).

/// SHA-256 der Apple Root CA - G3 (https://www.apple.com/certificateauthority/).
export const APPLE_ROOT_CA_G3_SHA256 = "63343abfb89a6a03ebb57e9b3f5fa7be7c4f5c756f3017b3a8c488c3653e9179";

// 1.2.840.113635.100.6.11.1 (App-Store-Belegsignatur) und 1.2.840.113635.100.6.2.1 (WWDR-Zwischen-CA)
const OID_LEAF = [0x06, 0x0a, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x63, 0x64, 0x06, 0x0b, 0x01];
const OID_INTERMEDIATE = [0x06, 0x0a, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x63, 0x64, 0x06, 0x02, 0x01];

const CURVES: Record<string, { name: string; size: number }> = {
  "2a8648ce3d030107": { name: "P-256", size: 32 },
  "2b81040022": { name: "P-384", size: 48 },
};
const HASHES: Record<string, string> = {
  "2a8648ce3d040302": "SHA-256",
  "2a8648ce3d040303": "SHA-384",
};

export class JwsError extends Error {}

/// Bytes mit eigenem ArrayBuffer (aus new/from/slice) – das verlangt WebCrypto als BufferSource (TS ≥ 5.7).
type Bytes = Uint8Array<ArrayBuffer>;

interface Tlv {
  tag: number;
  start: number;
  body: number;
  end: number;
}

interface Cert {
  der: Bytes;
  tbs: Bytes;
  spki: Bytes;
  curve: { name: string; size: number };
  hash: string;
  signature: Bytes;
  notBefore: number;
  notAfter: number;
}

function fail(reason: string): never {
  throw new JwsError(reason);
}

function tlv(buf: Uint8Array, pos: number): Tlv {
  if (pos + 2 > buf.length) fail("der_truncated");
  let len = buf[pos + 1];
  let body = pos + 2;
  if (len & 0x80) {
    const n = len & 0x7f;
    if (n < 1 || n > 4 || body + n > buf.length) fail("der_length");
    len = 0;
    for (let i = 0; i < n; i++) len = len * 256 + buf[body + i];
    body += n;
  }
  const end = body + len;
  if (end > buf.length) fail("der_truncated");
  return { tag: buf[pos], start: pos, body, end };
}

function children(buf: Uint8Array, t: Tlv): Tlv[] {
  const out: Tlv[] = [];
  for (let p = t.body; p < t.end; p = out[out.length - 1].end) out.push(tlv(buf, p));
  return out;
}

const hex = (b: Uint8Array) => Array.from(b, (x) => x.toString(16).padStart(2, "0")).join("");
const content = (buf: Uint8Array, t: Tlv) => buf.slice(t.body, t.end);

function contains(haystack: Uint8Array, needle: number[]): boolean {
  outer: for (let i = 0; i + needle.length <= haystack.length; i++) {
    for (let j = 0; j < needle.length; j++) if (haystack[i + j] !== needle[j]) continue outer;
    return true;
  }
  return false;
}

/// UTCTime (YYMMDDHHMMSSZ) oder GeneralizedTime (YYYYMMDDHHMMSSZ) → Millisekunden.
function time(buf: Uint8Array, t: Tlv): number {
  const s = new TextDecoder().decode(content(buf, t));
  const m = t.tag === 0x17 ? s.match(/^(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})Z$/) : s.match(/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})Z$/);
  if (!m) fail("der_time");
  let year = Number(m[1]);
  if (t.tag === 0x17) year += year >= 50 ? 1900 : 2000;
  return Date.UTC(year, Number(m[2]) - 1, Number(m[3]), Number(m[4]), Number(m[5]), Number(m[6]));
}

function parseCert(der: Bytes): Cert {
  const root = tlv(der, 0);
  const [tbs, sigAlg, sigVal] = children(der, root);
  if (!tbs || !sigAlg || !sigVal || sigVal.tag !== 0x03) fail("der_certificate");
  const f = children(der, tbs);
  const i = f[0]?.tag === 0xa0 ? 1 : 0; // [0] version
  const validity = children(der, f[i + 3]);
  const spki = f[i + 5];
  const curveOid = children(der, children(der, spki)[0])[1];
  const curve = curveOid && CURVES[hex(content(der, curveOid))];
  const hash = HASHES[hex(content(der, children(der, sigAlg)[0]))];
  if (!curve || !hash) fail("unsupported_algorithm");
  return {
    der,
    tbs: der.slice(tbs.start, tbs.end),
    spki: der.slice(spki.start, spki.end),
    curve,
    hash,
    signature: der.slice(sigVal.body + 1, sigVal.end), // ohne „unused bits“-Byte
    notBefore: time(der, validity[0]),
    notAfter: time(der, validity[1]),
  };
}

/// ECDSA-Signatur aus DER (SEQUENCE { r, s }) in das rohe r‖s-Format von WebCrypto.
function rawSignature(sig: Uint8Array, size: number): Bytes {
  const parts = children(sig, tlv(sig, 0));
  if (parts.length !== 2) fail("der_signature");
  const out = new Uint8Array(size * 2);
  parts.forEach((p, k) => {
    let v = content(sig, p);
    while (v.length > size && v[0] === 0) v = v.slice(1);
    if (v.length > size) fail("der_signature");
    out.set(v, k * size + size - v.length);
  });
  return out;
}

const key = (c: Cert) => crypto.subtle.importKey("spki", c.spki, { name: "ECDSA", namedCurve: c.curve.name }, false, ["verify"]);

async function signedBy(child: Cert, issuer: Cert): Promise<boolean> {
  return crypto.subtle.verify({ name: "ECDSA", hash: child.hash }, await key(issuer), rawSignature(child.signature, issuer.curve.size), child.tbs);
}

function b64(s: string): Bytes {
  const std = s.replace(/-/g, "+").replace(/_/g, "/");
  return Uint8Array.from(atob(std + "=".repeat((4 - (std.length % 4)) % 4)), (c) => c.charCodeAt(0));
}

/// Liefert die Nutzdaten der Transaktion, wenn Kette und Signatur stimmen; sonst [JwsError].
export async function verifyAppleJws(jws: string, options: { rootSha256?: string } = {}): Promise<Record<string, unknown>> {
  const parts = jws.split(".");
  if (parts.length !== 3) fail("jws_format");
  let header: { alg?: string; x5c?: string[] };
  let payload: Record<string, unknown>;
  try {
    header = JSON.parse(new TextDecoder().decode(b64(parts[0])));
    payload = JSON.parse(new TextDecoder().decode(b64(parts[1])));
  } catch {
    fail("jws_format");
  }
  if (header.alg !== "ES256" || !Array.isArray(header.x5c) || header.x5c.length !== 3) fail("jws_header");
  const [leaf, intermediate, root] = header.x5c.map((c) => parseCert(b64(c)));

  const rootSha = hex(new Uint8Array(await crypto.subtle.digest("SHA-256", root.der)));
  if (rootSha !== (options.rootSha256 ?? APPLE_ROOT_CA_G3_SHA256)) fail("untrusted_root");
  if (!contains(leaf.tbs, OID_LEAF) || !contains(intermediate.tbs, OID_INTERMEDIATE)) fail("missing_apple_oid");
  if (!(await signedBy(intermediate, root)) || !(await signedBy(leaf, intermediate))) fail("bad_chain");

  const data = new TextEncoder().encode(`${parts[0]}.${parts[1]}`);
  const sig = b64(parts[2]);
  if (leaf.curve.name !== "P-256" || sig.length !== 64) fail("jws_signature");
  if (!(await crypto.subtle.verify({ name: "ECDSA", hash: "SHA-256" }, await key(leaf), sig, data))) fail("jws_signature");

  const at = typeof payload.signedDate === "number" ? payload.signedDate : Date.now();
  if ([leaf, intermediate, root].some((c) => at < c.notBefore || at > c.notAfter)) fail("certificate_expired");
  return payload;
}
