# CEFFLO Production Release Plan

Status: PREPARED, awaiting the Founder production-write gate. Prepared
2026-09-27 from READ-ONLY inspection. No Production write has been made.

- Production Supabase project: `lmaxtrubwdniovxyuqdy`.
- Staging reference: `tomvvmwktehexwhktenw`.

## 1. Production migration parity (read-only evidence)

**Method.** Anonymous `GET <table>?select=<column>&limit=0` probes, which read
no rows, against one marker column per migration. The Production OpenAPI
schema needs a secret key, so it was not used.

| Marker (migration) | Staging | Production |
|---|---|---|
| `profiles.id` (202608130001 foundation) | present | **present** |
| `business_profile_audit` (202608270001) | present | missing table |
| `rate_limit_counters` (202608270007) | present | missing table |
| `orders.approved_at` (202608270010) | present | missing column |
| `delivery_stops.sequence_locked_at` (202608280001) | present | missing column |
| `orders.zone_id` (202608280002) | present | missing column |
| `team_invitations`, `rider_invitations` (202608290002/3) | present | missing tables |
| `platform_admins`, `admin_audit_log`, `business_subscriptions` (2026083000xx) | present (staff-only) | missing tables |
| `product_categories`, `product_media` (2026083100xx) | present (staff-only) | missing tables |
| `orders.origin` (202609010001) | present | missing column |
| `orders.location_status` (202609030001) | present | missing column |
| `businesses.service_origin_latitude` (202609030002) | present | missing column |
| `riders.vehicle_type` (202609030003) | present | missing column |
| `delivery_stops.preparation_status` (202609030006) | present | missing column |
| `orders.order_date` (202609260001, D-64) | present | missing column |
| `rider_assignments.live_topic` (202609270001, D-66) | present | missing column |

**Conclusion.**
- Production holds only the foundation migration `202608130001`.
- **53 canonical migrations are missing**, `202608270001` through
  `202609270002`. The table below lists them in order.
- Staging holds all 54 repo migrations in `schema_migrations`, an exact match.
- Edge functions: `tracking-pod` is deployed on Production and staging.
  `geocode-order` is deployed on neither.

Ordered migration set for Production (apply in this exact order):

| # | Migrations |
|---|---|
| 1–13 | 202608270001 → 202608270013 (S4-03/S4-04/S4-05) |
| 14–18 | 202608280001 → 202608280005 (S4-06) |
| 19–22 | 202608290001 → 202608290004 (S4-06.7/S4-07) |
| 23–27 | 202608300001 → 202608300005 (FOUNDR/grants) |
| 28–30 | 202608310001 → 202608310003 (S4-08/S4-10a-b) |
| 31–33 | 202609010001 → 202609010003 (S4-10e) |
| 34–45 | 202609030001 → 202609030012 (S4-11 Flow 2 engine) |
| 46–50 | 202609040001 → 202609040005 (F2 hardening) |
| 51 | 202609260001 (D-64 order number, with a data backfill of existing orders) |
| 52–53 | 202609270001 → 202609270002 (D-66 live location) |

Before applying, a secret-key or dashboard inspection must confirm there are
**no manual out-of-band Production objects**: compare `pg_proc`, `pg_policies`
and `information_schema.columns` with staging. Read-only probes cannot rule
that out.

## 2. Recovery posture

- Public (publishable-key) probes prove **only** that certain objects are
  reachable. They do **not** prove the full Production schema, RLS, grants,
  functions, triggers, out-of-band objects or data. §1 is therefore evidence
  for planning, not clearance to write.
- Backups and PITR **cannot be seen** with the public key. The Founder (or an
  operator with Dashboard access) must verify in Supabase Dashboard →
  Database → Backups:
  - the plan tier (Free has no automated backups; Pro has daily backups with
    7-day retention);
  - whether PITR is enabled.
- Migrations are **forward-only**. None has a down script, several add
  constraints or backfill data (for example 202609260001), and some change
  RLS or grants.
- **Rollback is therefore restore-from-backup/PITR, or a forward fix.** A
  schema-level "undo" is not available.
- **The write gate requires both:**
  - a privileged inspection (below);
  - a verified recovery point taken immediately before gate step G4.

## 3. Release procedure (gated; each gate must pass before the next)

