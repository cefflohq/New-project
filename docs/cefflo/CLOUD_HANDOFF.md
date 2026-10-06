# Cefflo — Cloud Handoff (2026-10-06)

Single source for a new session (Claude Code cloud / web or local) to continue
without re-deriving context. **Verify with git before trusting any note here**
(`git log -1`, `git status`, branch) — a stale handoff once started a session
on the wrong branch.

## 1. Where to work

| Item | Value |
|---|---|
| Repository | this repo, branch **`official/staging`** (the only working branch; no new branches/worktrees for surface work) |
| Main | `main` = marketing only (Vercel builds production `cefflo.com` from it) |
| Supabase STAGING | project ref `tomvvmwktehexwhktenw` — the only database you may change |
| Supabase PRODUCTION | `lmaxtrubwdniovxyuqdy` — **FORBIDDEN** without explicit Founder approval |
| Founder language | Reply to the Founder in **Bahasa Melayu**; code, commits and docs stay English |

### Hard rules
- Production (DB, secrets, DNS, Workers, Vercel) is **untouched** until the Founder approves a production release step.
- **Stop after push.** Deploy (even staging) only when the current instruction asks for it.
- Database changes: write a migration in `supabase/migrations/`, apply to staging only, record it in `supabase_migrations.schema_migrations`. Material authorization / RLS / role changes need Founder approval **before** applying.
- Every `psql` call is guarded: `[[ "$DATABASE_URL" == *tomvvmwktehexwhktenw* ]] || exit 1`.
- Requirements drive code: cite the locked decision before building; never invent behaviour. If UI and backend disagree, stop and report.
- Locked surfaces are frozen: change them only for a proven regression.
- Never print, log or commit secrets. Never reuse stored credentials to work around a missing permission.
- Do not add the unrelated untracked files in the working tree (`.claude/`, `docs/cefflo/brand/assets/logo/cefflo-bimi.svg`, `docs/cefflo/finos-framer-source-audit.*`, `docs/cefflo/legal/`, `wrangler.jsonc`).

