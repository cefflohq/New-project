# CEFFLO — Auto Zone, Run Size + Google Maps MASTER GUIDELINE

Status: **Guideline for build.** Founder decisions D1–D6 recorded
2026-10-14. Nothing here is LIVE or claimable until each phase is built
and verified (Product Truth §13). This file replaces the separate spec and
build-plan drafts of the same date.

Contents
- Part A — Product spec: auto zone assignment + target run size
- Part B — Google Maps terms, geocoding approach and phased build plan

## Panduan ringkas (BM)

1. **Zon** ikut kawasan sebenar (Setapak, Bangsar, Sentul, PJ…), dibina
   dari sel heksagon. Satu sel = satu zon, jadi zon tak bertindih.
2. **Liputan** ikut radius vendor (contoh 10 km), boleh lebih sehingga
   +20 % ikut muka bumi. Order lebih jauh ditanda "Outside coverage".
3. **Order masuk zon secara automatik** bila koordinatnya tepat. Zon yang
   vendor pilih sendiri sentiasa menang.
4. **Saiz run** default min 10, maks 15 order; vendor boleh ubah.
5. **Zon kecil** (bawah minimum) digabung dengan zon berdekatan yang
   sehaluan. Zon besar dipecah **ikut bentuk zon**, bukan potong kek.
6. **Google** untuk carian alamat, geocoding, peta dan navigasi (deep link
   ke Google Maps). `place_id` disimpan kekal; koordinat dari Google
   maksimum 30 hari; pin pelanggan/vendor dan GPS rider ialah data kita.
7. **Geocoding** guna fungsi sedia ada `geocode-order`, cuma tukar penyedia
   dari Mapbox ke Google. Order dari import/integrasi akan di-geocode
   automatik.
8. **Vendor tetap luluskan** setiap cadangan run sebelum dispatch. Tiada
   AI dan tiada auto-dispatch.

---

# Part A — Product spec

## 1. Problem

Vendors receive orders from the Storefront (customer drops a pin) and from
imports / integrations (CSV, Excel, Sheets, Drive, Shopify, WooCommerce,
Wix, API: text address only). Riders must deliver by area so they do not
criss-cross town. Today the vendor sorts orders into zones by hand and a
busy zone becomes one oversized run.

## 2. Current state (verified in code, 2026-10-14)

| Piece | Today | Where |
|---|---|---|
| Order coordinates | `orders.latitude/longitude` + `location_status` (`unresolved / resolved / ambiguous / failed`) | `202609030001_s4_11_batch_1_geocoding.sql` |
| Text address → coordinates | Mapbox Permanent Geocoding, once per order, stored | `supabase/functions/geocode-order` |
| Zone boundary | Polygon per zone (drawn, or auto from official mukim/bandar areas) — **display only** | `20261013090000_zone_boundaries.sql`, `functions/zone-boundary` |
| Order → zone | **Manual** (`zone_id` chosen by the vendor) | `create_delivery(..., p_zone_id)` |
| Plan proposal | Groups by `zone_id`, vehicle/capacity check, nearest-neighbour sequence, haversine. **One zone = one run, no size limit.** A zone larger than any rider's capacity is reported unplannable, not split. | `propose_delivery_plan` (`202609030004_...optimization_engine.sql`) |
| Commit | Vendor reviews, then `build_rider_run`; rider may resequence (`save_run_sequence`) | unchanged by this spec |

## 3. Scope

### 3.1 Auto zone assignment
1. When an order has `location_status = 'resolved'` and no zone, the server
   assigns the **active zone of the same business whose boundary contains
   the point** (point-in-polygon).
2. Triggers: order created, coordinates resolved/corrected, zone boundary
   created/changed/deleted, zone (de)activated. Re-evaluation only touches
   orders that are **not yet in a run** (never moves an order inside a
   planned or active run).
3. Point inside **several** zones (overlap): pick the zone whose boundary
   centre is nearest the point; ties → lowest zone id (deterministic).
4. Point inside **no** zone: order stays **Unzoned** and is shown to the
   vendor as "Outside your zones" (never guessed into the nearest zone).
