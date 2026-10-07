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
| **Vendor App (Owner) V1** | **LOCKED @ `2bd8636`** | see §3d |
| **Vendor Web V1** | **LOCKED @ `234b0cc`** | see §3f |
| Driver Marketplace Verification | **HOLD** — see §4 | backend + UI on staging |
| **Public Storefront V1** (`order.cefflo.com`) | **LOCKED @ `e93f464`** | see §3e (separate from Vendor Web Storefront Settings) |
| **FOUNDR V1** | **LOCKED @ `897977a`** | see §3g |
| Marketing | pending its audit round | |

**Next surface: MARKETING — NOT STARTED (wait for the Founder; Public Storefront locked 2026-10-07).** Compliance items (PDPA §5 / `PDPA_DATA_MAP.md`) are production-readiness gates, not blockers of staging work.

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

## 3d. Vendor App (Owner) V1 — LOCKED @ `2bd8636` (Founder-approved 2026-10-06)

- Scope: Today (business working day via `business_today`), Orders, Zones / Runs (locked Driver assignment terminal state), Drivers, Team (locked Invite / Operator / Helper contracts), Products + photos, Service Area (non-Mapbox), Business Profile + Hours, Profile / Account + private avatar, Appearance / Language (device-only), Help & Support (Contact Support; KIM / articles DEFERRED), About (real build version). Silent live refresh on resume / operational events. **Online/Offline removed.**
- Notifications: banner, Notification Center, realtime, resume refresh, Sound preference, 1.5 s burst protection; **Cefflo Signature Sound M v1.2.0** (Founder-approved: "Cef-flo, Cef-flo", `shared/sounds/cefflo-signature.*`, manifest `approved: true`).
- Subscription (pre-payment): designed V-50 / V-51 / V-52 / V-54 live on the server price book `subscription_plans` — FREE RM0 · 150 completed deliveries · 3 Drivers · 2 Zones · 1 User; GROW RM99 · 500 · 10 · 5 · 3; OPERATE RM199 · 1,500 · unlimited · unlimited · 10 (most popular); SCALE RM499 · 5,000 · unlimited · unlimited · 25; ENTERPRISE custom. FREE needs no payment details (every business starts FREE/active). Only completed deliveries count. Owner-only `my_subscription`; `request_plan_change` stops at the payment boundary (writes nothing); FOUNDR `admin_set_subscription` is the only plan setter. No fake payment, invoice or renewal date. **Quota / allowance enforcement deferred** to the commercial/payment pass (never block dispatch until then).
- Migrations (Vendor work, staging only): `20261007100000_business_today`, `20261007110000_subscription_plans_free_default`.
- Tests: `tests/staging/vendor_owner_lifecycle` (66), `tests/staging/subscription` (27); Flutter Vendor 222.
- Deferred pre-production: payment gateway / checkout / webhook / verified activation / invoices / payment methods; annual pricing, overage, quota + cap enforcement; Mapbox (Locate address, geocoding); external push (+ Android `.ogg` / iOS `.caf`); Google login E2E + redirect allow-list; KIM / help articles.
- Storefront untouched — next surface, waiting for the Founder's final UI references.

## 3e. Public Storefront V1 — LOCKED @ `e93f464` (Founder-approved 2026-10-07)

Canonical production surface `https://order.cefflo.com` (separate from Vendor Web Storefront Settings / Live Preview). Final verification: P0 none · P1 none. Earlier build history: 18 templates from the Founder's references (`store/templates.js`, `store/store.css`, engine `store/store.js`), migrations `20261007120000_storefront_preview`, `20261007130000_storefront_v1_template_keys`.