### Credentials (not in the repo)
Staging values live in a local env file outside the repo (`/tmp/cefflo-phase2a-staging.env` on the Founder's machine): `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_SECRET_KEY` (new-style `sb_secret_…`: send as `apikey`, not as a Bearer JWT), `DATABASE_URL`, `SUPABASE_ACCESS_TOKEN` (deploy Edge Functions only; it lacks `edge_functions_secrets_read` and `analytics_logs_read`), staging test accounts. A cloud session must be given its own copy by the Founder — never ask for secrets in chat.
Unset `DATABASE_URL`, `SUPABASE_SECRET_KEY`, `SUPABASE_ACCESS_TOKEN` before any client build.

## 2. Surface status

| Surface | Status | Baseline / notes |
|---|---|---|
| **Helper PWA** | **LOCKED @ `fe99e46`** | see §3 |
| Customer Tracking | LOCKED @ `b495169` | |
| **Invite PWA** | **LOCKED @ `79752d0`** | see §3b; `8c067bb` is historical/superseded |
| Production domain map | FINAL/LOCKED | `docs/cefflo/engineering/PRODUCTION_DOMAIN_MAP.md` (prepared `3c6284e`, not deployed) |
| **Operator** | **LOCKED @ `79752d0`** | see §3a |
| **Driver Core** | **LOCKED @ `8d773c4`** | see §3c |
| Driver Marketplace Verification | **HOLD** — see §4 | backend + UI on staging |
| Vendor App / Vendor Web | Wired on staging; parity decisions locked | full audit pending |
| Storefront, FOUNDR, Marketing | pending their audit rounds | |

**Next surface (per V1 order: Operator + Invite + Helper → Vendor Web → Storefront → Customer Tracking E2E → Vendor App → FOUNDR → Driver): Vendor Web — NOT STARTED.** Start only when the Founder says so.

## 3. Helper PWA — LOCKED @ `fe99e46`

- Source: `apps/vendor_mobile` (Flutter web, Helper entry; `lib/ui/screens/helper_workspace.dart`). Staging: `https://cefflo-staging-app.pages.dev/?access=helper`. Production domain: `helper.cefflo.com` (host selects the entry; not merged with Operator; no `app.cefflo.com`).
- Access: permanent Helper invite link → join request (role from the server token only) → Pending → Owner (or Operator, Helper requests only) approval → workspace. Removed / pending / reset-link / cross-business all denied server-side.
- Data: reads only `my_fulfilment_tasks`; writes only `advance_preparation`, `confirm_packing`, `confirm_sorting` (forward-only transitions, row-locked, idempotent).
- **Active workload rule (locked):** TODAY + UNFINISHED work of the previous 7 business calendar days.
  - Date authority: `businesses.timezone` → `business_today` (server). No device time, no hardcoded Malaysia.
  - Previous 7 days included only while unfinished (not Ready, not picked up); Ready/completed history excluded.
  - Older than 7 days: excluded from the Helper board, **never deleted, cancelled or reset**. Progress carries across days.
- **Multi-date fix (locked):** packing confirmed per (Zone, order date) group; sorting per Run, or per order date when there is no Run.
- Refresh: pull-to-refresh, after each action, and on app resume (no polling; Helper has no RLS read on `orders`, so no realtime).
- Migrations: `20261006200000_helper_board_business_today`, `20261006210000_helper_backlog_7_days` (staging only).
- Tests: `tests/staging/helper_lifecycle` (59), `helper_backlog` (22), `helper_access` (36), `helper_e2e` (33); Flutter `test/helper_working_day_test.dart`.

## 3a. Operator — LOCKED @ `79752d0` (Founder-approved 2026-10-06)

- Lifecycle: Owner's Operator link → join → Pending (no workspace, no privileges) → Owner approves → operational workspace. Business + role resolved server-side (`get_my_businesses`); `?access=` / host only choose the Sign-In variant.
- Approved capabilities: operational workspace and actions (orders, storefront, Driver hiring posts); Driver link + approve / reject pending Driver applicants; Helper link (get / reset) + approve / reject Helper join requests (own business only).
- Never: Owner or Operator invites; promote anyone (incl. self) to Owner; remove an active Driver; Business Profile / hours / slug / Team administration / subscription / billing; anything in another business.
- Removal (`update_team_member` → inactive) revokes every privilege immediately, including on a live session. A removed Operator rejoins only through the current valid link + Owner approval.
- Tests: `tests/staging/operator_lifecycle` (89), `operator_access` (42).

## 3b. Invite — LOCKED @ `79752d0` (Founder-approved 2026-10-06)

- Gateway `invite.cefflo.com`; routing Driver → `driver.cefflo.com`, Operator → `operator.cefflo.com`, Helper → `helper.cefflo.com`. Owner is never an invite role.
- One permanent token per business + role. The server-issued token alone decides business, role and validity; client URL / query / domain never authorize.
- Issuers: Owner → Operator / Driver / Helper; Operator → Driver / Helper. Helper, Driver and pending users issue nothing.
- **Reset semantics (locked product decision):** reset immediately invalidates the old token for NEW join attempts and reveals the new token for that business + role only. It does NOT cancel pending join requests already created; those stay Pending and the Owner / authorized Operator still approves or rejects them under the normal role rules. Do not change.
- Rejoin: removed Helper / Driver / Operator returns to Pending through the current link (old token refused); no duplicate membership or pending request; approval required again.
- **Security fix (locked):** `20261006220000_join_approval_never_restores_owner` — approval grants the requested role; a removed (inactive) Owner never regains Owner through an approved join request. Owner is preserved only for an ACTIVE Owner row.
- Tests: `operator_lifecycle` (89), `invite_security` (48), `invite_regression` (54).

## 3c. Driver Core — LOCKED @ `8d773c4` (Founder-approved 2026-10-06)

- Access: Driver invite → Pending → Owner / Operator approval → active Driver. Business-assigned Drivers need NO Marketplace activation, payment, OCR or face recognition (Marketplace / Find Jobs is separate).
- Flow (locked order): Plan Route → Pickup Checklist → Slide to Start Delivery → sequential stops → POD → Complete → History. `start_run_delivery` is refused until pickup is complete; stop order is enforced by `rider_transition`.
- Tracking propagation: Pickup → On the way → Delivered. Multi-stop: Start Delivery → stop #1 `out_for_delivery`; completing stop #N → stop #N+1 `out_for_delivery`. External customer channels DEFERRED.
- Assignment lifecycle (locked, `20261006230000_assignment_completed_on_delivery`): a completed delivery sets its own assignment `completed` + `completed_at`; other stops and the run are untouched until every stop is delivered, then the session completes. Never regress to a stale `accepted`.
- Known non-blockers (follow-ups, not fixed in the lock): POD CDN cache for a URL the same token already opened; private orphan POD object after a failed completion retry; no business selector for multi-business Drivers; Plan Route confirmation not kept across an app restart before pickup; external customer notification channels deferred.
- Tests: `tests/staging/driver_lifecycle` (110), `driver_profile` (25), `delivery_e2e` (33); Flutter Driver 78.

## 3d. Vendor App (Owner) — non-payment V1, pre-lock (2026-10-06, not locked)

- Done: Today on the business's working day (`business_today`, `20261007100000`); silent live refresh on resume / operational events; `tests/staging/vendor_owner_lifecycle` (66).
- **Online/Offline removed from Vendor V1** (Founder 2026-10-06): it was local-only, reset on restart and claimed "new orders paused" though nothing paused. No availability contract was created; a future Store Open/Closed is designed with Storefront / business hours.
- **Subscription:** commercial model and payment **HOLD** — final plans, prices, Free/default-plan policy, entitlements, upgrade lifecycle and checkout are finalised in the payment/commercial pass. V1 keeps the honest read of `business_subscriptions` (no row → "managed by Cefflo", never a pretend paid plan). `data/plans.dart` stays a candidate (demo only).
- **KIM / help articles: DEFERRED.** Contact Support (email) stays.
- **Notification sound: v1.0.0 CANDIDATE** implemented in the Vendor App (`apps/vendor_mobile/assets/sounds/cefflo_signature.mp3`; source `shared/sounds/cefflo-signature.wav`), **awaiting Founder listening approval**; manifest `approved: false`.
- **Storefront untouched** — waiting for the Founder's final UI references.

## 4. HOLDs

**Marketplace OCR live validation — HOLD**
- Blocker: Google Cloud `BILLING_DISABLED`. Resume condition: Cefflo business billing/payment setup is ready.
- State: Edge Function `verify-marketplace-driver` DEPLOYED/ACTIVE on staging @ `a534f2d`, restricted `GOOGLE_VISION_API_KEY` set server-side (never modify/rotate/expose). Function reaches Google; fails safe (driver stays pending).
- On resume (no rebuild, no redeploy): 1) Founder enables billing; 2) re-run the live Vision smoke (a [TEST] driver + a non-document text image as the vehicle photo); 3) confirm `DOCUMENT_TEXT_DETECTION` succeeds; 4) authorized real-document OCR (Founder captures via the Driver staging app); 5) full Marketplace Verification E2E; 6) only then lock the backend.
- Locked design: Find Jobs only (Vendor-invited drivers FREE, never gated); IC typed + keyed HMAC (Vault `driver_ic_hmac_key`), licence FRONT + BACK + ONE vehicle photo, all live camera; SQL decides AUTO PASS / RETAKE / NEEDS REVIEW; FOUNDR = exceptions only; businesses never see IC / hash / images / evidence.

