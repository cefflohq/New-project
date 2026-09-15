**Status:** CANONICAL — Founder-approved, merged into repo 2026-09-10
**Repo-reconciliation note:** This is the n8n orchestration/architecture blueprint for the daily content-production pipeline described at a charter level in `06_AI_MARKETING_ENGINE_MASTER.md`. It does not replace that document — it implements Teams 1–4 of it as a concrete workflow family. Team 5 (Paid Growth) and the weekly winner-selection loop are preserved and given explicit architectural placement in the **Repo Reconciliation Addendum** at the end of this file, per Founder Decision Gate approval 2026-09-10 (see `docs/cefflo/05_DECISIONS.md` D-25). The body below (§0–§25) is the Founder-approved source text, reproduced as supplied and unedited; all reconciliation additions are isolated in the clearly marked addendum so the original Founder text stays traceable. See also `docs/cefflo/audits/CEFFLO_AI_CONTENT_ENGINE_V1.1_RECONCILIATION_REPORT.md` for the full reconciliation analysis this file and D-25 are based on.

---

# CEFFLO AI CONTENT ENGINE --- MASTER ORCHESTRATOR SOT

**Status:** FINAL ARCHITECTURE BASELINE\
**Version:** v1.1 FINAL\
**Date:** 10 September 2026\
**Owner:** Founder, Cefflo\
**Purpose:** Canonical implementation blueprint for the Cefflo AI
Content Engine in n8n.

------------------------------------------------------------------------

## 0. LOCKED SYSTEM ROLES

-   **GitHub** = canonical/static Source of Truth (SOT): Product Truth,
    Brand Brain, Audience & Market Truth, Content Philosophy,
    campaign/rule documents.
-   **PostgreSQL** = dynamic operational state + Marketing Memory +
    performance history.
-   **n8n** = central orchestrator: trigger, retrieval, routing, state,
    retries, approvals, publishing coordination, analytics loop.
-   **LLMs / AI workers** = research, reasoning, concepts, scripts/copy,
    platform adaptation, QA assistance.
-   **Image / video models** = media production only when the concept
    requires generated media.
-   **Founder** = final approval authority during V1.

Full SOT documents remain intact. They are **not shortened merely to
save tokens**. Runtime uses retrieval to supply only relevant sections
to each task.

------------------------------------------------------------------------

# 1. FINAL HIGH-LEVEL FLOW

``` text
GITHUB — FULL CEFFLO SOT
            ↓
01 TRIGGER / DAILY CONFIG
            ↓
02 RETRIEVE RELEVANT SOT
            ↓
03 RESEARCH & ANGLE MINER
            ↓
04 MASTER CONCEPT BUILDER
            ↓
05 CREATIVE ROUTER
       ┌────┼──────┐
       ↓    ↓      ↓
     META  TIKTOK THREADS
       │    │      │
       └────┼──────┘
            ↓
06 AI QA
       ↓ FAIL → TARGETED REVISION → failed lane only
       ↓ PASS
07 FOUNDER APPROVAL
   ├─ APPROVE
   ├─ REVISE → targeted revision
   ├─ REJECT
   └─ HOLD
       ↓ APPROVE
08 PUBLISH
   ├─ Instagram
   ├─ Facebook
   ├─ TikTok
   └─ Threads
       ↓
09 ANALYTICS & PERFORMANCE SCORING
       ↓
10 MARKETING MEMORY — POSTGRES
       ↺
NEXT RESEARCH CYCLE
```

------------------------------------------------------------------------

# 2. WHY RESEARCH AND MASTER CONCEPT STAY SEPARATE

These are intentionally separate stages. They are **not duplicate AI
work**.

## 03 Research & Angle Miner

Answers:

> **What should Cefflo talk about?**

Responsibilities: - research useful/current topics when required -
identify audience pains/desires - find angles and hooks - compare
against Marketing Memory - avoid recent duplication - rank
opportunities - produce candidate angles

It must **not** jump straight into final platform content.

