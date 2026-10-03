# CEFFLO SECURITY & ACCESS --- CANONICAL MASTER SPECIFICATION

**Status:** CANONICAL SECURITY SOT / MASTER AUTHORITY\
**Date:** 2026-09-30\
**Owner / Final Authority:** Founder\
**Scope:** Company-wide cyber security, privacy, data protection,
identity, authentication, authorization, role/surface access, invite and
membership lifecycle, infrastructure, software supply chain, AI/agent
security, security operations, incident response, recovery, and
production security gates.

> **This document is the single canonical Security & Access Source of
> Truth for Cefflo.**
>
> It consolidates and supersedes, as separate active authorities: -
> `CEFFLO_CYBER_SECURITY_MASTER.md` -
> `CEFFLO_SECURITY_PRIVACY_AND_DATA_PROTECTION_MASTER.md` -
> `CEFFLO_SURFACE_ROLE_INVITE_MEMBERSHIP_ARCHITECTURE_MASTER_SPEC.md` -
> `CEFFLO_SECURITY_ROLE_MEMBERSHIP_RECONCILIATION_ADDENDUM.md`
>
> The older documents may remain in repository history for provenance,
> but they must not be treated as parallel active security architectures
> after this master is adopted.

## 0. Canonical interpretation rules

1.  Security controls are server-authoritative. Native, Web and PWA
    clients are untrusted.
2.  Authentication proves identity; authorization decides what the
    identity may do.
3.  A successful login never implies business access.
4.  Business access requires the appropriate active membership, role,
    resource scope, allowed action and valid resource state.
5.  Pending membership grants zero active-role privilege.
6.  Surface separation is UX/routing, not an authorization boundary.
7.  Invite possession permits a join flow only; it never grants active
    membership.
8.  Owner-controlled membership approval/removal is enforced by the
    backend.
9.  Cross-business isolation is mandatory even when valid resource
    identifiers are known.
10. Security changes must not be weakened merely to make a UI flow pass.
11. Critical/High findings are handled under the production gate defined
    in this master.
12. Where wording inherited from an older section conflicts with a later
    locked role/membership decision in this master, the explicit locked
    decision governs product behavior while the stricter security
    control governs authorization and data protection.

## 0A. Core authorization contract

Every sensitive request must establish, as applicable:

``` text
authenticated actor
+ correct environment
+ active tenant/business membership
+ permitted role
+ resource ownership/scope
+ allowed action
+ valid current resource state
+ additional approval where required
= ALLOW / DENY
```

No UI control, route, deep link, QR, invite token, notification, local
state, UUID, client claim, PWA shell or native application is proof of
authorization.

## 0B. Production Security Hardening --- mandatory readiness domain

These controls are part of the production security program and must be
audited against real staging/production architecture rather than blindly
added.

### Privileged account protection

-   Protect FOUNDR/platform-admin and other Crown Jewel identities with
    strong authentication.
-   MFA/passkeys should be used where supported for privileged humans.
-   Evaluate re-authentication/step-up protection for high-impact
    security/account actions.
-   Privileged access must be minimal, auditable and revocable.

### Abuse and rate controls

Review and protect, according to threat/risk: - sign in; - sign up; -
account recovery/password reset; - invite resolution; - join-request
submission; - public storefront order submission; - customer tracking; -
uploads; - bulk/list/export endpoints; - notification mutation/creation
endpoints; - webhook and integration entry points.

Controls may include bounded payloads/results, rate controls,
anti-enumeration, idempotency/replay protection, bot/abuse controls
where justified, and observable failure patterns.

### Audit trail

Security-significant events should record enough evidence to
reconstruct: - actor; - tenant/business; - action; - target/resource; -
timestamp; - result; - relevant security context without raw secrets or
unnecessary PII.

Priority events include membership approval/removal, role changes,
privileged FOUNDR actions, security-control changes, destructive
operations, credential/integration changes, exports and production
release/security-gate actions.

### Membership revocation

Removing a business membership must revoke protected business
authorization even if the user's global authentication session remains
valid. Verification requires fresh backend read-back plus denied
protected reads/writes after removal.

### Storage hardening

Private originals and sensitive assets remain private-by-default and
role-scoped. Public storefront display assets are a separate exposure
class. The known Helper access to original/private product media must be
resolved or explicitly approved with documented business need and
regression evidence before production.

### Backup and recovery

Backups count only when restoration is proven. Maintain backup scope,
retention, restricted access, restore tests, recovery documentation and
independent recovery access for Crown Jewels.

### Secrets

No service-role/admin/production privileged secret may exist in client
bundles, prompts, logs or repository history. Maintain environment
separation, inventory, least privilege, scanning and rotation
procedures.

### Monitoring and incident response

Security-relevant authentication/authorization failures, privileged
changes, abnormal bulk access, suspicious admin activity,
security-control changes and incidents must be observable. Maintain a
usable detect → triage → contain → preserve evidence → eradicate →
recover → verify → monitor → learn process.

### Adversarial security tests

Retain regression coverage for: - tenant isolation; - BOLA/IDOR; -
role/privilege escalation; - stale sessions and removed membership; -
invite role/business manipulation; - duplicate/replay approval; -
storage cross-tenant access; - bulk extraction; - tracking-token
isolation; - rider location access; - FOUNDR privilege; -
secrets/client-bundle exposure; - webhook forgery/replay where
applicable.

### Production hard gate

Production is blocked by unresolved P0/Critical findings. P1/High
findings must be fixed before launch unless an explicit, documented,
time-bounded Founder exception with compensating controls is permitted
by this master. Production readiness requires evidence, not a UI-only
pass.

------------------------------------------------------------------------

# PART I --- PRODUCT SECURITY, PRIVACY & DATA PROTECTION

This part preserves the implementation-facing security/privacy contract
and production evidence requirements.

## CEFFLO SECURITY, PRIVACY & DATA PROTECTION MASTER

**Status:** Canonical Security SOT / Mandatory Cross-Cutting Gate\
**Applies to:** Vendor Web/Desktop, Vendor Flutter, Rider Flutter/PWA,
Customer Tracking & Communication, FOUNDR Command Center, `cefflo_api`,
Supabase/Postgres/RPC, Storage, integrations, n8n/automation and
production infrastructure.\
**Primary launch jurisdiction:** Malaysia\
**Doctrine:** Grow = Operate. Security is part of the operating system,
not a post-launch add-on.

------------------------------------------------------------------------

### 0. Purpose

This document defines the minimum security, privacy and data-protection
contract required for Cefflo. It is implementation-facing: every control
must map to code/configuration, tests and evidence.

A feature is **not production-ready** merely because it works. It must
also prove that the correct actor can perform the action, the wrong
actor cannot, sensitive data exposure is minimized, and failures are
observable and recoverable.

#### Non-negotiable authorization rule

> **A successful login does not equal authorization. Every sensitive
> operation must independently prove tenant, role, resource ownership
> and allowed action on the server.**

#### Canonical architecture boundary

-   Supabase/Postgres/RPC/backend services are the canonical operational
    and authorization authority.
-   `cefflo_api` is the client gateway where applicable.
-   Flutter/Web/PWA own presentation and permitted client state only.
-   Clients MUST NOT recreate or bypass backend
    authorization/business-security decisions.
-   Client-side hiding, disabled buttons, route guards or local role
    checks are UX controls, **not security boundaries**.

------------------------------------------------------------------------

## 1. Security Principles

Cefflo MUST operate under these principles:

1.  **Deny by default.** No resource is accessible unless explicitly
    permitted.
2.  **Least privilege.** Users, services, tokens and automation receive
    only permissions required for their function.
3.  **Tenant isolation first.** One vendor must never access another
    vendor's protected resources.
4.  **Server-authoritative authorization.** Sensitive decisions happen
    on trusted backend boundaries.
5.  **Minimize data.** Collect, expose and retain only what is
    operationally necessary.
6.  **Defense in depth.** RLS, API authorization, validation, rate
    controls and monitoring complement each other.
7.  **Assume clients are hostile.** Web/mobile requests can be modified,
    replayed or scripted.
8.  **No security through obscurity.** Guess-resistant IDs do not
    replace authorization.
9.  **Auditable privileged actions.** Sensitive administrative actions
    must leave useful evidence.
10. **Secure failure.** Errors must not leak secrets, internal queries,
    tokens or unnecessary PII.
11. **Production evidence required.** "Implemented" without
    tests/evidence is not considered complete.

------------------------------------------------------------------------

## 2. Severity Model

### P0 --- Launch Blocker / Critical

Examples: - Cross-tenant customer/order/rider access. - Public access to
private storage/data. - Service-role/admin credentials exposed to a
client or repository. - Authentication bypass. - Unauthorized privilege
escalation. - Bulk extraction path for protected customer data. -
Production secret committed to source control.

**Rule:** Any unresolved P0 = **NO PRODUCTION LAUNCH**.

### P1 --- High

Examples: - Missing rate limiting on sensitive/bulk endpoints. -
Inadequate privileged audit logging. - Excessive PII exposure. - Weak
session/revocation controls. - Missing abuse protection on
authentication/recovery/invite flows.

**Rule:** P1 must be fixed before launch unless Founder explicitly
accepts a documented, time-bounded exception with compensating controls.

### P2 --- Medium / Hardening

Examples: - Security headers hardening. - Non-critical dependency
findings. - Logging/alert quality improvements. - Additional privacy
minimization opportunities.

P2 may be scheduled post-launch only when risk is documented and no
P0/P1 dependency exists.

------------------------------------------------------------------------

## 3. Data Classification

Every persistent field and major payload should be classified.

  --------------------------------------------------------------------------
  Class                   Examples                Minimum handling
  ----------------------- ----------------------- --------------------------
  PUBLIC                  marketing copy, public  normal integrity controls
                          storefront information  

  INTERNAL                operational             authenticated/authorized
                          configuration,          access
                          non-sensitive analytics 

  CONFIDENTIAL            orders, customer names, tenant isolation,
                          business records, rider controlled API access,
                          assignments             protected logs

  HIGHLY SENSITIVE        phone, delivery         strict need-to-know
                          address, precise/live   access, minimization,
                          rider location,         retention rules,
                          auth/session data,      audit/monitoring where
                          identity/license        appropriate
                          images, secrets         
  --------------------------------------------------------------------------

#### Prohibited data behavior

-   Do not collect a field "just in case".
-   Do not return entire database rows when a UI needs only a subset.
-   Do not expose internal IDs/metadata unnecessarily.
-   Do not place secrets or unrestricted sensitive payloads in analytics
    events.
-   Do not log passwords, OTPs, magic links, auth tokens, refresh tokens
    or service credentials.

------------------------------------------------------------------------

## 4. Tenant Isolation --- Critical Security Boundary

`vendor_id` / canonical tenant ownership MUST be enforced server-side
for every tenant-owned resource.

Protected resources include at minimum:

-   orders and order details;
-   customer/delivery recipient data;
-   zones and service areas;
-   delivery plans/runs/stops;
-   riders/helpers and invitations;
-   rider locations;
-   team membership and roles;
-   business/storefront configuration;
-   operational analytics;
-   uploaded documents/assets;
-   subscription/account data where applicable.

### Required controls

-   RLS enabled on every exposed tenant-owned table.
-   Policies bind authenticated actor → membership/role → tenant →
    resource.
-   RPC/functions MUST perform equivalent authorization when
    security-definer or privileged execution is involved.
-   Views MUST NOT accidentally bypass RLS or expose cross-tenant rows.
-   Storage paths/buckets require equivalent tenant/owner rules.
-   Backend service calls must scope queries explicitly even where RLS
    provides a second boundary.

### Mandatory negative tests

For Vendor A and Vendor B, tests MUST attempt:

-   read B resource using known B ID;
-   update B resource;
-   delete B resource;
-   enumerate B records;
-   access B via alternate endpoint/RPC;
-   access B storage object;
-   access B rider location;
-   alter request body/query tenant ID from A → B;
-   access stale resource after membership removal.

Expected result: deny without revealing protected resource contents.

**P0 acceptance:** zero successful cross-tenant reads/writes in the
security test suite.

------------------------------------------------------------------------

## 5. Authentication & Session Security

Authentication establishes identity only.

Required:

-   Supported auth flows must use approved backend/auth provider
    mechanisms.
-   Secure token storage appropriate to each client platform.
-   TLS for all production transport.
-   Expired/revoked sessions rejected.
-   Logout invalidates/revokes session where supported and removes local
    sensitive state.
