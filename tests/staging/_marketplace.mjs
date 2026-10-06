// Shared staging helper: put a Driver through Marketplace Verification V1
// with the real Driver RPCs, then record a high-confidence screening
// fixture through the service-role RPC (what the Edge Function does after
// Google Vision OCR). Idempotent. Needed only for Find Jobs.
import { createHash } from 'node:crypto';

export const JPG = Buffer.from('/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wAALCAABAAEBAREA/8QAFAABAAAAAAAAAAAAAAAAAAAAA//EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AN//Z', 'base64');

/** A valid, per-account MyKad IC (deterministic from the user id). */
export function testIcFor(userId) {
  const n = BigInt('0x' + createHash('sha256').update(userId).digest('hex').slice(0, 12)) % 1000000n;
  return `900101${String(n).padStart(6, '0')}`;
}
export const uidOf = (tok) => JSON.parse(Buffer.from(tok.split('.')[1], 'base64url').toString()).sub;

export function client(url, key) {
  const H = (t) => String(t).startsWith('sb_secret') ? { apikey: t, 'content-type': 'application/json' } : { apikey: key, authorization: `Bearer ${t}`, 'content-type': 'application/json' };
  const rpc = async (t, name, body = {}) => {
    const r = await fetch(`${url}/rest/v1/rpc/${name}`, { method: 'POST', headers: H(t), body: JSON.stringify(body) });
    const txt = await r.text(); let j; try { j = JSON.parse(txt); } catch { j = txt; }
    return { status: r.status, body: j };
  };
  const upload = async (t, path) => (await fetch(`${url}/storage/v1/object/cefflo-driver-documents/${path}`, { method: 'POST', headers: { apikey: key, authorization: `Bearer ${t}`, 'content-type': 'image/jpeg' }, body: JPG })).ok;
  return { H, rpc, upload };
}

export async function ensureMarketplaceVerified({ url, key, svc, driverToken, name, plate = 'VMV 1234', vehicle = 'motorcycle' }) {
  const { rpc, upload } = client(url, key);
  const uid = uidOf(driverToken);
  if ((await rpc(driverToken, 'my_marketplace_verification')).body?.status === 'verified') return true;
  const stamp = Date.now();
  const lp = `${uid}/licence-${stamp}.jpg`, vp = `${uid}/vehicle-${stamp}.jpg`;
  await upload(driverToken, lp); await upload(driverToken, vp);
  const ic = testIcFor(uid);
  for (const [fn, body] of [['submit_driver_licence', { p_ic_number: ic, p_licence_path: lp }],
                            ['submit_marketplace_vehicle', { p_vehicle_type: vehicle, p_vehicle_plate: plate, p_photo_path: vp }]]) {
    const r = await rpc(driverToken, fn, body);
    if (r.status >= 400) throw new Error(`${fn}: ${JSON.stringify(r.body)}`);
  }
  const res = await rpc(svc, 'record_marketplace_screening', {
    p_user_id: uid,
    p_licence: { text_found: true, confidence: 0.97, ic, name, classes: vehicle === 'motorcycle' ? ['B2', 'D'] : ['D'], expiry: '2030-12-31' },
    p_plate: { plates: [{ text: plate.replace(/\s/g, ''), confidence: 0.96 }] },
  });
  if (res.body?.status !== 'verified') throw new Error('not verified: ' + JSON.stringify(res.body));
  return true;
}
