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

  return { name, projectRef, supabaseUrl: url.origin, publishableKey };
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
    storageBucket: 'cefflo-pod'
  };
  return `window.CEFFLO_CONFIG = Object.freeze(${JSON.stringify(config, null, 2)});\n`;
}

export { PRODUCTION_PROJECT_REF };
