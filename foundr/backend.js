(function () {
  const api = window.CEFFLO;

  // ===== FOUNDR Phase 0-3 RPC wrappers =====
  const stuckRiders = (staleMinutes) => api.rpc('admin_stuck_riders', { p_stale_minutes: staleMinutes ?? 45 });
  const listVendors = () => api.rpc('admin_list_vendors', {});
  const getVendor = businessId => api.rpc('admin_get_vendor', { p_business_id: businessId });
  const listRiders = () => api.rpc('admin_list_riders', {});
  const deliveryOperations = () => api.rpc('admin_delivery_operations', {});

  const listAuditLog = (limit) => api.rpc('admin_list_audit_log', { p_limit: limit ?? 100 });
  const setFeatureFlag = (key, enabled, description) => api.rpc('admin_set_feature_flag', { p_key: key, p_enabled: enabled, p_description: description ?? null });
  const activeMaintenance = () => api.rpc('get_active_maintenance', {});
  const startMaintenance = (scope, reason, expectedDurationMinutes, rollbackCondition) =>
    api.rpc('admin_start_maintenance', { p_scope: scope, p_reason: reason, p_expected_duration_minutes: expectedDurationMinutes ?? null, p_rollback_condition: rollbackCondition });
  const endMaintenance = windowId => api.rpc('admin_end_maintenance', { p_id: windowId });

  const listSubscriptions = () => api.rpc('admin_list_subscriptions', {});
  const setSubscription = (businessId, planKey, status, mrrCents, trialEndsAt) =>
    api.rpc('admin_set_subscription', { p_business_id: businessId, p_plan_key: planKey, p_status: status, p_mrr_cents: mrrCents ?? null, p_trial_ends_at: trialEndsAt ?? null });
  const listAppVersions = () => api.rpc('admin_list_app_versions', {});
  const recordAppVersion = (app, version, minSupportedVersion, notes) =>
    api.rpc('admin_record_app_version', { p_app: app, p_version: version, p_min_supported_version: minSupportedVersion ?? null, p_notes: notes ?? null });
  const activeAnnouncements = () => api.rpc('get_active_announcements', {});
  const createAnnouncement = (title, body, severity, startsAt, endsAt) =>
    api.rpc('admin_create_announcement', { p_title: title, p_body: body, p_severity: severity ?? 'info', p_starts_at: startsAt ?? null, p_ends_at: endsAt ?? null });
  const setAnnouncementActive = (id, active) => api.rpc('admin_set_announcement_active', { p_id: id, p_active: active });

  window.CEFFLO_FOUNDR = Object.freeze({
    stuckRiders, listVendors, getVendor, listRiders, deliveryOperations,
    listAuditLog, setFeatureFlag, activeMaintenance, startMaintenance, endMaintenance,
    listSubscriptions, setSubscription, listAppVersions, recordAppVersion,
    activeAnnouncements, createAnnouncement, setAnnouncementActive,
  });

  // ===== Access gate =====
  // This UI has no login form of its own -- it is meant to run only for an
  // already-authenticated identity that is also a platform admin. Every RPC
  // above independently re-checks is_platform_admin() server-side regardless
  // of what this client believes, so this gate is a UX courtesy (a clear
  // "Access Denied" instead of a confusing half-rendered dashboard or a wall
  // of failed-RPC toasts), never the actual security boundary.
  function renderAccessDenied(message) {
    document.body.innerHTML = `
      <div style="min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px;font-family:'Poppins',system-ui,sans-serif;background:#0B0F1A;color:#F1F5F9;text-align:center;">
        <div>
          <h1 style="font-size:20px;margin:0 0 8px;">Access Denied</h1>
          <p style="font-size:13.5px;color:#94A3B8;max-width:360px;margin:0 auto;">${message}</p>
        </div>
      </div>`;
  }

  // ===== Bridge real data into the existing mock-driven render layer =====
  // The render/hook functions (renderOverview, renderVendors, hookPlatform,
  // ...) already read allVendors/featureFlags/recentPlatformActivity/
  // clientVersions as top-level closures rather than as function arguments,
  // so the smallest safe way to wire them to real data is to overwrite those
  // same variables once real data has loaded, then let goToPage() re-render
  // through the unmodified render layer -- not to rewrite every render
  // function's internals.
  //
  // Deliberately NOT bridged (left as the original prototype's mock data,
  // clearly out of scope for this pass -- see the session's Phase 3 report):
  // clusters/atRiskVendors (geographic + churn-risk modeling, no source),
  // systemHealthServices/integrationsHealth/systemUsage (infra monitoring,
  // no data source in Supabase), revenue/growth charts (no billing
  // transactions exist to compute from).
  function mapVendorRow(v) {
    return {
      id: v.business_id, name: v.business_name || v.name,
      businessType: '—', plan: '—', status: 'active',
      payingSince: '—', mrr: 0,
      orders: Number(v.order_count_30d || 0),
      retention: null,
      area: v.operating_area || '—',
      lastActivityMin: v.last_order_at ? Math.max(0, Math.round((Date.now() - new Date(v.last_order_at).getTime()) / 60000)) : null,
    };
  }
  function mapFlagRow(f) {
    return {
      key: f.key, title: f.description || f.key, desc: f.description || '',
      scope: '—', env: '—', on: !!f.enabled, affected: '—', owner: f.updated_by ? 'Admin' : '—',
    };
  }
  function mapActivityRow(a) {
    const ts = a.created_at ? new Date(a.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '';
    return { ts, text: `${a.action}${a.target_type ? ' · ' + a.target_type : ''}${a.reason ? ' — ' + a.reason : ''}`, actor: a.admin_user_id ? 'Admin' : 'System' };
  }
  function mapVersionRow(v) {
    return { name: v.app, version: v.version, status: v.min_supported_version && v.version === v.min_supported_version ? 'Latest' : 'Recorded' };
  }

  async function hydrateFoundr() {
    const [vendorsResult, auditResult] = await Promise.allSettled([listVendors(), listAuditLog(50)]);
    // feature_flags has no dedicated "list all" RPC (admin_set_feature_flag
    // upserts one at a time) -- read the table directly via PostgREST like
    // every other adapter's list*() helper does for its own tables.
    const flagsRows = await api.request('/rest/v1/feature_flags?select=*&order=key.asc').catch(() => []);
    const versionsRows = await listAppVersions().catch(() => []);

    if (vendorsResult.status === 'fulfilled' && Array.isArray(vendorsResult.value)) {
      allVendors = vendorsResult.value.map(mapVendorRow);
    }
    if (auditResult.status === 'fulfilled' && Array.isArray(auditResult.value)) {
      recentPlatformActivity = auditResult.value.map(mapActivityRow);
    }
    if (Array.isArray(flagsRows)) {
      featureFlags = flagsRows.map(mapFlagRow);
    }
    if (Array.isArray(versionsRows)) {
      clientVersions = versionsRows.map(mapVersionRow);
    }
  }

  async function boot() {
    if (!api.session()?.access_token) {
      renderAccessDenied('Sign in with a platform admin account to open FOUNDR. This surface has no self-service sign-up.');
      return;
    }
    try {
      // is_platform_admin() has no dedicated probe RPC; admin_list_vendors()
      // is the cheapest real Phase 1 call and will itself raise 'forbidden'
      // for a signed-in identity that is not a platform admin, which is the
      // exact condition this gate needs to detect.
      await listVendors();
    } catch (error) {
      renderAccessDenied('Your account is signed in but is not a platform admin. Ask an existing admin to grant access.');
      return;
    }
    try {
      await hydrateFoundr();
    } catch (error) {
      console.error('[CEFFLO FOUNDR hydrate]', error);
    }
    if (typeof goToPage === 'function') goToPage(typeof currentPage !== 'undefined' ? currentPage : 'overview');
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }
})();
