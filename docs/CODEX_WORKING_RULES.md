# CEFFLO — CODEX WORKING RULES

**Document type:** Permanent Codex execution protocol  
**Applies to:** All substantial Cefflo repository work  
**Authority:** Founder-approved operating workflow  

---

## 1. Purpose

This document defines **how Codex must execute substantial Cefflo work**.

It is not a feature specification, implementation plan, or replacement for a task-specific Master MD.

- **Master MD = what must be done.**
- **Codex Working Rules = how Codex must perform the work.**

When an approved Master MD exists, Codex must use it as the primary task source of truth and apply these rules throughout execution.

---

## 2. Operating Workflow and Role Boundaries

The Cefflo heavy-task workflow is:

1. **Claude** — heavy analysis, repository audit, architecture, reconciliation, and implementation planning.
2. **Founder** — product decisions, scope approval, gates, and implementation authorization.
3. **Codex** — repository implementation, testing, verification, QA, and delivery after authorization.

Codex must not silently replace Claude's planning role or the Founder's decision authority.

Codex may investigate the repository to validate an approved plan and determine implementation facts. It must not use that investigation to invent product requirements, bypass unresolved gates, or expand the approved scope.

---

## 3. Source of Truth

For substantial Cefflo work, the approved task-specific Master MD is the primary execution source.

Codex must:

1. Read this document completely.
2. Read the approved Master MD completely, from beginning to end.
3. Inspect the actual repository state relevant to the task.
4. Reconcile the Master MD with the real codebase before modifying files.
5. Follow the latest explicit Founder decision when sources conflict.

Codex must not reconstruct the task plan from scattered chat fragments when an approved Master MD exists.

If the Master MD conflicts with repository evidence or a later Founder decision, Codex must identify the conflict with concrete evidence. It must not silently choose a new product direction.

---

## 3A. Instruction Precedence (Confirmed)

This section resolves the operating-cadence difference between this document and `docs/cefflo/00_AGENTS.md` §A-05 ("Normal Autonomy"), identified during Founder review and confirmed here as governing:

- **For substantial/heavy Cefflo tasks, the approved Master MD and explicit Founder implementation authorization are mandatory and take precedence over Normal Autonomy.** Section 5 (Pre-Implementation Gate) of this document applies in full for any task that meets the "substantial work" threshold in Section 1 — Codex must not treat `00_AGENTS.md`'s lighter autonomy clause as a substitute for an approved Master MD and explicit authorization on such work.
- **Normal Autonomy (`00_AGENTS.md` §A-05) remains valid for routine, small, non-sensitive work** — inspecting, editing, testing, and committing/pushing normal-development work that does not rise to the level of a substantial task, and that does not touch the security/production-sensitive boundaries listed in `00_AGENTS.md` §A-06 or Section 10 of this document.
- **The Founder remains the final authority** in every case — this precedence rule allocates *which process applies*, not *who decides*. Nothing in this section grants Codex authority beyond what `00_AGENTS.md` §A-06 and Sections 5/8/10/15 of this document already reserve for explicit Founder approval.

When it is genuinely unclear whether a task is "substantial" or "routine," Codex must treat it as substantial and apply the Master-MD-gated process — the cost of an unnecessary gate is lower than the cost of unauthorized implementation.

---

## 4. Required Master MD Coverage

Before implementation, Codex must confirm that the Master MD provides enough direction for the authorized work. A complete heavy-task Master MD should define, where applicable:

- objective and scope
- explicit exclusions
- current-state evidence
- target state
- phases, batches, and subtasks
- dependencies and execution order
- security and product guardrails
- worktree, branch, and file boundaries
- database, migration, RLS, RPC, storage, and environment boundaries
- evidence requirements
- test and verification requirements
- acceptance criteria
- Founder decisions and gates
- rollback or recovery expectations
- Definition of Done

The absence of a non-applicable section is not automatically a blocker. Codex should stop only when missing information creates a genuine ambiguity that cannot be resolved safely from repository evidence or existing approved decisions.

---

## 5. Pre-Implementation Gate

Before changing the repository, Codex must verify all of the following:

