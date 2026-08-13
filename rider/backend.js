(function () {
  const api = window.CEFFLO;
  const uiStatus = status => ({ created: 'ready_for_pickup', ready_for_pickup: 'ready_for_pickup', picked_up: 'picked_up', out_for_delivery: 'out_for_delivery', arrived: 'out_for_delivery', delivered: 'delivered' }[status] || status);
  const assignments = () => api.request('/rest/v1/rider_assignments?select=*,orders(*)');
  const orders = () => api.request('/rest/v1/orders?select=*&order=delivery_sequence.asc.nullslast,created_at.asc');
  const transition = (orderId, next) => api.rpc('rider_transition', { p_order_id: orderId, p_next: next, p_idempotency_key: crypto.randomUUID() });
  async function complete(orderId, file, note) {
    const path = await api.uploadPod(orderId, file);
    return api.rpc('complete_delivery', { p_order_id: orderId, p_pod_path: path, p_note: note || '', p_idempotency_key: crypto.randomUUID() });
  }
  function mapOrder(row, index) {
    return { id: row.public_ref, backendId: row.id, publicRef: row.public_ref, customer: row.customer_name, phone: row.customer_phone,
      address: row.delivery_address, items: Array.isArray(row.items) ? row.items.length : 0, note: row.notes || '',
      status: uiStatus(row.delivery_status), backendStatus: row.delivery_status, sequence: row.delivery_sequence || index + 1,
      delivered: row.delivery_status === 'delivered', deliveredTime: row.completed_at ? new Date(row.completed_at) : null,
      lat: row.latitude ?? 3.139, lng: row.longitude ?? 101.6869, zone: 'Assigned route' };
  }
  async function hydrateOrders() {
    const rows = await orders();
    appState.orders = rows.map(mapOrder);
    const firstPending = appState.orders.findIndex(order => !order.delivered);
    appState.currentStopIndex = firstPending === -1 ? Math.max(appState.orders.length - 1, 0) : firstPending;
    appState.pickupIndex = firstPending === -1 ? 0 : firstPending;
    appState.activeAssignment = { ...(appState.activeAssignment || {}), zone: appState.orders.length ? 'Assigned route' : 'No active assignment' };
    localStorage.setItem('cefflo_rider_orders', JSON.stringify(rows));
    return appState.orders;
  }
  async function authenticatedRider() {
    const user = await api.request('/auth/v1/user');
    const rows = await api.request(`/rest/v1/riders?auth_user_id=eq.${encodeURIComponent(user.id)}&status=eq.active&select=*`);
    if (!rows[0]) { await api.logout(); throw new Error('ACCOUNT_NOT_APPROVED'); }
    return { user, rider: rows[0] };
  }
  async function login({ email, phone, password }) {
    await api.login(email || phone, password);
    const identity = await authenticatedRider();
    const rows = await hydrateOrders();
    return { user: { applicationStatus: 'approved', email: identity.user.email || null, phone: identity.rider.phone || phone || null, name: identity.rider.name, plate: identity.rider.vehicle_plate || '—' }, assignments: rows };
  }
  window.CEFFLO_AUTH = { login };
  window.CEFFLO_RIDER = Object.freeze({ assignments, orders, transition, complete, hydrateOrders });

  doLogin = async function () {
    const identifier = document.getElementById('li-phone').value.trim();
    const password = document.getElementById('li-pass').value;
    const feedback = document.getElementById('login-feedback');
    const button = document.querySelector('#screen-login .btn.btn-purple');
    feedback.textContent = ''; feedback.classList.remove('show'); button.disabled = true; button.textContent = 'Signing in...';
    try {
      const isEmail = identifier.includes('@');
      const digits = identifier.replace(/\D/g, '');
      const phone = digits.startsWith('60') ? `+60${digits.slice(2)}` : `+60${digits.replace(/^0/, '')}`;
      const result = await login({ email: isEmail ? identifier : null, phone: isEmail ? null : phone, password });
      appState.currentUser = result.user; localStorage.setItem('cefflo_rider_user', JSON.stringify(result.user)); localStorage.setItem('cefflo_session', '1');
      showScreen('screen-home'); renderHome(); renderProfilePage();
    } catch (error) { feedback.textContent = error.message || 'Unable to sign in. Check your credentials.'; feedback.classList.add('show'); }
    finally { button.disabled = false; button.textContent = 'Log In'; }
  };
  confirmPickup = async function () {
    const order = appState.orders[appState.pickupIndex];
    try {
      if (order.backendStatus === 'created') await transition(order.backendId, 'ready_for_pickup');
      await transition(order.backendId, 'picked_up'); order.backendStatus = 'picked_up'; order.status = 'picked_up';
      closeModal('modal-confirmPickup');
      if (appState.pickupIndex < appState.orders.length - 1) { appState.pickupIndex++; renderPickupScreen(); }
      else { renderAllPickedList(); showScreen('screen-allpicked'); }
    } catch (error) { showToast(error.message, 'error'); }
  };
  startDelivery = async function () {
    try { for (const order of appState.orders.filter(o => !o.delivered && o.backendStatus === 'picked_up')) { await transition(order.backendId, 'out_for_delivery'); order.backendStatus = 'out_for_delivery'; order.status = 'out_for_delivery'; }
      const firstPending = appState.orders.findIndex(order => !order.delivered);
      appState.sessionStart = new Date(); appState.currentStopIndex = firstPending === -1 ? Math.max(appState.orders.length - 1, 0) : firstPending; selectedRouteStop = appState.currentStopIndex; renderRouteOverview(); showScreen('screen-route');
    } catch (error) { showToast(error.message, 'error'); }
  };
  arriveAtStop = async function () {
    const order = appState.orders[appState.currentStopIndex];
    try { if (order.backendStatus === 'out_for_delivery') await transition(order.backendId, 'arrived'); order.backendStatus = 'arrived'; order.arrivalState = 'arrived'; renderArrivedPod(); showScreen('screen-arrivedpod'); }
    catch (error) { showToast(error.message, 'error'); }
  };
  const basePodSelected = onPodPhotoSelected;
  onPodPhotoSelected = function (input) { appState.podFile = input.files?.[0] || null; basePodSelected(input); };
  yesUsePhoto = async function () {
    const order = appState.orders[appState.currentStopIndex];
    try {
      if (!appState.podFile) throw new Error('Please take a POD photo first.');
      await complete(order.backendId, appState.podFile, document.getElementById('pod-note').value);
      order.delivered = true; order.backendStatus = 'delivered'; order.status = 'delivered'; order.deliveredTime = new Date(); order.podPhoto = appState.podPhoto;
      if (appState.currentStopIndex < appState.orders.length - 1) { appState.currentStopIndex++; renderNextStop(); showScreen('screen-nextstop'); }
      else { renderSummary(); showScreen('screen-summary'); }
    } catch (error) { showToast(error.message, 'error'); }
  };
  if (api.session()?.access_token) {
    setTimeout(() => authenticatedRider().then(hydrateOrders).then(() => { renderHome(); renderProfilePage(); showScreen('screen-home'); })
      .catch(error => { api.logout(); localStorage.removeItem('cefflo_session'); showScreen('screen-login'); console.error('[CEFFLO rider restore]', error); }), 1800);
  } else localStorage.removeItem('cefflo_session');
})();
