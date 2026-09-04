**Status:** CANONICAL — Founder-approved, merged into repo 2026-09-04
**Repo-reconciliation note:** Describes the TARGET multi-client architecture (Vendor Web/Desktop, Vendor Flutter, Rider Flutter, Customer Tracking, Operations/Helper, FOUNDR → cefflo_api → Supabase). Current live stack remains PWA-first for Vendor Web and Rider (see `docs/cefflo/02_ARCHITECTURE.md` AR-01/AR-02). Vendor Flutter and Rider Flutter are FUTURE capabilities per the Capability Truth States in `docs/cefflo/sot/01_PRODUCT_TRUTH.md` §10 — `docs/cefflo/05_DECISIONS.md` D-13's stage-gating for native Rider Flutter build sequencing remains in force until the Founder explicitly authorizes that build stage; this file does not itself authorize starting that work.

---

# CEFFLO — PRODUCT & TECHNICAL ARCHITECTURE SOT
**Status:** Canonical Architecture Doctrine
**Version:** 1.0 — 2026-09-04
**Owner:** Founder

## 1. Architecture Principle
Cefflo has one canonical operational truth.

```text
Vendor Web/Desktop
Vendor Flutter
Rider Flutter
Customer Tracking
Operations/Helper
FOUNDR
        ↓
     cefflo_api
        ↓
Supabase / Postgres / RPC / Storage
```

No client may maintain a competing operational source of truth.

## 2. Canonical Backend Ownership
Backend owns business truth for:
- authentication/authorization context;
- business tenancy;
- orders;
- location status;
- coverage;
- zones;
- vehicle compatibility;
- Rider capacity;
- planning eligibility;
- run construction;
- sequence validation/persistence;
- assignment;
- dispatch;
- delivery sessions/stops;
- delivery events;
- recovery eligibility;
- completion eligibility;
- POD references;
- customer-safe tracking projection;
- canonical ETA where supported;
- audit history.

## 3. Client Ownership
Clients own:
- presentation;
- navigation;
- form/client validation that does not replace server validation;
- loading/error/empty state;
- optimistic/pending UI only when safely reconciled;
- local preference state where appropriate;
- accessibility;
- responsive/native interaction.

Clients must not recreate backend business rules in Dart/JS.

## 4. Client Topology
### Vendor Web/Desktop
First-class broad operational/configuration client.

### Vendor Flutter
Separate mobile app; companion, not replacement.

### Rider Flutter
Separate execution app with Rider-specific state/authorization.

### Customer Tracking
Public tokenized safe projection, not direct operational-table access.

### FOUNDR
Privileged platform administration/operations; separate authorization domain.

## 5. Shared Packages
Conceptual:
- `cefflo_core`
- `cefflo_api`
- `cefflo_design`

Share only genuinely common concerns:
- typed models;
- API/RPC adapters;
- auth/session primitives;
- error mapping;
- environment config;
- design tokens/icons/assets where appropriate;
- telemetry abstractions;
- safe deep-link helpers.

Do not create one giant Vendor/Rider app or shared state tree.

## 6. API/RPC Contract Rule
Every operational mutation should:
1. authenticate/validate caller;
2. authorize tenant/role/action;
3. read/lock current canonical state where needed;
4. validate transition;
5. mutate canonical records atomically where required;
6. append event/audit;
7. return canonical snapshot/result;
8. be idempotent where retry is likely.

## 7. State Machine Doctrine
Delivery lifecycle vocabulary must be canonical.

Vendor preparation/business states may remain distinct from Rider delivery lifecycle where product semantics require it.

No client invents a private status vocabulary that changes business meaning.

## 8. Multi-Tenancy
Every business-owned record/action must preserve business isolation.

Requirements:
- RLS/authorization;
- no cross-tenant enumeration;
- IDs alone do not grant access;
- privileged/admin paths explicitly gated;
- test direct RPC/API calls, not UI hiding only.

