# Marketing Department
## CEFFLO Marketing Department — Master Specification

**Document:** `MARKETING_AI_MARKETING_6_MASTER.md`  
**Status:** MASTER BASELINE  
**Date:** 2026-09-19  
**Owner:** Founder / CEFFLO  
**System:** Marketing Department  
**Control Plane:** n8n

---

## 0. Purpose

Marketing is CEFFLO's autonomous marketing squad.

Its purpose is to continuously discover real customer problems, convert those problems into platform-native content, produce high-quality creative, independently verify the output, publish approved content, measure actual performance, and feed evidence-backed learning into the next marketing cycle.

Marketing is not a blind content factory.

Canonical loop:

```text
Research → Hypothesis → Create → Produce → QA → Publish → Measure → Learn → Improve
```

Core objective:

> Build a reliable, traceable, cost-controlled marketing system that becomes more effective as CEFFLO accumulates real market and content-performance evidence.

---

# 1. Operating Principles

1. **Founder owns Product Truth and major marketing direction.**
2. **n8n is the deterministic control plane.**
3. **M1–M6 are specialized AI roles, not unrestricted autonomous actors.**
4. **Agents retrieve current truth; chat/model memory is not canonical truth.**
5. **Product Truth always outranks marketing performance.**
6. **Approved Brand Truth must be followed.**
7. **Research signals are evidence, not automatically canonical facts.**
8. **Content must sound and feel native to the intended audience and platform.**
9. **Avoid generic SaaS/AI marketing language.**
10. **A concept is not the same as a post. One concept may produce multiple platform variants.**
11. **Do not invoke every agent for every content item. Route conditionally.**
12. **M5 verification is independent.**
13. **No valid M5 PASS means no normal publication.**
14. **Any content modification after M5 PASS invalidates that PASS for the modified version.**
15. **Retries are bounded. Diagnose before escalating model cost.**
16. **Paid-media spending is gated separately from organic publishing.**
17. **Every meaningful action must be traceable to IDs, versions, evidence, cost, and state transitions.**
18. **Marketing may propose learning; it may not silently rewrite Product Truth or Brand Truth.**

---

# 2. Marketing Department

## M1 — LEAD
**Function:** Strategy and orchestration  
**Tagline:** Decide what we are trying to achieve.

Responsibilities:

- Interpret Founder objective.
- Retrieve relevant Product, Brand, Audience, Content World, Decision, Research, Experiment, and Performance context.
- Resolve campaign/content objective.
- Select target audience and problem.
- Define angle family and intended outcome.
- Create/version Creative Briefs.
- Define hypotheses and experiments when appropriate.
- Route work to M2, M3, M4, M5, and M6.
- Re-triage failures.
- Detect material ambiguity or canonical conflicts.
- Trigger Founder Gates when required.

M1 should not:

- Act as routine copywriter.
- Produce final media.
- Publish content.
- Spend advertising money.
- Modify canonical Product Truth or Brand Truth without authorization.
- Hold raw credentials.

Primary output: **Creative Brief**.

---

## M2 — RADAR
**Function:** Market and audience intelligence  
**Tagline:** Find what matters.

Responsibilities:

### External Radar
- Discover audience pain points.
- Research public discussions and communities.
- Research competitors and adjacent solutions.
- Identify recurring questions and objections.
- Identify relevant search/trend/content-format signals.
- Attach evidence and confidence to findings.

### Internal Radar
- Read CEFFLO content analytics where authorized.
- Identify recurring comments/questions.
- Detect emerging objections.
- Detect high-performing/low-performing subject areas.
- Feed evidence-backed signals into future planning.

M2 should:

```text
Search → Extract → Cluster → Deduplicate → Score → Store Signal
```

M2 should not:

- Convert one observation into canonical Audience Truth.
- Assume competitor capabilities are CEFFLO capabilities.
- Publish or publicly reply.
- Invent product claims.
- Spend money.
- Modify canonical truth.

Primary output: **Research Signals / Research Pack**.

---

## M3 — STORY
**Function:** Creative strategy, scripts, and copy  
**Tagline:** Make people care.

Responsibilities:

- Convert Creative Brief + selected evidence into a content concept.
- Develop hooks, narrative, scripts, captions, CTAs, and platform adaptations.
- Preserve CEFFLO's natural brand voice.
- Adapt execution for TikTok, IG/FB, Threads, and future channels.
- Produce clear production instructions for M4.
- Check content history to reduce unnecessary duplication.
- Keep claims grounded in Product Truth.

One concept may generate:

```text
C-0042-TT
C-0042-IGFB
C-0042-TH
```

M3 should not:

- Treat literal English-to-Malay translation as acceptable brand copy.
- Use generic SaaS language merely because it sounds polished.
- Publish.
- Alter Product Truth.
- Spend advertising money.
- Hold raw platform credentials.

Primary output: **Concept Package**.

---

## M4 — STUDIO
**Function:** Creative production  
**Tagline:** Make the content.

M4 is one production agent with multiple tools. Image generation, video generation, editing, subtitles, audio, and rendering are tools under M4—not separate Marketing agents.

Responsibilities:

- Receive a scoped Production Pack.
- Generate/edit required images and video.
- Use approved reference assets.
- Create platform-specific media variants.
- Handle subtitles, voice/audio, cropping, resizing, rendering, and export.
- Preserve script meaning and Brand Truth.
- Version every production output.
- Perform targeted repairs when M5 identifies production-specific defects.

Potential production tool classes:

- Image generation/editing.
- Video generation.
- Seedance or approved video provider.
- Reference-image/video workflows.
- Asset library.
- Audio/voice tools.
- Subtitle tools.
- Renderer/editor.
- Export presets.

M4 should not:

- Publish.
- Change the intended product claim.
- Rewrite strategic meaning without routing to M3/M1.
- Modify Product Truth.
- Spend advertising money.
- Hold raw secrets.

Primary output: **Versioned Creative Assets**.

---

## M5 — GUARD
**Function:** Independent brand, product, creative, and platform QA  
**Tagline:** Protect the standard.

M5 is an independent verification gate.

M5 checks:

### Product
- Are claims supported by current Product Truth?
- Is terminology correct?
- Is the portrayed capability actually available/authorized?

### Brand
- Does the content follow Brand Truth?
- Is language natural and appropriate?
- Does it preserve CEFFLO positioning?

### Human Quality
- Does the content sound generic or machine-translated?
- Are there obvious AI visual/audio artifacts?
- Does the content feel plausible and human?

### Creative
- Is the hook clear?
- Is the narrative coherent?
- Do visual, voice, subtitles, and script agree?

### Platform
- Is the format suitable for the intended channel?
- Are duration/aspect/copy requirements satisfied?

### Rights / Safety
- Are there obvious asset, music, claim, or publishing concerns requiring intervention?

M5 outputs:

```text
PRODUCT: PASS | FAIL | N/A
BRAND: PASS | FAIL | N/A
HUMAN_QUALITY: PASS | FAIL | N/A
CREATIVE: PASS | FAIL | N/A
PLATFORM: PASS | FAIL | N/A
RIGHTS_SAFETY: PASS | FAIL | N/A

VERDICT: PASS | FAIL
```

