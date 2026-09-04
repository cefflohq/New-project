# CEFFLO Flow 3 — Vendor Web/Desktop Completion: Behavioural Contract Pack

**Status:** Flow 3 execution record and Flow 4 handoff document
**Branch:** `claude/flow-3-vendor-web-desktop-completion`
**Scope:** Vendor Web/Desktop (`vendor/index.html` + `vendor/backend.js`), against
`CEFFLO_FLOW_3_VENDOR_WEB_DESKTOP_COMPLETION_MASTER.md`
**Backend authority:** Flow 2 canonical backend (Supabase/Postgres/RPC), unmodified by Flow 3
**Production:** not touched at any point

This document is the required Master §32 "Vendor Behavioural Contract
Pack" plus a running execution record of what was found and fixed. It
supersedes any earlier in-session assumption that has since been
corrected — most importantly the assumption, stated at an earlier
checkpoint, that the entire legacy "Milestone 3/4/6" apparatus in
`vendor/index.html` was dead code. It was not: see §7 below.

---

## 1. Active Vendor information architecture

The live app is driven by `isVendorProposed(){ return true; }` — every
"...Proposed" page variant is what a real Vendor sees; the classic,
non-Proposed sibling bodies below them are legacy and unreachable.

**Bottom navigation** (mobile-width chrome, 4 fixed slots): Home
(Dashboard) · Orders · + Add Order (FAB) · Riders · Settings.

**Dashboard** (`pageDashboardProposed`): live KPI strip (orders/riders/
issues/completed %, all real, zero is a valid value), Current Deliveries
(from `getCurrentDeliveries()`, real), a Workload/Live-Session card (real
Operations/Helper work-session data where configured), Action Required
(real conditional alerts only — no fabricated fallback).

**Settings** (`pageSettingsProposed`): Business Profile, Team, Zones,
Active Runs, Need Attention, Change Password, Reports, Subscription
(HOLD), Help & Support, Privacy & Terms, About.

**Orders**: list (ongoing/issue/completed tabs, search), Order Detail,
New Order wizard, CSV/XLSX bulk import.

**Zones**: list + Service Area (coverage config), Zone Detail (rename,
enable/disable).

**Planning/Dispatch**: Suggested Runs (deterministic proposal) → Run
Builder (review/adjust/confirm) → dispatch.

**Active Runs / Run Detail**: list of in-progress (session, Rider) runs;
detail shows stops, real Rider location (if ever reported), open issues,
activity timeline.

**Need Attention**: aggregated real exceptions (unplannable orders, open
issues, offline Riders).

**Riders / Team**: Rider list/detail/invite/approve/deactivate; Team
list/invite/manage/revoke.

**Account**: Business Profile, Language, Change Password, Appearance
(dark/light), Notifications toggle (local preference).

---

## 2. Canonical API/RPC map per feature

| Feature | RPC(s) | Vendor wrapper |
|---|---|---|
| Order create | `create_delivery` | `createDelivery` |
| Order approve | `approve_order` | `approveOrder` |
| Order edit | `update_order_details` | `updateOrderDetails` |
| Bulk import | `import_orders_batch` | `importOrdersBatch` |
| Location resolve | Edge Function `geocode-order`, `set_order_location_manual` | `geocodeOrder`, `setOrderLocationManual` |
| Coverage | `is_within_coverage`, `order_coverage_status`, `set_business_service_area` | `orderCoverageStatus`, `setBusinessServiceArea` |
| Zone CRUD | `create_zone`, `rename_zone`, `set_zone_status` | `createZone`, `renameZone`, `setZoneStatus` |
| Planning | `propose_delivery_plan`, `list_plannable_orders` | `proposeDeliveryPlan` |
| Dispatch | `build_rider_run`, `assign_rider`, `reassign_rider` | `buildRiderRun`, `assignRider`, `reassignRider` |
| Recovery | `initiate_delivery_recovery` (Vendor-only, 4-arg) | `initiateDeliveryRecovery` |
| Rider location | `latest_rider_locations` | `latestRiderLocations` (F3-06) |
| Issue report | `vendor_report_delivery_issue` | `reportDeliveryIssue` |
| Rider mgmt | `deactivate_rider`, `update_rider_details`, `create_rider_invitation`, `revoke_rider_invitation`, `approve_pending_rider` | matching wrappers |
| Team mgmt | `update_team_member`, `create_team_invitation`, `revoke_team_invitation` | matching wrappers |
| Business profile | `update_business_profile` | `updateBusinessProfile` (+ real hydration of phone/email/address/operatingArea, added F3-12) |
| Auth | Supabase Auth REST (`/auth/v1/*`) directly, not an RPC | Sprint 1.3 + Milestone 6 auth cluster (see §7) |