-   Account recovery/magic-link/OTP endpoints protected from abuse and
    enumeration.
-   Re-authentication or equivalent protection for high-impact
    account/security operations where appropriate.
-   Development/test authentication shortcuts MUST NOT exist in
    production builds.

#### Authentication enumeration

Login/recovery responses should avoid unnecessarily confirming whether a
customer/user account exists.

------------------------------------------------------------------------

## 6. Authorization & Role Model

Every sensitive action must evaluate:

`authenticated actor + tenant membership + role + resource ownership/scope + allowed action`

Roles must be explicitly documented. At minimum evaluate boundaries for:

-   vendor owner/admin;
-   vendor team member roles;
-   rider;
-   helper where applicable;
-   Cefflo operational/admin/FOUNDR access;
-   backend service identities;
-   automation/integration identities.

#### Forbidden pattern

``` text
if (user.isLoggedIn) allowEverything();
```

#### Required authorization tests

-   lower role cannot invoke owner/admin action;
-   rider cannot become vendor/admin by modifying payload/token claims;
-   removed team member immediately loses protected access within
    expected session/revocation semantics;
-   customer tracking token cannot access another delivery;
-   privileged Cefflo access is separately controlled and audited.

------------------------------------------------------------------------

## 7. Supabase / Postgres / RPC Security

### Tables

-   RLS MUST be enabled where client-accessible data requires
    protection.
-   No unintended anonymous access.
-   Grants reviewed separately from RLS.
-   Sensitive columns exposed only when needed.

### RPC / Functions

Each RPC must document:

-   caller type;
-   required role;
-   tenant resolution method;
-   resource ownership checks;
-   accepted inputs;
-   output fields;
-   idempotency requirements;
-   abuse/rate-limit considerations;
-   security-definer usage, if any.

`SECURITY DEFINER` functions receive special review because they can
bypass caller privileges if incorrectly designed.

### Service role

**Supabase service-role credentials MUST NEVER appear in:**

-   Flutter bundle;
-   web frontend bundle;
-   PWA;
-   public environment variables;
-   mobile configuration;
-   repository/history;
-   screenshots/logs/docs intended for public/client distribution.

Service-role usage is server-only and narrowly scoped.

------------------------------------------------------------------------

## 8. API Security

All sensitive API/RPC endpoints require:

-   authentication where required;
-   authorization independent of client input;
-   strict input/schema validation;
-   safe query construction;
-   payload size limits where appropriate;
-   rate/abuse controls;
-   controlled error responses;
-   pagination/maximum result sizes for collections;
-   prevention of arbitrary bulk extraction;
-   idempotency for operations where duplicate execution is dangerous.

### IDOR / BOLA

Knowing or changing a resource identifier MUST NOT grant access.

Tests must mutate:

-   order IDs;
-   run IDs;
-   rider IDs;
-   zone IDs;
-   invite IDs;
-   customer tracking IDs/tokens;
-   storage object paths;
-   tenant IDs.

------------------------------------------------------------------------

## 9. Bulk Export, Scraping & Exfiltration Protection

This section exists specifically to prevent a compromised account or
vulnerable endpoint from becoming a practical customer-database
extraction mechanism.

Required controls:

-   default pagination and hard maximum page size;
-   no unrestricted "return all customers/orders" endpoint;
-   bulk exports restricted by role and business requirement;
-   exports include only required fields;
-   export events are auditable;
-   rate limiting/abuse detection on high-volume reads;
-   repeated sequential resource enumeration detectable where feasible;
-   privileged data exports require additional safeguards;
-   backend queries always tenant-scoped;
-   avoid long-lived public URLs for private exports/files;
-   signed URLs must be scoped and short-lived where used.

#### P0 test

Security review must attempt to extract a materially large set of
customer records using:

1.  a normal vendor account;
2.  a rider account;
3.  an unauthenticated client;
4.  modified API calls;
5.  predictable/sequential resource queries.

Any cross-tenant bulk extraction = P0.

------------------------------------------------------------------------

## 10. Customer Privacy

Customer/recipient information is operational data, not a
general-purpose marketing database by default.

Principles:

-   Show riders only information necessary to complete assigned delivery
    work.
-   Address/phone exposure should be limited to the relevant delivery
    lifecycle where practical.
-   Customer tracking views expose the minimum required state.
-   Tracking links/tokens must not reveal unrelated orders/customer
    records.
-   Search/list endpoints must not permit unauthorized customer
    enumeration.
-   Sensitive customer fields should not be copied into unnecessary
    systems.

------------------------------------------------------------------------

## 11. Rider Privacy & Location

Precise rider location is HIGHLY SENSITIVE.

Required:

-   collect location only for legitimate operational purposes;
-   define when collection starts/stops;
-   avoid permanent collection outside required operational state;
-   vendor access restricted to authorized operational context;
-   one vendor cannot observe riders belonging exclusively to another
    tenant;
-   historical location retention must have a defined period/purpose;
-   customer tracking receives only the location precision/context
    required by the product design;
-   location APIs protected against bulk history extraction.

Rider identity/license photos require private storage and restricted
access.

------------------------------------------------------------------------

## 12. Storage Security

For Supabase Storage or equivalent:

-   private-by-default for customer/rider/private business assets;
-   no public bucket for identity/license documents;
-   tenant/owner path policy enforced;
-   MIME/type and size validation for uploads;
-   random/non-user-controlled storage names where useful;
-   signed URLs expire;
-   deletion lifecycle defined;
-   malware/content scanning considered for relevant upload classes;
-   metadata must not leak unnecessary PII.

Mandatory tests include cross-tenant object read/write/delete attempts.

------------------------------------------------------------------------

## 13. Secrets & Environment Management

Secrets include API keys, DB credentials, signing keys, service roles,
webhook secrets and provider tokens.

Rules:

-   no production secrets in git;
-   no secrets hardcoded in client applications;
-   environment separation: development / staging / production;
-   production credentials not reused in staging/dev;
-   least-privileged provider credentials;
-   rotation procedure documented;
-   immediately rotate suspected exposed credentials;
-   secret scanning in repository/CI;
-   `.env` and generated secret files excluded appropriately;
-   n8n/integration credentials stored in approved credential stores,
    not workflow plaintext where avoidable.

------------------------------------------------------------------------

## 14. Logging, Monitoring & Audit

Security logging should answer:

-   who acted;
-   which tenant/resource;
-   what action;
-   when;
-   result;
-   relevant request/security context without exposing secrets.

Audit candidates:

-   role/membership changes;
-   rider approvals/removals;
-   privileged exports;
-   account/security setting changes;
-   privileged Cefflo admin access/actions;
-   destructive actions;
-   credential/webhook/integration changes where appropriate.

#### Never log

-   passwords;
-   OTP/magic-link secrets;
-   access/refresh tokens;
-   full credentials;
-   unnecessary full customer payloads;
-   full payment/security secrets.

#### Detection targets

Where practical alert/detect:

-   abnormal authentication failures;
-   high-volume customer/order reads;
-   sequential enumeration patterns;
-   repeated authorization failures;
-   unusual privileged exports;
-   suspicious admin activity.

------------------------------------------------------------------------

## 15. Data Lifecycle & Retention

For each sensitive data category define:

`purpose → collection → storage → authorized users → retention → deletion → backup expiry`

Categories include:

-   customer delivery data;
-   orders;
-   rider profile data;
-   rider live/historical location;
-   rider/license documents;
-   invitations;
-   authentication/security logs;
-   operational/audit logs;
-   deleted accounts/businesses;
-   backups.

Rules:

-   "keep forever" is not the default.
-   Deleting production data must account for backup retention behavior.
-   Retention values must be documented before production launch.
-   Analytics should use minimized/aggregated data when detailed PII is
    unnecessary.

------------------------------------------------------------------------

## 16. Malaysia Privacy / PDPA Readiness

Before Malaysian production launch, Cefflo must perform a
legal/compliance review against the **current applicable Malaysian
Personal Data Protection Act requirements and related
regulations/guidance**.

Engineering/product must provide mechanisms necessary to support, as
applicable:

-   clear privacy notice and purposes of processing;
-   lawful/appropriate collection and use;
-   disclosure controls;
-   security safeguards;
-   data accuracy/correction workflows;
-   access requests;
-   retention/deletion policy;
-   processor/vendor governance;
-   cross-border processing/hosting review;
-   breach assessment and applicable notification workflow;
-   user/account deletion and data-handling process.

**Important:** This MD defines engineering readiness; it does not
replace legal advice or the final Malaysia compliance review.

------------------------------------------------------------------------

## 17. Third-Party & Integration Security

Applies to Supabase, Curlec, messaging providers, maps, analytics, n8n,
AI services and future integrations.

Before production integration:

-   document data sent to provider;
-   minimize transmitted PII;
-   document credential type and storage;
-   verify webhook signatures where provider supports them;
-   prevent replay where relevant;
-   restrict callback endpoints;
-   define provider failure behavior;
-   review provider access/retention implications;
-   revoke credentials when integration removed.

#### AI systems

Customer/rider PII MUST NOT be sent to LLM/AI services merely for
convenience. AI workflows require explicit purpose,
minimization/redaction and approved data boundary.

------------------------------------------------------------------------

## 18. Webhook Security

All external webhooks must implement provider-appropriate controls:

-   signature verification;
-   timestamp/replay validation where supported;
-   idempotency/deduplication;
-   schema validation;
-   no trust in payload tenant/resource identifiers without server
    reconciliation;
-   controlled retry behavior;
-   secret rotation support;
-   audit/error visibility.

------------------------------------------------------------------------

## 19. Client Application Security

Vendor Flutter, Rider Flutter/PWA and Web/Desktop must:

-   never contain server secrets;
-   not trust local role/tenant values for authorization;
-   avoid persistent storage of unnecessary PII;
-   clear sensitive cached state on logout/account switch;
-   protect deep links/tracking links appropriately;
-   avoid leaking sensitive data through crash reports/analytics;
-   use production endpoints only in production builds;
-   handle screenshots/background app state sensitively where warranted.

Reverse engineering the app must not reveal credentials capable of
bypassing backend controls.

------------------------------------------------------------------------

## 20. FOUNDR / Internal Admin Security

FOUNDR/admin capability creates exceptional risk because it may span
tenants.

Required:

-   separate privileged role/authorization path;
-   least privilege;
-   strong authentication controls;
-   no silent privilege inheritance from normal vendor roles;
-   privileged actions audited;
-   high-risk actions require explicit confirmation/reason where
    appropriate;
-   tenant impersonation/support access clearly indicated and logged;
-   bulk customer export unavailable by default;
-   production DB console/service-role access restricted to minimum
    operators.

Any ability for ordinary vendor credentials to reach FOUNDR/global
administration = P0.

------------------------------------------------------------------------

## 21. Incident Response

Cefflo must have a usable incident runbook before launch.

### Phase A --- Detect & Triage

-   preserve relevant logs/evidence;
-   identify affected service/account/tenant;
-   classify suspected data/security impact;
-   establish incident owner.

### Phase B --- Contain

Possible actions:

-   revoke sessions/tokens;
-   rotate secrets;
-   disable vulnerable endpoint/integration;
-   block abusive source/account;
-   temporarily disable exports or affected functionality.

### Phase C --- Investigate

Determine:

-   initial vector;
-   affected tenants/users;
-   data categories involved;
-   earliest/latest known access;
-   whether data was only exposed or demonstrably extracted/modified;
-   persistence/backdoors/credential compromise.

### Phase D --- Legal/Notification Assessment

Use current Malaysian legal requirements and contractual obligations to
determine required notifications and timing. Do not improvise public
breach claims before scope is understood.

### Phase E --- Recover

-   patch root cause;
-   rotate affected credentials;
-   validate security tests;
-   restore services carefully;
-   monitor for recurrence.

### Phase F --- Post-Incident

-   root-cause analysis;
-   timeline;
-   affected data estimate;
-   corrective controls;
-   tests preventing regression;
-   update this SOT where needed.

------------------------------------------------------------------------

## 22. Security Testing Matrix

