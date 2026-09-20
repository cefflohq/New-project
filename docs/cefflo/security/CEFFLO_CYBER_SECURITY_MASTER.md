# CEFFLO CYBER SECURITY — MASTER SPECIFICATION

**Status:** MASTER BASELINE  
**Date:** 2026-09-19  
**Scope:** Company-wide product, infrastructure, data, software supply-chain, AI/agent security, continuous threat intelligence, vulnerability management, incident response, and recovery.  
**Owner / Final Authority:** Founder  
**Enforcement:** Technical controls + CEFFLO Control Layer governance + n8n execution engine + department workflows + infrastructure policy
**Role:** Cross-company security architecture — **not a sixth department and not an AI super-agent**.

---

## 0. Mission

CEFFLO Cyber Security protects CEFFLO products, infrastructure, data, users, software supply chain, and AI/agent systems while allowing the company to ship efficiently.

Security must not depend on an AI model behaving correctly.

> **AI may request an action. Security controls decide whether the action is allowed.**

> **Assume external content is untrusted. Compromise one component; do not compromise the company.**

> **Security intelligence stays current; security architecture stays controlled.**

---

## 1. Protected Surfaces

Product surfaces:
- Vendor Flutter App
- Driver Flutter App
- Vendor Web/Desktop
- Customer Tracking PWA
- Public Website
- Founder Command Center

Backend and data:
- APIs, Supabase, PostgreSQL, Auth, RLS, Storage, Realtime, webhooks, server functions/services

Infrastructure:
- VPS, Ubuntu/Linux, Docker, reverse proxy/TLS, n8n, CI/CD, DNS, backups, object storage

Development/supply chain:
- GitHub, branches/PRs, Flutter/Dart packages, npm/Node where used, Docker images, CI actions/plugins, SDKs, MCP servers/tools

AI/agents:
- model providers, prompts, context retrieval, memory, tools, permissions, autonomous workflows, events, model/API credentials

---

## 2. Security Domains

```text
CEFFLO CYBER SECURITY
├── Identity & Access
├── Application Security
├── API Security
├── Data / Database Security
├── Infrastructure / Network Security
├── Secrets & Key Management
├── Software Supply Chain
├── Malware / File Security
├── AI & Agent Security
├── Logging / Detection
├── Threat Intelligence
├── Vulnerability Management
├── Incident Response
├── Backup / Disaster Recovery
├── Security Testing
└── Governance / Founder Gates
```

---

## 3. Environment Isolation

```text
DEVELOPMENT → STAGING → PRODUCTION
```

Where practical:

```text
DEV credentials ≠ STAGING credentials ≠ PRODUCTION credentials
DEV database    ≠ STAGING database    ≠ PRODUCTION database
DEV permissions ≠ PRODUCTION permissions
```

Production authority is technically enforced, never inferred from an AI prompt.

---

## 4. Identity, Authentication & Least Privilege

Every human, service, workflow, agent tool and deployment identity receives only required permissions. Avoid shared omnipotent credentials.

Use MFA/passkeys where supported for privileged humans, secure session/token handling, revocation, protected reset flows, scoped service identities, and environment-specific permissions.

Agents cannot grant themselves permissions.

Authentication proves identity; authorization determines permitted actions.

---

## 5. Authorization & Supabase RLS

Client applications are untrusted. Hiding a UI control is not authorization.

Sensitive authorization is enforced server-side. For Supabase/PostgreSQL:
- use appropriate RLS and least privilege;
- default-deny sensitive data where practical;
- separate vendor/driver/customer/admin access;
- protect service-role credentials;
- audit policy changes;
- test positive and negative paths.

Required tests include:

```text
Vendor A cannot read Vendor B data.
Driver A cannot access unrelated Driver B runs.
Customer tracking cannot expose unrelated deliveries.
Normal vendor cannot perform Founder/Admin actions.
Unauthenticated client cannot bypass server policy.
```

---

## 6. API / Input / Web Security

APIs enforce authentication, authorization, schema/type validation, rate controls where appropriate, request limits, safe errors, idempotency and audit logging.

Never trust client-supplied role, vendor ID, permission, price, or completion state without server validation.

External forms, notes, uploads, URLs, webhooks, CSVs, email, support messages, CRM fields, AI output, retrieved web content and third-party API payloads are untrusted.

Web/PWA controls include HTTPS, secure headers, CSP where practical, secure cookies, CSRF controls where applicable, XSS prevention, safe DOM rendering, origin/CORS controls, safe service-worker caching and no secrets in frontend bundles.

---

## 7. Flutter / Mobile Security

Assume mobile clients can be inspected or modified.

- no privileged backend secrets in app bundles;
- secure token handling;
- minimize sensitive local storage;
- enforce permissions server-side;
- secure deep links;
- protect signing material;
- production-safe logging;
- dependency monitoring;
- release integrity checks where appropriate.

