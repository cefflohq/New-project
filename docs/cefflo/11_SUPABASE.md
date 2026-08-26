# CEFFLO --- SUPABASE / BACKEND

## S-00 Role

Supabase is the current backend direction for Cefflo.

## S-01 Areas to Verify

-   database schema/migrations;
-   Auth;
-   businesses/members;
-   riders/team access;
-   orders;
-   delivery sessions;
-   assignments;
-   stops;
-   append-only events;
-   rider locations;
-   tracking tokens;
-   ratings;
-   POD storage/access;
-   RPC/server mutations;
-   Realtime;
-   Edge Functions;
-   security events/rate limits where implemented.

## S-02 Migrations

Git-tracked migrations are the intended schema history. Never apply a
production migration without Founder approval. Avoid unversioned
production-only schema drift.

## S-03 RLS

Use least privilege. Verify role-specific access and negative cases. Do
not rely on client-side hiding for authorization.

## S-04 Mutations

Sensitive lifecycle/data mutations should use protected canonical
paths/RPC/server functions where architecture requires. Avoid direct
client mutations that bypass business rules.

## S-05 Auth

Production auth must not use mock OTP/auth flows. Re-verify current
phone/SMS provider/config; historical state indicated phone auth was not
operational.

## S-06 Realtime

Use only where needed for operational updates. Authorization/data
exposure must remain correct.

## S-07 Storage/POD

Sensitive POD assets should not be unrestricted public objects. Use
private/protected storage and signed/controlled access as designed.

## S-08 Tracking

Public tracking must be tokenized, minimal and rate-limited where
appropriate.

## S-09 Environment Separation

Keep preview/test and production configuration separated. Never commit
secrets.

## S-10 Backup/Recovery

Stage 4 requires explicit verification of available database
backup/recovery strategy and rollback implications.

## S-11 Stage 4 Gate

Schema, RLS, auth, lifecycle mutations, tracking/POD and relevant
negative/E2E tests pass for approved scope before production release.
