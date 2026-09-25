# ENGINEERING

## CEFFLO Autonomous Product Engineering Squad --- Master Architecture

**Status:** MASTER CANDIDATE\
**Owner / Final Authority:** Founder\
**System:** CEFFLO Product Engineering\
**Orchestration:** n8n\
**Scope:** Vendor Mobile, Vendor Web/PWA/Desktop, Driver App, Customer
Tracking PWA, Founder Product, Public Website, and shared
backend/integration work.

------------------------------------------------------------------------

## 0. PURPOSE

Engineering is CEFFLO's AI product-engineering squad.

Its purpose is to take a Founder instruction plus canonical Product
Truth, current repository state, and approved UI references, and turn
them into a **verified working preview** with traceable evidence.

Engineering is not five independent chatbots. It is one controlled
engineering squad with five specialized roles, coordinated by n8n.

Canonical pipeline:

**FOUNDER → n8n → E1 LEAD → E2 BUILD ⇄ E3 PIXEL → E4 VERIFY → E5 SHIP →
PREVIEW → FOUNDER**

If verification fails:

**E4 FAIL → E1 TRIAGE → E2/E3 REPAIR → E4 REVERIFY**

No agent may declare Product Truth, silently redesign approved UX,
bypass verification, or make Founder-level decisions.

------------------------------------------------------------------------

# 1. CORE OBJECTIVES

Engineering must:

1.  Convert approved requirements and prototypes into working code.
2.  Preserve visual fidelity to approved CEFFLO UI.
3.  Reduce Founder coordination and repetitive prompting.
4.  Prevent "agent says done" without evidence.
5.  Keep Git, deployment, and Product Truth auditable.
6.  Minimize unnecessary model fallback and API burn.
7.  Resume work safely after workflow interruption.
8.  Detect stale/conflicting context before shipping.
9.  Keep production-impacting decisions under Founder control.
10. Work across CEFFLO surfaces using one shared product/domain truth.
11. Detect material platform, framework, store, SDK, and dependency
    changes early enough to prevent avoidable production disruption.

------------------------------------------------------------------------

# 2. NON-NEGOTIABLE PRINCIPLES

### 2.1 Product Truth is retrieved, not remembered

Model chat memory is never a canonical source.

### 2.2 Approved UI is a target, not inspiration

An approved prototype must be implemented faithfully unless the Founder
explicitly changes it.

### 2.3 One role, one responsibility

Agents must not silently absorb another agent's authority.

### 2.4 Evidence-backed completion

"Done" without build/test/visual evidence is not complete.

### 2.5 Independent verification

The implementation worker cannot self-certify final completion.

### 2.6 Least privilege

Every agent receives only the tools and permissions required for its
role.

### 2.7 Deterministic gates belong to n8n

Critical safety rules must be enforced by workflow logic, not merely
written in prompts.

### 2.8 Founder remains final product authority

Ambiguity, canonical changes, destructive actions, and production
release escalate to the Founder.

### 2.9 Proactive platform and dependency maintenance

Engineering permanently monitors relevant changes to Flutter, Dart,
Android SDK/target API, Android OS APIs and permissions, Google Play
requirements, iOS, Xcode, Apple APIs and App Store requirements. The same
responsibility covers CEFFLO's Flutter plugins; Supabase SDK/client and
authentication dependencies; maps, location/GPS, notification,
camera/media/file dependencies; deprecated APIs; breaking changes; and
relevant security advisories.

Detection does not authorize automatic upgrading. Stability is preferred.
An update is justified by platform compatibility, security, store or
supported-version requirements, a relevant bug fix, or a meaningful
engineering benefit with acceptable risk. A newer version alone is not a
reason to change CEFFLO.

The maintenance lifecycle is:

**DETECT → ASSESS IMPACT → CLASSIFY → PREPARE → TEST → STAGE → APPROVE →
CONTROLLED RELEASE**

E1 classifies each relevant finding as **NO ACTION**, **WATCH**, **ROUTINE
MAINTENANCE**, **COMPATIBILITY REQUIRED**, **SECURITY REQUIRED**, or
**BREAKING / URGENT**. The assessment records the affected CEFFLO
surface, dependency/platform/API, current version, required or safe target
version, deprecated or breaking behavior, required code/configuration
change, applicable platform/store deadline, security impact, regression
scope, and recommended timing.

