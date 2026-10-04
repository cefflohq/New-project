# Staging Verification — 2026-10-04 (before Final UI/UX QA)

**Target:** staging `tomvvmwktehexwhktenw` only (schema = repo: 77/77 migrations).
**Code:** `official/staging` @ `d00fc9f`, built locally with the staging runtime
config (the hosted previews do not run this branch — see Configuration).
**Data:** new TEST-ONLY users `…+v1004{owner,operator,helper,rider,rider2,outsider}`
and business `[TEST] Verify 1004 Kedai`. No production access, no deploy.
Demo mode was not used as evidence anywhere below.

## Verified on real staging

| Area | Evidence | Result |
|---|---|---|
| Roles + permanent invite link | API as each real role: link per role, stable token, anon/outsider refused; Operator/Helper/Rider join → pending (no access) → Owner-only approval → active; self/outsider/Operator approval refused; repeat approval creates no duplicate | 48/48 |
| Order → … → Completed | create (Owner/Operator) → edit → approve → session → capacity check → run (idempotent replay) → accept → pickup → ready/picked up → sequence → out for delivery → arrived → POD upload → complete (idempotent) → Vendor read-back, events, public tracking; every wrong-role / wrong-rider / no-POD action refused | 50/56 first pass; the 6 were harness/order-of-steps issues, re-verified in the next row |
| Coverage → Zone → Plan, issue, recovery | unresolved = `pending_location`; resolved inside = `covered`, Johor = `out_of_coverage`; plan carries zone + candidate rider; issue → recovery (Vendor-only, idempotent) → assignment cancelled → re-plannable; events recorded | 18/19 (the 1 is by design, see note) |
| Debt #2 capacity failure (Vendor Web UI) | motorcycle/max-1 rider on a 3-order run: real violation shown, Create runs disabled; force-enabled click refused by `build_rider_run` and the reason shown; orders stay unassigned | PASS |
| Debt #10 contact support (real browser) | mailto captured: `support@cefflo.com`, subject, body = message + business id + role + account; page stays on Help | PASS |
| Debt #12 product media (Vendor Web UI) | 5 real JPEGs → save → refresh → reopen (5 load from display bucket, data persists) → reorder + remove → refresh (persisted); 6th photo refused by server; Helper/Rider/outsider cannot add, archive or reorder; originals private, display public | PASS (UI 8/8, API 11/11) |
| Debt #13 storefront (Vendor Web UI) | template/tagline/hero saved, publish, refresh + sign out/in persist; slug link + QR; Helper/outsider refused; bad theme / foreign hero refused; anon `public_storefront` serves the real config + products; hidden product and unpublished store not public; `store/` page renders the real config (served locally) | PASS (UI 8/8, API 13/13) |
| Vendor Web roles/states | Operator: Owner-only settings hidden, direct URLs fall back; Helper refused; Rider account gets business setup only; empty state; offline error + retry; sign out → direct URL shows nothing → sign in → data persists | 22/22 |
| Vendor App repository (live) | 11 existing anon contract tests + signed-in Owner/Operator/Helper (orders, events, coverage, team, riders, products, storefront, hours save/read, report issue, recovery refusal, Owner-only refusal) | 14/14 |
| Driver app (live) | staging contract tests | 11/11 |
| Customer tracking | real token: delivered timeline; `tracking-pod` signed POD URL serves the photo; bad token refused; snapshot hides phones/ids; rating via the real page persists once, visible to Vendor, not asked again | PASS |

Note — out-of-coverage orders are proposed in the plan: by design (S4-11
Batch 2: coverage is an operational exception, only vehicle/capacity blocks).

## Blockers

| P | Blocker | Why it blocks |
|---|---|---|
| P1 | `geocode-order` is not deployed on staging (HTTP 404); needs `CEFFLO_MAPBOX_ACCESS_TOKEN` | Orders created in either Vendor surface never resolve a location, so coverage stays "awaiting location" and Plan Delivery proposes nothing. Verified downstream only by resolving test orders with `set_order_location_manual`. Deploy needs Founder approval. |
| P1 | Customers cannot receive the tracking link | `create_delivery` returns the token once (only the hash is stored); neither Vendor App nor Vendor Web shows or shares it (the retired legacy page had the button). D-04: the shared link is the normal entry. `rotate_tracking_token` exists but invalidates any earlier link. **Product decision needed:** how and when the Vendor shares the link. |
| P1 | Public storefront is not served anywhere | `store/` is not in the static build; `cefflo.com/<slug>` redirects, `www.cefflo.com/<slug>` 404. The page itself works against staging. Needs the canonical storefront host/routing (see Configuration). |
| P2 | `tracking-pod` returns no CORS origin on staging | POD photo hidden in the browser tracking page (the function itself works). Set `CEFFLO_TRACKING_CORS_ORIGINS` to the staging tracking host. |
| P2 | Google sign-in not enabled on staging (`email` only) | "Continue with Google" on Vendor Web cannot be verified on staging. |
| P2 | Legacy invite backend still live (audit below) | Not reachable from Vendor UI; Driver app + invite PWA still use the rider legacy path. |
| P2 | `rotate_tracking_token` / `revoke_tracking_token` use `is_business_member` | A Helper can rotate/revoke a customer's tracking link. Review with the security master. |
| P2 | Public storefront ignores the hero image | Colours, tagline, products and photo order are applied; hero is not shown. |
| P2 | Helper message on Vendor Web says "Helpers use the Cefflo Vendor mobile app" | Founder decision: Helper = Helper PWA only (not built yet — later work order step). |