## 04 Master Concept Builder

Answers:

> **What exactly is Cefflo going to say about the selected angle?**

Responsibilities: - convert selected angle into a coherent Cefflo
concept - establish core message - establish Cefflo relevance - identify
truth/proof basis - establish CTA - establish creative direction -
establish allowed/prohibited claims - provide the common concept used by
all platform lanes

This separation creates a quality/control boundary between **idea
discovery** and **message construction**.

Do not merge these stages solely to save one model call unless later
measured evidence shows no meaningful quality/control loss.

------------------------------------------------------------------------

# 3. DAILY OUTPUT MODEL

Initial operating target:

**3--5 Master Concepts per day.**

This is configurable, not hard-coded.

For 5 Master Concepts:

``` text
5 Master Concepts
      ↓
5 Meta packages      → Instagram + Facebook
5 TikTok packages    → TikTok
5 Threads packages   → Threads
```

Instagram and Facebook **do not require two separately generated
creative packages by default**.

One Meta package may publish to both destinations.

The system therefore optimizes production while maintaining active
coverage on:

-   Instagram
-   Facebook
-   TikTok
-   Threads

------------------------------------------------------------------------

# 4. TOKEN / MODEL CALL STRATEGY

The goal is **not minimum calls at any cost**.

The goal is:

> Minimum unnecessary calls while preserving quality, control,
> recoverability, and sharp output.

## Recommended V1 call pattern

### Daily/batch level

Research & Angle Miner may generate/rank multiple candidate angles in
**one structured call** where practical.

Example:

``` text
1 Research call
→ candidate pool
→ rank/select 3–5 angles
```

### Concept level

Each selected angle can receive a Master Concept call where quality
requires it.

For 5 concepts:

``` text
up to 5 Master Concept calls
```

Batching may later be tested, but only after quality comparison.

### Creative level

For each approved Master Concept:

``` text
1 Meta creative intelligence call
1 TikTok creative intelligence call
1 Threads creative intelligence call
```

These calls produce structured creative instructions/copy/scripts.

They do **not automatically mean three expensive media generations**.

### Media generation

Image/video generation happens only after the creative plan determines
that media is needed.

Do not regenerate the same usable media separately for Instagram and
Facebook.

## Cost controls

1.  Retrieve relevant SOT sections only.
2.  Never inject the whole implementation MD into creative calls.
3.  Reuse stable context where safe.
4.  Use structured JSON outputs.
5.  Retry only the failed stage/lane.
6.  Do not regenerate passed Meta output because TikTok failed.
7.  Do not regenerate creative intelligence when only publishing failed.
8.  Use cheaper capable models for classification/routing where quality
    is unaffected.
9.  Use stronger models for research/concept/creative tasks where
    quality materially matters.
10. Record token/cost metadata later so actual cost can be optimized
    from evidence.

------------------------------------------------------------------------

# 5. 01 --- TRIGGER / DAILY CONFIG

Inputs:

``` text
run_id
date
campaign_id
concepts_required = 3–5 default
objective
market
language
content_focus
priority
approval_mode = founder_required
```

Initial trigger: - Manual Trigger for testing.

Later: - Schedule Trigger for daily operation.

Do not automate daily publishing until the complete manual path is
stable.

------------------------------------------------------------------------

# 6. 02 --- SOT RETRIEVAL

Canonical documents live in GitHub.

Example truth domains:

``` text
Product Truth
Brand Brain
Audience & Market Truth
Content Philosophy
Marketing Rules
Campaign documents
```

The retrieval layer does **not** blindly pass all files downstream.

It produces a runtime **Context Pack** containing only relevant source
sections.

Minimum Context Pack:

``` text
task_id
campaign_id
objective
target_audience
product_truth_context
brand_context
audience_context
content_rules
claim_guardrails
marketing_memory_context
source_references
```

Important:

**Retrieval is not summarization of the whole SOT.**

It is selection of relevant authoritative sections.

------------------------------------------------------------------------

