// Unit tests: restricted Google Vision API key for verify-marketplace-driver.
// A FAKE key generated at run time — never the real one. No network.
import { randomBytes } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { ScreeningUnavailable, VISION_URL, requireApiKey, annotateImage, screen } from '../supabase/functions/verify-marketplace-driver/vision.mjs';
import { extractLicenceFrontBack, extractPlates, visionText } from '../supabase/functions/verify-marketplace-driver/extract.mjs';

const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${x ? '  -> ' + String(x).slice(0, 200) : ''}`); if (!c) fails++; };
const KEY = 'AIzaTEST' + randomBytes(16).toString('hex');
const leaks = e => [e?.message, e?.stack, JSON.stringify(e ?? {})].some(s => String(s).includes(KEY));
const codeOf = async f => { try { await f(); return 'no-error'; } catch (e) { return e instanceof ScreeningUnavailable ? e.code : 'other'; } };

// 1. missing / bad key -> unavailable, no network call
for (const [label, k] of [['missing', undefined], ['empty', ''], ['whitespace', '   '], ['too short', 'abc'], ['contains spaces', 'AIza bad key value with spaces']]) {
  let called = false;
  const c = await codeOf(() => annotateImage('aW1n', k, { fetchImpl: async () => { called = true; } }));
  ok(`missing/invalid key (${label}) -> credential_missing, no Vision call`, c === 'credential_missing' && !called, c);
}
ok('valid-looking key accepted', requireApiKey(KEY) === KEY);

// request shape: key in header, not URL
let req;
const good = await annotateImage('aW1n', KEY, { fetchImpl: async (url, init) => { req = { url, init }; return { ok: true, status: 200, json: async () => ({ responses: [{ fullTextAnnotation: { text: 'VAB 1234', pages: [] } }] }) }; } });
ok('Vision endpoint images:annotate, key in x-goog-api-key header, NOT in the URL', req.url === VISION_URL && req.url === 'https://vision.googleapis.com/v1/images:annotate' && req.init.headers['x-goog-api-key'] === KEY && !req.url.includes(KEY) && !req.url.includes('key='));
ok('DOCUMENT_TEXT_DETECTION requested; body carries no key', JSON.parse(req.init.body).requests[0].features[0].type === 'DOCUMENT_TEXT_DETECTION' && !req.init.body.includes(KEY) && !!good.responses);

// 2/3. invalid response + network failure -> vision_failed, no key in error
for (const [label, impl] of [
  ['HTTP 400 API key not valid', async () => ({ ok: false, status: 400, json: async () => ({ error: { message: `API key not valid. key=${KEY}` } }) })],
  ['HTTP 403 restricted', async () => ({ ok: false, status: 403, json: async () => ({ error: { message: 'PERMISSION_DENIED' } }) })],
  ['per-image error', async () => ({ ok: true, status: 200, json: async () => ({ responses: [{ error: { message: 'Bad image data.' } }] }) })],
  ['no responses array', async () => ({ ok: true, status: 200, json: async () => ({}) })],
  ['non-JSON body', async () => ({ ok: true, status: 200, json: async () => { throw new Error('bad json ' + KEY); } })],
  ['network failure', async () => { throw new Error(`ECONNRESET ${VISION_URL} ${KEY}`); }],
]) {
  let err;
  try { await annotateImage('aW1n', KEY, { fetchImpl: impl }); } catch (e) { err = e; }
  ok(`Vision failure (${label}) -> vision_failed, key not in error`, err?.code === 'vision_failed' && err.message === 'vision_failed' && !leaks(err), err?.message);
}

// sanitized Google status: enum only, never the free-text message / key
{
  let e1; try { await annotateImage('aW1n', KEY, { fetchImpl: async () => ({ ok: false, status: 400, json: async () => ({ error: { status: 'INVALID_ARGUMENT', message: `API key not valid ${KEY}`, details: [{ reason: 'API_KEY_INVALID' }] } }) }) }); } catch (e) { e1 = e; }
  ok('Google error -> googleStatus = API_KEY_INVALID (reason enum), message/key dropped', e1?.googleStatus === 'API_KEY_INVALID' && !leaks(e1) && !JSON.stringify(e1).includes('not valid'), e1?.googleStatus);
  let e2; try { await annotateImage('aW1n', KEY, { fetchImpl: async () => ({ ok: false, status: 403, json: async () => ({ error: { status: 'PERMISSION_DENIED', message: 'Cloud Vision API has not been used' } }) }) }); } catch (e) { e2 = e; }
  ok('Google error without reason -> googleStatus = PERMISSION_DENIED', e2?.googleStatus === 'PERMISSION_DENIED');
  let e3; try { await annotateImage('aW1n', KEY, { fetchImpl: async () => ({ ok: false, status: 400, json: async () => ({ error: { status: `bad ${KEY}` } }) }) }); } catch (e) { e3 = e; }
  ok('non-enum Google status is never passed through (key cannot leak via status)', e3?.googleStatus === null && !leaks(e3));
}

// OCR failure never produces a verified status: screen() throws -> the Edge
// Function records nothing (driver stays pending; proven server-side in
// tests/staging/marketplace_verification "nothing screened yet -> pending").
const deps = { extractLicenceFrontBack, extractPlates, download: async () => new Uint8Array([1]) };
for (const [label, ocr] of [
  ['key missing', async () => { throw new ScreeningUnavailable('credential_missing'); }],
  ['Vision fails on the BACK side only', (() => { let n = 0; return async () => { if (++n === 2) throw new ScreeningUnavailable('vision_failed'); return { text: 'NAMA\nX', confidence: 0.99 }; }; })()],
  ['Vision fails on the vehicle photo', (() => { let n = 0; return async () => { if (++n === 3) throw new ScreeningUnavailable('vision_failed'); return { text: 'NAMA\nX', confidence: 0.99 }; }; })()],
]) {
  let out = null, err;
  try { out = await screen({ ...deps, ocr, licence: { front: 'f', back: 'b' }, vehicle: 'v' }); } catch (e) { err = e; }
  ok(`OCR failure (${label}) -> nothing to record (stays pending, never verified)`, out === null && err instanceof ScreeningUnavailable, err?.code);
}
const unreadable = await screen({ ...deps, ocr: async () => visionText({ responses: [{}] }), licence: { front: 'f', back: 'b' }, vehicle: 'v' });
ok('empty OCR text -> text_found false + no plates (SQL: RETAKE, never verified)', unreadable.licence.text_found === false && unreadable.plate.plates.length === 0);

// source checks
const idx = readFileSync(new URL('../supabase/functions/verify-marketplace-driver/index.ts', import.meta.url), 'utf8');
const vis = readFileSync(new URL('../supabase/functions/verify-marketplace-driver/vision.mjs', import.meta.url), 'utf8');
ok('reads GOOGLE_VISION_API_KEY server-side', idx.includes("Deno.env.get('GOOGLE_VISION_API_KEY')"));
ok('service-account / OAuth code removed', !/SERVICE_ACCOUNT|oauth2|createAssertion|private_key/.test(idx + vis));
ok('no logging of the key', !/console\./.test(vis) && !/console\.[a-z]+\([^)]*apiKey/.test(idx));
ok('responses never carry the key', !/json\(\{[^}]*apiKey/.test(idx) && !/json\(\{[^}]*e\.message/.test(idx));

console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
process.exit(fails ? 1 : 0);