## 9. Public Tracking Boundary
Anonymous Customer does not subscribe directly to protected operational tables.

Use high-entropy tracking token + safe projection.

Expose only minimum customer-safe fields.

## 10. Storage
Private by default for POD/private operational media.

Use scoped paths, policy checks and short-lived signed/proxy access.

No public reusable raw path for protected assets.

## 11. Realtime
Use realtime/subscriptions where they improve operations, but correctness must not depend solely on a websocket.

Clients need safe refresh/reconciliation.

Avoid duplicate subscriptions and stale state.

## 12. Offline / Retry
Where offline/pending actions are supported:
- distinguish queued/submitting/failed/confirmed;
- use idempotency;
- never claim completion before backend;
- reconcile conflicts;
- avoid duplicate POD/events;
- preserve only necessary pending data safely.

## 13. Location / Maps
Map/location truth remains backend-governed.

No server-only Mapbox/geocoding secret in Flutter/web client.

Mapbox Gate or provider credentials must not be bypassed by weakening security/environment guards.

A visual map is not evidence of GPS or ETA.

## 14. ETA
ETA is backend/canonical truth when implemented.

No client calculates/presents authoritative ETA independently unless explicitly designed as a canonical supported contract.

If credible writer is absent, UI says unavailable rather than fabricating.

## 15. Optimization
Planning/sequence/reorder is not automatically optimization.

Any optimizer must:
- be a defined backend capability;
- state inputs/constraints;
- preserve human review where required;
- expose conflicts;
- avoid unsupported AI claims.

## 16. Recovery
Recovery/reassignment requires narrow authorization, locking/concurrency safety and audit.

Post-pickup recovery must not be achieved by client-side reassignment hacks.

## 17. Auth & Session
- real authenticated sessions for protected clients;
- secure token handling;
- session restore/expiry;
- role/business context;
- no hardcoded OTP/password;
- no service-role key in client.

## 18. Environment Boundaries
At minimum:
- local/dev;
- staging;
- production.

Production mutations require explicit authorization.

Secrets never live in MD, source or client bundles.

## 19. Database Change Doctrine
- migrations are versioned;
- destructive changes gated;
- RLS/grants reviewed;
- backward compatibility considered for multiple clients;
- staging proof before Production;
- rollback/forward-fix strategy documented.

## 20. Observability
Capture enough to diagnose:
- API/RPC errors;
- auth failures;
- client crashes;
- failed mutations;
- webhook failures;
- payment events when enabled;
- background/notification failures;
- performance/health;
- privileged actions.

No sensitive payload logging by default.

## 21. Testing Pyramid
Static/unit → contract/RPC → widget/UI → integration → cross-client E2E → security → Production smoke.

Critical E2E:
Order → coverage/zone → plan → dispatch → Rider → stops/events → POD/issue/recovery → completion → customer-safe tracking/rating.

## 22. Cross-Client Consistency
No separate mobile operational database.

Every client should converge on canonical state after refresh/reconnect.

## 23. Security Non-Negotiables
- least privilege;
- RLS/authorization;
- secure secrets;
- private storage;
- safe public token;
- rate limits;
- idempotency;
- audit;
- dependency/security scan;
- no fake security via hidden UI.

## 24. Architecture Change Gate
Founder approval required for:
- replacing canonical backend;
- major auth/security model;
- destructive migration;
- merging Vendor/Rider apps;
- removing Vendor Web/Desktop;
- introducing Cefflo-owned rider marketplace/network;
- vendor-customer payment/accounting scope;
- major paid provider commitment;
- Production mutation.

## 25. Evidence Rule
Repo/runtime truth wins exact implementation details.
Founder-approved behavior wins product behavior.
Never fabricate migration/test/runtime evidence.

## 26. Definition of Done
Architecture is healthy when all clients consume one canonical backend, business rules are server-owned, tenant/security boundaries are proven, cross-client state converges, public tracking is safely projected, and no critical operation depends on mock/local-only truth.