The following is mandatory before production.

  ------------------------------------------------------------------------------
  Area                    Required test                  Severity if exploitable
  ----------------------- ------------------------------ -----------------------
  Tenant isolation        Vendor A reads/writes Vendor B P0

  Authentication          bypass/expired/revoked session P0/P1

  Authorization           role escalation                P0

  IDOR/BOLA               mutate resource IDs            P0

  Database/RLS            direct table/API cross-tenant  P0
                          query                          

  RPC                     privileged/security-definer    P0
                          bypass                         

  Storage                 private/cross-tenant object    P0
                          access                         

  Secrets                 repo/client bundle secret scan P0/P1

  Bulk data               high-volume                    P0/P1
                          extraction/enumeration         

  API abuse               rate-limit/payload abuse       P1

  Rider location          unauthorized/current/history   P0/P1
                          access                         

  Tracking                another customer's delivery    P0
                          accessible                     

  Admin                   vendor → global admin          P0
                          privilege                      

  Webhooks                forged/replayed event          P1/P0 depending impact

  Dependencies            known critical vulnerability   P1/P0 depending
                          review                         exploitability

  Logging                 secret/PII leakage             P1
  ------------------------------------------------------------------------------

------------------------------------------------------------------------

## 23. Automated Security Regression Tests

Security tests belong in CI/regression, not a one-time audit.

Minimum automated suites:

#### `SEC-TENANT`

Cross-tenant read/write/delete/enumeration tests.

#### `SEC-RBAC`

Role and privilege escalation tests.

#### `SEC-RLS`

Direct database/API policy tests for anonymous/authenticated roles.

#### `SEC-IDOR`

Resource-ID substitution tests.

#### `SEC-STORAGE`

Private file/object policy tests.

#### `SEC-SECRET`

Secret scanning and client bundle checks.

#### `SEC-EXPORT`

Bulk extraction/maximum page/export authorization tests.

#### `SEC-TRACKING`

Customer tracking token isolation tests.

#### `SEC-LOCATION`

Rider location authorization and retention behavior tests.

A previously fixed P0/P1 vulnerability MUST gain a regression test
whenever technically feasible.

------------------------------------------------------------------------

## 24. Production Security Gate

Production release is blocked until the following evidence exists.

### P0 Gate --- mandatory

-   [ ] Zero known authentication bypasses.
-   [ ] Zero known cross-tenant access paths.
-   [ ] Zero known privilege-escalation paths.
-   [ ] No service-role/admin secrets in clients/repo.
-   [ ] Private storage verified private.
-   [ ] Customer tracking isolation verified.
-   [ ] Rider location isolation verified.
-   [ ] Critical RPC authorization reviewed.
-   [ ] Bulk extraction tests passed.
-   [ ] Production environment separation verified.

### P1 Gate --- mandatory or explicit exception

-   [ ] Sensitive endpoints have abuse/rate controls.
-   [ ] Privileged actions produce useful audit evidence.
-   [ ] Incident response runbook exists.
-   [ ] Credential rotation procedure tested/documented.
-   [ ] Dependency/security scan reviewed.
-   [ ] Retention policy defined.
-   [ ] Privacy/PDPA launch review completed.
-   [ ] Third-party data flows documented.

#### Founder Gate

Release evidence presented as:

``` text
P0 open: 0
P1 open: 0 OR approved exceptions: <count>
P2 open: <count>
Security regression: PASS/FAIL
External/independent test: PASS / findings
PDPA readiness review: PASS / outstanding
Founder decision: GO / NO-GO
```

No vague "security looks okay" approval is acceptable.

------------------------------------------------------------------------

## 25. Ownership Matrix

  -----------------------------------------------------------------------
  Layer                   Owns                    Must NOT own
  ----------------------- ----------------------- -----------------------
  Flutter/Web/PWA         presentation, safe      authorization truth,
                          local UI state          tenant security
                                                  decisions

  cefflo_api/backend      request validation,     blindly trusting client
                          auth context, service   tenant/role IDs
                          boundaries              

  Postgres/RLS/RPC        canonical resource      relying on UI hiding
                          access rules, tenant    
                          isolation               

  Storage policies        object access control   public access to
                                                  private documents

  FOUNDR/Admin            authorized              unrestricted unaudited
                          support/operations      access

  n8n/integrations        approved workflow       uncontrolled customer
                          execution               DB access

  Founder                 risk acceptance /       bypassing technical P0
                          production gates        gate without
                                                  remediation
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 26. Required Repository Evidence

Claude/implementing agent must produce or locate evidence for each
security claim.

Expected evidence can include:

-   migration/policy file path;
-   RPC/function file path;
-   API handler/middleware path;
-   automated test path + test name;
-   CI/security scan result;
-   storage policy/config;
-   environment/secrets documentation;
-   incident runbook;
-   retention/privacy data map.

For every control report:

``` text
CONTROL:
STATUS: PASS / FAIL / PARTIAL / NOT APPLICABLE
SEVERITY: P0 / P1 / P2
IMPLEMENTATION EVIDENCE:
TEST EVIDENCE:
GAP:
REMEDIATION:
```

No evidence = not verified.

------------------------------------------------------------------------

## 27. Claude Repository Audit Execution Plan

Claude must NOT start by rewriting the security architecture. First
audit actual repo truth.

### Phase 1 --- Inventory

Map:

-   applications;
-   API/backend entry points;
-   Supabase migrations;
-   RLS policies;
-   RPC/functions;
-   storage buckets/policies;
-   auth/session code;
-   environment variables;
-   service-role usage;
-   integrations/webhooks;
-   customer/rider data models;
-   admin/FOUNDR paths;
-   existing tests.

Deliverable: `SECURITY_REPO_INVENTORY.md`.

### Phase 2 --- Threat Boundary Audit

Trace these actor paths:

1.  anonymous → customer tracking;
2.  vendor A → own resources;
3.  vendor A → vendor B resources;
4.  rider → assigned work;
5.  rider → unrelated work/vendor/customer;
6.  team member → owner-only operations;
7.  compromised client → direct Supabase/API calls;
8.  automation/integration → backend;
9.  Cefflo admin → tenant data.

Deliverable: `SECURITY_THREAT_BOUNDARY_AUDIT.md`.

### Phase 3 --- P0/P1 Findings

Create findings with:

-   exploit path;
-   affected resource;
-   severity;
-   proof/evidence;
-   remediation;
-   regression test required.

Do not expose real production secrets or customer PII in audit
documents.

### Phase 4 --- Fix Order

Fix in this priority:

1.  credentials/secrets exposure;
2.  auth bypass;
3.  tenant isolation;
4.  privilege escalation;
5.  storage exposure;
6.  customer tracking isolation;
7.  rider location/privacy;
8.  bulk extraction;
9.  API/webhook abuse;
10. logging/monitoring;
11. retention/privacy hardening;
12. P2 hardening.

### Phase 5 --- Regression

Run existing functional tests plus security suites. Security fixes must
not silently break canonical operational behavior.

### Phase 6 --- Evidence Pack

Deliver:

-   `SECURITY_FINDINGS.md`
-   `SECURITY_TEST_MATRIX.md`
-   `SECURITY_PRODUCTION_GATE.md`
-   relevant test files/migrations/code fixes
-   concise Founder GO/NO-GO summary.

------------------------------------------------------------------------

## 28. Acceptance Criteria for Current Cefflo Build

The current build is security-ready for its stage only when:

1.  Every client-accessible operational table has reviewed access rules.
2.  Vendor tenant isolation is proven with negative tests.
3.  Rider access is assignment/tenant scoped.
4.  Customer tracking is token/resource isolated.
5.  No privileged credential exists in Flutter/Web/PWA artifacts.
6.  RPCs do not trust caller-supplied tenant ownership.
7.  Sensitive storage is private and cross-tenant tested.
8.  Collection endpoints have bounded pagination/result sizes.
9.  Sensitive exports are restricted and auditable.
10. Precise rider location has explicit access and lifecycle rules.
11. P0 security tests run automatically.
12. Incident response and credential rotation procedures exist before
    production.
13. Malaysian privacy/PDPA readiness is reviewed against then-current
    law before launch.
14. Security evidence is attached to the production gate.

------------------------------------------------------------------------

## 29. Flow Integration

This MD is **cross-cutting** and applies immediately.

#### Flow 4 --- Vendor Flutter Mobile

Must comply before implementation is considered production-capable. UI
may never be treated as the authorization layer.

#### Flow 5 --- Rider Flutter Mobile

Must enforce assignment-scoped access, minimum customer disclosure,
secure location behavior and private rider documents.

#### Flow 6 --- Customer Tracking & Communication

Tracking isolation, token security, minimal customer/rider exposure and
anti-enumeration are mandatory.

#### Flow 7 --- FOUNDR Command Center

Requires privileged-access model and audit trail before
cross-tenant/global data capabilities are enabled.

#### Flow 8 --- Integration / Hardening

Runs the full consolidated security audit, adversarial testing,
dependency review, incident rehearsal and production evidence pack. Flow
8 is **not** the first time security is implemented.

#### Flow 9 --- Launch Prep

Production Security Gate + Malaysia privacy/PDPA gate must be signed off
before GO.

#### Flow 10 --- Marketing Engine

Marketing/AI automation must not receive unrestricted operational
customer/rider PII. Data passed to n8n/LLMs/content tools must be
purpose-limited and minimized/redacted.

------------------------------------------------------------------------

## 30. Security Change Rule

Any future feature that introduces one of the following MUST update this
SOT/security tests before production:

-   new user/role;
-   new sensitive data category;
-   new cross-tenant/global admin capability;
-   new storage bucket;
-   new public/customer link;
-   new integration/webhook;
-   new payment/billing flow;
-   new location collection;
-   new bulk export/reporting capability;
-   new AI/automation access to operational data.

Security requirements evolve with architecture; they must not become a
stale checklist.

------------------------------------------------------------------------

## 31. Definition of Done

A security-related implementation is DONE only when:

**Implementation + negative test + regression test + evidence +
documented residual risk = complete.**

Anything less remains open.

------------------------------------------------------------------------

### FINAL RELEASE RULE

> **Cefflo must fail closed. A user, rider, vendor, client application,
> integration or compromised credential receives only the smallest set
> of data and actions explicitly authorized for its current role, tenant
> and operational purpose.**

> **No unresolved P0 finding may enter production.**

------------------------------------------------------------------------

# PART II --- COMPANY-WIDE CYBER SECURITY, INFRASTRUCTURE & HIGH-ASSURANCE CONTROLS

This part preserves the company-wide cyber-security architecture,
infrastructure, supply-chain, AI/agent security, threat intelligence,
security operations, banking-style high-assurance controls, recovery and
Founder gates.

## CEFFLO CYBER SECURITY --- MASTER SPECIFICATION

**Status:** MASTER BASELINE\
**Date:** 2026-09-19\
**Scope:** Company-wide product, infrastructure, data, software
supply-chain, AI/agent security, continuous threat intelligence,
vulnerability management, incident response, and recovery.\
**Owner / Final Authority:** Founder\
**Enforcement:** Technical controls + n8n Control Layer + Engineering
workflows + infrastructure policy\
**Role:** Cross-company security architecture --- **not a sixth
department and not an AI super-agent**.

------------------------------------------------------------------------

### 0. Mission

CEFFLO Cyber Security protects CEFFLO products, infrastructure, data,
users, software supply chain, and AI/agent systems while allowing the
company to ship efficiently.

Security must not depend on an AI model behaving correctly.

> **AI may request an action. Security controls decide whether the
> action is allowed.**

> **Assume external content is untrusted. Compromise one component; do
> not compromise the company.**

> **Security intelligence stays current; security architecture stays
> controlled.**

------------------------------------------------------------------------

### 1. Protected Surfaces

Product surfaces: - Vendor Flutter App - Driver Flutter App - Vendor
Web/Desktop - Customer Tracking PWA - Public Website - Founder Command
Center

Backend and data: - APIs, Supabase, PostgreSQL, Auth, RLS, Storage,
Realtime, webhooks, server functions/services

Infrastructure: - VPS, Ubuntu/Linux, Docker, reverse proxy/TLS, n8n,
CI/CD, DNS, backups, object storage

Development/supply chain: - GitHub, branches/PRs, Flutter/Dart packages,
npm/Node where used, Docker images, CI actions/plugins, SDKs, MCP
servers/tools

AI/agents: - model providers, prompts, context retrieval, memory, tools,
permissions, autonomous workflows, events, model/API credentials

------------------------------------------------------------------------

### 2. Security Domains

