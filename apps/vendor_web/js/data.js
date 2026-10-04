// Canonical reads for the active business (RLS-scoped REST + RPCs).
import { api } from './api.js';
import { ctx } from './store.js';

const q = encodeURIComponent;
const bizFilter = () => `business_id=eq.${q(ctx.bid)}`;

export const fetchOrders = (extra = '') => api.get(`/rest/v1/orders?${bizFilter()}&select=id,public_ref,order_number,customer_name,customer_phone,delivery_address,latitude,longitude,notes,items,delivery_status,assigned_rider_id,zone_id,delivery_session_id,estimated_arrival_at,completed_at,created_at,updated_at,approved_at,location_status,order_date&order=created_at.desc&limit=500${extra}`);
export const fetchOrder = id => api.get(`/rest/v1/orders?id=eq.${q(id)}&${bizFilter()}&select=*`).then(r => r?.[0] || null);
export const fetchStops = () => api.get(`/rest/v1/delivery_stops?${bizFilter()}&select=order_id,preparation_status,sequence`);
export const fetchRiders = () => api.get(`/rest/v1/riders?${bizFilter()}&select=id,name,phone,vehicle_plate,vehicle_type,status,availability_status,created_at,max_active_orders&order=created_at.asc`);
export const fetchZones = () => api.get(`/rest/v1/zones?${bizFilter()}&select=id,name,status,created_at&order=name.asc`);
export const fetchSessions = () => api.get(`/rest/v1/delivery_sessions?${bizFilter()}&select=id,name,delivery_date,status,pickup_at,sorting_started_at,created_at&order=created_at.desc&limit=200`);
export const fetchOrderEvents = orderId => api.get(`/rest/v1/delivery_events?order_id=eq.${q(orderId)}&select=event_type,from_status,to_status,created_at,actor_role&order=created_at.asc`);
export const fetchRatings = () => api.get(`/rest/v1/ratings?select=rider_id,rating,order_id&limit=2000`);
export const fetchLocations = () => api.rpc('latest_rider_locations', { p_business_id: ctx.bid }).catch(() => []);
export const fetchBusiness = () => api.get(`/rest/v1/businesses?id=eq.${q(ctx.bid)}&select=*`).then(r => r?.[0] || null);
// Active members only: a removed (inactive) member has no access and is not on the team.
export const fetchMembers = () => api.get(`/rest/v1/business_members?${bizFilter()}&status=eq.active&select=user_id,role,status,created_at&order=created_at.asc`);
// Invite-link join requests (Owner-only by RLS): pending to decide, approved to name members.
export const fetchJoinRequests = status => api.get(`/rest/v1/team_join_requests?${bizFilter()}&status=eq.${status}&select=id,user_id,role,name,phone,created_at&order=created_at.asc`);
export const fetchTeamInvites = () => api.get(`/rest/v1/team_invitations?${bizFilter()}&select=id,role,invited_email,status,expires_at,created_at&order=created_at.desc`);
export const fetchRiderInvites = () => api.get(`/rest/v1/rider_invitations?${bizFilter()}&select=id,invited_email,invited_name,status,expires_at,created_at&order=created_at.desc`);

export const byId = rows => new Map((rows || []).map(r => [r.id, r]));

// Business-local "today" as YYYY-MM-DD (orders.order_date is business-local).
export function todayLocal() {
  const tz = ctx.business?.timezone || 'Asia/Kuala_Lumpur';
  return new Intl.DateTimeFormat('en-CA', { timeZone: tz, year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date());
}

export const orderNo = o => o.order_number || (o.public_ref ? `#${o.public_ref}` : `#${o.id.slice(0, 6).toUpperCase()}`);
