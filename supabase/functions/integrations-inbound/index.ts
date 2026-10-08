import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Integrations Phase 1 inbound endpoint (docs/cefflo/security/INTEGRATIONS_PHASE1_PROPOSAL.md).
//   POST /integrations-inbound/api/orders            Authorization: Bearer cfk_live_…
//   POST /integrations-inbound/woocommerce/{conn_id}  X-WC-Webhook-Signature
//   POST /integrations-inbound/shopify/{conn_id}      X-Shopify-Hmac-Sha256 + X-Shopify-Shop-Domain
// The business always comes from the server-side connection/key, never from the payload.

const MAX_BODY = 64 * 1024;
const enc = new TextEncoder();

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });

async function sha256Hex(s: string) {
  const d = await crypto.subtle.digest('SHA-256', enc.encode(s));
  return [...new Uint8Array(d)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

async function hmacBase64(secret: string, body: string) {
  const key = await crypto.subtle.importKey('raw', enc.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign('HMAC', key, enc.encode(body));
  return btoa(String.fromCharCode(...new Uint8Array(sig)));
}

function safeEqual(a: string, b: string) {
  if (!a || !b || a.length !== b.length) return false;
  let r = 0;
  for (let i = 0; i < a.length; i++) r |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return r === 0;
}

const str = (v: unknown) => (typeof v === 'string' ? v : v == null ? '' : String(v));
const joinAddr = (a: Record<string, unknown> = {}) =>
  [a.address_1 ?? a.address1, a.address_2 ?? a.address2, a.city, a.postcode ?? a.zip, a.state ?? a.province, a.country]
    .map(str).map((x) => x.trim()).filter(Boolean).join(', ');

// Provider payload → Cefflo normalised order.
function fromWoo(p: Record<string, any>) {
  const ship = p.shipping && (p.shipping.address_1 || p.shipping.city) ? p.shipping : p.billing || {};
  return {
    external_id: str(p.id),
    order: {
      customer_name: [ship.first_name, ship.last_name].map(str).join(' ').trim() || [p.billing?.first_name, p.billing?.last_name].map(str).join(' ').trim(),
      customer_phone: str(ship.phone || p.billing?.phone),
      delivery_address: joinAddr(ship),
      notes: str(p.customer_note),
      items: (Array.isArray(p.line_items) ? p.line_items : []).map((l: any) => ({ name: str(l.name), quantity: Number(l.quantity), price: Number(l.price ?? 0) })),
    },
  };
}

function fromShopify(p: Record<string, any>) {
  const ship = p.shipping_address || p.billing_address || {};
  return {
    external_id: str(p.id),
    order: {
      customer_name: str(ship.name) || [p.customer?.first_name, p.customer?.last_name].map(str).join(' ').trim(),
      customer_phone: str(ship.phone || p.phone || p.customer?.phone),
      delivery_address: joinAddr(ship),
      notes: str(p.note),
      items: (Array.isArray(p.line_items) ? p.line_items : []).map((l: any) => ({ name: str(l.title || l.name), quantity: Number(l.quantity), price: Number(l.price ?? 0) })),
    },
  };
}

function fromApi(p: Record<string, any>) {
  return {
    external_id: str(p.external_id),
    order: {
      customer_name: str(p.customer_name),
      customer_phone: str(p.customer_phone),
      delivery_address: str(p.delivery_address),
      notes: str(p.notes),
      items: (Array.isArray(p.items) ? p.items : []).map((l: any) => ({ name: str(l.name), quantity: Number(l.quantity), price: Number(l.price ?? 0) })),
    },
  };
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json(405, { error: 'method not allowed' });
  const url = new URL(req.url);
  const parts = url.pathname.split('/').filter(Boolean);
  const i = parts.indexOf('integrations-inbound');
  const [kind, arg] = parts.slice(i + 1);

  const raw = await req.text();
  if (raw.length > MAX_BODY) return json(413, { error: 'payload too large' });
  let payload: Record<string, any>;
  try { payload = JSON.parse(raw); } catch { return json(400, { error: 'invalid json' }); }
  if (!payload || typeof payload !== 'object' || Array.isArray(payload)) return json(400, { error: 'invalid payload' });

  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, { auth: { persistSession: false } });
  let connectionId: string;
  let norm: { external_id: string; order: unknown };

  if (kind === 'api' && arg === 'orders') {
    const key = (req.headers.get('authorization') || '').replace(/^Bearer\s+/i, '').trim();
    if (!/^cfk_live_[0-9a-f]{48}$/.test(key)) return json(401, { error: 'invalid api key' });
    const { data: hit } = await db.rpc('_integration_resolve_key', { p_key_hash: await sha256Hex(key) });
    if (!hit) return json(401, { error: 'invalid api key' });
    const { data: ok } = await db.rpc('check_rate_limit', { p_key_hash: await sha256Hex('intkey:' + hit.key_id), p_action: 'integration_api', p_window_seconds: 60, p_max_requests: 60 });
    if (ok === false) return json(429, { error: 'rate limited' });
    connectionId = hit.connection_id;
    norm = fromApi(payload);
  } else if ((kind === 'woocommerce' || kind === 'shopify') && /^[0-9a-f-]{36}$/.test(arg || '')) {
    const { data: t } = await db.rpc('_integration_webhook_target', { p_connection: arg, p_provider: kind });
    if (!t) return json(404, { error: 'not found' });
    const { data: ok } = await db.rpc('check_rate_limit', { p_key_hash: await sha256Hex('intconn:' + t.connection_id), p_action: 'integration_webhook', p_window_seconds: 60, p_max_requests: 120 });
    if (ok === false) return json(429, { error: 'rate limited' });
    const expected = await hmacBase64(t.secret, raw);
    if (kind === 'woocommerce') {
      // WooCommerce sends a ping (webhook_id only) when the webhook is saved.
      if (!req.headers.get('x-wc-webhook-signature') && payload.webhook_id) return json(200, { ok: true });
      if (!safeEqual(req.headers.get('x-wc-webhook-signature') || '', expected)) {
        await db.rpc('_integration_reject', { p_connection: t.connection_id, p_external: str(payload.id), p_reason: 'bad signature' });
        return json(401, { error: 'invalid signature' });
      }
      norm = fromWoo(payload);
    } else {
      const shop = (req.headers.get('x-shopify-shop-domain') || '').toLowerCase();
      if (!safeEqual(req.headers.get('x-shopify-hmac-sha256') || '', expected) || shop !== t.shop_domain) {
        await db.rpc('_integration_reject', { p_connection: t.connection_id, p_external: str(payload.id), p_reason: 'bad signature or shop' });
        return json(401, { error: 'invalid signature' });
      }
      norm = fromShopify(payload);
    }
    connectionId = t.connection_id;
  } else {
    return json(404, { error: 'not found' });
  }

  const { data, error } = await db.rpc('_integration_ingest_order', { p_connection: connectionId, p_external_id: norm.external_id, p_order: norm.order });
  if (error) return json(500, { error: 'ingest failed' });
  if (data?.error) return json(422, { error: data.error });
  return json(data?.duplicate ? 200 : 201, data);
});
