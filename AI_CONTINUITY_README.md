# CEFFLO — AI Agent Continuity & Automatic Handoff Protocol

**Canonical purpose:** Allow Codex and Claude to alternate as active implementation agents without depending on a final handoff message when either agent hits a usage limit or stops unexpectedly.

**Operating model:**
`Codex works → limit/stops → Claude resumes → limit/stops → Codex resumes`

Both agents are **workers/implementers by default**. Neither agent is assigned a permanent reviewer role.

---

## 1. Core Rule — Handoff Must Be Continuous, Not End-of-Session

Do **not** wait until the end of a task to create a handoff.

Every active agent must keep the repository checkpoint current **during execution**.

After every meaningful atomic work unit, update the live checkpoint immediately.

Examples of an atomic work unit:

- one file or coherent group of files changed;
- one migration applied;
- one provider action completed;
- one test suite run;
- one blocker discovered;
- one external credential/provider state changed;
- one acceptance gate passed or failed.

If the agent is cut off immediately afterward, the next agent must still be able to reconstruct the exact state.

---

## 2. Canonical Continuity Files

The repository must contain these two files:

### `AI_CONTINUITY_README.md`
This file. It defines the permanent operating protocol for Codex and Claude.

### `AI_ACTIVE_CHECKPOINT.md`
A continuously updated live execution state.

`AI_ACTIVE_CHECKPOINT.md` is the **first file every agent reads before doing any work** and one of the **last files updated after every atomic work unit**.

Do not create separate Codex and Claude checkpoint files. Both agents share the same canonical state.

---

## 3. Mandatory Start-of-Session Recovery Routine

Whenever Codex or Claude becomes the active worker, before modifying anything:

1. Read `AI_CONTINUITY_README.md`.
2. Read `AI_ACTIVE_CHECKPOINT.md`.
3. Run:
   - `git branch --show-current`
   - `git rev-parse HEAD`
   - `git status --short`
   - `git diff --stat`
   - `git diff --check`
4. Inspect the current diff relevant to the active sprint.
5. Verify the live checkpoint against actual repository/provider state.
6. Resume from `NEXT EXACT ACTION`.
7. Do **not** repeat completed work unless verification shows the checkpoint is stale or incorrect.
8. If checkpoint and actual state conflict, actual state wins. Update the checkpoint before continuing.

Never assume that the previous agent finished cleanly.

---

## 4. Mandatory Live Checkpoint Format

`AI_ACTIVE_CHECKPOINT.md` must always contain:

```md
# CEFFLO — ACTIVE EXECUTION CHECKPOINT

Updated:
Active agent:
Current Stage:
Current Sprint:
Current Sub-sprint / Work Package:
Status:

## 1. Current Objective
...

## 2. Last Confirmed Completed Action
...

## 3. Work Completed
- ...

## 4. Files Changed / Added
- ...

## 5. Current Git State
- Branch:
- HEAD:
- Working tree:
- Uncommitted changes:
- Commit/push status:

## 6. Tests / Verification
- ...
- PASS / FAIL / NOT RUN

## 7. Provider / External State
- Supabase:
- Vercel:
- Docker:
- DNS/Cloudflare:
- Other:

## 8. Secrets / Sensitive State
- Never write secret values.
- Record only whether a secret exists, where it is stored securely, and whether it must be recreated.
- Example: "Staging DB password exists only in secure ephemeral storage; value not recorded."

## 9. Current Blocker
...

## 10. NEXT EXACT ACTION
One exact next action only.

## 11. After That
- next action
- next action

## 12. DO NOT DO
- ...

## 13. Acceptance Gate Remaining
- ...

## 14. Production Safety
- Production accessed: YES/NO
- Production modified: YES/NO
- Production credentials used: YES/NO

## 15. Recovery Notes
Anything the next agent must verify if the previous process was interrupted mid-command.
```

---

## 5. Update Frequency

The active agent must update `AI_ACTIVE_CHECKPOINT.md`:

### Before
- any protected provider action;
- migration;
- destructive/reset operation;
- environment/secret change;
- deployment;
- Production-related action.

### Immediately after
- each meaningful code change group;
- each test suite;
- each provider action;
- each discovered blocker;
- each PASS/FAIL gate;
- each change in next action.

This makes the checkpoint resilient to usage-limit termination.

---

## 6. Atomic Execution Rule

Work in small recoverable units.

Bad:

> "Implement S4-03 completely, then update checkpoint."

Good:

> 1. Update checkpoint: starting RLS matrix change.
> 2. Make RLS change.
> 3. Run relevant tests.
> 4. Update checkpoint with result.
> 5. Continue to next atomic unit.

No agent should hold several hours of unrecorded state only in chat memory.

---

## 7. When an Agent Hits a Limit Unexpectedly

If the active agent disappears without a final handoff, the replacement agent must **not** guess.

Run the Start-of-Session Recovery Routine and reconstruct from:

1. `AI_ACTIVE_CHECKPOINT.md`;
2. Git HEAD/status/diff;
3. repository files;
4. test output that still exists;
5. provider state, when authorized;
6. current sprint acceptance criteria.

If an operation may have been interrupted mid-flight, verify whether it completed before retrying it.

Never blindly rerun:
- migrations;
- resets;
- password rotations;
- provider creation;
- deployments;
- DNS changes;
- destructive tests.

---

## 8. Agent Switching Rule

Only **one implementation agent is active at a time** on the same working tree.

When switching:

`ACTIVE_AGENT=Codex` → `ACTIVE_AGENT=Claude`

or

`ACTIVE_AGENT=Claude` → `ACTIVE_AGENT=Codex`

The new agent inherits the same:
- branch;
- working tree;
- uncommitted diff;
- sprint;
- acceptance gate;
- provider state.

Do not start a second implementation branch unless explicitly authorized.

---

## 9. No Duplicate Re-Audit Rule

The incoming agent should not spend tokens re-auditing the whole repository.

Default recovery scope:

1. live checkpoint;
2. current diff;
3. files named in checkpoint;
4. current sprint canonical docs;
5. failing tests/blocker only.

A full repository scan is allowed only when:
- checkpoint is unreliable;
- Git state materially conflicts;
- a release/security gate explicitly requires it;
- Founder authorizes a broader audit.

---

## 10. Token-Efficiency Rule

Both Codex and Claude are implementation workers.

Use tokens for:
- coding;
- migrations;
- tests;
- debugging;
- provider configuration;
- acceptance verification.

Avoid:
- repeating full project summaries;
- regenerating plans already locked;
- rereading unrelated docs;
- reviewing another agent's work by default;
- duplicate repository scans.

Review is performed only when a specific safety/release gate requires it.

---

## 11. Protected Actions

Founder approval remains required where the canonical Stage 4 rules require it, including:

- Production changes;
- provider/project creation;
- secrets or environment creation/change;
- migration/RLS/security changes where protected;
- destructive hosted actions;
- DNS/domain cutover;
- recovery/rollback exercises;
- Go-Live.

A previous approval applies only to its recorded scope.

Do not infer new authorization from an old approval.

---

## 12. Secret Handling

Never record secret values in:

- this README;
- `AI_ACTIVE_CHECKPOINT.md`;
- Git;
- chat handoffs;
- test reports;
- logs.

Checkpoint only non-secret metadata:

- secret exists / does not exist;
- secure location if needed;
- whether it is ephemeral;
- whether it was deleted;
- whether rotation/recreation is required.

---

## 13. Commit Strategy

Do not rely on commits as the only handoff mechanism.

Uncommitted work is allowed when the active sprint intentionally requires it, but the checkpoint must state exactly what is uncommitted.

Before any commit/push:
- all required tests for that checkpoint must be recorded;
- `git diff --check` must pass;
- unrelated changes must be excluded;
- commit/push must comply with the current authorization.

---