| Gate | Action | Pass criterion | On failure |
|---|---|---|---|
| G1 BACKUP/PITR VERIFIED | Take a fresh manual backup, or record the PITR timestamp. Confirm in the Dashboard that it is restorable. | Restore point ID/time recorded in the release log | STOP. No write. |
| G2 PROD SCHEMA + RLS INSPECTION | Privileged read-only session (`psql` with the DB connection string, from an operator machine and never committed). Dump `schema_migrations`, `pg_policies`, table/column list, functions, triggers, grants and row counts per table. Diff against staging at `202609270002`. | Only expected differences (the 53 pending migrations). No out-of-band objects that a migration would collide with. | STOP. Resolve each difference into the plan (a forward-compatible migration, or a documented skip) and re-run G2. |
| G3 ORDERED PLAN | Fix the exact list `202608270001 → 202609270002` (53 files), with a checksum of each file at the release commit. Name the operator and the approver. | Plan signed off by the Founder | STOP. |
| G4 APPLY, STOP ON FIRST ERROR | Apply each migration in order, each in its own transaction (`psql -v ON_ERROR_STOP=1 -1 -f <file>`, or `supabase db push`). Record each in `supabase_migrations.schema_migrations`. | Every file commits, and 54 rows are in `schema_migrations` | Halt at the failing file and do not continue. Either forward-fix (isolated and understood), or restore the G1 point. |
| G5 SCHEMA/RPC/RLS VERIFY | Re-run the G2 dump and diff it against staging. Marker probes (§1) return 200. D-64 backfill: every order has `order_date`/`order_seq`, with no duplicate `(business_id, order_date, order_seq)`. RLS checks as below. | Diff is empty, and all checks pass | Forward fix, or restore G1 |
| G6 EDGE FUNCTION / AUTH CONFIG | Deploy `geocode-order` and `tracking-pod`. Set their secrets (§5, `CEFFLO_TRACKING_CORS_ORIGINS=https://tracking.cefflo.com`). Configure Auth SMTP, Site URL, redirect allowlist and templates (§4). | Function health responds; test emails are received from `no-reply@cefflo.com` | Revert the setting or secret, or undeploy |
| G7 TEST-ONLY PROD SMOKE | Use TEST-ONLY accounts. **Vendor:** signup confirmation deep link, sign-in, create order `#CF-001` (location resolves), dispatch. **Driver** (Production build): invitation → accept → pickup → deliver with POD. **Customer:** tracking link. **Recovery:** password reset via the deep link. | Full lifecycle passes | Fix, or roll back the failing layer. Delete TEST-ONLY rows. |
| G8 GO / ROLLBACK | Founder decides GO. DNS cut-over (§6) happens **only after** G7. | GO recorded | Roll back per layer: DNS records, then config, then DB restore to G1 (last resort) |

RLS checks in G5:

- anon sees `[]` on all operational tables;
- a second business sees none of the first business's rows;
- `rider_live_keys` and `latest_rider_locations` refuse foreign callers;
- `public_tracking` returns null for `#CF-xxx`, `public_ref` and the order
  UUID used as a token.

Credentials the operator needs for G1–G6 (never committed or printed): the
Production DB connection string, a Supabase access token for the CLI, and
Dashboard access for backups and Auth settings.

## 4. Auth email (custom SMTP): prepared, not configured

- **Decided identity:**
  - display name **"Cefflo"**;
  - sender **`no-reply@cefflo.com`**;
  - never a personal mailbox.
- **Provider:** not chosen (Founder). Whatever provider is chosen, the settings
  are Supabase Auth → SMTP:
  - `SMTP_HOST`
  - `SMTP_PORT` (587 STARTTLS or 465)
  - `SMTP_USER`
  - `SMTP_PASSWORD`
  - sender `no-reply@cefflo.com`
  - name `Cefflo`
- **DNS at Cloudflare for `cefflo.com`:**
  - the provider's SPF include merged into the single existing SPF TXT;
  - the provider's DKIM CNAME/TXT records;
  - `_dmarc` TXT, starting at `v=DMARC1; p=none; rua=mailto:<monitored address>`,
    then tightened.
- **Auth URL configuration:**
  - Site URL `https://vendor.cefflo.com`;
  - redirect allowlist:
    - `cefflo-vendor://auth-callback`
    - `cefflo-driver://auth-callback`
    - `https://vendor.cefflo.com/**`
    - `https://invite.cefflo.com/**`
- **Code, verified 2026-09-27:**
  - `resetPasswordForEmail` redirects to the app scheme;
  - `signUp` passes `emailRedirectTo` to the app scheme in both apps, as does
    Vendor `resend`, so confirmation links no longer fall back to the Site URL.
  - Android intent filters and the iOS `CFBundleURLSchemes` declare
    `cefflo-vendor` and `cefflo-driver`.
