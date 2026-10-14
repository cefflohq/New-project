import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Order and business geocoding (Auto Zone + Google Maps master guideline
// Part B §B3, Founder decision D6, 2026-10-14).
//
// Provider: Google Geocoding API (server key CEFFLO_GOOGLE_MAPS_SERVER_KEY,
// Edge secret only). Mapbox Permanent Geocoding (CEFFLO_MAPBOX_ACCESS_TOKEN)
// stays as the fallback while the Google key is not set on an environment,
// so nothing breaks during the switch. The provider abstraction the A1
// migration built (orders.location_status, set_order_location,
// set_order_location_manual) is unchanged; only the provider behind it moves.
//
// GEOCODE ONCE -> STORE -> REUSE: this function never calls a provider for
// an order that is already 'resolved', whatever the caller intended.
//
// Google terms: the place_id is stored permanently; Google coordinates are
// kept at most 30 days (daily job _expire_google_coordinates, migration
// 20261014190000). Pins set by people (customer_pin, vendor_pin,
// manual_correction) are our own data and are never expired.
//
// Modes (POST body):
//   { order_id }                 geocode one order
//   { business_id, pending: true } geocode the business's unresolved orders
//                                  (after an import; batched, rate-limited)
//   { business_id }              locate the business's own address (read-only)

const MAPBOX_GEOCODE_URL = 'https://api.mapbox.com/search/geocode/v6/forward';
const GOOGLE_GEOCODE_URL = 'https://maps.googleapis.com/maps/api/geocode/json';

// ============================================================================
// Pure, Deno-independent logic -- exercised directly with plain Node in
// tests (tests/s4_11_batch_12_mapbox_geocoding.py,
// tests/google_geocoding.py), not only inside the Deno Edge runtime.
// ============================================================================

// Reject empty/whitespace/too-short input before ever spending a provider
// request on it.
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

// Mapbox v6 match_code.confidence tiers accepted as a resolved point.
const ACCEPTABLE_CONFIDENCE = new Set(['exact', 'high', 'medium']);

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
  // Mapbox returns [longitude, latitude] -- normalized here, once.
  return { status: 'resolved', longitude: coords[0], latitude: coords[1], reason: null };
}

// Google Geocoding request, biased to and restricted by the business's
// country (ISO 3166-1 alpha-2, e.g. 'MY').
function buildGoogleRequestUrl(address, apiKey, countryIso2, baseUrl) {
  const url = new URL(baseUrl || GOOGLE_GEOCODE_URL);
  const cc = /^[A-Za-z]{2}$/.test(String(countryIso2 || '')) ? String(countryIso2).toUpperCase() : 'MY';
  url.searchParams.set('address', address);
  url.searchParams.set('region', cc.toLowerCase());
  url.searchParams.set('components', `country:${cc}`);
  url.searchParams.set('key', apiKey);
  return url.toString();
}

// Google location_type values precise enough for a delivery point. A
// GEOMETRIC_CENTER / APPROXIMATE result, or any partial match, is a street,
// area or guess: 'ambiguous', so the vendor confirms the pin.
const GOOGLE_PRECISE = new Set(['ROOFTOP', 'RANGE_INTERPOLATED']);

function classifyGoogleResult(httpStatus, bodyJson) {
  if (httpStatus === 429) return { status: 'failed', reason: 'rate_limited' };
  if (httpStatus >= 500) return { status: 'failed', reason: 'provider_unavailable' };
  if (httpStatus !== 200) return { status: 'failed', reason: `unexpected_status_${httpStatus}` };
  const apiStatus = bodyJson && typeof bodyJson.status === 'string' ? bodyJson.status : null;
  if (apiStatus === 'ZERO_RESULTS') return { status: 'failed', reason: 'no_result' };
  if (apiStatus === 'REQUEST_DENIED') return { status: 'failed', reason: 'invalid_credentials' };
  if (apiStatus === 'OVER_QUERY_LIMIT' || apiStatus === 'OVER_DAILY_LIMIT') return { status: 'failed', reason: 'rate_limited' };
  if (apiStatus === 'INVALID_REQUEST') return { status: 'failed', reason: 'invalid_request' };
  if (apiStatus === 'UNKNOWN_ERROR') return { status: 'failed', reason: 'provider_unavailable' };
  if (apiStatus !== 'OK') return { status: 'failed', reason: 'malformed_provider_response' };
  const results = Array.isArray(bodyJson.results) ? bodyJson.results : [];
  if (!results.length) return { status: 'failed', reason: 'no_result' };
  const first = results[0];
  const loc = first && first.geometry ? first.geometry.location : null;
  if (!loc || typeof loc.lat !== 'number' || typeof loc.lng !== 'number') {
    return { status: 'failed', reason: 'malformed_provider_response' };
  }
  const placeId = typeof first.place_id === 'string' && first.place_id ? first.place_id : null;
  const locationType = first.geometry.location_type || 'unknown';
  if (first.partial_match === true) {
    return { status: 'ambiguous', reason: 'partial_match', placeId };
  }
  if (!GOOGLE_PRECISE.has(locationType)) {
    return { status: 'ambiguous', reason: `low_precision_${String(locationType).toLowerCase()}`, placeId };
  }
  return { status: 'resolved', latitude: loc.lat, longitude: loc.lng, placeId, reason: null };
}

