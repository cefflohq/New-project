(function () {
  const api = window.CEFFLO;
  const token = new URLSearchParams(location.search).get('token');

  // D-66 supersedes the 2B.3 "never on a timer" rule only while the page is
  // visible and the order is trackable (see the coalescing gate below).
  let isRefreshing = false;
  let lastRefreshAt = -Infinity;

  // Grow V1 Flow 2 (A5): public_tracking's `eta` field is now a truthful
  // range/state object, not a single timestamp -- never a fabricated
  // precise time. Formats only the states that have something honest to
  // show; every other state falls back to the template's existing
  // "we'll update you" copy rather than inventing text.
  function formatEta(eta) {
    if (!eta || !eta.state) return null;
    const clock = (iso) => new Date(iso).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    if (eta.state === 'estimated_range' && eta.earliest && eta.latest) {
      return `${clock(eta.earliest)}–${clock(eta.latest)}`;
    }
    if (eta.state === 'arriving_now') return 'Arriving now';
    return null;
  }

  async function refresh() {
    if (!token) throw new Error('Invalid tracking reference');
    const snapshot = await api.rpc('public_tracking', { p_token: token }, { token: null });
    if (!snapshot) throw new Error('Invalid tracking reference');
    // S4-06.7 (P3): every real delivery_status value maps to its own honest
    // tracking state -- issue/cancelled are real, distinct states and must
    // never fall through to picked_up (the old map only covered 5 of the 8
    // real values, so a fresh/issue/cancelled order was silently shown as
    // "Picked Up").
    const statusMap = {
      created: 'order_confirmed', ready_for_pickup: 'preparing', picked_up: 'picked_up',
      out_for_delivery: 'on_the_way', arrived: 'on_the_way', delivered: 'delivered',
      issue: 'issue', cancelled: 'cancelled'
    };
    window.CEFFLOTracking.setStatus(statusMap[snapshot.status] || 'order_confirmed', {
      orderId: snapshot.order_number ?? snapshot.order_id,
      storeName: snapshot.store_name,
      riderName: snapshot.rider_name || 'Your driver',
      // Approved fields (2026-10-05); absent values stay absent (rows hide).
      items: Array.isArray(snapshot.items) ? snapshot.items : null,
      pickupAddress: snapshot.pickup_address || null,
      businessPhone: snapshot.business_phone || null,
      riderVehicle: snapshot.rider_vehicle || null,
      riderPlate: snapshot.rider_plate || null,
      estimatedArrival: formatEta(snapshot.eta) || '—',
      deliveredAt: snapshot.completed_at ? new Date(snapshot.completed_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '—',
      podPhoto: snapshot.status === 'delivered' && snapshot.pod_available ? await podUrl().catch(() => null) : null,
      riderLocation: snapshot.rider_location || null,
      pickedUpAt: snapshot.picked_up_at ? new Date(snapshot.picked_up_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : null,
      ratingSubmitted: Boolean(snapshot.rating_submitted)
    });
    syncLive(snapshot);
    if (window.CEFFLOTracking.setFreshness) window.CEFFLOTracking.setFreshness(Date.now());
    return snapshot;
  }

  // Phase 2B.4 / D-66: one coalescing gate for every fetch trigger (open,
  // visible-again, bfcache, `loc` hint, safety fallback). Never two parallel
  // public_tracking reads; at least MIN_GAP_MS between fetch starts; hints
  // arriving sooner collapse into one follow-up fetch.
  const MIN_GAP_MS = 10000;
  let pending = false;
  let spacingTimer = null;
  let fallbackTimer = null;
  let live = null;
  let lastSnapshot = null;
  let loadRetries = 0;

  // Pull-to-refresh waits on the same gate; settled when the run finishes.
  const waiters = [];

  async function runRefresh() {
    isRefreshing = true;
    lastRefreshAt = Date.now();
    let outcome = 'ok';
    try {
      lastSnapshot = await refresh();
    } catch (error) {
      outcome = 'error';
      // Invalid/expired token, or no snapshot yet: the generic customer-safe
      // template (no internals). A failed re-check keeps the last real state.
      const phase = window.CEFFLOTracking.getSnapshot?.()?.phase;
      if (error.message === 'Invalid tracking reference') window.CEFFLOTracking.fail();
      else if (phase === 'loading') {
        // Transient (e.g. rate limit, network): retry through the gate twice,
        // then show the generic unavailable template.
        loadRetries += 1;
        if (loadRetries <= 2) pending = true; else window.CEFFLOTracking.fail();
      }
    } finally {
      isRefreshing = false;
      waiters.splice(0).forEach((done) => done(outcome));
      armFallback();
      if (pending) { pending = false; guardedRefresh(); }
    }
  }

  function guardedRefresh() {
    if (document.visibilityState === 'hidden') return;
    if (isRefreshing) { pending = true; return; }
    const wait = MIN_GAP_MS - (Date.now() - lastRefreshAt);
    if (wait > 0) {
      if (!spacingTimer) spacingTimer = setTimeout(() => { spacingTimer = null; guardedRefresh(); }, wait);
      return;
    }
    runRefresh();
  }

  const TRACKABLE = ['picked_up', 'out_for_delivery', 'arrived'];

  // Safety fallback only while visible and trackable: one fetch per staleness
  // limit (HIGH 60 s for the next stop / arrived, otherwise 3 min). Never
  // short-interval polling.
  function armFallback() {
    clearTimeout(fallbackTimer);
    const s = lastSnapshot;
    if (!s || !TRACKABLE.includes(s.status) || document.visibilityState === 'hidden') return;
    const high = s.status === 'arrived';
    fallbackTimer = setTimeout(guardedRefresh, high ? 60000 : 180000);
  }

  function syncLive(snapshot) {
    const want = snapshot.live && TRACKABLE.includes(snapshot.status) && document.visibilityState !== 'hidden';
    if (!want) { live && live.leave(); return; }
    if (!live && window.CEFFLOLive) {
      live = window.CEFFLOLive.createLiveChannel({
        url: api.config.supabaseUrl, apiKey: api.config.supabaseAnonKey, onHint: guardedRefresh
      });
    }
    if (live) live.join(snapshot.live.topic, snapshot.live.key);
  }

  function goHidden() {
    clearTimeout(fallbackTimer); fallbackTimer = null;
    clearTimeout(spacingTimer); spacingTimer = null;
    pending = false;
    live && live.leave();
  }

  const submitRating = (rating, feedback) => api.rpc('submit_rating', { p_token: token, p_rating: rating, p_feedback: feedback }, { token: null });
  async function podUrl() {
    const response = await fetch(`${api.config.supabaseUrl}/functions/v1/tracking-pod`, {
      method: 'POST', headers: { apikey: api.config.supabaseAnonKey, 'Content-Type': 'application/json' }, body: JSON.stringify({ token })
    });
    if (!response.ok) throw new Error('POD unavailable');
    return (await response.json()).url;
  }
  // Pull-to-refresh: the SAME coalescing gate (>= 10 s between fetches, the
  // backend's 10 / 60 s limit). Data fetched within the gap is already fresh,
  // so the gesture settles at once instead of sending another request.
  function pullRefresh() {
    if (!isRefreshing && Date.now() - lastRefreshAt < MIN_GAP_MS) return Promise.resolve('fresh');
    return new Promise((done) => { waiters.push(done); guardedRefresh(); });
  }
  window.CEFFLO_CUSTOMER = Object.freeze({ refresh: guardedRefresh, pullRefresh, submitRating, podUrl });

  window.addEventListener('load', guardedRefresh);
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') guardedRefresh();
    else goHidden();
  });
  window.addEventListener('online', guardedRefresh);
  window.addEventListener('pagehide', goHidden);
  window.addEventListener('pageshow', (event) => {
    if (event.persisted) guardedRefresh();
  });
})();
