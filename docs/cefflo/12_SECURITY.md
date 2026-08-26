# CEFFLO --- SECURITY

## SEC-00 Principle

Secure by default, least privilege, minimum public exposure, auditable
privileged actions.

## SEC-01 Authentication

No mock production auth. Verify session handling, role/business
membership and provider readiness.

## SEC-02 Authorization

Backend authorization/RLS is authoritative. Client UI is not a security
boundary.

## SEC-03 Public Tracking

Use high-entropy/protected tokens, minimum exposed data, rate limiting
and controlled mutation endpoints.

## SEC-04 POD

Protect storage and access. Avoid public predictable paths.

## SEC-05 Browser/PWA

Verify appropriate CSP, HSTS and other security headers in production
architecture. Avoid unnecessary PII in insecure local storage.

## SEC-06 Secrets

Never commit API keys, service-role keys, credentials or production
secrets. Use environment/secret stores.

## SEC-07 FOUNDR

Privileged actions require strong authorization, confirmation/reason
where appropriate and audit logging.

## SEC-08 Rate Limiting / Abuse

Protect public and sensitive endpoints according to risk. Cloudflare
and/or backend controls may participate; verify actual architecture.

## SEC-09 Logging

Security events and admin audit events should be useful without logging
secrets/sensitive payloads unnecessarily.

## SEC-10 Negative Testing

Test unauthorized actor, cross-business access, invalid token, invalid
transition, storage access and other relevant abuse cases.

## SEC-11 Protected Changes

Material auth/RLS/security policy changes and disabling controls require
Founder approval before execution.

## SEC-12 Incident/Recovery

Stage 4 should define how to detect, contain, rollback and investigate
critical security/production incidents.
