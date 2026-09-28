# Staging Verification & Production Readiness Prep — 2026-09-27

- **Baseline:** `claude/canonical-integration` @ `ec9fb64`.
- **Target:** staging `tomvvmwktehexwhktenw` only.
- **Production:** untouched. There were no Production reads or writes.

**Method:**

- Real staging identities from the staging env file, using the publishable
  key and user sessions, so RLS is in force.
- New rows are labelled `[TEST]`.
- The secret key was used only for one fixture step: confirming the email of
  the two dedicated signup test identities, because staging requires email
  confirmation and has no test inbox. It was never used for an assertion.

## Results

| Area | Check | Result |
|---|---|---|
| Vendor auth | sign-in (A, B); invalid credentials → HTTP 400 "invalid"; sign-out revokes | PASS |
| Vendor auth | signup accepts `cefflo-vendor://auth-callback`; requires confirmation | PASS |
| Vendor auth | resend with app redirect; password change persists (restored) | PASS |
| Business | `bootstrap_business` creates the business; caller is `owner`; the real address persists; **no origin preset** (null) | PASS |
| Pickup origin | `geocode-order` `business_id` mode on staging | **BLOCKED**: function not deployed (HTTP 404) |
| Coverage | `set_business_service_area` persists; re-read shows server state; a null origin is rejected (no silent default) | PASS |
| Invitations | rider invite returns a one-time token; stored as hash only; team invite (owner) | PASS |
| Driver | signup with `cefflo-driver://auth-callback`; `resolve_rider_invitation` exposes only business name/status | PASS |
| Driver | `accept_rider_invitation` → relationship to the correct business, `pending` | PASS |
| Driver (active fixture) | reads only orders assigned to own rider rows; `rider_live_keys` for own rider | PASS |
| Tracking | anonymous `public_tracking` with a valid token; no PII or internal ids; no location before pickup; no POD before delivery; forged token → null; `tracking-pod` refuses undelivered | PASS |
| Isolation (Vendor) | Vendor B cannot read or modify Vendor A's business, service area, invitations, riders, orders or members | PASS |
| Isolation (Driver) | invitation email-bound; forged token rejected; cannot read an unrelated business or its orders; `record_rider_location` / `rider_live_keys` refused for foreign ids | PASS |
| Isolation (anon) | no orders, no `rider_locations` | PASS |
| Flutter staging contracts | Vendor 11/11, Driver 11/11 | PASS |

**Totals:** E2E script 43 PASS / 0 FAIL / 2 BLOCKED; active-driver script
8/8 PASS.

**Note: the `businesses_rider` policy (202608290004) is intentional.** A
driver with a relationship to a business, including a pending one, can read
that business's row. The Driver app needs it for the business name. The
policy is row-scoped, not column-scoped, so the related business's
phone/email/address are readable too. This is **P1 hardening**, not a
tenant leak: unrelated businesses are not readable.

### Pickup origin: blocked items and required actions

The `geocode-order` `business_id` mode is covered by Vendor widget tests:

- a real origin is saved;
- the unlocatable state shows "pickup location required" and saves nothing;
- a saved origin is kept.

It is also covered by the pure-logic Node tests (30). It cannot be exercised
end-to-end on staging until:

1. a Supabase **access token** (`sbp_…`) is available for a staging deploy
   (`supabase functions deploy geocode-order --project-ref tomvvmwktehexwhktenw`);
2. `CEFFLO_MAPBOX_ACCESS_TOKEN` is set as a staging function secret.

The staging project secret key cannot deploy functions.

## Stale tests fixed

Both expectations were superseded, with no runtime change:

- **`f3_02_recent_orders_dashboard`:** asserted `<b>${o.id}</b>`. Since D-64
  the row shows `orderNo(o)` (`#CF-001`). The test now asserts that, and that
  the raw id is not the label.
- **`s4_04_batch_5_customer_ondemand_refresh`:** asserted the removed 3 s
  drop-cooldown. D-66's coalescing gate (in-flight → one follow-up, ≥ 10 s
  between fetch starts) is stricter. The test now asserts the gate.

## Release builds

- **Android:**
  - Release AABs build: Vendor 81.9 MB and Driver 59.1 MB.
  - Packages are `com.cefflo.cefflo_vendor_mobile` and
    `com.cefflo.cefflo_rider_mobile`.
  - Release signing reads `android/key.properties`, which is git-ignored.
    **No upload keystore exists**, so builds are debug-signed and not
    store-uploadable.
  - The builds verified here used staging defines. A store build needs
    `CEFFLO_ENVIRONMENT=production` plus the Production URL and publishable
    key; the env guard refuses any mismatch.
- **iOS:**
  - Bundle ids are `com.cefflo.vendor` and `com.cefflo.driver` (tests
    `.RunnerTests`).
  - Archiving needs macOS + Xcode, an Apple Developer membership, App IDs,
    a distribution certificate and provisioning profiles.

## Production read-only inspection (prepared, not run)

`scripts/production-inspection/`:

- `inspect.sql` runs in a read-only transaction.
- `run-readonly-inspection.sh` also forces a read-only session.
- `README.md` holds the procedure.

The staging baseline snapshot is
`evidence/STAGING_SCHEMA_BASELINE_2026-09-27.txt`: 54 migrations, `pg_cron`
installed, 3 buckets. The Production diff against it answers:

- the migration gap (actual number);
- `pg_cron`;
- out-of-band buckets;
- the order count before D-64;
- RPC and RLS presence;
- drift.

## Founder actions

1. **Supabase:**
   - confirm backups/PITR (Database → Backups) and record the restore point;
   - issue a **read-only** Production DB credential for the inspection;
   - optionally, provide an access token (staging) for the `geocode-order`
     staging deploy.
2. **SMTP:**
   - choose a provider (for example Resend, Postmark or SES);
   - sender `Cefflo <no-reply@cefflo.com>`, support `support@cefflo.com`;
   - later: SPF/DKIM/DMARC, Supabase SMTP settings, Site URL, redirect
     allowlist, and verifying signup, reset and OTP emails.
3. **Mapbox:**
   - account with Permanent Geocoding;
   - geocoding-only token;
   - set as function secret `CEFFLO_MAPBOX_ACCESS_TOKEN` (staging first, then
     Production at the write gate).
4. **Cloudflare / DNS (at GO only):**
   - `vendor`, `tracking`, `invite`, `foundr` → Pages;
   - `invite.cefflo.com` is required for Driver onboarding.
5. **Stores:**
   - Google Play Console + an upload keystore (`key.properties` kept outside
     git);
   - Apple Developer + a Mac for archive/signing;
   - store listings and privacy/support URLs.
