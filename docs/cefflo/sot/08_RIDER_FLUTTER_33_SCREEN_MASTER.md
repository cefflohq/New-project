**Status:** CANONICAL SOURCE ARTIFACT — merged into repo 2026-09-04. The master itself remains "Revised Working Master — Founder Review Required" (see its own status line below) — it is NOT YET IMPLEMENTED and NOT YET Founder-locked (its own Definition of Done checklist is unchecked, Founder Gates A-I are open). The current LIVE Rider client remains the PWA described in `docs/cefflo/07_RIDER.md`, consistent with `docs/cefflo/05_DECISIONS.md` D-13 stage-gating. Do not treat this file as authorizing Rider Flutter implementation to begin.

---

# CEFFLO Rider Flutter — 33 Full Screen Master

**Document Type:** Product / UX Screen Inventory & Implementation Reconciliation Baseline
**Platform:** Cefflo Rider Flutter Mobile
**Status:** Revised Working Master — Founder Review Required
**Supersedes:** Previous 51-screen Rider inventory
**Date:** 2026-09-04

> This document replaces the earlier 51-screen Rider map. The earlier inventory over-fragmented field execution into too many routes. This revision consolidates transient delivery states, navigation handoffs, customer-contact actions, POD review, completion transitions and recovery states into focused operational screens.

---

# 1. Purpose

Define the complete working Rider Flutter screen map while keeping the Rider experience focused, safe and practical during field execution.

This master distinguishes:

- **Full screens/routes** — counted in the 33-screen inventory.
- **Operational states** — remain inside a parent screen.
- **Components** — reusable UI, not separate routes.
- **Bottom sheets/dialogs/actions** — not counted as screens unless later explicitly promoted.
- **Native subsystems** — background GPS, camera/POD, notifications and external navigation are engineering capabilities, not artificial pages.

The target is not to maximize screen count. The target is complete functional coverage with the minimum sensible route fragmentation.

---

# 2. Core Architecture Guardrails

1. Rider Mobile is a **pure Flutter application**.
2. Rider Mobile and Vendor Mobile are separate Flutter apps.
3. Both consume canonical backend contracts/packages where appropriate.
4. Canonical operational truth remains:
   **Flutter → cefflo_api → Supabase / Postgres / RPC**.
5. Flutter owns presentation/client state only.
6. Do not recreate canonical coverage, zones, vehicle compatibility, capacity, planning eligibility, ETA, recovery eligibility, assignment rules, delivery transition rules or notification truth in Flutter.
7. Rider is a **field-execution app**, not a business-management app.
8. Rider access is **vendor-invite based**. No public rider marketplace/signup model.
9. External navigation apps may own turn-by-turn navigation; Cefflo owns run/stop state.
10. Returning from external navigation must restore the exact current run/stop and revalidate stale state.
11. Never claim GPS/background tracking is active unless the native service is genuinely running and backend writes are verified.
12. Never claim customer notification success, ETA, route optimization, POD upload, completion or recovery success unless canonical backend/provider state supports the claim.
13. Cefflo visual foundation remains **Black / White / Graphite**, with **Signal Lime candidate #C7F000** as operational signal.
14. Support **Light / Dark / System** presentation while preserving the approved Rider structure.
15. Rider UI must prioritize one-handed use, large touch targets, minimal reading and low distraction.

---

# 3. Safety Interaction Rule — Founder Locked

All critical Rider transitions use **SLIDE**, not tap.

Mandatory slide actions:

- **Start Pickup**
- **Start Delivery**
- **Arrive**
- **Complete Order**
- **Next Stop**

Canonical reusable component:

## Cefflo Critical Slide Action

Must support:

- circular Signal Lime knob
- clear instruction label
- disabled state
- loading/in-flight state
- backend failure/retry
- duplicate-action protection
- accessibility
- one-handed operation
- no accidental tap fallback

The approved Start Pickup direction uses a **black card/background with white text** and Signal Lime slide knob.

---

# 4. Revised Master Screen Inventory — 33 Full Screens

## ENTRY

| ID | Full Screen | Responsibility |
|---|---|---|
| **R-01** | **Splash** | Brand launch, bootstrap, session initialization and safe routing. |

## ACCESS / AUTH

