# CEFFLO Backend Wiring — Phase 2B.1 Vendor Operational Core

**Date:** 2026-09-25

**Status:** COMPLETE (D-61). Orders → Zones → Runs → Rider Assignment run on
canonical staging state from Vendor Mobile, observed identically by Vendor
Web/Desktop. Environment note: the `geocode-order` Edge Function is not
deployed on staging (HTTP 404), so the qualification order's location was
resolved through the canonical `set_order_location_manual` RPC — the same
call Vendor Web's location correction makes.

## What became real in Vendor Mobile

| Area | Contract reused | Before |
|---|---|---|
| Order create | `create_delivery` (now reads the canonical `{order, tracking_token}` result; previously reported a false "not created") | PARTIAL |
| Order geocode request | `geocode-order` function, fire-and-forget, as Vendor Web | MISSING |
| Order approval | `approve_order` | MISSING in UI |
| Order zone | `update_order_details(p_zone_id)` | MISSING in UI |
| Approved label | `approved_at` (order stays `created` until pickup) | showed "Pending approval" |
| Zone rename | `rename_zone` | direct table update |
| Zone delete | `set_zone_status('inactive')` | direct table delete |
| Planning | `propose_delivery_plan` (proposal) kept separate from persisted runs | proposal only |
| Dispatch | `check_run_vehicle_capacity` → `create_delivery_session` (if no open session) → `build_rider_run` | MISSING in UI |
| Runs read | `rider_assignments` + `delivery_sessions` + `delivery_stops`, Vendor Web's embed | MISSING |
| V-19 Run detail | persisted run, linked from Zone detail | DEMO |

Prototype mode keeps its fixtures for reads; prototype writes, including
dispatch, fail truthfully instead of faking success.

## Staging E2E (Vendor A, TEST-ONLY data, 393×852)

1. Mobile created zone `TEST-ONLY P2B1-uvmoi Zone` (`create_zone`).
2. Mobile created order `CF-5EA13EA1` (`create_delivery`); Order detail shows
   "Pending approval", Zone "Not set", Approve Order.
3. Location resolved via `set_order_location_manual` (see environment note).
4. Mobile set the zone and approved the order; Order detail shows "Approved".
5. Zone detail showed the server proposal; Dispatch sheet → capacity check →
   Dispatch: `create_delivery_session` 200, `build_rider_run` 200.
6. Zone detail shows the rider as "Dispatched"; V-19 shows the real run
   (session, rider, 0 of 1 delivered, next stop).
7. After reload, the zone still shows the dispatched run.
8. Vendor Web/Desktop (signed in as Vendor A) lists `CF-5EA13EA1` and its detail
   shows the same rider, zone and coordinates.
9. Zone rename used `rename_zone`; Delete zone used `set_zone_status`; the row
   remains with status `inactive`.

Canonical-state and isolation contract: 26/26 PASS — order, zone, run,
session and rider are real Business A records and consistent; events
`delivery.created`, `order.approved`, `order.location_resolved`,
`order.zone_changed`, `rider.assigned`, `session.order_attached` recorded; the
assigned Driver can read its run and another Driver cannot; Vendor B reads of
Business A orders, zones, runs, sessions, stops and events are empty; Vendor B
`approve_order`, `update_order_details`, `rename_zone`, `set_zone_status`,
`reassign_rider`, `build_rider_run`, `propose_delivery_plan` and
`create_delivery_session` on Business A are all denied, and Business A state is
unchanged.

## Tests

- `flutter analyze`: PASS. Vendor tests: 107 PASS (adds
  `test/operational_core_test.dart`). Anonymous live staging contracts: 11/11.
- Prototype and staging release web builds: PASS; no secrets or Production ref.

## Staging data created (TEST-ONLY, retained)

Zones `TEST-ONLY P2B1-uvmoi Zone` (active) and an archived `…Archive…` zone;
orders `CF-5EA13EA1` (dispatched) and `CF-8824D355` (created before the
order-id fix, unassigned); one delivery session and one rider assignment.

## Remaining (Phase 2B backlog)

- Stop sequencing: `build_rider_run` leaves stops unsequenced (badge shows 0)
  until `save_run_sequence` is wired.
- Remove-from-today's-plan needs a canonical planning contract.
- Rider approve/deactivate UI; Mobile manual location correction.
- Deploy `geocode-order` to staging (infrastructure, not authorized here).
