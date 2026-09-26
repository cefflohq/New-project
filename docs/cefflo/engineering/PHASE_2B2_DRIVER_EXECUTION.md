# Phase 2B.2 — Driver Execution

Status: COMPLETE (D-63). Staging only (`tomvvmwktehexwhktenw`). Production untouched.

## Scope
Driver Flutter (`apps/rider_mobile`) wired to the canonical lifecycle on the run
Vendor creates with `build_rider_run` (Phase 2B.1). No new RPC, table or migration.
Only added dependency: `image_picker` (POD photo).

| Driver action | Canonical contract |
|---|---|
| Accept Run | `accept_run` |
| Confirm Pickup | `start_pickup_run`, `rider_transition` → `ready_for_pickup` → `picked_up` |
| Slide to start route | `save_run_sequence`, `start_run_delivery` |
| Slide to Arrive | `rider_transition` → `out_for_delivery` → `arrived` |
| Confirm Delivery | POD upload `cefflo-pod/<riderId>/<orderId>/…`, `complete_delivery` |
| Report Issue | `rider_report_delivery_issue` |

## Staging evidence
- **Happy path** — order CF-5EA13EA1, run 0e5ea9ca (multi-business Driver, Business A):
  every call 200; order `delivered`, `completed_at` and `pod_storage_path` set,
  events `status_changed`, `run.sequence_saved`, `run.sequence_locked`, `delivery.completed`.
- **Reload restore** — Today shows the Completed run, 1 completed; History lists Delivered (1).
- **Vendor consistency** — Vendor Mobile shows Delivered; Vendor Web shows Completed with all
  Delivery Progress steps checked.
- **Issue path** — CF-8824D355: accept → pickup → route → arrive → "Customer not available";
  Vendor sees status `issue`, event `delivery.issue_reported`, reason `customer_unreachable`.
- **Isolation 26/26** — other Drivers (none/pending/other) and Vendor B cannot read the order,
  assignment, stops or events, sign the POD, or call `complete_delivery`.
- **Static** — `flutter analyze` clean; rider tests 12/12 (new `test/driver_execution_test.dart`).
  Staging and prototype builds secret-scan clean; prototype still opens the Driver auth screen.

## Limitations / backlog
- Multi-business Driver: no selection UI; oldest active relationship is used.
- Assignment stays `accepted` after the last stop (Vendor rider chip shows Accepted).
- Reschedule / Other issue reasons have no canonical value and are refused.
- Distance / ETA show "—" (no geocoding; `geocode-order` not deployed on staging).
- Pending Review "Submitted" ticks are presentation-only.
- Carried: Driver sign-up / recovery hit the staging email rate limit (429).
- Out of scope finding: Vendor Web "+" FAB still purple.
