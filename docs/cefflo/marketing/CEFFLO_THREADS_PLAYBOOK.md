# CEFFLO Marketing Canonical Reconciliation + Threads Playbook
**Status:** Draft for founder review (audited against repo SOT 2026-10-10)  
**Path:** `docs/cefflo/marketing/CEFFLO_THREADS_PLAYBOOK.md`  
**Prepared:** 2026-10-11  
**Purpose:** Resolve conflicts between the supplied marketing documents and establish a usable Threads writing standard without deleting source documents or inventing product capabilities.

---

# Part A — Canonical document authority

## 1. Authority stack

Use the following order when documents conflict:

1. **Current explicit Founder decision** — latest approved decision, including the current visual direction and terminology.
2. **Canonical Product Truth** — source of truth for what the product can do today, what is unavailable, what is on hold, and what must not be claimed.
3. **Canonical Brand Brain** — positioning, brand character, voice, identity, and messaging principles, after the conflicts below are reconciled.
4. **Marketing Master** — marketing department roles, M1–M6 workflow, context retrieval, research, content production, QA, publishing gates, analytics, and learning governance.
5. **Channel Playbooks** — channel-specific execution rules such as the Threads playbook in Part C.
6. **Campaign Briefs and Audience Records** — campaign-specific target, objective, angle, offer, and evidence.
7. **Completion / Implementation Reports** — records of what was implemented and tested in a particular scope. They are not brand strategy or universal product-truth documents.
8. **Historical content and performance records** — evidence and examples only; they do not override current truth.

If Product Truth is missing or a material conflict remains unresolved, mark the claim **HOLD**. Do not fill the gap with a plausible assumption.

## 2. Role of each supplied document

| Document | Keep as | It owns | It does not own |
|---|---|---|---|
| `marketing/CEFFLO_MARKETING_MASTER.md` | Marketing operations master | M1–M6, workflow, QA, context, publishing controls, analytics and learning | Product capability decisions or overriding current brand decisions |
| `sot/05_BRAND_BRAIN.md` | Brand strategy source, after reconciliation | Positioning, brand character, voice, messaging hierarchy and identity | Current product capability truth |
| `website/reports/CEFFLO_MARKETING_FINAL_COMPLETION_REPORT.md` | Website implementation report | Website scope, checks, implementation status and release gates recorded in that report | Brand strategy, universal product status, or permission to publish |

**Do not delete or merge these three documents into one.** They serve different purposes. Add a dedicated Threads playbook instead of making the Marketing Master carry every channel-specific writing rule.

## 3. Required reconciliation decisions

### 3.1 Visual identity

Already reconciled in the repo. Visual tokens are owned by `sot/12_EXPERIENCE_SYSTEM.md` §0A (Cefflo Flow Palette, D-70): Brand Blue `#0060FE`, Brand Gradient `#01265E → #00378F → #005CC4 → #0592EB`, Mustard `#FFC93C` (accent/CTA only, never a surface), Navy `#0B1220`, Cool White canvas, Inter. Signal Lime, Anchor Blue `#2563B3` and the purple era are retired. Marketing copy does not restate colour values.

### 3.2 Product terminology

Locked by D-38: **"Driver" / "Cefflo Driver"** is the user-facing term; **"Rider"** stays the internal backend/schema/API role name. User-facing flow:

`Many local orders → Coverage → Delivery Zones → Delivery Plan → Multi-drop Runs → Drivers → Delivered Today`

Where the audience naturally says "rider" (motorcycle context), it may appear as audience language in copy. Do not frame Cefflo as a rider company or rider marketplace.

### 3.3 Integration and capability claims

The supplied website completion report explicitly records that unsupported integrations, testimonials, performance statistics, ETA, and live-map claims were not added. It also says production publication remains blocked pending Privacy and Terms review.

Therefore:
- LIVE order intake (Vendor Web): CSV/Excel import, API key, Shopify and WooCommerce webhooks (Integrations Phase 1, staging until launch). Say "order masuk terus", never "sync". POS, ERP, Wix, Google Drive, Sheets and Forms are not built; do not claim them.
- Do not claim automatic route optimization, rider live location (LOCKED / IN DEVELOPMENT, Phase 2B.4), precise ETA, AI capability, or measurable delivery improvements. Customer tracking shows only a coarse ETA window where the backend computes it.
- Do not treat website visual QA as product-wide proof.
- Keep website publication status separate from product readiness. The report says the website implementation is ready for founder review, but production publication is blocked.