For every failure:

```text
FINDING_ID
SEVERITY
EVIDENCE
EXPECTED_CORRECTION
OWNER
AFFECTED_CRITERION
```

Routing:

- Strategy problem → M1
- Copy/tone/script → M3
- Visual/video/audio/subtitle → M4
- Material Product/Brand Truth conflict → HOLD / M1 / Founder Gate as appropriate

M5 must not repair its own findings.

Primary output: **Immutable QA Record**.

---

## M6 — GROWTH
**Function:** Distribution, analytics, and learning  
**Tagline:** Publish, measure, learn.

Responsibilities:

### Distribution
- Prepare approved publishing packages.
- Schedule authorized organic content.
- Request publishing through controlled platform integrations.
- Track publication state and platform IDs.
- Never bypass M5/freshness gates.

### Analytics
Retrieve and normalize available metrics such as:

- Views.
- Reach/impressions.
- Watch time.
- Early retention.
- Completion.
- Saves.
- Shares.
- Comments.
- Clicks.
- Conversions when available and attributable.

### Learning
- Compare concepts and variants.
- Evaluate experiment results.
- Detect patterns.
- Produce evidence-backed learnings.
- Feed learnings to Marketing Memory.
- Surface promotion candidates.

M6 should not:

- Autonomously increase paid-media budget.
- Treat one successful post as universal proof.
- Modify Product/Brand Truth.
- Mass-delete content.
- Change account-level settings.
- Hold raw credentials.

Primary outputs: **Publication Records, Performance Records, Learnings, Promotion Candidates**.

---

# 3. Model Strategy

Model assignment is configurable. Role definitions are canonical; provider/model assignments are operational configuration.

## V1 Cost-Controlled Baseline

| Agent | Default model strategy |
|---|---|
| M1 Lead | DeepSeek high-efficiency primary; stronger reasoning model only when diagnosed as necessary |
| M2 Radar | DeepSeek high-efficiency primary + research/search tools |
| M3 Story | DeepSeek high-efficiency primary; Sonnet-class creative escalation when required |
| M4 Studio | Strong multimodal/creative-director model + production tools; video provider such as Seedance |
| M5 Guard | Strong independent multimodal QA model |
| M6 Growth | DeepSeek high-efficiency primary |

Operational intent:

```text
DeepSeek-class model = high-volume/default engine
Strong multimodal model = visual production direction + independent QA
Sonnet-class model = targeted creative/reasoning escalation, not routine default
```

Model names and versions must be stored as configuration rather than embedded permanently into role logic.

Example:

```text
M1_PRIMARY_MODEL
M2_PRIMARY_MODEL
M3_PRIMARY_MODEL
M3_ESCALATION_MODEL
M4_DIRECTOR_MODEL
M4_VIDEO_PROVIDER
M5_PRIMARY_MODEL
M6_PRIMARY_MODEL
```

## Escalation Rule

Do not automatically cascade through expensive models.

First diagnose:

- Prompt defect?
- Missing context?
- Wrong reference?
- Tool/API failure?
- Production-provider failure?
- Genuine model capability limitation?

Only genuine capability limitations justify model escalation.

---

# 4. Tools and Permission Architecture

## Core Security Principle

> AI requests actions. Controlled tools execute actions.

Agents do not receive unrestricted GitHub, platform, provider, ad-account, database, or API credentials.

Secrets belong in n8n Credentials or an approved secret store.

---

## M1 Permissions

Allowed:

- Broad read access to marketing truth/context.
- Relevant analytics summaries.
- Campaign/content-calendar read.
- Experiment history.
- Brief/task creation.
- Agent dispatch.
- Task-state updates.

Not allowed:

- Raw secrets.
- Direct publishing.
- Paid spend.
- Final media generation.
- Canonical truth mutation without authorization.

---

## M2 Permissions

Allowed:

- Public web/search.
- Approved public social/community research.
- Competitor/public-page research.
- Internal analytics read where relevant.
- Comment/question retrieval where available.
- Research archive read/write.

Not allowed:

- Public replies.
- Publishing.
- Paid spend.
- Product/Brand Truth mutation.
- Raw secrets.

---

## M3 Permissions

Allowed:

- Creative Brief.
- Relevant Brand/Voice Truth.
- Selected Product Truth.
- Relevant research signals.
- Content-history lookup.
- Platform rules.
- Copy/script generation.
- Duplicate/similarity checks.

Not allowed:

- Publishing.
- Paid spend.
- Canonical truth mutation.
- Unrestricted credentials.

---

## M4 Permissions

Allowed:

- Scoped Production Pack.
- Approved brand/reference assets.
- Image generation/editing.
- Video generation.
- Audio/voice/subtitle tools.
- Rendering/editing/export.
- Generated-asset write access.

Not allowed:

- Publishing.
- Paid spend.
- Canonical truth mutation.
- Unapproved strategic rewrites.
- Raw credentials.

---

## M5 Permissions

Allowed:

- Read-only Creative Brief.
- Relevant Product Truth.
- Brand Truth.
- Intended audience.
- Final copy/script.
- Actual final media.
- Platform requirements.
- Media inspection.
- QA-record write.

Not allowed:

- Editing implementation/creative.
- Regeneration.
- Publishing.
- Paid spend.
- Canonical truth mutation.

---

## M6 Permissions

Allowed:

- Approved publishing packages.
- Controlled schedule/publish actions.
- Platform analytics retrieval.
- Performance normalization.
- Experiment result updates.
- Learning creation.
- Promotion-candidate creation.

Not allowed:

- Unapproved ad spend.
- Mass deletion.
- Canonical truth mutation.
- Raw secrets.
- Account-level security/config changes.

---

# 5. Permission Matrix

| Capability | M1 | M2 | M3 | M4 | M5 | M6 |
|---|---:|---:|---:|---:|---:|---:|
| Product Truth read | Full | Scoped | Scoped | Minimal | Full relevant | Scoped |
| Brand Truth read | Full | Scoped | Full relevant | Full relevant | Full relevant | Scoped |
| Marketing Memory | Full relevant | Research | Relevant | Minimal | Relevant | Full relevant |
| Public research | Limited | Full | Limited | No | Verification only | Limited |
| Analytics read | Summary | Relevant | Learning only | No | Relevant | Full |
| Write strategy | Yes | Signals only | No | No | No | Learning only |
| Write copy/script | No | No | Yes | Minor production text only | No | No |
| Generate media | No | No | No | Yes | No | No |
| Edit media | No | No | No | Yes | No | No |
| QA approval | No | No | No | No | Yes | No |
| Schedule content | No | No | No | No | No | Gated |
| Publish organic | No | No | No | No | No | Gated |
| Read comments | Summary | Yes | Relevant | No | Relevant | Yes |
| Public reply | No | No | No | No | No | Separate policy |
| Paid-media spend | No | No | No | No | No | Founder Gate |
| Modify canonical Product/Brand Truth | No | No | No | No | No | No |
| Read raw secrets | No | No | No | No | No | No |

