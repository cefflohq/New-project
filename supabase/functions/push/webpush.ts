// Web Push sender: RFC 8291 (aes128gcm message encryption) + RFC 8292 (VAPID),
// WebCrypto only, so it runs unchanged in Deno (Edge) and Node (tests).

const enc = new TextEncoder();

export function b64url(bytes: Uint8Array): string {
  let s = '';
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}
export function unb64url(s: string): Uint8Array {
  const b = atob(s.replace(/-/g, '+').replace(/_/g, '/') + '==='.slice((s.length + 3) % 4));
  return Uint8Array.from(b, c => c.charCodeAt(0));
}
const concat = (...parts: Uint8Array[]) => {
  const out = new Uint8Array(parts.reduce((n, p) => n + p.length, 0));
  let o = 0;
  for (const p of parts) { out.set(p, o); o += p.length; }
  return out;
};

async function hkdf(salt: Uint8Array, ikm: Uint8Array, info: Uint8Array, bytes: number) {
  const key = await crypto.subtle.importKey('raw', ikm, 'HKDF', false, ['deriveBits']);
  return new Uint8Array(await crypto.subtle.deriveBits({ name: 'HKDF', hash: 'SHA-256', salt, info }, key, bytes * 8));
}

/** Encrypts `payload` for one subscription (keys from PushSubscription.toJSON()). */
export async function encrypt(payload: Uint8Array, p256dh: string, auth: string, salt = crypto.getRandomValues(new Uint8Array(16))) {
  const uaPublic = unb64url(p256dh);
  const authSecret = unb64url(auth);
  const as = await crypto.subtle.generateKey({ name: 'ECDH', namedCurve: 'P-256' }, true, ['deriveBits']);
  const asPublic = new Uint8Array(await crypto.subtle.exportKey('raw', as.publicKey));
  const uaKey = await crypto.subtle.importKey('raw', uaPublic, { name: 'ECDH', namedCurve: 'P-256' }, false, []);
  const ecdh = new Uint8Array(await crypto.subtle.deriveBits({ name: 'ECDH', public: uaKey }, as.privateKey, 256));
  const ikm = await hkdf(authSecret, ecdh, concat(enc.encode('WebPush: info\0'), uaPublic, asPublic), 32);
  const cek = await hkdf(salt, ikm, enc.encode('Content-Encoding: aes128gcm\0'), 16);
  const nonce = await hkdf(salt, ikm, enc.encode('Content-Encoding: nonce\0'), 12);
  const key = await crypto.subtle.importKey('raw', cek, 'AES-GCM', false, ['encrypt']);
  const cipher = new Uint8Array(await crypto.subtle.encrypt({ name: 'AES-GCM', iv: nonce }, key, concat(payload, new Uint8Array([2]))));
  const rs = new Uint8Array([0, 0, 16, 0]); // record size 4096
  return concat(salt, rs, new Uint8Array([asPublic.length]), asPublic, cipher);
}

/** VAPID Authorization header value for `endpoint`. Keys: base64url raw P-256. */
export async function vapidAuth(endpoint: string, publicKey: string, privateKey: string, subject: string) {
  const pub = unb64url(publicKey);
  const jwk = { kty: 'EC', crv: 'P-256', d: privateKey, x: b64url(pub.slice(1, 33)), y: b64url(pub.slice(33, 65)), ext: true };
  const key = await crypto.subtle.importKey('jwk', jwk, { name: 'ECDSA', namedCurve: 'P-256' }, false, ['sign']);
  const head = b64url(enc.encode(JSON.stringify({ typ: 'JWT', alg: 'ES256' })));
  const body = b64url(enc.encode(JSON.stringify({ aud: new URL(endpoint).origin, exp: Math.floor(Date.now() / 1000) + 12 * 3600, sub: subject })));
  const sig = new Uint8Array(await crypto.subtle.sign({ name: 'ECDSA', hash: 'SHA-256' }, key, enc.encode(`${head}.${body}`)));
  return `vapid t=${head}.${body}.${b64url(sig)}, k=${publicKey}`;
}

export type Subscription = { endpoint: string; p256dh: string; auth_key: string };

/** Sends one push. Returns the push service's HTTP status. */
export async function sendPush(sub: Subscription, payload: unknown, vapid: { publicKey: string; privateKey: string; subject: string }, opts: { ttl?: number; urgent?: boolean; topic?: string } = {}) {
  const body = await encrypt(enc.encode(JSON.stringify(payload)), sub.p256dh, sub.auth_key);
  const headers: Record<string, string> = {
    authorization: await vapidAuth(sub.endpoint, vapid.publicKey, vapid.privateKey, vapid.subject),
    'content-encoding': 'aes128gcm',
    'content-type': 'application/octet-stream',
    ttl: String(opts.ttl ?? 86400),
    urgency: opts.urgent ? 'high' : 'normal',
  };
  if (opts.topic) headers.topic = opts.topic.replace(/[^A-Za-z0-9_-]/g, '').slice(0, 32);
  const res = await fetch(sub.endpoint, { method: 'POST', headers, body });
  await res.body?.cancel();
  return res.status;
}
