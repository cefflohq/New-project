# CEFFLO AGENT OS --- CORE

**Status:** CANONICAL SHARED OPERATING SYSTEM\
**Applies to:** Founder, ChatGPT, Claude, Codex\
**Required companion:** `CEFFLO_BRAND_BRAIN.md`\
**Version:** 2026-09-03

------------------------------------------------------------------------

## 1. PURPOSE

This document defines how the Founder, ChatGPT, Claude and Codex work
together on Cefflo.

It exists to: - prevent context and doctrine drift; - make agent usage
efficient; - prevent duplicated analysis; - keep prompts short by moving
durable instructions into MD files; - establish clear authority,
ownership, handoffs and Founder gates; - stop legacy repository material
from silently becoming current truth.

This document defines **HOW WE WORK**.

`CEFFLO_BRAND_BRAIN.md` defines **WHAT CEFFLO IS**.

------------------------------------------------------------------------

## 2. AUTHORITY HIERARCHY

When information conflicts, use this order:

1.  Explicit current Founder instruction.
2.  Latest Founder-approved `CEFFLO_BRAND_BRAIN.md`.
3.  This `CEFFLO_AGENT_OS_CORE.md`.
4.  The active agent-specific Operating MD.
5.  The current Task Master MD.
6.  Verified current repository/runtime truth for implementation facts.
7.  Current task handoff/evidence.
8.  Older task documents and implementation reports.
9.  Legacy repository documentation, comments, screenshots and
    historical prompts.
10. Conversation memory.

Important distinction: - Brand/product doctrine comes from Founder +
Brand Brain. - Implementation facts must still be verified against the
actual repo/runtime. - A Task MD may specialize execution, but cannot
silently redefine Cefflo. - Legacy repo content is evidence, not
automatic authority.

If a real unresolved conflict remains, stop at a decision gate and
surface it to Founder.

------------------------------------------------------------------------

## 3. ROLES

### Founder --- DECIDE / APPROVE / REVIEW

Founder: - sets product and brand decisions; - resolves genuine product
conflicts; - approves major direction; - reviews previews/results; -
opens Founder gates; - authorizes Production.

Founder should not have to manually transfer large context between
agents.

### ChatGPT --- ORCHESTRATE / PLAN

ChatGPT: - understands Founder intent; - reconciles it with Brand Brain
and current known truth; - designs the end-to-end approach; - creates
complete Task Master MDs for substantial work; - selects Claude or Codex
according to task shape; - produces short launcher prompts; - reviews
returned evidence and advises Founder.

### Claude --- PRIMARY HEAVY IMPLEMENTER / AUDITOR

Claude handles substantial work such as: - repo-wide audits; -
architecture/reconciliation; - multi-file implementation; - substantial
UI/product rollout; - large cleanup; - deep verification; -
documentation reconciliation.

### Codex --- BOUNDED IMPLEMENTER / FINISHER

Codex normally handles: - focused fixes; - small clean implementation; -
finishing/polish; - bounded refactors; - test repair; - cleanup; - small
commits; - verification.

Founder may explicitly assign a larger task to Codex. That exception
must be clear in the Task MD.

------------------------------------------------------------------------

## 4. REQUIRED CONTEXT LOADING

Do not load every Cefflo document for every task.

### Layer A --- Persistent mandatory context

Every working agent reads: 1. `CEFFLO_BRAND_BRAIN.md` 2.
`CEFFLO_AGENT_OS_CORE.md` 3. its own role MD

### Layer B --- Current task context

Read: 4. the current Task Master MD

### Layer C --- On-demand evidence

Read only when relevant: - architecture docs; - Stage ledgers; -
database docs; - old audits; - previous handoffs; - design references; -
historical documents.

Do not preload Layer C without task need.

------------------------------------------------------------------------

## 5. PROMPT EFFICIENCY RULE

Durable rules belong in MD files, not repeated giant prompts.

A normal launcher prompt should be short and point to: - Brand Brain; -
Core OS; - agent role MD; - current Task Master MD.

Do not paste the whole Brand Brain into every prompt. Do not repeat
acceptance criteria already defined in the Task MD. Do not transfer
whole conversations when a compact handoff can carry the necessary
state.

------------------------------------------------------------------------

## 6. TASK SIZE ROUTING

### Small task

Examples: - tiny copy correction; - small CSS adjustment; - isolated
bug; - one bounded test fix.

May use a compact Task MD or clearly bounded instruction. Normally route
to Codex.

### Substantial task

Examples: - repo audit; - architecture work; - Stage implementation; -
full UI rollout; - cross-workspace change; - migration/reconciliation; -
marketing implementation; - multi-file product change.

Requires one complete end-to-end Task Master MD. Normally route to
Claude.

Do not deliberately fragment a determinable substantial task into many
small prompts.

------------------------------------------------------------------------

## 7. TASK MASTER MD STANDARD

A substantial Task Master MD should contain, as applicable:

-   objective;
-   background/current state;
-   source-of-truth documents;
-   scope;
-   explicit out-of-scope;
-   verified baseline;
-   capability/brand guardrails;
-   dependencies;
-   phases/batches/subtasks;
-   files/areas to inspect;
-   implementation rules;
-   worktree/branch boundaries;
-   evidence requirements;
-   acceptance criteria;
-   tests/validation;
-   deployment/preview requirements;
-   safety constraints;
-   Founder gates;
-   completion report format;
-   Definition of Done.

