// Unit tests: Google service-account auth for the verify-marketplace-driver
// Edge Function. Uses a TEST RSA key generated at run time — never a real
// credential. No network: fetch is mocked.
import { generateKeyPairSync, createVerify } from 'node:crypto';
import {
  VISION_SCOPE, ScreeningUnavailable, parseServiceAccount, createAssertion,
  getAccessToken, annotateImage, screen, _resetTokenCache,
} from '../supabase/functions/verify-marketplace-driver/google_auth.mjs';
import { extractLicenceFrontBack, extractPlates, visionText } from '../supabase/functions/verify-marketplace-driver/extract.mjs';

const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${x ? '  -> ' + String(x).slice(0, 200) : ''}`); if (!c) fails++; };
const { privateKey, publicKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const PEM = privateKey.export({ type: 'pkcs8', format: 'pem' });
const SA = { type: 'service_account', client_email: 'test-ocr@cefflo-test.iam.gserviceaccount.com', private_key: PEM, token_uri: 'https://oauth2.googleapis.com/token', private_key_id: 'test' };
const enc = o => JSON.stringify(o, null, 2); // raw multi-line JSON, as stored in Supabase Secrets
const B64 = enc(SA);
const KEY_BODY = PEM.split('\n')[1];
const leaks = s => [KEY_BODY, 'ya29.TEST-ACCESS-TOKEN', SA.client_email].some(t => String(s).includes(t));
const codeOf = async f => { try { await f(); return 'no-error'; } catch (e) { return e instanceof ScreeningUnavailable ? e.code : 'other:' + e.message; } };
const dec = s => JSON.parse(Buffer.from(s, 'base64url').toString());

// --- credential validation
ok('raw multi-line JSON credential parses (client_email, private_key, token_uri)', B64.includes('\n') && parseServiceAccount(B64).client_email === SA.client_email);
ok('compact single-line raw JSON also parses', parseServiceAccount(JSON.stringify(SA)).token_uri === SA.token_uri);
for (const [label, v, code] of [
  ['missing credential', undefined, 'credential_missing'],
  ['empty credential', '', 'credential_missing'],
  ['whitespace only', '   \n ', 'credential_missing'],
  ['not JSON', 'not-json!!', 'credential_malformed'],
  ['base64 (no longer accepted)', Buffer.from(JSON.stringify(SA)).toString('base64'), 'credential_malformed'],
  ['JSON array', '[1,2]', 'credential_invalid_client_email'],
  ['missing client_email', enc({ ...SA, client_email: undefined }), 'credential_invalid_client_email'],
  ['non service-account email', enc({ ...SA, client_email: 'someone@gmail.com' }), 'credential_invalid_client_email'],
  ['missing private_key', enc({ ...SA, private_key: undefined }), 'credential_invalid_private_key'],
  ['garbage private_key', enc({ ...SA, private_key: '-----BEGIN PRIVATE KEY-----\nAAAA\n-----END PRIVATE KEY-----' }), 'credential_invalid_private_key'],
  ['missing token_uri', enc({ ...SA, token_uri: undefined }), 'credential_invalid_token_uri'],
  ['non-Google token_uri (attacker URL) rejected', enc({ ...SA, token_uri: 'https://evil.example.com/token' }), 'credential_invalid_token_uri'],
  ['http (not https) Google token_uri rejected', enc({ ...SA, token_uri: 'http://oauth2.googleapis.com/token' }), 'credential_invalid_token_uri'],
]) {
  _resetTokenCache();
  let called = false;
  const c = await codeOf(() => getAccessToken(v, { fetchImpl: async () => { called = true; return { ok: true, json: async () => ({ access_token: 'x' }) }; } }));
  ok(`credential: ${label} -> ${code}, no network call`, c === code && (code === 'credential_invalid_private_key' ? true : !called), c);
}

// --- JWT creation / signing
const now = 1_800_000_000;
const jwt = await createAssertion(parseServiceAccount(B64), now);
const [h, p, s] = jwt.split('.');
ok('JWT header: RS256 / JWT', dec(h).alg === 'RS256' && dec(h).typ === 'JWT');
const cl = dec(p);
ok('JWT claims: iss = client_email, scope = cloud-vision, aud = token_uri', cl.iss === SA.client_email && cl.scope === VISION_SCOPE && VISION_SCOPE === 'https://www.googleapis.com/auth/cloud-vision' && cl.aud === SA.token_uri);
ok('JWT claims: iat = now, exp = now + 3600', cl.iat === now && cl.exp === now + 3600);
const ver = createVerify('RSA-SHA256'); ver.update(`${h}.${p}`);
ok('JWT signature verifies with the matching public key', ver.verify(publicKey, Buffer.from(s, 'base64url')));
const other = generateKeyPairSync('rsa', { modulusLength: 2048 }).publicKey;
const ver2 = createVerify('RSA-SHA256'); ver2.update(`${h}.${p}`);
ok('JWT signature does NOT verify with another key', !ver2.verify(other, Buffer.from(s, 'base64url')));

// --- token exchange + caching
_resetTokenCache();
let calls = [];
const tokenOk = async (url, init) => { calls.push({ url, init }); return { ok: true, status: 200, json: async () => ({ access_token: 'ya29.TEST-ACCESS-TOKEN', expires_in: 3600 }) }; };
let t = now;
const tok = await getAccessToken(B64, { fetchImpl: tokenOk, nowS: () => t });
const form = new URLSearchParams(calls[0].init.body);
ok('token exchange: POST to the credential token_uri with the JWT bearer grant', calls[0].url === SA.token_uri && calls[0].init.method === 'POST' && form.get('grant_type') === 'urn:ietf:params:oauth:grant-type:jwt-bearer' && form.get('assertion').split('.').length === 3);
ok('token exchange: returns the access token', tok === 'ya29.TEST-ACCESS-TOKEN');
t = now + 3000; await getAccessToken(B64, { fetchImpl: tokenOk, nowS: () => t });
ok('cache: reused inside the expiry window (no second exchange)', calls.length === 1);
t = now + 3400; await getAccessToken(B64, { fetchImpl: tokenOk, nowS: () => t });
ok('cache: refreshed within the 5-minute safety margin before expiry', calls.length === 2);

for (const [label, impl] of [
  ['HTTP 400 invalid_grant', async () => ({ ok: false, status: 400, json: async () => ({ error: 'invalid_grant', error_description: 'Invalid JWT Signature.' }) })],
  ['200 without access_token', async () => ({ ok: true, status: 200, json: async () => ({}) })],
  ['network error', async () => { throw new Error('ECONNRESET ' + KEY_BODY); }],
  ['non-JSON body', async () => ({ ok: true, status: 200, json: async () => { throw new Error('bad json'); } })],
]) {
  _resetTokenCache();
  let err;
  try { await getAccessToken(B64, { fetchImpl: impl }); } catch (e) { err = e; }
  ok(`token exchange failure (${label}) -> token_exchange_failed, no secret in error`, err?.code === 'token_exchange_failed' && !leaks(err.message) && !leaks(err.stack) && !leaks(JSON.stringify(err)), err?.message);
}

// --- Vision call
let vreq;
const vision = await annotateImage('aW1n', 'ya29.TEST-ACCESS-TOKEN', { fetchImpl: async (url, init) => { vreq = { url, init }; return { ok: true, status: 200, json: async () => ({ responses: [{ fullTextAnnotation: { text: 'VAB 1234', pages: [] } }] }) }; } });
ok('Vision: Bearer token in the Authorization header, NO key in the URL', vreq.init.headers.authorization === 'Bearer ya29.TEST-ACCESS-TOKEN' && vreq.url === 'https://vision.googleapis.com/v1/images:annotate' && !vreq.url.includes('key='));
ok('Vision: DOCUMENT_TEXT_DETECTION requested', JSON.parse(vreq.init.body).requests[0].features[0].type === 'DOCUMENT_TEXT_DETECTION' && !!vision.responses);
for (const [label, impl] of [
  ['HTTP 403', async () => ({ ok: false, status: 403, json: async () => ({ error: { message: 'PERMISSION_DENIED' } }) })],
  ['per-image error', async () => ({ ok: true, status: 200, json: async () => ({ responses: [{ error: { message: 'Bad image data.' } }] }) })],
  ['network error', async () => { throw new Error('socket hang up'); }],
]) {
  let err;
  try { await annotateImage('aW1n', 'ya29.TEST-ACCESS-TOKEN', { fetchImpl: impl }); } catch (e) { err = e; }
  ok(`Vision failure (${label}) -> vision_failed, token not in error`, err?.code === 'vision_failed' && !leaks(err.message) && !leaks(err.stack), err?.message);
}

// --- OCR failure cannot produce a verified status: screen() throws, so the
// Edge Function records nothing (record_marketplace_screening is never
// called) and the driver stays pending (proven server-side in
// tests/staging/marketplace_verification "nothing screened yet -> pending").
let recorded = false;
const record = () => { recorded = true; };
const deps = { extractLicenceFrontBack, extractPlates, download: async () => new Uint8Array([1]) };
for (const [label, ocr] of [
  ['token exchange fails', async () => { throw new ScreeningUnavailable('token_exchange_failed'); }],
  ['Vision fails on the BACK side only', (() => { let n = 0; return async () => { if (++n === 2) throw new ScreeningUnavailable('vision_failed'); return { text: 'NAMA\nX', confidence: 0.99 }; }; })()],
  ['credential invalid', async () => { throw new ScreeningUnavailable('credential_invalid_private_key'); }],
]) {
  let out = null, err;
  try { out = await screen({ ...deps, ocr, licence: { front: 'f', back: 'b' }, vehicle: 'v' }); if (out.licence || out.plate) record(); } catch (e) { err = e; }
  ok(`OCR failure (${label}) -> nothing recorded (stays pending, never verified)`, !out && err instanceof ScreeningUnavailable && !recorded, err?.code);
}
const unreadable = await screen({ ...deps, ocr: async () => visionText({ responses: [{}] }), licence: { front: 'f', back: 'b' }, vehicle: 'v' });
ok('empty OCR text -> text_found false + no plates (SQL rules: RETAKE, never verified)', unreadable.licence.text_found === false && unreadable.plate.plates.length === 0, JSON.stringify(unreadable));

// --- no secrets in source / no API key dependency
import { readFileSync } from 'node:fs';
const idx = readFileSync(new URL('../supabase/functions/verify-marketplace-driver/index.ts', import.meta.url), 'utf8');
const ga = readFileSync(new URL('../supabase/functions/verify-marketplace-driver/google_auth.mjs', import.meta.url), 'utf8');
ok('old GOOGLE_VISION_API_KEY dependency removed (no ?key= URL)', !idx.includes('GOOGLE_VISION_API_KEY') && !idx.includes('?key=') && !ga.includes('?key='));
ok('Edge Function reads GOOGLE_VISION_SERVICE_ACCOUNT_JSON', idx.includes("Deno.env.get('GOOGLE_VISION_SERVICE_ACCOUNT_JSON')"));
ok('no console logging of credential / token / assertion', !/console\.(log|error|warn|info)\([^)]*(credential|token|assertion|private_key|access_token)\b/i.test(idx.replace("console.error('screening unavailable', e instanceof ScreeningUnavailable ? e.code : 'unexpected')", '')) && !/console\./.test(ga));
ok('responses never include secret material (only status/retake/error codes)', !/json\(\{[^}]*(token|credential|assertion|private)/i.test(idx));

console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
process.exit(fails ? 1 : 0);
