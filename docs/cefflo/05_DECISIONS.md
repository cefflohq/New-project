# CEFFLO --- LOCKED DECISIONS

Brand/product doctrine authority: `docs/cefflo/CEFFLO_BRAND_BRAIN.md`.
Where a decision below conflicts with the Brand Brain, the Brand Brain
wins; the decision is retained here for history and marked accordingly.

## D-01 Positioning

**STATUS: SUPERSEDED.** This decision reflected an earlier home-food-only
positioning. Current canonical positioning: Cefflo is a local same-day
delivery operating system for businesses that manage deliveries within
their own service area; food is an example, not the category boundary.
See `docs/cefflo/CEFFLO_BRAND_BRAIN.md` §1.1, §4. Retained below for
decision history only — not current doctrine.

> Cefflo = Operating System for Home-Based Food Businesses. Not primarily
> marketplace/rider company/GrabFood-style delivery platform.

The non-marketplace / non-rider-company / non-GrabFood-style framing
itself remains current doctrine (Brand Brain §3) — only the food-only
category boundary is superseded.

## D-02 Acquisition

Primary acquisition focus is vendors, not building a proprietary rider
network.

## D-03 Rider Model

Support vendor-owned/trusted rider teams through protected invitation/join,
not an open Cefflo Rider marketplace. One Rider Auth identity may belong to
multiple Vendor teams with explicit membership and strict authorization
boundaries.

## D-04 Customer Tracking

Tokenized customer tracking; no customer account required. The normal entry is
the shared tokenized link; manual token entry is not core Stage 4 scope. Tokens
require explicit expiry, revocation, rotation and protected recovery policy.

## D-05 Client Strategy

PWA-first for Stage 4. Future native Rider app does not block Stage 4
unless Founder explicitly changes scope.

## D-06 Code SOT

GitHub `main` is canonical code SOT unless explicitly superseded.

## D-07 Backend/Deployment

Supabase is current backend direction. Vercel is current web deployment
direction. Cloudflare remains part of the intended production DNS/edge
architecture. Preview/staging/production backend separation is required before
mutating test suites or production release.

## D-08 Release Policy

Normal updates should not require maintenance mode. Maintenance is
emergency/exception only. Prefer low-activity release windows,
backward-compatible backend changes, health checks and rollback. Cloudflare,
DNS, SSL and production-domain cutover belong only to the controlled
production-release phase after release, recovery and rollback gates pass.

## D-09 Payments

Vendor-controlled direct payment direction; COD is not core; riders
should not handle Cefflo cash.

## D-10 Engineering Method

No patchwork final fixes. Use scoped clean/root-cause implementation. Do
not redesign/refactor unrelated working areas. Preserve existing Vendor, Rider
and Customer UI shells and working protected backend foundations wherever
practical; integrate or adjust rather than rebuild wholesale.

## D-11 AI Ownership

**STATUS: SUPERSEDED.** This decision reflected an earlier fixed
single-executor model. Current agent roles and task routing are defined
by `docs/cefflo/agent-os/CEFFLO_AGENT_OS_CORE.md` §3 and §6: Claude is
the primary implementer for substantial Cefflo work (repo-wide audits,
architecture/reconciliation, multi-file implementation, large rollouts);
Codex is the bounded implementer/finisher for small, focused work;
ChatGPT orchestrates/plans for substantial tasks. Founder instruction
overrides normal routing. Retained below for decision history only —
not current doctrine.

> Codex is primary engineering executor and canonical code integrator.
> Claude is optional UI/prototype/review/specialist support, not parallel
> code SOT.

## D-12 Founder Authority

Founder approves protected production/security/billing/destructive
operations and final phase gates.

## D-13 Stage Discipline

Design future systems when useful, but build only when the current stage
needs them. Do not delay Stage 4 with later-stage
automation/native/regional features. Native Rider Flutter, complex autonomous
multi-agent orchestration, regional expansion and later-stage growth systems
are explicitly deferred.

## D-14 UI Launch Review

Before calling Vendor/Rider UI launch-ready verify: 1. exception/error
states; 2. urgent action hierarchy; 3. cross-app lifecycle/status
consistency.

## D-15 Naming

Brand: Cefflo. Administrative command center: FOUNDR.

## D-16 Business Authorization

Founder is final platform authority. Owner is the highest Vendor-business
authority. Operators/members receive explicit scoped permissions. Riders are
authorized only through team membership and delivery scope. Customers are
authorized only through valid tracking tokens. Lifecycle-sensitive writes must
use protected backend contracts; broad direct-table authority is not the target.

## D-17 Order and Delivery Planning

Vendor order approval/readiness is an explicit step before pickup semantics.
One delivery session/batch may contain multiple orders/stops. Batching, zones,
sessions, assignments and multi-drop delivery are required Stage 4 capabilities,
not legacy. Choose the simplest robust persisted/derived/hybrid zone contract
during implementation design. Operational outcomes must be backend-authoritative.

## D-18 Exceptions and Offline Promise

Exceptions use typed report/resolve/reassign/redelivery workflows with event
history. Vendor Stage 4 does not promise protected offline mutations; show
graceful network failure and retry. Rider Stage 4 supports practical PWA
degraded/network handling; native-grade offline/background GPS is future.
Availability remains simple and operationally necessary only.

## D-19 POD Integrity

Delivery completion must verify that the POD object exists in the correct
protected bucket/path, belongs to the order, was supplied under assigned-rider
authorization and has valid upload state. Fabricated, nonexistent, malformed,
foreign-order or foreign-rider POD paths must fail.

## D-20 Production Truth

Production must not confirm operational outcomes from mock, seeded, demo or
local-only state. Invalid tracking tokens expose no seeded customer/order data;
fabricated POD fallback is prohibited; rating success follows confirmed backend
persistence. Performance metrics derive from authoritative backend events/data.

## D-21 FOUNDR Stage 4 Scope

Minimum FOUNDR scope is Overview/Platform Health, Vendors, Riders, Delivery
Operations, required privileged controls, emergency Maintenance Control,
Feature Flags, Client Version Control, Audit Log, Integrations Health and
System/Security Health. Privileged actions require authorization,
confirmation/reason controls and append-only audit. Developer Mode remains
minimal and operational/diagnostic.

## D-22 Business Configuration and External Integrations

Business concepts/types primarily share configurable architecture; create
separate backend behavior only when genuinely required. The Vendor sales/order
page is required and feeds customer orders into the Vendor's Cefflo workflow.
External integrations are implemented only when required for functional Stage
4 or security/release requirements.

## D-23 Knowledge Reconciliation (2026-09-04)

A newer, Founder-approved, more granular SOT pack was reconciled into the repo at `docs/cefflo/sot/` on 2026-09-04 (see `docs/cefflo/sot/00_INDEX.md`). It supersedes `docs/cefflo/CEFFLO_BRAND_BRAIN.md` for brand/product/architecture doctrine (that file is retained, marked superseded, not deleted). Two clarifications from this reconciliation:

1. The new Architecture/Vendor-Web/Rider-Flutter-Master doctrine names Vendor Flutter and Rider Flutter as target first-class clients in Cefflo's canonical multi-client architecture. This describes the TARGET end-state, not a change to build sequencing. D-13's stage-gating for native Rider Flutter remains in force: it is a FUTURE capability per the Capability Truth States system, and its own source master (`docs/cefflo/sot/08_RIDER_FLUTTER_33_SCREEN_MASTER.md`) is self-labeled "Founder Review Required" with an unchecked Definition of Done. No Vendor Flutter master exists in this repo yet.
2. `docs/cefflo/sot/07_BUSINESS_LAUNCH_COMMERCIAL.md` (commercial/billing/go-live governance) is a new layer complementary to `docs/cefflo/launch/CEFFLO_GROW_V1_SCOPE_LOCK.md` (frozen V1 product/feature scope, 2026-09-03) — the two are not duplicates and neither supersedes the other.

Open gap surfaced by this reconciliation (not resolved, flagged for Founder attention): no Cefflo Pricing Master exists anywhere in this repository or in the reconciled knowledge pack. `docs/cefflo/sot/07_BUSINESS_LAUNCH_COMMERCIAL.md` §4 requires pricing to come from a Founder-approved Pricing Master, which does not yet exist.

## D-24 Knowledge Reconciliation, Second Pass (2026-09-04)

Three of D-23's four flagged gaps were filled by newly-supplied Founder documents, reconciled into `docs/cefflo/sot/`:

1. `docs/cefflo/sot/10_PRICING.md` (was: CEFFLO_PRICING_PLAN_MASTER_AUDIT.md) — status **CANDIDATE, NOT Founder-locked**. Every price/allowance in it (RM0/RM99/RM199/RM499/Custom, delivery/rider/zone/team caps) remains open per its own §16/§19 Definition of Done. This is the working input to `docs/cefflo/sot/07_BUSINESS_LAUNCH_COMMERCIAL.md` §4's Pricing Authority requirement, not itself a satisfaction of it — do not publish any figure from this file as final commercial truth.
2. `docs/cefflo/sot/09_VENDOR_FLUTTER_60_SCREEN_MASTER.md` (was: CEFFLO_VENDOR_FLUTTER_60_FULL_SCREEN_MASTER.md) — status **Working Master Baseline, Founder Review Required**, not implemented. Its own internal HOLD flags are preserved as-is: Subscription/billing screens V-50–V-54 remain HOLD pending a separately-approved Cefflo-subscription payment architecture (this is Vendor-paying-Cefflo billing, not vendor-customer payment — that boundary is unchanged), and V-41 Delivery Settings needs reconciliation against Service Area/Zones before lock. Same stage-gating logic as D-23 item 1 applies: this describes target scope, not authorization to begin Vendor Flutter implementation. The current LIVE Vendor client remains Vendor Web/Desktop.
3. `docs/cefflo/sot/marketing/07_MARKETING_MEMORY.md` (was: CEFFLO_MARKETING_MEMORY.md) — schema/doctrine only. Per its own §22, performance memory is intentionally EMPTY at initialization; no AI Marketing Engine implementation, n8n workflow, or real campaign evidence exists in this repo. Do not treat anything in this file as evidence of actual marketing results.

**Remaining open gap (unchanged from D-23):** `docs/cefflo/sot/08_RIDER_FLUTTER_33_SCREEN_MASTER.md` is still Founder-review-pending — no new Rider Flutter material was supplied in this pass.

No conflicts were found between the three new documents and existing doctrine; all three are additive fills of previously-flagged gaps, correctly labeled CANDIDATE/HOLD/Working-Master rather than promoted to LOCKED/LIVE.

## D-25 AI Content Engine v1.1 Reconciliation (2026-09-10)

A newer, Founder-approved AI Content Engine orchestration document (`CEFFLO_AI_CONTENT_ENGINE_MASTER_ORCHESTRATOR_SOT_v1.1_FINAL.md`) was reconciled against the existing marketing knowledge pack (`docs/cefflo/sot/marketing/`, merged 2026-09-04) via a Founder Decision Gate. Full analysis: `docs/cefflo/audits/CEFFLO_AI_CONTENT_ENGINE_V1.1_RECONCILIATION_REPORT.md`. Six decisions were approved:

1. **Lane model:** Instagram + Facebook share one Meta package by default; TikTok and Threads remain independent lanes. Canonical default = 3 publishing lanes. Theoretical ceiling for 5 core experiments/day corrected from the superseded ~140/week (4-lane assumption) to **~105/week** (3-lane). IG/FB may still split for a genuine platform-fit reason. Corrected in `docs/cefflo/sot/marketing/03_CONTENT_PHILOSOPHY.md` §2, `06_AI_MARKETING_ENGINE_MASTER.md` §5, `07_MARKETING_MEMORY.md` §3, and `00_MARKETING_KNOWLEDGE_PACK_INDEX.md`; clarified in `04_CREATIVE_PLAYBOOK.md` §11.
2. **Weekly Winner Engine + Paid Growth preserved:** modeled as `CEFFLO - 11 - Weekly Winner Engine` and `CEFFLO - 12 - Paid Growth`, weekly-cadence workflows layered after (not spliced into) the daily `CEFFLO - 00..10` chain, reading from Marketing Memory. Workflow 12 remains subject to the existing Founder/budget spend gate in `05_PAID_GROWTH_PLAYBOOK.md` §5. `05_PAID_GROWTH_PLAYBOOK.md` is unmodified — this decision only gives it explicit architectural placement.
3. **Master Concept = Core Experiment:** `master_concept_id` is the same persisted entity as the existing `CEFFLO-YYYY-Wxx-E###` experiment ID (`07_MARKETING_MEMORY.md` §5) — no new ID format introduced. `angle_id` remains an internal working identifier scoped to the Research & Angle Miner stage, tracked via Marketing Memory taxonomy tagging, not a new persisted top-level lineage ID. Platform-derivative suffixes (`-TT01`, `-IGR01`, `-FBR01`, `-TH01`, etc.) are unchanged.
4. **n8n workflow naming:** `CEFFLO - 00` through `12`, plus `CEFFLO - 99 - Error & Recovery`, is now canonical. The older `WF-01`..`WF-08` naming in `06_AI_MARKETING_ENGINE_MASTER.md` §8 is marked superseded-in-detail there (retained, not deleted) with an explicit mapping table to the new naming.
5. **New document created:** `docs/cefflo/sot/marketing/08_AI_CONTENT_ENGINE_ORCHESTRATOR.md` — the v1.1 source text (unedited) plus a clearly separated Repo Reconciliation Addendum covering decisions 1-4 and 6. It is the 10th item in the marketing knowledge hierarchy (`00_MARKETING_KNOWLEDGE_PACK_INDEX.md` and `docs/cefflo/sot/00_INDEX.md` §6 updated accordingly), implementing Teams 1-4 of `06_AI_MARKETING_ENGINE_MASTER.md` as a concrete n8n architecture. It does not replace that document's charter-level content (governance, cost, testing, evidence, Team 5, full Definition of Done), which remains canonical and unmodified.
6. **n8n repo-tracking policy — deferred:** whether `CEFFLO - 00 - Orchestrator Test` or any future n8n workflow export is version-controlled in this repository is explicitly deferred to the actual implementation/build gate. No `infra/n8n/` directory was created, no export policy was introduced, and `docs/cefflo/12_SECURITY.md`'s secrets doctrine is unchanged. Per D-23/D-24, no n8n workflows or `marketing_*` tables exist anywhere in this repository as of this reconciliation.

Untouched by this reconciliation, confirmed no direct conflict: `docs/cefflo/sot/marketing/01_AUDIENCE_ICP.md`, `02_CLAIMS_REGISTRY.md`, and the doctrine (as opposed to volume-math) content of `03_CONTENT_PHILOSOPHY.md` and `04_CREATIVE_PLAYBOOK.md`. `05_PAID_GROWTH_PLAYBOOK.md` is untouched and remains fully in force per decision 2.