5. A zone the **vendor set by hand** on an order is respected: auto
   assignment never overwrites a manual choice (`zone_source = 'manual'`
   vs `'auto'`).
6. Orders without trustworthy coordinates (`unresolved / ambiguous /
   failed`) are never auto-zoned; they stay in the existing "needs a pin"
   list.

### 3.2 Target Run Size
1. Per business setting: **minimum** and **maximum** orders per run.
   Defaults **min 10, max 15**, editable per vendor (D2).
2. Inside each zone, for N plannable orders:
   - N ≤ max → one run.
   - N > max → k = ceil(N / max) runs, sizes balanced (e.g. 32 → 11/11/10,
     22 → 11/11), never above max.
   - N < min → first merged with a nearby under-minimum zone in the same
     direction (D3, §6a); if still under the minimum, one run labelled
     "Below target size" so the vendor can wait or dispatch anyway. Never
     blocked.
3. Splitting follows the **zone's own shape** (D5): never a fixed
   "cake-slice" from the vendor. The zone's occupied hexagon cells are grown
   into k contiguous patches along cell adjacency (each patch starts from
   the cell farthest from the others, then takes its nearest neighbouring
   cells until it holds its share of orders). Each patch becomes one run
   and is sequenced with the existing nearest-neighbour step. Deterministic:
   same orders in → same runs out.
4. Rider fit: each proposed run must also fit a compatible rider's
   remaining capacity (existing `rider_effective_capacity` check). The
   effective max per run = min(business max, compatible rider capacity).
   No rider fits → run proposed **without a rider** and flagged, instead of
   the whole zone becoming unplannable.
5. Unzoned orders are planned as their own group with the same size rules.

### 3.3 Vendor review (unchanged principle)
- Output is a **proposal** only. The vendor reviews, may move orders
  between proposed runs, change the rider, then commits with the existing
  `build_rider_run`. Riders may still resequence stops. No auto-dispatch.

### 3.4 Geocoding for text-address orders
- Required only for orders arriving without a pin. Provider: **Google
  Geocoding** (D6); method in Part B §B3. Low-confidence results stay
  `ambiguous` and go to "needs a pin" — never auto-zoned on a guess.
- Storefront orders keep the customer's own pin (our data, no provider
  call).

## 4. Out of scope
- AI / LLM planning, turn-by-turn navigation, road-network distances or
  traffic, auto-dispatch, multi fulfilment point, changes to active runs,
  cross-business riders, customer notifications.

## 5. Data / API changes (proposed)
- `orders.zone_source text check in ('manual','auto')` (null when unzoned).
- `businesses.run_size_min int`, `businesses.run_size_max int`
  (defaults from §6; max ≥ min ≥ 1).
- `assign_order_zone(order_id)` (internal) + re-evaluation on the
  triggers in §3.1; owner/operator only, audited like other zone changes.
- `propose_delivery_plan` extended: split by run size, per-run flags
  (`below_target_size`, `no_rider_fits`), unzoned group. Response stays
  backward compatible for current Vendor Web / Vendor App callers.
- Vendor Web + Vendor App: Settings → "Run size" (min/max); Plan screen
  shows multiple runs per zone and the flags; Orders shows "Outside your
  zones" and "Auto" vs "Manual" zone.

## 6. Founder decisions

All six decided on 2026-10-14 — see §6a.

## 6a. Founder decisions recorded (2026-10-14)

**D1 — Auto zone assignment: APPROVED, with a hexagon zone model.**
- The map is divided into a fixed grid of **hexagon cells** (proposed: the
  open H3 grid; cell size to confirm, §6b). Every point on the map belongs
  to exactly one cell.
- A **zone is a named group of cells** (e.g. "Setapak", "Bangsar",
  "Brickfields"); its coverage is the union of its cells. The vendor can
  add or remove cells from a zone. The current official-area boundary
  (mukim / bandar) is used only to propose the first cells of a new zone.