# 7. 03 --- RESEARCH & ANGLE MINER

Inputs: - campaign/daily configuration - relevant SOT Context Pack -
Marketing Memory - optional current research/trends

Outputs:

``` text
angle_id
topic
target_audience
pain_or_desire
angle
hook_direction
why_it_matters
content_pillar
source_basis
duplication_score
priority_score
```

Requirements: - produce enough candidates to select 3--5 strong
concepts - flag unsupported ideas - avoid repeating recent angles/hooks
unnecessarily - prioritize concrete operational pain over generic
marketing language when appropriate

Current/public research is used only when the content task needs it.

------------------------------------------------------------------------

# 8. 04 --- MASTER CONCEPT BUILDER

For each selected angle, output:

``` text
master_concept_id
angle_id
core_message
problem
insight
Cefflo_relevance
truth_basis
desired_audience_action
hook_direction
CTA
creative_direction
allowed_claims
prohibited_claims
source_references
```

The Master Concept is platform-independent.

It is the shared truth/message foundation for Meta, TikTok, and Threads.

> **Repo reconciliation note (Decision 3, 2026-09-10):** `master_concept_id`
> is the same persisted entity as the existing Marketing Memory "core
> experiment" (`CEFFLO-YYYY-Wxx-E###`, see `07_MARKETING_MEMORY.md` §5 and
> `06_AI_MARKETING_ENGINE_MASTER.md` §13). `angle_id` is an internal working
> identifier scoped to the Research & Angle Miner stage; it is tracked as a
> taxonomy dimension (`07_MARKETING_MEMORY.md` §6, §9), not as a separate
> persisted top-level lineage ID. See Addendum A2 below for the full mapping.

------------------------------------------------------------------------

# 9. 05 --- CREATIVE ROUTER

Each Master Concept is routed into **three production lanes**:

``` text
                MASTER CONCEPT
                     ↓
          ┌──────────┼──────────┐
          ↓          ↓          ↓
        META       TIKTOK     THREADS
```

These are platform execution lanes, not three unrelated ideas.

------------------------------------------------------------------------

# 10. META LANE --- IG + FACEBOOK

Meta is one production lane.

Default:

``` text
ONE META ASSET/PACKAGE
        ├→ Instagram
        └→ Facebook
```

Expected creative package:

``` text
master_concept_id
format
hook
script_or_copy
scene_plan
on_screen_text
visual_direction
caption
CTA
metadata
duration
aspect_ratio
```

Possible formats: - Reel - static image/poster - carousel - product
demo - screen recording - other approved Meta format

For Reels, default target: - vertical 9:16 - strong opening - concise -
usable on both IG Reels and Facebook Reels

If a real platform constraint requires adaptation, adapt only the
necessary element rather than regenerating the entire asset.

> **Repo reconciliation note (Decision 1, 2026-09-10):** this Meta-shared
> default is the canonical daily publishing lane model repo-wide. It
> supersedes-in-detail the older "TikTok / Instagram / Facebook / Threads =
> 4 independent lanes" framing in `03_CONTENT_PHILOSOPHY.md` and
> `06_AI_MARKETING_ENGINE_MASTER.md` (both corrected to match). See
> Addendum A3 below.

------------------------------------------------------------------------

# 11. TIKTOK LANE

TikTok remains an independent creative execution lane.

Expected package:

``` text
master_concept_id
format
hook
first_2_seconds
script
scene_plan
on_screen_text
visual_direction
caption
CTA
platform_notes
duration
```

TikTok may share the same underlying Master Concept while using: -
different hook - different pacing - different scene treatment -
different copy/caption - different creator/UGC style

However:

**Independent does not mean wasteful.**

If a Meta video genuinely works natively on TikTok and passes TikTok QA,
reuse is allowed.

------------------------------------------------------------------------

# 12. THREADS LANE

Threads is mandatory platform coverage.

Expected package:

``` text
master_concept_id
opening_line
body
conversation_angle
CTA_or_question
optional_followup_posts
optional_media_reference
```