No RPC exists for: business logo storage, notification delivery/
preferences, Vendor-side run resequencing (see §6), Storefront/Order Page
theming.

---

## 3. Auth / session / business context

Real, live system — see §7 for the full reachability map. Summary: Sprint
1.3 (`submitProductionLogin`/`submitProductionSignup`/`submitPasswordReset`/
`submitNewPassword`, wired via real `onclick` handlers) plus Milestone 6's
auth/config plumbing (`authRequest`, `storeAuthSession`,
`restoreAuthSession`, `signUpWithPassword`, `refreshAuthSession`,
`productionSignOut`, `reauthenticateCurrentUser`,
`updateAuthenticatedPassword`) is the sole, real authentication system.
`initializeSprint13()` is the app's literal boot statement.

**Session-expiry handling**: real API failures (e.g. an expired token)
surface as an honest error toast via each action's own `catch` block —
never a fake success. There is no automatic redirect-to-login on a 401;
a Vendor must manually retry or reload. Safe (no fabrication), not
graceful — a real, disclosed UX gap for a future pass, not a security gap
(every mutation is independently re-authorized by the backend regardless
of client state).

---

## 4. Order states/actions

Canonical `delivery_status` enum: `created, ready_for_pickup, picked_up,
out_for_delivery, arrived, delivered, issue, cancelled`. UI mapping
(`statusToUi`): `readyForPickup, pickedUp, delivering (out_for_delivery/
arrived), completed (delivered), issue, cancelled`.

Actions available per state are backend-authoritative (approve → assign →
dispatch → Rider-driven transitions → Rider completes with POD). Vendor
never locally advances an order past what the backend confirms.
`confirmMarkDelivered` is deliberately absent/gated off — Vendor must
never impersonate the Rider or fabricate delivery completion.

## 5. Location/coverage states

`orders.location_status`: `unresolved, resolved, ambiguous, failed`.
Coverage: `is_within_coverage`/`order_coverage_status` return
`unconfigured | pending_location | covered | out_of_coverage`
(order-scoped) or boolean/null (point-scoped). Out-of-coverage orders stay
in Needs Review; coverage is never silently enlarged or bypassed.

## 6. Zone states/actions

`zones.status`: `active | inactive`. Create/rename/enable-disable all
real (F3-04, this session), gated by `is_business_member` (any active
Owner/Operator/Helper — matching `create_zone`'s own precedent, not
Owner/Operator-only).

## 7. Planning/review/dispatch flow

**Confirmed real** (earlier-session claim of "local-only" was stale):
Suggested Runs (`propose_delivery_plan`, a deterministic optimizer,
explicitly not "AI route optimization") generates grouped proposals →
"Build This Run" pre-fills the real Run Builder sheet → `confirmRunBuilder`
calls `build_rider_run` with a real idempotency key → dispatch. Manual
adjustments in Run Builder are revalidated server-side on confirm.

