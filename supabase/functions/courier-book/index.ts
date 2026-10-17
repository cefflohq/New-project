// Runs every minute (pg_cron + pg_net, secret header). Books waiting courier
// shipments on the vendor's EasyParcel account once the order is paid (couriers
// do not collect cash): EPSubmitOrderBulk then EPPayOrderBulk (vendor's prepaid
// credit). Stores the AWB, label and tracking link, and refreshes the status
// of booked parcels. The vendor presses nothing (Founder 2026-10-17).
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';
import { epCall } from '../_shared/easyparcel.ts';

Deno.serve(async (req) => {
  const secret = Deno.env.get('CEFFLO_CRON_SECRET') || '';
  if (!secret || req.headers.get('x-cron-secret') !== secret) return new Response('forbidden', { status: 403 });
  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  let booked = 0, failed = 0, refreshed = 0;

  const { data: waiting } = await db.from('storefront_shipments')
    .select('id, business_id, order_id, service_id, send_city, send_postcode, send_state, attempts, orders!inner(public_ref, payment_status, customer_name, customer_phone, delivery_address, items, notes)')
    .eq('status', 'waiting').lt('attempts', 10).eq('orders.payment_status', 'paid').limit(20);
  for (const s of waiting || []) {
    const o = (s as Record<string, any>).orders;
    const { data: a } = await db.from('vendor_courier_accounts').select('*').eq('business_id', s.business_id).maybeSingle();
    if (!a) continue;
    const ids = (o.items as any[]).map((l) => l.product_id);
    const { data: prods } = await db.from('products').select('id, weight_kg').in('id', ids);
    const weight = (o.items as any[]).reduce((t, l) => t + Number(prods?.find((p) => p.id === l.product_id)?.weight_kg || 1) * Number(l.quantity || 1), 0);
    const value = (o.items as any[]).reduce((t, l) => t + Number(l.line_subtotal_snapshot || 0), 0);
    const content = (o.items as any[]).map((l) => l.product_name_snapshot).join(', ').slice(0, 100);
    const now = new Date(Date.now() + 8 * 3600e3).toISOString().slice(0, 10);
    const sub = await epCall(a.demo, 'EPSubmitOrderBulk', a.api_key, [{
      weight: weight.toFixed(2), content, value: value.toFixed(2), service_id: s.service_id,
      pick_name: a.pickup_name, pick_contact: a.pickup_phone, pick_addr1: a.pickup_address, pick_city: a.pickup_city,
      pick_state: a.pickup_state, pick_code: a.pickup_postcode, pick_country: 'MY',
      send_name: o.customer_name, send_contact: o.customer_phone, send_addr1: String(o.delivery_address).slice(0, 100),
      send_city: s.send_city, send_state: s.send_state, send_code: s.send_postcode, send_country: 'MY',
      collect_date: now, sms: 0, send_email: '', reference: o.public_ref, idempotency_key: s.id,
    }]);
    const orderNo = sub.body?.result?.[0]?.order_number;
    if (!sub.ok || !orderNo) {
      failed++;
      await db.from('storefront_shipments').update({ attempts: s.attempts + 1, error: JSON.stringify(sub.body?.result?.[0]?.remarks || sub.body?.error_remark || 'submit failed').slice(0, 300), status: s.attempts + 1 >= 10 ? 'failed' : 'waiting', updated_at: new Date().toISOString() }).eq('id', s.id);
      continue;
    }
    const pay = await epCall(a.demo, 'EPPayOrderBulk', a.api_key, [{ order_no: orderNo }]);
    const parcel = pay.body?.result?.[0]?.parcel?.[0];
    if (!pay.ok || !parcel?.awb) {
      failed++;
      // Usually 'Insufficient Credit': the vendor tops up EasyParcel credit; we retry.
      await db.from('storefront_shipments').update({ ep_order_no: orderNo, attempts: s.attempts + 1, error: String(pay.body?.result?.[0]?.messagenow || 'payment failed').slice(0, 300), updated_at: new Date().toISOString() }).eq('id', s.id);
      await db.from('delivery_events').insert({ business_id: s.business_id, order_id: s.order_id, event_type: 'courier.payment_failed', actor_role: 'system', metadata: { message: pay.body?.result?.[0]?.messagenow || null } });
      continue;
    }
    booked++;
    await db.from('storefront_shipments').update({ status: 'booked', ep_order_no: orderNo, awb: parcel.awb, label_url: parcel.awb_id_link, tracking_url: parcel.tracking_url, error: null, updated_at: new Date().toISOString() }).eq('id', s.id);
    await db.from('orders').update({ notes: `${o.notes || ''}\nCourier AWB ${parcel.awb}. Label: ${parcel.awb_id_link}`.slice(0, 500) }).eq('id', s.order_id);
    await db.from('delivery_events').insert({ business_id: s.business_id, order_id: s.order_id, event_type: 'courier.booked', actor_role: 'system', metadata: { awb: parcel.awb } });
  }

  // Refresh booked parcels' status for the customer's order page.
  const { data: live } = await db.from('storefront_shipments').select('id, business_id, awb, last_status').eq('status', 'booked').neq('last_status', 'Successfully Delivered').limit(50);
  const byBiz = new Map<string, any>();
  for (const s of live || []) {
    if (!byBiz.has(s.business_id)) byBiz.set(s.business_id, (await db.from('vendor_courier_accounts').select('api_key, demo').eq('business_id', s.business_id).maybeSingle()).data);
    const a = byBiz.get(s.business_id); if (!a || !s.awb) continue;
    const t = await epCall(a.demo, 'EPTrackingBulk', a.api_key, [{ awb_no: s.awb }]);
    const latest = t.body?.result?.[0]?.latest_status;
    if (latest && latest !== s.last_status) { refreshed++; await db.from('storefront_shipments').update({ last_status: String(latest).slice(0, 120), updated_at: new Date().toISOString() }).eq('id', s.id); }
  }
  return new Response(JSON.stringify({ booked, failed, refreshed }), { headers: { 'Content-Type': 'application/json' } });
});
