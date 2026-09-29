# CEFFLO PRODUCTION READINESS MASTER

**Status:** Canonical — Production Readiness Execution Control  
**Authority:** Execution control for Production Readiness. Does not override Product Truth or higher canonical product/architecture SOTs.  
**Purpose:** Canonical execution control document for moving Cefflo from current staging state through full-stack integration, production readiness, and production launch.

---

## 1. Mission

Cefflo is now entering the **Full-Stack Integration → Production Readiness → Production** phase.

The objective is not merely to “connect the backend.”

Production readiness means every in-scope user-facing surface, screen, interaction, backend read/mutation, authentication flow, communication flow, cross-surface state transition, and critical failure/recovery state works truthfully against canonical backend state and survives end-to-end validation.

A screen existing does not mean it is complete.  
A button existing does not mean it works.  
A successful toast does not prove persistence.  
A frontend restriction does not prove authorization.  
A passing unit test does not prove a real staging journey.

**Production readiness requires evidence.**

---

## 2. Whole-Platform Fleet Rule — Critical

Cefflo moves toward production as **ONE PLATFORM FLEET**.

The program must never be interpreted as “finish Vendor first, then Driver, then Customer, then FOUNDR.” Every execution package must consider **all applicable launch surfaces together**.

Current platform fleet:

| Surface | Architecture |
|---|---|
| Vendor Mobile | Vendor application |
| Vendor Web | Vendor web application |
| Operator Access | Role/access mode through Vendor Mobile and Vendor Web; NOT a separate app |
| Helper Access | Access through Vendor Mobile only; NO Helper Web |
| Driver Mobile | Separate Driver mobile application |
| Customer Tracking | Customer Tracking PWA; no customer login |
| FOUNDR | Platform administration web application |
| Marketing | Marketing surface/PWA where applicable to launch scope |

For every package P1–P8:

1. Identify every applicable surface.
2. Audit all applicable surfaces as one package.
3. Record all package gaps before implementation.
4. Batch implementation/fixes across applicable surfaces.
5. Validate backend persistence and cross-surface truth.
6. Record evidence.
7. Do not mark the platform package VERIFIED while an applicable critical surface remains unresolved.

“Move together” does **not** mean forcing the same feature onto every surface.

Use:
- APPLICABLE
- NOT APPLICABLE
- DEFERRED
- OUT OF SCOPE

Examples:
- Customer Tracking has no user login; do not create one merely to satisfy P1.
- Helper has no Web surface; do not create Helper Web.
- Operator is a role through Vendor surfaces; do not create an Operator app.
- FOUNDR has platform-admin authentication/authorization requirements distinct from Vendor.

---

## 3. Package Completion Model

Every package must report status at two levels:

### 3.1 Surface Status
Example for P1:

| Surface | P1 Status |
|---|---|
| Vendor Mobile | VERIFIED / IN PROGRESS / etc. |
| Vendor Web | VERIFIED / IN PROGRESS / etc. |
| Operator Access | VERIFIED / IN PROGRESS / etc. |
| Helper Access | VERIFIED / IN PROGRESS / etc. |
| Driver Mobile | VERIFIED / IN PROGRESS / etc. |
| Customer Tracking | N/A where appropriate |
| FOUNDR | VERIFIED / IN PROGRESS / etc. |
| Marketing | N/A / applicable status |

### 3.2 Platform Package Status

A package can become **PLATFORM VERIFIED** only when every applicable critical surface has been reconciled and verified.

Example:

> Driver recovery E2E remains unverified → P1 PLATFORM STATUS remains IN PROGRESS even if Vendor and FOUNDR already pass.

No surface may silently be left behind.

---

## 4. Canonical Backend Principle

All applicable surfaces operate against the same canonical business truth.

This does not mean every client shares identical frontend code. It means the platform must not maintain contradictory versions of the same business object.

Example:

**Vendor dispatches an order → Driver receives it → Customer tracks it → FOUNDR observes it**

This is the **same canonical order and delivery state**.

Authorization determines what each role may see or mutate.

All clients are untrusted. Backend authorization remains authoritative.

---

## 5. Status Vocabulary

Use one status vocabulary throughout this program:

| Status | Meaning |
|---|---|
| ⬜ NOT STARTED | Work/evidence not started |
| 🟡 IN PROGRESS | Active reconciliation/implementation/QA |
| 🟢 VERIFIED | Evidence proves required behavior |
| 🔴 BLOCKED | Cannot proceed due to real blocker |
| 🟣 FOUNDER GATE | Founder decision/approval required |
| ⚪ DEFERRED | Explicitly postponed |
| — OUT OF SCOPE | Not part of current launch |

