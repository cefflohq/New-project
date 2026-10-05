// Session context: the signed-in user, their business memberships and the
// active business + role. Role always comes from the server
// (get_my_businesses); the UI only uses it
// to decide what to show — the server independently enforces every action.
import { api } from './api.js';
import { operatorEntry } from './access.js';

const ACTIVE = 'cefflo.vendorweb.activeBusiness';

export const ctx = {
  user: null,
  businesses: [],
  business: null, // { business_id, business_name, member_role, ... }
  get isOwner() { return this.business?.member_role === 'owner'; },
  get role() { return this.business?.member_role; },
  get bid() { return this.business?.business_id; },
};

export class HelperOnlyError extends Error {}
export class NoBusinessError extends Error {}

export async function loadContext() {
  ctx.user = await api.user();
  const rows = await api.rpc('get_my_businesses');
  const all = Array.isArray(rows) ? rows : [];
  // Phase 0 role isolation: Operator Access only opens businesses where the
  // account is an Operator (never its own Owner business). Helpers use the
  // Helper workspace in the app, never Vendor Web.
  ctx.businesses = all.filter(b => (operatorEntry() ? b.member_role === 'operator' : b.member_role !== 'helper'));
  if (!ctx.businesses.length) {
    if (all.some(b => b.member_role === 'helper')) throw new HelperOnlyError();
    throw new NoBusinessError();
  }
  let remembered = null;
  try { remembered = localStorage.getItem(ACTIVE); } catch { /* ignore */ }
  ctx.business = ctx.businesses.find(b => b.business_id === remembered) || ctx.businesses[0];
  return ctx;
}

export function selectBusiness(id) {
  const b = ctx.businesses.find(x => x.business_id === id);
  if (!b) return;
  ctx.business = b;
  try { localStorage.setItem(ACTIVE, id); } catch { /* ignore */ }
}

export function clearContext() {
  ctx.user = null; ctx.businesses = []; ctx.business = null;
}
