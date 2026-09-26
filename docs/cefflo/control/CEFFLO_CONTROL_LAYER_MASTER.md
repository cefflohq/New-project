# CEFFLO Control Layer — Master Specification

**Status:** MASTER BASELINE  
**Date:** 2026-09-19  
**Scope:** Company-wide AI orchestration and governance  
**Primary Control Plane:** n8n  
**Owner / Final Authority:** Founder  
**Child Departments:** Engineering · Product Intelligence · Marketing · Sales & CRM · Customer Service

---

# 0. Purpose

The CEFFLO Control Layer is the company-level operating control plane for CEFFLO's AI-assisted departments.

It is **not a sixth department** and **not another general-purpose AI agent**.

Its responsibilities are to:

- receive work and events;
- determine the correct workflow/department;
- assemble only current and relevant context;
- enforce permissions and Founder Gates;
- manage state transitions;
- coordinate cross-department handoffs;
- control model/tool usage and cost;
- detect loops, anomalies, stale context, and unsafe actions;
- preserve traceability and audit evidence;
- surface company-level status to the Founder.

Canonical principle:

> **Agents reason. Control Layer governs. Tools execute. Company Truth grounds. Founder decides exceptions.**

---

# 1. Company Architecture

```text
                              FOUNDER
                                 │
                                 ▼
                    CEFFLO CONTROL LAYER
                                 │
          ┌──────────────┬───────┼───────┬──────────────┐
          ▼              ▼       ▼       ▼              ▼
     Engineering     Product   Marketing Sales & CRM Customer Service
       E1–E5         PI1–PI6    M1–M6      S1–S6       CS1–CS6
          │              │       │       │              │
          └──────────────┴───────┼───────┴──────────────┘
                                 ▼
                       SHARED COMPANY TRUTH
                                 │
                ┌────────────────┼────────────────┐
                ▼                ▼                ▼
              GitHub          Supabase       Object Storage
                │                │                │
                └────────────────┼────────────────┘
                                 ▼
                       TOOLS / INTEGRATIONS
```

Department Master Specifications remain authoritative for internal department behavior.

The Control Layer governs interaction **between** those departments and the company-wide execution environment.

---

# 2. Canonical Department Registry

```text
ENGINEERING
Prefix: E
Agents: E1–E5

PRODUCT_INTELLIGENCE
Prefix: PI
Agents: PI1–PI6

MARKETING
Prefix: M
Agents: M1–M6

SALES_CRM
Prefix: S
Agents: S1–S6

CUSTOMER_SERVICE
Prefix: CS
Agents: CS1–CS6
```

Every department must register:

```text
DEPARTMENT_ID
MASTER_SOT_VERSION
ACTIVE_AGENTS
SUPPORTED_TASK_TYPES
INPUT_CONTRACTS
OUTPUT_CONTRACTS
PERMISSIONS
FOUNDER_GATES
STATE_MACHINE
COST_POLICY
ACTIVE_STATUS
```

No unregistered department or agent may execute privileged company actions.

---

# 3. Control Layer Components

## CL1 — Intake & Task Router

Deterministic company entry point.

Accepts:
- Founder commands;
- scheduled jobs;
- webhooks;
- department events;
- system alerts;
- approved external integration events.

Creates:

```text
COMPANY_TASK_ID
SOURCE
TASK_TYPE
REQUESTED_OUTCOME
OWNER_DEPARTMENT
PRIORITY
RISK_CLASS
CREATED_AT
```

Routing should use deterministic rules first. AI classification may assist only when routing is genuinely ambiguous.

---

## CL2 — Context Builder

Builds a scoped Context Pack for the assigned workflow.

It retrieves only what the task requires.

Example:

```text
Engineering Task
→ Engineering Master
→ Product Truth subset
→ approved requirement
→ repository/branch truth
→ relevant UI reference
→ Founder decisions affecting scope
```