Obfuscation is not an authorization boundary.

---

## 8. Data / Database Security

Use least-privilege DB roles, RLS where applicable, encrypted transport, secure backups, restricted backup access, reviewed migrations, retention controls, data minimization and auditable privileged operations.

Do not casually copy production customer data into development.

---

## 9. Secrets Management

Secrets belong in controlled credential stores/environment/vaults.

```text
SECRET → controlled store → controlled tool → action
```

Never:

```text
SECRET → prompt → model context → logs
```

Never commit secrets to Git or embed privileged keys in Flutter/PWA. Rotate exposed credentials and separate environments.

---

## 10. Network, VPS & n8n Security

Restrict inbound services, database exposure and administrative interfaces. Use TLS, firewalls, SSH hardening, least privilege, service isolation, supported security updates, monitoring and backups.

n8n is a high-value control-plane asset. Protect editor/admin access, credentials, webhook endpoints, execution data, environment variables, workflow modification and production activation.

Use authenticated/signed webhooks where applicable, validated payloads, idempotency, retry limits, cost limits, Founder Gates and restricted production actions.

---

## 11. GitHub & Supply-Chain Security

Use MFA/passkeys where supported, protect critical branches, scan secrets, monitor dependency/security advisories, minimize CI/token permissions and review third-party CI actions/plugins.

Maintain inventory of dependencies, Docker images, CI actions, MCP servers, SDKs and package sources.

A new version is not automatically safer; an advisory is not automatically exploitable. Assess real CEFFLO exposure.

---

## 12. Malware / File Security

For uploaded files:
- allow expected formats;
- validate content/type, not extension alone;
- size-limit uploads;
- isolate storage;
- prevent execution;
- scan where risk warrants;
- restrict public access;
- use controlled/signed access where appropriate.

AI treats uploaded documents as **data, not trusted instructions**.

---

# AI / AGENT SECURITY

## 13. Agent Trust Boundary

```text
UNTRUSTED CONTENT
       ↓
CONTEXT ISOLATION
       ↓
AI MODEL
       ↓
ACTION REQUEST
       ↓
DETERMINISTIC SECURITY / PERMISSION GATE
       ↓
CONTROLLED TOOL
       ↓
RESOURCE
```

Never provide an agent an unrestricted combination of sensitive data, privileged credentials, arbitrary shell and arbitrary internet access.

---

## 14. Prompt Injection / Indirect Prompt Injection

Webpages, email, customer notes, support tickets, documents, repo content, CRM fields, search results and third-party responses may contain hostile instructions.

Authority comes from CEFFLO's control plane, not text inside retrieved data.

Controls:
- separate trusted instructions from retrieved data;
- record provenance/trust;
- minimize context;
- restrict tools;
- validate tool arguments;
- isolate secrets;
- restrict outbound destinations;
- deterministic permission gates;
- human approval for high-impact actions;
- consequential-output verification.

Prompt filtering alone is insufficient.

---

## 15. Tool Abuse / Excessive Agency

Example Engineering boundaries:

```text
E1 Lead   → read context/repo; create plan; no production mutation
E2 Build  → scoped dev branch/worktree; build/test; no direct production DB/deploy
E3 Pixel  → UI references/render/source; visual verification; no production mutation
E4 Verify → independent tests/evidence; cannot self-approve implementation
E5 Ship   → controlled release workflow; production gated
```

Models request tool actions; controlled tools execute authorized actions.

---

## 16. Credential & Data Exfiltration Defense

Models know capabilities, not raw credentials.

Restrict arbitrary outbound networking for sensitive workers, validate destinations, redact secrets, log sensitive actions, detect abnormal volume and gate bulk exports.

Do not give one agent unrestricted sensitive-data access plus arbitrary external destinations.

---

## 17. Memory / Context Poisoning

Dynamic context records should preserve source, provenance, owner, timestamp, status, trust level and version.

Untrusted user content never silently becomes Company Truth.

Normal retrieval excludes superseded, deprecated, quarantined and unverified high-risk material.

---

## 18. AI Verification & Kill Switches

AI output is not proof. Verify consequential work with tests, builds, screenshots, database queries, authorization checks, deployment status and audit records.

CEFFLO must be able to disable independently:
- an agent;
- model provider;
- tool;
- integration;
- outbound communication;
- publishing;
- deployments;
- sensitive DB operations;
- automation family.

Kill switches must operate outside the agent being stopped.

---

# CONTINUOUS THREAT INTELLIGENCE

## 19. Master vs Dynamic Threat Registry

**CEFFLO_CYBER_SECURITY_MASTER.md** contains stable security architecture, controls, gates and doctrine.