---

# 6. Action Risk Levels

## GREEN — Autonomous

- Research.
- Context retrieval.
- Copy drafts.
- Content concepts.
- Media drafts.
- QA.
- Analytics retrieval.
- Performance analysis.
- Learning proposals.

## AMBER — Deterministically Gated

- Scheduling approved content.
- Publishing M5-PASS content.
- Modifying a scheduled time.
- Targeted media regeneration.
- Platform API retries.

n8n must enforce required gates.

## RED — Founder Gate

- New paid-media spend.
- Budget increase outside explicit pre-authorization.
- Major positioning/brand/product claim changes.
- Major public correction/crisis response.
- Mass deletion.
- Account/security changes.
- High-impact irreversible action.

---

# 7. Marketing Context System

Core rule:

> Marketing agents do not remember Product Truth. They retrieve current Product Truth.

Canonical context layers:

A. Product Truth  
B. Brand Truth  
C. Audience Truth  
D. Content World  
E. Research Signal Memory  
F. Content Memory  
G. Experiment Memory  
H. Performance Memory  
I. Founder Marketing Decision Ledger

---

## A. Product Truth

Defines:

- What CEFFLO is.
- Positioning.
- Supported audiences/use cases.
- Current capabilities.
- Product surfaces.
- Terminology.
- Lifecycle.
- Available/HOLD/future capabilities.
- Explicit prohibited claims.

Example:

```text
POSITIONING:
Local Same-Day Delivery Operating System

DO NOT CLAIM:
Marketplace
Rider marketplace
On-demand rider provider
```

Marketing cannot override Product Truth because a false claim performs well.

---

## B. Brand Truth

Defines:

- Voice.
- Tone.
- Language rules.
- Visual identity.
- Approved terminology.
- Positive examples.
- Prohibited language.
- Logo/brand assets.
- Platform adaptations.

Key language doctrine:

- Natural Malaysian Malay where Malay is used.
- Polite and conversational when appropriate.
- Avoid literal English-to-Malay marketing translation.
- Avoid generic AI/SaaS phrasing.
- Real operational language is preferred where suitable.

Example:

```text
AVOID:
"Revolusikan operasi penghantaran anda."

PREFERRED DIRECTION:
"Ada 50 order hari ni. Rider ada tiga orang je.
Macam mana nak bahagi delivery?"
```

---

## C. Audience Truth

Audience Truth must be structured, not merely “SMEs”.

Example:

```text
AUDIENCE_ID:
AUD-MEALPREP-01

TYPE:
Meal-prep operator

DELIVERY_MODEL:
Many scheduled local drops

COMMON_SITUATION:
30–100 orders
Limited drivers
Same-day delivery window

PAINS:
Order organization
Driver allocation
Route planning
Customer updates
Delivery visibility
```

Audience Truth requires evidence/authorization. A single research observation does not automatically become canonical truth.

---

## D. Content World

Content World describes real situations experienced by CEFFLO's intended users.

Initial families may include:

- Order Chaos.
- Driver Allocation.
- Route Planning.
- Delivery Visibility.
- Morning Operations.
- Failed Delivery.
- Customer Updates.
- Business Growth / operational scaling.
- Multi-source order intake.
- Zone management.
- Driver workload.
- Multi-drop delivery pressure.

Content World is a living structured universe:

```text
Situation → Tension → Problem → Angle → Possible Format
```

It is not merely a topic list.

---

## E. Research Signal Memory

M2 findings enter as signals before they can become truth.

Example:

```text
SIGNAL_ID:
RS-2026-0042

AUDIENCE:
AUD-MEALPREP-01

SIGNAL:
Difficulty splitting high delivery volume among limited drivers.

CONFIDENCE:
MEDIUM

STATUS:
ACTIVE

EVIDENCE:
[source references]

RELATED_CONTENT_WORLD:
CW-DRIVER-ALLOCATION
```

Signals can accumulate evidence and confidence.

---

## F. Content Memory

Every concept gets a stable ID.

Example:

```text
CONCEPT_ID:
C-0042

AUDIENCE:
AUD-MEALPREP-01

CONTENT_WORLD:
CW-DRIVER-ALLOCATION

PROBLEM:
70 deliveries / 3 drivers

ANGLE:
Operational pressure

OBJECTIVE:
Problem recognition
```

Platform variants:

```text
C-0042-TT
C-0042-IGFB
C-0042-TH
```

Asset versions:

```text
C-0042-TT-V1
C-0042-TT-V2
```

Avoid ambiguous filenames such as `final-final-2.mp4`.

---

## G. Experiment Memory

Marketing must learn through explicit hypotheses where useful.

Example:

```text
EXPERIMENT_ID:
EXP-0017

HYPOTHESIS:
Specific operational numbers create stronger initial attention
than generic delivery advice.

CONTROL:
"Macam mana nak urus banyak delivery?"

VARIANT:
"70 order. Rider ada tiga."

PRIMARY_METRIC:
3-second hold

SECONDARY_METRICS:
Completion
Shares

STATUS:
RUNNING
```

Result:

```text
SUPPORTED
NOT_SUPPORTED
INCONCLUSIVE
```

Do not claim universal proof from one post.

---

## H. Performance Memory

Two layers:

### Raw Performance
Platform-specific metrics per published variant.

### Derived Learning
Evidence-backed interpretation.

Example:

```text
LEARNING_ID:
LEARN-0021

OBSERVATION:
Operational-number hooks showed stronger early retention
across six tested videos.

CONFIDENCE:
MEDIUM

RELATED_EXPERIMENTS:
EXP-0017
EXP-0020

ACTION:
Continue testing quantity + driver-count hooks.
```

M1 should usually retrieve derived learning, not massive raw analytics payloads.

---

## I. Founder Marketing Decision Ledger

Example:

```text
DECISION_ID:
MDEC-0014

DATE:
2026-09-19

DECISION:
Use natural Malaysian Malay and avoid literal
English-to-Malay marketing copy.

STATUS:
ACTIVE

SCOPE:
Marketing copy
```

Statuses:

```text
ACTIVE
SUPERSEDED
HOLD
DEPRECATED
```

History remains traceable.

---

# 8. Context Precedence

When context conflicts:

1. Explicit current Founder instruction.
2. ACTIVE Founder Marketing Decision.
3. Canonical Product Truth.
4. Canonical Brand Truth.
5. Canonical Audience Truth.
6. Current Creative/Campaign Brief.
7. Current Research Signals.
8. Performance/Experiment Learning.
9. Historical Content Memory.

Material unresolved conflicts → **Founder Gate**.

Performance never overrides Product Truth.

---

# 9. Context Packs

Do not dump the entire CEFFLO marketing corpus into every model call.

## M1 Strategy Pack

- Product positioning.
- Relevant audience.
- Active Founder decisions.
- Relevant Content World.
- Recent research signals.
- Recent derived learnings.
- Campaign objective.
- Relevant experiments.

## M2 Research Pack

- Audience target.
- Content World.
- Known signals.
- Research gaps.
- Relevant content history.
- Duplication constraints.