| ID | Full Screen | Responsibility |
|---|---|---|
| **R-02** | **Invitation / Accept Invite** | Validate vendor invitation, show relevant vendor context and allow eligible Rider to accept. |
| **R-03** | **Rider Setup** | Complete required invited-Rider profile/setup fields. |
| **R-04** | **Sign In** | Rider authentication. |
| **R-05** | **Forgot Password** | Initiate password recovery. |
| **R-06** | **Reset Password** | Set a new password from valid recovery flow. |

### Not separate screens
- Invitation success
- Invalid/expired invitation
- Already accepted invitation
- Setup success

These are states within R-02/R-03 unless later proven to require dedicated routes.

---

## MAIN / HOME

| ID | Full Screen | Responsibility |
|---|---|---|
| **R-07** | **Home** | Rider landing surface: current assignment, resume active run, next work or honest no-assignment state. |

### R-07 states
- No assignment
- Assignment available
- Resume active run
- Network/retry
- Stale assignment
- Required permission warning

---

## RUN PREPARATION

| ID | Full Screen | Responsibility |
|---|---|---|
| **R-08** | **Run Overview** | Assigned run summary, pickup context, stop count, map/route overview and only genuinely available operational metrics. |
| **R-09** | **Plan Route** | Assigned stops + map; Rider may reorder permitted stop sequence using local knowledge and confirm/persist it. |

### R-09 states/components
- Stop list
- Drag/reorder
- Reactive map
- Route review
- Confirm sequence
- Persistence loading/error
- Rejected stale sequence

### Route planning guardrail
Cefflo must not claim route-optimization intelligence merely because Rider can reorder stops. Rider uses local knowledge; backend remains canonical for assignment and allowed sequence changes.

---

## PICKUP EXECUTION

| ID | Full Screen | Responsibility |
|---|---|---|
| **R-10** | **Pickup** | Pickup location/instructions/readiness and **Slide Start Pickup**. |
| **R-11** | **Pickup Checklist** | Verify assigned orders/items/stops before departure; surface missing-item/issue entry. |
| **R-12** | **Ready to Deliver** | Final departure review and **Slide Start Delivery**. |

### Pickup execution rule
Do not advance pickup state from optimistic local state if canonical transition fails.

---

## ACTIVE DELIVERY

| ID | Full Screen | Responsibility |
|---|---|---|
| **R-13** | **Active Delivery** | Primary live run workspace: progress, map, current stop, next-stop context and run continuity. |
| **R-14** | **Current Stop** | Active customer/address/instructions/contact/navigation plus arrival/completion states. |
| **R-15** | **Proof of Delivery** | Capture/review/submit POD using real camera/storage/backend capabilities. |
| **R-16** | **Delivery Issue** | Report delivery/pickup issue and display supported resolution/recovery/reassignment state. |
| **R-17** | **Run Complete** | Canonically confirmed end-of-run summary. |

---

# 5. Active Delivery State Model

The active run must not be implemented as a maze of routes.

## R-13 Active Delivery

Contains:

- run progress, e.g. `3 of 8 stops`
- map
- current-stop card
- next-stop preview
- run status
- honest GPS/tracking state where available
- issue entry
- safe resume behavior

Selecting current stop opens R-14.

## R-14 Current Stop

Contains:

- customer name
- delivery address
- delivery notes/instructions
- relevant order context
- Navigate action
- Call action
- WhatsApp/contact action where approved
- arrival state
- completion state

### Navigation

`Navigate` launches an approved external navigation application where configured.

**Navigate / Handoff is NOT a full Cefflo screen.**

When Rider returns:

1. restore current run
2. restore current stop
3. refresh canonical state
4. detect stale/reassigned/completed state
5. prevent duplicate actions

### Arrival

Arrival is a state within R-14.

Critical action:

**SLIDE ARRIVE**

Do not create a dedicated Arrived route.

### POD

When POD is required:

R-14 → R-15 Proof of Delivery

R-15 owns:

- camera capture
- preview/review
- retake
- upload
- retry
- canonical POD association
- submit state

**POD Review is not a separate full screen.**

### Complete Order

After required delivery evidence is satisfied:

**SLIDE COMPLETE ORDER**

Completion must be backend-confirmed.

After success:

R-15/R-14 → R-13 Active Delivery

R-13 advances its canonical current-stop context.

### Next Stop

The transition to the next execution step uses:

**SLIDE NEXT STOP**

`Stop Complete / Next Stop` is not a separate route.

After the final stop:

R-13 → R-17 Run Complete

---