A separate **Dynamic Threat Registry** contains changing CVEs, advisories, attack techniques, affected versions, exploit status, CEFFLO exposure, mitigations and remediation status.

Do not append every new vulnerability to this Master.

---

## 20. Threat Intelligence Pipeline

```text
TRUSTED SECURITY SOURCES
          ↓
SECURITY WATCH
          ↓
Normalize + Validate
          ↓
Match CEFFLO Technology Inventory
          ↓
     relevant?
     /         NO        YES
   ↓          ↓
record     Exposure Analysis
              ↓
        Security Finding
              ↓
      WATCH / REMEDIATE / EMERGENCY
```

Threat intelligence is evidence, not permission to modify production.

---

## 21. Preferred Source Classes

Prefer primary/authoritative sources:
- vendor security advisories and release notes;
- CISA advisories / known-exploited catalogs;
- authoritative CVE/vulnerability records;
- GitHub Security Advisories / dependency security tooling;
- OWASP application and GenAI/agentic guidance;
- Flutter/Dart advisories;
- Supabase/PostgreSQL advisories;
- n8n advisories;
- Ubuntu/Docker advisories;
- model/provider security notices.

Community reports may be intake signals but require validation.

---

## 22. Security Watch Cadence

**Event-driven:** provider/vendor/repository security alerts where available.

**Daily:** critical/high issues, known exploitation, malicious dependencies, urgent CEFFLO-stack advisories.

**Weekly:** broader dependencies, AI/agent threats, new attack techniques, configuration advisories, unresolved findings and stale inventory.

**Monthly:** permissions/access, dependency age, open findings, backup/recovery evidence, telemetry and exceptions.

Cadence is configurable.

---

## 23. CEFFLO Technology Inventory

Maintain real dynamic inventory:

```text
ASSET_ID
TYPE
PRODUCT/SERVICE
TECHNOLOGY
VERSION
ENVIRONMENT
EXPOSURE
OWNER
DEPENDENCIES
LAST_VERIFIED
STATUS
```

Inventory includes Flutter/Dart/Android, web stack, Node/npm where used, Supabase/PostgreSQL, n8n, Ubuntu, Docker, proxy, GitHub Actions, model providers, MCP servers and third-party SDKs.

Refresh from real systems where practical; never rely solely on remembered versions.

---

## 24. Vulnerability Applicability

```text
Affected version?
      ↓
Actually installed?
      ↓
Reachable/exposed?
      ↓
Exploit preconditions?
      ↓
Existing mitigation?
      ↓
CEFFLO RISK
```

Do not panic from severity score alone and do not dismiss critical exposure without evidence.

---

## 25. Security Finding Contract

```text
FINDING_ID
SOURCE
ADVISORY_ID
TITLE
AFFECTED_ASSET
INSTALLED_VERSION
AFFECTED_RANGE
ENVIRONMENT
SEVERITY
EXPLOIT_STATUS
EXPOSURE
IMPACT
EXISTING_CONTROLS
RECOMMENDED_ACTION
TEMPORARY_MITIGATION
PERMANENT_FIX
EVIDENCE
STATUS
CREATED_AT
UPDATED_AT
```

Statuses:

```text
NEW → VALIDATING → NOT_APPLICABLE / EXPOSED
→ MITIGATED / REMEDIATION_READY
→ STAGING_VERIFY → FOUNDER_GATE where required
→ FIXED → CLOSED
```

Also support `FALSE_POSITIVE` and explicitly approved `ACCEPTED_RISK`.

---

## 26. Vulnerability Remediation

```text
Threat detected
→ validate
→ inventory match
→ exposure assessment
→ prioritize
→ temporary mitigation if needed
→ Engineering remediation
→ security tests
→ staging
→ independent verification
→ Founder Gate if material
→ production
→ post-fix verification
→ close
```

No blind production auto-patching.

Risk considers severity, exploitation, exposure, privileges, data sensitivity, blast radius, exploit maturity, mitigations and business criticality.

Operational classes: `P0 EMERGENCY`, `P1 URGENT`, `P2 HIGH`, `P3 NORMAL`, `P4 WATCH`.

---

## 27. AI / Agent Threat Intelligence

Continuously track applicable developments in:
- direct/indirect prompt injection;
- tool poisoning;
- malicious MCP/tool definitions;
- excessive agency;
- confused-deputy attacks;
- memory/context poisoning;
- identity spoofing;
- cross-agent propagation;
- data exfiltration;
- unsafe autonomous browsing;
- malicious retrieved content;
- model/provider incidents;
- agent supply-chain compromise.

For each technique:

```text
NEW THREAT
→ CEFFLO attack surface exists?
→ existing control?
→ verify control
→ if weak/absent: SECURITY GAP
→ Engineering remediation
```

---

# SECURITY OPERATIONS

## 28. Security Testing