## M3 Story Pack

- Creative Brief.
- Relevant Product Truth.
- Audience language.
- Brand Voice.
- Selected signals.
- Relevant successful/failed examples.
- Platform requirements.

## M4 Production Pack

- Final script.
- Visual direction.
- Canonical brand assets.
- Required format/duration.
- Reference assets.
- Explicit DO / DO NOT rules.

M4 does not need the full analytics archive.

## M5 QA Pack

- Creative Brief.
- Relevant Product Truth.
- Brand Truth.
- Intended audience.
- Final copy/script.
- Actual media.
- Platform requirements.

## M6 Growth Pack

- Approved content variants.
- QA reference.
- Publishing metadata.
- Schedule.
- Experiment ID.
- Metrics schema.

---

# 10. Context Versioning and Freshness

Every task/cycle receives a context version.

Example:

```text
CONTEXT_VERSION:
MKT-CX-014

PRODUCT_TRUTH_VERSION:
PT-08

BRAND_TRUTH_VERSION:
BT-06

AUDIENCE_VERSION:
AUD-MEALPREP-01-v3

DECISION_SET:
MDEC-ACTIVE-19

BRIEF_VERSION:
B-0042-v2
```

Before publication, n8n performs a freshness check.

Check:

- Is the context still current?
- Has a relevant Founder Decision changed?
- Has Product Truth changed?
- Has Brand Truth changed?
- Is the exact content version still the one M5 verified?
- Is the content still approved?
- Is the schedule still valid?

If materially stale:

```text
STALE → HOLD → M1 REASSESS
```

---

# 11. Memory Promotion Rules

Agents can create:

- Research Signals.
- Proposed Learnings.
- Proposed Audience Updates.
- Proposed Brand Learnings.
- Experiment results.

Agents cannot autonomously promote these into canonical Product Truth or Brand Truth.

Example:

```text
"Conversational BM performed better this week"
```

is a **Marketing Learning**, not automatically:

```text
"All CEFFLO content must use conversational BM"
```

Canonical promotion requires appropriate evidence and/or Founder-authorized process.

---

# 12. Storage Architecture

## GitHub / Version-Controlled Repository

Recommended for human-readable canonical truth:

```text
/am6/
  product/
  brand/
  audiences/
  content-world/
  decisions/
  platform-rules/
  playbooks/
```

## Supabase

Recommended dynamic operational tables:

```text
research_signals
campaigns
creative_briefs
concepts
content_variants
assets
qa_runs
publications
analytics
experiments
learnings
agent_runs
cost_events
state_transitions
context_snapshots
```

## Object Storage

For:

- Approved references.
- Generated images.
- Generated video.
- Audio.
- Subtitles.
- Exports.
- Archived published assets.

## n8n

n8n performs:

```text
Retrieve → Assemble Context → Route → Execute → Gate → Persist → Schedule
```

n8n is not the canonical long-term database.

## Vector Search

Do not require a vector database for V1.

Start with:

- Stable IDs.
- Structured metadata.
- Tags.
- SQL filters.
- Full-text retrieval where useful.

Add embeddings/vector retrieval only when corpus size and retrieval quality justify the complexity.

---

# 13. Content Identity Architecture

Recommended hierarchy:

```text
Marketing Task
  ↓
Creative Brief
  ↓
Concept
  ↓
Platform Variant
  ↓
Asset Version
  ↓
QA Record
  ↓
Publication Record
  ↓
Performance Records
  ↓
Experiment Result
  ↓
Learning
```

Example:

```text
TASK: MKT-20260919-001
BRIEF: B-0081-v1
CONCEPT: C-0081
VARIANT: C-0081-TT
ASSET: C-0081-TT-V2
QA: MKT-QA-0081
PUBLICATION: PUB-TT-0081
EXPERIMENT: EXP-0017
LEARNING: LEARN-0031
```

---

# 14. Creative Brief Contract

Minimum M1 output:

```text
BRIEF_ID
BRIEF_VERSION
TASK_ID
CONTEXT_VERSION
OBJECTIVE
AUDIENCE
PROBLEM
CONTENT_WORLD
ANGLE
HYPOTHESIS
CORE_SCENARIO
PLATFORMS
FORMAT
CTA
SELECTED_RESEARCH_SIGNALS
PRODUCT_CONSTRAINTS
BRAND_CONSTRAINTS
DO_NOT
SUCCESS_METRICS
FOUNDER_GATES
```

---

# 15. Concept Package Contract

Minimum M3 output:

```text
CONCEPT_ID
BRIEF_ID
CORE_IDEA
HOOK
SCRIPT
CAPTION
CTA
PLATFORM_VARIANTS
PRODUCTION_NOTES
CLAIMS_USED
REFERENCES_USED
DUPLICATION_CHECK
```

---

# 16. Production Pack Contract

Minimum M4 input:

```text
CONCEPT_ID
VARIANT_ID
SCRIPT
CAPTION_IF_RENDERED
VISUAL_DIRECTION
FORMAT
ASPECT_RATIO
DURATION
BRAND_ASSETS
REFERENCE_ASSETS
AUDIO_DIRECTION
SUBTITLE_REQUIREMENTS
DO
DO_NOT
MAX_GENERATION_ATTEMPTS
```

Minimum M4 output:

```text
ASSET_VERSION
FILES
PROVIDER
GENERATION_ATTEMPT
PRODUCTION_ACTIONS
KNOWN_VARIANCE
TOOL_COST
```

---

# 17. QA Contract

Minimum M5 record:

```text
QA_ID
TASK_ID
CONCEPT_ID
VARIANT_ID
ASSET_VERSION
CONTEXT_VERSION
PRODUCT_RESULT
BRAND_RESULT
HUMAN_QUALITY_RESULT
CREATIVE_RESULT
PLATFORM_RESULT
RIGHTS_SAFETY_RESULT
FINDINGS[]
VERDICT
TIMESTAMP
MODEL
```

A PASS is valid only for the exact verified content/asset version and relevant context version.

---

# 18. Publication Contract

Minimum M6 publication package:

```text
PUBLICATION_ID
CONCEPT_ID
VARIANT_ID
VERIFIED_ASSET_VERSION
QA_ID
PLATFORM
ACCOUNT
CAPTION
SCHEDULE
EXPERIMENT_ID
TRACKING_METADATA
FRESHNESS_RESULT
```

Publication result:

```text
PLATFORM_POST_ID
PUBLISHED_AT
STATUS
PLATFORM_REFERENCE
ERROR_IF_ANY
```

---

# 19. n8n Execution State Machine

Canonical states:

```text
NEW
OBJECTIVE_RESOLVE
CONTEXT_BUILD
READY
RESEARCHING
BRIEF_READY
CREATING
CONTENT_ROUTE
PRODUCING
VERIFYING
TRIAGE
REPAIR
ESCALATION_REQUIRED
APPROVED
SCHEDULE_READY
FRESHNESS_CHECK
STALE
HOLD
PUBLISHING
PUBLISHED
MEASURING
LEARNING
CLOSED
FAILED
PAUSED_SYSTEM_GUARD
```

