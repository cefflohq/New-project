# CEFFLO — Auto Zone Assignment + Target Run Size (SPEC, DRAFT)

Status: **DRAFT for Founder approval.** Nothing here is built or claimable.
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

## 7. Acceptance criteria
- A resolved order inside exactly one active zone gets that zone
  automatically; outside all zones it stays Unzoned and is listed.
- A manually zoned order is never changed by auto assignment.
- Changing a zone boundary re-zones only orders not yet in a run.
- 32 plannable orders in one zone with max 15 → 3 runs of 11/11/10, each
  geographically contiguous, each sequenced; same input → identical plan.
- 7 orders with min 10 → 1 run flagged "Below target size", still
  dispatchable.
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
