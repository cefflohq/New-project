# CEFFLO Backend Wiring — Phase 2A Foundation Status

**Date:** 2026-09-25

**Status:** COMPLETE WITH EXTERNAL STAGING LIMITATION (D-60). All Phase 2A
foundation checks pass except the Driver sign-up and in-app recovery request
screens, which are blocked only by the staging Supabase built-in email rate
limit (HTTP 429, mapped truthfully in both apps).

## Implemented

- Driver email/password sign-in now calls Supabase Auth through
  `RiderRepository` before entering the authenticated shell.
- Driver account creation, password-reset request and recovery-password update
  now have repository adapters and surface backend failures truthfully.
- Auth provider error codes are mapped to stable, user-facing copy.
- Account creation creates Auth identity only. It does not create or approve a
  `riders` relationship.
- Existing relationship hydration remains the authority for Driver stage and
  active business/rider context.
- Prototype mode remains local and does not require Supabase.
- The shared auth inline prompt now wraps safely at the required 393×852 phone
  viewport; its content and visual treatment are unchanged.

## Verification completed

- All 51 tracked migrations applied on the disposable local Supabase stack.
- Backend inventory validation: PASS.
- RLS scope regression: PASS.
- Rider scope regression: PASS.
- Multi-business Driver context: PASS.
- Rider invitation contract: PASS.
- Rider-location backend contract: PASS.
- Driver `flutter analyze`: PASS.
- Driver tests: 2/2 PASS.
- Driver prototype web build: PASS.
- Driver local-backend web build: PASS.
- Driver D03/D04/D05/D07 inspected at 393×852: no overflow or clipping.
- Vendor `flutter analyze`: PASS.
- Vendor tests: 99 PASS; 11 live staging tests skipped because staging
  configuration was not supplied.
- Vendor prototype web build: PASS.
- Vendor local-backend web build: PASS.
- Staging target identity guard: PASS for `tomvvmwktehexwhktenw`; connection
  was read-only and the known Production project was not targeted.
- Staging backend schema/RLS/RPC/storage contract: PASS.
- Vendor anonymous live staging contracts: 11/11 PASS. This verifies RLS and
  deployment of the planning/dispatch RPC surface without persisting data.
- Driver anonymous live staging contracts: 11/11 PASS. This verifies Rider
  read isolation and deployment of assignment, Run, lifecycle and issue RPCs
  without creating an identity, uploading POD or persisting data.
- Driver `flutter analyze` after the live contract addition: PASS.
- Driver local tests after the live contract addition: 2/2 PASS.
- Customer Tracking staging build: PASS in an isolated temporary directory;
  staging ref was embedded, the Production ref and database URL were absent,
  and temporary output was deleted.
- Customer cross-app issue/tracking wiring tests: 32/32 PASS.
- Customer invalid-token `public_tracking` contract: PASS as part of the
  staging backend validation.

## Continuation run — 2026-09-25

Staging test identities were still absent from the local environment file
(`STAGING_VENDOR_*` and `STAGING_DRIVER_*` keys not present), so every
authenticated journey remains blocked. Verification that does not need them:

- Driver `flutter analyze`: PASS; local tests 2/2 PASS; anonymous live staging
  contracts 11/11 PASS.
- Vendor `flutter analyze`: PASS; local tests 99 PASS; anonymous live staging
  contracts 11/11 PASS.
- Prototype (`CEFFLO_UI_PROTOTYPE=true`) release web builds: PASS for both.
- Staging-configured **release** web builds: PASS for both. Each bundle embeds
  the staging ref only; the Production ref, any Postgres/pooler URL and
  `DATABASE_URL` are absent. Build input carried only the environment name, URL
  and publishable key. Build output was deleted afterwards.
- Real staging browser check at 393×852 (both release builds): entry screen and
  Continue with Email render with no console errors. A sign-in with a
  non-existent `example.invalid` address called staging `POST /auth/v1/token`,
  got HTTP 400, and showed the mapped copy "Email or password is incorrect. Try
  again." No overflow or clipping. A failed sign-in creates no identity or row.
- Customer `tests/s4_04_batch_5_customer_ondemand_refresh.py`: 15/15 PASS on
  `claude/customer-tracking-pwa`. The four UI assertions for the retired inline
  refresh button and freshness chrome now assert the approved C1-C4 state
  (`tracking-adapter.js` keeps `setFreshness` as a documented no-op). Backend
  refresh, guard and freshness-call assertions are unchanged. No UI was changed.

## Authenticated qualification — 2026-09-25 (D-59)

### Fixtures (staging `tomvvmwktehexwhktenw` only)

- 6 confirmed TEST-ONLY Auth identities created with the Auth admin API
  (Vendor A, Vendor B, Driver none, Driver pending, Driver one-active, Driver
  multi-active). Credentials were generated locally into the mode-600 env file
  and never printed.
- Business A and Business B (`TEST-ONLY Phase2A Business A/B`) plus one owner
  membership each, created as approved fixtures (no product flow creates a
  business).
- Driver relationships created only through the canonical RPCs, signed in as
  the test users: `create_rider_invitation` → `accept_rider_invitation` →
  `approve_pending_rider`. Result: pending (A), active (A), active (A + B).
