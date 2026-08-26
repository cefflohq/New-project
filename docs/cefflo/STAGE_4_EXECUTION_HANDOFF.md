# CEFFLO — Stage 4 Execution Handoff

Status: Phase 1 baseline lock; Stage 4 execution not yet authorized

Code/evidence baseline: GitHub `main` at
`5223d16b6497832334fe369551b0757af4409c02`

## 1. Phase 1 result

Phase 1 is complete. Authoritative evidence is recorded in:

- `PHASE_1_REPOSITORY_INVENTORY.md`;
- `PHASE_1_ACTIVE_LEGACY_CLASSIFICATION.md`;
- `PHASE_1_DEPLOYMENT_DOMAIN_MAP.md`;
- `PHASE_1_PRODUCT_LIFECYCLE_BASELINE.md`;
- `PHASE_1_BACKEND_SECURITY_BASELINE.md`;
- `PHASE_1_STAGE4_GAP_REPORT.md`.

Founder decisions are locked in `05_DECISIONS.md`. Current verified state is
summarized in `04_CURRENT_STATE.md`. The approved 16-sprint dependency sequence
in `PHASE_1_STAGE4_GAP_REPORT.md` is the Stage 4 execution authority.

## 2. Execution rules

1. Preserve existing Vendor, Rider and Customer UI shells and protected backend
   foundations wherever practical; integrate/adjust rather than rebuild.
2. Define and secure backend contracts before integrating dependent UI.
3. Preserve the working protected happy path while closing direct-write,
   cross-business, POD, token and mock-truth bypasses.
4. Run applicable negative, storage, lifecycle and cross-app tests in an
   explicitly isolated environment before production.
5. Never treat mock/local state, historical PASS, documentation intent or an
   unverified deployment as production truth.
6. Obtain Founder approval before protected infrastructure, environment,
   migration, RLS, Auth, secret, production, DNS, recovery or rollback actions.
7. Do not bypass sprint dependencies or the release/Go-Live gates.

## 3. Exact first Stage 4 sprint — S4-01

**Objective:** establish isolated preview/staging/test configuration and an
explicitly disposable test target so database, RLS, storage and E2E suites can
run without any path to production mutation.

P1.7 authorizes this objective and baseline only. It does **not** authorize
creating projects, changing provider settings, writing secrets, modifying
production configuration, running mutating tests or applying infrastructure.
Those S4-01 actions require a separate execution request and Founder approval
where protected.

### Entry criteria

- clean `main` synchronized with `origin/main` at the approved Phase 1 lock;
- S4-01 scope limited to environment/test isolation;
- provider/project ownership and proposed target topology identified read-only;
- explicit proof that every test target is non-production and disposable;
- secret-handling, cost, access, teardown and rollback plan reviewed;
- no application/RLS/lifecycle remediation mixed into S4-01.

### Acceptance gate

- preview, staging/test and production identities are unambiguous and separated;
- build/runtime configuration selects the intended environment without committed
  secrets or production fallback;
- database-mutating tests contain a fail-closed production guard;
- a disposable target can be reset/recreated and is documented;
- static validation and a harmless connectivity check pass;
- no production data/configuration is changed;
- exact diff, external actions, validation and remaining risks are reviewed;
- Founder approves any protected provider/environment creation or secret change.

### Next-sprint dependency

S4-02 may begin only after S4-01 passes. S4-02 finalizes the Owner/operator/
member/Rider/Customer permission matrix and protected backend contract design.
No RLS or lifecycle remediation begins before that design and its approvals.

## 4. Remaining S4-01 blocker

No unresolved product decision blocks S4-01 planning. Execution is blocked until
the Founder separately authorizes the proposed environment topology, provider
resources/access, secret handling and any cost-bearing or external changes after
read-only discovery identifies the exact targets.