It must not inject unrelated CRM, Marketing history, old SOTs, or obsolete implementation.

---

## CL3 — Company Truth Resolver

Resolves the current canonical source before execution.

Company truth domains may include:

```text
FOUNDER_DECISIONS
PRODUCT_TRUTH
BRAND_TRUTH
PRICING_COMMERCIAL_TRUTH
ENGINEERING_TRUTH
MARKETING_TRUTH
CRM_TRUTH
SUPPORT_TRUTH
DEPARTMENT_SOT
INTEGRATION_CONFIG
```

Canonical precedence:

```text
Current explicit Founder instruction
→ ACTIVE Founder Decision
→ Current canonical domain truth
→ Current approved task/requirement
→ Verified runtime evidence
→ derived learning
→ historical evidence
```

Historical evidence cannot silently override current truth.

---

## CL4 — Permission Engine

Every tool/action has a permission classification.

```text
READ
CREATE
UPDATE
SEND
PUBLISH
DEPLOY
SPEND
DELETE
CHANGE_TRUTH
SECURITY_SENSITIVE
FINANCIAL
```

The engine checks:

```text
WHO
WHAT
RESOURCE
SCOPE
ENVIRONMENT
RISK
CURRENT_STATE
REQUIRED_GATE
```

Agents request actions. The controlled tool layer executes only authorized actions.

Raw secrets/credentials are never placed into model context.

---

## CL5 — State Engine

Company-level state machine:

```text
NEW
ROUTING
CONTEXT_BUILD
CONTEXT_READY
EXECUTING
VERIFYING
GATE_REQUIRED
WAITING_FOUNDER
APPROVED
HANDOFF
COMPLETED
HOLD
ESCALATION_REQUIRED
FAILED
CANCELLED
PAUSED_SYSTEM_GUARD
```

Child department workflows retain their own detailed states.

Every transition records:

```text
TASK_ID
FROM_STATE
TO_STATE
ACTOR
REASON
EVIDENCE
TIMESTAMP
```

---

## CL6 — Founder Gate Manager

Founder intervention is reserved for material exceptions/decisions.

Typical Founder Gates:

```text
CANONICAL_TRUTH_CHANGE
MAJOR_PRODUCT_DIRECTION
DESTRUCTIVE_PRODUCTION_ACTION
PAID_MEDIA_SPEND
NON_STANDARD_COMMERCIAL_TERM
SENSITIVE_PUBLIC_RESPONSE
HIGH_IMPACT_SECURITY_ACTION
UNRESOLVED_CROSS_DEPARTMENT_CONFLICT
```

A Founder Gate contains:

```text
GATE_ID
TASK_ID
DECISION_REQUIRED
OPTIONS
RECOMMENDED_FACTS
IMPACT
COST/RISK
EVIDENCE
REQUESTING_DEPARTMENT
STATUS
```

The system should minimize unnecessary Founder interruptions.

---

## CL7 — Cross-Department Event Bus

Departments communicate through structured events rather than uncontrolled agent-to-agent chat.

Canonical event envelope:

```text
EVENT_ID
EVENT_TYPE
SOURCE_DEPARTMENT
SOURCE_ENTITY_ID
TARGET_DEPARTMENT
PAYLOAD_VERSION
PAYLOAD
EVIDENCE_REFS
CREATED_AT
IDEMPOTENCY_KEY
```

Initial company event types:

```text
CUSTOMER_ISSUE_DETECTED
SUPPORT_PATTERN_DETECTED
PRODUCT_SIGNAL_CREATED
PROBLEM_VALIDATED
REQUIREMENT_APPROVED
ENGINEERING_TASK_CREATED
ENGINEERING_SHIPPED
PRODUCT_VALIDATION_COMPLETED
LEAD_CREATED
LEAD_QUALIFIED
CUSTOMER_CONVERTED
ONBOARDING_BLOCKED
CONTENT_APPROVED
CONTENT_PUBLISHED
MARKETING_SIGNAL_CREATED
COMMERCIAL_OBJECTION_DETECTED
SYSTEM_ALERT
FOUNDER_DECISION_CREATED
```