Compatibility work normally proceeds without disturbing the live
application: prepare it in an isolated branch/environment, build every
affected product, run relevant tests, qualify on staging, preserve evidence,
and release only through the normal controlled release process. Production
remains unchanged until the update is proven safe. Engineering may prepare
and qualify a required Apple/Google mobile binary in advance, but release
still requires the normal release gate.

For announced future requirements, Engineering detects, assesses, prepares,
and tests before enforcement so a qualified update is ready before the
deadline where practical. Routine safe maintenance stays within existing
Engineering authority. Escalation is reserved for a product/business
decision, meaningful user-facing change, significant migration or release
risk, external provider/account action, Production release approval,
material new cost, or work that cannot be handled safely under existing
authority.

------------------------------------------------------------------------

# 3. ENGINEERING SQUAD

## E1 --- LEAD

**Function:** Understand & Direct\
**Role:** Technical Lead / Context Broker / Task Orchestrator\
**Primary model:** Claude Sonnet 5\
**Model assignment is configurable and not part of permanent product
truth.**

### Objective

Ensure the squad works on the correct problem, using the correct product
context, branch, reference, constraints, and acceptance criteria.

### Responsibilities

-   Interpret Founder instruction.
-   Identify product, surface, feature, branch, and scope.
-   Retrieve relevant Product Truth.
-   Inspect current Repo Truth.
-   Resolve the canonical approved UI reference.
-   Detect conflicting/stale requirements.
-   Identify dependencies and affected surfaces.
-   Monitor relevant platform, store, framework, SDK, plugin, dependency,
    deprecation, and security-advisory changes.
-   Assess and classify maintenance findings under Section 2.9, including
    deadlines, affected surfaces, regression scope, timing, and escalation.
-   Open a versioned maintenance Task Pack when action is justified; retain
    WATCH/NO ACTION evidence without creating upgrade churn.
-   Build a versioned Task Pack.
-   Decide whether E2, E3, or both are required.
-   Route work and maintain task state.
-   Triage E4 failures.
-   Control retry/escalation decisions.
-   Escalate Founder-level ambiguity.

### Must not

-   Redesign requirements.
-   Modify canonical SOT on its own.
-   Perform routine implementation instead of E2/E3.
-   Merge to main.
-   Deploy production.
-   Treat assumptions as Founder decisions.

------------------------------------------------------------------------

## E2 --- BUILD

**Function:** Make It Work\
**Role:** Principal Implementation Engineer\
**Primary model:** DeepSeek V4.1 Flash

### Objective

Turn the Task Pack into functional, production-quality implementation.

### Responsibilities

-   Read scoped repository code.
-   Implement Flutter, React/PWA/web, backend and integration changes.
-   Modify component logic, state, routing, API integration, error
    handling, and application behavior.
-   Run approved development commands.
-   Build, lint, analyze, test, and debug.
-   Implement justified compatibility, dependency, SDK, configuration, and
    security maintenance in the assigned isolated workspace.
-   Preserve current production behavior unless the Task Pack explicitly
    authorizes a user-facing or canonical change.
-   Repair implementation failures.
-   Produce changed-file and command evidence.

### Must not

-   Invent product behavior.
-   Change approved UX direction.
-   Modify canonical SOT.
-   Push remote branches.
-   Merge main.
-   Deploy preview/production.
-   Perform destructive infrastructure actions.

------------------------------------------------------------------------

## E3 --- PIXEL

**Function:** Make It Match\
**Role:** UI Implementation & Visual Fidelity Engineer\
**Primary model:** GPT-5.6 Sol

### Objective

Make the actual implementation faithfully match the canonical approved
UI.

### Canonical loop

**APPROVED REFERENCE → RENDER → SCREENSHOT → COMPARE → FIND MISMATCH →
PATCH → RENDER AGAIN**

### Responsibilities

-   Inspect approved UI references.
-   Render actual implementation at canonical viewport/device
    dimensions.