// Google when its key is set, Mapbox otherwise; null when neither is.
function pickProvider(googleKey, mapboxToken) {
  if (googleKey) return 'google';
  if (mapboxToken) return 'mapbox_permanent';
  return null;
}

// Fixed, public-safe error shape -- never forwards a raw provider/DB error.
function safeError(status, publicMessage) {
  return Response.json({ error: publicMessage }, { status });
}

// ============================================================================
// Provider call (Deno side)
// ============================================================================

function providerConfig() {
  const googleKey = Deno.env.get('CEFFLO_GOOGLE_MAPS_SERVER_KEY') || '';
  const mapboxToken = Deno.env.get('CEFFLO_MAPBOX_ACCESS_TOKEN') || '';
  return { provider: pickProvider(googleKey, mapboxToken), googleKey, mapboxToken };
}

// One provider request. Network failure -> { status: 'failed', reason:
// 'network_failure' }; every other outcome comes from the classifiers.
async function geocodeAddress(cfg, address, countryIso2) {
  let httpStatus;
  let bodyJson;
  try {
    const providerUrl = cfg.provider === 'google'
      ? buildGoogleRequestUrl(address, cfg.googleKey, countryIso2)
      : buildMapboxRequestUrl(address, cfg.mapboxToken);
    const response = await fetch(providerUrl);
    httpStatus = response.status;
    bodyJson = await response.json().catch(() => null);
  } catch (_) {
    return { status: 'failed', reason: 'network_failure', placeId: null };
  }
  return cfg.provider === 'google'
    ? classifyGoogleResult(httpStatus, bodyJson)
    : { ...classifyMapboxResult(httpStatus, bodyJson), placeId: null };
}

function clients(request) {
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  // Caller-scoped client: RLS decides what the caller may read, so a caller
  // outside the business gets nothing back.
  const callerClient = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY') || '', {
    global: { headers: { Authorization: request.headers.get('authorization') || '' } },
    auth: { persistSession: false },
  });
  // Service-role client: the only path allowed to call set_order_location
  // and check_rate_limit.
  const adminClient = createClient(supabaseUrl, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'), {
    auth: { persistSession: false },
  });
  return { callerClient, adminClient };
}

async function businessCountry(client, businessId) {
  const { data } = await client.from('businesses').select('country_iso2').eq('id', businessId).maybeSingle();
  return (data && data.country_iso2) || 'MY';
}

// Geocodes one order the caller can read and stores the outcome through the
// canonical set_order_location RPC.
async function geocodeOrder(adminClient, cfg, order, countryIso2) {
  const orderId = order.id;
  // GEOCODE ONCE -> STORE -> REUSE.
  if (order.location_status === 'resolved') {
    return { order_id: orderId, status: 'resolved', skipped: true, reason: 'already_resolved' };
  }
  const providerName = cfg.provider || 'google';
  const addressCheck = validateAddressInput(order.delivery_address);
  if (!addressCheck.valid) {
    await adminClient.rpc('set_order_location', {
      p_order_id: orderId, p_status: 'failed', p_provider: providerName, p_error: addressCheck.reason,
    });
    return { order_id: orderId, status: 'failed', reason: addressCheck.reason };
  }
  if (!cfg.provider) {
    await adminClient.rpc('set_order_location', {
      p_order_id: orderId, p_status: 'failed', p_provider: providerName, p_error: 'invalid_credentials',
    });
    return { order_id: orderId, status: 'failed', reason: 'not_configured', httpStatus: 502 };
  }
  // Cost discipline: per-business limit on the one function that spends
  // money per call, on top of the provider's own quota caps.
  const { data: allowed } = await adminClient.rpc('check_rate_limit', {
    p_key_hash: order.business_id, p_action: 'geocode_order', p_window_seconds: 60, p_max_requests: 30,
  });
  if (allowed === false) {
    await adminClient.rpc('set_order_location', {
      p_order_id: orderId, p_status: 'failed', p_provider: providerName, p_error: 'rate_limited',
    });
    return { order_id: orderId, status: 'failed', reason: 'rate_limited', httpStatus: 429 };
  }

  const result = await geocodeAddress(cfg, addressCheck.address, countryIso2);
  if (result.status === 'resolved') {
    await adminClient.rpc('set_order_location', {
      p_order_id: orderId, p_status: 'resolved', p_latitude: result.latitude, p_longitude: result.longitude,
      p_provider: providerName, p_place_id: result.placeId,
    });
    return { order_id: orderId, status: 'resolved', latitude: result.latitude, longitude: result.longitude };
  }
  await adminClient.rpc('set_order_location', {
    p_order_id: orderId, p_status: result.status, p_provider: providerName, p_error: result.reason,
    p_place_id: result.placeId,
  });
  return {
    order_id: orderId, status: result.status, reason: result.reason,
    httpStatus: result.reason === 'network_failure' ? 502 : undefined,
  };
}

