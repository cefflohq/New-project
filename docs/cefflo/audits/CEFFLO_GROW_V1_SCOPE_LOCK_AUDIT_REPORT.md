# CEFFLO GROW V1 — SCOPE LOCK AUDIT REPORT

**Task:** `docs/cefflo/tasks/CEFFLO_GROW_V1_FLOW_1_SCOPE_LOCK_MASTER.md` + `docs/cefflo/tasks/CEFFLO_GROW_V1_VEHICLE_CAPACITY_SCOPE_ADDENDUM.md`\
**Baseline:** `staging @ 9e7ea2dae61deaaee068f156d4b0086d7fade14d`\
**Branch:** `claude/grow-v1-flow-1-scope-lock`\
**Date:** 2026-09-03 (original) — revised 2026-09-03 (Vehicle & Capacity addendum)\
**Nature:** Read-only audit. No implementation performed.

This document holds the detailed evidence behind every classification in `docs/cefflo/launch/CEFFLO_GROW_V1_SCOPE_LOCK.md`. Read that document for the readable contract; read this one for the "why."

**Revision note:** all original findings below are preserved unchanged — nothing was re-litigated. §3a is new (Vehicle & Capacity evidence, added for the addendum). §4, §5, §10, §11 have short revision notes appended where a Founder Gate decision changed the recommendation without changing the underlying evidence.

---

## 1. Method

- Full read of `supabase/migrations/` (41 files) — every `create function`/`create table`/`create type` inventoried; the 8 migrations most relevant to planning/optimization/orders/FOUNDR read in full.
- Targeted `grep` sweeps across `vendor/`, `rider/`, `customer/`, `invite/`, `foundr/index.html` + their `backend.js` files, and `shared/` for: csv, xlsx, excel, spreadsheet, google sheet(s), drive, import, bulk, geocode, lat, lng, coverage, zone, route, optimiz, plan, sequence, run, stop, capacity, dispatch, rider, tracking, eta, reassign, recovery, failed, invite, helper, prepare, pack, ready — followed by full-context reads at every hit that mattered.
- Cross-referenced against `docs/cefflo/06_VENDOR.md`, `07_RIDER.md`, `08_CUSTOMER_TRACKING.md`, `10_DELIVERY_LIFECYCLE.md`, `11_SUPABASE.md`, `05_DECISIONS.md`, `04_CURRENT_STATE.md`, and `docs/cefflo/DECISION_REPORT_ISSUE_RESCHEDULE.md`.
- Distinguished, per the Task Master's own rule: (1) backend exists → (2) frontend calls it → (3) UI exposes it → (4) E2E path is proven. No runtime/browser testing was performed — nothing here claims level (4) unless a code comment or test explicitly documents it.

**Boundary of this audit:** this is deep, evidence-based sampling across every required dimension, not a line-by-line read of all ~50 files (several exceed 700KB). Where a claim rests on absence (e.g. "no geocoding call exists"), it rests on multiple independent search angles, not one grep, per the Task Master's own instruction.

---

## 2. Core Schema (the ground truth everything else sits on)

`202608130001_cefflo_foundation.sql` defines the base schema. Key facts:

- `orders` has `latitude double precision`, `longitude double precision` — **nullable, caller-supplied**. No column or trigger computes them from `delivery_address`.
- `delivery_status` enum: `created, ready_for_pickup, picked_up, out_for_delivery, arrived, delivered, issue, cancelled`. **No `preparing`/`packing`/`ready` states exist.** The only place `prepare`/`pack`/`ready`-shaped states exist in the whole schema is `product_media_status` (`queued, processing, prepared, approved` — a **photo-upload pipeline for the storefront catalog**, unrelated to order fulfillment).
- No `capacity` column exists on `riders` or anywhere else in the schema.
- `zones` table (`202608280002`) has **only** `id, business_id, name, status` — the migration's own header comment states: *"Operational grouping only — no geospatial data, no polygons, no lat/lng, no automatic detection, no routing intelligence."*
- `rider_locations` table exists with RLS allowing a rider to insert their own row; FOUNDR's `admin_stuck_riders`/`admin_delivery_operations` read from it. No confirmed live write path found in the rider frontend during this pass (see §4).

---

