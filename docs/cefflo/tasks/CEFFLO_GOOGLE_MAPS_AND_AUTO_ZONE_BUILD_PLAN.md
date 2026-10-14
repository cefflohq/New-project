# CEFFLO — Google Maps Migration + Auto Zone Build Plan (DRAFT)

Status: DRAFT build plan, 2026-10-14. Implements the Founder decisions in
`CEFFLO_AUTO_ZONE_AND_RUN_SIZE_SPEC.md` §6a (D1–D6). Nothing here is built
or claimable yet.

## 1. Google terms check (2026-10-14)

Verified against Google's published pages; the live terms must be re-read
at contract time because Google revises them.

| Topic | What Google says | Effect on Cefflo |
|---|---|---|
| Place ID storage | Place IDs are exempt from the caching restriction and **may be stored indefinitely** ([Place IDs](https://developers.google.com/maps/documentation/places/web-service/place-id), [Geocoding policies](https://developers.google.com/maps/documentation/geocoding/policies)) | Store `place_id` on orders and businesses permanently |
| Geocoding lat/lng | May be cached **up to 30 consecutive days**, then deleted ([Service Specific Terms](https://cloud.google.com/maps-platform/terms/maps-service-terms)) | Google-derived coordinates are operational data only (§3) |
| Android Geocoder SDK | lat/lng/address from the Android Geocoder SDK may be cached indefinitely, only for the app's end-user feature, not to replace API calls ([Service Specific Terms](https://cloud.google.com/maps-platform/terms/maps-service-terms)) | Not relied on (server-side geocoding is the design) |
| Google content on non-Google maps | Not allowed (Maps Platform ToS) | Wherever Google results are shown on a map, the map is Google |
| Free usage | Since 1 Mar 2025, free usage is **per SKU**: Essentials 10,000 / month, Pro 5,000, Enterprise 1,000 ([Pricing categories](https://developers.google.com/maps/billing-and-pricing/pricing-categories)) | Each product below has its own free quota |
| Geocoding price | Essentials, 10,000 free, then about **USD 5 / 1,000** ([StoreRocket guide](https://storerocket.io/learn/google-maps-api-pricing)) | Only orders without a pin are geocoded |
| Dynamic Maps (web) | Essentials, 10,000 free loads, then about **USD 7 / 1,000** ([StoreRocket guide](https://storerocket.io/learn/google-maps-api-pricing)) | Web maps: Vendor Web, Customer Tracking, Storefront |
| Maps SDK Android/iOS | Reported **free, unlimited** ([StoreRocket guide](https://storerocket.io/learn/google-maps-api-pricing), [Scrap.io](https://scrap.io/google-maps-api-pricing-calculator-alternatives-2025)) | Driver App and Vendor App maps cost nothing |
| Places Autocomplete | Sources disagree: per-request ~USD 2.83 / 1,000 after 10,000 free, or per-session ([StoreRocket](https://storerocket.io/learn/google-maps-api-pricing), [Woosmap](https://www.woosmap.com/blog/google-maps-api-pricing-breakdown)) | **Verify on Google's pricing page**; use session tokens either way |
| Navigation deep link | Google Maps URLs open the Maps app; no API key, not billed | Pickup + each stop navigate out of the Driver App |

Prices in USD are third-party summaries of Google's list price; confirm on
Google's own pricing page before budgeting.

## 2. Where Google is used (D6)

| # | Moment | Google product | Cost |
|---|---|---|---|
| 1 | Customer fills address (Storefront) | Places Autocomplete + Dynamic Map + drag pin | Autocomplete + map loads |
| 2 | Vendor sets business address (Business Profile) | Same | Negligible (once) |
| 3 | Rider → pickup | Maps URL deep link | Free |
| 4 | Rider orders stops on a map (drag-and-drop list) | Maps SDK (Flutter `google_maps_flutter`) | Free (reported) |
| 5 | Rider → each stop | Maps URL deep link | Free |
| 6 | Customer / vendor see rider + progress | Dynamic Map (web), Maps SDK (apps); rider GPS is our data | Web map loads only |
| 7 | Imported / integration orders (text address) | Geocoding API | Per order without a pin |

## 3. How we geocode with Google — reuse the existing flow

**Answer: keep the existing design, swap the provider.** Today
`supabase/functions/geocode-order` already does the right thing:
server-side only, once per order, skips orders already `resolved`, keeps
the customer's own pin, sets `location_status`
(`resolved / ambiguous / failed`), and is rate-limited. We keep that
function and its callers (Vendor Web `order_actions.js`, `settings.js`;
Vendor App `vendor_repository.dart`) and change only:

1. **Provider call:** Mapbox v6 forward geocode → Google Geocoding API
   (`region=my`, `components=country:MY`), server key in
   `CEFFLO_GOOGLE_MAPS_SERVER_KEY` (Edge secret, never in a client build).
2. **Confidence:** Google `location_type` + `partial_match` map onto the
   existing statuses: `ROOFTOP` / `RANGE_INTERPOLATED` and not partial →
   `resolved`; `GEOMETRIC_CENTER` / `APPROXIMATE` or partial match →
   `ambiguous` (vendor fixes the pin); zero results / errors → `failed`.
   Only `resolved` orders are auto-zoned or planned (spec §3.1).
3. **What we store:**
   - `orders.place_id` / `businesses.place_id` — permanent.
   - `latitude/longitude` + `location_provider='google'` +
     `location_resolved_at` — kept **at most 30 days**.
   - Our own coordinates are kept normally and marked by source:
     `customer_pin`, `vendor_pin` (dragged on the map / corrected),
     `rider_gps`. A vendor or customer dragging the pin turns a Google
     point into our own point.
4. **30-day job:** a daily scheduled job clears Google-sourced lat/lng
   older than 30 days on orders that are **finished** (delivered,
   cancelled, failed). Active orders are re-resolved from `place_id`
   (Place Details, location field) before the 30 days run out. Delivery
   history keeps POD, rider GPS, the address text and `place_id`.
5. **Gap fixed in the same phase:** imported and integration orders
   (CSV / Excel / Sheets / Drive / Shopify / Woo / Wix / API) are **not**
   geocoded automatically today; they wait for a manual edit. The import
   and `integrations-inbound` paths will queue `geocode-order` for every
   new order without a pin (batched, rate-limited).

## 4. Build phases

Each phase ships on staging, with tests, before the next starts.

**Phase 0 — Google account + keys (Founder / ops)**
- Google Cloud project + billing, budgets and quota caps per API (alert at
  50 / 80 / 100 %), so testing can never run up an unexpected bill.
- Keys: server key (Geocoding, Place Details; IP-unrestricted Edge
  function, API-restricted), browser key (Maps JS + Places; restricted to
  Cefflo domains), Android + iOS keys (restricted to app ids).

**Phase 1 — Geocoding on Google (backend)** — §3
- `geocode-order` provider swap + confidence mapping + `place_id` column +
  `location_source` + 30-day job + auto-queue for imports/integrations.
- Tests: pure-logic tests for the response classifier (as today), SQL
  tests for the 30-day clear and "pin always wins".

**Phase 2 — Address entry (Storefront + Business Profile)** — moments 1, 2
- Places Autocomplete with session tokens → Place Details (location) →
  Google map with a draggable pin → save `place_id` + pin as `customer_pin`
  / `vendor_pin`.
- Surfaces: Storefront (`store/`), Vendor Web settings, Vendor App
  Business Profile.

**Phase 3 — Hexagon zones + auto zone (backend)** — spec §3.1, D1, D4
- H3 cells (resolution 9) for each business's coverage radius + 20 %;
  each cell given to the official area (`admin_areas`) holding its centre;
  zone = named group of cells; one cell → one zone.
- `orders.zone_source` (`manual` / `auto`), auto assignment on create /
  resolve / boundary change, manual always wins, "Outside coverage".
- Postgres: H3 extension (`h3-pg`) if available on Supabase, otherwise
  cells precomputed in the Edge function and stored as text ids.

**Phase 4 — Run size + merge + shape-following split** — D2, D3, D5
- `businesses.run_size_min/max` (default 10 / 15, editable).
- `propose_delivery_plan` v2: merge nearby under-minimum zones in the same
  direction; split big zones into contiguous hexagon patches; rider-fit
  check; flags. Backward-compatible response.
- Settings → Run size on Vendor Web + Vendor App; Plan screen shows
  several runs per zone, merges and flags.

**Phase 5 — Maps on every surface switch to Google** — moments 3–6
- Driver App: `google_maps_flutter` for the stop-order map; Navigate =
  Maps URL deep link for pickup and each stop.
- Vendor App + Vendor Web: Google maps for orders, zones (hexagons), live
  riders.
- Customer Tracking: Google map for the rider (also unblocks the "View live
  map" that waits on a Mapbox token today).
- Remove Mapbox code paths and the `CEFFLO_MAPBOX_*` secrets once every
  surface is on Google; keep the free OpenFreeMap / CARTO fallback for
  builds without a key (dev, demo).

**Phase 6 — Verification + truth update**
- End-to-end on staging: storefront order → auto zone → plan (merge /
  split) → dispatch → rider deep-link navigation → tracking map.
- Cost check against the Google console after a week of staging use.
- Update `01_PRODUCT_TRUTH.md` §18.2 states only after verification.

## 5. Risks
- Pricing / terms change: budgets and quota caps in Phase 0; re-read terms
  before production.
- Malaysian addresses without house numbers geocode as `APPROXIMATE` →
  marked `ambiguous`, vendor drags the pin; customers pin at the source.
- H3 extension availability on Supabase → fallback in Phase 3.
- Mapbox removal touches all five map surfaces → Phase 5 last, one surface
  at a time, fallback tiles kept.