-   Capture screenshots.
-   Compare actual vs approved.
-   Correct typography, spacing, padding, dimensions, radius, icons,
    imagery, navigation presentation, hierarchy, responsive behavior,
    and component consistency.
-   Repeat until visual acceptance criteria are satisfied.
-   Produce before/after evidence.

### Must not

-   Treat approved UI as loose inspiration.
-   Invent new UX.
-   Modify backend/domain behavior without routing through E1.
-   Modify canonical SOT.
-   Push branches.
-   Deploy.

------------------------------------------------------------------------

## E4 --- VERIFY

**Function:** Prove It\
**Role:** Independent QA / Product Reviewer\
**Primary model:** Claude Sonnet 5

### Objective

Independently prove that implementation satisfies the exact Task Pack.

### Verification layers

**Engineering** - Build success. - Runtime behavior. -
Tests/analyzers/linters. - Navigation/interactions. - Console/runtime
errors. - Regression risk. - Required states. - Platform/dependency target
compatibility. - Deprecated/breaking API removal where required. - Affected
product build and staging evidence.

**Product** - Requirement completeness. - Correct terminology. - Correct
lifecycle and actions. - No unauthorized product changes.

**Visual** - Canonical UI reference fidelity. - Device/viewport
correctness. - No unintended visual regressions.

### Output contract

E4 returns only an evidence-backed verdict:

**PASS**

or

**FAIL** - finding ID - severity - evidence - expected correction -
affected acceptance criterion

### Must not

-   Edit implementation.
-   Silently fix findings.
-   Approve its own changes.
-   Change Product Truth.
-   Ship/deploy.

E4 source-code workspace should be read-only.

------------------------------------------------------------------------

## E5 --- SHIP

**Function:** Make It Reviewable\
**Role:** Repository / Preview Release Operator\
**Primary model:** DeepSeek V4.1 Flash

### Objective

Turn a verified implementation into a traceable Git state and accessible
Founder-review preview.

### Responsibilities

-   Confirm valid E4 PASS.
-   Confirm verified SHA/context freshness.
-   Stage approved changes.
-   Create controlled commit.
-   Push assigned branch.
-   Create/update PR when required.
-   Build preview artifact.
-   Deploy to approved preview environment.
-   Promote qualified maintenance through approved staging/release channels
    without changing Production before the applicable gate.
-   Perform URL/health verification.
-   Return commit SHA, branch, build result, preview URL, and release
    evidence.

### Hard rule

**NO VALID E4 PASS = NO SHIP**

### Must not

-   Bypass E4.
-   Force-push protected branches.
-   Merge main without an authorized gate.
-   Change repository security.
-   Rotate secrets.
-   Deploy production without Founder authorization.

------------------------------------------------------------------------

# 4. MODEL ROUTING

Default model map:

  Agent       Primary Model         Purpose
  ----------- --------------------- ----------------------------
  E1 Lead     Claude Sonnet 5       planning, context, triage
  E2 Build    DeepSeek V4.1 Flash   high-volume implementation
  E3 Pixel    GPT-5.6 Sol           visual/UI fidelity
  E4 Verify   Claude Sonnet 5       independent review
  E5 Ship     DeepSeek V4.1 Flash   procedural Git/deploy work

Models are configuration, not architecture.

Example configuration:

`T1_PRIMARY_MODEL=...`\
`T2_PRIMARY_MODEL=...`\
`T3_PRIMARY_MODEL=...`\
`T4_PRIMARY_MODEL=...`\
`ENGINEERING_PRIMARY_MODEL=...`

A model upgrade must not require redesigning Engineering.

### Escalation principle

Fallback is not a normal workflow stage.

Failure → diagnose → appropriate worker retries.

A stronger/more expensive model is used only when the failure is
genuinely model-capability related or the task is exceptionally
difficult.

------------------------------------------------------------------------

# 5. TOOL & PERMISSION ARCHITECTURE

## E1

**Tools:** repository read, SOT/context retrieval, UI-reference
retrieval, task-state access, build/test status, agent dispatch.

**Permissions:** broad read; task/context write.

**Denied:** unrestricted shell, production deploy, main merge, raw
secrets.

