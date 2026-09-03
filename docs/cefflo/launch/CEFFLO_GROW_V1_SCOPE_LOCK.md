# CEFFLO GROW V1 — SCOPE LOCK

**Status:** PROPOSED — awaiting Founder approval (not yet frozen)\
**Baseline:** `staging @ 9e7ea2dae61deaaee068f156d4b0086d7fade14d`\
**Detailed evidence:** `docs/cefflo/audits/CEFFLO_GROW_V1_SCOPE_LOCK_AUDIT_REPORT.md`\
**Brand/positioning authority:** `docs/cefflo/CEFFLO_BRAND_BRAIN.md`\
**Revision:** 2026-09-03 — incorporates the Founder-approved `docs/cefflo/tasks/CEFFLO_GROW_V1_VEHICLE_CAPACITY_SCOPE_ADDENDUM.md` and accompanying Founder Gate decisions (vehicle/capacity, Sheets/Drive reclassification, optimization architecture, CSV/Excel and Operations/Helper direction, Reschedule and ETA scope). Original audit evidence preserved; see §11a, §12, §22 for what changed.

---

## 1. What Grow V1 Is

Grow V1 is the first public-launch version of Cefflo's local same-day delivery operating system: a business brings today's orders into one place, Cefflo helps organize and plan the delivery workload, riders execute multi-drop runs, and customers track delivery — all inside the business's own service area, with the business's own team.

## 2. Launch Promise (Founder-locked)

> Bring in today's orders → Cefflo validates and locates them → organizes the delivery workload → optimizes the delivery plan → vendor reviews → riders execute multi-drop runs → customers track → delivered today.

Cefflo adapts to how a vendor already takes orders, rather than forcing a high-volume vendor to re-key everything by hand.

## 3. Canonical Operating Journey

**Order Intake → Canonical Validation → Address / Location → Coverage → Zone / Geographic Grouping → Vehicle & Capacity Compatibility → Optimization / Planning → Vendor Review / Manual Adjustment → Rider Assignment → Dispatch → Pickup → Ordered Multi-Drop Run → Customer Tracking → Delivery Result → Recovery / Completion / Audit**

This chain is only as strong as its weakest link — see §20 for exactly where it breaks today.

---

## 4. REQUIRED V1

These are Founder-locked; they cannot be downgraded by an executor. **Revised 2026-09-03** per the Vehicle & Capacity Scope Addendum and accompanying Founder Gate decisions.

1. **AI Optimization Layer — now explicitly location-aware, vehicle-aware, and capacity-aware.** Orders → location → delivery requirements → available Riders → vehicle compatibility → capacity compatibility → geographic grouping → run proposal → stop-sequence optimization → vendor review → dispatch. A shortest-route-only implementation that ignores vehicle/capacity compatibility does not satisfy this requirement. (Today: MISSING — see §12.)
2. **Vehicle classification for Riders (Motorcycle / Car / Van).** (Today: MISSING — see §11a.)
3. **Capacity-aware planning** — the system must not propose a plan that is obviously incompatible with a Rider's vehicle/capacity. (Today: MISSING — see §11a.)
4. **CSV bulk order import**, committing to canonical orders. (Today: PARTIAL — see §9.)
5. **Excel/XLSX bulk order import**, committing to canonical orders. (Today: PARTIAL — see §9.)
6. Manual New Order intake. (Today: LIVE.)
7. Cefflo Storefront order intake. (Today: LIVE at backend.)
8. Location capture (address) → coordinates → coverage → zone/grouping → planning, as one working chain. (Today: capture LIVE, everything after it MISSING/mocked — see §11.)
9. Vendor review, manual adjustment, and explicit dispatch confirmation before a run goes live — including visibility into vehicle/capacity conflicts. (Today: LIVE for the review/confirm mechanics; vehicle/capacity visibility MISSING.)
10. Rider: receive an ordered run, execute stops in enforced order, capture POD, complete. (Today: LIVE.)
11. Customer: truthful tracking of real delivery status. (Today: LIVE, except ETA — see §16.)
12. Delivery-issue reporting (vendor and rider). (Today: LIVE.)
13. **ETA that is truthful and computed from real operational information** — a range or coarser state is acceptable; a fabricated precise time is not. (Today: MISSING — the column exists but nothing ever sets it.)
14. **Reschedule / operational recovery**, narrowly scoped to deliveries that cannot be completed as originally planned — not a general appointment/calendar system. (Today: MISSING — open Founder decision on exact behavior remains, see §22.)