``` text
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

------------------------------------------------------------------------

### 3. Environment Isolation

``` text
DEVELOPMENT → STAGING → PRODUCTION
```

Where practical:

``` text
DEV credentials ≠ STAGING credentials ≠ PRODUCTION credentials
DEV database    ≠ STAGING database    ≠ PRODUCTION database
DEV permissions ≠ PRODUCTION permissions
```

Production authority is technically enforced, never inferred from an AI
prompt.

------------------------------------------------------------------------

### 4. Identity, Authentication & Least Privilege

Every human, service, workflow, agent tool and deployment identity
receives only required permissions. Avoid shared omnipotent credentials.

Use MFA/passkeys where supported for privileged humans, secure
session/token handling, revocation, protected reset flows, scoped
service identities, and environment-specific permissions.

Agents cannot grant themselves permissions.

Authentication proves identity; authorization determines permitted
actions.

------------------------------------------------------------------------

### 5. Authorization & Supabase RLS

Client applications are untrusted. Hiding a UI control is not
authorization.

Sensitive authorization is enforced server-side. For
Supabase/PostgreSQL: - use appropriate RLS and least privilege; -
default-deny sensitive data where practical; - separate
vendor/driver/customer/admin access; - protect service-role
credentials; - audit policy changes; - test positive and negative paths.

Required tests include:

``` text
Vendor A cannot read Vendor B data.
Driver A cannot access unrelated Driver B runs.
Customer tracking cannot expose unrelated deliveries.
Normal vendor cannot perform Founder/Admin actions.
Unauthenticated client cannot bypass server policy.
```

------------------------------------------------------------------------

### 6. API / Input / Web Security

APIs enforce authentication, authorization, schema/type validation, rate
controls where appropriate, request limits, safe errors, idempotency and
audit logging.

Never trust client-supplied role, vendor ID, permission, price, or
completion state without server validation.

External forms, notes, uploads, URLs, webhooks, CSVs, email, support
messages, CRM fields, AI output, retrieved web content and third-party
API payloads are untrusted.

Web/PWA controls include HTTPS, secure headers, CSP where practical,
secure cookies, CSRF controls where applicable, XSS prevention, safe DOM
rendering, origin/CORS controls, safe service-worker caching and no
secrets in frontend bundles.

------------------------------------------------------------------------

### 7. Flutter / Mobile Security

Assume mobile clients can be inspected or modified.

-   no privileged backend secrets in app bundles;
-   secure token handling;
-   minimize sensitive local storage;
-   enforce permissions server-side;
-   secure deep links;
-   protect signing material;
-   production-safe logging;
-   dependency monitoring;
-   release integrity checks where appropriate.

Obfuscation is not an authorization boundary.

------------------------------------------------------------------------

### 8. Data / Database Security

Use least-privilege DB roles, RLS where applicable, encrypted transport,
secure backups, restricted backup access, reviewed migrations, retention
controls, data minimization and auditable privileged operations.

Do not casually copy production customer data into development.

------------------------------------------------------------------------

### 9. Secrets Management

Secrets belong in controlled credential stores/environment/vaults.

``` text
SECRET → controlled store → controlled tool → action
```

Never:

``` text
SECRET → prompt → model context → logs
```

Never commit secrets to Git or embed privileged keys in Flutter/PWA.
Rotate exposed credentials and separate environments.

------------------------------------------------------------------------

### 10. Network, VPS & n8n Security

Restrict inbound services, database exposure and administrative
interfaces. Use TLS, firewalls, SSH hardening, least privilege, service
isolation, supported security updates, monitoring and backups.

n8n is a high-value control-plane asset. Protect editor/admin access,
credentials, webhook endpoints, execution data, environment variables,
workflow modification and production activation.

Use authenticated/signed webhooks where applicable, validated payloads,
idempotency, retry limits, cost limits, Founder Gates and restricted
production actions.

------------------------------------------------------------------------

### 11. GitHub & Supply-Chain Security

Use MFA/passkeys where supported, protect critical branches, scan
secrets, monitor dependency/security advisories, minimize CI/token
permissions and review third-party CI actions/plugins.

Maintain inventory of dependencies, Docker images, CI actions, MCP
servers, SDKs and package sources.

A new version is not automatically safer; an advisory is not
automatically exploitable. Assess real CEFFLO exposure.

------------------------------------------------------------------------

### 12. Malware / File Security

For uploaded files: - allow expected formats; - validate content/type,
not extension alone; - size-limit uploads; - isolate storage; - prevent
execution; - scan where risk warrants; - restrict public access; - use
controlled/signed access where appropriate.

AI treats uploaded documents as **data, not trusted instructions**.

------------------------------------------------------------------------

## AI / AGENT SECURITY

### 13. Agent Trust Boundary

``` text
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

Never provide an agent an unrestricted combination of sensitive data,
privileged credentials, arbitrary shell and arbitrary internet access.

------------------------------------------------------------------------

### 14. Prompt Injection / Indirect Prompt Injection

Webpages, email, customer notes, support tickets, documents, repo
content, CRM fields, search results and third-party responses may
contain hostile instructions.

Authority comes from CEFFLO's control plane, not text inside retrieved
data.

Controls: - separate trusted instructions from retrieved data; - record
provenance/trust; - minimize context; - restrict tools; - validate tool
arguments; - isolate secrets; - restrict outbound destinations; -
deterministic permission gates; - human approval for high-impact
actions; - consequential-output verification.

Prompt filtering alone is insufficient.

------------------------------------------------------------------------

### 15. Tool Abuse / Excessive Agency

Example Engineering boundaries:

``` text
E1 Lead   → read context/repo; create plan; no production mutation
E2 Build  → scoped dev branch/worktree; build/test; no direct production DB/deploy
E3 Pixel  → UI references/render/source; visual verification; no production mutation
E4 Verify → independent tests/evidence; cannot self-approve implementation
E5 Ship   → controlled release workflow; production gated
```

Models request tool actions; controlled tools execute authorized
actions.

------------------------------------------------------------------------

### 16. Credential & Data Exfiltration Defense

Models know capabilities, not raw credentials.

Restrict arbitrary outbound networking for sensitive workers, validate
destinations, redact secrets, log sensitive actions, detect abnormal
volume and gate bulk exports.

Do not give one agent unrestricted sensitive-data access plus arbitrary
external destinations.

------------------------------------------------------------------------

### 17. Memory / Context Poisoning

Dynamic context records should preserve source, provenance, owner,
timestamp, status, trust level and version.

Untrusted user content never silently becomes Company Truth.

Normal retrieval excludes superseded, deprecated, quarantined and
unverified high-risk material.

------------------------------------------------------------------------

### 18. AI Verification & Kill Switches

AI output is not proof. Verify consequential work with tests, builds,
screenshots, database queries, authorization checks, deployment status
and audit records.

CEFFLO must be able to disable independently: - an agent; - model
provider; - tool; - integration; - outbound communication; -
publishing; - deployments; - sensitive DB operations; - automation
family.

Kill switches must operate outside the agent being stopped.

------------------------------------------------------------------------

## CONTINUOUS THREAT INTELLIGENCE

### 19. Master vs Dynamic Threat Registry

**CEFFLO_CYBER_SECURITY_MASTER.md** contains stable security
architecture, controls, gates and doctrine.

A separate **Dynamic Threat Registry** contains changing CVEs,
advisories, attack techniques, affected versions, exploit status, CEFFLO
exposure, mitigations and remediation status.

Do not append every new vulnerability to this Master.

------------------------------------------------------------------------

### 20. Threat Intelligence Pipeline

``` text
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

------------------------------------------------------------------------

### 21. Preferred Source Classes

Prefer primary/authoritative sources: - vendor security advisories and
release notes; - CISA advisories / known-exploited catalogs; -
authoritative CVE/vulnerability records; - GitHub Security Advisories /
dependency security tooling; - OWASP application and GenAI/agentic
guidance; - Flutter/Dart advisories; - Supabase/PostgreSQL advisories; -
n8n advisories; - Ubuntu/Docker advisories; - model/provider security
notices.

Community reports may be intake signals but require validation.

------------------------------------------------------------------------

### 22. Security Watch Cadence

**Event-driven:** provider/vendor/repository security alerts where
available.

**Daily:** critical/high issues, known exploitation, malicious
dependencies, urgent CEFFLO-stack advisories.

**Weekly:** broader dependencies, AI/agent threats, new attack
techniques, configuration advisories, unresolved findings and stale
inventory.

**Monthly:** permissions/access, dependency age, open findings,
backup/recovery evidence, telemetry and exceptions.

Cadence is configurable.

------------------------------------------------------------------------

### 23. CEFFLO Technology Inventory

Maintain real dynamic inventory:

``` text
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

Inventory includes Flutter/Dart/Android, web stack, Node/npm where used,
Supabase/PostgreSQL, n8n, Ubuntu, Docker, proxy, GitHub Actions, model
providers, MCP servers and third-party SDKs.

Refresh from real systems where practical; never rely solely on
remembered versions.

------------------------------------------------------------------------

### 24. Vulnerability Applicability

``` text
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

Do not panic from severity score alone and do not dismiss critical
exposure without evidence.

------------------------------------------------------------------------

### 25. Security Finding Contract

``` text
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

``` text
NEW → VALIDATING → NOT_APPLICABLE / EXPOSED
→ MITIGATED / REMEDIATION_READY
→ STAGING_VERIFY → FOUNDER_GATE where required
→ FIXED → CLOSED
```

Also support `FALSE_POSITIVE` and explicitly approved `ACCEPTED_RISK`.

------------------------------------------------------------------------

### 26. Vulnerability Remediation

``` text
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

Risk considers severity, exploitation, exposure, privileges, data
sensitivity, blast radius, exploit maturity, mitigations and business
criticality.

Operational classes: `P0 EMERGENCY`, `P1 URGENT`, `P2 HIGH`,
`P3 NORMAL`, `P4 WATCH`.

------------------------------------------------------------------------

### 27. AI / Agent Threat Intelligence

Continuously track applicable developments in: - direct/indirect prompt
injection; - tool poisoning; - malicious MCP/tool definitions; -
excessive agency; - confused-deputy attacks; - memory/context
poisoning; - identity spoofing; - cross-agent propagation; - data
exfiltration; - unsafe autonomous browsing; - malicious retrieved
content; - model/provider incidents; - agent supply-chain compromise.

For each technique:

``` text
NEW THREAT
→ CEFFLO attack surface exists?
→ existing control?
→ verify control
→ if weak/absent: SECURITY GAP
→ Engineering remediation
```

------------------------------------------------------------------------

## SECURITY OPERATIONS

### 28. Security Testing

Static/supply chain: - dependency vulnerability checks; - secret
scanning; - useful static analysis; - configuration checks.

Dynamic: - API authorization; - negative RLS; - authentication abuse; -
rate limits; - uploads; - security headers; - staging simulations.

AI/agent: - prompt injection; - malicious customer/order/support
content; - tool-permission bypass; - arbitrary outbound destination; -
secret retrieval; - cross-tenant leakage; - memory poisoning; - Founder
Gate bypass; - recursive agent loops.

Only test systems CEFFLO is authorized to test.

------------------------------------------------------------------------

### 29. Engineering Security Gate

``` text
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

Material releases verify correct environment/build, tests, unresolved
blocking findings, secret handling, auth/RLS, migrations,
rollback/recovery path and release identity.

------------------------------------------------------------------------

### 30. Logging / Detection / Circuit Breakers

Log security-relevant authentication failures, privilege changes,
sensitive tool denials, deployments, workflow modifications, security
findings, credential errors, abnormal API/agent behavior and security
configuration changes. Never log raw secrets.

Alert levels: `INFO`, `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`.

Circuit breakers may transition affected scope:

``` text
NORMAL → RESTRICTED → QUARANTINED → PAUSED_SECURITY_GUARD
```

Triggers include repeated unauthorized actions, abnormal outbound
traffic, mass mutation/export, credential compromise, malicious
dependency, unexplained production change, repeated gate bypass, or
behavior outside expected scope.

------------------------------------------------------------------------

### 31. Incident Response