Event schemas are versioned.

---

## CL8 — Model Router

Models are runtime providers, not architecture.

Routing considers:

```text
TASK_TYPE
REASONING_COMPLEXITY
CONTEXT_SIZE
MULTIMODAL_NEED
LATENCY
COST
PRIVACY
RECENT_FAILURE
MODEL_CAPABILITY
```

Default policy:

```text
Use the lowest-cost model that reliably satisfies the task.
Escalate only after diagnosis.
```

Do not retry the same failed prompt/model blindly.

---

## CL9 — Tool Gateway

All external actions pass through controlled integrations.

Examples:
- GitHub;
- Supabase;
- email;
- messaging;
- publishing platforms;
- analytics;
- deployment;
- media generation;
- storage;
- payment/commercial systems where approved.

Tool call envelope:

```text
TOOL_CALL_ID
TASK_ID
AGENT
TOOL
ACTION
RESOURCE
PERMISSION
INPUT_HASH
IDEMPOTENCY_KEY
STARTED_AT
COMPLETED_AT
RESULT
COST
```

Privileged operations must be auditable.

---

## CL10 — Cost & Usage Guard

Tracks:

```text
MODEL_COST
TOOL_COST
TOKENS
MEDIA_GENERATION_COST
RETRY_COST
DEPARTMENT_COST
TASK_COST
DAILY_COST
MONTHLY_COST
```

Guard levels:

```text
NORMAL
WARNING
THROTTLE
FOUNDER_GATE
PAUSED_SYSTEM_GUARD
```

Cost limits are configurable and must not be hard-coded into agent prompts.

---

## CL11 — Audit & Observability

Company-level observability should expose:

```text
ACTIVE_TASKS
TASKS_BY_DEPARTMENT
WAITING_FOUNDER
FAILED_RUNS
PAUSED_WORKFLOWS
SYSTEM_ALERTS
COST_TODAY
COST_MONTH
RETRY_RATE
MODEL_USAGE
TOOL_USAGE
OPEN_ESCALATIONS
RECENT_DEPLOYMENTS
RECENT_PUBLICATIONS
OPEN_SUPPORT_CASES
ACTIVE_LEADS
```

The Founder Command Center consumes this layer.

---

## CL12 — System Guard / Circuit Breaker

Immediately pause affected workflows when detecting:

- uncontrolled retry loop;
- duplicate send/publish/deploy risk;
- abnormal token/API spend;
- unexpected mass record mutation;
- stale/conflicting canonical truth;
- authentication/credential failure;
- repeated model/tool failure;
- event storm;
- invalid permission escalation;
- production destructive action without gate;
- abnormal outbound communication volume;
- broken idempotency;
- cross-department recursion.

Default safe state:

```text
PAUSED_SYSTEM_GUARD
```

Recovery requires diagnosis, evidence, and an explicit controlled resume.

---

# 4. Company Task Contract

Every meaningful execution begins with one canonical task record.

```text
COMPANY_TASK_ID
PARENT_TASK_ID
SOURCE
REQUESTER
TASK_TYPE
OBJECTIVE
OWNER_DEPARTMENT
OWNER_AGENT
RISK_CLASS
PRIORITY
CONTEXT_VERSION
CURRENT_STATE
FOUNDER_GATE
BUDGET
RETRY_COUNT
CREATED_AT
UPDATED_AT
CLOSED_AT
```

Subtasks reference their parent.

No department creates an unrelated duplicate company task when a child task is sufficient.

---

# 5. Context Architecture

## Layer A — Immutable/Canonical Truth

Version-controlled human-readable truth:
- department Master SOTs;
- Product Truth;
- Brand Truth;
- approved architecture;
- active Founder Decisions;
- canonical terminology/contracts.

Recommended home: GitHub.