Do not use unsupported completion percentages.

---

# 6. Execution Architecture

The detailed readiness gates are grouped into **8 platform-wide execution packages**, not dozens of isolated sequential tasks.

## P1 — Auth + Communication
Platform-wide authentication, authorization entry flows, auth/security email and communication foundation.

## P2 — Core Backend Wiring
Every applicable screen/action/control connected truthfully to canonical backend behavior.

## P3 — Delivery End-to-End
Prove the complete delivery business journey across Vendor → Driver → Customer Tracking → FOUNDR.

## P4 — Notification System
Event-to-channel architecture, in-app notification truth, messaging/email/WhatsApp scope and delivery evidence.

## P5 — FOUNDR + Control
Real platform administration, operational visibility and control.

## P6 — Security + Reliability
RLS/RPC/authz/security hardening plus failure, retry, offline and resilience behavior.

## P7 — Full QA + Launch Audit
Every screen, interaction, role, device/browser and cross-surface journey validated.

## P8 — Production Cutover
Production infrastructure, migrations, domains, secrets, deployment, smoke tests and launch.

---

# 7. Execution Rounds

Packages may execute in parallel where dependencies allow. Parallelism **does not break the fleet rule**.

| Round | Execution |
|---|---|
| **Round 1** | P1 Auth + Communication + P2 Core Backend Wiring + P4 Notification System + P5 FOUNDR + Control — parallel where safe |
| **Round 2** | P3 Delivery End-to-End after required Round 1 dependencies are ready |
| **Round 3** | P6 Security + Reliability across the integrated platform |
| **Round 4** | P7 Full QA + Launch Audit across all launch surfaces |
| **Round 5** | P8 Production Cutover |

Round 1 worktrees may specialize by package, but each package remains platform-wide.

Before dependent later rounds, outputs must be reconciled into one platform state.

---

# 8. P1 — Auth + Communication

## 8.1 Auth Matrix

Audit applicable flows across:

- Vendor Mobile
- Vendor Web
- Operator Access
- Helper Access
- Driver Mobile
- FOUNDR

Inventory:

- Splash/auth entry
- Sign Up
- Verify Email
- Sign In
- Forgot Password
- Reset Password
- Session persistence
- Session refresh
- Expired session
- Invalid/expired recovery
- Logout
- Invitation claim where applicable
- No-access state
- Authorization after authentication

Authentication and authorization are separate.

A query parameter or UI mode may change presentation but may never grant role authority.

Backend/server state decides Owner, Operator, Helper, Driver and FOUNDR authority.

## 8.2 Auth/Security Email

Current verified staging foundation:

**Sender:** `Cefflo <no-reply@auth.cefflo.com>`  
**Flow:** Supabase Auth → Resend Custom SMTP → recipient inbox  
**DNS:** Cloudflare DNS only

Known verified evidence:
- `auth.cefflo.com` verified.
- Supabase staging Custom SMTP configured.
- Real FOUNDR password-recovery email delivered.
- Recovery redirect worked.
- Password update succeeded.
- Reopening the same one-time recovery link was correctly rejected.

Do not mark other email types verified without evidence.

Inventory every required auth/security email, including where applicable:
- Verify Email
- Password Reset
- Signup confirmation
- Email-change/security message
- Invitation/claim message

For every communication record:

`EVENT → SENDER → RECIPIENT → TRIGGER → TEMPLATE → CTA → REDIRECT → EXPIRY → RETRY → FAILURE STATE → LOGGING → STAGING QA → PRODUCTION QA`

## 8.3 Support Email

`support@cefflo.com` must be treated as a separate system from auth no-reply.

Do not assume it exists or works until verified.

Determine:
- mailbox provider
- inbound delivery
- reply capability
- routing/ownership
- Reply-To behavior
- support footer usage
- spam protection
- staging/production test evidence

## 8.4 Operational Communication

Inventory all V1 operational communication events against product truth.

Potential events to verify, not assume:
- invitation
- rider/driver assignment
- run dispatched
- pickup/start delivery
- delivery approaching
- customer tracking link
- delivered
- failed delivery / Need Attention
- operational alerts

For each event define:

`EVENT → ACTOR → RECIPIENT → CHANNEL → TRIGGER → BACKEND SOURCE → RETRY → FAILURE HANDLING → LOGGING → USER PREFERENCE → COST`

Do not invent providers.

## 8.5 WhatsApp / Messaging

If WhatsApp remains deferred, state it clearly.

