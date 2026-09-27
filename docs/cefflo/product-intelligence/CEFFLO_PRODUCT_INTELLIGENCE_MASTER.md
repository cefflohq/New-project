# CEFFLO Product Intelligence Department — Master Specification

**Status:** MASTER BASELINE  
**Date:** 2026-09-19  
**Department Prefix:** `PI`  
**Control Plane:** n8n  
**Owner:** Founder / CEFFLO

---

## 0. Mission

Product Intelligence turns real product usage, customer feedback, operational friction, support signals, sales objections, and market evidence into grounded product decisions for CEFFLO.

Canonical loop:

```text
Observe → Collect → Analyze → Discover → Prioritize → Specify → Validate → Learn
```

Product Intelligence does **not** build production code. Engineering builds. Product Intelligence determines what the evidence says, what problem is worth solving, and what a sufficiently grounded requirement should contain.

---

# 1. Department Agents

## PI1 — Usage
**Function:** Product analytics and behavioral signals.

Reads authorized product telemetry and operational data to understand:
- feature adoption;
- workflow completion;
- drop-off;
- repeated actions;
- error/friction patterns;
- product-surface usage;
- vendor/driver/customer workflow behavior;
- cohort differences where appropriate.

Outputs:
- `USAGE_SIGNAL`
- funnel/cohort summaries;
- anomaly candidates;
- evidence references.

PI1 must not infer user intent solely from clicks or silently change Product Truth.

## PI2 — Feedback
**Function:** Voice-of-customer intelligence.

Collects and structures:
- Customer Service themes;
- Founder feedback;
- vendor/driver/customer feedback;
- survey/interview findings;
- recurring questions;
- feature requests;
- complaints;
- Sales & CRM objections.

Outputs:
- `FEEDBACK_SIGNAL`
- clustered themes;
- frequency/severity;
- affected audience/workflow;
- evidence.

Feedback ≠ requirement automatically.

## PI3 — Discovery
**Function:** Problem discovery and synthesis.

Combines PI1 + PI2 + relevant Product Truth and market evidence to determine:
- what the underlying problem is;
- who experiences it;
- where in the lifecycle it occurs;
- evidence strength;
- whether the issue is product, UX, education, support, reliability, or another category.

Outputs:
- `PROBLEM_RECORD`
- problem statement;
- evidence bundle;
- affected lifecycle/surface;
- confidence;
- unresolved questions.

## PI4 — Prioritize
**Function:** Product opportunity prioritization.

Evaluates validated problems using transparent evidence such as:
- frequency;
- severity;
- affected users/workflows;
- strategic relevance;
- operational risk;
- revenue/activation/retention relevance where evidenced;
- dependency/effort input from Engineering.

Outputs:
- ordered planning candidates for Founder review;
- rationale and uncertainty;
- `PRIORITY_CANDIDATE`.

PI4 does not independently commit CEFFLO to a roadmap.

## PI5 — Requirements
**Function:** Product requirements and Engineering handoff.

Converts an approved problem/opportunity into an implementation-ready requirement pack:
- problem;
- users;
- current behavior;
- desired outcome;
- scope;
- non-goals;
- lifecycle impact;
- states/actions;
- terminology;
- acceptance criteria;
- dependencies;
- evidence;
- unresolved decisions.

Outputs:
- `PRODUCT_REQUIREMENT`
- Engineering Handoff Pack.

PI5 must not invent capabilities or implementation details that Engineering has not validated.

## PI6 — Validate
**Function:** Outcome validation.

After Engineering ships an approved change, PI6 checks whether the intended product outcome occurred using:
- usage evidence;
- support/feedback evidence;
- expected acceptance/outcome metrics;
- regression/friction signals.

Outputs:
- `VALIDATION_RESULT`
- `IMPROVED | NO_CLEAR_CHANGE | REGRESSED | INCONCLUSIVE`
- follow-up learning.

PI6 validates outcome, not Engineering code quality.

---

# 2. Canonical Flow

```text
Product Usage ─────► PI1 Usage ────┐
                                   │
Customer Service ─► PI2 Feedback ──┤
Sales & CRM ──────► PI2 Feedback ──┤
Founder ──────────► PI2 Feedback ──┤
                                   ▼
                             PI3 Discovery
                                   │
                                   ▼
                             PI4 Prioritize
                                   │
                              Founder Gate
                                   │
                                   ▼
                            PI5 Requirements
                                   │
                                   ▼
                              ENGINEERING
                                   │
                                 SHIPPED
                                   │
                                   ▼
                              PI6 Validate
                                   │
                                   └────► Product Learning
```

