// Marketplace Verification V1 screening (Founder 2026-10-06).
// Driver calls this after submitting IC + licence FRONT + BACK and/or vehicle
// type + plate + ONE live photo. Server-side only. Google Cloud Vision is
// called with a short-lived OAuth token from the dedicated service account
// (secret GOOGLE_VISION_SERVICE_ACCOUNT_JSON, raw JSON) — never exposed to the
// client, never logged, never returned. This function only extracts fields;
// record_marketplace_screening (service_role) applies the rules. If anything
// fails nothing is recorded, so a driver can never be verified by a failure.
// No biometric processing of any kind.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { extractLicenceFrontBack, extractPlates, visionText } from './extract.mjs';
import { annotateImage, getAccessToken, parseServiceAccount, screen, ScreeningUnavailable } from './google_auth.mjs';

const BUCKET = 'cefflo-driver-documents';
const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, 'content-type': 'application/json' } });

function toBase64(bytes: Uint8Array) {
  let bin = '';
  for (let i = 0; i < bytes.length; i += 0x8000) bin += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  return btoa(bin);
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: cors });
  if (req.method !== 'POST') return json({ error: 'method not allowed' }, 405);
  const credential = Deno.env.get('GOOGLE_VISION_SERVICE_ACCOUNT_JSON');
  const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const jwt = (req.headers.get('authorization') || '').replace(/^Bearer\s+/i, '');
  const { data: who } = await admin.auth.getUser(jwt);
  const uid = who?.user?.id;
  if (!uid) return json({ error: 'authentication required' }, 401);
  try {
    parseServiceAccount(credential);
  } catch (_) {
    return json({ error: 'screening unavailable' }, 503); // stays pending
  }

  const { data: v } = await admin.from('driver_marketplace_verifications')
    .select('status, licence_result, plate_result, vehicle_photo_path').eq('user_id', uid).maybeSingle();
  if (!v || ['verified', 'rejected'].includes(v.status)) return json({ status: v?.status ?? 'not_started' });
  const { data: lic } = await admin.from('driver_licences').select('front_path, back_path').eq('user_id', uid).maybeSingle();

  let result;
  try {
    result = await screen({
      licence: lic?.front_path && lic?.back_path && !v.licence_result ? { front: lic.front_path, back: lic.back_path } : null,
      vehicle: v.vehicle_photo_path && !v.plate_result ? v.vehicle_photo_path : null,
      download: async (path: string) => {
        const { data } = await admin.storage.from(BUCKET).download(path);
        if (!data) throw new ScreeningUnavailable('image_missing');
        return new Uint8Array(await data.arrayBuffer());
      },
      ocr: async (bytes: Uint8Array) =>
        visionText(await annotateImage(toBase64(bytes), await getAccessToken(credential))),
      extractLicenceFrontBack,
      extractPlates,
    });
  } catch (e) {
    // fixed code only (never secret material); the driver stays pending
    console.error('screening unavailable', e instanceof ScreeningUnavailable ? e.code : 'unexpected');
    return json({ error: 'screening unavailable' }, 503);
  }
  if (!result.licence && !result.plate) return json({ status: v.status });
  const { data, error } = await admin.rpc('record_marketplace_screening', { p_user_id: uid, p_licence: result.licence, p_plate: result.plate });
  if (error) return json({ error: 'record failed' }, 500);
  // user-facing only: status + which step to retake (no evidence)
  return json({ status: data.status, retake: data.retake });
});
