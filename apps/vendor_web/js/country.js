// Country pack of the active business (public.countries, Country Pack
// Guideline §3): phone prefix, postcode rule, minimum driver pay, currency.
// Malaysia is the fallback so nothing changes when the pack cannot load.
import { api } from './api.js';

export const MY = Object.freeze({
  iso2: 'MY', name_en: 'Malaysia', region: 'asia', status: 'live', currency: 'MYR', phone_code: '+60',
  timezones: ['Asia/Kuala_Lumpur'], postcode_regex: '^\\d{5}$', min_pay_per_drop: 3, languages: ['en', 'ms', 'zh-Hans', 'ta'],
});

let current = MY;
export const country = () => current;

export async function loadCountry(businessId) {
  current = MY;
  if (!businessId) return current;
  try {
    const rows = await api.get(`/rest/v1/businesses?id=eq.${encodeURIComponent(businessId)}&select=country_iso2,countries(*)`);
    const c = Array.isArray(rows) ? rows[0]?.countries : null;
    if (c?.iso2) current = Object.freeze({ ...c, min_pay_per_drop: Number(c.min_pay_per_drop ?? 0) || 0 });
  } catch { /* keep Malaysia */ }
  return current;
}

// Countries a new business may choose (live, or beta when invited).
export async function selectableCountries() {
  try {
    const rows = await api.get('/rest/v1/countries?select=*&status=in.(live,beta)&order=sort_order.asc');
    return Array.isArray(rows) && rows.length ? rows : [MY];
  } catch {
    return [MY];
  }
}

// "012-345 6789" + "+60" -> "+60123456789" (E.164). Already international
// numbers ("+65 …", "0065 …") are kept. Returns '' when there are no digits.
export function toE164(raw, phoneCode = current.phone_code) {
  const s = String(raw || '').trim();
  const digits = s.replace(/\D/g, '');
  if (!digits) return '';
  if (s.startsWith('+')) return `+${digits}`;
  if (digits.startsWith('00')) return `+${digits.slice(2)}`;
  const cc = String(phoneCode || '+60').replace(/\D/g, '');
  if (digits.startsWith('0')) return `+${cc}${digits.slice(1)}`;
  if (digits.startsWith(cc) && digits.length > cc.length + 6) return `+${digits}`;
  return `+${cc}${digits}`;
}
export const isE164 = v => /^\+[1-9]\d{6,14}$/.test(v || '');
// wa.me wants the international number without "+".
export const waNumber = (raw, phoneCode) => toE164(raw, phoneCode).slice(1);

export function postcodeOk(value, c = current) {
  const v = String(value || '').trim();
  if (!v || !c.postcode_regex) return true; // optional / country without postcodes
  try { return new RegExp(c.postcode_regex, 'i').test(v); } catch { return true; }
}
