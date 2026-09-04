**Status:** CANONICAL — Founder-approved, merged into repo 2026-09-04
**Repo-reconciliation note:** Net-new implementation master for the AI Marketing Engine (n8n-orchestrated). No implementation work (n8n workflows, marketing_* tables, etc.) exists in this repo yet — this file is the target specification only, per its own Phase M0 (Audit & SOT Reconciliation) being satisfied by this very reconciliation pass.

---

# CEFFLO AI MARKETING ENGINE — MASTER MD

**Status:** Implementation Master
**Purpose:** Build Cefflo's AI-assisted marketing operating system end-to-end
**Primary Orchestrator:** n8n
**Operating Principle:** Create → Distribute → Measure → Learn → Select Winners → Amplify → Repeat
**Brand:** Cefflo — Local Same-Day Delivery Operating System
**Owner / Final Authority:** Founder

---

## 1. OBJECTIVE

Build one coordinated AI Marketing Engine for Cefflo that can continuously produce, distribute, evaluate, learn from, and amplify marketing content across the primary launch channels.

This is not a "generate lots of AI posts" system.

The engine must optimize for:

1. qualified vendor attention;
2. understanding of Cefflo and its value;
3. trust;
4. meaningful engagement;
5. qualified traffic;
6. leads / early-access intent;
7. conversion learning;
8. repeatable winning messages and creative patterns.

The system must learn from real performance rather than repeatedly generating content from assumptions.

---

## 2. SOURCE-OF-TRUTH POSITIONING

Cefflo is a **local same-day delivery operating system for businesses that manage deliveries within their own service area**.

Core operating model:

**Many local orders → Coverage → Delivery zones → Delivery plan → Multi-drop runs → Riders → Delivered today**

Cefflo is not:

- a delivery marketplace;
- GrabFood/Foodpanda;
- a rider marketplace/company;
- a generic order-management SaaS;
- limited to food businesses.

Potential users include businesses such as bakeries, meal-prep operators, florists, gift/hamper businesses, beauty/skincare businesses and other businesses operating their own local same-day delivery workflow.

The Marketing Engine must never silently change this positioning.

---

## 3. MASTER PRINCIPLE

The system operates as a weekly learning loop:

**RESEARCH → IDEATE → CREATE → QA → PUBLISH → MEASURE → SCORE → LEARN → AMPLIFY WINNERS → FEED LEARNINGS BACK**

Volume exists to create more high-quality experiments.

Volume itself is not success.

The engine must distinguish:

- content output;
- reach;
- engagement;
- qualified engagement;
- qualified traffic;
- lead intent;
- conversion;
- actual business learning.

---

## 4. INITIAL DISTRIBUTION CHANNELS

Primary channels:

1. TikTok
2. Instagram
3. Facebook
4. Threads

Supported formats may include:

- short-form video;
- Reels;
- talking-head / creator-style content;
- product demonstration;
- screen recording;
- motion creative;
- static image;
- carousel;
- educational graphic;
- text post;
- founder-style post;
- problem/solution post;
- case-study content when genuine evidence exists.

Content is **not automatically duplicated across all four platforms**.

Every asset must have an explicit platform decision.

One core idea may produce several platform-native derivatives.

---

## 5. VOLUME MODEL

Initial operating target:

**5 core content experiments per day**

At seven days:

**35 core experiments per week**

A core experiment may create multiple platform-native outputs.

The theoretical ceiling if every experiment produced an output for all four platforms is:

**35 × 4 = 140 platform outputs/week**

140 is a ceiling, not a quota.

The router must not create an inappropriate platform version simply to increase output count.

Example:

- a strong text observation may be Threads-first;
- a product workflow demonstration may be TikTok/Reels-first;
- a carousel may be Instagram/Facebook-first;
- one concept may genuinely work on all four after adaptation.

Quality and platform fit override output volume.

---

## 6. WEEKLY WINNER LOOP

At the end of each weekly measurement window, the system ranks content using real performance data.

Target:

**Select approximately Top 5 winning content/angles each week.**

A winner is not determined by views alone.

Winning signals may include:

- qualified watch time;
- completion rate;
- saves;
- shares;
- meaningful comments;
- profile visits;
- link clicks;
- landing-page engagement;
- lead capture;
- demo / early-access intent;
- cost efficiency where paid data exists;
- audience relevance.

