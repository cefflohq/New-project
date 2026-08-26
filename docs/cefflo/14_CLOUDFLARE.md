# CEFFLO --- CLOUDFLARE / DOMAIN / EDGE

## CF-00 Role

Cloudflare covers Cefflo domain/DNS/edge controls where configured.

## CF-01 Domain Map

Target names: - `cefflo.com` - `vendor.cefflo.com` -
`rider.cefflo.com` - `track.cefflo.com` - `foundr.cefflo.com` -
`api.cefflo.com` only if architecture requires it.

Phase 1 must verify actual records and ownership.

## CF-02 DNS

Document record type, target, proxy status and purpose for each
production hostname. Avoid stale/duplicate records.

## CF-03 SSL/TLS

Use valid HTTPS end-to-end. Verify SSL/TLS mode and certificate
behaviour appropriate to origin architecture.

## CF-04 Proxy/Cache

Do not cache dynamic/authenticated/API content incorrectly. Coordinate
PWA/static caching with app/Vercel rules.

## CF-05 Edge Security

Where used, document WAF, bot/abuse, rate-limit and security rules. Do
not duplicate/conflict with backend controls blindly.

## CF-06 API/Tracking

Public tracking/API protection may use edge controls, but backend
authorization remains authoritative.

## CF-07 DNS Changes

Production DNS/domain changes require Founder approval before execution.

## CF-08 Recovery

Know how to revert bad DNS/edge changes and identify expected
propagation/health checks.

## CF-09 Stage 4 Gate

All required hostnames resolve correctly over HTTPS to intended services
with no stale/conflicting DNS and with appropriate edge/security
behaviour.
