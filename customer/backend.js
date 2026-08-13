(function () {
  const api = window.CEFFLO;
  const token = new URLSearchParams(location.search).get('token');
  async function refresh() {
    if (!token) throw new Error('Invalid tracking reference');
    const snapshot = await api.rpc('public_tracking', { p_token: token }, { token: null });
    if (!snapshot) throw new Error('Invalid tracking reference');
    const statusMap = { ready_for_pickup: 'picked_up', picked_up: 'picked_up', out_for_delivery: 'on_the_way', arrived: 'on_the_way', delivered: 'delivered' };
    window.CEFFLOTracking.setStatus(statusMap[snapshot.status] || 'picked_up', {
      orderId: snapshot.order_id,
      storeName: snapshot.store_name,
      riderName: snapshot.rider_name || 'Your rider',
      estimatedArrival: snapshot.eta ? new Date(snapshot.eta).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '—',
      deliveredAt: snapshot.completed_at ? new Date(snapshot.completed_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '—',
      podPhoto: null
    });
    return snapshot;
  }
  const submitRating = (rating, feedback) => api.rpc('submit_rating', { p_token: token, p_rating: rating, p_feedback: feedback }, { token: null });
  async function podUrl() {
    const response = await fetch(`${api.config.supabaseUrl}/functions/v1/tracking-pod`, {
      method: 'POST', headers: { apikey: api.config.supabaseAnonKey, 'Content-Type': 'application/json' }, body: JSON.stringify({ token })
    });
    if (!response.ok) throw new Error('POD unavailable');
    return (await response.json()).url;
  }
  window.CEFFLO_CUSTOMER = Object.freeze({ refresh, submitRating, podUrl });
  window.addEventListener('cefflo:delivery-rated', event => {
    submitRating(event.detail.rating, event.detail.feedback).catch(error => console.error('Rating persistence failed', error));
  });
  window.addEventListener('load', () => { refresh().catch(error => { document.getElementById('heroStatus').textContent = error.message; }); });
  setInterval(() => refresh().catch(() => {}), 15000);
})();