---

# 20. Canonical Execution Flow

```text
NEW
 │
 ▼
OBJECTIVE_RESOLVE
 │
 ▼
CONTEXT_BUILD
 │
 ▼
READY
 │
 ▼
RESEARCHING ───────────── M2
 │
 ▼
BRIEF_READY ───────────── M1
 │
 ▼
CREATING ──────────────── M3
 │
 ▼
CONTENT_ROUTE
 │
 ├── TEXT ──────────────────────────┐
 │                                  │
 └── MEDIA → PRODUCING ── M4 ──────┤
                                    ▼
                                VERIFYING
                                  M5
                               │       │
                            FAIL       PASS
                               │       │
                               ▼       ▼
                            TRIAGE   APPROVED
                               │       │
                       ┌───────┼───┐   ▼
                       ▼       ▼   ▼ SCHEDULE_READY
                      M1      M3  M4   │
                       │       │   │   ▼
                       └── REPAIR ─┘ FRESHNESS_CHECK
                               │       │
                               └─► M5  ├── STALE → HOLD → REASSESS
                                       │
                                       ▼
                                   PUBLISHING
                                      M6
                                       │
                                       ▼
                                   PUBLISHED
                                       │
                                       ▼
                                   MEASURING
                                      M6
                                       │
                                       ▼
                                   LEARNING
                                       │
                                       ▼
                                    CLOSED
                                       │
                                       ▼
                                Marketing Memory
                                    ↙      ↘
                                   M1       M2
```

---

# 21. State Details

## NEW

Sources:

- Founder request.
- Scheduled marketing cycle.
- Research signal.
- Experiment continuation.
- Performance-triggered opportunity.

Create:

```text
TASK_ID
SOURCE
PRIORITY
STATUS
CREATED_AT
```

No unnecessary model call is required merely to create the task.

---

## OBJECTIVE_RESOLVE

Resolve:

- Awareness.
- Problem recognition.
- Education.
- Product understanding.
- Engagement.
- Conversion/test.
- Experiment.

If materially ambiguous → Founder Gate.

---

## CONTEXT_BUILD

Retrieve only relevant truth and memory.

Create immutable task context snapshot:

```text
MARKETING_CONTEXT_VERSION
```

---

## READY

Task has sufficient objective and context to proceed.

---

## RESEARCHING

M2 runs only when research is required.

Outputs:

```text
SIGNALS
AUDIENCE_OBSERVATIONS
PAIN_POINTS
MARKET_ANGLES
SOURCE_EVIDENCE
CONFIDENCE
DUPLICATE_RISKS
```

Adaptation of an already-approved concept may skip this state.

---

## BRIEF_READY

M1 creates and versions the Creative Brief.

---

## CREATING

M3 creates the Concept Package and platform variants.

---

## CONTENT_ROUTE

Conditional route based on production requirement.

### Text-only

```text
M3 → M5
```

### Existing approved media

```text
M3 → M5
```

or:

```text
M3 → M4 adaptation → M5
```

### New image/video/media

```text
M3 → M4 → M5
```

Do not call M4 unnecessarily.

---

## PRODUCING

M4 creates the required media.

Every output must be versioned.

Expensive generation must obey generation limits.

---

## VERIFYING

M5 verifies the actual final output.

M5 does not verify only a description or self-report from M4.

---

## TRIAGE

M5 failure is classified by owner.

```text
STRATEGY → M1
COPY/TONE/SCRIPT → M3
MEDIA/PRODUCTION → M4
CANONICAL CONFLICT → HOLD / M1 / Founder Gate
```

---

## REPAIR

Only the failed scope should be repaired where possible.

Example:

```text
Subtitle error → repair subtitle
```

not:

```text
Subtitle error → regenerate entire video
```

---

## ESCALATION_REQUIRED

Reached after bounded unresolved retries or a diagnosed issue requiring stronger intervention.

Possible actions:

- Revised context.
- Revised brief.
- Tool/provider investigation.
- Stronger model.
- Founder clarification.
- Manual intervention.

---

## APPROVED

Requires M5 PASS for the exact version.

---

## SCHEDULE_READY

M6 prepares platform, account, caption, asset, schedule, experiment tracking, and metadata.

Cadence comes from the active Marketing Plan—not model whim.

---

## FRESHNESS_CHECK

Before any public action verify:

```text
M5_PASS == TRUE
CONTENT_VERSION == VERIFIED_VERSION
CONTEXT_RELEVANT_AND_CURRENT == TRUE
PLATFORM_AUTHORIZED == TRUE
SCHEDULE_VALID == TRUE
```

Relevant stale context blocks publication.

---

## STALE

The verified package is no longer safely publishable because relevant truth/context changed.

Route:

```text
STALE → HOLD → M1 REASSESS
```

---

## HOLD

Wait for:

- Context resolution.
- Founder Gate.
- Provider recovery.
- Missing evidence.
- Canonical decision.

---

## PUBLISHING

M6 requests the controlled publishing action.

n8n performs deterministic checks before connector/API execution.

Publishing failure retries the publishing operation only; it does not regenerate creative.

---

## PUBLISHED

Persist immutable publication record and schedule measurement jobs.

---

## MEASURING

Initial V1 measurement windows:

```text
T+1H
T+24H
T+72H
T+7D
```

These are configurable and platform-dependent.

Do not assume all metrics are meaningful across all platforms.

---

## LEARNING

M6 evaluates evidence and experiment results.

Learning records require:

```text
OBSERVATION
SAMPLE
CONFIDENCE
RELATED_CONTENT
RELATED_EXPERIMENTS
RECOMMENDED_NEXT_TEST
```

---

## CLOSED

Task completed with publication/measurement/learning records persisted as required.

---

# 22. Conditional Routing

Marketing must not execute all six agents mechanically.

## Full Video

```text
M1 → M2 → M3 → M4 → M5 → M6
```

## Threads / Text-Only

```text
M1/M2 → M3 → M5 → M6
```

## Existing Concept Adaptation

```text
M3 → M4 if media adaptation required → M5 → M6
```

## Reactive Opportunity

```text
M2 → M1 quick decision → M3 → M4 if needed → M5 → M6
```

## Analytics Cycle

```text
M6 → Performance Memory → Learning → M1/M2
```

---

# 23. Retry Doctrine

Infinite retries are prohibited.

## Attempt 1
Normal targeted repair.

## Attempt 2
M1 re-triage + targeted repair.

## Attempt 3
Stop automatic loop.

Set:

```text
ESCALATION_REQUIRED
```

Then diagnose cause before spending more.

Retry counts must be persisted by task, finding, provider, and asset where relevant.

---

# 24. Founder Gates

Founder approval is not required for every normal organic post once Marketing is operational and trusted.

Founder Gates apply to:

## Gate A — Strategy Ambiguity
Conflicting direction materially changes campaign/content behavior.

## Gate B — Canonical Change
New/changed positioning, product claim, major brand rule, audience truth, or major marketing doctrine.

## Gate C — Sensitive Public Response
Major complaint, controversy, legal/product incident, or public correction.

