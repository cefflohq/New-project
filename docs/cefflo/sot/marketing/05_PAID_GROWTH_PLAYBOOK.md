**Status:** CANONICAL — Founder-approved, merged into repo 2026-09-04
**Repo-reconciliation note:** Net-new marketing knowledge domain; no prior equivalent existed in this repo (`marketing/` previously contained only the built website, no knowledge docs).

---

# CEFFLO — PAID GROWTH PLAYBOOK
**Status:** Canonical Paid Growth SOT
**Version:** 1.0 — 2026-09-04
**Initial Mode:** Human-approved spend

## 1. Purpose
Define how Cefflo converts organic learning into controlled paid experiments across Meta, TikTok and Google/YouTube where appropriate.

## 2. Core Doctrine
**Organic discovers. Paid amplifies. Paid also learns.**

Paid media is not a substitute for product truth or weak creative.

## 3. Inputs to Paid Growth
Preferred inputs:
- weekly Top 5 organic candidates;
- validated/emerging winning angles;
- real product proof;
- explicit paid-only hypotheses;
- current audience/offer;
- landing destination;
- current commercial truth.

A high-view post is not automatically an ad candidate.

## 4. Candidate Gate
Score candidate on:
- audience relevance;
- retention/attention quality;
- qualified engagement;
- intent;
- conversion relevance;
- proof strength;
- brand safety;
- Claims Registry;
- landing-page readiness;
- creative adaptability.

Outcome:
**AMPLIFY / PAID-TEST / HOLD / REJECT**

## 5. Founder Spend Gate
Initial rule:
**No first launch or spend without Founder approval.**

AI may:
- build campaign proposal;
- select creative;
- recommend objective/audience/budget;
- generate variants;
- prepare payload/draft;
- monitor;
- recommend stop/scale.

It may not infer permission to spend.

## 6. Future Bounded Autonomy
Only after explicit Founder authorization:
- daily account cap;
- campaign cap;
- max new campaigns/day;
- max percentage/absolute budget increase;
- allowed countries;
- allowed objectives;
- allowed platforms;
- minimum data before scale;
- emergency stop rules.

## 7. Experiment Structure
Every paid experiment needs:
- paid_experiment_id;
- source organic experiment(s);
- hypothesis;
- platform;
- objective;
- audience;
- creative;
- landing destination;
- budget;
- start/end or review point;
- primary metric;
- guardrail metrics;
- approval record.

Change as few major variables as practical per test.

## 8. Funnel Objectives
Possible stages:
- awareness;
- qualified traffic;
- lead/early access;
- trial/signup;
- subscription/conversion where available;
- retargeting.

Use the platform objective that best matches the actual business goal and available tracking. Do not optimize for cheap clicks when the goal is qualified adoption.

## 9. Platform Roles
### Meta Ads
Useful for Reels/feed creative, retargeting and audience tests where account/API capability permits.

### TikTok Ads
Useful for creator/native short-video amplification and discovery.

### Google Ads / YouTube
Use when search intent or video reach/retargeting meaningfully matches the funnel. Do not force Google into every weekly Top 5.

Platform selection is a hypothesis to validate.

## 10. Budget Doctrine
No permanent budget numbers are hard-coded in this SOT.

Budget recommendation should consider:
- learning objective;
- platform minimums;
- audience size;
- historical CPA/CPL/CAC when available;
- creative confidence;
- cash/risk tolerance;
- sufficient data threshold.

Founder may spend aggressively for quality/growth, but the engine must preserve cost intelligence.

## 11. Scale Rules
Scale only when:
- primary metric meets current threshold;
- conversion/lead quality is acceptable;
- tracking is credible;
- no claim/brand issue;
- enough data exists for the decision;
- creative is not showing fatigue.

Scale method may include:
- controlled budget increase;
- additional audience;
- additional placement;
- creative derivative;
- platform expansion.

Never let an AI double budgets repeatedly without an explicit bounded policy.

## 12. Stop / Hold Rules
Recommend stop/hold for:
- spend without meaningful signal after sufficient test window;
- broken tracking;
- wrong audience;
- low-quality leads;
- creative fatigue;
- negative/irrelevant engagement;
- landing-page failure;
- policy/account issue;
- claim/brand problem;
- anomalous spend;
- duplicate campaign uncertainty.

## 13. Creative Fatigue
Monitor where data permits:
- frequency;
- declining CTR/engagement;
- rising cost;
- retention decline;
- conversion deterioration.

Response:
- new hook;
- new opening;
- new format;
- new proof;
- new angle only if evidence supports;
- pause rather than endlessly increasing spend.

## 14. Retargeting
Potential pools, subject to consent/platform rules:
- site visitors;
- engaged social audiences;
- video viewers;
- lead-form engagers;
- product/early-access visitors.

Do not use sensitive targeting or unsupported personal inference.

## 15. Landing-Page Rule
Paid traffic should land on a destination aligned with:
- ad promise;
- audience;
- funnel stage;
- current product availability;
- CTA.

Ad cannot promise more than landing/product can deliver.

## 16. Attribution
Store:
**organic experiment → paid derivative → campaign/ad set/ad → click/session → lead → conversion**

Where attribution is incomplete, mark uncertainty. Do not force deterministic CAC attribution from weak data.

## 17. Metrics
Depending on objective:
- CPM;
- reach/frequency;
- video retention;
- CTR;
- CPC;
- landing engagement;
- CPL;
- qualified lead rate;
- signup/trial rate;
- CPA;
- CAC;
- conversion rate;
- payback/LTV only when real commercial data exists.

Qualified business outcome outranks vanity metrics.

## 18. Paid Learning
Record:
- audience response;
- creative response;
- organic vs paid difference;
- platform;
- objective;
- cost;
- lead quality;
- conversion;
- fatigue;
- scale/stop decision;
- confidence.

Feed learnings into Marketing Memory and Content & Strategy.

## 19. API / MCP / Automation Architecture
n8n orchestrates adapters for:
- Meta;
- TikTok;
- Google.

Use official/supported APIs or approved connectors where possible.
MCP may expose tool interfaces, but it does not override platform permissions, ad policy, authentication or Founder spend gates.

Adapters must be idempotent. Uncertain create responses must not cause duplicate campaigns.

## 20. Security
- secrets in credential store;
- least privilege;
- production ad accounts protected;
- approval logged;
- spend changes logged;
- no secret in prompts/MD;
- emergency disable path.

## 21. Policy & Truth
Ads must obey:
- platform advertising policy;
- Claims Registry;
- Product Truth;
- Brand Brain;
- genuine proof rules.

Never bypass platform enforcement.

## 22. Weekly Paid Review
Founder summary:
- candidates;
- launched tests;
- spend;
- qualified outcomes;
- strongest/weakest creative;
- scale/stop recommendations;
- tracking issues;
- next tests;
- approvals required.

## 23. Definition of Done
Paid Growth is operational when an evidence-backed candidate can become a Founder-approved, traceable paid experiment; spend is bounded/auditable; performance returns to Marketing Memory; duplicate/failed-launch paths are safe; and no campaign can silently exceed authorization.