## 3. AI Optimization Layer — the central finding

**Required outcome per Task Master:** Orders → location intelligence → geographic/operational grouping → proposed runs → rider/run recommendation → efficient stop sequence → vendor review → dispatch.

**What is actually built**, function by function:

| Function (migration) | What it really does |
|---|---|
| `create_delivery` / `submit_public_order` | Accepts an address as **plain text**; `latitude`/`longitude` are optional caller-supplied parameters. `submit_public_order` (the Storefront path) doesn't even have lat/lng parameters. **No geocoding call exists anywhere in the codebase** — confirmed by zero hits for "geocod" across every frontend file. |
| `create_zone` / `rename_zone` / `set_zone_status` | Vendor manually types a zone **name** (a label). No geography involved at all. |
| `update_order_details` (`p_zone_id`) | Vendor manually **picks** which zone a specific order belongs to from a dropdown. Nothing computes this. |
| `build_rider_run` (`202608280004`) | Vendor supplies an explicit `p_order_ids` array and an explicit `p_rider_id`. All-or-nothing, idempotent, well-built — but **100% manual selection**. No distance, capacity, or eligibility scoring of any kind beyond "is this order approved and unassigned." |
| `save_run_sequence` (`202608280001`) | **Rider** supplies the exact ordered array via drag-and-drop. The RPC validates completeness/no-duplicates and persists it — it does not compute an order. |
| `start_pickup_run` / `start_run_delivery` | State-machine gates (all picked up? sequence complete and locked?) — no optimization content. |

**Frontend "coverage" logic** (`vendor/index.html:7937-7947`) reads `nearest.zone.coverageRadiusKm`/`radiusKm` and computes an `'out_of_coverage'`/`'coordinates_required'`/`'covered'` status. **These properties do not exist on the real `zones` table** (which has only `id/business_id/name/status`). This is frontend-only simulated/mock logic operating on local demo data, not a real backend capability — exactly the "client-authoritative mock/local outcomes" pattern `04_CURRENT_STATE.md` CS-06 already flagged as a Stage 4 blocker.

**Rider capacity**: a hardcoded demo array (`vendor/index.html:3972-3975`, `{id:'A', name:'Zone A', ..., riderId:'r1', capacity:10}`) is the only place `capacity` appears in the entire Vendor surface. Zero backend representation.

**Conclusion:** the *execution* half of the pipeline (vendor builds a run, rider sequences it, locks it, executes it in enforced order) is genuinely LIVE and well-engineered. The *intelligence* half (geocoding, automatic zone/coverage detection, capacity-aware allocation, recommended sequence) is **entirely MISSING** — every one of those steps is currently a human manually doing it through a form. This matches the Task Master's own warning almost exactly: *"Do not call manual sequencing 'AI optimization.'"* Today's system is manual sequencing, full stop.

---

## 3a. Vehicle & Capacity — new finding, Founder-approved addendum

Targeted re-audit for the specific search terms the addendum requires: rider vehicle fields, vehicle type, motorcycle/motorbike, car, van, driver terminology, rider capacity, max active orders, run capacity, order load/size, delivery vehicle requirement, assignment compatibility.

**Backend schema** — `riders` table (`202608130001_cefflo_foundation.sql` line 10) has exactly one vehicle-related column:

```sql
vehicle_plate text
```

That's it. No `vehicle_type`, no enum, no classification of any kind. Confirmed by:
- `202608270001_s4_03_batch_1_contracts.sql` lines 106/123 — a vendor RPC lets the vendor update `p_vehicle_plate`, nothing else vehicle-related.
- `202608300002_foundr_phase1_readonly_admin_rpcs.sql` lines 142/161 — FOUNDR's admin rider list reads `vehicle_plate`, nothing else.
- Zero hits for "capacity," "max active orders," "run capacity," "order load," or "delivery load" anywhere in `supabase/migrations/` (41 files) — the capacity concept does not exist at the schema level in any form.

**Frontend — Rider onboarding is hardcoded motorcycle-only.** `rider/index.html`, the 4-step signup flow, verbatim:

- Step 3 of 4 (line 495): `<h2 class="step-title">Vehicle details</h2><p class="step-sub">Tell the vendor which motorcycle you will use for delivery.</p>` … `<label>Motorcycle Plate No.</label>`
- Step 4 of 4 (line 496): `<h2 class="step-title">Identity verification</h2><p class="step-sub">Upload a clear motorcycle driving licence and a selfie holding the same licence.</p>` … `<label>Motorcycle Driving Licence</label>`

This is not an inference — the word "motorcycle" is hardcoded into the step copy, the field label, and the *required identity document type*. A Car or Van rider cannot complete this flow as written: they would be asked for a "Motorcycle Plate No." and a "Motorcycle Driving Licence" regardless of their actual vehicle. **This directly and unambiguously answers Founder Gate Question 9** ("Are any existing screens/backend functions motorcycle-only by assumption?"): yes, the entire Rider onboarding screen set.

**"Rider vehicle breakdown"** exists as one of the selectable reasons in the already-live delivery-issue contract (`rider/index.html` lines 727/1729/1741, feeding `rider_report_delivery_issue`, §11). This is a real, live *exception* pathway — useful context for Flow 2 (a natural place to hook vehicle-related recovery), but it is not vehicle-*type-aware planning* and doesn't change the MISSING classification above.

**"Driver" terminology conflict check** — zero occurrences of "driver" anywhere in the repository (`supabase/`, `vendor/`, `rider/`, `customer/`, `foundr/`, `invite/`, `shared/`). "Rider" is already the sole, consistent term throughout. The addendum's requirement not to introduce a competing "Driver" identity is **already satisfied by default** — there is nothing to correct here, only to confirm and preserve going forward.

**Recommended V1 capacity model:** vehicle-based default max-active-stops, with an explicit per-Rider Vendor override. Basis: this is the only candidate from the addendum's own list that (a) requires no new logistics concepts (weight/volume/dimensions — no evidence anywhere in the repo that Grow V1 needs these), (b) maps cleanly onto the existing `build_rider_run` all-or-nothing eligibility-check pattern (a straightforward `count(active stops) <= capacity` predicate, structurally identical to the eligibility checks that function already performs), and (c) still gives the Vendor real control (the addendum's explicit requirement) via the override.

**Recommended override behavior:** block the assignment by default; allow an explicit, clearly-labeled Vendor override that writes a `delivery_events` row (matching every other consequential action in this codebase) rather than silently permitting an invalid plan. This mirrors the existing pattern exactly — every mutating RPC in this codebase logs to `delivery_events` — so it is architecturally the path of least resistance, not a new pattern.

**Order-level vehicle requirement:** no evidence found that Grow V1 needs a per-order vehicle requirement field. The addendum's catering example illustrates a *business-type* reason a vendor might need Car/Van riders, not a confirmed need for customers/vendors to tag individual orders with a required vehicle at launch. Recommend deferring unless the Founder confirms otherwise.

---

## 4. CSV + Excel/XLSX Import

`vendor/index.html` lines ~5203–5330, function `readImportFile` / `confirmCsvImport`:

- File input accepts `.csv,.xlsx,.xls` (line 3423), 5MB limit enforced.
- CSV: custom text parser (`parseCsvText`).
- XLSX: dynamically loads `https://cdn.jsdelivr.net/npm/xlsx@0.18.5/dist/xlsx.full.min.js` from CDN, uses `XLSX.read` + `sheet_to_json`.
- Column recognition with fallback aliases (`x['Order ID']||x.orderId||x.id`, `x.Name||x.name||x.Customer`, etc.).
- Row validation (`validateImportRows`): flags duplicate order IDs, missing fields.
- Row-correction UI (`fixCsvRow`/`saveCsvRowFix`) — a sheet lets the vendor fix a bad row inline.
- **The commit step is explicitly disabled**, with its own code comment:

```js
function confirmCsvImport(){
  // S4-09: the current CSV shape has no order items and cannot satisfy the
  // existing authoritative create_delivery path without inventing product
  // data. Keep parsing/preview reachable, but never commit it into local or
  // backend operational truth until an approved compatible contract exists.
  toast('CSV import is not connected yet.', 'error');
}
```

No CSV/XLSX-specific backend object exists anywhere in `supabase/migrations/` (zero hits for csv/xlsx/excel/spreadsheet across all 41 files).

