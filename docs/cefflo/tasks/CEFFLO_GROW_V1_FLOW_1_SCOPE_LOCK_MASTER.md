# CEFFLO GROW V1 --- FLOW 1 SCOPE LOCK & CAPABILITY TRUTH MASTER

**Type:** Founder-controlled Task Master\
**Baseline:** `staging @ 9e7ea2dae61deaaee068f156d4b0086d7fade14d`\
**Executor:** Claude\
**Implementation authorization:** NONE --- audit, reconcile, define and
report only\
**Production authorization:** NONE\
**Required stop:** Founder Gate

## 0. Mission

Establish and freeze the definitive Cefflo Grow V1 launch scope before
Flow 2 implementation.

This task must answer with repository evidence: what Grow V1 must do at
public launch; what is desirable, post-V1 or out of scope; what is LIVE,
PARTIAL, MISSING, LEGACY/NON-CANONICAL or UNVERIFIED; and what must be
built in Flow 2.

Do not implement missing product capability during Flow 1.

## 1. Authority & Required Reading

Read: 1. `docs/cefflo/CEFFLO_BRAND_BRAIN.md` 2.
`docs/cefflo/agent-os/CEFFLO_AGENT_OS_CORE.md` 3.
`docs/cefflo/agent-os/CLAUDE_OPERATING.md` 4.
`docs/cefflo/audits/CEFFLO_REPO_TRUTH_RECONCILIATION_REPORT.md` 5. This
Task Master

Authority: current Founder instruction → Brand Brain → Agent OS Core →
Claude Operating MD → this Task Master → verified repo/runtime truth →
current evidence → older docs → legacy material → conversation memory.

## 2. Founder-Locked Grow V1 Promise

Working launch promise:

> Bring in today's orders → Cefflo validates and locates them →
> organizes the delivery workload → optimizes the delivery plan → vendor
> reviews → riders execute multi-drop runs → customers track → delivered
> today.

Cefflo adapts to vendors' existing order workflows instead of forcing
high-volume vendors to re-key orders manually.

## 3. REQUIRED V1 --- Founder Locked

### 3.1 AI Optimization Layer

`REQUIRED V1`. Do not downgrade.

Required outcome:

**Orders → location intelligence → geographic/operational grouping →
proposed runs → rider/run recommendation where applicable → efficient
stop sequence → vendor review/manual adjustment → dispatch**

Audit actual repo truth for: - lat/lng capture and geocoding -
zones/grouping - rider capacity - run creation - stop sequence
persistence - stop ordering/manual reorder - rider assignment - vendor
review/dispatch - navigation handoff - distance/time/route calculation -
optimization engine/provider - unresolved-location handling -
plan-change auditability

Do not call manual sequencing "AI optimization." The implementation may
ultimately use deterministic optimization, AI-assisted logic, or a
combination; the required user outcome is operationally useful
optimization.

### 3.2 CSV + Excel/XLSX Bulk Order Import

`REQUIRED V1`. Do not downgrade.

A vendor with ~100 orders/day must not be forced to key them in one by
one.

Define/audit: - CSV upload - Excel/XLSX upload - column
recognition/mapping - required fields - preview before commit -
validation - invalid/missing row correction - duplicate handling -
delivery-date handling - address normalization - import summary -
partial-success policy - retry/idempotency - canonical order creation -
location/geocoding after import - movement into planning

Imported records must become canonical Cefflo orders, not a parallel
shadow dataset.

## 4. Connected Spreadsheet Intake

Founder direction: minimize workflow migration. Investigate: - Google
Sheets connection/sync - Google Drive spreadsheet/file intake -
connected spreadsheet source - manual/scheduled sync - source-row
identity - duplicate prevention - changed/deleted/cancelled row
behavior - auth/security

Recommend exactly one: - `REQUIRED V1` - `DESIRABLE V1 IF LOW-RISK` -
`POST-V1`

Founder makes the final classification.

## 5. Other Order Intake Paths

Audit: - Cefflo Storefront - Manual New Order - CSV - Excel/XLSX -
Google Sheets - Google Drive - website/form/webhook if evidenced -
ecommerce/API/POS only if evidenced

For each determine whether it is real, canonical, tenant-safe, supplies
downstream-required data, and can proceed through locate → zone/group →
plan → dispatch → track.

Never infer integrations from marketing copy.

## 6. Location → Coverage → Zone Contract

Define/audit:

**Address → validation/normalization → coordinates → coverage decision →
zone/grouping input → planning**

Inspect address fields, lat/lng population, geocoding, autocomplete,
coverage model, zone model/UI/RPCs, automatic/manual assignment,
out-of-coverage behavior, unresolved-address correction, and whether
missing location blocks dispatch.

## 7. Optimization / Planning Contract

Define exact V1 behavior.

Inputs may include today's eligible orders, coordinates, geographic
relationship, rider availability/capacity, readiness and supported
delivery constraints.

