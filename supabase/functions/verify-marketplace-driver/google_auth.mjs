// Google service-account auth for Cloud Vision (server-to-server OAuth 2.0,
// JWT bearer grant). Pure and runtime-independent (WebCrypto + fetch), so it
// runs in the Deno Edge runtime and in Node tests alike.
//
// Secret: GOOGLE_VISION_SERVICE_ACCOUNT_JSON = the raw service-account JSON
// (multi-line value in Supabase Edge Function Secrets). Nothing secret (JSON, private key, JWT assertion, access token) is
// ever logged, returned or put in an error message: errors carry only a
// fixed code.

export const VISION_SCOPE = 'https://www.googleapis.com/auth/cloud-vision';
const ALLOWED_TOKEN_URIS = new Set([
  'https://oauth2.googleapis.com/token',
  'https://www.googleapis.com/oauth2/v4/token',
]);
const EXPIRY_MARGIN_S = 300;

/** Safe error: the message is a fixed code, never secret material. */
export class ScreeningUnavailable extends Error {
  constructor(code) {
    super(code);
    this.name = 'ScreeningUnavailable';
    this.code = code;
  }
}

/** Parse + validate the raw service-account JSON. */
export function parseServiceAccount(raw) {
  if (!raw || typeof raw !== 'string' || !raw.trim()) throw new ScreeningUnavailable('credential_missing');
  let sa;
  try {
    sa = JSON.parse(raw);
  } catch {
    throw new ScreeningUnavailable('credential_malformed');
  }
  const email = sa?.client_email, key = sa?.private_key, uri = sa?.token_uri;
  if (typeof email !== 'string' || !/^[^@\s]+@[^@\s]+\.iam\.gserviceaccount\.com$/.test(email)) {
    throw new ScreeningUnavailable('credential_invalid_client_email');
  }
  if (typeof key !== 'string' || !key.includes('-----BEGIN PRIVATE KEY-----') || !key.includes('-----END PRIVATE KEY-----')) {
    throw new ScreeningUnavailable('credential_invalid_private_key');
  }
  if (typeof uri !== 'string' || !ALLOWED_TOKEN_URIS.has(uri)) {
    throw new ScreeningUnavailable('credential_invalid_token_uri');
  }
  return { client_email: email, private_key: key, token_uri: uri };
}

const b64url = (bytes) => btoa(String.fromCharCode(...new Uint8Array(bytes))).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
const b64urlJson = (o) => b64url(new TextEncoder().encode(JSON.stringify(o)));

async function importKey(pem) {
  try {
    const body = pem.replace(/-----(BEGIN|END) PRIVATE KEY-----/g, '').replace(/\s+/g, '');
    const der = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
    return await crypto.subtle.importKey('pkcs8', der, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  } catch {
    throw new ScreeningUnavailable('credential_invalid_private_key');
  }
}

/** RS256-signed JWT assertion for the JWT bearer grant. */
export async function createAssertion(sa, nowS = Math.floor(Date.now() / 1000)) {
  const head = b64urlJson({ alg: 'RS256', typ: 'JWT' });
  const claims = b64urlJson({ iss: sa.client_email, scope: VISION_SCOPE, aud: sa.token_uri, iat: nowS, exp: nowS + 3600 });
  const key = await importKey(sa.private_key);
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(`${head}.${claims}`));
  return `${head}.${claims}.${b64url(sig)}`;
}

let cache = null; // { email, token, expiresAt } — this isolate only

export function _resetTokenCache() { cache = null; }

/** Short-lived OAuth access token, cached in memory with a safety margin. */
export async function getAccessToken(raw, { fetchImpl = fetch, nowS = () => Math.floor(Date.now() / 1000) } = {}) {
  const sa = parseServiceAccount(raw);
  const now = nowS();
  if (cache && cache.email === sa.client_email && cache.expiresAt - EXPIRY_MARGIN_S > now) return cache.token;
  const assertion = await createAssertion(sa, now);
  let res, body;
  try {
    res = await fetchImpl(sa.token_uri, {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }).toString(),
    });
    body = await res.json();
  } catch {
    throw new ScreeningUnavailable('token_exchange_failed');
  }
  if (!res.ok || typeof body?.access_token !== 'string' || !body.access_token) {
    throw new ScreeningUnavailable('token_exchange_failed');
  }
  const ttl = Number(body.expires_in) > 0 ? Number(body.expires_in) : 3600;
  cache = { email: sa.client_email, token: body.access_token, expiresAt: now + ttl };
  return cache.token;
}

/** Cloud Vision DOCUMENT_TEXT_DETECTION with a Bearer token. */
export async function annotateImage(imageBase64, token, { fetchImpl = fetch } = {}) {
  let res, body;
  try {
    res = await fetchImpl('https://vision.googleapis.com/v1/images:annotate', {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({
        requests: [{ image: { content: imageBase64 }, features: [{ type: 'DOCUMENT_TEXT_DETECTION' }], imageContext: { languageHints: ['ms', 'en'] } }],
      }),
    });
    body = await res.json();
  } catch {
    throw new ScreeningUnavailable('vision_failed');
  }
  if (!res.ok || body?.responses?.[0]?.error) {
    if (res.status === 401) _resetTokenCache();
    throw new ScreeningUnavailable('vision_failed');
  }
  return body;
}

/**
 * Screening orchestration: OCR the licence front + back and/or the vehicle
 * photo. Any failure throws ScreeningUnavailable so the caller records
 * NOTHING (the driver stays pending; never verified by a failure).
 */
export async function screen({ licence, vehicle, download, ocr, extractLicenceFrontBack, extractPlates }) {
  let lic = null, plate = null;
  if (licence) {
    const [f, b] = [await ocr(await download(licence.front)), await ocr(await download(licence.back))];
    lic = extractLicenceFrontBack(f, b);
  }
  if (vehicle) plate = extractPlates(await ocr(await download(vehicle)));
  return { licence: lic, plate };
}
