// Demo mode: explore the Vendor Web App with sample data, without signing in.
// Never available in Production (the runtime config decides). Nothing is sent
// to the backend while it is on: reads come from the sample business below,
// and every change is refused with a clear "not saved" message.
const KEY = 'cefflo.vendorweb.demo';
const cfg = window.CEFFLO_CONFIG || {};

export const demoAllowed = () => cfg.environment && cfg.environment !== 'production';
export function isDemo() {
  if (!demoAllowed()) return false;
  try { return sessionStorage.getItem(KEY) === '1'; } catch { return false; }
}
export function enterDemo() { try { sessionStorage.setItem(KEY, '1'); } catch { /* ignore */ } }
export function exitDemo() { try { sessionStorage.removeItem(KEY); } catch { /* ignore */ } }

export class DemoReadOnlyError extends Error {}

// ---------------------------------------------------------------- sample data
const BIZ = 'demo-biz-kopikita';
export const DEMO_SESSION = Object.freeze({ access_token: 'demo', token_type: 'bearer' });
const USER = { id: 'demo-owner', email: 'yusuf@kopikita.my', user_metadata: { full_name: 'Yusuf Sazali' } };

function todayLocal() {
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kuala_Lumpur', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date());
}
// Today at hh:mm Malaysia time, as an ISO timestamp.
const at = (h, m) => new Date(`${todayLocal()}T${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:00+08:00`).toISOString();
const minsAgo = n => new Date(Date.now() - n * 60000).toISOString();

const zones = [
  ['z-bangsar', 'Bangsar', 'active'], ['z-montkiara', 'Mont Kiara', 'active'], ['z-ttdi', 'TTDI', 'active'],
  ['z-damansara', 'Damansara', 'active'], ['z-pj', 'Petaling Jaya', 'active'], ['z-klang', 'Klang', 'inactive'],
].map(([id, name, status]) => ({ id, name, status, created_at: '2026-08-02T02:00:00Z' }));

const riders = [
  ['r-ahmad', 'Ahmad Razi', '+60 12-345 6789', 'VFY 7281', 'motorcycle', 'active', 'online'],
  ['r-siti', 'Siti Aminah', '+60 13-221 4410', 'BMD 4120', 'car', 'active', 'online'],
  ['r-jason', 'Jason Lim', '+60 17-889 0213', 'VDT 3302', 'motorcycle', 'active', 'online'],
  ['r-nur', 'Nur Iman', '+60 11-5520 7781', 'VFE 9812', 'motorcycle', 'active', 'offline'],
  ['r-farid', 'Farid Hakim', '+60 19-330 1276', 'WXA 5521', 'van', 'pending', 'offline'],
].map(([id, name, phone, vehicle_plate, vehicle_type, status, availability_status], i) => ({
  id, name, phone, vehicle_plate, vehicle_type, status, availability_status, max_active_orders: 12,
  created_at: `2026-0${7 + (i % 2)}-1${i}T02:00:00Z`,
}));

const session = { id: 's-morning', name: 'Morning run', delivery_date: todayLocal(), status: 'active', pickup_at: at(10, 0), sorting_started_at: at(9, 30), created_at: at(9, 0) };

