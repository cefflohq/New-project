# CEFFLO AI COMPANY OPERATING PRINCIPLES

> **Classification (D-67): CANONICAL internal operating principles.** They
> complement — and do not replace — `CEFFLO_CONTROL_LAYER_MASTER.md`, which
> remains the company AI governance/orchestration authority. They govern how
> the company behind Cefflo operates; they do not reposition the Cefflo product
> (a Local Same-Day Delivery Operating System) as a generic Agentic OS.

**Status:** Canonical Operating Principles\
**Scope:** Internal Cefflo AI Company Architecture\
**Purpose:** Define how Cefflo's AI departments operate autonomously,
safely, measurably, and with minimal founder monitoring.\
**Important:** This document does **not** reposition Cefflo as a
general-purpose "Agentic OS". Cefflo remains a **Local Same-Day Delivery
Operating System**. These principles govern how the company behind
Cefflo operates.

------------------------------------------------------------------------

## 1. Core Objective

Cefflo is designed to operate as a lean AI-native company where
increasing company output does not require founder workload to increase
at the same rate.

The internal operating model must enable:

-   autonomous execution for routine work;
-   clear and measurable outputs;
-   controlled access and permissions;
-   human approval for consequential actions;
-   cross-department coordination;
-   continuous learning from real operations;
-   exception-based founder involvement rather than constant
    supervision.

The target is not "more AI agents".

The target is:

> **A company operating system where goals become verified outputs
> through controlled AI and human execution.**

------------------------------------------------------------------------

## 2. Product Boundary

The internal AI Company architecture and the Cefflo customer product are
separate layers.

### Cefflo Product

Cefflo remains a vertical operating system for businesses running their
own local same-day delivery.

``` text
Vendor
  ↓
Orders
  ↓
Coverage
  ↓
Zones
  ↓
Delivery Plan
  ↓
Multi-drop Runs
  ↓
Riders / Drivers
  ↓
Delivered Today
```

Customer-facing surfaces remain:

-   Vendor Web/Desktop
-   Vendor Flutter Mobile
-   Driver Flutter Mobile
-   Customer Tracking PWA
-   Public Website
-   Founder Admin

Cefflo must **not** expand into a generic HR, payroll,
project-management, CRM, meeting, or general business operating system
merely to imitate horizontal AI platforms.

### Cefflo AI Company

Behind the product sits the internal operating architecture:

``` text
                    CONTROL LAYER
                         │
        ┌────────────────┼────────────────┐
        ↓                ↓                ↓
 Engineering         Marketing      Customer Service
    E1–E5             M1–M6               CS
        │                │                │
        └────────────┬───┴────────────┬───┘
                     ↓                ↓
                 Sales & CRM    Product Intelligence
                                      PI
                         │
                   Cyber Security
```

Its job is to build, operate, protect, grow, support, and continuously
improve Cefflo.

------------------------------------------------------------------------

## 3. Five Operating Principles

All active Cefflo departments and agents must follow the same five
principles:

``` text
SERVICE CONTRACT
       ↓
OUTPUT
       ↓
PERMISSION
       ↓
APPROVAL
       ↓
LEARNING LOOP
```

These principles are operating rules layered onto the existing
department architecture. They do not require rebuilding the
architecture.

------------------------------------------------------------------------

# 4. Principle 1 --- Service Contract

Every repeatable operation must have a defined contract before it is
treated as autonomous.

A service contract defines:

-   objective;
-   required inputs;
-   allowed tools and data;
-   execution process;
-   expected output;
-   acceptance criteria;
-   responsible department/agent;
-   permission boundary;
-   approval requirement;
-   failure/escalation path;
-   audit evidence.

Generic structure:

``` text
INPUT
  ↓
SERVICE / PROCESS
  ↓
RESPONSIBLE AGENT
  ↓
OUTPUT
  ↓
VERIFICATION
  ↓
COMPLETE / ESCALATE
```

An agent saying "done" is never sufficient evidence of completion.

### Example --- Engineering Release

``` text
SERVICE
Vendor Mobile Release

INPUT
Approved scope + canonical repo state

EXECUTOR
Engineering

REQUIRED OUTPUT
✓ implementation complete
✓ tests pass
✓ staging verification pass
✓ visual QA pass
✓ security checks pass
✓ clean replacement where applicable
✓ commit/push complete
✓ correct preview/release verified

FAILURE
Escalate with exact blocker and evidence
```

This converts execution from prompt-driven work into contract-driven
work.

------------------------------------------------------------------------

# 5. Principle 2 --- Output-Driven Operation

Cefflo measures completed outcomes, not agent activity.