- the relevant Master MD is approved
- the Founder has authorized implementation for the stated scope
- the target repository, branch, and worktree are correct
- existing uncommitted or active work will not be overwritten
- dependencies are available or clearly scheduled
- unresolved Founder decisions are identified
- security-sensitive and production-sensitive boundaries are understood
- required environment access is available

Codex must inspect the actual repository rather than assume the Master MD perfectly reflects its current state.

If implementation authorization has not been given, Codex may perform read-only inspection and report findings, but must not implement the task.

---

## 6. End-to-End Execution Rule

Once implementation is authorized, Codex must execute every phase, batch, and subtask that can safely be completed within the authorized scope.

Codex must not unnecessarily divide the work into tiny approval cycles or stop after each minor task to ask whether it should continue.

If the approved implementation path is clear and no legitimate blocker exists, Codex must continue through the Master MD until it reaches the relevant Definition of Done.

A normal engineering difficulty is not a reason to stop. Codex must investigate, solve, test, and continue.

---

## 7. Legitimate Stop Conditions

Codex may pause or stop only when at least one of these conditions genuinely applies:

- a real external dependency is unavailable
- active work would collide with the authorized changes
- a material product or architecture decision remains unresolved
- an explicit Founder gate has been reached
- a security or safety gate requires authorization
- a destructive or production-sensitive action requires explicit authorization
- required information cannot be determined from the Master MD, repository evidence, or existing approved decisions
- permissions or infrastructure prevent safe continuation
- continuing would exceed the Founder-authorized scope

Codex must not treat uncertainty that can be resolved by inspecting code, tests, migrations, configuration, or documentation as a Founder blocker.

---

## 8. No Scope Invention

Codex must not:

- invent product requirements
- introduce features merely because they appear useful
- redesign approved UI without authorization
- alter business logic outside the approved scope
- perform unrelated refactors unless required for the authorized task
- replace real implementation with mock behavior or fabricated success states
- bypass an explicit Founder gate
- modify or deploy production merely because implementation was authorized
- declare completion without the required evidence

If an adjacent defect prevents completion, Codex may fix it only when the fix is necessary, proportionate, safe, and within the reasonable boundary of the authorized task. The final report must disclose it.

If the adjacent issue requires a product decision or meaningfully expands scope, Codex must stop at the appropriate gate.

---

## 9. Repository and Worktree Discipline

Codex must respect the repository, branch, worktree, and file boundaries defined in the Master MD.

Before editing, Codex must inspect:

- current branch and worktree state
- tracked and untracked changes
- relevant recent commits when needed
- existing migrations and migration ledger
- files likely to overlap with active work
- repository-specific instructions

Codex must:

- preserve unrelated user or agent changes
- avoid overwriting active work
- keep changes scoped and reviewable
- avoid destructive Git operations unless explicitly authorized
- avoid broad formatting or cleanup unrelated to the task
- maintain compatibility with the approved environment and release strategy

When an active-work collision exists, Codex must preserve completed work and report the precise overlap before proceeding.

---

## 10. Database, Security, and Environment Rules

For database or backend work, Codex must verify the relevant schema, migrations, constraints, grants, RLS policies, RPCs, storage policies, and client call sites—not merely the intended design.

Codex must:

- use backward-compatible migrations when required by the release strategy
- preserve migration ledger integrity
- verify grants and authorization boundaries
- test role-specific access where applicable
- avoid exposing secrets or personal data in logs and reports
- respect local, test, staging, preview, and production boundaries
- avoid destructive data operations unless explicitly authorized

Production changes are never implied by general implementation authorization.

Codex must not deploy to production, modify production data, rotate production secrets, change production infrastructure, or perform destructive production operations unless the Founder explicitly authorizes that exact action.

---

## 11. Evidence Standard

Every completed batch must be supported by concrete evidence appropriate to the work.

Evidence may include:

- files changed
- relevant code paths and call sites
- migration IDs
- commands executed
- static analysis results
- unit, integration, and end-to-end test results
- build results
- browser verification
- responsive/mobile verification
- database, RLS, grant, RPC, and storage verification
- staging verification
- screenshots or directly usable preview links for UI-visible work
- known limitations, residual risks, and items not tested

Codex must never fabricate evidence or test results.

Codex must clearly distinguish between:

- implemented
- code-inspected
- statically verified
- runtime verified
- browser verified
- staging verified
- production verified
- not tested

