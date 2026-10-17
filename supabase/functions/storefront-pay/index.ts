// Storefront online payment (Founder 2026-10-17): a Curlec Payment Link on the
// VENDOR's own Curlec account (Razorpay API, Basic auth key_id:key_secret).
// Cefflo never holds the money. Input: { slug, idempotency_key }. The amount is
// computed here from the order's price snapshot, never from the browser.
// Curlec links must live at least 15 minutes; Cefflo's window is 5 minutes and
// curlec-sync cancels the link when it passes.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

const API = 'https://api.razorpay.com/v1';
const WINDOW_SECONDS = 300;
const LINK_MIN_SECONDS = 16 * 60;

const cors = (origin: string | null) => ({
  'Access-Control-Allow-Origin': origin || '*',
  'Access-Control-Allow-Headers': 'apikey, authorization, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  Vary: 'Origin',
});
const json = (body: unknown, status: number, origin: string | null) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json', ...cors(origin) } });

Deno.serve(async (req) => {
  const origin = req.headers.get('Origin');
  if (req.method === 'OPTIONS') return new Response(null, { headers: cors(origin) });
  if (req.method !== 'POST') return json({ error: 'method not allowed' }, 405, origin);
  let input: { slug?: string; idempotency_key?: string };
  try { input = await req.json(); } catch { return json({ error: 'bad request' }, 400, origin); }
  const slug = String(input.slug || '').toLowerCase();
  const key = String(input.idempotency_key || '');
  if (!/^[a-z0-9-]{3,30}$/.test(slug) || !/^[0-9a-f-]{36}$/i.test(key)) return json({ error: 'bad request' }, 400, origin);

  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const { data: page } = await db.from('public_order_pages').select('business_id, slug, delivery_fee').eq('slug', slug).maybeSingle();
  if (!page) return json({ error: 'not found' }, 404, origin);
  const { data: order } = await db.from('orders')
    .select('id, public_ref, items, payment_status, customer_name, customer_phone')
    .eq('business_id', page.business_id).eq('submission_idempotency_key', key).maybeSingle();
  if (!order) return json({ error: 'order not found' }, 404, origin);
  if (order.payment_status === 'paid') return json({ paid: true }, 200, origin);
  if (order.payment_status !== 'awaiting_payment') return json({ error: 'order is not awaiting payment' }, 409, origin);

  const { data: acct } = await db.from('vendor_payment_accounts').select('key_id, key_secret').eq('business_id', page.business_id).maybeSingle();
  if (!acct) return json({ error: 'online payment unavailable' }, 409, origin);
  const auth = { Authorization: `Basic ${btoa(`${acct.key_id}:${acct.key_secret}`)}`, 'Content-Type': 'application/json' };

  // Reuse a live link (the customer pressed Pay twice).
  const { data: live } = await db.from('storefront_payments').select('provider_ref, expires_at')
    .eq('order_id', order.id).eq('status', 'pending').gt('expires_at', new Date().toISOString()).maybeSingle();
  if (live?.provider_ref) {
    const r = await fetch(`${API}/payment_links/${live.provider_ref}`, { headers: auth });
    const l = await r.json().catch(() => null);
    if (r.ok && l?.short_url && l.status === 'created') return json({ checkout_url: l.short_url, expires_at: live.expires_at }, 200, origin);
  }

  const { data: sub } = await db.from('storefront_subscriptions').select('id, delivery_fee').eq('first_order_id', order.id).maybeSingle();
  let drops = 1;
  if (sub) {
    const { count } = await db.from('storefront_subscription_days').select('id', { count: 'exact', head: true }).eq('subscription_id', sub.id);
    drops = Math.max(1, count || 1);
  }
  const goods = (order.items as Array<{ line_subtotal_snapshot: number }>).reduce((s, l) => s + Math.round(Number(l.line_subtotal_snapshot) * 100), 0);
  const fee = Math.round(Number((sub?.delivery_fee ?? page.delivery_fee) || 0) * 100);
  const amount = (goods + fee) * drops;
  if (amount <= 0) return json({ error: 'invalid amount' }, 409, origin);

  const fnBase = `${Deno.env.get('SUPABASE_URL')}/functions/v1`;
  const now = Math.floor(Date.now() / 1000);
  let contact = String(order.customer_phone || '').replace(/[^0-9+]/g, '');
  if (/^0\d/.test(contact)) contact = `+6${contact}`;
  const body = {
    amount, currency: 'MYR', accept_partial: false,
    reference_id: `${order.public_ref}-${now}`.slice(0, 40),
    description: `${order.public_ref}${drops > 1 ? `, ${drops} deliveries` : ''}`,
    customer: { name: order.customer_name, contact },
    notify: { sms: false, email: false }, reminder_enable: false,
    expire_by: now + LINK_MIN_SECONDS,
    callback_url: `${fnBase}/curlec-return?slug=${encodeURIComponent(page.slug)}&key=${key}`,
    callback_method: 'get',
    notes: { cefflo_order: order.public_ref },
  };
  const r = await fetch(`${API}/payment_links`, { method: 'POST', headers: auth, body: JSON.stringify(body) });
  const l = await r.json().catch(() => null);
  if (!r.ok || !l?.id || !l?.short_url) {
    console.error('curlec link failed', r.status, JSON.stringify(l)?.slice(0, 300));
    return json({ error: 'payment provider error' }, 502, origin);
  }
  const expires = new Date((now + WINDOW_SECONDS) * 1000).toISOString();
  await db.from('storefront_payments').insert({ business_id: page.business_id, order_id: order.id, provider_ref: l.id, amount_cents: amount, expires_at: expires });
  return json({ checkout_url: l.short_url, expires_at: expires }, 200, origin);
});
