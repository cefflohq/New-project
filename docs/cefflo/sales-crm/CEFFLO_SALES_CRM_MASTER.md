# CEFFLO Sales & CRM Department — Master Specification

**Status:** MASTER BASELINE  
**Date:** 2026-09-19  
**Department Prefix:** `S`  
**Control Plane:** n8n  
**Owner:** Founder / CEFFLO

---

## 0. Mission

Sales & CRM converts legitimate interest into successful CEFFLO customers through disciplined lead handling, qualification, follow-up, onboarding coordination, activation, and retention signals.

Canonical loop:

```text
Capture → Qualify → Engage → Convert → Onboard → Activate → Retain → Learn
```

The department must help prospects make informed decisions. It must not fabricate urgency, product capabilities, pricing, customer evidence, or outcomes.

---

# 1. Department Agents

## S1 — Intake
**Function:** Lead capture and CRM hygiene.

Handles:
- inbound leads;
- approved campaign leads;
- website enquiries;
- referrals;
- manually added prospects;
- source attribution;
- deduplication;
- contact/account normalization;
- consent/contactability state where required.

Outputs:
- canonical `LEAD_RECORD`;
- source;
- owner/state;
- duplicate resolution.

## S2 — Qualify
**Function:** Fit and need discovery.

Determines from available evidence:
- business type;
- delivery model;
- approximate operational situation;
- problem/use case;
- relevant CEFFLO fit;
- missing qualification information.

Outputs:
- `QUALIFICATION_RECORD`;
- `FIT | POSSIBLE_FIT | NOT_CURRENT_FIT | NEED_MORE_INFO`.

No unsupported assumptions about the prospect.

## S3 — Engage
**Function:** Contextual sales communication and follow-up.

Creates/sends authorized:
- responses;
- follow-ups;
- product explanations;
- demo/onboarding invitations;
- relevant educational material.

Uses current Product Truth, Pricing Truth, Brand/Language rules, and CRM context.

No spam, fake scarcity, invented discounts, or unsupported promises.

## S4 — Convert
**Function:** Conversion workflow.

Coordinates:
- approved plan/pricing presentation;
- trial/signup path;
- sales questions;
- unresolved objections;
- Founder escalation for non-standard commercial decisions.

Outputs:
- opportunity state;
- conversion event;
- loss reason when known.

S4 cannot create unauthorized commercial terms.

## S5 — Onboard
**Function:** Customer onboarding coordination.

After conversion/signup:
- identifies onboarding stage;
- delivers approved setup guidance;
- tracks required setup milestones;
- detects onboarding blockers;
- routes product/support issues to Customer Service or Product Intelligence.

Outputs:
- onboarding state;
- blocker record;
- handoff evidence.

## S6 — Retain
**Function:** Activation/retention CRM intelligence.

Monitors authorized customer lifecycle signals such as:
- incomplete activation;
- dormant account;
- recurring friction;
- renewal/plan events where applicable;
- customer engagement signals.

Creates appropriate follow-up tasks and retention signals.

S6 must not use manipulative dark patterns or invent churn risk without evidence.

---

# 2. Canonical Flow

```text
Marketing / Website / Referral / Founder
                  │
                  ▼
              S1 Intake
                  │
                  ▼
             S2 Qualify
             │        │
       not fit      relevant
             │        ▼
          nurture   S3 Engage
                      │
                      ▼
                  S4 Convert
                      │
                   customer
                      │
                      ▼
                  S5 Onboard
                      │
                      ▼
                  S6 Retain
                      │
            ┌─────────┴─────────┐
            ▼                   ▼
     Customer Service     Product Intelligence
```

Marketing supplies demand/leads; Sales & CRM owns the lead/customer commercial lifecycle.

---

# 3. CRM Source of Truth

One canonical CRM record per lead/account/contact relationship.

Core records:
```text
LEAD
CONTACT
ACCOUNT
OPPORTUNITY
ACTIVITY
QUALIFICATION
ONBOARDING
LIFECYCLE_EVENT
CONSENT_STATE
LOSS_REASON
HANDOFF
```

Do not create parallel agent-specific CRM memories.

---

# 4. IDs

```text
S-TASK-0001
LEAD-0001
ACC-0001
OPP-0001
QUAL-0001
ACT-0001
ONB-0001
RET-0001
```

All communications/actions must trace to the correct CRM entity.

---

# 5. State Machine

