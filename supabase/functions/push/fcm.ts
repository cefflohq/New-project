// FCM HTTP v1 sender for the Android apps. The service account JSON comes
// from the CEFFLO_FCM_SERVICE_ACCOUNT secret; WebCrypto only (RS256 JWT).
import { b64url } from './webpush.ts';

const enc = new TextEncoder();
type Account = { project_id: string; client_email: string; private_key: string };
let cached: { token: string; exp: number } | null = null;

async function accessToken(sa: Account) {
  const now = Math.floor(Date.now() / 1000);
  if (cached && cached.exp > now + 60) return cached.token;
  const head = b64url(enc.encode(JSON.stringify({ alg: 'RS256', typ: 'JWT' })));
  const claim = b64url(enc.encode(JSON.stringify({
    iss: sa.client_email, scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token', iat: now, exp: now + 3600,
  })));
  const der = Uint8Array.from(atob(sa.private_key.replace(/-----[^-]+-----|\s/g, '')), c => c.charCodeAt(0));
  const key = await crypto.subtle.importKey('pkcs8', der, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const sig = new Uint8Array(await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, enc.encode(`${head}.${claim}`)));
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: `${head}.${claim}.${b64url(sig)}` }),
  });
  const j = await res.json();
  if (!res.ok) throw new Error(`fcm auth ${res.status} ${JSON.stringify(j).slice(0, 200)}`);
  cached = { token: j.access_token, exp: now + (j.expires_in ?? 3600) };
  return cached.token;
}

/** HTTP status; 404 means the token is gone (app uninstalled). */
export async function sendFcm(sa: Account, token: string, n: { title: string; body: string; tag: string; urgent: boolean; data: Record<string, string> }) {
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
    method: 'POST',
    headers: { authorization: `Bearer ${await accessToken(sa)}`, 'content-type': 'application/json' },
    body: JSON.stringify({
      message: {
        token,
        notification: { title: n.title, body: n.body },
        data: n.data,
        android: {
          priority: n.urgent ? 'HIGH' : 'NORMAL',
          notification: { tag: n.tag, channel_id: 'cefflo_alerts', icon: 'ic_stat_cefflo', color: '#01265E', default_sound: true },
        },
      },
    }),
  });
  if (res.ok) { await res.body?.cancel(); return res.status; }
  const t = await res.text();
  console.error('fcm send', res.status, t.slice(0, 300));
  if (/UNREGISTERED|registration token/i.test(t)) return 404;
  return res.status;
}
