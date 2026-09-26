**Status:** CANDIDATE — NOT Founder-Locked (merged into repo 2026-09-04)
**Repo-reconciliation note:** Fills the "no Cefflo Pricing Master exists" gap flagged in `docs/cefflo/sot/00_INDEX.md` §9 and `docs/cefflo/05_DECISIONS.md` D-23. This document is a pricing DIRECTION CANDIDATE only — every number in it (RM0/RM99/RM199/RM499, delivery allowances, Rider/Zone/team caps) is explicitly unlocked per the source document's own §16/§19. `docs/cefflo/sot/07_BUSINESS_LAUNCH_COMMERCIAL.md` §4 ("Pricing Authority") requires a current Founder-approved Pricing Master before any price is published as final — this candidate does not itself satisfy that requirement; it is the working input to it. Do not treat any figure below as final commercial truth, and do not let it override `docs/cefflo/sot/07_BUSINESS_LAUNCH_COMMERCIAL.md` §12 ("Product Truth Gate") for marketing/pricing pages.

---

# CEFFLO PRICING PLAN — MASTER AUDIT & DECISION MD

**Status:** Pricing Direction Candidate — NOT Founder-Locked
**Market:** Malaysia-first, Asia-ready
**Product:** Cefflo — Local Same-Day Delivery Operating System
**Date:** 4 September 2026

---

## 1. PURPOSE

This document defines the working commercial model for Cefflo Malaysia and the final audit required before Founder lock.

The pricing system must:

- make Cefflo easy to experience before payment;
- preserve the perceived value of a serious delivery operating system;
- monetize business growth and operational scale;
- avoid crippling the core Cefflo workflow behind feature gates;
- remain simple for Malaysian SMEs to understand;
- protect Cefflo from uncontrolled free-tier cost and abuse;
- support promotions without constantly changing the official list price;
- remain structurally compatible with future regional pricing across Asia.

---

## 2. PRODUCT VALUE BEING PRICED

Cefflo is not a simple order-taking or rider-tracking utility.

The core operational loop is:

**Orders → Coverage → Zones → Delivery Planning → Dispatch → Riders → Live Delivery → Customer Tracking → POD → Completion**

The broader product includes:

- Vendor Web/Desktop;
- Vendor Flutter Mobile;
- Rider Flutter Mobile;
- Service Area and Coverage;
- Delivery Zones;
- Delivery Plan / Review & Dispatch;
- Multi-drop Runs;
- Rider Assignment;
- Live Operational Visibility;
- Customer Tracking;
- Proof of Delivery;
- Team and Rider Management;
- Storefront / Business surfaces where approved;
- FOUNDR operational control plane.

Pricing should therefore reflect operational value, not compete to be the cheapest utility SaaS.

---

## 3. COMMERCIAL PRINCIPLES

### P-01 — Meaningful Free Tier

Cefflo must have a permanent Free tier.

Free is an acquisition engine, not a crippled demo.

A Free business must be able to experience the complete Cefflo operating loop using real deliveries.

### P-02 — Free Must Be Capped

Free is never unlimited.

Caps may include:

- completed deliveries;
- active riders;
- active zones;
- team/admin users;
- business locations;
- storage/retention where appropriate;
- premium integrations and support.

### P-03 — Scale, Not Broken Features

Core functionality should not be artificially removed simply to force payment.

Free should still demonstrate:

**Order → Plan → Dispatch → Rider → Track → POD → Complete**

Paid plans primarily unlock greater scale, operational complexity and higher-level capabilities.

### P-04 — Do Not Price Per Rider

Cefflo should not use a linear `RM × rider` billing model.

Rider count may be used as a plan boundary on lower tiers, but businesses should not be penalized every time they add a temporary or part-time rider.

### P-05 — Completed Delivery as Primary Usage Metric

Working definition:

> **1 successfully completed customer delivery = 1 Cefflo delivery usage.**

Do not count:

- draft orders;
- deleted pre-dispatch orders;
- route views;
- planning calculations;
- rider logins;
- POD uploads;
- customer tracking views.

The canonical usage ledger must live backend-side.

### P-06 — Never Interrupt an Active Delivery

Subscription or quota enforcement must never stop a Rider in the middle of an active run.

If a dispatched run crosses the monthly allowance, allow it to finish safely.

Restriction should apply to subsequent new dispatch activity after the active operation completes.

### P-07 — Stable List Price, Flexible Promotions

Official monthly list prices should remain stable.

Cefflo may reduce effective acquisition price using:

- launch promotions;
- limited campaigns;
- first-N-month offers;
- founding-vendor offers;
- annual billing discounts;
- targeted retention offers.

Do not repeatedly change the public base price week to week.

### P-08 — Malaysia Pricing Is Regional

Malaysia uses MYR pricing.

Future Asian markets should receive their own regional price books based on local willingness-to-pay and economics rather than simple currency conversion.

---

## 4. CURRENT PRICING CANDIDATE