**Other holds:** Face recognition / biometrics — HOLD (absolute). Marketplace RM49 activation and all payments — NOT IMPLEMENTED (never fake success). Mapbox — gated (see V1 gates). Driver paid vehicle change: UI ready, Curlec (MY) / Stripe (intl) live keys required before production.

## 5. Follow-ups (not blockers of locked surfaces)

- **Driver customer notifications (Founder decision 2026-10-06):** external customer delivery (WhatsApp / SMS / customer push) stays DEFERRED; never fake success. Driver Core V1 keeps the state progression: Start Delivery → stop #1 `out_for_delivery`; completing stop #N → stop #N+1 `out_for_delivery` (sequence enforced by `rider_transition`). Customer Tracking reflects these states; the future notification system consumes the same transitions. The absence of an external second-stop message is NOT a Driver Core blocker.
- **Assignment terminal state (fixed 2026-10-06, `20261006230000`):** `complete_delivery` now sets the stop's own assignment `completed` + `completed_at`; the run completes only when every stop is delivered. Staging backfill: 66 assignments whose order was already delivered. Remaining Driver follow-ups (non-blocking): CDN cache of an already-fetched POD URL, orphan POD objects on retry, multi-business Driver selector, Plan Route confirmation not kept across app restart, external customer notification channels.

