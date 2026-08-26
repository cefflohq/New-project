# CEFFLO --- VERCEL

## VE-00 Role

Vercel is the current web deployment direction.

## VE-01 Deployments

Map each production/preview deployment to the canonical GitHub source
and client surface.

## VE-02 Environments

Verify preview vs production environment variables and backend
endpoints. Never expose server-only secrets to browser bundles.

## VE-03 Domains

Coordinate Vercel domain configuration with `14_CLOUDFLARE.md`.

## VE-04 SOT

A live Vercel page is evidence of deployment state, not permission to
ignore GitHub SOT. Phase 1 must map deployment commit/source to repo.

## VE-05 Preview

Use preview deployment for material frontend/integration validation
before production where practical.

## VE-06 Release

Normal releases should minimize interruption. Coordinate PWA
version/cache behaviour with `15_PWA.md`.

## VE-07 Rollback

Know how to identify last known-good deployment and rollback safely.
Backend compatibility must be considered before frontend rollback.

## VE-08 Health

Verify critical routes/assets/API connectivity after deployment.

## VE-09 Protected Actions

Production project/domain/environment changes may be
infrastructure-sensitive; follow Founder approval boundaries.

## VE-10 Stage 4 Gate

Every required client resolves to the intended production deployment,
uses correct environment configuration and has tested rollback/smoke
procedures.
