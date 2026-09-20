# CEFFLO --- ARCHITECTURE

Fuller canonical architecture doctrine (target multi-client end-state
incl. Vendor Flutter/Rider Flutter): `docs/cefflo/sot/02_ARCHITECTURE.md`
(2026-09-04). Current live stack remains PWA-first per AR-01/AR-02
below; see `docs/cefflo/05_DECISIONS.md` D-13 and D-23 for Flutter
stage-gating.

## AR-00 System Model

One secure backend supports multiple Cefflo clients.

## AR-01 Client Surfaces

-   `cefflo.com` --- marketing/acquisition.
-   `vendor.cefflo.com` --- Vendor PWA.
-   `rider.cefflo.com` --- Rider PWA.
-   `tracking.cefflo.com` --- tokenized Customer Tracking.
-   `foundr.cefflo.com` --- FOUNDR Command Center.
-   `api.cefflo.com` --- only if the canonical production architecture
    actually requires it.

## AR-02 Core Stack

Current direction: - GitHub --- code SOT; - Supabase ---
backend/data/auth/realtime/storage/functions; - Vercel --- web
deployment; - Cloudflare --- domain/DNS/edge controls where
configured; - PWA-first clients; - Contabo Ubuntu VPS --- AI engineering
workstation; - Codex --- primary engineering executor.

Do not replace major stack components without Founder approval.

## AR-03 Shared Contracts

Cross-client contracts include: - identity/authorization; - business
membership; - orders; - rider team/assignment; - delivery lifecycle; -
delivery stops/events; - tracking tokens; - POD; - ratings; -
version/update behaviour.

Shared contracts must not be independently redefined by each client.

## AR-04 Data Direction

Known backend domains include businesses/members, riders, delivery
sessions, orders, assignments, stops, append-only delivery events, rider
locations, tracking tokens, ratings and POD. Exact current schema must
be verified from repo/migrations.

## AR-05 Public vs Authenticated Surfaces

Vendor/Rider/FOUNDR are authenticated according to their role. Customer
Tracking is public-token based and must expose only required
information.

## AR-06 Release Architecture

Prefer preview/staging validation before production. Normal releases
should minimize interruption. Backend evolution should be
backward-compatible where practical. Health checks and rollback must
protect production.

## AR-07 Architecture Change Gate

Any material change to client boundaries, backend ownership, deployment
topology, identity model, lifecycle contract or SOT requires
architecture review and Founder approval when protected by
`00_AGENTS.md`.


## AR-08 Company AI Governance

The canonical company AI governance and cross-department orchestration
architecture is `docs/cefflo/control/CEFFLO_CONTROL_LAYER_MASTER.md`.

```text
Founder
  ↓
CEFFLO Control Layer
  ↓
n8n — primary technical execution/control-plane engine
  ↓
Engineering / Product Intelligence / Marketing / Sales & CRM / Customer Service
```

Cyber Security is a cross-company guardrail, not a department or AI
super-agent. Department masters remain authoritative inside their departments.
The Control Layer governs between departments and across company-level gates,
permissions, events, model routing, tools, cost, audit and system guards.

Agents reason. Control Layer governs. Tools execute. Company Truth grounds.
Founder decides exceptions.
