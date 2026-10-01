# CEFFLO Engineering n8n Package

**Status:** Bootstrap structure only — FG-ENG-02 pending

This directory holds the source-controlled contracts and policies for the
four-workflow CEFFLO Engineering control plane. No workflow has been generated,
imported or activated at this gate.

Planned workflow names:

1. `CEFFLO ENG - 00 - Control Plane`
2. `CEFFLO ENG - 01 - Context Builder`
3. `CEFFLO ENG - 02 - Role Executor`
4. `CEFFLO ENG - 99 - Failure & Escalation`

Models are providers behind role capability requirements. The runner, not a
prompt, enforces tool permissions. Phase 01 rejects production actions.

Configuration and contracts in this package contain credential references
only. Secret values must never be committed.

