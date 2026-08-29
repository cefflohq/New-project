(function () {
  const api = window.CEFFLO;
  const ACTIVE_RIDER_KEY = 'cefflo_active_rider_id';
  const uiStatus = status => ({ created: 'ready_for_pickup', ready_for_pickup: 'ready_for_pickup', picked_up: 'picked_up', out_for_delivery: 'out_for_delivery', arrived: 'out_for_delivery', delivered: 'delivered' }[status] || status);
  // S4-07.3a: explicitly scoped to the active Rider relationship -- RLS
  // (is_current_rider) remains an identity-wide ownership ceiling only, not
  // active-context workflow scoping, so once one identity can legitimately
  // hold more than one Rider relationship, an unfiltered query would mix
  // every business's orders into one list. Nested embed (orders ->
  // delivery_stops -> rider_assignments) unchanged otherwise -- every order
  // carries its backend-authoritative assignment status/accepted_at AND the
  // real sequencing fields, no local assumption ever made.
  const orders = riderId => api.request(`/rest/v1/orders?assigned_rider_id=eq.${encodeURIComponent(riderId)}&select=*,delivery_stops(id,sequence,sequence_locked_at,assignment_id,rider_assignments(status,accepted_at))&order=created_at.asc`);
  // Explicitly scoped to the active business, same reasoning as orders()
  // above -- sessions_rider/is_session_rider remains a ceiling; the filter
  // is what actually prevents Business A/B Wave mixing in the UI.
  const sessions = businessId => api.request(`/rest/v1/delivery_sessions?business_id=eq.${encodeURIComponent(businessId)}&select=id,name`);
  const transition = (riderId, orderId, next) => api.rpc('rider_transition', { p_rider_id: riderId, p_order_id: orderId, p_next: next, p_idempotency_key: crypto.randomUUID() });
  const acceptAssignment = (riderId, orderId) => api.rpc('accept_assignment', { p_rider_id: riderId, p_order_id: orderId });
  const declineAssignment = (riderId, orderId) => api.rpc('decline_assignment', { p_rider_id: riderId, p_order_id: orderId });
  const acceptRun = (riderId, sessionId) => api.rpc('accept_run', { p_rider_id: riderId, p_delivery_session_id: sessionId });
  const declineRun = (riderId, sessionId) => api.rpc('decline_run', { p_rider_id: riderId, p_delivery_session_id: sessionId });
  const saveRunSequence = (riderId, sessionId, orderedOrderIds) => api.rpc('save_run_sequence', { p_rider_id: riderId, p_delivery_session_id: sessionId, p_ordered_order_ids: orderedOrderIds });
  const startPickupRun = (riderId, sessionId) => api.rpc('start_pickup_run', { p_rider_id: riderId, p_delivery_session_id: sessionId });
  const startRunDelivery = (riderId, sessionId) => api.rpc('start_run_delivery', { p_rider_id: riderId, p_delivery_session_id: sessionId });
  async function complete(riderId, orderId, file, note) {
    // Same activeRiderId threaded through both calls -- never independently
    // derived, so the upload's path-embedded context and the completion
    // RPC's explicit context can never disagree.
    const path = await api.uploadPod(riderId, orderId, file);
    return api.rpc('complete_delivery', { p_rider_id: riderId, p_order_id: orderId, p_pod_path: path, p_note: note || '', p_idempotency_key: crypto.randomUUID() });
  }
  function mapOrder(row) {
    const stop = Array.isArray(row.delivery_stops) ? row.delivery_stops[0] : row.delivery_stops;
    const assignment = stop && (Array.isArray(stop.rider_assignments) ? stop.rider_assignments[0] : stop.rider_assignments);
    return { id: row.public_ref, backendId: row.id, publicRef: row.public_ref, customer: row.customer_name, phone: row.customer_phone,
      address: row.delivery_address, items: Array.isArray(row.items) ? row.items.length : 0, note: row.notes || '',
      status: uiStatus(row.delivery_status), backendStatus: row.delivery_status,
      // Real S4-06.2 sequencing only -- the legacy orders.delivery_sequence
      // column is never read. sequence is null until Plan Route's Save
      // Sequence succeeds; sequenceLocked only becomes true after Start
      // Delivery locks it (S4-06.2/.4's authoritative fields).
      sequence: stop ? stop.sequence : null, sequenceLocked: Boolean(stop && stop.sequence_locked_at),
      deliverySessionId: row.delivery_session_id,
      delivered: row.delivery_status === 'delivered', deliveredTime: row.completed_at ? new Date(row.completed_at) : null,
      // No fabricated coordinate fallback -- lat/lng stay null when the
      // order genuinely has none, so map/navigate code can honestly detect
      // and handle that case instead of silently pointing somewhere fake.
      lat: row.latitude ?? null, lng: row.longitude ?? null,
      assignmentStatus: assignment ? assignment.status : null, assignmentAcceptedAt: assignment ? assignment.accepted_at : null };
  }
  // Real canonical hierarchy: Wave (delivery_session_id) -> this Rider's own
  // assignments/stops -- derived, never a new "Run" table. A Rider whose
  // assignments span multiple Waves gets one independent group per Wave;
  // they are never silently merged into one list. appState.orders is
  // already scoped to the active Rider relationship by hydrateOrders(), so
  // this never mixes across businesses either.
  function riderRuns() {
    const groups = new Map();
    appState.orders.forEach(order => {
      const key = order.deliverySessionId || 'unassigned';
      if (!groups.has(key)) {
        // Real Wave name if genuinely loaded (appState.sessionNames, from
        // hydrateOrders); never fabricated -- stays null if this
        // session's name could not be read for any reason, and the UI
        // already falls back to a factual "N orders" label in that case.
        const waveName = (appState.sessionNames && order.deliverySessionId) ? (appState.sessionNames[order.deliverySessionId] || null) : null;
        groups.set(key, { sessionId: order.deliverySessionId, waveName, orders: [] });
      }
      groups.get(key).orders.push(order);
    });
    return [...groups.values()];
  }
  async function hydrateOrders() {
    if (!appState.activeRiderId) return (appState.orders = []);
    const rows = await orders(appState.activeRiderId);
    appState.orders = rows.map(mapOrder);
    try {
      const sessionRows = appState.activeBusinessId ? await sessions(appState.activeBusinessId) : [];
      appState.sessionNames = Object.fromEntries(sessionRows.map(s => [s.id, s.name]));
    } catch (error) {
      // Never block hydration on this -- the UI already handles a missing
      // Wave name honestly (factual order-count fallback).
      appState.sessionNames = appState.sessionNames || {};
    }
    const firstPending = appState.orders.findIndex(order => !order.delivered);
    appState.currentStopIndex = firstPending === -1 ? Math.max(appState.orders.length - 1, 0) : firstPending;
    appState.pickupIndex = firstPending === -1 ? 0 : firstPending;
    localStorage.setItem('cefflo_rider_orders', JSON.stringify(rows));
    return appState.orders;
  }

  // ===== S4-07.3a: multi-business Rider identity/context =====
  // localStorage persistence is UX continuity only, never authorization --
  // every RPC independently re-validates p_rider_id server-side regardless
  // of what this device remembers.
  function setActiveRiderContext(riderRow) {
    appState.activeRiderId = riderRow.id;
    appState.activeBusinessId = riderRow.business_id;
    appState.currentRiderRelationship = riderRow;
    localStorage.setItem(ACTIVE_RIDER_KEY, riderRow.id);
  }
  clearActiveRiderContext = function () {
    appState.activeRiderId = null; appState.activeBusinessId = null; appState.currentRiderRelationship = null;
    localStorage.removeItem(ACTIVE_RIDER_KEY);
  };
  // Fetches every riders row for this auth identity (no status filter --
  // this is the one read that must NOT be scoped to "the active
  // relationship," since it is how a relationship gets selected in the
  // first place) and classifies it. Zero active relationships is still the
  // real ACCOUNT_NOT_APPROVED gate, now correctly considering every
  // business the identity has ever been invited to, not just one.
  async function classifyRiderRelationships() {
    const user = await api.request('/auth/v1/user');
    const rows = await api.request(`/rest/v1/riders?auth_user_id=eq.${encodeURIComponent(user.id)}&select=*`);
    const active = rows.filter(r => r.status === 'active');
    const pending = rows.filter(r => r.status === 'pending');
    if (!active.length) { await api.logout(); throw new Error('ACCOUNT_NOT_APPROVED'); }
    let businessNameById = {};
    const businessIds = [...new Set(rows.map(r => r.business_id))];
    if (businessIds.length) {
      try {
        const businesses = await api.request(`/rest/v1/businesses?id=in.(${businessIds.map(encodeURIComponent).join(',')})&select=id,name`);
        businessNameById = Object.fromEntries(businesses.map(b => [b.id, b.name]));
      } catch (error) {
        businessNameById = {}; // Team screen falls back to a factual placeholder rather than blocking on this.
      }
    }
    return { user, all: rows, active, pending, businessNameById };
  }
  function findPersistedActiveRider(active) {
    const savedId = localStorage.getItem(ACTIVE_RIDER_KEY);
    if (!savedId) return null;
    return active.find(r => r.id === savedId) || null;
  }
  // Auto-selects when exactly one active relationship exists (zero UI
  // friction, byte-identical outcome to the pre-S4-07.3a single-business
  // case). Otherwise re-uses a still-valid persisted selection silently; a
  // stale/removed/no-longer-active persisted value is discarded, never
  // trusted, and the caller is told selection is required.
  async function resolveActiveRiderContext() {
    const identity = await classifyRiderRelationships();
    appState.riderRelationships = identity;
    if (identity.active.length === 1) {
      setActiveRiderContext(identity.active[0]);
      return { needsSelection: false, identity };
    }
    const persisted = findPersistedActiveRider(identity.active);
    if (persisted) {
      setActiveRiderContext(persisted);
      return { needsSelection: false, identity };
    }
    clearActiveRiderContext();
    return { needsSelection: true, identity };
  }
  function riderUserFromRelationship(identity, riderRow) {
    return { applicationStatus: 'approved', email: identity.user.email || null, phone: riderRow.phone || null, name: riderRow.name, plate: riderRow.vehicle_plate || '—' };
  }

  async function authenticatedRider() {
    // Retained for compatibility with any caller expecting the pre-S4-07.3a
    // single-relationship shape; internally now goes through the same
    // classify+resolve path everything else uses.
    const { identity } = await resolveActiveRiderContext();
    return { user: identity.user, rider: appState.currentRiderRelationship };
  }
  async function login({ email, phone, password }) {
    await api.login(email || phone, password);
    const { needsSelection, identity } = await resolveActiveRiderContext();
    if (needsSelection) {
      return { needsSelection: true, identity };
    }
    const rows = await hydrateOrders();
    return { needsSelection: false, user: riderUserFromRelationship(identity, appState.currentRiderRelationship), assignments: rows };
  }
  window.CEFFLO_AUTH = { login };
  window.CEFFLO_RIDER = Object.freeze({
    orders, transition, complete, acceptAssignment, declineAssignment, hydrateOrders,
    acceptRun, declineRun, saveRunSequence, startPickupRun, startRunDelivery, riderRuns,
    classifyRiderRelationships, resolveActiveRiderContext, setActiveRiderContext, clearActiveRiderContext
  });

  // In-flight guard shared by both actions: prevents duplicate taps firing a
  // second request for the same order while the first is still pending.
  const assignmentActionsInFlight = new Set();
  async function runAssignmentAction(orderId, action, successMessage) {
    if (assignmentActionsInFlight.has(orderId)) return;
    assignmentActionsInFlight.add(orderId);
    try {
      await action(appState.activeRiderId, orderId);
      await hydrateOrders();
      renderHome();
      showToast(successMessage, 'success');
    } catch (error) {
      showToast(error.message || 'Unable to update assignment', 'error');
    } finally {
      assignmentActionsInFlight.delete(orderId);
    }
  }
  acceptAssignmentAction = orderId => runAssignmentAction(orderId, acceptAssignment, 'Assignment accepted');
  declineAssignmentAction = orderId => runAssignmentAction(orderId, declineAssignment, 'Assignment declined');

  // ===== Run-level Accept/Decline (S4-06.4) -- the PRIMARY control for a
  // multi-order Run; per-order accept/decline above remains compatible and
  // unbroken as the secondary path. =====
  const runActionsInFlight = new Set();
  async function runSessionAction(sessionId, action, successMessage, onSuccess) {
    if (runActionsInFlight.has(sessionId)) return;
    runActionsInFlight.add(sessionId);
    try {
      await action(appState.activeRiderId, sessionId);
      await hydrateOrders();
      showToast(successMessage, 'success');
      onSuccess();
    } catch (error) {
      showToast(error.message || 'Unable to update this Run', 'error');
    } finally {
      runActionsInFlight.delete(sessionId);
    }
  }
  // Accept Run advances directly into Plan Route (the Founder-locked flow:
  // Assigned -> Accept Run -> Plan Route), not back to Home.
  acceptRunAction = sessionId => runSessionAction(sessionId, acceptRun, 'Run accepted', () => enterRun(sessionId));
  declineRunAction = sessionId => runSessionAction(sessionId, declineRun, 'Run declined', () => renderHome());

  function sortBySequence(list) {
    return [...list].sort((a, b) => (a.sequence ?? Infinity) - (b.sequence ?? Infinity));
  }
  // Canonical hierarchy only: Wave (delivery_session_id) -> this Rider's
  // own non-declined stops in that Wave. Never mixes across Waves.
  function activeRunOrders() {
    return sortBySequence(appState.orders.filter(o => o.deliverySessionId === appState.activeRunSessionId && o.assignmentStatus !== 'declined'));
  }
  function refreshActiveRunOrders() { appState.activeRunOrders = activeRunOrders(); return appState.activeRunOrders; }
  window.CEFFLO_RIDER_RUN = Object.freeze({ activeRunOrders, refreshActiveRunOrders, sortBySequence });

  // ===== Plan Route: explicit Save Sequence. Local drag order is planning
  // state only -- never authoritative until save_run_sequence succeeds. =====
  saveSequenceAction = async function () {
    const orderIds = appState.planRouteOrder.map(o => o.backendId);
    try {
      await saveRunSequence(appState.activeRiderId, appState.activeRunSessionId, orderIds);
      await hydrateOrders();
      appState.planRouteOrder = refreshActiveRunOrders();
      showToast('Sequence saved', 'success');
    } catch (error) {
      // Revert to the last backend-confirmed sequence -- never claim saved.
      appState.planRouteOrder = refreshActiveRunOrders();
      showToast(error.message || 'Unable to save sequence', 'error');
    }
    renderRouteOverview();
  };

  // ===== Start Pickup: factual event only -- never marks any order
  // picked_up. =====
  startPickupRunAction = async function () {
    try {
      await startPickupRun(appState.activeRiderId, appState.activeRunSessionId);
      enterPickupChecklist();
    } catch (error) { showToast(error.message || 'Unable to start pickup', 'error'); }
  };

  // ===== Pickup Checklist: unordered, independent two-hop transition per
  // order, matching the existing real contract exactly. =====
  const pickupActionsInFlight = new Set();
  pickupOrderAction = async function (orderId) {
    if (pickupActionsInFlight.has(orderId)) return;
    pickupActionsInFlight.add(orderId);
    try {
      const order = appState.orders.find(o => o.backendId === orderId);
      if (order && order.backendStatus === 'created') await transition(appState.activeRiderId, orderId, 'ready_for_pickup');
      await transition(appState.activeRiderId, orderId, 'picked_up');
      await hydrateOrders();
      refreshActiveRunOrders();
    } catch (error) {
      // Partial two-hop failure (ready_for_pickup succeeded, picked_up did
      // not, or vice versa): refresh real state rather than assume either
      // fact locally -- a retry safely resumes since both hops are
      // themselves idempotent no-ops once already reached.
      await hydrateOrders().catch(() => {});
      refreshActiveRunOrders();
      showToast(error.message || 'Unable to confirm pickup', 'error');
    } finally {
      pickupActionsInFlight.delete(orderId);
      renderPickupChecklist();
    }
  };

  // ===== S4-07.3a Team selection ("Choose Team" / "Switch Team") =====
  function teamPickerRowHtml(row, businessNameById, opts) {
    const name = businessNameById[row.business_id] || 'Business';
    const isActiveContext = opts.currentActiveId === row.id;
    return `<div class="pick-list-row" style="cursor:pointer;${isActiveContext ? 'opacity:.6;' : ''}" onclick="${opts.onClick}('${row.id}')">
      <span class="nm">${name}</span>${isActiveContext ? '<span class="ck">&#10003;</span>' : ''}
    </div>`;
  }
  function renderChooseTeamModal(identity, opts = {}) {
    const onClick = opts.forSwitch ? 'switchToRiderContext' : 'selectTeamAndContinue';
    const content = document.getElementById('choose-team-content');
    if (!content) return;
    const activeRows = identity.active.map(row => teamPickerRowHtml(row, identity.businessNameById, { onClick, currentActiveId: appState.activeRiderId })).join('');
    const pendingRows = identity.pending.map(row => `
      <div class="pick-list-row" style="opacity:.55;cursor:default;">
        <span class="nm">${identity.businessNameById[row.business_id] || 'Business'}</span>
        <span class="oid" style="font-size:11px;">Pending approval</span>
      </div>`).join('');
    content.innerHTML = `${activeRows}${pendingRows}` || '<p class="empty-sub">No teams available.</p>';
    openModal('modal-chooseTeam');
  }
  // Initial mandatory selection (login-time, more than one active
  // relationship, no valid persisted selection).
  selectTeamAndContinue = async function (riderId) {
    const row = (appState.riderRelationships?.active || []).find(r => r.id === riderId);
    if (!row) return;
    setActiveRiderContext(row);
    closeModal('modal-chooseTeam');
    try {
      const rows = await hydrateOrders();
      appState.currentUser = riderUserFromRelationship(appState.riderRelationships, row);
      localStorage.setItem('cefflo_rider_user', JSON.stringify(appState.currentUser));
      localStorage.setItem('cefflo_session', '1');
      showScreen('screen-home'); renderHome(); renderProfilePage();
    } catch (error) { showToast(error.message || 'Unable to load your Team.', 'error'); }
  };
  // Voluntary later switch (Profile / Account area) -- only ever offered
  // when more than one active relationship exists. Clears stale run/order
  // UI state and performs a fresh scoped hydrate before returning Home.
  openSwitchTeam = async function () {
    try {
      const identity = await classifyRiderRelationships();
      appState.riderRelationships = identity;
      if (identity.active.length < 2) { showToast('You have only one active Team.', 'warning'); return; }
      renderChooseTeamModal(identity, { forSwitch: true });
    } catch (error) { showToast(error.message || 'Unable to load your Teams.', 'error'); }
  };
  switchToRiderContext = async function (riderId) {
    const row = (appState.riderRelationships?.active || []).find(r => r.id === riderId);
    if (!row) return;
    if (appState.activeRiderId === row.id) { closeModal('modal-chooseTeam'); return; }
    setActiveRiderContext(row);
    appState.activeRunSessionId = null;
    appState.planRouteOrder = [];
    appState.orders = [];
    closeModal('modal-chooseTeam');
    try {
      appState.currentUser = riderUserFromRelationship(appState.riderRelationships, row);
      localStorage.setItem('cefflo_rider_user', JSON.stringify(appState.currentUser));
      await hydrateOrders();
      renderHome(); renderProfilePage();
      showScreen('screen-home');
      showToast(`Switched to ${appState.riderRelationships.businessNameById[row.business_id] || 'selected Team'}`, 'success');
    } catch (error) { showToast(error.message || 'Unable to switch Team.', 'error'); }
  };

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
      if (result.needsSelection) {
        renderChooseTeamModal(result.identity, { forSwitch: false });
        return;
      }
      appState.currentUser = result.user; localStorage.setItem('cefflo_rider_user', JSON.stringify(result.user)); localStorage.setItem('cefflo_session', '1');
      showScreen('screen-home'); renderHome(); renderProfilePage();
    } catch (error) { feedback.textContent = error.message || 'Unable to sign in. Check your credentials.'; feedback.classList.add('show'); }
    finally { button.disabled = false; button.textContent = 'Log In'; }
  };
  // confirmPickup (the sequential wizard's per-tap handler) is retired from
  // the live flow -- bypassed by the new unordered pickupOrderAction above,
  // reachable only from the checklist. Left defined, unreferenced by any
  // live control, matching the project's established "bypass, don't
  // delete" precedent for superseded mock/legacy behavior.

  // Start Delivery: exactly one start_run_delivery call. The former
  // per-order out_for_delivery loop is removed entirely -- no order's
  // delivery_status is touched here at all; the per-stop out_for_delivery
  // transition now happens at "Start This Stop" (see startSelectedRouteStop
  // below), matching the real per-stop lifecycle instead of a bulk
  // upfront approximation.
  startDelivery = async function () {
    try {
      await startRunDelivery(appState.activeRiderId, appState.activeRunSessionId);
      await hydrateOrders();
      const stops = refreshActiveRunOrders();
      const firstPending = stops.findIndex(order => !order.delivered);
      appState.sessionStart = new Date();
      appState.currentStopIndex = firstPending === -1 ? Math.max(stops.length - 1, 0) : firstPending;
      selectedRouteStop = appState.currentStopIndex;
      renderRouteOverview(); showScreen('screen-route');
    } catch (error) { showToast(error.message || 'Unable to start delivery', 'error'); }
  };
  // Start This Stop: the real out_for_delivery transition for the specific
  // current stop, fired at the moment the Rider begins heading to it --
  // not fabricated upfront for the whole Run. Backend's own sequential
  // enforcement (once locked) rejects this if an earlier stop is
  // incomplete, exactly matching Delivery Run's "current stop only" UI.
  startSelectedRouteStop = async function () {
    if (selectedRouteStop !== appState.currentStopIndex) { showToast('Complete the current stop first.', 'warning'); return; }
    const stops = refreshActiveRunOrders();
    const order = stops[appState.currentStopIndex];
    if (!order) return;
    try {
      if (order.backendStatus === 'picked_up') await transition(appState.activeRiderId, order.backendId, 'out_for_delivery');
      await hydrateOrders(); refreshActiveRunOrders();
      renderActiveDelivery(); showScreen('screen-activedelivery');
    } catch (error) { showToast(error.message || 'Unable to start this stop', 'error'); }
  };
  arriveAtStop = async function () {
    const stops = refreshActiveRunOrders();
    const order = stops[appState.currentStopIndex];
    if (!order) return;
    try {
      if (order.backendStatus === 'out_for_delivery') await transition(appState.activeRiderId, order.backendId, 'arrived');
      await hydrateOrders(); refreshActiveRunOrders();
      renderArrivedPod(); showScreen('screen-arrivedpod');
    } catch (error) { showToast(error.message || 'Unable to confirm arrival', 'error'); }
  };
  const basePodSelected = onPodPhotoSelected;
  onPodPhotoSelected = function (input) { appState.podFile = input.files?.[0] || null; basePodSelected(input); };
  yesUsePhoto = async function () {
    const stops = refreshActiveRunOrders();
    const order = stops[appState.currentStopIndex];
    if (!order) return;
    try {
      if (!appState.podFile) throw new Error('Please take a POD photo first.');
      await complete(appState.activeRiderId, order.backendId, appState.podFile, document.getElementById('pod-note').value);
      await hydrateOrders();
      const updated = refreshActiveRunOrders();
      if (appState.currentStopIndex < updated.length - 1) { appState.currentStopIndex++; renderNextStop(); showScreen('screen-nextstop'); }
      else { renderSummary(); showScreen('screen-summary'); }
    } catch (error) { showToast(error.message || 'Unable to confirm delivery', 'error'); }
  };
  if (api.session()?.access_token) {
    setTimeout(() => resolveActiveRiderContext().then(({ needsSelection, identity }) => {
      if (needsSelection) {
        renderProfilePage();
        showScreen('screen-login');
        renderChooseTeamModal(identity, { forSwitch: false });
        return;
      }
      appState.currentUser = riderUserFromRelationship(identity, appState.currentRiderRelationship);
      localStorage.setItem('cefflo_rider_user', JSON.stringify(appState.currentUser));
      return hydrateOrders().then(() => { renderHome(); renderProfilePage(); showScreen('screen-home'); });
    }).catch(error => { api.logout(); localStorage.removeItem('cefflo_session'); clearActiveRiderContext(); showScreen('screen-login'); console.error('[CEFFLO rider restore]', error); }), 1800);
  } else localStorage.removeItem('cefflo_session');
})();
