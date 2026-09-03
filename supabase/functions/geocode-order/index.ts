import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Grow V1 Flow 2 (A1) -- Founder-locked provider: Mapbox Permanent
// Geocoding. This function is the sole caller of the Mapbox Geocoding API
// anywhere in this codebase -- the provider abstraction the A1 migration
// already built (orders.location_status, set_order_location,
// set_order_location_manual) stays exactly as it was; this only fills in
// the one missing piece, an actual provider behind it.
//
// GEOCODE ONCE -> STORE -> REUSE: this function refuses to call Mapbox at
// all when the order is already 'resolved' -- the caller (Vendor frontend)
// is expected to only invoke this right after intake or right after an
// explicit address change, but this is enforced here too, defensively, so
// no caller mistake can ever cause a repeat paid request for an unchanged
// address.
//
// Permanent, never Temporary: Mapbox's v6 Geocoding API takes an explicit
// `permanent=true` query parameter (their Long-term Storage / Permanent
// Geocoding semantics, a distinct contracted capability from the default
// Temporary result). It is passed unconditionally below -- there is no
// code path that omits it.

const MAPBOX_GEOCODE_URL = 'https://api.mapbox.com/search/geocode/v6/forward';

// ============================================================================
// Pure, Deno-independent logic -- exercised directly with plain Node in
// tests (matching supabase/functions/tracking-pod/index.ts's own established
// "pure logic separated from Deno.serve" convention), not only inside the
// Deno Edge runtime this sandbox does not have available.
// ============================================================================

// Reject empty/whitespace/too-short input before ever spending a Mapbox
// request on it -- a malformed address is a distinct, immediate failure
// class (Task requirement #11), not something the provider should be asked
// to guess at.
function validateAddressInput(address) {
  const trimmed = String(address == null ? '' : address).trim();
  if (!trimmed) return { valid: false, reason: 'empty_address' };
  if (trimmed.length < 3) return { valid: false, reason: 'address_too_short' };
  return { valid: true, address: trimmed };
}

function buildMapboxRequestUrl(address, accessToken, baseUrl) {
  const url = new URL(baseUrl || MAPBOX_GEOCODE_URL);
  url.searchParams.set('q', address);
  url.searchParams.set('permanent', 'true');
  url.searchParams.set('limit', '1');
  url.searchParams.set('access_token', accessToken);
  return url.toString();
}

// Mapbox v6 match_code.confidence tiers, worst to best. Anything below
// 'medium' is not trusted as an automatically-resolved delivery location --
// classified 'ambiguous' for a human to confirm/correct via
// set_order_location_manual, never silently accepted as a precise point.
const ACCEPTABLE_CONFIDENCE = new Set(['exact', 'high', 'medium']);

// Classifies a completed Mapbox HTTP response into exactly one outcome.
// Every branch in Task requirement #11's list is a distinct, named reason:
// no result, ambiguous/low-confidence, malformed provider response,
// rate limit, invalid/expired credentials, provider-side failure. Network-
// level failure (fetch itself throwing) is handled by the caller, since
// there is no HTTP response to classify in that case.
function classifyMapboxResult(httpStatus, bodyJson) {
  if (httpStatus === 401 || httpStatus === 403) {
    return { status: 'failed', reason: 'invalid_credentials' };
  }
  if (httpStatus === 429) {
    return { status: 'failed', reason: 'rate_limited' };
  }
  if (httpStatus >= 500) {
    return { status: 'failed', reason: 'provider_unavailable' };
  }
  if (httpStatus !== 200) {
    return { status: 'failed', reason: `unexpected_status_${httpStatus}` };
  }
  const features = bodyJson && Array.isArray(bodyJson.features) ? bodyJson.features : null;
  if (!features || features.length === 0) {
    return { status: 'failed', reason: 'no_result' };
  }
  const feature = features[0];
  const coords = feature && feature.geometry ? feature.geometry.coordinates : null;
  if (!Array.isArray(coords) || coords.length < 2 || typeof coords[0] !== 'number' || typeof coords[1] !== 'number') {
    return { status: 'failed', reason: 'malformed_provider_response' };
  }
  const confidence = feature.properties && feature.properties.match_code ? feature.properties.match_code.confidence : undefined;
  if (!ACCEPTABLE_CONFIDENCE.has(confidence)) {
    return { status: 'ambiguous', reason: `low_confidence_${confidence || 'unknown'}` };
  }
  // Mapbox returns [longitude, latitude] -- normalized here, once, so no
  // caller anywhere else in this codebase has to remember the axis order.
  return { status: 'resolved', longitude: coords[0], latitude: coords[1], reason: null };
}