### 3.4 Brand principles to retain

Retain the following from the Brand Brain and Marketing Master:
- Cefflo is a local same-day delivery operating system for businesses managing deliveries within their own service area.
- Food is an example, not the boundary of the product.
- Sell observable operational clarity, not “AI magic”.
- Prefer concrete operational language to generic SaaS claims.
- Natural Malaysian Malay; English terms are acceptable where people actually use them.
- Never fabricate customers, testimonials, revenue, order volume, savings, integrations, product screens, or AI capability.
- Marketing performance may improve hooks and formats, but never overrides Product Truth.

## 4. Clean-replacement implementation rules

When applying this reconciliation to the active repository:
1. (Signal Lime is already retired in all active SOT; no action.)
2. Replace the superseded rule in the active source of truth; do not add a second contradictory override at the bottom.
3. Replace product-facing “Rider” terminology with “Driver” only where it describes the product surface. Preserve natural audience wording where justified.
4. Search all active marketing prompts for unverified integration, live tracking, ETA, optimization, AI, and outcome claims.
5. Add the Threads playbook as a separate channel rule.
6. Keep implementation reports as historical scoped evidence.
7. Run a conflict search after edits. If an old rule remains active, the task is not complete.
8. Do not delete historical records needed for traceability. Remove obsolete rules from active paths after QA.

---

# Part B — Product-claim guardrail

Before drafting product-led content, the writer must retrieve current Product Truth.

## Claim states

- **VERIFIED:** explicit current evidence supports the exact claim.
- **CONDITIONAL:** only use with a stated scope or caveat.
- **HOLD:** not supported by the available source material.
- **PROHIBITED:** contradicts canonical truth or would misrepresent Cefflo.

## Current guardrails based on supplied documents

| Claim | Status | Rule |
|---|---|---|
| Cefflo is a local same-day delivery operating system for businesses managing deliveries in their own service area | Verified as positioning | May be used |
| Cefflo is a marketplace or supplies on-demand drivers | Prohibited | Never position Cefflo this way |
| Storefront with shareable link/QR and 18 styles | Public Storefront V1 LOCKED (e93f464); production publication pending pre-production gates | Describe exactly; do not claim it is publicly live until launch |
| Orders, zones, suggested delivery plan + review before dispatch, multi-drop runs, manual driver assignment, pickup checklist, photo POD, CSV/Excel import (Vendor Web) | LIVE per Product Truth §18.2 | Describe only the exact behavior; no "automatic" or "smart" wording |
| Shopify / WooCommerce webhooks, API key order intake | LIVE on Vendor Web (staging, Phase 1) | Inbound orders only, no "sync"; public once launched |
| POS / ERP / Wix / outbound webhooks | FUTURE | Do not claim |
| Google Drive / Sheets / Forms | Not in Product Truth | Do not claim |
| Rider live location / live map | LOCKED / IN DEVELOPMENT (2B.4) | Do not claim |
| ETA | Coarse window only, where computable | Never promise a delivery time or precise ETA |
| Automatic route optimization, auto-assign, smart run builder, customer notifications | FUTURE | Do not claim |
| Customer testimonials, customer logos, savings or performance statistics | Prohibited unless independently evidenced | Never invent or imply proof |
| Production website is live and approved | Not supported | Completion report says production publication is blocked pending Privacy and Terms |

A draft is not allowed to turn a HOLD claim into a fact because it sounds persuasive.

---

# Part C — CEFFLO Threads Content Playbook

## 1. Purpose

Write Threads posts that sound like a Malaysian business operator sharing a useful recommendation or practical workflow—not a generic SaaS ad and not an AI-generated essay.

The post should attract businesses that actually manage their own local deliveries. It should not chase empty engagement from people with no relevant delivery operation.

## 2. Default post structure

Use this structure when a product recommendation or list post fits the objective:

**Main post**
1. Identify a specific audience.
2. Name a recognizable operational situation or job-to-be-done.
3. Make a useful recommendation or introduce a practical approach.
4. If it is a product-led post, introduce Cefflo naturally and state what the reader will get from the list.
5. Direct readers to the first comment only if the comment contains the promised useful material.

**First comment**
1. Give the promised list, steps, checklist, or practical explanation.
2. Explain each point in plain language.
3. Keep every product claim within verified Product Truth.
4. End with a relevant, low-pressure next step only when appropriate.

Do not repeat the main post’s pain point in the first comment. The comment must add value, not paraphrase the hook.

This structure is a default, not a mandatory template for every post. Awareness posts, founder POVs, replies, and evidence-led stories may need a different native structure.

## 3. Length and language

- Default to medium-short: enough detail to be useful, short enough to read naturally in Threads.
- Write in natural Malaysian Malay with English terms where people would actually use them: for example, “order”, “team”, “delivery”, “assign”, “workflow”.
- Do not translate English marketing copy word for word.
- Address: "saya" / "kita" / "korang" (Threads). Do not use "anda", "aku" or "kau" (CE2 doctrine §6). A first-person voice must never pretend to be a customer.
- Do not manufacture slang, typos, forced jokes, or emoji.
- Avoid corporate phrases such as “revolusikan operasi”, “unlock your potential”, “seamless end-to-end ecosystem”, and “game changer”.
- Do not use fake personal discovery such as “aku baru jumpa/guna app ni” from the official brand account.
- Do not invent a personal anecdote or customer result.

## 4. Useful-list standard

When the post promises “5 benda”, “5 cara”, “checklist”, or similar, each item must be independently useful.

Acceptable item types:
- a concrete step the reader can do;
- a decision rule;
- a checklist item;
- an explanation of a product capability that is verified;
- a common operational mistake and how to avoid it;
- a clear way to evaluate whether the approach fits their business.

Reject list items that are:
- the same benefit reworded;
- empty adjectives (“mudah”, “powerful”, “best”, “seamless”) without explaining the practical meaning;
- unverified features;
- generic advice that could fit any software;
- five versions of “save time”.

## 5. Funnel intent

### TOFU — awareness
Goal: make the right operator recognize a pattern or learn something useful. Product mention is optional and should not overpower the post.

Good angles:
- a practical checklist before the delivery window starts;
- a decision rule for dividing deliveries among drivers;
- how to spot a dispatch process that depends too much on memory;
- a simple way to prepare orders before assigning drivers.

Avoid:
- a generic “bisnes susah?” hook;
- a product feature dump;
- pretending one workflow fits every business.

### MOFU — consideration
Goal: help the reader assess a process or tool. A product recommendation can appear if the audience and fit are clear.

Good angles:
- what to check before adopting a delivery-management tool;
- how to assess whether order, zone, driver and delivery-status information is organized;
- a specific, verified Cefflo workflow with a clear limitation where relevant.

Avoid:
- unsupported comparisons;
- claiming Cefflo replaces every tool or system;
- feature lists that are not tied to an actual job.

### BOFU / conversion
Goal: invite a relevant next step from a reader whose need is clear.

Good angles:
- a specific product walkthrough;
- a real demo or sign-up CTA that is currently available;
- a clear statement of who Cefflo is and is not for.

Avoid:
- fake scarcity;
- unapproved pricing or offer claims;
- claiming production readiness or availability without checking the current launch gate.

## 6. Audience specificity

Do not address “SMEs” as if all businesses have the same operation. Name the segment and delivery model.

Possible audience candidates—use as hypotheses until validated by research:
- F&B, catering, meal prep, bakery or frozen-food businesses with their own local delivery;
- online sellers and D2C brands with recurring local drops;
- local retailers offering scheduled deliveries;
- owners/operators coordinating a packing team and one or more drivers.

Each brief should state:
- **Audience:** who exactly;
- **Delivery model:** same-day, scheduled, multi-drop, etc.;
- **Situation:** what is happening today;
- **Objective:** TOFU, MOFU, or BOFU;
- **Angle:** the insight or useful lesson;
- **Claim evidence:** which Product Truth supports any product statement;
- **CTA:** the next real action, if one is needed.