```text
NEW_LEAD
NORMALIZE
QUALIFYING
NEED_MORE_INFO
QUALIFIED
NURTURE
ENGAGING
OPPORTUNITY
COMMERCIAL_GATE
CONVERTED
ONBOARDING
ACTIVATING
ACTIVE
RETENTION_ATTENTION
LOST
CLOSED
HOLD
FAILED
PAUSED_SYSTEM_GUARD
```

---

# 6. Communication Permissions

GREEN:
- draft responses;
- summarize lead history;
- qualify using supplied/verified information;
- create internal follow-up tasks;
- send pre-authorized routine messages within policy.

AMBER:
- automated follow-up sequences;
- onboarding reminders;
- lifecycle messages;
- CRM status changes with deterministic rules.

RED / Founder Gate:
- custom pricing;
- discounts outside approved policy;
- contractual commitments;
- refunds/credits outside approved policy;
- enterprise/non-standard commercial terms;
- sensitive public/commercial disputes.

Raw credentials remain in controlled integrations.

---

# 7. Handoffs

## Marketing → Sales & CRM
```text
LEAD_ID
SOURCE/CAMPAIGN
KNOWN_CONTEXT
CONSENT/CONTACTABILITY
ATTRIBUTION
```

## Sales & CRM → Customer Service
For an actual support/setup problem:
```text
CUSTOMER_ID
ISSUE
CONTEXT
URGENCY
ACTIONS_ALREADY_TAKEN
```

## Sales & CRM → Product Intelligence
For repeated product objections/needs:
```text
SIGNAL
AFFECTED_SEGMENT
FREQUENCY
EVIDENCE
RELATED_LOSS/FRICTION
```

Sales requests do not automatically become Product Requirements.

---

# 8. Truth Rules

Sales communication must retrieve:
1. Product Truth.
2. Pricing/Commercial Truth.
3. Active Founder Decisions.
4. Customer/account CRM context.
5. Approved Brand/Language rules.

Never invent:
- features;
- release dates;
- customer counts;
- discounts;
- integration availability;
- service levels;
- guarantees;
- case-study results.

---

# 9. Metrics

Useful department metrics:
- lead response time;
- qualification completion;
- lead-source quality;
- conversion by relevant cohort/source;
- onboarding completion;
- activation;
- loss-reason distribution;
- follow-up completion;
- retention-attention resolution;
- manual Founder intervention rate.

Metrics inform learning; they do not authorize deceptive optimization.

---

# 10. Clean Context Doctrine

> One customer/lead record. One active commercial truth. No patch mountain.

Do not make agents read every old email/message by default. Build scoped CRM Context Packs containing current state, relevant recent history, open objections, prior commitments, and current Product/Pricing Truth.

Superseded sales scripts and pricing rules are excluded from normal retrieval.

---

# 11. Definition of Done

A Sales & CRM workflow is complete when:
1. the lead/customer identity is correctly associated;
2. source and relevant context are recorded;
3. qualification is evidence-based;
4. communications use current truth;
5. commitments are traceable;
6. conversion/loss state is recorded;
7. onboarding handoff is complete when applicable;
8. product/support signals are routed to the correct department;
9. no unauthorized commercial action occurred.

**Lead ≠ qualified lead. Interest ≠ commitment. Feature request ≠ product promise. Conversion ≠ activation.**

---

# 12. Model Strategy

Runtime model choices are configurable.

Recommended strategy:
- S1 Intake: efficient model/rules + deterministic CRM normalization.
- S2 Qualify: efficient reasoning model using explicit qualification evidence.
- S3 Engage: strong language model for natural, brand-safe communication.
- S4 Convert: reasoning model + deterministic commercial rules.
- S5 Onboard: efficient model + workflow/status tools.
- S6 Retain: efficient analytical model + lifecycle signals.

Use stronger models only after diagnosing context/tool/model limitations.

---

# 13. Tools & Permission Matrix

| Capability | S1 | S2 | S3 | S4 | S5 | S6 |
|---|---:|---:|---:|---:|---:|---:|
| CRM read | Full relevant | Full relevant | Full relevant | Full relevant | Customer scoped | Customer scoped |
| Product Truth | Minimal | Relevant | Full relevant | Full relevant | Full relevant | Relevant |
| Pricing Truth | No | Relevant | Full relevant | Full | Relevant | Relevant |
| Create/update lead | Yes | Qualification | Activity | Opportunity | Onboarding | Lifecycle |
| Send routine message | No | No | Gated | Gated | Gated | Gated |
| Custom commercial terms | No | No | No | Founder Gate | No | No |
| Product promise | No | No | No | No | No | No |
| Paid marketing spend | No | No | No | No | No | No |
| Raw credentials | No | No | No | No | No | No |

