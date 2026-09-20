# CEFFLO Engineering n8n Package

**Status:** FG-ENG-04 runtime implementation — pilot activation prohibited

This directory holds the source-controlled contracts, deterministic runner,
and policies for the four-workflow CEFFLO Engineering control plane. Runtime
qualification is permitted by FG-ENG-04. The real V11 pilot and workflow
activation remain prohibited until FG-ENG-07.

Planned workflow names:

1. `CEFFLO ENG - 00 - Control Plane`
2. `CEFFLO ENG - 01 - Context Builder`
3. `CEFFLO ENG - 02 - Role Executor`
4. `CEFFLO ENG - 99 - Failure & Escalation`

Models are providers behind role capability requirements. The runner, not a
prompt, enforces tool permissions. Phase 01 rejects production actions.

The runner binds to loopback by default, verifies HMAC request envelopes,
rejects replayed nonces, enforces the role/action matrix, and executes only its
fixed action registry. It has no free-form shell adapter. Model credentials
remain in n8n and never enter runner requests, logs, task packs, or Git.

Budget accounting reserves the worst-case request cost before dispatch. The
single cumulative ledger includes qualification, retry, and fallback usage and
fails closed at the Founder-approved USD 3.00 ceiling. A request with uncertain
usage retains its full reservation until reconciled.

The canonical OpenAI target is the dedicated Engineering DEV project
`proj_mQtcb9RRJj5euIafLwn8GICr`. Until its isolated n8n credential is created
and registered in `config/provider-credentials.json`, the OpenAI provider is
disabled and the Role Executor fails closed. The shared Content Creator
credential is not an Engineering credential.

Configuration and contracts in this package contain credential references
only. Secret values must never be committed.