- **Templates:** confirm signup, reset password, magic link/OTP (the Vendor
  email OTP uses `{{ .Token }}`). Each is branded "Cefflo" with no personal
  names.
- **Invitations:**
  - Vendor creates the invitation through RPC (`p_invited_email/name/phone`) and shares
    the `https://invite.cefflo.com/...` link.
  - The Driver opens it, signs up or signs in (the confirmation deep link returns
    to the app), then accepts.
  - The invitation flow sends **no** Supabase invite email, so SMTP only affects
    signup, recovery and OTP.
  - `invite.cefflo.com` must resolve before launch (§6).

## 5. Geocoding (Mapbox): required for launch

- Launch quality **requires** geocoding. There is no degraded manual-location
  launch plan.
- **Token scope:**
  - `geocode-order` reads the **server-side** secret `CEFFLO_MAPBOX_ACCESS_TOKEN`
    (Mapbox Geocoding v6 forward, `permanent=true`).
  - Verified 2026-09-27: no Mapbox token appears in any client, test fixture or
    committed file. Only the env-var name is in `.env.staging.example`.
- **Failure behaviour is truthful.** The order's `location_status` becomes
  `failed` with a recorded reason:
  - `invalid_credentials`
  - `rate_limited`
  - `provider_unavailable`
  - `network_failure`
  - `no_result`
  - `malformed_provider_response`

  Or it becomes `ambiguous` (low confidence). The Vendor UI shows "Address could not be located"
  or "Address ambiguous", never a fake coordinate.
- **Deploy requirements (G6):**
  - a Mapbox account with Permanent Geocoding enabled;
  - a token with geocoding scope only;
  - `supabase secrets set CEFFLO_MAPBOX_ACCESS_TOKEN=… --project-ref lmaxtrubwdniovxyuqdy`;
  - `supabase functions deploy geocode-order --project-ref lmaxtrubwdniovxyuqdy`.
- **Verification:** a G7 test order resolves (`location_status=resolved`), and
  coverage, suggested runs and ETA render.

## 6. DNS / hosting: prepared, not changed

Authoritative nameservers: Cloudflare (`chuck`/`maya.ns.cloudflare.com`).
`preview.cefflo.com` is **not touched**.

| Host | Serves today | Production target |
|---|---|---|
| `cefflo.com`, `www.cefflo.com` | Vercel, retirement placeholder | Unchanged (Website Master is out of scope) |
| `vendor.cefflo.com` | Vercel, retirement placeholder | Vendor Web/Desktop (static `vendor/`) |
| `tracking.cefflo.com` | Vercel, retirement placeholder | Customer Tracking (static `customer/`) |
| `invite.cefflo.com` | **NXDOMAIN** | Invitation route (`invite/`); **required for Driver onboarding** |
| `foundr.cefflo.com` | Vercel, retirement placeholder | Founder Admin (`foundr/`); internal, behind Cloudflare Access |
| `rider.cefflo.com` | Vercel, retirement placeholder | Stays retired |
| `preview.cefflo.com` | Cloudflare, Vendor preview | **Do not touch** |

Cut-over, after G7 only:

1. **Record.** Export the current Cloudflare DNS records for the 4 hosts
   (type, target, proxy flag, TTL) into the release log. This is the rollback
   source.
2. **Build.** `scripts/build-static.mjs` with the Production env (publishable
   key only; never a secret key or DB URL). Deploy to one Cloudflare Pages
   project per host, or one project with per-host routes. Verify on the
   `*.pages.dev` URLs first.
3. **Attach.** Add each custom domain in Pages; this creates a proxied CNAME to
   the Pages project. For `invite` this is a new record. For `vendor`,
   `tracking` and `foundr` it replaces the Vercel record.
4. **Verify.** HTTPS 200, the correct surface on each host, the tracking link
   from a G7 order, and the invite link.
5. **Rollback.** Restore the recorded record values (DNS changes take effect
   within minutes when proxied). For `invite`, delete the record. Remove the
   Vercel projects only after a stable period.

## 7. Monitoring (launch minimum)