Do not merely paste an Instagram caption into Threads.

The idea remains shared; the writing becomes text-native.

------------------------------------------------------------------------

# 13. MEDIA GENERATION --- WHO DOES WHAT

Do not treat an LLM and an image/video model as the same job.

## LLM / Creative AI

Produces: - concept reasoning - script - caption - copy - shot/scene
plan - visual direction - image prompt - video prompt - platform
adaptation

## Image generator

Produces: - poster/static visual - campaign image - approved generated
visual assets

## Video generator

Produces: - generated video/B-roll/UGC-style assets where selected

## Product-real asset lane

Where possible, use real: - Cefflo UI - screen recordings - product
demonstrations - actual approved brand assets

Do not generate fake product UI or fake evidence when real product
assets are required.

Media provider is **not permanently locked in this architecture**. The
provider can be selected based on quality, cost, API availability, and
format.

------------------------------------------------------------------------

# 14. 06 --- AI QA GATE

AI QA and Founder Approval are separate gates.

AI QA checks:

### Truth

-   supported by SOT?
-   invented feature?
-   planned feature presented as live?
-   fake statistic/testimonial/proof?

### Brand

-   correct positioning?
-   Cefflo terminology?
-   too generic?
-   overclaiming?
-   on-brand tone?

### Creative

-   clear hook?
-   understandable message?
-   strong enough?
-   correct platform format?
-   repetitive?

### Duplication

-   same recent hook?
-   same angle?
-   same structure?
-   same visual treatment overused?

Output:

``` text
qa_status = PASS | REVISE | REJECT
qa_score
failed_rules
qa_feedback
revision_target
```

### REVISE

Return only to the affected stage/lane.

Example:

``` text
TikTok fails hook quality
→ revise TikTok only
→ do not regenerate Meta/Threads/Master Concept
```

### REJECT

Use when the concept is fundamentally unsuitable or unsupported.

> **Repo reconciliation note:** this stage is the workflow-level
> enforcement point for `02_CLAIMS_REGISTRY.md`'s GREEN/AMBER/RED gate,
> `03_CONTENT_PHILOSOPHY.md` §18 Content QA (Q1–Q12), and
> `04_CREATIVE_PLAYBOOK.md` §16 Creative QA (C1–C13). This section does not
> replace those rule sets — it is where they are applied.

------------------------------------------------------------------------

# 15. 07 --- FOUNDER APPROVAL

Only AI-QA-passed content reaches Founder Review.

Founder sees: - Master Concept - Meta output - TikTok output - Threads
output - media preview - captions/copy - QA status - planned
destinations/timing

Founder decisions:

``` text
APPROVE
REVISE
REJECT
HOLD
```

Founder revision feedback routes to the exact affected stage where
possible.

Founder feedback is stored in Marketing Memory.

V1 rule:

**No production publishing without Founder approval.**

------------------------------------------------------------------------

# 16. 08 --- PUBLISHING

Publishing is a downstream action. It must not alter creative truth.

Destinations: - Instagram - Facebook - TikTok - Threads

Meta efficiency:

``` text
Approved Meta package
     ├→ Instagram
     └→ Facebook
```

Do not assume every cross-posting behavior exists automatically. The
exact API/integration behavior must be verified during implementation.

Publishing record:

``` text
content_id
master_concept_id
platform
asset_id
campaign_id
scheduled_time
published_time
publish_status
external_post_id
error_code
```

If publishing fails: - keep approved asset - retry publishing only - do
not regenerate content

------------------------------------------------------------------------

# 17. 09 --- ANALYTICS & PERFORMANCE SCORING

Collect available platform metrics after configured windows.

Potential metrics: - views - reach - watch time - completion - likes -
comments - shares - saves - profile actions - clicks/actions -
platform-specific metrics

Performance must be evaluated relative to: - platform - format -
objective - content age - historical Cefflo baseline

Do not use one simplistic score across every platform.

------------------------------------------------------------------------