- **Public access:** only published / enabled storefronts are public; unpublished / disabled ones take no orders; data-minimised payload (business name, area, hours, active products, approved display photos); original / private product media stays private; XSS escaping enforced.
- **Ordering:** server-authoritative products and prices; hidden / cross-business products refused; integer quantities, 1-50 per product, max 20 lines; idempotency key required; replay never duplicates and returns the same order with its rotated tracking token; a successful order creates exactly one Vendor `order.new_customer` notification. Refusals return `{error}` (HTTP 200) so they stay counted.
- **Business hours:** browsable while closed; new orders refused server-side while closed (canonical `business_open_now`, business timezone, overnight hours supported); no configured hours keeps the existing unknown semantics (ordering allowed); client clock never authoritative; payload `next_open`.
- **Rate limiting (migration `20261007150000`):** trusted caller identity = `sb-forwarded-for`, then `cf-connecting-ip`, else one restrictive shared bucket; client-controlled `X-Forwarded-For` / `True-Client-IP` never trusted (verified against the real Supabase proxy chain); read limit 60/min/caller, order limit 5/min/caller, per-store 120/min; malformed / refused attempts counted; limiter failure fails closed.
- **Language:** English default, Bahasa Melayu selectable; stored on the device; no auto-detection; vendor content never translated.
- **Cart:** persisted on the device per storefront, no customer details stored, reconciled with the live catalogue on load, clearable, cleared after a successful order; server authoritative.
- **Customer phone:** international format (optional +, 7-15 digits), frontend for UX, backend authoritative; no SMS verification.
- **Money:** always two decimals (RM 8.00).
- **Tracking:** the success page shows Track your order when tracking is configured and a token is returned; replay restores valid tracking access; the tracking lifecycle stays governed by locked Customer Tracking.
- **SEO:** published live storefront indexable with basic description / OG; preview and unpublished / nonexistent storefronts noindex; no SEO subsystem in V1.
- **18 templates — PASS:** Care, Capsule, Kit, Brew, Crimson, Lift, Harvest, Botanic, Combo, Discover, Atelier, Pour, Tailor, Sprint, Splash, Service, Warung, Collector. Ids / order and the Vendor Storefront Settings contract unchanged; the Founder's references remain the visual source of truth. Final QA 18 templates × 4 widths (390 / 820 / 1100 / 1440) × 4 screens = 288 browser checks: no page-level overflow, no blank screens, no console errors.
- **Security baseline:** `storefront_security` 44/44 · `storefront` 25/25 · `storefront_v1` 25/25 (unpublished / disabled, closed business, hidden and cross-business products, server price, quantity and line limits, idempotency, replay, rate-limit spoofing, malformed abuse, minimal payload, Vendor notification, XSS, private original media).
- **Regression (2026-10-07):** storefront_security 44/44 · foundr_admin 168/168 · subscription 27/27 · vendor_owner_lifecycle 66/66 · storefront_v1 25/25 · storefront 25/25 · operator_access 42/42 · operator_lifecycle 89/89 · helper_access 36/36 · helper_backlog 22/22 · helper_lifecycle 59/59 · helper_e2e 33/33 · invite_regression 54/54 · invite_security 48/48 · driver_profile 25/25 · driver_lifecycle 110/110 · rider_hub_find_jobs 57/57 · delivery_e2e 33/33 · customer_tracking 63/63 · marketplace_verification 55/55; offline storefront_templates 6/6, vendor_web_auth_recovery 10/10, foundr_auth_recovery 12/12, foundr_mfa 15/15, production_surfaces, marketplace ocr / vision.
- **Hard pre-production gates (do not reopen the lock):** (1) Public Storefront Privacy Notice and any legally required consent (PDPA) before real users; (2) configure and verify `CEFFLO_STOREFRONT_BASE_URL=https://order.cefflo.com/` and `CEFFLO_TRACKING_BASE_URL=https://tracking.cefflo.com/`, then deployment smoke test; (3) migration `20261007150000` in the approved production migration rollout.
- **Known non-blockers:** no deployed staging Storefront surface; local staging env lacks the Storefront / Tracking base URLs; the JavaScript-added noindex is not seen by non-JS crawlers; tracking starts per the locked Customer Tracking lifecycle; the idempotency key is not kept across a full reload after an interrupted submission; unrelated `apps/vendor_mobile/analysis_options.yaml` untouched.

## 3f. Vendor Web V1 — LOCKED @ `234b0cc` (Founder-approved 2026-10-07)

