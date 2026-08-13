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
      p_longitude: input.longitude ?? null, p_items: input.items || []
    });
  }
  const assignRider = (orderId, riderId) => api.rpc('assign_rider', { p_order_id: orderId, p_rider_id: riderId });
  const listOrders = businessId => api.request(`/rest/v1/orders?business_id=eq.${encodeURIComponent(businessId)}&select=*&order=created_at.desc`);
  const listRiders = businessId => api.request(`/rest/v1/riders?business_id=eq.${encodeURIComponent(businessId)}&select=*&order=created_at.asc`);
  const listRatings = orderIds => orderIds.length
    ? api.request(`/rest/v1/ratings?order_id=in.(${orderIds.map(encodeURIComponent).join(',')})&select=*`)
    : Promise.resolve([]);

  function mapOrder(row) {
    return {
      id: row.public_ref, backendId: row.id, publicRef: row.public_ref, customer: row.customer_name, customerName: row.customer_name,
      phone: row.customer_phone, customerPhone: row.customer_phone, address: row.delivery_address,
      note: row.notes || '', notes: row.notes || '', items: row.items || [], riderId: row.assigned_rider_id,
      status: statusToUi[row.delivery_status] || row.delivery_status, backendStatus: row.delivery_status,
      total: '0.00', payment: row.payment_status || 'Pending',
      trackingToken: localStorage.getItem(`cefflo_tracking_token_${row.id}`),
      delivered: row.delivery_status === 'delivered', completedAt: row.completed_at,
      time: row.completed_at ? new Date(row.completed_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : null,
      createdAt: row.created_at, updatedAt: row.updated_at, activity: []
    };
  }
  function mapRider(row) {
    return { id: row.id, name: row.name, phone: row.phone, plate: row.vehicle_plate || '—', status: row.status, zone: 'Unassigned' };
  }

  async function hydrateCanonicalWorkspace() {
    if (!api.session()?.access_token) return false;
    const rows = await businesses();
    const selected = rows.find(item => item.business_id === localStorage.getItem('cefflo_active_business_id')) || rows[0];
    if (!selected) return false;
    state.businessId = selected.business_id;
    state.storeName = selected.business_name;
    localStorage.setItem('cefflo_active_business_id', selected.business_id);
    const orders = await listOrders(selected.business_id);
    const [riders, ratings] = await Promise.all([listRiders(selected.business_id), listRatings(orders.map(order => order.id))]);
    state.riders = riders.map(mapRider);
    state.orders = orders.map(mapOrder);
    const ratingOrderIds = new Set(ratings.map(item => item.order_id));
    state.orders.forEach(order => { order.ratingSubmitted = ratingOrderIds.has(order.backendId); order.riderName = state.riders.find(r => r.id === order.riderId)?.name || null; });
    state.deliverySessions = [];
    state.deliveryStops = [];
    state.riderAssignments = [];
    state.zones = [];
    state.issues = [];
    state.orderStatusHistory = [];
    backendState.mode = 'remote'; backendState.status = 'connected'; backendState.lastSyncedAt = new Date().toISOString();
    persistOperationalStoreLocalOnly();
    return true;
  }

  function subscribe(businessId, refresh) {
    const client = window.supabase?.createClient(api.config.supabaseUrl, api.config.supabaseAnonKey, {
      global: { headers: { Authorization: `Bearer ${api.session()?.access_token || api.config.supabaseAnonKey}` } }
    });
    if (!client) return () => {};
    const channel = client.channel(`vendor:${businessId}`).on('postgres_changes', {
      event: '*', schema: 'public', table: 'orders', filter: `business_id=eq.${businessId}`
    }, refresh).subscribe();
    return () => client.removeChannel(channel);
  }

  window.CEFFLO_VENDOR = Object.freeze({ businesses, createDelivery, assignRider, listOrders, listRiders, listRatings, hydrate: hydrateCanonicalWorkspace, subscribe });
  hydrateOperationalStateFromBackend = hydrateCanonicalWorkspace;
  syncOperationalStateToBackend = async () => true;

  wizSubmit = async function () {
    try {
      const created = await createDelivery({ businessId: state.businessId, customerName: wizardState.data.name,
        customerPhone: wizardState.data.phone, address: wizardState.data.address, notes: wizardState.data.note || '', items: wizardState.data.items });
      localStorage.setItem(`cefflo_tracking_token_${created.order.id}`, created.tracking_token);
      await hydrateCanonicalWorkspace();
      toast(tf('orderCreatedSuccess', { id: created.order.public_ref }), 'success');
      navigate('orders', { tab: 'ongoing' }, false);
    } catch (error) { toast(error.message || 'Unable to create delivery', 'error'); }
  };

  confirmAssignRiderOrder = async function (el) {
    try {
      const order = state.orders.find(item => item.id === el.dataset.orderid);
      await assignRider(order?.backendId || el.dataset.orderid, el.dataset.riderid);
      await hydrateCanonicalWorkspace(); closeSheet(); toast('Rider assigned', 'success'); render();
    } catch (error) { toast(error.message || 'Unable to assign rider', 'error'); }
  };
  // The UI dispatcher stores handler references during the inline application
  // bootstrap, before this adapter is loaded. Replace those references as well
  // as the global functions so clicks cannot fall through to demo persistence.
  ACTIONS.wizSubmit = wizSubmit;
  ACTIONS.confirmAssignRiderOrder = confirmAssignRiderOrder;
  ACTIONS.openCustomerTracking = function (el) {
    const order = state.orders.find(item => item.id === el.dataset.id);
    if (!order?.trackingToken) return toast('Tracking link is unavailable for this browser session.', 'error');
    const trackingBase = location.hostname === 'vendor.cefflo.com' ? 'https://track.cefflo.com/' : '../customer/';
    window.open(`${trackingBase}?token=${encodeURIComponent(order.trackingToken)}`, '_blank', 'noopener');
  };
  if (api.session()?.access_token) {
    const restore = () => hydrateCanonicalWorkspace().then(() => render()).catch(error => console.error('[CEFFLO vendor adapter]', error));
    restore();
    setTimeout(restore, 1800);
  }
})();