``` text
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

Severity: - `SEV-1 CRITICAL` --- major compromise/material
exposure/destruction/broad takeover. - `SEV-2 HIGH` --- serious but
contained compromise. - `SEV-3 MEDIUM` --- weakness/suspicious activity
requiring remediation. - `SEV-4 LOW` --- low-risk finding/hardening.

Incident records preserve timeline, assets, environment, indicators,
evidence, containment, root cause, recovery, impact and follow-up.
Legal/regulatory conclusions require appropriate human review.

------------------------------------------------------------------------

### 32. Backup / Disaster Recovery

Backups count only if restoration works.

Track backup scope, retention, restricted access, restore tests and
recovery documentation.

Prioritize recovery for production DB, auth, Vendor/Driver backend,
Customer Tracking, n8n Control Layer, Founder access and deployment
pipeline.

Track:

``` text
LAST_BACKUP
LAST_SUCCESSFUL_RESTORE_TEST
RECOVERY_TARGET
BACKUP_STATUS
```

------------------------------------------------------------------------

### 33. Founder Security Gates

Founder approval is required for defined high-impact actions such as: -
material security architecture exceptions; - acceptance of material
unresolved risk; - destructive production remediation; - broad
company-wide credential/security-policy changes; - material
customer-facing incident communications; - other high-impact actions
explicitly classified as gated.

Routine low-risk maintenance should not unnecessarily interrupt the
Founder.

Security exceptions must have control, reason, risk, mitigation, owner,
approver, expiry and review date.

------------------------------------------------------------------------

### 34. Storage / IDs

Recommended canonical structures, reusing existing equivalents where
possible:

``` text
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

``` text
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

------------------------------------------------------------------------

### 35. n8n Security Automation Responsibilities

Logical responsibilities:

``` text
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

These are responsibilities, not a mandate for 14 workflows. Consolidate
cleanly and avoid workflow sprawl.

Threat monitoring may read inventory/advisories and create/update
findings, alerts and Engineering tasks. It may not autonomously delete
production data, patch/deploy production, accept material risk, rewrite
canonical security policy or perform broad destructive remediation.

------------------------------------------------------------------------

### 36. Engineering Handoff

Security → Engineering:

``` text
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

``` text
ENGINEERING_TASK_ID
CHANGESET
TEST_RESULTS
STAGING_RESULT
DEPLOYMENT_STATUS
FIX_VERSION
REMAINING_RISK
```

A finding closes only after verification.

Customer Service routes suspected takeover, privacy exposure, malicious
content, unauthorized access and vulnerability reports into the security
incident path.

------------------------------------------------------------------------

### 37. Context Hygiene / Clean Replacement

Normal security retrieval excludes superseded policy, deprecated
controls, old credential references, archived incident instructions and
unverified threats presented as fact.

Historical incidents remain evidence, not automatically active policy.

Follow CEFFLO doctrine:

> **REPLACE \> PATCH when materially superseded.**

When replacing a control: map dependencies → implement replacement →
test → switch consumers → verify → deactivate/remove obsolete runtime
control → audit references.

One active architecture. One canonical truth path. No patch mountain.

------------------------------------------------------------------------

### 38. Security Cost Discipline

Track source-query, model, scan, tool, storage, security-task and
incident costs.

Use deterministic matching before expensive AI reasoning:

``` text
advisory product not in CEFFLO inventory
→ NOT_APPLICABLE

real match
→ deeper analysis
```

AI may assist with advisory synthesis, exposure reasoning, event triage,
attack mapping, security tests and incident timelines.

AI is never the sole authority for access control, secret protection,
production approval, risk acceptance or legal obligations.

------------------------------------------------------------------------

### 39. Security Baseline Before Production

Before CEFFLO production: - real asset/dependency inventory current; -
environment credentials separated; - database/RLS reviewed and tested; -
privileged accounts protected; - source/dependency security controls
active; - n8n hardened; - backups configured; - restore test
completed; - logging/alerting active; - incident path tested; -
production release gate working; - agent permissions tested; -
prompt-injection tests run; - kill switch tested; - no unresolved
blocking critical finding.

------------------------------------------------------------------------

### 40. Implementation Sequence

**Phase 01 --- Inventory:** real apps, backend, VPS, n8n, Supabase,
GitHub, dependencies, models, MCP/tools, credential references and
environments.

**Phase 02 --- Baseline Hardening:** highest-risk identity, secrets,
network, DB, n8n, GitHub and environment gaps.

**Phase 03 --- Engineering Security Gates:** integrate checks into
build/staging/release.

**Phase 04 --- AI/Agent Security:** scoped tools, injection boundaries,
provenance, egress controls, gates and kill switches.

**Phase 05 --- Threat Intelligence:** dynamic advisory intake and
inventory matching.

**Phase 06 --- Vulnerability Management:** finding → Engineering →
staging → verification → release.

**Phase 07 --- Detection / Incident Response:** telemetry, alerts,
containment and incident records.

**Phase 08 --- Backup / Recovery:** prove restoration.

**Phase 09 --- Founder Security View:** concise posture and actionable
alerts.

**Phase 10 --- Production Security Gate:** enforce security readiness
before public launch.

------------------------------------------------------------------------

### 41. First Pilots

Vulnerability pilot:

``` text
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

``` text
Malicious instruction embedded in authorized test content
→ agent reads it as untrusted data
→ prohibited tool action attempted
→ permission gate DENIES
→ security event recorded
→ no secret/data exfiltration
```

------------------------------------------------------------------------

### 42. Founder Cyber Security View

Target:

``` text
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

------------------------------------------------------------------------

### 43. Hard Prohibitions

Never permit: - secrets in model prompts; - privileged service keys in
client bundles; - UI-only authorization; - unrestricted production
access because an AI requests it; - unrestricted sensitive data +
credentials + arbitrary internet in one agent context; - blind
production auto-patching; - destructive incident response without
authority; - silent acceptance of material risk; - agent
self-escalation; - unverified external content becoming security
truth; - duplicate active security architectures; - disabling security
merely to make tests pass; - false "secure" claims without evidence; -
scanning/attacking systems CEFFLO is not authorized to test.

------------------------------------------------------------------------

### 44. Acceptance Tests

V1 must demonstrate: 1. unauthorized privileged action denied; 2.
cross-tenant data access denied; 3. model cannot retrieve raw production
secret through normal context/tools; 4. malicious prompt in untrusted
content gains no authority; 5. forbidden tool call is deterministically
denied; 6. sensitive workflow cannot exfiltrate to arbitrary
destination; 7. gated production action cannot bypass Founder Gate; 8.
development identity cannot mutate production; 9. advisory matching uses
real inventory; 10. retries do not duplicate consequential actions; 11.
kill switch disables selected capability outside the agent; 12.
simulated incident enters containment path; 13. restore test proves
recoverability; 14. material event can be reconstructed from audit
evidence.

------------------------------------------------------------------------

### 45. Definition of Done --- Cyber Security V1

CEFFLO Cyber Security V1 is operational when: 1. real asset/dependency
inventory exists; 2. dev/staging/production boundaries are enforced; 3.
privileged credentials are isolated from models/clients; 4. DB
authorization/RLS is tested; 5. n8n is hardened; 6.
GitHub/source/dependency controls are active; 7. Engineering security
gates exist; 8. AI tools use deterministic least privilege; 9.
prompt-injection boundaries are tested; 10. agent privilege escalation
is blocked; 11. threat intelligence matches against real inventory; 12.
findings have verified remediation lifecycle; 13. material security
telemetry/alerts work; 14. circuit breakers and kill switches work; 15.
incident response is tested; 16. backups restore successfully; 17.
production cannot bypass required security gates; 18. Founder sees
concise security posture; 19. no blocking critical finding remains
unresolved for production; 20. no obsolete parallel security
architecture remains active.

------------------------------------------------------------------------

------------------------------------------------------------------------

## BANKING-STYLE HIGH-ASSURANCE SECURITY ADDENDUM

### 46. Crown Jewels Classification

CEFFLO must explicitly identify systems whose compromise could create
company-wide impact.

Initial Crown Jewels:

``` text
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

Crown Jewels receive stronger controls than ordinary development
resources.

Requirements: - explicit owner; - minimal identities with access; - no
direct routine agent access; - stronger authentication for privileged
humans where supported; - environment isolation; - access logging; -
controlled changes; - recovery plan; - periodic access review; -
immediate credential rotation path; - no raw Crown Jewel credentials in
AI context.

A new critical system must be evaluated for Crown Jewel classification
when introduced.

------------------------------------------------------------------------

### 47. Banking-Style Segmentation

CEFFLO follows the principle that compromise of one component must not
automatically grant access to another security zone.

Target zones:

``` text
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

``` text
DEVELOPMENT
STAGING
PRODUCTION
SECURITY / RECOVERY
```

Examples:

``` text
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

Segmentation may be implemented through identities, RLS, network
controls, credential boundaries, tool gateways, environment separation,
scoped APIs and deployment gates.

Physical network separation is not required for every boundary; the
security objective is enforceable isolation.

------------------------------------------------------------------------

### 48. Zero-Trust / Assume-Breach Principle

Successful authentication does not create unlimited trust.

For every consequential action evaluate:

``` text
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

``` text
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

Security design must assume that an account, agent, dependency, endpoint
or integration can eventually become compromised.

------------------------------------------------------------------------

### 49. Separation of Duties

No single routine identity should control the entire high-impact
lifecycle.

Engineering baseline:

``` text
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

An agent that creates a high-impact change must not independently
provide the final authorization for that same change.

------------------------------------------------------------------------

### 50. Dual Control for Critical Actions

Certain Crown Jewel actions require two distinct authorities or an
equivalent deterministic approval chain.

Examples:

``` text
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

``` text
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

Dual control must not be simulated by the same AI role approving itself
under two names.

------------------------------------------------------------------------

### 51. Privileged Access Management

Privileged access should be exceptional rather than permanent.

Target model:

``` text
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

Where platform capabilities allow: - prefer short-lived
credentials/tokens; - avoid persistent root/admin sessions; - log
privileged actions; - require stronger human authentication; - remove
dormant privileged identities; - periodically review access; - revoke
authority immediately after compromise.

AI agents should normally receive action-specific tool permissions
rather than general administrative credentials.

------------------------------------------------------------------------

### 52. High-Risk Action Classification

Actions are classified independently from the agent requesting them.

Suggested classes:

``` text
R0 — READ / LOW RISK
R1 — REVERSIBLE NON-PRODUCTION CHANGE
R2 — SENSITIVE / STAGING CHANGE
R3 — PRODUCTION OR CROWN JEWEL CHANGE
R4 — DESTRUCTIVE / COMPANY-WIDE / EMERGENCY
```

Example control:

``` text
R0 → normal scoped permission
R1 → scoped execution + audit
R2 → verification required
R3 → independent verification + Security Gate
R4 → Security Gate + Founder Gate + explicit recovery plan
```

Classification is deterministic where possible.

A model cannot lower the risk class of its own requested action.

------------------------------------------------------------------------

### 53. Transaction-Like Security for Consequential Actions

CEFFLO does not move customer money like a bank, but high-impact system
actions should be treated similarly to sensitive transactions.

For consequential actions evaluate:

``` text
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

``` text
ALLOW
CHALLENGE / REQUIRE APPROVAL
DENY
```

Examples include: - production deployment; - mass customer
communication; - bulk data export; - permission modification; -
destructive migration; - secret rotation; - workflow activation with
production authority.

------------------------------------------------------------------------

### 54. Blast-Radius Budgets

Every privileged tool or service identity should have a defined maximum
expected blast radius.

Examples:

``` text
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

If a capability could compromise the entire company from one identity,
it requires explicit architectural review.

------------------------------------------------------------------------

### 55. Crown Jewel Monitoring

Crown Jewels receive higher-sensitivity telemetry.

Monitor as applicable: - privileged login; - credential
creation/rotation; - permission changes; - production deployment; -
production database administrative operation; - security-policy
modification; - n8n credential/workflow modification; - GitHub
production-authority changes; - backup deletion/change; - kill-switch
modification; - abnormal bulk data access.

High-confidence anomalous activity may automatically restrict the
affected identity or capability while preserving evidence.

------------------------------------------------------------------------

### 56. Break-Glass Emergency Access

CEFFLO may maintain tightly controlled emergency access for recovery
when normal control paths fail.

Requirements:

``` text
BREAK-GLASS ACCESS
→ not used for routine work
→ strongly protected
→ Founder-controlled where practical
→ use generates CRITICAL audit event
→ limited duration
→ credentials rotated/resecured after use
→ mandatory incident/review record
```

Break-glass access must not become a permanent shortcut around security
architecture.

------------------------------------------------------------------------

### 57. Recovery Independence

A compromised production system must not be able to destroy every
recovery mechanism.