| Plan | Monthly List Price | Delivery Allowance Candidate | Position |
|---|---|---|---|
| **FREE** | **RM0** | **100 / month** | Experience Cefflo |
| **GROW** | **RM99** | **500 / month** | Small growing operation |
| **OPERATE** | **RM199** | **1,500 / month** | Core / hero plan |
| **SCALE** | **RM499** | **5,000 / month** | High-volume operation |
| **ENTERPRISE** | **Custom** | Custom | High-volume / special requirements |

**OPERATE** is the current candidate for the **Most Popular / Hero** plan.

These prices and allowances are **not yet Founder-locked**.

---

## 5. FREE PLAN — CURRENT CANDIDATE

### Purpose

Allow a new Malaysian business to run genuine deliveries with Cefflo without providing payment details first.

### Candidate Limits

- RM0 forever;
- 100 completed deliveries per monthly billing cycle;
- 1 business;
- 1 business location;
- 1 primary admin/user;
- up to 3 active Riders;
- up to 2 active Zones;
- core delivery workflow available;
- Vendor surfaces available as approved;
- Rider App available;
- customer tracking available;
- POD available;
- basic operational reporting;
- Cefflo branding retained;
- no premium API access;
- no premium integrations;
- no priority support;
- paid communication channels are not automatically unlimited.

### Founder Gate F-01

Pressure-test **100 vs 150 completed deliveries/month** before final lock.

Do not raise the cap simply because a larger number looks more attractive. The decision must consider conversion behavior, cost, abuse and the target micro-business usage pattern.

---

## 6. GROW — CURRENT CANDIDATE

**RM99/month**

Target: small businesses that have outgrown Free but are not yet running a large delivery operation.

Candidate:

- 500 completed deliveries/month;
- up to 10 active Riders;
- more Zones than Free — candidate 5;
- up to 3 team/admin users;
- 1 operating location;
- complete core Cefflo workflow;
- standard reporting;
- standard support.

Working positioning:

> **For growing businesses running local deliveries regularly.**

---

## 7. OPERATE — CURRENT CANDIDATE

**RM199/month**

This is the current hero plan.

Target: the business Cefflo primarily wants to serve — a real, recurring local delivery operation.

Candidate:

- 1,500 completed deliveries/month;
- unlimited Riders;
- unlimited Zones;
- up to 10 team/admin users;
- 1 operating location;
- full operational workflow;
- advanced operational reporting;
- richer branding/configuration where approved;
- selected integrations where commercially appropriate;
- priority support candidate.

Working positioning:

> **Run your local delivery operation in one place.**

At full allowance:

`RM199 / 1,500 ≈ RM0.133 per completed delivery.`

The product should be able to defend this price through operational value rather than discounts.

---

## 8. SCALE — CURRENT CANDIDATE

**RM499/month**

Target: high-volume businesses and more operationally complex customers.

Candidate:

- 5,000 completed deliveries/month;
- unlimited Riders;
- unlimited Zones;
- up to 25 team/admin users;
- candidate 3 operating locations;
- advanced reporting;
- advanced operational controls;
- selected integrations/API capability;
- priority support.

At full allowance:

`RM499 / 5,000 ≈ RM0.10 per completed delivery.`

Multi-location entitlement requires reconciliation with Cefflo's actual business/location architecture before lock.

---

## 9. ENTERPRISE

**Custom pricing**

Potential qualification:

- materially above Scale volume;
- larger multi-location operations;
- custom integrations;
- API requirements;
- custom permissions/security;
- dedicated onboarding;
- contractual support requirements;
- special operational architecture.

Enterprise must not become a dumping ground for features that should exist in the normal product.

---

## 10. QUOTA BEHAVIOR

Example:

A Free business is at `98 / 100`.

It dispatches a legitimate 7-stop run.

Cefflo must allow all 7 deliveries to complete even if usage becomes `105 / 100`.

After the run:

> **You've outgrown Free. Your active deliveries were completed safely. Upgrade to dispatch your next delivery run.**

Do not:

- terminate the run;
- prevent POD;
- prevent completion;
- hide customer tracking;
- strand the Rider;
- corrupt canonical run state.

Quota enforcement must be operationally safe.

---

## 11. CANONICAL BILLING / USAGE LEDGER

Usage must be server-authoritative.

Conceptual record:

```text
business_id
billing_period
delivery_id
completed_at
billable_unit = 1
plan_at_completion
```

Requirements:

- idempotent counting;
- one completed delivery cannot be counted twice;
- deleting UI records does not manipulate historical usage;
- retries do not duplicate usage;
- recovery/reassignment does not create false additional deliveries;
- monthly reset changes allowance period, not historical ledger;
- FOUNDR can audit usage discrepancies.

Flutter and Web clients display billing state; they do not determine billable truth.

---

## 12. PROMOTION STRATEGY

Premium list pricing gives Cefflo room to acquire customers without permanently lowering perceived product value.

Examples to test later:

### Launch Offer

Operate:

**RM199 → RM149/month for first 3 months**

### Founding Vendor

A fixed promotional rate for a defined introductory period.

### Annual

Potential later model:

**Pay for approximately 10 months and receive 12 months.**

Annual billing should not be prioritized until monthly pricing and retention behavior have been validated.