---

# 3. Context Sources

Product Intelligence retrieves current context; it does not rely on chat memory.

Required sources:
1. Product Truth.
2. Founder Decision Ledger.
3. Product telemetry.
4. Customer Service signals.
5. Sales & CRM signals.
6. Relevant Marketing research where applicable.
7. Existing problem/requirement history.
8. Engineering dependency/effort evidence.
9. Validation history.

Precedence:
```text
Current Founder Instruction
→ Active Founder Decision
→ Product Truth
→ Verified product evidence
→ Approved requirement
→ Derived learning
→ historical evidence
```

---

# 4. IDs

```text
PI-TASK-0001
USG-0001
FDB-0001
PRB-0001
PRI-0001
REQ-0001
VAL-0001
PILEARN-0001
```

Every requirement must trace backward to problem/evidence and forward to Engineering work and validation.

---

# 5. State Machine

```text
NEW
CONTEXT_BUILD
COLLECTING
ANALYZING
PROBLEM_CANDIDATE
EVIDENCE_REVIEW
PRIORITY_REVIEW
FOUNDER_GATE
REQUIREMENT_BUILD
READY_FOR_ENGINEERING
IN_ENGINEERING
SHIPPED
VALIDATING
LEARNING
CLOSED
HOLD
FAILED
PAUSED_SYSTEM_GUARD
```

---

# 6. Founder Gates

Required for:
- roadmap commitment;
- material scope choice with competing product directions;
- new canonical Product Truth;
- major lifecycle/terminology change;
- destructive product removal;
- ambiguous high-impact requirement.

Normal evidence collection and analysis remain autonomous.

---

# 7. Department Boundaries

Product Intelligence:
- **does** identify, ground, prioritize candidates, specify approved requirements, validate outcomes;
- **does not** write/deploy production code;
- **does not** run Marketing campaigns;
- **does not** own Sales follow-up;
- **does not** resolve support tickets;
- **does not** silently create roadmap commitments.

Engineering receives requirements from PI5 and returns implementation/dependency evidence.

Customer Service and Sales & CRM provide structured signals, not direct roadmap commands.

---

# 8. Storage

Recommended dynamic records in Supabase:
```text
pi_usage_signals
pi_feedback_signals
pi_problems
pi_priority_candidates
pi_requirements
pi_validations
pi_learnings
pi_agent_runs
pi_state_transitions
pi_cost_events
```

Canonical Product Truth and approved human-readable requirements/decisions should remain version controlled.

---

# 9. Clean Context Doctrine

> One active Product Intelligence architecture. One current requirement path. No patch mountain.

Do not keep obsolete requirements, duplicate problem definitions, or superseded product-analysis rules in normal runtime retrieval.

When a requirement is superseded, active retrieval returns the current version. History remains available through version history/audit storage only when specifically needed.

---

# 10. Definition of Done

A Product Intelligence task is complete only when:
1. evidence is traceable;
2. the affected user/workflow is identified;
3. observation is separated from interpretation;
4. confidence/uncertainty is recorded;
5. approved work has a clear requirement;
6. Engineering receives one canonical handoff;
7. shipped changes are validated when validation is required;
8. learning is persisted.

**Signal ≠ problem. Problem ≠ requirement. Requirement ≠ roadmap commitment. Shipped ≠ validated.**

---

# 11. Model Strategy

Role definitions are canonical; model/provider assignments are runtime configuration.

Recommended strategy:
- PI1 Usage: efficient analytical model + SQL/analytics tools.
- PI2 Feedback: efficient language model + clustering/retrieval.
- PI3 Discovery: stronger reasoning model when evidence synthesis is complex.
- PI4 Prioritize: reasoning model, but prioritization inputs and formulas remain inspectable.
- PI5 Requirements: strong reasoning/specification model.
- PI6 Validate: independent analytical model where practical.

Do not escalate models automatically. Diagnose missing evidence, bad context, query defects, or tool failures first.

---

# 12. Tools & Permission Matrix

