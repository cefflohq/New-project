**Status:** CANONICAL — Founder-approved, merged into repo 2026-09-04
**Repo-reconciliation note:** This is the current canonical Founder-approved knowledge-base root. It supersedes `docs/cefflo/CEFFLO_BRAND_BRAIN.md` for brand/product/architecture doctrine and extends the same "newer canonical layer above the numbered pack" pattern already established by `docs/cefflo/00_AGENTS.md`. Each domain below is resolved to its actual repo path (or flagged as a genuine gap) rather than left as a bare filename placeholder.

**Company AI governance authority added 2026-09-20 (D-43):**
- `docs/cefflo/control/CEFFLO_CONTROL_LAYER_MASTER.md` — canonical company AI governance and cross-department orchestration architecture. n8n is its primary technical execution/control-plane engine. Departments retain their internal authority; Cyber Security remains a cross-company guardrail.

**Engineering and security authorities added 2026-09-19 (D-39; baseline selection amended by D-40):**
- `docs/cefflo/engineering/CEFFLO_ENGINEERING_MASTER.md` — canonical Engineering Department E1–E5 architecture.
- `docs/cefflo/security/CEFFLO_CYBER_SECURITY_MASTER.md` — canonical cross-company security architecture. During Engineering Bootstrap Phase 01 it constrains only the approved Engineering attack surface; it does not authorize building the wider Cyber Security system.

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

