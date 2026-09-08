# Vendor Mobile — Flutter + canonical backend integration (execution evidence)

Status: **PARTIAL**. Foundation, typed navigation, audit fixes, and a real
backend-wired operational slice — now including coverage, planning, dispatch
and service area — are done. Most inventory routes are not
migrated yet and several capabilities are BLOCKED on inputs that do not exist
in this repository or environment.

Production touched: **NO**.

## Baseline

| Item | Value |
|---|---|
| Base branch | `claude/flow-3-vendor-web-desktop-completion` |
| Base SHA | `2e51dca` |
| Work branch | `claude/vendor-mobile-backend-integration` |
| App path | `apps/vendor_mobile/` |
| Backend | Supabase project `tomvvmwktehexwhktenw` (**cefflo-staging**) |
| Production project | `lmaxtrubwdniovxyuqdy` (cefflo-platform) — never contacted |

### Why this base

| Branch | Migrations | SOT docs | Ahead of main |
|---|---:|---:|---:|
| `main` (`15a551b`) | 1 | 0 | — |
| `staging` (`72b31b0`) | 34 | 0 | 75 |
| `claude/flow-3-...` (`2e51dca`) | **51** | **19** | **112** |

`codex/cefflo-vendor-flutter-prototype` (`4b4ca8a`) shares **no common
ancestor** with the canonical line (`git merge-base` is empty; 37 files, orphan
root). It was therefore not merged. The Flutter client was rebuilt inside the
canonical repository instead, as the master requires ("do not blindly merge
unrelated branches or flatten histories").

## Backend reality (measured, not assumed)

`docs/cefflo/04_CURRENT_STATE.md` still describes Phase 1 and states Stage 4
has not started. That is **stale**: the repository contains 51 migrations and
115 RPC definitions, and staging has 29 RLS-enabled tables and 93 functions.

**Deployment drift — RESOLVED on 7 September.** Staging was 17 migrations
behind the repository. All 17 have now been applied in canonical order and the
migration ledger was corrected to the repository's own version numbers, so
staging and `supabase/migrations` are byte-for-byte in step (51 = 51, latest
`202609040005`, no gaps, no reverse drift).

## What is really wired (live reads/writes)

| Area | Contract used | State |
|---|---|---|
| Sign in | Supabase email OTP | REAL |
| Business context | `get_my_businesses` | REAL |
| Orders list/detail | `orders` table via RLS | REAL |
| Create order | `create_delivery` | REAL |
| Edit order | `update_order_details` | REAL |
| Approve order | `approve_order` | REAL |
| Report issue | `vendor_report_delivery_issue` | REAL (not yet surfaced in UI) |
| Zones | `zones` table, `create_zone`, `set_zone_status` | REAL (read wired; create/status in repository only) |
| Riders | `riders` table | REAL (read) |
| Team | `business_members` table | REAL (read) |
| Products | `products` table, `create_product`, `update_product` | REAL (read wired) |
| Service area | `set_business_service_area` + `businesses` read | REAL |
| Order coverage verdict | `order_coverage_status`, `is_within_coverage` | REAL |
| Plannable order set | `list_plannable_orders` | REAL |
| Plan proposal (grouping, rider candidate, sequence) | `propose_delivery_plan` | REAL |
| Capacity/vehicle pre-check | `check_run_vehicle_capacity` | REAL |
| Dispatch | `create_delivery_session` + `build_rider_run` | REAL |
| Customer-facing ETA | `compute_order_eta` | **BY DESIGN NOT CLIENT-CALLABLE** — `f2_11` revoked it from `anon` and `authenticated`; it is an internal helper for token-gated `public_tracking`. The Vendor client does not call it. |
| Product photography | — | **BLOCKED — no approved background-removal provider** |
| Apple / Google sign-in | — | **BLOCKED — no OAuth provider configured** |
| Customer storefront + intake | `public_order_catalog`, `submit_public_order` deployed | **NOT STARTED** |
| Rider/helper applications | `create_rider_invitation` deployed | **NOT STARTED** (repository method only) |
| Subscription V-50–54 | — | **NOT MIGRATED** |

No client-side computation of coverage, eligibility, capacity, planning or ETA
exists in this codebase; those remain server-owned.

## Mandatory audit fixes

| # | Fix | State | Evidence |
|---|---|---|---|
| 1 | Back returns parent, correct active tab | DONE | `core/routes.dart` parent/tab graph; `test/routing_test.dart` |
| 2 | Details bound to the selected id | DONE | `VendorLocation.entityId`, `requiresEntityId`; tests |
| 3 | Order detail restored; no planning CTA when completed; Save persists | DONE | `VendorOrder.canPlan/canEdit/canApprove`; `OrderFormScreen._save` calls the RPC and only navigates on success |
| 4 | KPI and list counts from one scoped read; canonical statuses preserved | DONE | `OrderTab` mapping; `DeliveryStatus.wire` asserted against the DB enum |
| 5 | Settings/profile Save updates real data | PARTIAL | order create/edit persist; business/profile/hours forms not migrated |
| 6 | Bell opens notification inbox | PARTIAL | route + entry point exist; inbox content not built |
| 7 | No toast-only actionable buttons | DONE | unavailable capabilities render `StateBlock.blocked`, not fake success |
| 8 | Legal placeholders / real About build data | NOT DONE | routes not migrated |

## Tests actually run

| Suite | Result |
|---|---|
| `flutter analyze` | **PASS**, no issues |
| `test/routing_test.dart` (12 tests) | **PASS** |
| `test/staging_contract_test.dart` (11 live tests, staging) | **PASS** |

The live suite proves, against the real staging project: every one of the eight
previously-missing coverage/planning/dispatch contracts is now deployed and
answers with its own tenant rules rather than "missing contract"; RLS still
denies unauthenticated order reads; `get_my_businesses` is now correctly
*denied* to anonymous callers after the grant hardening; and the previously
working contracts (`approve_order`, `create_zone`, `update_order_details`)
still respond — no regression.

Not run: widget/integration coverage of individual screens, dark-mode and
enlarged-text passes over the route matrix, authenticated end-to-end flows
(no test identity exists on staging), 60-route visual evidence.

## Preview

<https://cefflo-vendor-mobile-staging.netlify.app> — built from this branch with
`--dart-define` staging configuration. No key is committed; `lib/core/env.dart`
reads configuration at build time and the app refuses to start unless
`CEFFLO_ENVIRONMENT` is `staging` or `local`.

## Reference package gap

The master cites `docs/cefflo/reference/vendor-prototype-20260906/`
(`index.html`, `style.css`, `app.js`, `experience.css`, `experience.js`,
`assets/`). That path does not exist on any branch, and the supplied ZIP is the
earlier pack (`index.html`, `style.css`, `app.js` only). Rider and product
photography, the login composition and the customer storefront layout could not
be reproduced from source. The preview URL is owner-private (HTTP 401 for this
agent).

No brand mark is referenced, bundled or implied by this work. The Founder has
confirmed there is no approved Cefflo logo asset in scope here; the Flutter
client ships Flutter's default placeholder icons and a plain text wordmark
until an approved asset is supplied.

## Canonical-doc conflict recorded

`docs/cefflo/sot/09_VENDOR_FLUTTER_60_SCREEN_MASTER.md` describes Vendor Flutter
as FUTURE, "not blanket implementation authorization", and holds V-41 and
V-50–V-54. The 6 September master supersedes both points (it authorizes
non-production implementation and reopens V-50–54 as UI). This task followed the
newer master and records the conflict here rather than silently rewriting the
SOT.

## Staging migration run — 7 September

All 17 repository migrations that staging was missing were applied in canonical
order via the Supabase MCP. Pre-flight audit found no destructive DDL (the only
`drop`/`delete` statements operate on a session-local temp table inside
`propose_delivery_plan`), no `NOT NULL` column added without a default, and no
reverse drift.

| # | Migration | Introduces / changes |
|---:|---|---|
| 1 | `202609030001_s4_11_batch_1_geocoding` | `order_location_status` enum, `orders` location columns, `set_order_location*` |
| 2 | `202609030002_s4_11_batch_2_coverage_zones` | **`set_business_service_area`**, **`order_coverage_status`**, **`list_plannable_orders`**, `haversine_km`, `businesses` service-area columns |
| 3 | `202609030003_s4_11_batch_3_vehicle_capacity_compatibility` | vehicle/capacity model; drops+recreates `create_delivery`, `update_order_details`, `update_rider_details`, `build_rider_run` |
| 4 | `202609030004_s4_11_batch_4_optimization_engine` | **`propose_delivery_plan`**, `sequence_group_nearest_neighbor` |
| 5 | `202609030005_s4_11_batch_5_csv_xlsx_canonical_commit` | `import_orders_batch` |
| 6 | `202609030006_s4_11_batch_6_operations_helper` | `helper` member role, `preparation_status` |
| 7 | `202609030007_s4_11_batch_7_operations_helper_rpcs` | `is_business_operational`, `advance_preparation`; narrows `assign_rider`/`approve_order`/`build_rider_run` |
| 8 | `202609030008_s4_11_batch_8_truthful_eta` | **`compute_order_eta`**, `public_tracking` uses it |
| 9 | `202609030009_s4_11_batch_9_recovery_reschedule` | `initiate_delivery_recovery` |
| 10 | `202609030010_s4_11_batch_10_helper_permission_audit` | narrows 15 RPCs to `is_business_operational` (incl. **`set_business_service_area`**) |
| 11 | `202609030011_s4_11_batch_11_recovery_created_state_fix` | recovery from `created` |
| 12 | `202609030012_s4_11_batch_12_geocode_on_address_change` | address change invalidates resolved location |
| 13 | `202609040001_f2_13_max_active_orders_rename` | `capacity_override` → `max_active_orders` |
| 14 | `202609040002_f2_08_rider_location_backend` | `record_rider_location`, `latest_rider_locations`, **RLS tightening** (below) |
| 15 | `202609040003_f2_02_is_within_coverage` | **`is_within_coverage`**, unified coverage boundary |
| 16 | `202609040004_f2_11_rpc_grant_hardening` | grant hardening; **revokes `compute_order_eta` from clients** |
| 17 | `202609040005_f2_09_recovery_vendor_only` | recovery becomes vendor-only |

### Security-relevant changes included — flagged for Founder awareness

These are tightenings, not relaxations, and are canonical repository content:

1. **RLS policy replaced** (`f2_08`): `locations_rider` INSERT on
   `rider_locations` now also requires `business_id` to match the rider's own
   business, closing a cross-tenant spoofing hole. `rider_locations` had 0 rows.
2. **Permission narrowing** (`batch_7`, `batch_10`): ~18 vendor RPCs moved from
   `is_business_member` to `is_business_operational`, so the new `helper` role
   cannot approve, assign, dispatch or configure.
3. **Grant hardening** (`f2_11`): `anon` execute revoked from a set of sensitive
   RPCs, and `compute_order_eta` revoked from clients entirely.

Behavioural consequence observed in test: an anonymous caller now receives
`permission denied for function get_my_businesses` instead of an empty list.
The app only calls it post-authentication, so no user-facing behaviour changed.

### Post-apply verification

| Check | Result |
|---|---|
| All 6 target RPCs exist with expected signatures | PASS |
| Grants: 5 executable by `authenticated`, none by `anon` | PASS |
| `compute_order_eta` executable by neither (by design) | PASS |
| Duplicate function overloads | **none** |
| Public functions | 93 → 114 |
| Migration ledger vs repository | 51 = 51, latest `202609040005`, no gaps |
| Row counts (orders / riders / businesses) | 1 / 1 / 1, unchanged |
| RLS-enabled tables | 29, unchanged |

The MCP recorded its own timestamp versions on apply; the ledger was then
corrected to the repository's canonical version numbers so a future
`supabase db push` will not attempt to re-apply them.

## Remaining implementation scope

1. Provide the 20260906 reference package with its assets (rider/product
   photography) — visual-system completion is deliberately out of this pass.
2. Decide and authorize a background-removal provider for product media.
3. Create a staging test identity so authenticated end-to-end flows
   (sign-in → plan → dispatch → delivery) can be exercised and evidenced.
4. Configure OAuth providers if Apple/Google sign-in is required.
5. Not yet migrated: customer storefront and intake, rider/helper application
   flows, product media UI, subscription V-50–54, notification inbox content,
   legal/About routes, and the remaining inventory screens listed as
   `NotMigratedScreen`.