## 5. Desirable V1

- **Connected Google Sheets/Drive intake — `DESIRABLE V1 IF LOW-RISK`** (changed from `POST-V1`; see §10). Must not block public launch if OAuth/integration risk or timeline materially threatens the core launch path.
- Live rider GPS location on the map (schema/RLS exist; live write path unconfirmed).
- Post-pickup reassignment (mentioned in migration history as a deferred correction; current exact behavior not re-verified this pass).

## 6. Post-V1

- Google Sheets / Google Drive connected intake **only if** the §10/§22 risk assessment goes against it at build time (fallback from Desirable V1).
- Website/webhook order intake.
- Predictive/advanced route optimization beyond a working deterministic-plus-AI-assisted-recommendation baseline.
- Nonessential FOUNDR analytics beyond the already-live admin surfaces.
- Complex kilogram/volume/dimension delivery-load logistics — the addendum explicitly says not to introduce this without evidence of need; none was found this pass.

## 7. Out of Scope

- Nationwide rider marketplace; public helper marketplace.
- Vendor-customer invoices, payouts, payment balances, quotations, or accounting of any kind. (Confirmed already removed from FOUNDR in the prior reconciliation task — zero backend for it remains.)
- Arbitrary storefront color/brand builder — the live Storefront theme system is four curated themes, by design (`previews/s4-10d-order-page-theme`).
- Speculative POS/API integrations.
- Enterprise/decorative features not tied to the launch promise.

AI Optimization and CSV/Excel import are explicitly **not** eligible to be moved to this list.

---

## 8. Order Intake Matrix

| Source | Real & canonical? | Tenant-safe? | Feeds locate→plan→dispatch→track? | Verdict |
|---|---|---|---|---|
| Manual New Order | Yes | Yes | Yes | **LIVE** |
| Cefflo Storefront | Yes | Yes | Address text only, no coordinates | **LIVE** (backend); coordinates gap shared with all intake paths |
| CSV | Parses/validates/previews; does not commit | Yes (once committed) | N/A yet | **PARTIAL** |
| Excel/XLSX | Same as CSV | Yes (once committed) | N/A yet | **PARTIAL** |
| Google Sheets | Not built | — | — | **MISSING** |
| Google Drive | Not built | — | — | **MISSING** |
| Website form/webhook | No evidence found | — | — | **MISSING** |
| Ecommerce/API/POS | No evidence found | — | — | **MISSING** (correctly out of current scope) |

## 9. CSV / Excel Contract

**What's real today (keep as-is — Founder-confirmed):** file upload (5MB limit) → CSV text parsing or XLSX.js parsing → column-alias recognition (Order ID/Name/Phone/Address/Zone with common header variants) → per-row validation (missing fields, duplicate order IDs) → a preview table with per-row status → an inline "fix this row" editor. This foundation stays; nothing here needs rebuilding.

**What's missing:** the commit step. The code itself states why — the current CSV/XLSX row shape has no line-item data, and the canonical order-creation path (`create_delivery`) needs items.

**Recommended reconciliation (Founder-requested; still a Flow 2 build decision, not implemented here):** extend the canonical order contract to accept a minimal-items convention rather than inventing a parallel import-order system. Concretely — `create_delivery`/`submit_public_order` already accept `p_items jsonb default '[]'`, i.e. an **empty items array is already structurally valid** at the type level; the actual blocker is almost certainly application-level validation or product-catalog assumptions downstream, not the column itself. The safest path is a small, additive convention: imported rows populate `items` with a single synthetic line (e.g. `[{"description": <free-text from an "Order Contents" column>, "quantity": 1}]`) that satisfies whatever downstream expects a non-empty/product-linked array, while keeping every imported order a **real row in the same `orders` table**, going through the **same `create_delivery` RPC**, with the **same tracking token, same event log, same everything** as a manually-entered order. No shadow table, no parallel status system. This is a recommendation for Flow 2 to verify and implement — not decided or built here.

## 10. Connected Spreadsheet (Google Sheets / Drive) Recommendation