- One real Vendor sign-up identity created through the Vendor app (unconfirmed,
  awaiting email verification).
- The legacy web `vendor/` and `invite/` pages build and serve locally against
  staging from an isolated copy (public config only).

### Authenticated API contract: 53/53 PASS

Refresh-token session restore; `get_my_businesses` returns exactly the own
business for each Vendor; own business readable; cross-business reads of
`businesses`, `business_members`, `riders`, `orders`, `zones`, `products`,
`delivery_sessions`, `rider_invitations` return empty for both Vendors;
cross-business invitation rejected; Vendor A sees exactly its 3 test riders;
each Driver identity sees exactly its expected relationships and no other
rider rows; Driver cross-business reads empty; multi-active Driver resolves
both businesses; tampered JWT rejected; recovery request accepted (2); sign-out
revokes the refresh token.

### Browser flows at 393×852 on staging release builds

| Flow | Vendor | Driver |
|---|---|---|
| Sign-in (real `/auth/v1/token`) | PASS — Business A / B from real data | PASS |
| Stage landing | n/a | PASS after fix — none → No Business Connected; pending → Pending Review |
| Active business context | PASS — switcher lists only own business (owner) | Active state shows DemoData Today surface (open) |
| Session restore on reload | PASS | PASS |
| Sign-out | PASS — `logout` 204, session cleared, stays signed out | PASS after fix |
| Expired / corrupted session | PASS — refresh 400, returns to entry, session cleared | PASS |
| Real sign-up | PASS — `signup` 200 → "Verify your email" | Blocked — staging email rate limit (429), truthful error shown |
| Recovery request | API PASS; in-app request hit rate limit (429), truthful error shown | API PASS |
| Invalid credentials | PASS | PASS |

### Defects found and status

- FIXED (Driver `feedff9`): real sessions ignored the hydrated stage and
  landed on the demo Today stack; Log Out never revoked the Supabase session;
  the prototype "simulate approval" link rendered in the real build.
- FIXED (Vendor): Riders list showed a pending rider as "Offline" and the
  Offline filter included pending riders. Pending riders now show "Pending"
  (existing warning chip) and appear only under All and Pending. Verified on
  staging at 393×852 with the TEST-ONLY riders.
- PHASE 2B BACKLOG (D-60): active Driver Today real-data wiring (DemoData
  greeting, business row, date, counters, current run).
- PHASE 2B BACKLOG (D-60): explicit multi-business Driver selection; today the
  first returned active relationship is used, `selectRelationship` has no
  screen, and the relationship query has no stable order.
- PHASE 2B BACKLOG (D-60): Pending Review "Submitted" ticks are static display
  only; they write nothing and assert no backend success.
- OPEN (backend/product): no business-creation flow exists.
- ENV: staging uses the built-in Supabase mailer; its hourly email limit
  blocks repeated sign-up/recovery UI runs.

## Final Phase 2A result (D-60)

- Driver: analyze PASS; tests 7/7 PASS; anonymous live staging 11/11 PASS.
- Vendor: analyze PASS; tests 102 PASS (adds rider-status regression);
  anonymous live staging 11/11 PASS.
- Authenticated staging API contract: 53/53 PASS.
- Prototype and staging release web builds: PASS for both apps; bundles carry
  the staging ref only, with no secret key, database URL or test credential.
- Real-data browser flows at 393×852: PASS except the carried email checks.
- TEST-ONLY Phase2A staging fixtures are retained for Phase 2B and regression.

### Carried into the next staging regression run

1. Driver real sign-up through the app (last result: `signup` 429).
2. Vendor in-app recovery request (last result: `recover` 429).
3. Driver in-app recovery request.

Re-run them only after the built-in mailer limit has reset; no SMTP or
infrastructure change is authorized.

## Historical gate (superseded by the result above)

The staging project and public/runtime configuration are now available through
a local mode-600 environment file outside Git. No authorized Vendor or Driver
test identity has been supplied. Anonymous contract probes prove deployment
and denial behavior, but cannot prove authenticated hydration, session or
cross-business behavior in the Flutter clients.

Before Phase 2A can be declared complete, run the guarded live contract suite
and these flows against staging:

1. Vendor signup/sign-in/recovery and `get_my_businesses` under an authorized
   Vendor identity.
2. Driver sign-in/recovery with no relationship, pending relationship, one
   active relationship and multiple active relationships.
3. Cross-business negative reads for Vendor and Driver identities.
4. Session restore, sign-out and expired-session handling in both Flutter apps.
5. Release-mode web builds configured for staging, followed by 393×852
   screenshots of the affected real-data states.

Staging metadata/contracts were read, but no staging data was created, changed
or deleted. No Production system was accessed, no migration was deployed and
no branch was pushed. Vendor operational wiring, authenticated Driver delivery
qualification and a valid-token Customer journey remain outside the completed
evidence in this partial Phase 2A implementation.

## Known validation debt

Resolved in the continuation run above: the Customer on-demand-refresh suite
now reflects the approved C1-C4 UI and passes 15/15.