Where practical: - separate backup authority from ordinary application
authority; - restrict backup deletion; - maintain recovery information
outside the compromised runtime; - test clean restoration; - protect
critical configuration and deployment history; - preserve known-good
release references.

Goal:

``` text
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

------------------------------------------------------------------------

### 58. Banking-Style Security Mapping for CEFFLO

``` text
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

CEFFLO adopts the control philosophy, not unnecessary banking-scale
operational complexity.

------------------------------------------------------------------------

### 59. Updated High-Assurance Production Path

``` text
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

------------------------------------------------------------------------

### 60. High-Assurance Acceptance Tests

In addition to the base acceptance tests, verify:

1.  compromise of a development identity cannot directly administer
    production;
2.  Marketing/Customer Service credentials cannot access Crown Jewels;
3.  E2 cannot approve and ship its own material production change;
4.  Crown Jewel access creates auditable security telemetry;
5.  an R3/R4 action cannot lower its own risk classification;
6.  expired privileged authority can no longer act;
7.  break-glass usage generates an explicit security event;
8.  production compromise does not eliminate the recovery path;
9.  backup authority is sufficiently isolated from routine application
    authority;
10. a compromised agent remains inside its defined blast-radius budget;
11. Security Watch cannot autonomously accept a material risk;
12. Founder-gated actions cannot be completed by agent impersonation or
    workflow self-approval.

------------------------------------------------------------------------

### 61. Updated Security Doctrine Lock

CEFFLO Cyber Security now applies a high-assurance model:

``` text
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

**No single AI agent should possess end-to-end authority over a Crown
Jewel change.**

**Authentication does not equal unlimited trust.**

**High-impact actions are verified like sensitive transactions.**

**Recovery capability must survive compromise of the production
runtime.**

## FINAL LOCK

``` text
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

**AI may request an action. Security controls decide whether the action
is allowed.**

**Security intelligence stays current; security architecture stays
controlled.**

**One active architecture. One canonical truth path. No patch
mountain.**

------------------------------------------------------------------------

# PART III --- ROLE, SURFACE, INVITE & MEMBERSHIP ARCHITECTURE

This part is the approved product/access architecture. Role, surface and
shared backend workspace are distinct concepts. Backend authorization
remains authoritative.

## CEFFLO SURFACE, ROLE, INVITE & MEMBERSHIP ARCHITECTURE --- MASTER SPEC

**Status:** Approved product/access architecture\
**Scope:** Owner/Vendor, Operator, Helper, Rider/Driver, FOUNDR Admin\
**Purpose:** Lock Cefflo's role-to-surface architecture, shared backend
workspace, invitation routing, approval lifecycle, membership removal,
and related notification behaviour.

### 1. Core architecture

Cefflo separates three concepts:

1.  **Role** --- who the user is and what they may do.
2.  **Surface** --- which native app, PWA, or web experience they use.
3.  **Business workspace/backend** --- the shared operational data
    belonging to the business.

Different roles do not require separate databases. Owner and Operator
may work on the same business, orders, zones, runs, riders, and other
permitted operational records while having different permissions and
entry experiences.

Backend authorization/RLS remains authoritative. Hiding UI is never
sufficient security.

### 2. Canonical role → surface matrix

  -----------------------------------------------------------------------
  Role              Mobile            Desktop/browser   Native install
  ----------------- ----------------- ----------------- -----------------
  Owner / Vendor    Cefflo Vendor     Vendor Web /      Available;
                    native app        Vendor PWA        primary Owner
                                                        mobile surface

  Operator          Vendor PWA via    Vendor Web via    Not required
                    Operator Access   Operator Access   

  Helper            Helper PWA        Helper PWA where  Not required
                                      applicable        

  Rider / Driver    Cefflo Driver     No normal         Required for
                    native app        operational web   normal Driver
                                      surface           operation

  FOUNDR Admin      FOUNDR PWA        FOUNDR Web App    Not required
  -----------------------------------------------------------------------

PWA is a delivery surface, not a role.

### 3. Owner / Vendor

Owner has the broad/full approved business access.

Owner may use: - Cefflo Vendor native app on mobile. - Cefflo Vendor
Web/PWA on browser or laptop.

Both connect to the same business backend.

Owner uses the Owner/Vendor entry flow.

### 4. Operator

Operator is a limited business member, not a separate business.

Operator: - does **not** need the native Vendor app; - uses Vendor PWA
on mobile; - uses Vendor Web on desktop/browser; - has an explicit
**Operator Access** login/entry experience; - works against the same
business backend as Owner; - sees only Operator-approved capabilities.

Conceptually:

``` text
Vendor PWA / Web
→ Operator Access
→ Sign In / Sign Up as required
→ backend resolves membership = Operator
→ Operator-limited business workspace
```

Do not permanently clone the entire Vendor application merely to remove
menus. Prefer shared domain models, repository/backend logic, and
operational components with role-aware shells/navigation/capabilities.
This avoids Owner and Operator versions drifting apart.

Backend permission checks remain authoritative.

### 5. Helper

Helper uses the dedicated **Helper PWA**.

Helper must not be routed into the generic Owner Vendor login/workspace
simply because Helper belongs to the same business.

Flow:

``` text
Helper invite QR/link
→ Helper-specific join route
→ Helper Sign In / Sign Up
→ submit join request
→ Pending Owner approval
→ approved
→ Helper PWA fulfilment workspace
```

Helper must not inherit Owner or Operator access.

### 6. Rider / Driver

Rider uses the **Cefflo Driver native app** for normal delivery
operations.

Rider membership is scoped to a business. If multi-business membership
is supported, removing a Rider from Business A must not delete the
Rider's Cefflo account or membership in Business B.

### 7. FOUNDR Admin

FOUNDR is one administration web application:

``` text
Desktop browser → FOUNDR Web App
Mobile browser / Add to Home Screen → FOUNDR PWA
```

FOUNDR Web and PWA are not separate backend products.

Access requires `platform_admin` authorization and remains separate from
ordinary Vendor/Operator/Helper access.

### 8. Shared backend workspace

Conceptually:

``` text
                    CEFFLO BACKEND
                          │
                     Business ABC
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
      OWNER            OPERATOR           HELPER
   broad access      limited access     restricted
        │                 │                 │
 Vendor App/Web      Vendor PWA/Web      Helper PWA
```

The backend determines authenticated user, business membership, role,
membership status, and permitted actions.

Never create separate Owner, Operator, or Helper databases.

### 9. Invite context must survive authentication

A role invitation must retain: - business; - intended role; - invite
token; - correct destination/surface.

Bad:

``` text
Scan Helper QR
→ generic Vendor Sign In
→ invite/role context lost
→ wrong workspace
```

Required:

``` text
Scan Helper QR
→ Helper join route
→ auth if required
→ invite context preserved
→ submit Helper request
→ correct post-auth destination
```

Same principle applies to Operator and Rider.

### 10. Role-specific invite routing

Conceptually:

``` text
Operator invite → Operator Vendor PWA/Web join route
Helper invite   → Helper PWA join route
Rider invite    → Driver/Rider join route
```

Do not send all invite types through one Owner-oriented Vendor login.

### 11. Invite does not equal active membership

Possessing a QR/link must not automatically grant access.

Canonical lifecycle:

``` text
INVITE OPENED
→ AUTHENTICATED / REGISTERED
→ JOIN FORM SUBMITTED
→ PENDING OWNER APPROVAL
→ APPROVED or REJECTED
→ ACTIVE MEMBERSHIP only if APPROVED
```

This is especially important for permanent/shared QR links.

### 12. Team approval --- Operator and Helper

**Team must expose Pending requests.**

Conceptually:

``` text
TEAM
[ Members ] [ Pending ]
```

Pending contains Operator and Helper join requests.

Example:

``` text
Farah Ahmad
Operator
farah@example.com
Requested 5 min ago

[ Reject ]   [ Approve ]
```

Team approval is **Owner-only** unless product policy is explicitly
changed later.

Operator must not approve another Operator or Helper merely because
Operator can perform operational work.

### 13. Rider approval

Rider uses the equivalent pattern:

``` text
Riders
[ Active ] [ Pending ]
```

Flow:

``` text
Owner creates Rider invite
→ QR/link
→ Rider opens Driver join flow
→ auth/signup
→ submit
→ Pending
→ Owner reviews in Riders > Pending
→ Approve / Reject
→ approved Rider membership becomes active
```

### 14. Approval outcomes

#### Operator approved

Pending request → Owner Approve → Operator membership active → Vendor
PWA/Web → Operator workspace.

#### Helper approved

Pending request → Owner Approve → Helper membership active → Helper PWA.

#### Rider approved

Pending request → Owner Approve → Rider membership active → Driver App
access for that business.

#### Rejected

Rejected requests do not create/activate membership.

### 15. Already-member behaviour

If the recipient already belongs to the business in the relevant
capacity: - do not create a duplicate pending request; - do not create
duplicate membership; - show a clear state such as **"You're already
part of {Business Name}."** - route them to the appropriate permitted
workspace.

### 16. Join-request notifications

Submitting a real join request should notify the Owner through the
Cefflo Notification System.

Operator example:

``` text
Cefflo                         Just now
New Operator request
Farah wants to join your team.
```

Tap → `Team → Pending → Farah`.

Helper example:

``` text
Cefflo                         Just now
New Helper request
Amir wants to join your team.
```

Tap → `Team → Pending → Amir`.

Rider example:

``` text
Cefflo                         Just now
New rider request
Aiman wants to join your delivery team.
```

Tap → `Riders → Pending → Aiman`.

The temporary notification banner informs and deep-links. Do not put
Approve/Reject directly into the \~3-second banner. The actual decision
belongs on the review screen.

### 17. Pending request vs active membership

These are different operations.

#### Pending

User has no active membership yet.

Actions: - Approve - Reject

Reject does not require typing `CONFIRM`.

#### Active

User already has business access.

Removal is security-sensitive and requires stronger confirmation.

### 18. Removal terminology

Use: - **Remove member** for Operator/Helper. - **Remove rider** for
Rider.

Do not call normal membership removal "Delete account." The action
removes the relationship with the current business; it does not delete
the person's global Cefflo identity.

### 19. Active Team member removal

Owner removal flow:

``` text
Team > Members
→ select Operator/Helper
→ Remove member
→ destructive confirmation modal
→ type CONFIRM
→ destructive button enabled
→ backend revoke/remove membership
→ fresh backend read-back
→ verify access revoked
→ lightweight success toast
```

Suggested modal:

**Remove Sarah from your team?**

Sarah will lose access to this business and its permitted workspace.

**Type CONFIRM to continue.**

Input must match `CONFIRM` exactly before **Remove member** becomes
enabled.

### 20. Rider removal

Suggested modal:

**Remove Aiman as a rider?**

Aiman will lose access to this business and can no longer receive new
delivery assignments from this business.

**Type CONFIRM to continue.**

Input: `CONFIRM`

Button: **Remove rider**

Removal affects only the selected business membership.

### 21. Active-work safety

Typed confirmation is only a UI safety layer. Backend integrity checks
are still required.

Before Rider membership removal, check for blocking operational state
such as: - active run; - current delivery assignment; - another real
backend-defined dependency.

If unsafe:

``` text
remove request
→ backend rejects
→ explain dependency
→ Owner resolves/reassigns work
→ retry removal
```

Do not orphan active delivery work.

For Operator/Helper, enforce real backend dependencies if they exist; do
not invent dependencies merely for UI.

### 22. Removal authorization

Membership approval/removal is Owner-controlled business administration
unless explicitly changed later.

Operator cannot approve/remove Team members by default. Helper and Rider
cannot remove other members.

Backend enforcement is mandatory.

### 23. Removal persistence standard

Success means:

``` text
Owner confirms
→ backend mutation
→ success response
→ fresh membership read
→ membership absent/inactive
→ removed user can no longer access business
→ reload/re-auth check
→ state remains correct
```

A success toast alone is not proof.

### 24. Removal success feedback

After successful removal use lightweight UI feedback, for example: -
`Member removed` - `Rider removed`

This is a normal UI toast: - auto-dismiss; - no notification sound; - no
Notification Center record.

Whether the removed user receives a separate system notification is a
separate product decision and must not be fabricated without approval.

### 25. Owner vs Operator capability model

Conceptually:

``` text
OWNER
approved business administration
+ operations

