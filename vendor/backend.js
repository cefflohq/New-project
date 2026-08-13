(function () {
  const api = window.CEFFLO;
  async function businesses() { return api.rpc('get_my_businesses', {}); }
  async function createDelivery(input) {
    return api.rpc('create_delivery', {
      p_business_id: input.businessId,
      p_customer_name: input.customerName,
      p_customer_phone: input.customerPhone,
      p_delivery_address: input.address,
      p_notes: input.notes || '',
      p_latitude: input.latitude ?? null,
      p_longitude: input.longitude ?? null,
      p_items: input.items || []
    });
  }
  const assignRider = (orderId, riderId) => api.rpc('assign_rider', { p_order_id: orderId, p_rider_id: riderId });
  async function listOrders(businessId) {
    return api.request(`/rest/v1/orders?business_id=eq.${encodeURIComponent(businessId)}&select=*&order=created_at.desc`);
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
  window.CEFFLO_VENDOR = Object.freeze({ businesses, createDelivery, assignRider, listOrders, subscribe });
})();