**Founder-confirmed design boundary (not a gap):** Vendor plans, builds,
and dispatches a run; **stop/order resequencing after dispatch is
Rider-owned by design.** `save_run_sequence` gates on
`is_current_rider(p_rider_id)` — a Vendor caller can never pass this
check, and `build_rider_run` itself never sets `delivery_stops.sequence`
at all. This was investigated this session by reading the actual RPC body,
not assumed. The Founder has explicitly ruled: **do not widen this
authorization boundary; do not add a Vendor mutation path for
`save_run_sequence`.** Master §15's "reorder stops" wording under Planning
is reconciled here as pre-dispatch order/rider/wave adjustment only (which
Run Builder already supports), not post-dispatch resequencing. **Flow 4
must not build a Vendor-side resequencing feature** — this is intentional
product/security design, not an implementation defect.

## 8. Run/stops/events model

A "Run" = one Rider's `rider_assignments` set within one
`delivery_session` (Wave) — `computeRunProgress()`'s existing grouping,
first given a real UI consumer this session (F3-06, Active Runs/Run
Detail). Real stops (ordered, real status), real open issues, real
activity timeline (from `delivery_events`, includes recovery events).
**No customer-safe ETA is shown** — `compute_order_eta` was correctly
hardened to internal-only in Flow 2's F2-11 (no tenant check existed); no
other canonical Vendor-facing ETA source exists. **Real Rider location**
via `latest_rider_locations` (F2-08), fetched lazily on Run Detail open; a
missing row means no Rider client has ever reported one yet (Rider
Flutter background GPS is Flow 5) — never fabricated.

## 9. Rider/invitation/capacity model

Real invitation lifecycle (`create_rider_invitation` →
`resolve_rider_invitation` → `approve_pending_rider`/reject via
`deactivate_rider`, `revoke_rider_invitation`). Real vehicle type
(motorcycle/car/van) and `max_active_orders` override
(`update_rider_details`). Riders have **no real zone-assignment concept**
in this schema — a `mapRider().zone` field existed only as a hardcoded
`'Unassigned'` placeholder and was displayed as if real in four places;
fixed this session (F3-12) by removing the fabricated display, not by
inventing a real zone concept that doesn't exist.

## 10. Team/permission model

`is_business_member` (any active Owner/Operator/Helper) vs.
`is_business_operational` (Owner/Operator only — dispatch-authority
actions). Team and Riders are deliberately separate models (confirmed no
"Workforce" duplicate screen exists — a stale earlier-audit claim,
re-verified false this session). Every action independently re-checked by
the backend regardless of client-side role gating.

## 11. Need Attention/recovery model

`pageNeedAttention` (built from scratch, F3-09) aggregates three real
sources — Flow 2's own `propose_delivery_plan` exception classification
(`unplannable_orders`), real open issues, real offline Riders — no local
exception array is ever synthesized. "Stuck/abnormal run" detection is
honestly absent: no canonical backend signal exists for it, and inventing
a client-side staleness threshold would itself be exactly the kind of
business-logic duplication Master §3 forbids.

Recovery (`initiate_delivery_recovery`) is **Vendor-authorized only** — a
prior-session narrowing, reconfirmed and not touched this Flow. Rider's
channel is `rider_report_delivery_issue` ("report an issue"), never
self-service ownership release.

## 12. Storefront/Business Profile responsibilities