OPERATOR
approved operations
- Owner-only administration
```

Current Owner-only areas may include Team administration, Business
Profile administration, membership approval/removal, and other
explicitly restricted settings.

Actual permissions must match current backend/product truth.

### 26. Layered authorization

Role restrictions should be coherent across:

``` text
UI capability visibility
+ route/surface guard
+ repository/API behavior
+ backend RPC/RLS authorization
```

Do not maintain unrelated permission systems that can drift.

### 27. Authentication cases for invites

Every role invite must handle:

**Already authenticated as correct account**\
Continue join flow.

**Authenticated as another account**\
Show current identity and **Use another account** while preserving
invite context.

**Existing account but signed out**\
Sign in, then resume invite.

**No account**\
Sign up/verify as required, then resume the same invite.

**Already a member**\
Show explicit already-member state.

At no point should invite token, role, or business context be lost.

### 28. Security rules

1.  Invite token alone does not grant active membership.
2.  Operator/Helper/Rider requests require Owner approval under this
    model.
3.  Operator cannot approve/remove Team members unless future policy
    explicitly permits it.
4.  Helper cannot escalate to Operator/Owner.
5.  Rider membership does not grant Vendor workspace access.
6.  Removing membership must actually revoke backend access.
7.  Membership for one business must not leak access to another.
8.  Multi-business Rider access remains business-scoped.
9.  UI hiding never replaces RLS/RPC authorization.
10. Invite role intent survives authentication.

### 29. Canonical end-to-end flows

#### Operator

``` text
Owner creates Operator invite
→ QR/link
→ Operator PWA/Web join route
→ Sign In / Sign Up
→ submit
→ Pending
→ Owner notification
→ Team > Pending
→ Approve / Reject
→ if approved: active Operator membership
→ Operator-limited Vendor workspace
```

#### Helper

``` text
Owner creates Helper invite
→ QR/link
→ Helper PWA join route
→ Sign In / Sign Up
→ submit
→ Pending
→ Owner notification
→ Team > Pending
→ Approve / Reject
→ if approved: active Helper membership
→ Helper PWA
```

#### Rider

``` text
Owner creates Rider invite
→ QR/link
→ Driver join route
→ Sign In / Sign Up
→ submit
→ Pending
→ Owner notification
→ Riders > Pending
→ Approve / Reject
→ if approved: active Rider membership
→ Driver App business access
```

### 30. Implementation guidance

Before changing architecture, inspect existing: - auth routes; - invite
tables/functions; - membership model; - join-request model; - RLS; -
role claims; - Vendor Web/PWA; - Helper PWA; - Driver join flow; - Team
UI; - Riders UI; - Notification System.

Reuse existing real backend capabilities wherever possible.

Do not begin by cloning apps.

Any new schema, RPC, or security-policy change must be justified against
staging truth and gated for approval where appropriate.

### 31. QA matrix

#### Operator

Verify invite generation, correct route, signup/sign-in invite
preservation, Pending request, Owner notification, Team Pending
visibility, Owner approval, restricted Operator access, typed-CONFIRM
removal, and post-removal access revocation.

#### Helper

Verify Helper route, auth preservation, Pending request, Owner
notification, Team Pending, approval, Helper PWA entry, typed-CONFIRM
removal, and access revocation.

#### Rider

Verify Driver join route, Pending request, Owner notification, Riders
Pending, approval, relevant business access, typed-CONFIRM removal,
active-work protection, and preservation of other business memberships.

#### Cross-role

Verify Operator cannot approve/remove Team members, Helper cannot enter
Owner/Operator workspace, unrelated users cannot access the business,
duplicate invites do not create duplicate membership, and already-member
handling is explicit.

### 32. Definition of done

This architecture is correctly implemented when: - every role enters the
correct surface; - Owner and Operator safely share one business backend
with different permissions; - Operator does not require native Vendor
app; - Helper remains in Helper PWA; - FOUNDR operates through
Web/PWA; - invite context survives authentication; - Operator, Helper,
and Rider requests remain Pending until Owner approval; - Team exposes
Pending Operator/Helper requests; - Riders exposes Pending Rider
requests; - Owner receives join-request notifications; - active
membership removal requires typed `CONFIRM`; - Rider removal protects
active operational work; - removal revokes only the intended business
relationship; - backend authorization remains authoritative.

### 33. Locked decisions

1.  Owner and Operator share the same Cefflo business backend/workspace.
2.  Owner has broader/full approved access; Operator has limited access.
3.  Owner uses Vendor native app and/or Vendor Web/PWA.
4.  Operator does not need the native Vendor app; Operator uses Vendor
    PWA/Web.
5.  Operator has its own Operator Access entry/auth experience.
6.  Helper uses the dedicated Helper PWA.
7.  Helper invite/auth must not fall into generic Owner Vendor Sign In.
8.  Rider uses the Driver native app.
9.  FOUNDR uses FOUNDR Web/PWA from one administration surface.
10. No separate Owner/Operator/Helper databases.
11. Do not blindly duplicate the full Vendor app for Operator; share
    operational modules while restricting surface/capabilities.
12. Operator/Helper/Rider invitation context survives sign-in/sign-up.
13. Invite submission creates **Pending**, not automatic membership.
14. Owner approves/rejects Operator/Helper in **Team → Pending**.
15. Owner approves/rejects Rider in **Riders → Pending**.
16. New join requests generate appropriate Owner notifications.
17. Notification tap should deep-link to the relevant Pending request
    where supported.
18. Rejecting a pending request does not require typed `CONFIRM`.
19. Removing an active Operator, Helper, or Rider is a destructive
    membership action.
20. Active membership removal requires typing **CONFIRM**.
21. Use `Remove member` / `Remove rider`, not account-deletion language.
22. Rider removal must not orphan active delivery work.
23. Multi-business Rider membership remains scoped to the selected
    business.
24. Removal requires backend read-back and access-revocation
    verification.
25. Ordinary removal success uses lightweight UI toast, not a Cefflo
    operational notification.

------------------------------------------------------------------------

### Final principle

**One backend workspace. Different roles. Correct entry surface.
Least-privilege access. Explicit Owner approval. Safe membership
removal.**

Cefflo should make collaboration easy without making access ambiguous.

------------------------------------------------------------------------

# PART IV --- ROLE / MEMBERSHIP SECURITY RECONCILIATION

This part applies the security model to invite, pending membership,
Owner approval, activation, removal, revocation, multi-business
isolation, notifications and role-specific attack tests.

## CEFFLO SECURITY RECONCILIATION --- ROLE, INVITE & MEMBERSHIP ADDENDUM

**Status:** Security reconciliation / additive control specification\
**Date:** 2026-09-30\
**Applies to:** Cefflo Cyber Security Master, Security/Privacy/Data
Protection Master, and the approved Surface/Role/Invite/Membership
Architecture\
**Authority:** Founder approval required for security-policy/schema
changes

> This document does **not** replace the existing Cefflo security
> masters. It reconciles the newly approved role, surface, invite,
> approval and membership lifecycle with Cefflo's existing zero-trust
> security model.

------------------------------------------------------------------------

### 1. Existing security principles remain authoritative

Preserve the established Cefflo security baseline:

-   zero trust;
-   deny by default;
-   least privilege;
-   server-authoritative authorization;
-   tenant/business isolation;
-   RLS on protected client-accessible data;
-   protected RPC/server-side authorization for sensitive actions;
-   service-role credentials are server-only;
-   clients are untrusted;
-   positive and negative authorization tests;
-   IDOR/BOLA testing;
-   protected storage paths;
-   secure session/token handling and revocation;
-   auditability for privileged/sensitive operations;
-   production security gate before launch.

A UI route, hidden menu, PWA shell, native app, deep link, or possession
of an invite token is never proof of authorization.

------------------------------------------------------------------------

## 2. Authorization tuple

Every sensitive request must establish, as applicable:

``` text
authenticated actor
+ active tenant/business membership
+ permitted role
+ resource ownership/scope
+ allowed action
+ valid current resource state
```

For invitation acceptance/approval/removal, membership **status** is
also security-significant.

`pending` is not equivalent to `active`.

------------------------------------------------------------------------

## 3. Surface is not a security boundary

Approved product surfaces:

  Role           Surface
  -------------- ------------------------------------
  Owner          Vendor native app + Vendor Web/PWA
  Operator       Vendor PWA/Web via Operator Access
  Helper         Helper PWA
  Rider          Driver native app
  FOUNDR Admin   FOUNDR Web/PWA

These surfaces improve routing and UX. They do not replace backend
authorization.

Examples:

-   Operator cannot gain Owner rights by manually navigating to an Owner
    URL.
-   Helper cannot gain Operator rights by calling Vendor RPCs directly.
-   A Rider token cannot be used to access Vendor business data.
-   FOUNDR routes require `platform_admin`, not merely access to the
    FOUNDR URL.

------------------------------------------------------------------------

## 4. Shared business workspace security

Owner and Operator may use the same underlying business workspace.

This does **not** mean identical permissions.

The backend must resolve the current business and active membership for
every protected action.

Minimum invariant:

``` text
Business A member
≠
permission to Business B
```

Cross-business reads/writes must fail even when the caller knows valid
UUIDs, order IDs, run IDs, storage paths, invite IDs or notification IDs
belonging to another business.

------------------------------------------------------------------------

## 5. Role privilege model

### Owner

Broad/full approved business administration and operations.

Owner-only security-sensitive capabilities include, where product policy
specifies:

-   Team approval;
-   Team membership removal;
-   Rider approval/removal;
-   Owner-only business administration;
-   other explicit Owner-only settings.

### Operator

Operational access only according to the approved capability matrix.

Operator must not inherit Owner privileges simply because Owner and
Operator share repositories, components, routes or backend tables.

### Helper

Restricted fulfilment access only.

Helper must not inherit general Vendor operational reads/writes unless
explicitly required by the approved Helper workflow.

### Rider

Driver/run-specific access scoped to authorized business relationships
and assigned operational resources.

### FOUNDR Admin

Platform-level privileges require explicit `platform_admin`
authorization and must remain isolated from ordinary business roles.

------------------------------------------------------------------------

## 6. Invite token security

An invite token is a capability to **begin a join flow**, not a
credential granting business access.

Possession of a valid invite token may expose only the minimum
information required to understand and complete the invitation.

It must not grant:

-   active membership;
-   business operational data;
-   Team data;
-   Orders;
-   Runs;
-   private storage;
-   Owner/Operator capabilities.

High-entropy invite tokens must remain non-enumerable and appropriately
scoped.

------------------------------------------------------------------------

## 7. Invite role integrity

The role encoded/resolved by an invite must be server-authoritative.

A client must not be able to:

``` text
receive Helper invite
→ alter payload to role=operator
→ gain Operator request/access
```

The backend must derive or validate:

-   business;
-   invite;
-   intended role;
-   invite validity;
-   invite status/expiry where applicable.

Client-provided role fields must not be trusted as authority.

------------------------------------------------------------------------

## 8. Invite context through authentication

Authentication may interrupt the join journey, but must not erase or
mutate the original invite security context.

Required cases:

-   already signed in as intended user;
-   signed in as another user;
-   existing account signed out;
-   new signup;
-   email verification;
-   session restoration.

After auth, the server must revalidate the invite before accepting a
join request.

Do not trust pre-auth client state alone.

------------------------------------------------------------------------

## 9. Pending is zero active privilege

Canonical lifecycle:

``` text
INVITE
→ AUTHENTICATED
→ REQUEST SUBMITTED
→ PENDING
→ APPROVED / REJECTED
```

Security invariant:

``` text
PENDING ≠ ACTIVE MEMBERSHIP
```

A pending Operator, Helper or Rider must not receive the permissions of
that role before approval.

RLS/RPC/storage policies must test active membership status where
membership is required.

------------------------------------------------------------------------

## 10. Owner-only approval

Under the approved product model:

-   Operator join request → Owner approval.
-   Helper join request → Owner approval.
-   Rider join request → Owner approval.

Approval authorization must be enforced server-side.

Negative tests must prove:

-   Operator cannot approve Operator;
-   Operator cannot approve Helper;
-   Helper cannot approve anyone;
-   Rider cannot approve anyone;
-   unrelated user cannot approve;
-   Owner of Business A cannot approve Business B request.

UI hiding is secondary.

------------------------------------------------------------------------

## 11. Approval transaction integrity

Approval must prevent:

-   duplicate active memberships;
-   approval of an invalid/revoked request;
-   role substitution;
-   cross-business approval;
-   replay creating duplicate membership.

Prefer one protected backend contract for the security-sensitive
transition where consistent with existing architecture.

Approval should be idempotent where appropriate.

After approval, perform fresh read-back of membership state.

------------------------------------------------------------------------

## 12. Rejection

Rejecting a pending request:

-   must be Owner-authorized;
-   must not create active membership;
-   must not leave temporary access behind;
-   should preserve an auditable request state where the current model
    supports it.

Typed `CONFIRM` is not required for rejecting a user who has never
gained active membership.

------------------------------------------------------------------------

## 13. Active membership removal

Removal is different from account deletion.

The security operation is:

``` text
revoke/remove user's membership
for Business X
```

It must not delete the user's global Cefflo identity.

For multi-business users, only the selected business relationship is
affected.

------------------------------------------------------------------------

## 14. Typed CONFIRM is UX protection, not authorization

The approved UI requires the Owner to type:

`CONFIRM`

before removing an active Operator, Helper or Rider.

This prevents accidental destructive actions.

It is **not** a security control.

The backend must independently prove:

-   caller identity;
-   caller is authorized Owner;
-   target membership belongs to the same business;
-   target role/removal is permitted;
-   current operational state allows removal.

An attacker bypassing the modal must still be denied if unauthorized.

------------------------------------------------------------------------

## 15. Removal revocation semantics

Successful removal must result in effective loss of protected business
access.

Verification must include:

``` text
remove membership
→ fresh membership read
→ membership inactive/absent
→ attempt protected read
→ denied/empty as appropriate
→ attempt protected write
→ denied
```

Do not declare removal complete from a UI success response alone.

Session/token behaviour must be tested so that a previously
authenticated removed member cannot continue protected access merely
because the client still holds a valid auth session.

Authentication may remain valid globally; **business authorization must
cease**.

------------------------------------------------------------------------

## 16. Rider active-work safety

Before removing a Rider, backend/domain logic must protect active
operational work.

At minimum inspect real current dependencies such as:

-   active run;
-   assigned undelivered stops;
-   current delivery assignment.

If removal would orphan active work:

``` text
remove
→ reject safely
→ identify dependency
→ Owner resolves/reassigns
→ retry
```

Do not rely on client-side checks only.

Do not invent blockers that do not exist in the actual domain model.

------------------------------------------------------------------------

## 17. Multi-business Rider isolation

If Rider belongs to multiple businesses:

``` text
remove Rider from Business A
```

must not:

-   delete Rider account;
-   revoke Business B membership;
-   remove Business B assignments/history;
-   expose Business B data to Business A Owner.

Every Rider membership/assignment operation must be business-scoped.

------------------------------------------------------------------------

## 18. Storage reconciliation

Storage authorization must follow the same role/membership model as
database access.

Test storage paths for:

-   Owner;
-   Operator;
-   Helper;
-   Rider;
-   unrelated authenticated user;
-   anonymous user where public assets are intentionally public.

### Current finding requiring reconciliation

The current staging audit found that **Helper can read original/private
product-media storage**.

Do not classify this as harmless without determining business need.

Required review:

1.  Identify exact bucket/path and policy.
2.  Identify why Helper qualifies.
3.  Determine whether any approved Helper workflow requires original
    product media.
4.  If not required, propose least-privilege tightening.
5.  Test Owner/Operator/product workflows for regression.
6.  Do not apply the security-policy change without Founder approval.

Public storefront display assets are a separate exposure decision from
private originals.

------------------------------------------------------------------------

## 19. Notification security

Notification records and deep links must respect normal authorization.

Requirements:

-   user can read only eligible notification records;
-   notification payload must not leak unauthorized business/resource
    data;
-   Owner join-request notifications must not expose another business;
-   deep-link destination rechecks authorization;
-   deleting/marking notifications cannot affect another user;
-   FOUNDR broadcast creation remains platform-admin only;
-   recipient targeting is resolved server-side.

A notification is never an authorization token.

------------------------------------------------------------------------

## 20. Operator PWA/Web security

Operator Access is a distinct entry experience, but the shared Vendor
backend must enforce Operator limits.

Attack tests should include direct calls to Owner-only functions from an
authenticated Operator.

Expected result: denied.

Test at minimum Owner-only actions identified by current product truth,
including Team administration and other restricted business settings.

------------------------------------------------------------------------

## 21. Helper PWA security

Helper PWA is an intentionally restricted surface.

Attack tests must assume the Helper can inspect network requests and
manually call backend endpoints.

Therefore prove that Helper cannot:

-   access Owner/Operator business administration;
-   enumerate unrelated business data;
-   escalate role;
-   approve membership;
-   remove membership;
-   access private storage without explicit business need;
-   invoke protected Vendor RPCs outside Helper scope.

------------------------------------------------------------------------

## 22. FOUNDR security

FOUNDR Web/PWA remains a privileged administration surface.

Preserve existing controls:

-   `platform_admin` server-side verification;
-   no demo/admin bypass;
-   no assumption that FOUNDR route possession equals admin rights;
-   privileged operations auditable;
-   service-role secrets never shipped to browser;
-   least privilege and separation of duties where applicable.

FOUNDR Broadcast authorization must remain platform-admin only.

------------------------------------------------------------------------

## 23. Session and stale-access tests

For Owner, Operator, Helper and Rider test:

-   valid session;
-   expired session;
-   revoked/removed business membership while auth session remains;
-   logout;
-   invalid token;
-   role/membership change during active session.

Important distinction:

``` text
403 authorization failure
≠ automatically expired login
```

Do not globally log users out for every authorization denial.

Session invalidation logic must distinguish authentication failure from
legitimate permission denial.

------------------------------------------------------------------------

## 24. IDOR / BOLA matrix

For every sensitive identifier, attempt substitution with another
business/resource.

Include:

-   business_id;
-   member_id;
-   join_request_id;
-   invite token/id;
-   order_id;
-   run_id;
-   rider membership;
-   notification_id;
-   storage path/object;
-   storefront administrative resources.

Test both reads and writes.

Knowing an identifier must never grant access.

------------------------------------------------------------------------

## 25. RPC security contract

Every security-sensitive RPC should document:

``` text
allowed caller
required role
business/tenant resolution
resource ownership/scope
membership status requirement
allowed state transition
inputs
outputs
idempotency/replay behavior
SECURITY DEFINER implications
abuse/rate considerations where relevant
```

`SECURITY DEFINER` must not bypass tenant/role checks.

Explicit grants should remain minimum necessary.

------------------------------------------------------------------------

## 26. Audit logging

Security-significant actions should be auditable where the existing
audit architecture supports them.

Priority events:

-   membership approved;
-   membership rejected where useful;
-   active member removed;
-   role changed, if supported;
-   privileged FOUNDR action;
-   security-sensitive business setting changes;
-   policy/admin operations.

Logs must not expose secrets or unnecessary sensitive payloads.

------------------------------------------------------------------------

## 27. Abuse controls for invite flows

Invite/join endpoints should consider:

-   high-entropy tokens;
-   anti-enumeration responses;
-   duplicate-request handling;
-   replay/idempotency;
-   reasonable rate limiting;
-   token revocation/rotation where supported;
-   prevention of role tampering.

Do not add friction that breaks normal invite use without a concrete
threat model.

------------------------------------------------------------------------

## 28. Required negative test matrix

Minimum:

  -----------------------------------------------------------------------
  Actor                   Attempt                 Expected
  ----------------------- ----------------------- -----------------------
  Pending Operator        read Operator business  DENY
                          data                    

  Pending Helper          use Helper active       DENY
                          workspace               

  Pending Rider           receive active Rider    DENY
                          privileges              

  Operator                approve Team request    DENY

  Operator                remove Team member      DENY

  Helper                  approve/remove          DENY
                          membership              

  Rider                   access Vendor workspace DENY

  Business A Owner        approve/remove Business DENY
                          B member                

  Removed Operator        protected business      DENY
                          read/write              

  Removed Helper          protected               DENY
                          Helper/business access  

  Removed Rider           new Business A          DENY
                          operational access      

  Unrelated user          resolve protected       DENY
                          business resources      

  Helper                  private product         DENY unless explicitly
                          originals               required/approved

  Non-platform-admin      FOUNDR privileged       DENY
                          operation               
  -----------------------------------------------------------------------

Also test the positive counterpart for every allowed action.

------------------------------------------------------------------------

## 29. Production security gate additions

Before production release of the new membership architecture, evidence
must prove:

1.  Invite token does not grant membership.
2.  Pending users have zero active-role privileges.
3.  Invite role cannot be escalated by payload manipulation.
4.  Owner-only approval is enforced server-side.
5.  Cross-business approval/removal fails.
6.  Duplicate/replayed approval does not create duplicate membership.
7.  Active removal revokes protected access.
8.  Rider removal cannot orphan active work.
9.  Multi-business Rider isolation holds.
10. Operator direct-call attempts to Owner-only APIs fail.
11. Helper privilege-escalation/direct-call attempts fail.
12. Deep links reauthorize at destination.
13. Storage policies match approved role needs.
14. Helper original-media finding is resolved or explicitly approved
    with documented rationale.
15. Session/auth failures are distinguished from authorization failures.
16. Security regression tests are retained in the suite.

Critical/High security findings remain launch blockers under the
existing security gate.

------------------------------------------------------------------------

## 30. Implementation rule for Claude/Codex

When reconciling the repo:

**Inspect first. Do not blindly migrate.**

For each requirement classify:

-   already secure and verified;
-   implemented but unverified;
-   gap fixable without security-policy change;
-   requires schema/RPC/RLS/storage-policy change;
-   intentionally deferred.

For RLS, privileged RPC, schema, or storage-policy changes:

1.  show current staging truth;
2.  show exploit/failure scenario;
3.  propose least-privilege change;
4.  show regression impact;
5.  obtain Founder approval where required;
6.  apply to staging only;
7.  run positive + negative tests;
8.  provide evidence;
9.  production remains untouched until gate approval.

Never weaken a policy merely to make a UI flow pass.

------------------------------------------------------------------------

## 31. Source-of-truth relationship

Use the documents as complementary authorities:

``` text
CEFFLO_CYBER_SECURITY_MASTER
        │
        ├── company-wide security architecture
        │