- Each **vendor has a coverage radius** (existing
  `businesses.service_coverage_radius_km`, e.g. 10 km). Zones are built
  only from cells inside that radius, with a **tolerance of up to +20 %**
  (10 km → a zone may reach ~12 km) so zones follow real terrain and
  roads. Orders beyond the tolerance are flagged "Outside coverage", never
  dropped silently.
- Auto assignment = the order's point → its cell → the zone that owns the
  cell. Manual zone on an order still wins (§3.1 rule 5).

**D3 — Zones below the minimum: MERGE with a nearby zone.**
- If a zone has fewer orders than the minimum (e.g. Bangsar 5) and a
  **nearby** zone is also below the minimum (e.g. Brickfields 6), the
  planner merges them into one run (5 + 6 = 11 ≥ 10).
- "Nearby" (proposed): the two zones touch (share a cell edge) or their
  centres are within a short distance, **and** they lie in roughly the
  same direction from the vendor (bearing difference ≤ 45°) so the rider
  travels one way ("sehaluan").
- Merging repeats with the next nearest under-minimum zone until the run
  reaches the minimum or nothing nearby is left; the result never exceeds
  the maximum. A group still under the minimum is proposed as one run
  flagged "Below target size" (still dispatchable).
- Merging only changes the **proposed run**, not the zones themselves.

**D4 — Overlapping zones: RESOLVED by D1.** With the hexagon grid every
cell belongs to one zone only, so zones cannot overlap and no overlap rule
is needed. The system refuses to put one cell in two zones.

**D2 — Run size: default min 10 / max 15, editable per vendor.**
Reason (Founder field experience): a run starts after pickup (e.g. pick up
09:30–10:00, start 10:00). 10 orders take an experienced rider about 1.5 h
in good weather, a new rider 2–2.5 h, up to ~3 h in rain; an experienced
rider can finish 15 in about 2 h. Vendors adjust min/max in Settings to fit
their riders, food type and area.

**Zone source + cell size (D1 detail).** Zones follow the **existing
local area divisions** — Klang Valley: Setapak, Bangsar, Sentul, Selayang,
Gombak, Batu Caves, Petaling Jaya, Subang Jaya, Brickfields… (official
areas already loaded in `public.admin_areas`). Hexagon cells are fine
enough (proposed H3 resolution 9, ≈ 0.1 km²) that each cell is given to
the area that contains its centre, so the cell group traces the real area
outline. Vendors may rename, merge or trim zones.

**D5 — Split method: follows the zone's shape (contiguous hexagon
patches), not a cake-slice.** See §3.2 rule 3.

**D6 — Geocoding / address search provider: GOOGLE.** Google Places
Autocomplete for customer and vendor address entry (search + drag the
pin), Google Geocoding for text-address orders from imports and
integrations, Google maps where Google data is shown. Navigation to pickup
and to each stop is a deep link into the Google Maps app. Replaces Mapbox
(currently on HOLD). Storage rule: keep Google `place_id`; Google-derived
coordinates are kept only for the operational window allowed by Google's
terms (to be verified, ~30 days); coordinates from our own sources
(customer/vendor dragged pin, rider GPS, vendor correction) are kept
normally. Pricing and terms check to be done before build.

## 7. Acceptance criteria
- A resolved order inside exactly one active zone gets that zone
  automatically; outside all zones it stays Unzoned and is listed.
- A manually zoned order is never changed by auto assignment.
- Changing a zone boundary re-zones only orders not yet in a run.
- 32 plannable orders in one zone with max 15 → 3 runs of 11/11/10, each
  a contiguous patch of the zone's own cells (no cake-slice), each sequenced; same input → identical plan.
- Bangsar 5 + Brickfields 6 (adjacent, same direction), min 10 → one
  merged run of 11. A lone 7-order zone with nothing nearby → 1 run
  flagged "Below target size", still dispatchable.
- No cell belongs to two zones; an order beyond coverage radius + 20 %
  is flagged "Outside coverage".
- No run exceeds the business max or the assigned rider's capacity.
- Existing flows (manual zone, `build_rider_run`, `save_run_sequence`,
  rider resequencing) behave exactly as before.