No UI may claim WhatsApp was sent when no provider exists.

If moved into V1, require a Founder Gate for:
- provider
- pricing
- templates
- consent
- phone normalization
- retry/failure handling
- backend architecture
- cost controls

## 8.6 In-App Notifications

Audit:
- event source
- persistence
- unread/read state
- badge/count
- deep link/action
- refresh/realtime behavior
- preferences
- failure state

No fake badge, fake count, fake success toast, or fabricated “sent” state.

## 8.7 Marketing Communication

Marketing communication must remain logically separate from transactional authentication.

If campaigns are in launch scope, define:
- consent
- unsubscribe
- audience/source
- sender identity
- sender reputation
- campaign delivery system

---

# 9. P2 — Core Backend Wiring

Build one **Interaction Ledger** across all applicable surfaces.

Minimum columns:

| Surface | Role | Screen | Control | User Action | Expected Result | Backend Contract | Persistence | Reload Proof | Error State | Status | Evidence | Package |
|---|---|---|---|---|---|---|---|---|---|---|---|---|

Audit:
- buttons
- links
- toggles
- forms
- slide/swipe controls
- modal CTAs
- retry
- refresh
- create/update/delete
- assign
- dispatch
- complete
- settings mutations

Classify every interaction:

- REAL
- BROKEN
- FAKE
- LOCAL-ONLY
- HIDDEN
- DEFERRED
- OUT OF SCOPE

A successful toast is not proof.

For mutations, normal proof should be:

**User action → backend response → canonical persisted state → reload/refetch → same state remains**

Core product areas include at minimum:
- Business Setup
- Business Profile
- Service Area
- Orders
- Zones
- Planning
- Runs
- Riders/Drivers
- Team
- Helper Pool where applicable
- Storefront
- Products
- Settings
- Integrations
- Customer Tracking
- Rating/POD
- FOUNDR operations

Do not add new product scope while reconciling.

---

# 10. P3 — Delivery End-to-End

This is a platform business-journey gate, not an isolated app test.

Validate:

**Owner authenticated  
→ business exists  
→ service area  
→ rider/driver available  
→ order created  
→ valid address/location  
→ zone/coverage  
→ planning  
→ run  
→ assignment  
→ Review & Dispatch  
→ Driver receives work  
→ PLAN ROUTE  
→ PICKUP CHECKLIST  
→ Start Pickup  
→ DELIVERY RUN  
→ Start Delivery  
→ customer visibility  
→ Arrive  
→ Complete  
→ POD where applicable  
→ Customer Tracking Delivered  
→ rating where applicable  
→ history/completed state  
→ FOUNDR sees correct operational truth**

Cross-surface state must agree.

## Customer Tracking

Validate:
- secure tracking access
- correct order
- Picked Up
- On the Way
- Delivered
- Tracking Unavailable
- refresh/refocus behavior
- rider data only where permitted
- ETA honesty
- Delivery Details
- POD
- rating
- rating persistence
- invalid/expired tracking access

No fabricated ETA, rider contact, POD, rating or notification.

---

# 11. P4 — Notification System

Create an Event → Channel Matrix:

| Event | Source | Recipient | In-App | Email | WhatsApp | V1 Required? | Provider | Status | Cost | Retry | Audit Log |
|---|---|---|---|---|---|---|---|---|---|---|---|

The system must prevent:
- duplicate communication
- fake notification UI
- unnecessary paid API calls
- missing critical events
- transactional/marketing mixing

Notification architecture must be driven by real product events and canonical backend state.

---

# 12. P5 — FOUNDR + Control

FOUNDR must observe and control platform truth, not demo data.

Audit:
- authentication
- platform-admin authorization
- password recovery
- operational visibility
- Need Attention
- admin delivery operations
- stuck rider/driver visibility where canonical
- maintenance
- feature/platform controls
- audit visibility
- version/platform information

Fabricated success behavior must be removed or explicitly blocked from launch.

FOUNDR changes that affect platform behavior must respect Founder/backend approval gates.

---

# 13. P6 — Security + Reliability

## Security

Audit:
- RLS
- RPC grants
- SECURITY DEFINER functions
- role escalation
- business isolation
- public tracking exposure
- invite abuse
- FOUNDR authorization
- secret handling
- rate limits
- auth enumeration
- replay/duplicate mutations
- idempotency
- audit logging

Frontend hiding is never authorization.

## Reliability

Validate:
- offline
- timeout
- duplicate tap
- 401
- 403
- 404
- 409 where applicable
- 429
- 5xx
- stale state
- partial failure
- retry
- recovery

