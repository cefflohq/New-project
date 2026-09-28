# CEFFLO Customer Service Department — Master Specification

**Status:** MASTER BASELINE  
**Date:** 2026-09-19  
**Department Prefix:** `CS`  
**Control Plane:** n8n  
**Owner:** Founder / CEFFLO

---

## 0. Mission

Customer Service gives CEFFLO vendors, drivers, and other supported users fast, grounded assistance while turning recurring operational problems into structured evidence for Product Intelligence and Engineering.

Canonical loop:

```text
Receive → Identify → Triage → Resolve → Verify → Close → Learn
```

Customer Service is not allowed to invent product behavior, silently alter customer data, or hide unresolved product defects.

---

# 1. Department Agents

## CS1 — Intake
**Function:** Request/ticket intake.

Receives authorized support channels and creates one canonical case.

Captures:
- customer/account;
- user role;
- channel;
- issue description;
- product surface;
- timestamps;
- attachments/evidence;
- urgency indicators;
- related existing case.

Outputs:
- `CASE_ID`;
- normalized case record;
- duplicate/link information.

## CS2 — Triage
**Function:** Classification, severity, and routing.

Classifies:
- how-to;
- account/setup;
- delivery workflow;
- driver workflow;
- customer tracking;
- billing/subscription where applicable;
- bug candidate;
- outage candidate;
- product feedback/request;
- security/privacy-sensitive issue;
- unknown.

Determines severity and correct owner.

CS2 does not diagnose beyond evidence.

## CS3 — Resolve
**Function:** Grounded support resolution.

Uses:
- current Product Truth;
- approved support knowledge;
- account/case context;
- known incident/workaround records;
- permitted tools/actions.

Provides steps or performs pre-authorized reversible support actions.

If evidence is insufficient, it asks for only what is needed or escalates.

## CS4 — Verify
**Function:** Resolution verification and quality check.

Checks:
- was the stated problem actually resolved?
- does evidence support closure?
- was the correct product behavior communicated?
- are there unresolved side effects?
- is follow-up required?

Outputs:
- `RESOLVED`
- `PARTIALLY_RESOLVED`
- `UNRESOLVED`
- `WAITING_CUSTOMER`
- `ESCALATE`.

CS4 should be independent from CS3 for material cases.

## CS5 — Escalate
**Function:** Specialist/department escalation.

Builds a clean Evidence Pack for:
- Engineering;
- Product Intelligence;
- Sales & CRM;
- Founder;
- security/incident path if separately defined.

Engineering bug handoff includes:
```text
CASE_ID
SURFACE
EXPECTED
ACTUAL
REPRODUCTION
EVIDENCE
ENVIRONMENT
SEVERITY
WORKAROUND
CUSTOMER_IMPACT
```

Product Intelligence handoff includes recurring pain/feedback evidence, not a pre-decided requirement.

## CS6 — Knowledge
**Function:** Support learning and knowledge hygiene.

Analyzes resolved cases to:
- identify recurring issues;
- propose support knowledge updates;
- detect outdated articles;
- identify missing self-service guidance;
- produce structured support learnings.

CS6 cannot silently rewrite Product Truth. Knowledge changes that imply product behavior must match current Product Truth.

---

# 2. Canonical Flow

```text
Customer / Vendor / Driver
           │
           ▼
       CS1 Intake
           │
           ▼
       CS2 Triage
       │    │    │
       │    │    └────► Product feedback → PI
       │    └─────────► Bug/technical → CS5 → Engineering
       ▼
      CS3 Resolve
           │
           ▼
      CS4 Verify
       │        │
   resolved   unresolved
       │        ▼
       │      CS5 Escalate
       │
       ▼
      CLOSED
       │
       ▼
     CS6 Knowledge
       │
       ├────► Support Knowledge
       └────► Product Intelligence signals
```

---

# 3. Case Source of Truth

One canonical case per support issue, with linked duplicates where appropriate.

Core fields:
```text
CASE_ID
CUSTOMER_ID
ACCOUNT_ID
USER_ROLE
CHANNEL
CATEGORY
SURFACE
SEVERITY
STATUS
SUMMARY
EVIDENCE
ACTIONS
OWNER
RELATED_INCIDENT
RELATED_CASES
RESOLUTION
CREATED_AT
UPDATED_AT
```

Do not create isolated agent-specific ticket histories.

---

# 4. IDs

```text
CS-TASK-0001
CASE-0001
ESC-0001
KB-0001
CSLEARN-0001
INCIDENT-0001
```

---

# 5. State Machine

```text
NEW
IDENTIFY
TRIAGE
NEED_INFO
READY_TO_RESOLVE
RESOLVING
VERIFYING
WAITING_CUSTOMER
ESCALATION_REQUIRED
ESCALATED_ENGINEERING
ESCALATED_PRODUCT
ESCALATED_COMMERCIAL
RESOLVED
CLOSED
REOPENED
HOLD
FAILED
PAUSED_SYSTEM_GUARD
```

---

# 6. Severity

Initial framework:

