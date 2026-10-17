// Runs every minute (pg_cron + pg_net, secret header). For each pending
// storefront payment: if Curlec says paid, mark it paid (covers customers who
// closed the tab before returning); once Cefflo's 5-minute window has passed,
// cancel the Curlec link so it cannot be paid later.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

const API = 'https://api.razorpay.com/v1';

Deno.serve(async (req) => {
  const secret = Deno.env.get('CEFFLO_CRON_SECRET') || '';
  if (!secret || req.headers.get('x-cron-secret') !== secret) return new Response('forbidden', { status: 403 });
  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const since = new Date(Date.now() - 30 * 60 * 1000).toISOString();
  const { data: rows } = await db.from('storefront_payments')
    .select('id, business_id, provider_ref, amount_cents, expires_at, status')
    .in('status', ['pending', 'expired']).gt('created_at', since).limit(200);
  let paid = 0, cancelled = 0;
  const keys = new Map<string, string | null>();
  for (const p of rows || []) {
    if (!keys.has(p.business_id)) {
      const { data: a } = await db.from('vendor_payment_accounts').select('key_id, key_secret').eq('business_id', p.business_id).maybeSingle();
      keys.set(p.business_id, a ? `Basic ${btoa(`${a.key_id}:${a.key_secret}`)}` : null);
    }
    const auth = keys.get(p.business_id);
    if (!auth) continue;
    const r = await fetch(`${API}/payment_links/${p.provider_ref}`, { headers: { Authorization: auth } });
    const l = await r.json().catch(() => null);
    if (!r.ok || !l) continue;
    if (l.status === 'paid' && Number(l.amount_paid) >= p.amount_cents) {
      await db.rpc('_storefront_mark_paid', { p_payment_id: p.id }); paid++;
    } else if (l.status === 'created' && new Date(p.expires_at).getTime() < Date.now()) {
      const c = await fetch(`${API}/payment_links/${p.provider_ref}/cancel`, { method: 'POST', headers: { Authorization: auth, 'Content-Type': 'application/json' }, body: '{}' });
      if (c.ok) cancelled++;
    }
  }
  return new Response(JSON.stringify({ checked: rows?.length || 0, paid, cancelled }), { headers: { 'Content-Type': 'application/json' } });
});
