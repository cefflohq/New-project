// CEFFLO FOUNDR -- data layer. Every read and write goes to the canonical
// FOUNDR backend contract (supabase/migrations/202608300001..05): the
// platform_admins allowlist, the Phase 1 read-only admin RPCs, and the Phase
// 2/3 privileged write RPCs that each re-check is_platform_admin() and write
// admin_audit_log themselves. There is no mock or fallback data here: a call
// either returns the server's truth or throws its error.
(function () {
  const base = window.CEFFLO;
  const cfg = window.CEFFLO_CONFIG;

  async function authFetch(path, body) {
    const res = await fetch(`${cfg.supabaseUrl}${path}`, {
      method: 'POST',
      headers: { apikey: cfg.supabaseAnonKey, Authorization: `Bearer ${cfg.supabaseAnonKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    const text = await res.text();
    const data = text ? JSON.parse(text) : null;
    if (!res.ok) {
      const err = new Error(data?.msg || data?.message || data?.error_description || `Request failed (${res.status})`);
      err.status = res.status;
      err.code = data?.error_code || data?.code;
      throw err;
    }
    return data;
  }

  // ----- session -----
  let refreshing = null;
  function refresh() {
    const s = base.session();
    if (!s?.refresh_token) return Promise.reject(Object.assign(new Error('Session expired'), { status: 401 }));
    refreshing ??= authFetch('/auth/v1/token?grant_type=refresh_token', { refresh_token: s.refresh_token })
      .then(next => base.setSession(next))
      .finally(() => { refreshing = null; });
    return refreshing;
  }
  const expiresSoon = () => { const s = base.session(); return s?.expires_at && s.expires_at * 1000 - Date.now() < 60_000; };
  async function call(fn) {
    if (expiresSoon()) await refresh().catch(() => {});
    try { return await fn(); } catch (e) {
      if (/JWT expired|invalid JWT|401/i.test(String(e.message))) { await refresh(); return fn(); }
      throw e;
    }
  }
  const rpc = (name, body = {}) => call(() => base.rpc(name, body));
  const get = path => call(() => base.request(path));

  async function signIn(email, password) {
    const s = await authFetch('/auth/v1/token?grant_type=password', { email: email.trim(), password });
    return base.setSession(s);
  }
  async function signOut() { await base.logout(); }

  // Password recovery. The emailed link returns to this page's own folder, so
  // it follows local, preview, staging and production without a hard-coded
  // host; Supabase Auth honours it only when it is on the Redirect URLs list.
  const authRedirect = () => new URL('./', location.href).href;
  // FOUNDR target sign-in is Google only (FG-9). GoTrue's authorize redirect
  // returns here with #access_token=..., stored by consumeAuthFragment; the
  // platform-admin gate then decides access exactly as for any session.
  const googleSignInUrl = () => `${cfg.supabaseUrl}/auth/v1/authorize?provider=google&redirect_to=${encodeURIComponent(authRedirect())}`;
  function recover(email) {
    return authFetch(`/auth/v1/recover?redirect_to=${encodeURIComponent(authRedirect())}`, { email: email.trim() });
  }
  // Create Your Account: GoTrue sign-up (confirmation by 6-digit email code).
  // An account grants nothing in FOUNDR: entry still needs the
  // platform_admins allowlist (and, later, aal2).
  function signUp(fullName, email, password) {
    return authFetch(`/auth/v1/signup?redirect_to=${encodeURIComponent(authRedirect())}`, { email: email.trim(), password, data: { full_name: fullName.trim() } });
  }
  function resendSignUpCode(email) {
    return authFetch(`/auth/v1/resend?redirect_to=${encodeURIComponent(authRedirect())}`, { type: 'signup', email: email.trim() });
  }
  async function verifySignUpCode(email, code) {
    const s = await authFetch('/auth/v1/verify', { type: 'signup', email: email.trim(), token: String(code).trim() });
    if (!s?.access_token) throw Object.assign(new Error('That code could not be used. Request a new one.'), { status: 400 });
    return base.setSession({ ...s, expires_at: s.expires_at || Math.floor(Date.now() / 1000) + (s.expires_in || 3600) });
  }

  // The reset email carries a 6-digit code (and a link). The code signs in
  // with a recovery session (aal1), stored like any session; an admin with
  // an authenticator still proves the second step before the password
  // changes (GoTrue itself requires aal2 to update it).
  async function verifyRecoveryCode(email, code) {
    const s = await authFetch('/auth/v1/verify', { type: 'recovery', email: email.trim(), token: String(code).trim() });
    if (!s?.access_token) throw Object.assign(new Error('That code could not be used. Request a new one.'), { status: 400 });
    return base.setSession({ ...s, expires_at: s.expires_at || Math.floor(Date.now() / 1000) + (s.expires_in || 3600) });
  }
  // A recovery link lands with #access_token=...&type=recovery. Stores the
  // session, clears the tokens from the address bar and returns the type.
  function consumeAuthFragment() {
    const h = new URLSearchParams(location.hash.replace(/^#/, ''));
    if (!h.get('access_token')) return null;
    base.setSession({
      access_token: h.get('access_token'),
      refresh_token: h.get('refresh_token'),
      expires_at: Number(h.get('expires_at')) || undefined,
      token_type: 'bearer',
    });
    history.replaceState(null, '', location.pathname + location.search);
    return h.get('type');
  }
  // An expired or used link lands with #error=...&error_code=otp_expired.
  function consumeAuthError() {
    const h = new URLSearchParams(location.hash.replace(/^#/, ''));
    const q = new URLSearchParams(location.search);
    const src = h.get('error') ? h : q.get('error') ? q : null;
    if (!src) return null;
    const out = { code: src.get('error_code') || src.get('error'), description: src.get('error_description') || '' };
    ['error', 'error_code', 'error_description'].forEach(k => q.delete(k));
    const search = q.toString();
    history.replaceState(null, '', location.pathname + (search ? `?${search}` : ''));
    return out;
  }
  function updatePassword(password) {
    return call(async () => {
      const res = await fetch(`${cfg.supabaseUrl}/auth/v1/user`, {
        method: 'PUT',
        headers: { apikey: cfg.supabaseAnonKey, Authorization: `Bearer ${base.session()?.access_token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ password }),
      });
      const text = await res.text();
      const data = text ? JSON.parse(text) : null;
      if (!res.ok) throw Object.assign(new Error(data?.msg || data?.message || `Request failed (${res.status})`), { status: res.status, code: data?.error_code });
      return data;
    });
  }
  // ----- MFA (GoTrue TOTP) -----
  // Calls GoTrue with the signed-in user's own access token. The server
  // decides everything: GoTrue requires aal2 to add a factor or remove one
  // once a verified factor exists, and verify only succeeds for a valid code.
  async function userAuth(method, path, body) {
    return call(async () => {
      const res = await fetch(`${cfg.supabaseUrl}${path}`, {
        method,
        headers: { apikey: cfg.supabaseAnonKey, Authorization: `Bearer ${base.session()?.access_token}`, 'Content-Type': 'application/json' },
        body: body === undefined ? undefined : JSON.stringify(body),
      });
      const text = await res.text();
      const data = text ? JSON.parse(text) : null;
      if (!res.ok) throw Object.assign(new Error(data?.msg || data?.message || data?.error_description || `Request failed (${res.status})`), { status: res.status, code: data?.error_code || data?.code });
      return data;
    });
  }
  // The AAL of the stored access token ('aal1' | 'aal2'), read from its own
  // claims for display/routing only; the server re-reads the same JWT.
  function sessionAal() {
    const token = base.session()?.access_token;
    if (!token) return null;
    try {
      const part = token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/');
      return JSON.parse(atob(part.padEnd(part.length + (4 - part.length % 4) % 4, '='))).aal || 'aal1';
    } catch { return null; }
  }
  // The caller's own admin + MFA state (platform_admin_status, self-context).
  const platformAdminStatus = () => rpc('platform_admin_status');
  async function listFactors() {
    const user = await currentUser();
    return (user?.factors || []).filter(f => f.factor_type === 'totp');
  }
  const enrollTotp = friendlyName =>
    userAuth('POST', '/auth/v1/factors', { factor_type: 'totp', friendly_name: friendlyName, issuer: 'Cefflo FOUNDR' });
  const unenrollFactor = factorId => userAuth('DELETE', `/auth/v1/factors/${encodeURIComponent(factorId)}`);
  const challengeFactor = factorId => userAuth('POST', `/auth/v1/factors/${encodeURIComponent(factorId)}/challenge`, {});
  // A correct code upgrades this session to aal2: GoTrue returns a new
  // session, which replaces the stored one.
  async function verifyFactor(factorId, challengeId, code) {
    const s = await userAuth('POST', `/auth/v1/factors/${encodeURIComponent(factorId)}/verify`, { challenge_id: challengeId, code: String(code).trim() });
    if (s?.access_token) base.setSession({ ...s, expires_at: s.expires_at || Math.floor(Date.now() / 1000) + (s.expires_in || 3600) });
    return s;
  }

  function currentUser() {
    return call(async () => {
      const res = await fetch(`${cfg.supabaseUrl}/auth/v1/user`, { headers: { apikey: cfg.supabaseAnonKey, Authorization: `Bearer ${base.session()?.access_token}` } });
      if (!res.ok) {
        const data = await res.json().catch(() => null);
        throw Object.assign(new Error(data?.msg || `Request failed (${res.status})`), { status: res.status, code: data?.error_code || data?.code });
      }
      return res.json();
    });
  }

  // ----- access (Phase 0) -----
  // is_platform_admin() is the canonical allowlist check (authenticated only).
  const isPlatformAdmin = () => rpc('is_platform_admin');
  const listPlatformAdmins = () => get('/rest/v1/platform_admins?select=user_id,role,created_at&order=created_at.asc');

  // ----- Phase 1: read-only cross-business views -----
  const stuckRiders = staleMinutes => rpc('admin_stuck_riders', { p_stale_minutes: staleMinutes ?? 45 });
  const listVendors = () => rpc('admin_list_vendors');
  const getVendor = async businessId => { const rows = await rpc('admin_get_vendor', { p_business_id: businessId }); return Array.isArray(rows) ? rows[0] : rows; };
  const listRiders = () => rpc('admin_list_riders');
  const deliveryOperations = () => rpc('admin_delivery_operations');

  // ----- Phase 2: audit, feature flags, maintenance -----
  const listAuditLog = limit => rpc('admin_list_audit_log', { p_limit: limit ?? 500 });
  const listFeatureFlags = () => get('/rest/v1/feature_flags?select=*&order=key.asc');
  const setFeatureFlag = (key, enabled, description) => rpc('admin_set_feature_flag', { p_key: key, p_enabled: enabled, p_description: description ?? null });
  const activeMaintenance = () => rpc('get_active_maintenance');
  const listMaintenanceWindows = () => get('/rest/v1/maintenance_windows?select=*&order=started_at.desc&limit=100');
  const startMaintenance = (scope, reason, expectedDurationMinutes, rollbackCondition) =>
    rpc('admin_start_maintenance', { p_scope: scope, p_reason: reason, p_expected_duration_minutes: expectedDurationMinutes ?? null, p_rollback_condition: rollbackCondition });
  const endMaintenance = windowId => rpc('admin_end_maintenance', { p_id: windowId });

  // ----- Phase 3: subscriptions (admin-set), versions, announcements -----
  const listSubscriptions = () => rpc('admin_list_subscriptions');
  // The locked server price book (public read): FOUNDR never keeps its own.
  const listPlans = () => get('/rest/v1/subscription_plans?select=key,name,monthly_price_myr,delivery_allowance,driver_cap,zone_cap,team_user_cap,most_popular,self_serve,sort&order=sort.asc');
  const setSubscription = (businessId, planKey, status, mrrCents, trialEndsAt) =>
    rpc('admin_set_subscription', { p_business_id: businessId, p_plan_key: planKey, p_status: status, p_mrr_cents: mrrCents ?? null, p_trial_ends_at: trialEndsAt ?? null });
  const listAppVersions = () => rpc('admin_list_app_versions');
  const recordAppVersion = (app, version, minSupportedVersion, notes) =>
    rpc('admin_record_app_version', { p_app: app, p_version: version, p_min_supported_version: minSupportedVersion ?? null, p_notes: notes ?? null });
  const activeAnnouncements = () => rpc('get_active_announcements');
  const listAnnouncements = () => get('/rest/v1/platform_announcements?select=*&order=created_at.desc&limit=200');
  const createAnnouncement = (title, body, severity, startsAt, endsAt) =>
    rpc('admin_create_announcement', { p_title: title, p_body: body, p_severity: severity ?? 'info', p_starts_at: startsAt ?? null, p_ends_at: endsAt ?? null });
  const setAnnouncementActive = (id, active) => rpc('admin_set_announcement_active', { p_id: id, p_active: active });

  // ----- Marketplace Driver verification (manual exceptions review) -----
  // Admin RLS reads (aal2 admin only). Only the screening fields needed for a
  // decision are selected: the OCR result also holds the licence's full IC
  // number, which never leaves the server -- the IC shows as last 4 digits
  // (driver_licences.ic_last4) only.
  const VERIF_COLS = 'user_id,status,retake,reasons,vehicle_type,vehicle_plate,vehicle_photo_path,plate_result,attempts,submitted_at,screened_at,reviewed_at,reviewed_by,updated_at,'
    + 'lic_name:licence_result->>name,lic_expiry:licence_result->>expiry,lic_classes:licence_result->classes,lic_confidence:licence_result->>confidence,lic_text_found:licence_result->>text_found';
  const listVerifications = () => get(`/rest/v1/driver_marketplace_verifications?select=${VERIF_COLS}&order=updated_at.desc&limit=500`);
  const getLicence = async userId => (await get(`/rest/v1/driver_licences?user_id=eq.${encodeURIComponent(userId)}&select=user_id,ic_last4,front_path,back_path,submitted_at`))?.[0] || null;
  // Private bucket: a short-lived signed URL per document (storage policy
  // driver_documents_own_read allows the platform admin); never a public URL.
  async function signDocument(path, expiresIn = 300) {
    return call(async () => {
      const res = await fetch(`${cfg.supabaseUrl}/storage/v1/object/sign/cefflo-driver-documents/${path.split('/').map(encodeURIComponent).join('/')}`, {
        method: 'POST',
        headers: { apikey: cfg.supabaseAnonKey, Authorization: `Bearer ${base.session()?.access_token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ expiresIn }),
      });
      const data = await res.json().catch(() => null);
      if (!res.ok || !data?.signedURL) throw Object.assign(new Error(data?.message || data?.error || `Document unavailable (${res.status})`), { status: res.status });
      return `${cfg.supabaseUrl}/storage/v1${data.signedURL}`;
    });
  }
  const decideVerification = (userId, decision, reason) => rpc('decide_marketplace_verification', { p_user_id: userId, p_decision: decision, p_reason: reason || null });

  // ----- Notification broadcasts (in-app notification centre fan-out) -----
  const broadcastNotification = (title, body, audience, businessId, reason) =>
    rpc('admin_broadcast_notification', { p_title: title, p_body: body, p_audience: audience, p_business_id: businessId ?? null, p_reason: reason });
  const listBroadcasts = (limit = 200) => rpc('admin_list_broadcasts', { p_limit: limit });
  const broadcastAudienceSize = (audience, businessId) => rpc('admin_broadcast_audience_size', { p_audience: audience, p_business_id: businessId ?? null });

  // Round-trip time of a real authenticated backend call (System health).
  async function probe() {
    const t0 = performance.now();
    await rpc('is_platform_admin');
    return Math.round(performance.now() - t0);
  }

  window.CEFFLO_FOUNDR = Object.freeze({
    session: () => base.session(), signIn, signOut, googleSignInUrl, recover, verifyRecoveryCode, signUp, resendSignUpCode, verifySignUpCode, consumeAuthFragment, consumeAuthError, updatePassword, currentUser, isPlatformAdmin, listPlatformAdmins, probe,
    sessionAal, platformAdminStatus, listFactors, enrollTotp, unenrollFactor, challengeFactor, verifyFactor,
    stuckRiders, listVendors, getVendor, listRiders, deliveryOperations,
    listAuditLog, listFeatureFlags, setFeatureFlag, activeMaintenance, listMaintenanceWindows, startMaintenance, endMaintenance,
    listSubscriptions, listPlans, setSubscription, listAppVersions, recordAppVersion,
    activeAnnouncements, listAnnouncements, createAnnouncement, setAnnouncementActive,
    broadcastNotification, listBroadcasts, broadcastAudienceSize,
    listVerifications, getLicence, signDocument, decideVerification,
  });
})();