# 18. 10 --- MARKETING MEMORY

Marketing Memory lives primarily in PostgreSQL as structured dynamic
data.

Store:

``` text
master_concept_id
angle
hook
audience
content_pillar
platform
format
creative_direction
publish_date
performance
qa_feedback
founder_feedback
winner_or_loser
lessons
reuse_recommendation
```

Marketing Memory informs the next Research & Angle cycle.

It **cannot overwrite canonical Product Truth or Brand Truth**.

Example loop:

``` text
Analytics:
Operational pain hook performs strongly.

Memory:
Record pattern + context.

Next Research:
Increase priority for similar concrete pain angles,
while avoiding exact duplication.
```

> **Repo reconciliation note:** this is the minimum field set for the V1
> vertical slice. `07_MARKETING_MEMORY.md` remains the full canonical
> Marketing Memory schema (Experiment/Asset/Publication/Performance/
> Qualitative/Learning/Paid/Cost Memory, confidence levels, funnel memory,
> winner types, anti-contamination rules, attribution chain) and is
> unaffected by this document.

------------------------------------------------------------------------

# 19. FAILURE / RETRY MATRIX

  Failure                      Correct action
  ---------------------------- -----------------------------------------
  GitHub/SOT unavailable       Stop generation; retry retrieval
  Required truth missing       Flag for review; do not invent
  Research AI fails            Retry Research only
  Master Concept fails         Retry that concept only
  Meta generation fails        Retry Meta lane only
  TikTok generation fails      Retry TikTok lane only
  Threads generation fails     Retry Threads lane only
  QA says revise               Return to named failed stage/lane
  Founder requests revision    Return to named stage/lane
  Image/video provider fails   Retry/switch media generation only
  Publish API fails            Retry publish only
  Analytics unavailable        Retry analytics later
  AI/API has no credit         Set WAITING_AI; preserve workflow state

Configurable maximum retry count prevents infinite loops.

------------------------------------------------------------------------

# 20. WORKFLOW STATE

Recommended states:

``` text
NEW
CONTEXT_READY
RESEARCHING
ANGLES_READY
CONCEPT_BUILDING
CONCEPT_READY
CREATIVE_GENERATING
QA_PENDING
REVISION_REQUIRED
FOUNDER_REVIEW
APPROVED
REJECTED
HOLD
SCHEDULED
PUBLISHING
PUBLISHED
ANALYTICS_PENDING
ANALYZED
ARCHIVED
WAITING_AI
ERROR
```

Every item should preserve IDs, timestamps, source references, retry
count, and error reason.

------------------------------------------------------------------------

# 21. N8N PRODUCTION WORKFLOW FAMILY

Do not build the production engine as one giant canvas.

Recommended:

``` text
CEFFLO - 00 - Master Orchestrator
CEFFLO - 01 - SOT Retrieval
CEFFLO - 02 - Research & Angle Miner
CEFFLO - 03 - Master Concept Builder
CEFFLO - 04 - Creative Router
CEFFLO - 05A - Meta Creator
CEFFLO - 05B - TikTok Creator
CEFFLO - 05C - Threads Writer
CEFFLO - 06 - AI QA
CEFFLO - 07 - Founder Approval
CEFFLO - 08 - Publisher
CEFFLO - 09 - Analytics & Scoring
CEFFLO - 10 - Marketing Memory
CEFFLO - 99 - Error & Recovery
```

The current small workflow remains:

`CEFFLO - 00 - Orchestrator Test`

Purpose: - learning - credentials - basic routing - AI connectivity -
smoke testing

Do not delete it and do not turn it into the entire production factory.

> **Repo reconciliation note (Decision 2 & 4, 2026-09-10):** this list
> covers the **daily** chain only. The weekly-cadence Weekly Winner Engine
> and Paid Growth workflows (`CEFFLO - 11` and `CEFFLO - 12`) are preserved
> and given explicit placement in Addendum A1 below — they are not part of
> the daily 00–10/99 chain. This naming also supersedes-in-detail the older
> `WF-01`..`WF-08` naming in `06_AI_MARKETING_ENGINE_MASTER.md` §8 (see
> Addendum A4). The repo-tracking policy for `CEFFLO - 00 - Orchestrator
> Test` and any future n8n workflow exports is explicitly **deferred** —
> see Addendum A5.