```text
S1 CRITICAL
Major service/security/data-impact incident or broad production failure.

S2 HIGH
Important workflow blocked for a customer/account with no reasonable workaround.

S3 NORMAL
Functional issue with workaround or ordinary support problem.

S4 LOW
Question, guidance, cosmetic issue, or low-impact request.
```

Severity must be evidence-based and configurable.

---

# 7. Permissions

GREEN:
- read support knowledge;
- read scoped customer/account context;
- explain documented behavior;
- create/update cases;
- request evidence;
- provide approved troubleshooting;
- create internal escalations.

AMBER:
- pre-authorized reversible account/support actions;
- routine case notifications;
- approved operational corrections with audit logs.

RED / Founder or designated human gate:
- irreversible/destructive data changes;
- financial compensation outside policy;
- account/security ownership changes;
- major public incident communication;
- legal/privacy-sensitive commitments;
- production-wide destructive action.

Models never receive raw credentials.

---

# 8. Engineering Handoff Contract

Customer Service must not send vague messages such as:

```text
"App rosak. Tolong check."
```

Minimum technical handoff:
```text
CASE_ID
CUSTOMER/ROLE
PRODUCT_SURFACE
EXPECTED_BEHAVIOR
ACTUAL_BEHAVIOR
REPRO_STEPS
EVIDENCE
TIMESTAMP
ENVIRONMENT
SEVERITY
BUSINESS_IMPACT
WORKAROUND
```

Engineering returns:
```text
ENGINEERING_TASK_ID
STATUS
ROOT_CAUSE_IF_CONFIRMED
FIX_VERSION
DEPLOYMENT_STATUS
CUSTOMER_SAFE_RESPONSE
```

CS then communicates only verified information.

---

# 9. Product Intelligence Handoff

Recurring support issues should become structured signals:

```text
SIGNAL
AFFECTED_USERS
CASE_COUNT
SEVERITY_PATTERN
WORKFLOW
EVIDENCE
CURRENT_WORKAROUND
```

Customer Service does not decide that a feature must be built.

PI evaluates the evidence.

---

# 10. Knowledge Architecture

Support knowledge has statuses:
```text
DRAFT
ACTIVE
STALE
SUPERSEDED
DEPRECATED
```

Normal retrieval uses `ACTIVE` only.

Knowledge articles should reference Product Truth version where relevant.

If Product Truth changes materially, affected support knowledge becomes `STALE` until revalidated.

---

# 11. Context Packs

## CS1 Intake Pack
Minimal identity/channel/case duplication context.

## CS2 Triage Pack
Case + Product surface + known incident/category rules.

## CS3 Resolution Pack
Case + current Product Truth subset + active support knowledge + scoped account context + approved actions.

## CS4 Verification Pack
Original issue + actions + evidence + expected outcome.

## CS5 Escalation Pack
Only evidence required by receiving department.

## CS6 Knowledge Pack
Resolved-case clusters + active knowledge + relevant Product Truth.

Do not send entire customer histories to every agent.

---

# 12. Customer Communication Doctrine

Responses should:
- be clear;
- be concise where possible;
- match the customer's language when supported;
- distinguish confirmed behavior from investigation;
- never claim a fix is deployed before verification;
- never blame the customer without evidence;
- avoid unnecessary technical jargon;
- provide the next actionable step.

---

# 13. Metrics

Useful metrics:
- first response time;
- time to resolution;
- reopen rate;
- escalation rate;
- verified-resolution rate;
- recurring-case rate;
- cases by product surface;
- outdated-knowledge incidents;
- Engineering handoff quality;
- Product Intelligence signal yield;
- automation containment where quality remains acceptable.

Speed must not be optimized at the expense of false closure.

---

# 14. Circuit Breakers

Enter `PAUSED_SYSTEM_GUARD` or escalate when:
- broad outage pattern detected;
- security/privacy-sensitive anomaly;
- repeated destructive-action request;
- support tool begins producing unexpected changes;
- case duplication explosion;
- knowledge conflict with Product Truth;
- repeated incorrect automated resolutions;
- authentication/credential failure.

No blind retry loops.

---

# 15. Clean Context Doctrine

> One case truth. One active support knowledge path. No patch mountain.

Do not retain obsolete troubleshooting steps in active retrieval.

When a workaround/fix is superseded:
1. verify the new canonical behavior;
2. update the active knowledge;
3. mark the old knowledge superseded/deprecated;
4. exclude it from normal context.

History remains available only when explicitly needed.

---

# 16. Definition of Done

A support case is done only when:
1. identity/context is sufficient;
2. issue is correctly classified;
3. actions are traceable;
4. response is grounded in current truth;
5. resolution is verified or explicitly unresolved/escalated;
6. required Engineering/PI/Sales handoff is complete;
7. customer-facing status is accurate;
8. reusable learning is captured when appropriate.

**Reply sent ≠ resolved. Workaround ≠ fix. Bug report ≠ confirmed bug. Closed ≠ successful unless resolution evidence supports closure.**

---

# 17. Model Strategy

