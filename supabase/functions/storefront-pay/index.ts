// Storefront online payment (Founder 2026-10-17): creates a CHIP purchase on
// the VENDOR's own CHIP account for an order placed with p_payment='online',
// and returns CHIP's checkout_url. Cefflo never holds the money.
// Input: { slug, idempotency_key }. The amount is computed here from the
// order's own price snapshot (never trusted from the browser): goods and the
// delivery fee, multiplied by the number of package deliveries.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

const CHIP = 'https://gate.chip-in.asia/api/v1';
const WINDOW_SECONDS = 300;

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
    .select('id, public_ref, items, payment_status, customer_name, customer_phone, created_at')
    .eq('business_id', page.business_id).eq('submission_idempotency_key', key).maybeSingle();
  if (!order) return json({ error: 'order not found' }, 404, origin);
  if (order.payment_status === 'paid') return json({ paid: true }, 200, origin);
  if (order.payment_status !== 'awaiting_payment') return json({ error: 'order is not awaiting payment' }, 409, origin);

  // Reuse a live purchase (e.g. the customer pressed Pay twice).
  const { data: live } = await db.from('storefront_payments').select('chip_purchase_id, expires_at')
    .eq('order_id', order.id).eq('status', 'pending').gt('expires_at', new Date().toISOString()).maybeSingle();

  const { data: acct } = await db.from('vendor_payment_accounts').select('brand_id, secret_key').eq('business_id', page.business_id).maybeSingle();
  if (!acct) return json({ error: 'online payment unavailable' }, 409, origin);
  const auth = { Authorization: `Bearer ${acct.secret_key}`, 'Content-Type': 'application/json' };

  if (live?.chip_purchase_id) {
    const r = await fetch(`${CHIP}/purchases/${live.chip_purchase_id}/`, { headers: auth });
    const p = await r.json().catch(() => null);
    if (r.ok && p?.checkout_url) return json({ checkout_url: p.checkout_url, expires_at: live.expires_at }, 200, origin);
  }

  // Package: number of deliveries; a single order = 1.
  const { data: sub } = await db.from('storefront_subscriptions').select('id, delivery_fee').eq('first_order_id', order.id).maybeSingle();
  let drops = 1;
  if (sub) {
    const { count } = await db.from('storefront_subscription_days').select('id', { count: 'exact', head: true }).eq('subscription_id', sub.id);
    drops = Math.max(1, count || 1);
  }
  const goodsCents = (order.items as Array<{ line_subtotal_snapshot: number }>).reduce((s, l) => s + Math.round(Number(l.line_subtotal_snapshot) * 100), 0);
  const feeCents = Math.round(Number((sub?.delivery_fee ?? page.delivery_fee) || 0) * 100);
  const products = [{ name: `Order ${order.public_ref}${drops > 1 ? ` × ${drops} deliveries` : ''}`, price: goodsCents * drops, quantity: 1 }];
  if (feeCents > 0) products.push({ name: `Delivery × ${drops}`, price: feeCents * drops, quantity: 1 });
  const amount = products.reduce((s, p) => s + p.price, 0);
  if (amount <= 0) return json({ error: 'invalid amount' }, 409, origin);

  const fnBase = `${Deno.env.get('SUPABASE_URL')}/functions/v1`;
  const store = (Deno.env.get('CEFFLO_STOREFRONT_BASE_URL') || 'https://order.cefflo.com/').replace(/\/?$/, '/');
  const due = Math.floor(Date.now() / 1000) + WINDOW_SECONDS;
  const digits = String(order.customer_phone || '').replace(/[^0-9]/g, '');
  const body = {
    brand_id: acct.brand_id,
    reference: order.public_ref,
    client: { email: `${digits || 'customer'}@customers.cefflo.com`, phone: order.customer_phone, full_name: order.customer_name },
    purchase: { currency: 'MYR', products, due, due_strict: true },
    success_callback: `${fnBase}/chip-callback?business=${page.business_id}`,
    success_redirect: `${store}${page.slug}#/paid/${key}`,
    failure_redirect: `${store}${page.slug}#/payfail/${key}`,
    cancel_redirect: `${store}${page.slug}#/payfail/${key}`,
  };
  const r = await fetch(`${CHIP}/purchases/`, { method: 'POST', headers: auth, body: JSON.stringify(body) });
  const p = await r.json().catch(() => null);
  if (!r.ok || !p?.id || !p?.checkout_url) {
    console.error('chip purchase failed', r.status, JSON.stringify(p)?.slice(0, 300));
    return json({ error: 'payment provider error' }, 502, origin);
  }
  const expires = new Date(due * 1000).toISOString();
  await db.from('storefront_payments').insert({ business_id: page.business_id, order_id: order.id, chip_purchase_id: p.id, amount_cents: amount, expires_at: expires });
  return json({ checkout_url: p.checkout_url, expires_at: expires }, 200, origin);
});
