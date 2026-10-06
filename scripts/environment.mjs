const PRODUCTION_PROJECT_REF = 'lmaxtrubwdniovxyuqdy';
const ENVIRONMENTS = new Set(['local', 'preview', 'staging', 'test', 'production']);
const HOSTED_REF = /^[a-z0-9]{20}$/;

export function resolveFrontendEnvironment(values) {
  const name = String(values.CEFFLO_ENVIRONMENT || '').trim().toLowerCase();
  const projectRef = String(values.CEFFLO_SUPABASE_PROJECT_REF || '').trim().toLowerCase();
  const supabaseUrl = String(values.SUPABASE_URL || '').trim();
  const publishableKey = String(values.SUPABASE_PUBLISHABLE_KEY || '').trim();

  if (!ENVIRONMENTS.has(name)) throw new Error('CEFFLO_ENVIRONMENT must explicitly be local, preview, staging, test, or production');
  if (!projectRef) throw new Error('CEFFLO_SUPABASE_PROJECT_REF is required');
  if (!supabaseUrl) throw new Error('SUPABASE_URL is required');
  if (!publishableKey) throw new Error('SUPABASE_PUBLISHABLE_KEY is required');

  let url;
  try { url = new URL(supabaseUrl); } catch { throw new Error('SUPABASE_URL must be a valid absolute URL'); }
  if (!['http:', 'https:'].includes(url.protocol)) throw new Error('SUPABASE_URL must use http or https');
  if (url.username || url.password || url.pathname !== '/' || url.search || url.hash) {
    throw new Error('SUPABASE_URL must be an origin without credentials, path, query, or fragment');
  }

  if (name === 'local') {
    if (projectRef !== 'local') throw new Error('Local builds require CEFFLO_SUPABASE_PROJECT_REF=local');
    if (!['127.0.0.1', 'localhost', '[::1]'].includes(url.hostname)) throw new Error('Local builds require a loopback SUPABASE_URL');
  } else {
    if (!HOSTED_REF.test(projectRef)) throw new Error('Hosted environments require a 20-character Supabase project ref');
    if (url.hostname !== `${projectRef}.supabase.co`) throw new Error('SUPABASE_URL does not match CEFFLO_SUPABASE_PROJECT_REF');
  }

  if (name === 'production') {
    if (projectRef !== PRODUCTION_PROJECT_REF) throw new Error('Production environment identity does not match the approved Production project ref');
  } else if (projectRef === PRODUCTION_PROJECT_REF || url.hostname === `${PRODUCTION_PROJECT_REF}.supabase.co`) {
    throw new Error('Known Production Supabase project is forbidden for non-production builds');
  }

  const driverStoreUrls = {
    android: storeUrl(values.CEFFLO_DRIVER_PLAY_STORE_URL, 'play.google.com', 'CEFFLO_DRIVER_PLAY_STORE_URL'),
    ios: storeUrl(values.CEFFLO_DRIVER_APP_STORE_URL, 'apps.apple.com', 'CEFFLO_DRIVER_APP_STORE_URL'),
  };
  const vendorStoreUrls = {
    android: storeUrl(values.CEFFLO_VENDOR_PLAY_STORE_URL, 'play.google.com', 'CEFFLO_VENDOR_PLAY_STORE_URL'),
    ios: storeUrl(values.CEFFLO_VENDOR_APP_STORE_URL, 'apps.apple.com', 'CEFFLO_VENDOR_APP_STORE_URL'),
  };

  // Where the invitation PWA hands a permanent invite link (Founder,
  // 2026-10-01). Role-aware destinations (production domain map, Founder
  // 2026-10-05): Driver -> driver.cefflo.com, Operator -> operator.cefflo.com,
  // Helper -> helper.cefflo.com. `vendor` is the shared Vendor App build used
  // with ?access= when no dedicated Operator/Helper host is configured
  // (staging). Optional; https only. The token, never the URL, decides role.
  const appWebUrls = {
    driver: webAppUrl(values.CEFFLO_DRIVER_WEB_URL, 'CEFFLO_DRIVER_WEB_URL'),
    vendor: webAppUrl(values.CEFFLO_VENDOR_WEB_URL, 'CEFFLO_VENDOR_WEB_URL'),
    operator: webAppUrl(values.CEFFLO_OPERATOR_WEB_URL, 'CEFFLO_OPERATOR_WEB_URL'),
    helper: webAppUrl(values.CEFFLO_HELPER_WEB_URL, 'CEFFLO_HELPER_WEB_URL'),
  };
  // The Team Invite gateway (production https://invite.cefflo.com/). The
  // static surfaces build invite links from it; unset = the bundled /invite/.
  const inviteBaseUrl = baseUrl(values.CEFFLO_INVITE_BASE_URL, 'CEFFLO_INVITE_BASE_URL');

  // Public product URLs, environment-driven (Founder 2026-10-04): the
  // Storefront base ({base}{slug}; production https://order.cefflo.com/) and
  // the Customer Tracking base ({base}?token=...). Optional; https only.
  const storefrontBaseUrl = baseUrl(values.CEFFLO_STOREFRONT_BASE_URL, 'CEFFLO_STOREFRONT_BASE_URL');
  const trackingBaseUrl = baseUrl(values.CEFFLO_TRACKING_BASE_URL, 'CEFFLO_TRACKING_BASE_URL');
  // The Owner Vendor Web console (production https://vendor.cefflo.com/).
  // Optional; https only. Lets the Storefront accept Live Preview data from
  // that origin (the Vendor Web Storefront page embeds store/?embed=1).
  const vendorConsoleUrl = webAppUrl(values.CEFFLO_VENDOR_CONSOLE_URL, 'CEFFLO_VENDOR_CONSOLE_URL');

  // Mapbox PUBLIC token for on-demand client maps (Customer Tracking "View
  // live map"). Public pk.* only -- a secret sk.* token never ships to a client.
  const mapboxPublicToken = String(values.CEFFLO_MAPBOX_PUBLIC_TOKEN || '').trim() || null;
  if (mapboxPublicToken && !/^pk\.[A-Za-z0-9._-]+$/.test(mapboxPublicToken)) throw new Error('CEFFLO_MAPBOX_PUBLIC_TOKEN must be a public pk.* Mapbox token');

  return { name, projectRef, supabaseUrl: url.origin, publishableKey, driverStoreUrls, vendorStoreUrls, appWebUrls, inviteBaseUrl, storefrontBaseUrl, trackingBaseUrl, vendorConsoleUrl, mapboxPublicToken };
}