- Parity with the locked Vendor App, fitted to desktop: Today, Orders, Zones / Active Runs, Drivers, Team (Drivers / Operators / Helpers; approve / reject / remove with typed CONFIRM), Products, Service Area (manual coordinates; Locate needs Mapbox), Storefront settings, Business Profile + Hours, Profile, Notifications + Sound M v1.2.0, Subscription, Hiring, Appearance / Language (EN/BM), Help, About, auth (email/password, session restore, expired session, sign-out). Invite Reset not in UI (as the App, Founder 2026-10-01; server function kept).
- Storefront settings: the 18 V1 templates (ids/order shared with the renderer and the Vendor App, test-enforced), Live Preview through the real renderer (`store/?embed=1`), colour/slogan live, banner field hidden for no-banner templates, old templates and style selector removed.
- Subscription from the server price book (`my_subscription` + `subscription_plans`), ENTERPRISE custom, monthly only; payment HOLD.
- Dates/times in the business timezone; `business_today`; no driver Online/Offline; live refresh on Vendor notifications and tab resume; a refused (`forbidden`) action re-checks membership (as the App's loadSession).
- Verification 2026-10-07 (staging, real accounts, CDP browser): 144-page sweep at 1440/1100/820/390 (no overflow, console errors or failed requests), Owner + Operator browser QA, security matrix 105/105, full staging regression green, Flutter Vendor 235.
- Production requirement: `CEFFLO_VENDOR_CONSOLE_URL=https://vendor.cefflo.com/` (Live Preview origin; recorded in the domain map). Gates: Google OAuth, Mapbox, Push, Payments.

## 3g. FOUNDR V1 — LOCKED @ `897977a` (Founder-approved 2026-10-07)

Final verification: P0 none · P1 none · READY FOR FOUNDR LOCK.

- **Auth / security:** platform admin only; server-authoritative authorization; **MFA / AAL2 required server-side** (`is_platform_admin()` requires aal2, migration `20261007140000`) — an admin without MFA cannot use admin RPCs or admin RLS/storage reads; mandatory MFA set-up (no "Not now"); Cloudflare Access stays in the production protection architecture; sensitive admin mutations are audit-logged.
- **Admin backend:** the 24 FOUNDR admin RPCs on the real backend; no fake operational/admin data; RLS + RPC authorization authoritative; `admin_audit_log` authoritative for admin mutations.
- **Subscriptions:** server price book only — FREE · GROW · OPERATE · SCALE · ENTERPRISE (custom). `trial` is a status, never a selectable plan. No `business_subscriptions` row = **Free (default)** (no row created). Admin override through `admin_set_subscription` with confirmation (current → target), server result shown, audited. No fake payment / invoices / renewal, annual pricing, overage or quota enforcement.
- **Marketplace Driver Verification (manual review, LOCKED):** views Pending / Needs review / Verified / Rejected / Retake; decisions Verify / Reject / Retake licence / Retake vehicle via `decide_marketplace_verification` (now writes `admin_audit_log` `marketplace_decision`); private documents through temporary signed URLs only; IC shown as last 4 digits only, the full IC never exposed by FOUNDR; confirmation before every decision; reason required for Reject / Retake; result refreshed from the backend. Google Vision / OCR, Marketplace activation payment and face / liveness remain HOLD.
- **Terminology:** user-facing "Driver"; backend identifiers keep `rider` / `riders` / `rider_*`.
- **Modules locked as functional:** Overview, Vendors, Operations, Drivers, Driver Verification, Controls (Maintenance, Flags, Announcements, Broadcast), Versions, Subscriptions, System Health, Audit Log, Settings / Account / Admin, Auth + MFA. Honest HOLD states (not blockers, never fabricated): Support, Marketing, external Integrations Health.
- **Security baseline:** `tests/staging/foundr_admin` **168/168** — all 24 used admin RPCs; anon / normal user / business Owner / AAL1 admin rejected, AAL2 admin permitted; RLS isolation; private document access; audit rows for every admin mutation incl. Marketplace decisions; fixtures cleaned.
- **Browser QA (CDP, real [TEST] admin + TOTP):** PASS at 1440 / 1100 / 820 / 390; 52-page sweep with 0 console errors, 0 failed requests, 0 page errors; no page-level horizontal overflow; single approved light theme.
- **Regression (2026-10-07):** foundr_admin 168/168 · subscription 27/27 · vendor_owner_lifecycle 66/66 · storefront_v1 25/25 · storefront 25/25 · operator_access 42/42 · operator_lifecycle 89/89 · helper_access 36/36 · helper_backlog 22/22 · helper_lifecycle 59/59 · helper_e2e 33/33 · invite_regression 54/54 · invite_security 48/48 · driver_profile 25/25 · driver_lifecycle 110/110 · rider_hub_find_jobs 57/57 · delivery_e2e 33/33 · customer_tracking 63/63 · marketplace_verification 55/55; offline foundr_auth_recovery 12/12 · foundr_mfa 15/15 (+ storefront_templates 6/6, vendor_web_auth_recovery 10/10, production_surfaces).
- **Known non-blockers:** (1) **HARD PRE-OCR PRODUCTION GATE:** `driver_marketplace_verifications.licence_result` can technically hold the full IC from OCR; data minimisation must be resolved BEFORE Google Vision / OCR is enabled for real users (not done in the lock). (2) Long admin email truncates at phone width (cosmetic). (3) `apps/vendor_mobile/analysis_options.yaml` local change is unrelated and untouched.
- Global holds that do not reopen FOUNDR: payment gateway, Marketplace activation payment, Vision/OCR live processing and its data-minimisation fix, face/liveness, Mapbox, external push, Google OAuth production E2E/allow-list, Supabase Singapore production project, production DNS/secrets/migrations, remaining PDPA readiness, external Support/Marketing/integration sources.

## 4. HOLDs

**Marketplace OCR live validation — HOLD**
- Blocker: Google Cloud `BILLING_DISABLED`. Resume condition: Cefflo business billing/payment setup is ready.
- State: Edge Function `verify-marketplace-driver` DEPLOYED/ACTIVE on staging @ `a534f2d`, restricted `GOOGLE_VISION_API_KEY` set server-side (never modify/rotate/expose). Function reaches Google; fails safe (driver stays pending).
- On resume (no rebuild, no redeploy): 1) Founder enables billing; 2) re-run the live Vision smoke (a [TEST] driver + a non-document text image as the vehicle photo); 3) confirm `DOCUMENT_TEXT_DETECTION` succeeds; 4) authorized real-document OCR (Founder captures via the Driver staging app); 5) full Marketplace Verification E2E; 6) only then lock the backend.
- Locked design: Find Jobs only (Vendor-invited drivers FREE, never gated); IC typed + keyed HMAC (Vault `driver_ic_hmac_key`), licence FRONT + BACK + ONE vehicle photo, all live camera; SQL decides AUTO PASS / RETAKE / NEEDS REVIEW; FOUNDR = exceptions only; businesses never see IC / hash / images / evidence.

