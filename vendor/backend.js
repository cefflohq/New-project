(function () {
  const api = window.CEFFLO;
  const vendorSession = JSON.parse(localStorage.getItem('cefflo_auth_session') || 'null');
  if (vendorSession?.access_token && !api.session()?.access_token) api.setSession(vendorSession);
  const statusToUi = {
    created: 'readyForPickup', ready_for_pickup: 'readyForPickup', picked_up: 'pickedUp',
    out_for_delivery: 'delivering', arrived: 'delivering', delivered: 'completed',
    issue: 'issue', cancelled: 'cancelled'
  };

  async function businesses() { return api.rpc('get_my_businesses', {}); }
  async function createDelivery(input) {
    return api.rpc('create_delivery', {
      p_business_id: input.businessId, p_customer_name: input.customerName,
      p_customer_phone: input.customerPhone, p_delivery_address: input.address,
      p_notes: input.notes || '', p_latitude: input.latitude ?? null,
      p_longitude: input.longitude ?? null, p_items: input.items || [],
      p_zone_id: input.zoneId ?? null, p_vehicle_requirement: input.vehicleRequirement || 'any'
    });
  }
  const assignRider = (orderId, riderId) => api.rpc('assign_rider', { p_order_id: orderId, p_rider_id: riderId });
  const approveOrder = orderId => api.rpc('approve_order', { p_order_id: orderId });
  const deactivateRider = riderId => api.rpc('deactivate_rider', { p_rider_id: riderId });
  const updateRiderDetails = input => api.rpc('update_rider_details', {
    p_rider_id: input.riderId, p_name: input.name ?? null, p_phone: input.phone ?? null,
    p_vehicle_plate: input.vehiclePlate ?? null, p_vehicle_type: input.vehicleType ?? null,
    // Flow 2 Canonical Backend Completion Master, D-03: canonical field
    // name is max_active_orders (nullable integer; null = fall back to
    // the vehicle-type default). Renamed from capacity_override -- same
    // semantics, same RPC parameter position.
    p_max_active_orders: input.maxActiveOrders ?? null
  });
  const updateOrderDetails = input => api.rpc('update_order_details', {
    p_order_id: input.orderId, p_customer_name: input.customerName ?? null,
    p_customer_phone: input.customerPhone ?? null, p_delivery_address: input.address ?? null,
    p_notes: input.notes ?? null, p_items: input.items ?? null,
    p_zone_id: input.zoneId ?? null, p_clear_zone: input.clearZone ?? false,
    p_vehicle_requirement: input.vehicleRequirement ?? null
  });
  // Grow V1 Flow 2 (A1-A6): new operational-engine RPC wrappers, following
  // the exact same thin-wrapper convention as every function above.
  const checkRunVehicleCapacity = (riderId, orderIds) => api.rpc('check_run_vehicle_capacity', {
    p_rider_id: riderId, p_order_ids: orderIds
  });
  const proposeDeliveryPlan = businessId => api.rpc('propose_delivery_plan', { p_business_id: businessId });
  const importOrdersBatch = (businessId, rows, idempotencyKey) => api.rpc('import_orders_batch', {
    p_business_id: businessId, p_rows: rows, p_idempotency_key: idempotencyKey
  });
  const advancePreparation = (orderId, next) => api.rpc('advance_preparation', {
    p_order_id: orderId, p_next: next
  });
  const setBusinessServiceArea = (businessId, lat, lng, radiusKm) => api.rpc('set_business_service_area', {
    p_business_id: businessId, p_origin_latitude: lat, p_origin_longitude: lng, p_radius_km: radiusKm
  });
  const initiateDeliveryRecovery = (orderId, reason, note, idempotencyKey) => api.rpc('initiate_delivery_recovery', {
    p_order_id: orderId, p_reason: reason, p_rider_id: null, p_note: note || '', p_idempotency_key: idempotencyKey
  });
  const setOrderLocationManual = (orderId, lat, lng) => api.rpc('set_order_location_manual', {
    p_order_id: orderId, p_latitude: lat, p_longitude: lng
  });
  // Grow V1 Flow 2 -- Mapbox Permanent Geocoding provider gate. Calls the
  // geocode-order Edge Function (the only place in this codebase that
  // talks to Mapbox), which itself enforces GEOCODE ONCE (skips the call
  // entirely if the order is already 'resolved') and persists the result
  // through the existing canonical set_order_location RPC -- no parallel
  // location write path. Uses the caller's own session (Authorization
  // header), so the Edge Function's RLS-scoped read enforces the same
  // tenant boundary as every other Vendor action here.
  const geocodeOrder = async (orderId) => {
    const response = await fetch(`${api.config.supabaseUrl}/functions/v1/geocode-order`, {
      method: 'POST',
      headers: {
        apikey: api.config.supabaseAnonKey,
        Authorization: `Bearer ${api.session()?.access_token || api.config.supabaseAnonKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ order_id: orderId }),
    });
    const result = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(result.error || 'Geocoding request failed');
    return result;
  };
  const updateTeamMember = input => api.rpc('update_team_member', {
    p_business_id: input.businessId, p_user_id: input.userId,
    p_role: input.role ?? null, p_status: input.status ?? null
  });
  const reassignRider = (orderId, riderId) => api.rpc('reassign_rider', {
    p_order_id: orderId, p_new_rider_id: riderId
  });
  const createDeliverySession = (businessId, name) => api.rpc('create_delivery_session', {
    p_business_id: businessId, p_name: name
  });
  const createZone = (businessId, name) => api.rpc('create_zone', {
    p_business_id: businessId, p_name: name
  });
  const buildRiderRun = input => api.rpc('build_rider_run', {
    p_delivery_session_id: input.sessionId, p_rider_id: input.riderId,
    p_order_ids: input.orderIds, p_idempotency_key: input.idempotencyKey,
    p_override_capacity: input.overrideCapacity || false
  });
  const updateBusinessProfile = input => api.rpc('update_business_profile', {
    p_business_id: input.businessId, p_name: input.name ?? null, p_phone: input.phone ?? null,
    p_email: input.email ?? null, p_address: input.address ?? null,
    p_operating_area: input.operatingArea ?? null, p_timezone: input.timezone ?? null,
    p_currency: input.currency ?? null, p_idempotency_key: input.requestId ?? null
  });
  // S4-07: trusted-team + Rider invitation RPCs. Role/business always come
  // from the server-side invitation row on accept -- these client wrappers
  // never accept a role at accept time, only at creation (Owner-only,
  // enforced server-side regardless of what this client sends).
  const createTeamInvitation = input => api.rpc('create_team_invitation', {
    p_business_id: input.businessId, p_role: input.role, p_invited_email: input.email
  });
  const revokeTeamInvitation = invitationId => api.rpc('revoke_team_invitation', { p_invitation_id: invitationId });
  const createRiderInvitation = input => api.rpc('create_rider_invitation', {
    p_business_id: input.businessId, p_invited_email: input.email, p_invited_name: input.name, p_invited_phone: input.phone
  });
  const revokeRiderInvitation = invitationId => api.rpc('revoke_rider_invitation', { p_invitation_id: invitationId });
  const approvePendingRider = riderId => api.rpc('approve_pending_rider', { p_rider_id: riderId });
  // S4-08: authoritative delivery-issue report. Only the four Vendor "Report
  // Issue" reasons with a genuine canonical backend match are wired here --
  // 'time' (sudden time change) and 'spill' (packaging spill) have no
  // truthful mapping and are deliberately left unmapped, not force-mapped.
  const VENDOR_ISSUE_REASON_MAP = { unreachable: 'customer_unreachable', wrong: 'address_problem', bike: 'rider_unable_to_proceed', late: 'vendor_not_ready' };
  const reportDeliveryIssue = (orderId, reasonType, note) => api.rpc('vendor_report_delivery_issue', { p_order_id: orderId, p_reason_type: reasonType, p_note: note || null });

  const listOrders = businessId => api.request(`/rest/v1/orders?business_id=eq.${encodeURIComponent(businessId)}&select=*&order=created_at.desc`);
  const listRiders = businessId => api.request(`/rest/v1/riders?business_id=eq.${encodeURIComponent(businessId)}&select=*&order=created_at.asc`);
  const listBusinessMembers = businessId => api.request(`/rest/v1/business_members?business_id=eq.${encodeURIComponent(businessId)}&select=*&order=created_at.asc`);
  const listTeamInvitations = businessId => api.request(`/rest/v1/team_invitations?business_id=eq.${encodeURIComponent(businessId)}&select=id,role,invited_email,status,expires_at,created_at&order=created_at.desc`);
  const listRiderInvitations = businessId => api.request(`/rest/v1/rider_invitations?business_id=eq.${encodeURIComponent(businessId)}&select=id,invited_email,invited_name,status,expires_at,created_at&order=created_at.desc`);
  const listRatings = orderIds => orderIds.length
    ? api.request(`/rest/v1/ratings?order_id=in.(${orderIds.map(encodeURIComponent).join(',')})&select=*`)
    : Promise.resolve([]);
  const listZones = businessId => api.request(`/rest/v1/zones?business_id=eq.${encodeURIComponent(businessId)}&select=*&order=name.asc`);
  const listDeliverySessions = businessId => api.request(`/rest/v1/delivery_sessions?business_id=eq.${encodeURIComponent(businessId)}&select=*&order=created_at.desc`);
  const listDeliveryEvents = businessId => api.request(`/rest/v1/delivery_events?business_id=eq.${encodeURIComponent(businessId)}&select=id,order_id,event_type,from_status,to_status,actor_role,metadata,created_at&order=created_at.desc`);
  // S4-06.7 (P1): minimal factual Run-progress hydration -- one nested embed
  // (assignments_vendor/stops_vendor RLS already permit this for a business
  // member, unchanged), mirroring the same real-embed pattern the Rider
  // adapter already uses. No new table, no fabricated field: assignment
  // status (assigned/accepted/declined/...) and this order's own stop
  // status/sequence, nothing else.
  const listRiderAssignments = businessId => api.request(`/rest/v1/rider_assignments?business_id=eq.${encodeURIComponent(businessId)}&select=id,rider_id,delivery_session_id,status,accepted_at,delivery_stops(id,order_id,status,sequence)&order=assigned_at.asc`);
  // Grow V1 Flow 2 (C1-C3): ALL of this business's stops, not only the
  // ones already attached to a rider_assignments row -- Prepare->Pack->
  // Ready is upstream of assignment (a Helper works on an order before a
  // Vendor ever builds a run for it), so listRiderAssignments' assignment-
  // scoped join above cannot carry preparation truth for unassigned orders.
  const listDeliveryStops = businessId => api.request(`/rest/v1/delivery_stops?business_id=eq.${encodeURIComponent(businessId)}&select=id,order_id,preparation_status,preparation_updated_at&order=created_at.asc`);
  // Grow V1 Flow 2 (A2): the business's own service-area columns.
  // get_my_businesses() is a curated cross-membership view that doesn't
  // carry them; a direct, RLS-scoped single-row fetch is the smallest
  // real addition rather than widening that RPC's contract.
  const getServiceArea = businessId => api.request(`/rest/v1/businesses?id=eq.${encodeURIComponent(businessId)}&select=service_origin_latitude,service_origin_longitude,service_coverage_radius_km`).then(rows => rows[0] || {});

  function mapOrder(row) {
    return {
      id: row.public_ref, backendId: row.id, publicRef: row.public_ref, customer: row.customer_name, customerName: row.customer_name,
      phone: row.customer_phone, customerPhone: row.customer_phone, address: row.delivery_address,
      note: row.notes || '', notes: row.notes || '', items: row.items || [], riderId: row.assigned_rider_id,
      zoneId: row.zone_id, deliverySessionId: row.delivery_session_id,
      status: statusToUi[row.delivery_status] || row.delivery_status, backendStatus: row.delivery_status,
      total: '0.00', payment: row.payment_status || 'Pending',
      trackingToken: localStorage.getItem(`cefflo_tracking_token_${row.id}`),
      approvedAt: row.approved_at, approvedBy: row.approved_by,
      delivered: row.delivery_status === 'delivered', completedAt: row.completed_at,
      time: row.completed_at ? new Date(row.completed_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : null,
      createdAt: row.created_at, updatedAt: row.updated_at, activity: [],
      // Grow V1 Flow 2 (A1/A3): real canonical location/vehicle-requirement
      // truth -- location_status/vehicle_requirement are real orders
      // columns; coverageStatus is fetched lazily per-order (order detail
      // only, not this bulk hydrate -- it's a live haversine computation,
      // not a stored column, so calling it for every order on every list
      // refresh would be wasteful) via CEFFLO_VENDOR.orderCoverageStatus.
      locationStatus: row.location_status, latitude: row.latitude, longitude: row.longitude,
      vehicleRequirement: row.vehicle_requirement || 'any'
    };
  }
  function mapRider(row) {
    return { id: row.id, name: row.name, phone: row.phone, plate: row.vehicle_plate || '—', status: row.status === 'inactive' ? 'offline' : row.status, zone: 'Unassigned', availabilityStatus: row.availability_status,
      // Grow V1 Flow 2 (A3, renamed under F2-13/D-03): real canonical
      // Motorcycle/Car/Van truth and per-Rider max_active_orders override,
      // replacing the vehicle_plate-only model Flow 1 found.
      vehicleType: row.vehicle_type || 'motorcycle', maxActiveOrders: row.max_active_orders };
  }
  function mapZone(row) {
    return { id: row.id, name: row.name, status: row.status };
  }
  // S4-06.7 (P1): one row per real rider_assignments record (= one order's
  // assignment, per this project's per-order assignment model), carrying
  // this Rider's genuine assignment state and this order's own stop
  // status/sequence -- never fabricated, never inferred from orders alone.
  function mapAssignment(row) {
    const stop = Array.isArray(row.delivery_stops) ? row.delivery_stops[0] : row.delivery_stops;
    return {
      id: row.id, riderId: row.rider_id, deliverySessionId: row.delivery_session_id,
      status: row.status, acceptedAt: row.accepted_at,
      orderId: stop ? stop.order_id : null, stopId: stop ? stop.id : null,
      stopStatus: stop ? (statusToUi[stop.status] || stop.status) : null, sequence: stop ? stop.sequence : null
    };
  }
  function mapStopFromAssignment(row) {
    const stop = Array.isArray(row.delivery_stops) ? row.delivery_stops[0] : row.delivery_stops;
    if (!stop) return null;
    return { id: stop.id, orderId: stop.order_id, riderId: row.rider_id, sequence: stop.sequence, status: statusToUi[stop.status] || stop.status };
  }
  function mapSession(row) {
    return { id: row.id, name: row.name, status: row.status, deliveryDate: row.delivery_date };
  }

  async function hydrateCanonicalWorkspace() {
    if (!api.session()?.access_token) return false;
    const rows = await businesses();
    const selected = rows.find(item => item.business_id === localStorage.getItem('cefflo_active_business_id')) || rows[0];
    if (!selected) return false;
    state.businessId = selected.business_id;
    state.storeName = selected.business_name;
    // S4-07 (Section 12): reconnect the real current membership role into
    // the canonical hydration path -- get_my_businesses() already returns
    // it; this path previously never captured it, so Owner-only UI (the
    // Team screen's Invite controls) could not be gated on a real value.
    // Backend RPCs remain independently authoritative regardless of this
    // client-side gate (every Owner-only RPC re-checks is_business_owner).
    state.currentMemberRole = selected.member_role;
    localStorage.setItem('cefflo_active_business_id', selected.business_id);
    const orders = await listOrders(selected.business_id);
    const [riders, ratings, zones, sessions, assignments, events, stops, serviceArea] = await Promise.all([
      listRiders(selected.business_id), listRatings(orders.map(order => order.id)),
      listZones(selected.business_id), listDeliverySessions(selected.business_id),
      listRiderAssignments(selected.business_id), listDeliveryEvents(selected.business_id),
      listDeliveryStops(selected.business_id), getServiceArea(selected.business_id)
    ]);
    state.serviceArea = serviceArea;
    state.riders = riders.map(mapRider);
    state.orders = orders.map(mapOrder);
    // Grow V1 Flow 2 (C1-C3): attach real preparation truth (Prepare->
    // Pack->Ready) onto every order, from the full-stop query above --
    // covers unassigned orders too, unlike the assignment-scoped join.
    const stopByOrderId = new Map(stops.map(stop => [stop.order_id, stop]));
    state.orders.forEach(order => {
      const stop = stopByOrderId.get(order.backendId);
      order.preparationStatus = stop ? stop.preparation_status : 'not_started';
      order.deliveryStopId = stop ? stop.id : null;
    });
    const ratingOrderIds = new Set(ratings.map(item => item.order_id));
    state.orders.forEach(order => { order.ratingSubmitted = ratingOrderIds.has(order.backendId); order.riderName = state.riders.find(r => r.id === order.riderId)?.name || null; });
    // Real S4-06.3/.5a data -- distinct from the deprecated mock engine's
    // same-named fields, which this canonical hydration path always
    // overwrites (never left populated with fabricated values).
    state.zones = zones.map(mapZone);
    // Real orders carry only zoneId (a real zones.id FK); every existing
    // display site in this UI (Orders list, Order Detail, CSV export) reads
    // a resolved zone NAME off order.zone, a field only the old mock
    // order-creation flow ever set. Backfill it here, once, right after both
    // real orders and real zones are hydrated -- otherwise every real order
    // renders the zone column as the literal text "undefined".
    state.orders.forEach(order => { order.zone = state.zones.find(z => z.id === order.zoneId)?.name || t('unassigned'); });
    state.deliverySessions = sessions.map(mapSession);
    // S4-06.7 (P1): real assignment/stop data, replacing the two arrays this
    // path previously always hardcoded empty. riderAssignments carries the
    // genuine per-order assignment state (assigned/accepted/declined/...)
    // the Vendor previously had no way to see at all; deliveryStops mirrors
    // it in the shape the existing dashboard aggregation already expects.
    state.riderAssignments = assignments.map(mapAssignment);
    state.deliveryStops = assignments.map(mapStopFromAssignment).filter(Boolean);
    const orderByBackendId = new Map(state.orders.map(order => [order.backendId, order]));
    state.orderStatusHistory = events.filter(event => event.order_id).map(event => ({
      id: event.id, orderId: orderByBackendId.get(event.order_id)?.id || event.order_id,
      eventType: event.event_type, fromStatus: event.from_status, toStatus: event.to_status,
      actorRole: event.actor_role, metadata: event.metadata || {}, createdAt: event.created_at
    }));
    state.issues = events.filter(event => event.event_type === 'delivery.issue_reported').map(event => ({
      id: event.id, orderId: orderByBackendId.get(event.order_id)?.id || event.order_id,
      type: event.metadata?.reason_type || 'delivery', note: event.metadata?.note || '',
      status: 'open', createdAt: event.created_at
    }));
    backendState.mode = 'remote'; backendState.status = 'connected'; backendState.lastSyncedAt = new Date().toISOString();
    persistOperationalStoreLocalOnly();
    if (typeof reconcileRunBuilderAfterHydrate === 'function') reconcileRunBuilderAfterHydrate();
    return true;
  }

  // S4-07 (Section 13): the Team screen's own data -- fetched lazily, only
  // when that screen is actually opened, rather than on every canonical
  // hydrate (this project's established "smallest real-data hydration
  // necessary" discipline, matching S4-06.7 P1's own reasoning).
  async function hydrateTeamWorkspace() {
    if (!state.businessId) return false;
    const [members, teamInvitations, riderInvitations] = await Promise.all([
      listBusinessMembers(state.businessId), listTeamInvitations(state.businessId), listRiderInvitations(state.businessId)
    ]);
    state.teamMembers = members.map(m => ({ userId: m.user_id, role: m.role, status: m.status, createdAt: m.created_at }));
    state.teamInvitations = teamInvitations.map(i => ({ id: i.id, role: i.role, email: i.invited_email, status: i.status, expiresAt: i.expires_at, createdAt: i.created_at }));
    state.riderInvitations = riderInvitations.map(i => ({ id: i.id, email: i.invited_email, name: i.invited_name, status: i.status, expiresAt: i.expires_at, createdAt: i.created_at }));
    return true;
  }

  let unsubscribeRealtime = null;
  // Minimal public teardown: unsubscribes the active Vendor realtime channel
  // (if any), clears the reference, and is safe to call with none active --
  // used by Vendor logout so no old-business channel outlives the session.
  function stopRealtime() {
    if (unsubscribeRealtime) { try { unsubscribeRealtime(); } catch (error) { /* ignore */ } }
    unsubscribeRealtime = null;
  }
  // Minimal public start: (re)establishes the one Vendor realtime channel
  // for the current business, reusing subscribe() exactly as before. Safe
  // to call repeatedly -- the same not-already-subscribed guard that used
  // to live only in the initial-load restore() closure now lives here, so
  // any later authenticated-hydration event (not just first script load)
  // can trigger a fresh subscription after logout -> login in the same tab.
  function startRealtime() {
    if (!unsubscribeRealtime && state.businessId) {
      unsubscribeRealtime = subscribe(state.businessId, () => hydrateCanonicalWorkspace().then(render).catch(() => {}));
    }
  }
  function subscribe(businessId, refresh) {
    const client = window.supabase?.createClient(api.config.supabaseUrl, api.config.supabaseAnonKey, {
      global: { headers: { Authorization: `Bearer ${api.session()?.access_token || api.config.supabaseAnonKey}` } }
    });
    if (!client) return () => {};
    // S4-06.7 (P6): narrowly extended -- rider_assignments and
    // delivery_stops added so a Rider's Accept/Decline/pickup/delivery
    // progress becomes observable without waiting on an unrelated Vendor
    // action, matching the real Run-progress data now hydrated in P1.
    // Still just table-change notifications feeding the same
    // hydrateCanonicalWorkspace() refresh -- no new realtime subsystem.
    const channel = client.channel(`vendor:${businessId}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'orders', filter: `business_id=eq.${businessId}` }, refresh)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'rider_assignments', filter: `business_id=eq.${businessId}` }, refresh)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'delivery_stops', filter: `business_id=eq.${businessId}` }, refresh)
      .subscribe();
    return () => client.removeChannel(channel);
  }

  const orderCoverageStatus = orderId => api.rpc('order_coverage_status', { p_order_id: orderId });

  window.CEFFLO_VENDOR = Object.freeze({
    businesses, createDelivery, assignRider, approveOrder, deactivateRider, updateRiderDetails,
    updateOrderDetails, updateTeamMember, reassignRider, updateBusinessProfile,
    createDeliverySession, buildRiderRun,
    listOrders, listRiders, listRatings, listZones, listDeliverySessions,
    createTeamInvitation, revokeTeamInvitation, createRiderInvitation, revokeRiderInvitation, approvePendingRider, reportDeliveryIssue,
    listBusinessMembers, listTeamInvitations, listRiderInvitations,
    hydrate: hydrateCanonicalWorkspace, hydrateTeam: hydrateTeamWorkspace, subscribe, startRealtime, stopRealtime,
    // Grow V1 Flow 2
    checkRunVehicleCapacity, proposeDeliveryPlan, importOrdersBatch, advancePreparation,
    setBusinessServiceArea, initiateDeliveryRecovery, setOrderLocationManual, orderCoverageStatus, geocodeOrder
  });
  hydrateOperationalStateFromBackend = hydrateCanonicalWorkspace;
  syncOperationalStateToBackend = async () => true;

  wizSubmit = async function () {
    try {
      const created = await createDelivery({ businessId: state.businessId, customerName: wizardState.data.name,
        customerPhone: wizardState.data.phone, address: wizardState.data.address, notes: wizardState.data.note || '', items: wizardState.data.items,
        vehicleRequirement: wizardState.data.vehicleRequirement || 'any' });
      localStorage.setItem(`cefflo_tracking_token_${created.order.id}`, created.tracking_token);
      await hydrateCanonicalWorkspace();
      toast(tf('orderCreatedSuccess', { id: created.order.public_ref }), 'success');
      navigate('orders', { tab: 'ongoing' }, false);
      // Fire-and-forget: geocoding failure/slowness must never block or
      // undo a successful order creation -- the order exists either way,
      // just 'unresolved' until a retry (automatic or the Order Detail
      // "Geocode Address" action) succeeds.
      geocodeOrder(created.order.id).then(() => hydrateCanonicalWorkspace()).then(render).catch(() => {});
    } catch (error) { toast(error.message || 'Unable to create delivery', 'error'); }
  };

  const approvingOrders = new Set();
  approveOrderAction = async function (el) {
    const order = state.orders.find(item => item.id === el.dataset.id);
    const orderId = order?.backendId || el.dataset.id;
    if (approvingOrders.has(orderId)) return; // in-flight guard: prevent duplicate approval requests
    approvingOrders.add(orderId);
    try {
      await approveOrder(orderId);
      await hydrateCanonicalWorkspace();
      toast('Order approved', 'success');
      render();
    } catch (error) {
      toast(error.message || 'Unable to approve order', 'error');
    } finally {
      approvingOrders.delete(orderId);
    }
  };

  confirmAssignRiderOrder = async function (el) {
    try {
      const order = state.orders.find(item => item.id === el.dataset.orderid);
      const orderId = order?.backendId || el.dataset.orderid;
      if (order?.riderId && order.riderId !== el.dataset.riderid) {
        await reassignRider(orderId, el.dataset.riderid);
      } else if (!order?.riderId) {
        await assignRider(orderId, el.dataset.riderid);
      }
      await hydrateCanonicalWorkspace(); closeSheet(); toast('Rider assigned', 'success'); render();
    } catch (error) { toast(error.message || 'Unable to assign rider', 'error'); }
  };

  ACTIONS.confirmCreateZone = async function () {
    const name = document.getElementById('new_zone_name')?.value.trim();
    if (!name) { toast('Enter a zone name.', 'error'); return; }
    try {
      await createZone(state.businessId, name);
      await hydrateCanonicalWorkspace();
      closeSheet(); render(); toast(`Zone ${name} created`, 'success');
    } catch (error) { toast(error.message || 'Unable to create zone', 'error'); }
  };

  ACTIONS.assignZoneRider = async function (el) {
    try {
      const zone = state.zones.find(item => item.id === el.dataset.zone);
      const rider = state.riders.find(item => item.id === el.dataset.rider);
      if (!zone || !rider) throw new Error('Zone or Rider not found.');
      const orders = state.orders.filter(order => order.zoneId === zone.id && order.backendStatus === 'created' && order.approvedAt && !order.riderId);
      if (!orders.length) throw new Error('No approved unassigned orders in this zone.');
      let session = state.deliverySessions.find(item => ['planned', 'active'].includes(item.status));
      if (!session) session = await createDeliverySession(state.businessId, `${zone.name} Run`);
      const idempotencyKey = window.crypto?.randomUUID?.();
      if (!idempotencyKey) throw new Error('Unable to generate a secure request id.');
      await buildRiderRun({ sessionId: session.id, riderId: rider.id, orderIds: orders.map(order => order.backendId), idempotencyKey });
      await hydrateCanonicalWorkspace(); closeSheet(); render(); toast(`Zone orders assigned to ${rider.name}`, 'success');
    } catch (error) { toast(error.message || 'Unable to assign zone orders', 'error'); }
  };

  confirmDeactivateRider = async function (el) {
    try {
      await deactivateRider(el.dataset.id);
      await hydrateCanonicalWorkspace(); closeSheet(); toast('Rider deactivated', 'success'); render();
    } catch (error) { toast(error.message || 'Unable to deactivate rider', 'error'); }
  };

  function runBuilderPayloadSignature(sessionId, riderId, orderIds) {
    return JSON.stringify({ sessionId, riderId, orderIds: [...orderIds].sort() });
  }
  confirmRunBuilder = async function () {
    if (runBuilderState.submitting) return;
    const selectedOrders = state.orders.filter(o => runBuilderState.selectedOrderIds.has(o.backendId));
    const rider = state.riders.find(r => r.id === runBuilderState.riderId);
    if (!selectedOrders.length || !rider) return;
    if (runBuilderState.waveMode === 'existing' && !runBuilderState.waveId) return;
    if (runBuilderState.waveMode === 'new' && !runBuilderState.newWaveName.trim()) return;

    runBuilderState.submitting = true;
    runBuilderState.lastError = null;
    if (typeof rerenderRunBuilderSheet === 'function') rerenderRunBuilderSheet();

    try {
      let sessionId = runBuilderState.waveMode === 'existing' ? runBuilderState.waveId : runBuilderState.resolvedNewSessionId;
      if (!sessionId) {
        // Created at most once per operation -- cached on the state so an
        // ambiguous-failure retry of the SAME operation never creates a
        // second Wave; it reuses whatever was already made.
        const created = await api.rpc('create_delivery_session', {
          p_business_id: state.businessId, p_name: runBuilderState.newWaveName.trim()
        });
        sessionId = created.id;
        runBuilderState.resolvedNewSessionId = sessionId;
      }
      const orderIds = selectedOrders.map(o => o.backendId);
      const signature = runBuilderPayloadSignature(sessionId, rider.id, orderIds);
      if (runBuilderState.pendingSignature !== signature) {
        // A materially different operation (orders/Rider/Wave changed)
        // always gets a fresh key; an unresolved retry of the identical
        // operation reuses the one already generated for it.
        runBuilderState.pendingKey = (window.crypto && window.crypto.randomUUID) ? window.crypto.randomUUID() : null;
        runBuilderState.pendingSignature = signature;
      }
      if (!runBuilderState.pendingKey) throw new Error('Unable to generate a secure request id in this browser.');

      const result = await api.rpc('build_rider_run', {
        p_delivery_session_id: sessionId, p_rider_id: rider.id, p_order_ids: orderIds,
        p_idempotency_key: runBuilderState.pendingKey,
        // Grow V1 Flow 2 (A3): only ever true after the Vendor has seen the
        // violation list (renderRunBuilderErrorBanner) and explicitly
        // clicked "Assign anyway" (ACTIONS.confirmRunBuilderOverride below)
        // -- never defaulted true, never silently retried.
        p_override_capacity: runBuilderState.overrideCapacity
      });
      await hydrateCanonicalWorkspace();
      closeSheet();
      toast(result.vehicle_capacity_override_used
        ? `${result.order_count} orders assigned to ${rider.name} (vehicle/capacity override recorded)`
        : `${result.order_count} orders assigned to ${rider.name}`, 'success');
      resetRunBuilderState();
      render();
    } catch (error) {
      runBuilderState.submitting = false;
      if (typeof handleRunBuilderError === 'function') await handleRunBuilderError(error);
      if (typeof rerenderRunBuilderSheet === 'function') rerenderRunBuilderSheet();
    }
  };
  ACTIONS.confirmRunBuilder = confirmRunBuilder;

  // Grow V1 Flow 2 (A3): overrides index.html's handleRunBuilderError with
  // one new branch (vehicle/capacity), delegating every other message to
  // the original implementation unchanged -- the same "backend.js adds the
  // real RPC-aware branch, index.html keeps the pure-UI fallback" split
  // used throughout this file.
  const baseHandleRunBuilderError = handleRunBuilderError;
  handleRunBuilderError = async function (error) {
    const msg = String((error && error.message) || '');
    if (msg.includes('vehicle/capacity incompatible')) {
      const selectedOrders = state.orders.filter(o => runBuilderState.selectedOrderIds.has(o.backendId));
      const rider = state.riders.find(r => r.id === runBuilderState.riderId);
      try {
        const check = await checkRunVehicleCapacity(rider.id, selectedOrders.map(o => o.backendId));
        runBuilderState.capacityViolations = check.violations || [];
      } catch (e) {
        runBuilderState.capacityViolations = [];
      }
      runBuilderState.lastError = { type: 'vehicle_capacity_conflict' };
      return;
    }
    return baseHandleRunBuilderError(error);
  };
  ACTIONS.confirmRunBuilderOverride = async function () {
    runBuilderState.overrideCapacity = true;
    runBuilderState.lastError = null;
    await confirmRunBuilder();
  };

  // Grow V1 Flow 2 (B1): the real commit step. Overrides index.html's
  // stub (which only ever showed "CSV import is not connected yet.") --
  // parse/preview/validate/fix-row above are untouched, exactly per the
  // Founder-approved "keep the existing foundation" direction. Only
  // 'Valid' rows are submitted; still-invalid rows stay visible for the
  // Vendor to fix or abandon, matching the existing per-row-fix UX.
  const csvImportInFlight = { key: null, submitting: false };
  confirmCsvImport = async function () {
    if (csvImportInFlight.submitting) return;
    const validRows = csvState.rows.filter(r => r.status === 'Valid');
    if (!validRows.length) { toast('No valid rows to import.', 'error'); return; }
    const idempotencyKey = window.crypto?.randomUUID?.();
    if (!idempotencyKey) { toast('Unable to generate a secure request id in this browser.', 'error'); return; }
    csvImportInFlight.submitting = true;
    try {
      const rows = validRows.map((r, i) => ({
        source_row_ref: r.orderId || `row-${r.sourceRow || i}`,
        customer_name: r.name, customer_phone: r.phone, delivery_address: r.address,
        zone_name: r.zone || null
      }));
      const result = await importOrdersBatch(state.businessId, rows, idempotencyKey);
      await hydrateCanonicalWorkspace();
      csvState.step = 1; csvState.rows = [];
      closeSheet();
      const committedCount = (result.committed || []).length;
      const rejectedCount = (result.rejected || []).length;
      navigate('orders', { tab: 'ongoing' }, false);
      toast(rejectedCount > 0
        ? `${committedCount} orders imported, ${rejectedCount} rejected at commit time.`
        : `${committedCount} orders imported.`, rejectedCount > 0 ? 'error' : 'success');
      // CSV/XLSX enters the exact same canonical location lifecycle as
      // every other intake path -- no separate import-only geocoding
      // system. Fire-and-forget per committed row: a slow/failed geocode
      // must never undo or block the already-successful canonical commit
      // above; each order simply stays 'unresolved' (retryable later) if
      // its request doesn't succeed.
      const committedIds = (result.committed || []).map(c => c.order_id).filter(Boolean);
      if (committedIds.length) {
        Promise.allSettled(committedIds.map(id => geocodeOrder(id)))
          .then(() => hydrateCanonicalWorkspace())
          .then(render)
          .catch(() => {});
      }
    } catch (error) {
      toast(error.message || 'Unable to commit import', 'error');
    } finally {
      csvImportInFlight.submitting = false;
    }
  };
  ACTIONS.confirmCsvImport = confirmCsvImport;

  // Grow V1 Flow 2 (C1-C3): real Prepare->Pack->Ready action, replacing
  // index.html's stub. In-flight guard mirrors approveOrderAction's own
  // pattern (prevent duplicate taps mutating the same stop twice).
  const prepActionsInFlight = new Set();
  advancePreparationAction = async function (el) {
    const orderId = el.dataset.orderid;
    const next = el.dataset.next;
    if (!orderId || !next || prepActionsInFlight.has(orderId)) return;
    prepActionsInFlight.add(orderId);
    try {
      await advancePreparation(orderId, next);
      await hydrateCanonicalWorkspace();
      toast('Preparation updated', 'success');
      render();
    } catch (error) {
      toast(error.message || 'Unable to update preparation status', 'error');
    } finally {
      prepActionsInFlight.delete(orderId);
    }
  };
  ACTIONS.advancePreparationAction = advancePreparationAction;

  confirmEditRiderVehicle = async function (el) {
    try {
      const vehicleType = document.getElementById('erv_vehicle_type')?.value;
      const maxActiveOrdersRaw = document.getElementById('erv_capacity')?.value.trim();
      const maxActiveOrders = maxActiveOrdersRaw ? Number(maxActiveOrdersRaw) : null;
      if (maxActiveOrdersRaw && (!Number.isFinite(maxActiveOrders) || maxActiveOrders <= 0)) throw new Error('Capacity must be a positive number.');
      await updateRiderDetails({ riderId: el.dataset.id, vehicleType, maxActiveOrders });
      await hydrateCanonicalWorkspace();
      closeSheet(); render(); toast('Rider vehicle/capacity updated', 'success');
    } catch (error) { toast(error.message || 'Unable to update rider', 'error'); }
  };
  ACTIONS.confirmEditRiderVehicle = confirmEditRiderVehicle;

  confirmEditServiceArea = async function () {
    try {
      const lat = Number(document.getElementById('esa_lat')?.value);
      const lng = Number(document.getElementById('esa_lng')?.value);
      const radius = Number(document.getElementById('esa_radius')?.value);
      if (!Number.isFinite(lat) || !Number.isFinite(lng) || !Number.isFinite(radius) || radius <= 0) throw new Error('Enter a valid latitude, longitude, and radius.');
      await setBusinessServiceArea(state.businessId, lat, lng, radius);
      await hydrateCanonicalWorkspace();
      closeSheet(); render(); toast('Service area saved', 'success');
    } catch (error) { toast(error.message || 'Unable to save service area', 'error'); }
  };
  ACTIONS.confirmEditServiceArea = confirmEditServiceArea;

  // Grow V1 Flow 2 -- Mapbox Permanent Geocoding provider gate. Manual
  // retry action on Order Detail (unresolved/ambiguous/failed) and the
  // preserved manual-correction path (set_order_location_manual) --
  // required to stay functional independent of provider outcome (Task
  // requirement #9).
  const geocodeActionsInFlight = new Set();
  geocodeOrderAction = async function (el) {
    const order = state.orders.find(item => item.id === el.dataset.id);
    const orderId = order?.backendId || el.dataset.id;
    if (geocodeActionsInFlight.has(orderId)) return;
    geocodeActionsInFlight.add(orderId);
    try {
      const result = await geocodeOrder(orderId);
      await hydrateCanonicalWorkspace();
      render();
      if (result.status === 'resolved') toast(result.skipped ? 'Already located' : 'Location resolved', 'success');
      else toast(`Could not resolve location (${result.reason || result.status})`, 'error');
    } catch (error) {
      toast(error.message || 'Unable to geocode this address', 'error');
    } finally {
      geocodeActionsInFlight.delete(orderId);
    }
  };
  ACTIONS.geocodeOrderAction = geocodeOrderAction;

  confirmSetLocationManual = async function (el) {
    try {
      const lat = Number(document.getElementById('sl_lat')?.value);
      const lng = Number(document.getElementById('sl_lng')?.value);
      if (!Number.isFinite(lat) || !Number.isFinite(lng)) throw new Error('Enter a valid latitude and longitude.');
      const order = state.orders.find(item => item.id === el.dataset.id);
      const orderId = order?.backendId || el.dataset.id;
      await setOrderLocationManual(orderId, lat, lng);
      await hydrateCanonicalWorkspace();
      closeSheet(); render(); toast('Location set', 'success');
    } catch (error) { toast(error.message || 'Unable to set location', 'error'); }
  };
  ACTIONS.confirmSetLocationManual = confirmSetLocationManual;

  // Grow V1 Flow 2 (A6): real narrow recovery action, replacing the S4-09
  // "not connected yet" reschedule stub. Reuses the same in-flight-guard/
  // idempotency-key pattern as every other real mutation here.
  const recoveryInFlight = new Set();
  confirmReschedule = async function (el) {
    const order = state.orders.find(item => item.id === el.dataset.id);
    const orderId = order?.backendId || el.dataset.id;
    if (recoveryInFlight.has(orderId)) return;
    const reason = document.getElementById('recov_reason')?.value;
    const note = document.getElementById('recov_note')?.value || '';
    const idempotencyKey = window.crypto?.randomUUID?.();
    if (!idempotencyKey) { toast('Unable to generate a secure request id in this browser.', 'error'); return; }
    recoveryInFlight.add(orderId);
    try {
      await initiateDeliveryRecovery(orderId, reason, note, idempotencyKey);
      await hydrateCanonicalWorkspace();
      closeSheet();
      toast('Order returned to planning', 'success');
      render();
    } catch (error) {
      toast(error.message || 'Unable to recover this delivery', 'error');
    } finally {
      recoveryInFlight.delete(orderId);
    }
  };
  ACTIONS.confirmReschedule = confirmReschedule;

  saveBusinessProfile = async function () {
    try {
      const values = {
        name: document.getElementById('bp_storeName')?.value.trim(),
        phone: document.getElementById('bp_phone')?.value.trim(),
        email: document.getElementById('bp_email')?.value.trim(),
        address: document.getElementById('bp_address')?.value.trim(),
        operatingArea: document.getElementById('bp_area')?.value.trim()
      };
      if (Object.values(values).some(value => !value)) throw new Error(t('completeRequiredFields'));
      const business = await updateBusinessProfile({
        businessId: state.businessId, ...values,
        requestId: window.crypto?.randomUUID?.() || null
      });
      state.storeName = business.name;
      state.businessPhone = business.phone;
      state.businessEmail = business.email;
      state.businessAddress = business.address;
      state.operatingArea = business.operating_area;
      state.businessProfileCompleted = true;
      syncNewAccountOnboarding();
      toast(t('businessProfileSaved'), 'success'); navigate('settings', {}, false);
    } catch (error) { toast(error.message || 'Unable to save business profile', 'error'); }
  };
  // The UI dispatcher stores handler references during the inline application
  // bootstrap, before this adapter is loaded. Replace those references as well
  // as the global functions so clicks cannot fall through to demo persistence.
  ACTIONS.wizSubmit = wizSubmit;
  ACTIONS.approveOrderAction = approveOrderAction;
  ACTIONS.confirmAssignRiderOrder = confirmAssignRiderOrder;
  ACTIONS.confirmDeactivateRider = confirmDeactivateRider;
  ACTIONS.saveBusinessProfile = saveBusinessProfile;
  // S4-07: real Team screen actions. Every mutation re-hydrates the Team
  // workspace and re-renders -- backend remains authoritative throughout,
  // this is purely a refresh-after-write pattern, not client-side state
  // fabrication.
  ACTIONS.openTeamScreen = async function () {
    try {
      await hydrateTeamWorkspace();
      navigate('team', {}, true);
    } catch (error) { toast(error.message || 'Unable to load Team.', 'error'); }
  };
  ACTIONS.confirmInviteTeamMember = async function () {
    try {
      const email = document.getElementById('tim_email')?.value.trim();
      const role = document.getElementById('tim_role')?.value;
      if (!email || !role) throw new Error(t('completeRequiredFields'));
      const result = await createTeamInvitation({ businessId: state.businessId, email, role });
      const link = `${inviteBaseUrl()}?type=team&token=${encodeURIComponent(result.token)}`;
      await hydrateTeamWorkspace();
      openSheet(renderInviteLinkSheet('Invite link ready', link));
      render();
    } catch (error) { toast(error.message || 'Unable to create invitation', 'error'); }
  };
  ACTIONS.confirmRevokeTeamInvitation = async function (el) {
    try {
      await revokeTeamInvitation(el.dataset.id);
      await hydrateTeamWorkspace(); render(); toast('Invitation revoked', 'success');
    } catch (error) { toast(error.message || 'Unable to revoke invitation', 'error'); }
  };
  ACTIONS.confirmInviteRiderReal = async function () {
    try {
      const name = document.getElementById('rid_name')?.value.trim();
      const phone = document.getElementById('rid_phone')?.value.trim();
      const email = document.getElementById('rid_email')?.value.trim();
      if (!name || !phone || !email) throw new Error(t('completeRequiredFields'));
      const result = await createRiderInvitation({ businessId: state.businessId, name, phone, email });
      const link = `${inviteBaseUrl()}?type=rider&token=${encodeURIComponent(result.token)}`;
      await hydrateTeamWorkspace();
      openSheet(renderInviteLinkSheet('Rider invite link ready', link));
      render();
    } catch (error) { toast(error.message || 'Unable to create Rider invitation', 'error'); }
  };
  ACTIONS.confirmRevokeRiderInvitation = async function (el) {
    try {
      await revokeRiderInvitation(el.dataset.id);
      await hydrateTeamWorkspace(); render(); toast('Invitation revoked', 'success');
    } catch (error) { toast(error.message || 'Unable to revoke invitation', 'error'); }
  };
  ACTIONS.confirmApprovePendingRider = async function (el) {
    try {
      await approvePendingRider(el.dataset.id);
      await hydrateCanonicalWorkspace(); await hydrateTeamWorkspace(); render(); toast('Rider approved', 'success');
    } catch (error) { toast(error.message || 'Unable to approve Rider', 'error'); }
  };
  ACTIONS.confirmRejectPendingRider = async function (el) {
    try {
      await deactivateRider(el.dataset.id);
      await hydrateCanonicalWorkspace(); await hydrateTeamWorkspace(); render(); toast('Rider request rejected', 'success');
    } catch (error) { toast(error.message || 'Unable to reject Rider', 'error'); }
  };
  // S4-08: real authoritative issue report. Success is reported ONLY after
  // the RPC itself succeeds and the canonical workspace has been re-hydrated
  // -- never a local-only status mutation, never a claim beyond what the
  // backend actually recorded (no "customer contacted", no "WhatsApp sent",
  // no "Rider notified" -- those never happened).
  const issueActionsInFlight = new Set();
  ACTIONS.confirmReportDeliveryIssue = async function (el) {
    const canonical = VENDOR_ISSUE_REASON_MAP[el.dataset.reason];
    if (!canonical) { toast('This issue type is not connected yet.', 'error'); return; }
    const order = state.orders.find(item => item.id === el.dataset.id);
    const orderId = order?.backendId || el.dataset.id;
    if (issueActionsInFlight.has(orderId)) return;
    issueActionsInFlight.add(orderId);
    try {
      await reportDeliveryIssue(orderId, canonical, null);
      await hydrateCanonicalWorkspace();
      if (!deliveryExecState.completedStops.includes(orderId)) deliveryExecState.completedStops.push(orderId);
      closeSheet();
      toast('Delivery issue reported.', 'success');
      render();
    } catch (error) {
      toast(error.message || 'Unable to report delivery issue', 'error');
    } finally {
      issueActionsInFlight.delete(orderId);
    }
  };
  ACTIONS.confirmManageTeamMember = async function (el) {
    try {
      const role = document.getElementById('mtm_role')?.value;
      const status = document.getElementById('mtm_status')?.value;
      await updateTeamMember({ businessId: state.businessId, userId: el.dataset.userid, role, status });
      await hydrateTeamWorkspace(); closeSheet(); render(); toast('Team member updated', 'success');
    } catch (error) { toast(error.message || 'Unable to update team member', 'error'); }
  };
  ACTIONS.openCustomerTracking = function (el) {
    const order = state.orders.find(item => item.id === el.dataset.id);
    if (!order?.trackingToken) return toast('Tracking link is unavailable for this browser session.', 'error');
    const trackingBase = location.hostname === 'vendor.cefflo.com' ? 'https://tracking.cefflo.com/' : '../customer/';
    window.open(`${trackingBase}?token=${encodeURIComponent(order.trackingToken)}`, '_blank', 'noopener');
  };
  if (api.session()?.access_token) {
    const restore = () => hydrateCanonicalWorkspace().then(() => {
      render();
      // S4-06.7 (P6): subscribe exactly once, after the first hydrate has
      // resolved the real businessId -- previously this adapter exported
      // `subscribe` but never actually called it, so no realtime channel
      // ever existed regardless of table scope.
      startRealtime();
    }).catch(error => console.error('[CEFFLO vendor adapter]', error));
    restore();
    setTimeout(restore, 1800);
  }
})();
