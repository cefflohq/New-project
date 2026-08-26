# CEFFLO --- QA & RELEASE

## Q-00 Principle

A Stage 4 release is a system gate, not a visual sign-off.

## Q-01 Test Layers

-   targeted component/feature;
-   integration;
-   backend/RLS/negative;
-   cross-app lifecycle;
-   E2E;
-   PWA/browser/mobile;
-   production smoke;
-   health/rollback.

## Q-02 Core E2E

At minimum validate the approved journey: Vendor order/operation → rider
assignment → pickup/in-transit/stops → delivery/POD → customer tracking
→ rating where applicable.

## Q-03 Exception Matrix

Test relevant: - unauthorized/cross-business access; - invalid/expired
tracking token; - invalid lifecycle transition; - customer
unreachable; - wrong address; - condo/access; - vendor not ready; -
rider/assignment issue; - POD upload/display failure; - offline/network
failure; - stale PWA/client version.

## Q-04 UI Launch Review

Before Vendor/Rider final: 1. exception states; 2. urgent action
hierarchy; 3. lifecycle/status consistency.

## Q-05 Release Candidate

RC requires known commit, known environment, clean diff/state, test
evidence, migration/deployment plan, rollback plan and known blockers.

## Q-06 Production Deployment

Prefer low-activity period. Apply backward-compatible sequencing.
Protected production actions require Founder approval.

## Q-07 Smoke

After deploy verify domains, auth, key routes, backend connectivity,
tracking, critical mutations, POD and FOUNDR health as applicable.

## Q-08 Monitoring

Confirm ability to observe critical failures after release. Classify
analytics/error monitoring as implemented/future/decision-required
during Phase 1/6.

## Q-09 Rollback

Frontend rollback alone may not be safe after incompatible backend
change. Verify rollback as a complete release sequence.

## Q-10 Go-Live Gate

Stage 4 GO-LIVE only after required gates pass and Founder approves.
Never hide failed/unrun checks.