## Layer B — Dynamic Operational Truth

Examples:
- tasks;
- state;
- CRM;
- support cases;
- analytics;
- events;
- execution logs;
- cost records;
- validation results.

Recommended home: Supabase/Postgres.

## Layer C — Large Assets

Examples:
- screenshots;
- videos;
- design references;
- generated media;
- support attachments;
- exports.

Recommended home: object storage.

## Layer D — External Live Systems

Accessed through tools/integrations only when required.

---

# 6. Context Pack Contract

Every model invocation receives a scoped pack:

```text
TASK_ID
ROLE
OBJECTIVE
CURRENT_STATE
CURRENT_CANONICAL_RULES
RELEVANT_ENTITY_DATA
RELEVANT_EVIDENCE
ALLOWED_ACTIONS
FORBIDDEN_ACTIONS
OUTPUT_SCHEMA
CONTEXT_VERSION
```

Explicitly exclude by default:

```text
SUPERSEDED
DEPRECATED
LEGACY
ARCHIVED
OLD_PROMPT
OLD_WORKFLOW
DUPLICATE_SOT
UNRELATED_DEPARTMENT_CONTEXT
```

---

# 7. Clean Replacement & Context Hygiene Doctrine

> **REPLACE > PATCH when a system is materially superseded.**

> **One active architecture. One canonical truth path. No patch mountain.**

For materially replaced workflows/components/prompts/SOTs:

1. identify the canonical replacement;
2. map real dependencies;
3. implement clean replacement;
4. switch consumers;
5. verify behavior;
6. confirm required dependencies;
7. deactivate/remove obsolete runtime implementation;
8. audit dead references/duplicate logic;
9. exclude superseded context from normal retrieval.

Git/version history preserves history. Runtime context does not need to carry obsolete architecture.

---

# 8. Idempotency

Any action with external or duplicate-risk effects requires an idempotency key.

Mandatory for:
- messages;
- publishing;
- deploys;
- CRM record creation;
- payments/financial operations if introduced;
- cross-department events;
- destructive mutations;
- scheduled actions.

Retrying must not duplicate the external effect.

---

# 9. Retry Doctrine

Company maximum autonomous repair attempts:

```text
MAX_RETRY = 3
```

Retries are targeted, not full-workflow blind reruns.

Sequence:

```text
FAIL
→ DIAGNOSE
→ TARGETED_REPAIR
→ VERIFY
```

After three unsuccessful repair attempts:

```text
ESCALATION_REQUIRED
```

A circuit-breaker condition overrides the retry budget and pauses immediately.

---

# 10. Verification Doctrine

Self-claim is not proof.

Verification should be independent where material.

Evidence examples:
- test output;
- build result;
- screenshot/render;
- API response;
- database state;
- publication ID;
- CRM event;
- delivery status;
- analytics query;
- support resolution evidence.

A task may only transition to `COMPLETED` when its department-specific Definition of Done is satisfied.

---

# 11. Cross-Department Routing

## Customer Service → Product Intelligence

Recurring support pain:
```text
CS
→ SUPPORT_PATTERN_DETECTED
→ PI
```

## Product Intelligence → Engineering

Approved product requirement:
```text
PI
→ REQUIREMENT_APPROVED
→ Engineering
```

## Engineering → Product Intelligence

Verified shipped change:
```text
Engineering
→ ENGINEERING_SHIPPED
→ PI6 validation
```

## Marketing → Sales & CRM

Qualified/consented lead signal:
```text
Marketing
→ LEAD_CREATED
→ Sales & CRM
```

## Sales & CRM → Customer Service

Customer/onboarding support issue:
```text
Sales
→ CUSTOMER_ISSUE_DETECTED
→ CS
```

## Sales & CRM → Product Intelligence

Repeated objection/product gap:
```text
Sales
→ COMMERCIAL_OBJECTION_DETECTED
→ PI
```

