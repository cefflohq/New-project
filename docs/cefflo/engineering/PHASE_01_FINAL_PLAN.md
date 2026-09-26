# CEFFLO Engineering Bootstrap — Phase 01 Final Plan

**Status:** CANONICAL IMPLEMENTATION PLAN — FG-ENG-01 APPROVED 2026-09-19  
**Current stop:** FG-ENG-02 — Baseline Selection  
**Scope:** Engineering Department bootstrap in DEV/STAGING only  
**Authority:** Founder decision D-39

## 1. Objective

Build the minimum secure Engineering system required to operate:

```text
E1 Lead → E2 Build ⇄ E3 Pixel → E4 Verify → E5 Ship
```

n8n is the deterministic control plane. The system has no Engineering
super-agent. Models are configurable providers behind role capability
requirements.

## 2. Canonical architecture

The minimum n8n family is:

1. `CEFFLO ENG - 00 - Control Plane`
2. `CEFFLO ENG - 01 - Context Builder`
3. `CEFFLO ENG - 02 - Role Executor`
4. `CEFFLO ENG - 99 - Failure & Escalation`

The Role Executor dispatches typed role requests. It is infrastructure, not a
sixth role.

The restricted Engineering Runner is a deterministic tool gateway. It will
accept named actions with typed arguments, enforce role permissions outside
model prompts, and reject free-form shell execution.

## 3. Security boundary

Phase 01 is DEV/STAGING only. The runtime must not contain a production
credential, production DB administrator, production VPS/root identity,
production Supabase service role, Docker socket, generic shell endpoint, or
arbitrary egress path.

Models receive capabilities and task data, never raw credentials. The runner
independently authenticates n8n, checks the task/role/action/environment,
enforces path and network policies, applies idempotency, and records an audit
event.

The relevant security authority is
`docs/cefflo/security/CEFFLO_CYBER_SECURITY_MASTER.md`. Phase 01 applies it to
the Engineering attack surface only.

## 4. Context and evidence

Every execution uses an immutable Task Pack containing exact source SHAs,
content hashes, reference version, active Founder decisions, scope, allowed
paths, acceptance criteria and trust metadata.

Normal retrieval excludes superseded, historical, quarantined and unverified
material. Repository content and external artifacts are data, not control
instructions.

## 5. Role locks

- E1 reads scoped truth and writes plans; it cannot mutate source.
- E2 writes only assigned worktree paths and executes allowlisted builds/tests.
- E3 receives the approved reference and actual render in the same multimodal
  request. No image input means no visual PASS.
- E4 independently verifies an exact candidate tree and cannot repair it.
- E5 cannot edit source and may ship only the exact E4-verified manifest to a
  task branch and DEV/STAGING preview.

Any source mutation after E4 PASS invalidates the PASS.

## 6. Attempts and cost

There are three total autonomous implementation attempts: initial execution,
then at most two targeted repairs. No fourth attempt is permitted. Transport
retries are separately bounded and cannot reset this budget.

Every role run records provider/model, capability, tokens where available,
duration, cost or estimation status, retries, attempts and result. Missing
price metadata fails closed unless explicitly permitted by an approved budget
policy.

## 7. Founder gates

| Gate | Status |
|---|---|
| FG-ENG-01 Phase Authorization | APPROVED |
| FG-ENG-02 Baseline Selection | PENDING — current stop |
| FG-ENG-03 Canonical Reference | PENDING |
| FG-ENG-04 Spend/Credential Envelope | PENDING beyond existing non-production capability |
| FG-ENG-05 Scope Exception | PENDING |
| FG-ENG-06 Security Exception | PENDING |
| FG-ENG-07 Pilot Activation | PENDING |
| FG-ENG-08 Operational Acceptance | PENDING |

## 8. Ordered implementation

1. Track the Engineering and Cyber Security masters.
2. Create bootstrap documentation, contracts and policy configuration.
3. Produce the decision/dependency-aware baseline reconciliation packet.
4. Stop at FG-ENG-02.
5. After FG-ENG-02, create the approved isolated baseline worktree.
6. Implement the schema, artifact store, restricted runner and adapters.
7. Generate/import four workflows inactive.
8. Run functional and security tests.
9. Obtain later gates before provider spend, pilot activation or operation.

## 9. Rollback principle

Rollback begins by disabling dispatch, stopping the runner, revoking scoped
non-production credentials and preserving evidence. Additive schema or audit
records are not destructively removed automatically. Original branches remain
unchanged until the new baseline and rollback path are verified.

## 10. Forbidden during Phase 01

- production or Crown Jewel access;
- generic or model-generated shell execution;
- arbitrary egress;
- secrets in prompts/logs/source;
- Docker socket access;
- merge/rebase/cherry-pick/deletion before FG-ENG-02;
- E2/E3 self-verification, E4 repair, or E5 unverified source changes;
- workflow/pilot activation before its gate;
- n8n PostgreSQL upgrade;
- modification of Marketing workflows;
- wider department or full Cyber Security implementation;
- deletion of legacy implementation before dependency and rollback proof.

## 11. Operational acceptance

Engineering AI is operational only after the four-workflow control plane,
role-enforced runner, context provenance, replay/idempotency controls, real E3
multimodal path, independent E4, exact-tree E5, kill switches, cost limits and
the Vendor V11 DEV/STAGING evidence loop all pass, followed by FG-ENG-08.