Runtime model/provider choices remain configurable.

Recommended strategy:
- CS1 Intake: efficient model + deterministic identity/case normalization.
- CS2 Triage: efficient classification/reasoning model.
- CS3 Resolve: strong grounded language/reasoning model with scoped support tools.
- CS4 Verify: independent model/check where material.
- CS5 Escalate: efficient evidence-pack builder.
- CS6 Knowledge: efficient clustering/synthesis model.

Stronger models are escalation tools, not automatic fallbacks.

---

# 18. Tools & Permission Matrix

| Capability | CS1 | CS2 | CS3 | CS4 | CS5 | CS6 |
|---|---:|---:|---:|---:|---:|---:|
| Case read/write | Create | Classify | Update actions | Verify | Escalation | Aggregate |
| Product Truth | Minimal | Relevant | Full relevant | Full relevant | Relevant | Full relevant |
| Support Knowledge | Minimal | Relevant | Full | Full relevant | Relevant | Full |
| Account context | Identity | Scoped | Scoped | Scoped | Minimal required | No raw account history |
| Reversible support action | No | No | Gated | No | No | No |
| Close case | No | No | No | Verified/gated | No | No |
| Engineering escalation | No | Route | No | Recommend | Yes | No |
| Product signal | No | Route | No | Relevant | Yes | Yes |
| Destructive action | No | No | Founder/designated gate | No | No | No |
| Raw credentials | No | No | No | No | No | No |

---

# 19. Storage Architecture

Recommended tables:
```text
cs_cases
cs_case_events
cs_case_evidence
cs_escalations
cs_incidents
cs_knowledge
cs_knowledge_versions
cs_learnings
cs_agent_runs
cs_state_transitions
cs_cost_events
```

Attachments/media belong in controlled object storage with references from the case.

---

# 20. Resolution Gate

A case may become `RESOLVED` only when:
```text
IDENTITY_SUFFICIENT == TRUE
CURRENT_PRODUCT_CONTEXT == TRUE
ACTION_TRACE_EXISTS == TRUE
RESOLUTION_EVIDENCE_PRESENT == TRUE
CS4_VERDICT == RESOLVED
OPEN_CRITICAL_FINDING == FALSE
```

If verification is impossible:
```text
WAITING_CUSTOMER | UNRESOLVED | ESCALATION_REQUIRED
```

Never close merely to improve support metrics.

---

# 21. Retry & Escalation Doctrine

Maximum autonomous repair cycle: 3.

Retry only the failed scope:
- retrieval failure → retrieval;
- tool action failure → tool action;
- explanation incorrect → response correction;
- missing evidence → request evidence;
- unresolved product defect → escalate, do not keep troubleshooting indefinitely.

Repeated unresolved case → CS5 / designated human path.

No duplicate customer messages from workflow retries.

---

# 22. Cost & Run Telemetry

Record:
```text
CASE_ID
TASK_ID
AGENT
MODEL
CHANNEL
INPUT_TOKENS
OUTPUT_TOKENS
MODEL_COST
TOOL_COST
RETRY_COUNT
DURATION
RESULT
ESCALATION
TIMESTAMP
```

Track cost per resolved case, escalation, support category, and repeated issue.

---

# 23. Cross-Department Contracts

### CS → Engineering
Verified reproduction/evidence pack for technical defect candidates.

### Engineering → CS
Confirmed status, fix/release reference, safe customer-facing explanation.

### CS → Product Intelligence
Recurring pain/request patterns with case counts and evidence.

### Sales & CRM → CS
Converted/onboarding customer issue with account and prior-action context.

### CS → Sales & CRM
Commercial/billing/plan issue that belongs to commercial ownership.

---

# 24. Implementation Phases

1. Canonical case schema + identity/deduplication.
2. CS1 Intake.
3. CS2 Triage.
4. CS3 grounded resolution using active knowledge.
5. CS4 independent Resolution Gate.
6. CS5 Engineering/PI/commercial handoffs.
7. CS6 knowledge-learning loop.
8. Circuit breakers, telemetry, regression tests.
9. Controlled channel expansion.

Start with one support channel and a constrained knowledge domain.

---

# 25. Hard Prohibitions

Customer Service must not:
- fabricate a resolution;
- say a fix is deployed before verification;
- silently close unresolved cases;
- perform destructive account/data actions without authorization;
- expose one customer's data to another;
- endlessly troubleshoot a confirmed Engineering defect;
- let stale support knowledge override Product Truth;
- send duplicate messages because of retries;
- rewrite Product Truth from support anecdotes;
- optimize closure rate by misclassifying cases.

---

# 26. Final Definition of Done

Department V1 is ready when:
- CS1–CS6 boundaries are enforced;
- one canonical case record exists;
- case deduplication works;
- current Product Truth/Knowledge retrieval works;
- CS4 Resolution Gate works;
- Engineering/PI/Sales handoffs are structured;
- retry limits/circuit breakers work;
- telemetry/cost records persist;
- stale knowledge is excluded from normal retrieval;
- no case can be falsely closed by bypassing verification.