### Guardrail

Never create an expectation that users should wait for next week's discount.

Campaigns need:

- defined eligibility;
- defined start/end;
- clear renewal price;
- no deceptive crossed-out pricing;
- measurable acquisition objective.

---

## 13. COST / COGS AUDIT REQUIRED

Before Founder lock, estimate COGS by plan for:

- Supabase/Postgres;
- API/Edge Functions;
- Realtime;
- Rider GPS/location writes;
- maps;
- address search/geocoding;
- POD media storage;
- bandwidth/egress;
- customer tracking traffic;
- notification infrastructure;
- paid WhatsApp/SMS if introduced;
- observability/logging;
- support burden.

Paid third-party communication must not silently become unlimited Free entitlement.

---

## 14. PERSONA PRESSURE TEST

Pricing must be tested against at least these Malaysian operating profiles:

### Persona A — Micro Home Bakery

Approx. 3–8 deliveries/day.

Question: Does Free create enough real experience without allowing a growing commercial operation to remain permanently free?

### Persona B — Growing Bakery

Approx. 15–30 deliveries/day.

Question: Does Grow feel like an obvious, affordable graduation from Free?

### Persona C — Meal Prep / Recurring Delivery

Approx. 40–80 deliveries/day.

Question: Does Operate provide sufficient allowance and obvious operational ROI?

### Persona D — Florist / Gifts / Hampers

Normal volume may be modest but seasonal peaks can be extreme.

Question: How should Cefflo treat seasonal spikes without creating hostile upgrade behavior?

### Persona E — High-Volume Local Seller

100+ deliveries/day.

Question: Is Scale large enough, or does this persona naturally belong in Enterprise?

For each persona calculate:

- deliveries/month;
- riders;
- zones;
- team users;
- locations;
- expected plan;
- price per completed delivery;
- estimated COGS;
- gross margin;
- operational value;
- upgrade trigger;
- seasonal behavior.

---

## 15. METRICS AFTER LAUNCH

Do not change pricing based on feelings alone.

Track:

- Free registrations;
- activation rate;
- first delivery completed;
- first run dispatched;
- Free businesses reaching 25 / 50 / 75 / 100 deliveries;
- Free → Grow conversion;
- Grow → Operate conversion;
- time-to-upgrade;
- churn;
- delivery usage distribution;
- rider distribution;
- zone distribution;
- COGS/business;
- support cost/business;
- promotion conversion;
- discount dependency;
- plan downgrade behavior.

The 100-delivery Free cap can be revisited using actual evidence.

---

## 16. WHAT IS NOT LOCKED

The following remain open until final pricing audit:

- Free cap: 100 vs 150;
- Grow allowance: 500;
- Operate allowance: 1,500;
- Scale allowance: 5,000;
- exact Rider caps;
- exact Zone caps;
- team-user caps;
- multi-location entitlement;
- POD retention policy;
- reporting differentiation;
- premium integration boundaries;
- API entitlement;
- annual pricing;
- overage model;
- promotion rules;
- final Enterprise qualification;
- final COGS thresholds.

---

## 17. CURRENT RECOMMENDED DIRECTION

Current strongest candidate:

> **FREE — RM0**
> Experience Cefflo with a meaningful but controlled monthly allowance.

> **GROW — RM99/month**
> First paid step for a growing local delivery business.

> **OPERATE — RM199/month** ⭐
> Primary Cefflo plan and current Most Popular candidate.

> **SCALE — RM499/month**
> High-volume operational tier.

> **ENTERPRISE — Custom**

Commercial philosophy:

> **Free lets you experience Cefflo.**
> **Grow lets you run a small operation.**
> **Operate lets you run the business.**
> **Scale lets you run serious volume.**

---

## 18. FINAL FOUNDER GATES

### Gate A — Value

Does each paid tier reflect the actual value of Cefflo's operational system?

### Gate B — Free Economics

Can Cefflo sustainably support the chosen Free cap?

### Gate C — Natural Graduation

Do real Malaysian business profiles naturally move Free → Grow → Operate → Scale?

### Gate D — Margin

Does each paid plan maintain healthy gross margin under realistic usage?

### Gate E — Simplicity

Can a Vendor understand the plans in under one minute?

### Gate F — Operational Safety

Can quota/billing enforcement ever interrupt an active delivery?
**Required answer: NO.**

### Gate G — Regional Future

Can the same tier architecture later support regional Asian price books without rewriting the product?

---

## 19. DEFINITION OF DONE — PRICING LOCK

Pricing becomes Founder-Locked only when:

- Malaysian competitor benchmark is documented;
- international benchmark is documented;
- five Malaysian personas are modelled;
- Free 100 vs 150 is decided;
- COGS estimates exist for each tier;
- delivery allowances are validated;
- Rider/Zone/team/location caps are validated;
- quota enforcement behavior is specified;
- promotion rules are defined;
- payment/subscription implementation approach is separately approved;
- Founder explicitly approves final prices and limits.

Until then:

**RM0 / RM99 / RM199 / RM499 / Custom is the approved pricing direction candidate, not the final commercial lock.**