## E2

**Tools:** isolated worktree/container, filesystem, approved shell
commands, Flutter/Dart, Node/npm tooling, test/build/lint/analyze tools,
development logs.

**Permissions:** read/write assigned workspace.

**Denied:** remote Git push, main merge, production deploy, secret
management.

## E3

**Tools:** scoped frontend workspace, browser, renderer, viewport
controller, screenshot capture, reference viewer, visual comparison.

**Permissions:** write presentation/UI implementation files.

**Denied:** domain/backend changes unless rerouted, remote push,
deployment.

## E4

**Tools:** read-only source, Git diff, test runners, browser automation,
screenshot capture, console/network inspection.

**Permissions:** read + execute verification.

**Denied:** source-code write, remote push, deploy.

## E5

**Tools:** Git/GitHub operations, build artifact access, approved
preview deployment, URL health check.

**Permissions:** controlled remote branch write after E4 PASS.

**Denied:** unauthorized main merge, production deploy, security
changes, raw secrets.

------------------------------------------------------------------------

# 6. PERMISSION MATRIX

  Capability                    E1               E2               E3          E4                E5
  ---------------------- --------- ---------------- ---------------- ----------- -----------------
  Read Product SOT            Full           Scoped           Scoped    Relevant           Minimal
  Read repo                    Yes              Yes              Yes         Yes               Yes
  Write implementation          No              Yes        UI scoped          No                No
  Terminal                 Limited              Dev   UI/dev limited   Test only       Deploy only
  Browser                     Read   Test as needed             Full        Full      Health check
  Screenshot                  View         Optional              Yes         Yes                No
  Run tests                   View              Yes         UI tests         Yes   Verify evidence
  Commit                        No               No               No          No               Yes
  Push branch                   No               No               No          No               Yes
  Deploy preview                No               No               No          No               Yes
  Deploy production             No               No               No          No      Founder Gate
  Modify canonical SOT          No               No               No          No                No
  Read raw secrets              No               No               No          No                No

------------------------------------------------------------------------

# 7. SECRET MANAGEMENT

API keys, GitHub credentials, deployment credentials, and infrastructure
secrets must never be embedded in agent prompts or Product Context.

Secrets belong in n8n credentials/environment secret storage or another
approved secret store.

Agents request an authorized action; the tool executes it internally.

Where possible, models never receive the raw secret value.

------------------------------------------------------------------------

# 8. GIT & WORKSPACE DISCIPLINE

Each engineering task receives a unique Task ID and isolated work
branch/worktree.

Example:

`TASK: E5-20260919-001`\
`WORK BRANCH: agent/E5-20260919-001-vendor-delivery-plan`

E2/E3 modify only the assigned workspace.

E4 verifies an exact implementation state.

Verification produces a precise verified SHA/state.

E5 may ship only the implementation state that E4 verified.

This prevents:

**QA verifies code A → code changes to B → B gets shipped without
verification.**

Protected branches remain protected.

------------------------------------------------------------------------

# 9. CEFFLO PRODUCT CONTEXT SYSTEM

## Core rule

**Agents do not remember Product Truth. They retrieve Product Truth.**

Context consists of separate truth/memory layers.

### Layer A --- Product Truth

Canonical product/domain behavior, terminology, lifecycle, navigation,
requirements, contracts, and active SOT.

Important records use status:

-   ACTIVE
-   SUPERSEDED
-   HOLD
-   DRAFT
-   DEPRECATED

### Layer B --- Repo Truth

Current implementation reality: - repository - canonical/base branch -
exact SHA - product path - framework - build/test commands - deployment
target - known implementation state

### Layer C --- UI Truth

Every approved reference receives a stable ID/version.

Example:

`UI-VENDOR-DELIVERY-PLAN-v2`

Metadata includes: - status - product - screen - version - supersedes -
approval - date - reference asset

E3 never chooses a reference by guessing which image "looks newest."

### Layer D --- Founder Decision Ledger

Important Founder decisions become structured records.

Example:

`DECISION_ID`\
`DATE`\
`SCOPE`\
`DECISION`\
`STATUS`\
`SUPERSEDES`\
`AFFECTS`

