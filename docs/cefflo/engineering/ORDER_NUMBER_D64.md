# D-64 — Human-facing order number `#CF-001`

Status: COMPLETE — verified on staging (`tomvvmwktehexwhktenw`). Production untouched.

## Backend
Migration `202609260001_order_number_daily_sequence.sql`:
- `orders.order_date date`, `orders.order_seq integer` (not null, > 0), unique
  `(business_id, order_date, order_seq)`; generated
  `order_number = '#CF-' || lpad(seq,3,'0')` (seq ≥ 1000 printed as is).
- `BEFORE INSERT` trigger `assign_order_number`: `order_date` = `created_at`
  in `businesses.timezone`; takes `pg_advisory_xact_lock(business, day)`, then
  `max(order_seq)+1`. Updates cannot change `order_date` / `order_seq`.
- Backfill: per business and business-local day of `created_at`, numbered by
  `(created_at, id)`. Staging: Business A 25 Sep → CF-8824D355 `#CF-001`,
  CF-5EA13EA1 `#CF-002`; Dapur Staging QA 30 Aug → CF-9029BD95 `#CF-001`.
- `public_tracking` and `list_plannable_orders` additively return `order_number`.

## Surfaces
Vendor Flutter (`cefOrderRef`), Driver Flutter (stop reference), Vendor Web
(`orderNo()` at display sites only; `o.id`/`backendId` unchanged), Customer
Tracking (`orderId` = `order_number`).

## Staging evidence (2026-09-26)
- New order via `create_delivery` (Vendor A): CF-EEC22B74 → `#CF-001`, date
  2026-09-26 — first of the new business day, while 25 Sep kept #CF-001/#CF-002.
- `public_tracking(token)` → `order_number #CF-001`; `public_tracking('#CF-001')`
  → null (number is not a key).
- Vendor Web orders: `#CF-001`, `#CF-002`. Vendor Mobile orders: `#CF-001`.
  Driver Stop List (CF-5EA13EA1): `#CF-002`.
- Customer Tracking page for the new order shows "Tracking not ready yet"
  (pre-pickup state has no reference row; existing behaviour).

## Tests
Vendor Flutter 107 pass (format cases 001…1000), Driver 12 pass, static 49 pass.
`tests/d64_order_number.py` — PASS on staging (single approved run,
2026-09-26): first daily #CF-001, increment, per-business independence,
MYT-midnight reset, #CF-999 → #CF-1000, immutability, and 12 simultaneous
committed inserts for one business/day received unique seq 1–12. Afterwards:
no D64 test businesses/orders remain, no duplicate
`(business_id, order_date, order_seq)`, existing 4 staging orders unchanged.

## Customer Tracking pre-pickup copy (micro-polish)
Pre-pickup state (`order_confirmed` / `preparing`) now shows "No order yet"
(light grey, `--ink-faint`) and "Tracking starts when your rider collects the
order.", with no warning glyph. Issue / cancelled / error states unchanged.