System output must define proposed runs/grouping, recommended allocation
where applicable, recommended stop sequence and unresolved conflicts.

Vendor must be able to review before dispatch, make approved manual
adjustments, change rider where permitted, reorder stops and explicitly
confirm/dispatch.

Rider must receive an ordered run, next-stop context and navigation
handoff.

If repo only has deterministic grouping/sequencing, say so. If no
optimizer exists, say so.

## 8. Canonical Operational Lifecycle

Audit existing statuses and propose one canonical Grow V1 lifecycle.

Conceptual journey only:

**Received → Prepare → Pack → Ready → Planned → Assigned → Pickup →
Delivery Run → Delivered / Failed / Exception**

Use actual canonical backend terminology where different.

Map: - backend values - Vendor presentation - Operations/Helper
presentation - Rider presentation - Customer-safe presentation - actor
allowed to transition - illegal transitions - recovery transitions -
legacy duplicate status systems

## 9. Four Workspace Responsibility Lock

### Vendor / Owner

Audit launch-critical business setup, order intake/correction, overview,
workforce/riders, coverage/zones, optimization/planning, review,
dispatch, live visibility, Need Attention and recovery.

### Operations / Helper

Launch responsibility: **Prepare → Pack → Ready**. Audit identity,
permissions, preparation/packing/readiness and handoff.

### Rider

Launch responsibility: **Receive run → understand sequence → pickup
checklist → execute multi-drop → POD/result → completion**. Audit auth,
assignment, stops, sequence, current stop, navigation, slide actions,
GPS, POD, failed delivery, recovery and resume behavior.

### Customer

Launch responsibility: storefront/order where applicable → truthful
tracking → delivery progress → completion/rating where supported. Audit
storefront, tracking token/page, statuses, ETA truth, location/rider
visibility, POD/rating and privacy.

## 10. Exception & Recovery Contract

Audit required V1 behavior for at least: - invalid/unresolved address -
out-of-coverage - duplicate import - malformed/partial import - rider
unavailable - capacity exceeded - rider removed after planning - order
not ready - customer unavailable - failed delivery - post-pickup
reassignment - duplicate action submission - refresh during run -
network loss - stale plan after changes - cancelled order - plan re-run
after manual edits

For each identify priority, current behavior, desired V1 behavior,
responsible workspace, dispatch-blocking status and recovery/audit
requirement.

## 11. Explicit Non-Goals

Create a scope-protection list. Investigate/defer or exclude where
appropriate: - nationwide rider marketplace - public helper
marketplace - vendor-customer invoices/payouts/payment
balances/quotations/accounting - arbitrary storefront color builder -
nonessential FOUNDR analytics - speculative POS/API integrations -
advanced predictive intelligence beyond launch-critical optimization -
unnecessary enterprise/decorative features

AI Optimization Layer and CSV/Excel import are NOT candidates for
exclusion.

## 12. Launch-Critical FOUNDR Boundary

Classify FOUNDR/admin surfaces: - `LAUNCH REQUIRED` - `POST-V1` -
`REMOVE / NON-CANONICAL`

Focus only on business/account oversight, Cefflo subscriptions/platform
revenue, critical operational/support administration, platform
health/incident visibility, necessary intervention and audit visibility.

Do not reintroduce Invoices & Payouts or vendor-customer finance.

## 13. Two-Axis Capability Classification

Every capability gets two independent labels.

Launch priority: - `REQUIRED V1` - `DESIRABLE V1` - `POST-V1` -
`OUT OF SCOPE` - `FOUNDER DECISION REQUIRED`

Current truth: - `LIVE` - `PARTIAL` - `MISSING` -
`LEGACY / NON-CANONICAL` - `UNVERIFIED`

Every LIVE/PARTIAL finding requires evidence. Backend existence alone is
not equivalent to live UI/E2E capability.

## 14. Audit Coverage

Inspect enough of the repo to establish truth across Vendor,
Operations/Helper, Rider, Customer, Invite/workforce, shared frontend,
Supabase migrations/schema/RPCs/functions, Edge Functions,
auth/RLS/grants, planning/run/stop logic, location/geocoding,
imports/uploads, FOUNDR, tests and relevant environment/config/docs.

Search semantically and by exact terms including: csv, xlsx, excel,
spreadsheet, google sheets, drive, import, bulk, geocode, lat, lng,
coverage, zone, route, optimize, plan, sequence, run, stop, capacity,
dispatch, rider, tracking, eta, reassign, recovery, failed, invite,
helper, prepare, pack, ready.

Do not infer absence from one grep.

## 15. Evidence Rules

Prefer file paths, function/RPC names, migrations, tables/columns, real
call sites and tests.

Distinguish: 1. backend exists 2. frontend calls it 3. UI exposes it 4.
E2E path is proven