**Conclusion:** upload → parse → preview → validate → correct is real, working, substantial frontend engineering (roughly a full feature). The one missing piece — committing validated rows into canonical orders via `create_delivery` (or an import-shaped equivalent) — is deliberately, explicitly stubbed, for a clearly stated reason (order `items` shape mismatch). This is squarely **PARTIAL**, not MISSING and not LIVE.

**Revision note (addendum):** Founder Gate decision is to keep the existing parse/preview/validate foundation as-is (no rebuild) and recommend the safest canonical-commit reconciliation: extend `create_delivery`'s accepted `items` contract to accept a CSV/import-shaped payload (a minimal synthetic single-line-item, or an explicitly-nullable items array for import-sourced orders) rather than inventing a parallel import-specific mutation path. This keeps `create_delivery` as the single authoritative order-creation RPC — consistent with every other intake path in §6 — instead of creating a second, competing write path for imported orders. Exact contract shape is a Flow 2 implementation decision; Flow 1 only locks the direction.

---

## 5. Google Sheets / Google Drive

Zero references anywhere in the repository — no code, no migration, no doc beyond `01_PRODUCT.md` P-09's forward-looking "Future areas may include manual/CSV/Google Sheets intake." Not started, not stubbed, not investigated in code.

**Recommendation basis:** CSV/Excel — the simpler, no-OAuth version of this same idea — isn't finished yet (§4). Google Sheets/Drive requires OAuth consent flow, token storage/refresh, a sync scheduler, source-row identity tracking, and change/delete handling that CSV import doesn't need at all. Building this before CSV/Excel is committed to canonical orders would be building on an unfinished foundation.