## Gate D — Paid Media
New ad spend or budget increase outside explicit pre-authorized rules.

## Gate E — High-Impact Action
Mass deletion, account/security changes, irreversible action.

---

# 25. Paid Ads Workflow

Paid media is not a seventh Marketing agent.

M6 may create a **Promotion Candidate**.

Flow:

```text
ORGANIC CONTENT
      │
      ▼
M6 PERFORMANCE DETECTION
      │
      ▼
PROMOTION_CANDIDATE
      │
      ▼
FOUNDER_GATE
   │       │
REJECT   APPROVE
   │       │
CLOSE     ▼
       ADS_TEST_READY
           │
           ▼
       BUDGET_GUARD
           │
           ▼
         LAUNCH
           │
           ▼
        MONITOR
           │
      ┌────┴────┐
      ▼         ▼
   CONTINUE    KILL
```

Future pre-authorized ad rules may define:

- Maximum budget.
- Maximum duration.
- Objective.
- Allowed audiences.
- Kill conditions.
- Escalation thresholds.

Until explicitly authorized, Marketing cannot independently spend advertising money.

---

# 26. Experiment System

Each meaningful test should have an explicit hypothesis.

Example:

```text
EXPERIMENT_ID:
EXP-0023

HYPOTHESIS:
Specific operational numbers create stronger
problem recognition than generic delivery tips.

A:
"Macam mana nak urus banyak delivery?"

B:
"70 order. Rider ada tiga orang."

PRIMARY_METRIC:
3-second hold

SECONDARY:
Completion
Shares
```

Experiment results:

```text
SUPPORTED
NOT_SUPPORTED
INCONCLUSIVE
```

Marketing optimizes for repeatable knowledge, not merely viral outliers.

---

# 27. Measurement and Learning Doctrine

Never reduce performance analysis to views alone.

Consider where available:

- Initial hold.
- Watch time.
- Completion.
- Shares.
- Saves.
- Comments.
- Clicks.
- Conversion.
- Audience/platform context.

Every learning must distinguish:

- Observation.
- Interpretation.
- Confidence.
- Sample size.
- Recommended next test.

A learning is not automatically Brand Truth.

---

# 28. Organic Cadence Doctrine

Current planning doctrine:

```text
5 concepts/day
×
3 lanes:
1. IG + FB shared
2. TikTok
3. Threads
```

This represents an approximate ceiling of 105 platform outputs/week if every concept produces all three lane variants.

Important:

> Concept ≠ Post.

One concept can be adapted across lanes.

Marketing may route fewer variants when a concept does not naturally fit every platform.

Quality and relevance outrank mechanically filling the ceiling.

Cadence remains configurable through the active Marketing Plan.

---

# 29. Asset Lifecycle

Asset classes:

## CANONICAL
Official logo, approved product screenshots, approved brand/reference assets.

Read-only to agents unless explicitly authorized.

## GENERATED
Draft AI/generated/edited assets.

M4 may create/edit.

## APPROVED
Exact version passed by M5.

Do not silently overwrite.

## PUBLISHED
Historical public version.

Treat as immutable historical evidence.

Revisions create new versions.

---

# 30. Cost Telemetry

Every model/tool call should record where technically available:

```text
TASK_ID
CONCEPT_ID
AGENT
MODEL
PROVIDER
INPUT_TOKENS
CACHED_TOKENS
OUTPUT_TOKENS
MODEL_COST
TOOL_COST
VIDEO_GENERATION_COST
RETRY_COUNT
DURATION
RESULT
FAILURE_CATEGORY
TIMESTAMP
```

Primary cost metrics:

- Cost per concept.
- Cost per approved concept.
- Cost per published post.
- Cost per platform.
- Cost per video.
- Cost per experiment.
- Cost by agent.
- Retry waste.
- Escalation rate.

Optimization must use CEFFLO's real performance/cost data, not assumptions alone.

---

# 31. Circuit Breakers

n8n must be able to enter:

```text
PAUSED_SYSTEM_GUARD
```

when conditions such as these occur:

- Configured API-spend ceiling exceeded.
- Repeated provider failure.
- Repeated M5 failures.
- Duplicate-publishing risk.
- Stale context.
- Credential/authentication failure.
- Unexpected queue explosion.
- Video-generation runaway.
- Repeated platform rejection.
- Data-integrity anomaly.

A circuit breaker stops the affected workflow instead of retrying indefinitely.

---

# 32. Concurrency

Concepts/tasks may progress independently.

Example:

```text
C-081 → M4
C-082 → M5
C-083 → Scheduled
C-084 → M3
C-085 → M2
```

Use Task ID / Concept ID / Variant ID to isolate state.

Apply stricter concurrency limits to expensive providers such as video generation.

---

# 33. Daily Operating Pattern

Illustrative only; exact times are not locked:

```text
M2 Radar refresh
      ↓
M1 selects/builds briefs
      ↓
M3 creates concepts
      ↓
M4 produces media where required
      ↓
M5 verifies
      ↓
Approved queue
      ↓
M6 schedules/publishes
      ↓
M6 ingests analytics from existing posts
      ↓
Experiments + Learnings update
      ↓
Next M1/M2 cycle retrieves new evidence
```

---

# 34. Failure Memory

Store recurring operational failures separately from Product/Brand Truth.

Example fields:

```text
FAILURE_ID
SIGNATURE
AGENT
PROVIDER
CONTENT_TYPE
ROOT_CAUSE
CONFIRMED_FIX
LAST_SEEN
RECURRENCE_COUNT
```

Examples:

- Provider rejects unsupported aspect ratio.
- Subtitle renderer corrupts a language.
- Publishing connector duplicates on timeout.
- Specific generation prompt repeatedly produces text artifacts.

Use Failure Memory to reduce rediscovery and token/tool waste.

---

# 35. Evidence Contract Between Agents

## M1 → M2/M3
- Task ID.
- Context version.
- Objective.
- Audience.
- Constraints.
- Creative Brief when ready.

## M2 → M1/M3
- Signal IDs.
- Evidence.
- Confidence.
- Research summary.
- Duplicates/risks.

## M3 → M4/M5
- Concept ID.
- Platform variants.
- Final script/copy.
- Claims used.
- Production notes.

## M4 → M5
- Exact asset version.
- Actual final media.
- Production actions.
- Provider/tool info.
- Known variance.

## M5 → n8n/M1/M3/M4/M6
- QA ID.
- Exact verified version.
- PASS/FAIL.
- Findings.
- Owner.
- Evidence.
- Context version.

## M6 → Marketing Memory
- Publication record.
- Metrics.
- Experiment results.
- Derived learning.
- Promotion candidate if applicable.

---

# 36. Context Snapshot for Every Published Variant

Persist:

```text
TASK_ID
CONCEPT_ID
VARIANT_ID
ASSET_VERSION
CONTEXT_VERSION
PRODUCT_TRUTH_VERSION
BRAND_TRUTH_VERSION
AUDIENCE_VERSION
ACTIVE_DECISION_SET
BRIEF_VERSION
QA_ID
M5_VERDICT
PUBLICATION_ID
PLATFORM_POST_ID
MODEL_RUN_REFERENCES
COST_SUMMARY
```