Static/supply chain:
- dependency vulnerability checks;
- secret scanning;
- useful static analysis;
- configuration checks.

Dynamic:
- API authorization;
- negative RLS;
- authentication abuse;
- rate limits;
- uploads;
- security headers;
- staging simulations.

AI/agent:
- prompt injection;
- malicious customer/order/support content;
- tool-permission bypass;
- arbitrary outbound destination;
- secret retrieval;
- cross-tenant leakage;
- memory poisoning;
- Founder Gate bypass;
- recursive agent loops.

Only test systems CEFFLO is authorized to test.

---

## 29. Engineering Security Gate

```text
Requirement
→ Build
→ Functional Tests
→ Security Checks
→ Staging
→ Security Verification
→ Release Candidate
→ Founder Gate where required
→ Production
→ Monitoring
```

Material releases verify correct environment/build, tests, unresolved blocking findings, secret handling, auth/RLS, migrations, rollback/recovery path and release identity.

---

## 30. Logging / Detection / Circuit Breakers

Log security-relevant authentication failures, privilege changes, sensitive tool denials, deployments, workflow modifications, security findings, credential errors, abnormal API/agent behavior and security configuration changes. Never log raw secrets.

Alert levels: `INFO`, `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`.

Circuit breakers may transition affected scope:

```text
NORMAL → RESTRICTED → QUARANTINED → PAUSED_SECURITY_GUARD
```

Triggers include repeated unauthorized actions, abnormal outbound traffic, mass mutation/export, credential compromise, malicious dependency, unexplained production change, repeated gate bypass, or behavior outside expected scope.

---

## 31. Incident Response

```text
DETECT
→ TRIAGE
→ CONTAIN
→ PRESERVE EVIDENCE
→ ERADICATE
→ RECOVER
→ VERIFY
→ MONITOR
→ POST-INCIDENT REVIEW
→ CONTROL IMPROVEMENT
```

Severity:
- `SEV-1 CRITICAL` — major compromise/material exposure/destruction/broad takeover.
- `SEV-2 HIGH` — serious but contained compromise.
- `SEV-3 MEDIUM` — weakness/suspicious activity requiring remediation.
- `SEV-4 LOW` — low-risk finding/hardening.

Incident records preserve timeline, assets, environment, indicators, evidence, containment, root cause, recovery, impact and follow-up. Legal/regulatory conclusions require appropriate human review.

---

## 32. Backup / Disaster Recovery

Backups count only if restoration works.

Track backup scope, retention, restricted access, restore tests and recovery documentation.

Prioritize recovery for production DB, auth, Vendor/Driver backend, Customer Tracking, CEFFLO Control Layer governance and its n8n execution engine, Founder access and deployment pipeline.

Track:

```text
LAST_BACKUP
LAST_SUCCESSFUL_RESTORE_TEST
RECOVERY_TARGET
BACKUP_STATUS
```

---

## 33. Founder Security Gates

Founder approval is required for defined high-impact actions such as:
- material security architecture exceptions;
- acceptance of material unresolved risk;
- destructive production remediation;
- broad company-wide credential/security-policy changes;
- material customer-facing incident communications;
- other high-impact actions explicitly classified as gated.

Routine low-risk maintenance should not unnecessarily interrupt the Founder.

Security exceptions must have control, reason, risk, mitigation, owner, approver, expiry and review date.

---

## 34. Storage / IDs

Recommended canonical structures, reusing existing equivalents where possible:

```text
security_assets
security_dependencies
security_advisories
security_findings
security_events
security_alerts
security_incidents
security_controls
security_control_tests
security_exceptions
security_access_reviews
security_patch_records
security_backup_tests
security_agent_events
security_threat_techniques
security_cost_events
```

IDs:

```text
SEC-ASSET-000001
SEC-ADV-000001
SEC-FIND-000001
SEC-ALERT-000001
SEC-INC-000001
SEC-CTRL-000001
SEC-TEST-000001
SEC-EXC-000001
SEC-PATCH-000001
SEC-AI-000001
```

---

## 35. n8n Security Automation Responsibilities

Logical responsibilities:

```text
SEC-00 Asset Inventory Refresh
SEC-01 Threat Intelligence Intake
SEC-02 Advisory Validation / Normalization
SEC-03 CEFFLO Exposure Matcher
SEC-04 Vulnerability Finding Manager
SEC-05 Dependency / Supply Chain Watch
SEC-06 AI / Agent Threat Watch
SEC-07 Security Alert Router
SEC-08 Engineering Remediation Handoff
SEC-09 Security Verification
SEC-10 Incident / Containment Router
SEC-11 Backup / Recovery Verification
SEC-12 Security Metrics / Founder View
SEC-99 Emergency Security Guard
```

These are responsibilities, not a mandate for 14 workflows. Consolidate cleanly and avoid workflow sprawl.

