**Status:** CANONICAL — Founder-approved, merged into repo 2026-09-04
**Repo-reconciliation note:** Net-new marketing knowledge domain; no prior equivalent existed in this repo (`marketing/` previously contained only the built website, no knowledge docs). Canonical hierarchy items 1-2 below are resolved to repo paths rather than duplicated, to avoid a duplicate-SOT violation.
**Reconciliation update (2026-09-10):** item 9 added — `08_AI_CONTENT_ENGINE_ORCHESTRATOR.md` (Founder-approved v1.1 n8n orchestration blueprint). The volume/ceiling figure below is corrected to match its Meta-shared-by-default lane model. See `docs/cefflo/05_DECISIONS.md` D-25 and `docs/cefflo/audits/CEFFLO_AI_CONTENT_ENGINE_V1.1_RECONCILIATION_REPORT.md`.
**Reconciliation update (2026-09-10, second pass):** items 11–12 added — `09_CONTENT_WORLD_PRODUCTION_DOCTRINE.md` and `10_BRAND_VOICE_LANGUAGE_SYSTEM.md` (FG-1 reconciled, further Founder gates FG-2/FG-V1–V4 not yet granted). See `docs/cefflo/05_DECISIONS.md` D-26 and `docs/cefflo/audits/CEFFLO_CONTENT_WORLD_DOCTRINE_RECONCILIATION_REPORT.md`.

---

# CEFFLO — MARKETING KNOWLEDGE PACK INDEX
**Version:** 2026-09-04

## Canonical hierarchy
1. `docs/cefflo/sot/01_PRODUCT_TRUTH.md` (was: CEFFLO_PRODUCT_TRUTH.md)
2. `docs/cefflo/sot/05_BRAND_BRAIN.md` (was: CEFFLO_BRAND_BRAIN / current canonical Brand Brain)
3. `docs/cefflo/sot/marketing/07_MARKETING_MEMORY.md` (was: CEFFLO_MARKETING_MEMORY.md) — schema initialized 2026-09-04; performance memory intentionally EMPTY until real evidence is collected.
4. `docs/cefflo/sot/marketing/01_AUDIENCE_ICP.md` (was: 04_CEFFLO_AUDIENCE_ICP.md)
5. `docs/cefflo/sot/marketing/02_CLAIMS_REGISTRY.md` (was: 05_CEFFLO_CLAIMS_REGISTRY.md)
6. `docs/cefflo/sot/marketing/03_CONTENT_PHILOSOPHY.md` (was: 06_CEFFLO_CONTENT_PHILOSOPHY.md)
7. `docs/cefflo/sot/marketing/04_CREATIVE_PLAYBOOK.md` (was: 07_CEFFLO_CREATIVE_PLAYBOOK.md)
8. `docs/cefflo/sot/marketing/05_PAID_GROWTH_PLAYBOOK.md` (was: 08_CEFFLO_PAID_GROWTH_PLAYBOOK.md)
9. `docs/cefflo/sot/marketing/06_AI_MARKETING_ENGINE_MASTER.md` (was: CEFFLO_AI_MARKETING_ENGINE_MASTER.md)
10. `docs/cefflo/sot/marketing/08_AI_CONTENT_ENGINE_ORCHESTRATOR.md` — Founder-approved v1.1 (2026-09-10), the concrete n8n orchestration blueprint implementing item 9's Teams 1-4. Item 9 remains the full-program charter (governance, testing, cost, Team 5/Paid Growth); item 10 is its daily-pipeline architecture layer, not a replacement.
11. `docs/cefflo/sot/marketing/09_CONTENT_WORLD_PRODUCTION_DOCTRINE.md` — Founder-approved FG-1 reconciliation 2026-09-10 (`docs/cefflo/05_DECISIONS.md` D-26). Content-world/scenario/production doctrine for video-led content. **FG-2 (Content World Baseline) is not yet granted** — no structured Content World/Operational Pain/Scenario data exists yet.
12. `docs/cefflo/sot/marketing/10_BRAND_VOICE_LANGUAGE_SYSTEM.md` — Founder-approved FG-1-equivalent reconciliation 2026-09-10 (`docs/cefflo/05_DECISIONS.md` D-26). Brand voice and native Malaysian Malay language doctrine. **FG-V1–FG-V4 are not yet granted** — this doctrine does not yet drive any live content generation.
13. `docs/cefflo/sot/marketing/11_CREATIVE_INTELLIGENCE_LAYER.md` — reconciled and implemented 2026-09-11 (`docs/cefflo/05_DECISIONS.md` D-27). Business/vehicle/scenario taxonomy, scenario contract, scenario engine and validator (code, tested). Operationalizes item 11's Phase B. **GATE B (Rider vs Driver terminology) RESOLVED and closed** — product/schema role stays "Rider" everywhere; Creative Intelligence display terms are vehicle-contextual (Motorcycle=Rider, Car/Van=Driver, mixed fleet=Delivery Team). No n8n workflow activated; no database migration applied.

## Authority
Founder decision wins. Product Truth controls capability reality. Brand Brain controls identity/expression. Marketing Memory stores evidence, not doctrine. Specialist knowledge documents operate within those boundaries.

## Reconciliation
The older CEFFLO_CONTENT_ENGINE_MASTER.md contains valuable content libraries and principles but its volume doctrine of 3/day, 21/week, up to 84 adaptations is superseded.

Current canonical Marketing Engine volume:
**5 core experiments/day → ~35/week → theoretical ceiling ~105 platform-native outputs/week** (three default lanes — Meta [Instagram + Facebook shared], TikTok, Threads — per `08_AI_CONTENT_ENGINE_ORCHESTRATOR.md` §3/§10; ~140 assumed four independent lanes and is superseded 2026-09-10, see D-25).

Do not mass-delete historical documents. Mark/reconcile them so they cannot silently override current doctrine.

## Next implementation artifact
After this Knowledge Pack is accepted/reconciled into the repository, create/execute the n8n implementation plan against `docs/cefflo/sot/marketing/06_AI_MARKETING_ENGINE_MASTER.md`. Do not let individual agents invent missing doctrine.

## Repo state as of this reconciliation (2026-09-04)
No n8n workflows, `marketing_experiments`/`marketing_assets`/`marketing_posts`/`marketing_metrics`/`marketing_learnings`/`marketing_paid_campaigns`/`marketing_cost_ledger` tables, or any part of the AI Marketing Engine implementation exist in this repository yet. `marketing/index.html` is the built public website only, unrelated to this knowledge domain. This index and its five linked playbooks are the target specification, not evidence of implementation.