function baseUrl(raw, name) {
  const value = String(raw || '').trim();
  if (!value) return null;
  let url;
  try { url = new URL(value); } catch { throw new Error(`${name} must be a valid absolute URL`); }
  if (url.protocol !== 'https:' || url.search || url.hash || url.username || url.password) throw new Error(`${name} must be an https URL without credentials, query or fragment`);
  if (!url.pathname.endsWith('/')) throw new Error(`${name} must end with /`);
  return url.href;
}

function webAppUrl(raw, name) {
  const value = String(raw || '').trim();
  if (!value) return null;
  let url;
  try { url = new URL(value); } catch { throw new Error(`${name} must be a valid absolute URL`); }
  if (url.protocol !== 'https:' || url.search || url.hash) throw new Error(`${name} must be an https URL without query or fragment`);
  return url.href;
}

// Cefflo Driver / Cefflo Vendor store listings for the invitation PWA. Optional: absent
// until the Founder supplies the real listing URLs (never guessed). When
// present they must be https links on the official store host.
function storeUrl(raw, host, name) {
  const value = String(raw || '').trim();
  if (!value) return null;
  let url;
  try { url = new URL(value); } catch { throw new Error(`${name} must be a valid absolute URL`); }
  if (url.protocol !== 'https:' || url.hostname !== host) throw new Error(`${name} must be an https://${host}/ listing URL`);
  return url.href;
}

export function serializeRuntimeConfig(environment) {
  const config = {
    environment: environment.name,
    supabaseProjectRef: environment.projectRef,
    supabaseUrl: environment.supabaseUrl,
    supabaseAnonKey: environment.publishableKey,
    schema: 'public',
    authRequired: true,
    realtimeEnabled: true,
    storageBucket: 'cefflo-pod',
    driverStoreUrls: environment.driverStoreUrls || { android: null, ios: null },
    vendorStoreUrls: environment.vendorStoreUrls || { android: null, ios: null },
    appWebUrls: environment.appWebUrls || { driver: null, vendor: null, operator: null, helper: null },
    inviteBaseUrl: environment.inviteBaseUrl || null,
    storefrontBaseUrl: environment.storefrontBaseUrl || null,
    trackingBaseUrl: environment.trackingBaseUrl || null,
    vendorConsoleUrl: environment.vendorConsoleUrl || null,
    mapboxPublicToken: environment.mapboxPublicToken || null
  };
  return `window.CEFFLO_CONFIG = Object.freeze(${JSON.stringify(config, null, 2)});\n`;
}

export { PRODUCTION_PROJECT_REF };