Threat monitoring may read inventory/advisories and create/update findings, alerts and Engineering tasks. It may not autonomously delete production data, patch/deploy production, accept material risk, rewrite canonical security policy or perform broad destructive remediation.

---

## 36. Engineering Handoff

Security → Engineering:

```text
FINDING_ID
AFFECTED_ASSET
ENVIRONMENT
TECHNOLOGY/VERSION
THREAT
EXPOSURE
SEVERITY
EVIDENCE
TEMPORARY_MITIGATION
REQUIRED_OUTCOME
VERIFICATION_CRITERIA
```

Engineering → Security:

```text
ENGINEERING_TASK_ID
CHANGESET
TEST_RESULTS
STAGING_RESULT
DEPLOYMENT_STATUS
FIX_VERSION
REMAINING_RISK
```

A finding closes only after verification.

Customer Service routes suspected takeover, privacy exposure, malicious content, unauthorized access and vulnerability reports into the security incident path.

---

## 37. Context Hygiene / Clean Replacement

Normal security retrieval excludes superseded policy, deprecated controls, old credential references, archived incident instructions and unverified threats presented as fact.

Historical incidents remain evidence, not automatically active policy.

Follow CEFFLO doctrine:

> **REPLACE > PATCH when materially superseded.**

When replacing a control: map dependencies → implement replacement → test → switch consumers → verify → deactivate/remove obsolete runtime control → audit references.

One active architecture. One canonical truth path. No patch mountain.

---

## 38. Security Cost Discipline

Track source-query, model, scan, tool, storage, security-task and incident costs.

Use deterministic matching before expensive AI reasoning:

```text
advisory product not in CEFFLO inventory
→ NOT_APPLICABLE

real match
→ deeper analysis
```

AI may assist with advisory synthesis, exposure reasoning, event triage, attack mapping, security tests and incident timelines.

AI is never the sole authority for access control, secret protection, production approval, risk acceptance or legal obligations.

---

## 39. Security Baseline Before Production

Before CEFFLO production:
- real asset/dependency inventory current;
- environment credentials separated;
- database/RLS reviewed and tested;
- privileged accounts protected;
- source/dependency security controls active;
- n8n hardened;
- backups configured;
- restore test completed;
- logging/alerting active;
- incident path tested;
- production release gate working;
- agent permissions tested;
- prompt-injection tests run;
- kill switch tested;
- no unresolved blocking critical finding.

---

## 40. Implementation Sequence

**Phase 01 — Inventory:** real apps, backend, VPS, n8n, Supabase, GitHub, dependencies, models, MCP/tools, credential references and environments.

**Phase 02 — Baseline Hardening:** highest-risk identity, secrets, network, DB, n8n, GitHub and environment gaps.

**Phase 03 — Engineering Security Gates:** integrate checks into build/staging/release.

**Phase 04 — AI/Agent Security:** scoped tools, injection boundaries, provenance, egress controls, gates and kill switches.

**Phase 05 — Threat Intelligence:** dynamic advisory intake and inventory matching.

**Phase 06 — Vulnerability Management:** finding → Engineering → staging → verification → release.

**Phase 07 — Detection / Incident Response:** telemetry, alerts, containment and incident records.

**Phase 08 — Backup / Recovery:** prove restoration.

**Phase 09 — Founder Security View:** concise posture and actionable alerts.

**Phase 10 — Production Security Gate:** enforce security readiness before public launch.

---

## 41. First Pilots

Vulnerability pilot:

```text
Real CEFFLO inventory
→ real advisory or controlled simulated finding
→ match
→ exposure analysis
→ finding
→ Engineering remediation
→ staging
→ security verification
→ close
```

AI-security pilot:

```text
Malicious instruction embedded in authorized test content
→ agent reads it as untrusted data
→ prohibited tool action attempted
→ permission gate DENIES
→ security event recorded
→ no secret/data exfiltration
```

---

## 42. Founder Cyber Security View

Target:

```text
CEFFLO CYBER SECURITY

Overall posture              NORMAL
Critical findings            0
High findings                0
Open incidents               0
Security patches pending     -
Dependency alerts            -
AI / Agent alerts            -

Last threat update           -
Last dependency scan         -
Last security test           -
Last successful restore      -

Production access            -
Secrets                      -
RLS / authorization          -
n8n                          -
Backups                      -
Agent permissions            -
```

Only actionable high-risk matters should demand Founder attention.

---

## 43. Hard Prohibitions

Never permit:
- secrets in model prompts;
- privileged service keys in client bundles;
- UI-only authorization;
- unrestricted production access because an AI requests it;
- unrestricted sensitive data + credentials + arbitrary internet in one agent context;
- blind production auto-patching;
- destructive incident response without authority;
- silent acceptance of material risk;
- agent self-escalation;
- unverified external content becoming security truth;
- duplicate active security architectures;
- disabling security merely to make tests pass;
- false "secure" claims without evidence;
- scanning/attacking systems CEFFLO is not authorized to test.