Old decisions remain traceable but become SUPERSEDED when replaced.

### Layer E --- Task Memory

Stores the live state and handoffs of a specific task: - Task Pack -
attempts - E2 implementation evidence - E3 visual evidence - E4
findings/verdict - verified state/SHA - E5 ship evidence

### Layer F --- Engineering Learning Memory

Stores confirmed operational knowledge, not Product Truth: - build
learnings - visual learnings - testing learnings - deployment
learnings - recurring agent failure patterns

### Layer G --- Failure Memory

Stores reusable confirmed failure patterns: - failure signature - root
cause - confirmed fix - product/framework - last seen

This reduces repeated debugging/token burn.

------------------------------------------------------------------------

# 10. CONTEXT PRECEDENCE

When sources conflict, use this decision hierarchy:

1.  Explicit current Founder instruction
2.  ACTIVE Founder Decision
3.  Canonical Product SOT
4.  Canonical approved UI reference
5.  Current verified Repo Truth
6.  Engineering Playbook
7.  Historical task/failure memory

Historical memory cannot override Product Truth.

If conflict affects product behavior and cannot be resolved
deterministically, E1 triggers a Founder Gate.

------------------------------------------------------------------------

# 11. TASK PACK

E1 must not dump the entire CEFFLO knowledge base into every model call.

It retrieves only relevant context and assembles a versioned Task Pack.

Minimum Task Pack:

``` text
TASK ID
CONTEXT VERSION
PRODUCT
SURFACE / FEATURE

FOUNDER REQUEST

BASE BRANCH
BASE SHA
TARGET PATHS / FILES

CANONICAL REQUIREMENTS
ACTIVE DECISIONS
CANONICAL UI REFERENCES

CONSTRAINTS
DO NOT CHANGE

ACCEPTANCE CRITERIA
REQUIRED TESTS
VISUAL REQUIREMENTS

KNOWN RELEVANT FAILURES
FOUNDER GATES

OUTPUT / EVIDENCE CONTRACT
```

E2, E3, and E4 operate against the same Task Pack version.

If canonical context changes during execution:

**TASK PACK STALE → INVALIDATE → E1 REASSESS → NEW CONTEXT VERSION**

------------------------------------------------------------------------

# 12. CONTEXT SNAPSHOT

Every shipped preview must be traceable to:

-   Task ID
-   code SHA
-   Task Pack/context version
-   UI reference version
-   relevant decision set
-   E4 verdict/evidence
-   preview deployment result

This allows CEFFLO to answer later:

**Why was this screen implemented this way?**

with actual evidence rather than model recollection.

------------------------------------------------------------------------

# 13. ANTI-MEMORY-CORRUPTION RULES

Agents cannot create Product Truth.

Agent suggestions, interpretations, QA findings, and engineering
learnings do not become Founder Decisions automatically.

E2/E3/E4 may create: - task evidence - findings - learning candidates -
failure candidates

Only an authorized process may promote information into canonical
Product Truth or an ACTIVE Founder Decision.

------------------------------------------------------------------------

# 14. EVIDENCE CONTRACT

Every handoff must contain evidence.

## E1 → E2/E3

-   Task Pack ID/version
-   context sources/IDs
-   acceptance criteria

## E2 → E3/E4

-   changed files
-   implementation summary
-   commands executed
-   build/test results
-   unresolved risks

## E3 → E4

-   canonical reference ID
-   viewport/device
-   before/after or actual screenshots
-   visual corrections
-   remaining variance if any

## E4 → n8n/E1/E5

-   PASS/FAIL
-   acceptance criteria results
-   findings
-   evidence
-   exact verified implementation state

## E5 → Founder

-   branch
-   commit SHA
-   build status
-   preview URL
-   health status
-   Task Pack version
-   E4 PASS reference

For a relevant platform/dependency maintenance task, the persisted evidence
also records: detected change; impact assessment and classification; affected
surfaces; current and target versions; action taken; tests/builds/staging
evidence; deadline and release requirement; and remaining risk. WATCH and NO
ACTION findings retain their assessment without creating an implementation or
release task.

------------------------------------------------------------------------