**Founder decision: `DESIRABLE V1 IF LOW-RISK`** (revised from this document's earlier `POST-V1` recommendation).

CSV/Excel canonical-commit remains the prerequisite — building the OAuth-based connector before the no-auth version even creates orders would still be building on an unfinished foundation (§9). The revision changes the *ambition*, not the *sequencing*: Flow 2 should attempt Sheets/Drive once CSV/Excel is done, but it **must not block public launch** if the OAuth/integration work introduces material risk or delay to the core launch path. If, once attempted, it proves low-risk and fast, it ships in V1; if not, it falls back to Post-V1 without re-opening this decision.

## 11. Location → Coverage → Zone Contract (today vs. required)

| Stage | Required | Today |
|---|---|---|
| Address capture | Required field on every order | **LIVE** |
| Address → coordinates (geocoding) | Automatic | **MISSING** — no geocoding call exists anywhere in the codebase, on any intake path |
| Coverage decision | Should determine if an address is deliverable | **Frontend-simulated only** — reads a `coverageRadiusKm` property that doesn't exist on the real `zones` table; not backend-enforced |
| Zone / grouping | Should organize orders geographically | **Manual label only** — a vendor-typed name with zero geography, by explicit design of its own migration |
| Missing-location blocking | Should prevent dispatch without a location | **Not enforced** — `build_rider_run` has no coverage/location check |

## 11a. Vehicle & Capacity Contract (new — Founder-approved addendum)

**Required:** a Rider may operate a Motorcycle, Car, or Van. Vehicle is an attribute of the canonical Rider role, not a separate workspace or identity — **"Driver" is not introduced as a competing term.** Planning must consider vehicle and capacity compatibility before proposing a run, and the Vendor must be able to see and resolve incompatibilities.

**Today — verified by direct repository inspection:**

- The `riders` table has exactly one vehicle-related field: `vehicle_plate text` (a license-plate number). **No vehicle-type column, enum, or classification exists anywhere in the schema.**
- **The entire Rider signup/onboarding flow is hardcoded motorcycle-only**, in both copy and required documents (`rider/index.html`, Signup Step 3–4 of 4): the step is titled "Vehicle details," reads *"Tell the vendor which **motorcycle** you will use for delivery,"* the field is labeled *"**Motorcycle** Plate No.,"* and identity verification requires uploading a *"**Motorcycle** Driving Licence."* A Car or Van rider is not accommodated by this flow at all today. This directly answers the addendum's Founder Gate Question 9: **yes, the Rider onboarding screen is motorcycle-only by hardcoded assumption.**
- No `capacity` concept exists anywhere — not on `riders`, not on any session/run/assignment table, not as a computed value in any RPC.
- "Rider vehicle breakdown" already exists as a delivery-issue reason (`rider/index.html`) — a real, live *exception* hook, but unrelated to vehicle-*type-aware planning*.
- "Driver" as competing terminology: **zero occurrences anywhere in the repository.** Rider is already the sole, consistent term — the addendum's requirement to avoid a Rider/Driver split is already satisfied by default; nothing needs correcting here.

**Recommended V1 capacity model** (per the addendum's instruction to recommend, not invent without evidence): given zero existing infrastructure, the simplest reliable model is **vehicle-based default capacity (max active stops per run) with an explicit per-Rider Vendor override** — i.e. Motorcycle/Car/Van each get a sensible default max-stops value, and the Vendor can raise or lower it for a specific Rider. This combines two of the addendum's candidate models (vehicle-based default + configurable per-Rider) rather than inventing a new one, keeps the constraint simple ("count of active stops," not weight/volume/dimensions — no evidence found that Grow V1 needs those), and is enforceable with the same all-or-nothing pattern `build_rider_run` already uses.

**Vendor override behavior when an assignment is vehicle/capacity-incompatible** (the addendum's explicit open question, §7): recommend **block by default, with an explicit, clearly-labeled override action** that records an audit event (matching the existing `delivery_events` pattern used everywhere else) — never a silent invalid plan. This is a recommendation; final confirmation is a Founder decision (§22).

**Order-level vehicle requirement:** no evidence in the current product/repo that individual orders need their own vehicle requirement at V1 (e.g. "this order needs a van") — catering-scale orders were given only as a *business-type* example in the addendum, not a confirmed per-order requirement. Recommend deferring an order-level vehicle-requirement field to Flow 2/Post-V1 unless the Founder confirms it's needed at launch (see §22).

## 12. AI Optimization Contract (today vs. required)

The single most important finding of this audit — now extended by the Vehicle & Capacity addendum.

**Required (revised):** orders → location → delivery requirements → available Riders → **vehicle compatibility → capacity compatibility** → geographic grouping → run proposal → stop-sequence optimization → vendor review → dispatch. A shortest-route-only implementation that ignores vehicle/capacity is **not sufficient**, per the addendum.

**Today:** a vendor manually picks which orders go into a run and which rider gets it (`build_rider_run`); a rider manually drags stops into an order (`save_run_sequence`). Both are well-built, safe, idempotent, all-or-nothing backend contracts — the *execution* half of the pipeline is solid. But there is no automatic grouping, no distance/time calculation, no vehicle/capacity-aware recommendation, and no sequence optimization anywhere. **No optimizer exists.** What exists is deterministic manual sequencing, exactly the thing the Task Master said not to call "AI optimization."

**Optimization architecture recommendation (Founder-directed):** the route/planning engine must be built on a **deterministic foundation** — not designed around an LLM — so that plans are reproducible and reviewable, exactly like every other operational contract in this codebase (idempotent, auditable, all-or-nothing). Concretely, for V1:

1. A deterministic geographic clustering/grouping step (orders → candidate groups), using real coordinates once geocoding exists (§11).
2. A deterministic sequencing step within each group — nearest-neighbor or an equivalent bounded heuristic is an honest, defensible V1 (the Task Master itself allows "the implementation may ultimately use deterministic optimization... the required user outcome is operationally useful optimization").
3. Vehicle/capacity compatibility filtering applied **before** grouping is finalized (§11a) — a candidate group is only valid if a compatible Rider/vehicle combination exists for it.
4. Where real road distance/travel-time materially improves plan quality over straight-line distance, an appropriate routing/distance provider may be used for that specific calculation — this is a data input to the deterministic optimizer, not a replacement for it.
5. An AI-assisted layer (e.g. a plain-language explanation of why a plan was proposed, or a secondary suggestion when the deterministic pass finds no clean grouping) may sit **on top of** this deterministic foundation, never underneath it or in place of it.

This is an architecture recommendation for Flow 2 to implement — no engine, provider, or library is selected or integrated in this task.

## 13. Planning / Review / Dispatch Contract

- Vendor reviews and explicitly confirms before dispatch: **LIVE** (`build_rider_run` is the confirm action itself — nothing auto-dispatches).
- Manual reorder/adjustment: **LIVE** (`save_run_sequence`).
- Rider gets an ordered run with enforced next-stop logic: **LIVE** (a locked run cannot skip ahead — earlier stops must complete first).
- Navigation handoff to a maps app: not independently confirmed this pass — **UNVERIFIED**.

## 14. Status Lifecycle

Canonical backend states: `created → ready_for_pickup → picked_up → out_for_delivery → arrived → delivered`, with `issue`/`cancelled` as side states. An explicit vendor **approval** gate exists before pickup semantics apply.

**Gap:** there is no `preparing`/`packing`/`ready`-for-fulfillment state in this lifecycle at all — an order goes straight from `created` to `ready_for_pickup` with nothing in between. The only "prepare/pack" states anywhere in the schema belong to a completely different pipeline (storefront product-photo processing), not to orders.

## 15. Four Workspace Responsibility Matrix

| Workspace | Launch responsibility | Readiness |
|---|---|---|
| Vendor / Owner | Setup, intake, review, dispatch, oversight, recovery, **+ vehicle registration and capacity-conflict visibility** | **Mostly LIVE** for the original scope — CSV commit and location intelligence are the open gaps. Vehicle/capacity visibility and control is entirely **MISSING** (no UI, no backend, §11a). |
| Operations / Helper | Prepare → Pack → Ready | **MISSING as a distinct workspace — Founder-confirmed this must not collapse into a Vendor-only view.** No backend lifecycle states exist for Prepare/Pack/Ready (the only "prepare/pack" states in the schema belong to storefront photo processing, unrelated). The Vendor UI's own "Helper Pool" screen currently reads: *"Helpers is not connected yet."* A separate "Core Team" (staff invitation/membership) is real and live but is authentication/permissions, not a workflow — it does not substitute for the required workspace. Flow 2 must define: (a) the Prepare/Pack/Ready backend states, (b) a distinct authenticated Operations/Helper surface (reusing the existing invitation/membership plumbing where possible), (c) the handoff point into Planning. |
| Rider | Receive run, execute in order, POD, complete. **Canonical role stays "Rider" regardless of vehicle** — a Rider operates a Motorcycle, Car, or Van; vehicle is an attribute, not an identity. | **LIVE** for the original execution flow. Vehicle-type support is **MISSING** — onboarding is hardcoded motorcycle-only (§11a). GPS live-location and post-pickup reassignment unconfirmed. |
| Customer | Order (where applicable), truthful tracking, rating. No vehicle-selection complexity should ever reach the customer — confirmed no evidence this pass that it needs to. | **LIVE**, except ETA is never actually computed (always effectively blank) — must become a truthful range/state, not a fabricated precise time (§16). |

## 16. Exception & Recovery Matrix (launch-critical subset)

| Exception | Today | Dispatch-blocking? |
|---|---|---|
| Delivery issue (vendor/rider-reported) | **LIVE** — typed reason enum, both actors covered | No, tracked as an event |
| Reschedule / operational recovery | **MISSING — now REQUIRED V1** (Founder decision), kept deliberately narrow: recovery for a delivery that cannot complete as planned, **not** a general appointment/calendar system. `docs/cefflo/DECISION_REPORT_ISSUE_RESCHEDULE.md` remains the open product-decision record for its exact behavior — this scope lock does not resolve it, only confirms it must ship at V1. | Should be, once built |
| Vehicle/capacity-incompatible assignment | **MISSING** (new, from the addendum) — no detection exists because no vehicle/capacity data exists. Recommended: block by default with an explicit, audited override (§11a). | Recommended: yes, unless explicitly overridden |
| Invalid/unresolved address, out-of-coverage | Frontend-simulated only, not backend-enforced | No (should be, isn't) |
| Duplicate/malformed CSV row | Caught in preview UI | Import doesn't commit yet regardless |
| Rider unavailable/capacity exceeded | No capacity concept exists to detect this (same root cause as the row above) | No |
| Duplicate action submission | **LIVE** broadly (idempotency keys on the key mutating actions) | — |
| Cancelled order | Status exists; transition trigger path not re-traced this pass | UNVERIFIED |
| Post-pickup reassignment | Referenced in migration history as deferred; current exact behavior unconfirmed | UNVERIFIED |

Full table with every item the Task Master listed is in the audit report §11.

## 17. FOUNDR Launch Boundary

**LAUNCH REQUIRED (already LIVE):** business/vendor oversight, rider oversight, delivery operations visibility (including a stuck-rider signal), platform subscriptions/revenue (the "Platform Revenue" surface from the prior reconciliation), app version control, platform announcements, platform-admin authorization gate.

**REMOVE / NON-CANONICAL:** Invoices & Payouts — already removed in the prior reconciliation task; confirmed zero backend ever existed for it.

**POST-V1:** anything beyond the above minimum (deeper analytics, incident tooling) — not audited in detail this pass since it isn't launch-blocking either way.

## 18. Capability Matrix — Priority × Truth

| Capability | Priority | Truth |
|---|---|---|
| Manual New Order | REQUIRED V1 | LIVE |
| Storefront order intake | REQUIRED V1 | LIVE (backend) |
| CSV import | REQUIRED V1 | PARTIAL |
| Excel/XLSX import | REQUIRED V1 | PARTIAL |
| Google Sheets/Drive intake | **DESIRABLE V1 IF LOW-RISK** (Founder-decided) | MISSING |
| Address capture | REQUIRED V1 | LIVE |
| Geocoding | REQUIRED V1 | MISSING |
| Coverage decision | REQUIRED V1 | LEGACY/NON-CANONICAL (frontend mock) |
| Zone (manual label) | REQUIRED V1 | LIVE (as designed — a label, not geography) |
| **Vehicle type classification (Motorcycle/Car/Van)** | **REQUIRED V1** | **MISSING** — only a plate-number text field exists |
| **Rider onboarding vehicle-type support** | **REQUIRED V1** | **LEGACY/NON-CANONICAL** — hardcoded motorcycle-only copy and required document |
| **Capacity model (per-Rider max stops)** | **REQUIRED V1** | **MISSING** |
| **Vehicle/capacity-aware run eligibility** | **REQUIRED V1** | **MISSING** |
| Automatic grouping/optimization | REQUIRED V1 | MISSING |
| Manual run building (vendor) | REQUIRED V1 | LIVE |
| Manual stop sequencing (rider) | REQUIRED V1 | LIVE |
| Sequence lock + enforced execution order | REQUIRED V1 | LIVE |
| Vendor review/dispatch confirm | REQUIRED V1 | LIVE |
| Order approval gate | REQUIRED V1 | LIVE |
| Rider invitation/approval | REQUIRED V1 | LIVE |
| Operations/Helper Prepare→Pack→Ready | REQUIRED V1 | MISSING |
| POD capture | REQUIRED V1 | LIVE |
| Rider GPS live location | DESIRABLE V1 | PARTIAL/UNVERIFIED |
| Customer tracking (status) | REQUIRED V1 | LIVE |
| Customer ETA | REQUIRED V1 | MISSING (column exists, never set) |
| Customer rating | REQUIRED V1 | LIVE |
| Delivery-issue reporting | REQUIRED V1 | LIVE |
| Reschedule / operational recovery | **REQUIRED V1** (Founder-decided; scope kept narrow, exact behavior still open — §22) | MISSING |
| Post-pickup reassignment | DESIRABLE V1 | UNVERIFIED |
| FOUNDR business/rider/ops oversight | LAUNCH REQUIRED | LIVE |
| FOUNDR platform revenue | LAUNCH REQUIRED | LIVE |
| FOUNDR Invoices & Payouts | REMOVE | Correctly absent |

## 19. Dependency Map

**Order Intake → Canonical Validation → Address/Location → Coverage → Zone/Grouping → Vehicle & Capacity → Optimization/Planning → Vendor Review → Rider Assignment → Dispatch → Pickup → Ordered Multi-Drop Run → Customer Tracking → Delivery Result → Recovery/Completion/Audit**

Live: Order Intake (manual/Storefront) → Canonical Validation → Address capture → *(gap)* → Vendor Review/Manual Grouping → Rider Assignment → Dispatch → Pickup → Ordered Multi-Drop Run → Customer Tracking → Delivery Result (mostly) → Recovery (partial).

**The gap sits at exactly one place: Address/Location → Coverage → Zone/Grouping → Vehicle & Capacity → Optimization/Planning.** Everything upstream (getting an order into the system) and everything downstream (a human-built run executing correctly, in order, with proof, tracked by the customer) is real. The middle — turning an address into a coordinate, a coverage decision, a vehicle/capacity-eligible grouping, and an efficient plan — is the missing engine. Vehicle & Capacity sits inside this same gap, immediately upstream of Optimization, because an optimizer cannot propose a valid run without first knowing which Riders/vehicles a given order is even eligible for.

## 20. Current Repo Gaps (summary)

1. No geocoding anywhere.
2. Coverage/zone-matching is a frontend simulation with no real data behind it.
3. **No vehicle-type classification anywhere; Rider onboarding is hardcoded motorcycle-only.**
4. **No capacity concept of any kind.**
5. No optimizer — grouping and sequencing are 100% manual.
6. CSV/Excel import doesn't commit to canonical orders.
7. Google Sheets/Drive not started.
8. Operations/Helper has no backend lifecycle at all.
9. ETA is never computed.
10. Reschedule has no contract (open Founder decision on exact behavior).

## 21. Proposed Flow 2 Scope

See the audit report and the completion report for full workstream detail (objectives, dependencies, likely files, tests, worktree concerns). Sequence below is evidence-based, not a mechanical copy of any suggested order:

1. **Location & Geocoding** — pick a geocoding provider, wire it into every intake path, backfill coordinates. Hard prerequisite for everything downstream in this list except #6 and #7.
2. **Real Coverage & Zone Intelligence** — replace the frontend mock with a backend-verified coverage decision using real coordinates. Depends on #1.
3. **Vehicle & Capacity** — add vehicle-type to the Rider schema and onboarding flow (fixing the motorcycle-only hardcoding), add the recommended capacity model (§11a), and vehicle/capacity eligibility filtering to run-building. Does not strictly depend on #1/#2 at the schema level, but must land before #4 — an optimizer cannot filter by vehicle/capacity it doesn't know about.
4. **Optimization Engine v1** — deterministic clustering + sequencing (§12), consuming real coordinates (#1), real coverage (#2), and vehicle/capacity eligibility (#3). This is the convergence point of #1–#3; it cannot start meaningfully before they land.
5. **Operations / Helper Workspace** — define and build Prepare→Pack→Ready as real backend states plus a dedicated authenticated surface. **Evidence-based deviation from a naive linear order: this does not depend on #1–#4 at all** — it is an upstream-of-planning concern (an order must be prepared before it can be planned), and could reasonably be built in parallel with the location/optimization workstream rather than strictly after it, if worktree/team capacity allows.
6. **CSV/Excel Canonical Commit** — resolve the items-shape reconciliation (§9), wire `confirmCsvImport` to real `create_delivery` calls. **Also evidence-based deviation: this has no dependency on #1–#5 either** — it is purely an order-intake contract question and could be done any time, including in parallel or even first, since it's a comparatively small, well-scoped fix to an already-substantial feature.
7. **ETA Computation** — compute and keep `estimated_arrival_at` current from real plan/progress data. Depends on #4 (a real plan is what makes an ETA meaningful rather than guessed).
8. **Reschedule / Recovery** — close the open Founder decision on exact behavior, then build it. Benefits from #4/#7 existing (a reschedule needs to re-enter a real plan) but its typed-exception pattern can be scaffolded using the same approach as the already-live delivery-issue contract independently.
9. **Google Sheets/Drive** (only if not deferred at build time per §10) — after #6, since it is architecturally "CSV/Excel's commit path, different row source."

**Net evidence-based conclusion:** the Founder's suggested high-level order (Geocoding → Coverage/Zones → Vehicle & Capacity → Optimization → CSV/Excel → Operations/Helper → ETA → Recovery) is directionally correct for the *location-intelligence spine* (steps 1–4 and 7–8 above), but **Operations/Helper and CSV/Excel do not actually sit on that spine** — both are independent of it and can run in parallel with it rather than strictly after Optimization, which shortens the realistic critical path if team/worktree capacity allows more than one stream at once.

## 22. Unresolved Founder Decisions

**Decided this round** (recorded here for traceability, no longer open): Google Sheets/Drive is `DESIRABLE V1 IF LOW-RISK` (§10); the optimizer must be deterministic-first with an optional AI-assisted layer on top, not LLM-designed (§12); Operations/Helper ships as a genuinely distinct workspace, not a Vendor view (§15); Reschedule is `REQUIRED V1` with narrow recovery-only scope (§16); ETA must be truthful/range-honest, never fabricated precision (§16); the Rider/Driver terminology question needed no correction (already consistently "Rider," §11a).

**Still genuinely open:**

1. **Reschedule's exact behavior** — `REQUIRED V1` is now locked, but *what specifically happens* (who can trigger it, what states it's valid from, whether it creates a new run entry or mutates the existing one) is not decided. `docs/cefflo/DECISION_REPORT_ISSUE_RESCHEDULE.md` remains the open record; Flow 2 cannot build this until it's resolved.
2. **Optimization Engine v1 technical approach** — deterministic geographic clustering (self-built) vs. a paid routing/distance provider vs. a hybrid — a real cost/complexity tradeoff within the now-locked "deterministic foundation" architecture (§12).
3. **CSV/Excel items-shape fix** — this document now recommends the synthetic-single-line-item approach (§9) as the technically safest path; Founder confirmation of that specific approach (vs. an alternative) is still open.
4. **Vehicle/capacity V1 model** — this document recommends vehicle-based default capacity with per-Rider Vendor override (§11a); Founder confirmation of that specific model is still open.
5. **Vehicle/capacity override behavior** — this document recommends block-by-default with an explicit audited override (§11a); Founder confirmation is still open.
6. **Order-level vehicle requirement** — this document recommends deferring to Flow 2/Post-V1 pending evidence of need (§11a); Founder confirmation is still open.
7. **Operations/Helper exact build shape** — confirmed as a distinct workspace (decided), but the precise backend states and whether it reuses the existing Core Team invitation plumbing or needs its own is a Flow 2 design decision, not locked here.

## 23. Definition of Scope Freeze

This scope is frozen only once the Founder responds `APPROVE SCOPE FREEZE` (or `APPROVE WITH CORRECTIONS`, with those corrections applied and re-confirmed) to this document and its companion audit report. Until then, this remains **PROPOSED**, and Flow 2 implementation is not authorized.
