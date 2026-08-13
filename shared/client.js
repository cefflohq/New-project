(function () {
  const config = window.CEFFLO_CONFIG;
  if (!config) throw new Error('CEFFLO_CONFIG is required');
  const sessionKey = 'cefflo.auth.session.v1';
  let session = JSON.parse(localStorage.getItem(sessionKey) || 'null');

  async function request(path, { method = 'GET', body, token = session?.access_token } = {}) {
    const response = await fetch(`${config.supabaseUrl}${path}`, {
      method,
      headers: {
        apikey: config.supabaseAnonKey,
        Authorization: `Bearer ${token || config.supabaseAnonKey}`,
        'Content-Type': 'application/json'
      },
      body: body === undefined ? undefined : JSON.stringify(body)
    });
    const text = await response.text();
    const data = text ? JSON.parse(text) : null;
    if (!response.ok) throw new Error(data?.message || data?.error_description || `Request failed (${response.status})`);
    return data;
  }
  const rpc = (name, body, options) => request(`/rest/v1/rpc/${name}`, { method: 'POST', body, ...options });
  async function login(identifier, password) {
    const credential = String(identifier).includes('@') ? { email: identifier, password } : { phone: identifier, password };
    session = await request('/auth/v1/token?grant_type=password', { method: 'POST', body: credential, token: null });
    localStorage.setItem(sessionKey, JSON.stringify(session));
    return session;
  }
  async function logout() {
    if (session?.access_token) await request('/auth/v1/logout', { method: 'POST' }).catch(() => {});
    session = null;
    localStorage.removeItem(sessionKey);
  }
  async function uploadPod(orderId, file) {
    const path = `orders/${orderId}/${crypto.randomUUID()}.${(file.type.split('/')[1] || 'jpg').replace('jpeg', 'jpg')}`;
    const response = await fetch(`${config.supabaseUrl}/storage/v1/object/${config.storageBucket}/${path}`, {
      method: 'POST',
      headers: { apikey: config.supabaseAnonKey, Authorization: `Bearer ${session.access_token}`, 'Content-Type': file.type, 'x-upsert': 'false' },
      body: file
    });
    if (!response.ok) throw new Error(await response.text());
    return path;
  }
  window.CEFFLO = Object.freeze({ config, request, rpc, login, logout, uploadPod, session: () => session });
})();