## 14. Current CEFFLO Stage 4 Rule

Canonical Stage 4 contains S4-01 through S4-16.

Do not skip sprint dependencies.

Current execution must always record:

`Stage 4 → S4-XX → sub-work-package → exact acceptance gate`

Sub-work-package letters such as `S4-01A` to `S4-01E` are execution labels, not replacements for the canonical sprint.

---

## 15. Initial Live Checkpoint — Current State

Use the following as the starting state when installing this protocol.

### Current Stage
Stage 4

### Current Sprint
S4-01 — isolated preview/staging/test configuration and disposable test target

### Current execution area
S4-01E — Hosted Acceptance

### Confirmed completed
- Working directory/repository access established.
- Docker host works; Codex uses full-access approval only when Docker/local Supabase requires it.
- Environment identity contract implemented.
- Production fallback removed.
- Fail-closed Production guards implemented.
- Local disposable Supabase implemented.
- Local reset/recreation PASS.
- Environment/negative guard tests PASS (30/30 at latest hosted-readiness verification).
- Local backend validation PASS.
- Local transactional E2E PASS.
- Hosted readiness PASS.
- `cefflo-staging` created in Mumbai/South Asia.
- Staging project ref: `tomvvmwktehexwhktenw`.
- Production ref `lmaxtrubwdniovxyuqdy` remains prohibited for non-production testing.
- Staging foundation migration applied.
- Hosted schema/RLS/storage validation PASS.
- `cefflo-pod` private bucket verified.
- Manual official Supabase Session Pooler `psql` authentication eventually PASS after password propagation delay.

### Current blocker
Automated hosted transactional E2E has **not** passed yet.

Manual interactive `psql` authentication succeeded, but the automated E2E attempt using an ephemeral captured secret failed authentication. The discrepancy between the manually entered effective password and the ephemeral secret capture must be resolved safely.

### NEXT EXACT ACTION
Diagnose/repair the **ephemeral staging password capture path only**, without another blind password rotation, then perform a single non-mutating authentication check using the exact securely captured bytes.

### Only after authentication passes
Run the already-approved hosted transactional E2E against `cefflo-staging`, validate cleanup/backend/RLS/storage/migration integrity, then continue to Vercel Preview/Staging acceptance under the required authorization.

### DO NOT DO
- Do not access or modify Production.
- Do not use Production credentials.
- Do not start S4-02 before S4-01 acceptance passes.
- Do not reset staging blindly again.
- Do not configure Vercel until the hosted E2E gate and authorization sequence permit it.
- Do not commit/push unless authorized.
- Do not change Docker host security/permissions.

---

## 16. Definition of a Successful Agent Handoff

A handoff is successful even if the previous agent disappears without a final message when the incoming agent can answer, from repository state alone:

1. What sprint are we in?
2. What exactly is already done?
3. What files are currently changed?
4. What tests passed/failed?
5. What provider actions already happened?
6. What is the blocker?
7. What is the next exact action?
8. What is prohibited?
9. Was Production touched?
10. Can work resume without repeating a completed protected action?

If those answers are available, continuity is working.

---

**Operating principle:**

> **Checkpoint continuously → execute atomically → verify immediately → update state → next agent resumes from repository truth.**

---

## Context Budget Amendment

Default recovery scope after an agent switch is limited to:

1. AI_ACTIVE_CHECKPOINT.md
2. Current Git diff/status
3. Current sprint canonical documentation
4. A maximum of 3–8 files directly relevant to the recorded NEXT EXACT ACTION

A full-repository scan is prohibited by default.

A broader scan is allowed only when:
- AI_ACTIVE_CHECKPOINT.md conflicts materially with actual repository/Git state;
- the current task is an explicit release/security gate requiring broad verification;
- the current blocker cannot be resolved from the bounded recovery scope;
- Founder explicitly authorizes a broader audit.

The incoming agent must prefer the smallest sufficient context and must not spend tokens re-reading unrelated files, historical summaries, or already verified work.