---

## 44. Acceptance Tests

V1 must demonstrate:
1. unauthorized privileged action denied;
2. cross-tenant data access denied;
3. model cannot retrieve raw production secret through normal context/tools;
4. malicious prompt in untrusted content gains no authority;
5. forbidden tool call is deterministically denied;
6. sensitive workflow cannot exfiltrate to arbitrary destination;
7. gated production action cannot bypass Founder Gate;
8. development identity cannot mutate production;
9. advisory matching uses real inventory;
10. retries do not duplicate consequential actions;
11. kill switch disables selected capability outside the agent;
12. simulated incident enters containment path;
13. restore test proves recoverability;
14. material event can be reconstructed from audit evidence.

---

## 45. Definition of Done — Cyber Security V1

CEFFLO Cyber Security V1 is operational when:
1. real asset/dependency inventory exists;
2. dev/staging/production boundaries are enforced;
3. privileged credentials are isolated from models/clients;
4. DB authorization/RLS is tested;
5. n8n is hardened;
6. GitHub/source/dependency controls are active;
7. Engineering security gates exist;
8. AI tools use deterministic least privilege;
9. prompt-injection boundaries are tested;
10. agent privilege escalation is blocked;
11. threat intelligence matches against real inventory;
12. findings have verified remediation lifecycle;
13. material security telemetry/alerts work;
14. circuit breakers and kill switches work;
15. incident response is tested;
16. backups restore successfully;
17. production cannot bypass required security gates;
18. Founder sees concise security posture;
19. no blocking critical finding remains unresolved for production;
20. no obsolete parallel security architecture remains active.

---


---

# BANKING-STYLE HIGH-ASSURANCE SECURITY ADDENDUM

## 46. Crown Jewels Classification

CEFFLO must explicitly identify systems whose compromise could create company-wide impact.

Initial Crown Jewels:

```text
CEFFLO CROWN JEWELS
├── Production Customer / Operational Data
├── Supabase Privileged / Service-Role Access
├── Production Database Administrative Access
├── n8n Credentials and Production Control Plane
├── GitHub / CI-CD Production Authority
├── Production VPS / Infrastructure Administration
├── Production Signing / Deployment Credentials
├── Founder Command Center / Founder Authority
├── Security Configuration / Kill Switches
└── Backup / Recovery Assets
```

Crown Jewels receive stronger controls than ordinary development resources.

Requirements:
- explicit owner;
- minimal identities with access;
- no direct routine agent access;
- stronger authentication for privileged humans where supported;
- environment isolation;
- access logging;
- controlled changes;
- recovery plan;
- periodic access review;
- immediate credential rotation path;
- no raw Crown Jewel credentials in AI context.

A new critical system must be evaluated for Crown Jewel classification when introduced.

---

## 47. Banking-Style Segmentation

CEFFLO follows the principle that compromise of one component must not automatically grant access to another security zone.

Target zones:

```text
PUBLIC / UNTRUSTED
        │
        ▼
APPLICATION EDGE
        │
        ▼
APPLICATION SERVICES
        │
        ▼
DATA SERVICES
        │
        ▼
PRIVILEGED CONTROL ZONE
```

Separately controlled:

```text
DEVELOPMENT
STAGING
PRODUCTION
SECURITY / RECOVERY
```

Examples:

```text
Compromised Vendor client
        ✕
Production DB admin

Compromised development agent
        ✕
Production VPS root

Compromised Marketing workflow
        ✕
Supabase service-role

Compromised public website
        ✕
n8n credential store

Compromised support content
        ✕
AI privileged tool authority
```

Segmentation may be implemented through identities, RLS, network controls, credential boundaries, tool gateways, environment separation, scoped APIs and deployment gates.

Physical network separation is not required for every boundary; the security objective is enforceable isolation.

---

## 48. Zero-Trust / Assume-Breach Principle

Successful authentication does not create unlimited trust.

For every consequential action evaluate:

```text
WHO
  ↓
WHICH ENVIRONMENT
  ↓
WHICH RESOURCE
  ↓
WHICH ACTION
  ↓
IS THIS IDENTITY AUTHORIZED?
  ↓
IS ADDITIONAL APPROVAL REQUIRED?
  ↓
ALLOW / CHALLENGE / DENY
```

CEFFLO operates on an assume-breach principle:

```text
PREVENT
   ↓
DETECT
   ↓
CONTAIN
   ↓
RESPOND
   ↓
RECOVER
   ↓
LEARN
```

Security design must assume that an account, agent, dependency, endpoint or integration can eventually become compromised.

---

## 49. Separation of Duties

