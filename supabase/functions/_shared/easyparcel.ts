// EasyParcel (Malaysia) API: form-encoded POST to {base}?ac=<action> with
// `api` and a `bulk` array (PHP http_build_query style: bulk[0][field]).
export const epBase = (demo: boolean) => (demo ? 'https://demo.connect.easyparcel.my/' : 'https://connect.easyparcel.my/');

export async function epCall(demo: boolean, action: string, api: string, bulk: Record<string, unknown>[]) {
  const form = new URLSearchParams();
  form.set('api', api);
  bulk.forEach((item, i) => {
    for (const [k, v] of Object.entries(item)) if (v !== undefined && v !== null) form.set(`bulk[${i}][${k}]`, String(v));
  });
  const r = await fetch(`${epBase(demo)}?ac=${action}`, {
    method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: form.toString(),
  });
  const j = await r.json().catch(() => null);
  return { ok: r.ok && j && String(j.api_status || '').toLowerCase() !== 'fail' && Number(j.error_code ?? 0) === 0, body: j };
}