---

# 14. Pre-Send / Commercial Verification Gate

Sales does not need another agent merely to count agents. n8n applies deterministic verification before external action.

For routine outbound:
```text
CONTACT_ALLOWED == TRUE
IDENTITY_RESOLVED == TRUE
CURRENT_PRODUCT_TRUTH == TRUE
CURRENT_PRICING_TRUTH == TRUE
MESSAGE_VERSION_CURRENT == TRUE
UNSUPPORTED_CLAIM == FALSE
OPEN_FOUNDER_GATE == FALSE
```

For commercial action:
```text
TERM_WITHIN_APPROVED_POLICY == TRUE
DISCOUNT_WITHIN_POLICY == TRUE
COMMITMENT_TRACEABLE == TRUE
```

Otherwise HOLD or Founder Gate.

---

# 15. Storage Architecture

Recommended CRM/operational tables:
```text
crm_contacts
crm_accounts
crm_leads
crm_opportunities
crm_activities
crm_qualifications
crm_onboarding
crm_lifecycle_events
crm_consent_states
crm_loss_reasons
crm_handoffs
crm_agent_runs
crm_state_transitions
crm_cost_events
```

One canonical CRM entity graph; no parallel agent memories.

---

# 16. Retry & Escalation

Maximum autonomous repair attempts: 3.

Retry only the failed operation:
- CRM normalization failure → normalization only.
- Message validation failure → message correction only.
- platform send failure → send operation only.
- missing qualification → request/collect missing information.

After repeated failure → `ESCALATION_REQUIRED` / HOLD.

Never repeatedly contact a prospect because a workflow retry fired.

---

# 17. Circuit Breakers

Pause affected workflow on:
- duplicate-send risk;
- abnormal outbound volume;
- consent/contactability conflict;
- stale pricing/product truth;
- credential failure;
- repeated platform rejection;
- CRM identity collision;
- unexpected mass status changes;
- cost ceiling breach.

No blind retries.

---

# 18. Cost & Activity Telemetry

Record:
```text
TASK_ID
LEAD_ID
ACCOUNT_ID
AGENT
MODEL
CHANNEL
INPUT_TOKENS
OUTPUT_TOKENS
MODEL_COST
TOOL_COST
SEND_ATTEMPT
RETRY_COUNT
DURATION
RESULT
TIMESTAMP
```

Track cost per qualified lead, converted customer, completed onboarding, and retained/activated workflow where meaningful.

---

# 19. Cross-Department Contracts

### Marketing → Sales
Lead source, campaign/concept attribution, known context, consent/contactability.

### Sales → Customer Service
Customer setup/support issue with actions already taken.

### Sales → Product Intelligence
Repeated objections/needs/loss reasons with evidence.

### Product Intelligence → Sales
Current approved product capability/positioning updates relevant to sales.

### Engineering → Sales
Only verified shipped/release information suitable for customer communication.

---

# 20. Implementation Phases

1. Canonical CRM schema + deduplication.
2. S1 Intake.
3. S2 qualification rules.
4. S3 controlled communication drafts.
5. Pre-send gate + one low-risk authorized channel.
6. S4 commercial gate.
7. S5 onboarding.
8. S6 lifecycle/retention signals.
9. Telemetry/circuit breakers/regression tests.

Start with inbound leads before broad automated outbound.

---

# 21. Hard Prohibitions

Sales & CRM must not:
- spam;
- contact users without required permission;
- invent urgency/scarcity;
- invent product capability or release date;
- invent pricing/discounts;
- make unauthorized contractual commitments;
- repeatedly send because of workflow retries;
- create duplicate CRM identities knowingly;
- hide known unresolved objections;
- turn sales pressure into Product Truth.

---

# 22. Final Definition of Done

Department V1 is ready when:
- S1–S6 boundaries are enforced;
- one canonical CRM record exists;
- deduplication works;
- qualification is evidence-based;
- pre-send/commercial gates work;
- Founder Gates work;
- cross-department handoffs are structured;
- retry/circuit-breaker controls work;
- activity/cost telemetry persists;
- no external action can bypass authorization rules.