No direct cross-department command bypasses the Control Layer.

---

# 12. Founder Decision Ledger

Founder decisions are first-class records.

```text
DECISION_ID
DOMAIN
DECISION
STATUS
EFFECTIVE_AT
SUPERSEDES
EVIDENCE/CONTEXT
CREATED_AT
```

Statuses:

```text
ACTIVE
SUPERSEDED
REVOKED
EXPERIMENTAL
```

Normal runtime retrieval uses `ACTIVE` decisions relevant to the task.

---

# 13. Permission Classes

## P0 — Read

Low-risk scoped reads.

## P1 — Internal Create/Update

Internal task/event/analysis records.

## P2 — External Reversible Action

Routine approved sends/publishing/tool actions with logs and idempotency.

## P3 — Material Action

Deployments, broad outbound actions, commercial changes, sensitive account changes.

Requires explicit department policy and may require a gate.

## P4 — High-Impact / Destructive / Financial / Canonical

Examples:
- destructive production mutation;
- major spend;
- non-standard financial commitment;
- canonical Product/Brand/Architecture truth change.

Founder Gate required unless a future explicit policy delegates the exact action.

---

# 14. Security & Secrets

Rules:

- secrets stay in credential stores/environment/integration vaults;
- models receive references/capabilities, never raw secrets;
- least privilege per tool;
- production and staging permissions separated;
- sensitive data is scoped to task need;
- every privileged mutation is logged;
- credential rotation must not require prompt changes;
- agents cannot grant themselves permissions.

---

# 15. Data Minimization

Only retrieve data required for the current task.

Examples:

```text
Marketing copy task
≠ entire CRM database

Engineering UI fix
≠ customer support history

Support case
≠ entire Git repository

Sales follow-up
≠ all Product Intelligence raw research
```

This reduces privacy exposure, latency, confusion, and token cost.

---

# 16. Company Storage Schema

Recommended core tables:

```text
control_tasks
control_subtasks
control_events
control_state_transitions
control_context_versions
control_founder_gates
control_founder_decisions
control_tool_calls
control_model_calls
control_cost_events
control_permissions
control_department_registry
control_agent_registry
control_alerts
control_incidents
control_audit_log
```

Department-specific tables remain owned by department schemas.

---

# 17. Company IDs

```text
CTASK-000001
CEVT-000001
CGATE-000001
CDEC-000001
CTOOL-000001
CMODEL-000001
CALERT-000001
CINC-000001
CTX-000001
```

Department IDs remain unchanged:

```text
E-...
PI-...
M-...
S-...
CS-...
```

---

# 18. n8n Workflow Architecture

Recommended company workflows:

```text
CEFFLO-CTRL-00  Intake Router
CEFFLO-CTRL-01  Context Builder
CEFFLO-CTRL-02  Truth Resolver
CEFFLO-CTRL-03  Permission Gate
CEFFLO-CTRL-04  Department Dispatcher
CEFFLO-CTRL-05  Event Bus
CEFFLO-CTRL-06  Founder Gate
CEFFLO-CTRL-07  Model Router
CEFFLO-CTRL-08  Tool Gateway
CEFFLO-CTRL-09  Retry / Escalation
CEFFLO-CTRL-10  Cost Guard
CEFFLO-CTRL-11  Observability
CEFFLO-CTRL-12  System Guard
CEFFLO-CTRL-99  Recovery / Admin
```

These are logical responsibilities. Implementation may consolidate workflows where doing so remains clear, testable, and maintainable.

Do not create workflow sprawl merely to mirror this list.

---

# 19. Founder Command Center Contract

The Control Layer should eventually expose a Founder view such as:

```text
TODAY

Engineering              active / blocked / shipped
Product Intelligence     signals / requirements / validation
Marketing                creating / approved / published
Sales & CRM              leads / opportunities / onboarding
Customer Service         open / escalated / resolved

Founder Gates            waiting
System Alerts            active
Failed Runs              count
Paused Workflows         count

AI/API Cost Today
AI/API Cost Month

Recent:
- deployments
- publications
- conversions
- product findings
- major support issues
```

