// complaint-photos — a customer adds up to 5 photos to the complaint they
// filed from the tracking page. No account: the tracking token proves the
// order, and the complaint must be the customer's own for that order.
//   POST ← { token, complaint_id, photos: [{ type, data (base64) }] }
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const CORS = { 'access-control-allow-origin': '*', 'access-control-allow-headers': 'apikey, authorization, content-type', 'access-control-allow-methods': 'POST, OPTIONS' };
const json = (v: unknown, status = 200) => new Response(JSON.stringify(v), { status, headers: { 'content-type': 'application/json', ...CORS } });
const TYPES: Record<string, string> = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' };
const MAX = 5 * 1024 * 1024;

async function sha256(s: string) {
  const d = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(s));
  return [...new Uint8Array(d)].map(b => b.toString(16).padStart(2, '0')).join('');
}

Deno.serve(async req => {
  if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS });
  if (req.method !== 'POST') return json({ error: 'not found' }, 404);
  const { token, complaint_id, photos } = await req.json().catch(() => ({}));
  if (typeof token !== 'string' || typeof complaint_id !== 'string' || !Array.isArray(photos) || !photos.length) return json({ error: 'bad request' }, 400);
  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, { auth: { persistSession: false } });

  const { data: t } = await db.from('tracking_tokens').select('order_id, revoked_at, expires_at').eq('token_hash', await sha256(token)).maybeSingle();
  if (!t || t.revoked_at || (t.expires_at && new Date(t.expires_at) < new Date())) return json({ error: 'invalid tracking token' }, 403);
  const { data: c } = await db.from('complaints').select('id, order_id, complainant_role, status').eq('id', complaint_id).maybeSingle();
  if (!c || c.order_id !== t.order_id || c.complainant_role !== 'customer' || c.status === 'resolved') return json({ error: 'forbidden' }, 403);
  const { count } = await db.from('complaint_entries').select('id', { count: 'exact', head: true }).eq('complaint_id', c.id).eq('kind', 'photo');
  if ((count ?? 0) + photos.length > 5) return json({ error: 'up to 5 photos' }, 400);

  let saved = 0;
  for (const p of photos) {
    const ext = TYPES[p?.type];
    if (!ext || typeof p.data !== 'string') continue;
    const bytes = Uint8Array.from(atob(p.data), ch => ch.charCodeAt(0));
    if (bytes.length > MAX) continue;
    const path = `customer/${c.id}/${crypto.randomUUID()}.${ext}`;
    const { error } = await db.storage.from('cefflo-complaint-evidence').upload(path, bytes, { contentType: p.type });
    if (error) { console.error(error.message); continue; }
    await db.from('complaint_entries').insert({ complaint_id: c.id, kind: 'photo', author_role: 'complainant', file_path: path });
    saved++;
  }
  return json({ saved });
});