# 6. ISSUE / RECOVERY MODEL

## R-16 Delivery Issue

Consolidates:

- pickup-stage issue where appropriate
- missing item
- unable to deliver
- customer/contact issue
- address/access issue
- other approved reason
- submitted issue detail
- pending resolution
- resolved state
- backend-approved recovery
- backend-approved reassignment

### Guardrails

- Rider cannot invent reassignment.
- Rider cannot locally override canonical run ownership.
- Recovery eligibility remains backend-owned.
- Post-pickup reassignment must use the approved recovery contract.
- Unsupported states must fail safely.
- Never display fabricated "resolved" or "reassigned" success.

---

# 7. ASSIGNMENTS / HISTORY

| ID | Full Screen | Responsibility |
|---|---|---|
| **R-18** | **Assignments** | Rider-visible assignment/history workspace. |
| **R-19** | **Assignment Detail** | Read the permitted details of active/issue/completed assigned work. |

### R-18 tabs/states
- Active
- Issues
- Completed

`Completed Deliveries` is therefore not a separate route.

`Completed Delivery Detail` reuses R-19 in read-only completed state.

---

# 8. PROFILE

| ID | Full Screen | Responsibility |
|---|---|---|
| **R-20** | **Profile** | Rider account/profile hub. |
| **R-21** | **Edit Profile** | Edit permitted Rider identity/contact fields. |
| **R-22** | **Vehicle** | View/edit permitted vehicle details. |
| **R-23** | **Rider Documents** | Licence/document information if retained after product/backend reconciliation. |

### Vehicle guardrail
Vehicle compatibility/eligibility remains canonical backend logic. Client edits cannot bypass backend validation.

### R-23 status
**REVIEW / Founder Gate.**

Retain only if actual Cefflo Rider workforce/compliance model needs a dedicated full-screen document surface. Otherwise merge into Profile/Vehicle.

---

# 9. SETTINGS

| ID | Full Screen | Responsibility |
|---|---|---|
| **R-24** | **Settings** | Rider preferences/settings hub. |
| **R-25** | **Navigation** | Preferred supported external navigation app/behavior. |
| **R-26** | **Notifications** | Rider notification preferences where supported. |
| **R-27** | **Appearance & Language** | Light/Dark/System and supported language preference. |
| **R-28** | **Location & Permissions** | Honest device/app location and background-permission status/guidance. |

### R-28 rule
This screen must read real permission/service state. It cannot show "GPS tracking active" from a hardcoded/mock flag.

---

# 10. SECURITY

| ID | Full Screen | Responsibility |
|---|---|---|
| **R-29** | **Security** | Rider account security and password-management surface. |

`Change Password` is a flow/state within R-29, not a separate full screen.

---

# 11. HELP / SUPPORT

| ID | Full Screen | Responsibility |
|---|---|---|
| **R-30** | **Help & Support** | FAQ, contact/support entry and Rider delivery/safety guidance. |

Separate Help Centre, Contact Support and Delivery Safety pages from the old inventory are consolidated here unless content volume later proves a dedicated route is necessary.

---

# 12. LEGAL / ABOUT

| ID | Full Screen | Responsibility |
|---|---|---|
| **R-31** | **Privacy Policy** | Cefflo privacy policy. |
| **R-32** | **Terms of Service** | Cefflo terms. |
| **R-33** | **About Cefflo** | App version/build and relevant application/legal information. |

---

# 13. Revised Full Screen Count

| Group | Count |
|---|---:|
| Entry | 1 |
| Access / Auth | 5 |
| Home | 1 |
| Run Preparation | 2 |
| Pickup Execution | 3 |
| Active Delivery | 5 |
| Assignments / History | 2 |
| Profile | 4 |
| Settings | 5 |
| Security | 1 |
| Help / Support | 1 |
| Legal / About | 3 |
| **TOTAL** | **33** |

**Canonical IDs: R-01 → R-33**

---

# 14. Core Operational Screens

The actual field-execution heart of Rider Mobile is intentionally compact:

1. **R-07 Home**
2. **R-08 Run Overview**
3. **R-09 Plan Route**
4. **R-10 Pickup**
5. **R-11 Pickup Checklist**
6. **R-12 Ready to Deliver**
7. **R-13 Active Delivery**
8. **R-14 Current Stop**
9. **R-15 Proof of Delivery**
10. **R-16 Delivery Issue**
11. **R-17 Run Complete**