The Top 5 become inputs to the Paid Growth Engine.

Winning **angles** must also be recorded separately from individual assets.

Example:

If three creatives based on "stop planning deliveries manually in WhatsApp" perform strongly, the system should learn that the *problem angle* may be the winning insight rather than treating three videos as unrelated winners.

---

# 7. AI TEAM ARCHITECTURE

The system consists of five specialist teams coordinated by n8n.

These are logical teams/agents, not necessarily five separate paid AI subscriptions.

## TEAM 1 — CONTENT & STRATEGY

### Mission

Decide what Cefflo should say, to whom, why now, and in what format.

### Responsibilities

- audience/problem research;
- content pillars;
- angle generation;
- hooks;
- scripts;
- Threads copy;
- captions;
- carousel narratives;
- CTA selection;
- platform adaptation;
- hypothesis definition;
- experiment IDs;
- reuse of validated winning angles.

### Required inputs

- Brand/Product source-of-truth documents;
- product capabilities;
- Founder-approved positioning;
- previous content performance;
- winning/losing angle library;
- current marketing objective;
- target audience;
- product updates that are actually available.

### Required output schema

Every proposed core experiment should contain at minimum:

- experiment_id;
- date;
- objective;
- audience;
- pain_point;
- angle;
- hypothesis;
- hook;
- core_message;
- proof/evidence available;
- CTA;
- recommended format;
- recommended platforms;
- adaptation notes;
- claim-risk classification.

---

## TEAM 2 — CREATIVE PRODUCTION

### Mission

Turn approved concepts into high-quality platform-ready assets.

### Creative Production Router

The system must be **tool-agnostic**.

It must choose production methods according to the creative requirement, not because one vendor/model was hard-coded as "the video tool."

Possible lanes:

### A. Real Product Demo

Preferred when showing Cefflo functionality.

Inputs may include:

- real screen capture;
- approved product prototype;
- real UI footage;
- motion treatment;
- captions;
- voiceover.

Never generate a fake Cefflo interface and present it as real product behavior.

### B. Creator / UGC-Style Explainer

For natural creator-style communication.

Possible specialized services may be integrated later.

Rules:

- never claim an AI actor is a genuine Cefflo customer/vendor;
- never fabricate testimonials;
- never fabricate business results;
- simulated scenarios must be framed honestly.

### C. Generative Video / B-roll

For concept visualization, hooks, transitions and supporting shots.

Potential providers/models may change over time.

Provider selection must therefore live in configuration rather than marketing doctrine.

### D. Static / Carousel

For:

- educational breakdowns;
- workflows;
- pain points;
- comparisons;
- product explanations;
- launch announcements;
- operational concepts.

### E. Editing / Assembly

May combine:

- product capture;
- generated B-roll;
- voice;
- subtitles;
- logo;
- motion graphics;
- CTA;
- platform-safe export.

### Production QA

Every asset must pass:

- brand check;
- claim check;
- product-truth check;
- legibility check;
- platform format check;
- visual quality check;
- AI-artifact check where relevant;
- CTA check.

---

## TEAM 3 — PUBLISHING & DISTRIBUTION

### Mission

Deliver approved content to the correct platform, in the correct format, at the intended time.

### Responsibilities

- publishing queue;
- platform adaptation;
- caption formatting;
- hashtags/metadata where useful;
- scheduled publishing;
- publishing status;
- failure/retry handling;
- asset/content ID tracking;
- URL/UTM attribution where applicable.

### Core rule

Publishing must be **idempotent**.

A retry must not accidentally create duplicate posts.

### Initial integration targets

- TikTok publishing interface where available/approved;
- Meta APIs for Instagram/Facebook where applicable;
- Threads supported publishing interface;
- future channel integrations through adapters.

If a platform does not permit the intended automation, the workflow must fall back to an approval/manual-publish queue rather than bypassing platform controls.

---

## TEAM 4 — ANALYTICS & LEARNING

### Mission

Determine what actually worked and convert performance into reusable marketing intelligence.

### Responsibilities

