# CEFFLO GROW V1 — SCOPE LOCK

**Status:** PROPOSED — awaiting Founder approval (not yet frozen)\
**Baseline:** `staging @ 9e7ea2dae61deaaee068f156d4b0086d7fade14d`\
**Detailed evidence:** `docs/cefflo/audits/CEFFLO_GROW_V1_SCOPE_LOCK_AUDIT_REPORT.md`\
**Brand/positioning authority:** `docs/cefflo/CEFFLO_BRAND_BRAIN.md`

---

## 1. What Grow V1 Is

Grow V1 is the first public-launch version of Cefflo's local same-day delivery operating system: a business brings today's orders into one place, Cefflo helps organize and plan the delivery workload, riders execute multi-drop runs, and customers track delivery — all inside the business's own service area, with the business's own team.

## 2. Launch Promise (Founder-locked)

> Bring in today's orders → Cefflo validates and locates them → organizes the delivery workload → optimizes the delivery plan → vendor reviews → riders execute multi-drop runs → customers track → delivered today.

Cefflo adapts to how a vendor already takes orders, rather than forcing a high-volume vendor to re-key everything by hand.

## 3. Canonical Operating Journey

**Order Intake → Canonical Validation → Address / Location → Coverage → Zone / Geographic Grouping → Optimization / Planning → Vendor Review / Manual Adjustment → Rider Assignment → Dispatch → Pickup → Ordered Multi-Drop Run → Customer Tracking → Delivery Result → Recovery / Completion / Audit**

This chain is only as strong as its weakest link — see §20 for exactly where it breaks today.

---

## 4. REQUIRED V1

These are Founder-locked; they cannot be downgraded by an executor.

1. **AI Optimization Layer** — orders → location intelligence → grouping → proposed runs → recommendation → sequence → vendor review → dispatch. (Today: MISSING — see §12.)
2. **CSV bulk order import.** (Today: PARTIAL — see §9.)
3. **Excel/XLSX bulk order import.** (Today: PARTIAL — see §9.)
4. Manual New Order intake. (Today: LIVE.)
5. Cefflo Storefront order intake. (Today: LIVE at backend.)
6. Location capture (address) → coordinates → coverage → zone/grouping → planning, as one working chain. (Today: capture LIVE, everything after it MISSING/mocked — see §11.)
7. Vendor review, manual adjustment, and explicit dispatch confirmation before a run goes live. (Today: LIVE.)
8. Rider: receive an ordered run, execute stops in enforced order, capture POD, complete. (Today: LIVE.)
9. Customer: truthful tracking of real delivery status. (Today: LIVE, except ETA — see §16.)
10. Delivery-issue reporting (vendor and rider). (Today: LIVE.)

## 5. Desirable V1

- Connected Google Sheets/Drive intake — **recommended `POST-V1`**, see §10.
- Live rider GPS location on the map (schema/RLS exist; live write path unconfirmed).
- Post-pickup reassignment (mentioned in migration history as a deferred correction; current exact behavior not re-verified this pass).
- Reschedule (an existing, still-open Founder decision — see §16, §21).

## 6. Post-V1

- Google Sheets / Google Drive connected intake (pending Founder classification, recommendation below).
- Website/webhook order intake.
- Predictive/advanced route optimization beyond a working baseline optimizer.
- Nonessential FOUNDR analytics beyond the already-live admin surfaces.

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

**What's real today:** file upload (5MB limit) → CSV text parsing or XLSX.js parsing → column-alias recognition (Order ID/Name/Phone/Address/Zone with common header variants) → per-row validation (missing fields, duplicate order IDs) → a preview table with per-row status → an inline "fix this row" editor.

**What's missing:** the commit step. The code itself states why — the current CSV/XLSX row shape has no line-item data, and the canonical order-creation path (`create_delivery`) needs items. This isn't a vague gap; it's one clearly identified, scoped contract decision away from being finished.

**To close this gap (Flow 2 candidate, not decided here):** either (a) define a minimal-items convention for imported orders (e.g., a single free-text "order contents" line item), or (b) extend the canonical order contract to accept item-less orders explicitly. Either is a scoped backend decision, not a rebuild.

