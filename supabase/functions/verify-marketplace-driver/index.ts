// Marketplace Verification V1 screening (Founder 2026-10-06).
// Driver calls this after submitting IC + licence FRONT + BACK and/or vehicle
// type + plate + ONE live photo. Server-side only: the Google Cloud Vision
// key (GOOGLE_VISION_API_KEY) never reaches the client. This function only
// extracts fields; record_marketplace_screening (service_role) applies the
// rules. If OCR fails nothing is recorded, so a driver can never be
// verified by a failure. No biometric processing of any kind.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { extractLicenceFrontBack, extractPlates, visionText } from './extract.mjs';

const BUCKET = 'cefflo-driver-documents';
const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, 'content-type': 'application/json' } });

async function ocr(bytes: Uint8Array, key: string) {
  let bin = '';
  for (let i = 0; i < bytes.length; i += 0x8000) bin += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  const r = await fetch(`https://vision.googleapis.com/v1/images:annotate?key=${key}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      requests: [{ image: { content: btoa(bin) }, features: [{ type: 'DOCUMENT_TEXT_DETECTION' }], imageContext: { languageHints: ['ms', 'en'] } }],
    }),
  });
  if (!r.ok) throw new Error(`vision ${r.status}`);
  const body = await r.json();
  if (body?.responses?.[0]?.error) throw new Error('vision error');
  return visionText(body);
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: cors });
  if (req.method !== 'POST') return json({ error: 'method not allowed' }, 405);
  const key = Deno.env.get('GOOGLE_VISION_API_KEY');
  const url = Deno.env.get('SUPABASE_URL')!;
  const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const jwt = (req.headers.get('authorization') || '').replace(/^Bearer\s+/i, '');
  const { data: who } = await admin.auth.getUser(jwt);
  const uid = who?.user?.id;
  if (!uid) return json({ error: 'authentication required' }, 401);
  if (!key) return json({ error: 'screening not configured' }, 503);

  const { data: v } = await admin.from('driver_marketplace_verifications')
    .select('status, licence_result, plate_result, vehicle_photo_path').eq('user_id', uid).maybeSingle();
  if (!v || ['verified', 'rejected'].includes(v.status)) return json({ status: v?.status ?? 'not_started' });
  const { data: lic } = await admin.from('driver_licences').select('front_path, back_path').eq('user_id', uid).maybeSingle();

  let licence = null, plate = null;
  try {
    if (lic?.front_path && lic?.back_path && !v.licence_result) {
      const side = async (path: string) => {
        const { data } = await admin.storage.from(BUCKET).download(path);
        if (!data) throw new Error('missing image');
        return ocr(new Uint8Array(await data.arrayBuffer()), key);
      };
      licence = extractLicenceFrontBack(await side(lic.front_path), await side(lic.back_path));
    }
    if (v.vehicle_photo_path && !v.plate_result) {
      const { data } = await admin.storage.from(BUCKET).download(v.vehicle_photo_path);
      if (data) plate = extractPlates(await ocr(new Uint8Array(await data.arrayBuffer()), key));
    }
  } catch (_) {
    return json({ error: 'screening unavailable' }, 503); // stays pending
  }
  if (!licence && !plate) return json({ status: v.status });
  const { data, error } = await admin.rpc('record_marketplace_screening', { p_user_id: uid, p_licence: licence, p_plate: plate });
  if (error) return json({ error: 'record failed' }, 500);
  // user-facing only: status + which step to retake (no evidence)
  return json({ status: data.status, retake: data.retake });
});
