# CEFFLO Backend Wiring — Phase 2A Foundation Status

**Date:** 2026-09-25

**Status:** PARTIAL — local and anonymous staging qualification complete;
authenticated staging journeys blocked on dedicated test identities

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

## Remaining Phase 2A gate

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
