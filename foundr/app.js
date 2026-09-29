// CEFFLO FOUNDR -- platform command center (docs/cefflo/09_FOUNDR.md, D-21).
// Every number and row on screen comes from the canonical FOUNDR backend
// (foundr/backend.js). There is no mock data path: a surface either shows
// the server's truth, an honest empty/error state, or states plainly that it
// is not available yet. Privileged writes always pass through a
// confirmation step and are recorded by the backend in admin_audit_log.
(() => {
const F = window.CEFFLO_FOUNDR;
const root = document.getElementById('app');
const PAGE = 10;
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const num = n => Number(n || 0).toLocaleString('en-MY');
const TZ = 'Asia/Kuala_Lumpur';
const fmtDate = iso => iso ? new Date(iso).toLocaleDateString('en-MY', { day: 'numeric', month: 'short', year: 'numeric', timeZone: TZ }) : '—';
const fmtDateTime = iso => iso ? new Date(iso).toLocaleString('en-MY', { day: 'numeric', month: 'short', hour: 'numeric', minute: '2-digit', timeZone: TZ }) : '—';
const fmtTime = iso => iso ? new Date(iso).toLocaleTimeString('en-MY', { hour: 'numeric', minute: '2-digit', timeZone: TZ }) : '—';
const ago = iso => {
  if (!iso) return '—';
  const m = Math.round((Date.now() - new Date(iso).getTime()) / 60000);
  if (m < 1) return 'just now';
  if (m < 60) return `${m} min ago`;
  const h = Math.round(m / 60);
  if (h < 48) return `${h} h ago`;
  return `${Math.round(h / 24)} days ago`;
};
const rm = cents => cents == null ? '—' : `RM ${(cents / 100).toLocaleString('en-MY', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
const initials = s => String(s || '').replace(/[^\p{L}\p{N}\s]/gu, ' ').split(/\s+/).filter(Boolean).slice(0, 2).map(w => w[0]).join('').toUpperCase() || '?';
const shortId = id => id ? String(id).slice(0, 8) : '—';
const human = s => String(s || '').replace(/_/g, ' ').replace(/^./, c => c.toUpperCase());

// ------------------------------------------------------------------ icons
const icons = {
  overview: '<path d="M3 11 12 3l9 8v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>',
  vendors: '<path d="M4 9h16l-2-5H6zM5 9v11h14V9M9 20v-6h6v6"/>',
  operations: '<rect x="4" y="3" width="16" height="18" rx="2"/><path d="M8 8h8M8 12h5"/>',
  riders: '<circle cx="6" cy="17" r="3"/><circle cx="18" cy="17" r="3"/><path d="M6 17h4l3-6h4l1 6M13 11l-2-4H8"/>',
  controls: '<path d="M4 6h10M18 6h2M4 12h4M12 12h8M4 18h12"/><circle cx="16" cy="6" r="2"/><circle cx="10" cy="12" r="2"/><circle cx="18" cy="18" r="2"/>',
  product: '<path d="M4 5h16v13H4zM8 21h8M12 18v3"/>',
  business: '<path d="M4 20V9h5v11M10 20V4h5v16M16 20v-7h4v7M2 20h20"/>',
  support: '<path d="M4 5h16v12H9l-5 4z"/>',
  marketing: '<path d="m4 13 11-5v10L4 13zM15 11h3a3 3 0 0 1 0 6h-3M6 14l1 6h3l-1-5"/>',
  system: '<path d="M3 12h4l3-8 4 16 3-8h4"/>',
  audit: '<path d="M6 3h12v18H6zM9 8h6M9 12h6M9 16h4"/>',
  settings: '<circle cx="12" cy="12" r="3"/><path d="M4 12h2m12 0h2M12 4v2m0 12v2M6.3 6.3l1.4 1.4m8.6 8.6 1.4 1.4m0-11.4-1.4 1.4m-8.6 8.6-1.4 1.4"/>',
};
const svg = k => `<svg viewBox="0 0 24 24">${icons[k] || ''}</svg>`;
const ti = d => `<svg class="ti" viewBox="0 0 24 24" aria-hidden="true">${d}</svg>`;
const I = {
  search: ti('<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>'),
  bell: ti('<path d="M6 8a6 6 0 1 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.9 1.9 0 0 0 3.4 0"/>'),
  down: ti('<path d="m6 9 6 6 6-6"/>'),
  refresh: ti('<path d="M20 11a8 8 0 1 0-2.3 5.7M20 4v7h-7"/>'),
  menu: ti('<path d="M4 6h16M4 12h16M4 18h16"/>'),
};

const NAV = [
  ['overview', 'Overview'], ['vendors', 'Vendors'], ['operations', 'Operations'], ['riders', 'Riders'],
  ['controls', 'Controls'], ['product', 'Versions'], ['business', 'Subscriptions'],
  ['system', 'System'], ['audit', 'Audit Log'], ['support', 'Support'], ['marketing', 'Marketing'],
  ['settings', 'Settings'],
];
const ROUTES = NAV.map(n => n[0]);

// ------------------------------------------------------------------ state
const route0 = () => { const r = location.hash.slice(1).split('?')[0]; return ROUTES.includes(r) ? r : 'overview'; };
const state = { route: route0(), tab: '', query: '', filters: {}, page: 1, drawer: null, modal: null, menu: null, gq: '', stuckMinutes: 45 };
let me = { user: null };
const data = {};      // key -> server rows
const errors = {};    // key -> Error
const pending = {};   // key -> Promise
let updatedAt = null;

const LOADERS = {
  vendors: () => F.listVendors(),
  subs: () => F.listSubscriptions(),
  ops: () => F.deliveryOperations(),
  riders: () => F.listRiders(),
  stuck: () => F.stuckRiders(state.stuckMinutes),
  audit: () => F.listAuditLog(500),
  flags: () => F.listFeatureFlags(),
  windows: () => F.listMaintenanceWindows(),
  anns: () => F.listAnnouncements(),
  activeAnns: () => F.activeAnnouncements(),
  versions: () => F.listAppVersions(),
  admins: () => F.listPlatformAdmins(),
  broadcasts: () => F.listBroadcasts(200),
};
const NEEDS = {
  overview: ['vendors', 'ops', 'stuck', 'audit', 'windows', 'activeAnns', 'flags', 'versions'],
  vendors: ['vendors', 'subs'], operations: ['ops'], riders: ['riders', 'stuck'],
  controls: ['windows', 'flags', 'anns'], product: ['versions'], business: ['subs'],
  system: ['windows', 'activeAnns', 'admins'], audit: ['audit'], settings: ['admins'],
  support: [], marketing: [],
};
function load(key, force = false) {
  if (!force && (key in data)) return Promise.resolve(data[key]);
  if (pending[key]) return pending[key];
  delete errors[key];
  pending[key] = LOADERS[key]()
    .then(v => { data[key] = Array.isArray(v) ? v : (v ?? []); updatedAt = new Date(); return data[key]; })
    .catch(e => { errors[key] = e; delete data[key]; handleAuthError(e); })
    .finally(() => { delete pending[key]; render(); });
  return pending[key];
}
function ensure(keys, force = false) { keys.forEach(k => load(k, force)); }
const ready = keys => keys.every(k => k in data);
const failed = keys => keys.find(k => errors[k]);
function invalidate(...keys) { keys.forEach(k => { delete data[k]; delete errors[k]; }); }

// ------------------------------------------------------------------ helpers
const chip = (label, tone = '') => `<span class="chip ${tone}">${esc(label)}</span>`;
const toneFor = s => /suspend|cancel|issue|critical|past_due|stuck|inactive|unreachable|failed/i.test(s) ? 'red' : /trial|pending|warning|ready_for_pickup|created|not set|offline/i.test(s) ? 'amber' : /active|online|delivered|healthy|reachable|operational|live/i.test(s) ? '' : 'blue';
const statusChip = s => chip(human(s || 'Not set'), toneFor(s || 'not set'));
const metric = (v, l, sub = '', bad = false) => `<div class="metric"><div class="metric-value">${v}</div><div class="metric-label">${esc(l)}</div>${sub ? `<div class="trend ${bad ? 'down' : ''}">${sub}</div>` : ''}</div>`;
const metrics = (arr, cards = true) => `<div class="metrics ${cards ? 'metrics-cards' : ''}" style="--cols:${arr.length}">${arr.map(a => metric(...a)).join('')}</div>`;
const head = (eyebrow, title, desc, action = '') => `<div class="page-head"><div><div class="eyebrow">${esc(eyebrow)}</div><h1>${esc(title)}</h1><p>${esc(desc)}</p></div>${action}</div>`;
const tabs = (items, active) => `<div class="tabs" role="tablist">${items.map(([id, label, count]) => `<button class="tab ${id === active ? 'active' : ''}" role="tab" aria-selected="${id === active}" data-tab="${esc(id)}">${esc(label)}${count != null ? `<span class="tab-count">${num(count)}</span>` : ''}</button>`).join('')}</div>`;
const select = (key, opts, label) => `<select class="select" data-filter="${key}" aria-label="${esc(label || key)}">${opts.map(([v, l]) => `<option value="${esc(v)}" ${String(state.filters[key] ?? '') === String(v) ? 'selected' : ''}>${esc(l)}</option>`).join('')}</select>`;
const toolbar = (placeholder, selects = '') => `<div class="toolbar"><div class="search"><span class="search-icon">${I.search}</span><input data-search placeholder="${esc(placeholder)}" value="${esc(state.query)}" aria-label="${esc(placeholder)}"></div>${selects}</div>`;
const loadingBlock = (rows = 5) => `<div class="card card-pad" aria-busy="true">${Array.from({ length: rows }, () => '<div class="skel"></div>').join('')}</div>`;
const errorBlock = keys => { const k = failed(keys); const e = errors[k]; return `<div class="card card-pad err-card" role="alert"><b>Could not load this from the server.</b><p class="sub">${esc(e?.message || 'Unknown error')}</p><button class="btn" data-retry="${esc(keys.join(','))}">Try again</button></div>`; };
const emptyBlock = (title, body = '') => `<div class="empty"><b>${esc(title)}</b>${body ? `<br><span class="sub inline">${esc(body)}</span>` : ''}</div>`;
const unavailable = (title, body) => `<div class="card card-pad unavail" role="status"><span class="chip amber">Not available yet</span><h3>${esc(title)}</h3><p>${esc(body)}</p></div>`;

function paginate(list) {
  const pages = Math.max(1, Math.ceil(list.length / PAGE));
  if (state.page > pages) state.page = pages;
  return { rows: list.slice((state.page - 1) * PAGE, state.page * PAGE), pages, total: list.length };
}
function pager({ pages, total }, noun) {
  if (!total) return '';
  const p = state.page, from = (p - 1) * PAGE + 1, to = Math.min(total, p * PAGE);
  const list = [...new Set([1, pages, p - 1, p, p + 1].filter(x => x >= 1 && x <= pages))].sort((a, b) => a - b);
  let html = '', prev = 0;
  for (const x of list) { if (x - prev > 1) html += '<span class="page-gap">…</span>'; html += `<button class="page ${x === p ? 'active' : ''}" data-page="${x}" ${x === p ? 'aria-current="page"' : ''}>${x}</button>`; prev = x; }
  return `<div class="pagination"><span>Showing ${num(from)}–${num(to)} of ${num(total)} ${esc(noun)}</span><div class="pages"><button class="page" data-page="${p - 1}" ${p === 1 ? 'disabled' : ''} aria-label="Previous page">‹</button>${html}<button class="page" data-page="${p + 1}" ${p === pages ? 'disabled' : ''} aria-label="Next page">›</button></div></div>`;
}
function table(headers, rows, selectType = '') {
  if (!rows.length) return '';
  return `<div class="table-wrap"><table class="table"><thead><tr>${headers.map(h => `<th>${esc(h)}</th>`).join('')}</tr></thead><tbody>${rows.map(r => `<tr class="${selectType && state.drawer?.type === selectType && String(state.drawer?.id) === String(r.id) ? 'selected' : ''}" ${selectType ? `data-select="${selectType}" data-id="${esc(r.id)}" tabindex="0"` : ''}>${r.cells.map(c => `<td>${c}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`;
}
const match = (q, ...fields) => !q || fields.join(' ').toLowerCase().includes(q.toLowerCase());
const f = k => state.filters[k] ?? '';
const distinct = (list, key) => [...new Set(list.map(x => x[key]).filter(Boolean))].sort((a, b) => String(a).localeCompare(String(b)));
const byName = key => (a, b) => String(a[key] || '').localeCompare(String(b[key] || ''));
const byTime = key => (a, b) => new Date(b[key] || 0) - new Date(a[key] || 0);
const scopeLabel = s => SCOPES.find(x => x[0] === s)?.[1] || s;

// ------------------------------------------------------------------ pages
function overview() {
  const keys = NEEDS.overview;
  const vendors = data.vendors || [], ops = data.ops || [], stuck = data.stuck || [], audit = data.audit || [];
  const windows = data.windows || [], anns = data.activeAnns || [], flags = data.flags || [], versions = data.versions || [];
  const live = windows.filter(w => !w.ended_at);
  const orders30 = vendors.reduce((s, v) => s + Number(v.order_count_30d || 0), 0);
  const unassigned = ops.filter(o => !o.assigned_rider_id).length;
  const byStatus = OPS_STATUSES.map(s => [s, ops.filter(o => o.delivery_status === s).length]);
  const max = Math.max(1, ...byStatus.map(x => x[1]));
  const today = new Date().toLocaleDateString('en-MY', { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric', timeZone: TZ });
  const title = head(today, 'Cefflo at a glance', 'Live platform state across every business.');
  if (failed(['vendors']) && !ready(['vendors'])) return title + errorBlock(['vendors']);
  const k = (key, html) => (key in data) ? html : errors[key] ? '<span class="sub inline">unavailable</span>' : '…';
  return `${title}
  ${metrics([
    [k('vendors', num(vendors.length)), 'Vendors', k('vendors', `${num(vendors.filter(v => Number(v.order_count_30d) > 0).length)} ordered in 30 days`)],
    [k('vendors', num(orders30)), 'Orders (30 days)'],
    [k('ops', num(ops.length)), 'Deliveries in flight', k('ops', unassigned ? `${num(unassigned)} unassigned` : 'all assigned'), unassigned > 0],
    [k('stuck', num(stuck.length)), 'Riders not reporting', k('stuck', `no location for ${state.stuckMinutes}+ min`), stuck.length > 0],
  ], false)}
  <div class="layout-right"><div>
    <div class="card card-pad"><div class="card-title"><h3>Deliveries in flight by status</h3><button class="link" data-go="operations">View all</button></div>
      ${!('ops' in data) ? (errors.ops ? errorBlock(['ops']) : '<div class="skel"></div><div class="skel"></div>') : ops.length ? byStatus.map(([s, n]) => `<div class="list-row clickable" data-go="operations" data-go-tab="${s}"><span class="grow">${esc(human(s))}</span><div class="progress" style="width:180px"><i style="width:${n / max * 100}%"></i></div><b style="width:40px;text-align:right">${num(n)}</b></div>`).join('') : emptyBlock('No deliveries in flight', 'Every order is delivered or cancelled.')}
    </div>
    <div class="card card-pad" style="margin-top:12px"><div class="card-title"><h3>Latest admin activity</h3><button class="link" data-go="audit">View all</button></div>
      ${!('audit' in data) ? (errors.audit ? errorBlock(['audit']) : '<div class="skel"></div>') : audit.length ? audit.slice(0, 6).map(a => `<div class="list-row clickable" data-go="audit" data-open="audit:${esc(a.id)}"><span style="width:110px">${esc(fmtDateTime(a.created_at))}</span><i class="dot"></i><b class="grow">${esc(human(a.action))}</b><span class="sub inline">${esc(human(a.target_type || ''))}</span><span>›</span></div>`).join('') : emptyBlock('No admin actions recorded yet')}
    </div>
  </div><aside class="stack">
    <div><div class="card-title"><h3>Platform controls</h3></div>
      ${insight('controls', 'maintenance', 'Maintenance', 'windows', live.length ? `${live.length} active: ${live.map(w => scopeLabel(w.scope)).join(', ')}` : 'No active maintenance', live.length ? 'red' : '')}
      ${insight('controls', 'announcements', 'Announcements', 'activeAnns', anns.length ? `${anns.length} live now` : 'None live', anns.some(a => a.severity === 'critical') ? 'red' : anns.length ? 'amber' : '')}
      ${insight('controls', 'flags', 'Feature flags', 'flags', `${flags.filter(x => x.enabled).length} of ${flags.length} on`)}
      ${insight('product', '', 'Client versions', 'versions', versions.length ? `${versions.length} releases recorded` : 'No releases recorded yet', versions.length ? '' : 'amber')}
    </div>
    <div class="card card-pad"><div class="card-title"><h3>Needs attention</h3><button class="link" data-go="riders" data-go-tab="stuck">View all</button></div>
      ${!('stuck' in data) ? (errors.stuck ? errorBlock(['stuck']) : '<div class="skel"></div>') : stuck.length ? stuck.slice(0, 5).map(s => `<div class="list-row clickable" data-go="riders" data-go-tab="stuck" data-open="rider:${esc(s.rider_id)}"><i class="dot" style="background:var(--amber)"></i><span class="grow"><b>${esc(s.rider_name)}</b><span class="sub">${esc(s.business_name)} · ${esc(human(s.assignment_status))}</span></span><span class="sub inline">${s.last_recorded_at ? esc(ago(s.last_recorded_at)) : 'never'}</span></div>`).join('') : emptyBlock('Nothing needs attention', 'Every rider on a job is reporting location.')}
    </div>
  </aside></div>`;
}
function insight(route, tab, title, key, text, tone = '') {
  const body = (key in data) ? esc(text) : errors[key] ? 'Could not load' : 'Loading…';
  return `<div class="insight clickable" data-go="${route}" ${tab ? `data-go-tab="${tab}"` : ''}><i class="insight-dot" style="background:${tone === 'red' ? 'var(--red)' : tone === 'amber' ? 'var(--amber)' : 'var(--green)'}"></i><div class="grow"><b>${esc(title)}</b><p>${body}</p></div><span>›</span></div>`;
}

// --- Vendors
function vendorList() {
  const subs = new Map((data.subs || []).map(s => [s.business_id, s]));
  return (data.vendors || []).map(v => ({ ...v, sub: subs.get(v.business_id) || null }));
}
function vendors() {
  const keys = NEEDS.vendors;
  const title = head('Vendors', 'Vendors', 'Every business on Cefflo, with activity and admin-recorded subscription.');
  if (failed(keys)) return title + errorBlock(keys);
  if (!ready(keys)) return title + loadingBlock();
  const all = vendorList();
  const status = v => v.sub?.status || 'not_set';
  const tabList = [['all', 'All', all.length], ...['active', 'trial', 'past_due', 'suspended', 'cancelled', 'not_set'].map(s => [s, s === 'not_set' ? 'Not set' : human(s), all.filter(v => status(v) === s).length])];
  const tab = state.tab || 'all';
  const list = all.filter(v => (tab === 'all' || status(v) === tab)
    && match(state.query, v.name, v.email, v.phone, v.operating_area)
    && (!f('activity') || (f('activity') === 'active' ? Number(v.order_count_30d) > 0 : !Number(v.order_count_30d)))
    && (!f('plan') || (v.sub?.plan_key || '') === f('plan')));
  const sort = f('sort') || 'newest';
  list.sort(sort === 'name' ? byName('name') : sort === 'orders' ? (a, b) => Number(b.order_count_30d) - Number(a.order_count_30d) : byTime('created_at'));
  const pg = paginate(list);
  const plans = distinct(all.map(v => ({ p: v.sub?.plan_key })), 'p');
  return `${title}
  ${metrics([
    [num(all.length), 'Vendors'],
    [num(all.filter(v => Number(v.order_count_30d) > 0).length), 'Ordered in 30 days'],
    [num(all.reduce((s, v) => s + Number(v.order_count_30d || 0), 0)), 'Orders (30 days)'],
    [num(all.reduce((s, v) => s + Number(v.active_rider_count || 0), 0)), 'Active riders'],
    [num(all.filter(v => ['suspended', 'past_due'].includes(status(v))).length), 'Past due or suspended', '', all.some(v => ['suspended', 'past_due'].includes(status(v)))],
  ])}
  ${tabs(tabList, tab)}
  ${toolbar('Search name, email, phone or area…', select('activity', [['', 'All activity'], ['active', 'Ordered in 30 days'], ['idle', 'No orders in 30 days']], 'Activity') + select('plan', [['', 'All plans'], ...plans.map(p => [p, human(p)])], 'Plan') + select('sort', [['newest', 'Newest first'], ['name', 'Name A–Z'], ['orders', 'Most orders (30d)']], 'Sort'))}
  ${pg.total ? table(['Vendor', 'Area', 'Plan', 'Subscription', 'Orders (30d)', 'Active riders', 'Last order', 'Joined'], pg.rows.map(v => ({ id: v.business_id, cells: [
    `<div class="entity"><span class="entity-avatar">${esc(initials(v.name))}</span><span><strong>${esc(v.name)}</strong><span class="sub">${esc(v.email || v.phone || '—')}</span></span></div>`,
    esc(v.operating_area || '—'), esc(v.sub?.plan_key ? human(v.sub.plan_key) : '—'), statusChip(status(v)), `<b>${num(v.order_count_30d)}</b>`, num(v.active_rider_count), esc(v.last_order_at ? ago(v.last_order_at) : 'Never'), esc(fmtDate(v.created_at)),
  ] })), 'vendor') : emptyBlock(all.length ? 'No vendors match these filters' : 'No vendors yet', all.length ? 'Clear the search or filters.' : 'Businesses appear here once they sign up.')}
  ${pager(pg, 'vendors')}`;
}

// --- Operations
const OPS_STATUSES = ['created', 'ready_for_pickup', 'picked_up', 'out_for_delivery', 'arrived', 'issue'];
const staleRider = o => o.assigned_rider_id && (!o.rider_last_seen || Date.now() - new Date(o.rider_last_seen) > 15 * 60000);
function operations() {
  const title = head('Operations', 'Deliveries in flight', 'Every order not yet delivered or cancelled, across all businesses, with its rider’s last known position.');
  if (failed(['ops'])) return title + errorBlock(['ops']);
  if (!ready(['ops'])) return title + loadingBlock();
  const all = data.ops;
  const tab = state.tab || 'all';
  const list = all.filter(o => (tab === 'all' || o.delivery_status === tab)
    && match(state.query, o.public_ref, o.business_name, o.rider_name)
    && (!f('vendor') || o.business_id === f('vendor'))
    && (!f('rider') || (f('rider') === 'assigned' ? !!o.assigned_rider_id : f('rider') === 'unassigned' ? !o.assigned_rider_id : staleRider(o))));
  list.sort(f('sort') === 'oldest' ? (a, b) => new Date(a.created_at) - new Date(b.created_at) : byTime('created_at'));
  const pg = paginate(list);
  const vendorsOpt = [...new Map(all.map(o => [o.business_id, o.business_name])).entries()].sort((a, b) => String(a[1]).localeCompare(String(b[1])));
  return `${title}
  ${metrics([
    [num(all.length), 'In flight'],
    [num(all.filter(o => !o.assigned_rider_id).length), 'Unassigned', '', all.some(o => !o.assigned_rider_id)],
    [num(all.filter(o => ['picked_up', 'out_for_delivery', 'arrived'].includes(o.delivery_status)).length), 'On the road'],
    [num(all.filter(o => o.delivery_status === 'issue').length), 'Issues', '', all.some(o => o.delivery_status === 'issue')],
    [num(all.filter(staleRider).length), 'Rider location stale (15+ min)', '', all.some(staleRider)],
  ])}
  ${tabs([['all', 'All in flight', all.length], ...OPS_STATUSES.map(s => [s, human(s), all.filter(o => o.delivery_status === s).length])], tab)}
  ${toolbar('Search order ref, vendor or rider…', select('vendor', [['', 'All vendors'], ...vendorsOpt], 'Vendor') + select('rider', [['', 'All riders'], ['assigned', 'Rider assigned'], ['unassigned', 'No rider'], ['stale', 'Location stale']], 'Rider') + select('sort', [['newest', 'Newest first'], ['oldest', 'Oldest first']], 'Sort'))}
  ${pg.total ? table(['Order', 'Vendor', 'Status', 'Rider', 'Rider last seen', 'ETA', 'Created'], pg.rows.map(o => ({ id: o.order_id, cells: [
    `<b style="color:#0870de">${esc(o.public_ref || shortId(o.order_id))}</b>`, esc(o.business_name), statusChip(o.delivery_status),
    o.rider_name ? `<b>${esc(o.rider_name)}</b>` : chip('Unassigned', 'amber'),
    o.assigned_rider_id ? (o.rider_last_seen ? `<span class="${staleRider(o) ? 'warn' : ''}">${esc(ago(o.rider_last_seen))}</span>` : '<span class="warn">No location yet</span>') : '—',
    esc(o.estimated_arrival_at ? fmtTime(o.estimated_arrival_at) : '—'), esc(fmtDateTime(o.created_at)),
  ] })), 'order') : emptyBlock(all.length ? 'No deliveries match these filters' : 'No deliveries in flight', all.length ? 'Clear the search or filters.' : 'Every order is delivered or cancelled.')}
  ${pager(pg, 'deliveries')}`;
}

// --- Riders
function riders() {
  const title = head('Riders', 'Riders', 'Every rider across all businesses, and riders on a job who stopped reporting location.');
  const tab = state.tab || 'all';
  if (tab === 'stuck') {
    if (failed(['stuck'])) return title + ridersTabs() + errorBlock(['stuck']);
    if (!ready(['stuck'])) return title + ridersTabs() + loadingBlock();
    const list = data.stuck.filter(s => match(state.query, s.rider_name, s.rider_phone, s.business_name));
    list.sort((a, b) => Number(b.minutes_since_last_location ?? 1e9) - Number(a.minutes_since_last_location ?? 1e9));
    const pg = paginate(list);
    return `${title}${ridersSummary()}${ridersTabs()}
    <div class="toolbar"><div class="search"><span class="search-icon">${I.search}</span><input data-search placeholder="Search rider, phone or vendor…" value="${esc(state.query)}" aria-label="Search riders not reporting"></div>
      <label class="inline-label">No location for <select class="select" data-stuck aria-label="Silence threshold">${[15, 30, 45, 60, 120].map(m => `<option value="${m}" ${m === state.stuckMinutes ? 'selected' : ''}>${m}+ min</option>`).join('')}</select></label></div>
    ${pg.total ? table(['Rider', 'Vendor', 'Job status', 'Last location', 'Minutes silent'], pg.rows.map(s => ({ id: s.rider_id, cells: [
      `<b>${esc(s.rider_name)}</b><span class="sub">${esc(s.rider_phone || '')}</span>`, esc(s.business_name), statusChip(s.assignment_status),
      esc(s.last_recorded_at ? fmtDateTime(s.last_recorded_at) : 'Never reported'), `<b class="warn">${s.minutes_since_last_location == null ? '—' : num(Math.round(s.minutes_since_last_location))}</b>`,
    ] })), 'rider') : emptyBlock(data.stuck.length ? 'No riders match' : 'No riders are silent', data.stuck.length ? '' : `Every rider on an active job reported location in the last ${state.stuckMinutes} minutes.`)}
    ${pager(pg, 'riders')}`;
  }
  if (failed(['riders'])) return title + errorBlock(['riders']);
  if (!ready(['riders'])) return title + loadingBlock();
  const all = data.riders;
  const list = all.filter(r => (tab === 'all' || r.status === tab)
    && match(state.query, r.name, r.phone, r.vehicle_plate, r.business_name)
    && (!f('vendor') || r.business_id === f('vendor'))
    && (!f('avail') || r.availability_status === f('avail')));
  const sort = f('sort') || 'newest';
  list.sort(sort === 'name' ? byName('name') : sort === 'delivered' ? (a, b) => Number(b.delivered_count_30d) - Number(a.delivered_count_30d) : byTime('created_at'));
  const pg = paginate(list);
  const vendorsOpt = [...new Map(all.map(r => [r.business_id, r.business_name])).entries()].sort((a, b) => String(a[1]).localeCompare(String(b[1])));
  return `${title}${ridersSummary()}${ridersTabs()}
  ${toolbar('Search name, phone, plate or vendor…', select('vendor', [['', 'All vendors'], ...vendorsOpt], 'Vendor') + select('avail', [['', 'Any availability'], ['online', 'Online'], ['offline', 'Offline']], 'Availability') + select('sort', [['newest', 'Newest first'], ['name', 'Name A–Z'], ['delivered', 'Most delivered (30d)']], 'Sort'))}
  ${pg.total ? table(['Rider', 'Vendor', 'Vehicle plate', 'Status', 'Availability', 'Delivered (30d)', 'Active jobs', 'Joined'], pg.rows.map(r => ({ id: r.rider_id, cells: [
    `<div class="entity"><span class="entity-avatar">${esc(initials(r.name))}</span><span><strong>${esc(r.name)}</strong><span class="sub">${esc(r.phone || '')}</span></span></div>`,
    esc(r.business_name), esc(r.vehicle_plate || '—'), statusChip(r.status), statusChip(r.availability_status), num(r.delivered_count_30d), num(r.active_assignment_count), esc(fmtDate(r.created_at)),
  ] })), 'rider') : emptyBlock(all.length ? 'No riders match these filters' : 'No riders yet', all.length ? 'Clear the search or filters.' : 'Riders appear once a business invites them.')}
  ${pager(pg, 'riders')}`;
}
function ridersSummary() {
  const all = data.riders || [];
  const k = html => ('riders' in data) ? html : '…';
  return metrics([
    [k(num(all.length)), 'Riders'], [k(num(all.filter(r => r.status === 'active').length)), 'Active'],
    [k(num(all.filter(r => r.availability_status === 'online').length)), 'Online now'],
    [k(num(all.filter(r => r.status === 'pending').length)), 'Pending approval'],
    [('stuck' in data) ? num(data.stuck.length) : '…', `Silent ${state.stuckMinutes}+ min on a job`, '', (data.stuck || []).length > 0],
  ]);
}
function ridersTabs() {
  const all = data.riders || [];
  const c = s => ('riders' in data) ? all.filter(r => r.status === s).length : null;
  return tabs([['all', 'All', ('riders' in data) ? all.length : null], ...['active', 'pending', 'inactive'].map(s => [s, human(s), c(s)]), ['stuck', 'Not reporting', ('stuck' in data) ? data.stuck.length : null]], state.tab || 'all');
}

// --- Controls: Maintenance, Feature Flags, Announcements (emergency comms)
const SCOPES = [['all', 'All surfaces'], ['vendor', 'Vendor'], ['rider', 'Rider / Driver'], ['customer', 'Customer Tracking'], ['invite', 'Invite'], ['foundr', 'FOUNDR']];
function controls() {
  const tab = state.tab || 'maintenance';
  const title = head('Controls', 'Platform controls', 'Emergency maintenance, feature flags, platform announcements and notification broadcasts. Every change is confirmed and written to the audit log.');
  const t = tabs([['maintenance', 'Maintenance'], ['flags', 'Feature flags'], ['announcements', 'Announcements'], ['broadcasts', 'Broadcasts']], tab);
  const key = { maintenance: 'windows', flags: 'flags', announcements: 'anns', broadcasts: 'broadcasts' }[tab];
  if (tab === 'broadcasts') ensure(['broadcasts', 'vendors']);
  if (failed([key])) return title + t + errorBlock([key]);
  if (!ready([key])) return title + t + loadingBlock();
  if (tab === 'broadcasts') {
    const list = data.broadcasts.filter(x => match(state.query, x.title, x.body, x.reason, x.business_name) && (!f('aud') || x.audience === f('aud')));
    const pg = paginate(list);
    return `${title}${t}
    <div class="card card-pad status-panel" style="margin-bottom:12px"><p class="sub">Sends an in-app notification to the Vendor and/or Rider notification centre of every account in the audience, with a banner and sound while the app is open. Push to closed apps is not connected yet, so this is not an emergency channel for users who are offline; use a critical announcement for that.</p></div>
    ${toolbar('Search broadcasts…', select('aud', [['', 'All audiences'], ...AUDIENCES], 'Audience') + `<button class="btn primary" data-modal="broadcast" ${'vendors' in data ? '' : 'disabled'}>＋ New broadcast</button>`)}
    ${pg.total ? table(['Broadcast', 'Audience', 'Recipients', 'Read', 'Reason', 'Sent'], pg.rows.map(x => ({ id: x.id, cells: [`<b>${esc(x.title)}</b><span class="sub">${esc(x.body)}</span>`, esc(audienceLabel(x.audience)) + (x.business_name ? `<span class="sub">${esc(x.business_name)}</span>` : ''), num(x.recipient_count), `${num(x.read_count)}<span class="sub">${x.recipient_count ? Math.round(100 * x.read_count / x.recipient_count) + '%' : '—'}</span>`, esc(x.reason), esc(fmtDateTime(x.created_at))] }))) : emptyBlock(data.broadcasts.length ? 'No broadcasts match' : 'No broadcasts yet', data.broadcasts.length ? '' : 'Broadcasts appear here with their recipient and read counts.')}
    ${pager(pg, 'broadcasts')}`;
  }
  if (tab === 'maintenance') {
    const live = data.windows.filter(w => !w.ended_at);
    const pg = paginate(data.windows);
    return `${title}${t}
    <div class="card card-pad ${live.length ? 'danger-panel' : 'status-panel'}" style="margin-bottom:12px">
      <div class="card-title"><h3>${live.length ? `Maintenance active (${live.length})` : 'No maintenance active'}</h3><button class="btn danger" data-modal="maintenance">Start maintenance</button></div>
      ${live.length ? live.map(w => `<div class="list-row"><span class="grow"><b>${esc(scopeLabel(w.scope))}</b><span class="sub">${esc(w.reason)} · started ${esc(fmtDateTime(w.started_at))}${w.expected_duration_minutes ? ` · expected ${num(w.expected_duration_minutes)} min` : ''}</span><span class="sub">Rollback: ${esc(w.rollback_condition)}</span></span><button class="btn" data-end="${esc(w.id)}">End</button></div>`).join('') : '<p class="sub">Maintenance is emergency-only (F-05). Normal releases go through Client Versions, without interrupting users.</p>'}
    </div>
    <div class="card-title"><h3>History</h3></div>
    ${pg.total ? table(['Scope', 'Reason', 'Rollback condition', 'Started', 'Ended', 'Status'], pg.rows.map(w => ({ id: w.id, cells: [esc(scopeLabel(w.scope)), esc(w.reason), esc(w.rollback_condition), esc(fmtDateTime(w.started_at)), esc(w.ended_at ? fmtDateTime(w.ended_at) : '—'), w.ended_at ? chip('Ended', 'blue') : chip('Active', 'red')] }))) : emptyBlock('No maintenance windows recorded')}
    ${pager(pg, 'windows')}`;
  }
  if (tab === 'flags') {
    const list = data.flags.filter(x => match(state.query, x.key, x.description));
    const pg = paginate(list);
    return `${title}${t}
    <div class="toolbar"><div class="search"><span class="search-icon">${I.search}</span><input data-search placeholder="Search flag key or description…" value="${esc(state.query)}" aria-label="Search flags"></div><button class="btn primary" data-modal="flag">＋ New flag</button></div>
    ${pg.total ? table(['Flag', 'Description', 'State', 'Last changed', ''], pg.rows.map(x => ({ id: x.key, cells: [`<code>${esc(x.key)}</code>`, esc(x.description || '—'), x.enabled ? chip('On') : chip('Off', 'blue'), esc(fmtDateTime(x.updated_at)), `<button class="toggle ${x.enabled ? 'on' : ''}" data-flag="${esc(x.key)}" role="switch" aria-checked="${x.enabled}" aria-label="Turn ${esc(x.key)} ${x.enabled ? 'off' : 'on'}"></button>`] }))) : emptyBlock(data.flags.length ? 'No flags match' : 'No feature flags yet', data.flags.length ? '' : 'Create one with New flag.')}
    ${pager(pg, 'flags')}`;
  }
  const anns = data.anns;
  const isLive = a => a.active && new Date(a.starts_at) <= Date.now() && (!a.ends_at || new Date(a.ends_at) > Date.now());
  const list = anns.filter(a => match(state.query, a.title, a.body) && (!f('sev') || a.severity === f('sev')));
  const pg = paginate(list);
  return `${title}${t}
  ${toolbar('Search announcements…', select('sev', [['', 'All severities'], ['info', 'Info'], ['warning', 'Warning'], ['critical', 'Critical (emergency)']], 'Severity') + '<button class="btn primary" data-modal="announcement">＋ New announcement</button>')}
  ${pg.total ? table(['Announcement', 'Severity', 'Window', 'State', ''], pg.rows.map(a => ({ id: a.id, cells: [`<b>${esc(a.title)}</b><span class="sub">${esc(a.body)}</span>`, statusChip(a.severity), `${esc(fmtDateTime(a.starts_at))}<span class="sub">${a.ends_at ? 'until ' + esc(fmtDateTime(a.ends_at)) : 'no end'}</span>`, isLive(a) ? chip('Live') : a.active ? chip('Outside window', 'blue') : chip('Off', 'blue'), `<button class="btn" data-ann="${esc(a.id)}" data-active="${a.active ? 0 : 1}">${a.active ? 'Turn off' : 'Turn on'}</button>`] }))) : emptyBlock(anns.length ? 'No announcements match' : 'No announcements yet', anns.length ? '' : 'Critical announcements are the emergency channel to every client app.')}
  ${pager(pg, 'announcements')}`;
}

const AUDIENCES = [['vendors', 'All vendors (Owners and Operators)'], ['riders', 'All riders'], ['all', 'Everyone (vendors and riders)'], ['business', 'One business (its Owners and Operators)']];
const audienceLabel = a => AUDIENCES.find(x => x[0] === a)?.[1] || a;

// --- Client Versions
const APPS = [['vendor', 'Vendor'], ['rider', 'Rider / Driver'], ['customer', 'Customer Tracking'], ['invite', 'Invite'], ['foundr', 'FOUNDR']];
function product() {
  const title = head('Client Version Control', 'Client versions', 'The release register for each client app: current version and minimum supported version.', '<button class="btn primary" data-modal="version">＋ Record release</button>');
  if (failed(['versions'])) return title + errorBlock(['versions']);
  if (!ready(['versions'])) return title + loadingBlock();
  const all = data.versions;
  const latest = app => all.filter(v => v.app === app).sort(byTime('released_at'))[0];
  const list = all.filter(v => (!f('app') || v.app === f('app')) && match(state.query, v.version, v.min_supported_version, v.notes));
  const pg = paginate(list);
  return `${title}
  <div class="version-grid">${APPS.map(([id, label]) => { const v = latest(id); return `<div class="card card-pad"><div class="eyebrow">${esc(label)}</div><div class="metric-value">${v ? esc(v.version) : '—'}</div><div class="sub">${v ? `Min supported ${esc(v.min_supported_version || '—')} · ${esc(fmtDate(v.released_at))}` : 'No release recorded'}</div></div>`; }).join('')}</div>
  <p class="note">Client apps do not report their running version to the backend yet, so this register is kept by hand, one audited entry per release.</p>
  ${toolbar('Search version or notes…', select('app', [['', 'All apps'], ...APPS], 'App'))}
  ${pg.total ? table(['App', 'Version', 'Min supported', 'Notes', 'Released'], pg.rows.map(v => ({ id: v.id, cells: [esc(APPS.find(a => a[0] === v.app)?.[1] || v.app), `<b>${esc(v.version)}</b>`, esc(v.min_supported_version || '—'), esc(v.notes || '—'), esc(fmtDateTime(v.released_at))] }))) : emptyBlock(all.length ? 'No releases match' : 'No releases recorded yet', all.length ? '' : 'Record the first release with Record release.')}
  ${pager(pg, 'releases')}`;
}

// --- Subscriptions (admin-set; no payment gateway)
const SUB_STATUSES = ['trial', 'active', 'past_due', 'suspended', 'cancelled'];
function business() {
  const title = head('Business', 'Subscriptions', 'Plan and status per business, as recorded by a platform admin. There is no payment gateway: nothing here is billed or computed.');
  if (failed(['subs'])) return title + errorBlock(['subs']);
  if (!ready(['subs'])) return title + loadingBlock();
  const all = data.subs;
  const st = s => s.status || 'not_set';
  const mrr = all.filter(s => s.status === 'active').reduce((t, s) => t + Number(s.mrr_cents || 0), 0);
  const plans = distinct(all, 'plan_key');
  const list = all.filter(s => match(state.query, s.business_name, s.plan_key) && (!f('status') || st(s) === f('status')) && (!f('plan') || s.plan_key === f('plan')));
  list.sort(byName('business_name'));
  const pg = paginate(list);
  return `${title}
  ${metrics([[num(all.length), 'Businesses'], [rm(mrr), 'Recorded MRR (active)'], [num(all.filter(s => s.status === 'active').length), 'Active'], [num(all.filter(s => s.status === 'trial').length), 'Trial'], [num(all.filter(s => !s.status).length), 'Not set', '', all.some(s => !s.status)]])}
  ${toolbar('Search business or plan…', select('status', [['', 'All statuses'], ...SUB_STATUSES.map(s => [s, human(s)]), ['not_set', 'Not set']], 'Status') + select('plan', [['', 'All plans'], ...plans.map(p => [p, human(p)])], 'Plan'))}
  ${pg.total ? table(['Business', 'Plan', 'Status', 'MRR', 'Trial ends', 'Updated'], pg.rows.map(s => ({ id: s.business_id, cells: [`<b>${esc(s.business_name)}</b>`, esc(s.plan_key ? human(s.plan_key) : '—'), statusChip(st(s)), esc(rm(s.mrr_cents)), esc(fmtDate(s.trial_ends_at)), esc(s.updated_at ? fmtDateTime(s.updated_at) : '—')] })), 'vendor') : emptyBlock(all.length ? 'No subscriptions match' : 'No businesses yet')}
  ${pager(pg, 'businesses')}`;
}

// --- System health
let health = null;
async function runHealth() {
  health = { running: true };
  render();
  const out = { at: new Date() };
  try { out.latency = await F.probe(); out.api = 'reachable'; } catch (e) { out.api = 'unreachable'; out.apiError = e.message; }
  try { await F.listAuditLog(1); out.audit = 'reachable'; } catch (e) { out.audit = 'unreachable'; out.auditError = e.message; }
  const s = F.session();
  out.sessionExp = s?.expires_at ? new Date(s.expires_at * 1000) : null;
  health = out;
  render();
}
function system() {
  const title = head('System', 'System health', 'Live checks FOUNDR can make itself, and the health sources that are not connected yet.', `<button class="btn" data-health>${I.refresh} Run checks again</button>`);
  if (!health) { health = { running: true }; queueMicrotask(runHealth); }
  if (health.running) return title + loadingBlock(3);
  const live = (data.windows || []).filter(w => !w.ended_at);
  return `${title}
  ${metrics([
    [health.api === 'reachable' ? chip('Reachable') : chip('Unreachable', 'red'), 'Supabase API', health.api === 'reachable' ? `${num(health.latency)} ms round trip` : esc(health.apiError), health.api !== 'reachable'],
    [health.audit === 'reachable' ? chip('Readable') : chip('Unreachable', 'red'), 'Audit log', health.audit === 'reachable' ? 'admin read works' : esc(health.auditError), health.audit !== 'reachable'],
    [health.sessionExp ? chip('Valid') : chip('Unknown', 'amber'), 'Admin session', health.sessionExp ? `until ${esc(fmtTime(health.sessionExp.toISOString()))}` : ''],
    [('windows' in data) ? (live.length ? chip('Active', 'red') : chip('None')) : '…', 'Maintenance'],
    [('admins' in data) ? num(data.admins.length) : '…', 'Platform admins'],
  ])}
  <p class="note">Checked ${esc(health.at.toLocaleTimeString('en-MY', { timeZone: TZ }))}. These are the only checks FOUNDR can run today.</p>
  ${unavailable('Integrations and infrastructure health', 'Vercel deployments, Cloudflare/DNS, Mapbox geocoding, email delivery and uptime history need a monitoring source connected to FOUNDR. Until then FOUNDR shows no status for them rather than a guessed one.')}`;
}

// --- Audit log
const AUDIT_GROUPS = [['all', 'All'], ['maintenance', 'Maintenance'], ['feature_flag', 'Feature flags'], ['subscription', 'Subscriptions'], ['version', 'Versions'], ['announcement', 'Announcements'], ['broadcast', 'Broadcasts']];
const inGroup = (a, g) => g === 'all' || String(a.action).includes(g) || String(a.target_type || '').includes(g);
function auditRows() {
  const list = (data.audit || []).filter(a => inGroup(a, state.tab || 'all')
    && match(state.query, a.action, a.target_type, a.target_id, a.reason, a.admin_user_id, JSON.stringify(a.metadata || {}))
    && (!f('action') || a.action === f('action')) && (!f('target') || a.target_type === f('target')));
  if (f('sort') === 'oldest') list.sort((a, b) => new Date(a.created_at) - new Date(b.created_at));
  return list;
}
function audit() {
  const title = head('Audit', 'Audit log', 'Every privileged FOUNDR action, as recorded by the backend. Append-only.', '<button class="btn" data-export>⇩ Export CSV</button>');
  if (failed(['audit'])) return title + errorBlock(['audit']);
  if (!ready(['audit'])) return title + loadingBlock();
  const all = data.audit;
  const list = auditRows();
  const pg = paginate(list);
  const who = id => !id ? 'System' : me.user?.id === id ? 'You' : shortId(id);
  return `${title}
  ${tabs(AUDIT_GROUPS.map(([id, l]) => [id, l, all.filter(a => inGroup(a, id)).length]), state.tab || 'all')}
  ${toolbar('Search action, target, reason or admin…', select('action', [['', 'All actions'], ...distinct(all, 'action').map(a => [a, human(a)])], 'Action') + select('target', [['', 'All targets'], ...distinct(all, 'target_type').map(a => [a, human(a)])], 'Target') + select('sort', [['newest', 'Newest first'], ['oldest', 'Oldest first']], 'Sort'))}
  ${pg.total ? table(['Time', 'Admin', 'Action', 'Target', 'Reason', 'Details'], pg.rows.map(a => ({ id: a.id, cells: [esc(fmtDateTime(a.created_at)), `<div class="entity"><span class="entity-avatar">${esc(who(a.admin_user_id)[0])}</span><span>${esc(who(a.admin_user_id))}</span></div>`, `<b>${esc(human(a.action))}</b>`, `${esc(human(a.target_type || '—'))}<span class="sub">${esc(a.target_id || '')}</span>`, esc(a.reason || '—'), `<span class="sub inline">${esc(Object.entries(a.metadata || {}).map(([k, v]) => `${k}: ${v}`).join(' · ') || '—')}</span>`] })), 'audit') : emptyBlock(all.length ? 'No entries match' : 'No admin actions recorded yet')}
  ${pager(pg, 'entries')}
  <p class="note">Showing the latest ${num(all.length)} entries (the backend returns at most 500 per request).</p>`;
}

// --- Not built: Support, Marketing (no backend source; outside the D-21 minimum scope)
const support = () => head('Support', 'Support & feedback', 'Customer, vendor and rider support.') + unavailable('Support tickets are not connected', 'There is no support-ticket backend in Cefflo yet. FOUNDR will show real tickets here once that backend exists.');
const marketing = () => head('Marketing', 'Marketing', 'Acquisition and ads performance.') + unavailable('Marketing data is not connected', 'Ads spend, leads and ROAS need an ads/analytics source connected to the backend. Until then FOUNDR shows no marketing numbers.');

// --- Settings
function settings() {
  const title = head('Settings', 'Account & access', 'Your admin account and who can open FOUNDR.');
  const mine = (data.admins || []).find(a => a.user_id === me.user?.id);
  return `${title}<div class="layout-right"><div>
    <div class="card card-pad"><div class="card-title"><h3>Your account</h3></div>
      <div class="kv"><span>Email</span><b>${esc(me.user?.email || '—')}</b></div>
      <div class="kv"><span>User ID</span><code>${esc(me.user?.id || '—')}</code></div>
      <div class="kv"><span>Admin role</span><span>${mine ? statusChip(mine.role) : ('admins' in data ? '—' : '…')}</span></div>
      <div class="kv"><span>Admin since</span><span>${esc(mine ? fmtDate(mine.created_at) : ('admins' in data ? '—' : '…'))}</span></div>
      <div class="modal-actions" style="justify-content:flex-start"><button class="btn danger" data-signout>Sign out</button></div>
    </div>
    <div class="card card-pad" style="margin-top:12px"><div class="card-title"><h3>Platform admins</h3></div>
      ${failed(['admins']) ? errorBlock(['admins']) : !ready(['admins']) ? '<div class="skel"></div>' : data.admins.length ? data.admins.map(a => `<div class="list-row"><span class="entity-avatar">${esc((a.role || 'a')[0].toUpperCase())}</span><span class="grow"><code>${esc(a.user_id)}</code>${a.user_id === me.user?.id ? ' <span class="chip blue">You</span>' : ''}</span>${statusChip(a.role)}<span class="sub inline">since ${esc(fmtDate(a.created_at))}</span></div>`).join('') : emptyBlock('No admins listed')}
      <p class="note">Admin access is granted directly in the database by design; FOUNDR has no self-service grant.</p>
    </div></div>
    <aside class="stack">${unavailable('Platform preferences', 'Company details, notification preferences and backups have no backend store yet.')}</aside></div>`;
}

const PAGES = { overview, vendors, operations, riders, controls, product, business, system, audit, support, marketing, settings };

// ------------------------------------------------------------------ drawer
const vendorDetail = {};
const vdPending = new Set();
function loadVendorDetail(id, force = false) {
  if (vdPending.has(id) || (!force && vendorDetail[id] !== undefined)) return;
  delete vendorDetail[id];
  vdPending.add(id);
  F.getVendor(id)
    .then(v => { vendorDetail[id] = v || new Error('Vendor not found'); })
    .catch(e => { vendorDetail[id] = e; handleAuthError(e); })
    .finally(() => { vdPending.delete(id); render(); });
}
const kvRows = rows => rows.map(([k, x]) => `<div class="kv"><span>${esc(k)}</span><span>${esc(x ?? '—')}</span></div>`).join('');
function drawer() {
  const d = state.drawer;
  if (!d) return '';
  const close = '<button class="drawer-close" data-close aria-label="Close">×</button>';
  let body = '';
  if (d.type === 'vendor') {
    const v = (data.vendors || []).find(x => x.business_id === d.id);
    const sub = (data.subs || []).find(s => s.business_id === d.id);
    const det = vendorDetail[d.id];
    if (det === undefined) queueMicrotask(() => loadVendorDetail(d.id));
    const name = v?.name || sub?.business_name || (det && !(det instanceof Error) ? det.name : '') || 'Vendor';
    body = `<div class="drawer-head"><span class="entity-avatar" style="width:42px;height:42px">${esc(initials(name))}</span><div><h2>${esc(name)}</h2>${statusChip(sub?.status || 'not_set')}</div>${close}</div>
    ${det === undefined ? '<div class="skel"></div><div class="skel"></div>' : det instanceof Error ? `<div class="err-card card card-pad" role="alert"><b>Could not load vendor details.</b><p class="sub">${esc(det.message)}</p><button class="btn" data-vendor-retry="${esc(d.id)}">Try again</button></div>` : `
      <div class="drawer-section"><h3>Business</h3>${kvRows([['Phone', det.phone || '—'], ['Email', det.email || '—'], ['Address', det.address || '—'], ['Area', det.operating_area || '—'], ['Joined', fmtDate(det.created_at)], ['Active members', num(det.member_count)]])}</div>
      <div class="drawer-section"><h3>Orders</h3>${kvRows([['Last 30 days', num(det.order_count_30d)], ['Delivered (30d)', num(det.delivered_count_30d)], ['Issues (30d)', num(det.issue_count_30d)], ['All time', num(det.order_count_total)], ['Riders', `${num(det.active_rider_count)} active of ${num(det.rider_count)}`]])}</div>`}
    <div class="drawer-section"><h3>Subscription</h3>${('subs' in data) ? kvRows([['Plan', sub?.plan_key ? human(sub.plan_key) : 'Not set'], ['Status', human(sub?.status || 'not set')], ['MRR', rm(sub?.mrr_cents)], ['Trial ends', fmtDate(sub?.trial_ends_at)], ['Updated', sub?.updated_at ? fmtDateTime(sub.updated_at) : '—']]) : errors.subs ? '<p class="sub">Subscription could not be loaded.</p>' : '<div class="skel"></div>'}
      <button class="btn primary" style="width:100%;margin-top:8px" data-modal="subscription" data-id="${esc(d.id)}" ${'subs' in data ? '' : 'disabled'}>Change subscription</button>
      <p class="sub">Recorded by hand for this business; no payment is taken.</p></div>`;
  } else if (d.type === 'order') {
    const o = (data.ops || []).find(x => x.order_id === d.id);
    if (!o) return '';
    body = `<div class="drawer-head"><div><h2>${esc(o.public_ref || shortId(o.order_id))}</h2>${statusChip(o.delivery_status)}</div>${close}</div>
    <div class="drawer-section"><h3>Order</h3>${kvRows([['Vendor', o.business_name], ['Created', fmtDateTime(o.created_at)], ['ETA', o.estimated_arrival_at ? fmtDateTime(o.estimated_arrival_at) : '—'], ['Order ID', o.order_id]])}
      <button class="link" data-open="vendor:${esc(o.business_id)}">Open vendor ›</button></div>
    <div class="drawer-section"><h3>Rider</h3>${o.assigned_rider_id ? `${kvRows([['Rider', o.rider_name], ['Last seen', o.rider_last_seen ? `${fmtDateTime(o.rider_last_seen)} (${ago(o.rider_last_seen)})` : 'No location reported']])}${o.rider_last_lat != null ? `<a class="btn" style="display:inline-block;margin-top:6px" target="_blank" rel="noopener" href="https://www.google.com/maps?q=${encodeURIComponent(o.rider_last_lat + ',' + o.rider_last_lng)}">Open last position in Maps ↗</a>` : ''}` : '<p class="sub">No rider assigned. The business assigns riders in Vendor.</p>'}</div>`;
  } else if (d.type === 'rider') {
    const r = (data.riders || []).find(x => x.rider_id === d.id);
    const s = (data.stuck || []).find(x => x.rider_id === d.id);
    if (!r && !s) return ('riders' in data) || ('stuck' in data) ? '' : `<aside class="drawer">${close}<div class="skel"></div></aside>`;
    body = `<div class="drawer-head"><span class="entity-avatar" style="width:42px;height:42px">${esc(initials(r?.name || s?.rider_name))}</span><div><h2>${esc(r?.name || s?.rider_name)}</h2>${r ? statusChip(r.status) : ''}</div>${close}</div>
    <div class="drawer-section"><h3>Rider</h3>${kvRows([['Phone', r?.phone || s?.rider_phone || '—'], ['Vendor', r?.business_name || s?.business_name], ['Vehicle plate', r?.vehicle_plate || '—'], ['Availability', r ? human(r.availability_status) : '—'], ['Delivered (30d)', r ? num(r.delivered_count_30d) : '—'], ['Active jobs', r ? num(r.active_assignment_count) : '—'], ['Joined', r ? fmtDate(r.created_at) : '—']])}
      <button class="link" data-open="vendor:${esc(r?.business_id || s?.business_id)}">Open vendor ›</button></div>
    ${s ? `<div class="drawer-section"><h3>Not reporting</h3>${kvRows([['Job status', human(s.assignment_status)], ['Last location', s.last_recorded_at ? `${fmtDateTime(s.last_recorded_at)} (${ago(s.last_recorded_at)})` : 'Never reported']])}</div>` : ''}`;
  } else if (d.type === 'audit') {
    const a = (data.audit || []).find(x => String(x.id) === String(d.id));
    if (!a) return ('audit' in data) ? '' : `<aside class="drawer">${close}<div class="skel"></div></aside>`;
    body = `<div class="drawer-head"><div><h2>${esc(human(a.action))}</h2><span class="sub">${esc(fmtDateTime(a.created_at))}</span></div>${close}</div>
    <div class="drawer-section">${kvRows([['Entry', `#${a.id}`], ['Admin', a.admin_user_id || 'System'], ['Target', `${human(a.target_type || '—')} ${a.target_id || ''}`], ['Reason', a.reason || '— (not captured by this action)']])}</div>
    <div class="drawer-section"><h3>Metadata</h3><pre class="json">${esc(JSON.stringify(a.metadata || {}, null, 2))}</pre></div>`;
  }
  return body ? `<aside class="drawer" aria-label="Details">${body}</aside>` : '';
}

// ------------------------------------------------------------------ modals (privileged writes)
// Each privileged action: form -> confirm (what will happen + audit note) ->
// the real RPC -> success only after the server returns. Actions whose
// backend contract has no reason parameter say so; FOUNDR never pretends to
// store a reason the backend does not accept.
const REASON_NOTE = 'This backend action records who did it, what changed and when. It has no reason field, so no reason is stored.';
function modal() {
  const m = state.modal;
  if (!m) return '';
  const wrap = (title, inner) => `<div class="modal-backdrop" data-backdrop><form class="modal" data-form role="dialog" aria-modal="true" aria-label="${esc(title)}" novalidate><h2>${esc(title)}</h2>${inner}<div class="field-err" ${m.error ? '' : 'hidden'} role="alert">${esc(m.error || '')}</div></form></div>`;
  const actions = (primary, danger = false) => `<div class="modal-actions"><button type="button" class="btn" data-modal-close ${m.busy ? 'disabled' : ''}>${m.step === 'confirm' && !DIRECT.has(m.type) ? 'Back' : 'Cancel'}</button><button type="submit" class="btn ${danger ? 'danger' : 'primary'}" ${m.busy ? 'disabled' : ''}>${m.busy ? 'Working…' : esc(primary)}</button></div>`;
  const v = m.values || {};
  const confirm = (lines, auditAction, reasonStored) => `<div class="confirm"><ul>${lines.filter(Boolean).map(l => `<li>${l}</li>`).join('')}</ul><p class="note">Recorded in the audit log as <code>${esc(auditAction)}</code>. ${reasonStored ? 'Your reason is stored with it.' : esc(REASON_NOTE)}</p></div>`;
  switch (m.type) {
    case 'maintenance':
      if (m.step === 'confirm') return wrap('Start maintenance?', confirm([`Scope: <b>${esc(scopeLabel(v.scope))}</b>`, `Reason: ${esc(v.reason)}`, `Expected duration: ${v.duration ? esc(v.duration) + ' min' : 'not set'}`, `Rollback condition: ${esc(v.rollback)}`, 'Users of this scope see the maintenance state until you end it.'], 'start_maintenance', true) + actions('Start maintenance', true));
      return wrap('Start maintenance', `<p class="sub">Emergency or exception only (F-05). The backend requires scope, reason and rollback condition.</p>
        <div class="field"><label for="m-scope">Scope</label><select id="m-scope" name="scope">${SCOPES.map(([id, l]) => `<option value="${id}" ${v.scope === id ? 'selected' : ''}>${l}</option>`).join('')}</select></div>
        <div class="field"><label for="m-reason">Reason</label><textarea id="m-reason" name="reason" rows="2" maxlength="500">${esc(v.reason || '')}</textarea></div>
        <div class="field"><label for="m-dur">Expected duration in minutes (optional)</label><input id="m-dur" name="duration" type="number" min="1" max="10080" value="${esc(v.duration || '')}"></div>
        <div class="field"><label for="m-roll">Rollback condition</label><textarea id="m-roll" name="rollback" rows="2" maxlength="500">${esc(v.rollback || '')}</textarea></div>` + actions('Review'));
    case 'end-maintenance': {
      const w = (data.windows || []).find(x => x.id === m.id);
      return wrap('End maintenance?', confirm([`Scope: <b>${esc(scopeLabel(w?.scope))}</b>`, `Started ${esc(fmtDateTime(w?.started_at))}`, 'Users of this scope return to normal service.'], 'end_maintenance', false) + actions('End maintenance', true));
    }
    case 'flag':
      if (m.step === 'confirm') return wrap('Create feature flag?', confirm([`Key: <code>${esc(v.key)}</code>`, `State: <b>${v.enabled ? 'On' : 'Off'}</b>`, `Description: ${esc(v.description || '—')}`], 'set_feature_flag', false) + actions('Create flag'));
      return wrap('New feature flag', `<div class="field"><label for="f-key">Key</label><input id="f-key" name="key" value="${esc(v.key || '')}" placeholder="vendor_new_planner" maxlength="80" autocomplete="off"><small class="hint">Lowercase letters, numbers, dot, dash and underscore.</small></div>
        <div class="field"><label for="f-desc">Description</label><input id="f-desc" name="description" value="${esc(v.description || '')}" maxlength="200"></div>
        <label class="check"><input type="checkbox" name="enabled" ${v.enabled ? 'checked' : ''}> Turn on now</label>` + actions('Review'));
    case 'toggle-flag': {
      const x = (data.flags || []).find(y => y.key === m.id);
      return wrap(`Turn ${x?.enabled ? 'off' : 'on'} this flag?`, confirm([`<code>${esc(m.id)}</code> goes from <b>${x?.enabled ? 'On' : 'Off'}</b> to <b>${x?.enabled ? 'Off' : 'On'}</b>.`, x?.description ? esc(x.description) : ''], 'set_feature_flag', false) + actions(x?.enabled ? 'Turn off' : 'Turn on', !!x?.enabled));
    }
    case 'announcement':
      if (m.step === 'confirm') return wrap('Publish announcement?', confirm([`<b>${esc(v.title)}</b>`, esc(v.body), `Severity: ${esc(human(v.severity))}${v.severity === 'critical' ? ' (emergency)' : ''}`, `From ${v.starts ? esc(fmtDateTime(new Date(v.starts).toISOString())) : 'now'}${v.ends ? ' until ' + esc(fmtDateTime(new Date(v.ends).toISOString())) : ', no end'}`], 'create_announcement', false) + actions('Publish', v.severity === 'critical'));
      return wrap('New announcement', `<div class="field"><label for="a-title">Title</label><input id="a-title" name="title" value="${esc(v.title || '')}" maxlength="120"></div>
        <div class="field"><label for="a-body">Message</label><textarea id="a-body" name="body" rows="3" maxlength="1000">${esc(v.body || '')}</textarea></div>
        <div class="field"><label for="a-sev">Severity</label><select id="a-sev" name="severity">${[['info', 'Info'], ['warning', 'Warning'], ['critical', 'Critical (emergency)']].map(([id, l]) => `<option value="${id}" ${v.severity === id ? 'selected' : ''}>${l}</option>`).join('')}</select></div>
        <div class="form-grid"><div class="field"><label for="a-start">Starts (optional)</label><input id="a-start" name="starts" type="datetime-local" value="${esc(v.starts || '')}"></div><div class="field"><label for="a-end">Ends (optional)</label><input id="a-end" name="ends" type="datetime-local" value="${esc(v.ends || '')}"></div></div>` + actions('Review'));
    case 'toggle-ann': {
      const a = (data.anns || []).find(x => x.id === m.id);
      return wrap(`${m.active ? 'Turn on' : 'Turn off'} announcement?`, confirm([`<b>${esc(a?.title)}</b>`, m.active ? 'It shows in client apps during its window.' : 'Client apps stop showing it.'], 'set_announcement_active', false) + actions(m.active ? 'Turn on' : 'Turn off', !m.active));
    }
    case 'broadcast': {
      const biz = (data.vendors || []).slice().sort((a, b) => String(a.name).localeCompare(String(b.name)));
      if (m.step === 'confirm') {
        const size = m.size === undefined ? '<span class="sub inline">Counting…</span>' : m.size === null ? '<span class="sub inline">Could not count</span>' : `<b>${num(m.size)}</b> account${m.size === 1 ? '' : 's'}`;
        return wrap('Send broadcast?', `<div class="preview-note"><div class="sub">Preview (as it appears in the notification centre)</div><div class="notif-preview"><b>${esc(v.title)}</b><span>${esc(v.body)}</span></div></div>`
          + confirm([`Audience: <b>${esc(audienceLabel(v.audience))}</b>${v.audience === 'business' ? ` · ${esc(biz.find(x => x.business_id === v.business)?.name || '')}` : ''}`, `Recipients now: ${size}`, `Reason: ${esc(v.reason)}`, 'Delivered in-app only (notification centre, banner and sound while the app is open). It cannot be recalled.'], 'broadcast_notification', true)
          + actions('Send broadcast', false).replace('type="submit"', `type="submit" ${m.size ? '' : 'disabled'}`));
      }
      return wrap('New broadcast', `<div class="field"><label for="b-title">Title</label><input id="b-title" name="title" value="${esc(v.title || '')}" maxlength="120"></div>
        <div class="field"><label for="b-body">Message</label><textarea id="b-body" name="body" rows="3" maxlength="1000">${esc(v.body || '')}</textarea></div>
        <div class="field"><label for="b-aud">Audience</label><select id="b-aud" name="audience">${AUDIENCES.map(([id, l]) => `<option value="${id}" ${(v.audience || 'vendors') === id ? 'selected' : ''}>${esc(l)}</option>`).join('')}</select></div>
        <div class="field"><label for="b-biz">Business (only for One business)</label><select id="b-biz" name="business"><option value="">Choose a business…</option>${biz.map(x => `<option value="${esc(x.business_id)}" ${v.business === x.business_id ? 'selected' : ''}>${esc(x.name)}</option>`).join('')}</select></div>
        <div class="field"><label for="b-reason">Reason (stored in the audit log)</label><textarea id="b-reason" name="reason" rows="2" maxlength="500">${esc(v.reason || '')}</textarea></div>` + actions('Review'));
    }
    case 'version':
      if (m.step === 'confirm') return wrap('Record release?', confirm([`App: <b>${esc(APPS.find(a => a[0] === v.app)?.[1])}</b>`, `Version: <b>${esc(v.version)}</b>`, `Min supported: ${esc(v.min || '—')}`, `Notes: ${esc(v.notes || '—')}`], 'record_app_version', false) + actions('Record release'));
      return wrap('Record release', `<div class="field"><label for="v-app">App</label><select id="v-app" name="app">${APPS.map(([id, l]) => `<option value="${id}" ${v.app === id ? 'selected' : ''}>${l}</option>`).join('')}</select></div>
        <div class="form-grid"><div class="field"><label for="v-ver">Version</label><input id="v-ver" name="version" value="${esc(v.version || '')}" placeholder="1.4.0" maxlength="40"></div><div class="field"><label for="v-min">Min supported (optional)</label><input id="v-min" name="min" value="${esc(v.min || '')}" placeholder="1.2.0" maxlength="40"></div></div>
        <div class="field"><label for="v-notes">Notes (optional)</label><textarea id="v-notes" name="notes" rows="2" maxlength="500">${esc(v.notes || '')}</textarea></div>` + actions('Review'));
    case 'subscription': {
      const s = (data.subs || []).find(x => x.business_id === m.id) || {};
      if (m.step === 'confirm') return wrap('Change subscription?', confirm([`Business: <b>${esc(s.business_name)}</b>`, `Plan: ${esc(human(s.plan_key || 'not set'))} → <b>${esc(human(v.plan))}</b>`, `Status: ${esc(human(s.status || 'not set'))} → <b>${esc(human(v.status))}</b>`, `MRR: ${esc(rm(s.mrr_cents))} → <b>${esc(v.mrr === '' ? '—' : rm(Math.round(Number(v.mrr) * 100)))}</b>`, `Trial ends: ${esc(v.trial ? fmtDate(new Date(`${v.trial}T12:00:00+08:00`).toISOString()) : '—')}`, v.status === 'suspended' ? '<b>Suspended</b> is recorded here only; it does not block the business in Vendor.' : ''], 'set_subscription', false) + actions('Save subscription', ['suspended', 'cancelled'].includes(v.status)));
      const cur = { plan: v.plan ?? s.plan_key ?? 'trial', status: v.status ?? s.status ?? 'trial', mrr: v.mrr ?? (s.mrr_cents != null ? (s.mrr_cents / 100).toFixed(2) : ''), trial: v.trial ?? (s.trial_ends_at ? s.trial_ends_at.slice(0, 10) : '') };
      return wrap(`Subscription · ${s.business_name || ''}`, `<p class="sub">Recorded by hand; there is no payment gateway.</p>
        <div class="form-grid"><div class="field"><label for="s-plan">Plan</label><select id="s-plan" name="plan">${['trial', 'free', 'grow', 'operate'].map(p => `<option value="${p}" ${cur.plan === p ? 'selected' : ''}>${human(p)}</option>`).join('')}</select></div>
        <div class="field"><label for="s-status">Status</label><select id="s-status" name="status">${SUB_STATUSES.map(p => `<option value="${p}" ${cur.status === p ? 'selected' : ''}>${human(p)}</option>`).join('')}</select></div>
        <div class="field"><label for="s-mrr">MRR in RM (optional)</label><input id="s-mrr" name="mrr" type="number" min="0" step="0.01" value="${esc(cur.mrr)}"></div>
        <div class="field"><label for="s-trial">Trial ends (optional)</label><input id="s-trial" name="trial" type="date" value="${esc(cur.trial)}"></div></div>` + actions('Review'));
    }
  }
  return '';
}
const DIRECT = new Set(['end-maintenance', 'toggle-flag', 'toggle-ann']); // confirm-only actions
const openModal = (type, extra = {}) => { state.modal = { type, step: DIRECT.has(type) ? 'confirm' : 'form', values: {}, ...extra }; state.menu = null; render(); };
function readForm(form) {
  const o = {};
  new FormData(form).forEach((val, k) => { o[k] = typeof val === 'string' ? val.trim() : val; });
  form.querySelectorAll('input[type=checkbox]').forEach(c => { o[c.name] = c.checked; });
  return o;
}
const SEMVER = /^\d+(\.\d+){0,3}([-+][\w.]+)?$/;
function validate(type, v) {
  switch (type) {
    case 'maintenance':
      if (!v.reason) return 'Reason is required.';
      if (!v.rollback) return 'Rollback condition is required.';
      if (v.duration && (!/^\d+$/.test(v.duration) || Number(v.duration) < 1)) return 'Duration must be a whole number of minutes.';
      return '';
    case 'flag':
      if (!/^[a-z0-9][a-z0-9_.-]{1,79}$/.test(v.key || '')) return 'Use 2–80 lowercase letters, numbers, dot, dash or underscore.';
      if ((data.flags || []).some(x => x.key === v.key)) return 'A flag with this key already exists. Turn it on or off from the list instead.';
      return '';
    case 'announcement':
      if (!v.title) return 'Title is required.';
      if (!v.body) return 'Message is required.';
      if (v.starts && v.ends && new Date(v.ends) <= new Date(v.starts)) return 'End must be after start.';
      if (v.ends && new Date(v.ends) <= Date.now()) return 'End must be in the future.';
      return '';
    case 'version':
      if (!SEMVER.test(v.version || '')) return 'Version must look like 1.4.0.';
      if (v.min && !SEMVER.test(v.min)) return 'Min supported must look like 1.2.0.';
      return '';
    case 'broadcast':
      if (!v.title) return 'Title is required.';
      if (!v.body) return 'Message is required.';
      if (!AUDIENCES.some(a => a[0] === v.audience)) return 'Choose an audience.';
      if (v.audience === 'business' && !v.business) return 'Choose the business.';
      if (!v.reason) return 'Reason is required.';
      return '';
    case 'subscription':
      if (v.mrr !== '' && (isNaN(Number(v.mrr)) || Number(v.mrr) < 0)) return 'MRR must be zero or a positive amount.';
      return '';
  }
  return '';
}
async function submitModal(form) {
  const m = state.modal;
  if (!m || m.busy) return;
  if (m.step !== 'confirm') {
    const v = readForm(form);
    m.values = v;
    m.error = validate(m.type, v);
    if (!m.error) m.step = 'confirm';
    // The confirmation shows the exact audience the server will target now.
    if (!m.error && m.type === 'broadcast') {
      delete m.size;
      F.broadcastAudienceSize(v.audience, v.audience === 'business' ? v.business : null)
        .then(n => { if (state.modal === m) { m.size = Number(n) || 0; if (!m.size) m.error = 'This audience has no accounts to notify.'; render(); } })
        .catch(e => { if (state.modal === m) { m.size = null; m.error = e.message || 'Could not count the audience.'; handleAuthError(e); render(); } });
    }
    return render();
  }
  m.busy = true; m.error = ''; render();
  const v = m.values;
  try {
    let done = '';
    switch (m.type) {
      case 'maintenance': await F.startMaintenance(v.scope, v.reason, v.duration ? Number(v.duration) : null, v.rollback); invalidate('windows'); done = 'Maintenance started'; break;
      case 'end-maintenance': await F.endMaintenance(m.id); invalidate('windows'); done = 'Maintenance ended'; break;
      case 'flag': await F.setFeatureFlag(v.key, !!v.enabled, v.description || null); invalidate('flags'); done = `Flag ${v.key} created`; break;
      case 'toggle-flag': { const x = data.flags.find(y => y.key === m.id); await F.setFeatureFlag(m.id, !x.enabled, null); invalidate('flags'); done = `Flag ${m.id} turned ${x.enabled ? 'off' : 'on'}`; break; }
      case 'announcement': await F.createAnnouncement(v.title, v.body, v.severity, v.starts ? new Date(v.starts).toISOString() : null, v.ends ? new Date(v.ends).toISOString() : null); invalidate('anns', 'activeAnns'); done = 'Announcement published'; break;
      case 'toggle-ann': await F.setAnnouncementActive(m.id, !!m.active); invalidate('anns', 'activeAnns'); done = m.active ? 'Announcement turned on' : 'Announcement turned off'; break;
      case 'broadcast': { const r = await F.broadcastNotification(v.title, v.body, v.audience, v.audience === 'business' ? v.business : null, v.reason); invalidate('broadcasts'); done = `Broadcast sent to ${num(r?.recipient_count ?? 0)} account${r?.recipient_count === 1 ? '' : 's'}`; break; }
      case 'version': await F.recordAppVersion(v.app, v.version, v.min || null, v.notes || null); invalidate('versions'); done = 'Release recorded'; break;
      case 'subscription': await F.setSubscription(m.id, v.plan, v.status, v.mrr === '' ? null : Math.round(Number(v.mrr) * 100), v.trial ? new Date(`${v.trial}T23:59:59+08:00`).toISOString() : null); invalidate('subs'); done = 'Subscription saved'; break;
    }
    invalidate('audit');
    state.modal = null;
    ensure(NEEDS[state.route]);
    ensure(['windows', 'activeAnns']);
    toast(done);
    render(); // close the modal even when no reloaded key belongs to this page
  } catch (e) {
    m.busy = false; m.error = e.message || 'The server refused this action.';
    handleAuthError(e);
    render();
  }
}

// ------------------------------------------------------------------ shell
function banner() {
  const live = (data.windows || []).filter(w => !w.ended_at);
  const crit = (data.activeAnns || []).filter(a => a.severity === 'critical');
  if (!live.length && !crit.length) return '';
  return `<div class="banner" role="status">${live.length ? `<b>Maintenance active</b> · ${esc(live.map(w => scopeLabel(w.scope)).join(', '))} <button class="link light" data-go="controls" data-go-tab="maintenance">Manage</button>` : ''}${crit.length ? `${live.length ? ' &nbsp;·&nbsp; ' : ''}<b>Critical announcement live</b> · ${esc(crit[0].title)} <button class="link light" data-go="controls" data-go-tab="announcements">Manage</button>` : ''}</div>`;
}
function menus() {
  if (state.menu === 'notify') {
    const live = (data.windows || []).filter(w => !w.ended_at), anns = data.activeAnns || [], stuck = data.stuck || [];
    const items = [
      ...live.map(w => [`Maintenance active: ${scopeLabel(w.scope)}`, 'controls', 'maintenance']),
      ...anns.map(a => [`${human(a.severity)} announcement live: ${a.title}`, 'controls', 'announcements']),
      ...(stuck.length ? [[`${stuck.length} rider${stuck.length > 1 ? 's' : ''} not reporting location`, 'riders', 'stuck']] : []),
    ];
    const loading = ['windows', 'activeAnns', 'stuck'].some(k => pending[k]);
    return `<div class="pop pop-notify" role="menu">${items.length ? items.map(([t, r, tab]) => `<button role="menuitem" data-go="${r}" data-go-tab="${tab}">${esc(t)}</button>`).join('') : `<p class="sub" style="padding:10px">${loading ? 'Checking…' : 'Nothing needs attention.'}</p>`}</div>`;
  }
  if (state.menu === 'admin') return `<div class="pop pop-admin" role="menu"><div style="padding:10px"><b>${esc(me.user?.email || '')}</b><span class="sub">Platform admin</span></div><button role="menuitem" data-go="settings">Account & access</button><button role="menuitem" data-signout>Sign out</button></div>`;
  if (state.menu === 'search' && state.gq.trim().length >= 2) {
    const q = state.gq.trim();
    const hits = [
      ...(data.vendors || []).filter(v => match(q, v.name, v.email, v.phone)).slice(0, 5).map(v => ['Vendor', v.name, `vendor:${v.business_id}`, 'vendors']),
      ...(data.riders || []).filter(r => match(q, r.name, r.phone, r.vehicle_plate)).slice(0, 5).map(r => ['Rider', `${r.name} · ${r.business_name}`, `rider:${r.rider_id}`, 'riders']),
      ...(data.ops || []).filter(o => match(q, o.public_ref, o.rider_name)).slice(0, 5).map(o => ['Delivery', `${o.public_ref || shortId(o.order_id)} · ${o.business_name}`, `order:${o.order_id}`, 'operations']),
    ];
    const loading = ['vendors', 'riders', 'ops'].some(k => pending[k]);
    return `<div class="pop pop-search" role="listbox">${hits.length ? hits.map(([k, label, open, r]) => `<button role="option" data-go="${r}" data-open="${esc(open)}"><span class="chip blue">${k}</span> ${esc(label)}</button>`).join('') : `<p class="sub" style="padding:10px">${loading ? 'Searching…' : 'No vendor, rider or delivery matches.'}</p>`}</div>`;
  }
  return '';
}
function shell() {
  const hasAlerts = (data.windows || []).some(w => !w.ended_at) || (data.activeAnns || []).length || (data.stuck || []).length;
  const initial = esc((me.user?.email || 'A')[0].toUpperCase());
  return `<div class="shell"><aside class="sidebar" id="sidebar"><div class="brand">Cefflo</div><nav class="nav" aria-label="FOUNDR">${NAV.map(([r, l], i) => `${i === 9 ? '<div class="nav-sep"></div>' : ''}<button class="nav-btn ${state.route === r ? 'active' : ''}" data-route="${r}" title="${l}" aria-label="${l}" ${state.route === r ? 'aria-current="page"' : ''}>${svg(r)}<span>${l}</span></button>`).join('')}</nav><div class="profile"><div class="avatar">${initial}</div><div><b>${esc((me.user?.email || '').split('@')[0])}</b><span>Platform admin</span></div></div></aside><div class="nav-scrim" id="nav-scrim"></div>
  <main class="workspace"><header class="topbar"><button class="mobile-menu" data-menu aria-label="Open menu">${I.menu}</button>
    <div class="global-search"><span class="search-icon">${I.search}</span><input data-gsearch placeholder="Search vendor, rider or delivery…" value="${esc(state.gq)}" aria-label="Search vendors, riders and deliveries" autocomplete="off">${state.menu === 'search' ? menus() : ''}</div>
    <div class="top-spacer"></div>
    <button class="date-control" data-refresh title="Reload this page’s data from the server">${I.refresh}<span>${updatedAt ? 'Updated ' + esc(updatedAt.toLocaleTimeString('en-MY', { hour: 'numeric', minute: '2-digit', timeZone: TZ })) : 'Refresh'}</span></button>
    <div class="menu-anchor"><button class="icon-control" data-notify aria-label="Alerts" aria-expanded="${state.menu === 'notify'}">${I.bell}${hasAlerts ? '<i class="notif-dot"></i>' : ''}</button>${state.menu === 'notify' ? menus() : ''}</div>
    <div class="menu-anchor"><button class="admin-control" data-admin aria-expanded="${state.menu === 'admin'}"><span class="avatar">${initial}</span> Admin ${I.down}</button>${state.menu === 'admin' ? menus() : ''}</div></header>
    ${banner()}
    <section class="content ${state.drawer ? 'with-drawer' : ''}" id="content">${PAGES[state.route]()}</section></main>${drawer()}${modal()}</div>`;
}

// ------------------------------------------------------------------ render + events
let authScreen = true;
function render() {
  if (authScreen) return;
  const a = document.activeElement;
  const focus = a?.matches?.('[data-search],[data-gsearch]') ? { sel: a.matches('[data-gsearch]') ? '[data-gsearch]' : '[data-search]', pos: a.selectionStart } : null;
  const scrollY = window.scrollY;
  root.innerHTML = shell();
  window.scrollTo(0, scrollY);
  if (focus) { const el = root.querySelector(focus.sel); if (el) { el.focus(); try { el.setSelectionRange(focus.pos, focus.pos); } catch { /* not a text input */ } } }
}
function go(r, tab = '', open = '') {
  state.route = ROUTES.includes(r) ? r : 'overview';
  state.tab = tab; state.query = ''; state.filters = {}; state.page = 1; state.menu = null; state.drawer = null; state.gq = '';
  if (open) { const [type, ...id] = open.split(':'); state.drawer = { type, id: id.join(':') }; }
  if (location.hash.slice(1) !== state.route) history.pushState(null, '', `#${state.route}`);
  document.getElementById('sidebar')?.classList.remove('open');
  document.getElementById('nav-scrim')?.classList.remove('show');
  ensure(NEEDS[state.route]);
  if (state.drawer?.type === 'vendor') ensure(['vendors', 'subs']);
  if (state.drawer?.type === 'rider') ensure(['riders', 'stuck']);
  render();
  window.scrollTo(0, 0);
}
let toastTimer;
function toast(text) {
  const t = document.getElementById('toast');
  t.textContent = text; t.classList.add('show');
  clearTimeout(toastTimer); toastTimer = setTimeout(() => t.classList.remove('show'), 2600);
}
function exportCsv() {
  const rows = auditRows();
  const cols = ['id', 'created_at', 'admin_user_id', 'action', 'target_type', 'target_id', 'reason', 'metadata'];
  const cell = x => `"${String(x ?? '').replace(/"/g, '""')}"`;
  const csv = [cols.join(','), ...rows.map(r => cols.map(c => cell(c === 'metadata' ? JSON.stringify(r.metadata || {}) : r[c])).join(','))].join('\n');
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv' }));
  a.download = `foundr-audit-${new Date().toISOString().slice(0, 10)}.csv`;
  document.body.append(a); a.click(); a.remove();
  setTimeout(() => URL.revokeObjectURL(a.href), 1000);
  toast(`Exported ${rows.length} entries`);
}

root.addEventListener('click', e => {
  if (authScreen) return;
  const t = e.target;
  const el = s => t.closest(s);
  // Clicking anywhere outside an open menu closes it (then the click proceeds).
  const closedMenu = state.menu && !el('.pop') && !el('[data-notify],[data-admin],[data-gsearch]');
  if (closedMenu) state.menu = null;
  if (el('[data-route]')) return go(el('[data-route]').dataset.route);
  if (el('[data-go]')) { const b = el('[data-go]'); return go(b.dataset.go, b.dataset.goTab || '', b.dataset.open || ''); }
  if (el('[data-open]')) { const [type, ...id] = el('[data-open]').dataset.open.split(':'); state.drawer = { type, id: id.join(':') }; if (type === 'vendor') ensure(['vendors', 'subs']); return render(); }
  if (el('[data-tab]')) { state.tab = el('[data-tab]').dataset.tab; state.page = 1; if (state.route === 'controls') { state.query = ''; state.filters = {}; } if (state.route === 'riders' && state.tab === 'stuck') ensure(['stuck']); return render(); }
  if (el('[data-page]')) { const b = el('[data-page]'); if (b.disabled) return; state.page = Number(b.dataset.page); render(); return document.querySelector('.tabs, .toolbar')?.scrollIntoView({ block: 'nearest' }); }
  if (el('[data-select]')) { const r = el('[data-select]'); state.drawer = { type: r.dataset.select, id: r.dataset.id }; return render(); }
  if (el('[data-close]')) { state.drawer = null; return render(); }
  if (el('[data-retry]')) { el('[data-retry]').dataset.retry.split(',').forEach(k => { if (errors[k]) load(k, true); }); return render(); }
  if (el('[data-vendor-retry]')) { loadVendorDetail(el('[data-vendor-retry]').dataset.vendorRetry, true); return render(); }
  if (el('[data-refresh]')) { const keys = NEEDS[state.route]; Object.keys(vendorDetail).forEach(k => delete vendorDetail[k]); if (state.route === 'system') health = null; ensure(keys, true); ensure(['windows', 'activeAnns'], true); return render(); }
  if (el('[data-health]')) return runHealth();
  if (el('[data-export]')) return exportCsv();
  if (el('[data-notify]')) { state.menu = state.menu === 'notify' ? null : 'notify'; ensure(['windows', 'activeAnns', 'stuck']); return render(); }
  if (el('[data-admin]')) { state.menu = state.menu === 'admin' ? null : 'admin'; return render(); }
  if (el('[data-signout]')) return signOut();
  if (el('[data-menu]')) { document.getElementById('sidebar').classList.add('open'); document.getElementById('nav-scrim').classList.add('show'); return; }
  if (el('#nav-scrim')) { document.getElementById('sidebar').classList.remove('open'); document.getElementById('nav-scrim').classList.remove('show'); return; }
  if (el('[data-modal]')) { const b = el('[data-modal]'); if (b.disabled) return; return openModal(b.dataset.modal, b.dataset.id ? { id: b.dataset.id } : {}); }
  if (el('[data-end]')) return openModal('end-maintenance', { id: el('[data-end]').dataset.end });
  if (el('[data-flag]')) return openModal('toggle-flag', { id: el('[data-flag]').dataset.flag });
  if (el('[data-ann]')) { const b = el('[data-ann]'); return openModal('toggle-ann', { id: b.dataset.ann, active: b.dataset.active === '1' }); }
  if (el('[data-modal-close]')) { const m = state.modal; if (!m || m.busy) return; if (m.step === 'confirm' && !DIRECT.has(m.type)) { m.step = 'form'; m.error = ''; } else state.modal = null; return render(); }
  if (t.matches('[data-backdrop]')) { if (!state.modal?.busy) state.modal = null; return render(); }
  // Never re-render on an unhandled click: it would replace a form before its
  // submit event fires. Only repaint when a menu actually closed.
  if (closedMenu) render();
});
document.addEventListener('keydown', e => {
  if (authScreen) return;
  if (e.key === 'Enter' && e.target.matches('tr[data-select]')) { state.drawer = { type: e.target.dataset.select, id: e.target.dataset.id }; render(); }
  if (e.key === 'Enter' && e.target.matches('[data-gsearch]')) { e.preventDefault(); root.querySelector('.pop-search [data-go]')?.click(); }
  if (e.key === 'Escape') { if (state.modal && !state.modal.busy) state.modal = null; else if (state.menu) state.menu = null; else if (state.drawer) state.drawer = null; else return; render(); }
});
root.addEventListener('input', e => {
  if (authScreen) return;
  if (e.target.matches('[data-search]')) { state.query = e.target.value; state.page = 1; render(); }
  if (e.target.matches('[data-gsearch]')) { state.gq = e.target.value; state.menu = 'search'; if (state.gq.trim().length >= 2) ensure(['vendors', 'riders', 'ops']); render(); }
});
root.addEventListener('change', e => {
  if (authScreen) return;
  if (e.target.matches('[data-filter]')) { state.filters[e.target.dataset.filter] = e.target.value; state.page = 1; render(); }
  if (e.target.matches('[data-stuck]')) { state.stuckMinutes = Number(e.target.value); state.page = 1; load('stuck', true); render(); }
});
root.addEventListener('submit', e => { if (!authScreen && e.target.matches('[data-form]')) { e.preventDefault(); submitModal(e.target); } });
window.addEventListener('popstate', () => { if (!authScreen) { const r = route0(); if (r !== state.route) go(r); } });

// ------------------------------------------------------------------ auth gate
// FOUNDR opens only for a signed-in identity on the platform_admins
// allowlist (is_platform_admin()). The server re-checks the same condition
// on every admin RPC, so this gate is the UX of the boundary, not the
// boundary itself.
function authFrame(inner) {
  authScreen = true;
  root.innerHTML = `<div class="auth-screen"><div class="auth-box"><div class="auth-brand">Cefflo <span>FOUNDR</span></div>${inner}</div></div>`;
}
function renderSignIn(message = '') {
  authFrame(`<form data-signin novalidate><h1>Sign in</h1><p class="sub">Platform admins only. There is no sign-up.</p>
    ${message ? `<div class="auth-msg" role="status">${esc(message)}</div>` : ''}
    <div class="field"><label for="em">Email</label><input id="em" type="email" autocomplete="username" required></div>
    <div class="field"><label for="pw">Password</label><input id="pw" type="password" autocomplete="current-password" required></div>
    <div class="field-err" data-err hidden role="alert"></div>
    <button class="btn primary" type="submit" style="width:100%">Sign in</button>
    <button class="link" type="button" data-forgot style="justify-self:center">Forgot password?</button></form>`);
  const form = root.querySelector('[data-signin]'), err = form.querySelector('[data-err]');
  form.querySelector('#em').focus();
  form.querySelector('[data-forgot]').addEventListener('click', () => renderForgot(form.querySelector('#em').value.trim()));
  form.addEventListener('submit', async e => {
    e.preventDefault();
    const email = form.querySelector('#em').value.trim(), pw = form.querySelector('#pw').value;
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) { err.textContent = 'Enter a valid email address.'; err.hidden = false; return; }
    if (!pw) { err.textContent = 'Enter your password.'; err.hidden = false; return; }
    const btn = form.querySelector('[type=submit]');
    btn.disabled = true; btn.textContent = 'Signing in…'; err.hidden = true;
    try { await F.signIn(email, pw); await boot(); } catch (ex) {
      err.textContent = /invalid/i.test(ex.message) ? 'Incorrect email or password.' : ex.message; err.hidden = false;
      btn.disabled = false; btn.textContent = 'Sign in';
    }
  });
}
const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
function renderForgot(prefill = '') {
  authFrame(`<form data-forgot-form novalidate><h1>Reset password</h1><p class="sub">We'll email you a link to set a new password.</p>
    <div class="field"><label for="em">Email</label><input id="em" type="email" autocomplete="username" required value="${esc(prefill)}"></div>
    <div class="field-err" data-err hidden role="alert"></div>
    <button class="btn primary" type="submit" style="width:100%">Send reset link</button>
    <button class="link" type="button" data-back style="justify-self:center">Back to sign in</button></form>`);
  const form = root.querySelector('[data-forgot-form]'), err = form.querySelector('[data-err]');
  form.querySelector('#em').focus();
  form.querySelector('[data-back]').addEventListener('click', () => renderSignIn());
  form.addEventListener('submit', async e => {
    e.preventDefault();
    const email = form.querySelector('#em').value.trim();
    if (!EMAIL_RE.test(email)) { err.textContent = 'Enter a valid email address.'; err.hidden = false; return; }
    const btn = form.querySelector('[type=submit]');
    btn.disabled = true; btn.textContent = 'Sending…'; err.hidden = true;
    try {
      await F.recover(email);
      renderSignIn(`If ${email} has an account, a reset link is on its way. Open it on this device.`);
    } catch (ex) {
      err.textContent = ex.status === 429 ? 'Too many emails sent. Wait a while and try again.' : ex.message; err.hidden = false;
      btn.disabled = false; btn.textContent = 'Send reset link';
    }
  });
}
// After a recovery link: the recovery session is stored; set a new password
// before the admin gate runs.
function renderSetPassword() {
  authFrame(`<form data-setpw novalidate><h1>Set new password</h1><p class="sub">Choose a new password for your FOUNDR sign-in.</p>
    <div class="field"><label for="p1">New password</label><input id="p1" type="password" autocomplete="new-password" required></div>
    <div class="field"><label for="p2">Confirm password</label><input id="p2" type="password" autocomplete="new-password" required></div>
    <div class="field-err" data-err hidden role="alert"></div>
    <button class="btn primary" type="submit" style="width:100%">Save password</button></form>`);
  const form = root.querySelector('[data-setpw]'), err = form.querySelector('[data-err]');
  form.querySelector('#p1').focus();
  form.addEventListener('submit', async e => {
    e.preventDefault();
    const p1 = form.querySelector('#p1').value, p2 = form.querySelector('#p2').value;
    if (p1.length < 8) { err.textContent = 'Use at least 8 characters.'; err.hidden = false; return; }
    if (p1 !== p2) { err.textContent = 'Passwords do not match.'; err.hidden = false; return; }
    const btn = form.querySelector('[type=submit]');
    btn.disabled = true; btn.textContent = 'Saving…'; err.hidden = true;
    try { await F.updatePassword(p1); await boot(); } catch (ex) {
      if (ex.status === 401) { await F.signOut().catch(() => {}); return renderSignIn('That reset link has expired. Request a new one.'); }
      err.textContent = ex.message; err.hidden = false;
      btn.disabled = false; btn.textContent = 'Save password';
    }
  });
}
function renderDenied(email) {
  authFrame(`<h1>Access denied</h1><p class="sub">${esc(email || 'This account')} is signed in but is not a platform admin. Access is granted directly in the database by an existing admin.</p><button class="btn primary" data-signout-denied style="width:100%;margin-top:14px">Sign out</button>`);
  root.querySelector('[data-signout-denied]').addEventListener('click', signOut);
}
function renderBootError(e) {
  authFrame(`<h1>Could not reach Cefflo</h1><p class="sub">${esc(e.message)}</p><button class="btn primary" data-boot-retry style="width:100%;margin-top:14px">Try again</button>`);
  root.querySelector('[data-boot-retry]').addEventListener('click', boot);
}
let bouncing = false;
function handleAuthError(e) {
  if (bouncing || authScreen) return;
  const msg = String(e?.message || '');
  if (e?.status === 401 || /JWT|session expired/i.test(msg)) {
    bouncing = true;
    F.signOut().catch(() => {}).finally(() => { bouncing = false; reset(); renderSignIn('Your session ended. Sign in again.'); });
  } else if (/forbidden/i.test(msg)) {
    // The allowlist changed under an open session: the server now refuses.
    renderDenied(me.user?.email);
  }
}
function reset() {
  [data, errors, vendorDetail].forEach(o => Object.keys(o).forEach(k => delete o[k]));
  me = { user: null }; health = null; updatedAt = null;
  Object.assign(state, { modal: null, drawer: null, menu: null, gq: '', query: '', filters: {}, page: 1 });
}
async function signOut() { await F.signOut().catch(() => {}); reset(); renderSignIn(); }
async function boot() {
  if (!F.session()?.access_token) return renderSignIn();
  authFrame('<div class="skel"></div><div class="skel"></div>');
  try {
    me.user = await F.currentUser();
    if (await F.isPlatformAdmin() !== true) return renderDenied(me.user?.email);
  } catch (e) {
    if (e?.status === 401 || /JWT|session/i.test(String(e?.message))) { await F.signOut().catch(() => {}); return renderSignIn('Your session ended. Sign in again.'); }
    return renderBootError(e);
  }
  authScreen = false;
  ensure(['admins', 'windows', 'activeAnns', 'stuck']);
  ensure(NEEDS[state.route]);
  render();
}

// An emailed recovery link lands here first: open Set New Password with its
// session, or explain a link that has expired or was already used.
function start() {
  const linkError = F.consumeAuthError();
  if (linkError) return renderSignIn(linkError.code === 'otp_expired' ? 'That reset link has expired or was already used. Request a new one.' : (linkError.description || 'That link could not be used.'));
  if (F.consumeAuthFragment() === 'recovery') return renderSetPassword();
  return boot();
}
start();
if ('serviceWorker' in navigator) window.addEventListener('load', () => navigator.serviceWorker.register('./sw.js').catch(() => {}));
})();