**No Storefront/Order Page theming feature exists anywhere in this
codebase** — confirmed via a full repo search this session; it is
aspirational product-doc scope (`docs/cefflo/06_VENDOR.md` V-07), not
built. Business Profile itself is real (`update_business_profile`, with
real hydration of phone/email/address/operatingArea added this session —
previously blank on a Vendor's first visit before their first save).
**Business Logo upload is device-local-only** — no backend field/storage
exists for it at all; honestly disclosed via a persistent caption
(F3-12/F3-10) rather than claiming a shared, persisted asset. Real
server-backed logo storage (a storage bucket + RLS + a schema field) is a
scoped, genuine future addition, not built here.

## 13. Account/settings/language/theme behaviour

Language: real, immediate, per-user, `localStorage`-persisted (`en-MY,
ms-MY, zh-Hans-MY, ta-MY`). Appearance (dark/light): real, device-local,
honestly disclosed via its own storage-key naming. Notifications toggle:
was a live control with zero effect anywhere, silently resetting every
reload — fixed this session (F3-11) to genuinely persist to
`localStorage`, since no notification-delivery backend exists to wire it
to for real. Change Password: real (Supabase Auth reauth+update) but was
**dead-unreachable** — no live nav trigger reached it; fixed this session
by adding a real Settings-menu entry.

## 14. Loading/error/empty patterns

Established, consistent convention this session: every new/fixed screen
shows a real loading state while a fetch is in flight, an honest empty
state naming the real reason nothing is there (never silently blank), and
routes every failure through a `catch` that shows an error toast — never
a fake success shown before or without a resolved RPC.

## 15. Canonical status-label mapping

`statusToUi` (delivery_status → UI label), `statusChip()` (status → chip
class + text, always paired, never color-only).

## 16. Responsive/experience-system decisions

**Known, disclosed gap, not fixed this Flow:** this app has no genuine
desktop-optimized layout. `.app-device` simply centers a fixed
max-width-760px mobile column with a border on wider viewports — no split
list/detail view, no wider tables, no desktop information density
anywhere. Master §23 asks for real desktop optimization; Master §7
explicitly warns against "a ground-up visual rewrite" / "unnecessary
wholesale redesign." Building genuine multi-column desktop layouts across
this entire app is that scale of work — a deliberate future initiative,
not attempted here. What *was* fixed this session (F3-13): the shared
`innerHeader()` back/action buttons (used on every screen) had no
accessible name at all; fixed once, benefiting every screen. Keyboard
`:focus-visible` was already correctly implemented globally (a genuine,
pre-existing accessibility feature, not something this pass added).

## 17. Features explicitly HOLD/POST-V1

- Vendor→Cefflo subscription/payment — HOLD per Master §4/§21, untouched.
- Storefront/Order Page theming — does not exist; not built this Flow.
- Notification delivery/preferences backend — does not exist; the
  granular per-category settings page (dead-unreachable, would-be-fake)
  was removed rather than left as fabricated-but-unreachable scaffolding.
- Server-backed Business Logo storage — real future addition, not built.
- Vendor-side manual run resequencing — intentionally out of scope, see §7.

## 18. Known backend limitations Flutter must not "solve" locally

- **Resequencing is Rider-owned** (§7) — do not build a Vendor Flutter
  bypass for this; it is a security/product boundary, not a gap.
- **No canonical Vendor-facing ETA source** — `compute_order_eta` is
  internal-only (F2-11 hardening); do not compute a local estimate.
- **No notification-delivery backend** — do not build a Vendor Flutter
  notification-preferences screen that has nothing real to control.
- **Riders have no real zone-assignment concept** — do not display or
  invent one.
- **Mapbox Gate A** (from Flow 2) remains blocked on a genuinely-missing
  credential in every environment checked so far — carried forward as an
  external dependency, not a Flow 3/4 implementation gap.

---

## F3 Workstream Status (Master §33.C format)

| Workstream | Status | Notes |
|---|---|---|
| F3-00 Baseline + Contract Reconciliation | **PASS** | Corrected 3 stale Master/prior-audit assumptions this session (Zone→Rider quick-assign is real; no Workforce duplicate; Planning is genuinely wired) |
| F3-01 App Shell/Auth/Hydration | **PASS** | Real, live (§3, §7); session-expiry handling safe-not-graceful, disclosed |
| F3-02 Today Dashboard | **PASS** | Fabricated KPI padding/fallbacks removed |
| F3-03 Orders/Order Detail/Intake | **PASS** | Bulk import already canonical; 2 minor honesty fixes (zone-required mismatch, Recent Imports) |
| F3-04 Zones + Service Area | **PASS** | Rename/enable-disable wired to real, previously-unused RPCs |
| F3-05 Planning/Review & Dispatch | **PASS** | Re-verified real; no changes needed |
| F3-06 Active Runs/Run Detail | **PASS** | Built from scratch this Flow |
| F3-07 Riders/Workforce/Invitation | **PASS** | Undefined-field bugs fixed; zone-fabrication removed |
| F3-08 Team/Permissions | **PASS** | Full re-audit, no defects found |
| F3-09 Need Attention + Recovery UX | **PASS** | Built from scratch this Flow |
| F3-10 Storefront/Appearance/Business Profile | **PASS** | No Storefront feature exists (nothing to build); Logo honestly disclosed |
| F3-11 Account/Settings/Support | **PASS** | Change Password reachable; dead notification page removed; toggle persisted |
| F3-12 Truthfulness/Legacy/Mock Cleanup | **PASS** | Legacy Milestone 3/4/6 apparatus resolved (§7); ~10 distinct fabrication/undefined-field bugs found and fixed across the session |
| F3-13 Responsive/Accessibility | **PARTIAL** | Shared-header accessibility fixed; genuine desktop layout is a disclosed, deliberate non-goal this pass (see §16) |
| F3-14 E2E/Security | **PARTIAL** | Full backend/RPC-level regression + cross-tenant security suite passes (65/66, 6 pre-existing unrelated failures); interactive click-through E2E and session/network-resilience scenarios NOT verified — no browser-automation tool available in this environment |
| F3-15 Contract Pack | **PASS** | This document |

## Tests / Regressions

Full local suite (against local disposable Supabase, never staging/
Production): **65/66 non-frontend-static tests pass.** The 6 failures are
the same pre-existing, unrelated frontend static-test failures documented
since the Flow 2 closure report — unchanged in count, one fewer than the
original 7 (one was fixed as a byproduct of this session's F3-06 Run
Builder work). New test files added this Flow: `f3_04_zone_edit_wiring.py`,
`f3_06_active_runs_wiring.py`, `f3_02_dashboard_truthfulness.py`,
`f3_07_rider_profile_truthfulness.py`, `f3_09_need_attention_wiring.py`,
`f3_10_11_truthfulness_and_zone_fabrication.py`,
`f3_12_undefined_field_sweep.py`,
`f3_12_legacy_milestone_apparatus_removal.py`,
`f3_13_accessibility_shared_header.py`. All new backend RPC surfaces
consumed this Flow (`rename_zone`, `set_zone_status`,
`latest_rider_locations`) already had real cross-tenant DB-level denial
tests from their original Flow 2 batches (`s4_06_batch_3_zones.py`,
`f2_08_rider_location_backend.py`) — reconfirmed passing, not duplicated.

## Known limitations (no hidden failures)

1. No browser-automation tool in this environment — interactive E2E,
   screenshots, and real session/network-resilience testing were not
   possible; static source analysis and real backend test execution are
   the evidence basis throughout.
2. No genuine desktop-optimized layout exists (§16) — a deliberate,
   disclosed non-goal for this pass given Master's own anti-redesign
   guardrail.
3. Session expiry is safe but not graceful (§3) — no auto-redirect.
4. Mapbox Gate A (Flow 2, carried forward) remains blocked on a missing
   credential.
5. Vercel preview builds for arbitrary branches fail on a missing
   `CEFFLO_ENVIRONMENT` project setting (fail-closed by design) — no
   dashboard access to fix; not weakened.

## P0/P1 blockers

None identified. No Founder Gate was triggered during this execution
(Gate A missing-dependency, Gate B product conflict, Gate C subscription,
Gate D destructive schema change, Gate E new paid provider, Gate F
Production — none applied).

## Recommendation

Flow 4 (Vendor Flutter) may begin. This document, §§1–18, is the stable
behavioural contract to build against. The single most important thing
for Flow 4 to internalize before starting is §7/§18's Rider-owned-
resequencing boundary and §18's other "do not solve locally" list — every
one of them was reached by reading the actual backend/frontend code, not
assumed, and each carries the specific evidence trail in this session's
commit history on `claude/flow-3-vendor-web-desktop-completion`.
