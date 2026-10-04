# CEFFLO — Security Repo Inventory (Phase 1)

**Authority:** `docs/cefflo/security/CEFFLO_SECURITY_AND_ACCESS_MASTER_SPEC.md` §27 Phase 1
**Date:** 2026-10-04
**Baseline:** branch `official/staging` @ `6cd686b`; staging Supabase `tomvvmwktehexwhktenw`
**Method:** static read of the repo plus read-only queries against staging
(`default_transaction_read_only=on`). Nothing was changed.

## 1. Backend parity (staging)

| Check | Result |
|---|---|
| Migrations applied vs repo | 77 / 77, identical versions (latest `20260930162439`) |
| Client RPCs present on staging | All surfaces: none missing |
| Public tables | 39, all with RLS enabled |
| Public functions | 175, of which 164 `SECURITY DEFINER` (each needs §25 review) |
| Edge functions in repo | `geocode-order`, `tracking-pod` |

Storage buckets: `cefflo-avatars` private · `cefflo-pod` private ·
`cefflo-product-originals` private · `cefflo-product-display` PUBLIC ·
`cefflo-storefront-assets` PUBLIC.

## 2. Surfaces

| Surface | Code | Backend use | Gaps |
|---|---|---|---|
| Vendor App (Owner) | `apps/vendor_mobile` (Flutter) | 46 RPCs, direct reads on 16 tables; real path unless `CEFFLO_UI_PROTOTYPE` | Delivery Settings "Coming soon"; Google import not connected; no Remove member (`update_team_member`) or typed `CONFIRM` |
| Vendor Web | `apps/vendor_web` (served `/web/`) | 23 RPCs | No Team → Pending approval, no Remove member / `CONFIRM`; help articles and platform integrations not connected |
| Legacy Vendor Web | `vendor/` (served `/vendor/`) | 33 RPCs, 9,281 lines | Second code path for the same surface; retire |
| Driver App (Rider) | `apps/rider_mobile` (Flutter) | 18 RPCs (full run/delivery lifecycle) | Unverified end to end |
| Operator | `?access=operator` inside Vendor App and Vendor Web (`apps/vendor_web/js/access.js`) | Shared Vendor RPCs | Own entry/auth surface not built (Founder decision 2026-10-03: own entry, shared code) |
| Helper | `helper_workspace.dart` inside Vendor App | `my_fulfilment_tasks`, `advance_preparation`, `confirm_packing`, `confirm_sorting` | Dedicated Helper PWA not built |
| FOUNDR | `foundr/` | 22 admin RPCs, `is_platform_admin` / `platform_admin_status`; no mock path | Integrations/infra health, support tickets, marketing data, platform preferences not connected; Google sign-in placeholder; MFA foundation not enforced |
| Customer Tracking | `customer/` | `public_tracking`, `submit_rating`, `tracking-pod` | Staging E2E + SEC-TRACKING on hold |
| Invitation | `invite/` | `resolve_invite_link` | — |

## 3. Security controls observed (not yet test-verified)

| Control | Evidence | Status |
|---|---|---|
| Owner-only team approval | `decide_team_join_request` references owner check | Implemented, unverified |
| Owner-only member removal | `update_team_member` → `is_business_owner` | Implemented, unverified; no UI in new surfaces |
| Owner-only rider removal + active-work guard | `deactivate_rider` → `is_business_owner`, counts open assignments/orders/stops | Implemented, unverified |
| Business membership excludes Helper and non-active | `is_business_member`: role in (owner, operator) and status = active | Implemented, unverified |
| Helper read of private product originals (§18 finding) | `product_originals_vendor_read` uses `is_business_member` | Appears resolved; needs negative test |
| Membership statuses | `business_members.status` ∈ {active, inactive} | — |

## 4. Database/security test suite — RESOLVED 2026-10-04

The 40 "import errors" were the environment guard refusing to run without an
explicit, disposable target (by design). The suite now runs against a
disposable local Supabase (`npx supabase start`, all 77 migrations) via
`scripts/run-db-tests-local.sh`, which can only target loopback port 54322.

Result: **36 / 36 modules pass** (token lifecycle, RLS, rate limits, POD path,
tracking/rating limits, order approval, sessions/runs, zones, team and rider
invitations, multi-business rider context, delivery issues, catalogue,
public order page, storefront roles, RPC grant hardening).

Stale tests updated to the approved behaviour:
- `s4_07_batch_3_rider_invitation`: Operator approval of a rider is refused;
  Owner approves (Master §10, security batch 1).
- `s4_03_batch_1_contracts`: removing a rider with open work is refused until
  the work is closed (Master §16).
- `storefront_v1_roles`: parameter typing fix.
- `s4_10b_product_media_contract`: retired — it encoded the one-photo
  pipeline replaced by `20260930090556_product_media_multi` (Founder approval
  2026-10-01); the current contract is covered by `storefront_v1_roles`.

Not run (tools, not tests): `guarded_supabase_reset`, `check_target_identity`,
`validate_backend`. Not yet covered: an explicit negative test that a Helper
cannot read `cefflo-product-originals` objects (§18).

## 5. Agreed work order (Founder, 2026-10-04)

1. ~~Fix the test harness so security suites run.~~ Done 2026-10-04.
2. Vendor App: Remove member + typed `CONFIRM`; decide Delivery Settings.
3. Vendor Web: Team → Pending and Remove member parity; retire `/vendor/`.
4. Operator: own entry/auth on shared code.
5. Helper PWA.
6. Driver App end-to-end verification.
7. FOUNDR: decide unconnected sections; enforce MFA.
8. Security evidence pack + full staging E2E (incl. Customer Tracking).