## D-26 Content World & Brand Voice Doctrine — FG-1 Reconciliation (2026-09-10)

Two Founder-supplied working masters — `CEFFLO_CONTENT_WORLD_CONTENT_PRODUCTION_DOCTRINE_MASTER.md` and `CEFFLO_BRAND_VOICE_MALAYSIAN_LANGUAGE_SYSTEM_MASTER.md` — were reconciled against the existing marketing pack, `08_AI_CONTENT_ENGINE_ORCHESTRATOR.md`, and D-25, per `docs/cefflo/audits/CEFFLO_CONTENT_WORLD_DOCTRINE_RECONCILIATION_REPORT.md`. Founder approved FG-1 (SOT Reconciliation) for the Content World doctrine with five explicit decisions; the Brand Voice doctrine was reconciled in the same pass with no material conflict found.

1. **Content Quantity Doctrine corrected to D-25:** the Content World doctrine's §16 originally restated the superseded 4-lane/~140-outputs/week model. Corrected in place to the Founder-approved 3-lane Meta-shared model (~105/week, `35 × 3`). The superseded 4-lane/~140 model is not restored or preserved. The doctrine's underlying point (distribution volume ≠ production volume) is preserved.
2. **Five pain/situation/world taxonomies kept separate, cross-referenced, not consolidated:** Segment Families (`01_AUDIENCE_ICP.md` §5, *who*), Pain Library P01–17 (`01_AUDIENCE_ICP.md` §8, audience pains), Situation Library S01–18 (`03_CONTENT_PHILOSOPHY.md` §6, angle-mining contexts), Operational Pain OP-01–14 (`09_CONTENT_WORLD_PRODUCTION_DOCTRINE.md` §4, production-scenario problems), and Content Worlds CW-01–06 (`09_CONTENT_WORLD_PRODUCTION_DOCTRINE.md` §3, persistent production environments) each keep their own scope and numbering. Cross-references added across `01_AUDIENCE_ICP.md`, `03_CONTENT_PHILOSOPHY.md`, `07_MARKETING_MEMORY.md`, and `09_CONTENT_WORLD_PRODUCTION_DOCTRINE.md` Addendum A2/A3/A4 so agents do not treat overlapping entries as contradictory duplicates.
3. **Signal Lime / logo wording corrected, not locked:** `09_CONTENT_WORLD_PRODUCTION_DOCTRINE.md` §19 originally described "official CEFFLO logo" and a locked Signal Lime "system." Corrected in place to reflect current repository truth — no logo is Founder-locked yet (`docs/cefflo/sot/06_BRAND_ASSETS_GOVERNANCE.md` §5) and Signal Lime `#C7F000` remains a candidate color (`04_CREATIVE_PLAYBOOK.md` §3). The color value itself is unchanged; only the finality claim was corrected. This reconciliation does not lock either.
4. **Video Editor/Assembler — capability documented, no insertion point adopted:** `09_CONTENT_WORLD_PRODUCTION_DOCTRINE.md` Addendum A6 documents the required capability and presents two unselected options for inserting it into the `CEFFLO-00..12,99` family (internal to 05A/05B, or a new shared sub-workflow) for a future, separate Founder review. Nothing was applied to `docs/cefflo/tasks/CEFFLO_DEEPSEEK_AI_ROUTER_IMPLEMENTATION_MASTER.md` or any n8n workflow.
5. **FG-2 (Content World Baseline) remains ungranted; Brand Voice & Language System dependency now supplied.** The Content World doctrine's own Founder Gates FG-2 through FG-5 remain unauthorized — no structured Content World/Operational Pain/Scenario data, no video model benchmark, no Editor/Assembler build, and no production/publishing/ads activation may begin. The CEFFLO Brand Voice & Malaysian Language System doctrine this gate was waiting on has since been supplied and reconciled as `docs/cefflo/sot/marketing/10_BRAND_VOICE_LANGUAGE_SYSTEM.md` (native BM generation — never translated from an English master — speech-register system, respect boundary, speaker-voice matrix). No material conflict was found between it and existing Brand Brain (`05_BRAND_BRAIN.md` §4 Voice, §16 Brand Vocabulary), Content Philosophy, or Creative Playbook doctrine — it is a previously-missing elaboration, not a contradiction. Supplying this input does not itself grant FG-2, nor this document's own FG-V1 through FG-V4 (Voice Baseline / Calibration Set / Voice-Audio Test / Production Integration) — all remain separate, explicit Founder approvals.

**New documents created:** `docs/cefflo/sot/marketing/09_CONTENT_WORLD_PRODUCTION_DOCTRINE.md` (hierarchy item 11) and `docs/cefflo/sot/marketing/10_BRAND_VOICE_LANGUAGE_SYSTEM.md` (hierarchy item 12), both cross-referenced from `00_MARKETING_KNOWLEDGE_PACK_INDEX.md`, `docs/cefflo/sot/00_INDEX.md` §6, and — for the Brand Voice document — `docs/cefflo/sot/05_BRAND_BRAIN.md` §4. Cross-reference notes (no doctrine changes) added to `01_AUDIENCE_ICP.md` §5, `03_CONTENT_PHILOSOPHY.md` §4/§6/§7/§8, `04_CREATIVE_PLAYBOOK.md` §3/§6–9/§7/§13, and `07_MARKETING_MEMORY.md` §4.B/§6/§19.

**Untouched, confirmed no direct conflict:** `02_CLAIMS_REGISTRY.md`, `05_PAID_GROWTH_PLAYBOOK.md`, `06_AI_MARKETING_ENGINE_MASTER.md`, `08_AI_CONTENT_ENGINE_ORCHESTRATOR.md`, `docs/cefflo/tasks/CEFFLO_DEEPSEEK_AI_ROUTER_IMPLEMENTATION_MASTER.md`, and the `automation/n8n/content-engine` ROI skeleton — none required changes for this reconciliation.

**No n8n workflow, credential, migration, or production/publishing/ads/schedule was touched.** No commit or push was made as part of this reconciliation.

## D-27 Creative Intelligence Layer — Reconciliation + Implementation (2026-09-11)

`CEFFLO — CREATIVE INTELLIGENCE LAYER: Master Specification & Implementation Directive` (Founder-directed, dated 2026-09-11) was reconciled and — per explicit Founder instruction to execute all non-conflicting phases through testing — substantially implemented, per its own §1 (Repo/SOT Reconciliation) through §10 (Testing).