These 11 screens must receive the highest UX, safety, lifecycle and backend-integration attention.

---

# 15. Canonical Rider Journey

## Access

**Invitation → Rider Setup → Sign In**

## Assigned Work

**Home → Run Overview → Plan Route**

## Pickup

**Pickup → SLIDE Start Pickup → Pickup Checklist → Ready to Deliver → SLIDE Start Delivery**

## Multi-stop Run

**Active Delivery → Current Stop → Navigate → return/resume → SLIDE Arrive → POD if required → SLIDE Complete Order → Active Delivery → SLIDE Next Stop**

Repeat until final stop.

## Completion

**Final stop complete → Run Complete**

## Exception

At a supported execution point:

**Delivery Issue → canonical issue/recovery state → resume the correct canonical run/stop**

---

# 16. Primary Navigation — Reconciliation Baseline

Existing Rider vocabulary has used:

- **Home**
- **Orders**
- **Route**
- **Profile**

For Flutter reconciliation:

### Home
R-07

### Orders / Assignments
R-18

### Route
State-aware entry:
- no run → route overview/empty context
- assigned/pre-run → R-08/R-09
- active run → R-13

### Profile
R-20

This is a reconciliation baseline, not authorization to blindly copy legacy PWA navigation.

When a delivery run is active, **Current Run / Current Stop takes operational priority**.

---

# 17. Not Counted as Full Screens

The following are intentionally not separate routes:

- Invitation success
- Invitation error/expired state
- Route Review
- Navigate / external navigation handoff
- Arrived state
- Customer Contact
- POD Review
- Complete Order
- Stop Complete
- Next Stop
- Recovery / Reassignment state
- Completed Deliveries tab
- Completed Delivery Detail variant
- Change Password flow
- FAQ section
- Contact Support section
- Safety Guidance section
- Bottom navigation shell
- Active-run persistent controls
- Stop cards
- Map markers
- route progress
- slide component
- confirmation dialogs
- logout confirmation
- camera/location OS permission prompts
- loading/skeleton
- empty state
- offline state
- retry state
- stale-session state
- duplicate-action warning
- upload progress
- snackbars/toasts
- push notification itself
- Google Maps/Waze/Apple Maps application

---

# 18. Shared UI Families

33 screens must not become 33 unrelated layouts.

## Family A — Auth / Access
R-02–R-06

## Family B — Run Overview / Planning
R-07–R-09

## Family C — Field Execution
R-10–R-17

## Family D — Assignment Lists / Detail
R-18–R-19

## Family E — Profile / Settings
R-20–R-29

## Family F — Support / Legal
R-30–R-33

---

# 19. Native / Flutter Engineering Subsystems

## A. Background Location

Must be a real Flutter/native subsystem if live Rider tracking is enabled.

Requirements include:

- permission lifecycle
- Android foreground service where required
- iOS background location mode where required
- sensible/battery-aware update policy
- canonical API/write path
- verified backend location records
- correct start/stop lifecycle
- logout/run-completion cleanup
- no false active-tracking claim

## B. Camera / POD

Requirements:

- real device camera
- preview/retake
- upload
- retry
- canonical storage/backend association
- safe failure state
- no fabricated upload success

## C. External Navigation

Requirements:

- approved navigation targets
- intent/deep-link handoff
- exact run/stop context preservation
- return/resume
- backend refresh
- stale-state detection
- duplicate-action protection

## D. Customer Notifications

Founder-approved direction includes customer notification beginning when Rider starts delivery, with at minimum early-stop customers potentially receiving on-the-way/tracking information through the intended channel when the backend/provider implementation genuinely supports it.

Rider UI must not own provider/business logic and must not fabricate send success.

## E. Offline / Weak Network

Where implemented:

- preserve safe local read context
- never invent canonical delivery transitions
- only queue actions explicitly designed to be replay-safe
- reconcile after reconnect
- prevent duplicate completion/POD submissions

---

# 20. Required Repo / Product Reconciliation

Before implementation scope is frozen, audit R-01 through R-33 against:

- current Rider PWA
- Rider Flutter code/routes
- shared Flutter packages
- cefflo_api
- Supabase schema/RPCs
- rider assignments/stops/session contracts
- delivery events
- POD/storage contracts
- location contracts
- issue/recovery contracts
- current experience-system direction

Every screen must be classified:

- **KEEP**
- **MERGE**
- **REMOVE**
- **NEW**
- **EXISTS / POLISH**
- **HOLD**

Verify specifically:

1. Invite-only Rider access.
2. No public Rider signup.
3. Home/Assignments/Route/Profile navigation.
4. Plan Route drag/reorder behavior.
5. Map reaction to reordered sequence.
6. Sequence persistence through canonical backend.
7. Pickup → Checklist → Start Delivery flow.
8. All five critical actions use slide.
9. Real background GPS before tracking claims.
10. Verified location writes.
11. Safe external navigation return/resume.
12. Real camera/POD path.
13. Canonical completion transition.
14. Duplicate-action protection.
15. Issue/recovery backed by real contracts.
16. No fabricated ETA.
17. No fabricated customer notification success.
18. Vehicle compatibility remains backend-owned.
19. Decide R-23 Rider Documents retain vs merge.
20. No Vendor-only features leak into Rider.

---

# 21. Founder Gates

## Gate A — 33-Screen Inventory
Founder reviews R-01 through R-33.

## Gate B — Rider Navigation
Lock final Flutter primary navigation after repo/PWA reconciliation.

## Gate C — Field Execution
Lock R-10 through R-17 as one coherent operational system, not isolated pages.

## Gate D — Background Location
Prove native background GPS and canonical writes before enabling live-tracking claims.

## Gate E — Route Sequence
Verify Rider reorder persistence and backend validation.

## Gate F — POD
Verify camera → upload → canonical association → completion flow.

## Gate G — Recovery
Do not expose recovery/reassignment behavior beyond actual backend support.

## Gate H — Rider Documents
Decide whether R-23 remains a dedicated page or merges into Profile/Vehicle.

## Gate I — Experience System
All screens must use the approved Cefflo Rider visual/safety system.

---

# 22. Acceptance Criteria

The revised Rider architecture is acceptable when:

- Rider can enter through a valid invitation/auth flow.
- Rider sees only authorized assigned work.
- Rider can inspect an assigned run.
- Rider can reorder permitted stops and persist the sequence.
- Rider can execute pickup checklist.
- Start Pickup uses slide.
- Start Delivery uses slide.
- Active run state survives navigation handoff/resume.
- Arrive uses slide.
- POD uses real camera/upload infrastructure.
- Complete Order uses slide.
- Next Stop uses slide.
- Backend failure never silently advances canonical state.
- Duplicate actions are prevented.
- Run Complete reflects canonical completion.
- Issues/recovery reflect canonical backend truth.
- GPS/tracking claims reflect real native service state.
- Light/Dark presentation remains consistent.
- Rider is not exposed to unnecessary Vendor/admin complexity.

---

# 23. Definition of Done

This Master is finalized only when:

- [ ] Founder reviews all 33 screens.
- [ ] R-01 through R-33 are reconciled with actual routes/components.
- [ ] Every screen receives KEEP / MERGE / REMOVE / NEW / EXISTS-POLISH / HOLD.
- [ ] R-23 Rider Documents decision is made.
- [ ] Duplicate responsibilities are removed.
- [ ] Operational states are not unnecessarily promoted into routes.
- [ ] The 11 core operational screens form one coherent journey.
- [ ] All five critical Rider actions use the canonical slide component.
- [ ] Background location is proven before tracking UI is enabled.
- [ ] Route reorder/persistence is tested.
- [ ] Navigation handoff/resume is tested.
- [ ] POD is tested end-to-end.
- [ ] Completion/next-stop transitions are tested against backend truth.
- [ ] Issue/recovery behavior is tested.
- [ ] No Vendor-only subscription/payment/storefront/business-management features exist in Rider.
- [ ] Final screen count is recalculated after reconciliation.
- [ ] Founder explicitly locks the final Rider Flutter Screen Map.

---

# 24. Current Working Baseline

## **33 full screens**
### **R-01 → R-33**

Core execution:

**Home → Run Overview → Plan Route → Pickup → Pickup Checklist → Ready to Deliver → Active Delivery → Current Stop → POD → Delivery Issue when needed → Run Complete**

Critical transitions:

**SLIDE Start Pickup → SLIDE Start Delivery → SLIDE Arrive → SLIDE Complete Order → SLIDE Next Stop**

This 33-screen revision supersedes the previous 51-screen inventory and is the preferred baseline for Rider Flutter reconciliation.