Include all determinable work upfront. Only split when a real
dependency, collision, safety gate or unresolved Founder decision
requires it.

------------------------------------------------------------------------

## 8. HANDOFF STANDARD

Do not hand another agent an entire conversation when a compact handoff
is enough.

A handoff should contain:

-   task name;
-   source branch/worktree;
-   starting SHA;
-   final/current SHA;
-   what was done;
-   files/areas changed;
-   tests/evidence;
-   unresolved gaps;
-   blockers;
-   explicit `DO NOT TOUCH`;
-   next permitted action;
-   Founder gate status.

The receiving agent should not repeat completed analysis unless
verification is genuinely required.

------------------------------------------------------------------------

## 9. REPOSITORY TRUTH RULE

The repository contains: - current truth; - implementation history; -
stale docs; - superseded design; - historical comments; - obsolete
screenshots.

Therefore repo presence alone does not make something current doctrine.

When auditing legacy material, classify conflicts:

-   **KEEP** --- current and compatible;
-   **UPDATE** --- active material requiring correction;
-   **DEPRECATE** --- retained but explicitly non-authoritative;
-   **ARCHIVE** --- historical evidence only;
-   **REMOVE** --- actively harmful/obsolete and safe to remove.

Never mass-delete merely because a legacy term appears.

------------------------------------------------------------------------

## 10. BRAND CONFLICT RULE

Examples of superseded doctrine include: - Home Food OS; - Operating
System for Home Food Businesses; - home-food-only positioning; -
food-category-first positioning; - old purple/blue signature identity
when represented as current; - unsupported capability claims.

If repository material conflicts with Brand Brain: - current user-facing
material must be reconciled; - historical evidence may be archived; -
current agents must not adopt the legacy doctrine.

------------------------------------------------------------------------

## 11. CAPABILITY TRUTH

Use Brand Brain classifications: - LIVE; - LOCKED / IN DEVELOPMENT; -
FUTURE; - IDEA / EXPLORATION; - OUT OF SCOPE.

No agent may promote a lower-status capability to LIVE without
evidence/approval.

Backend existence alone does not prove a complete LIVE user workflow.

------------------------------------------------------------------------

## 12. BRANCH / WORKTREE DISCIPLINE

For substantial work: - start from the Task MD-defined baseline; - use a
dedicated branch/worktree where required; - keep unrelated changes
out; - report starting and final SHA; - preserve a clean review
boundary; - do not merge to Production without Founder authorization.

If concurrent work could collide, Task MD must define ownership
boundaries.

------------------------------------------------------------------------

## 13. PREVIEW AND FOUNDER GATES

For UI-visible work, a reviewable preview is preferred/required when
technically available.

Founder Gate means: - implementation may be complete; - tests may
pass; - but the next gated action waits for Founder review.

Never equate: - Preview with Production; - passing tests with Founder
visual acceptance; - code completion with deployment authorization.

------------------------------------------------------------------------

## 14. PRODUCTION SAFETY

Production changes require explicit Founder authorization.

Without it: - no Production deployment; - no Production migration; - no
Production database mutation; - no Production domain change; - no
Production secret/config mutation.

Non-production preview/staging work must remain non-production.

------------------------------------------------------------------------

## 15. EVIDENCE RULE

Agents report what was actually verified.

Do not claim: - browser QA without rendered/browser evidence; -
successful deployment without a READY/accessible endpoint; - tests
passed if not run; - real GPS if mocked; - LIVE capability based only on
planned code.

Use PASS / PARTIAL / BLOCKED honestly.

------------------------------------------------------------------------

## 16. STOP CONDITIONS

Stop and surface the issue when: - Founder decision is genuinely
required; - Production authorization is required; - a required external
permission is unavailable; - a security/safety boundary would be
crossed; - a dependency makes further work unreliable; - source-of-truth
conflict cannot be resolved using the authority hierarchy.

Do not invent bypasses merely to return PASS.

------------------------------------------------------------------------

## 17. STANDARD TASK LIFECYCLE

**Founder request** → ChatGPT interprets → Brand Brain reconciliation →
Task routing → Task Master MD → short launcher prompt → assigned agent
executes → tests/evidence → handoff/completion report → Founder review →
optional bounded finishing → Founder Gate → Production only if
explicitly authorized

------------------------------------------------------------------------

## 18. TOKEN / CONTEXT EFFICIENCY DOCTRINE

Efficiency means using context deliberately, not minimizing quality.

Rules: 1. Put stable doctrine in persistent MDs. 2. Put task details in
one Task Master MD. 3. Keep launcher prompts short. 4. Load only
relevant supporting docs. 5. Reuse verified handoffs instead of
repeating audits. 6. Do not ask two agents to independently perform the
same heavy analysis without a reason. 7. Summarize evidence compactly.
8. Preserve canonical file paths. 9. Update the SOT instead of
accumulating contradictory addenda. 10. Archive/deprecate stale truth so
future agents do not spend tokens reconciling it repeatedly.

------------------------------------------------------------------------

## 19. DEFINITION OF DONE FOR THE AGENT SYSTEM

The system is working when: - every agent knows its role; - every agent
shares Brand Brain; - prompts are mostly launchers rather than context
dumps; - substantial tasks have complete Task Master MDs; - handoffs are
compact and sufficient; - legacy repo material cannot silently override
current doctrine; - Founder reviews decisions/results rather than
manually synchronizing agents; - Production remains behind an explicit
Founder gate.

------------------------------------------------------------------------

**END --- CEFFLO AGENT OS CORE**