Backend hardening gaps require explicit implementation plans and Founder Gates where architecture/security changes are involved.

---

# 14. P7 — Full QA + Launch Audit

Build matrices for:

A. Every screen  
B. Every interaction  
C. Every role  
D. Every cross-surface journey  
E. Device/browser coverage  
F. Failure/recovery states

Launch surfaces:
- Vendor Mobile
- Vendor Web
- Operator Access
- Helper Access
- Driver Mobile
- Customer Tracking
- FOUNDR
- Marketing where included in launch scope

Validate:
- supported mobile sizes
- desktop web
- mobile web
- relevant browsers
- refresh
- reopen
- session recovery
- cache/version refresh

Final E2E uses the real staging backend.

Mocks and unit tests support QA but do not replace staging E2E.

---

# 15. P8 — Production Cutover

Production is a separate approval gate.

Document and verify:
- production Supabase
- approved DB migrations
- production RLS
- production secrets
- environment variables
- Resend production configuration
- DNS
- production domains
- Auth Site URL
- Auth Redirect URLs
- rate limits
- map/geocode provider configuration
- notification provider configuration
- Flutter release configuration
- web deployment
- service-worker/cache versioning
- monitoring/logging
- rollback/recovery

No localhost or staging preview URL may leak into production communication.

## Production Smoke Test

After deployment, controlled production tests must cover at minimum:
- login
- signup where applicable
- verify email
- password reset
- business access
- critical create/read operation
- dispatch/delivery critical path
- Customer Tracking
- permissions
- FOUNDR access
- communication delivery

Use controlled production test accounts/data.

---

# 16. Founder Gate Register

Maintain one centralized register to prevent repeated decisions.

| Gate ID | Decision Required | Why | Options | Impact | Blocks | Status |
|---|---|---|---|---|---|---|

Founder approval is required before protected backend/schema/RLS/auth configuration changes, production deployment, or other decisions already governed by Cefflo’s canonical rules.

---

# 17. Evidence Register

Every important VERIFIED status must reference evidence.

Acceptable evidence may include:
- commit
- automated test
- staging E2E result
- DB result
- Supabase Auth log
- backend/function log
- deployment/version
- screenshot/preview where appropriate

A UI screenshot alone does not prove backend persistence or authorization.

---

# 18. Parallel Worktree Rules

Parallel work is encouraged only when ownership is safe.

For every package/worktree record:
- owned directories/files
- backend dependencies
- shared migration risk
- shared canonical-document risk
- merge order
- prerequisite package

Do not allow two parallel agents to independently modify the same critical backend contract.

Round 1 may use separate package worktrees:

- P1: platform-wide Auth + Communication
- P2: platform-wide Core Backend Wiring
- P4: platform-wide Notification System
- P5: FOUNDR + platform control dependencies

These are **not app-specific worktrees** by definition.

---

# 19. Execution Workflow Per Package

Use:

**AUDIT PACKAGE  
→ collect ALL gaps across applicable surfaces  
→ classify evidence/status  
→ Founder Gate only where necessary  
→ batch implementation  
→ package tests  
→ real staging E2E  
→ cross-surface reconciliation  
→ evidence register  
→ platform package verification**

Do **not** use:

**audit one button → patch → audit next button → patch → repeat**

The package model exists to reduce duplicated work, token usage and regressions.

---

# 20. Current Known Evidence Snapshot

**Reconciled:** 2026-09-29 against the repository, staging Supabase Auth logs and Vercel deployments.

## 20.1 Auth / Security Email Foundation (staging)

- Resend domain `auth.cefflo.com` is verified for staging.
- Supabase staging (`cefflo-staging`) Custom SMTP is configured.
- Current auth sender: `Cefflo <no-reply@auth.cefflo.com>`.
- A real FOUNDR password-recovery email was delivered through this sender.
- `support@cefflo.com` must NOT be marked configured until its actual mailbox/routing state is verified.
- WhatsApp/provider-dependent delivery notifications must NOT be marked live unless a real provider is wired and verified.

## 20.2 Password Recovery — Implementation vs Canonical vs Evidence

