**Status:** CANONICAL — Founder-approved, merged into repo 2026-09-04
**Repo-reconciliation note:** This is the current canonical Founder-approved knowledge-base root. It supersedes `docs/cefflo/CEFFLO_BRAND_BRAIN.md` for brand/product/architecture doctrine and extends the same "newer canonical layer above the numbered pack" pattern already established by `docs/cefflo/00_AGENTS.md`. Each domain below is resolved to its actual repo path (or flagged as a genuine gap) rather than left as a bare filename placeholder.

---

# CEFFLO — KNOWLEDGE BASE MASTER INDEX
**Version:** 1.0 — 2026-09-04
**Purpose:** Top-level map of Cefflo canonical knowledge domains.

## 0. CEFFLO 7-Phase Execution Roadmap (parent hierarchy — added 2026-09-12, see `docs/cefflo/05_DECISIONS.md` D-29)

The Founder-directed top-level execution structure, PHASE 01 (Founder-approved 2026-09-12 as the current run's baseline; not yet finally reviewed/approved — see D-29) through PHASE 07:

```text
PHASE 01 — TRUTH / SOT BASELINE                    Gate: TRUTH READY
PHASE 02 — GROW V1 PRODUCT ARCHITECTURE            Gate: V1 READY
PHASE 03 — MARKETING ENGINE + CONTENT PILOT        Gate: MARKETING MACHINE READY
PHASE 04 — VENDOR PRODUCT                          Gate: VENDOR READY
PHASE 05 — DELIVERY EXPERIENCE                     Gate: DELIVERY LOOP READY
PHASE 06 — PLATFORM + COMMERCIAL                   Gate: PLATFORM READY
PHASE 07 — PRODUCT PILOT → LAUNCH                  Gate: GO / NO-GO
```

**Deliberate sequencing change (Founder-directed, 2026-09-12):** Marketing Engine execution (Phase 03) is intentionally earlier than full product completion. Once Phase 01+02 are approved, the marketing/content machine may build and run in parallel with Vendor (Phase 04) and Delivery Experience (Phase 05) product work — marketing does not wait for the whole product to finish, but must never represent the product as more commercially available than Product Truth supports.

**Relationship to `docs/cefflo/03_ROADMAP.md`'s existing "Stage 4 Roadmap, Phase 0–7":** that is a *different, narrower, already-partially-executed* framework (AI Workstation → Baseline & SOT Lock → Backend & Security → Vendor PWA → Rider+Customer → FOUNDR → Integration & RC → Production & Go-Live) — same "Phase N" numbering convention, different scope, no Marketing phase. To prevent the two "Phase N" sequences being confused: the Stage-4 roadmap's Phase 1 (Baseline & SOT Lock) is subsumed by this hierarchy's Phase 01; its Phase 2 (Backend & Security) and Phase 3 (Vendor PWA) map into this hierarchy's Phase 02/04; its Phase 4 (Rider+Customer) maps into Phase 05 (Delivery Experience); its Phase 5 (FOUNDR) and commercial/billing scope map into Phase 06; its Phase 6–7 (Integration/RC, Production/Go-Live) map into Phase 07. `03_ROADMAP.md`'s sprint-level detail (S4-01 etc.) remains valid execution-level evidence — see the reconciliation note added to that file.

**Five Canonical Product Surfaces** (frozen 2026-09-12, Phase 02 — see `docs/cefflo/sot/02_ARCHITECTURE.md` §0 for the full freeze): Vendor Product (Web/Desktop + Flutter — one product, two presentation surfaces), Driver Product (Flutter Mobile — the target-state surface described by `docs/cefflo/sot/08_RIDER_FLUTTER_33_SCREEN_MASTER.md`/`docs/cefflo/07_RIDER.md`'s live PWA; canonical backend/schema role remains "Rider," unchanged), Customer Tracking (Web/PWA), CEFFLO Website (Public Web — `docs/cefflo/sot/11_CEFFLO_WEBSITE.md`, domain 17 below), FOUNDR Command Center (Internal Web/Desktop). Operations/Helper is a permission-scoped role within Vendor Product's team system (D-22, `CEFFLO_GROW_V1_SCOPE_LOCK.md` §15), not a sixth surface.

**Workforce terminology (reconciled 2026-09-12):** general/unscoped term is Driver / Delivery Driver / Delivery Team; "Rider" is natural specifically for motorcycle context (Driver is also acceptable there); Car/Van use Driver / Van Driver / Delivery Driver. **No backend/schema/API renaming performed or authorized** — `riders` table, `rider_vehicle_type` enum, and all D-01–D-28 "Rider" product/role terminology remain exactly as-is. See `docs/cefflo/sot/01_PRODUCT_TRUTH.md` §4 for the canonical statement.

Full Phase 01+02 execution report: `docs/cefflo/05_DECISIONS.md` D-29.

## 1. Vendor Flutter
Primary:
- `docs/cefflo/sot/09_VENDOR_FLUTTER_60_SCREEN_MASTER.md` — status: WORKING MASTER BASELINE, "Founder Review Required," NOT YET IMPLEMENTED. Subscription/billing screens V-50–V-54 remain HOLD; V-41 Delivery Settings remains RECONCILIATION REQUIRED.
- `docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md` — **CANONICAL as of 2026-09-11 (D-33)**, the approved Visual DNA/Experience System. Fills the previously-empty "approved Design Lab/DNA outputs" slot.

Authority:
Product Truth → Architecture → Flow 3 Behavioural Contract → approved Visual DNA (`docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md`) → Flutter implementation.

Reference: `docs/cefflo/flow3/VENDOR_BEHAVIOURAL_CONTRACT_PACK.md` (the Flow 3 Vendor Web exit contract Flow 4 must build against). The current LIVE Vendor client remains Vendor Web/Desktop (`docs/cefflo/06_VENDOR.md`) — neither this master nor the now-canonical Experience System authorizes starting Flutter implementation or migrating existing Flutter code; that remains a separate, not-yet-authorized execution stage.

## 2. Rider Flutter
Primary:
- `docs/cefflo/sot/08_RIDER_FLUTTER_33_SCREEN_MASTER.md` — status: ACTIVE MASTER, "Founder Review Required," NOT YET IMPLEMENTED.
- `docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md` — **CANONICAL as of 2026-09-11 (D-33)**, the same shared Visual DNA authority as Vendor Flutter. No Rider Flutter implementation exists in the repository yet — this is the visual authority it will build against once authorized.
- Rider execution behavior — see `docs/cefflo/07_RIDER.md` for the current LIVE Rider PWA (the actual live client today).
- shared canonical backend contracts — see `docs/cefflo/sot/02_ARCHITECTURE.md` and `docs/cefflo/11_SUPABASE.md`.

## 3. Customer
Primary:
- `docs/cefflo/sot/04_CUSTOMER_TRACKING.md` (canonical doctrine)
- `docs/cefflo/08_CUSTOMER_TRACKING.md` (current PWA implementation routing)

Customer is a narrow public projection of canonical delivery truth.

## 4. Vendor Web
Primary:
- `docs/cefflo/sot/03_VENDOR_WEB_DESKTOP.md` (canonical doctrine)
- `docs/cefflo/06_VENDOR.md` (current implementation routing)
- `docs/cefflo/flow3/VENDOR_BEHAVIOURAL_CONTRACT_PACK.md` (Flow 3 exit contract, complete)
- `docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md` — **CANONICAL as of 2026-09-11 (D-33)**, shared visual authority (also applies to Vendor Flutter and Rider Flutter). Does not authorize any implementation change to the live Vendor Web client by itself.

Vendor Web/Desktop remains first-class.

## 5. Product Architecture
Primary:
- `docs/cefflo/sot/02_ARCHITECTURE.md` (canonical doctrine — target multi-client end-state)
- `docs/cefflo/02_ARCHITECTURE.md` (current implementation routing)
- "Flow 2 Canonical Backend Completion Master" — no separate master doc exists in this repo; its outcomes are reflected in the current migrations/RPCs/tests.
- migrations/RPC/security architecture references — see `docs/cefflo/11_SUPABASE.md`, `docs/cefflo/12_SECURITY.md`.

## 6. Marketing Engine
Primary hierarchy:
1. `docs/cefflo/sot/01_PRODUCT_TRUTH.md`
2. `docs/cefflo/sot/05_BRAND_BRAIN.md`
3. `docs/cefflo/sot/marketing/07_MARKETING_MEMORY.md` — schema initialized; performance memory intentionally EMPTY, no real campaign data exists yet.
4. `docs/cefflo/sot/marketing/01_AUDIENCE_ICP.md`
5. `docs/cefflo/sot/marketing/02_CLAIMS_REGISTRY.md`
6. `docs/cefflo/sot/marketing/03_CONTENT_PHILOSOPHY.md`
7. `docs/cefflo/sot/marketing/04_CREATIVE_PLAYBOOK.md`
8. `docs/cefflo/sot/marketing/05_PAID_GROWTH_PLAYBOOK.md`
9. `docs/cefflo/sot/marketing/06_AI_MARKETING_ENGINE_MASTER.md`
10. `docs/cefflo/sot/marketing/08_AI_CONTENT_ENGINE_ORCHESTRATOR.md` — Founder-approved v1.1 (2026-09-10), n8n orchestration blueprint for item 9's daily pipeline; see `docs/cefflo/05_DECISIONS.md` D-25.
11. `docs/cefflo/sot/marketing/09_CONTENT_WORLD_PRODUCTION_DOCTRINE.md` — Founder-approved FG-1 reconciliation (2026-09-10); FG-2 (Content World Baseline) not yet granted. See `docs/cefflo/05_DECISIONS.md` D-26.
12. `docs/cefflo/sot/marketing/10_BRAND_VOICE_LANGUAGE_SYSTEM.md` — Founder-approved FG-1-equivalent reconciliation (2026-09-10), Malaysian Malay brand-voice doctrine; FG-V1–V4 not yet granted. See `docs/cefflo/05_DECISIONS.md` D-26.
13. `docs/cefflo/sot/marketing/11_CREATIVE_INTELLIGENCE_LAYER.md` — reconciled and implemented (2026-09-11): taxonomy, scenario contract/engine/validator, tested. GATE B (Rider/Driver terminology) RESOLVED — product/schema stays "Rider"; display terms are vehicle-contextual (Motorcycle=Rider, Car/Van=Driver, mixed=Delivery Team). See `docs/cefflo/05_DECISIONS.md` D-27.

## 7. Marketing Performance
Runtime evidence only:
- Marketing Memory schema exists (`docs/cefflo/sot/marketing/07_MARKETING_MEMORY.md`) but its data/exports are empty — no experiments have run yet.
- weekly reports — none exist yet.
- experiment performance — none exist yet.
- organic/paid learnings — none exist yet.

Do not store invented winner data here. This domain is N/A until real campaign data exists — no AI Marketing Engine implementation exists in this repo yet (see `docs/cefflo/sot/marketing/00_MARKETING_KNOWLEDGE_PACK_INDEX.md`).

## 8. Brand Assets
**Updated 2026-09-12 (Founder baseline closeout, D-30):** logo and Signal Lime are now Founder-locked.
**Updated 2026-09-11 (Experience System canonicalization, D-33):** Signal Lime's primary/signature-colour status is **superseded** — see below. Logo lock from D-30 is unaffected.
Primary:
- `docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md` — **CANONICAL, current palette/typography/surface-system authority.** CEFFLO Yellow `#FEC819` is the current locked primary/signature accent.
- `docs/cefflo/sot/06_BRAND_ASSETS_GOVERNANCE.md` — logo governance remains current here; §2's palette section is historical as of D-33 (annotated in place, not deleted).
- current Brand System — **logo LOCKED** (`docs/cefflo/brand/assets/logo/cefflo-logo-official.png`, see governance file §5, unaffected by D-33); **Signal Lime RETIRED** as primary colour (was locked at `#C7F000` under D-30; superseded by CEFFLO Yellow `#FEC819` under D-33 — see `12_EXPERIENCE_SYSTEM.md` §1).
- locked assets: logo (master + transparent + wordmark variants, PNG only), full palette/typography/surface system per `12_EXPERIENCE_SYSTEM.md`.
- exploration archive clearly separated — see `previews/cefflo-logo-identity-exploration/` (untracked, exploration only) — **superseded/historical, not canonical.**
- historical visual notes: `docs/cefflo/CEFFLO_BRAND_BRAIN.md` §8 (superseded, retained for history).

## 9. Cefflo Pricing
Primary:
- `docs/cefflo/sot/10_PRICING.md` — status: CANDIDATE, **NOT Founder-Locked**. RM0/RM99/RM199/RM499/Custom tier structure and all delivery/rider/zone/team allowances remain open per its own §16/§19.
- international pricing framework — not present beyond the "regional price books, not simple currency conversion" principle in §10_PRICING.md §3 P-08.
- approved price books — not present.

Candidate/simulation values must remain labeled. Do not publish any figure in `docs/cefflo/sot/10_PRICING.md` as final commercial truth.

## 10. Business & Launch
Primary:
- `docs/cefflo/sot/07_BUSINESS_LAUNCH_COMMERCIAL.md` (commercial/launch governance)
- `docs/cefflo/launch/CEFFLO_GROW_V1_SCOPE_LOCK.md` (Founder-approved, FROZEN 2026-09-03, V1 product/feature scope — complementary, not duplicate)
- Curlec subscription implementation/onboarding artifacts — none exist yet.
- legal/support/commercial launch decisions — see `docs/cefflo/05_DECISIONS.md`.

## 11. AI Agent Rules
Primary:
- `docs/cefflo/agent-os/CEFFLO_AGENT_OS_CORE.md`
- `docs/cefflo/agent-os/CHATGPT_OPERATING.md`
- `docs/cefflo/agent-os/CLAUDE_OPERATING.md`
- `docs/cefflo/agent-os/CODEX_OPERATING.md`
- `docs/CODEX_WORKING_RULES.md` (repo-root `docs/`, not `docs/cefflo/`)

Agent rules govern how work is performed; they do not override Product Truth or Founder decisions.

## 12. Global Authority Order
1. Latest explicit Founder decision
2. Canonical Product Truth / Architecture / Brand doctrine for their domains
3. Current verified runtime/repository/backend contracts
4. Current active implementation masters
5. Specialist SOTs
6. Historical/reference material

When conflict exists: reconcile; do not average.

## 13. Stale Doctrine Rule
Historical files may remain for traceability but must not silently override current doctrine.

Examples of superseded directions:
- Home Food OS positioning;
- purple/blue signature identity;
- Cefflo-owned rider network;
- vendor-customer payment/deposit/balance handling;
- fake GPS/ETA/optimization;
- old 3-content/day Marketing volume doctrine.

## 14. File Status Vocabulary
Use:
- CANONICAL / LOCKED
- ACTIVE MASTER
- CANDIDATE
- HOLD
- FUTURE
- EXPLORATION
- SUPERSEDED / ARCHIVE

## 15. Definition of Done
The knowledge base is healthy when an agent can locate the correct domain SOT, resolve conflicts deterministically, distinguish current truth from exploration/history, and execute without inventing missing product doctrine.

## 16. Open gaps / pending Founder decisions (updated 2026-09-04, second pass)
- `docs/cefflo/sot/10_PRICING.md` exists but is a CANDIDATE, not Founder-locked — no final price may be published (domain 9 above).
- `docs/cefflo/sot/09_VENDOR_FLUTTER_60_SCREEN_MASTER.md` exists but is "Founder Review Required," not implemented; its Subscription/billing screens V-50–V-54 are HOLD pending a separate Founder-approved payment architecture, and V-41 Delivery Settings needs reconciliation against Service Area/Zones (domain 1 above).
- `docs/cefflo/sot/marketing/07_MARKETING_MEMORY.md` exists but its performance memory is intentionally empty — no AI Marketing Engine implementation or real campaign data exists yet (domain 6/7 above).
- `docs/cefflo/sot/08_RIDER_FLUTTER_33_SCREEN_MASTER.md` remains "Founder Review Required" — not yet locked, not yet implemented; the current live Rider client is the PWA at `docs/cefflo/07_RIDER.md`.

See `docs/cefflo/05_DECISIONS.md` D-23 and D-24 for the full reconciliation record.

## 17. CEFFLO Website (added 2026-09-12, Founder baseline closeout — D-30)
Primary:
- `docs/cefflo/sot/11_CEFFLO_WEBSITE.md` — the fifth canonical product surface (§0 above / `02_ARCHITECTURE.md` §0). Public Web, acquisition/commercial surface only, not operational.
- current implementation: `marketing/index.html` (built public site) — Phase 03 pre-launch landing and Phase 06 full commercial site are both not yet built.

This closes the gap originally flagged when the five-canonical-product-surface architecture was frozen (2026-09-12, D-29).
