# CEFFLO --- RIDER PWA

> **Superseded (D-62, 2026-09-25).** The static Rider PWA (`rider/`) was
> removed from the active baseline. Canonical Driver UI is Flutter only:
> `apps/rider_mobile`. The sections below are historical behaviour notes. The
> backend contracts the static client called remain canonical for Driver
> execution (Phase 2B.2): `accept_assignment`, `decline_assignment`,
> `accept_run`, `decline_run`, `start_pickup_run`, `start_run_delivery`,
> `save_run_sequence`, `rider_transition`, `complete_delivery`,
> `rider_report_delivery_issue`, plus RLS-scoped reads of `riders`,
> `businesses`, `orders` and `delivery_sessions`, and POD upload through
> `shared/client.js` `uploadPod(riderId, orderId, file)`.

Historically this section described the LIVE Rider PWA. Future target direction
(NOT YET implemented, Founder review pending):
`docs/cefflo/sot/13_DRIVER_FLUTTER_42_SCREEN_MASTER.md` (active master as of
2026-09-14, D-37; supersedes `docs/cefflo/sot/08_RIDER_FLUTTER_33_SCREEN_MASTER.md`,
now historical).

**Terminology note — LOCKED (2026-09-12 freeze, locked 2026-09-14 per D-38):** "Cefflo Driver" is the locked user-facing product name for this surface's target-state Flutter app. The canonical role/schema/API name stays "Rider," unchanged and separately locked (`docs/cefflo/sot/01_PRODUCT_TRUTH.md` §4). This live PWA's own code/routes/schema are unaffected — "Rider" backend identifiers here are unchanged by the product-name lock.

## RI-00 Purpose

Rider PWA executes the vendor's delivery plan.

## RI-01 Strategy

Riders are primarily vendor-owned/trusted team members, not a Cefflo
marketplace supply pool.

## RI-02 Canonical Route

Planned: `rider.cefflo.com`. Verify current deployment/baseline in Phase
1.

## RI-03 Core Flow

-   authentication/team access;
-   assigned jobs;
-   pickup readiness;
-   pickup;
-   route/stops;
-   stop progress;
-   delivery status;
-   POD;
-   completion;
-   history/profile as approved.

## RI-04 Route Model

Support one rider with multiple drops/stops. Route UI must reflect
actual assignment order/zone logic rather than assume single-drop
on-demand delivery.

## RI-05 Status

Rider actions must use canonical transition rules from
`10_DELIVERY_LIFECYCLE.md`. UI must not invent independent status
meanings.

## RI-06 POD

POD capture/upload must use protected backend/storage contracts. Failure
needs explicit recoverable UX; do not silently mark inconsistent
completion.

## RI-07 Exceptions

Consider: - customer unreachable; - wrong address; -
condo/guard/access; - vendor/order not ready; - route/stop issue; - POD
upload failure; - GPS/location limitations where relevant; -
offline/network failure.

## RI-08 PWA vs Native

Stage 4 remains PWA-first. Future Flutter/native Rider app for deeper
GPS/camera/push/offline capabilities is later unless explicitly
approved.

## RI-09 UI

Mobile-first, high-action clarity, minimal distraction. Current job/next
action must be obvious.

## RI-10 Stage 4 Gate

Rider can securely receive valid assignments and complete approved
lifecycle/POD flows with relevant exception handling, consistent with
Vendor and Customer Tracking.
