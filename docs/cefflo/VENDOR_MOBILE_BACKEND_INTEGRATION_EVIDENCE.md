# Vendor Mobile — Flutter + canonical backend integration (execution evidence)

Status: **PARTIAL**. Foundation, typed navigation, audit fixes and a real
backend-wired operational slice are done. Most inventory routes are not
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

**Deployment drift — repository vs staging.** These canonical RPCs exist in
`supabase/migrations` but are **not deployed** to staging:

- `propose_delivery_plan`
- `list_plannable_orders`
- `order_coverage_status`
- `is_within_coverage`
- `compute_order_eta`
- `set_business_service_area`

Consequence: planning, dispatch and coverage cannot be wired on this
environment. The app surfaces this as an explicit blocked state; it does not
fake a result. Applying those migrations to staging was **not** performed in
this task.

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
| Planning / dispatch / coverage | see drift list | **BLOCKED — not deployed** |
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
| `test/staging_contract_test.dart` (4 live tests, staging) | **PASS** |

The live suite proves: `get_my_businesses` is reachable; RLS denies
unauthenticated order reads; a contract missing from staging is classified as
blocked rather than success; a deployed contract fails with a real backend
error instead of a blocked state.

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
earlier pack (`index.html`, `style.css`, `app.js` only). Logo F, rider and
product photography, the login gradient composition and the customer storefront
layout could not be reproduced from source. The preview URL is owner-private
(HTTP 401 for this agent).

## Canonical-doc conflict recorded

`docs/cefflo/sot/09_VENDOR_FLUTTER_60_SCREEN_MASTER.md` describes Vendor Flutter
as FUTURE, "not blanket implementation authorization", and holds V-41 and
V-50–V-54. The 6 September master supersedes both points (it authorizes
non-production implementation and reopens V-50–54 as UI). This task followed the
newer master and records the conflict here rather than silently rewriting the
SOT.

## Next blockers to clear

1. Apply the six missing migrations to staging (or confirm they are
   intentionally withheld) to unblock planning, dispatch and coverage.
2. Provide the 20260906 reference package with assets.
3. Decide and authorize a background-removal provider for product media.
4. Create a staging test identity so authenticated end-to-end flows can be
   exercised and evidenced.
5. Configure OAuth providers if Apple/Google sign-in is required.