- Tests: SQL tests for point-in-polygon, overlap, unzoned, manual-wins,
  split sizes, determinism; UI checks on Vendor Web + Vendor App.

## 8. Rollout
1. Staging only; existing businesses keep manual zoning until they turn
   on "Auto zone" (default on for new businesses — Founder to confirm).
2. Marketing may not claim the feature until it is LIVE and verified
   (Product Truth §13).

## 9. Risks
- Official area boundaries may not match how a vendor thinks of an area →
  vendor can redraw the boundary (already supported) or set zone by hand.
- Straight-line distance ignores rivers/highways → runs are proposals; the
  vendor and rider can adjust.
- Bad geocodes put orders in the wrong zone → only `resolved` (high
  confidence) orders are auto-zoned.

---

# Part B — Google Maps + build plan

## B1. Google terms check (2026-10-14)

Verified against Google's published pages; the live terms must be re-read
at contract time because Google revises them.

| Topic | What Google says | Effect on Cefflo |
|---|---|---|
| Place ID storage | Place IDs are exempt from the caching restriction and **may be stored indefinitely** ([Place IDs](https://developers.google.com/maps/documentation/places/web-service/place-id), [Geocoding policies](https://developers.google.com/maps/documentation/geocoding/policies)) | Store `place_id` on orders and businesses permanently |
| Geocoding lat/lng | May be cached **up to 30 consecutive days**, then deleted ([Service Specific Terms](https://cloud.google.com/maps-platform/terms/maps-service-terms)) | Google-derived coordinates are operational data only (§B3) |
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

## B2. Where Google is used (D6)

| # | Moment | Google product | Cost |
|---|---|---|---|
| 1 | Customer fills address (Storefront) | Places Autocomplete + Dynamic Map + drag pin | Autocomplete + map loads |
| 2 | Vendor sets business address (Business Profile) | Same | Negligible (once) |
| 3 | Rider → pickup | Maps URL deep link | Free |
| 4 | Rider orders stops on a map (drag-and-drop list) | Maps SDK (Flutter `google_maps_flutter`) | Free (reported) |
| 5 | Rider → each stop | Maps URL deep link | Free |
| 6 | Customer / vendor see rider + progress | Dynamic Map (web), Maps SDK (apps); rider GPS is our data | Web map loads only |
| 7 | Imported / integration orders (text address) | Geocoding API | Per order without a pin |

## B3. How we geocode with Google — reuse the existing flow

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
   Only `resolved` orders are auto-zoned or planned (Part A §3.1).
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

## B4. Build phases

Each phase ships on staging, with tests, before the next starts.

**Phase 0 — Google account + keys (Founder / ops)**
- Google Cloud project + billing, budgets and quota caps per API (alert at
  50 / 80 / 100 %), so testing can never run up an unexpected bill.
- Keys: server key (Geocoding, Place Details; IP-unrestricted Edge
  function, API-restricted), browser key (Maps JS + Places; restricted to
  Cefflo domains), Android + iOS keys (restricted to app ids).

**Phase 1 — Geocoding on Google (backend)** — §B3 — **built 2026-10-14**
(`geocode-order` Google + Mapbox fallback, `pending` batch mode for imports,
integration orders auto-geocoded, migration `20261014140000_google_geocoding`
with `place_id` and the daily 30-day expiry job; tests
`tests/google_geocoding.py`. Known gap: an order still inside a run after
30 days keeps its Google point until the run ends. Deploy + live test on
staging pending.)
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

**Phase 3 — Hexagon zones + auto zone (backend)** — Part A §3.1, D1, D4
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

## B5. Risks
- Pricing / terms change: budgets and quota caps in Phase 0; re-read terms
  before production.
- Malaysian addresses without house numbers geocode as `APPROXIMATE` →
  marked `ambiguous`, vendor drags the pin; customers pin at the source.
- H3 extension availability on Supabase → fallback in Phase 3.
- Mapbox removal touches all five map surfaces → Phase 5 last, one surface
  at a time, fallback tiles kept.