CEFFLO_SECURITY_PRIVACY_AND_DATA_PROTECTION_MASTER
        │
        ├── product/data protection controls
        │
CEFFLO_SURFACE_ROLE_INVITE_MEMBERSHIP_ARCHITECTURE_MASTER_SPEC
        │
        ├── approved product role/surface/membership behaviour
        │
THIS RECONCILIATION ADDENDUM
        │
        └── security implications + mandatory verification
```

If product UX and security appear to conflict, do not silently weaken
security. Escalate the exact conflict for Founder decision.

------------------------------------------------------------------------

## 32. Locked reconciliation decisions

1.  Shared backend does not mean shared privilege.
2.  Surface separation is UX/routing, not authorization.
3.  Invite token grants join-flow access only.
4.  Pending membership grants zero active-role privilege.
5.  Invite role/business scope is server-authoritative.
6.  Operator/Helper/Rider activation requires Owner approval under the
    approved model.
7.  Approval/removal is server-authorized and business-scoped.
8.  `CONFIRM` protects against accidental clicks but never replaces
    backend authorization.
9.  Removing membership must revoke protected business access even if
    global auth session remains valid.
10. Multi-business Rider relationships remain isolated.
11. Deep links and notifications never bypass authorization.
12. Storage follows least privilege independently of UI.
13. Helper access to original product media must be explicitly justified
    or tightened.
14. Clients remain untrusted across Native, Web and PWA.
15. Production release requires positive and adversarial evidence, not
    only green UI tests.

------------------------------------------------------------------------

### Final security principle

**Authenticate identity. Authorize every action. Scope every resource.
Trust no client. Activate access only after approval. Revoke access at
the backend, not merely in the UI.**

------------------------------------------------------------------------

# FINAL CANONICAL LOCK

Cefflo operates one active security architecture.

**Authenticate identity. Authorize every action. Scope every resource.
Trust no client. Activate access only after approval. Revoke access at
the backend, not merely in the UI.**

**One backend workspace. Different roles. Correct entry surface.
Least-privilege access. Explicit Owner approval. Safe membership
removal.**

**Security intelligence stays current; security architecture stays
controlled.**

**Implementation + negative test + regression test + evidence +
documented residual risk = complete.**

No unresolved P0/Critical finding may enter production.