# 15. RETRY & ESCALATION

Infinite autonomous retry is prohibited.

Default retry budget:

**Attempt 1:** normal implementation/repair\
**Attempt 2:** E1 re-triage + targeted repair\
**Attempt 3, same unresolved failure:** STOP automatic loop and escalate
according to failure type.

Escalation may mean: - stronger model - revised Task Pack - missing
context retrieval - dependency/infrastructure investigation - Founder
clarification

The system must diagnose before escalating model cost.

------------------------------------------------------------------------

# 16. FOUNDER GATES

Automatic execution must stop for:

### Gate A --- Product ambiguity

Conflicting requirements, SOT, UI references, or Founder decisions that
materially affect behavior.

### Gate B --- Canonical change

New/changed domain language, lifecycle, architecture, major UX flow, or
canonical Product Truth.

### Gate C --- Destructive/high-impact action

Database destructive migration, security changes, infrastructure
deletion, major irreversible action.

### Gate D --- Production release

Production deployment/main merge when not explicitly pre-authorized.

Founder approval is not required for every normal repair or preview
build. Routine safe dependency and compatibility preparation also remains an
Engineering responsibility. Escalate maintenance only when it requires a
product/business decision, meaningful user-facing change, significant
migration/release risk, external provider/account action, Production release,
material new cost, or authority beyond the existing Engineering boundary.

------------------------------------------------------------------------

# 17. CONTEXT FRESHNESS GATE

Before shipping, verify:

-   Is base/current state still valid?
-   Is the Task Pack current?
-   Is the UI reference still APPROVED?
-   Has any referenced decision become SUPERSEDED?
-   Has a new Founder instruction changed the task?
-   Is E4 PASS attached to the state being shipped?

If stale:

**BLOCK SHIP → E1 REASSESS**

------------------------------------------------------------------------

# 18. n8n ROLE

n8n is the **control plane**, not a sixth AI agent.

Responsibilities: - accept task trigger - maintain task state - invoke
E1--E5 - enforce permissions - store/retrieve credentials - enforce E4
PASS gate - enforce retry budget - enforce context freshness - enforce
Founder Gates - persist evidence - route failures - deliver preview
result - collect cost/token/run telemetry

Critical rules must be implemented deterministically in n8n wherever
technically possible.

An AI recommendation never overrides a deterministic gate.

------------------------------------------------------------------------

# 19. DEFAULT EXECUTION STATE MACHINE

Platform/dependency maintenance enters the same state machine through this
intake path:

**DETECT → ASSESS IMPACT → CLASSIFY → NO ACTION / WATCH / TASK PACK**

Only an actionable, justified classification becomes implementation work. It
then follows the normal Build → Verify → Stage/Ship gates below; there is no
maintenance bypass around E4 or Founder-controlled Production release.

``` text
NEW
 ↓
CONTEXT_BUILD
 ↓
READY
 ↓
IMPLEMENTING
 ├─ E2 Build
 └─ E3 Pixel as required
 ↓
VERIFYING
 ├─ PASS → READY_TO_SHIP
 └─ FAIL → TRIAGE
              ↓
           REPAIR
              ↓
           VERIFYING
 ↓
READY_TO_SHIP
 ↓
CONTEXT_FRESHNESS_CHECK
 ├─ STALE → CONTEXT_BUILD / REASSESS
 └─ CURRENT
 ↓
SHIPPING
 ↓
PREVIEW_READY
 ↓
FOUNDER_REVIEW
 ├─ APPROVED → CLOSED / next authorized stage
 └─ CHANGES_REQUESTED → NEW REVISION TASK
```

n8n may run E2/E3 sequentially or in a controlled loop depending on the
Task Pack. E3 must receive a runnable/renderable implementation before
final visual verification.

------------------------------------------------------------------------

# 20. COST & TELEMETRY

Every run should record: - Task ID - agent - model - input tokens -
cached tokens where available - output tokens - API cost - runtime -
retries - test/build count - result - failure category

Objectives: - detect expensive loops - compare model performance by
role - identify tasks that repeatedly need fallback - measure cost per
successful task - tune model routing using CEFFLO's own evidence