## 10. Connected Spreadsheet (Google Sheets / Drive) Recommendation

**Recommended: `POST-V1`.**

Reasoning: this is a materially larger scope than CSV/Excel (OAuth consent, token storage/refresh, sync scheduling, source-row identity, change/delete handling) — and the simpler, no-auth version of the same idea (CSV/Excel) isn't committing orders yet. Building the harder version first would be building on a foundation that doesn't yet reach the finish line for the easy version. Once CSV/Excel import actually creates canonical orders end-to-end, a Google Sheets connector reduces mostly to "same commit path, different row source."

**This is a recommendation. The Task Master reserves this classification for the Founder — see §21.**

## 11. Location → Coverage → Zone Contract (today vs. required)

| Stage | Required | Today |
|---|---|---|
| Address capture | Required field on every order | **LIVE** |
| Address → coordinates (geocoding) | Automatic | **MISSING** — no geocoding call exists anywhere in the codebase, on any intake path |
| Coverage decision | Should determine if an address is deliverable | **Frontend-simulated only** — reads a `coverageRadiusKm` property that doesn't exist on the real `zones` table; not backend-enforced |
| Zone / grouping | Should organize orders geographically | **Manual label only** — a vendor-typed name with zero geography, by explicit design of its own migration |
| Missing-location blocking | Should prevent dispatch without a location | **Not enforced** — `build_rider_run` has no coverage/location check |

## 12. AI Optimization Contract (today vs. required)

The single most important finding of this audit.

**Required:** orders → location intelligence → geographic/operational grouping → proposed runs → rider/run recommendation → efficient stop sequence → vendor review → dispatch.

**Today:** a vendor manually picks which orders go into a run and which rider gets it (`build_rider_run`); a rider manually drags stops into an order (`save_run_sequence`). Both are well-built, safe, idempotent, all-or-nothing backend contracts — the *execution* half of the pipeline is solid. But there is no automatic grouping, no distance/time calculation, no capacity-aware recommendation, and no sequence optimization anywhere. **No optimizer exists.** What exists is deterministic manual sequencing, exactly the thing the Task Master said not to call "AI optimization."

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
| Vendor / Owner | Setup, intake, review, dispatch, oversight, recovery | **Mostly LIVE** — CSV commit and location intelligence are the open gaps |
| Operations / Helper | Prepare → Pack → Ready | **MISSING as a workspace.** No backend lifecycle states exist for it, and the Vendor UI's own "Helper Pool" screen currently reads: *"Helpers is not connected yet."* A separate "Core Team" (staff invitation/membership) is real and live, but is not the same thing as a Prepare→Pack→Ready workflow. |
| Rider | Receive run, execute in order, POD, complete | **LIVE**, with GPS live-location and post-pickup reassignment unconfirmed |
| Customer | Order (where applicable), truthful tracking, rating | **LIVE**, except ETA is never actually computed (always effectively blank) |

## 16. Exception & Recovery Matrix (launch-critical subset)

