# CEFFLO GROW — MASTER R0–R7 PLAN

**STATUS: FOUNDER APPROVED — IMPLEMENTATION AUTHORIZED (PRODUCTION EXCLUDED)**

**Document type:** Master Reconciliation / Grow Implementation Planning Output
**Produced by:** Claude, per `CEFFLO_GROW_MASTER_REPOSITORY_IMPROVEMENT_BRIEF.md`
**Inputs:** `CEFFLO_GROW_READINESS_AUDIT.md`, `CEFFLO_BRAND_SYSTEM.md`, direct inspection of the actual `staging` repository
**Implementation authority:** Codex, authorized by the Founder for WT-1 through WT-6 subject to the dependency and preview gates in this document
**Production:** Strictly out of scope unless separately authorized

**Repository:** `/home/cefflo/New-project` · **Remote:** `cefflohq/New-project` · **Branch:** `staging` · **implementation baseline:** `ed8e074453a6e4f44309e2bced38b43a53d9707a` · local == `origin/staging` (0 ahead/behind) after an authorized fetch on 2026-09-02. The working tree carries known, isolated unrelated state (`marketing/index.html`, `.claude/`, and preview directories), which must remain untouched. The secondary worktree at `/home/cefflo/.codex/worktrees/a110/New-project` is clean on `codex/vendor-auth-production` @ `9539cb07b65ad0477b2af1e87076274fc56a0bfd`; Git proves that commit is already an ancestor of `staging`, 27 commits behind with zero unique commits. The prior collision hold is therefore closed at this baseline.

---

## ⚠️ Correction to the prior `CEFFLO_GROW_READINESS_AUDIT.md`

Per the master brief's own instruction to re-verify rather than trust the prior audit blindly, function-level tracing (at a granularity the original audit passes did not reach) found the prior audit's central claim — *"Vendor order and zone creation writes only to localStorage"* — is **half wrong**. Precise findings:

- **Order creation is REAL.** The actual "New Order" wizard (`wizSubmit`, defined `vendor/index.html:5189`) is overridden by `vendor/backend.js:250-259` to call the real `create_delivery` RPC, store the real tracking token, and refresh via real hydration — only *then* does it toast success. `window.CEFFLO_ENGINE.commands.createOrder`/`createProductionOrder` (`vendor/index.html:7720`) — the function the prior audit found — has **zero call sites anywhere in the codebase**. It is dead code, already superseded.
- **Hydration is REAL** for orders, riders, ratings, zones, delivery_sessions, rider_assignments, delivery_stops. `vendor/backend.js:247`: `hydrateOperationalStateFromBackend = hydrateCanonicalWorkspace;` — the same override pattern — and `hydrateCanonicalWorkspace` (`vendor/backend.js:133-171`) genuinely fetches all of these via real PostgREST reads, with an explicit code comment: *"Real S4-06.3/.5a data — distinct from the deprecated mock engine's same-named fields, which this canonical hydration path always overwrites."* `issues` and `order_status_history` remain hardcoded `[]` even here — that part of the prior finding stands.
- **Zone *creation* is still genuinely unreconciled** — `create_zone` (real, tested RPC) has zero call sites anywhere in Vendor. There is no live path, fake or real, that creates a standalone zone today.
- **One specific quick-action, `ACTIONS.assignZoneRider` (`vendor/index.html:7902-7909`), is still local-only** — it calls `CEFFLO_ENGINE.commands.createDeliverySession`/`assignZoneToRider` directly, is **not** in backend.js's override list, and shows a "Rider assigned successfully" toast before/independent of any real backend write. This is a distinct, narrower UI action from the real Run Builder flow (`confirmRunBuilder`, which IS real).
- **`inviteRiderCommand` (quick "add rider," `vendor/index.html:7890-7895`) is still local-only** — and this one is more than an incompleteness: it bypasses the trusted-invitation model entirely (locked decision D-03 in `docs/cefflo/05_DECISIONS.md`), which real RPCs (`create_rider_invitation`/`create_team_invitation`) already implement correctly elsewhere.
- **Order editing and zone rename/enable-disable are not fake — they simply don't exist in the UI at all.** `update_order_details` and `rename_zone`/`set_zone_status` are real, tested RPCs with **zero call sites** anywhere in Vendor.

This materially shrinks R0's actual scope. The reconciliation work is **four specific, bounded actions**, not a rebuild of order/zone creation.

---

## A. Program Executive Verdict

