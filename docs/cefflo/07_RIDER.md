# CEFFLO --- RIDER PWA

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
