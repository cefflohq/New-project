// Live courier rates for a storefront checkout (Founder 2026-10-17), from the
// vendor's own EasyParcel account. Input: { slug, postcode, state, items:
// [{product_id, quantity}] }. Weight comes from the vendor's product weights.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';
import { epCall } from '../_shared/easyparcel.ts';

const STATES = ['jhr','kdh','ktn','mlk','nsn','phg','prk','pls','png','sgr','trg','kul','pjy','srw','sbh','lbn'];
const cors = (o: string | null) => ({ 'Access-Control-Allow-Origin': o || '*', 'Access-Control-Allow-Headers': 'apikey, authorization, content-type', 'Access-Control-Allow-Methods': 'POST, OPTIONS', Vary: 'Origin' });
const json = (b: unknown, s: number, o: string | null) => new Response(JSON.stringify(b), { status: s, headers: { 'Content-Type': 'application/json', ...cors(o) } });

Deno.serve(async (req) => {
  const origin = req.headers.get('Origin');
  if (req.method === 'OPTIONS') return new Response(null, { headers: cors(origin) });
  let i: { slug?: string; postcode?: string; state?: string; items?: { product_id: string; quantity: number }[] };
  try { i = await req.json(); } catch { return json({ error: 'bad request' }, 400, origin); }
  const slug = String(i.slug || '').toLowerCase(), postcode = String(i.postcode || ''), state = String(i.state || '');
  if (!/^[a-z0-9-]{3,30}$/.test(slug) || !/^[0-9]{5}$/.test(postcode) || !STATES.includes(state) || !Array.isArray(i.items) || !i.items.length || i.items.length > 20) {
    return json({ error: 'bad request' }, 400, origin);
  }
  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const { data: page } = await db.from('public_order_pages').select('business_id, enabled').eq('slug', slug).maybeSingle();
  if (!page) return json({ error: 'not found' }, 404, origin);
  const { data: acct } = await db.from('vendor_courier_accounts').select('api_key, demo, pickup_postcode, pickup_state').eq('business_id', page.business_id).maybeSingle();
  if (!acct) return json({ error: 'courier unavailable' }, 409, origin);
  const ids = i.items.map((x) => String(x.product_id));
  const { data: prods } = await db.from('products').select('id, weight_kg').eq('business_id', page.business_id).in('id', ids);
  const weight = i.items.reduce((s, x) => s + Number(prods?.find((p) => p.id === x.product_id)?.weight_kg || 1) * Math.max(1, Math.min(50, Number(x.quantity) || 1)), 0);
  const res = await epCall(acct.demo, 'EPRateCheckingBulk', acct.api_key, [{
    pick_code: acct.pickup_postcode, pick_state: acct.pickup_state, pick_country: 'MY',
    send_code: postcode, send_state: state, send_country: 'MY', weight: weight.toFixed(2),
  }]);
  const rates = res.body?.result?.[0]?.rates;
  if (!res.ok || !Array.isArray(rates)) return json({ error: 'no rates', detail: res.body?.result?.[0]?.remarks || null }, 502, origin);
  const out = rates
    .map((r: Record<string, unknown>) => ({ service_id: r.service_id, courier_name: r.courier_name, service_name: r.service_name, price: Number(r.price), delivery: r.delivery }))
    .filter((r: { price: number }) => Number.isFinite(r.price))
    .sort((a: { price: number }, b: { price: number }) => a.price - b.price)
    .slice(0, 6);
  return json({ weight_kg: Number(weight.toFixed(2)), rates: out }, 200, origin);
});