**Yes — R0 through R7 can be delivered incrementally, without a rebuild.** The corrected R0 finding above makes this more true, not less: the real RPC layer, the real canonical hydration path, and the real run/assignment/sequencing machinery already carry most of Grow's weight. What remains is: (1) four bounded reconciliation fixes, (2) a genuinely new location/coverage foundation (nothing to reconcile — nothing exists), (3) a deterministic planning layer that calls existing persistence, (4) wiring two already-real FOUNDR RPCs to a UI, (5) one narrowly-scoped recovery RPC, (6) an honest ETA/notification layer. None of this requires touching the proven session/assignment/stop/sequencing backend — only calling it, and in one case (recovery), adding one new function beside it.

---

## B. R0–R7 Readiness Table

| Stage | Current Readiness | Reusable Assets | Exact Gaps | Dependencies | Risk | Recommended Package |
|---|---|---|---|---|---|---|
| **R0** Reconciliation | **Better than prior audit stated** — order creation & hydration are real; 4 specific actions remain local-only | `wizSubmit`→`create_delivery`, `hydrateCanonicalWorkspace`, all 7 backend.js overrides, `create_zone`/`rename_zone`/`set_zone_status` (real, unused) | Zone creation UI, `assignZoneToRider` quick-action, `inviteRiderCommand` quick-add, issues/history read-back | None | Medium (was High) | WT-1 |
| **R1** Location | MISSING | `orders.latitude/longitude` columns (exist, unpopulated) | No acquisition mechanism at all | R0 (order shape must be stable first) | Blocks everything downstream | WT-2 |
| **R2** Coverage/Zones | MISSING (coverage) / CONFLICT (zones, per R0) | Real `zones` table+RPCs | No coverage concept; zone creation UI (R0 fixes this) | R0, R1 | Medium | WT-2 |
| **R3** Planning | PARTIAL | `build_rider_run`, `save_run_sequence`, idempotency pattern | No grouping/proposal logic at all | R1, R2, R0 (capacity) | Medium | WT-3 |
| **R4** Live Ops/Attention | PARTIAL (BACKEND-ONLY) | `admin_delivery_operations`, `admin_stuck_riders`, `vendor_report_delivery_issue`, Rider's real Leaflet integration | Zero FOUNDR call sites; no Vendor attention surface; 3 hardcoded mock arrays in FOUNDR | None (fully independent) | Low | WT-4 |
| **R5** Recovery | PARTIAL | `delivery_issue_reason` enum, `delivery_events`, locking idiom, terminal-cancellation pattern | No retry/reassign-after-pickup path at all | R0 | High (real product decision) | WT-5 |
| **R6** Customer Visibility | PARTIAL | Real tracking/POD/rating, `delivery_events` as event source | ETA never written; notifications absent (honestly) | R5 (for coherent recovery notifications) | Medium | WT-6 |
| **R7** Integration/Launch | N/A until R0-R6 land | Existing 57-file test suite discipline | Nothing to validate yet | R0-R6 | — | Final gate, no dedicated worktree |

---

## C. Dependency Graph

```
R0 (Reconciliation)
 ├─→ R1 (Location) ─→ R2 (Coverage/Zones) ─→ R3 (Planning)
 │                                                 │
 ├─→ R4 (Live Ops/Attention)  [fully parallel to R1/R2/R3]
 │                                                 │
 └─→ R5 (Recovery) ─────────────────────────────→ R6 (Customer Visibility/Notifications)
                                                    │
                                    R7 (Integration & Launch Validation)
                                    — depends on ALL of the above
```

**Can run in parallel today, once R0 lands:** R4 (Live Ops) is fully independent of R1/R2/R3/R5/R6 — it only needs real orders (already true) and its own two already-real RPCs. R1→R2→R3 is a strict chain. R5 depends only on R0 (needs real orders to reassign), not on R1/R2/R3. R6 depends on R5 for recovery-coherent notifications but its ETA-honesty and tracking-preservation parts could start once R0 is done.

---

## D. Founder Decision Record

*Every decision below was explicitly approved and locked by the Founder on 2026-09-02. Implementation must follow these decisions exactly.*

### D-01 — Coordinate acquisition method

**Status: APPROVED / LOCKED — option (a)**

**Why it matters:** Determines cost, UX, and reliability for the entire location foundation (R1). Nothing in R2/R3 can proceed meaningfully without this.

**Options:**
- (a) Client-side address autocomplete capturing lat/lng at order-entry time (near-zero marginal cost, needs a JS autocomplete widget).
- (b) Device GPS at order-entry time (free, but conflates "where the phone is" with "where the delivery is" — the master brief explicitly warns against treating these as equivalent).
- (c) Server-side batch geocoding via a paid provider (Google/Mapbox) run after order creation.
- (d) OneMap Malaysia / government geocoder (likely free/cheap, Malaysia-specific, less proven coverage than commercial providers).

