import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Known-live CEFFLO Customer tracking origin (verified reachable this
// session). Production's real tracking domain is not yet attached/resolving
// (see docs/cefflo/PHASE_1_DEPLOYMENT_DOMAIN_MAP.md) and is deliberately NOT
// guessed here -- it must be added via CEFFLO_TRACKING_CORS_ORIGINS once
// established, not hard-coded speculatively.
const DEFAULT_ALLOWED_ORIGINS = [
  'https://new-project-git-staging-cefflohq26-6353s-projects.vercel.app',
];

const RATE_LIMIT_WINDOW_SECONDS = 60;
const RATE_LIMIT_MAX_REQUESTS = 10;

// Pure, Deno-independent so this logic can be exercised directly with a
// plain JS runtime in tests, not only inside the Deno Edge runtime.
function resolveAllowedOrigins(rawEnvValue) {
  const configured = String(rawEnvValue || '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
  return configured.length ? configured : DEFAULT_ALLOWED_ORIGINS;
}

function isOriginAllowed(origin, allowedOrigins) {
  return Boolean(origin) && allowedOrigins.includes(origin);
}

function buildCorsHeaders(origin, allowedOrigins) {
  const headers = { Vary: 'Origin' };
  if (isOriginAllowed(origin, allowedOrigins)) {
    headers['Access-Control-Allow-Origin'] = origin;
    headers['Access-Control-Allow-Headers'] = 'content-type';
    headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS';
  }
  return headers;
}

// Seconds remaining until the current fixed window resets, matching the
// same bucket boundary check_rate_limit() uses server-side
// (floor(epoch / window) * window).
function secondsUntilWindowReset(windowSeconds) {
  const nowSeconds = Date.now() / 1000;
  return Math.max(1, Math.ceil(windowSeconds - (nowSeconds % windowSeconds)));
}

async function sha256Hex(value) {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest('SHA-256', bytes);
  return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, '0')).join('');
}

// Fixed, public-safe error shape. Never forward error.message from a
// database/storage/client exception -- it can contain raw Postgres text,
// internal RPC names, storage paths, or other implementation detail.
function safeError(status, publicMessage, headers) {
  return Response.json({ error: publicMessage }, { status, headers });
}

Deno.serve(async (request) => {
  const origin = request.headers.get('origin');
  const allowedOrigins = resolveAllowedOrigins(Deno.env.get('CEFFLO_TRACKING_CORS_ORIGINS'));
  const cors = buildCorsHeaders(origin, allowedOrigins);

  if (request.method === 'OPTIONS') {
    // Preflight: only allowed origins get a response granting the browser
    // permission to proceed. Disallowed origins get a plain 204 with no
    // Access-Control-Allow-Origin header, so the browser blocks the actual
    // request -- never a permissive/reflected/wildcard origin.
    return new Response(null, { status: 204, headers: cors });
  }

  try {
    const body = await request.json().catch(() => null);
    const token = body && typeof body.token === 'string' ? body.token : null;
    if (!token) return safeError(400, 'Invalid request', cors);

    const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, { auth: { persistSession: false } });

    // Rate limit gate: its own independent RPC call/statement, so a later
    // failure in this request can never roll back the counter increment
    // (unlike calling the same primitive from inside public_tracking/
    // submit_rating's own statement -- see the S4-04.B05 checkpoint entry).
    // Limiter infrastructure failure fails OPEN; a genuine over-limit result
    // fails closed (429). Token validity/expiry/revocation is unaffected --
    // still fully enforced by public_tracking below.
    let allowed = true;
    try {
      const key = await sha256Hex(token);
      const { data: rateLimitOk, error: rateLimitError } = await admin.rpc('check_rate_limit', {
        p_key_hash: key,
        p_action: 'tracking_pod',
        p_window_seconds: RATE_LIMIT_WINDOW_SECONDS,
        p_max_requests: RATE_LIMIT_MAX_REQUESTS,
      });
      if (rateLimitError) {
        console.error('[tracking-pod] check_rate_limit error', rateLimitError);
      } else {
        allowed = rateLimitOk !== false;
      }
    } catch (rateLimitException) {
      console.error('[tracking-pod] check_rate_limit unexpected error', rateLimitException);
    }

    if (!allowed) {
      const retryAfter = String(secondsUntilWindowReset(RATE_LIMIT_WINDOW_SECONDS));
      return safeError(429, 'Too many requests', { ...cors, 'Retry-After': retryAfter });
    }

    const { data: tracking, error } = await admin.rpc('public_tracking', { p_token: token });
    if (error || !tracking || tracking.status !== 'delivered' || !tracking.pod_available) {
      // Deliberately identical response for "token doesn't exist", "expired",
      // "revoked", and "not yet delivered" -- distinguishing these would let
      // a caller enumerate/probe token validity (same principle as
      // public_tracking's own unified not-found behavior; D-20).
      if (error) console.error('[tracking-pod] public_tracking error', error);
      return safeError(404, 'POD unavailable', cors);
    }

    const { data: podPath, error: pathError } = await admin.rpc('internal_tracking_pod_path', { p_token: token });
    if (pathError || !podPath) {
      if (pathError) console.error('[tracking-pod] internal_tracking_pod_path error', pathError);
      return safeError(404, 'POD unavailable', cors);
    }

    const { data, error: signError } = await admin.storage.from('cefflo-pod').createSignedUrl(podPath, 300);
    if (signError || !data) {
      console.error('[tracking-pod] createSignedUrl error', signError);
      return safeError(404, 'POD unavailable', cors);
    }

    return Response.json({ url: data.signedUrl, expiresIn: 300 }, { headers: cors });
  } catch (error) {
    // Any unexpected failure (malformed env, network, unforeseen exception):
    // logged server-side only, never surfaced to the public caller.
    console.error('[tracking-pod] unexpected error', error);
    return safeError(500, 'Unexpected error', cors);
  }
});

export { resolveAllowedOrigins, isOriginAllowed, buildCorsHeaders, secondsUntilWindowReset, DEFAULT_ALLOWED_ORIGINS, RATE_LIMIT_WINDOW_SECONDS, RATE_LIMIT_MAX_REQUESTS };