No single routine identity should control the entire high-impact lifecycle.

Engineering baseline:

```text
E1 Lead
   ↓
E2 Build
   ↓
E4 Independent Verify
   ↓
Security Gate
   ↓
Founder Gate when required
   ↓
E5 Controlled Ship
```

E2 cannot approve its own material production change.

E4 verification does not grant production authority.

E5 executes only an approved release path.

Security automation cannot accept its own material risk finding.

An agent that creates a high-impact change must not independently provide the final authorization for that same change.

---

## 50. Dual Control for Critical Actions

Certain Crown Jewel actions require two distinct authorities or an equivalent deterministic approval chain.

Examples:

```text
Production deployment
Material RLS / authorization change
Production database destructive migration
Production secret rotation with broad impact
Security-control disablement
Major incident containment affecting customers
Restoration of privileged access
Material emergency remediation
```

Canonical pattern:

```text
REQUESTER
    ↓
INDEPENDENT VERIFICATION
    ↓
SECURITY / POLICY GATE
    ↓
FOUNDER APPROVAL when classified as Founder-gated
    ↓
CONTROLLED EXECUTOR
```

Dual control must not be simulated by the same AI role approving itself under two names.

---

## 51. Privileged Access Management

Privileged access should be exceptional rather than permanent.

Target model:

```text
NORMAL IDENTITY
     ↓
REQUEST PRIVILEGED ACTION
     ↓
POLICY CHECK
     ↓
APPROVAL if required
     ↓
SCOPED / TIME-LIMITED AUTHORITY
     ↓
ACTION
     ↓
AUDIT
     ↓
AUTHORITY EXPIRES
```

Where platform capabilities allow:
- prefer short-lived credentials/tokens;
- avoid persistent root/admin sessions;
- log privileged actions;
- require stronger human authentication;
- remove dormant privileged identities;
- periodically review access;
- revoke authority immediately after compromise.

AI agents should normally receive action-specific tool permissions rather than general administrative credentials.

---

## 52. High-Risk Action Classification

Actions are classified independently from the agent requesting them.

Suggested classes:

```text
R0 — READ / LOW RISK
R1 — REVERSIBLE NON-PRODUCTION CHANGE
R2 — SENSITIVE / STAGING CHANGE
R3 — PRODUCTION OR CROWN JEWEL CHANGE
R4 — DESTRUCTIVE / COMPANY-WIDE / EMERGENCY
```

Example control:

```text
R0 → normal scoped permission
R1 → scoped execution + audit
R2 → verification required
R3 → independent verification + Security Gate
R4 → Security Gate + Founder Gate + explicit recovery plan
```

Classification is deterministic where possible.

A model cannot lower the risk class of its own requested action.

---

## 53. Transaction-Like Security for Consequential Actions

CEFFLO does not move customer money like a bank, but high-impact system actions should be treated similarly to sensitive transactions.

For consequential actions evaluate:

```text
Identity
+ Environment
+ Resource
+ Requested action
+ Scope
+ Expected change
+ Risk class
+ Approval state
+ Idempotency
+ Audit identity
```

Then:

```text
ALLOW
CHALLENGE / REQUIRE APPROVAL
DENY
```

Examples include:
- production deployment;
- mass customer communication;
- bulk data export;
- permission modification;
- destructive migration;
- secret rotation;
- workflow activation with production authority.

---

## 54. Blast-Radius Budgets

Every privileged tool or service identity should have a defined maximum expected blast radius.

Examples:

```text
Marketing publisher
→ publishing channels only

Customer Service agent
→ scoped support/customer-service operations

E2 Build
→ assigned development worktree/branch

E5 Ship
→ approved release artifact/path only

Threat Watch
→ read inventory + create findings

Security Guard
→ block/pause defined capability
→ no arbitrary company-wide mutation
```

If a capability could compromise the entire company from one identity, it requires explicit architectural review.

---

## 55. Crown Jewel Monitoring

Crown Jewels receive higher-sensitivity telemetry.

Monitor as applicable:
- privileged login;
- credential creation/rotation;
- permission changes;
- production deployment;
- production database administrative operation;
- security-policy modification;
- n8n credential/workflow modification;
- GitHub production-authority changes;
- backup deletion/change;
- kill-switch modification;
- abnormal bulk data access.

High-confidence anomalous activity may automatically restrict the affected identity or capability while preserving evidence.

---

## 56. Break-Glass Emergency Access

CEFFLO may maintain tightly controlled emergency access for recovery when normal control paths fail.

Requirements:

```text
BREAK-GLASS ACCESS
→ not used for routine work
→ strongly protected
→ Founder-controlled where practical
→ use generates CRITICAL audit event
→ limited duration
→ credentials rotated/resecured after use
→ mandatory incident/review record
```

Break-glass access must not become a permanent shortcut around security architecture.

