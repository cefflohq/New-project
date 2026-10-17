// CHIP success callback (Founder 2026-10-17). CHIP POSTs the purchase when it
// is paid. The body is verified with the vendor's CHIP public key
// (X-Signature: base64 RSA PKCS#1 v1.5 over SHA-256 of the raw body) before
// anything is trusted. Then the order is marked paid.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

const CHIP = 'https://gate.chip-in.asia/api/v1';

function pemToDer(pem: string): Uint8Array {
  const b64 = pem.replace(/-----[^-]+-----/g, '').replace(/\s+/g, '');
  return Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
}

async function verify(raw: Uint8Array, sigB64: string, pem: string): Promise<boolean> {
  try {
    const key = await crypto.subtle.importKey('spki', pemToDer(pem), { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify']);
    const sig = Uint8Array.from(atob(sigB64), (c) => c.charCodeAt(0));
    return await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key, sig, raw);
  } catch { return false; }
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return new Response('method not allowed', { status: 405 });
  const business = new URL(req.url).searchParams.get('business') || '';
  if (!/^[0-9a-f-]{36}$/i.test(business)) return new Response('bad request', { status: 400 });
  const raw = new Uint8Array(await req.arrayBuffer());
  const sig = req.headers.get('X-Signature') || '';
  if (!sig) return new Response('unsigned', { status: 401 });

  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const { data: acct } = await db.from('vendor_payment_accounts').select('secret_key').eq('business_id', business).maybeSingle();
  if (!acct) return new Response('unknown business', { status: 404 });
  const pk = await fetch(`${CHIP}/public_key/`, { headers: { Authorization: `Bearer ${acct.secret_key}` } });
  if (!pk.ok) return new Response('key unavailable', { status: 502 });
  const pem = await pk.json(); // JSON-encoded PEM string
  if (!(await verify(raw, sig, String(pem)))) return new Response('bad signature', { status: 401 });

  const purchase = JSON.parse(new TextDecoder().decode(raw));
  const { data: pay } = await db.from('storefront_payments').select('id, order_id, amount_cents, status')
    .eq('chip_purchase_id', purchase.id).eq('business_id', business).maybeSingle();
  if (!pay) return new Response('unknown purchase', { status: 404 });
  const paidTotal = Number(purchase?.purchase?.total ?? purchase?.payment?.amount ?? 0);
  if (purchase.status === 'paid' && paidTotal >= pay.amount_cents && pay.status !== 'paid') {
    await db.from('storefront_payments').update({ status: 'paid', paid_at: new Date().toISOString() }).eq('id', pay.id);
    await db.from('orders').update({ payment_status: 'paid' }).eq('id', pay.order_id);
    await db.from('delivery_events').insert({ business_id: business, order_id: pay.order_id, event_type: 'payment.paid', actor_role: 'system', metadata: { provider: 'chip', purchase_id: purchase.id, amount_cents: pay.amount_cents } });
  }
  return new Response('ok');
});
