# CEFFLO — Auto Zone Assignment + Target Run Size (SPEC, DRAFT)

Status: **DRAFT — Founder decisions 1 and 3 recorded 2026-10-14 (§6a); 2, 5, 6 still open.** Nothing here is built or claimable.
Truth state today: FUTURE (Product Truth §18.2 "Smart Zone Clustering",
"Target Run Size / run profiles", "Smart Run Builder").
Date: 2026-10-14.

## Ringkasan (BM)

Order yang ada koordinat akan **masuk zon secara automatik** ikut sempadan
zon (Setapak, Seremban, Cheras…). Dalam setiap zon, order dipecahkan jadi
**run bersaiz 10–15 order**, setiap run berkumpul rapat dari segi lokasi,
satu run untuk satu rider. Semua ini dikira oleh **algoritma Cefflo sendiri**
(tiada AI, tiada Google). Google hanya diperlukan untuk tukar alamat teks
jadi koordinat bagi order yang datang tanpa pin (import / integrasi). Vendor
tetap semak dan luluskan cadangan sebelum dispatch.

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
   Proposed defaults **min 10, max 15** (Founder to confirm, §6).
2. Inside each zone, for N plannable orders:
   - N ≤ max → one run.
   - N > max → k = ceil(N / max) runs, sizes balanced (e.g. 32 → 11/11/10,
     22 → 11/11), never above max.
   - N < min → still one run, labelled "Below target size" so the vendor
     can merge, wait, or dispatch anyway. Never blocked.
3. Splitting is **by location**, deterministic: orders are ordered by
   bearing (angle) from the business service origin and cut into k
   contiguous slices (a "sweep"), so each run covers one wedge of the zone
   instead of interleaving. Each slice is then sequenced with the existing
   nearest-neighbour step.
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
- Required only for orders arriving without a pin. Provider choice
  (Mapbox today on HOLD vs Google Geocoding) is a **separate Founder
  decision**; this spec works with either. Low-confidence results stay
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

## 6. Founder decisions needed
1. **Approve auto zone assignment** (§3.1), including "manual always wins".
2. **Default run size**: min 10 / max 15? Editable per business?
3. **Below-minimum zones**: one small run flagged (proposed), or try to
   merge with the neighbouring zone?
4. **Overlapping zones** rule: nearest zone centre (proposed)?
5. **Split method**: sweep by bearing from the service origin (proposed,
   simple and deterministic) — or other preference?
6. **Geocoding provider** for text-address orders: Google vs Mapbox (separate
   pricing/terms review requested).

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

## 6b. Still open
- D2: default run size — minimum **10** confirmed in discussion; maximum
  15 to confirm. Editable per business?
- Hexagon cell size (proposed H3 resolution 8, ≈ 0.7 km² per cell, fine
  enough for Klang Valley streets; resolution 7 ≈ 5 km² if too fine).
- D5: split method for big zones (sweep by bearing, proposed).
- D6: geocoding provider (Google vs Mapbox).

## 7. Acceptance criteria
- A resolved order inside exactly one active zone gets that zone
  automatically; outside all zones it stays Unzoned and is listed.
- A manually zoned order is never changed by auto assignment.
- Changing a zone boundary re-zones only orders not yet in a run.
- 32 plannable orders in one zone with max 15 → 3 runs of 11/11/10, each
  geographically contiguous, each sequenced; same input → identical plan.
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