------------------------------------------------------------------------

# 22. BUILD ORDER --- FINAL

## Phase A --- Source foundation

1.  Confirm canonical GitHub SOT files.
2.  Remove/mark competing outdated SOT versions.
3.  Define file/version references.

**Gate:** Founder confirms canonical truth set.

## Phase B --- Retrieval

Build `01 - SOT Retrieval`.

Test: One marketing task must return the correct relevant source
sections.

**Gate:** no missing/irrelevant context severe enough to weaken output.

## Phase C --- Research

Build `02 - Research & Angle Miner`.

Test: Generate candidate pool and select strong, non-duplicate angles.

## Phase D --- Master Concept

Build `03 - Master Concept Builder`.

Test: Each selected angle becomes a source-grounded concept with truth
basis and guardrails.

## Phase E --- Creative lanes

Build: - 05A Meta - 05B TikTok - 05C Threads

Test: One Master Concept produces all three required platform packages.

## Phase F --- QA

Build AI QA + targeted revision routing.

Test: Inject deliberately bad claims and confirm rejection/revision.

## Phase G --- Founder Approval

Build review/approval state.

Test: APPROVE, REVISE, REJECT, HOLD.

## Phase H --- Publish

Connect platform integrations.

Test one approved concept first.

## Phase I --- Analytics

Collect performance.

## Phase J --- Marketing Memory

Store learnings and retrieve them in next Research cycle.

## Phase K --- Daily automation

Only after the full manual path passes: - schedule - 3--5 concepts/day -
publishing windows - retry schedules

------------------------------------------------------------------------

# 23. FINAL ACCEPTANCE TEST --- ONE CONCEPT

Before scaling to 3--5/day, run one concept end-to-end.

Must prove:

``` text
Trigger
✓

GitHub relevant SOT retrieval
✓

Research angle
✓

Master Concept
✓

Meta package
✓

TikTok package
✓

Threads package
✓

AI QA
✓

Founder approval
✓

Publish
✓

Analytics record
✓

Marketing Memory update
✓
```

Only then scale volume.

------------------------------------------------------------------------

# 24. DEFINITION OF DONE --- V1

V1 is complete when one orchestrated run can:

1.  Receive daily/campaign configuration.
2.  Retrieve relevant canonical Cefflo truth from GitHub.
3.  Use Marketing Memory from PostgreSQL.
4.  Research and rank content angles.
5.  Produce the configured number of Master Concepts.
6.  Generate one Meta package per concept for IG + Facebook.
7.  Generate one TikTok-native package per concept.
8.  Generate one Threads-native package per concept.
9.  Generate required media without duplicate unnecessary production.
10. QA all outputs.
11. Revise only failed lanes.
12. Present passed outputs to Founder.
13. Respect APPROVE / REVISE / REJECT / HOLD.
14. Publish approved outputs.
15. Preserve approved content if publishing fails.
16. Collect available analytics.
17. Score/store performance.
18. Store Founder feedback.
19. Feed relevant learnings into future Research cycles.
20. Never allow Marketing Memory or creative AI to override canonical
    Cefflo truth.

> **Repo reconciliation note:** this is the Definition of Done for the
> **V1 daily pipeline slice** specifically. `06_AI_MARKETING_ENGINE_MASTER.md`
> §33 remains the full-program Definition of Done (adds Team 5/paid growth,
> cost observability, and test/evidence requirements) — this DoD nests
> inside that one, matching this document's own Final Acceptance Test in
> §23 and `06_AI_MARKETING_ENGINE_MASTER.md` §25's MVP Implementation
> Principle.

------------------------------------------------------------------------

# 25. FINAL LOCK