This allows CEFFLO to reconstruct why a public content item existed and what truth/version governed it.

---

# 37. Anti-Memory-Corruption Rules

1. Agents cannot create Product Truth.
2. Agents cannot silently create Brand Truth.
3. Research Signal ≠ Audience Truth.
4. Marketing Learning ≠ universal rule.
5. One viral post ≠ proven strategy.
6. Historical content does not outrank active decisions.
7. Superseded decisions remain traceable but are excluded from normal active context.
8. Product Truth always wins over performance optimization.
9. Content with stale material context must be re-evaluated before publication.
10. Canonical promotion requires the authorized process.

---

# 38. Initial Content World Doctrine

Marketing should emphasize real operational situations relevant to businesses managing their own local same-day delivery.

Initial areas:

- Many orders arriving at once.
- Too few drivers for current volume.
- Splitting orders between drivers.
- Delivery zones.
- Multi-drop routing.
- Order organization.
- Driver management.
- Customer delivery updates.
- Delivery status visibility.
- Failed/issue deliveries.
- Morning dispatch pressure.
- Scaling from a small number of deliveries to larger daily volume.
- Multiple business/order sources.
- Bakery, meal-prep, catering, florist, gifts/hampers, online/offline businesses, local manufacturers, and other businesses with their own delivery operations.

The purpose is not to repeatedly advertise features.

The purpose is to make CEFFLO visibly understand the operational world its customers live in.

---

# 39. Human-Quality Doctrine

Marketing must actively avoid:

- Generic SaaS slogans.
- Corporate filler.
- Literal translation.
- Empty motivational content.
- Repetitive AI hooks.
- Fake urgency.
- Random cinematic AI footage unrelated to customer reality.
- Fake product UI.
- Unsupported claims.
- Over-polished dialogue that no intended customer would naturally say.

Prefer:

- Specific operational situations.
- Real numbers where appropriate.
- Recognizable delivery pressure.
- Natural language.
- Platform-native pacing.
- Realistic environments.
- Useful tension.
- Clear problem recognition.
- Human imperfection where it improves authenticity.

---

# 40. Success Metrics for Marketing System

System quality:

- M5 first-pass rate.
- Retry rate.
- Escalation rate.
- Stale-context incidents.
- Unauthorized-action incidents.
- Duplicate-content incidents.
- Publishing failure rate.
- Provider failure rate.

Creative quality:

- Founder correction rate.
- Human-quality QA pass rate.
- Brand QA pass rate.
- Product-truth QA pass rate.

Performance:

- Relevant platform metrics by content type.
- Experiment completion rate.
- Learning confidence growth.
- Reusable winning-pattern rate.

Efficiency:

- Cost per approved concept.
- Cost per published variant.
- Video generation waste.
- Token cost by agent.
- Time from brief to approved content.
- Time from approved content to publication.

---

# 41. V1 Implementation Sequence

## Phase 1 — Foundation

Build:

- Marketing database schema.
- Task/state tables.
- Context snapshot system.
- Decision/Truth retrieval.
- Cost telemetry.
- Provider credential isolation.
- Basic circuit breakers.

Acceptance:

- One task can be created, versioned, and traced end-to-end without publishing.

---

## Phase 2 — Text Pilot

Implement:

```text
M1 → M2 → M3 → M5
```

Use text-only content first.

Validate:

- Context retrieval.
- Creative Brief.
- Research evidence.
- Natural copy.
- Independent QA.
- Retry routing.
- Cost tracking.

No public autonomous publishing required for the first technical test.

---

## Phase 3 — Controlled Publishing

Add M6 organic publishing for an approved low-risk channel/path.

Validate:

- M5 PASS gate.
- Freshness check.
- Exact-version publishing.
- Publication record.
- API failure behavior.
- Duplicate prevention.

---

## Phase 4 — Analytics + Learning

Implement:

- Measurement jobs.
- Platform metrics ingestion.
- Normalization.
- Experiment records.
- Derived learning.
- M1/M2 retrieval of learnings.

---

## Phase 5 — M4 Studio

Add:

- Image production.
- Video production.
- Seedance/approved provider.
- Subtitle/audio/rendering.
- Versioned assets.
- M5 multimodal verification.
- Generation cost controls.

Video should not be the first dependency required to prove Marketing architecture.

---

## Phase 6 — Full Multi-Lane Operation

Enable conditional routing across:

- IG + FB.
- TikTok.
- Threads.

Support multiple concurrent concepts with controlled expensive-provider concurrency.

---

## Phase 7 — Promotion Candidate / Ads Gate

Implement:

- Organic winner detection.
- Promotion Candidate.
- Founder Gate.
- Budget Guard.
- Controlled paid test.
- Monitor/kill logic.

Do not enable autonomous unrestricted ad spend.

---

# 42. Pilot Recommendation

The first Marketing pilot should be intentionally small.

Recommended pilot:

- One audience.
- One Content World.
- One clear operational problem.
- Text-first or simple existing-media content.
- One or two platform variants.
- Full M1/M2/M3/M5 trace.
- M6 publication only after the gates are verified.
- Cost telemetry enabled from the first run.

Example scenario:

```text
AUDIENCE:
Meal-prep operator

PROBLEM:
50 orders today, only 3 drivers.

OBJECTIVE:
Problem recognition.

TEST:
Specific operational-number hook vs generic advice.
```

Do not start by generating dozens of videos.

Prove orchestration and evidence integrity first.

---

# 43. Definition of Done — Content Variant

A content variant is not done because an AI generated it.

Done requires:

1. Valid Task ID.
2. Valid current Context Version.
3. Valid Creative Brief where required.
4. Grounded concept.
5. Exact versioned final copy/media.
6. Required production completed.
7. M5 PASS on the exact final version.
8. Freshness check passes before publication.
9. Publishing succeeds where publication is in scope.
10. Publication record persists.
11. Measurement jobs are scheduled where required.
12. Cost/evidence records persist.

Canonical rule:

> Generated ≠ done.  
> Looks good ≠ done.  
> Agent says PASS ≠ done.  
> Verified, traceable, current, and safely publishable = done.

---

# 44. Definition of Done — Marketing V1

Marketing V1 is operational when:

- M1–M6 role boundaries are technically enforced.
- Model assignments are configurable.
- Credentials are isolated from models.
- Context retrieval works.
- Task/Concept/Variant IDs are stable.
- State transitions persist.
- M5 independently gates publication.
- Retry limits work.
- Freshness checks work.
- Controlled organic publishing works.
- Analytics ingestion works.
- Experiment/Learning records work.
- Cost telemetry works.
- Circuit breakers work.
- Founder Gates work.
- One end-to-end pilot completes with traceable evidence.

---

# 45. Hard Prohibitions

Marketing must not:

- Invent CEFFLO capabilities.
- Reposition CEFFLO without authorization.
- Publish content that failed M5.
- Publish a modified version using an older PASS.
- Ignore materially stale context.
- Expose raw secrets to models.
- Give all agents unrestricted platform access.
- Allow infinite retries.
- Regenerate expensive media when a targeted repair is sufficient.
- Spend paid-media budget without the applicable authorization.
- Treat research as canonical Product Truth.
- Treat one performance outlier as universal marketing truth.
- Let M5 repair its own QA findings.
- Let a model bypass deterministic n8n gates.
- Overwrite published history.
- Optimize engagement using false product claims.

---

# 46. Canonical Marketing Architecture

```text
                            FOUNDER
                               │
                               ▼
                       n8n CONTROL PLANE
                               │
                    Context / State / Gates
                               │
                ┌──────────────┴──────────────┐
                ▼                             ▼
           M1 — LEAD                     M2 — RADAR
        Strategy / Brief              Research / Signals
                │                             │
                └──────────────┬──────────────┘
                               ▼
                          M3 — STORY
                    Concept / Copy / Script
                               │
                       ┌───────┴────────┐
                       │                │
                 media required     text-only
                       │                │
                       ▼                │
                  M4 — STUDIO           │
                 Production / Render    │
                       └────────┬────────┘
                                ▼
                           M5 — GUARD
                       Independent QA Gate
                          │            │
                        FAIL          PASS
                          │            │
                    M1 / M3 / M4       ▼
                          │        M6 — GROWTH
                          │     Publish / Measure / Learn
                          │            │
                          └────────────┤
                                       ▼
                               MARKETING MEMORY
                                  │          │
                                  ▼          ▼
                                 M1          M2
```

---

# 47. Canonical Names

System:

**Marketing Department**

Full descriptor:

**CEFFLO Marketing Department**

Agents:

```text
M1 — Lead
M2 — Radar
M3 — Story
M4 — Studio
M5 — Guard
M6 — Growth
```

Infrastructure:

```text
n8n = Control Plane
Marketing Context System = Truth + Evidence + Learning
Supabase = Dynamic Operational Memory
GitHub = Canonical Human-Readable Truth / Version Control
Object Storage = Media / Reference Assets
Paid Ads = Gated Workflow, not Agent 7
```

---

# 48. Final System Doctrine

Marketing exists to create a compounding marketing advantage.

The target is not maximum autonomous output.

The target is:

```text
Better evidence
      ↓
Better understanding
      ↓
Better concepts
      ↓
Better production
      ↓
Stronger QA
      ↓
Safer distribution
      ↓
Better measurement
      ↓
Better learning
      ↓
Better next decision
```

The system should require less Founder babysitting over time **without reducing Founder control over Product Truth, Brand Truth, paid spend, or high-impact public decisions**.

**End of Marketing Master Baseline.**

---

# 49. Clean Replacement & Context Hygiene Doctrine

## Core Rule

> **Marketing is a clean replacement for the previous CEFFLO marketing-agent architecture, not a patch layer on top of it.**

The previous marketing-agent implementation, prompts, architecture documents, reconciliation reports, and superseded workflow logic must not be part of Marketing Department's normal runtime context.

Marketing should be able to operate without reading legacy marketing-agent material to determine what is current.

## Why

Keeping old and new marketing systems together forces agents to spend tokens on:

- obsolete prompts;
- superseded agent roles;
- old workflow diagrams;
- reconciliation documents;
- conflicting cadence or model rules;
- dead configuration;
- unused n8n branches;
- historical assumptions that no longer govern AM6.

That increases cost and ambiguity and can cause an agent to execute the wrong instruction.

## Replacement Rule

For Marketing implementation:

```text
OLD MARKETING AGENT SYSTEM
          ↓
Identify only required infrastructure dependencies
          ↓
Build Marketing cleanly
          ↓
Validate Marketing end-to-end
          ↓
Switch active marketing execution to AM6
          ↓
Remove/deactivate obsolete marketing-agent runtime
          ↓
Audit for legacy references
          ↓
Marketing becomes the ONLY ACTIVE MARKETING AGENT SOT
```

Do not migrate legacy prompts/docs merely to preserve history.

Git/version history may preserve history outside normal runtime context.

## Repository Isolation

Marketing should live in a **dedicated repository/workspace**, separate from the old marketing-agent implementation and separate from unrelated product code unless the Founder explicitly changes this rule.

The Marketing repository should contain only what Marketing requires, for example:

```text
/am6
  MASTER.md
  /product-context-minimum
  /brand
  /audiences
  /content-world
  /decisions
  /platform-rules
  /workflows
  /schemas
  /prompts
  /tests
  /ops
```

Do not copy the old marketing documentation tree into the new Marketing repository.

## What May Be Reused

Reuse is allowed only for a concrete dependency that remains valid, such as:

- provider/account authorization;
- n8n credential references;
- platform integration identifiers;
- verified API configuration;
- canonical CEFFLO Product Truth;
- canonical Brand Truth;
- approved reusable assets;
- required infrastructure endpoints.

Reuse the **dependency**, not the obsolete architecture surrounding it.

## n8n Replacement Rule

Do not transform the old marketing workflows into Marketing through endless node-by-node patches.

Preferred procedure:

```text
Inventory required integrations
        ↓
Create clean Marketing workflows
        ↓
Connect controlled credentials
        ↓
Run Marketing pilot
        ↓
Verify state machine / QA / telemetry
        ↓
Deactivate old marketing workflows
        ↓
Confirm no active dependency
        ↓
Remove obsolete workflow/config where authorized
```

The old workflow must not remain an active hidden fallback unless explicitly required.

## Prompt Hygiene

Each Marketing role has one current canonical prompt/configuration path.

Avoid:

```text
M3 prompt
+ correction prompt
+ tone patch
+ new tone addendum
+ final instruction override
```

Instead:

```text
Canonical M3 prompt vNext
```

Replace the superseded prompt after validation.

## Context Retrieval Hygiene

Normal Marketing Context Packs must retrieve only current material.

Default retrieval must exclude:

```text
SUPERSEDED
DEPRECATED
LEGACY
ARCHIVED
OLD_MARKETING_AGENT
```

Historical retrieval is allowed only when a specific task explicitly requires historical analysis.

## Token Hygiene Metric

Marketing should track unnecessary context growth as an engineering concern.

Useful indicators:

- context tokens per accepted content task;
- duplicate context records retrieved;
- superseded records accidentally retrieved;
- prompt size by agent;
- unused context fields;
- repeated static context that should be cached or reduced.

The goal is not merely cheaper calls. It is **less ambiguity per call**.

## Definition of Done Addition

Marketing replacement is not complete when the new workflow merely runs beside the old one.

Marketing replacement is complete when:

1. Marketing is validated end-to-end;
2. Marketing is the only active marketing-agent architecture;
3. old marketing-agent workflows are inactive/removed as authorized;
4. legacy prompts/docs are absent from Marketing runtime context;
5. only verified reusable infrastructure dependencies remain;
6. retrieval defaults to current Marketing truth;
7. no agent needs a reconciliation chain to determine what is current.

Canonical rule:

> **One active marketing architecture. One current context path. No patch mountain.**