**Other holds:** Face recognition / biometrics — HOLD (absolute). Marketplace RM49 activation and all payments — NOT IMPLEMENTED (never fake success). Mapbox — gated (see V1 gates). Driver paid vehicle change: UI ready, Curlec (MY) / Stripe (intl) live keys required before production.

## 5. Follow-ups (not blockers of locked surfaces)

- **Removed team member data lifecycle (Founder decision 2026-10-07):** keep current behaviour for V1 — removal revokes access immediately (status `inactive`), never deletes the account, profile or history; rejoin via the invite link with re-approval. Permanent deletion after 24 h rejected (FK failures, cascades other businesses, erases audit). Details: `docs/cefflo/security/REMOVED_MEMBER_DATA_LIFECYCLE.md`.
- **Driver customer notifications (Founder decision 2026-10-06):** external customer delivery (WhatsApp / SMS / customer push) stays DEFERRED; never fake success. Driver Core V1 keeps the state progression: Start Delivery → stop #1 `out_for_delivery`; completing stop #N → stop #N+1 `out_for_delivery` (sequence enforced by `rider_transition`). Customer Tracking reflects these states; the future notification system consumes the same transitions. The absence of an external second-stop message is NOT a Driver Core blocker.
- **Assignment terminal state (fixed 2026-10-06, `20261006230000`):** `complete_delivery` now sets the stop's own assignment `completed` + `completed_at`; the run completes only when every stop is delivered. Staging backfill: 66 assignments whose order was already delivered. Remaining Driver follow-ups (non-blocking): CDN cache of an already-fetched POD URL, orphan POD objects on retry, multi-business Driver selector, Plan Route confirmation not kept across app restart, external customer notification channels.

0. Known non-blockers (Operator/Invite lock): (a) Vendor App client UX guard `isOwner ?? true` while business is unresolved — server authorization is authoritative; change only on a proven regression. (b) Test-harness debt: legacy suites (`operator_access`, `invite_security`) leave [TEST] auth accounts behind and `invite_security` resets the shared staging Helper link each run; clean up later.

1. **Owner/Operator — stale fulfilment >7 days should surface under Needs Attention / operational attention.** Today "Need attention" (Vendor App + Web) counts only delivery issues. Do not build without approval.
2. FOUNDR exception-review UI for Marketplace Verification (backend stores status + reasons).
3. Multi-vehicle per driver needs a schema change (riders hold one vehicle) — propose separately.
4. Flutter resets the tab title to "Cefflo Vendor" on operator/helper hosts (manifest is correct).
5. Push notifications (V1 required, after the surface audits); Google Sign-in where shown (V1 required).

## 6. Production release checklist (pending, needs approval per step)

Staging-only migrations to promote (in order) are everything from `20261005120000` through `20261007130000` in `supabase/migrations/`, plus secrets/env from `PRODUCTION_DOMAIN_MAP.md` (static build bases, Supabase Auth allow-list, tracking-pod CORS, Mapbox public token, Cloudflare token with Workers + DNS edit). Record current DNS before attaching custom domains. Marketplace verification needs its own Vault key and Vision key per environment.

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