**Locked decision:** Client-side address autocomplete captures and persists the real delivery-address latitude/longitude. Device GPS must not be used as the delivery coordinate and coordinates must never be fabricated. Reuse an existing approved provider/configuration if present; do not silently choose or contract a paid provider. If none exists, WT-2 reports that external dependency while independent packages continue.

**Consequence of deferring:** Zones, coverage, density, and any optimizer work all stay blocked.

### D-02 — Coverage model

**Status: APPROVED / LOCKED — option (a)**

**Why it matters:** Schema choice affects every downstream planning input and the future polygon upgrade path (R2.1).

**Options:**
- (a) Radius + centroid per business (cheapest, works for most home-business delivery patterns).
- (b) Named-area/postcode list (simple, Malaysian-postcode-friendly, no lat/lng math needed at all).
- (c) Polygon (most correct, most Vendor setup burden, needs PostGIS or manual point-in-polygon logic).

**Locked decision:** Radius + centroid per business for Grow V1. Polygon/PostGIS is deferred to Scale, while the V1 design must permit a future polygon addition without rebuilding radius records.

**Consequence of deferring:** Zone-membership validation (R2.3) has no real "is this order in my area" answer.

### D-03 — Rider capacity model

**Status: APPROVED / LOCKED — option (b)**

**Why it matters:** Affects the optimizer's design (R3.2); a wrong model misrepresents real physical delivery capacity.