| Capability | PI1 | PI2 | PI3 | PI4 | PI5 | PI6 |
|---|---:|---:|---:|---:|---:|---:|
| Product Truth read | Scoped | Scoped | Full relevant | Full relevant | Full relevant | Full relevant |
| Usage analytics | Full | Relevant | Relevant | Summary | Relevant | Full |
| Feedback/support signals | No | Full | Full relevant | Summary | Relevant | Full relevant |
| Sales objections/signals | No | Full | Full relevant | Summary | Relevant | Relevant |
| Research evidence | No | Relevant | Full relevant | Summary | Relevant | Relevant |
| Create signal | Usage | Feedback | No | No | No | Validation |
| Create problem record | No | No | Yes | No | No | No |
| Create priority candidate | No | No | No | Yes | No | No |
| Create requirement | No | No | No | No | Yes | No |
| Approve roadmap | No | No | No | No | No | No |
| Production code/deploy | No | No | No | No | No | No |
| Change Product Truth | No | No | No | No | No | No |
| Raw credentials | No | No | No | No | No | No |

n8n/tooling executes privileged reads/actions. Models do not receive raw secrets.

---

# 13. Requirement Gate

Before `READY_FOR_ENGINEERING`, n8n performs a deterministic Requirement Gate.

Required:
```text
APPROVED_PROBLEM == TRUE
CURRENT_PRODUCT_CONTEXT == TRUE
SCOPE_DEFINED == TRUE
NON_GOALS_DEFINED == TRUE
ACCEPTANCE_CRITERIA_PRESENT == TRUE
DEPENDENCIES_RECORDED == TRUE
TERMINOLOGY_VALID == TRUE
UNRESOLVED_FOUNDER_DECISIONS == FALSE
TRACEABLE_EVIDENCE == TRUE
```

Failure routes to PI5 or HOLD/Founder Gate. This is a gate, not a seventh agent.

---

# 14. Retry & Escalation Doctrine

Maximum autonomous repair cycle: 3 attempts.

1. Correct missing/incorrect evidence or query.
2. Rebuild the affected analysis/specification only.
3. Stop and set `ESCALATION_REQUIRED`.

Diagnose before retrying:
- missing telemetry;
- bad segmentation/query;
- contradictory feedback;
- stale Product Truth;
- insufficient sample;
- tool/provider failure;
- genuine model limitation.

Never manufacture certainty to escape an inconclusive state.

---

# 15. Cost & Run Telemetry

Record:
```text
TASK_ID
AGENT
MODEL
TOOL
INPUT_TOKENS
OUTPUT_TOKENS
TOOL_COST
MODEL_COST
DURATION
RETRY_COUNT
RESULT
EVIDENCE_COUNT
TIMESTAMP
```

Track cost per validated problem, approved requirement, and completed validation.

---

# 16. Circuit Breakers

Enter `PAUSED_SYSTEM_GUARD` or HOLD when:
- telemetry integrity is suspect;
- abnormal query volume/cost occurs;
- repeated contradictory Product Truth is retrieved;
- duplicate requirement creation spikes;
- repeated agent/tool failures occur;
- evidence is too weak for the requested decision;
- a workflow attempts to bypass Founder/Requirement Gate.

No blind retries.

---

# 17. Cross-Department Contracts

### Customer Service → PI
Recurring case evidence, severity pattern, workflow, workaround.

### Sales & CRM → PI
Repeated objections, lost-opportunity reasons, requested capabilities, segment evidence.

### Marketing → PI
Market/research signals only when relevant; marketing performance does not define Product Truth.

### PI → Engineering
One canonical approved Requirement Pack.

### Engineering → PI
Dependency/effort evidence, shipped version, implementation status, verified release reference.

---

# 18. Implementation Phases

1. Schema + IDs + state transitions.
2. PI1/PI2 evidence ingestion.
3. PI3 problem synthesis.
4. PI4 prioritization candidates + Founder Gate.
5. PI5 requirement contract + deterministic Requirement Gate.
6. Engineering handoff.
7. PI6 post-ship validation.
8. Telemetry, cost controls, circuit breakers, regression tests.

Pilot one real product problem before broad automation.

---

# 19. Hard Prohibitions

Product Intelligence must not:
- invent telemetry or feedback;
- infer motivation as fact;
- convert one request directly into roadmap;
- fabricate confidence/sample size;
- bypass Founder Gate;
- write/deploy production code;
- silently modify Product Truth;
- duplicate an active canonical requirement;
- keep superseded requirements in normal runtime context.

---

# 20. Final Definition of Done

Department V1 is ready when:
- PI1–PI6 boundaries are enforced;
- evidence is traceable;
- Requirement Gate works;
- Founder Gates work;
- Engineering receives one canonical handoff;
- post-ship validation is recorded;
- retry limits and circuit breakers work;
- telemetry/cost records persist;
- superseded context is excluded by default.