Bad completion signals:

``` text
14 files changed
8 tasks completed
105 posts generated
20 leads reviewed
Agent reported success
```

These describe activity.

Cefflo requires verified outputs.

### Engineering

``` text
OUTPUT
Vendor Mobile — Release Ready

Tests        PASS
Staging      PASS
Visual QA    PASS
Security     PASS
Release      PASS
```

### Marketing

``` text
Content
  ↓
Distribution
  ↓
Qualified attention
  ↓
Lead
  ↓
Vendor signup
  ↓
Activated vendor
  ↓
Paid vendor
```

Generating content is not the final business output.

### Customer Service

``` text
Ticket
  ↓
Diagnosis
  ↓
Resolution
  ↓
Verified customer outcome
  ↓
Knowledge captured
```

### Sales & CRM

``` text
Lead
  ↓
Qualification
  ↓
Follow-up
  ↓
Conversion / Disqualification
  ↓
CRM state updated
```

Every department must distinguish **activity metrics** from **business
outputs**.

------------------------------------------------------------------------

# 6. Principle 3 --- Permission by Design

No AI agent receives broad company access merely because the technology
allows it.

Permissions must follow:

> **Minimum access required to complete the service contract.**

Permissions are part of agent architecture, not an afterthought.

### Example --- Marketing

Allowed:

-   approved content library;
-   campaign data;
-   marketing analytics;
-   approved publishing channels.

Not allowed by default:

-   production database;
-   deployment infrastructure;
-   customer credentials;
-   unrestricted source-code writes;
-   company billing controls.

### Example --- Customer Service

Allowed:

-   support tickets;
-   approved knowledge base;
-   relevant vendor/customer context required for support.

Not allowed by default:

-   unrelated customer records;
-   source-code deployment;
-   marketing budgets;
-   infrastructure administration.

### Example --- Engineering

Allowed according to role:

-   repository;
-   CI/CD;
-   development environment;
-   staging.

Production access must remain separately controlled.

### Cyber Security Role

Cyber Security defines and audits:

-   identity;
-   credentials;
-   secrets;
-   least privilege;
-   environment boundaries;
-   tool permissions;
-   production access;
-   audit logs;
-   revocation;
-   incident response.

An agent must never gain permissions simply because another agent has
them.

------------------------------------------------------------------------

# 7. Principle 4 --- Risk-Based Approval

Not every action requires founder approval.

Not every action should be autonomous.

Cefflo uses risk-based execution levels.

## Level 0 --- Read Only

Agent may inspect, analyse, classify, summarize, and recommend.

No external or system-changing action.

## Level 1 --- Autonomous Execution

For low-risk, repeatable, reversible operations with a clear service
contract.

Examples:

-   routine analysis;
-   approved reporting;
-   content generation within locked brand rules;
-   internal classification;
-   standard data processing.

## Level 2 --- Autonomous + Audit

Agent may execute within predefined limits.

Every action and output must be logged and reviewable.

Examples may include:

-   approved workflow execution;
-   scheduled content under locked rules;
-   routine operational updates;
-   bounded automation.

## Level 3 --- Human Approval Required

Agent prepares the action completely but cannot execute the
consequential step until approval.

Examples:

-   significant advertising budget increase;
-   production deployment when required by release policy;
-   material pricing changes;
-   sensitive customer remediation;
-   high-impact infrastructure changes.

## Level 4 --- Human Only

Reserved for actions where autonomous execution is inappropriate.

Examples may include:

-   critical security authority;
-   legal commitments;
-   irreversible financial authority;
-   root-level emergency decisions;
-   changes to fundamental company positioning.

The Control Layer determines the required approval level from the
service contract and risk policy.

------------------------------------------------------------------------

# 8. Founder-by-Exception

The Founder must not become the routing layer for routine AI work.

Bad model:

``` text
Agent → Founder → Agent
Agent → Founder → Agent
Agent → Founder → Agent
```

Target model:

``` text
Company Goal
     ↓
Control Layer
     ↓
Department
     ↓
Agent / Workflow
     ↓
Verified Output
     ↓
Audit + Knowledge
```

Founder involvement occurs when:

-   approval level requires it;
-   an operation leaves its allowed boundary;
-   acceptance criteria fail;
-   departments conflict;
-   a strategic decision is required;
-   security risk exceeds threshold;
-   financial exposure exceeds threshold;
-   company/product positioning is affected.

Founder Admin should therefore evolve toward an **exception-driven
command centre**, not a dashboard requiring continuous observation.

Example:

