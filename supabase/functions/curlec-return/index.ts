// Curlec redirects the customer here after the payment page (callback_url,
// GET). Nothing in the query string is trusted: the link is re-read from
// Curlec with the vendor's key, and only status 'paid' with the full amount
// marks the order paid. Then the customer is sent back to the storefront.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

const API = 'https://api.razorpay.com/v1';

Deno.serve(async (req) => {
  const u = new URL(req.url);
  const slug = (u.searchParams.get('slug') || '').toLowerCase();
  const key = u.searchParams.get('key') || '';
  const linkId = u.searchParams.get('razorpay_payment_link_id') || '';
  const store = (Deno.env.get('CEFFLO_STOREFRONT_BASE_URL') || 'https://order.cefflo.com/').replace(/\/?$/, '/');
  const back = (ok: boolean) => Response.redirect(`${store}${slug}#/${ok ? 'paid' : 'payfail'}/${key}`, 302);
  if (!/^[a-z0-9-]{3,30}$/.test(slug) || !/^[0-9a-f-]{36}$/i.test(key) || !/^plink_[A-Za-z0-9]+$/.test(linkId)) return back(false);

  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const { data: pay } = await db.from('storefront_payments').select('id, business_id, amount_cents, status').eq('provider_ref', linkId).maybeSingle();
  if (!pay) return back(false);
  if (pay.status === 'paid') return back(true);
  const { data: acct } = await db.from('vendor_payment_accounts').select('key_id, key_secret').eq('business_id', pay.business_id).maybeSingle();
  if (!acct) return back(false);
  const r = await fetch(`${API}/payment_links/${linkId}`, { headers: { Authorization: `Basic ${btoa(`${acct.key_id}:${acct.key_secret}`)}` } });
  const l = await r.json().catch(() => null);
  if (r.ok && l?.status === 'paid' && Number(l.amount_paid) >= pay.amount_cents) {
    await db.rpc('_storefront_mark_paid', { p_payment_id: pay.id });
    return back(true);
  }
  return back(false);
});
