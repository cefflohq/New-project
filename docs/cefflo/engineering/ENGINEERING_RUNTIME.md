# CEFFLO Engineering Runtime Contract

**Status:** Phase 01 bootstrap contract  
**Current gate:** FG-ENG-02 pending

## Trust zones

```text
Founder-authorized intake
        ↓
n8n deterministic control plane
        ↓ authenticated typed request
Restricted Engineering Runner
        ↓ policy-approved action
Task worktree / build / renderer / model adapter / staging preview
```

Production and Crown Jewels are outside the Phase 01 graph.

## Request envelope

Every runner request will carry:

```text
request_id
task_id
role
action
arguments
environment
task_pack_hash
idempotency_key
timestamp
nonce
body_hash
signature
```

The runner validates identity, signature, request age, nonce uniqueness,
schema, role/action permission, environment, task state and budget before an
action begins.

## Execution rules

- Actions are registry IDs, not shell strings.
- Executables and argument arrays are defined by trusted configuration.
- Working directories resolve inside the assigned task root.
- Symlink/path escape is rejected.
- Environment variables are allowlisted per action.
- Time, output, process and network limits are explicit.
- Builds have no network by default.
- Dependency installation is a separate locked action.
- Artifacts are hashed before persistence.
- Output is redacted before storage or model delivery.

## State and idempotency

Consequential actions require a unique idempotency key. The control plane uses
compare-and-set state transitions. A restart must resume from persistent state
without duplicating a commit, push or preview publication.

## Worktree isolation

Each task binds to an approved base SHA and a dedicated worktree, temp area and
artifact area. The runner rechecks the Git root, base and allowed paths before
mutation. A task cannot read another task's private artifacts or write another
task's worktree.

## Verification identity

E4 receives a clean verification execution and read-only candidate source. Its
writable outputs are separate. The verdict binds to the Task Pack hash,
candidate tree hash, test results, render hashes and verifier run ID.

E5 creates a commit only when the staged tree equals the verified tree. Any
extra, missing or modified path fails closed.

## Control switches

The runtime must support independent disablement of:

- the Engineering family;
- a role;
- a provider/model;
- a runner action;
- outbound model calls;
- Git push;
- preview publication.

Disablement is enforced outside models and produces an audit event.

