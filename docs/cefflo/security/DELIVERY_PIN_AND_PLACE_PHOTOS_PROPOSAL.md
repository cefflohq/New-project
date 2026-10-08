# Delivery pin + place reference photos — proposal

**Status:** APPROVED (Founder 2026-10-08) with changes: **photos dropped** — the delivery note carries the
clues; **map = OpenStreetMap + Leaflet** (temporary, until Mapbox). Built on staging: migration
`20261008120000_storefront_delivery_pin.sql`, Storefront pin (required), Driver App navigation to the pin + note.
Driver mini map, Vendor Web and Vendor App pin views/pickers built 2026-10-08; vendor write path = §7 (proposed, not applied). Not yet: tracking-link "add pin".
**Date:** 2026-10-08 · **Requested by:** Founder
**Touches LOCKED surfaces:** Public Storefront (e93f464), Driver Core (8d773c4) → re-lock after this change.

## 1. Problem (Founder)
Customers type an address that is on another lorong or a hard-to-find rumah lot; map links send the
rider to the wrong place; riders call the customer. Riders need the exact spot and visual clues.

## 2. Current truth (staging tomvvmwktehexwhktenw)
- `orders.latitude`, `orders.longitude` exist but are never set by the Storefront:
  `submit_storefront_order(p_slug, p_items, p_customer_name, p_customer_phone, p_delivery_address, p_delivery_notes, p_idempotency_key)`.
- No place photos (no column, no bucket). Driver App shows the address text only.
- Mapbox work is ON HOLD (2026-10-04).

## 3. Proposed behaviour
**Storefront checkout (customer)**
1. "Pin lokasi saya" → browser GPS (permission prompt) → map with a draggable pin to fine-tune
   (accuracy shown; low accuracy asks the customer to drag the pin to the house).
2. Search/drag fallback when GPS is denied.
3. Place photos: **3 required** (Founder) — e.g. depan rumah / pagar / tempat letak barang.
   Compressed on the phone (≤ 1600 px, JPEG, EXIF incl. GPS stripped), ≤ 5 MB each.
4. Order submits pin + photos with the existing idempotency key.

**Tracking link (customer)** — orders from WooCommerce/Shopify/API/manual have no pin: the tracking
page offers "Tambah pin & gambar lokasi" until the rider starts the run.

**Driver App (rider)** — stop card: "Buka peta" (exact lat/lng in Google Maps/Waze) + photo gallery
(tap to enlarge) + delivery notes.

**Vendor App/Web** — order detail shows the pin and photos; vendor can add/replace for phone orders.

## 4. Data & security design
| Item | Design |
|---|---|
| Pin | `orders.latitude/longitude` (existing) + new `location_accuracy_m numeric`, `location_source text check in ('gps','pin_adjusted','search','vendor')` |
| Photos | new table `order_place_photos(order_id, business_id, position 1–3, storage_path, created_at)`; private bucket `order-place-photos` (5 MB, image/jpeg/png/webp) |
| Customer upload | via Edge Function with a short-lived signed upload URL bound to the order + idempotency key / tracking token; no anonymous bucket write |
| Read | Owner/Operator of the business; the Rider assigned to the run containing the stop (signed URLs, 10 min); Helper no; public no |
| RPC | `submit_storefront_order` gains `p_latitude, p_longitude, p_accuracy, p_photo_paths` (validated: Malaysia bounds, paths owned by this checkout) |
| Abuse | existing storefront rate limit; max 3 photos; MIME + size enforced by bucket and function |
| Retention (PDPA) | photos deleted **30 days after the order is delivered/cancelled** (scheduled job); pin kept with the order |

## 5. Founder decisions needed
1. **Map tiles for the pin screen** — Mapbox is ON HOLD. Options: (a) lift the hold for this (Mapbox token), (b) OpenStreetMap tiles via Leaflet now, Mapbox later.
2. **Photos: 3 required, or 3 recommended (min 1)?** Required gives riders the most help but some customers will drop the order.
3. **Photo retention: 30 days after delivery** OK?
4. PDPA: privacy notice text must mention location + photos (PDPA track is paused; this adds a new personal-data category).

## 6. Tests (staging)
Owner/Operator read ✓; assigned rider read ✓; other rider / Helper / anon denied; upload without a valid
checkout denied; 4th photo rejected; oversize/wrong MIME rejected; out-of-Malaysia pin rejected;
idempotent resubmit keeps one set of photos; retention job deletes after 30 days.

## 7. Addendum — vendor pin for manual/phone orders (`set_order_pin`) — PROPOSED, NOT APPLIED
**Date:** 2026-10-08 · **Needs Founder approval before it is applied anywhere** (material auth/RLS-adjacent change, A-06).

**Problem.** Vendor Web / Vendor App now show the pin and offer a "Pin lokasi" picker on the manual order
form, but vendors cannot write `orders.latitude/longitude` (no UPDATE path for members). Without a write path the
picker cannot save; the apps treat the failure as a warning (order is saved, "pin could not be saved").

**Proposal.** One narrow `SECURITY DEFINER` RPC, draft in `supabase/migrations/20261008130000_vendor_set_order_pin.sql`:
`set_order_pin(p_order_id uuid, p_latitude double precision, p_longitude double precision) returns orders`.

| Rule | Design |
|---|---|
| Who | `is_business_member(order.business_id)` = active **Owner/Operator** only. Helper, Driver, other business, anon refused (`forbidden`). |
| Bounds | Malaysia: lat 0.5–7.6, lng 99.5–119.5; NULL/NaN refused. |
| State | Refused once the order is `delivered` or `cancelled` (allowed while in transit — a vendor may correct a wrong pin for the Driver). |
| Writes | `latitude`, `longitude`, `location_source='vendor'`, `location_accuracy_m=null`; also `location_status='resolved'`, `location_provider='vendor_pin'`, `location_resolved_at=now()` (same bookkeeping as `set_order_location_manual`, so planning treats it as resolved). |
| Audit | `delivery_events` row `order.pin_set`, actor = caller, role `vendor` (existing event pattern). |
| Grants | `revoke all … from public, anon; grant execute … to authenticated`. |

**Decisions for the Founder.**
1. OK to add this RPC (staging first)?
2. Allow pinning while the order is in transit, or only before pickup (`created`/`ready_for_pickup`)? Draft allows any non-closed state.
3. Known interaction: `update_order_details` clears the pin when the address changes, and `geocode-order` may later
   overwrite a pin for orders still `unresolved`. Draft marks a vendor pin `resolved`, so geocoding should skip it — to be verified on staging.

**Tests (staging, rollback-only, `tests/delivery_pin_set_order_pin.py`):** Owner ✓, Operator ✓, Helper ✗, Driver ✗,
other business ✗, anon ✗, out-of-bounds ✗, delivered ✗, audit row written. Not run yet.