// ============================================================================
// { business_id } -- the business's own pickup address (read-only: the
// Vendor saves the point through set_business_service_area).
// ============================================================================
async function geocodeBusinessAddress(request, businessId) {
  const { callerClient, adminClient } = clients(request);
  const { data: business, error } = await callerClient
    .from('businesses')
    .select('id, address, country_iso2')
    .eq('id', businessId)
    .maybeSingle();
  if (error || !business) return safeError(403, 'Business not found or not accessible');

  const addressCheck = validateAddressInput(business.address);
  if (!addressCheck.valid) {
    return Response.json({ business_id: businessId, status: 'failed', reason: addressCheck.reason });
  }
  const cfg = providerConfig();
  if (!cfg.provider) return safeError(502, 'Geocoding provider is not configured');

  const { data: allowed } = await adminClient.rpc('check_rate_limit', {
    p_key_hash: businessId, p_action: 'geocode_business', p_window_seconds: 60, p_max_requests: 5,
  });
  if (allowed === false) {
    return safeError(429, 'Geocoding rate limit reached for this business, try again shortly');
  }
  const result = await geocodeAddress(cfg, addressCheck.address, business.country_iso2);
  if (result.reason === 'network_failure') return safeError(502, 'Unable to reach geocoding provider');
  if (result.status === 'resolved') {
    return Response.json({
      business_id: businessId, status: 'resolved', latitude: result.latitude, longitude: result.longitude,
      place_id: result.placeId,
    });
  }
  return Response.json({ business_id: businessId, status: result.status, reason: result.reason });
}

// ============================================================================
// { business_id, pending: true } -- unresolved orders after an import or an
// integration. Bounded per call; the caller (or the next import) picks up
// the rest.
// ============================================================================
const PENDING_BATCH = 25;

async function geocodePendingOrders(request, businessId) {
  const { callerClient, adminClient } = clients(request);
  const { data: orders, error } = await callerClient
    .from('orders')
    .select('id, business_id, delivery_address, location_status')
    .eq('business_id', businessId)
    .eq('location_status', 'unresolved')
    .in('delivery_status', ['created', 'ready_for_pickup'])
    .order('created_at', { ascending: true })
    .limit(PENDING_BATCH);
  if (error) return safeError(403, 'Business not found or not accessible');
  const cfg = providerConfig();
  const country = await businessCountry(callerClient, businessId);
  const counts = { resolved: 0, ambiguous: 0, failed: 0 };
  for (const order of orders || []) {
    const out = await geocodeOrder(adminClient, cfg, order, country);
    counts[out.status] = (counts[out.status] || 0) + 1;
    if (out.reason === 'rate_limited' || out.reason === 'not_configured') break;
  }
  return Response.json({ business_id: businessId, processed: (orders || []).length, ...counts, more: (orders || []).length === PENDING_BATCH });
}

// ============================================================================
// Deno HTTP entry point
// ============================================================================

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return safeError(405, 'Method not allowed');
  }

  const body = await request.json().catch(() => null);
  const businessId = body && typeof body.business_id === 'string' ? body.business_id : null;
  if (businessId && body.pending === true) return geocodePendingOrders(request, businessId);
  if (businessId) return geocodeBusinessAddress(request, businessId);
  const orderId = body && typeof body.order_id === 'string' ? body.order_id : null;
  if (!orderId) return safeError(400, 'order_id is required');

  const { callerClient, adminClient } = clients(request);
  const { data: order, error: orderError } = await callerClient
    .from('orders')
    .select('id, business_id, delivery_address, location_status')
    .eq('id', orderId)
    .maybeSingle();
  if (orderError || !order) {
    return safeError(403, 'Order not found or not accessible');
  }

  const out = await geocodeOrder(adminClient, providerConfig(), order, await businessCountry(callerClient, order.business_id));
  if (out.httpStatus === 502) return safeError(502, out.reason === 'network_failure' ? 'Unable to reach geocoding provider' : 'Geocoding provider is not configured');
  if (out.httpStatus === 429) return safeError(429, 'Geocoding rate limit reached for this business, try again shortly');
  return Response.json({ order_id: out.order_id, status: out.status, latitude: out.latitude, longitude: out.longitude, reason: out.reason, skipped: out.skipped });
});