**One material conflict found (GATE B), flagged and resolved conservatively, not silently:** the source document's §2 instructs marketing content to call car/van operators "Driver"/"Delivery Driver," reserving "Rider" for motorcycle only. This directly conflicts with `docs/cefflo/audits/CEFFLO_GROW_V1_SCOPE_LOCK_AUDIT_REPORT.md` §11a (Founder-locked: *"'Driver' is not introduced as a competing term"*), `docs/cefflo/tasks/CEFFLO_GROW_V1_VEHICLE_CAPACITY_SCOPE_ADDENDUM.md` §2, `docs/cefflo/sot/01_PRODUCT_TRUTH.md`'s canonical spine, and the real live schema (`supabase/migrations/202609030003_s4_11_batch_3_vehicle_capacity_compatibility.sql`'s `rider_vehicle_type` enum on the `riders` table — no `drivers` table or terminology exists anywhere in the codebase). Resolution: the taxonomy defaults `canonical_role`/`natural_language_label` to **"Rider"** for all vehicle types (the existing locked doctrine), flagged with `_terminology_note` fields and an explicit regression test (`GATE_B_terminology_guardrail`) in `automation/n8n/content-engine/tests/cil_test.mjs`. Not applied as originally written; not silently discarded either — the source document's own §2 opening line reads as a deliberate instruction, so this is presented for Founder resolution rather than decided unilaterally. Reversing the default (to CIL's original "Driver for car/van" proposal) is a one-line change once the Founder decides.

**No other material conflict found** (Gates A/C/D/E all clear — see the reconciliation addendum in the new SOT document for detail).

**New SOT document:** `docs/cefflo/sot/marketing/11_CREATIVE_INTELLIGENCE_LAYER.md` (hierarchy item 13) — source text reproduced with the GATE B correction applied in place at §2/§29, plus a Repo Reconciliation Addendum (relationship to `09_CONTENT_WORLD_PRODUCTION_DOCTRINE.md`'s Phase B, full GATE B analysis, implementation summary).

**Implemented (Phases 3–8, 10), all under `automation/n8n/content-engine/` (uncommitted, matching the rest of this session's work):**
- Taxonomy (Phase 3): `fixtures/cil/{vehicle_types,business_archetypes,personas,operational_situations,emotional_tensions,creative_formats}.json`.
- Scenario contract (Phase 4): `contracts/cil-scenario.schema.json`.
- Scenario engine (Phase 5): `scripts/cil-scenario-engine.mjs` — deterministic, includes a vehicle-mix realism heuristic.
- Validation (Phase 6): `scripts/cil-validate.mjs` — plausibility, business/vehicle/human fit, Product-Truth allowlist check, language-register check, creative-value check, anti-fabrication, diversity/novelty check.
- Marketing Memory contract (Phase 8): `migrations/202609110001_cil_scenarios.sql` (additive `cil_scenarios` table) — **created, not applied to any database**; target Postgres instance is the same open item already recorded against the DeepSeek AI Router Master's Phase 0.
- Tests (Phase 10): `tests/cil_test.mjs` — all 10 representative scenarios (meal prep+motorcycles, catering+van, florist+car, ecommerce+mixed fleet, factory/B2B+van, bakery+motorcycle/car, delivery-person shortage, order spike, customer-communication pressure, mixed-vehicle workload) plus negative tests for vehicle-realism rejection, Product-Truth rejection, anti-fabrication rejection, diversity/novelty flagging, the GATE B terminology guardrail, and taxonomy breadth. **Executed — all passed** (`{"result":"PASS","scenarios_tested":10,...}`). Existing regression suite re-run: `tests/validate_artifacts.mjs` passed unchanged; `tests/roi_smoke.mjs` fails at the same pre-existing, already-disclosed step as before this task (SOT-manifest resolution against `HEAD` for `08_AI_CONTENT_ENGINE_ORCHESTRATOR.md`, which remains uncommitted from an earlier reconciliation pass) — not a regression introduced by this work.

**Not implemented in this pass, by design:** Phase 7 (Content & Strategy handoff) is satisfied by the scenario contract itself — no separate code was needed. Phase 9 (n8n integration) is documented only (CIL slots into `CEFFLO - 02 - Research & Angle Miner` per the architecture diagram) — no live n8n workflow was created, modified, or imported, consistent with Production Safety (GATE D). No migration was applied to any database.

**Final status (superseded by the update below): ~~PASS WITH LIMITATIONS~~**

### D-27 update — GATE B Resolved (2026-09-11)

Founder resolved the GATE B conflict flagged above. Decision: **the product/backend/API/schema role stays exactly "Rider" everywhere — no Rider → Driver product or schema migration of any kind.** "Driver" is adopted only as a Creative Intelligence / Content World / marketing-copy **display term**, vehicle-contextual: Motorcycle → Rider; Car → Driver; Van → Driver (alt. "Van Driver"); a mixed/general workforce (more than one vehicle type in a scenario) → "Delivery Team", never a singular Rider/Driver label.

**Implemented:** `automation/n8n/content-engine/fixtures/cil/vehicle_types.json` (`canonical_role` unchanged at `"rider"`; `natural_language_label` vehicle-contextual; `mixed_fleet_label: "Delivery Team"` added); `fixtures/cil/personas.json` (fixed "Rider" label replaced with a per-scenario-resolved note); `scripts/cil-scenario-engine.mjs` (new `resolveWorkforceLabel()`, wired into `buildScenario()` → `delivery_team.label`); `contracts/cil-scenario.schema.json` (`delivery_team.label` documented); `scripts/cil-validate.mjs` (new `WORKFORCE_LABEL` check). `docs/cefflo/sot/marketing/11_CREATIVE_INTELLIGENCE_LAYER.md` §2/§29 annotations and Addendum C1 updated from "flagged, unresolved" to "resolved," with the exact mapping recorded.

**Tests re-run, all passed:** `tests/cil_test.mjs` — `canonical_role` confirmed `"rider"` for all three vehicle types; `natural_language_label` confirmed Motorcycle=Rider/Car=Driver/Van=Driver; `resolveWorkforceLabel()` verified for single motorcycle, single car, single van, 2-type mixed, and 3-type mixed fleets; end-to-end verification through all affected representative scenarios (catering→van→Driver, florist→car→Driver, ecommerce→mixed→Delivery Team, mixed-vehicle-workload→3-type mixed→Delivery Team); and a direct read of `supabase/migrations/202609030003_s4_11_batch_3_vehicle_capacity_compatibility.sql` confirming the real `rider_vehicle_type` enum is byte-for-byte untouched and no competing `driver_vehicle_type` enum exists (`git status`/`git diff --stat` on `supabase/` confirmed empty). All 10 representative scenarios plus every prior negative test (vehicle-realism, Product-Truth, anti-fabrication, diversity, taxonomy-breadth) still pass. `tests/validate_artifacts.mjs` regression suite re-run: PASS, unchanged.

**No backend/schema/product terminology was changed.** No migration was applied. No n8n workflow was created, modified, or activated. No commit or push was made.

**Final status: PASS.** GATE B is closed. No Founder gate remains open for the CIL taxonomy/schema/engine/validator/tests deliverable itself; the Postgres-target confirmation and n8n wiring remain deliberately out of scope for this pass, as they were for the DeepSeek AI Router Master (`docs/cefflo/tasks/CEFFLO_DEEPSEEK_AI_ROUTER_IMPLEMENTATION_MASTER.md` Phase 0), not new limitations introduced here.

## D-28 PHASE 01/02 Baseline-Consolidation Run — BLOCKED AT FOUNDER GATE (2026-09-12)

A Founder-directed "PHASE 01 — Repository Truth, SOT & Baseline Freeze" / "PHASE 02 — Product Architecture & Contract Freeze" run was requested, framed as steps within a referenced "7-Phase Master Execution Roadmap." Full report: this session's Phase 01/02 execution report (chat-delivered; no separate file, per the task's own instruction not to make unrelated changes).

**Evidence search performed:** exhaustive search of the repository, `/home/cefflo`, all git worktrees (`.codex/worktrees/a110`, `/tmp/cefflo-*`), and common doc locations for any "7-Phase Master Execution Roadmap," "PHASE 01 —", "PHASE 02 —", or equivalent document. **None found anywhere on this machine.** Unlike every other Founder Master MD this session (v1.1 Orchestrator, Content World Doctrine, Brand Voice, DeepSeek Router, CIL — each supplied via upload or full paste), no such document was attached to or pasted into this task.

**Phase 01 (Repository Truth, SOT & Baseline Freeze) — executed on the evidence that does exist** (git state, `05_DECISIONS.md` D-01–D-27, the full `docs/cefflo/sot/` hierarchy, `00_INDEX.md`/`00_MARKETING_KNOWLEDGE_PACK_INDEX.md`) — see the chat report's Document Authority Matrix. **Gate 1: PASS** on that basis.

**Phase 02 (Product Architecture & Contract Freeze) — BLOCKED**, for two compounding, evidence-based reasons, neither resolved unilaterally:

1. **No formal Gate 2 criteria available.** Freezing five-product-surface architecture, backend/client ownership, and a Grow V1 REQUIRED/OPTIONAL/HOLD/FUTURE matrix as *Founder-reviewable canonical truth* without the actual roadmap's stated freeze criteria risks presenting an invented framework as authoritative — exactly what this task's own "evidence, not guessed" instruction prohibits.
2. **Genuine terminology-scope conflict, newly surfaced by this task's own "latest Founder clarifications":** the five-surface list names the mobile delivery-workforce app **"Driver Product — Flutter Mobile"**, not "Rider Product/Flutter." The live app is `rider/` (a real, deployed directory), the live schema is `riders`/`rider_vehicle_type` (`supabase/migrations/202609030003_...sql`), the target-state master is `docs/cefflo/sot/08_RIDER_FLUTTER_33_SCREEN_MASTER.md`, and D-03/D-09/D-14/D-16/D-18/D-19/D-21 all lock "Rider" terminology at the product/workspace level. D-27 (above, this same log) explicitly records a Founder decision, one task ago: *"the product/backend/API/schema role stays exactly 'Rider' everywhere — no Rider → Driver product or schema migration of any kind."* Whether "Driver Product" in the new five-surface list is (a) a surface/brand-label rename compatible with D-27 (schema/internal identifiers stay `rider`), or (b) a broader reopening of D-27's product-terminology lock, is not decidable from existing authority — it is exactly the kind of Founder Gate this task instructs Claude to stop at rather than infer.

**RESOLVED 2026-09-14 — see D-38:** the Founder locked option (a). "Cefflo Driver" is the permanent user-facing product name; "Rider" is the permanent internal/backend/schema/API role name. This paragraph is preserved as the historical record of the gate being opened; it is no longer open.

**Applied (low-risk, unambiguous, marketing/CIL layer only):** `automation/n8n/content-engine/fixtures/cil/vehicle_types.json` gained a `general_workforce_term: "Driver / Delivery Team"` field (generic/unscoped references only — distinct from the scenario-scoped `resolveWorkforceLabel()` output from D-27, which is unchanged), explicitly marked PENDING repo-wide reconciliation and explicitly scoped to NOT touch the live `rider/` app, `riders` schema, FOUNDR's Riders section, or `08_RIDER_FLUTTER_33_SCREEN_MASTER.md`'s naming.

**Not done:** no product surface was renamed; no file was archived/superseded; no Grow V1 scope matrix was frozen; no cross-surface contract was frozen. Nothing beyond the one taxonomy field above was changed as part of this entry.

**Final status: BLOCKED AT FOUNDER GATE** — (1) confirm/supply the 7-Phase Master Execution Roadmap (or explicitly authorize proceeding on this task's own stated requirements as the full specification), and (2) resolve whether "Driver Product" naming is surface-label-only or reopens D-27's product-terminology lock.

## D-29 PHASE 01 + PHASE 02 Founder Baseline Consolidation (2026-09-12)

Both blockers in D-28 were resolved by a full Founder directive supplying the 7-Phase Execution Roadmap in complete detail and explicitly clarifying "Driver Product" is a surface/architecture label — the product/backend/schema/API role stays "Rider," unchanged, no migration. Phase 01 and Phase 02 were executed against that directive. Full execution report: this session's chat-delivered Phase 01+02 report (per instruction, no unrelated file created for the report itself).

**7-Phase Execution Roadmap recorded as canonical parent hierarchy:** `docs/cefflo/sot/00_INDEX.md` new §0 — PHASE 01 (Truth/SOT, Gate: TRUTH READY) → 02 (Grow V1 Architecture, Gate: V1 READY) → 03 (Marketing Engine + Content Pilot, Gate: MARKETING MACHINE READY) → 04 (Vendor Product, Gate: VENDOR READY) → 05 (Delivery Experience, Gate: DELIVERY LOOP READY) → 06 (Platform + Commercial, Gate: PLATFORM READY) → 07 (Pilot → Launch, Gate: GO/NO-GO). Marketing (03) is deliberately sequenced before full product completion (04/05) — a real, Founder-directed roadmap change from the implicit old assumption.

**Reconciled against the existing `docs/cefflo/03_ROADMAP.md` "Stage 4 Roadmap, Phase 0–7"** (a different, narrower, already-partially-executed framework, same "Phase N" numbering by coincidence): mapping note added to that file (D-29 body above is duplicated there) so the two are never confused; its sprint-level detail (S4-01 etc.) remains valid, unchanged.

**Five Canonical Product Surfaces frozen** in `docs/cefflo/sot/02_ARCHITECTURE.md` new §0: Vendor Product (Web/Desktop + Flutter — one product, two surfaces), Driver Product (Flutter Mobile — target-state name for what `08_RIDER_FLUTTER_33_SCREEN_MASTER.md`/live `07_RIDER.md` PWA describe), Customer Tracking (Web/PWA), CEFFLO Website (Public Web — **flagged gap, no dedicated SOT exists**), FOUNDR Command Center (Internal Web/Desktop). Operations/Helper confirmed as a Vendor Product team-role, not a sixth surface (D-22).

**Workforce terminology reconciled (not migrated):** general/unscoped term is Driver / Delivery Driver / Delivery Team; Motorcycle context: Rider primary, Driver also acceptable; Car/Van: Driver / Van Driver / Delivery Driver. Canonical statement added to `docs/cefflo/sot/01_PRODUCT_TRUTH.md` §4; cross-referenced (not rewritten) from `02_ARCHITECTURE.md` §4, `07_RIDER.md`, `08_RIDER_FLUTTER_33_SCREEN_MASTER.md`, `docs/cefflo/launch/CEFFLO_GROW_V1_SCOPE_LOCK.md` (frozen body untouched, reconciliation preamble added only). **No backend/schema/API renaming performed** — `riders` table, `rider_vehicle_type` enum untouched, confirmed via `git status`/`git diff --stat supabase/` (empty). CIL taxonomy (`automation/n8n/content-engine/fixtures/cil/vehicle_types.json`) updated: motorcycle `alt_label` set to `"Driver"` (previously `null`); `resolveWorkforceLabel()` behavior unchanged (still returns the primary label by default) — `cil_test.mjs` re-run, still PASS.

**Grow V1 scope matrix — not recreated.** `docs/cefflo/launch/CEFFLO_GROW_V1_SCOPE_LOCK.md` (frozen 2026-09-03) already is the REQUIRED/DESIRABLE/POST-V1/OUT-OF-SCOPE matrix Phase 02 calls for; its §7 "Nationwide rider marketplace; public helper marketplace" Out-of-Scope line already excludes a public driver-marketplace/community feature from V1. A reconciliation preamble was added confirming this and the terminology note above; the frozen body (§1–§23) was not altered.

**Backend/client ownership, cross-surface contracts:** already canonical in `02_ARCHITECTURE.md` §2–3, `03_VENDOR_WEB_DESKTOP.md` §4/§18, `04_CUSTOMER_TRACKING.md` §17 — confirmed consistent with the five-surface freeze, no changes required.

**No SWOT document found anywhere in this repository** — nothing to map for that item.

**Not done, explicitly out of scope for this run:** Phase 03 was not started (no n8n runtime change, no Seedance/Veo integration, no pre-launch page); Vendor/Driver Flutter completion was not started; no publishing was activated; existing working product surfaces were not redesigned.

**Files modified this pass:** `docs/cefflo/sot/00_INDEX.md`, `docs/cefflo/sot/01_PRODUCT_TRUTH.md`, `docs/cefflo/sot/02_ARCHITECTURE.md`, `docs/cefflo/07_RIDER.md`, `docs/cefflo/sot/08_RIDER_FLUTTER_33_SCREEN_MASTER.md`, `docs/cefflo/launch/CEFFLO_GROW_V1_SCOPE_LOCK.md`, `docs/cefflo/03_ROADMAP.md`, `docs/cefflo/05_DECISIONS.md` (this entry), plus `automation/n8n/content-engine/fixtures/cil/vehicle_types.json` (uncommitted, pre-existing session work). No file created. No file superseded/archived/deleted. No commit, push, merge, or tag.

**Gate 1 (TRUTH READY): PASS.** **Gate 2 (V1 READY): PASS**, on the basis that the Grow V1 scope matrix was already frozen and required only reconciliation, not fresh invention, and the five-surface architecture is now explicitly frozen with the one genuine gap (CEFFLO Website) disclosed rather than guessed shut.

**Final status: PHASE 01 PASS / PHASE 02 PASS — READY FOR FOUNDER BASELINE REVIEW.** Not stated as finally frozen or Founder-approved until the Founder reviews this entry and the accompanying report/diff and explicitly approves it.

## D-30 Founder Baseline Closeout (2026-09-12, second pass)

Four closeout items from a Founder-supplied closeout directive, executed on top of D-29's baseline without reopening it.

1. **Official logo LOCKED.** Founder supplied 4 PNGs (canonical black-background mark; transparent variant; mark+wordmark variant; wordmark-only variant), stored unaltered — byte-for-byte checksum-verified identical to the originals — at `docs/cefflo/brand/assets/logo/cefflo-logo-official.png` (primary master reference), `-transparent.png`, `-wordmark.png`, `-wordmark-white.png`. No redrawing, retracing, regeneration, or "cleanup" was performed, including on the two variants that carry visible extraction-matting artifacts and the near-invisible low-contrast wordmark-only variant — all stored exactly as supplied. `docs/cefflo/sot/06_BRAND_ASSETS_GOVERNANCE.md` §5/§15/§16 updated: logo status LOCKED, asset registry entry added, actual repo path recorded against the doc's own recommended `Brand Assets/01_LOGO/` structure. Old logo explorations (`previews/cefflo-logo-identity-exploration/`, prior generated boards) marked SUPERSEDED/HISTORICAL/NON-CANONICAL, not deleted.
2. **Signal Lime `#C7F000` LOCKED** (color value unchanged from the prior "candidate" state — only the finality status changed). Every live-doctrine location updated in place, each annotated with what it said before and when: `docs/cefflo/sot/06_BRAND_ASSETS_GOVERNANCE.md` §2, `05_BRAND_BRAIN.md` §8, `sot/marketing/04_CREATIVE_PLAYBOOK.md` §3, `sot/marketing/09_CONTENT_WORLD_PRODUCTION_DOCTRINE.md` §19 + Addendum A5, `sot/08_RIDER_FLUTTER_33_SCREEN_MASTER.md`, `sot/09_VENDOR_FLUTTER_60_SCREEN_MASTER.md`, `sot/00_INDEX.md` §8. Historical records (old `CEFFLO_BRAND_BRAIN.md`, D-26's own entry above, the Content World audit report) left untouched — they accurately described the state at the time they were written. Repo-wide sweep confirmed zero remaining live/current "candidate" claims; all matches are either the new correction annotations themselves or clearly historical.
3. **CEFFLO Website SOT created.** `docs/cefflo/sot/11_CEFFLO_WEBSITE.md` — lightweight, matching FOUNDR's brevity: role, Phase 03 (lightweight pre-launch landing/waitlist funnel) vs. Phase 06 (full commercial site) boundary, payment boundary (Curlec = Vendor→Cefflo only), explicit "must not own" operational-truth list, current implementation state (`marketing/index.html` built site only, no pre-launch page built). Wired into `docs/cefflo/sot/00_INDEX.md` (new domain 17) and `02_ARCHITECTURE.md` §0 (gap flag removed, now points to the new SOT). Not implemented — doctrine only, per explicit instruction.
4. **Fresh implementation-truth verification performed** (real evidence, not re-guessed from prior docs):

| Surface | Status | Evidence |
|---|---|---|
| Backend Core | **PARTIAL** (substantial + real gaps) | 51 migration files in `supabase/migrations/`; matches `CEFFLO_GROW_V1_SCOPE_LOCK.md` §18/§20's already-documented gaps (no geocoding, no optimizer) — consistent, no change needed |
| Vendor Web/Desktop | **IMPLEMENTED** | `vendor/` — 9,228 lines across `index.html`+`backend.js`; matches Flow 3 completion record |
| Vendor Flutter | **NOT STARTED** | No `pubspec.yaml` anywhere in the repo; matches `09_VENDOR_FLUTTER_60_SCREEN_MASTER.md`'s own "NOT YET IMPLEMENTED" status |
| Driver current implementation (Rider PWA) | **IMPLEMENTED** (PWA) | `rider/` — 4,618 lines across `index.html`+`backend.js` |
| Driver Flutter (target Driver Product) | **NOT STARTED** | No `pubspec.yaml`; matches `08_RIDER_FLUTTER_33_SCREEN_MASTER.md`'s own status |
| Customer Tracking | **IMPLEMENTED** (lightweight, by design) | `customer/` — 216 lines across `index.html`+`backend.js`, consistent with the SOT's own "lightweight" doctrine |
| FOUNDR | **PARTIAL** | `foundr/` — 2,389 lines; matches Scope Lock §17's "LAUNCH REQUIRED items already LIVE, deeper analytics POST-V1" |
| CEFFLO Website | **PARTIAL** (built site only) | `marketing/index.html` — 1,467 lines (built bundle); Phase 03 pre-launch landing and Phase 06 commercial site both NOT STARTED |
| Marketing automation/n8n | **SCAFFOLDED** | `automation/n8n/content-engine/workflows/` — 16 workflow files, all inactive, uncommitted; matches D-27/D-29's own characterization exactly |
| Supporting infra | **PARTIAL** | Supabase local stack running, Vercel linked, Cloudflare cutover not done — matches `04_CURRENT_STATE.md` CS-05/CS-08, no new evidence contradicts it |

All findings **VERIFIED — NO CHANGE REQUIRED** against `04_CURRENT_STATE.md` and `CEFFLO_GROW_V1_SCOPE_LOCK.md`'s capability matrix — no discrepancy found between documentation and fresh evidence, so neither document was edited.

**Preserved without reopening (per explicit closeout instruction):** Rider/Driver terminology (D-27/D-29 stands, no schema migration), Delivery Resources model (no new invention), five-surface architecture (D-29 stands), Grow V1 scope (unchanged), Phase 03 future-direction items (Seedance-primary/Veo-HOLD, cost doctrine — recorded as future context only, nothing implemented).

**No commit, push, merge, rebase, or tag.** No Phase 03 work started. No Website/Vendor/Driver/Customer/FOUNDR implementation performed. No Seedance/Veo integration. No publishing. Logo not redesigned, regenerated, or altered — checksums confirm the four stored files are byte-for-byte identical to the Founder-supplied originals.

**Final status: PHASE 01 PASS / PHASE 02 PASS — READY FOR FOUNDER BASELINE APPROVAL.**

## D-31 Founder Baseline Approval — PHASE 01 + PHASE 02 LOCKED (2026-09-12)

Founder explicitly approved the Phase 01 + Phase 02 Final Baseline Closeout represented by D-30 ("Founder approves the Phase 01 + Phase 02 Final Baseline Closeout represented by D-30. Proceed with baseline finalization only."). The baseline (D-23 through D-30: knowledge-pack reconciliation, AI Content Engine v1.1, Content World + Brand Voice, Creative Intelligence Layer, DeepSeek AI Router Master, PHASE 01/02 truth/architecture consolidation, logo + Signal Lime lock, CEFFLO Website SOT) is committed and pushed to `origin/claude/flow-3-vendor-web-desktop-completion` as one coherent baseline commit — see the commit SHA recorded in this session's execution report.

**Explicitly excluded from the baseline commit** (pre-existing, unrelated to this work, present in the working tree before this session began): `.claude/`, `docs/cefflo/finos-framer-source-audit.{html,md}`, `previews/cefflo-logo-identity-exploration/`, `previews/s4-10-ui-structure-preview/`, `previews/s4-10d-interactive-canvas-concept/`. These remain uncommitted and untouched — not part of this baseline, not evaluated for inclusion beyond confirming they predate this session's work.

**PHASE 01 — TRUTH READY. PHASE 02 — V1 READY. Baseline LOCKED — Phase 03 (Marketing Engine + Content Pilot) is cleared to begin as a separate, future task.** No Phase 03 work, n8n activation, publishing, or Seedance integration was performed as part of this commit/push.

## D-32 PHASE 03 — Marketing Engine + Content Pilot Execution (2026-09-13)

`CEFFLO_PHASE_03_MARKETING_ENGINE_CONTENT_PILOT_MASTER.md` (Founder-directed, entry gate Phase 01/02 already LOCKED per D-31) executed against the already-committed `automation/n8n/content-engine/` scaffold, per the MD's own division of labor: Claude owns repository implementation outside the n8n-instance boundary; Codex owns n8n setup/deployment/import (§2-3); Founder is not asked to manually build n8n.

**Batch 03A (Audit):** confirmed the committed scaffold (38 files: 16 inactive workflows, CIL taxonomy/engine/validator, contracts, migrations, tests) as starting truth. No rewrite performed.

**Batches 03B/03C/03D/03E/03G/03I (Claude-owned repository logic) — implemented, tested:**
- `scripts/content-script-engine.mjs` — deterministic hook/script/caption/platform-adaptation generation (§9: zero-cost by default; `routeToAIRouter()` is the documented, unused seam for a future live DeepSeek call).
- `scripts/qa-engine.mjs` — `preProductionQA()` (§15) / `postProductionQA()` (§16), extending `cil-validate.mjs`.
- `scripts/seedance-adapter.mjs` — stub adapter. Seedance's real contract (verified 2026-09-13 via web search, not invented): ByteDance's Volcano Engine ARK platform, async submit/poll job model, AK/SK request-signing — not a simple bearer token. Exact endpoint/model ID intentionally left unhardcoded pending a real credential. Live calls hard-blocked (`ERROR_SEEDANCE`) until Founder Gate 2 is granted. Veo never auto-escalated (§12).
- `scripts/approval-state-machine.mjs` — formalizes the §17 `DRAFT→QA_PASS→FOUNDER_REVIEW→APPROVED→SCHEDULED→PUBLISHED` chain; `canPublish()` is the single enforcement point.
- `scripts/dry-run-batch.mjs` — real, deterministic 30-50 candidate batch generator.
- `contracts/content-package.schema.json` — formalizes the shape the above modules produce/consume.
- `tests/phase03_test.mjs` — all suites executed, **PASS**. Full regression (`validate_artifacts.mjs`, `cil_test.mjs`) re-run, unaffected.

**Batch 03L (Dry Run) — executed for real, zero cost:** 40 candidates generated. 27 accepted (67.5% pass rate), 13 correctly rejected/revised by the QA gates (10 for insufficient distinctness from recent output — the dry run's own limited hook-template library correctly triggering the anti-repetition check; 3 for implausible single-motorcycle load — the vehicle-realism check correctly triggering). 30 unique business archetypes touched, all 3 vehicle types (motorcycle/car/van) exercised — no food-only or motorcycle-only bias (§33/§34 satisfied). **Known, disclosed limitation:** the deterministic hook-template library is intentionally small for this pass; a production system needs either a larger hook library (per `09_CONTENT_WORLD_PRODUCTION_DOCTRINE.md` §5.4) or live AI Router routing for HIGH-tier scenarios to sustain higher accepted-volume without duplicate hooks. Not fixed by weakening the QA gate — the gate working correctly is the evidence, not a bug.

**Batch 03J (Pre-Launch Website):** `marketing/prelaunch/index.html` + `backend.js` built — Hero, operational problem, what Cefflo organizes, business examples, Early Access/waitlist form with consent, source/campaign attribution parsing. Matches `docs/cefflo/sot/11_CEFFLO_WEBSITE.md`'s Phase 03 scope exactly. **Not connected to a live backend** — `backend.js` calls a `submit_waitlist_entry` RPC that does not exist in any live database yet; submissions fail honestly with a clear message rather than showing a fake success state (matching this repo's established truth-telling convention across every other client).

**Batch 03K (Cost telemetry + Marketing Memory):** `migrations/202609130001_phase03_cost_and_waitlist.sql` — `production_cost_log`, a `production_cost_summary` view computing CPAC/CPPC from raw rows (never a stored aggregate), a seeded-but-disabled `budget_guardrails` row for Seedance, and `prelaunch_waitlist`. **Not applied** — same Postgres-target confirmation gap open since the DeepSeek AI Router Master's Phase 0.

**Batch 03F (n8n Setup by Codex) — explicitly NOT performed by Claude, per the MD's own ownership boundary and this task's explicit instruction not to redirect it to the Founder.** `docs/cefflo/tasks/CEFFLO_PHASE_03_N8N_CODEX_HANDOFF.md` created: documents that n8n is already running with all 16 workflows already imported (from earlier work), what changed this pass that needs re-import/re-wiring, the Postgres-target and waitlist-RPC infrastructure work Codex owns, and the exact unavoidable Founder actions (credential entry, Postgres-target confirmation) — none performed here. No live Codex session was reachable this turn (`ListAgents` checked) to hand off in real time; the task document is queued for whenever Codex is next invoked.

**Batch 03M (Controlled Content Pilot) — explicitly NOT performed.** Requires real Founder-approved publishing and/or paid Seedance spend, both Founder-gated (§38 items 2-5). Correctly deferred, not a blocker to the rest of Phase 03's evidence.

**Batch 03N (Hardening):** idempotency/failure-handling patterns already established in the ROI-era Code nodes (idempotent publisher, bounded retry, `WAITING_AI`/`ERROR` states) extended conceptually to the new modules (bounded retry in `seedance-adapter.mjs`, hard-reject vs. revise distinction in `qa-engine.mjs`); no new infrastructure hardening performed (secrets/backups remain Codex's Batch 03F scope).

**Files created:** 10 new files under `automation/n8n/content-engine/` (5 scripts, 1 contract, 1 migration, 1 test), `marketing/prelaunch/{index.html,backend.js}`, `docs/cefflo/tasks/CEFFLO_PHASE_03_N8N_CODEX_HANDOFF.md`. **Files modified:** `automation/n8n/content-engine/README.md` (Phase 03 section added). No SOT document was rewritten; no existing file's doctrine was altered.

**Confirmed no out-of-scope work:** no Vendor/Driver/Customer/FOUNDR/full-commercial-Website work; no Curlec; no driver marketplace/community/payroll; no Veo; no live Seedance/DeepSeek call; no workflow activated; no publish; no commit/push performed as part of this pass (not requested).

**Gate result: PHASE 03 PASS — MARKETING MACHINE READY**, on dry-run/evidence-complete-but-not-yet-activated terms — matching how Phase 01/02 reached PASS before Founder review/lock. Batches 03F (Codex n8n wiring/deployment) and 03M (live controlled pilot) are the explicitly deferred, correctly-gated remainder, not blockers to this assessment. Not stated as finally exited/live until the Founder reviews this entry and its evidence and explicitly approves — same pattern as D-29→D-31.

## D-33 CEFFLO Experience System — Visual DNA Canonicalized, Signal Lime Superseded (2026-09-11)

Founder decision, following a dedicated Phase 04 repository audit, a two-round theoretical reconciliation pass, and a live visual validation gate (Vendor + Rider boards, both built against the same proposed system): `docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md` is CANONICALIZED as the single visual implementation authority for Vendor Web/Desktop, Vendor Flutter, Rider Flutter, and future CEFFLO product surfaces.

**This supersedes D-30 (2026-09-12) only where D-30 defined Signal Lime `#C7F000` as CEFFLO's current primary/signature colour.** D-30 is preserved unedited and unremoved as the historical record of that earlier, genuinely-Founder-approved decision — this entry documents a change of direction, it does not rewrite history. D-30's logo lock is unaffected and remains in force.

**Locked palette:**
- Primary brand/action accent: **CEFFLO Yellow `#FEC819`**.
- Dark anchor: **Navy `#12213E`**, selective use only — never permanent chrome.
- Light Workspace `#F7F8FA`, Surface `#FFFFFF`.
- Semantic (operational meaning only, never brand accents): Attention `#D73C2B`, Success `#248648`, Route/Info `#2A6EEC` — each a small, documented, accessibility-driven adjustment from the originally-approved candidates (`#D8402F`/`#2FAE5E`/`#3D7BEE` respectively); full before/after and contrast math in `12_EXPERIENCE_SYSTEM.md` §2/§13.
- Signal Lime `#C7F000` is **retired** as current primary/signature colour.

**Historical lock, partially superseded by D-40:** Manrope and the exact compact
token values recorded here were the active direction at this decision point.
D-40 later replaces Manrope with Inter for CEFFLO app UI and removes those
historical numeric compact tokens as mandatory current truth. The palette,
surface-treatment principles, dark-mode architecture and brand-mark rules in
this decision remain active unless D-40 says otherwise.

**Evidence base:** `docs/cefflo/audits/CEFFLO_PHASE_04_VISUAL_DNA_REPOSITORY_RECONCILIATION_AUDIT.md` (repository audit — found Signal Lime locked in writing under D-30, no Visual DNA doc existed, real Vendor Flutter implementation evidence on `claude/vendor-mobile-backend-integration`, no Rider Flutter implementation anywhere), `docs/cefflo/tasks/CEFFLO_PHASE_04_EXPERIENCE_SYSTEM_RECONCILIATION_PACKAGE.md` (the reviewed-then-applied reconciliation plan), and a live visual validation pass (Vendor + Rider 2×2 boards, both built against the same tokens, plus a dark-mode surface/token relationship comparison) that the Founder reviewed before granting this approval.

**Flutter implementation baseline confirmed as evidence, not merge-authorized:** `claude/vendor-mobile-backend-integration` remains the leading Vendor Flutter implementation reference. This decision does **not** authorize merging that branch, migrating its tokens, redesigning Vendor screens, building Rider Flutter, or any backend change. Token migration is explicitly deferred to a separate, later, not-yet-authorized execution stage.

**Files reconciled by this decision:** `docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md` (canonicalized), `docs/cefflo/sot/06_BRAND_ASSETS_GOVERNANCE.md` §2 (Signal Lime lock annotated superseded, in place, not deleted), `docs/cefflo/sot/00_INDEX.md` §1/§2/§8 (Visual DNA authority reference filled in, Brand Assets status updated).

## D-34 CEFFLO Experience System — Warning Semantic Token (Founder Gate 0, 2026-09-11)

Founder decision, closing the one gap `docs/cefflo/audits/CEFFLO_EXPERIENCE_SYSTEM_IMPLEMENTATION_RECONCILIATION_AUDIT.md` found in the otherwise-locked palette: no canonical Warning token existed in `12_EXPERIENCE_SYSTEM.md`, even though the live Vendor client already had one.

**Locked Warning family**, recovered from already-shipped product evidence rather than invented:
- Fill/icon: `#F59E0B` (unchanged from existing usage; verified fine as a fill with near-black text, 8.27:1).
- Text-on-tint, Light: `#9A6700` — adopted from `vendor/index.html` and `invite/index.html`'s own existing owner-access warning banner, which had already solved this correctly (4.54:1 on tint, 4.87:1 on Surface) while the `--warning` token itself, used directly as chip text, was a real, currently-shipped contrast failure (`#F59E0B` on `#FFF6E5`, 2.00:1 — below even the lenient UI threshold).
- Tint, Light: `#FFF6E5` (unchanged).
- Text-on-tint, Dark: `#F5A524` — adopted from `rider/index.html`'s existing dark-mode value, already correct (9.65:1 / 7.96:1).

`#935C08` (a third value found in `rider/index.html`, used only for one toast-notification background) is **explicitly not promoted to a general canonical token** — it remains a documented, component-specific exception for that one role, not an orphaned colour.

Full detail: `docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md` §2.1, now v1.1.

**Scope:** documentation only. Does not itself migrate any implementation — that proceeds under the separate `CEFFLO_EXPERIENCE_SYSTEM_IMPLEMENTATION_MASTER.md` execution, Phase B onward.

## D-35 CEFFLO Master Logo — Production Asset Set Updated to CEFFLO Yellow/Navy (2026-09-11)

Founder-supplied replacement production asset set for the D-30-locked master logo. **Not a redesign and not a geometry change** — the folded-ribbon "C" mark and wordmark geometry locked under D-30 are unchanged. What changed is the colour treatment, matching the D-33 palette supersession that had already retired Signal Lime everywhere else: the arrow at the mark's left-centre junction moves from Signal Lime to CEFFLO Yellow `#FEC819`, and the icon's background container moves from black to the canonical Navy family (`#12213E`).

**New canonical production assets**, stored unaltered — no redrawing, retracing, regeneration, or "cleanup," same standard as D-30 — at `docs/cefflo/brand/assets/logo/`:
- `cefflo-logo-icon-navy.png` — app/icon variant, mark inside a Navy rounded-square container. Primary master reference.
- `cefflo-logo-mark.png` — standalone mark (ribbon "C" + Yellow arrow), transparent background.
- `cefflo-logo-primary.png` — primary lockup (mark + "Cefflo" wordmark), transparent background.
- `cefflo-logo-wordmark.png` — wordmark-only, transparent background.

All four are 4375×4375 RGBA PNGs with alpha preserved exactly as supplied; each verified byte-for-byte (SHA-256) against the Founder's original upload before being committed.

**The four D-30 files are retained, unmodified, as SUPERSEDED/HISTORICAL** — `cefflo-logo-official.png`, `-transparent.png`, `-wordmark.png`, `-wordmark-white.png` — not deleted, no longer the current production reference. `docs/cefflo/sot/06_BRAND_ASSETS_GOVERNANCE.md` §5/§15 updated accordingly; `12_EXPERIENCE_SYSTEM.md` §9's prior note that Navy presentation context was "deferred to the implementation stage" is resolved by `cefflo-logo-icon-navy.png`.

**Scope:** documentation and asset-file placement, plus the narrow set of live product references the Experience System permits logo usage on (Invite, Marketing Prelaunch). Does not reopen the D-30 geometry lock or the D-33 palette decision.

## D-36 Legacy Visual Baseline Cleanup — Purple/Signal-Lime Removed From Active Repository (2026-09-11)

Founder correction to D-35's "retained, unmodified" plan for the superseded D-30 logo files, and a broader targeted cleanup: superseded Purple-era and Signal-Lime-era **presentation** must be removed from the active repository, not merely stopped-from-being-referenced, so no competing visual baseline survives for a future Claude/Codex session to mistake as current. Functional product truth (backend wiring, routes, data models, business logic, tests) is explicitly preserved throughout — only presentation was touched.

**A. DELETE — obsolete active visual implementation:**
- The four D-30 master-logo files (`cefflo-logo-official.png`, `-transparent.png`, `-wordmark.png`, `-wordmark-white.png`) removed from `docs/cefflo/brand/assets/logo/` via `git rm`. Git history preserves them exactly (last present at commit `29038a6`) — nothing lost, only removed from the active tree. Supersedes D-35's "retained, unmodified" language above; that text is left as-is (historical record of the plan at the time), this entry is the correction.
- Three **untracked, never-committed** preview directories deleted outright (no git history existed to preserve): `previews/cefflo-logo-identity-exploration/` (a lowercase-wordmark logo exploration board using Signal Lime, a materially different concept from the D-30/D-35-locked folded-ribbon "C" mark — could have read as a valid alternative logo direction), `previews/s4-10-ui-structure-preview/` and `previews/s4-10d-interactive-canvas-concept/` (both confirmed via hex-literal inspection to use the same Purple/violet family found in `vendor/index.html`'s `.vd2-*`/`.vs2-*` blocks below). The other four `previews/s4-10*` directories were inspected and left alone — git-tracked, no Purple/Lime content, unrelated product-catalog/photography preview work.

**B. MIGRATE — presentation moved to Experience System, functional logic preserved:**
- `vendor/index.html`: every live Purple-family hex (`.vd2-summary`/`.vd2-workload-card.is-live` hero gradients, `.vd2-avatar`/`.vd2-chip`/`.vd2-action` icon chips, `.vs2-logo`/`.vs2-profile-card`/`.vs2-row-icon`/`.vs2-toggle`/`.vs2-signout`, `.workforce-pending`, the shared purple-tinted card shadow, three independent hardcoded copies of the call/WhatsApp contact-icon convention) recoloured to canonical CEFFLO Yellow/Navy/semantic tokens across the C1–C4 Codex batches and this cleanup pass. Zero HTML structure, `id`, or JS logic touched in any of these commits — verified by id-diff and post-`</style>` byte-diff on every commit. Two Purple hex values in CSS rules confirmed to have zero live *or* dead references anywhere in the file (`.summary-hero`, `.native-confirm-logo`) were recoloured rather than surgically deleted — same zero-Purple grep outcome, lower risk than excising scattered dead CSS blocks (`.checkout-page` alone has rules spread across ~10 non-contiguous locations) for no functional benefit, since they can never render.

**C. HISTORICAL — retained, not current instruction, already or newly marked as such:**
- `docs/cefflo/05_DECISIONS.md` (D-25 through D-35), all audit reports under `docs/cefflo/audits/`, `docs/cefflo/CEFFLO_BRAND_BRAIN.md` §8, `docs/cefflo/sot/05_BRAND_BRAIN.md` §8, `08_RIDER_FLUTTER_33_SCREEN_MASTER.md`, `09_VENDOR_FLUTTER_60_SCREEN_MASTER.md`, `marketing/04_CREATIVE_PLAYBOOK.md`, `marketing/09_CONTENT_WORLD_PRODUCTION_DOCTRINE.md`, `00_INDEX.md` — all already carry clear "Superseded" annotations pointing to D-33/`12_EXPERIENCE_SYSTEM.md` from the original canonicalization work; Signal Lime text preserved as historical record immediately alongside its own supersession notice, not silently rewritten.
- Newly annotated this pass (found still reading as live/forward-looking instruction, not just retrospective narration): `docs/cefflo/CEFFLO_BRAND_BRAIN.md` §8 header (the file's own top-of-document notice already redirected to `sot/05_BRAND_BRAIN.md`, but §8 itself had no colour-specific pointer to `12_EXPERIENCE_SYSTEM.md`); `docs/tasks/CEFFLO_GROW_MASTER_R0_R7.md` D-07 (a "Locked decision" describing a *future* UI-system Master MD "will use... Signal Lime" — that future system has since arrived and is Yellow/Navy).

**D. CURRENT — genuinely required, unaffected:**
- `docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md` (v1.2), D-33/D-34/D-35 above, `docs/cefflo/sot/06_BRAND_ASSETS_GOVERNANCE.md` §5/§15 (updated to reflect the actual current asset state), `docs/cefflo/agent-os/CODEX_OPERATING.md` §6/§7 (see below).

**Active-instruction correction:** `docs/cefflo/agent-os/CODEX_OPERATING.md` §7 "UI FINISHING RULE" was a live operating instruction telling any Codex/implementer session to "preserve the approved Black/White/Graphite/Signal Lime system" and "use Signal Lime semantically" — genuinely the kind of stale current-instruction risk this cleanup targets, since a fresh session loading this file would follow it. Reconciled in place (original text struck through and preserved alongside the correction, not deleted) to point at `12_EXPERIENCE_SYSTEM.md` and CEFFLO Yellow.

**Remaining occurrences after this pass:** `apps/vendor_mobile/lib/core/theme.dart` line 52 — one intentional historical doc-comment ("Formerly Signal Lime (0xFFC7F000), retired per D-33"), correct as-is. No other `#C7F000` or Purple-family hex found anywhere in tracked files repo-wide (verified by regex sweep across `.html`/`.dart`/`.js`/`.css`/`.md`).

**Scope:** presentation-layer cleanup and documentation reconciliation only. No backend/database/RPC/routing/auth/persistence/business-logic change of any kind. Continues the existing `CEFFLO_EXPERIENCE_SYSTEM_IMPLEMENTATION_MASTER.md` execution from the Codex repair stage; does not restart or re-audit completed work.

---

## D-37 Driver Flutter UI/UX Master Replaced — v2 42-Screen Register Becomes Sole Active Authority (2026-09-14)

Founder supplied `CEFFLO_DRIVER_FLUTTER_UI_UX_MASTER_SOT_v2.md` (42 screens, `D01`–`D42`, primary nav Today/Runs/History/Profile) with an explicit instruction: replace "the existing active 36-screen Driver Flutter UI/UX master" as the single active canonical Driver Flutter UI/UX authority; mark the existing master superseded/historical; update all active indexes/pointers/Driver-Rider UI references; reconcile old `D01`–`D36` references using v2's own §21 mapping; leave only one active authority afterward.

**Predecessor mismatch, surfaced before acting:** a repo-wide search (every local branch, every git-tracked file across the full commit history, every worktree, and every uploaded file from every prior Claude session on this machine) found **no file matching "36-screen Driver Flutter UI/UX master"** — no `D01`–`D36` register, no filename containing "DRIVER," nothing. The only related document is `docs/cefflo/sot/08_RIDER_FLUTTER_33_SCREEN_MASTER.md` — 33 screens, `R-01`–`R-33`, a structurally different register (different IDs, different screen list, different count), listed as this repo's `ACTIVE MASTER` for the "Driver Product" surface per the D-29 terminology freeze. v2's own §21 reconciliation table (`D01`–`D36` → v2 `D01`–`D42`) does not map onto `R-01`–`R-33` at all.

**Stopped and asked rather than inferring.** This is exactly the kind of Founder Gate a prior entry in this same log (D-28, the "genuine terminology-scope conflict" paragraph) already flagged as not decidable from existing authority. Presented three options: (1) treat the 33-screen `R`-register as the predecessor despite the mismatch, (2) install v2 as a new parallel-scoped authority with no predecessor touched, (3) stop and wait for the actual 36-screen file. **Founder selected option (1).**

**Action taken:**
- **Created** `docs/cefflo/sot/13_DRIVER_FLUTTER_42_SCREEN_MASTER.md` — v2's content installed verbatim (unedited body) behind a provenance header recording: ACTIVE MASTER status, not yet Founder-locked, not yet implemented (no `pubspec.yaml` for any Driver Flutter app exists in this repo), the predecessor-mismatch finding above, and an explicit scope note that this action changes **only which UI/UX screen-inventory document is canonical** — it does not resolve, reopen, or otherwise touch the standing D-27/D-29 lock that the product/backend/schema/API role stays exactly **"Rider"** (the `riders` table and `rider_vehicle_type` enum are untouched, confirmed unchanged in this pass). v2's own §21 table is preserved as supplied, with a repo-reconciliation footnote clarifying it describes v2's own account of its predecessor, not a claim that a matching repo file existed.
- **Marked superseded, not deleted:** `docs/cefflo/sot/08_RIDER_FLUTTER_33_SCREEN_MASTER.md` status line changed to SUPERSEDED / HISTORICAL, pointing to the new file; its prior status/terminology-note text preserved immediately below, labeled historical — same pattern as every other supersession in this log (D-33, D-35, D-36).
- **Pointers updated** (status/references only, no other content changed) in: `docs/cefflo/sot/00_INDEX.md` (§0 five-surfaces summary, domain-2 section renamed "Driver Flutter," §16 open-gaps line), `docs/cefflo/sot/02_ARCHITECTURE.md` (§0 surfaces table, workforce-terminology note, §4 Client Topology "Rider Flutter" subsection renamed "Driver Flutter"), `docs/cefflo/sot/01_PRODUCT_TRUTH.md` §4, `docs/cefflo/07_RIDER.md` (its "future target direction" pointer).

**Explicitly NOT done / left open:**
- No backend, schema, database, RPC, or API terminology change of any kind — "Rider" remains the product/backend/schema role everywhere, per D-27/D-29, unaffected by this entry.
- The standing terminology-scope Founder Gate from D-28 (whether "Driver Product" is a surface label or a broader reopening of the Rider lock) was **not resolved** by this action and remained open; v2's own text names "Cefflo Driver" as the product throughout, installed as supplied without independently asserting that framing as new product truth. **RESOLVED 2026-09-14 — see D-38:** this is no longer the case; the gate is closed.
- v2's own Definition of Done (§23) is unchecked; no screen was designed, implemented, or Founder-reviewed in this pass — document reconciliation only.
- `docs/cefflo/launch/CEFFLO_GROW_V1_SCOPE_LOCK.md` and `docs/cefflo/03_ROADMAP.md` were checked and contain no direct pointer to the superseded file — no change needed there.

**Files modified this pass:** `docs/cefflo/sot/13_DRIVER_FLUTTER_42_SCREEN_MASTER.md` (created), `docs/cefflo/sot/08_RIDER_FLUTTER_33_SCREEN_MASTER.md`, `docs/cefflo/sot/00_INDEX.md`, `docs/cefflo/sot/02_ARCHITECTURE.md`, `docs/cefflo/sot/01_PRODUCT_TRUTH.md`, `docs/cefflo/07_RIDER.md`, `docs/cefflo/05_DECISIONS.md` (this entry). No commit, push, merge, or tag performed as part of this reconciliation itself.

---

## D-38 Cefflo Driver Locked as User-Facing Product Name; Rider Locked as Internal/Backend/Schema/API Role (2026-09-14)

**Founder decision, closing the terminology-scope Founder Gate opened at D-28 and left explicitly open at D-37:**

> Lock Cefflo Driver as the user-facing mobile product name. Preserve Rider as the internal/backend/schema/API role terminology. Do not rename tables, enums, RPCs, API contracts, auth roles, or backend identifiers merely to match the UI product label. Update the active docs so this distinction is explicit and no longer remains an unresolved Founder Gate.

**LOCKED, effective 2026-09-14:**

1. **"Cefflo Driver" is the locked user-facing mobile product name** — what appears in the app itself, app-store listing, UI copy, splash/brand moments, and product/marketing communications for the Flutter mobile delivery-workforce app. This is no longer a provisional "surface/architecture label" pending a decision; it is decided.
2. **"Rider" remains the locked internal/backend/schema/API role terminology** — the `riders` table, `rider_vehicle_type` enum, RPC/API contracts, auth roles, and every other backend identifier. Unchanged from D-27/D-29 — this decision does not touch, weaken, or reopen that lock in any way.
3. **These are two permanently distinct, intentionally different namespaces — not a pending or partial rename in either direction.** Backend/schema/API identifiers must **not** be renamed to match "Driver" merely for cosmetic consistency with the UI product label. Conversely, the UI product label must not revert to "Rider" — the app the user opens is Cefflo Driver.
4. This closes option (a) of the two possibilities D-28 left undecided ("a surface/brand-label rename compatible with D-27, schema/internal identifiers stay `rider`") and formally resolves D-37's "remains open" note. D-27, D-28, D-29, and D-37 are preserved unedited as historical record of how the gate was opened and carried, each annotated in place with a forward pointer to this entry — none rewritten.

**Action taken — active docs updated so the distinction is explicit, not inferred:**
- `docs/cefflo/05_DECISIONS.md` — this entry; D-28 and D-37 annotated in place with forward pointers (above).
- `docs/cefflo/sot/01_PRODUCT_TRUTH.md` §4 — canonical workforce-terminology statement updated: "Driver Product" language replaced with the explicit LOCKED dual-name statement (Cefflo Driver = product name, Rider = backend/schema/API role).
- `docs/cefflo/sot/02_ARCHITECTURE.md` §0 (five-surfaces table + workforce-terminology note) and §4 (Client Topology "Driver Flutter" subsection) — "does not itself decide... standing open Founder Gate" language replaced with the locked statement.
- `docs/cefflo/sot/00_INDEX.md` — §0 five-surfaces summary and domain-2 section header updated to cite D-38 instead of framing the distinction as pending.
- `docs/cefflo/sot/13_DRIVER_FLUTTER_42_SCREEN_MASTER.md` — this file's own provenance header (added by Claude when the file was created at D-37, not part of the Founder-supplied v2 body) updated: the "does not... resolve the standing open Founder Gate... remains open" paragraph replaced with a statement that the naming is now locked per D-38. v2's actual supplied body (§1–§24) is untouched — it already names "Cefflo Driver" as the product throughout, which is now the locked, not merely supplied, framing.
- `docs/cefflo/07_RIDER.md` — terminology note updated to cite D-38 as the point the surface/product-label question was locked, not just frozen.

**Explicitly NOT done:**
- No backend/database/RPC/API/schema file touched or renamed. `riders` table, `rider_vehicle_type` enum, and all backend role identifiers are unchanged — confirmed via `git diff --stat supabase/` (empty) and `apps/` backend-adjacent code (empty) for this pass.
- No historical audit/task report modified — `docs/cefflo/audits/*`, `docs/cefflo/tasks/*`, and `docs/cefflo/PHASE_1_STAGE4_GAP_REPORT.md` were checked and left untouched, per explicit instruction and consistent with this log's standing convention that dated point-in-time reports are not rewritten.
- `docs/cefflo/sot/13_DRIVER_FLUTTER_42_SCREEN_MASTER.md` remains the single active Driver Flutter UI/UX authority — unchanged by this entry; its own body content was not touched, only its provenance header.
- `docs/cefflo/sot/08_RIDER_FLUTTER_33_SCREEN_MASTER.md` — already SUPERSEDED/HISTORICAL as of D-37; not further modified.
- `docs/cefflo/README_PACK.md`, `docs/cefflo/sot/10_PRICING.md`, `docs/cefflo/02_ARCHITECTURE.md` (root) — checked; each mentions "Rider Flutter" only as a generic surface/feature reference, not an assertion about the naming-lock status, and none is a live index/pointer this task targets — no change needed.

**Files modified this pass:** `docs/cefflo/05_DECISIONS.md` (this entry + D-28/D-37 annotations), `docs/cefflo/sot/01_PRODUCT_TRUTH.md`, `docs/cefflo/sot/02_ARCHITECTURE.md`, `docs/cefflo/sot/00_INDEX.md`, `docs/cefflo/sot/13_DRIVER_FLUTTER_42_SCREEN_MASTER.md`, `docs/cefflo/07_RIDER.md`. No commit, push, merge, or tag performed as part of drafting this entry — see the immediately following commit for that.

---

## D-39 Engineering Department Bootstrap Phase 01 — Plan Approved, Baseline Gate Pending (2026-09-19)

Founder approved `FG-ENG-01 Phase Authorization` for the canonical
`CEFFLO ENGINEERING BOOTSTRAP — PHASE 01 FINAL PLAN`.

The approved Engineering architecture is:

```text
E1 Lead → E2 Build ⇄ E3 Pixel → E4 Verify → E5 Ship
```

n8n is the deterministic control plane. The minimum workflow family is locked
to four responsibilities: `CEFFLO ENG - 00 - Control Plane`, `01 - Context
Builder`, `02 - Role Executor`, and `99 - Failure & Escalation`. The Role
Executor is infrastructure, not a sixth Engineering agent.

Phase 01 is DEV/STAGING only. The latest Engineering Master and Cyber Security
Master are canonical at:

- `docs/cefflo/engineering/CEFFLO_ENGINEERING_MASTER.md`
- `docs/cefflo/security/CEFFLO_CYBER_SECURITY_MASTER.md`

Security is enforced by deterministic runner/tool controls outside model
prompts. Routine AI roles receive no production credentials, production DB
administration, production VPS/root authority, production Supabase service-role
authority, generic remote shell, Docker socket, arbitrary egress, unrestricted
model-generated commands, or direct access to Crown Jewels.

Only `FG-ENG-01` is granted. The following remain unapproved:

- `FG-ENG-02` baseline selection;
- `FG-ENG-03` canonical UI reference;
- `FG-ENG-04` spend/credential envelope beyond already available
  non-production capabilities;
- `FG-ENG-05` scope exception;
- `FG-ENG-06` security exception;
- `FG-ENG-07` pilot activation;
- `FG-ENG-08` operational acceptance.

The current implementation stop is `FG-ENG-02`. Before that gate, work is
limited to tracking the two masters, creating the approved bootstrap
documentation/contracts/configuration structure, and producing a non-destructive
decision/dependency-aware reconciliation packet for:

- `claude/flow-3-vendor-web-desktop-completion`
- `claude/experience-system-implementation`

No merge, cherry-pick, rebase, branch deletion, destructive reconciliation,
workflow activation, migration execution, Vendor V11 pilot, production action,
Marketing workflow modification, wider department implementation, Cyber
Security system rollout, or n8n PostgreSQL upgrade is authorized before the
applicable later gate.

---

## D-40 Engineering Baseline Selection — Approved with Amendments (2026-09-19)

Founder approved `FG-ENG-02` using the curated clean-integration strategy with
these immutable source points:

- Current bootstrap stop: `e8793900cc387c48c4cc30cd4328df5f0799043c`.
- Experience snapshot: `e5d47cc7e310f91e71e9220bdda79eae08686ea3`.

The isolated baseline preserves D-37, D-38, D-39 and the Phase 01 Engineering
bootstrap; imports selected valid Experience web/shared work and the substantial
Vendor Mobile implementation; excludes the obsolete Rider 33-screen scaffold,
`previews/vendor-auth-prototype/**`, and
`apps/vendor_mobile/CLAUDE_UI_HANDOFF.md`; and keeps V-50–V-54 outside the
active baseline. The original source branches remain intact for evidence and
rollback. Driver is not rebuilt or reconciled under this gate.

**Typography amendment:** Inter is the active Founder-approved typeface for
CEFFLO app UI, including Vendor Mobile and future Driver Mobile work. This
supersedes D-33's Manrope direction. The valid locally bundled Inter
implementation is retained; Manrope must not be restored as active runtime
truth unless a later Founder decision explicitly changes the direction.

**Compact-token amendment:** the historical `12 / 13 / 11 / 20 / 60 / 14`
values are not mandatory current tokens. Baseline integration preserves the
latest valid implementation and removes duplicate or clearly superseded token
systems where authority is sufficient. It does not perform broad visual
retuning. Any unresolved value requiring design judgment is held for
`FG-ENG-03`, where Founder-approved references and E3 Pixel can validate exact
values.

Vendor Mobile lifecycle truth is **IMPLEMENTED / INTEGRATION IN PROGRESS / UI
NOT YET LOCKED / DEV-STAGING**. This is evidence of a substantial working
implementation, not a production-readiness claim.

This decision authorizes only isolated baseline creation and technical
validation. It does not grant FG-ENG-03 through FG-ENG-08, Vendor V11 execution,
Engineering workflow activation, production deployment, or the n8n PostgreSQL
upgrade. The next required Founder gate is `FG-ENG-03 — Canonical Reference`.

---

## D-41 Vendor Mobile V11 Canonical Reference Registered (2026-09-19)

Founder approved `FG-ENG-03` for reference registration only. The active
canonical visual reference is:

- Reference ID: `UI-VENDOR-V11-TODAY-v1`.
- Product/screen: CEFFLO Vendor Mobile, V11 Today.
- Asset: `docs/cefflo/engineering/references/vendor-mobile/UI-VENDOR-V11-TODAY-v1/reference.jpg`.
- SHA-256: `0940081867837b1a51c18d7917cfba4cbff493f130cce9e0de730cedfea86bcb`.
- Approved baseline: commit `2f3e49af1d649a79fcd7d6e7b1894cd56de6f378`, tree
  `b28fd255cf45afa390fb7ca1cc4a13f96de5a973`.

The asset is visual authority for V11 only. Product Truth and active Founder
decisions continue to govern behaviour, terminology, lifecycle and
functionality. Inter remains canonical. No global design-system rule may be
derived from this single screenshot without additional shared evidence.

`REF-CONFLICT-V11-NAV-001` is escalated: the image labels the fifth navigation
item `Settings`, while the active Vendor Mobile master specifies `Menu`. No
navigation terminology or behaviour is changed by this registration.

FG-ENG-03 does not authorize E1–E5 execution, V11 repair, model spend, workflow
activation, pilot activation, deployment or any later Founder gate. The next
formal gate is `FG-ENG-04 — Spend/Credential Envelope`; the navigation conflict
also requires explicit Founder resolution before implementation may treat the
reference label as product truth.

## D-42 V11 Navigation Reference Conflict Resolved — Product Truth Prevails

Recorded 2026-09-19. Founder explicitly resolved REF-CONFLICT-V11-NAV-001:
the canonical fifth navigation item is **Menu**. Do not amend Product Truth
to Settings. Preserve the reference's placement, spacing, icon treatment,
typography treatment, navigation-bar structure and applicable active/inactive
visual behaviour. Product Truth governs terminology and navigation behaviour;
the reference governs visual presentation.

UI-VENDOR-V11-TODAY-v1 remains ACTIVE with its original JPEG bytes and hash.
The conflict status is **RESOLVED — PRODUCT TRUTH PREVAILS**. D-41's request
for a navigation decision is closed by this decision.

Only FG-ENG-04 preparation is authorized next. No V11 modification, E1–E5
execution, pilot activation, purchase, credential provisioning or deployment
is authorized. FG-ENG-04 remains pending Founder approval.


---

## D-43 Control Layer Master Canonical Migration (2026-09-20)

Founder approved the documentation-only migration of the CEFFLO Control Layer
Master. The single active company AI governance authority is:

- Path: `docs/cefflo/control/CEFFLO_CONTROL_LAYER_MASTER.md`
- Source SHA-256: `bccaad1b21d7f285636d47e2c2be6fec292cd416eccb47e320922a913fab4693`

The canonical hierarchy is Founder → CEFFLO Control Layer → n8n as primary
technical execution/control-plane engine → Engineering, Product Intelligence,
Marketing, Sales & CRM and Customer Service. Cyber Security remains a
cross-company guardrail. Department masters retain internal authority.

Agents reason. Control Layer governs. Tools execute. Company Truth grounds.
Founder decides exceptions.

Agent OS and `17_AI_WORKFLOW.md` govern human-led development collaboration
only. The former DeepSeek AI Router task master is deprecated; company model
routing, tool dispatch and cost governance belong to CL8–CL10. Jev is recorded
only as **CANDIDATE JUDGMENT ENGINE — NOT QUALIFIED / NOT REQUIRED / NO ACTIVE
DEPENDENCY**.

This decision authorizes documentation reconciliation only. It does not
authorize Control Layer runtime or n8n workflow implementation, workflow
activation, database/schema or credential changes, provider qualification,
paid API calls, Engineering changes, V11 execution, FG-ENG-07, Jev setup or
legacy-file deletion. Engineering checkpoint
`053011c3af92c6b392b256208b743444275c4f6a` remains the frozen parent of this
documentation migration.


---

## D-44 CEFFLO Marketing Department Canonical Migration (2026-09-20)

Founder decisions D-MKT-01 through D-MKT-07 establish the sole active Marketing
architecture:

- Master: `docs/cefflo/marketing/CEFFLO_MARKETING_MASTER.md`
- SHA-256: `19f2ca5767aff7d5da2d3db4cda4df87953339a02d0cf2df9b97826472873579`
- Department: **CEFFLO Marketing Department**
- Roles: M1 Lead, M2 Radar, M3 Story, M4 Studio, M5 Guard, M6 Growth

Canonical hierarchy is Founder → CEFFLO Control Layer → n8n as primary
technical execution/control-plane engine → CEFFLO Marketing Department →
M1–M6. Marketing consumes company Control Layer contracts rather than
recreating them. M5 is independent.

The former Teams 1–5, `WF-01..08`, `CEFFLO - 00..12,99`, FG-2 and FG-V1–FG-V4
architectures are superseded as active authority. Their documents, workflows,
schemas, operational data and evidence remain untouched where not replaced by
concise documentation pointers, classified as legacy migration sources pending
replacement validation and a later Founder decision.

Founder approval remains required for organic publishing during migration and
the initial implementation/pilot. Paid media remains Founder-gated. No bounded
autonomous publishing is authorized. No `/am6/MASTER.md` or second Marketing
Master is permitted. Jev remains **CANDIDATE JUDGMENT ENGINE — NOT QUALIFIED /
NOT REQUIRED / NO ACTIVE DEPENDENCY**.

This decision authorizes canonical documentation migration only. It does not
authorize M1–M6 runtime implementation, new or activated workflows, workflow
JSON changes, database/schema/data changes, credentials, providers, paid API
calls, publishing, scheduling, advertising, Control Layer runtime, Engineering
changes, Engineering qualification or the V11 pilot.

## D-45 Vendor Mobile Gradient-Header Visual SOT (2026-09-23)

Founder supplied a new reference set for Vendor Mobile (Overview, Orders,
Zones, Riders, Rider Detail, Settings, New Order, Add Product, Sign In) and
declared it the canonical visual source of truth. Where it conflicts with the
earlier written SOT, the references win.

Retired: the flat-white authenticated header and CEFFLO Yellow as the active
bottom-navigation colour (`sot/12_EXPERIENCE_SYSTEM.md` §8 and the "active
navigation state" use in §1.1). There must not be two valid visual SOTs.

Adopted (written into `sot/12_EXPERIENCE_SYSTEM.md` v1.4 §8/§8A): one brand
gradient chrome running edge-to-edge behind a transparent status bar; white
content surface entering with rounded top corners and continuing behind a
transparent gesture area; three header variants (top-level, back-navigation,
detail hero); CEFFLO Blue (`#0B5FE3`, distinct from semantic Route/Info) for
active navigation, active tabs, section/detail icons and links; CEFFLO Yellow
remains the primary CTA colour; neutral grey status pills with semantic tint
only where a state must stand out; eight screen archetypes (A–H).

Implementation keeps the component architecture of the Vendor Mobile
normalization pass (branch `claude/vendor-mobile-ui-normalization-3wvl4d`,
`2e8cf63`) and replaces its visual layer at the source. Scope: Vendor Mobile
only. It does not change routes, data contracts, backend behaviour, Driver,
Vendor Web/Desktop, Customer Tracking or FOUNDR.

## D-46 Vendor Mobile Normalization — Header, Navigation, Settings and Contact Standard (2026-09-23)

Founder supplied a final normalization brief with new approved references
(Rider Detail, Delivery Plan, Invite Rider). It amends D-45 where they
differ; D-45's palette, gradient, content surface and archetypes stand.

Changed:
- **One header row everywhere.** `[leading] [title centred on the screen]
  [trailing]`, 56px, 20/700 white; both side slots take the wider side's
  width so an icon on one side never moves the title. Replaces D-45's large
  left-aligned top-level title and the separate back-navigation variant.
- **Four primary destinations**: Today · Orders · Zones · Riders. Menu is
  no longer a tab. Settings opens from a gear at the left of the Today
  header (business name centred, notifications right); Settings routes
  belong to Today.
- **One Settings directory** (Account: Personal information, Security,
  Notifications, Language, Appearance, Privacy · Business: Business profile,
  Storefront, Products, Team, Customers, Service area · Support: Help &
  support, About Cefflo · Sign out). V-42 Profile, which duplicated the
  Account destinations, is removed; its inventory position is an audit
  marker only (like V-41).
- **Contact standard**: any person/entity detail with a usable phone number
  uses the one `ContactActions` pair: neutral outlined circular Call (opens
  `tel:`) and WhatsApp (opens `wa.me`), labelled underneath. No number →
  "Not provided", no actions. Applies to Rider, Customer, Team member and the
  Order detail customer.
- **Rider Detail**: hero shows name, status, role and the vehicle plate;
  one stats card of Total orders · Customer rating · Joined (no "Max
  orders"); then Contact; then licence / additional information.
- **Primary actions stay reachable**: a screen's yellow CTA is pinned in a
  shared sticky action bar above the nav / gesture area on detail screens,
  operational screens and forms. Long content (order items, zone orders,
  recent deliveries) shows a compact preview with "View all".
- **Density**: list rows 60 (grouped 56), avatar / icon disc 40, compact
  section spacing; cards are white with a hairline border and subtle shadow.
- **Status pills are semantic by delivery state** everywhere: Ready /
  Delivered green, in progress blue, awaiting approval amber, Issue red.
  Replaces D-45's neutral-by-default list pills.

Scope: Vendor Mobile only. No backend, data-contract, Driver, Vendor
Web/Desktop, Customer Tracking or FOUNDR change. Recorded in
`sot/12_EXPERIENCE_SYSTEM.md` §8/§8A.

## D-47 Vendor Mobile Global Polish — Splash Anchor Blue, Outline Cards, Type Scale (2026-09-23)

Founder direction for a consistency pass over Vendor Mobile. Amends D-45/D-46
where they differ.

- **Anchor Blue = the Splash navy** (Founder chose V01 Splash over the Sign In
  sky blue). `CefGradients.brand` is the locked Splash backdrop value for
  value: linear top-left → bottom-right `#0A1730 · #12213E · #1E4585 · #12213E`
  (stops 0 / .34 / .66 / 1) plus the radial lift `#2F6BD0` @ 20%. Splash and
  the app shell render the same `BrandBackdrop`; the header, status bar and
  in-body hero surfaces (e.g. the Invitation link card) are one surface.
  The interactive blue (`CefColors.brand`: active nav/tabs, links, icons,
  selected states, map accents) is the Splash lift `#1E4585`; its tint is
  `#E8ECF3`. Retires `#0B5FE3`, the `#0633A8 → #0A6BE6` header gradient and the
  `#2A6EEC` info blue. Browser/PWA chrome colour is `#0A1730`.
- **Cards are outline-only**: white, 1px cool-grey border, 18px radius, no
  shadow. Elevation only on genuinely floating surfaces (dialogs, sheets).
- **Spacing first, dividers second**: no rules between page sections or form
  sections; list separators are light and inset past the leading icon.
- **Type scale (Inter)**: page title 20/600 (D-48); entity name 28/700; section
  heading 20/600; row title 16/600; body 15/400; secondary 14/400; pill 13/600;
  caption 12/500. Screens use theme roles only.
- **One outline icon family (Lucide)**: nav active state is the same outline
  icon in Anchor Blue (no filled Material variants); detail rows use the grey
  icon disc; Call / WhatsApp / Directions use one `OutlinedIconAction`.
- **Orders header**: Search and Add only (filter removed).
- **Order detail**: identity centred (reference, status, meta).
- **Notification centre**: unread/read states, mark read/unread, mark all
  read, swipe-to-delete with Undo, clear all; the Today bell dot reflects
  unread count.
- **Invite QR**: a real, scannable code in a compact dimmed modal.

Open: the Sign In / auth-sheet sky sweep (`#51BDF8 → #0B67E8 → #031A50`) is a
Founder-locked auth composition and was not changed in this pass; it is the
one remaining non-Anchor blue in Vendor Mobile.

## D-48 Cefflo Icon Family — Canonical Icon Design and Palette (2026-09-24)

Founder supplied the **Cefflo Icon Family** sheet
(`docs/cefflo/brand/icon-family/cefflo-vendor-icon-family.png`) and declared it
the canonical icon design for Cefflo apps, applied first to Vendor Mobile. Its
palette replaces the D-47 Splash-extracted values; D-47's other rules (outline
cards, spacing-first dividers, type roles) stand.

**Palette**
- Anchor Blue gradient (top-left → bottom-right): `#0B1220` top (navy) ·
  `#1C3F7A` mid dark · `#2563B3` Anchor Blue (primary) · `#0A1F44` bottom.
  One `CefGradients.brand`, painted by `BrandBackdrop` (Splash, header +
  status bar as one surface, hero cards). Browser/PWA chrome `#0B1220`.
- Anchor Blue `#2563B3`: active navigation, active tabs, links, selected
  states, map accents. Tint `#E9EFF7`.
- Action CTA `#F5C400` · Success `#10B981` · Warning `#F59E0B` · Error `#EF4444`.

**Icon rules**
- One outline family (Lucide), **24px** everywhere: top app bar, bottom
  navigation, actions, rows.
- Every non-navigation icon is **navy `#0B1220`** and **bare** — no container,
  no tinted disc, no brand-coloured share buttons — centred in a 44px slot
  (`IconTile`) so rows align. Founder amendment 2026-09-24: the **round 1px
  outline is reserved for the Call and WhatsApp contact actions only**.
- **Only bottom-navigation icons are coloured**: active = filled icon in Anchor
  Blue with label and indicator; default = navy outline.
- Exception: status indicators on specific screens (e.g. Need Attention red,
  completion checks, selected radio). Map markers use Anchor Blue.
- Settings is the **hamburger** (≡) at the left of the Today header; "More"
  is the horizontal ellipsis.
- Call and WhatsApp: round outlined icons with a caption. Directions and share
  channels: bare icons with a caption.

**Header title**: 20px SemiBold (header icons 24px).

Note: `#10B981` / `#F59E0B` as text on white are below WCAG AA contrast
(about 2.5:1 and 2.1:1); they are applied as specified on status pills and
KPI figures. Sign In / auth sheets keep their locked sky sweep (open item from
D-47).

## D-49 Vendor Mobile Zones Flow — Zone Detail Is the Operational Screen (2026-09-24)

Founder-approved final Zones flow: Zones overview → Zone detail → (swipe a
delivery → Delete) / (⋮ Zone options → Edit zone name / Delete zone). No
separate Delivery Plan, Review Delivery Plan, Proposed Run, Edit Zone or
dispatch-confirmation screens.

- **Zones overview (V-16)**: hamburger · "Zones" · +; one map with every
  zone (first active zone emphasised); "Zones (n)" list — name, status,
  today's orders · riders, chevron.
- **Zone detail (V-17)**: header is the zone's name with ⋮; large map; name +
  status + locality; exactly three figures without a card — Total distance
  (server plan distance), Total orders, Delivered (actual delivered count, 0
  until something is delivered); "Today's deliveries" (no run wording) — rider
  header with a neutral grey "n orders" pill, then cardless numbered stops
  (distance · travel time, planned arrival when the server supplies them),
  divided by hairlines. Swipe a stop fully left to remove it (red trash,
  Undo-free confirmation via a deliberate full swipe).
- **Zone options**: exactly Edit zone name (lightweight sheet, Cancel/Save)
  and Delete zone (red; confirmation sheet "Delete {zone}?"). No boundary or
  status options.
- **Removed**: V-18 Review Delivery Plan (`ReviewDispatchScreen`) and V-30 Edit
  Zone (edit mode of the zone form); both are audit markers only. V-29 Create
  Zone keeps a create-only form. Dispatch RPC methods remain in the repository
  as backend contracts.
- **Open**: V-19 Active run is no longer linked from any screen (it was only
  reached after dispatch); kept, reachable by audit URL, pending a Founder
  decision. Removing a delivery from today's plan and renaming / deleting a
  zone have no dedicated server contracts: rename / delete use direct `zones`
  table writes under RLS; removal works in the demo and reports "not
  available yet" against a live backend.

## D-50 Vendor Mobile Cardless Content Rule (2026-09-24)

CONTENT IS CARDLESS; controls and true structural surfaces may keep
containers. Repeated content rows (orders, deliveries, riders, zones,
notifications, issues, history) sit directly on the page, separated by
spacing and the one `CefDivider` (1px, light cool grey, inset past the
leading icon). Kept as containers by function: buttons, fields, pills,
sheets, dialogs, toasts, maps, media, summary surfaces (Business profile
summary, Rider stats), grouped settings on the grey Settings page, the
Share-via control group, the Contact / information cards on approved detail
screens.

Applied: Today Need Attention (cards → rows; tinted red status mark; "View
all"), Customer detail orders (bordered group → rows). Today also gains the
greeting on the navy chrome ("Good Morning, {name}! / Here's what's happening
today.") per the Founder reference.

## D-51 Vendor Mobile — One Canonical Vendor Blue; More Tab; Today Header (2026-09-24)

Founder reference (Today / Subscription board) supersedes the D-47/D-48 blue
values. One source of truth in `lib/core/theme.dart`:

- `CefGradients.brand`: bottom-left → top-right `#01265E · #00378F · #005CC4 ·
  #0592EB` (stops 0 / .35 / .7 / 1), sampled from the reference. No overlays.
  Painted only by `BrandBackdrop`: Splash, Sign In and every auth sheet, the
  app shell (status bar + header as one transparent, continuous surface) and
  in-body hero surfaces. Browser/PWA chrome `#01265E`.
- `CefColors.anchorBlue` `#01265E` (deep end); `CefColors.brand` `#0060FE` —
  the one interactive blue (active nav/tabs, links, selection, map boundaries
  and pins, progress); tint `#E6EFFF`. `CefColors.navy` `#0B1220` stays the
  neutral dark for icons and text.
- Retired: `#1C3F7A` / `#0A1F44` / `#2563B3` (D-48) and the Sign In sky sweep
  `#51BDF8 / #0B67E8 / #031A50` — the auth screens now share the canonical
  gradient.
- Semantic colours unchanged (success, issue, CTA yellow, neutral grey).

Navigation: bottom navigation is Today · Orders · Zones · Riders · **More**
(hamburger icon). More hosts the Settings hub (title "More"); every settings
route belongs to the More tab. The hamburger is removed from the Today and
Zones headers (supersedes D-46's header gear/hamburger).

Today header: date on the left ("Wed / 24 Sep"), business name with a
dropdown mark in the centre (business switcher), bell on the right; greeting
below on the same blue surface.

## D-52 Vendor Mobile — One Universal Background (2026-09-24)

The canonical Vendor blue is the universal background of the authenticated
app, not a screen decoration. `VendorShell` paints it once (`BrandBackdrop`)
full screen — behind the transparent status bar, the transparent headers,
the white content surface and the bottom navigation — and the element
persists across Today / Orders / Zones / Riders / More, so it never restarts.
Screens are foreground layers: no screen, header or app bar declares a blue
or a gradient. Direction: TOP deep Anchor Blue `#01265E` → `#00378F` →
`#005CC4` → BOTTOM bright `#0592EB`. Splash and auth use the same token.
Guarded by a widget test (one backdrop; same element across all tabs).

## D-53 Vendor Mobile Correction Pass — Edge-to-Edge, Mustard, #CF Numbers, Vendor Permissions (2026-09-24)

- **Edge-to-edge**: status bar and system navigation / gesture area are
  transparent on every screen; the screen underneath continues to both
  physical edges. Native: `CefSystemBars` (unchanged). Web/PWA on Android:
  `viewport-fit=cover` plus an `env(safe-area-inset-bottom)` probe fed into
  MediaQuery at the app root, removing the standalone black strip.
- **`CefColors.ceffloMustard` `#FFC93C`**: the one Cefflo yellow (clear warm
  mustard, not gold/orange/lemon), replacing `#F5C400`; always dark text.
- **Order numbers** display as `#CF` + number (`ORD-1008` → `#CF1008`) through
  one formatter, `cefOrderRef`; stored references are unchanged.
- **Vendor does not progress delivery**: Order detail has no "Mark as On the
  Way" (or any rider-state action); On the Way / Delivered come from the
  Rider app and are only reflected. A Ready order has no bottom action.

## D-54 Vendor Mobile — More, Subscription and the Centred Status Modal (2026-09-24)

- **More** (V-46) is cardless on white: Account (Profile, Security,
  Notifications, Language, Appearance) · Business (Business Profile,
  Storefront, Products, Team, Subscription) · Support (Help & Support,
  Privacy, About Cefflo) · Sign out row · version. No Customers, Service
  Area or top-level Billing entry.
- **Language** is a bottom sheet from More (Bahasa Melayu, English, 中文,
  தமிழ்); V-48 is an audit marker only.
- **Notifications** (V-47): issues, delivery progress and account security
  are always on (no switch); three optional switches.
- **Appearance** (V-49): accent colour swatches (Blue, Navy, Red, Green,
  Yellow, Orange, Purple, Black, White, Custom picker). No light/dark mode.
  Session preference; it must never recolour semantic colours, the Cefflo
  gradient or the mustard CTA.
- **Subscription** (previously HOLD): V-50 Subscription, V-51 Choose a plan,
  V-52 Review & Payment, V-54 Billing History, under More › Business. Plans
  are the pricing candidate in `sot/10_PRICING.md` (Free RM0 · Grow RM99 ·
  Operate RM199 Most Popular · Scale RM499; yearly = 10 months), held in
  `lib/data/plans.dart`. Selected plan = restrained Anchor Blue (tint, thin
  outline, check); mustard only as the small Most Popular badge; no
  decorative plan icons. CTA "Subscribe". Payments are demo-only.
- **One centred status modal** (`runAsyncFeedback`) for every transactional
  state: Processing (small spinner), Success (layered green mark, title +
  Done only), Failure (small red mark, Try again + optional secondary).
  Centred, dimmed/softened backdrop, fade + slight scale — never a page, a
  bottom sheet or a slide-up. V-53 Payment Success is this modal.


## D-55 Vendor Mobile — Storefront Redesign and Extensible Template System (2026-09-24)

**Decision (Founder).** The Storefront screen is replaced by a visual-first, cardless storefront-management surface. Templates become a data-driven, extensible library.

- **Model.** A template is a reusable layout: its renderer, default theme, background treatments and declared customization capabilities. Vendor data (business identity, products, prices, categories) is injected at render time and never stored per template. Tags are discovery filters only; any vendor may use any template.
- **Registry.** There is one canonical registry (`apps/vendor_mobile/lib/ui/screens/storefront/templates/template_registry.dart`), and each template owns `templates/<id>/`. The gallery, its filter chips, Template Preview and Customize render from the registry and never branch on a template id. The process for adding a template is documented in `templates/STOREFRONT_TEMPLATE_GUIDE.md`.
- **Initial set.** Exactly the five approved reference layouts, rebuilt to follow the Founder mockups with neutral content:
  - Arena (Bold Showcase) — the default;
  - Stride (Clean Minimal);
  - Ritual (Premium Product);
  - Market (Clean Commerce);
  - Feast (Rich Visual).

  The earlier renderers that were not in the reference set are removed.
- **Screens.**
  - Storefront (V-31): the active storefront's real miniature is the hero, running behind the transparent status bar with overlay Back, name, green Active, View storefront and Customize; Explore Templates follows below.
  - Flow: Template Preview (X-02) → Use This Template → Customize (V-33) → Save.
  - Nothing goes live until Save.
- **Thumbnails.** Every thumbnail is a live miniature of the template rendering the vendor's own products. Product imagery uses neutral, brand-free illustrations until the catalogue has product photos. No third-party branding ships.
- **Customize** renders only the controls the template declares: brand colour (swatches + custom), background (template treatments + custom tint), hero image (templates with a banner) and store name / tagline (defaulting to the Business Profile). Changes update the live preview immediately but stay a draft until saved.
- **Colours.**
  - Cefflo blue is used for selection and filters; mustard for primary actions; green for Active.
  - Template colours belong to the template and the vendor, never to the Vendor app palette.
- **Persistence.** Storefront configuration is in-memory session state behind `AppState.applyStorefront`, since there is no storefront backend yet.

## D-56 Backend Wiring Sequence and Truth Boundary (2026-09-24)

**Decision (Founder).** Backend wiring for the current Flutter Vendor, Flutter
Driver and Customer Tracking PWA proceeds only after a read-only audit and a
separate Founder gate.

- Shared Auth, roles and active business/rider context are wired and verified
  first because all three product surfaces depend on them.
- Implementation order is Vendor Mobile → Driver Mobile → Customer Tracking.
  Each surface consumes the authoritative data produced by the previous one.
- Wiring belongs in repository/adapter layers; the approved UI remains locked
  except for the smallest state/error integration required for truthful wiring.
- `VendorRepository.demo()`, `RiderRepository.demo()`/`DemoData`, and
  `CEFFLO_UI_PROTOTYPE=true` remain supported as explicit preview-only paths.
  Demo state must never be represented as persisted backend truth.
- Missing capabilities stay behind a clear adapter boundary and are reported as
  unavailable. Schema changes require new migrations; existing migrations are
  immutable.
- Every app must pass repository tests, Flutter analysis/tests, web build,
  staging real-data flows and 393×852 visual evidence before its branch may be
  pushed.

Phase 1 evidence and the implementation gate are recorded in
`docs/cefflo/engineering/BACKEND_WIRING_AUDIT.md`.

## D-57 Phase 2A Driver Auth and Active Relationship Boundary (2026-09-25)

**Decision (Founder).** Phase 2A is authorized as the foundation step only.
Driver authentication uses the same Supabase Auth identity boundary as Vendor,
while operational authorization continues to come from canonical `riders`
relationships and RLS.

- Password sign-in, account creation, reset and recovery-password update go
  through `RiderRepository`; the real build may not enter the signed-in shell
  through a local-only callback.
- Creating an Auth user does not create, approve or fabricate a Driver
  relationship. A user without a canonical relationship remains in the
  no-business state until the invitation/approval contract is wired.
- One Auth identity may own multiple Driver relationships across businesses.
  The app hydrates all relationships, chooses an active relationship explicitly
  for scoped reads, and passes that rider id to later operational mutations.
- `CEFFLO_UI_PROTOTYPE=true` keeps the existing local demo journey. Demo state
  remains preview-only and cannot be used as evidence of persistence.
- Repository migrations, RLS, invitation, multi-business context and location
  contracts are qualified first on the disposable local Supabase target.
  Staging parity and real-data qualification remain blocked until the staging
  publishable configuration and authorized test identities are available.

This decision does not authorize Vendor operational wiring, Driver delivery
actions, Customer Tracking changes, production access, migration deployment or
branch push.

## D-58 Phase 2A Staging Qualification Boundary (2026-09-25)

**Decision (Founder authorization carried forward from Phase 2A).** Staging
qualification is split into two evidence levels so anonymous contract probes
cannot be mistaken for authenticated end-to-end proof.

- The only permitted hosted target is staging project
  `tomvvmwktehexwhktenw`. Environment identity must pass before any API or
  database probe; the known Production project remains prohibited.
- Anonymous live suites may prove RLS denial, RPC deployment, invalid tracking
  token behavior and frontend build configuration. They must not create users,
  upload POD, or leave test data.
- Authenticated Vendor/Driver session, role, relationship, tenant-isolation and
  real-data UI journeys require dedicated staging test identities. They remain
  unqualified until those identities are supplied out of band.
- A staging publishable key may be embedded only in an isolated staging build.
  Database connection material must never enter a frontend bundle. Temporary
  staging build output is deleted after validation.
- Passing anonymous contracts does not authorize migration deployment,
  Production access, workflow activation or branch push.

Current evidence: backend contract PASS; Vendor anonymous live contracts
11/11 PASS; Driver anonymous live contracts 11/11 PASS; Customer staging build
and invalid-token contract PASS. No staging mutation occurred.

## D-59 Phase 2A Staging Test Fixtures and Driver Session Truth (2026-09-25)

**Decision (Founder).** Authenticated Phase 2A qualification may use dedicated,
TEST-ONLY staging fixtures on `tomvvmwktehexwhktenw` only.

- Test Auth identities are created through the Supabase Auth admin API with the
  staging secret key held outside Git on the VPS. The secret key is used only
  by local qualification scripts and must never enter a frontend bundle.
- Because no product flow creates a business yet, Business A and Business B
  (`TEST-ONLY Phase2A …`) and their owner memberships may be created directly
  as staging fixtures. This is not a product path and grants no precedent for
  Production.
- Driver relationships are never written directly. They are produced only by
  the canonical Vendor invitation → Driver acceptance → Vendor approval RPCs,
  called as the signed-in test identities.
- In the real build, the Driver lands on the screen owned by the hydrated
  relationship stage, Log Out revokes the Supabase session, and the
  prototype "simulate approval" control is shown only in prototype mode.
- The Driver Today surface's DemoData counters, current run, greeting and
  business row are operational wiring and remain outside Phase 2A; they block
  a truthful active-Driver real-data qualification until separately approved.

## D-60 Phase 2A Close-Out and Phase 2B Backlog (2026-09-25)

**Decision (Founder).** Phase 2A is COMPLETE WITH EXTERNAL STAGING LIMITATION.

- The only unpassed checks are the Driver sign-up and in-app recovery request
  screens, blocked by the staging Supabase built-in email rate limit (429).
  They carry into the next staging regression run. No SMTP or infrastructure
  change is authorized for this.
- Moved to the Phase 2B backlog, not implemented in Phase 2A: active Driver
  Today real-data wiring; explicit multi-business Driver selection; real data
  behind the Pending Review "Submitted" ticks (static display, no backend
  success asserted).
- The Vendor Riders semantic defect is fixed within Phase 2A: a pending rider
  is never displayed or filtered as Offline.
- All `TEST-ONLY Phase2A` staging fixtures are retained for Phase 2B and
  regression testing.
- Phase 2B does not start until separately approved by the Founder.

## D-61 Phase 2B.1 Vendor Operational Core (2026-09-25)

**Decision (Founder).** Vendor Mobile uses the same canonical contracts as
Vendor Web/Desktop for Orders → Zones → Runs → Rider Assignment. No migration
and no new RPC.

- **Dispatch** stays inside Zone detail (D-49 information architecture kept):
  rider selection → `check_run_vehicle_capacity` → confirmation →
  `build_rider_run`, as bottom-sheet overlays; no V-18 screen. The open
  session is chosen with Vendor Web's rule (first planned/active session,
  else `create_delivery_session`).
- **Canonical assignment path** is run-based `build_rider_run`;
  `reassign_rider` is for correction only. Mobile adds no per-order
  assignment flow.
- **V-19 Run detail** is re-linked from a dispatched rider on Zone detail and
  reads the persisted `rider_assignments` + `delivery_stops` rows.
- **Zones:** rename through `rename_zone`; Delete zone archives through
  `set_zone_status('inactive')` -- no hard delete.
- **Orders:** Order detail offers Approve (`approve_order`) and Zone
  selection (`update_order_details`) before dispatch; an approved order that is
  still `created` reads "Approved".
- **Remove from today's deliveries** stays unavailable in the real build until
  a canonical planning contract exists; zone membership is not today's plan.
- Rider approve/deactivate UI stays out of this phase.
- Correction: the backend contains `bootstrap_business`; the Phase 2A gap is
  that no completed product/UI business-creation flow calls it. Phase 2A stays
  COMPLETE WITH EXTERNAL STAGING LIMITATION.

## D-62 Canonical UI Clean Replacement (2026-09-25)

**Decision (Founder).** The active repository baseline carries exactly the
canonical CEFFLO UI products; obsolete UI is removed from the active tree,
build, routing and tests (Git history keeps it).

- **Vendor:** Mobile `apps/vendor_mobile` (Flutter) and Web/Desktop `vendor/`.
  The Web/Desktop welcome presentation (hero photo, welcome copy/CSS, yellow
  Get Started CTA, `showAuthWelcome`) is removed. Unauthenticated startup is
  the existing login screen (`emailLogin`), the entry the Flow 3 Contract
  Pack names; its existing language control moved there from the welcome.
- **Driver:** Flutter Mobile `apps/rider_mobile` only. The static Rider PWA
  (`rider/`) is removed; its backend contracts stay canonical and are listed
  in `07_RIDER.md`. `rider.cefflo.com` serves only a retirement worker.
- **Customer Tracking:** `customer/` from `claude/customer-tracking-pwa`.
- **Founder:** `foundr/` from `codex/foundr-pwa-interactive-prototype`.
- **Public Website: NOT IMPLEMENTED.** `marketing/` (and `prelaunch/`) is
  removed; `www.cefflo.com` has no product rewrite.
- **Invitation:** `invite/` is a temporary supporting Vendor → Driver route,
  not a product, pending migration into Driver onboarding. `invite.cefflo.com`
  is routed to it (Vendor Web already issues links to that host).
- Prototype previews `previews/s4-10a…d` are removed with their preview-only
  tests.
- The static build publishes only `scripts/canonical-surfaces.mjs` and fails
  if a removed surface or the welcome markers reappear.
- Removed PWAs are retired explicitly: `retired/sw.js` clears caches and
  unregisters; the Vendor shell cache is rotated.
- Backend contracts, migrations, RLS and shared client/config are unchanged.

## D-63 Phase 2B.2 Driver Execution (2026-09-26)

**Decision.** The approved Driver Flutter UI (`apps/rider_mobile`) executes a
dispatched run on the existing canonical contracts only. No new RPC, table or
migration.

- Accept → `accept_run`; Confirm Pickup → `start_pickup_run` then
  `rider_transition` to `picked_up`; route confirm → `save_run_sequence` then
  `start_run_delivery` (locks the sequence only); arrive →
  `rider_transition` `out_for_delivery` → `arrived`; deliver → POD upload to
  `cefflo-pod/<riderId>/<orderId>/…` then `complete_delivery`; issue →
  `rider_report_delivery_issue`.
- Issue reasons map to canonical values only (customer_unreachable,
  address_problem, vendor_not_ready, rider_unable_to_proceed). "Reschedule" and
  "Other" are refused with a visible error until a canonical reason exists.
- The authenticated build projects Today, Run Details, stops, History and
  Profile from backend rows. Demo data is used only by the prototype build; no
  fabricated distance, ETA, map labels, notifications or documents.
- A Driver linked to several businesses resolves the oldest active
  relationship (`created_at` ascending) until explicit selection UI exists.

## D-64 Human-Facing Order Number `#CF-001` (2026-09-26)

**Decision (Founder, locked).** Every product surface shows one order number
format: `#CF-` plus a per-business daily sequence, at least three digits and
never capped (`#CF-001` … `#CF-999`, `#CF-1000`). Supersedes the `#CF1008`
display rule of D-53.

- Per business, reset each **business-local** calendar day
  (`businesses.timezone`, default `Asia/Kuala_Lumpur`). Business A and B may
  both show `#CF-027`; uniqueness is `(business_id, order_date, order_seq)`.
- Assigned by the backend on insert (`orders.order_date`, `orders.order_seq`,
  generated `orders.order_number`) under a per-business-day transaction lock;
  immutable afterwards. Migration `202609260001_order_number_daily_sequence`.
- Display/operational only. `orders.id` stays the identity for joins, RPCs,
  RLS, storage paths and events; `public_ref` is unchanged. Customer Tracking
  access stays token-only; the number is never a lookup key.
- `public_tracking` and `list_plannable_orders` additively return
  `order_number`.

## D-65 Phase 2B.3 Customer Tracking on Real Data (2026-09-26)

**Decision.** Customer Tracking (link/token only) renders exclusively the
existing `public_tracking` snapshot. No new RPC, table, policy or migration.

- Activation: tracking opens at `picked_up` (Driver collects). `created` /
  `ready_for_pickup` show the neutral "No order yet" state; `out_for_delivery`
  and `arrived` → On the Way; `delivered` → Delivered; `issue` / `cancelled`
  → their existing truthful templates; invalid/expired token → generic
  "Tracking unavailable" (no internals).
- Token mode never merges prototype fixtures. Fields the contract does not
  carry (items, note, pickup time, addresses, recipient, rider vehicle/plate/
  photo/contact, rider note) render "—"; no map/route and no ETA unless the
  backend returns a truthful ETA. Fixtures remain prototype-only.
- Order identity shown is the D-64 `#CF-001`; the token stays the only
  credential.
- Reached progress milestones use the semantic success green (`--success`)
  instead of the vendor primary (Founder request), in every state.
- The status head stacks the icon centred above a centred title and body
  (Founder request). Each milestone dot carries a visible label (Pickup /
  On the Way / Delivered); the content group is centred vertically in the
  sheet; "Powered by Cefflo" stays on every screen with a larger bottom inset.