- ingest platform metrics;
- normalize cross-platform metrics;
- maintain content performance history;
- rank content;
- identify winning hooks;
- identify winning pain points;
- identify winning formats;
- identify winning audiences;
- identify weak content;
- detect false winners;
- generate weekly learning report;
- feed learning back into Team 1.

### Analytics must separate

**Vanity signals**

- raw views;
- likes;
- impressions.

from

**Intent/quality signals**

- saves;
- shares;
- meaningful comments;
- profile visits;
- link clicks;
- qualified landing sessions;
- leads;
- signups;
- demo/early-access intent;
- conversion.

---

## TEAM 5 — PAID GROWTH

### Mission

Take validated organic winners and test/amplify them through paid distribution.

Potential destinations:

- Meta Ads;
- TikTok Ads;
- Google Ads / YouTube where appropriate.

### Core principle

**Organic discovers. Paid amplifies. Paid also generates additional learning.**

The engine must not blindly boost whatever has the most views.

Paid candidates must pass:

- audience relevance;
- product truth;
- conversion relevance;
- brand safety;
- adequate organic evidence or explicit controlled-test rationale.

### Paid responsibilities

- campaign proposal;
- audience hypothesis;
- creative selection;
- budget proposal;
- experiment structure;
- launch after required approval;
- performance monitoring;
- stop/scale recommendations;
- creative fatigue detection;
- learning capture.

---

# 8. ORCHESTRATION — n8n

n8n is the workflow orchestrator, not the marketing brain itself.

It coordinates:

- triggers;
- schedules;
- state;
- agent/model calls;
- document/context retrieval;
- production providers;
- publishing;
- analytics ingestion;
- scoring;
- approval gates;
- paid campaign operations;
- notifications;
- logging.

## Recommended logical workflows

### WF-01 — Daily Marketing Planner

Trigger → load context → load recent performance → generate candidate experiments → validate → approval/queue.

### WF-02 — Creative Production Router

Approved experiment → determine asset type → route to appropriate provider/process → QA → asset registry.

### WF-03 — Publishing Router

Approved asset → platform adaptation → schedule → publish → record platform IDs/status.

### WF-04 — Metrics Collector

Scheduled → collect metrics → normalize → persist.

### WF-05 — Weekly Winner Engine

Weekly metrics snapshot → score → identify Top 5 → extract angle learnings → generate Founder report.

### WF-06 — Paid Amplification

Approved winner → campaign proposal → Founder/budget gate → platform adapter → launch → monitor.

### WF-07 — Learning Memory

Performance + qualitative findings → structured learning store → make available to future planning cycles.

### WF-08 — Failure / Cost / Safety Monitor

Track:

- workflow failures;
- API failures;
- duplicate risk;
- spend;
- model usage;
- publishing failures;
- campaign anomalies;
- claim/safety escalations.

---

# 9. MODEL ROUTING

Do not call every AI provider for every task.

Use routing.

Possible logical model classes:

### FAST / LOW-COST MODEL

Use for:

- classification;
- metadata;
- formatting;
- first-pass variations;
- summarization;
- tagging;
- metric normalization assistance.

### REASONING / STRATEGY MODEL

Use for:

- weekly analysis;
- positioning-sensitive work;
- campaign strategy;
- complex synthesis;
- winner diagnosis;
- major creative briefs.

### CREATIVE GENERATION MODEL

Use when actual visual/video generation is required.

### REVIEWER MODEL

Use selectively for:

- risky claims;
- major campaign launches;
- high-spend creative;
- brand consistency;
- contradictory recommendations.

Do not create an expensive multi-agent debate for routine work.

---

# 10. KNOWLEDGE / MD ARCHITECTURE

The Marketing Engine must not depend on one enormous prompt.

Use versioned source documents.

Recommended knowledge hierarchy:

## A. Product Truth

What Cefflo actually does.

## B. Brand Brain

Positioning, tone, identity, visual principles, prohibited interpretations.

## C. Audience / ICP

Who Cefflo is speaking to and their operating problems.

## D. Content Philosophy

What useful Cefflo content means.

## E. Claims Registry

What can/cannot be claimed.

## F. Creative Playbook

Formats, hooks, production patterns and platform conventions.

## G. Performance Learning Store

Observed winners, losers, audience responses and hypotheses.

## H. Paid Growth Playbook

