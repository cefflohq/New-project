(function () {
  const api = window.CEFFLO;
  async function login({ email, phone, password }) {
    await api.login(email || phone, password);
    const rows = await assignments();
    return { user: { applicationStatus: 'approved', email: email || null, phone: phone || null }, assignments: rows };
  }
  const assignments = () => api.request('/rest/v1/rider_assignments?select=*,orders(*)');
  const orders = () => api.request('/rest/v1/orders?select=*&order=delivery_sequence.asc');
  const transition = (orderId, next) => api.rpc('rider_transition', { p_order_id: orderId, p_next: next, p_idempotency_key: crypto.randomUUID() });
  async function complete(orderId, file, note) {
    const path = await api.uploadPod(orderId, file);
    return api.rpc('complete_delivery', { p_order_id: orderId, p_pod_path: path, p_note: note || '', p_idempotency_key: crypto.randomUUID() });
  }
  window.CEFFLO_AUTH = { login };
  window.CEFFLO_RIDER = Object.freeze({ assignments, orders, transition, complete });
})();