The canonical V1 architecture is:

``` text
GitHub SOT
    ↓
Trigger / Daily Config
    ↓
Relevant SOT Retrieval
    ↓
Research & Angle Miner
    ↓
Master Concept Builder
    ↓
Creative Router
 ┌──────┼────────┐
 ↓      ↓        ↓
META  TIKTOK  THREADS
 ↓      ↓        ↓
 └──────┼────────┘
        ↓
      AI QA
   ↙ revise  ↓ pass
             ↓
      Founder Approval
   ↙ revise/reject/hold
             ↓ approve
          Publish
             ↓
     Analytics / Scoring
             ↓
     Marketing Memory
             ↺
       Next Research Cycle
```

**GitHub = Truth.**\
**PostgreSQL = Dynamic Memory.**\
**n8n = Orchestrator.**\
**AI = Workers.**\
**Founder = Final Gate.**

This architecture is the V1 baseline. Changes after this point should be
evidence-driven or explicitly Founder-approved, not casual
simplification.

**End --- v1.1 FINAL**

------------------------------------------------------------------------

# REPO RECONCILIATION ADDENDUM (added 2026-09-10, Founder Decision Gate approved — see `docs/cefflo/05_DECISIONS.md` D-25)

The sections above are the Founder-approved v1.1 source text, unedited. The items below are the reconciliation additions approved at the 2026-09-10 Founder Decision Gate, kept separate so the original text and the reconciliation layer are both independently traceable. Full analysis backing these decisions: `docs/cefflo/audits/CEFFLO_AI_CONTENT_ENGINE_V1.1_RECONCILIATION_REPORT.md`.

## A1. Weekly Workflow Extension — CEFFLO 11 & 12 (Decision 2)

v1.1's §21 workflow family (`CEFFLO - 00` through `10`, plus `99`) covers the **daily** content-production chain only. `06_AI_MARKETING_ENGINE_MASTER.md` §6 Weekly Winner Loop, §35 Final Target Operating Loop, and `05_PAID_GROWTH_PLAYBOOK.md` in full remain required and are preserved as two additional workflows, **not** spliced into the daily chain:

```text
CEFFLO - 11 - Weekly Winner Engine
CEFFLO - 12 - Paid Growth
```