Rules for amplification, testing, stopping and scaling.

This Master MD coordinates those sources. It does not replace them.

---

# 11. CONTENT PILLARS — INITIAL

Initial pillars should include a balanced mix such as:

### 1. Operational Pain

Examples:

- too many local orders to coordinate manually;
- rider assignment confusion;
- delivery-zone complexity;
- managing multi-drop runs;
- visibility gaps during today's delivery operation.

### 2. Education

Teach businesses better local delivery operations without making every post an advertisement.

### 3. Product Demonstration

Show actual Cefflo workflows as the product becomes reviewable.

### 4. Founder / Build-in-Public

Selective, useful progress and product reasoning.

Do not turn the account into a development diary.

### 5. Before / After Workflow

Compare operational processes honestly without fabricated performance claims.

### 6. Category Scenarios

Show how the operating model applies to different business types.

### 7. Objection Handling

Address concerns such as:

- "I already use WhatsApp."
- "I only have two riders."
- "My deliveries are local."
- "I already use spreadsheets."

### 8. Proof

Only when genuine proof exists:

- actual user feedback;
- real workflow results;
- real case studies;
- genuine testimonials.

---

# 12. PLATFORM-NATIVE RULE

Do not simply copy-paste identical content everywhere.

Each core experiment has:

**one strategic idea**

but may have:

**multiple native executions.**

Example:

Core idea:
"Your delivery problem may not be rider shortage. It may be poor run planning."

Possible derivatives:

- TikTok: 25-second hook + scenario;
- IG Reel: polished version;
- Facebook: Reel plus contextual caption;
- Threads: written operational observation + discussion prompt;
- IG carousel: 5-frame breakdown.

All derivatives retain the same experiment lineage.

---

# 13. CONTENT IDENTITY & ATTRIBUTION

Every core experiment needs a unique ID.

Example:

`CEFFLO-2026-W37-E014`

Every derivative links to the parent:

- E014-TT01
- E014-IGR01
- E014-FBR01
- E014-TH01

Store:

- content ID;
- parent experiment;
- platform;
- asset;
- copy;
- publish timestamp;
- platform post ID;
- campaign ID if amplified;
- performance snapshots;
- final classification.

This is essential for real learning.

---

# 14. WINNER SCORING

Do not hard-code one universal scoring formula before sufficient real data exists.

Start with a configurable weighted model.

Illustrative categories:

- Reach Quality
- Retention
- Engagement Quality
- Intent
- Conversion
- Efficiency
- Strategic Relevance

Example conceptual score:

`Winner Score = Retention + Qualified Engagement + Intent + Conversion + Strategic Fit`

Weights must be configurable.

A post with 500,000 low-intent views must be allowed to rank below a post with 15,000 views that generates strong qualified vendor traffic.

The system must preserve raw metrics alongside normalized scores so scoring changes can be recalculated historically.

---

# 15. PAID AMPLIFICATION GATES

Automation must not equal uncontrolled spending.

## Initial operating mode

**Human-approved campaign launch.**

AI may:

- propose campaign;
- prepare creative;
- recommend audience;
- recommend budget;
- generate variants;
- monitor;
- recommend scale/stop.

Founder approval is required before first launch/spend unless the Founder later explicitly authorizes bounded autonomous spend.

## Future bounded autonomy

May be enabled only with explicit rules such as:

- daily campaign cap;
- account cap;
- maximum budget increase;
- maximum number of new campaigns;
- allowed objectives;
- allowed countries;
- emergency stop conditions.

Never infer permission to spend money.

---

# 16. MARKETING TRUTH & ETHICS GUARDRAILS

The engine must never:

- invent customers;
- invent testimonials;
- invent revenue;
- invent delivery savings;
- invent performance metrics;
- present an AI actor as a genuine customer;
- show fabricated product functionality as live;
- imply Cefflo owns a rider network;
- imply Cefflo is a marketplace;
- make unsupported superiority claims;
- fake scarcity;
- fake reviews;
- impersonate competitors or real people.

AI-generated illustrative content must not be represented as documentary proof.

---

# 17. PRODUCT TRUTH GATE

Before content enters production, classify claims:

### GREEN

Directly supported by canonical product behavior or approved positioning.

### AMBER

Reasonable marketing interpretation but requires review.