| Need | Mechanism | Class |
|---|---|---|
| Backend/function failures | Supabase Logs (Postgres, API, Edge Functions) plus a function error-rate check | REQUIRED FOR LAUNCH (enable, and name a reviewer) |
| Auth failures | Supabase Auth logs | REQUIRED FOR LAUNCH |
| Delivery workflow failures | `delivery_events` (issue/recovery), Vendor Need Attention | Exists |
| Tracking failures | Invalid-lookup telemetry, rate-limit counters | Exists |
| Deployment failures | Cloudflare Pages deploy status | REQUIRED FOR LAUNCH (with Pages) |
| Alerting, APM, uptime pings | — | POST-LAUNCH IMPROVEMENT |

## 8. Native mobile (Founder decision 2026-09-27: Android + iOS)

| Target | State |
|---|---|
| Vendor Android | Project existed (`0950f2f`). Release manifest was missing INTERNET, now fixed (PR #12). Release APK builds (82.5 MB) with package `com.cefflo.cefflo_vendor_mobile`, label "Cefflo Vendor", deep link `cefflo-vendor://auth-callback`. **Store signing not configured** (debug-signed). |
| Driver Android | Created (PR #12). Release APK builds (59.5 MB) with `com.cefflo.cefflo_rider_mobile`, label "Cefflo Driver", INTERNET + fine/coarse location, deep link `cefflo-driver://auth-callback`. Store signing not configured. |
| Vendor iOS | Created (PR #12). Bundle `com.cefflo.vendor` (Android `com.cefflo.cefflo_vendor_mobile`), display "Cefflo Vendor", camera/photo usage strings, URL scheme `cefflo-vendor`. **Build/archive needs macOS + Xcode.** |
| Driver iOS | Created (PR #12). Bundle `com.cefflo.driver` (Android `com.cefflo.cefflo_rider_mobile`), display "Cefflo Driver", location/camera/photo usage strings, URL scheme `cefflo-driver`. **Build/archive needs macOS + Xcode.** |

- **Identifiers (final, 2026-09-27):**
  - Android: `com.cefflo.cefflo_vendor_mobile` and `com.cefflo.cefflo_rider_mobile`
    (kept).
  - iOS: `com.cefflo.vendor` and `com.cefflo.driver`.

  iOS forbids `_`, so the iOS IDs cannot mirror the Android ones. Nothing is
  registered yet, and all four are permanent once published.
- **Remaining for stores:**
  - **Android:** Google Play Console account, an upload keystore (`key.properties`
    outside git) and `signingConfigs.release`, an AAB build, a store listing,
    and privacy/support URLs.
  - **iOS:** Apple Developer Program membership, App IDs for the confirmed
    bundle IDs, a distribution certificate and provisioning profiles, an App
    Store Connect record, and an archive/upload from macOS/Xcode.
- **Production build configuration:** `--dart-define`s `CEFFLO_ENVIRONMENT=production`,
  `SUPABASE_URL=https://lmaxtrubwdniovxyuqdy.supabase.co` and the production
  publishable key. Never a secret key.
- **Background location:** not included (D-66, foreground only).

## 9. Production write gate (single Founder approval)

| # | Mutation | Why | Target | Risk | Verification | Recovery |
|---|---|---|---|---|---|---|
| 1 | G1 fresh backup / PITR point + G2 privileged read-only inspection | Migrations are forward-only; public probes do not prove full state | Prod DB (read) | None | Restore point recorded; G2 diff only the 53 pending | — |
| 2 | Apply migrations 202608270001 → 202609270002 (53) | Production is at foundation only | Prod DB | High (schema, RLS, backfill) | G5 | Restore point or forward fix |
| 3 | Custom SMTP, email templates, Site URL, redirect allowlist | Built-in mailer is rate-limited; native recovery links | Prod Auth | Medium | Recovery and verification email received | Revert settings |
| 4 | `tracking-pod` `CEFFLO_TRACKING_CORS_ORIGINS=https://tracking.cefflo.com` | POD photo on the hosted tracking page | Prod function secret | Low | POD thumbnail loads on `tracking.cefflo.com` | Revert secret |
| 5 | Deploy `geocode-order` plus `CEFFLO_MAPBOX_ACCESS_TOKEN` (required) | Coordinates for coverage, planning and ETA | Prod functions | Low | New order resolves location | Undeploy / unset |
| 6 | Production smoke test (G7, on `*.pages.dev` hosts) with TEST-ONLY accounts | Release proof | Prod | Low (test rows) | Full lifecycle passes | Clean TEST-ONLY rows |
| 7 | Cloudflare Pages project; DNS `vendor`, `tracking`, `invite`, `foundr` → Pages (G8, after GO) | Serve canonical web surfaces | Cloudflare | Medium (reversible) | HTTPS 200 and smoke test | Restore recorded records |