---

## 57. Recovery Independence

A compromised production system must not be able to destroy every recovery mechanism.

Where practical:
- separate backup authority from ordinary application authority;
- restrict backup deletion;
- maintain recovery information outside the compromised runtime;
- test clean restoration;
- protect critical configuration and deployment history;
- preserve known-good release references.

Goal:

```text
PRODUCTION COMPROMISED
        ↓
CONTAIN
        ↓
KNOWN-GOOD RECOVERY PATH STILL EXISTS
        ↓
RESTORE
        ↓
VERIFY
```

---

## 58. Banking-Style Security Mapping for CEFFLO

```text
HIGH-ASSURANCE PRINCIPLE       CEFFLO IMPLEMENTATION

Network segmentation        → environment / identity / service isolation
IAM / PAM                   → scoped identities + privileged action gates
MFA                         → privileged Founder/admin authentication
Fraud-style monitoring      → anomaly + security monitoring
SOC-style visibility        → Cyber Security Watch + Founder security view
Threat intelligence         → Dynamic Threat Registry
Transaction controls        → deterministic high-risk action gates
Dual control                → independent verification + gated execution
Core-system isolation       → Crown Jewel protection
Incident response           → Security Incident workflow
Disaster recovery           → protected backups + tested restoration
Continuous assessment       → recurring security tests + exposure matching
```

CEFFLO adopts the control philosophy, not unnecessary banking-scale operational complexity.

---

## 59. Updated High-Assurance Production Path

```text
                    CHANGE REQUEST
                          │
                          ▼
                    RISK CLASSIFY
                          │
              ┌───────────┴───────────┐
              ▼                       ▼
          R0 / R1                  R2 / R3 / R4
              │                       │
              ▼                       ▼
       Scoped execution       Independent verification
                                      │
                                      ▼
                                Security Gate
                                      │
                           ┌──────────┴──────────┐
                           ▼                     ▼
                    Founder Gate            no Founder Gate
                    when required            if policy allows
                           │                     │
                           └──────────┬──────────┘
                                      ▼
                              Controlled Executor
                                      │
                                      ▼
                                  Production
                                      │
                                      ▼
                                  Monitoring
```

Crown Jewel changes default to stronger verification and authorization.

---

## 60. High-Assurance Acceptance Tests

In addition to the base acceptance tests, verify:

1. compromise of a development identity cannot directly administer production;
2. Marketing/Customer Service credentials cannot access Crown Jewels;
3. E2 cannot approve and ship its own material production change;
4. Crown Jewel access creates auditable security telemetry;
5. an R3/R4 action cannot lower its own risk classification;
6. expired privileged authority can no longer act;
7. break-glass usage generates an explicit security event;
8. production compromise does not eliminate the recovery path;
9. backup authority is sufficiently isolated from routine application authority;
10. a compromised agent remains inside its defined blast-radius budget;
11. Security Watch cannot autonomously accept a material risk;
12. Founder-gated actions cannot be completed by agent impersonation or workflow self-approval.

---

## 61. Updated Security Doctrine Lock

CEFFLO Cyber Security now applies a high-assurance model:

```text
VERIFY IDENTITY
      ↓
LIMIT PRIVILEGE
      ↓
SEGMENT SYSTEMS
      ↓
PROTECT CROWN JEWELS
      ↓
INDEPENDENTLY VERIFY HIGH-RISK CHANGES
      ↓
CONTROL PRIVILEGED EXECUTION
      ↓
MONITOR CONTINUOUSLY
      ↓
ASSUME BREACH
      ↓
CONTAIN BLAST RADIUS
      ↓
RECOVER FROM KNOWN-GOOD STATE
```

**No single routine compromise should equal total CEFFLO compromise.**

**No single AI agent should possess end-to-end authority over a Crown Jewel change.**

**Authentication does not equal unlimited trust.**

**High-impact actions are verified like sensitive transactions.**

**Recovery capability must survive compromise of the production runtime.**


# FINAL LOCK

```text
                     CEFFLO CYBER SECURITY
                              │
       ┌──────────────────────┼──────────────────────┐
       ▼                      ▼                      ▼
 PRODUCT / DATA         INFRASTRUCTURE          AI / AGENTS
       │                      │                      │
       └──────────────────────┼──────────────────────┘
                              ▼
                   DETERMINISTIC CONTROLS
                              │
                              ▼
                    CONTINUOUS MONITORING
                              │
                              ▼
                    THREAT INTELLIGENCE
                              │
                              ▼
                 VERIFIED REMEDIATION LOOP
                              │
                              ▼
                         FOUNDER GATES
```

**AI may request an action. Security controls decide whether the action is allowed.**

**Security intelligence stays current; security architecture stays controlled.**

**One active architecture. One canonical truth path. No patch mountain.**