### RED

Unsupported, misleading, unimplemented or prohibited.

RED claims do not publish.

The claims registry should record the decision so the same issue is not re-litigated every day.

---

# 18. HUMAN APPROVAL MODEL

Not every post should require Founder micromanagement forever.

Use progressive autonomy.

## Stage 1 — Training

Founder approves:

- strategy;
- content;
- major creative;
- publishing;
- paid campaigns.

## Stage 2 — Controlled Organic Autonomy

Pre-approved content classes may publish automatically.

Founder reviews:

- unusual claims;
- major announcements;
- sensitive content;
- paid campaigns.

## Stage 3 — Bounded Growth Automation

Organic workflow highly automated.

Paid activity may gain bounded autonomy only after explicit authorization and spending rules.

---

# 19. DATA MODEL — MINIMUM

Implementation may use Postgres/Supabase or another approved durable store.

Minimum logical entities:

### marketing_experiments

- id
- objective
- audience
- pain_point
- angle
- hypothesis
- status
- created_at

### marketing_assets

- id
- experiment_id
- asset_type
- provider
- source/reference
- version
- qa_status
- cost

### marketing_posts

- id
- experiment_id
- asset_id
- platform
- platform_post_id
- published_at
- status

### marketing_metrics

- post_id
- captured_at
- impressions
- views
- watch metrics
- likes
- comments
- shares
- saves
- profile actions
- clicks
- leads
- conversions
- available platform-specific metrics

### marketing_learnings

- id
- period
- learning_type
- audience
- angle
- evidence
- confidence
- recommended_action

### marketing_paid_campaigns

- id
- source_experiment_id
- platform
- campaign_id
- objective
- budget
- status
- approval
- performance

### marketing_cost_ledger

- provider
- workflow
- experiment_id
- unit
- estimated_cost
- actual_cost
- timestamp

---

# 20. COST CONTROL

The Founder is willing to spend for quality and growth.

That does **not** remove the requirement for cost intelligence.

Track costs by:

- model;
- workflow;
- creative;
- experiment;
- platform;
- campaign;
- week.

The engine should answer:

- cost per core experiment;
- cost per published asset;
- cost per qualified visitor;
- cost per lead;
- paid CAC when enough data exists;
- which production methods produce the best quality/economics.

Do not optimize for minimum spend.

Optimize for **useful learning and growth per ringgit**.

---

# 21. OBSERVABILITY

Every workflow must have:

- run ID;
- timestamps;
- input reference;
- output reference;
- status;
- retry count;
- provider/model;
- cost where available;
- error reason;
- approval state.

Failures must be visible.

No silent failure.

---

# 22. FAILURE HANDLING

Required behavior:

### AI provider unavailable

Retry with bounded policy or route to approved fallback.

### Creative provider failure

Keep experiment state; retry or route elsewhere.

### Publishing failure

Do not regenerate the strategy. Retry publishing safely.

### Analytics API unavailable

Preserve last snapshot and retry later.

### Duplicate event

Idempotency must prevent duplicate publishing/campaign creation.

### Paid API failure

Never repeatedly create campaigns during uncertain response state.

### Cost anomaly

Pause affected automated lane and notify.

---

# 23. SECRETS & SECURITY

- API keys must live in secure credentials/environment storage.
- Never place secrets inside MD files.
- Never expose provider credentials to generated content.
- Separate staging/testing from production marketing accounts where practical.
- Use least-privilege credentials.
- Log actions without logging secrets.
- Paid advertising credentials require stronger access controls.

---

# 24. IMPLEMENTATION PHASES

## PHASE M0 — Audit & Source-of-Truth Reconciliation

Before implementation:

1. inspect existing Cefflo marketing/brand/product MDs;
2. identify existing n8n or marketing infrastructure;
3. identify reusable schemas/workflows;
4. reconcile contradictions;
5. produce implementation map;
6. do not duplicate existing canonical systems.

### Exit

Clear source-of-truth map.

---

## PHASE M1 — Marketing Data Foundation

Build:

- experiment registry;
- asset registry;
- post registry;
- metrics store;
- learning store;
- paid campaign registry;
- cost ledger.

### Exit

One experiment can be traced end-to-end.

---

## PHASE M2 — Knowledge Loader