- **Trigger:** weekly schedule, independent of the daily `00` trigger.
- **CEFFLO - 11** reads from `10 - Marketing Memory` (read-only input, does not write back into the daily chain's state machine). Selects approximately Top 5 per `06_AI_MARKETING_ENGINE_MASTER.md` §6 / `07_MARKETING_MEMORY.md` §8, and extracts angle/hook/audience/format learnings per `07_MARKETING_MEMORY.md` §9.
- **CEFFLO - 12** consumes `11`'s Top 5 output. Subject to the existing Founder/budget spend gate — `05_PAID_GROWTH_PLAYBOOK.md` §5: "No first launch or spend without Founder approval." This gate is unchanged by this reconciliation.
- **Dependency chain:** `10 → 11 → 12`, weekly cadence, layered after — not inside — the daily `00–10` chain. The daily chain's retry/idempotency model (§19 above) is not extended to 11/12; they define their own failure handling consistent with `06_AI_MARKETING_ENGINE_MASTER.md` §22.

## A2. Master Concept ↔ Core Experiment ID Mapping (Decision 3)

No new ID format is introduced. Mapping:

```text
Angle (angle_id)              → internal working ID, Research & Angle Miner stage only,
                                 not persisted as a top-level lineage ID; tracked as a
                                 taxonomy/tag dimension in Marketing Memory
                                 (07_MARKETING_MEMORY.md §6, §9)
                                        ↓ selected angle becomes:
Master Concept (master_concept_id) ≡ Core Experiment (CEFFLO-YYYY-Wxx-E###)
                                 — same persisted entity, same ID scheme,
                                 unchanged from 07_MARKETING_MEMORY.md §5
                                        ↓ produces:
Platform derivatives            → existing derivative-suffix system unchanged:
                                   -TT01, -IGR01, -FBR01, -TH01, etc.
```

`07_MARKETING_MEMORY.md` §5 (Experiment Identity) and `06_AI_MARKETING_ENGINE_MASTER.md` §13 (Content Identity & Attribution) are the canonical source for this ID/lineage scheme and are unchanged by this reconciliation.

## A3. Lane Model Confirmation (Decision 1)

The Meta-shared-by-default model in §3 and §10 above is confirmed as the canonical repo-wide daily publishing lane model: **3 default lanes** (Meta [IG+FB], TikTok, Threads), with IG/FB split permitted only for a genuine platform-fit reason (§10 above: "adapt only the necessary element"). Recalculated theoretical ceiling for the 5-concepts/day example: **5 × 3 = 15 packages/day → ~105/week**, not the previously-stated ~140/week. `03_CONTENT_PHILOSOPHY.md` §2, `06_AI_MARKETING_ENGINE_MASTER.md` §5, `07_MARKETING_MEMORY.md` §3, and `00_MARKETING_KNOWLEDGE_PACK_INDEX.md` have been corrected to this model as part of this same reconciliation pass; `04_CREATIVE_PLAYBOOK.md` §11 carries a clarifying addendum.

## A4. Workflow Naming Supersession (Decision 4)

`CEFFLO - 00` through `12`, plus `CEFFLO - 99 - Error & Recovery`, is now the one canonical n8n workflow family name/number referenced repo-wide. The older `WF-01`..`WF-08` naming in `06_AI_MARKETING_ENGINE_MASTER.md` §8 is marked superseded-in-detail there (not deleted) with an explicit mapping table to this naming. No n8n workflow exists in this repository yet, so this decision has zero implementation impact today — it fixes the naming that any future build must use.

## A5. n8n Repo-Tracking Policy — DEFERRED (Decision 6)

Whether `CEFFLO - 00 - Orchestrator Test` (referenced in §21 above) or any future n8n workflow JSON export should be version-controlled in this repository is **explicitly deferred** to the actual implementation/build gate (§22 Phase A above). This reconciliation pass does not create an `infra/n8n/` directory, does not introduce a workflow-export policy, and does not alter `docs/cefflo/12_SECURITY.md`'s existing secrets doctrine. Per `docs/cefflo/05_DECISIONS.md` D-23/D-24, no n8n workflows or `marketing_*` tables exist anywhere in this repository as of this reconciliation — `CEFFLO - 00 - Orchestrator Test`, if it exists, is n8n-instance-only state, not repository implementation truth. This note exists so the two are not confused.

## A6. Cross-References

- `docs/cefflo/sot/marketing/00_MARKETING_KNOWLEDGE_PACK_INDEX.md` — hierarchy item 9, points here.
- `docs/cefflo/sot/00_INDEX.md` §6 — Marketing Engine domain, points here.
- `docs/cefflo/sot/marketing/06_AI_MARKETING_ENGINE_MASTER.md` — charter-level document this file implements; §5, §8 corrected/annotated to match this file.
- `docs/cefflo/sot/marketing/07_MARKETING_MEMORY.md` — full canonical Marketing Memory schema; §3 corrected to match A3.
- `docs/cefflo/sot/marketing/03_CONTENT_PHILOSOPHY.md` — §2 corrected to match A3.
- `docs/cefflo/sot/marketing/04_CREATIVE_PLAYBOOK.md` — §11 carries the Meta-shared-default clarification.
- `docs/cefflo/sot/marketing/05_PAID_GROWTH_PLAYBOOK.md` — doctrine source for `CEFFLO - 12`.
- `docs/cefflo/05_DECISIONS.md` D-25 — Founder decision record for this reconciliation pass.
- `docs/cefflo/audits/CEFFLO_AI_CONTENT_ENGINE_V1.1_RECONCILIATION_REPORT.md` — full reconciliation analysis and Founder Decision Gate this addendum executes.