**Revision note (Founder Gate decision):** reclassified from POST-V1 to **DESIRABLE V1 IF LOW-RISK**. This does not change the MISSING current-truth finding above or the technical dependency on CSV/Excel being committed first — it changes launch priority only. Practical reading: Google Sheets/Drive intake may enter V1 scope *if and only if* it can be delivered as a thin layer on top of the already-reconciled CSV/Excel commit path (§4's revision note) without its own bespoke sync/identity/OAuth infrastructure being built from scratch under launch time pressure. If that condition can't be met without materially expanding scope or risk, it reverts to POST-V1 by the same logic. This is a conditional inclusion, not an unconditional V1 commitment — Flow 2 must re-confirm feasibility before committing engineering time.

---

## 6. Other Order Intake Paths

| Path | Evidence | Verdict |
|---|---|---|
| Manual New Order | `create_delivery` RPC, live since the foundation migration, wired in Vendor UI | LIVE |
| Cefflo Storefront | `202609010001_s4_10e_public_order_page_contract.sql` (371 lines, dated Sept 1 — most recent backend work): `create_order_page`, `rotate_order_page_token`, `set_order_page_enabled`, `public_order_catalog`, `submit_public_order`, `decline_order`. Rate-limited, idempotency-keyed, RLS-scoped. Product catalog/media pipeline (`s4_10a`–`s4_10e`) backs it. | LIVE at backend; frontend order-page UI referenced by the same S4-10 series but not independently re-verified end-to-end this pass |
| CSV | See §4 | PARTIAL |
| Excel/XLSX | See §4 | PARTIAL |
| Google Sheets | See §5 | MISSING |
| Google Drive | See §5 | MISSING |
| Website form/webhook | No evidence found | MISSING |
| Ecommerce/API/POS | No evidence found | MISSING (correctly; Brand Brain classifies as IDEA/EXPLORATION) |

Note: `submit_public_order` does **not** capture lat/lng — same location-intelligence gap as manual/CSV intake (§3).

---

## 7. Location → Coverage → Zone

Already substantially covered in §3. Summary:

- Address capture: LIVE (plain text, required field).
- Lat/lng storage: LIVE as columns; **population is MISSING** — no geocoding path exists.
- Coverage decision: the only implementation found is frontend-mock (§3) — **LEGACY/NON-CANONICAL** (it simulates a real decision using data the backend doesn't have).
- Zone as a manual label: LIVE, by design, per its own migration comment.
- Out-of-coverage handling: the mock frontend path sets a `coverageStatus` field, but nothing downstream (backend) reads or enforces it — dispatch is not actually blocked by it at the RPC level (`build_rider_run` has no coverage check).

---

## 8. Optimization / Planning / Review / Dispatch Contract

Full detail in §3. In the Task Master's own required terms:

- Proposed runs/grouping: **not proposed by the system** — vendor selects manually.
- Recommended allocation: **does not exist**.
- Recommended stop sequence: **does not exist** — rider sets it manually.
- Unresolved conflicts: partially — `build_rider_run` does check order eligibility (approved, unassigned, correct business) all-or-nothing, and raises a clear error; that's real conflict *detection*, not conflict *resolution guidance*.
- Vendor review before dispatch: LIVE — `build_rider_run` is the explicit "confirm" action; nothing is auto-dispatched.
- Manual adjustment / reorder: LIVE (`save_run_sequence`).
- Rider gets ordered run + next-stop context + navigation handoff: the ordered run and "current stop" concept are backend-real (`rider_transition`'s locked-sequence enforcement, §9 below); navigation *handoff* (e.g. deep-linking to Maps) was not independently verified as a live frontend behavior this pass — flagged **UNVERIFIED**.

**Direct answer to the Task Master's explicit question:** *"If repo only has deterministic grouping/sequencing, say so. If no optimizer exists, say so."* — **No optimizer exists.** What exists is deterministic, 100% human-driven grouping and sequencing, well-built at the state-machine/data-integrity level, with zero automated intelligence anywhere in the pipeline.

**Revision note (Founder Gate decision):** the V1 optimization/planning layer must be built on a **deterministic foundation** — explicit rules over geocoded location, vehicle compatibility (§3a), and capacity (§3a), not an LLM asked to "figure out" a delivery plan. An optional AI-assisted layer (e.g. explaining a proposed grouping in plain language, or suggesting adjustments) may sit on top of the deterministic core, but must never be the sole mechanism producing the plan Riders execute — the underlying grouping/sequencing must be verifiable and reproducible. Route/distance calculation may call an optional external routing/distance provider (e.g. a mapping API) rather than requiring Cefflo to implement geospatial routing itself, but the decision of *which* orders go together and *whether* an assignment is valid (vehicle/capacity compatibility) stays deterministic and in Cefflo's own logic regardless of which routing provider is used. This directly extends the addendum's §4/§8 vehicle-and-capacity-aware planning chain — the chain itself is deterministic; only the optional stop-order distance calculation may lean on an external provider.

---

## 9. Canonical Operational Lifecycle

Backend enum (`delivery_status`): `created → ready_for_pickup → picked_up → out_for_delivery → arrived → delivered`, with `issue`/`cancelled` as side states. `rider_transition` enforces this exact linear graph and additionally enforces **stop order** once a run's sequence is locked (`202608280001` lines 331-350: a rider cannot mark a later stop `out_for_delivery`/`arrived` while an earlier-sequenced stop in the same locked run isn't yet `delivered`).

Separately, `approve_order` (`202608270010`) exists — an explicit vendor approval gate before an order can be picked up, matching Brand Brain/D-17's "order approval/readiness is an explicit step."

| Conceptual stage | Backend reality |
|---|---|
| Received | `created` (order row exists) |
| Prepare / Pack | **No backend representation** — no status, no table, no RPC. Only a same-named-but-unrelated `product_media_status` pipeline exists (photo processing for the storefront catalog). |
| Ready | `ready_for_pickup` (delivery_status) — reachable directly from `created`, skipping any prepare/pack step |
| Planned | `delivery_sessions.status = 'planned'` |
| Assigned | `rider_assignments` row created (`assign_rider` / `build_rider_run`) |
| Pickup | `picked_up` + `start_pickup_run` event |
| Delivery Run | `out_for_delivery` under a locked sequence |
| Delivered / Failed / Exception | `delivered`; `issue` (delivery-issue contract, §11); no distinct "failed" terminal state — `issue` is the closest |

**Legacy/duplicate status systems:** none found — `delivery_status` is the single canonical source; `orders.delivery_sequence` was explicitly superseded by `delivery_stops.sequence` per `202608280001`'s own comment ("left untouched and unused — no migration or drop of it in this batch," i.e. a known, harmless dead column, not a competing live system).

---

## 10. Four Workspace Audit

### Vendor / Owner
LIVE across: auth, business setup (`bootstrap_business`), order intake (manual + Storefront), order approval, rider team management + invitation, zone labeling, run building, dispatch, delivery-issue reporting, subscription/plan display. PARTIAL: CSV/Excel commit (§4), coverage/zone intelligence (§3, §7). MISSING: capacity (§3a), vehicle type (§3a), reschedule (§11).

**Revision note (addendum):** the Vendor's REQUIRED V1 surface now explicitly includes: registering/viewing a Rider's vehicle type, seeing vehicle/capacity compatibility and conflicts during run building, and a labeled override action for an incompatible assignment that writes an audit event rather than silently proceeding (§3a). This is additive to the existing run-building UI, not a new workspace.

### Operations / Helper
**MISSING as a distinct workspace.** Two independent, converging pieces of evidence:
1. No `prepare`/`pack`/`ready` order-lifecycle states exist anywhere in the schema (§9).
2. The Vendor UI's own "Helper Pool" tab renders, verbatim: *"Helpers is not connected yet. Helper Pool requires a backend contract that does not exist yet."* (`vendor/index.html:6361,6395`)

A "Core Team" concept exists via `team_invitations`/`accept_team_invitation` (business members with `operator` role) — this is real and LIVE, but it is *team membership/permissions*, not a *Prepare→Pack→Ready workspace or workflow*. The two should not be conflated in the scope lock.

**Revision note (Founder Gate decision):** confirmed as REQUIRED V1, and confirmed it must be its own distinct workspace/surface (Prepare → Pack → Ready) rather than being collapsed into or represented as a tab inside the Vendor/Owner workspace. Basis: the four-workspace model (§ Brand Brain) treats workspace boundaries as role/permission boundaries, not UI convenience groupings — a Helper has a narrower, task-focused permission surface than a Vendor/Owner, and merging them would either over-grant Helpers Vendor-level access or under-serve Vendors by hiding Owner controls inside a Helper-shaped screen. This does not conflict with the addendum's §9 instruction not to introduce a separate *Driver* workspace — Operations/Helper is orthogonal to Rider/vehicle and was already a planned distinct workspace before this addendum.

### Rider
LIVE: auth (`current_rider_id`), invitation/approval (`create_rider_invitation`→`accept_rider_invitation`→`approve_pending_rider`), assignment, locked sequence with enforced stop order, POD (`complete_delivery` + `cefflo-pod` private storage bucket with RLS scoping upload/read to the assigned rider or business member), delivery-issue reporting. PARTIAL/UNVERIFIED: live GPS location writes (schema + RLS insert policy exist; no confirmed live frontend write call found this pass — consistent with a prior, explicitly-corrected false-GPS-claim in project history per git log "Remove false Rider GPS tracking claim"). MISSING: reschedule/failed-delivery recovery beyond the `issue` report, vehicle type, capacity (§3a).

**Revision note (addendum):** the onboarding flow (`rider/index.html:495-497`) hardcodes "motorcycle" into step copy, field label, and required document type — this is the concrete MISSING gap Flow 2 must close (§3a). No change to the canonical **Rider** role name — "Driver" terminology has zero occurrences repository-wide, so the addendum's requirement to avoid a competing role is already satisfied without any correction.

### Customer
LIVE: `public_tracking` (status, rider name, completed_at, POD path once delivered), `submit_rating` (one rating per order, idempotent). Referenced directly in `customer/index.html`. PARTIAL/MISSING: ETA — `orders.estimated_arrival_at` is **read** by `public_tracking` but **no function in any migration ever sets it** — it is effectively always null today. Storefront ordering itself is covered in §6.

**Revision note (Founder Gate decision):** ETA confirmed REQUIRED V1. Given the confirmed absence of geocoding/routing (§3, §3a), a precise time-of-arrival cannot be honestly computed at V1. Recommend a range/status-based ETA (e.g. derived from run position/stop-count and a coarse per-stop duration assumption, surfaced as a range or "N stops away" rather than a clock time) that never fabricates false precision. Do not build a spinning "12:47 PM" estimate on top of the current MISSING location/optimization layer — that would misrepresent the system's actual capability to the Customer. Exact computation is a Flow 2 decision; Flow 1 locks the honesty constraint.

---

## 11. Exception & Recovery

| Exception | Current backend truth | Evidence |
|---|---|---|
| Delivery issue (vendor- or rider-reported) | LIVE | `vendor_report_delivery_issue`, `rider_report_delivery_issue`, typed `delivery_issue_reason` enum (`202608310001`) |
| Reschedule | **MISSING** | Zero matches for "reschedule" across all 41 migrations. `docs/cefflo/DECISION_REPORT_ISSUE_RESCHEDULE.md` (still present, unedited) explicitly documents this as a live open product decision: *"No RPC or migration exists for either action [Report Issue or Reschedule]... until a Founder decision... is made."* Report Issue has since shipped (above); this doc is now **stale for "Report Issue"** but still accurate for **"Reschedule."** |
| Invalid/unresolved address, out-of-coverage | Frontend-mock only (§3, §7) — no backend enforcement | — |
| Duplicate/malformed import | Detected in the CSV preview UI (§4); moot until import commits | `validateImportRows` |
| Rider unavailable / capacity exceeded | No capacity concept exists (§3a) to even detect this | — |
| Rider removed after planning | Not traced this pass | UNVERIFIED |
| Post-pickup reassignment | Not confirmed; `reassign_rider` is referenced by name in several migration comments as an existing function whose *correction* was deferred across S4-06 batches — the function's current exact behavior after those deferrals was not independently re-read this pass | UNVERIFIED |
| Duplicate action submission | LIVE, broadly — idempotency keys used in `build_rider_run`, `submit_public_order`, `rider_transition`/`complete_delivery` (`p_idempotency_key`) | — |
| Cancelled order | `cancelled` is a valid `delivery_status` and `assignment_status` value; transition-trigger path not traced this pass | UNVERIFIED |
| Network loss / refresh during run | Not a backend concern per se; sequence-lock design (§9) makes state recoverable across refreshes since it's server-persisted, not session state — reasonable but not independently tested | UNVERIFIED |

**Revision note (Founder Gate decision):** Reschedule is confirmed **REQUIRED V1**, but narrowly scoped — a bounded action that lets a Vendor or Rider move a specific delivery's planned execution (e.g. to a later run, or flag it for re-planning) with an audit event, not a general-purpose calendar/scheduling system. It should reuse the existing `delivery_events` audit pattern and the existing `issue`/`delivery_issue_reason` machinery where they overlap (a reschedule is, structurally, one more typed reason a delivery leaves its current run) rather than inventing a parallel state machine. Exact RPC/state design is a Flow 2 decision; Flow 1 locks the "required but narrow" boundary so Flow 2 doesn't over-build a scheduling product.

---

## 12. FOUNDR Boundary

Real, LIVE backend (`202608300001`–`5`): `platform_admins`/`is_platform_admin`, `admin_list_vendors`, `admin_get_vendor`, `admin_list_riders`, `admin_stuck_riders`, `admin_delivery_operations`, `admin_list_subscriptions`, `admin_set_subscription`, `app_versions`/`admin_record_app_version`, `platform_announcements`/`admin_create_announcement`. This matches Brand Brain §12/D-21's minimum FOUNDR scope closely (Vendors, Riders, Delivery Operations, Subscriptions/Platform Revenue, Version Control, Announcements).

No `invoice`/`payout` RPC exists anywhere — confirms the FOUNDR "Invoices & Payouts" UI tile removed in the prior reconciliation task had zero backend behind it; the removal was correct and complete.

---

## 13. Working-Tree / Safety Confirmation

- No migrations, RPCs, schema, UI features, or product code were created or changed in this task — every action was `Read`/`Grep`/`Bash` (read-only) plus writing the two required Flow 1 documents and this Task Master's own placement.
- `git status` at time of writing: clean on all tracked files; the same pre-existing untracked items from prior sessions remain (`.claude/`, Finos audit files, `previews/`).
- No Production, staging-mutating, or deployment action was taken.

---

**End of audit report.** See `docs/cefflo/launch/CEFFLO_GROW_V1_SCOPE_LOCK.md` for the scope contract synthesized from this evidence.