| Exception | Today | Dispatch-blocking? |
|---|---|---|
| Delivery issue (vendor/rider-reported) | **LIVE** — typed reason enum, both actors covered | No, tracked as an event |
| Reschedule | **MISSING** — a still-open, explicitly documented Founder decision (`docs/cefflo/DECISION_REPORT_ISSUE_RESCHEDULE.md`) | N/A |
| Invalid/unresolved address, out-of-coverage | Frontend-simulated only, not backend-enforced | No (should be, isn't) |
| Duplicate/malformed CSV row | Caught in preview UI | Import doesn't commit yet regardless |
| Rider unavailable/capacity exceeded | No capacity concept exists to detect this | No |
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
| Google Sheets/Drive intake | FOUNDER DECISION REQUIRED (recommend POST-V1) | MISSING |
| Address capture | REQUIRED V1 | LIVE |
| Geocoding | REQUIRED V1 | MISSING |
| Coverage decision | REQUIRED V1 | LEGACY/NON-CANONICAL (frontend mock) |
| Zone (manual label) | REQUIRED V1 | LIVE (as designed — a label, not geography) |
| Automatic grouping/optimization | REQUIRED V1 | MISSING |
| Rider capacity | REQUIRED V1 | MISSING |
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
| Reschedule | DESIRABLE V1 (Founder decision open) | MISSING |
| Post-pickup reassignment | DESIRABLE V1 | UNVERIFIED |
| FOUNDR business/rider/ops oversight | LAUNCH REQUIRED | LIVE |
| FOUNDR platform revenue | LAUNCH REQUIRED | LIVE |
| FOUNDR Invoices & Payouts | REMOVE | Correctly absent |

## 19. Dependency Map

**Order Intake → Canonical Validation → Address/Location → Coverage → Zone/Grouping → Optimization/Planning → Vendor Review → Rider Assignment → Dispatch → Pickup → Ordered Multi-Drop Run → Customer Tracking → Delivery Result → Recovery/Completion/Audit**

Live: Order Intake (manual/Storefront) → Canonical Validation → Address capture → *(gap)* → Vendor Review/Manual Grouping → Rider Assignment → Dispatch → Pickup → Ordered Multi-Drop Run → Customer Tracking → Delivery Result (mostly) → Recovery (partial).

**The gap sits at exactly one place: Address/Location → Coverage → Zone/Grouping → Optimization/Planning.** Everything upstream (getting an order into the system) and everything downstream (a human-built run executing correctly, in order, with proof, tracked by the customer) is real. The middle — turning an address into a coordinate, a coverage decision, and an efficient plan — is the missing engine.

## 20. Current Repo Gaps (summary)

1. No geocoding anywhere.
2. Coverage/zone-matching is a frontend simulation with no real data behind it.
3. No optimizer — grouping and sequencing are 100% manual.
4. No rider capacity concept.
5. CSV/Excel import doesn't commit to canonical orders.
6. Google Sheets/Drive not started.
7. Operations/Helper has no backend lifecycle at all.
8. ETA is never computed.
9. Reschedule has no contract (open Founder decision).

## 21. Proposed Flow 2 Scope

See the audit report and the completion report (§M) for full workstream detail. Summary, in dependency order:

1. **Location & Geocoding** — pick a geocoding provider, wire it into every intake path, backfill coordinates.
2. **Real Coverage & Zone Intelligence** — replace the frontend mock with a backend-verified coverage decision using real coordinates.
3. **Rider Capacity** — add the concept to the schema and to run-building eligibility.
4. **Optimization Engine v1** — deterministic-first (nearest-neighbor/geographic clustering is a legitimate honest v1, per the Task Master's own allowance), feeding proposed runs and a recommended sequence, with the vendor's manual override staying exactly as-is.
5. **CSV/Excel Commit Path** — resolve the items-shape decision, wire `confirmCsvImport` to real order creation.
6. **Operations/Helper Workspace** — define and build Prepare→Pack→Ready as real backend states + a dedicated UI.
7. **ETA Computation** — compute and keep `estimated_arrival_at` current from real plan/progress data.
8. **Reschedule** — close the open Founder decision from `DECISION_REPORT_ISSUE_RESCHEDULE.md`, then build it.
9. **Google Sheets/Drive** (only if the Founder does not defer it further) — after CSV/Excel is proven end-to-end.

## 22. Unresolved Founder Decisions

1. Google Sheets/Drive classification (recommend `POST-V1`, §10).
2. Reschedule: resolve the open product decision in `DECISION_REPORT_ISSUE_RESCHEDULE.md` before Flow 2 can build it.
3. Optimization Engine v1 approach: deterministic geographic clustering vs. a paid routing API/provider vs. AI-assisted — a real cost/complexity tradeoff the Founder should weigh in on before Flow 2 starts.
4. CSV/Excel items-shape fix: minimal free-text line item vs. extending `create_delivery` to accept item-less orders.
5. Whether Operations/Helper ships as a fully separate authenticated surface or as a scoped view inside Vendor for V1.

## 23. Definition of Scope Freeze

This scope is frozen only once the Founder responds `APPROVE SCOPE FREEZE` (or `APPROVE WITH CORRECTIONS`, with those corrections applied and re-confirmed) to this document and its companion audit report. Until then, this remains **PROPOSED**, and Flow 2 implementation is not authorized.
