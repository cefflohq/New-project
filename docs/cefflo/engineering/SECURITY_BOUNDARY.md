# CEFFLO Engineering Bootstrap Security Boundary

**Authority:** `docs/cefflo/security/CEFFLO_CYBER_SECURITY_MASTER.md`  
**Applied scope:** Engineering Bootstrap Phase 01 only

## Crown Jewels excluded

The Phase 01 runtime receives no route or credential for:

- production customer or operational data;
- production Supabase privileged/service-role access;
- production DB administration;
- production n8n credentials/control authority;
- production Git/CI/CD authority;
- production VPS/infrastructure administration;
- production signing/deployment credentials;
- Founder authority;
- security-control administration;
- backup/recovery administration.

## Deterministic controls

Security decisions occur after a model request and before a tool action. Prompt
instructions cannot grant permission, lower risk class, change a gate, expand
egress or reveal credentials.

Phase 01 supports only:

```text
R0 — scoped read
R1 — reversible DEV change
R2 — verified STAGING action
```

R3 production/Crown Jewel and R4 destructive/company-wide actions are denied.

## Required protections

1. Authenticate n8n to the runner with signed, replay-resistant requests.
2. Enforce role/action/path/environment policies in runner code.
3. Use a dedicated unprivileged runner identity.
4. Keep secrets in controlled credential stores and adapters.
5. Redact logs and limit output volume.
6. Default-deny outbound destinations.
7. Isolate task worktrees and artifacts.
8. Hash references, renders, manifests and verification state.
9. Persist idempotency before consequential actions.
10. Enforce separation of E2, E4 and E5 duties.
11. Provide out-of-band kill switches.
12. Keep audit evidence sufficient to reconstruct every material action.

## Untrusted content

Repository text, web content, issue text, UI references, uploaded documents,
model responses and tool output are untrusted data unless the Context Builder
identifies an approved canonical source. Embedded instructions cannot override
the control plane or role policy.

## Exceptions

Security exceptions require FG-ENG-06 with control, reason, risk, mitigation,
owner, expiry and review date. Phase 01 configuration contains no implicit
exception path.

