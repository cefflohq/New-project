// business-verification — the owner sends their IC (front and back, taken
// with the camera) and optionally the SSM certificate. The server reads the
// owner's name and IC number from the IC photo (Google Vision, the same
// GOOGLE_VISION_API_KEY as driver screening) so they are never typed. When
// the photo cannot be read, it is saved anyway and Cefflo reads it by eye.
//   POST (signed-in owner) ← { business_id, ic_front_path, ic_back_path, ssm_path? }
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { annotateImage } from './vision.mjs';
import { readMyKad } from './mykad.mjs';

const CORS = { 'access-control-allow-origin': '*', 'access-control-allow-headers': 'authorization, apikey, content-type', 'access-control-allow-methods': 'POST, OPTIONS' };
const json = (v: unknown, status = 200) => new Response(JSON.stringify(v), { status, headers: { 'content-type': 'application/json', ...CORS } });
const URL_ = Deno.env.get('SUPABASE_URL')!;

function toBase64(bytes: Uint8Array) {
  let s = '';
  for (let i = 0; i < bytes.length; i += 0x8000) s += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  return btoa(s);
}

// deno-lint-ignore no-explicit-any
async function readIc(admin: any, path: string) {
  let read = { ic: null as string | null, name: null as string | null };
  let reason = '';
  try {
    const key = Deno.env.get('GOOGLE_VISION_API_KEY');
    if (!key) reason = 'no_key';
    const { data: file } = await admin.storage.from('cefflo-business-documents').download(path);
    if (key && file) read = readMyKad(await annotateImage(toBase64(new Uint8Array(await file.arrayBuffer())), key));
    if (key && file && !(read.ic && read.name)) reason = 'not_found_in_text';
  } catch (e) {
    // Fixed codes only (e.g. PERMISSION_DENIED, API_KEY_INVALID); never the key.
    reason = [(e as Error).message, (e as { googleStatus?: string }).googleStatus ?? ''].filter(Boolean).join(':');
    console.error('ic read skipped', reason);
  }
  return { read, reason };
}

async function reRead(auth: string, businessId: string) {
  const user = createClient(URL_, Deno.env.get('SUPABASE_ANON_KEY')!, { global: { headers: { Authorization: auth } }, auth: { persistSession: false } });
  const { data: isAdmin } = await user.rpc('is_platform_admin');
  if (isAdmin !== true) return json({ error: 'forbidden' }, 403);
  const admin = createClient(URL_, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, { auth: { persistSession: false } });
  const { data: v } = await admin.from('business_verifications').select('ic_front_path, status').eq('business_id', businessId).maybeSingle();
  if (!v || v.status !== 'pending') return json({ error: 'not pending' }, 409);
  const { read, reason } = await readIc(admin, v.ic_front_path);
  const ok = !!(read.ic && read.name);
  // Replace an earlier (possibly wrong) reading with this one.
  await admin.from('business_verifications').update({ owner_name: read.name, owner_ic_last4: read.ic ? read.ic.slice(8) : null, ocr_status: ok ? 'read' : 'unread' }).eq('business_id', businessId);
  return json({ read: ok, owner_name: read.name, owner_ic_last4: read.ic ? read.ic.slice(8) : null, reason: ok ? null : reason });
}

Deno.serve(async req => {
  if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS });
  if (req.method !== 'POST') return json({ error: 'not found' }, 404);
  const auth = req.headers.get('authorization') ?? '';
  const { business_id, ic_front_path, ic_back_path, ssm_path, reread } = await req.json().catch(() => ({}));
  // FOUNDR: a platform admin reads the stored IC again (e.g. after the
  // Vision key or billing was fixed), without the owner resubmitting.
  if (reread === true && typeof business_id === 'string') return reRead(auth, business_id);
  const inFolder = (p: unknown) => typeof p === 'string' && p.split('/')[0] === business_id && !p.includes('..');
  if (typeof business_id !== 'string' || !inFolder(ic_front_path) || !inFolder(ic_back_path) || (ssm_path != null && !inFolder(ssm_path))) {
    return json({ error: 'invalid document' }, 400);
  }
  // Who is calling, and do they own this business?
  const user = createClient(URL_, Deno.env.get('SUPABASE_ANON_KEY')!, { global: { headers: { Authorization: auth } }, auth: { persistSession: false } });
  const { data: me } = await user.auth.getUser();
  if (!me?.user) return json({ error: 'not signed in' }, 401);
  const { data: owner } = await user.rpc('is_business_owner', { p_business: business_id });
  if (owner !== true) return json({ error: 'forbidden' }, 403);

  const admin = createClient(URL_, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, { auth: { persistSession: false } });
  const { data: existing } = await admin.from('business_verifications').select('status').eq('business_id', business_id).maybeSingle();
  if (existing?.status === 'verified') return json({ error: 'business already verified' }, 409);

  const { read } = await readIc(admin, ic_front_path);
  const ok = !!(read.ic && read.name);
  const row = {
    business_id, ic_front_path, ic_back_path, ssm_path: ssm_path ?? null,
    owner_name: read.name, owner_ic_last4: read.ic ? read.ic.slice(8) : null, ocr_status: ok ? 'read' : 'unread',
    status: 'pending', reject_reason: null, submitted_by: me.user.id, submitted_at: new Date().toISOString(),
    reviewed_by: null, reviewed_at: null,
  };
  const { error } = await admin.from('business_verifications').upsert(row, { onConflict: 'business_id' });
  if (error) { console.error(error.message); return json({ error: 'could not save' }, 500); }
  return json({ status: 'pending', read: ok, owner_name: read.name, owner_ic_last4: row.owner_ic_last4 });
});