The dashboard reads Control Layer truth; it does not create an independent shadow state.

---

# 20. Company-Level Metrics

Track:

```text
TASK_SUCCESS_RATE
TASK_CYCLE_TIME
RETRY_RATE
ESCALATION_RATE
FOUNDER_INTERRUPTION_RATE
CONTEXT_TOKENS_PER_TASK
MODEL_COST_PER_TASK
TOOL_COST_PER_TASK
COST_BY_DEPARTMENT
FAILED_TOOL_RATE
DUPLICATE_ACTION_PREVENTED
CIRCUIT_BREAKER_EVENTS
STALE_CONTEXT_BLOCKS
CROSS_DEPARTMENT_HANDOFF_TIME
```

Optimization goal:

> Increase useful autonomous completion while preserving correctness, Founder control, traceability, and cost discipline.

---

# 21. Failure Classes

```text
CONTEXT_FAILURE
TRUTH_CONFLICT
MODEL_FAILURE
TOOL_FAILURE
PERMISSION_FAILURE
INTEGRATION_FAILURE
VERIFICATION_FAILURE
COST_GUARD_FAILURE
IDEMPOTENCY_FAILURE
STATE_FAILURE
CROSS_DEPARTMENT_FAILURE
SECURITY_GUARD_FAILURE
```

Failures are classified before repair.

---

# 22. Recovery

Recovery process:

```text
PAUSE
→ IDENTIFY AFFECTED TASKS
→ CLASSIFY ROOT CAUSE
→ VERIFY CANONICAL TRUTH
→ REPAIR MINIMUM SCOPE
→ TEST
→ RECONCILE STATE
→ CONTROLLED RESUME
→ POST-INCIDENT RECORD
```

Do not resume from an unknown state.

---

# 23. Department Independence

The Control Layer must not absorb department reasoning.

Examples:

- Engineering decides implementation within its Master SOT.
- Product Intelligence performs product discovery/requirements.
- Marketing creates and validates marketing work.
- Sales & CRM manages commercial lifecycle.
- Customer Service resolves and escalates support cases.

Control Layer governs routing, context, permissions, state, cost, and audit.

This prevents a monolithic "super-agent."

---

# 24. No Free Agent-to-Agent Chat

Unstructured autonomous cross-agent conversations are prohibited as the default architecture.

Use:

```text
structured task
structured event
structured evidence
structured handoff
```

This reduces:
- token waste;
- hidden decisions;
- context drift;
- recursion;
- unclear ownership;
- untraceable commitments.

---

# 25. Human Agency

The Founder remains the final authority for defined high-impact decisions.

The system may:
- assemble evidence;
- identify conflicts;
- present options;
- execute pre-authorized routine workflows.

The system must not:
- fabricate Founder approval;
- reinterpret silence as approval for gated actions;
- expand its own permissions;
- silently change canonical company truth.

---

# 26. Implementation Sequence

## Phase 1 — Registry & Schemas
Create company IDs, task/event/state schemas, department registry, audit structure.

## Phase 2 — Truth Resolver
Connect current canonical SOT/Founder/Product/Brand/Commercial truth.

## Phase 3 — Intake + Router
Create one company entry point and deterministic department routing.

## Phase 4 — Context Builder
Implement scoped role/task context packs with superseded-context exclusion.

## Phase 5 — Permission + Founder Gates
Enforce action classes and approval paths.

## Phase 6 — Department Dispatcher
Connect the five existing Department Master architectures.

## Phase 7 — Event Bus
Implement versioned cross-department contracts and idempotency.

## Phase 8 — Model + Tool Gateway
Centralize provider routing, tool permissions, audit, and credentials.

## Phase 9 — Retry + System Guard
Implement diagnosis, max-3 targeted repair, circuit breakers, recovery.