// Fixed, public-safe error shape -- never forwards a raw provider/DB error
// message to the caller, matching tracking-pod's own safeError precedent.
function safeError(status, publicMessage) {
  return Response.json({ error: publicMessage }, { status });
}

// ============================================================================
// Deno HTTP entry point
// ============================================================================

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return safeError(405, 'Method not allowed');
  }

  const body = await request.json().catch(() => null);
  const orderId = body && typeof body.order_id === 'string' ? body.order_id : null;
  if (!orderId) return safeError(400, 'order_id is required');

  const authHeader = request.headers.get('authorization') || '';
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  // Founder-mandated: environment/config-driven, never hardcoded, never
  // committed. A missing token is treated exactly like an invalid one --
  // both are the same "credentials not usable" failure to the caller.
  const mapboxToken = Deno.env.get('CEFFLO_MAPBOX_ACCESS_TOKEN');

  // Caller-scoped client: respects RLS exactly as the Vendor's own browser
  // session would (orders_vendor policy = is_business_member(business_id)).
  // This is the authorization check -- a caller who cannot SELECT this
  // order under RLS gets nothing back, never a geocode result for an order
  // outside their business.
  const callerClient = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY') || '', {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });
  const { data: order, error: orderError } = await callerClient
    .from('orders')
    .select('id, business_id, delivery_address, location_status')
    .eq('id', orderId)
    .maybeSingle();

  if (orderError || !order) {
    return safeError(403, 'Order not found or not accessible');
  }

  // GEOCODE ONCE -> STORE -> REUSE, enforced here regardless of what the
  // caller intended: an already-resolved order is never re-sent to Mapbox.
  if (order.location_status === 'resolved') {
    return Response.json({ order_id: orderId, status: 'resolved', skipped: true, reason: 'already_resolved' });
  }

  const addressCheck = validateAddressInput(order.delivery_address);

  // Service-role client: the only privileged path allowed to call
  // set_order_location (revoked from anon/authenticated in the A1
  // migration) and check_rate_limit (service_role-only).
  const adminClient = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false } });

  if (!addressCheck.valid) {
    await adminClient.rpc('set_order_location', {
      p_order_id: orderId, p_status: 'failed', p_provider: 'mapbox_permanent', p_error: addressCheck.reason,
    });
    return Response.json({ order_id: orderId, status: 'failed', reason: addressCheck.reason });
  }

  if (!mapboxToken) {
    await adminClient.rpc('set_order_location', {
      p_order_id: orderId, p_status: 'failed', p_provider: 'mapbox_permanent', p_error: 'invalid_credentials',
    });
    return safeError(502, 'Geocoding provider is not configured');
  }

  // Cost-discipline: a bounded per-business rate limit on the one function
  // in this codebase that spends real money per call, independent of and
  // in addition to Mapbox's own account-level limits.
  const { data: allowed } = await adminClient.rpc('check_rate_limit', {
    p_key_hash: order.business_id, p_action: 'geocode_order', p_window_seconds: 60, p_max_requests: 30,
  });
  if (allowed === false) {
    await adminClient.rpc('set_order_location', {
      p_order_id: orderId, p_status: 'failed', p_provider: 'mapbox_permanent', p_error: 'rate_limited',
    });
    return safeError(429, 'Geocoding rate limit reached for this business, try again shortly');
  }

  let httpStatus;
  let bodyJson;
  try {
    const mapboxUrl = buildMapboxRequestUrl(addressCheck.address, mapboxToken);
    const response = await fetch(mapboxUrl);
    httpStatus = response.status;
    bodyJson = await response.json().catch(() => null);
  } catch (networkError) {
    await adminClient.rpc('set_order_location', {
      p_order_id: orderId, p_status: 'failed', p_provider: 'mapbox_permanent', p_error: 'network_failure',
    });
    return safeError(502, 'Unable to reach geocoding provider');
  }

  const result = classifyMapboxResult(httpStatus, bodyJson);

  if (result.status === 'resolved') {
    await adminClient.rpc('set_order_location', {
      p_order_id: orderId, p_status: 'resolved', p_latitude: result.latitude, p_longitude: result.longitude,
      p_provider: 'mapbox_permanent',
    });
    return Response.json({ order_id: orderId, status: 'resolved', latitude: result.latitude, longitude: result.longitude });
  }

  await adminClient.rpc('set_order_location', {
    p_order_id: orderId, p_status: result.status, p_provider: 'mapbox_permanent', p_error: result.reason,
  });
  return Response.json({ order_id: orderId, status: result.status, reason: result.reason });
});
