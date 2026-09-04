**Status:** CANONICAL — Founder-approved, merged into repo 2026-09-04
**Repo-reconciliation note:** This is the current canonical Founder-approved knowledge-base root. It supersedes `docs/cefflo/CEFFLO_BRAND_BRAIN.md` for brand/product/architecture doctrine and extends the same "newer canonical layer above the numbered pack" pattern already established by `docs/cefflo/00_AGENTS.md`. Each domain below is resolved to its actual repo path (or flagged as a genuine gap) rather than left as a bare filename placeholder.

---

# CEFFLO — KNOWLEDGE BASE MASTER INDEX
**Version:** 1.0 — 2026-09-04
**Purpose:** Top-level map of Cefflo canonical knowledge domains.

## 1. Vendor Flutter
Primary:
- `docs/cefflo/sot/09_VENDOR_FLUTTER_60_SCREEN_MASTER.md` — status: WORKING MASTER BASELINE, "Founder Review Required," NOT YET IMPLEMENTED. Subscription/billing screens V-50–V-54 remain HOLD; V-41 Delivery Settings remains RECONCILIATION REQUIRED.
- approved Design Lab/DNA outputs when locked — none exist yet.

Authority:
Product Truth → Architecture → Flow 3 Behavioural Contract → approved Visual DNA → Flutter implementation.

Reference: `docs/cefflo/flow3/VENDOR_BEHAVIOURAL_CONTRACT_PACK.md` (the Flow 3 Vendor Web exit contract Flow 4 must build against). The current LIVE Vendor client remains Vendor Web/Desktop (`docs/cefflo/06_VENDOR.md`) — this master does not authorize starting Flutter implementation.

## 2. Rider Flutter
Primary:
- `docs/cefflo/sot/08_RIDER_FLUTTER_33_SCREEN_MASTER.md` — status: ACTIVE MASTER, "Founder Review Required," NOT YET IMPLEMENTED.
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

## 7. Marketing Performance
Runtime evidence only:
- Marketing Memory schema exists (`docs/cefflo/sot/marketing/07_MARKETING_MEMORY.md`) but its data/exports are empty — no experiments have run yet.
- weekly reports — none exist yet.
- experiment performance — none exist yet.
- organic/paid learnings — none exist yet.

Do not store invented winner data here. This domain is N/A until real campaign data exists — no AI Marketing Engine implementation exists in this repo yet (see `docs/cefflo/sot/marketing/00_MARKETING_KNOWLEDGE_PACK_INDEX.md`).

## 8. Brand Assets
Primary:
- `docs/cefflo/sot/06_BRAND_ASSETS_GOVERNANCE.md`
- current Brand System — no logo is Founder-locked yet (see governance file §5).
- locked logo/color/type/icon assets — none locked yet.
- exploration archive clearly separated — see `previews/cefflo-logo-identity-exploration/` (untracked, exploration only).
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