## Phase 10 — Cost + Observability
Build department/task cost telemetry and company status views.

## Phase 11 — Founder Command Center
Connect the existing Founder surface to Control Layer truth.

## Phase 12 — End-to-End Pilot
Run one real workflow across multiple departments and verify every state/handoff.

---

# 27. Recommended First End-to-End Pilot

Use a controlled product-support scenario:

```text
CS detects repeated vendor issue
        ↓
SUPPORT_PATTERN_DETECTED
        ↓
PI receives evidence
        ↓
PI validates problem
        ↓
Founder Gate if required
        ↓
PI creates approved requirement
        ↓
Engineering implements
        ↓
Engineering verifies + ships
        ↓
PI6 validates outcome
        ↓
CS knowledge updated
        ↓
Control Layer closes parent task
```

This pilot tests:
- event routing;
- context;
- Product Truth;
- Founder Gate;
- Engineering handoff;
- verification;
- post-ship validation;
- support learning;
- cost;
- audit trail.

---

# 28. Hard Prohibitions

The Control Layer must never:

- become a general-purpose super-agent;
- allow departments to bypass permission gates;
- allow uncontrolled agent-to-agent loops;
- expose raw credentials to models;
- treat old/superseded truth as active;
- execute gated actions without approval;
- retry external effects without idempotency;
- duplicate sends/publishes/deployments through retry;
- silently change canonical truth;
- allow a model to grant itself permissions;
- hide failures to keep workflows green;
- optimize cost by removing required verification;
- optimize speed by bypassing Founder Gates;
- keep obsolete workflow architecture active after verified clean replacement.

---

# 29. Acceptance Tests

Minimum tests before company-wide activation:

### Routing
- every supported task type routes correctly;
- ambiguity enters a controlled resolution path.

### Context
- only relevant current truth is loaded;
- superseded documents are excluded.

### Permissions
- unauthorized tool calls are blocked;
- permitted calls execute only within scope.

### Founder Gate
- gated action cannot proceed without explicit approval;
- approval/rejection is traceable.

### Idempotency
- repeated webhook/retry does not duplicate external effect.

### State
- invalid transitions are rejected;
- recovery reconciles state correctly.

### Cost
- model/tool usage is recorded;
- configured guard thresholds trigger.

### Circuit Breaker
- simulated loop/event storm pauses safely.

### Cross-Department
- event schema validates;
- receiving department receives correct evidence.

### Audit
- a completed task can be reconstructed from intake through final result.

---

# 30. Definition of Done

CEFFLO Control Layer V1 is ready when:

1. all five departments are registered;
2. company task IDs and state transitions work;
3. canonical truth resolution works;
4. scoped Context Packs work;
5. superseded context is excluded by default;
6. permissions are enforced outside model prompts;
7. Founder Gates block gated actions correctly;
8. cross-department events are versioned and idempotent;
9. tool calls are auditable;
10. model/tool cost is measurable by task and department;
11. targeted retry is capped at three;
12. circuit breakers pause abnormal workflows;
13. recovery can reconcile interrupted tasks;
14. Founder Command Center can consume one company-level truth;
15. at least one multi-department pilot passes end-to-end;
16. no obsolete parallel Control Layer remains active.

---

# 31. Final Lock

```text
FOUNDER
   ↓
CEFFLO CONTROL LAYER
   ↓
┌─────────────────────────────────────────────────────────────┐
│ Engineering │ Product Intelligence │ Marketing │ Sales/CRM │ Customer Service │
└─────────────────────────────────────────────────────────────┘
   ↓
SHARED COMPANY TRUTH
   ↓
CONTROLLED TOOLS & INTEGRATIONS
   ↓
AUDITABLE BUSINESS EXECUTION
```

**Agents reason. Control Layer governs. Tools execute. Company Truth grounds. Founder decides exceptions.**

**One active architecture. One canonical truth path. No patch mountain.**