## Final UI/UX QA list (not fixed)

- Error state shows the raw "Failed to fetch" under "Something went wrong".
- Capacity wording "Capacity exceeded: 0 active + 3 requested exceeds 1." is technical.
- Unpublished storefront uses the generic "Pending" chip.
- Rider account on Vendor Web lands on "Set up your business" with no explanation that it is a Driver account.
- Customer tracking time is browser-local (correct, but consider showing the business timezone).

## Configuration still required (verified, not assumed)

| Item | Verified state |
|---|---|
| `geocode-order` deploy + `CEFFLO_MAPBOX_ACCESS_TOKEN` | Not deployed on staging (404); production per release plan G6 |
| `tracking-pod` `CEFFLO_TRACKING_CORS_ORIGINS` | Deployed on staging; no origin allowed |
| Customer tracking host | `tracking.cefflo.com` serves the marketing site; `/customer/` 404 |
| Vendor Web host | `vendor.cefflo.com` serves the marketing site; the `/web/` redirect in `vercel.json` is not deployed |
| Hosted staging preview | `preview.cefflo.com` serves the Flutter Vendor App build on every path (not `official/staging` static surfaces) |
| Storefront base URL + routing | `CEFFLO_CONFIG.storefrontBaseUrl` absent (Web falls back to `https://cefflo.com/`, App default the same); no host routes `/<slug>` to `store/`; `store/` not in the build |
| Google OAuth provider | Staging: only `email` enabled |
| Driver / Vendor store listing URLs | `null` in runtime config |
| Auth email (SMTP, templates, redirects) | Signup requires confirmation (`mailer_autoconfirm=false`); email delivery not exercised in this pass |

## Security cleanup — legacy email invitations (audit only, nothing changed)

**Callers in the repo:** Vendor App / Vendor Web: none (retired in `67d58ad`).
Driver app: `claim_my_rider_invitations` on every sign-in and
`accept_rider_invitation` in onboarding. Invite PWA (`invite/backend.js`):
`resolve_/consent_/decline_{team,rider}_invitation` for legacy `?token=` links.
Tests: `s4_07_batch_1/3`, `s4_07_frontend_wiring`.
**Database:** 14 functions reference `team_invitations` / `rider_invitations`;
two RLS policies; no triggers or views. Staging rows: team 10 pending + 2
consented; rider 27 pending + 16 consented (still redeemable).
**Risk:** the team path (`claim_my_team_invitations` / `accept_team_invitation`
→ `team_membership_from_invitation`) creates an **active** membership with no
approval step — contrary to Master Part III §9-11. It is Owner-initiated
(`create_team_invitation` is Owner-only), so not an outsider escalation. The
rider path creates **pending** riders (approval still required).
**Safe to retire after, in order:**
1. Driver app: remove `claimMyRiderInvitations` (sign-in) and the
   `accept_rider_invitation` onboarding path; invite PWA: remove legacy
   `?token=` handling (keep `?link=`); update the s4_07 tests.
2. Migration (staging first, Founder-approved): expire open invitations
   (`pending`/`consented` → `expired`), then `revoke execute … from
   authenticated` on `create_*`, `consent_*`, `accept_*`, `claim_my_*`,
   `resolve_*`, `decline_*`, `revoke_*` invitation functions. Keep tables for
   audit history; drop later only with a data decision.
3. Positive/negative tests: link flow unchanged; every legacy RPC refused.

## Result

**STAGING NOT YET VERIFIED** — to reach Final UI/UX QA:
1. Founder-approved staging deploy of `geocode-order` with a staging Mapbox token
   (then re-run order → plan through the UI without manual location).
2. Founder decision on how the Vendor shares the customer tracking link, then
   implement and verify it.
3. Canonical storefront host/routing decision (and include `store/` in the
   build), then set the storefront base URL.
4. A hosted staging deployment of `official/staging` surfaces for the Founder
   walkthrough (Vendor Web, Customer, Invite, Storefront), with
   `CEFFLO_TRACKING_CORS_ORIGINS` set for its tracking host.