**Options:**
- (a) No explicit capacity for V1 (optimizer fills runs up to today's existing manual pattern, with no hard limit).
- (b) Simple `max_active_orders int` field on `riders`.
- (c) Richer weight/volume capacity model.

**Locked decision:** Add nullable `max_active_orders int` per rider. Null behavior must be deterministic and documented. No weight/volume capacity model belongs in Grow V1.

**Consequence of deferring:** The optimizer either has no capacity awareness (a) or the schema commits prematurely to a physical model (c) that may not match how Vendors actually think about their riders.

### D-04 — Post-pickup recovery scope

**Status: APPROVED / LOCKED — option (a)**

**Why it matters:** This is the one genuine architectural gate standing between the current schema and Delivery Recovery V1 (R5.2). `reassign_rider` explicitly and intentionally refuses to touch anything past `ready_for_pickup`.

**Options:**
- (a) Build a new, narrowly-scoped Recovery RPC as detailed in the WT-5 package below — do **not** weaken `reassign_rider`'s existing guard.
- (b) Defer all post-pickup recovery to Scale; ship Grow V1 with pre-pickup-only reassignment.

**Locked decision:** Build a new narrowly scoped Recovery RPC. Do not modify or weaken `reassign_rider`. Recovery is allowed only in `issue`, moves only remaining eligible stops, never touches delivered stops, and must enforce locking, concurrency safety, business isolation, and complete delivery-event audit history. Split-run and automatic rebalancing remain out of scope.

**Consequence of deferring:** Grow ships without its second named differentiator (the first being Same-Day Autopilot / R3's planning layer).

### D-05 — Notification provider / build timing

**Status: APPROVED / LOCKED — option (c)**

**Why it matters:** Real per-message cost and a genuine vendor-lock-in decision (R6.3). Notifications are currently, deliberately, honestly absent from the codebase.

**Options:**
- (a) WhatsApp Business API (matches the existing customer-initiated `wa.me` link pattern already in the codebase; higher setup cost and approval process).
- (b) SMS via a Malaysian aggregator.
- (c) Defer the live send entirely for Grow V1; design and skeleton the event-driven outbox now, keep the current honest "no notifications" state until a provider is authorized.

**Locked decision:** Defer live WhatsApp/SMS delivery for Grow V1. Implement only credible ETA honesty and the notification architecture document. Do not build an outbox table, Edge Function, or provider integration, and never claim a message was sent. Live notifications require separate future Founder authorization.

**Consequence of deferring:** Zero cost/vendor risk if deferred; the customer must keep manually revisiting the tracking link either way, today and under option (c).

### D-06 — `inviteRiderCommand` disposition

**Status: APPROVED / LOCKED — option (a)**

**Why it matters:** This quick-add-rider path (`vendor/index.html:7890-7895`) doesn't just leave a gap — it actively bypasses the trusted-invitation security model that locked decision D-03 (`docs/cefflo/05_DECISIONS.md`) already establishes, and that real RPCs (`create_rider_invitation`/`create_team_invitation`) already correctly implement elsewhere in the same app.

**Options:**
- (a) Remove the quick-add button entirely; route all rider-adding through the real, existing invitation flow.
- (b) Keep a "quick add" affordance, but make it call a real RPC that still respects invitation/join semantics (i.e., it would just be a faster on-ramp into the same real flow, not a bypass of it).

**Locked decision:** Remove `inviteRiderCommand` and every live quick-add path that bypasses trusted invitations. All rider additions use the existing invitation flow; no shortcut replacement RPC is authorized for Grow V1.

**Consequence of deferring:** This UI element continues silently contradicting a locked security/product decision for as long as it remains unaddressed.

### D-07 — Grow UI acceptance and unified visual-system sequencing

**Status: APPROVED / LOCKED — visual polish deferred by Founder on 2026-09-02**

**Locked decision:** Visual-polish acceptance for Grow R0–R7 is deferred to a separate Founder-approved unified UI-system Master MD covering Marketing, Vendor, Rider, Customer Tracking, and FOUNDR. That future system will use Black, White, Graphite, and Signal Lime as the operational brand signal; the current purple styling is not the future brand baseline.

Grow UI work must remain minimal, structurally sound, accessible, and functionally usable. It must preserve semantic structure and component boundaries for the future unified pass without introducing an independent visual direction. Per-package visual-polish gates are replaced by functional browser-verification gates. This waiver does not relax staging authentication, authoritative RPC execution, persistence after refresh, second-session visibility where applicable, RLS/business isolation, browser runtime, console, mobile usability, regression, or truthful-success requirements.

---

## E. Exact Worktree Plan

*Smallest justified decomposition — six worktrees, not one per R-stage.*

| Worktree | R-stage Coverage | Scope | Depends On | Parallel-Safe? | Likely Files | Migrations | Tests | Must Not Touch | Founder Gate | Merge Order |
|---|---|---|---|---|---|---|---|---|---|---|
| **WT-1 Reconcile** | R0 | Zone creation UI, `assignZoneToRider`→real RPCs, remove `inviteRiderCommand` quick-add, wire issues/history read-back, remove fake GPS check | None | **No — must check `codex/vendor-auth-production` first (collision risk, Section F below)** | `vendor/index.html`, `vendor/backend.js`, `rider/index.html:1636` | None | New wiring tests matching `s4_08_batch_1_frontend_wiring.py` style | `wizSubmit`, `confirmRunBuilder`, and the other 5 already-real overrides (call, don't modify) | Functional browser verification; visual polish deferred | 1st |
| **WT-2 Location + Coverage** | R1, R2 | Address autocomplete + coordinate capture; minimal `coverage_area` table; zone-membership validation | WT-1 (order shape) | No | New migration, `vendor/index.html` order form + coverage setup screen, S4-10E submission form | Yes — new small migration | New RLS/coordinate tests | S4-10E's closed decline/idempotency logic (additive only) | Functional browser verification; visual polish deferred | 2nd |
| **WT-3 Planning Layer** | R3 | New deterministic zone-bucket planner RPC; capacity field; Vendor "Review & Dispatch" surface | WT-2 | No | New migration/RPC, `vendor/index.html` dispatch UI | Yes — capacity column + planner RPC | New idempotency/concurrency test matching `build_rider_run`'s own rigor | `build_rider_run`, `save_run_sequence` bodies (call only) | Functional browser verification; visual polish deferred | 3rd |
| **WT-4 FOUNDR Live Ops + Need Attention** | R4 | Wire `admin_delivery_operations`/`admin_stuck_riders` into FOUNDR; add Leaflet (reuse Rider's pattern); Vendor Need Attention list; replace 3 mock arrays | None | **Yes — fully independent, safe to start immediately** | `foundr/index.html`, `foundr/backend.js`, Vendor Orders tab | None | Wiring tests | Vendor order-creation logic | Functional browser verification; visual polish deferred | Anytime, independent |
| **WT-5 Recovery V1** | R5 | New narrowly-scoped post-pickup partial-reassignment RPC | WT-1 (real orders) | No | New migration/RPC | Yes | New dedicated test suite matching `s4_06_batch_4` rigor | `reassign_rider`'s existing pre-pickup guard | Functional browser verification; visual polish deferred | 4th (parallel with WT-3 OK — different files) |
| **WT-6 Customer Visibility** | R6 | ETA honesty pass plus notification architecture document; no outbox, Edge Function, or live provider | WT-5 (recovery coherence) | Partial — ETA-honesty part can start after WT-1 | `customer/index.html`, documentation | ETA change only if a durable backend write is required | New ETA tests | POD/rating (already correct, untouched) | Functional browser verification; visual polish deferred | 5th |

---

## F. Collision Analysis with Active Worktrees

The collision gate was resolved with read-only Git evidence on 2026-09-02. `codex/vendor-auth-production` is clean at `9539cb07b65ad0477b2af1e87076274fc56a0bfd`; that commit is the merge base and is already an ancestor of current `staging`. The branch is 27 commits behind with zero unique commits. Its sole historical commit changed only the Vendor dashboard workload-card CSS and `pageDashboardProposed` helpers in `vendor/index.html`; it did not change `vendor/backend.js`, authentication/session code, or the WT-1/WT-2 target functions.

**Collision gate: CLOSED.** WT-1 and WT-2 may proceed in dependency order from the recorded `staging` baseline. The secondary worktree remains out of scope and must not be modified.

---

## G. Codex Implementation Packages

### WT-1 — Reconcile

**Goal:** Close the four specific real-vs-local-only gaps identified in the correction above. Nothing else in Vendor changes.

**Exact scope:**
1. Zone creation: add a "New Zone" UI action calling the real `create_zone(p_business_id, p_name)` RPC (already exists, `202608280002_s4_06_batch_3_zones.sql`), following the exact same override pattern as the other 7 backend.js-reassigned actions (define a stub in `vendor/index.html`, override it in `vendor/backend.js`, `await` the RPC, only toast success after it resolves, `await hydrateCanonicalWorkspace()` to refresh).
2. `ACTIONS.assignZoneRider` (`vendor/index.html:7902-7909`): replace the `CEFFLO_ENGINE.commands.createDeliverySession`/`assignZoneToRider` calls with real `create_delivery_session` (if no active session — reuse the existing RPC already called elsewhere in backend.js at line 320) + `assign_rider`/`build_rider_run` as appropriate to the single-order-quick-assign use case. Move this action into the same backend.js-override list as the other 7.
3. Remove `inviteRiderCommand` (`vendor/index.html:7890-7895`) and its UI trigger entirely. Route all rider-adding through the existing real `create_rider_invitation` flow (already wired for the proper Team screen per prior audit findings). This implements locked Founder Decision D-06 option (a).
4. Wire real reads for `issues`/`order_status_history` into `hydrateCanonicalWorkspace` (`vendor/backend.js:169-170`, currently `state.issues = []; state.orderStatusHistory = [];`) — real `delivery_events` fetch, scoped by business.
5. `rider/index.html:1636`: delete `const away=Math.random()<0.18;` and its `confirm(t('far_location'))` gate entirely — do not substitute another approximation. (Real GPS-based proximity is R1/WT-2 scope, not this package — if WT-2 lands first, this can be revisited to use real distance; until then, remove the false claim.)

**Existing RPC/schema to reuse:** `create_zone`, `rename_zone`, `set_zone_status`, `create_delivery_session`, `assign_rider`, `build_rider_run`, `create_rider_invitation`, `delivery_events` (all real, tested, untouched).

**Migrations required:** None.

**Prohibited changes:** Do not modify `wizSubmit`, `approveOrderAction`, `confirmAssignRiderOrder`, `confirmDeactivateRider`, `confirmRunBuilder`, `saveBusinessProfile`, or `hydrateCanonicalWorkspace`'s existing (already-real) fields. Do not modify `create_delivery`, `build_rider_run`, `save_run_sequence`, or any RPC body. Do not touch `zones_vendor`/`orders_vendor`/`riders_vendor`/`assignments_vendor` RLS policies.

**Acceptance criteria:** A Vendor-created zone is visible via direct Postgres read. `assignZoneRider` produces a real `rider_assignments` row. No UI path can create a rider without a real invitation record. `delivery_events` for an order are visible in the Vendor UI. No `Math.random()`-based proximity claim remains anywhere in `rider/index.html`.

**Automated tests:** New test file matching `tests/s4_08_batch_1_frontend_wiring.py`'s style — static grep-based assertions that each reconciled action's handler contains the expected `api.rpc(...)` call and does not reference `CEFFLO_ENGINE.commands.createOrder`/`assignZoneToRider`/`inviteRiderCommand`. A rollback-only DB test proving a zone created via the new path is a real row.

**Browser/manual validation:** Create a zone in Vendor, refresh, confirm it persists. Use the zone-assign quick action, confirm a real `rider_assignments` row exists. Confirm the rider-add button is gone or routes through invitation. Confirm the Rider app's arrival screen no longer shows a random "far from location" prompt.

**Founder preview:** Yes — this changes visible Vendor/Rider behavior.

**Dependency/merge order:** First. Blocks WT-2, WT-3, WT-5. Collision gate is closed — see Section F.

---

### WT-2 — Location + Coverage

**Goal:** The smallest trustworthy location and coverage foundation.

**Exact scope:**
- Add client-side address-autocomplete-driven coordinate capture to the Vendor order wizard (`wizSubmit`'s form) and to S4-10E's public submission form, writing real `latitude`/`longitude` at creation time (per Founder Decision D-01).
- New minimal `business_coverage_areas` table: `business_id`, `center_lat`, `center_lng`, `radius_meters`, nullable `polygon` (reserved, unused in V1) — per Founder Decision D-02.
- New RPC `set_business_coverage(p_business_id, p_center_lat, p_center_lng, p_radius_meters)`, `security definer`, owner/operator-gated like every other Vendor-mutation RPC.
- New RPC `is_within_coverage(p_business_id, p_lat, p_lng)` (or inline check in `create_delivery`/`submit_public_order`) — simple haversine-distance-vs-radius check, no PostGIS needed for radius math.
- Zone-membership: keep `orders.zone_id` manual-assignment-only (already correct per the audit), just ensure the real hydration path (now confirmed real) is what populates the Vendor's zone-assignment UI.

**Existing RPC/schema to reuse:** `orders.latitude/longitude` (exist), `create_delivery`, `submit_public_order`, `create_zone` (from WT-1), `is_business_member`.

**Migrations required:** Yes — one new migration for `business_coverage_areas` + the two new RPCs, following the exact `SECURITY DEFINER`+`set search_path=public`+explicit revoke/grant pattern used throughout.

**Prohibited changes:** Do not install PostGIS/pgRouting (not needed for radius math). Do not modify `zones`/`orders.zone_id` schema. Do not touch S4-10E's closed idempotency/decline logic.

**Acceptance criteria:** New orders carry real coordinates captured at entry, distinguishable from missing/legacy. A business can set a coverage radius. An out-of-coverage submission is accepted into Needs Review with a clear Vendor warning, is excluded from automatic delivery planning until coverage or zone is resolved, and retains its original address and coordinates unchanged.

**Automated tests:** New RLS/business-isolation test for the coverage table (two-business negative matrix, matching the established pattern). Haversine-distance unit test with known coordinate pairs.

**Browser/manual validation:** Enter an address in the order wizard, confirm coordinates are captured. Set a business coverage radius in Vendor, confirm it persists and survives refresh.

**Founder preview:** Yes — new Vendor coverage-setup screen and order-form autocomplete.

**Dependency/merge order:** Second, after WT-1. Collision gate is closed — see Section F.

---

### WT-3 — Planning Layer

**Goal:** Orders in → reviewable plan ready, using existing execution machinery.

**Exact scope:**
- `riders.max_active_orders int null` column (Founder Decision D-03, option b).
- New deterministic RPC `propose_delivery_plan(p_business_id, p_delivery_date)`: groups eligible orders (`delivery_status='created'`, `approved_at is not null`, `zone_id is not null`) by zone, respects `max_active_orders` if set, returns a **proposal only** (no writes) shaped as `{zone_id, rider_id, order_ids[]}[]` for Vendor review.
- New Vendor "Review & Dispatch" screen consuming that proposal, letting the Vendor adjust before committing — commit calls the **existing** `build_rider_run`+`save_run_sequence` per zone/rider group, reusing their existing idempotency-key pattern for the whole multi-run commit.

**Existing RPC/schema to reuse:** `build_rider_run`, `save_run_sequence` (call unchanged), `zones`, `orders.zone_id`, `riders.max_active_orders` (new, from this package).

**Migrations required:** Yes — the capacity column + the one new read-only proposal RPC (writes nothing itself).

**Prohibited changes:** Do not modify `build_rider_run` or `save_run_sequence` internals. Do not introduce PostGIS/clustering. Do not call this "AI" anywhere in code, copy, or commit messages.

**Acceptance criteria:** Given a real set of approved, zoned, geocoded orders, the proposal RPC returns a deterministic, reviewable grouping. Committing it produces real `delivery_sessions`/`rider_assignments`/`delivery_stops` via the existing RPCs, consumable unchanged by the existing Rider Plan Route flow.

**Automated tests:** New concurrency/idempotency test matching `s4_06_batch_5a_build_rider_run_concurrency.py`'s rigor for the multi-run commit path. Determinism test — same input, same output, twice.

**Browser/manual validation:** Generate a plan for a real set of test orders, review it in the new Vendor screen, dispatch, confirm the Rider app shows the resulting run exactly as if it had been built manually today.

**Founder preview:** Yes — new "Review & Dispatch" surface.

**Dependency/merge order:** Third, after WT-2.

---

### WT-4 — FOUNDR Live Ops + Need Attention

**Goal:** Make already-real backend data visible; replace mock arrays.

**Exact scope:**
- `foundr/index.html`: call `admin_delivery_operations()`/`admin_stuck_riders()` (both real, unused) and render real data in the existing Overview/Delivery Operations panels.
- Add Leaflet 1.9.4 (matching Rider's exact integration, `rider/index.html:17,467,2075-2076`) to `foundr/index.html` for the Live Ops map.
- Delete the three hardcoded arrays (`foundr/index.html:712,784,819`) entirely.
- Vendor: new thin "Need Attention" list querying `orders` where `delivery_status='issue'`, reusing already-real `delivery_events`/issue-reason data (once WT-1 wires the read-back).

**Existing RPC/schema to reuse:** `admin_delivery_operations`, `admin_stuck_riders`, `vendor_report_delivery_issue`, `delivery_issue_reason` enum, `delivery_events`.

**Migrations required:** None.

**Prohibited changes:** No FOUNDR redesign beyond wiring real data into existing panels. Do not modify the two admin RPCs. Do not touch Vendor order-creation logic.

**Acceptance criteria:** FOUNDR's Live Ops panel shows real active runs/riders. No hardcoded mock array remains anywhere in `foundr/index.html`. Vendor shows a real, non-empty-when-applicable Need Attention list.

**Automated tests:** Wiring test matching `s4_08_batch_1_frontend_wiring.py` style, asserting the mock arrays are gone and the real RPC calls exist.

**Browser/manual validation:** Trigger a real delivery issue via the Rider app, confirm it appears in both the new Vendor Need Attention list and FOUNDR's panel within one refresh cycle.

**Founder preview:** Yes.

**Dependency/merge order:** Independent — can start immediately, in parallel with everything else. **Not held by the collision in Section F.**

---

### WT-5 — Recovery V1

**Goal:** One narrowly-scoped RPC enabling post-pickup partial reassignment, per Founder Decision D-04.

**Exact scope:** New RPC, e.g. `recover_remaining_delivery(p_order_id uuid, p_new_rider_id uuid, p_reason text)`:
- Must be a **new function**, not a modification of `reassign_rider`.
- Guard: only callable when `delivery_status='issue'` (not any other status).
- Row-locks the order (matching the existing `for update` idiom).
- Never touches stops already `delivered`.
- Writes a full `delivery_events` entry (`event_type='delivery.recovered'`, old/new rider, reason).
- Business-scoped via `is_business_member`, same as every other Vendor-mutation RPC.
- Concurrency-safe against a second simultaneous recovery attempt on the same order (the row lock handles this).

**Existing RPC/schema to reuse:** `delivery_events`, the `for update` locking idiom, `is_business_member`, the `delivery_issue_reason` enum (for the reason parameter's shape).

**Migrations required:** Yes — one new RPC, `security definer`, explicit revoke-then-grant to `authenticated` only.

**Prohibited changes:** Do not modify `reassign_rider`'s existing guard in any way. Do not build split-run/rebalancing (Scale, explicitly out of scope).

**Acceptance criteria:** An order in `'issue'` state past `ready_for_pickup` can be reassigned to a new rider; completed stops are provably untouched; `delivery_events` shows full history; a second concurrent recovery attempt on the same order fails safely, not silently.

**Automated tests:** New dedicated test suite matching `tests/s4_06_batch_4_run_accept_decline_reassign.py`'s rigor — must include: recovery on an order with some delivered/some pending stops (only pending move), a concurrency test (two simultaneous recovery calls), a cross-business negative test.

**Browser/manual validation:** Simulate a rider going stuck mid-run (via `admin_stuck_riders`' detection, from WT-4), trigger recovery from Vendor, confirm the Rider app for the *new* rider shows only the remaining stops, and the *old* rider's app no longer shows them.

**Founder preview:** Yes — new Vendor recovery action.

**Dependency/merge order:** Fourth, after WT-1 (needs real orders). Can run parallel to WT-3 (different files).

---

### WT-6 — Customer Visibility

**Goal:** Honest ETA, and a designed (not necessarily built) notification boundary.

**Exact scope:**
- ETA: smallest credible source — even a simple "N stops ahead in the run" sequence-position-derived estimate, written to `orders.estimated_arrival_at` at each `rider_transition`. If no credible source is ready, **display nothing rather than a fabricated time** (per the master brief's own R6.2 instruction).
- Notification architecture: produce a design document describing an eventual event-driven provider boundary, idempotency expectations, consent/template requirements, failure handling, and observability. Per locked Founder Decision D-05, do not build an outbox table, Edge Function, or provider integration in Grow V1.

**Existing RPC/schema to reuse:** `orders.estimated_arrival_at` (exists, unpopulated), `delivery_events` (real event source), `public_tracking` (unchanged).

**Migrations required:** Only if the credible ETA implementation needs a durable backend write. No notification migration is authorized.

**Prohibited changes:** Do not rebuild tracking/POD/rating (already correct). Do not claim a message was sent before a provider confirms it.

**Acceptance criteria:** ETA shown to a customer is either real (sequence-derived) or absent — never fabricated. The architecture document must not imply that live notifications are implemented or sent.

**Automated tests:** ETA computation and honesty tests appropriate to the chosen credible source.

**Browser/manual validation:** Confirm the Customer tracking page shows a real or absent ETA, never a stale/fake one, across a full order lifecycle.

**Founder preview:** Yes.

**Dependency/merge order:** Fifth — ETA implementation follows WT-5 for recovery coherence; the architecture document may be prepared independently.

---

## H. Launch-Critical vs Deferred

| Item | Classification |
|---|---|
| WT-1 Reconciliation (all 4 fixes) | **LAUNCH CRITICAL** — a mismatched Vendor operational reality is not shippable |
| Fake GPS proximity removal | **LAUNCH CRITICAL** — active fabricated capability claim |
| WT-2 Location + Coverage | **GROW V1** |
| WT-3 Planning Layer | **GROW V1** |
| WT-4 FOUNDR Live Ops + Need Attention | **GROW V1** (arguably launch-critical for FOUNDR's own credibility, but not blocking Vendor/Rider/Customer launch) |
| WT-5 Recovery V1 | **GROW V1** |
| ETA honesty (WT-6 half) | **GROW V1** |
| Notification build (WT-6 half, pending D-05) | **POST-LAUNCH** unless Founder authorizes sooner |
| PostGIS/pgRouting installation | **SCALE** — not needed for V1's radius/haversine math |
| Split-run/auto-rebalancing | **SCALE** |
| Historical density/ML-based planning | **SCALE** |
| External rider capacity | **OUT OF SCOPE** |
| Order editing UI, zone rename/enable-disable UI | **POST-LAUNCH** (RPCs already exist; genuinely minor) |
| Stale-docs reconciliation (R7.6) | **POST-LAUNCH**, after implementation is proven — do not do this now |

---

## I. Final Definition of Done

Cefflo can credibly be called launch-ready Grow when:

1. Every Vendor operational mutation (order, zone, assignment, rider-add) writes only through a real, tested, SECURITY DEFINER RPC — no local-engine-only path remains reachable from any live button.
2. A Vendor-created order/zone/assignment survives refresh and is visible from a second browser/session, proven by test.
3. No UI surface shows a fabricated capability (fake GPS proximity, fake ETA, fake notification-sent, fake Live Ops data) — every claim is either real or absent.
4. New orders carry real, honestly-sourced coordinates; businesses have a real coverage boundary.
5. A Vendor can generate a reviewable delivery plan from real orders and dispatch it through the existing, unmodified run/assignment/sequencing machinery.
6. FOUNDR's Live Ops and Need Attention surfaces show real data, with zero hardcoded arrays remaining.
7. A mid-run rider failure can be recovered by the Vendor without touching already-completed deliveries, with full audit history.
8. Customer tracking shows only what the backend can prove.
9. The full ORDERS→...→DELIVERED-TODAY loop (R7.1) passes an end-to-end test on one known commit.
10. Security/RLS/business-isolation regression suite passes with zero new gaps introduced by any worktree.
11. Each UI-visible worktree passes its functional browser-verification gate. Founder visual-polish approval is explicitly deferred to the future unified UI-system Master MD per D-07.
12. This still does **not** authorize production deployment — that remains a separate, later gate per the master brief's own R7.7 boundary.

---

## Execution Restrictions (carried forward from the authorizing brief)

- **Founder implementation authorization has been given for WT-1 through WT-6**, subject to their real dependency, security, staging, and UI preview gates.
- **No production deployment is authorized** under any circumstance by this document.
- **The `codex/vendor-auth-production` collision gate is closed** by the evidence recorded in Section F.
- WT-1 through WT-6 must still follow the dependency order in Sections C/E/G. Functional browser-verification gates remain mandatory; visual-polish acceptance is deferred under D-07.
- If no approved address-autocomplete provider/configuration exists, only the provider-dependent WT-2 path is blocked; every independently executable authorized package must continue.
- The second worktree (`codex/vendor-auth-production`) must not be entered or modified as part of acting on this document.
- Live notification delivery, notification outbox/Edge Function work, PostGIS/pgRouting, split-run/automatic rebalancing, Production access, and any feature outside this Master MD remain unauthorized.

---

**Functional browser verification remains required before any UI-visible worktree is accepted as functionally complete. Visual-polish acceptance is deferred by Founder under D-07.**