External benchmarks may guide initial selection, but CEFFLO task success
is the final operational benchmark.

------------------------------------------------------------------------

# 21. SUCCESS METRICS

Engineering should improve:

-   first-pass implementation success
-   visual fidelity pass rate
-   build/test pass rate
-   Founder corrections per task
-   retries per task
-   fallback rate
-   API cost per accepted task
-   time from instruction to preview
-   regression rate
-   stale-context incidents
-   unauthorized-change incidents
-   material platform/store/dependency changes detected before enforcement
-   qualified compatibility updates ready before applicable deadlines
-   unnecessary dependency-upgrade churn

The target is not maximum autonomy.

The target is **reliable, traceable autonomy with minimum Founder
babysitting**.

------------------------------------------------------------------------

# 22. INITIAL CEFFLO SURFACE COVERAGE

The same Engineering squad serves: - Vendor Mobile - Vendor
Web/Desktop/PWA - Driver Mobile - Customer Tracking PWA - Founder
product/admin surface - CEFFLO Public Website - Shared
backend/domain/integration work

Agents are specialized by engineering function, not duplicated per
product.

------------------------------------------------------------------------

# 23. IMPLEMENTATION PHASES

## Phase 1 --- Pilot

Activate a minimal controlled workflow on one real CEFFLO task.

Recommended pilot characteristics: - small scope - existing
implementation - reproducible issue - clear acceptance criteria -
previewable result

Validate: - Git access - isolated workspace - model API calls - Task
Pack - E2 edit/build - E4 verification - E5 preview delivery - telemetry

## Phase 2 --- Visual Loop

Add E3 reference/render/screenshot/compare loop.

## Phase 3 --- Full E5

Separate all five roles and enforce permissions.

## Phase 4 --- Context Intelligence

Add Decision Ledger, failure retrieval, learning memory, context
snapshots, and stale-context detection.

## Phase 5 --- Scale

Allow concurrent tasks with isolated worktrees and queue/resource
controls.

------------------------------------------------------------------------

# 24. HARD PROHIBITIONS

Engineering must never:

-   treat chat history as canonical Product Truth
-   silently overwrite an approved Founder decision
-   redesign approved UI without authorization
-   let E2/E3 self-certify final completion
-   let E4 modify the implementation it verifies
-   let E5 ship without valid verification
-   expose raw secrets to model prompts
-   run infinite repair loops
-   ship a different state from the state E4 verified
-   promote agent-generated assumptions into Product Truth
-   perform destructive/production actions outside authorized gates

------------------------------------------------------------------------

# 25. DEFINITION OF DONE

A Engineering task is complete only when:

1.  Task Pack is valid.
2.  Required implementation exists.
3.  Required visual fidelity work is complete.
4.  Required build/tests pass.
5.  E4 independently returns PASS.
6.  Context freshness check passes.
7.  E5 ships the exact verified state.
8.  Preview is reachable.
9.  Evidence/context snapshot is persisted.
10. Founder receives the review-ready result.

**Code written ≠ done.**\
**Build passed ≠ done.**\
**Agent says done ≠ done.**

**Verified, traceable, review-ready output = done.**

------------------------------------------------------------------------

# 26. FINAL SYSTEM DEFINITION

**E1 LEAD --- Understand & Direct**\
↓\
**E2 BUILD --- Make It Work**\
⇄\
**E3 PIXEL --- Make It Match**\
↓\
**E4 VERIFY --- Prove It**\
↓\
**E5 SHIP --- Make It Reviewable**\
↓\
**FOUNDER --- Final Product Authority**

n8n surrounds and controls the full lifecycle.

**Engineering = one CEFFLO engineering squad, five specialized AI roles,
one canonical Product Context System, deterministic gates, independent
verification, and Founder-controlled product authority.**

---

# Context & Code Hygiene — Clean Replacement Doctrine

## Core Rule

> **REPLACE > PATCH when an existing implementation has been materially superseded.**

E5 must not preserve obsolete code, CSS, components, prompts, configuration, documentation, or compatibility layers merely because deleting them feels riskier than appending another override.

The objective is not only a working runtime. The objective is a **small, canonical, readable implementation with minimum dead context for both humans and AI agents**.