``` text
CEFFLO STATUS

Operations          Healthy
Engineering         Release ready
Marketing           Campaigns operating
Sales               Pipeline operating
Support             Normal
Security            No critical incident
Product Intel       New insights available

NEEDS FOUNDER

⚠ Production approval
⚠ Material spend change
⚠ Critical security event
⚠ Pricing proposal
```

The objective is minimum monitoring with maximum visibility when
intervention matters.

------------------------------------------------------------------------

# 9. Cross-Department Operating Chain

Departments must not operate as isolated AI silos.

Outputs should become structured inputs for other departments.

``` text
Engineering
     ↓
Product / Release Output
     ↓
Product Intelligence
     ↓
Product Understanding
     ↓
Marketing
     ↓
Market Activity
     ↓
Sales & CRM
     ↓
Vendor Acquisition
     ↓
Customer Service
     ↓
Support Signals
     ↓
Product Intelligence
     ↓
Insight
     ↓
Engineering
```

The Control Layer coordinates ownership, dependencies, state,
escalation, and handoff.

Cross-department communication should pass structured operational
context rather than unrestricted conversational history wherever
possible.

------------------------------------------------------------------------

# 10. Principle 5 --- Learning Loop

Every meaningful operation should improve future operations when
sufficient evidence exists.

Generic loop:

``` text
OPERATION
   ↓
OUTPUT
   ↓
RESULT
   ↓
DATA / SIGNAL
   ↓
PRODUCT INTELLIGENCE
   ↓
KNOWLEDGE
   ↓
VALIDATION
   ↓
IMPROVED RULE / PRODUCT / PROCESS
   ↓
NEXT OPERATION
   ↺
```

Cefflo must distinguish **observations** from **validated knowledge**.

AI-generated conclusions must not automatically become company truth.

Knowledge promotion requires appropriate evidence and validation.

------------------------------------------------------------------------

# 11. Cefflo Delivery Intelligence Flywheel

The most strategically valuable learning loop can eventually come from
real delivery operations.

``` text
Orders
  ↓
Zones
  ↓
Runs
  ↓
Rider execution
  ↓
Delivery times
  ↓
Exceptions / failures
  ↓
Customer outcomes
  ↓
Operational data
  ↓
Product Intelligence
  ↓
Validated patterns
  ↓
Product / operational improvement
  ↓
Better future deliveries
  ↺
```

Potential knowledge may include validated relationships between:

-   order density;
-   zone geometry;
-   run size;
-   rider capacity;
-   delivery windows;
-   route behaviour;
-   failure patterns;
-   merchant preparation timing;
-   customer availability;
-   successful delivery outcomes.

This operational knowledge can become a long-term Cefflo advantage.

It must be built from legitimate, permissioned data and validated
evidence rather than assumptions.

------------------------------------------------------------------------

# 12. Control Layer Responsibility

The Control Layer is not merely a "boss agent".

Its responsibility is orchestration and governance.

For every operation it should eventually be able to resolve:

``` text
What is the goal?
      ↓
What output proves completion?
      ↓
Which service contract applies?
      ↓
Which department owns it?
      ↓
Which agent/workflow executes it?
      ↓
What permissions are required?
      ↓
What approval level applies?
      ↓
How is output verified?
      ↓
Where is evidence logged?
      ↓
What should be learned?
```

Core responsibilities:

-   goal routing;
-   service selection;
-   department ownership;
-   dependency management;
-   output verification;
-   permission enforcement;
-   approval routing;
-   exception escalation;
-   auditability;
-   cross-department handoff;
-   learning-loop routing.

The Control Layer should avoid unnecessary reasoning or intervention
when deterministic workflows can safely perform the operation.

------------------------------------------------------------------------

# 13. Relationship With n8n

n8n remains the central workflow orchestrator where appropriate.

The operating model should separate responsibilities:

``` text
CONTROL LAYER
Decides what should happen and under what rules
        ↓
n8n / SYSTEM WORKFLOWS
Coordinates deterministic execution
        ↓
AI AGENTS
Reason, generate, classify, analyse, or act within permission
        ↓
TOOLS / SYSTEMS
Perform authorised operations
        ↓
VERIFICATION
Confirms expected output
```

AI should not replace deterministic automation where deterministic
automation is safer, cheaper, and more reliable.

------------------------------------------------------------------------

# 14. Auditability

Autonomy without evidence is not acceptable.

Important autonomous operations should capture sufficient evidence to
answer:

-   what happened;
-   when;
-   which service contract was used;
-   which agent/workflow executed it;
-   what input triggered it;
-   which tools were used;
-   what changed;
-   what output was produced;
-   whether verification passed;
-   whether human approval occurred;
-   why escalation occurred if applicable.

