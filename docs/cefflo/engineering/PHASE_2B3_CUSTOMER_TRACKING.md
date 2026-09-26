# Phase 2B.3 — Customer Tracking

Status: COMPLETE (D-65). Staging only (`tomvvmwktehexwhktenw`). Production untouched.
No schema, RPC, policy or migration change.

## Contract
`public_tracking(p_token)` → `order_number, order_id (public_ref), store_name, status,
eta, rider_name, completed_at, pod_available, rating_submitted`; POD image via the
existing `tracking-pod` edge function (token → short-lived signed URL). Refresh on open,
focus/return and bfcache restore (existing on-demand policy).

## Staging E2E (order #CF-001 / CF-EEC22B74, Business A, TEST-ONLY Driver)
Vendor `create_delivery` → `approve_order` → `create_delivery_session` → `build_rider_run`;
Driver executed in the Driver Flutter staging build.

| Step | Backend | Customer |
|---|---|---|
| A. dispatched, not accepted | created | No order yet |
| A2. Driver Accept Run | created | No order yet |
| B. Driver Confirm Pickup | picked_up | Pickup, Tracking ID #CF-001 |
| C. route + Slide to Arrive | arrived | On the Way, rider "TEST-ONLY Driver" |
| D. POD + complete | delivered | Delivered, Delivered At, POD thumbnail |
| E. reload | delivered | Delivered (unchanged) |

Cross-surface, same order: Vendor Web `#CF-001` Completed (delivered), Vendor Mobile
Delivered tab `#CF-001`, Driver Stop List `#CF-001`, Customer `#CF-001` Delivered.
Issue (#CF-003, `vendor_report_delivery_issue`) → "Delivery on hold"; cancelled
(#CF-002, `decline_order`) → "Order cancelled"; invalid token → "Tracking unavailable".

## Security
`public_tracking` with `#CF-001`, the public_ref, or the order UUID → null. Another order's
token returns only that order. Anonymous REST on orders, tracking_tokens,
delivery_stops, rider_locations, riders → `[]`; anonymous POD sign → 400; Vendor B
cannot read the order. Snapshot carries no UUID, phone, address or storage path.

## Tests
`tests/test_customer_tracking_live.py` (7 cases, real ES modules in Node): pre-activation,
activation/progress, #CF from snapshot, no fixture leakage, POD/time only when real,
issue/cancelled/invalid, token-only access. Static suite 56/56 OK.

## Limitations
- No customer-visible rider location: the Driver app does not yet write
  `record_rider_location`, and `public_tracking` exposes no coordinates. No map is shown.
- ETA shows only when `compute_order_eta` returns a range (no geocoded orders on staging).
- Delivery address, items, pickup time, recipient are not in the contract → "—".
- `tracking-pod` CORS allowlist has `tracking.cefflo.com` and an old Vercel staging
  preview; there is no deployed staging customer origin, so the POD thumbnail was
  verified by relaying the real function response in the local harness.
- Rating "already rated" state is per-browser (existing adapter), not read from
  `rating_submitted`.
