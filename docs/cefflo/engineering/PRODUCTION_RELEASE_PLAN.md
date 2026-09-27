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

- Backups and PITR **cannot be seen** with the public key. The Founder must
  verify in the Supabase Dashboard → Database → Backups:
  - the plan tier (Free has no automated backups; Pro has daily backups with
    7-day retention);
  - whether PITR is enabled.
- Migrations are **forward-only**. None has a down script, several add
  constraints or backfill data (for example 202609260001), and some change
  RLS or grants.
- **Rollback is therefore restore-from-backup/PITR, or a forward fix.** A
  schema-level "undo" is not available.
- **Required before step 3:** a fresh manual backup, or a confirmed PITR
  point, taken immediately before migration.

## 3. Release procedure

1. **PRECHECK.**
   - Founder approves the release gate.
   - Confirm backup/PITR, and record the restore point.
   - Secret-key parity inspection: out-of-band objects and row counts per
     table.
2. **Apply migrations** 1→53 in order, each in its own transaction (Supabase
   CLI `db push`, or the same `psql -1 -f` procedure used on staging), and
   record each in `supabase_migrations.schema_migrations`. **Stop at the first
   error** and do not continue.
3. **Post-migration verification.**
   - Marker probes from §1 all return 200.
   - `schema_migrations` count is 54 and matches the repo.
   - The D-64 backfill: every order has `order_date`/`order_seq`, with no
     duplicate `(business_id, order_date, order_seq)`.
4. **RLS verification:**
   - anon sees `[]` on all operational tables;
   - a second business sees none of the first business's rows;
   - `rider_live_keys` and `latest_rider_locations` refuse foreign callers;
   - `public_tracking` returns null for `#CF-xxx`, `public_ref` and the order
     UUID used as a token.
5. **Function configuration:**
   - `tracking-pod`: set `CEFFLO_TRACKING_CORS_ORIGINS=https://tracking.cefflo.com`
     (the canonical origin, `02_ARCHITECTURE.md`).
   - Deploy `geocode-order` with `CEFFLO_MAPBOX_ACCESS_TOKEN`, if Mapbox is
     approved for launch (§5).
6. **Auth configuration (§4):**
   - custom SMTP;
   - Site URL;
   - redirect allowlist `cefflo-vendor://auth-callback`,
     `cefflo-driver://auth-callback`, `https://invite.cefflo.com/**`;
   - email templates (the Vendor sign-up confirmation uses OTP code
     `{{ .Token }}`).
7. **Hosting and DNS (§6).**
8. **Smoke test** with TEST-ONLY accounts:
   - Vendor sign-in, create order (`#CF-001`), dispatch;
   - Driver (Android build against Production) accept → pickup → deliver
     with POD;
   - Customer tracking link from the order;
   - password recovery via the deep link.
9. **Rollback / recovery:**
   - Migration failure: stop, and restore from the step-1 restore point, or
     forward-fix if the failure is isolated and understood.
   - Config or DNS failure: revert that setting (DNS records are reversible;
     keep the prior values recorded).

## 4. Auth email (custom SMTP)

The repo decides **no** sender domain, sender address or provider. `supabase/config.toml`
covers local development only. Production settings needed (Supabase Auth →
SMTP):

- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_USER`
- `SMTP_PASSWORD`
- `SMTP_FROM_ADDRESS`
- `SMTP_FROM_NAME`

Founder decision required: the sender domain and address (for example on
`cefflo.com`, with SPF/DKIM/DMARC DNS records at Cloudflare) and the provider.

Native apps (done in code): password recovery redirects to
`cefflo-vendor://auth-callback` / `cefflo-driver://auth-callback`. The app
opens the existing Set New Password screen, then signs out after the update.

## 5. Geocoding (Mapbox)

- `geocode-order` reads the **server-side** secret `CEFFLO_MAPBOX_ACCESS_TOKEN`
  (Mapbox Geocoding v6, `permanent=true`). It is never in client code.
- Without it, orders are marked `location_status=failed`
  (`invalid_credentials`). Manual location entry and manual run building
  still work.