Do not claim runtime/browser validation unless actually performed.

## 16. No-Implementation Guardrail

Allowed: read, search, inspect, compare, classify, and create/update
Flow 1 documentation/evidence.

Not authorized: product implementation, migrations, schema/RPC changes,
UI feature builds, marketing builds, deployments, env/secret mutation,
Production actions, or unrelated merges.

## 17. Required Deliverables

Create:

`docs/cefflo/launch/CEFFLO_GROW_V1_SCOPE_LOCK.md`

It must contain: 1. Grow V1 definition 2. launch promise 3. canonical
operating journey 4. Required V1 5. Desirable V1 6. Post-V1 7. Out of
Scope 8. order intake matrix 9. CSV/Excel contract 10. connected
spreadsheet recommendation 11. location/coverage/zone contract 12. AI
Optimization contract 13. planning/review/dispatch contract 14. status
lifecycle/map 15. four-workspace responsibility matrix 16.
exception/recovery matrix 17. FOUNDR launch boundary 18. capability
matrix: priority × truth 19. dependency map 20. current repo gaps 21.
proposed Flow 2 scope 22. unresolved Founder decisions 23. definition of
scope freeze

Also create:

`docs/cefflo/audits/CEFFLO_GROW_V1_SCOPE_LOCK_AUDIT_REPORT.md`

Keep detailed evidence in the audit report; keep the scope contract
readable.

## 18. Required Dependency Map

At minimum:

**Order Intake** → **Canonical Validation** → **Address / Location** →
**Coverage** → **Zone / Geographic Grouping** → **Optimization /
Planning** → **Vendor Review / Manual Adjustment** → **Rider
Assignment** → **Dispatch** → **Pickup** → **Ordered Multi-Drop Run** →
**Customer Tracking** → **Delivery Result** → **Recovery / Completion /
Audit**

Identify missing upstream capabilities that block downstream work.

## 19. Flow 2 Handoff

Do NOT execute Flow 2.

Propose dependency-ordered workstreams for **Flow 2 --- Finish Core
Operational Engine** based only on verified gaps.

For each proposed workstream include objective, dependencies, likely
systems/files, likely migration/backend/frontend work, tests, evidence,
collision/worktree concerns and any Founder gate.

## 20. Acceptance Criteria

Flow 1 passes only if: - baseline verified at
`9e7ea2dae61deaaee068f156d4b0086d7fade14d` - canonical authority
honored - AI Optimization = REQUIRED V1 - CSV = REQUIRED V1 - Excel/XLSX
= REQUIRED V1 - Google Sheets/Drive investigated with recommendation -
Storefront/manual intake verified - location/geocoding, coverage, zones,
planning/grouping, stop sequencing, rider capacity, vendor review/manual
adjustment and multi-drop truth verified - all four workspaces audited -
status lifecycle reconciled - launch-critical exceptions/recovery
defined - FOUNDR boundary defined - non-goals documented - priority and
implementation truth independently classified - every LIVE/PARTIAL
finding evidenced - Flow 2 dependency order proposed - no product
implementation - no Production action - working-tree state reported -
Founder decisions clearly separated from executor recommendations

## 21. Definition of Done

Flow 1 is DONE only when the Founder can say:

> "Yes. This is exactly the Cefflo Grow V1 we intend to launch."

Until Founder approval, scope remains PROPOSED and Flow 2 is not
authorized.

## 22. Required Completion Report

Return: A. STATUS --- PASS/PARTIAL/BLOCKED\
B. BASELINE --- branch/SHA/tree state\
C. GROW V1 SUMMARY\
D. REQUIRED V1 --- exact list\
E. CURRENT TRUTH --- counts for LIVE/PARTIAL/MISSING/LEGACY/UNVERIFIED\
F. BIGGEST LAUNCH GAPS --- dependency order\
G. AI OPTIMIZATION FINDINGS\
H. CSV/EXCEL FINDINGS\
I. GOOGLE SHEETS/DRIVE RECOMMENDATION\
J. FOUR WORKSPACE READINESS\
K. EXCEPTION/RECOVERY READINESS\
L. FOUNDR BOUNDARY\
M. FLOW 2 PROPOSED WORKSTREAMS\
N. FOUNDER DECISIONS REQUIRED\
O. FILES CREATED/CHANGED\
P. VALIDATION\
Q. PRODUCTION\
R. FOUNDER GATE

## 23. Founder Gate

**STOP --- FOUNDER GATE**

Do not begin Flow 2. Do not deploy. Do not touch Production.

Wait for Founder review of: - `CEFFLO_GROW_V1_SCOPE_LOCK.md` -
`CEFFLO_GROW_V1_SCOPE_LOCK_AUDIT_REPORT.md`

Founder response will be one of: - `APPROVE SCOPE FREEZE` -
`APPROVE WITH CORRECTIONS` - `REJECT / REVISE`