Audit depth should be proportional to risk.

------------------------------------------------------------------------

# 15. Failure Model

Agents must fail explicitly.

Never:

``` text
Unable to complete
→ silently continue
→ mark task complete
```

Required:

``` text
Execution
   ↓
Acceptance criteria fail
   ↓
Identify exact failed condition
   ↓
Retry only if authorised and useful
   ↓
Escalate to correct owner
   ↓
Preserve evidence
```

A failed operation with accurate evidence is preferable to a false
success.

------------------------------------------------------------------------

# 16. What Cefflo Must Not Do

These principles must **not** cause Cefflo to:

-   reposition itself as a generic Agentic OS;
-   build unrelated HR/payroll/project-management products;
-   add AI features merely because competitors use AI;
-   create agents without clear responsibility;
-   grant broad shared credentials;
-   make every operation autonomous;
-   require founder approval for every minor action;
-   accept agent self-reporting as verification;
-   turn the Control Layer into an unnecessarily complex super-agent;
-   build infrastructure before there is a real operational need;
-   interrupt the current production-readiness roadmap to implement
    speculative architecture.

------------------------------------------------------------------------

# 17. Implementation Doctrine

These principles should be introduced progressively as departments are
activated.

They are **not a reason to stop current product work and build a new
framework**.

Current priority remains product and production readiness.

When each AI Company department becomes operational:

``` text
1. Define its services
2. Define required outputs
3. Define acceptance criteria
4. Assign permissions
5. Assign approval levels
6. Define audit evidence
7. Define escalation
8. Connect cross-department handoffs
9. Add learning loops only where useful
10. Automate progressively after verification
```

Start with the smallest reliable operating contract.

Do not over-engineer hypothetical future operations.

------------------------------------------------------------------------

# 18. Department Contract Template

Every active service may use the following template.

``` text
SERVICE NAME:

OWNER:
Department / Agent

OBJECTIVE:
What business result is required?

TRIGGER:
What starts this service?

INPUT:
What information is required?

TOOLS:
What authorised systems may be used?

PROCESS:
What operation is performed?

OUTPUT:
What concrete result must exist?

ACCEPTANCE CRITERIA:
How is completion objectively verified?

PERMISSIONS:
What may the executor read/write/execute?

APPROVAL LEVEL:
0 / 1 / 2 / 3 / 4

AUDIT:
What evidence must be recorded?

FAILURE:
What constitutes failure?

ESCALATION:
Who receives the exception?

DOWNSTREAM:
Which service/department receives the output?

LEARNING:
What useful signal should be captured?
```

------------------------------------------------------------------------

# 19. Target State

The long-term internal model is:

``` text
                    FOUNDER
                       │
               Strategy / Approval
                       │
                       ▼
               ┌───────────────┐
               │ CONTROL LAYER │
               └───────┬───────┘
                       │
       ┌───────────────┼────────────────┐
       ↓               ↓                ↓
 Engineering       Marketing      Customer Service
       │               │                │
       ├───────────────┼────────────────┤
       ↓               ↓                ↓
 Product Intel     Sales & CRM     Cyber Security
       │
       └───────────────┬────────────────┘
                       ↓
                VERIFIED OUTPUTS
                       ↓
                 CEFFLO PRODUCT
                       ↓
            REAL DELIVERY OPERATIONS
                       ↓
                 DATA / SIGNALS
                       ↓
              PRODUCT INTELLIGENCE
                       ↓
             VALIDATED KNOWLEDGE
                       ↓
                BETTER OPERATIONS
                       ↺
```

The desired result is not maximum autonomy.

The desired result is:

> **Maximum reliable company output with minimum unnecessary founder
> intervention.**

------------------------------------------------------------------------

# 20. Canonical Rule

All future Cefflo AI Company automation should follow this rule:

> **No agent without responsibility.\
> No service without an output.\
> No output without verification.\
> No action without permission.\
> No consequential action without the correct approval.\
> No useful operational signal should be wasted when it can safely
> improve the system.**

------------------------------------------------------------------------

## Final Position

Cefflo remains a **Local Same-Day Delivery Operating System**.

Its internal AI Company architecture exists to allow a lean company to
build, operate, protect, grow, support, and improve that product with
increasingly autonomous execution.

The five operating principles are:

1.  **Service Contract**
2.  **Output**
3.  **Permission**
4.  **Approval**
5.  **Learning Loop**

These principles complement the existing Engineering, Marketing,
Customer Service, Sales & CRM, Product Intelligence, Control Layer, and
Cyber Security architecture.

They do not replace it.