// [ref, customer, phone, address, zone, status, rider, prep, approved, items, createdHH:MM, issue/location]
const O = [
  ['CF-1001', 'Nadia Rahman', '+60 12-771 2034', 'No. 8, Jalan Telawi 3, Bangsar', 'z-bangsar', 'delivered', 'r-ahmad', null, true, [['Chocolate Cake 6"', 1], ['Matcha Latte', 2]], '08:12'],
  ['CF-1002', 'Firdaus Cafe', '+60 3-2201 8890', 'Lot 2, Jalan Kiara 1, Mont Kiara', 'z-montkiara', 'out_for_delivery', 'r-siti', null, true, [['Croissant', 12]], '08:20'],
  ['CF-1003', 'Amy Lee', '', 'Jalan Tun Mohd Fuad 2, TTDI', 'z-ttdi', 'created', null, null, true, [['Blueberry Tart', 4]], '08:31'],
  ['CF-1004', 'Hafiz Omar', '+60 16-402 1187', '12, Jalan SS2/24, Petaling Jaya', 'z-pj', 'picked_up', 'r-jason', null, true, [['Cookies Box', 2]], '08:40'],
  ['CF-1005', 'Mei Ling', '+60 12-990 4471', 'Jalan Bangsar Utama 1, Bangsar', 'z-bangsar', 'delivered', 'r-ahmad', null, true, [['Chocolate Cake 6"', 1]], '08:44'],
  ['CF-1006', 'Brew & Bites', '+60 3-7722 1045', 'Jalan Kiara 3, Mont Kiara', 'z-montkiara', 'out_for_delivery', 'r-siti', null, true, [['Croissant', 6], ['Matcha Latte', 6]], '08:52'],
  ['CF-1007', 'Aisyah Rahman', '+60 13-455 0921', 'Jalan 2/27A, Damansara', 'z-damansara', 'issue', 'r-jason', null, true, [['Hamper Raya', 1]], '09:01'],
  ['CF-1008', 'Brew & Bites', '+60 3-7722 1045', 'Jalan Kiara 3, Mont Kiara', 'z-montkiara', 'ready_for_pickup', 'r-siti', 'packed', true, [['Cookies Box', 3]], '09:10'],
  ['CF-1009', 'Kumaravelu', '+60 17-203 5518', 'Jalan Usahawan 4, Setapak', null, 'created', null, null, false, [['Chocolate Cake 8"', 1]], '09:18', 'failed'],
  ['CF-1010', 'Siti Norazimah', '+60 19-661 2380', 'Jalan Genting Kelang, TTDI', 'z-ttdi', 'created', null, 'preparing', true, [['Matcha Latte', 4]], '09:26'],
  ['CF-1011', 'Daniel Tan', '+60 12-310 7765', 'Jalan Taman Ibu Kota, Damansara', 'z-damansara', 'delivered', 'r-nur', null, true, [['Blueberry Tart', 2]], '07:58'],
  ['CF-1012', 'Lee Chin Wei', '+60 16-778 2201', 'Jalan Setapak Indah, Petaling Jaya', 'z-pj', 'arrived', 'r-jason', null, true, [['Croissant', 4]], '09:34'],
  ['CF-1013', 'Farah Ibrahim', '+60 11-2203 5519', 'Jalan Danau Kota 1, Bangsar', 'z-bangsar', 'ready_for_pickup', 'r-ahmad', 'sorted', true, [['Cookies Box', 1]], '09:41'],
  ['CF-1014', 'Rizal Hamdan', '+60 13-880 1102', 'Jalan Tun Razak, TTDI', 'z-ttdi', 'created', null, null, false, [['Hamper Raya', 2]], '09:55'],
];

const orders = O.map(([ref, customer_name, customer_phone, delivery_address, zone_id, delivery_status, assigned_rider_id, prep, approved, items, created, location_status], i) => {
  const [h, m] = created.split(':').map(Number);
  const created_at = at(h, m);
  return {
    id: `o-${ref}`, public_ref: ref, order_number: `#${ref}`, customer_name, customer_phone, delivery_address,
    latitude: null, longitude: null, notes: i % 4 === 0 ? 'Leave at reception. Call upon arrival.' : null,
    items: items.map(([name, quantity]) => ({ name, quantity })), delivery_status, assigned_rider_id, zone_id,
    delivery_session_id: assigned_rider_id ? session.id : null, estimated_arrival_at: null,
    completed_at: delivery_status === 'delivered' ? at(h + 2, (m + 10) % 60) : null,
    created_at, updated_at: delivery_status === 'created' ? created_at : minsAgo(5 + i * 3),
    approved_at: approved ? at(h, (m + 4) % 60) : null, location_status: location_status || 'resolved',
    order_date: todayLocal(), business_id: BIZ, _prep: prep, _stop: i + 1,
  };
}).sort((a, b) => b.created_at.localeCompare(a.created_at));

const FLOW = ['created', 'ready_for_pickup', 'picked_up', 'out_for_delivery', 'arrived', 'delivered'];
function events(o) {
  const out = [{ event_type: 'order_created', from_status: null, to_status: 'created', created_at: o.created_at, actor_role: 'vendor' }];
  const upto = o.delivery_status === 'issue' ? FLOW.indexOf('out_for_delivery') : FLOW.indexOf(o.delivery_status);
  let t = new Date(o.created_at).getTime();
  for (let i = 1; i <= upto; i++) {
    t += 22 * 60000;
    out.push({ event_type: 'status_changed', from_status: FLOW[i - 1], to_status: FLOW[i], created_at: new Date(t).toISOString(), actor_role: i < 2 ? 'vendor' : 'rider' });
  }
  if (o.delivery_status === 'issue') out.push({ event_type: 'issue_reported', from_status: 'out_for_delivery', to_status: 'issue', created_at: new Date(t + 15 * 60000).toISOString(), actor_role: 'rider' });
  return out;
}