- Coverage decisions, suggested runs and ETA need coordinates, so launch
  **without** Mapbox is functional but degraded.
- Recommended token restrictions: a Mapbox secret token with geocoding scope
  only, used only from the Edge Function, and URL-restricted where Mapbox
  allows.

## 6. DNS / hosting (read-only inventory, 2026-09-27)

Authoritative nameservers: Cloudflare (`chuck`/`maya.ns.cloudflare.com`).

| Host | Serves today | Production target |
|---|---|---|
| `cefflo.com`, `www.cefflo.com` | Vercel, retirement placeholder | Public Website, once approved (D-62 NOT IMPLEMENTED); placeholder until then |
| `vendor.cefflo.com` | Vercel, retirement placeholder | Vendor Web/Desktop (static build `vendor/`) |
| `tracking.cefflo.com` | Vercel, retirement placeholder | Customer Tracking (static build `customer/`) |
| `foundr.cefflo.com` | Vercel, retirement placeholder | Founder Admin (`foundr/`); internal |
| `invite.cefflo.com` | **NXDOMAIN** | Invitation route (`invite/`). Vendor Web already issues links to this host, so it is **required for Driver onboarding** |
| `rider.cefflo.com` | Vercel, retirement placeholder | Stays retired; not the Driver app |
| `preview.cefflo.com` | Cloudflare, Vendor preview | Keep; preview infrastructure |
| `api.cefflo.com`, `app.cefflo.com` | NXDOMAIN | Not required (clients talk to Supabase directly) |

- Minimum plan: host the canonical static build (`scripts/build-static.mjs`
  with production env) on Cloudflare Pages. Then repoint `vendor`,
  `tracking`, `invite` and `foundr` from Vercel to Pages.
- Record prior DNS values for rollback. Remove Vercel records only after
  Pages is verified.
- Native Vendor/Driver apps need no web host, only the auth redirect schemes
  above and public privacy/support URLs for the stores.

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
| Vendor iOS | Created (PR #12). Bundle `com.cefflo.ceffloVendorMobile`, display "Cefflo Vendor", camera/photo usage strings, URL scheme `cefflo-vendor`. **Build/archive needs macOS + Xcode.** |
| Driver iOS | Created (PR #12). Bundle `com.cefflo.ceffloRiderMobile`, display "Cefflo Driver", location/camera/photo usage strings, URL scheme `cefflo-driver`. **Build/archive needs macOS + Xcode.** |

- **Identifiers.** Package and bundle IDs follow the repo's existing `com.cefflo` org
  convention and are **PROVISIONAL**. No Founder-approved IDs exist in the
  repo. They must be confirmed (or replaced) before the first store upload,
  because they are permanent once published.
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
| 1 | Fresh backup / PITR restore point | Migrations are forward-only | Prod DB | None | Restore point recorded | — |
| 2 | Apply migrations 202608270001 → 202609270002 (53) | Production is at foundation only | Prod DB | High (schema, RLS, backfill) | §3 steps 3–4 | Restore point or forward fix |
| 3 | Custom SMTP, email templates, Site URL, redirect allowlist | Built-in mailer is rate-limited; native recovery links | Prod Auth | Medium | Recovery and verification email received | Revert settings |
| 4 | `tracking-pod` `CEFFLO_TRACKING_CORS_ORIGINS=https://tracking.cefflo.com` | POD photo on the hosted tracking page | Prod function secret | Low | POD thumbnail loads on `tracking.cefflo.com` | Revert secret |
| 5 | Deploy `geocode-order` plus `CEFFLO_MAPBOX_ACCESS_TOKEN` (if approved) | Coordinates for coverage, planning and ETA | Prod functions | Low | New order resolves location | Undeploy / unset |
| 6 | Cloudflare Pages project; DNS `vendor`, `tracking`, `invite`, `foundr` → Pages | Serve canonical web surfaces | Cloudflare | Medium (reversible) | HTTPS 200 and smoke test | Restore recorded records |
| 7 | Production smoke test (§3 step 8) with TEST-ONLY accounts | Release proof | Prod | Low (test rows) | Full lifecycle passes | Clean TEST-ONLY rows |