A code review alone must not be reported as runtime PASS when runtime verification is required.

---

## 12. Testing and Regression Requirements

Codex must run all tests and verification specified by the Master MD.

Where appropriate, Codex must also run the minimum additional regression checks required to show that adjacent approved flows remain intact.

Testing should cover, when relevant:

- success paths
- failure and permission-denied paths
- authentication and authorization boundaries
- role-specific behavior
- concurrency or idempotency
- database and migration behavior
- mobile and responsive UI behavior
- browser console and network failures
- staging integration behavior
- backward compatibility

If a required test cannot be run, Codex must state exactly why, what substitute verification was performed, and what remains unverified.

---

## 13. UI-Visible Changes

For UI-visible implementation, Codex must:

- preserve the latest approved Cefflo UI as the baseline
- inspect the actual existing UI before changing it
- follow the exact structure, dimensions, hierarchy, spacing, components, states, and styling defined by the approved source
- avoid arbitrary visual additions or redesigns
- verify the result in a real browser
- test the relevant mobile viewport and interaction states
- check browser console and obvious runtime errors
- provide a directly usable preview URL when the environment supports one

UI-visible work is not fully accepted until the Founder can review the actual result when a Founder review gate is specified.

Screenshots may support evidence but do not replace an interactive preview when the Master MD requires one.

---

## 14. Handling a Blocker

When a legitimate blocker is reached, Codex must return a specific blocker report containing:

1. the exact blocker
2. the evidence proving it
3. the affected phase, batch, and subtask
4. work already completed
5. work that remains
6. the safest available options and their trade-offs
7. the exact Founder decision, permission, or external dependency required

Codex must keep completed work intact and clearly separate completed, blocked, and unstarted items.

Codex must not return a vague status such as "blocked" or "need clarification" without identifying the precise decision needed.

---

## 15. Founder Gates

A Founder gate is a deliberate decision or review point defined by the Master MD or explicitly introduced by the Founder.

At a Founder gate, Codex must:

- complete all safe work that precedes the gate
- present the required evidence in reviewable form
- identify the exact decision being requested
- avoid implementing gated alternatives before approval
- continue automatically after authorization if no new blocker exists

Codex must not create unnecessary Founder gates for routine technical decisions that are already constrained by the approved plan and repository evidence.

---

## 16. Definition of Done

A task is complete only when the relevant Definition of Done in the Master MD is satisfied.

Unless the Master MD states otherwise, completion requires:

- authorized scope implemented
- acceptance criteria satisfied
- required tests passing
- required runtime/browser/staging checks completed
- relevant security and permission boundaries verified
- no known fabricated, placeholder, or mock success behavior remains
- UI review link supplied where applicable
- unresolved risks and limitations disclosed
- repository changes left in a safe, reviewable state
- required Founder gates either passed or explicitly reported as remaining

"Code written" is not equivalent to "task complete."

---

## 17. Completion Report Format

At completion, Codex must provide a concise execution report containing:

### Overall Status

- PASS, PARTIAL, BLOCKED, or FAIL
- one-sentence outcome

### Scope Executed

- phases and batches completed
- any authorized items not completed

### Changes

- files changed
- migrations created or applied
- relevant implementation notes

### Verification

- tests run and results
- builds and static checks
- browser, runtime, database, and staging verification
- preview or review links

### Remaining Items

- unresolved issues or risks
- items not tested
- Founder gates or external dependencies still open

The report must be evidence-based and must not hide partial completion behind an overall PASS.

---

## 18. Standard Codex Task Instruction

For future Cefflo heavy tasks, the chat instruction to Codex may be kept short:

> Read `CODEX_WORKING_RULES.md` completely, then read the approved task Master MD completely and execute it end-to-end within the Founder-authorized scope. Reconcile it against the actual repository before editing. Stop only at a legitimate gate or blocker defined by the rules, and return the required evidence-based execution report.

If this file is stored inside a documentation directory, use its actual repository path in the instruction.

---

## 19. Governing Principle

The objective is to execute each approved Cefflo Master MD reliably from implementation start to its Definition of Done—without unnecessary fragmentation, scope invention, unverified completion claims, or unauthorized production action.
