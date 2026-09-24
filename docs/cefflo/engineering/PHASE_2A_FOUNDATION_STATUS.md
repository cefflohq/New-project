# CEFFLO Backend Wiring — Phase 2A Foundation Status

**Date:** 2026-09-25

**Status:** PARTIAL — local qualification complete; staging qualification blocked

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

## Remaining Phase 2A gate

The host has no linked Supabase staging project, staging publishable
configuration or authorized staging test identities. The repository identifies
the expected staging project in guarded tests, but a repository reference is
not authentication and was not treated as permission or a credential.

Before Phase 2A can be declared complete, run the guarded live contract suite
and these flows against staging:

1. Vendor signup/sign-in/recovery and `get_my_businesses` under an authorized
   Vendor identity.
2. Driver sign-in/recovery with no relationship, pending relationship, one
   active relationship and multiple active relationships.
3. Cross-business negative reads for Vendor and Driver identities.
4. Session restore, sign-out and expired-session handling in both Flutter apps.
5. Production-mode web builds configured for staging, followed by 393×852
   screenshots of the affected real-data states.

No staging or production data was accessed or changed. No migration was
deployed. Vendor operational wiring, Driver delivery actions and Customer
Tracking remain outside this partial Phase 2A implementation.