Do not invent order counts, driver counts, or operational numbers to make the copy feel specific. If numbers are illustrative, label them clearly as an example or hypothetical.

## 7. CTA rules

Use a CTA only when it gives the reader a clear next step.

Good directions:
- see the actual workflow;
- review a relevant product page;
- try the current available sign-up/demo path;
- save or share a genuinely useful checklist;
- reply with a relevant operational question.

Before using a product CTA, verify that the destination exists, works, and is approved for public use. The website completion report says production publication was blocked pending Privacy and Terms review; do not treat that report as permission to launch.

## 8. Quality gate before approval

A Threads draft passes only if all applicable checks pass:

- [ ] Specific audience—not merely “SMEs”.
- [ ] One clear objective and one central idea.
- [ ] The hook describes a recognizable situation, not generic pain bait.
- [ ] The main post and first comment have different jobs.
- [ ] The first comment adds actionable value and does not repeat the pain.
- [ ] Any promised list has genuinely distinct, useful items.
- [ ] Natural Malaysian language; no literal translation or fake slang.
- [ ] No invented first-person experience, customer story, metrics, or testimonial.
- [ ] Every product claim is supported by current Product Truth.
- [ ] No unverified integration, AI, automation, live map, ETA, optimization, or outcome claim.
- [ ] CTA destination and public availability are verified.
- [ ] The draft sounds like an operator who understands the work, not generic AI marketing.

If a product claim fails, remove or HOLD that claim. Do not rewrite around the same unsupported promise.

## 9. Example pattern — illustrative, not approved product copy

**Main post**

Untuk bisnes yang urus delivery sendiri, sebelum tambah driver, check dulu cara order dibahagikan.

Saya akan tengok 5 benda: apa yang perlu disusun sebelum dispatch, apa yang patut jelas pada setiap driver, dan macam mana nak tahu delivery mana dah selesai. Saya letak checklist ringkas dekat komen.

**First comment**

1. **Pastikan setiap order ada alamat yang boleh digunakan.** Jangan tunggu driver dah bergerak baru cari maklumat yang tertinggal.
2. **Kumpulkan delivery ikut kawasan servis.** Ini langkah menyusun kerja; jangan anggap ia bermaksud sistem sudah mengoptimumkan laluan secara automatik.
3. **Jelaskan siapa yang bertanggungjawab untuk setiap run.** Elakkan dua orang menyangka orang lain sedang urus order yang sama.
4. **Tetapkan cara team menandakan status delivery.** Pilih status yang semua orang faham dan gunakan secara konsisten.
5. **Semak order yang belum selesai sebelum tamatkan operasi.** Pastikan ada orang yang bertanggungjawab untuk follow-up.

Nota: contoh ini mengajar proses operasi umum. Jangan tambah dakwaan bahawa Cefflo menyokong mana-mana langkah secara automatik melainkan Product Truth semasa mengesahkannya.

---

# Part D — Implementation checklist

Use this checklist when applying the document to the active repository. This file is a specification; it does not mean repository files have already been changed.

- [x] Canonical Product Truth: `sot/01_PRODUCT_TRUTH.md` (capability states §18.2).
- [x] Visual direction already reconciled (`sot/12_EXPERIENCE_SYSTEM.md` §0A).
- [ ] Replace active product-facing “Rider” terminology with “Driver” where appropriate.
- [ ] Search active prompts/workflows for unverified integrations, live tracking, ETA, AI, automatic optimization, and outcome claims.
- [ ] Add this Threads playbook to the active marketing playbooks directory.
- [ ] Make M3 and M5 retrieve the playbook when the platform is Threads.
- [ ] Keep the website completion report as scoped implementation evidence; do not treat it as launch approval.
- [ ] Run a repository-wide conflict search and QA the exact changed files.
- [ ] Remove superseded rules from active paths only after QA; preserve historical evidence.

**Definition of done:** one active rule per decision, no conflicting current visual or terminology rules, Threads drafts are checked against current Product Truth, and the repository-wide search confirms superseded rules are no longer active.