| Item | Value |
|---|---|
| FOUNDR recovery + current FOUNDR Sign In UI | Branch `claude/notification-system`, commits `c4a4403` → `61a53dc` |
| Implementation exists | YES |
| Canonical (in `main`) | NO — must not be treated as canonical until integrated |
| FOUNDR staging recovery E2E | VERIFIED — Supabase Auth log 2026-09-29 12:21 UTC: `GET /verify` → 303 (`login`), `PUT /user` → 200 (`user_modified`); reopening the same one-time link → 403 "One-time token not found" (correctly rejected) |
| Vendor Web recovery | Code + automated tests exist; real staging E2E NOT VERIFIED |
| Vendor Mobile / Operator / Helper recovery | Mobile deep-link implementation exists (`cefflo-vendor://auth-callback`); web-build compatibility fix exists for QA (`d04ad34`); tests 159/159; real staging E2E NOT VERIFIED |
| Driver Mobile recovery | Implementation exists (`cefflo-driver://auth-callback`); web-build fix `d04ad34`; tests 55/55; real staging E2E NOT VERIFIED |

## 20.3 QA Harness / Staging Test Surfaces

Manual staging QA deployments (built from `claude/notification-system`, staging Supabase):

- `https://cefflo-vendor-app-staging.vercel.app/**` — Vendor Mobile web build
- `https://cefflo-driver-app-staging.vercel.app/**` — Driver Mobile web build

These URLs still require Auth Redirect URL / configuration verification where applicable. `d04ad34` contains the web-build Forgot Password correction used for staging QA.

**CRITICAL CLASSIFICATION — QA HARNESS / STAGING TEST SURFACE**

The Vendor Mobile web build and its `?access=operator` / `?access=helper` routes, and the Driver Mobile web build, are QA/testing representations of the mobile applications. They are NOT production surfaces and must NOT be added to the production surface architecture (Section 2).

Do NOT introduce:
- Helper Web
- a separate Operator Web application
- a Driver Web product

Helper remains Vendor Mobile only. Operator remains a role/access mode through Vendor surfaces per canonical architecture. Driver remains Driver Mobile. Any temporary Vercel/web build used to test mobile behaviour must be labelled **QA HARNESS / STAGING TEST SURFACE**.

## 20.4 P1 Status Snapshot — Password Recovery Only

| Surface | Recovery | Reason |
|---|---|---|
| FOUNDR | 🟢 VERIFIED-STAGING | Section 20.2 evidence |
| Vendor Web | 🟡 IN PROGRESS | Implementation/tests exist; real staging E2E pending |
| Vendor Mobile | 🟡 IN PROGRESS | Implementation/tests exist; real device/deep-link E2E pending |
| Operator Access | 🟡 IN PROGRESS | Shares Vendor auth architecture; role/no-access E2E still requires verification |
| Helper Access | 🟡 IN PROGRESS | Shares Vendor Mobile auth architecture; role/no-access E2E still requires verification |
| Driver Mobile | 🟡 IN PROGRESS | Implementation/tests exist; real device/deep-link E2E pending |
| Customer Tracking | — NOT APPLICABLE | No customer login |

**P1 PLATFORM STATUS = 🟡 IN PROGRESS**

Do NOT infer the status of Sign Up, Verify Email, Sign In, session handling, invitations or other P1 flows from recovery status. Those require the full P1 audit.

---

# 21. Launch Gate

GO LIVE requires:

- no unresolved critical blocker
- no fake functionality on launch surfaces
- P1 Auth + Communication PASS
- P2 Core Backend Wiring PASS
- P3 critical Delivery E2E PASS
- P4 required V1 Notifications PASS or explicitly approved deferred scope
- P5 FOUNDR/control launch requirements PASS
- P6 Security + Reliability PASS
- P7 Full QA PASS
- P8 Production configuration/deployment PASS
- cross-surface truth PASS
- monitoring/logging available
- rollback/recovery path understood

No surface may silently remain behind the platform launch state.

---

# 22. Definition of Done

Cefflo is Production Ready only when the approved launch fleet functions as one integrated platform against canonical backend truth.

The final proof is not that individual apps “look finished.”

The proof is that:

**real users can authenticate → perform their permitted work → produce canonical backend state → other relevant surfaces observe the correct state → communications occur truthfully → failures recover safely → permissions hold → the full business journey survives staging and production smoke validation.**

---

# 23. Control Rule for Claude / Codex

This Master is an execution control document.

Before implementation:
1. Reconcile current repository truth.
2. Update package matrices/evidence.
3. Identify genuine gaps.
4. Identify Founder Gates.
5. Respect worktree/package boundaries.

Do not:
- resurrect retired architecture
- invent product scope
- invent providers
- claim UI existence equals backend completion
- claim tests equal staging E2E
- merge protected/canonical branches without approval
- deploy production without approval
- modify schema/RLS/auth configuration without the required Founder gate
- clean or alter unrelated dirty working trees

All implementation must move Cefflo toward one verified platform state.
