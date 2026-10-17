// push — closed-app alerts (Web Push, and FCM for the Android apps). docs/cefflo/security/PUSH_NOTIFICATIONS.md
//   GET  /push/vapid  → { key } (public VAPID key for PushManager.subscribe)
//   POST /push/send   ← { id } from the notifications AFTER INSERT hook,
//                        authorised by x-push-secret.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { sendPush } from './webpush.ts';
import { sendFcm } from './fcm.ts';

const VAPID = {
  publicKey: Deno.env.get('CEFFLO_VAPID_PUBLIC_KEY') ?? '',
  privateKey: Deno.env.get('CEFFLO_VAPID_PRIVATE_KEY') ?? '',
  subject: Deno.env.get('CEFFLO_VAPID_SUBJECT') ?? 'mailto:cefflohq26@gmail.com',
};
const FCM = (() => { try { return JSON.parse(Deno.env.get('CEFFLO_FCM_SERVICE_ACCOUNT') ?? ''); } catch { return null; } })();
const SECRET = Deno.env.get('CEFFLO_PUSH_WEBHOOK_SECRET') ?? '';
const CORS = { 'access-control-allow-origin': '*', 'access-control-allow-headers': 'authorization, apikey, content-type', 'access-control-allow-methods': 'GET, OPTIONS' };
const json = (v: unknown, status = 200, extra: Record<string, string> = {}) =>
  new Response(JSON.stringify(v), { status, headers: { 'content-type': 'application/json', ...extra } });

function safeEqual(a: string, b: string) {
  if (!a || !b || a.length !== b.length) return false;
  let r = 0;
  for (let i = 0; i < a.length; i++) r |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return r === 0;
}

// Where a tap lands: Vendor Web knows hash routes; the apps open at their base.
function link(base: string | null, target: { screen?: string; id?: string } = {}) {
  if (!base) return '/';
  if (/\/web\/?$/.test(base.replace(/[?#].*$/, ''))) {
    const b = base.replace(/[?#].*$/, '').replace(/\/?$/, '/');
    if (target.screen === 'order' && target.id) return `${b}#/orders/${target.id}`;
    if (target.screen === 'runs') return `${b}#/runs`;
    if (target.screen === 'riders' || target.screen === 'rider') return `${b}#/riders${target.id ? `/${target.id}` : ''}`;
    return b;
  }
  return base;
}

Deno.serve(async req => {
  const path = new URL(req.url).pathname.replace(/\/+$/, '');
  if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS });
  if (req.method === 'GET' && path.endsWith('/vapid')) {
    return VAPID.publicKey ? json({ key: VAPID.publicKey }, 200, CORS) : json({ error: 'push not configured' }, 503, CORS);
  }
  if (req.method !== 'POST' || !path.endsWith('/send')) return json({ error: 'not found' }, 404);
  if (!safeEqual(req.headers.get('x-push-secret') ?? '', SECRET)) return json({ error: 'unauthorized' }, 401);
  if (!(VAPID.publicKey && VAPID.privateKey) && !FCM) return json({ error: 'push not configured' }, 503);

  const { id } = await req.json().catch(() => ({}));
  if (typeof id !== 'string' || !/^[0-9a-f-]{36}$/.test(id)) return json({ error: 'bad id' }, 400);
  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, { auth: { persistSession: false } });

  const { data: n } = await db.from('notifications')
    .select('id, recipient_user_id, app, title, body, priority, target, read_at').eq('id', id).maybeSingle();
  if (!n || n.read_at) return json({ sent: 0 });
  const { data: pref } = await db.from('notification_preferences').select('enabled').eq('user_id', n.recipient_user_id).maybeSingle();
  if (pref && !pref.enabled) return json({ sent: 0 });
  const { data: subs } = await db.from('push_subscriptions')
    .select('id, kind, endpoint, p256dh, auth_key, base_url, failures')
    .eq('user_id', n.recipient_user_id).eq('app', n.app);

  let sent = 0;
  for (const s of subs ?? []) {
    const payload = { title: n.title, body: n.body, url: link(s.base_url, n.target ?? {}), tag: n.id, urgent: n.priority === 'urgent' };
    let status = 0;
    try {
      if (s.kind === 'fcm') {
        if (!FCM) continue;
        const t = n.target ?? {};
        status = await sendFcm(FCM, s.endpoint, { title: n.title, body: n.body, tag: n.id, urgent: payload.urgent,
          data: { id: n.id, screen: String(t.screen ?? ''), target_id: String(t.id ?? '') } });
      } else {
        if (!VAPID.publicKey) continue;
        status = await sendPush(s, payload, VAPID, { urgent: n.priority === 'urgent', topic: n.id.replace(/-/g, '') });
      }
    } catch (e) { console.error('push send', s.kind, String(e)); status = 0; }
    if (status >= 200 && status < 300) {
      sent++;
      if (s.failures) await db.from('push_subscriptions').update({ failures: 0 }).eq('id', s.id);
    } else if (status === 404 || status === 410 || s.failures >= 4) {
      await db.from('push_subscriptions').delete().eq('id', s.id);
    } else {
      await db.from('push_subscriptions').update({ failures: s.failures + 1 }).eq('id', s.id);
    }
  }
  return json({ sent });
});