Build version-aware retrieval of:

- Product Truth;
- Brand Brain;
- audience;
- claims;
- content philosophy;
- creative playbook;
- learnings.

### Exit

Agents do not rely on giant hard-coded prompts.

---

## PHASE M3 — Content & Strategy Engine

Build Team 1.

Generate structured experiments.

### Exit

Daily planner produces valid, traceable, product-safe proposals.

---

## PHASE M4 — Creative Production Router

Build format classification and provider adapters.

Start with the minimum providers required to prove the loop.

Do not integrate every possible video model on day one.

### Exit

Approved experiments can produce reviewable assets.

---

## PHASE M5 — Publishing Engine

Build platform adapters progressively.

### Exit

A platform-ready asset can be published or safely queued for manual publishing with complete attribution.

---

## PHASE M6 — Analytics Engine

Collect and normalize metrics.

### Exit

Published content has historical performance snapshots.

---

## PHASE M7 — Winner & Learning Engine

Implement configurable scoring and weekly analysis.

### Exit

System can produce evidence-backed Top 5 plus documented learnings.

---

## PHASE M8 — Paid Growth Engine

Integrate advertising platforms progressively.

Initial mode requires approval.

### Exit

An approved organic winner can become a traceable paid experiment without uncontrolled spend.

---

## PHASE M9 — Founder Command Layer

Provide one concise control surface/reporting channel.

Founder should be able to see:

- what is planned;
- what published;
- what failed;
- what is winning;
- Top 5;
- paid recommendations;
- spend;
- leads;
- decisions requiring approval.

Avoid flooding the Founder with agent chatter.

---

## PHASE M10 — Hardening

Test:

- retries;
- duplicate protection;
- provider outages;
- malformed AI output;
- claim rejection;
- missing metrics;
- cost tracking;
- paid approval gate;
- campaign idempotency;
- secret handling.

---

# 25. MVP IMPLEMENTATION PRINCIPLE

Do not build all integrations simultaneously.

Prove one complete vertical slice:

**Founder objective → content experiment → asset → one real platform → metrics → winner evaluation → learning**

Then expand platform/provider adapters.

This prevents a large but unproven automation graph.

The architecture must nevertheless support the full target state defined in this Master.

---

# 26. FOUNDER COMMAND EXAMPLES

The final system should eventually support commands conceptually like:

> Create this week's Cefflo marketing experiments focused on businesses managing many local same-day orders.

> Show me yesterday's strongest content and why it performed.

> Give me this week's Top 5 paid candidates.

> Prepare paid tests for the approved winners.

> Show me what Cefflo learned about vendor pain points this month.

These commands should operate on structured system state, not isolated chatbot memory.

---

# 27. WEEKLY FOUNDER REPORT

Keep it concise.

Minimum:

## Output

- core experiments created;
- assets published by platform;
- production/publishing failures;
- total organic reach;
- qualified engagement;
- qualified traffic;
- leads;
- Top 5;
- paid performance;
- spend;
- strongest angle;
- weakest angle;
- new learning;
- next-week recommendation;
- Founder decisions required.

---

# 28. SUCCESS METRICS

The Marketing Engine itself should be judged on:

### Reliability

- successful workflow rate;
- publishing success;
- data completeness;
- duplicate rate.

### Production

- experiments/week;
- usable asset rate;
- time from idea to publish.

### Learning

- percentage of experiments with usable performance evidence;
- number of validated/refuted hypotheses;
- reuse rate of proven learnings.

### Growth

- qualified traffic;
- leads;
- conversion;
- paid efficiency;
- CAC when meaningful.

Do not optimize the engine primarily for number of posts.

---

# 29. TEST REQUIREMENTS

Implementation must include tests appropriate to the actual stack.

Minimum coverage:

### Unit / logic

- scoring;
- normalization;
- routing;
- claim classification;
- ID generation;
- platform adaptation.

### Integration

- model adapter;
- creative adapter;
- publishing adapter;
- metrics adapter;
- paid adapter.

### Workflow

- happy path;
- provider failure;
- retry;
- duplicate trigger;
- invalid structured output;
- rejected claim;
- manual approval;
- denied paid launch.

### Security

- secret leakage;
- unauthorized campaign creation;
- privilege boundaries.