const business = {
  id: BIZ, name: 'Kopi Kita', email: 'hello@kopikita.my', phone: '+60 3-2201 5566',
  address: 'No. 12, Jalan Damai 3, 50400 Kuala Lumpur', timezone: 'Asia/Kuala_Lumpur',
  service_origin_latitude: 3.1579, service_origin_longitude: 101.7123, service_coverage_radius_km: 15,
};
const members = [
  { user_id: USER.id, role: 'owner', status: 'active', created_at: '2026-08-01T02:00:00Z' },
  { user_id: 'demo-operator-1', role: 'operator', status: 'active', created_at: '2026-08-05T02:00:00Z' },
  { user_id: 'demo-operator-2', role: 'operator', status: 'active', created_at: '2026-08-20T02:00:00Z' },
];
const inDays = n => new Date(Date.now() + n * 86400000).toISOString();
const ratings = [['r-ahmad', 5], ['r-ahmad', 5], ['r-ahmad', 4], ['r-siti', 5], ['r-siti', 4], ['r-jason', 5], ['r-nur', 4]]
  .map(([rider_id, rating], i) => ({ rider_id, rating, order_id: `o-r${i}` }));

// ---------------------------------------------------------------- query layer
const clone = v => JSON.parse(JSON.stringify(v));
const strip = rows => rows.map(({ _prep, _stop, ...r }) => r);

function params(path) {
  const [base, qs = ''] = path.split('?');
  const table = base.replace(/^\/rest\/v1\//, '');
  const eq = {};
  for (const part of qs.split('&')) {
    const [k, v] = part.split('=');
    if (v && v.startsWith('eq.') && k !== 'business_id') eq[k] = decodeURIComponent(v.slice(3));
  }
  return { table, eq };
}

const TABLES = {
  orders: () => strip(orders),
  delivery_stops: () => orders.filter(o => o._prep || o.assigned_rider_id).map(o => ({ order_id: o.id, preparation_status: o._prep || 'ready', sequence: o._stop })),
  riders: () => riders,
  zones: () => zones,
  delivery_sessions: () => [session],
  ratings: () => ratings,
  businesses: () => [business],
  product_categories: () => [{ id: 'cat-1', name: 'Hampers' }, { id: 'cat-2', name: 'Cookies' }],
  products: () => [
    { id: 'p-1', name: 'Hamper Raya', description: 'Festive hamper', display_price: 129, status: 'active', category_id: 'cat-1', business_id: BIZ },
    { id: 'p-2', name: 'Cookies Box', description: 'Assorted cookies', display_price: 35, status: 'active', category_id: 'cat-2', business_id: BIZ },
    { id: 'p-3', name: 'Mini Tart Set', description: '', display_price: 28, status: 'hidden', category_id: 'cat-2', business_id: BIZ },
  ],
  business_members: () => members,
  profiles: () => [{ id: USER.id, display_name: 'Yusuf Sazali', phone: '+60 12-600 1122' }],
};

export async function demoGet(path) {
  const { table, eq } = params(path);
  if (table === 'delivery_events') {
    const o = orders.find(x => x.id === eq.order_id);
    return o ? events(o) : [];
  }
  const rows = TABLES[table] ? TABLES[table]() : [];
  return clone(rows.filter(r => Object.entries(eq).every(([k, v]) => String(r[k]) === v)));
}

export async function demoRpc(name, body = {}) {
  switch (name) {
    case 'get_my_businesses': return [{ business_id: BIZ, business_name: business.name, member_role: 'owner', timezone: business.timezone }];
    case 'get_invite_link': return { token: `demo-${body.p_kind}-link` };
    case 'latest_rider_locations': return [];
    case 'get_storefront': return { slug: 'kopi-kita', published: false, published_at: null, template_key: 'arena', theme: {} };
    case 'order_coverage_status': return 'covered';
    case 'check_run_vehicle_capacity': return { compatible: true, violations: [] };
    case 'propose_delivery_plan': {
      const waiting = orders.filter(o => o.approved_at && !o.assigned_rider_id && o.delivery_status === 'created');
      const byZone = new Map();
      waiting.forEach(o => byZone.set(o.zone_id, [...(byZone.get(o.zone_id) || []), o]));
      return { groups: [...byZone].map(([zone_id, os], i) => ({ zone_id, stops: os.map(o => ({ order_id: o.id })), candidate_rider_id: ['r-jason', 'r-nur'][i % 2], total_distance_km: 4.2 + i * 2.3 })) };
    }
    default: throw readOnly();
  }
}

export const demoUser = () => clone(USER);
export const readOnly = () => new DemoReadOnlyError(document.documentElement.lang === 'ms'
  ? 'Mod demo: perubahan tidak disimpan.'
  : 'Demo mode: changes are not saved.');