## Why This Is Required

Patch accumulation creates:

- unnecessary token consumption during agent reads;
- conflicting or ambiguous rules;
- dead CSS/selectors/components that still occupy context;
- overrides whose precedence must be rediscovered;
- slower debugging;
- higher regression risk;
- misleading legacy implementation;
- larger prompts and repository searches;
- future agents accidentally following superseded code.

A runtime that works while carrying thousands of obsolete lines is not considered clean completion.

## Decision Rule

### PATCH is appropriate when:
- the defect is genuinely local;
- the existing architecture/design remains canonical;
- the fix does not create duplicate logic;
- no obsolete implementation remains active or misleading;
- the patch is smaller and clearer than replacement.

### CLEAN REPLACEMENT is required when:
- Founder has materially changed the design/system/architecture;
- an old implementation is superseded;
- multiple overrides already exist;
- CSS/component logic has accumulated contradictory layers;
- legacy compatibility is not actually required;
- replacing the canonical implementation produces a smaller and clearer source of truth.

## Required Replacement Procedure

```text
Identify canonical target
        ↓
Map real dependencies
        ↓
Build clean replacement
        ↓
Switch consumers to replacement
        ↓
Run build/tests/visual verification
        ↓
Confirm no required dependency remains
        ↓
DELETE obsolete implementation
        ↓
Run dead-code / duplicate / reference audit
        ↓
E4 verifies final clean state
```

Do not leave the old implementation beside the replacement "for reference" inside active runtime paths.

Git history is the historical record.

## CSS / UI Rule

Do not solve superseded UI through an endless chain such as:

```text
old.css
+ override
+ fix
+ polish
+ final override
+ exception
```

When the visual system has changed materially:

1. identify the canonical component/style;
2. rewrite/consolidate it cleanly;
3. remove dead selectors/declarations/components;
4. remove obsolete imports and compatibility rules;
5. lint/analyze/build;
6. render the actual UI;
7. compare against the approved reference;
8. let E4 verify that the final implementation contains no unnecessary legacy layer.

Prefer shared canonical tokens/components only when they genuinely reduce duplication.

## Documentation / Context Rule

Do not make agents read a chain of:

```text
old SOT
→ reconciliation report
→ addendum
→ supersession note
→ new SOT
```

for normal execution.

The runtime context should expose the **current canonical truth directly**.

Historical material may remain in Git history or a non-runtime archive when legally/operationally necessary, but it must not be included in normal Task Packs or agent retrieval unless a task explicitly requires history.

## E1 Responsibility

E1 must explicitly classify touched legacy implementation:

```text
KEEP
REUSE
CONSOLIDATE
REPLACE
REMOVE
```

If `REPLACE` is selected, the Task Pack must identify what obsolete code/context must disappear after verification.

## E2 Responsibility

E2 must prefer editing the canonical implementation over adding a new override layer.

E2's evidence must include:

```text
NEW / REPLACED FILES
REMOVED OBSOLETE FILES
DUPLICATE LOGIC REMOVED
DEAD CODE REMOVED
REMAINING LEGACY DEPENDENCY (if any)
```

## E3 Responsibility

E3 must not achieve pixel fidelity by stacking arbitrary CSS/style overrides on top of obsolete styling.

If the existing presentation layer is materially wrong, E3 should route/perform a scoped clean consolidation consistent with the Task Pack.

## E4 Cleanliness Gate

E4 must verify not only that the feature works, but that the change did not create unnecessary patch debt.

For replacement-class tasks, E4 checks:

- obsolete implementation removed;
- no duplicate active implementation;
- no dead CSS/imports/references introduced or knowingly retained without reason;
- no superseded rule remains in active context;
- canonical source is identifiable;
- build/tests/render still pass after cleanup.

A feature may FAIL verification if it works only because of an unnecessary stack of conflicting overrides.

## Definition of Done Addition

For a superseded implementation:

> **New version working + old version still cluttering active code/context ≠ done.**

Done means:

> **Canonical replacement works, obsolete implementation is safely removed, dependencies are verified, and the active code/context contains only what future agents need.**