0. Known non-blockers (Operator/Invite lock): (a) Vendor App client UX guard `isOwner ?? true` while business is unresolved — server authorization is authoritative; change only on a proven regression. (b) Test-harness debt: legacy suites (`operator_access`, `invite_security`) leave [TEST] auth accounts behind and `invite_security` resets the shared staging Helper link each run; clean up later.

1. **Owner/Operator — stale fulfilment >7 days should surface under Needs Attention / operational attention.** Today "Need attention" (Vendor App + Web) counts only delivery issues. Do not build without approval.
2. FOUNDR exception-review UI for Marketplace Verification (backend stores status + reasons).
3. Multi-vehicle per driver needs a schema change (riders hold one vehicle) — propose separately.
4. Flutter resets the tab title to "Cefflo Vendor" on operator/helper hosts (manifest is correct).
5. Push notifications (V1 required, after the surface audits); Google Sign-in where shown (V1 required).

## 6. Production release checklist (pending, needs approval per step)

Staging-only migrations to promote (in order) are everything from `20261005120000` through `20261007100000` in `supabase/migrations/`, plus secrets/env from `PRODUCTION_DOMAIN_MAP.md` (static build bases, Supabase Auth allow-list, tracking-pod CORS, Mapbox public token, Cloudflare token with Workers + DNS edit). Record current DNS before attaching custom domains. Marketplace verification needs its own Vault key and Vision key per environment.

## 7. How to verify

```bash
set -a; . <staging env file>; set +a; unset DATABASE_URL
for t in tests/staging/*.test.mjs; do node "$t" | tail -1; done   # staging suites
node tests/production_surfaces.test.mjs
node tests/marketplace_ocr_extract.test.mjs; node tests/marketplace_vision_auth.test.mjs
(cd apps/vendor_mobile && flutter analyze && flutter test); git checkout -- apps/vendor_mobile/analysis_options.yaml
(cd apps/rider_mobile && flutter analyze && flutter test); git checkout -- apps/rider_mobile/analysis_options.yaml
```
Last full run (2026-10-06): all staging suites green (helper_lifecycle 59, helper_backlog 22, helper_access 36, helper_e2e 33, invite_regression 54, invite_security 48, operator_access 42, delivery_e2e 33, customer_tracking 63, rider_hub_find_jobs 57, driver_profile 25, storefront 25, marketplace_verification 55), production_surfaces 51, Flutter Vendor 213, Driver 76.

Staging test accounts follow `zelix.co00+v1004{owner,operator,helper,rider,rider2,outsider}@gmail.com` (password in the env file / Founder); business `8b643f0b-4034-47c3-bbbf-1eb8bea72532`. Tests create `[TEST]` fixtures and must clean them up.

## 8. Report format

End each surface round with: `| Surface | V1 Ready | Wired % | Surface blocker | Global dependency | Hold/Future | What's left |`, then global V1 gates (Push, Mapbox, Google OAuth, Payments) and P0/P1 blockers. Never declare a surface LOCKED yourself — report READY FOR LOCK and wait.