**Five Canonical Product Surfaces** (frozen 2026-09-12, Phase 02 — see `docs/cefflo/sot/02_ARCHITECTURE.md` §0 for the full freeze; Driver Product UI/UX authority updated 2026-09-14, D-37; Driver/Rider naming LOCKED 2026-09-14, D-38): Vendor Product (Web/Desktop + Flutter — one product, two presentation surfaces), Driver Product ("Cefflo Driver" — LOCKED as the user-facing product name, D-38 — Flutter Mobile; UI/UX described by `docs/cefflo/sot/13_DRIVER_FLUTTER_42_SCREEN_MASTER.md` [ACTIVE MASTER, 42 screens D01–D42] and executes today as `docs/cefflo/07_RIDER.md`'s live PWA; canonical backend/schema role remains "Rider," LOCKED and unchanged, D-38 — the superseded 33-screen predecessor is `docs/cefflo/sot/08_RIDER_FLUTTER_33_SCREEN_MASTER.md`, now historical), Customer Tracking (Web/PWA), CEFFLO Website (Public Web — `docs/cefflo/sot/11_CEFFLO_WEBSITE.md`, domain 17 below), FOUNDR Command Center (Internal Web/Desktop). Operations/Helper is a permission-scoped role within Vendor Product's team system (D-22, `CEFFLO_GROW_V1_SCOPE_LOCK.md` §15), not a sixth surface.

**Workforce terminology (reconciled 2026-09-12):** general/unscoped term is Driver / Delivery Driver / Delivery Team; "Rider" is natural specifically for motorcycle context (Driver is also acceptable there); Car/Van use Driver / Van Driver / Delivery Driver. **No backend/schema/API renaming performed or authorized** — `riders` table, `rider_vehicle_type` enum, and all D-01–D-28 "Rider" product/role terminology remain exactly as-is. See `docs/cefflo/sot/01_PRODUCT_TRUTH.md` §4 for the canonical statement.

Full Phase 01+02 execution report: `docs/cefflo/05_DECISIONS.md` D-29.

## 1. Vendor Flutter
Primary:
- `docs/cefflo/sot/09_VENDOR_FLUTTER_60_SCREEN_MASTER.md` — WORKING MASTER BASELINE, Founder Review Required; **IMPLEMENTED / INTEGRATION IN PROGRESS / UI NOT YET LOCKED / DEV-STAGING** under D-40. V-50–V-54 remain HOLD and excluded from active routes; V-41 remains RECONCILIATION REQUIRED.
- `docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md` — **CANONICAL v1.3 under D-33–D-35 and D-40**. Inter is active app UI typography; exact compact values await FG-ENG-03 reference validation.

Authority:
Product Truth → Architecture → Flow 3 Behavioural Contract → approved Visual DNA (`docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md`) → Flutter implementation.

Reference: `docs/cefflo/flow3/VENDOR_BEHAVIOURAL_CONTRACT_PACK.md` (the Flow 3 Vendor Web exit contract). Vendor Web/Desktop remains the current LIVE Vendor client. D-40 authorizes the isolated Vendor Flutter DEV/STAGING baseline integration only; visual lock and later operation remain gated.

## 2. Driver Flutter ("Cefflo Driver" = LOCKED product name; "Rider" = LOCKED backend/schema/API role — D-38)
Primary:
- `docs/cefflo/sot/13_DRIVER_FLUTTER_42_SCREEN_MASTER.md` — status: **ACTIVE MASTER** (2026-09-14, D-37), 42 screens (D01–D42), "WORKING MASTER BASELINE," NOT YET Founder-locked, NOT YET IMPLEMENTED. The sole active Driver/Rider Flutter UI/UX screen-inventory authority.
- `docs/cefflo/sot/08_RIDER_FLUTTER_33_SCREEN_MASTER.md` — **SUPERSEDED / HISTORICAL** (2026-09-14, D-37). 33 screens, `R-01`–`R-33`. Retained for traceability only; do not implement against it.
- `docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md` — **CANONICAL as of 2026-09-11 (D-33)**, the same shared Visual DNA authority as Vendor Flutter. No Driver Flutter implementation exists in the repository yet — this is the visual authority it will build against once authorized.
- Rider execution behavior — the static Rider PWA was retired (D-62); canonical Driver UI is Flutter (`apps/rider_mobile`). `docs/cefflo/07_RIDER.md` keeps the historical behaviour and the Driver execution contracts.
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

## 6. CEFFLO Marketing Department

Canonical authority:
- `docs/cefflo/marketing/CEFFLO_MARKETING_MASTER.md` — sole active Marketing
  architecture; M1 Lead, M2 Radar, M3 Story, M4 Studio, M5 Guard and M6 Growth.

Parent governance:
- `docs/cefflo/control/CEFFLO_CONTROL_LAYER_MASTER.md` — company governance,
  including Founder Gate, cross-department event, model/tool/cost/audit and
  system-guard contracts.

The previous Marketing knowledge pack, Teams 1–5, `WF-01..08`,
`CEFFLO - 00..12,99`, their reconciliation addenda and
`automation/n8n/content-engine/**` are **LEGACY MIGRATION SOURCE / REPLACEMENT
CANDIDATE**. They are excluded from normal Marketing runtime retrieval. Existing
workflows, schemas, data and credentials remain untouched pending replacement
validation and a later Founder decision.

## 7. Marketing Performance

Marketing performance truth must come from verified operational records and
the canonical Marketing context/memory contracts. Legacy memory tables and
reports are migration evidence only until reconciled. Do not invent performance,
winner or learning data.

## 8. Brand Assets
**Brand Brain (D-68):** `docs/cefflo/sot/05_BRAND_BRAIN.md` is the single current canonical Brand Brain (positioning, story, voice, marketing doctrine). `docs/cefflo/CEFFLO_BRAND_BRAIN.md` is historical only.
**Updated 2026-09-12 (Founder baseline closeout, D-30):** logo and Signal Lime are now Founder-locked.
**Updated 2026-09-11 (Experience System canonicalization, D-33):** Signal Lime's primary/signature-colour status is **superseded** — see below. Logo lock from D-30 is unaffected.
Primary:
- `docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md` — **CANONICAL, current palette/typography/surface-system authority.** CEFFLO Yellow `#FEC819` is the current locked primary/signature accent.
- `docs/cefflo/sot/06_BRAND_ASSETS_GOVERNANCE.md` — logo governance remains current here; §2's palette section is historical as of D-33 (annotated in place, not deleted).
- current Brand System — **logo LOCKED** (geometry: D-30, unaffected by D-33; production asset set updated to CEFFLO Yellow/Navy under D-35 — `docs/cefflo/brand/assets/logo/cefflo-logo-icon-navy.png`, see governance file §5); **Signal Lime RETIRED** as primary colour (was locked at `#C7F000` under D-30; superseded by CEFFLO Yellow `#FEC819` under D-33 — see `12_EXPERIENCE_SYSTEM.md` §1).
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

## 11. AI Governance and Development Agent Rules
Company governance authority:
- `docs/cefflo/control/CEFFLO_CONTROL_LAYER_MASTER.md`
- `docs/cefflo/control/CEFFLO_AI_COMPANY_OPERATING_PRINCIPLES.md` (CANONICAL
  operating principles — complements the Control Layer Master, does not
  replace it; D-67)

Development collaboration rules:
Primary:
- `docs/cefflo/agent-os/CEFFLO_AGENT_OS_CORE.md`
- `docs/cefflo/agent-os/CHATGPT_OPERATING.md`
- `docs/cefflo/agent-os/CLAUDE_OPERATING.md`
- `docs/cefflo/agent-os/CODEX_OPERATING.md`
- `docs/CODEX_WORKING_RULES.md` (repo-root `docs/`, not `docs/cefflo/`)
- `docs/cefflo/engineering/CEFFLO_ENGINEERING_MASTER.md` (Engineering Department roles, orchestration, gates and evidence)
- `docs/cefflo/security/CEFFLO_CYBER_SECURITY_MASTER.md` (security boundaries for agents, tools, credentials and Crown Jewels)

Development agent rules govern how repository work is performed; they do not
override Product Truth, department masters, the Control Layer Master, or Founder
decisions. The Control Layer is governance architecture, not a sixth department.
Jev is recorded only as **CANDIDATE JUDGMENT ENGINE — NOT QUALIFIED / NOT
REQUIRED / NO ACTIVE DEPENDENCY**.

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
- `docs/cefflo/sot/09_VENDOR_FLUTTER_60_SCREEN_MASTER.md` remains "Founder Review Required" while its DEV/STAGING implementation is integrated and awaits UI lock. Subscription/billing V-50–V-54 are HOLD and excluded from active routes pending separate Founder approval; V-41 Delivery Settings still needs reconciliation against Service Area/Zones (domain 1 above).
- `docs/cefflo/sot/marketing/07_MARKETING_MEMORY.md` exists but its performance memory is intentionally empty — no AI Marketing Engine implementation or real campaign data exists yet (domain 6/7 above).
- `docs/cefflo/sot/13_DRIVER_FLUTTER_42_SCREEN_MASTER.md` (active master as of 2026-09-14, D-37, superseding `08_RIDER_FLUTTER_33_SCREEN_MASTER.md`) remains a "WORKING MASTER BASELINE" — not yet Founder-locked, not yet implemented; the current live Rider client is the PWA at `docs/cefflo/07_RIDER.md`.

See `docs/cefflo/05_DECISIONS.md` D-23 and D-24 for the full reconciliation record.

## 17. CEFFLO Website (added 2026-09-12, Founder baseline closeout — D-30)
Primary:
- `docs/cefflo/sot/11_CEFFLO_WEBSITE.md` — the fifth canonical product surface (§0 above / `02_ARCHITECTURE.md` §0). Public Web, acquisition/commercial surface only, not operational.
- `docs/cefflo/website/CEFFLO_PUBLIC_WEBSITE_MASTER.md` — ACTIVE MASTER, the single maintained Public Website master (visual direction + commercial/product-truth rules; incorporates Visual Spec V2 Final; D-67). Does not by itself approve publication.
- `docs/cefflo/website/reports/CEFFLO_PUBLIC_WEBSITE_POLISH_REPORT.md` — HISTORICAL report / input to the Master; not Product Truth.
- current implementation: none published (D-62, Public Website NOT IMPLEMENTED); held draft in `docs/cefflo/website/drafts/` (NOT APPROVED).

This closes the gap originally flagged when the five-canonical-product-surface architecture was frozen (2026-09-12, D-29).

## 18. Strategy (FUTURE — added 2026-09-26, D-67)
- `docs/cefflo/strategy/CEFFLO_RIDER_NETWORK_STRATEGY.md` — FUTURE: Founder-approved direction (Rider Hub, portable rider identity, capacity network). Not current scope; design-now/build-later, gated by production stability and real usage.
