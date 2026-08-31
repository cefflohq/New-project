(function () {
  const api = window.CEFFLO;
  const token = new URLSearchParams(location.search).get('token');

  // CEFFLO Customer Tracking is "latest known location on demand," not
  // continuous live tracking (Founder policy). Fetch on initial open,
  // return/refocus, bfcache restore, and manual refresh only -- never on a
  // timer.
  const REFRESH_COOLDOWN_MS = 3000;
  let isRefreshing = false;
  let lastRefreshAt = 0;

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
      orderId: snapshot.order_id,
      storeName: snapshot.store_name,
      riderName: snapshot.rider_name || 'Your rider',
      estimatedArrival: snapshot.eta ? new Date(snapshot.eta).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '—',
      deliveredAt: snapshot.completed_at ? new Date(snapshot.completed_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '—',
      podPhoto: snapshot.status === 'delivered' && snapshot.pod_available ? await podUrl().catch(() => null) : null
    });
    if (snapshot.rating_submitted) {
      const form = document.getElementById('ratingForm');
      const thanks = document.getElementById('ratingThanks');
      const copy = document.getElementById('ratingThanksCopy');
      if (form) form.hidden = true;
      if (thanks) thanks.classList.add('is-visible');
      if (copy && !copy.textContent.trim()) copy.textContent = 'Your rating was submitted successfully.';
    }
    if (window.CEFFLOTracking.setFreshness) window.CEFFLOTracking.setFreshness(Date.now());
    return snapshot;
  }

  // Single shared entry point for every refresh trigger (initial load,
  // visibility/focus return, bfcache restore, manual button). An in-flight
  // guard collapses trigger events that fire together (e.g. visibilitychange
  // and pageshow on the same real tab return) into one request; the cooldown
  // absorbs rapid repeats (e.g. button mashing) without a second round trip.
  async function guardedRefresh() {
    if (isRefreshing) return;
    if (Date.now() - lastRefreshAt < REFRESH_COOLDOWN_MS) return;
    isRefreshing = true;
    lastRefreshAt = Date.now();
    try {
      await refresh();
    } catch (error) {
      document.getElementById('heroStatus').textContent = error.message;
    } finally {
      isRefreshing = false;
    }
  }

  const submitRating = (rating, feedback) => api.rpc('submit_rating', { p_token: token, p_rating: rating, p_feedback: feedback }, { token: null });
  async function podUrl() {
    const response = await fetch(`${api.config.supabaseUrl}/functions/v1/tracking-pod`, {
      method: 'POST', headers: { apikey: api.config.supabaseAnonKey, 'Content-Type': 'application/json' }, body: JSON.stringify({ token })
    });
    if (!response.ok) throw new Error('POD unavailable');
    return (await response.json()).url;
  }
  window.CEFFLO_CUSTOMER = Object.freeze({ refresh: guardedRefresh, submitRating, podUrl });
  window.addEventListener('cefflo:delivery-rated', event => {
    submitRating(event.detail.rating, event.detail.feedback).catch(error => console.error('Rating persistence failed', error));
  });

  window.addEventListener('load', guardedRefresh);
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') guardedRefresh();
  });
  window.addEventListener('pageshow', (event) => {
    if (event.persisted) guardedRefresh();
  });
})();
