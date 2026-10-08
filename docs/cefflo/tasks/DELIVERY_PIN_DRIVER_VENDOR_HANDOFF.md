# Handoff — Delivery pin map on Driver App + Vendor App/Web

**From:** Claude A (2026-10-08) · **Founder-approved feature** (see `docs/cefflo/security/DELIVERY_PIN_AND_PLACE_PHOTOS_PROPOSAL.md`, photos dropped, OpenStreetMap/OpenFreeMap temporary until Mapbox).
**Branch:** `official/staging` (work in place, no new branch/worktree). **Do not deploy** — Claude A deploys after you finish.

## Already done (do not redo)
- Migration `supabase/migrations/20261008120000_storefront_delivery_pin.sql` (applied on staging):
  `orders.latitude/longitude` (existing), new `orders.location_accuracy_m numeric`,
  `orders.location_source text` check in `('gps','pin_adjusted','map','vendor')`;
  `submit_storefront_order(..., p_latitude, p_longitude, p_location_accuracy_m, p_location_source)`.
- Storefront pin UI (reference implementation — copy its look and behaviour): `store/store.js`
  section `// ---- delivery pin` (MapLibre GL 4.7.1 from cdn.jsdelivr + style
  `https://tiles.openfreemap.org/styles/positron`, fixed centre pin, locate button, zoom +/-, accuracy chip,
  pin counts only after GPS or a user map move at zoom ≥ 14, attribution "© OpenStreetMap · OpenFreeMap")
  and CSS `/* Delivery pin — CEFFLO UI over MapLibre/OpenFreeMap */` in `store/store.css`.
  Gotcha: MapLibre sets `.maplibregl-map { position: relative }` → give the canvas
  `position: absolute !important; inset: 0; width: 100%; height: 100%`.
- Driver App: `RiderOrder.latitude/longitude` (lib/data/models.dart), `DriverStop.latitude/longitude/note`
  (lib/data/driver_models.dart, mapped in lib/core/app_state.dart `_toStop`), `openNavigation()` in
  lib/core/dial.dart, navigation `_RoundAction` + note + "pinned" line in lib/ui/screens/operations.dart (~1470).

## Task 1 — Driver App (`apps/rider_mobile`)
1. In the stop detail card (operations.dart, where `openNavigation` is used) add a **mini map** (≈ 180 px,
   rounded, same CEFFLO look) showing the customer pin when `stop.latitude != null`:
   use `flutter_map` with an OpenFreeMap-compatible source **or** a static raster fallback; must work on
   Flutter **web** (the Driver ships as a PWA) and Android/iOS. Non-interactive or pan-only; tap opens navigation.
2. Below it a full-width **"Navigasi"** button (same as the round action). Keep the address fallback when no pin.
3. No pin → show a small muted line "Pelanggan tidak pin lokasi — guna alamat" (EN/MS ARB keys).
4. `flutter analyze` clean, `flutter test` green.

## Task 2 — Vendor Web (`apps/vendor_web`)
1. Order detail (`js/pages/orders.js` detail panel): mini map with the pin (MapLibre/OpenFreeMap, same UI
   tokens) + "Buka di peta" link (`https://www.google.com/maps/search/?api=1&query=lat,lng`).
2. Orders list: small "Tiada pin" chip on orders without coordinates (i18n EN/MS in `js/i18n.js`).
3. Manual/phone orders: in the create/edit order form, a "Pin lokasi" picker using the **same fixed-centre-pin UI**
   as the Storefront; saves via the RPC in Task 4 with source `vendor`.

## Task 3 — Vendor App (`apps/vendor_mobile`)
Same as Task 2 in Flutter: order detail mini map + "Buka di peta", "Tiada pin" chip in the orders list,
pin picker in the manual order form/edit (fixed centre pin, locate, zoom). ARB keys EN + MS (+ other locales
the app already ships). `flutter analyze` clean, `flutter test` green.

## Task 4 — Backend (needs the Founder's OK before applying; write the proposal section first)
Vendors cannot write `orders.latitude/longitude` today. Add a SECURITY DEFINER RPC
`set_order_pin(p_order_id uuid, p_latitude double precision, p_longitude double precision)`:
- caller must be Owner/Operator of the order's business (`is_business_member`, Helper excluded);
- Malaysia bounds (lat 0.5–7.6, lng 99.5–119.5); refuse once the order is delivered/cancelled;
- sets `location_source = 'vendor'`, `location_accuracy_m = null`; audit via the existing order events pattern.
New migration file `supabase/migrations/2026100813xxxx_vendor_set_order_pin.sql`. Add the section to the
proposal doc above and **ask the Founder before applying**. Apply on staging only after approval:
guard every psql with `[[ "$DATABASE_URL" == *tomvvmwktehexwhktenw* ]] || exit 1`
(env `/home/cefflo/cefflo-ops/staging.env`, never print secrets). Production `lmaxtrubwdniovxyuqdy` is FORBIDDEN.
Tests: Owner ✓, Operator ✓, Helper ✗, Driver ✗, other business ✗, anon ✗, out-of-bounds ✗, delivered ✗.

## Rules
- Reply to the Founder in Bahasa Melayu; code/commits/docs in English.
- Do not commit: `.claude/`, `docs/cefflo/brand/assets/logo/cefflo-bimi.svg`, `docs/cefflo/finos-framer-source-audit.*`,
  `docs/cefflo/legal/`, `wrangler.jsonc`, `apps/*/analysis_options.yaml`,
  `docs/cefflo/website/reports/CEFFLO_MARKETING_FINAL_COMPLETION_REPORT.md`.
- No live GPS / ETA / route-optimisation claims in UI copy.
- Commit per task with trailer:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and push to `official/staging`.
- **Do not deploy.** When done, list commits + what was tested + what was not.