### Cost

- usage logged;
- anomaly path.

No "green" claim without actual evidence.

---

# 30. EVIDENCE REQUIREMENTS

For every completed implementation phase provide:

- workflow names/IDs;
- files changed;
- schemas/migrations;
- tests;
- execution evidence;
- sample structured outputs;
- known limitations;
- provider/API limitations;
- real blockers.

Do not fabricate successful publishing, metrics, API access or campaign execution.

---

# 31. FOUNDER GATES

Explicit Founder decision is required for:

1. material positioning change;
2. unsupported product claim;
3. new production social-account connection where authorization is required;
4. initial paid campaign launch;
5. autonomous paid-spend permission;
6. significant budget-policy change;
7. destructive marketing-data operation;
8. use of genuine customer identity/testimonial;
9. any change that could misrepresent Cefflo's operating model.

Normal implementation work should continue without unnecessary interruption.

---

# 32. NON-GOALS FOR INITIAL BUILD

Do not:

- build a giant custom marketing dashboard before the core loop works;
- integrate every AI video provider;
- call all AI agents for every content item;
- auto-spend advertising money without authorization;
- chase vanity metrics;
- mass-produce identical cross-platform posts;
- fake UGC;
- fabricate customer proof;
- replace product truth with marketing copy;
- build workflows that require Founder copy-paste between agents.

---

# 33. DEFINITION OF DONE

The Cefflo AI Marketing Engine is complete for its initial production scope when:

1. n8n orchestrates the core workflows;
2. canonical marketing state is durable and traceable;
3. Brand/Product/Claims context is versioned and consumed correctly;
4. Team 1 can produce structured experiments;
5. Team 2 can route and produce approved creative through configured providers;
6. Team 3 can publish or safely queue platform-native content;
7. Team 4 can ingest and normalize real performance metrics;
8. weekly winner selection produces evidence-backed Top 5 candidates;
9. learnings feed future planning;
10. Team 5 can prepare and, after required approval, launch a traceable paid test on at least one supported advertising platform;
11. spend cannot occur outside authorized guardrails;
12. costs are observable;
13. retries/idempotency/error handling are proven;
14. Founder receives concise actionable reporting;
15. no fake testimonials, fabricated product behavior or unsupported claims are present;
16. tests and evidence support the completion claim;
17. remaining provider/platform limitations are explicitly documented.

---

# 34. IMPLEMENTER EXECUTION RULES

The implementer must:

- read this Master MD in full before changing code/workflows;
- audit existing repository/docs/infrastructure before creating duplicates;
- preserve canonical product/brand truth;
- use adapters so providers can change;
- keep workflows observable and idempotent;
- minimize Founder interruptions;
- stop only for a genuine Founder gate, credential/external dependency, collision/safety issue, or unresolved product decision;
- never weaken security/approval controls to force a demo;
- never fabricate evidence;
- commit clean checkpoints;
- produce a final completion report against this Definition of Done.

---

# 35. FINAL TARGET OPERATING LOOP

```text
FOUNDER / OBJECTIVE
        │
        ▼
n8n ORCHESTRATOR
        │
        ▼
CONTENT & STRATEGY
        │
        ▼
CREATIVE PRODUCTION ROUTER
        │
        ▼
QA / PRODUCT TRUTH
        │
        ▼
PUBLISHING & DISTRIBUTION
        │
        ├── TikTok
        ├── Instagram
        ├── Facebook
        └── Threads
        │
        ▼
ANALYTICS & LEARNING
        │
        ▼
WEEKLY WINNER ENGINE
        │
        ├── losing/neutral → learning store
        │
        └── TOP 5
                │
                ▼
        PAID GROWTH ENGINE
                │
        Founder / Budget Gate
                │
                ├── Meta Ads
                ├── TikTok Ads
                └── Google Ads
                │
                ▼
          PERFORMANCE DATA
                │
                └──────────────► LEARNING STORE
                                      │
                                      └──► NEXT CONTENT CYCLE
```

---

## END STATE

Cefflo should not merely have an AI content generator.

It should have a **marketing learning system**:

**produce enough high-quality experiments to discover what the market responds to, preserve the learning, amplify genuine winners, and continuously improve the next cycle.**
