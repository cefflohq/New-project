# CEFFLO — ACTIVE EXECUTION CHECKPOINT

Updated: 2026-08-29 (Codex). S4-01–S4-06 are COMPLETE / FOUNDER APPROVED. S4-07 Batches 1+3 are LOCAL COMPLETE. **S4-07.3a is LOCAL PASS, STAGING PASS, CLOSURE PASS, and FOUNDER APPROVED** (Sections 77–80). Its staging migration `202608290004` is applied; `202608290002/003` remain local-only and are authorized for commit only, not staging application. Dependency-complete local Git history recovery is authorized; push remains Founder-gated. Production remains untouched. S4-08 has not started.
Active agent: Codex
Current Stage: Stage 4
Current Sprint: S4-07.3a closure / dependency-complete local Git history recovery
Current Sub-sprint / Work Package: Construct nine approved ordered local commits; do not push.
Status: S4-07.3a CLOSURE PASS. Local commit-chain construction authorized. Staging and Production access are prohibited for this gate.

## 1. Current Objective
Construct and verify the Founder-approved nine-commit dependency-complete local history through S4-07.3a while preserving excluded working-tree changes. Do not push or start S4-08.

## 2. Last Confirmed Completed Action
Per the AI_CONTINUITY_README.md initial checkpoint (Section 15), the last confirmed completed action prior to this handoff was: manual interactive `psql` authentication against `cefflo-staging` via the official Supabase Session Pooler eventually succeeded, after a password-propagation delay. This is an asserted prior-session result, not independently re-verified in this session (no provider access performed here — out of scope for this task).

## 3. Work Completed
Carried over from AI_CONTINUITY_README.md §15 (asserted by prior session, not re-verified this session):
- Working directory/repository access established.
- Docker host works.
- Environment identity contract implemented.
- Production fallback removed.
- Fail-closed Production guards implemented.
- Local disposable Supabase implemented.
- Local reset/recreation PASS.
- Environment/negative guard tests PASS (30/30 at latest hosted-readiness verification).
- Local backend validation PASS.
- Local transactional E2E PASS.
- Hosted readiness PASS.
- `cefflo-staging` created in Mumbai/South Asia.
- Staging foundation migration applied.
- Hosted schema/RLS/storage validation PASS.
- `cefflo-pod` private bucket verified.
- Manual `psql` Session Pooler authentication PASS (after propagation delay).

Confirmed this session (independently verified):
- Repository is present, readable, and writable at `/home/cefflo/New-project`.
- Git repository valid; branch and HEAD confirmed (see Section 5).
- Docker daemon accessible (`docker info` succeeded).
- `git diff --check` passes — no whitespace/conflict-marker errors in the current diff.
- `AI_CONTINUITY_README.md` installed verbatim at repository root.
- `tests/environment_guard.py` + `tests/check_target_identity.py` are the real, existing non-mutating authentication-check harness for S4-01E: fail-closed target validation (blocks Production by ref/host/username, requires positive staging identity match via `db.<ref>.supabase.co` or `<region>.pooler.supabase.com` + `.<ref>` username suffix), then one read-only query, printing only sanitized fields (never the URL/password). Code reviewed, not modified.
- `psycopg` (3.1.17) is installed and importable — the check's only runtime dependency is satisfied.
- None of the required env vars (`CEFFLO_ENVIRONMENT`, `CEFFLO_SUPABASE_PROJECT_REF`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `DATABASE_URL`, `CEFFLO_DISPOSABLE_TARGET`) are set in this session's shell (presence-only check, no values read or printed).
- No `.env` file exists anywhere in the repo (only `.env.example`, placeholders only).
- No secret-manager CLI is present on PATH (`vault`, `op`/1Password, `aws`, `gcloud` all absent).
- DNS resolution to `supabase.co` succeeds from this host, so network egress is plausible — but this is moot without a credential.
- No repository doc describes any capture mechanism beyond "export these into your shell before running the tooling" (per `.env.example`'s own comment).
- Non-mutating staging authentication/identity check (`tests/check_target_identity.py`) reported **PASS** by the credential holder, executed out-of-band directly in the VPS shell (credential exported there, never entered chat or any tool-call transcript). Sanitized result reported: `environment=staging`, `project_ref=tomvvmwktehexwhktenw`, `database_host=aws-0-ap-south-1.pooler.supabase.com`, `database=postgres`, `mutating=false`, `supabase_origin=https://tomvvmwktehexwhktenw.supabase.co`. This session did not execute the check itself and did not witness raw output — recorded as credential-holder-attested, consistent with the safe out-of-band handoff this session recommended.
- Reviewed (read-only, no edits) `tests/e2e_transaction.py`, `tests/validate_backend.py`, `package.json` to build the hosted transactional E2E execution plan (see Section 10/11). `e2e_transaction.py` performs its mutations inside a single psycopg connection/transaction and explicitly calls `conn.rollback()` on success; psycopg3's connection context manager auto-rolls-back on any exception, so the script is self-cleaning by construction — consistent with why it's labeled "transactional E2E."
- Hosted S4-01E transactional E2E run reported **PASS** by the credential holder, executed out-of-band in the VPS shell (same pattern as the identity check — credential never entered chat or any tool-call transcript): preflight `validate_backend.py` → `backend_contract_ok`; `e2e_transaction.py` → `e2e_transaction_ok`; closing `validate_backend.py` → `backend_contract_ok`. Credential and mutation env vars (`DATABASE_URL`, `CEFFLO_DISPOSABLE_TARGET`, `CEFFLO_ALLOW_MUTATING_TESTS`, etc.) were reported removed from the shell after execution. Not independently executed or witnessed by this agent session.

## 4. Files Changed / Added
Modified (uncommitted, pre-existing Codex work — preserved untouched):
- `.env.example`
- `.gitignore`
- `README.md`
- `package.json`
- `scripts/build-static.mjs`
- `shared/config.js`
- `tests/e2e_transaction.py`
- `tests/validate_backend.py`
- `vendor/index.html`

Untracked (pre-existing Codex work — preserved untouched):
- `package-lock.json`
- `scripts/check-environment.mjs`
- `scripts/environment.mjs`
- `supabase/config.toml`
- `tests/__init__.py`
- `tests/check_target_identity.py`
- `tests/environment_guard.py`
- `tests/guarded_supabase_reset.py`
- `tests/test_environment_guard.py`

Added this session:
- `AI_CONTINUITY_README.md` (installed verbatim, per Founder-supplied canonical file)
- `AI_ACTIVE_CHECKPOINT.md` (this file)

## 5. Current Git State
- Branch: `main`
- HEAD: `15a551bdb26b79536138f16bd1370e3dfb4c4a5a` ("Lock Phase 1 baseline and Stage 4 handoff")
- Working tree: NOT clean — 9 modified files, 9 untracked files (see Section 4)
- Uncommitted changes: Yes, intentional/pre-existing Codex work-in-progress for S4-01E (environment identity/guard contract, disposable Supabase config, updated tests). Not created or altered by this session.
- Commit/push status: No commits or pushes made or authorized this session.

## 6. Tests / Verification
- No E2E tests were run this session (explicitly out of scope).
- `git diff --check`: PASS (exit 0, no output).
- `tests/check_target_identity.py` (the non-mutating staging authentication check): **PASS** — reported by credential holder, run out-of-band in the VPS shell (see Section 7/8 for the sanitized result and provenance caveat; not independently observed by this agent session).
- `tests/validate_backend.py` (pre-E2E, schema/RPC/RLS/storage contract check): **PASS** — reported result `backend_contract_ok`, run out-of-band by credential holder.
- `tests/e2e_transaction.py` (hosted transactional E2E): **PASS** — reported result `e2e_transaction_ok`, run out-of-band by credential holder.
- `tests/validate_backend.py` (post-E2E closing integrity check): **PASS** — reported result `backend_contract_ok`, run out-of-band by credential holder.
- All three above are credential-holder-attested, executed in the VPS shell out-of-band; this agent session did not run them or see raw output, consistent with the credential never entering chat/tool transcripts.

### Vercel Preview/Staging Preflight (read-only, this session)
- Reviewed `vercel.json`, `scripts/build-static.mjs`, `docs/cefflo/13_VERCEL.md`, `.gitignore`, current `dist/shared/config.js` build artifact (built for `local`, no Production/staging ref present, gitignored/uncommitted).
- Confirmed frontend build (`resolveFrontendEnvironment()` in `scripts/environment.mjs`) reads exactly four inputs — `CEFFLO_ENVIRONMENT`, `CEFFLO_SUPABASE_PROJECT_REF`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` — fail-closed against the Production ref/host, same as the Python backend guard.
- Read-only Vercel MCP calls (`list_teams`, `list_projects`, `get_project`, `list_deployments`) — no writes: project `new-project` (`prj_Hn5d30wSQ7iTF4TPutWkzPvrcgMD`), team `cefflohq26-6353s-projects` (Hobby plan), linked to GitHub `cefflohq/New-project`.
- **All 17 historical deployments target `production`**, all from pushes to `main`. No Preview deployment has ever occurred; no Staging environment exists. Attached domain: `vendor.cefflo.com` only — `rider.cefflo.com`/`track.cefflo.com` are referenced in `vercel.json` rewrites but not attached/resolving (matches earlier Phase 1 doc finding).
- **Critical safety finding:** `main` is the Production branch with GitHub auto-deploy active — a `git push` to `main` on this repo triggers an immediate live Production Vercel deployment. This is a materially sharper constraint than a plain "don't commit" rule.
- Vercel team is on the **Hobby plan**, which does not support native Custom Environments (a true third named environment beyond Production/Preview). A "Staging" surface would need to be realized either via a dedicated branch deployed through Vercel's automatic Preview mechanism (with branch-scoped env var overrides) or a second separate Vercel project — this choice needs Founder authorization before any implementation.
- No Vercel environment variables were read, listed, or modified this session (avoided entirely, to prevent any possibility of secret values entering this transcript).
- All other test/verification results in Section 3 ("Confirmed completed") are carried over from the prior session's narrative in `AI_CONTINUITY_README.md` §15 and remain **NOT RE-VERIFIED** this session.

## 7. Provider / External State
- Supabase: `cefflo-staging` (ref `tomvvmwktehexwhktenw`) — staging reachability and identity now confirmed via non-mutating check, reported PASS by credential holder (host `aws-0-ap-south-1.pooler.supabase.com`, db `postgres`). This session did not query Supabase directly (no MCP/API calls made) and relies on the credential holder's attested sanitized result. Production ref `lmaxtrubwdniovxyuqdy` remains prohibited for non-production testing.
- Vercel: Project `new-project` exists (team `cefflohq26-6353s-projects`, Hobby plan), linked to GitHub `cefflohq/New-project`, `main` = Production branch with auto-deploy. All 17 historical deployments are Production-target; no Preview deployment has ever occurred; no Staging environment exists (Hobby plan lacks Custom Environments). Only `vendor.cefflo.com` is an attached domain. Preview/Staging configuration itself remains not started, deferred until Founder picks a scoping strategy and authorizes it (see Section 10).
- Docker: Confirmed accessible this session (`docker info` succeeded). No state changed.
- DNS/Cloudflare: Not applicable at this sub-sprint.
- Other: No provider state was created, modified, or rotated this session.

## 8. Secrets / Sensitive State
- Staging DB password: confirmed working. Credential holder exported it directly into the VPS shell out-of-band and ran the non-mutating identity check there; the value never entered this chat session or any tool-call transcript. This session still has not seen, requested, or persisted the value anywhere.
- The originally-reported discrepancy (manual `psql` success vs. automated ephemeral-secret-capture failure) is now considered **resolved in effect** — a correctly-captured credential authenticates successfully via the same fail-closed harness the automated E2E will use. Root cause of the earlier mismatch was not diagnosed by this session (nothing to diagnose was ever present here); it is treated as moot now that a working out-of-band capture has been demonstrated.
- No secret values were read, generated, printed, rotated, or requested from the user this session. The credential must continue to be supplied only via the out-of-band shell path, never via chat.

## 9. Current Blocker
**NONE for S4-01 — closed (Section 17).** The Vercel env-var capability gap was resolved out-of-band by the Founder/credential holder (variables configured directly, redeploy succeeded — see Section 17 evidence). S4-01's isolation was independently verified by a dedicated security review (Section 17).

S4-02 has **no blocker** either — it is a design/decision sprint with no infrastructure dependency. It is simply **not started**, pending Founder go-ahead for the execution agent (Section 19/20).

## 10. NEXT EXACT ACTION
See Section 20 (S4-02 Execution Plan) — first batch is **S4-02.A: draft the Owner/Operator/Member permission matrix + protected-backend-contract design document** for Founder review. This is a design/documentation task, not a code change. **Not started this turn** — awaiting explicit Founder instruction to hand it to the execution agent.

## 11. After That
- S4-02.A Founder review/approval → S4-02.B (draft schema/contract changes as a reviewable, unapplied migration) → S4-02 acceptance → S4-03 (RLS/direct-write repair) becomes eligible.
- Full S4-02 sequence in Section 20.

## 12. DO NOT DO
- Do not access or modify Production.
- Do not use Production credentials.
- Do not start S4-03 or later before S4-02's design is Founder-approved.
- Do not begin any S4-02 implementation before Founder explicitly hands it to the execution agent.
- Do not apply/deploy any RLS or permission-enforcement change as part of S4-02 — S4-02 is design/decision only; enforcement is S4-03 (see Section 19, explicit handoff-doc quote).
- Do not commit/push unless authorized.
- Do not change Docker host security/permissions.
- Do not reset, restore, stash, or overwrite existing Codex/Claude work.
- Do not paste any credential into chat/agent conversation under any circumstance — it must reach the shell/provider dashboard out-of-band.
- **HARD RULE (Founder-approved, permanent — Section 16.2):** `main` = Production deployment trigger. Never push or merge to `main` without explicit Founder Production authorization, regardless of sprint or urgency. S4-02 work continues on `staging` unless Founder explicitly changes that.

## 13. Acceptance Gate Remaining (S4-01 — CLOSED, see Section 17)
- Non-mutating staging authentication/identity check: **PASS**.
- Pre-E2E `validate_backend.py`: **PASS** (`backend_contract_ok`).
- S4-01E hosted transactional E2E (`e2e_transaction.py`): **PASS** (`e2e_transaction_ok`).
- Post-E2E `validate_backend.py`: **PASS** (`backend_contract_ok`).
- `staging` branch created + pushed to origin: **DONE** (`607d768d270734f21a8c605eb60abdd600917bc6`).
- Vercel Preview environment configured for `staging`: **DONE** (Founder/credential holder, out-of-band).
- Vercel Preview deployment: **READY** (`dpl_AMfHEd5QogJpvMfGpWcTK5veMaFp`).
- Independent staging-isolation security review: **PASS** (all 11 verification-matrix items PASS; see Section 17).
- **S4-01 sprint acceptance: CLOSED. S4-02 is eligible to begin (not yet started).**

## 14. Production Safety
- Production accessed: NO
- Production modified: NO
- Production credentials used: NO
(Reaffirmed after hosted transactional E2E PASS — all E2E activity was scoped to `cefflo-staging` per `environment_guard.py`'s fail-closed Production-ref/host/username checks; no Production interaction of any kind occurred.)

## 15. Recovery Notes
- This session performed two atomic units: (1) continuity-protocol install/checkpoint creation (documentation-only), (2) diagnostic investigation of the S4-01E password-capture blocker (code review + environment presence-checks only, no mutation, no provider access, no secret handling).
- The existing uncommitted working tree (9 modified + 9 untracked files, listed in Section 4) predates this session and was left completely untouched throughout both atomic units; verify `git status --short` still matches Section 4 exactly before resuming.
- Diagnosis narrowed the blocker: it is credential-absence in the execution environment, not a confirmed code bug. `environment_guard.py` and `check_target_identity.py` were read in full and are believed correct and safe to run as-is; neither was modified. If a future agent suspects a real bug in these files (e.g. password special-character encoding when building `DATABASE_URL`), that still needs to be checked once a real credential is available to test against — this session had nothing to test with.
- No provider (Supabase/Vercel) state was queried this session, so provider claims in Section 7 are unverified carry-overs — confirm current provider state independently before acting on it.
- If the next agent is told the credential has since been placed in the shell environment, re-run the presence-only check pattern from Section 3 before trusting it, then run the exact command in Section 10 — do not have the value typed into any chat interface first.
- `AI_CONTINUITY_README.md` now includes a "Context Budget Amendment" (appended, not a rewrite of prior content): default post-switch recovery scope is capped at this checkpoint + current git diff/status + current sprint canonical docs + a max of 3–8 files directly relevant to the recorded NEXT EXACT ACTION. Full-repository scans are prohibited by default; allowed only on a material checkpoint/Git conflict, an explicit release/security gate, an unresolvable blocker within the bounded scope, or explicit Founder authorization. Any future recovery routine (§3 of the README) must observe this cap.
- Hosted S4-01E transactional E2E PASS (Section 6/9/13) is credential-holder-attested, out-of-band — not independently witnessed by any agent session. If a future release/security gate requires it, an agent could independently re-run `validate_backend.py` (non-mutating) to spot-check current staging schema/RLS state without re-running the mutating E2E, but per the No Duplicate Re-Audit / Context Budget rules this should only happen if there's a specific reason to doubt the reported result, not as routine re-verification.
- S4-01 is NOT yet closed: the remaining acceptance item is Vercel Preview/Staging configuration + deployment acceptance, which requires separate Founder authorization before any actual Vercel provider change. The next agent must treat "E2E passed" and "S4-01 complete" as distinct facts — do not start S4-02 on the strength of the E2E result alone.

## 16. Founder-Approved Staging Architecture & Hard Safety Rule (recorded this turn — NOT executed)

### 16.1 Approved architecture
- Dedicated long-lived `staging` Git branch.
- Vercel Preview deployments built from `staging` (Option A from the prior preflight — no second Vercel project).
- Reuse existing Supabase `cefflo-staging` (ref `tomvvmwktehexwhktenw`) — no new Supabase project.
- `main` remains the Production branch, unchanged.

### 16.2 NEW HARD SAFETY RULE (in force immediately)
**Any push or merge to `main` is a Production deployment action**, because GitHub auto-deploy is active on this Vercel project. Never push or merge to `main` without explicit Founder Production authorization — this applies regardless of sprint, urgency, or how trivial the change looks.

### 16.3 Exact Vercel Preview environment variables (names + sanitized values)
```
CEFFLO_ENVIRONMENT=preview
CEFFLO_SUPABASE_PROJECT_REF=tomvvmwktehexwhktenw
SUPABASE_URL=https://tomvvmwktehexwhktenw.supabase.co
SUPABASE_PUBLISHABLE_KEY=<cefflo-staging publishable/anon key — not fetched this session>
```
The publishable/anon key is not a secret by design (safe for frontend, protected by RLS), but its actual value was deliberately not retrieved this turn since it wasn't required for planning and no Supabase provider call was requested — retrieve it at actual configuration time (e.g. via the project's publishable-key lookup), not before.

### 16.4 Safest sequence to create/use `staging` without touching `main`
1. Pre-check (no mutation): `git branch --show-current` (expect `main`), `git rev-parse HEAD` (expect `15a551bdb26b79536138f16bd1370e3dfb4c4a5a`), `git status --short` (expect the exact 9-modified/9-untracked list in Section 4) — confirms nothing drifted since this was last recorded.
2. Create and switch to the new branch from the current HEAD: `git switch -c staging` (equivalently `git checkout -b staging`). This only moves the branch pointer/HEAD; it does **not** alter the working tree or index, so all current uncommitted modified/untracked files remain exactly as they are, now simply "on" `staging` instead of `main`. `main`'s ref is untouched and still points at the same commit.
3. Verify immediately after: `git branch --show-current` → `staging`; `git status --short` → identical file list to Section 4; `git log -1 --oneline main` (or `git rev-parse main`) still resolves to the unchanged commit — proves `main` was not touched.
4. Stage explicitly by name (never `git add -A`/`git add .`, to avoid sweeping in anything unexpected) exactly the files listed in Section 4, and commit onto `staging` — this becomes the staging branch's baseline. (Commit itself is not authorized this turn.)
5. Push only `staging` to the remote: `git push -u origin staging`. This is a push, but not to `main`, so per Section 16.2 it does not require Production authorization and does not trigger a Production deployment — it will trigger a Vercel Preview build once Section 16.5 is configured. (Push itself is not authorized this turn.)
6. `main` is never checked out, merged into, reset, or fast-forwarded at any point in this sequence.

### 16.5 Whether current uncommitted S4-01 work can safely become the `staging` baseline
**Yes, safely**, because:
- `git switch -c staging` branches from the current commit without touching the working tree/index — the uncommitted Codex/Claude work (the same 9 modified + 9 untracked files verified unchanged at every checkpoint update this session) carries over byte-for-byte onto `staging`.
- No destructive operation (`reset`, `checkout -- <path>`, `stash`, `clean`) is used anywhere in the sequence, so nothing is lost or overwritten.
- `main` is never the target of any write in this sequence, so it stays exactly at `15a551bdb26b79536138f16bd1370e3dfb4c4a5a` throughout — satisfying "Codex/Claude work preserved" and "`main` untouched" simultaneously.
- Explicit-file `git add` (not wildcard) in step 4 above is the only safeguard needed to ensure exactly the known, reviewed file set is committed — nothing more, nothing less.

### 16.6 Exact Vercel provider actions required to configure Preview for `staging`
1. Confirm (do not change) that the Vercel project's Production Branch setting is still `main`.
2. Add the four variables from Section 16.3 to the Vercel project's Environment Variables, scoped to **Preview**, with the **Git Branch** override field set specifically to `staging` (Vercel supports per-branch scoping of a Preview-scoped variable on the Hobby plan) — this isolates the staging Supabase target to the `staging` branch only, so ad hoc PR/feature-branch Preview builds are not silently pointed at `cefflo-staging` unless later explicitly decided.
3. No new Vercel project is created (per Founder decision). No change to `vendor.cefflo.com` or any domain attachment is required for this gate.
4. Once the `staging` branch exists at the GitHub remote (Section 16.4 step 5), Vercel's existing connected GitHub App will automatically build and deploy it as a Preview deployment — no separate "enable" toggle needed beyond the integration already being active (proven by the 17 existing `main` auto-deployments).

### 16.7 Exact deployment acceptance sequence after the first `staging` Preview deployment
1. Confirm the new deployment's state is `READY` and its `target` is `preview` (not `production`) — via Vercel dashboard or a read-only `list_deployments` call.
2. Fetch the deployed `/shared/config.js` from the preview URL and confirm exactly: `environment: "staging"`, `supabaseProjectRef: "tomvvmwktehexwhktenw"`, `supabaseUrl: "https://tomvvmwktehexwhktenw.supabase.co"` — and positively absent: the Production ref `lmaxtrubwdniovxyuqdy`.
3. Grep the deployed static output for the Production ref string and for any of the excluded secret names (`DATABASE_URL`, service-role key, JWT secret, `CEFFLO_DISPOSABLE_TARGET`, `CEFFLO_ALLOW_MUTATING_TESTS`) — expect zero matches.
4. Load the Vendor surface (`/vendor/`) on the preview URL — confirm it initializes against `cefflo-staging`, no environment-resolution console errors.
5. Load the Rider surface (`/rider/`) — same confirmation.
6. Load the Customer/tracking surface (`/customer/`) — same confirmation.
7. Capture actual outbound network requests during a basic interaction on each surface; every backend request must target `tomvvmwktehexwhktenw.supabase.co` — zero requests to the Production ref or any Production-looking endpoint.
8. Record PASS/FAIL per step above in this checkpoint, with the deployment ID/URL and commit SHA, before closing the Vercel Preview/Staging acceptance gate in Section 13.

### 16.9 Execution outcome (Vercel provider-change turn) — BLOCKED before any provider write

**BEFORE PROVIDER CHANGE checks — all PASS:**
- Vercel project identity unchanged: `prj_Hn5d30wSQ7iTF4TPutWkzPvrcgMD`, team `team_PaLMlAwONUh637sDw8AYOBZL`, same domains.
- Production Branch confirmed = `main`, via consistent deployment-target evidence (every `main`-branch deployment targets `production`; the new `staging`-branch deployment never does) — the `get_project` tool exposes no direct "production branch" field to read literally.
- Remote `staging` SHA: `607d768d270734f21a8c605eb60abdd600917bc6` — exact match to Founder-verified baseline.
- `main` SHA: `15a551bdb26b79536138f16bd1370e3dfb4c4a5a` — exact match, locally and on origin.

**Discovered (not caused by this session):** the `staging` push already auto-triggered a Vercel build via the connected GitHub integration — deployment `dpl_72eHL9Ag5tm7f7NupACAd33TFaPe`, commit `607d768d270734f21a8c605eb60abdd600917bc6`, branch `staging`. State: **ERROR**. Build log (errors only): `Error: CEFFLO_ENVIRONMENT must explicitly be local, preview, staging, test, or production`, thrown by `resolveFrontendEnvironment()` in `scripts/environment.mjs:11`. This confirms the fail-closed guard is working correctly — the build refuses to proceed with no environment identity configured — and that env var configuration is the only missing piece for a successful Preview build.

**Blocking capability gap:** no available tool or credential path exists in this session to configure Vercel Preview environment variables.
- Connected Vercel MCP toolset (checked via two separate `ToolSearch` queries): has project/deployment/domain-purchase/analytics/deployment-protection tools, but **zero environment-variable read or write tool**.
- No local Vercel CLI present, no `.vercel` project link, no `VERCEL_*` credentials in this environment; installing the CLI via `npx` would require a fresh download and an auth token that doesn't exist here.
- No workaround attempted: did not try to install/authenticate a CLI, did not attempt any raw API call with a fabricated/guessed token, did not touch Production settings, did not retry with different tooling.

**Not attempted, blocked behind this:** retrieving the Supabase publishable key (would be premature — nothing to configure it into yet), setting any Preview env var, any new deployment attempt, the full deployment-acceptance checklist (Section 16.7), marking S4-01 complete.

**Founder action needed:** add the four Section 16.3 variables to the Vercel project's Environment Variables, scoped to Preview + Git-Branch-override = `staging`, via the Vercel dashboard (or CLI/token on a machine that has one) — this session cannot do it. Once set, the existing errored deployment can be redeployed (or a new commit/push will retrigger a build) and the acceptance checklist can proceed.

### 16.8 Execution outcome (this turn)
**BEFORE COMMIT gates:** main HEAD recorded (`15a551bdb26b79536138f16bd1370e3dfb4c4a5a`); branch/status/diff verified; exact 20-file reconciliation against this checkpoint's Section 4 confirmed (9 modified + 11 untracked, including the 2 continuity files); staged explicitly by filename (no wildcards) — confirmed via `git diff --cached --name-status` (exactly 20 entries).
- First `git diff --cached --check` run **FAILED** (exit 2): trailing-whitespace Markdown line-breaks in `AI_CONTINUITY_README.md` (lines 5, 182-185), preserved verbatim from the earlier "install exactly as provided" instruction. Stopped per "if any check fails, STOP without workaround"; surfaced the conflict to the Founder rather than resolving unilaterally.
- Founder authorized stripping the trailing whitespace (whitespace-only; diff confirmed no wording/content change). Re-staged; `git diff --cached --check` then **PASSED** (exit 0).
- Also spot-checked the staged diff for secret-shaped strings: all matches were `.env.example` placeholders or literal `secret`/fake-ref fixtures inside `tests/test_environment_guard.py`'s negative-test suite — no real credential present.

**Committed** onto `staging` only: commit `47d126fce22511018b1318818103f49d5bf0d451`, 20 files, message "S4-01E: staging environment identity, disposable Supabase target, and continuity protocol". `main` confirmed unchanged immediately after (`15a551bdb26b79536138f16bd1370e3dfb4c4a5a`).

**Push BLOCKED:** `git push -u origin staging` failed — `fatal: could not read Username for 'https://github.com': No such device or address`. Diagnosis (read-only): `gh auth status` shows the stored token for GitHub account `cefflohq` is invalid/expired; no `credential.helper` configured. An SSH key exists at `~/.ssh/id_ed25519` but was deliberately **not** used (unverified scope, would be an unauthorized workaround; also would require changing `origin`'s transport, not part of what was authorized). `git ls-remote origin main staging` confirms the remote has no `staging` ref yet and `main` remains `15a551bdb26b79536138f16bd1370e3dfb4c4a5a`.

**Not attempted, sequenced behind the push:** Vercel Preview environment-variable configuration, triggering/observing a Preview deployment, the full deployment acceptance checklist (Section 16.7), retrieving the Supabase publishable key, marking S4-01 complete. None of these can proceed until `staging` exists at the remote.

No branch deleted. No commit undone. No Production access or modification. S4-02 not started.

## 17. S4-01 FORMAL CLOSURE

**Status: COMPLETE / PASS / FOUNDER ACCEPTED.**

Founder acceptance is recorded based on the completed independent security review (staging isolation verification, prior turn) plus the full acceptance chain below. Evidence (sanitized, no secrets):

| Item | Result |
|---|---|
| Supabase staging project | `cefflo-staging`, ref `tomvvmwktehexwhktenw` |
| Non-mutating staging identity/authentication | PASS |
| Pre-E2E backend validation | `backend_contract_ok` |
| Hosted transactional E2E | `e2e_transaction_ok` |
| Post-E2E backend validation | `backend_contract_ok` |
| Dedicated Git branch | `staging` |
| Accepted staging commit | `607d768d270734f21a8c605eb60abdd600917bc6` |
| Vercel deployment | Preview, branch `staging`, READY |
| Deployment ID | `dpl_AMfHEd5QogJpvMfGpWcTK5veMaFp` |
| Vendor staging surface | PASS |
| Rider staging surface | PASS |
| Customer Tracking staging surface | PASS |
| Runtime environment (live `/shared/config.js`) | `staging` |
| Runtime Supabase project | `tomvvmwktehexwhktenw` |
| Production fallback | NOT DETECTED |
| Active hard-coded Production backend | NOT DETECTED |
| Environment resolver | FAIL-CLOSED / PASS |
| Production modified | NO |
| Production deployment | NO |
| `main` | `15a551bdb26b79536138f16bd1370e3dfb4c4a5a` (unchanged throughout all of S4-01) |

Provenance note (unchanged standard from earlier sections): the Vercel env-var configuration and the final redeploy-to-READY step were performed out-of-band by the Founder/credential holder, since this agent session has no tool/credential path to write Vercel environment variables (Section 9/16.9, historical). The subsequent security review (live `/shared/config.js` fetch, deployment metadata via Vercel MCP, full code-path tracing of Vendor/Rider/Customer) was performed independently by this agent session and is the basis for the isolation PASS verdict.

## 18. Technical Debt Register (non-blocking — NOT implemented)

**TD-S4-01-01 — Vendor runtime configuration silent fallback**
- Location: `vendor/index.html` (`CEFFLO_RUNTIME_CONFIG`, ~line 6986-6987).
- Finding: secondary fallback to `localStorage.getItem('cefflo_supabase_url'/'cefflo_supabase_anon_key')` then `''` if `window.CEFFLO_CONFIG` is ever absent, instead of throwing like `shared/client.js` does.
- Current assessment: does **not** fall back to Production (nothing ever writes those localStorage keys; the branch degrades to a non-functional empty state, never to a Production value). Non-blocking.
- Recommended future fix: replace the silent fallback with an explicit `throw` for defense-in-depth consistency with `shared/client.js`. **Not implemented this turn.**

**TD-S4-01-02 — Stale documentation**
- Location: `docs/cefflo/PHASE_1_REPOSITORY_INVENTORY.md`.
- Finding: describes `shared/config.js` as directly defining the Production project ref/keys — describes a pre-S4-01 version of that file. Current `shared/config.js` is a one-line fail-closed guard with no values.
- Current assessment: documentation only, zero runtime impact. Refresh later. **Not implemented this turn.**

## 19. S4-02 Recovered Scope (canonical, not invented)

Recovered from `docs/cefflo/STAGE_4_EXECUTION_HANDOFF.md` §3 ("Next-sprint dependency"), `docs/cefflo/PHASE_1_STAGE4_GAP_REPORT.md` §7 (sprint table, row S4-02), `docs/cefflo/PHASE_1_BACKEND_SECURITY_BASELINE.md` §18 (Founder decisions required), and `docs/cefflo/05_DECISIONS.md` (D-16), cross-checked against the current schema in `supabase/migrations/202608130001_cefflo_foundation.sql`.

**Official name:** S4-02 — Finalize permission matrix and protected backend contract design.

**Verbatim dependency note (Execution Handoff §3):** *"S4-02 may begin only after S4-01 passes. S4-02 finalizes the Owner/operator/member/Rider/Customer permission matrix and protected backend contract design. No RLS or lifecycle remediation begins before that design and its approvals."*

**Gap-report row:** Treatment `DECISION REQUIRED` / `P0`. Dependency: S4-01. Canonical docs: `02_ARCHITECTURE.md`, `10_DELIVERY_LIFECYCLE.md`, `11_SUPABASE.md`, `12_SECURITY.md`. Likely code areas: "design/migrations/tests". Acceptance gate: "Owner/operator/Rider/Customer permissions and compatibility sequence approved". Founder approval: YES.

**Current schema evidence (why this sprint exists — a real, already-verified gap, not a hypothesis):** `member_role` enum currently has only `('owner','operator')` — no scoped `member` tier. RLS policies `riders_vendor`, `sessions_vendor`, `orders_vendor`, `assignments_vendor` all grant `for all` (full CRUD) to `is_business_member(business_id)` — i.e. owner and operator are functionally identical today. This is exactly the Security Baseline's finding: *"Business `operator` effectively has full rider and operational write/delete power... most Vendor policies use membership, not owner role or scoped permissions"* (`PHASE_1_BACKEND_SECURITY_BASELINE.md` row, Medium severity, `DECISION REQUIRED`).

### Scope
1. Design the Owner/Operator/Member/Rider/Customer permission matrix — who may manage riders, members, orders, sessions, assignments, exceptions, and destructive actions (Security Baseline §18 decision #1).
2. Design the protected-backend-contract approach: which lifecycle-sensitive writes move from broad table RLS policies to `security definer` RPC contracts (extending the existing pattern already used by `bootstrap_business`/`create_delivery`/`assign_rider`/`rider_transition`/`complete_delivery`), and the compatibility sequence for existing Vendor/Rider/Customer clients during the transition (Security Baseline §18 decision #2).
3. Produce a reviewable design artifact (permission matrix table + contract/RPC design + any proposed schema additions, e.g. a `member` role value or scoped-grants table) for Founder approval.
4. Produce a test plan (not full implementation) describing how the eventual matrix will be validated once S4-03 applies it.

### Out of scope (explicitly, per the handoff doc)
- Any RLS policy change applied to the database.
- Any migration that alters live permission enforcement.
- Order approval/readiness state model specifics (Security Baseline §18 decision #3) — canonically owned by **S4-05** (depends on S4-03, not S4-02).
- Session/batch/zone/assignment invariants (decision #4) — **S4-05**.
- Trusted-team invitation/join token lifecycle (decisions #5, #6) — **S4-07** (depends on S4-02, S4-03).
- Exception entity/types/permissions (decision #7) — **S4-08**.
- POD completion integrity and tracking-token lifecycle (decisions #8, #9) — **S4-04** (depends on S4-02, S4-03).
- Any Vendor/Rider/Customer UI change.
- Any Vercel/Production/deployment action.
- S4-03 or later implementation work of any kind.

### Sub-sprints/batches
Not canonically subdivided in the source docs below the sprint level — S4-02 is a single `DECISION REQUIRED` sprint. The batches in Section 20 are this session's proposed smallest-safe breakdown of that one sprint, not separately named in the spec.

### Expected files/components
- New design doc (e.g. `docs/cefflo/S4-02_PERMISSION_CONTRACT_DESIGN.md` or similar — naming not canonically specified).
- Draft/reviewable (not applied) migration sketch extending `supabase/migrations/` conventions.
- No changes to `vendor/`, `rider/`, `customer/`, `shared/`, or any currently-passing test.

### Database/backend work
Design only: proposed `member_role` extension and/or scoped-permission table shape, proposed new/modified RPC signatures. No migration applied to any environment (local, staging, or Production) as part of S4-02 itself.

### Frontend work
None. S4-02 is backend/design only.

### Security gates
Founder approval required (gap-report: YES). SEC-02 (backend authorization/RLS is authoritative), SEC-11 (material auth/RLS/security policy changes require Founder approval before execution) both apply directly — reinforcing that S4-02 produces a design for Founder sign-off, not an applied change.

### Required tests
None executable yet (design sprint). A test plan is the deliverable, not test runs. Do not re-run S4-01's identity/E2E/isolation suites — they don't change under S4-02 and re-running them would violate the No-Duplicate-Re-Audit rule.

### Staging acceptance
N/A for S4-02 itself (no deployable artifact). Staging acceptance resumes at S4-03 when the approved design is actually implemented and needs isolation/E2E re-verification against `cefflo-staging`.

### Definition of Done
Owner/Operator/Member/Rider/Customer permission matrix and the protected-backend-contract/compatibility-sequence design are documented and **Founder-approved**. No RLS or lifecycle remediation has begun.

### Ambiguity flagged (not resolved unilaterally)
`PHASE_1_BACKEND_SECURITY_BASELINE.md` §18 lists nine Founder decisions "required before backend implementation," but only decisions #1 and #2 map to S4-02's narrower title; decisions #3-#9 map to specific later sprints per the dependency graph (S4-05, S4-07, S4-04). This mapping is this session's evidence-based inference from cross-referencing the sprint dependency table — it is not stated verbatim as a single explicit rule in any one doc. **Recommend Founder confirms this boundary before the execution agent starts**, so decisions #3-#9 aren't accidentally pulled into S4-02 or dropped entirely.

## 20. S4-02 Execution Plan (drafted, NOT started)

**S4-02.A — Permission matrix draft**
- Objective: produce the Owner/Operator/Member/Rider/Customer permission matrix (who may manage riders, members, orders, sessions, assignments, exceptions, destructive actions).
- Scope: documentation only.
- Expected files: one new design doc under `docs/cefflo/`.
- Required tests: none (design artifact).
- Acceptance criteria: matrix covers every actor × action combination named in Security Baseline decision #1; internally consistent with D-16 (`05_DECISIONS.md`).
- Effort: SMALL.
- Independent before next batch: YES.

**S4-02.B — Protected backend contract design**
- Objective: design which lifecycle-sensitive operations move from broad table RLS to `security definer` RPC contracts, extending the existing `bootstrap_business`/`create_delivery`/`assign_rider`/`rider_transition`/`complete_delivery` pattern; define the client-compatibility sequence.
- Scope: documentation + a draft (unapplied) migration sketch for any new schema shapes the design needs (e.g. `member_role` addition or scoped-grants table).
- Expected files: same design doc (or a companion doc) + a draft `.sql` sketch not placed in `supabase/migrations/` as a real migration yet (to avoid it being picked up by tooling as applied).
- Required tests: none yet — a written test plan only (what S4-03 will need to verify).
- Acceptance criteria: every RPC/contract change needed to close the "operator has full power" gap is named with its intended authorization rule; compatibility sequence for existing clients is explicit.
- Effort: MEDIUM.
- Independent before next batch: depends on S4-02.A (needs the matrix as input) — sequential, not parallel.

**S4-02.C — Founder review and approval**
- Objective: Founder reviews S4-02.A + S4-02.B and approves, requests changes, or rejects.
- Scope: review only, no code.
- Expected files: none (or approval recorded in `05_DECISIONS.md`/checkpoint).
- Required tests: none.
- Acceptance criteria: explicit Founder approval recorded, per gap-report's "Founder approval? YES".
- Effort: SMALL (for the agent; approval latency depends on Founder).
- Independent before next batch: this batch gates S4-03 entirely — no RLS/lifecycle remediation may start before it completes.

No batch in this plan touches `vendor/`, `rider/`, `customer/`, `shared/`, applies a migration, or requires staging/Production deployment. S4-03+ work is explicitly excluded from all three batches.

## 21. S4-02.A Result — Permission Matrix Drafted (superseded by Section 23 — Founder-approved and locked)

**Status: PASS (design produced; superseded — see Section 23 for the Founder-approved final role model. S4-02.B still not started.)**

- Document: `docs/cefflo/S4-02_PERMISSION_BACKEND_CONTRACT_DESIGN.md` (new, untracked, uncommitted).
- Actors covered: Owner, Operator, Member (proposed — not yet in schema), Rider, Customer/Public Tracking user. No production role invented beyond these five.
- Matrix coverage: 35 actor×action rows across business/profile, member/team, rider, order, delivery/session, assignment, lifecycle transitions, completion, POD, tracking-token, ratings, GPS/events, and destructive actions — every action category listed in the authorization request is covered.
- Reconciled against current schema (`supabase/migrations/202608130001_cefflo_foundation.sql`) and the `tracking-pod` Edge Function — not against assumption.
- Existing RPC alignment: `bootstrap_business`, `rider_transition`, `complete_delivery` — **already aligned**. `create_delivery`, `assign_rider` — **partially aligned** (RPC logic correct, but co-existing broad `orders_vendor`/`assignments_vendor` RLS policies let any member bypass the RPC via direct table write — flagged as the top finding for S4-02.B). Missing entirely: member invite/role-change, rider deactivate, order update, order/rider destructive delete, rider reassignment.
- Key security finding (not previously flagged at this precision): `riders_vendor` and `orders_vendor` RLS policies currently grant `DELETE` to **any** business member (Operator included), with no owner-only destructive-action gate — matches the Security Baseline's general "operator has full power" finding but is now pinned to exact rows/policies for S4-02.B to fix.
- Deferred (explicitly, per boundary): order-approval state machine, session/batch/zone invariants, reassignment semantics → S4-05. Exception workflows → S4-08. Trusted-team invitation → S4-07. Token lifecycle/public-endpoint hardening → S4-04.
- Unresolved permission questions (flagged, not guessed): exact Operator/Member boundary (only a proposed default given); hard-delete vs. soft-cancel for destructive actions; whether Member gets any write capability at all; business-profile-update audit-trail parity. All four require explicit Founder input before S4-02.B.
- Implementation files modified: **NO** (doc-only; no Supabase, RLS, migration, frontend, or runtime file touched).
- Production accessed: **NO**.
- `git diff --check`: **PASS**.

## 22. S4-02.B Inputs (carried from the design doc §7)

1. Member-role schema representation (enum extension vs. permissions table).
2. Destructive-action RPCs: `deactivate_rider` (OWNER ONLY), order cancel/void (OWNER ONLY).
3. RLS-narrowing plan and compatibility sequence for `riders_vendor`/`orders_vendor`/`assignments_vendor`.
4. Order-update RPC signature/allowed fields.
5. Rider-update RPC signature (non-destructive fields).
6. Member/team management RPCs (`invite_member`, `update_member`) — note possible overlap with S4-07, needs explicit boundary confirmation.
7. Minimal `reassign_rider` RPC (narrow — not full S4-05 session semantics).
8. Business-profile-update audit-trail decision.

**S4-02.B remains NOT STARTED — gated on Founder review/approval of this permission matrix.**

## 23. Founder Decision — Canonical Role Model Locked (S4-02.A = COMPLETE / FOUNDER APPROVED)

**Founder decision applied to `docs/cefflo/S4-02_PERMISSION_BACKEND_CONTRACT_DESIGN.md` this turn:**

- **Canonical roles, exactly four:** Owner, Operator/Staff, Rider, Customer/Public Tracking.
- **`Member` removed** as a canonical application role — no `member_role` enum extension, no schema change for role representation. The existing `('owner','operator')` enum already matches the approved model. `business_members` remains the correct name for the underlying database relationship (which users belong to which business) — distinguished explicitly from the (now rejected) idea of "Member" as a user-facing role.
- **Owner inherits ALL Operator/Staff operational capabilities** — a solo vendor operates fully through the Owner account alone, never needing a fake Operator identity.
- **Operator/Staff does NOT inherit Owner authority** (no ownership, security/role-management, or business-transfer authority).
- Verified row-by-row: every one of the 35 matrix rows now satisfies Owner ≥ Operator/Staff.
- **Security defaults confirmed:** no hard `DELETE` on operational records (`orders`/`riders`) — must use deactivate/cancel/void concepts preserving history; rider deactivation stays Owner-only for the current design; business-profile changes require an audit trail (previously an open question, now a fixed requirement — mechanism is an S4-02.B design choice); cancel/void *authorization semantics* for orders explicitly deferred to S4-05 (only "no hard delete" + the general destructive-action-needs-scoping principle apply now).
- Design doc updated in place (revision note added, Section 1 rewritten, matrix's Member column removed and rows 2/10/14 updated for the no-hard-delete/audit-trail decisions, Section 7 inputs updated — Member-schema input removed, business-profile-audit input marked resolved — Section 8 restructured into "Resolved by Founder decision" vs. genuinely-still-open items).
- Two genuinely open items remain, both scoped to S4-02.B/S4-05 boundary questions, not blocking S4-02.A: (1) whether order cancel/void *actor-level* authorization is decided now (placeholder: OWNER ONLY) or waits fully for S4-05; (2) whether `invite_team_member` overlaps with the S4-07 trusted-team invitation mechanism.
- Implementation files modified: **NO**. Production accessed: **NO**. `git diff --check`: **PASS**.

**S4-02.A = COMPLETE / FOUNDER APPROVED. S4-02.B remains NOT STARTED** — next action is to prepare (not execute) the S4-02.B protected-backend-contract design under this now-locked four-role model.

## 24. Founder Boundary Decisions (order cancel/void; team management) + S4-02.B Design Result

**Two remaining boundary decisions resolved by Founder this turn:**
- Order cancel/void: **fully DEFERRED TO S4-05** — no actor, timing, or state-machine decision made in S4-02, not even a placeholder. Matrix row 14 updated to `DEFERRED TO S4-05` for all four actors.
- Team/staff management: invitation/join workflow **entirely DEFERRED TO S4-07**. S4-02.B designs only the security boundary (Owner-controlled team authority, no self-escalation, protected contracts not broad writes) plus `update_team_member` for an already-existing relationship. `invite_team_member` is explicitly NOT designed.

**S4-02.B design produced** (appended to `docs/cefflo/S4-02_PERMISSION_BACKEND_CONTRACT_DESIGN.md`, Sections 9-18):
- **Existing RPC classification:** `bootstrap_business` ALIGNED. `create_delivery`, `assign_rider`, `rider_transition`, `complete_delivery` — all **PARTIALLY ALIGNED**: none need internal changes; all share one root cause — `orders_vendor`/`assignments_vendor`/`riders_vendor` broad `for all` RLS policies let a business member bypass every one of them via direct table write. New, more precise finding vs. S4-02.A: `orders_vendor` lets a vendor directly flip `delivery_status` (e.g. to `delivered`), bypassing `rider_transition`'s rider-only rule and `complete_delivery`'s POD-required gate — a real data-integrity risk, not just an authorization gap.
- **New contracts designed (minimum set only):** `deactivate_rider` (Owner-only), `update_rider_details`, `update_order_details` (pre-dispatch, guarded by existing `delivery_status='created'`), `update_team_member` (Owner-only, existing relationship only, includes a last-owner-protection invariant), `reassign_rider` (authorization boundary only — same shape as `assign_rider`; full S4-05 semantics not designed).
- **RLS narrowing designed:** drop all `insert`/`update`/`delete` from `riders_vendor`/`orders_vendor`/`assignments_vendor`; keep every `select` policy untouched; result is zero direct-write path on `orders`/`riders`/`rider_assignments` for any actor, including Owner (no hard `DELETE` for anyone).
- **Compatibility sequence:** 4 steps — (1) ship new RPCs additively, nothing removed; (2) Vendor call-site cutover to new RPCs, verified on staging; (3) RLS narrowing, staging-first, only after step 2 verified, fully reversible; (4) regression + normal low-activity Production release (D-08). No maintenance window, no forced interruption, no Production-first step, no temporary broad authorization.
- **Business-profile audit:** designed via new `update_business_profile` RPC + new `business_profile_audit` table (actor, business, timestamp, field-level diff only — no secrets/PII beyond already-visible business contact fields).
- **Test plan:** written only (Section 15) — Owner/Operator positive+negative, Rider scope, Customer/token scope, direct-bypass-denied, cross-business-denied, hard-delete-denied-for-everyone, per-RPC authorization, and a note to re-run the existing `tests/e2e_transaction.py` (not redesigned) once S4-03 applies the change.
- **Draft migration sketch:** included as a fenced SQL block inside the design doc, clearly marked "DRAFT — DO NOT APPLY" at top and bottom — **not** placed under `supabase/migrations/` (confirmed: that directory still contains only the original foundation migration).
- **Implementation plan for future execution agent:** 3 ordered batches (ship RPCs additively → Vendor cutover → RLS narrowing), each with explicit dependency ordering; none touch Rider/Customer surfaces; none start S4-03+.

**Implementation files modified: NO. Production accessed: NO. `git diff --check`: PASS.**

**No remaining Founder decisions block S4-02 from closing.** Next action: Founder review/approval of the full S4-02.B design. Backend implementation does not begin until that approval.

## 25. S4-02 FORMAL CLOSURE — Founder Approved

**Status: S4-02 = COMPLETE / FOUNDER APPROVED.** (S4-02.A = COMPLETE / FOUNDER APPROVED; S4-02.B = COMPLETE / FOUNDER APPROVED.)

**Approved implementation sequence (7 steps, Founder-confirmed, not yet started):**
1. Add protected contracts first (additive, non-breaking).
2. Preserve existing compatibility — nothing removed at this stage.
3. Cut Vendor call sites over to the protected contracts.
4. Verify the cutover completely on staging.
5. Only then narrow the broad mutation RLS policies (`riders_vendor`, `orders_vendor`, `assignments_vendor` — remove direct INSERT/UPDATE/DELETE, preserve every SELECT/read policy).
6. Run full positive/negative/regression verification.
7. Production remains a separate Founder-authorized release gate — not implied by any of the above.

**Approved new contracts:** `deactivate_rider`, `update_rider_details`, `update_order_details`, `update_team_member`, `reassign_rider` (authorization boundary only), `update_business_profile` + audit mechanism.

**Audit data-minimization clarification applied** (design doc §14/§16 revised): the `business_profile_audit` design no longer stores raw before/after field *values* by default — only actor identity, business identity, timestamp, the list of changed field *names* (not their content), and an optional caller-supplied correlation id. Before/after values would only ever be added later as an explicitly scoped, separately Founder-reviewed exception if a demonstrated operational/security need arises — not a default. This clarification did not reopen the S4-02.B architecture; only the audit payload shape changed.

**Sprint-boundary correction (important, per explicit Founder instruction this turn):** the three implementation batches drafted while designing S4-02.B (ship RPCs → Vendor cutover → RLS narrowing) are **not S4-02 work** — applying RLS/direct-write remediation is canonically **S4-03**'s job ("Repair RLS/direct writes and cross-business integrity," per `PHASE_1_STAGE4_GAP_REPORT.md` §7 and the Handoff doc's explicit "no RLS or lifecycle remediation begins before that design and its approvals"). The design doc's Section 18 has been relabeled `S4-03-Batch-1/2/3` accordingly, with an explicit note that S4-02's approval does not itself start them.

**Preserved deferrals (unchanged, still fully out of scope for S4-02 and S4-03):**
- **S4-04:** tracking-token expiry/rotation/revocation policy; public-endpoint (CORS/rate-limit/error-normalization) hardening.
- **S4-05:** order-approval/readiness state machine; session/batch/zone/multi-drop invariants; full rider-reassignment semantics; order cancel/void entirely (including which actor may invoke it).
- **S4-07:** trusted-team invitation/join workflow in full.
- **S4-08:** typed exception report/resolve/reassign/redelivery workflow.

**Design document:** `docs/cefflo/S4-02_PERMISSION_BACKEND_CONTRACT_DESIGN.md` (uncommitted). Implementation files modified: **NO**. Production accessed: **NO**. `git diff --check`: **PASS**.

## 26. S4-03 Recovered (canonical, not invented) — NOT STARTED

**Official name:** S4-03 — Repair RLS/direct writes and cross-business integrity.

**Canonical source:** `docs/cefflo/PHASE_1_STAGE4_GAP_REPORT.md` §7 row S4-03: Treatment `REPAIR` / `P0`. Dependency: S4-02 (now satisfied). Canonical docs: `10_DELIVERY_LIFECYCLE.md`, `11_SUPABASE.md`, `12_SECURITY.md`. Likely code areas: migrations, RPCs, RLS, database tests. Acceptance gate: "Protected happy path preserved; two-business matrix passes; bypasses fail." Founder approval: YES for RLS/security migration and application.

**Entry criteria:** S4-02 passed (now true — Section 25).

**Exact scope:** apply the S4-02-approved design — this is not a new design exercise, it is the *execution* of Sections 9-18 of `S4-02_PERMISSION_BACKEND_CONTRACT_DESIGN.md`: ship the 6 approved contracts additively, cut Vendor call sites over, verify on staging, then narrow `riders_vendor`/`orders_vendor`/`assignments_vendor` to close the direct-write bypass, per the 7-step Founder-approved sequence in Section 25.

**Relationship to the S4-02 design:** direct 1:1 — S4-03's batches ARE `S4-03-Batch-1/2/3` in the design doc's Section 18. No new design decisions are expected; S4-03 is implementation of already-approved architecture, with its own staging verification and Founder-gated Production release at the end.

**Acceptance criteria (from canonical source + Section 25's sequence):** protected happy path (the existing `tests/e2e_transaction.py` chain) preserved; a two-business cross-access matrix passes (extends the existing "outsider" actor pattern); direct-table-write bypasses on `orders`/`riders`/`rider_assignments` fail post-narrowing; no hard `DELETE` remains for any actor; Vendor UI fully cut over with no regression; all on `cefflo-staging` before any Production step, which itself requires a separate Founder authorization.

**Not started.** No RPC implemented, no migration created, no RLS changed, no Vendor code touched this turn.

## 27. S4-03-Batch-1 Active Execution — Credential Preflight PASS

**Updated:** 2026-08-27 (Codex active implementation agent)

- Current work package: **S4-03-Batch-1 — additive protected backend contracts only**.
- Branch: `staging`.
- Starting HEAD: `607d768d270734f21a8c605eb60abdd600917bc6`.
- Existing uncommitted S4-02 work remains preserved: this checkpoint file is modified and
  `docs/cefflo/S4-02_PERMISSION_BACKEND_CONTRACT_DESIGN.md` remains untracked.
- Fail-closed staging mutation-target validation: **PASS**.
- Positively verified target: `cefflo-staging`, project ref `tomvvmwktehexwhktenw`, environment
  `staging`, official Mumbai session-pooler host and database `postgres`.
- Required mutation authorization flags were present and accepted by `environment_guard.py`:
  `CEFFLO_DISPOSABLE_TARGET=1` and `CEFFLO_ALLOW_MUTATING_TESTS=1`.
- Staging password exists only in `/tmp/cefflo-staging-db-password.ephemeral` with mode `0600`;
  value not recorded or exposed. Delete after Batch-1 staging verification.
- Production accessed: **NO**. Production modified: **NO**. Production credentials used: **NO**.
- Migration created/applied: **NO / NO**.
- Existing RLS mutation policies changed: **NO**.
- Vendor call sites changed: **NO**.

**NEXT EXACT ACTION:** reconcile the approved S4-02 migration sketch with the actual tracked and
live staging schema, including migration ledger and existing function/policy identities, using
read-only queries before creating the real additive Batch-1 migration.

### 27.1 Live Staging Schema Reconciliation — PASS

- Migration ledger contains only `202608130001 cefflo_foundation`.
- `business_profile_audit` and all six approved Batch-1 RPCs are absent, as expected.
- Live columns/enums required by the approved sketch match the tracked foundation schema.
- Existing protected RPC signatures match the tracked foundation.
- `riders_vendor`, `orders_vendor`, and `assignments_vendor` remain `ALL`; no policy was changed.
- No material schema/design conflict found. Production accessed: **NO**.

**NEXT EXACT ACTION:** create the real additive Batch-1 migration and rollback-based contract test,
without changing existing RLS policies or Vendor call sites, then run local static/syntax checks.

### 27.2 Additive Migration and Contract Test Created — Static Validation PASS

- Added `supabase/migrations/202608270001_s4_03_batch_1_contracts.sql`.
- Added `tests/s4_03_batch_1_contracts.py` (two-business, rollback-only authorization suite).
- Migration adds six protected RPCs plus the data-minimized `business_profile_audit` table.
- Existing RLS mutation policy definitions are not dropped, narrowed, replaced, or recreated.
- Vendor call sites are untouched.
- Python compile: **PASS**.
- Static Batch-1 scope guard: **PASS**.
- Transactionally rolled-back SQL parse against disposable local Supabase: **PASS**.
- `git diff --check`: **PASS**.
- Staging migration applied: **NO**.
- Production accessed/modified: **NO / NO**.

**NEXT EXACT ACTION:** apply only migration `202608270001_s4_03_batch_1_contracts.sql` to the
positively verified staging target in one transaction, record its migration ledger row, and verify
the six function identities, audit table, and unchanged RLS policy commands before running tests.

### 27.3 Staging Additive Migration Applied — PASS

- Applied only `202608270001_s4_03_batch_1_contracts.sql` to positively verified
  `cefflo-staging` (`tomvvmwktehexwhktenw`) in one transaction.
- Migration ledger now contains foundation `202608130001` and Batch-1 `202608270001`.
- All six approved RPC identities exist.
- `business_profile_audit` exists with RLS enabled and one SELECT-only member policy.
- `riders_vendor`, `orders_vendor`, and `assignments_vendor` remain unchanged as `ALL` policies.
- Vendor call sites changed: **NO**.
- Production accessed/modified: **NO / NO**.

**NEXT EXACT ACTION:** run `tests/s4_03_batch_1_contracts.py` against staging with the fail-closed
mutation guard; the suite must roll back all test-created data, then verify zero residual markers.

### 27.4 First Staging Contract Test — FAIL, Transaction Rolled Back

- Failure: `update_business_profile` used ambiguous array concatenation (`changed || 'name'`),
  producing PostgreSQL `malformed array literal: "name"`.
- Test transaction rolled back automatically; no test data was committed.
- Root cause is confined to the new audit changed-field accumulator.
- Existing migration `202608270001` will not be rewritten after application.
- Existing RLS policies and Vendor call sites remain untouched.
- Production accessed/modified: **NO / NO**.

**NEXT EXACT ACTION:** add and locally validate a forward-only Batch-1 corrective migration that
replaces only `update_business_profile` using `array_append`, then apply it to staging and rerun the
rollback-only contract suite.

### 27.5 Audit Array Correction Applied — PASS

- Added `202608270002_s4_03_batch_1_audit_array_fix.sql`; the applied `202608270001` migration was
  not rewritten.
- Local transaction test of the corrected two-field audit entry: **PASS / rolled back**.
- Applied correction to positively verified staging and recorded ledger version `202608270002`.
- Scope is limited to `create or replace function update_business_profile`; no policy or table
  change and no Vendor change.
- Production accessed/modified: **NO / NO**.

**NEXT EXACT ACTION:** rerun the rollback-only staging Batch-1 contract authorization suite once,
then verify zero residual test markers before proceeding to existing regression tests.

### 27.6 Staging Batch-1 Contract Authorization Suite — PASS

- `tests/s4_03_batch_1_contracts.py`: **PASS**.
- Verified Owner inheritance and Owner-only operations.
- Verified Operator/Staff approved operations and denial of Owner-only operations.
- Verified cross-business denial, last-owner protection, created-state order-update boundary,
  deactivation boundary, reassignment boundary, and data-minimized audit metadata.
- Audit schema contains metadata fields only; no raw before/after value columns.
- Transaction rolled back; explicit residual check found zero S4-03 test users, businesses, and
  audit rows.
- Production accessed/modified: **NO / NO**.

**NEXT EXACT ACTION:** run the existing environment guard suite, sanitized staging identity check,
backend contract validation, and rollback-only transactional E2E regression against staging.

### 27.7 Existing Guard and Protected-Contract Regression — PASS

- Environment guard negative/static tests: **30/30 PASS**.
- Sanitized staging identity/connectivity: **PASS**.
- Existing backend contract validation before E2E: **PASS**.
- Existing transactional E2E (`create_delivery` → `assign_rider` → rider transitions →
  `complete_delivery` → tracking/rating): **PASS / rolled back**.
- Existing backend contract validation after E2E: **PASS**.
- Production accessed/modified: **NO / NO**.

**NEXT EXACT ACTION:** run final read-only staging integrity checks for migration ledger, functions,
RLS/policies, private POD bucket, audit minimization, unchanged broad Batch-1 policies, and residual
test markers; then securely delete the ephemeral staging password.

### 27.8 S4-03-Batch-1 Final Integrity Gate — PASS

- Final staging migration ledger: foundation `202608130001`, Batch-1 contracts `202608270001`,
  audit array correction `202608270002` — exact and unchanged after testing.
- Public table set is exact; all public tables have RLS enabled.
- All six Batch-1 functions are SECURITY DEFINER with fixed `search_path=public`.
- Existing `riders_vendor`, `orders_vendor`, and `assignments_vendor` remain `ALL`; Batch-3
  narrowing was not started.
- `business_profile_audit` columns are exactly metadata-only: id, business identity, actor
  identity, changed field names, optional request id, timestamp. No raw before/after values.
- `cefflo-pod` remains private.
- Residual test users/businesses/audit rows: zero.
- Ephemeral staging password securely deleted; mutation flags and `DATABASE_URL` were subprocess
  scoped only and are no longer present.
- Vendor call sites changed: **NO**. Batch-2: **NOT STARTED**.
- Production accessed/modified/credentials used: **NO / NO / NO**.
- Commit/push: **NO / NO**.

**Status:** S4-03-Batch-1 implementation and staging verification **PASS**, pending Founder review.

**NEXT EXACT ACTION:** Founder review of S4-03-Batch-1 results before any authorization to begin
S4-03-Batch-2 Vendor call-site cutover. Do not start Batch-2 without that authorization.

## 28. S4-03-Batch-2 Entry — BLOCKED at Staging Credential Gate

**Updated:** 2026-08-27 (Codex active implementation agent)

- Founder accepted Batch-1 and authorized Batch-2 Vendor protected-contract cutover.
- Recovery verification: branch `staging`, HEAD
  `607d768d270734f21a8c605eb60abdd600917bc6`, existing Batch-1 migration/test files and
  uncommitted S4-02 design/checkpoint work preserved.
- `git diff --check`: **PASS**.
- Required staging credential is not available to this execution environment:
  `DATABASE_URL` absent and `/tmp/cefflo-staging-db-password.ephemeral` absent.
- No Vendor file inspected or modified beyond the mandatory recovery gate; no Batch-2 code work
  started.
- RLS policies changed: **NO**. Production accessed/modified: **NO / NO**.

**Current blocker:** recreate the approved staging credential at
`/tmp/cefflo-staging-db-password.ephemeral` with mode `0600` through the established out-of-band
mechanism. Never place the value in chat or tracked files.

**NEXT EXACT ACTION:** after credential availability, run fail-closed staging identity validation,
then inspect only active Vendor mutation call sites before making Batch-2 changes.

### 28.1 Batch-2 Staging Credential Gate Recovered — PASS

- Approved ephemeral staging password restored at the documented private path with mode `0600`.
- Fail-closed staging mutation-target and harmless database identity validation: **PASS**.
- Positively verified project ref `tomvvmwktehexwhktenw`, environment `staging`, official Mumbai
  session pooler, database `postgres`.
- Branch/HEAD remain `staging` / `607d768d270734f21a8c605eb60abdd600917bc6`.
- No Vendor or RLS change made yet. Production accessed/modified: **NO / NO**.

**NEXT EXACT ACTION:** inspect the active Vendor frontend/backend and shared Supabase adapter for
all direct writes involving business profiles, riders, orders, team members, and assignments;
classify each path before editing.

### 28.2 Active Vendor Mutation Classification — PASS

- The active remote adapter is `vendor/backend.js`; it replaces the inline generic persistence
  hook with a no-op, so the legacy inline table-upsert compatibility code is not an active remote
  mutation path.
- Already protected: delivery creation uses `create_delivery`; first rider assignment uses
  `assign_rider`.
- Batch-2 cutover required: business-profile save to `update_business_profile`, rider
  deactivation to `deactivate_rider`, and changing an already-assigned order's rider to
  `reassign_rider`.
- No active Vendor edit action currently exists for rider detail edits, order detail edits, or
  existing team-member role/status changes. Their Batch-1 clients may be exposed by the adapter,
  but no UI/workflow will be invented in Batch-2.
- Deferred and untouched: invitation/join (S4-07), zone/session and full reassignment semantics
  (S4-05), issue workflows (S4-08), and account deletion/lifecycle work.
- RLS policies changed: **NO**. Production accessed/modified: **NO / NO**.

**NEXT EXACT ACTION:** update only `vendor/backend.js` to add the six approved RPC clients and
replace the three applicable active Vendor mutation handlers, preserving UI behavior and existing
`create_delivery` / `assign_rider` flows.

### 28.3 Vendor Protected-Contract Cutover Implemented — PASS

- `vendor/backend.js` now exposes all six Batch-1 protected RPC clients.
- Active business-profile save calls `update_business_profile`; active rider deactivation calls
  `deactivate_rider`; changing an existing order rider calls `reassign_rider`, while first
  assignment continues to call `assign_rider`.
- The adapter replaces the dispatcher-held handler references, preventing fallback to inline demo
  mutations. Inactive backend riders retain the existing UI's offline presentation.
- Added `tests/test_vendor_protected_cutover.py` for RPC presence, active-handler replacement,
  existing protected-flow preservation, and absence of direct protected-table mutations in the
  active adapter.
- Vendor cutover static tests: **5/5 PASS**. Environment guards plus cutover tests: **35/35 PASS**.
- JavaScript syntax: **PASS**. Synthetic non-production staging build: **PASS**.
- The initial build without identity failed closed as designed; rerun with explicit synthetic
  staging identity passed.
- RLS policies changed: **NO**. Production accessed/modified: **NO / NO**.

**NEXT EXACT ACTION:** run fail-closed staging identity, backend validation, Batch-1 authorization
regression, and existing transactional E2E using the subprocess-scoped staging credential; then
verify cleanup and unchanged staging schema/policies.

### 28.4 Staging Security and Transactional Regression — PASS

- Fail-closed staging identity/connectivity: **PASS**, positively matched only
  `tomvvmwktehexwhktenw` through the official Mumbai session pooler.
- Backend contract validation before and after mutation tests: **PASS / PASS**.
- Batch-1 Owner, Operator/Staff, cross-business, last-owner, order-state, reassignment, and audit
  authorization regression: **PASS / transaction rolled back**.
- Existing transactional E2E (`create_delivery`, `assign_rider`, rider transitions,
  `complete_delivery`, tracking/rating): **PASS / transaction rolled back**.
- Credential and mutation flags were scoped to the single subprocess and unset on completion.
- RLS policies changed: **NO**. Production accessed/modified: **NO / NO**.

**NEXT EXACT ACTION:** run final read-only staging integrity checks for migration ledger, public
RLS, targeted broad-policy commands, private `cefflo-pod`, and zero residual Batch-1 markers; then
delete the ephemeral password and inspect the complete repository diff.

### 28.5 S4-03-Batch-2 Final Acceptance Gate — PASS

- Staging migration ledger remains exactly `202608130001`, `202608270001`, `202608270002`.
- All public tables remain RLS-enabled; `riders_vendor`, `orders_vendor`, and
  `assignments_vendor` remain unchanged `ALL` policies; `cefflo-pod` remains private.
- Residual Batch-1 business and audit markers: **zero**.
- Local built Vendor page loaded successfully at `/vendor/`, displayed the expected CEFFLO entry
  screen, loaded the active adapter, and emitted no browser console errors.
- Static inspection confirms the active adapter contains only read-only REST requests for orders,
  riders, and ratings; protected mutations use RPCs. Legacy inline generic persistence remains
  disabled by the active adapter and was not expanded or rewritten.
- `git diff --check`: **PASS**. Complete diff inspected; no RLS migration, Vendor HTML, shared
  client, Production, or unrelated application changes were introduced by Batch-2.
- Ephemeral staging password securely deleted. Mutation flags and database URL are absent outside
  completed subprocesses.
- Branch/HEAD: `staging` / `607d768d270734f21a8c605eb60abdd600917bc6`.
- Existing S4-02 documentation, Batch-1 migrations/tests, and prior checkpoint state preserved.
- Commit/push: **NO / NO**. Production accessed/modified/credentials used: **NO / NO / NO**.

**Status:** S4-03-Batch-2 Vendor protected-contract cutover and staging regression **PASS**.

**NEXT EXACT ACTION:** Founder review of S4-03-Batch-2 results before any authorization to begin
S4-03-Batch-3 RLS narrowing. Do not start Batch-3 without explicit authorization.

## 29. S4-03-Batch-3 Entry — BLOCKED at Staging Credential Gate

**Updated:** 2026-08-27 (Codex active implementation agent)

- Founder accepted Batch-2 and authorized Batch-3 RLS narrowing and security acceptance.
- Recovery verification: branch `staging`, HEAD
  `607d768d270734f21a8c605eb60abdd600917bc6`; existing S4-02 documentation, Batch-1 migrations
  and tests, Batch-2 Vendor adapter/test, and prior checkpoint work remain preserved.
- Batch-1 migrations `202608270001` and `202608270002` are present.
- Batch-2 active adapter cutover is present; targeted active direct mutation dependency remains
  **NONE**. Existing protected RPCs are SECURITY DEFINER with fixed search paths, so their table
  mutations are designed to continue independently of caller RLS policy permission; live staging
  verification remains required before migration.
- `git diff --check`: **PASS**.
- Required staging credential is unavailable: `DATABASE_URL` is not injected and
  `/tmp/cefflo-staging-db-password.ephemeral` is absent.
- No Batch-3 migration or test file was created; no database action was attempted.
- RLS policies changed: **NO**. Production accessed/modified: **NO / NO**.

**Current blocker:** recreate the approved cefflo-staging password at
`/tmp/cefflo-staging-db-password.ephemeral` with mode `0600` through the established out-of-band
mechanism. Never place its value in chat or tracked files.

**NEXT EXACT ACTION:** after credential availability, run fail-closed staging identity validation
and read-only live verification of the targeted policies and protected-function execution model;
only then create the forward-only Batch-3 narrowing migration.

### 29.1 Batch-3 Credential and RPC/RLS Execution Preflight — PASS

- Approved ephemeral staging credential restored with mode `0600`.
- Fail-closed identity/connectivity positively matched environment `staging`, project ref
  `tomvvmwktehexwhktenw`, database `postgres`, and the official Mumbai session pooler.
- Live targeted policies are exactly the expected broad state: `riders_vendor`, `orders_vendor`,
  and `assignments_vendor` are `ALL`; existing rider-scoped SELECT policies remain present.
- All eleven protected happy-path functions are live as SECURITY DEFINER, owned by `postgres`,
  have fixed `search_path` configuration, and remain executable by `authenticated`.
- The live function owner has `BYPASSRLS`; protected function table writes therefore execute under
  the definer authorization model rather than the caller's narrowed policies. The functions also
  retain their explicit actor/business authorization checks.
- `authenticated` currently has table-level INSERT/UPDATE/DELETE grants, so removing mutation RLS
  policies will fail closed at row-policy enforcement while leaving SELECT policies explicit.
- Active Vendor targeted direct mutation dependency remains **NONE**.
- Production accessed/modified: **NO / NO**.

**NEXT EXACT ACTION:** create the smallest forward-only migration that replaces only the three
targeted `ALL` policies with same-name business-member SELECT policies, plus rollback-only Batch-3
direct-bypass acceptance tests; validate both locally before staging application.

### 29.2 Batch-3 Migration and Acceptance Harness Prepared — PASS

- Added forward-only migration `202608270003_s4_03_batch_3_rls_narrowing.sql`.
- The migration changes only `riders_vendor`, `orders_vendor`, and `assignments_vendor`, replacing
  each `ALL` policy with a same-name business-member `SELECT` policy. It contains no unrelated
  policy, schema, grant, or permissive mutation change.
- Added rollback-only `tests/s4_03_batch_3_rls.py` covering protected RPC writes after narrowing;
  direct INSERT/UPDATE/status/DELETE bypass denial across orders, riders, and assignments;
  cross-business denial; Operator Owner-only denial; Rider delivery scope; and anon token-only
  public scope.
- Python compile: **PASS**. Environment plus Batch-2 static regression: **35/35 PASS**.
- JavaScript syntax: **PASS**. `git diff --check`: **PASS**.
- Transactional disposable-local migration parse/policy-shape check: **PASS / rolled back**;
  targeted policies became exactly SELECT within the transaction.
- Staging migration applied: **NO**. Production accessed/modified: **NO / NO**.

**NEXT EXACT ACTION:** apply only migration `202608270003_s4_03_batch_3_rls_narrowing.sql` to the
positively verified staging target in one transaction, record ledger version `202608270003`, and
immediately verify the three targeted policies are SELECT-only with no outside policy changes.

### 29.3 Batch-3 Staging RLS Narrowing Applied — PASS

- Applied only `202608270003_s4_03_batch_3_rls_narrowing.sql` to positively verified
  `cefflo-staging` (`tomvvmwktehexwhktenw`) in one transaction.
- Recorded migration ledger version `202608270003:s4_03_batch_3_rls_narrowing`.
- Live targeted policy state is now exactly:
  `orders_vendor:SELECT`, `riders_vendor:SELECT`, `assignments_vendor:SELECT`.
- No other migration or provider change was performed.
- Production accessed/modified: **NO / NO**.

**NEXT EXACT ACTION:** run `tests/s4_03_batch_3_rls.py` once against staging with fail-closed
mutation authorization; stop on any protected-RPC failure or direct-bypass success, otherwise
verify the transaction rolled back with zero residual markers.

### 29.4 Batch-3 Security Matrix — FAIL / STOPPED on Rider Cross-Business Defect

- `tests/s4_03_batch_3_rls.py` stopped at the Rider scope matrix.
- Proven defect: a Business A rider was able to call `rider_transition` for an unassigned Business
  B order. The function's guard uses `o.assigned_rider_id <> rid`; when
  `assigned_rider_id` is NULL, the expression is NULL and PL/pgSQL does not enter the rejection
  branch. The subsequent SECURITY DEFINER update therefore crosses the intended business/delivery
  boundary.
- This defect predates Batch-3 and is exposed now by the required two-business acceptance matrix;
  it is not caused by the SELECT-only policies.
- Tests completed before the stop proved protected Owner RPC writes still work after narrowing and
  denied all required Owner direct INSERT/UPDATE/status/DELETE bypasses for orders, riders, and
  rider assignments, plus Owner-B direct/RPC access to Business-A data and Operator Owner-only
  RPCs. The public/customer portion and final soft-deactivation assertion were not reached.
- The failed test transaction rolled back. Residual Batch-3 users/businesses: **zero**.
- Applied ledger `202608270003` remains present and targeted policies remain SELECT-only.
- Per the authorization ambiguity stop condition, no corrective function migration was created,
  no RLS policy was weakened, and remaining regression/acceptance suites were not run.
- Ephemeral staging password securely deleted.
- Production accessed/modified: **NO / NO**. Commit/push: **NO / NO**.

**Current blocker:** `rider_transition` requires an explicitly authorized forward-only correction
using a NULL-safe assignment guard (for example `o.assigned_rider_id is distinct from rid`) before
Batch-3 acceptance can resume. The same assignment guard shape in `complete_delivery` must be
reviewed and corrected together if confirmed, rather than leaving a parallel cross-business path.

**NEXT EXACT ACTION:** Founder review and explicit authorization for a forward-only security-fix
migration covering the NULL-unsafe assignment checks in `rider_transition` and, if confirmed,
`complete_delivery`; then recreate the staging credential and resume Batch-3 from this failed
Rider-scope gate. Do not start S4-04.

### 29.5 Rider-Scope Security Fix Authorized — BLOCKED at Credential Gate

- Founder authorized exactly one forward-only migration replacing only
  `o.assigned_rider_id <> rid` with `o.assigned_rider_id is distinct from rid` in
  `rider_transition` and `complete_delivery`, preserving every other behavior.
- Branch/HEAD remain `staging` / `607d768d270734f21a8c605eb60abdd600917bc6`.
- Existing S4-03 files and applied-narrowing migration source remain present and preserved.
- `git diff --check`: **PASS**.
- Required staging credential is absent at
  `/tmp/cefflo-staging-db-password.ephemeral`; no fix migration or test change was created.
- Production accessed/modified: **NO / NO**. Commit/push: **NO / NO**.

**Current blocker:** recreate the approved cefflo-staging password at
`/tmp/cefflo-staging-db-password.ephemeral` with mode `0600` using the existing out-of-band flow.

**NEXT EXACT ACTION:** after credential availability, prove fail-closed staging identity, create
and locally validate `202608270004_s4_03_batch_3_rider_scope_fix.sql` plus the focused assignment
scope regression, then apply the single authorized forward-only fix to staging.

### 29.6 Rider-Scope Fix Prepared and Locally Validated — PASS

- Fail-closed staging identity again positively matched only `tomvvmwktehexwhktenw`; ledger through
  `202608270003` and SELECT-only targeted policies were confirmed before file changes.
- Added `202608270004_s4_03_batch_3_rider_scope_fix.sql` with exactly two CREATE OR REPLACE
  statements: `rider_transition` and `complete_delivery`.
- Mechanical comparison against the foundation definitions proves the only function-body change
  is `o.assigned_rider_id<>rid` to `o.assigned_rider_id is distinct from rid`; signatures,
  SECURITY DEFINER, fixed search paths, lifecycle/POD/event/idempotency behavior are identical.
- Added rollback-only `tests/s4_03_rider_scope_fix.py` covering correct/different/NULL/cross-business
  assignments, unknown/inactive riders, the four transitions, completion, and the POD invariant.
- Python compile: **PASS**. `git diff --check`: **PASS**.
- Transactional disposable-local SQL parse and execution-setting check: **PASS / rolled back**.
- Staging fix applied: **NO**. Production accessed/modified: **NO / NO**.

**NEXT EXACT ACTION:** apply only `202608270004_s4_03_batch_3_rider_scope_fix.sql` to positively
verified staging in one transaction, record ledger `202608270004`, and immediately verify both
live definitions contain the NULL-safe comparison with unchanged security settings.

### 29.7 Rider-Scope Fix Applied to Staging — PASS

- Applied only `202608270004_s4_03_batch_3_rider_scope_fix.sql` to positively verified
  `cefflo-staging` in one transaction and recorded ledger version `202608270004`.
- Live `rider_transition` and `complete_delivery` both contain the NULL-safe assignment comparison.
- Both functions remain SECURITY DEFINER with `search_path=public`; signatures and execute grants
  were not changed.
- Production accessed/modified: **NO / NO**.

**NEXT EXACT ACTION:** run `tests/s4_03_rider_scope_fix.py` once against staging with the
fail-closed mutation guard; stop on any assignment-scope or lifecycle/POD regression, otherwise
verify rollback residue before resuming the Batch-3 matrix.

### 29.8 Focused Rider-Scope Regression — PASS

- Correct assigned rider: four-transition lifecycle and completion **PASS**.
- Different rider, NULL assignment, cross-business unassigned order, and cross-business assigned
  order: **DENIED**.
- Unknown/unmapped and inactive rider: **DENIED**.
- `complete_delivery` with NULL assignment: **DENIED**.
- POD-required invariant: empty POD **DENIED**; valid arrived+POD completion **PASS**.
- Test transaction rolled back.
- Production accessed/modified: **NO / NO**.

**NEXT EXACT ACTION:** rerun the complete rollback-only Batch-3 RLS/two-business/Rider/public
matrix from the previously failed gate; stop on any remaining bypass or authorization failure.

### 29.9 Complete Batch-3 Security Matrix — PASS

- Protected Owner RPC writes after narrowing: **PASS**.
- Direct INSERT, UPDATE, lifecycle/status manipulation, and hard DELETE across orders, riders, and
  rider assignments: **DENIED**.
- Business-B RPC/direct mutation against Business-A data: **DENIED**.
- Operator/Staff Owner-only operations: **DENIED**; approved inherited operations remained covered
  by the protected contract suite.
- Rider delivery/cross-business scope: **PASS / cross-scope denied**.
- Customer/Public table access: **DENIED**; tokenized `public_tracking` contract: **PASS**.
- Test transaction rolled back.
- Production accessed/modified: **NO / NO**.

**NEXT EXACT ACTION:** run the complete staging regression sequence: environment guards, backend
validation before E2E, transactional E2E, backend validation after E2E, Batch-1 contracts, and
Batch-2 Vendor cutover tests; stop on any regression.

### 29.10 Final S4-03 Regression and Integrity Gate — PASS

- Environment guards plus Batch-2 Vendor cutover tests: **35/35 PASS**.
- Backend validation before/after E2E: **PASS / PASS**.
- Existing transactional E2E: **PASS / rolled back**.
- Batch-1 protected-contract authorization regression: **PASS / rolled back**.
- Synthetic non-production Vendor build and JavaScript syntax: **PASS**.
- Local Vendor browser load: **PASS**; expected CEFFLO entry screen and no console errors.
- Final staging ledger is exact through `202608270004`; both fixed functions are NULL-safe,
  SECURITY DEFINER, and fixed-path.
- All public tables have RLS enabled. Targeted Vendor policies remain SELECT-only. `cefflo-pod`
  remains private. Public schema objects match the tracked foundation plus Batch-1 audit table.
- Residual test users, businesses, and audit markers: **zero**.
- Ephemeral staging password securely deleted; database URL and mutation flags were subprocess
  scoped only.
- No policy outside the three Batch-3 targets changed. No prior migration was rewritten.
- `git diff --check`: **PASS**. Production accessed/modified/credentials used: **NO / NO / NO**.
- Commit/push: **NO / NO**.

**Status:** S4-03 rider-scope fix and complete Batch-3 acceptance **PASS**, pending Founder formal
closure. S4-04 has not started.

**NEXT EXACT ACTION:** Founder review for formal S4-03 closure and recovery of canonical S4-04.
Do not start S4-04 without separate authorization.

## 30. Independent Security Review — Batch-3 Defect Confirmed (Claude, read-only)

**Confirms Codex's Section 29.4 finding independently**, via direct inspection of the actual current SQL (not the report alone), the table's column constraints, and the failing test — extends it by closing the two items Codex left open ("if confirmed" on `complete_delivery`; no stated check of the 6 new Batch-1 functions).

- **Defect confirmed, root cause verified from first principles:** `rider_transition` and `complete_delivery` (both unchanged since the original `202608130001_cefflo_foundation.sql`, never touched by `202608270001`/`...02`/`...03`) both gate on `o.id is null or rid is null or o.assigned_rider_id<>rid`. `assigned_rider_id` is a nullable column (`references riders on delete set null`); when NULL, `<>rid` evaluates to SQL NULL, the OR-chain evaluates to NULL, and PL/pgSQL treats a NULL `IF` condition as false — the `raise exception 'forbidden'` never fires. Any authenticated active rider (any business) can then act on any unassigned order of any other business. Independently reproduced the exact scenario in `tests/s4_03_batch_3_rls.py` line 87 (unassigned `order_b` in Business B) / line 158 (Business A's rider calling `rider_transition` against it, expected `rejected(...,"forbidden")`).
- **`complete_delivery`'s separate `o.delivery_status<>'arrived'` guard is NOT the same bug** — `delivery_status` is `NOT NULL` on the `orders` table, so that comparison is always well-defined. Only the `assigned_rider_id` comparison is unsafe.
- **Targeted sibling search — all 13 existing SECURITY DEFINER mutation functions checked** (7 original: `bootstrap_business`, `create_delivery`, `assign_rider`, `rider_transition`, `complete_delivery`, `public_tracking`, `submit_rating`; 6 new Batch-1: `update_business_profile`, `deactivate_rider`, `update_rider_details`, `update_order_details`, `update_team_member`, `reassign_rider`). **Only `rider_transition` and `complete_delivery` have the defect.** Every other function gates on `is_business_member()`/`is_business_owner()` (boolean-returning, safe) or a `NOT EXISTS` subquery with fully-qualified literal filters (safe — NULL in a WHERE-clause existence check yields "no match" → correctly denied, unlike NULL inside a PL/pgSQL `IF ... <> ...` condition). This is a scoped, evidence-based answer, not a broad re-audit.
- **Recommended NULL-safe condition (matches Codex's own proposal):** replace `o.assigned_rider_id<>rid` with `o.assigned_rider_id is distinct from rid` in both functions, keeping the existing `o.id is null or rid is null or ...` structure unchanged. `IS DISTINCT FROM` correctly returns TRUE when `assigned_rider_id` is NULL (closing the bug) while preserving identical behavior for every already-correct case (matching rider → allowed; different non-null rider → denied, unchanged).
- **SECURITY DEFINER implication confirmed:** both functions run as their owner (`BYPASSRLS`, per Codex's 29.1 finding), so this in-function check is the *only* gate — there is no RLS backstop for it. This is exactly why the bug was a full bypass, not a partial one.
- **Cross-business "assigned" order was never exploitable** — only the *unassigned* case was broken. A non-null mismatched `assigned_rider_id` was already correctly rejected pre-fix.
- **Fix does not reopen S4-02 architecture.** The bug is in code that predates S4-02/S4-03 entirely (original foundation migration); it is orthogonal to the permission matrix, the new contracts, and the RLS-narrowing design, all of which remain independently valid and require no rework. Batch-3's already-applied policy narrowing (`202608270003`) is unaffected and does not need to be rolled back.
- **Implementation files modified by this review: NONE.** Production accessed: NO. This entry is documentation only.

## 31. S4-03 FORMAL CLOSURE — Founder Accepted

**Status: S4-03 = COMPLETE / PASS / FOUNDER ACCEPTED.**

**Operating-model change (this turn):** Claude is now the primary architect/implementation engineer/security reviewer for CEFFLO Stage 4. Codex remains available as backup/independent QA/handoff, not invoked by default to duplicate work already done.

**Final staging migration ledger:**
1. `202608130001` — `cefflo_foundation`
2. `202608270001` — `s4_03_batch_1_contracts`
3. `202608270002` — `s4_03_batch_1_audit_array_fix`
4. `202608270003` — `s4_03_batch_3_rls_narrowing`
5. `202608270004` — `s4_03_batch_3_rider_scope_fix`

**Final targeted RLS state:** `riders_vendor` / `orders_vendor` / `assignments_vendor` = SELECT only (business-member read preserved everywhere; no direct-write path remains on any of the three tables).

**Rider-scope defect closed** — independently verified by reading the actual applied `202608270004` file (not just accepting the report): `rider_transition` and `complete_delivery` now use `o.assigned_rider_id is distinct from rid`, replacing the NULL-unsafe `<>`. Every other line in both functions is byte-identical to the original foundation migration — confirms this was a minimal, forward-only, non-behavior-changing fix exactly as recommended in Section 30. No rollback performed or required.

**Verified final acceptance (per Founder + this session's independent review, Sections 29-30):** direct-write bypasses denied; two-business matrix PASS; Owner/Operator-Staff/Rider/Customer-Public authorization all PASS; protected happy path PASS; Vendor protected-contract cutover PASS; backend validation PASS; transactional E2E PASS; database integrity PASS; residual test data zero; RLS narrowing remains valid (unaffected by the rider-scope fix, since that fix lives entirely inside the two RPCs, not the policies).

**Production accessed: NO. Production modified: NO.** `git diff --check`: PASS (see below). Checkpoint updated; no commit/push performed.

## 32. S4-04 Recovered (canonical, reconciled against current state) — NOT STARTED

**Official name:** S4-04 — Repair POD, token lifecycle, public endpoints, and Rider logout.

**Canonical sources:** `docs/cefflo/PHASE_1_STAGE4_GAP_REPORT.md` §7 row S4-04 (`REPAIR`+`COMPLETE`/`P0`, dependency S4-02+S4-03 — both now satisfied; canonical docs `08_CUSTOMER_TRACKING.md`, `10_DELIVERY_LIFECYCLE.md`, `11_SUPABASE.md`, `12_SECURITY.md`; likely code areas: migrations/RPCs, storage, Edge Function, shared/Rider/Customer adapters, tests; acceptance: "Real authorized POD succeeds; nonexistent/foreign paths fail; token/logout/security tests pass"; Founder approval YES for security/backend changes), `docs/cefflo/PHASE_1_BACKEND_SECURITY_BASELINE.md` §18 decisions #8-#9, and `docs/cefflo/08_CUSTOMER_TRACKING.md` (read in full this turn — CT-03 Security: token format/entropy/expiry, rate-limit public endpoints, no unnecessary internal-ID/PII exposure, controlled/signed POD access, protected rating mutation).

**Entry criteria:** S4-02 and S4-03 both passed — now satisfied.

**Reconciliation against CURRENT repository/staging state (verified this turn, not assumed from the old Phase 1 audit):**
- **Rider logout — STILL BROKEN.** `rider/index.html`'s actual `doLogout()` (bound to the UI's "Yes, Log Out" button) is `localStorage.removeItem('cefflo_session'); showScreen('screen-login');` only — it never calls `window.CEFFLO.logout()` (the correct implementation in `shared/client.js`, which does call `/auth/v1/logout` to revoke the server-side session). It also uses a different, seemingly-legacy localStorage key (`cefflo_session`) than the shared client's (`cefflo.auth.session.v1`/`CEFFLO_SESSION_KEY`). Confirmed via direct code read — the Phase 1 finding is still accurate; S4-01/02/03 never touched this file's logout path.
- **Tracking-token lifecycle — STILL UNADDRESSED.** `create_delivery` still inserts into `tracking_tokens` without setting `expires_at` (confirmed unchanged since the original foundation migration); no expiry/rotation/revocation RPC exists.
- **Public-endpoint hardening — STILL UNADDRESSED.** `supabase/functions/tracking-pod/index.ts` still has wildcard `Access-Control-Allow-Origin: '*'` and returns raw `error.message` to the client; confirmed unchanged.
- **POD path exposure — STILL UNADDRESSED.** `public_tracking`'s RPC still returns `pod_storage_path` directly inside its JSON payload (not just via the already-correct signed-URL Edge Function path); confirmed unchanged.
- **Rate limiting — CONFIRMED ABSENT** repo-wide (targeted grep for `rate.limit`/`rateLimit`/`throttl` found zero implementation anywhere).
- Nothing in S4-01/02/03's work touched any of the above — all five findings are independently reconfirmed current, not stale carry-overs.

**Exact scope:**
1. Rider logout repair — `doLogout()` (or its call site) must revoke the server-side Auth session (via `shared/client.js`'s `logout()`, or an equivalent correct call) before clearing local state; reconcile the two divergent session-key names.
2. Tracking-token lifecycle — design + implement expiry on creation, and protected rotation/revocation contract(s), per Security Baseline decision #9.
3. Public-endpoint hardening — `tracking-pod` Edge Function: replace wildcard CORS with an allowed-origin policy, normalize error responses (no raw exception messages); add rate-limiting/abuse telemetry to `public_tracking`, `submit_rating`, and the Edge Function per CT-03/11_SUPABASE.md S-08.
4. POD path minimization — stop returning the raw storage path from `public_tracking`; keep it behind the existing signed-URL boundary only.
5. POD completion integrity review (Security Baseline decision #8: upload reservation/receipt, object verification, retry, replacement, retention, deletion policy) — confirm current `complete_delivery`/storage-policy behavior against this decision and close any gap found.

**Out of scope (explicitly, per Founder boundary and canonical dependency structure):** order-approval/readiness lifecycle, cancel/void, session/batch/zone invariants, full reassignment semantics (all S4-05); trusted-team invitation/join (S4-07); typed exception workflow (S4-08). No S4-02/S4-03 architecture (permission matrix, protected-contract pattern, RLS narrowing) is redesigned.

**Backend work:** migrations/RPCs for token lifecycle + POD-path minimization; Edge Function edit for CORS/error-normalization/rate-limiting.

**Frontend work:** minimal, adapter-level only — `rider/backend.js`/`rider/index.html` logout call-site fix (not a UI rebuild), matching the established S4-01–S4-03 pattern of adapter-level cutover rather than wholesale rewrite.

**Security requirements:** SEC-03 (public tracking: high-entropy/protected tokens, minimum exposed data, rate limiting, controlled mutation endpoints), SEC-04 (POD: protect storage/access, avoid public predictable paths), SEC-08 (rate limiting/abuse per risk), SEC-11 (Founder approval before material auth/RLS/security policy execution).

**Required tests:** token expiry/rotation/revocation positive+negative; Edge Function CORS/error-shape regression; rate-limit trigger test (if implemented via DB/edge logic, not just infra-level); Rider logout — session actually revoked server-side after logout (not just local-storage cleared); regression of existing `public_tracking`/`submit_rating`/`tracking-pod` happy path; regression of the full existing `tests/e2e_transaction.py` chain (not redesigned, just re-run).

**Staging acceptance:** all of the above verified on `cefflo-staging` before any Production step, which remains separately Founder-gated, per the same pattern used for S4-01 through S4-03.

**Definition of Done:** real authorized POD access succeeds; nonexistent/foreign/expired/revoked token paths fail with no data leakage; Rider logout revokes the server session; public endpoints have CORS/error/rate-limit hardening in place; token/logout/security tests pass on staging; Production untouched until separately authorized.

### Spec/current-state gaps (only real differences found)
None beyond what's already listed above as "still unaddressed" — the canonical scope and the current code state agree on what's broken; no discrepancy between the Phase 1 audit and current reality was found (S4-01/02/03 simply never touched this surface, so nothing here is stale).

### Founder decisions required before implementation
None block starting S4-04.B02 (Rider logout fix) or S4-04.B04 (POD path minimization) below — both are corrections to already-approved contracts. Two decisions affect scope/design choices within token-lifecycle and rate-limiting batches specifically:
1. Token lifetime policy — what default `expires_at` duration for new tracking tokens, and what rotation/revocation triggers (manual Vendor action? automatic on delivery completion + N days? both?).
2. Rate-limiting mechanism — Supabase/Postgres-level (e.g. a request-count table + check), Edge Function-level, or Cloudflare-level (per `14_CLOUDFLARE.md`, not yet in active use for this project) — affects which layer implements it and whether it's in scope for this repo at all versus infra config.

### Proposed execution plan (NOT executed)

| Batch | Objective | Files/Components | Dependencies | Tests | Acceptance | Effort |
|---|---|---|---|---|---|---|
| S4-04.B01 | Fix Rider logout to revoke server session | `rider/index.html` (`doLogout()`), possibly `rider/backend.js` | None | Logout actually invalidates the Auth session server-side (verify via a follow-up authenticated call failing); local state cleared | Rider logout matches `shared/client.js`'s correct pattern; single divergent session key reconciled | SMALL |
| S4-04.B02 | POD path minimization in `public_tracking` | `supabase/migrations/*` (RPC replace only) | None | `public_tracking` response no longer contains `pod_storage_path`; signed-URL Edge Function flow unaffected and still works | Customer surface still gets POD access only via the existing signed-URL path; no regression | SMALL |
| S4-04.B03 | Tracking-token lifecycle (expiry + rotation/revocation contract) | New migration: `expires_at` default on creation, new revoke/rotate RPC(s) | Founder decision #1 above | Token expires per policy; revoked token denied; rotation issues a new valid token and invalidates the old one | Matches Security Baseline decision #9; existing `public_tracking`/`submit_rating` happy path unaffected | MEDIUM |
| S4-04.B04 | Edge Function CORS + error normalization | `supabase/functions/tracking-pod/index.ts` | None | Allowed-origin enforced; no raw exception text returned to client | Matches SEC-03/CT-03; existing legitimate POD signed-URL flow still works | SMALL |
| S4-04.B05 | Rate limiting / abuse telemetry on public endpoints | Edge Function + possibly a new DB-backed counter/table, or documented as infra-level (Cloudflare) depending on Founder decision #2 | Founder decision #2 above | Repeated abusive calls throttled/logged; legitimate single-token usage unaffected | Matches SEC-08/CT-03/S-08; no regression on legitimate customer flow | MEDIUM (depends on chosen mechanism) |

No batch touches S4-05/S4-07/S4-08 territory. No batch executed this turn.

## 33. S4-04.B01 — Rider Server-Side Logout Repair — COMPLETE / PASS / FOUNDER ACCEPTED

**Status: COMPLETE / PASS / FOUNDER ACCEPTED.** Branch `staging`, HEAD `607d768d270734f21a8c605eb60abdd600917bc6` (unchanged — all work uncommitted, matching established pattern).

**Root cause confirmed** by direct inspection: `rider/index.html`'s `doLogout()` (bound to the "Yes, Log Out" button) only did `localStorage.removeItem('cefflo_session'); showScreen('screen-login');` — it never called the shared client's `logout()`, so the real Supabase bearer session (`cefflo_rider_auth_session`, holding `access_token`/`refresh_token`) was never revoked, server-side or locally.

**Legacy session key classified:** `cefflo_session` (a bare `'1'` flag, distinct from the real credential) is **ACTIVE AND REQUIRED** — it's `rider/index.html`'s own local UI-routing flag (login/pending/home screen selection, read/written in ~7 places including `rider/backend.js`), not a credential and not dead code. Left untouched, per instructions — removing it was unnecessary for this fix and would have broken unrelated routing logic.

**Fix (2 lines, `rider/index.html`):**
```diff
-function doLogout(){
+async function doLogout(){
+  try { await window.CEFFLO.logout(); } catch (error) { console.error('[CEFFLO rider logout]', error); }
   localStorage.removeItem('cefflo_session');
   showScreen('screen-login');
 }
```
Uses the exact same `window.CEFFLO.logout()` call already correctly used elsewhere in `rider/backend.js` (lines 31, 94) — no second authentication implementation introduced. `shared/client.js` (unmodified) already fails safe internally (`.catch(()=>{})` on the network call), and the added `try/catch` here is explicit defense-in-depth.

**Verification performed:**
1. **Real empirical Auth-protocol test** against local disposable Supabase (not staging — no credential gate needed): created an ephemeral confirmed test user via the local admin API, logged in for a real `access_token`, called `/auth/v1/logout` (exactly what the fix now triggers), then confirmed the *same* access_token was rejected (`403`) on a subsequent `/auth/v1/user` call, and the refresh_token was rejected (`400`) too. **This is genuine, immediate server-side session revocation on this Supabase version, not merely a client-side no-op.** Ephemeral test user deleted afterward; no residue.
2. **Static regression test added:** `tests/test_rider_logout_fix.py` (4 tests, all pass) — confirms `doLogout()` calls `window.CEFFLO.logout()`, fails safely via try/catch, still clears the local routing flag and navigates correctly, and does not introduce a second `/auth/v1/logout` call path.
3. **Local synthetic build:** `npm run build` with `CEFFLO_ENVIRONMENT=local` succeeded; confirmed the fix is present in `dist/rider/index.html`.
4. **No regression:** `npm run test:environment` (30/30 PASS, unchanged) and the existing `tests/test_vendor_protected_cutover.py` (5/5 PASS, unchanged) both still pass — no unrelated Vendor/environment-guard behavior affected.
5. **Not performed:** a full interactive browser click-through (login→logout via UI) — stopped by explicit user interruption before invoking the browser tool. Not needed for confidence here: the underlying revocation mechanism is proven empirically at the protocol level (item 1), and the call-site correctness is proven statically (item 2); a full UI walkthrough would additionally have required seeding a fixture rider/business/auth-user (Rider signup is prototype/mock, per Phase 1 docs, and wouldn't produce a real approved rider on its own) — disproportionate for a 2-line, well-understood fix.

**git diff --check: PASS.** Files changed: `rider/index.html` (the fix), `tests/test_rider_logout_fix.py` (new regression test). No RLS, migration, Edge Function, or unrelated RPC touched. No Vendor/Customer behavior changed.

**Production accessed: NO. Production modified: NO. Commit: NO. Push: NO.**

**B02/B03/B04/B05/S4-05: NOT started.**

## 34. S4-04.B02 — Stop `public_tracking` Exposing Raw POD Path — COMPLETE / PASS / FOUNDER ACCEPTED

**Status: COMPLETE / PASS / FOUNDER ACCEPTED.** Branch `staging`, HEAD `607d768d270734f21a8c605eb60abdd600917bc6` (unchanged).

**Reconciliation performed before editing** (per instruction): found exactly two consumers of `public_tracking`'s `pod_path` field —
- `customer/backend.js` (line 15): only ever did a **truthy check** (`snapshot.status === 'delivered' && snapshot.pod_path`), never used the actual path string, before calling the already-secure `podUrl()` (the signed-URL Edge Function). Removing the field outright would have silently broken legitimate POD viewing for every customer.
- `supabase/functions/tracking-pod/index.ts` (line 10-12): the **only** consumer needing the real path value, to pass into `createSignedUrl()`.

This reconciliation is why the fix is not a simple field deletion — it's a boolean replacement for the public contract plus a narrowly-scoped internal lookup for the one legitimate privileged consumer.

**Change (new migration `202608270005_s4_04_batch_2_pod_path_minimization.sql`):**
- `public_tracking`: `'pod_path', case when ... then s.pod_storage_path end` → `'pod_available', (o.delivery_status='delivered' and s.pod_storage_path is not null)`. Every other field/join/token-validation clause byte-identical.
- New `internal_tracking_pod_path(p_token text) returns text`: same token/expiry/revocation validation, returns the real path, granted to `service_role` only.
- `tracking-pod/index.ts`: checks `tracking.pod_available` instead of `tracking.pod_path`; calls the new internal RPC (as the admin/service-role client it already is) to get the real path before signing.
- `customer/backend.js` line 15: `snapshot.pod_path` → `snapshot.pod_available`.

**Self-caught defect during verification (worth recording precisely):** the migration's first draft used `revoke all on function ... from public;` before granting to `service_role`, mirroring the codebase's existing convention (used correctly elsewhere for `authenticated`-only functions). Empirically testing it locally showed `anon`/`authenticated` could **still** execute the new function despite the revoke — `has_function_privilege('anon', ...)` returned `true`. Root cause: this Supabase instance has default privileges (`ALTER DEFAULT PRIVILEGES`) that grant EXECUTE on every new `public`-schema function **directly** to `anon`, `authenticated`, and `service_role` as named roles at creation time — not via the `PUBLIC` pseudo-role — so `revoke ... from public` alone is a silent no-op for this specific restriction. Fixed to `revoke all on function ... from public, anon, authenticated;` and re-verified `has_function_privilege` returns `false`/`false`/`true` for anon/authenticated/service_role respectively. This is now documented inline in the migration as a comment, since it's a non-obvious platform behavior any future service_role-only function on this project must account for.

**Verification performed (all against a fully fresh local-disposable-Supabase reset — `npx supabase db reset --local` — not the earlier ad-hoc patch):**
1. All 6 migrations (`202608130001` through the new `202608270005`) apply cleanly in sequence from scratch.
2. New test `tests/s4_04_batch_2_pod_path.py` (rollback-only, matching established convention): confirms `public_tracking` never contains a `pod_path` key or any string resembling a storage path, before and after delivery; confirms `pod_available` is `false` pre-delivery and `true` post-delivery; confirms `anon`, an authenticated business owner, and the assigned rider are **all** denied (`permission denied`) calling `internal_tracking_pod_path` directly; confirms cross-business (Business B owner) is also denied; confirms only `service_role` can resolve the real path, and only for a valid token (an invalid token returns `NULL`, not an error/leak). **PASS.**
3. Regression, same fresh target: `validate_backend.py` (`backend_contract_ok`), `e2e_transaction.py` (`e2e_transaction_ok` — full existing lifecycle chain unaffected), `s4_03_batch_1_contracts.py`, `s4_03_batch_3_rls.py`, `s4_03_rider_scope_fix.py` — all still pass unchanged.
4. `npm run test:environment` (30/30) and `tests/test_vendor_protected_cutover.py` + `tests/test_rider_logout_fix.py` (9/9) — all still pass; confirms zero Vendor/Rider regression from this Customer/public-endpoint-only change.
5. `customer/backend.js` syntax verified with `node --check` (extracted IIFE). `tracking-pod/index.ts` has no Deno toolchain available to compile locally; verified by direct read plus a balanced-braces/parens sanity check — the edit is a 3-line, structurally minimal change to an already-reviewed file.

**git diff --check: PASS.** Files changed: `supabase/functions/tracking-pod/index.ts`, `customer/backend.js`; new `supabase/migrations/202608270005_s4_04_batch_2_pod_path_minimization.sql`, new `tests/s4_04_batch_2_pod_path.py`. No RLS policy touched, no unrelated RPC touched, no Vendor/Rider file touched.

**Production accessed: NO. Production modified: NO. Commit: NO. Push: NO.**

**B03/B04/B05/S4-05: NOT started.**

## 35. S4-04.B03 — Tracking-Token Lifecycle — COMPLETE / PASS / FOUNDER ACCEPTED

**Status: COMPLETE / PASS / FOUNDER ACCEPTED.** Branch `staging`, HEAD `607d768d270734f21a8c605eb60abdd600917bc6` (unchanged).

**Founder-locked policy reconciled against current schema/contracts — no technical blocker found.** `tracking_tokens.order_id` being `unique` makes rotation a simple in-place `UPDATE` (not a new row), which naturally satisfies "invalidate the previous token immediately" (the old hash exists nowhere once overwritten) without any schema change. `delivery_events` is directly reusable for audit (order-scoped, already has `actor_user_id`/`actor_role`/`metadata jsonb`, already deny-by-default for direct writes).

**Implementation (new migration `202608270006_s4_04_batch_3_token_lifecycle.sql`):**
- `create_delivery`: **no change** — it already leaves `expires_at` `NULL` at creation, which already means exactly "valid for the life of an active delivery" per the Founder's locked policy (no arbitrary 7-day creation clock). This was independently confirmed to match the policy precisely rather than assumed.
- `complete_delivery`: `create or replace`, adding one statement — `update tracking_tokens set expires_at=now()+interval '48 hours' where order_id=o.id` — inside the existing idempotent completion block (guarded by the pre-existing `if o.delivery_status='delivered' then return o` early-return, so it can't double-fire). Every other line byte-identical to the `202608270004` version.
- New `revoke_tracking_token(p_order_id)`: business-scoped (`is_business_member` — Owner **and** Operator/Staff, matching the Founder's explicit both-roles instruction), sets `revoked_at=now()`, logs a `delivery_events` row (`tracking_token_revoked`), returns `boolean` only — **never returns the token row** (which would leak `token_hash`).
- New `rotate_tracking_token(p_order_id)`: same business-scoped authorization, generates a fresh token via the identical `gen_random_bytes(32)`/`digest(...,'sha256')` pattern `create_delivery` already uses, sets `expires_at` to `NULL` if the order isn't yet delivered or `now()+48h` if it is (Founder's exact rule 5), clears `revoked_at`, logs `tracking_token_rotated`, returns the **raw new token only** (never the hash).
- Grants: `revoke all on function ... from public, anon, authenticated; grant execute ... to authenticated;` on both new functions — applying the Batch-2-discovered Supabase default-privilege fix (explicit `anon`/`authenticated` revoke, not just `from public`) **proactively this time**, verified via `has_function_privilege`: `anon` denied, `authenticated` allowed, on both.

**Verification (fresh `npx supabase db reset --local`, all 7 migrations applied clean):**
- New test `tests/s4_04_batch_3_token_lifecycle.py` (rollback-only): active/undelivered order carries no expiry and remains usable indefinitely; cross-business (`owner_b`), Rider, and anon are all denied calling either new RPC (anon denied at the **grant** layer with `permission denied`, authenticated-wrong-business denied **inside** the function with `forbidden` — both layers verified as genuinely distinct, not assumed); Operator/Staff *and* Owner both successfully rotate/revoke (both-roles requirement verified positively, not just negatively); rotation invalidates the old token immediately and the new one is immediately usable; revoke denies access with no reactivation path (recovery only via a fresh rotation); rotating an active order keeps `NULL` expiry, rotating a delivered order grants a fresh ~48h window measured from rotation time (not the original `completed_at`); `delivery_events` audit rows recorded for every revoke/rotate with `actor_role='vendor'` and metadata containing only `token_id` — verified the raw token string never appears in any audit row; completing delivery sets `expires_at` to within a few seconds of `completed_at+48h`; normal customer `public_tracking`/`submit_rating` access verified to never mutate `expires_at`. One test-harness bug was caught and fixed during this process: an early draft tried to read `tracking_tokens` directly as a simulated business-member actor, which the table's own zero-SELECT-policy design (correctly, by S4-02.A's own matrix) denies — fixed by reading ground truth via the unrestricted harness connection (`reset role`) for internal-state assertions, never treating that as a real actor capability. **PASS.**
- Full regression on the same fresh target: `validate_backend.py` (`backend_contract_ok`), `e2e_transaction.py` (`e2e_transaction_ok` — full existing lifecycle, including `public_tracking`/`submit_rating`, unaffected), `s4_03_batch_1_contracts.py`, `s4_03_batch_3_rls.py`, `s4_03_rider_scope_fix.py`, `s4_04_batch_2_pod_path.py` — all pass unchanged.
- `npm run test:environment` (30/30) and the Vendor/Rider static suites (9/9) — zero regression outside the token-lifecycle surface.

**Incidental finding (not fixed, out of scope — informational only):** the same anon-default-privilege gap fixed here and in B02 likely also technically applies to Batch-1's six functions (`update_business_profile`, `deactivate_rider`, `update_rider_details`, `update_order_details`, `update_team_member`, `reassign_rider`), which only did `revoke all ... from public` before granting to `authenticated`. Practically low-severity there (each already gates internally on `is_business_member`/`is_business_owner` via `auth.uid()`, which is `NULL` for a genuine `anon` caller, so the internal check still correctly blocks it) — not a live bypass, but a defense-in-depth gap worth closing in a future hardening pass. Not touched this turn: S4-03 is already Founder-closed and reopening it wasn't authorized.

**git diff --check: PASS.** Files changed: new `supabase/migrations/202608270006_s4_04_batch_3_token_lifecycle.sql`, new `tests/s4_04_batch_3_token_lifecycle.py`. No RLS policy touched, no Vendor/Rider/Customer file touched, no S4-05 cancel/void semantics implemented.

**Production accessed: NO. Production modified: NO. Commit: NO. Push: NO.**

**B04/B05/S4-05: NOT started.**

## 36. S4-04.B04 — `tracking-pod` Edge Function Hardening — PASS (awaiting Founder review)

**Status: PASS** (with explicit, un-hidden gaps in runtime verification — see below). Branch `staging`, HEAD `607d768d270734f21a8c605eb60abdd600917bc6` (unchanged).

**Technical debt formally recorded per Founder instruction (not fixed, S4-03 not reopened):** the six S4-03 Batch-1 protected functions (`update_business_profile`, `deactivate_rider`, `update_rider_details`, `update_order_details`, `update_team_member`, `reassign_rider`) likely retain unnecessary `anon`/`authenticated` EXECUTE grants caused by Supabase default privileges (the same class of issue B02 first discovered and B03 proactively fixed for its own new functions). Their internal `is_business_member`/`is_business_owner` checks already prevent practical bypass (an `anon` caller has `auth.uid() = NULL`, which those checks correctly reject regardless of the grant). Preserved for a later security-hardening/final-acceptance review, not addressed in B04.

**Reconciliation before editing:** re-read the actual current `tracking-pod/index.ts` (post-B02) and confirmed the B02/B03 contract it depends on: `public_tracking` → `pod_available` boolean only; `internal_tracking_pod_path` → service-role-only raw path; `createSignedUrl` on the private `cefflo-pod` bucket. None of this needed to change — B04 only touches how the function talks to the browser (CORS) and what it says on failure (error shape), not what it checks or signs.

**CORS design:** replaced wildcard (`Access-Control-Allow-Origin: '*'`) with an explicit allowlist, checked via exact string match against the request's `Origin` header (never reflected/wildcarded for a non-matching origin). The allowlist is env-configurable (`CEFFLO_TRACKING_CORS_ORIGINS`, comma-separated) with a hard-coded default containing exactly one entry: `https://new-project-git-staging-cefflohq26-6353s-projects.vercel.app` — the one Customer-serving origin empirically verified live and reachable earlier this session (via a direct fetch during the S4-01 isolation review), not a guess. Production's real tracking domain (`track.cefflo.com` per `08_CUSTOMER_TRACKING.md` CT-01) is **not** hard-coded, since it is not currently attached/resolving anywhere (confirmed via the Vercel project's domain list) — per the explicit instruction not to guess an unestablished origin. An env-configured value fully replaces the default rather than merging with it (verified by test).

**Preflight handling:** `OPTIONS` requests get a `204` with `Vary: Origin` always, plus `Access-Control-Allow-Origin`/`-Headers`/`-Methods` only when the origin is in the allowlist. A disallowed origin's preflight gets no permissive header, so the browser blocks the follow-up real request — the standard, correct CORS mechanism (not an application-layer 403, since CORS is fundamentally a browser-enforced read restriction, not a server-side access-control gate; the token remains the actual authorization boundary, unchanged).

**Disallowed-origin behavior:** the actual request logic still runs identically regardless of Origin (a non-browser caller doesn't send/enforce CORS at all, so gating business logic on Origin would be security theater) — only the response headers vary. Verified: disallowed/missing origins get zero CORS headers beyond `Vary: Origin`; a literal `'*'` in a misconfigured env value is treated as a non-matching literal string, never as allow-all (tested explicitly).

**Error contract:** every client-facing error is now one of exactly three fixed strings — `"Invalid request"` (400, malformed/missing token), `"POD unavailable"` (404, covers token-not-found/expired/revoked/not-yet-delivered/missing-POD/signing-failure **uniformly and indistinguishably**, deliberately — matching `public_tracking`'s own existing anti-enumeration design and D-20, so a caller can never probe which specific reason caused a denial), `"Unexpected error"` (500, any unforeseen exception). Raw error objects are now only ever passed to `console.error(...)` (Edge Function server-side logs), never into a `Response.json` body — confirmed by static check that no `error.message`/`signError.message` appears in any client-facing code path.

**Information-leakage verification:** static checks confirm no Postgres/RPC/storage internals, no `pod_path`-as-a-public-field, no service-role key or publishable key literal, and no wildcard CORS anywhere in the file.

**Legitimate POD happy path preserved:** the success path (`public_tracking` → `internal_tracking_pod_path` → `createSignedUrl` → `{url, expiresIn}`) is structurally unchanged from B02 — only wrapped with the new CORS headers and routed through `safeError` on failure instead of the old catch-all.

**B02 regression / B03 regression / other regression:** all PASS — `validate_backend.py`, `e2e_transaction.py`, `s4_04_batch_2_pod_path.py`, `s4_04_batch_3_token_lifecycle.py`, `s4_03_batch_1_contracts.py`, `s4_03_batch_3_rls.py`, `s4_03_rider_scope_fix.py` (all DB-side, unaffected since this batch touches only the Edge Function file), `npm run test:environment` (30/30), Vendor/Rider static suites (9/9). None of these exercise the Edge Function itself — they confirm the database/RPC layer B04 depends on is untouched.

**Runtime verification performed (genuine, actually executed):** new `tests/s4_04_batch_4_edge_hardening.py` — 6 tests that **extract the real CORS-matching functions verbatim from the actual source file and execute them with Node** (not Deno, but real execution of the real algorithm, not a re-implementation in the test): confirms the default staging origin is allowed, a disallowed origin gets no permissive header, no-Origin requests get no permissive header, an env-configured allowlist fully replaces the default and is isolated from it, an empty-string origin never matches, and a literal `'*'` is never treated as allow-all. Plus 8 static structural checks (no wildcard CORS, no raw error forwarding, fixed error messages present, server-side logging present, B02/B03 contracts textually preserved/untouched, service-role+private-bucket preserved, no hardcoded secrets).

**Runtime verification still required (explicitly not claimed as done):** the actual `Deno.serve` HTTP dispatch was never invoked — no local Deno runtime is available in this environment (confirmed absent again this turn). Specifically NOT verified by running real HTTP requests: a real `OPTIONS` preflight round-trip, a real `POST` from an allowed vs. disallowed browser `Origin`, a real malformed-JSON-body request, a real invalid/expired/revoked-token request against a live database, a real successful signed-URL issuance end-to-end. All of these require either a local Deno install or an actual staging deployment of the updated function (`supabase functions deploy tracking-pod` against `cefflo-staging`, which is a provider action not authorized in this batch). This gap is real and should be closed via staging deployment + live testing before this batch is treated as fully release-ready, even though the static/functional evidence gathered here is strong.

**git diff --check: PASS.** Files changed: `supabase/functions/tracking-pod/index.ts` (full rewrite of CORS/error handling, B02/B03 logic preserved); new `tests/s4_04_batch_4_edge_hardening.py`. No RLS, migration, Vendor/Rider/Customer file, token-lifecycle, or S4-05 logic touched.

**Production accessed: NO. Production modified: NO. Commit: NO. Push: NO.**

**B05/S4-05: NOT started.**

## 37. S4-04.B04 — Staging Runtime Acceptance — PARTIAL PASS, remaining scenarios BLOCKED

**Status: PARTIAL PASS.** Deployment succeeded and 6 of the 11 requested scenarios verified with real HTTP evidence. The remaining 4-5 fixture-dependent scenarios are genuinely BLOCKED, not improvised around.

**Target identity (fail-closed, verified before any action):** `list_projects` (Supabase Management API) called fresh this turn — confirmed exactly two projects exist: `cefflo-staging` (`tomvvmwktehexwhktenw`, region `ap-south-1`, `ACTIVE_HEALTHY`) and `cefflo-platform` (`lmaxtrubwdniovxyuqdy` — the known Production ref, `ACTIVE_HEALTHY`). Every subsequent call used `project_id=tomvvmwktehexwhktenw` explicitly; the Production ref was never referenced in any tool call this turn.

**Function deployed:** `tracking-pod`, version 1 (first-ever deployment to `cefflo-staging` — `list_edge_functions` showed zero functions before this), `status: ACTIVE`, `verify_jwt: false`. **`verify_jwt` justification (explicit, not a default-accepted guess):** the function implements its own custom authentication (the tracking token, validated via `public_tracking`), and `customer/backend.js`'s actual call sends only an `apikey` header with no `Authorization: Bearer <user-jwt>` — requiring `verify_jwt: true` would reject every legitimate customer request at the gateway before the function even runs, breaking the no-account customer flow (D-04/CT-04). Deployed source is functionally identical to the reviewed local file (minus the test-only trailing `export` statement and TS-only `!` non-null assertions, both no-ops for runtime since Supabase auto-injects `SUPABASE_URL`/`SUPABASE_SERVICE_ROLE_KEY`).

**Runtime scenarios — real HTTP requests against `https://tomvvmwktehexwhktenw.supabase.co/functions/v1/tracking-pod`:**

| # | Scenario | Result | Evidence |
|---|---|---|---|
| 1 | Allowed-Origin POST | **PASS** | `Origin: <staging alias>` → `404 {"error":"POD unavailable"}` with `access-control-allow-origin` echoing the exact origin |
| 2 | Allowed-Origin OPTIONS | **PASS** | `204`, correct `Access-Control-Allow-Origin/-Headers/-Methods`, `Vary: Origin` |
| 3 | Disallowed Origin | **PASS** | `Origin: https://evil.example.com` → identical `404 {"error":"POD unavailable"}` body, but **zero** `access-control-*` headers present — browser would block the page from reading it |
| 4 | Malformed Request | **PASS** | Missing `token` field, invalid JSON body, and wrong-type `token` (number) all → `400 {"error":"Invalid request"}` |
| 5 | Invalid Token | **PASS** | Garbage token string → `404 {"error":"POD unavailable"}`; confirmed via `query_logs` (read-only) against `function_logs` that **no `console.error` fired** for this request, meaning `public_tracking` was called successfully and legitimately returned no match — not a masked RPC failure |
| 6 | Expired Token | **BLOCKED** | needs a real token row with a past `expires_at` |
| 7 | Revoked Token | **BLOCKED** | needs a real token row with `revoked_at` set |
| 8 | Missing/Unavailable POD | **BLOCKED** | needs a real, valid, non-delivered (or delivered-without-POD) order/token |
| 9 | Authorized POD Signed URL | **BLOCKED** | needs a real delivered order with a POD object actually uploaded to `cefflo-pod` |
| 10 | No Information Leakage | **PASS for all paths actually exercised** (1-5 above: clean, fixed-shape bodies, no raw DB/RPC/storage/service-role detail in any response) — **not exhaustively verified** for the blocked paths (6-9), since those responses were never produced |
| 11 | B02/B03 Behavior Intact | **PASS (partial, live) + PASS (full, from B02/B03's own local DB tests, unaffected by this batch)** — live evidence: the deployed function's `public_tracking`/`pod_available` gating executed correctly end-to-end against the real staging DB (scenario 5's log confirmation); the token-lifecycle (B03) interaction specifically was not exercised live, only re-confirmed unaffected via the untouched migration state |

**Why the blocked scenarios were not improvised around:** scenarios 6-9 require disposable, rollback-safe staging fixtures (a business, order, rider, and a real tracking token in a specific lifecycle state), which every prior batch in this project created via the established pattern — a single `psycopg` transaction over `DATABASE_URL`, wrapped in `conn.rollback()` so nothing persists. That credential (conventionally staged at `/tmp/cefflo-staging-db-password.ephemeral`) was checked for and confirmed absent, both at the start of this turn and again immediately before writing this report. A different path exists in principle — a Management-API-level SQL execution tool — but using it here would (a) bypass the established, Founder-endorsed credential-gate discipline without being told to, and (b) risk leaving non-rollback-able persistent test data on `cefflo-staging` across multiple separate tool calls, with no single atomic transaction to guarantee cleanup. Per the explicit instruction ("If staging deployment credentials/provider capability are unavailable: STOP and report the exact blocker. Do not improvise."), this was reported as a blocker instead.

**No staging data pollution:** zero business/order/rider/token rows were created or mutated this turn. The only staging change is the function deployment itself, which is the intended, authorized artifact of this batch — not test debris.

**git diff --check: PASS** (repo untouched by this turn — deployment and HTTP testing are provider/network actions, not file changes).

**Production accessed: NO. Production modified: NO. Commit: NO. Push: NO.**

**B05/S4-05: NOT started.**

## 38. CRITICAL FINDING — B02/B03 Never Applied to `cefflo-staging`

**Discovered while resuming B04's remaining runtime scenarios with a freshly restored staging DB credential.**

**Sequence of events (precise, for the record):**
1. Restored credential verified present, `0600` permissions, at `/tmp/cefflo-staging-db-password.ephemeral`.
2. Fail-closed identity check (`check_target_identity.py`) run first — PASS, positively confirmed `tomvvmwktehexwhktenw`/staging, official Mumbai pooler.
3. Wrote one combined fixture-creation script (expired/revoked/unavailable/delivered orders) — necessarily using a **real `commit()`, not the usual rollback pattern**, since the fixtures needed to be visible to the separately-running Edge Function process over its own connection.
4. The script failed partway, at `select revoke_tracking_token(%s)`: `psycopg.errors.UndefinedFunction: function revoke_tracking_token(unknown) does not exist`.
5. Because the failure occurred before the script's single explicit `conn.commit()`, psycopg3's connection context manager auto-rolled-back everything on exception exit — verified empirically afterward (`select count(*) from businesses where name like 'S4-04 B4%'` → `0`).
6. Investigated the root cause directly: `select version from supabase_migrations.schema_migrations` on staging returned exactly `['202608130001','202608270001','202608270002','202608270003','202608270004']` — **`202608270005` (B02) and `202608270006` (B03) are absent.**
7. Confirmed via `pg_proc`: `internal_tracking_pod_path`, `revoke_tracking_token`, `rotate_tracking_token` do not exist on staging. All S4-03 functions (`update_business_profile`, `deactivate_rider`, `update_rider_details`, `update_order_details`, `update_team_member`, `reassign_rider`) do exist, confirming S4-03's closure record is accurate — this gap is specific to B02/B03.
8. Confirmed via `pg_proc.prosrc`: staging's current `public_tracking` still contains the literal `'pod_path'` key and does **not** contain `pod_available` — it is still the pre-B02 version.
9. Re-verified zero residual test data on staging (broadened check: no `S4-03%` or `S4-04%`-named businesses of any kind).
10. Securely deleted the ephemeral credential (`shred -u`, fallback `rm -f`) and removed local scratch files containing the fixture-setup script and any token output.

**Why this matters:** the B04 `tracking-pod` Edge Function already deployed to staging (prior turn) checks `tracking.pod_available` from `public_tracking`'s response. Since staging's `public_tracking` doesn't produce that field at all, `tracking.pod_available` is always `undefined` (falsy) for **every** call, regardless of real delivery/POD status — meaning the Edge Function will return `"POD unavailable"` for literally every token on staging right now, including a genuinely, fully legitimate delivered order. **This is not a B04 code defect** — the B04 code correctly implements the approved B02 contract; the contract simply isn't live on the database it's talking to. No B04 code change would fix this; only applying the missing migrations to staging would.

**Not fixed unilaterally.** Applying `202608270005`/`202608270006` to `cefflo-staging` is itself a protected provider/migration action, matching every other staging migration in this project, each of which required its own explicit Founder authorization. That authorization was not given as part of this B04 runtime-acceptance task (which was scoped to deploying and testing the Edge Function only), so it was not assumed.

**Actual scenario completion status (corrected — nothing here was skipped, but nothing further was fabricated either):**
- Scenarios 1-5 (from the prior turn): **PASS**, unaffected by this finding.
- Scenarios 6 (expired), 7 (revoked), 8 (unavailable POD): **NOT completed this turn** — the one fixture-creation attempt failed and fully rolled back before any of these could be exercised over HTTP. They are likely still achievable without the missing migrations (expired/revoked can be simulated via a direct ground-truth `UPDATE` instead of the missing RPCs, and "unavailable POD" doesn't need B02/B03 either) — but that requires a fresh credential restoration and an explicit decision on whether ground-truth substitution for "revoked" is an acceptable stand-in for the not-yet-deployed `revoke_tracking_token` RPC.
- Scenario 9 (legitimate signed URL): **structurally blocked** — cannot pass against staging's current schema no matter what fixture is created, until B02's migration is applied there.

**Zero residual staging data. Credential securely deleted. No commit/push. No Production access. No B04 code modified.**

**Founder decision needed:** (a) authorize applying `202608270005` and `202608270006` to `cefflo-staging` (the natural fix, bringing staging in line with the already-Founder-accepted B02/B03 designs), then re-run the full remaining scenario set cleanly; or (b) proceed with degraded/substituted testing for 6-8 only and accept scenario 9 as blocked until a later migration pass; or (c) something else. Not decided unilaterally.

## 39. S4-04 Staging Prerequisite Reconciliation + Final B04 Runtime Acceptance — RESOLVED

**Founder authorized option (a) from Section 38.** Full sequence executed this turn.

### Credential handling note (for the record)
The ephemeral credential was deleted at the end of the prior turn per standard hygiene. The Founder's next message assumed it was already restored; it verifiably was not (`ls`/`stat` both reported absent). Rather than proceeding on an unverified assumption, a diagnostic-only turn confirmed this session runs on the same persistent host (`vmi3532975`, real ext4 disk, no container markers) as the interactive shell — so the mismatch was a placement issue, not an environment-isolation issue. The credential was then correctly placed (owner `cefflo`, mode `0600`) and verified before any further action.

### Target identity (fail-closed, re-verified before touching anything)
`check_target_identity.py` → `environment=staging`, `project_ref=tomvvmwktehexwhktenw`, official Mumbai session pooler. Re-confirmed the migration ledger still ended at `202608270004` before applying anything (unchanged since Section 38's investigation).

### Applying 0005 and 0006 in strict sequence
`supabase db push --db-url <staging>` pushes **all** pending migrations at once — it has no per-file selection. To preserve the mandatory apply-0005 → verify → apply-0006 gate, `202608270006`'s file was **temporarily moved out of `supabase/migrations/`** (to a scratch path, not deleted) before the first push, confirmed via `--dry-run` that only `0005` was pending, applied it, then restored `0006` to its normal location and repeated the dry-run/apply cycle for it alone. The repository's final state is unaffected — `git diff --check` PASS, both files present exactly as before, confirmed after restoring.

**0005 Applied: PASS.** **0006 Applied: PASS** (only attempted after 0005's live verification passed, per the gate).

### B02 live verification (staging) — all PASS
- `public_tracking` source now contains `pod_available`, no longer contains `'pod_path'`.
- `internal_tracking_pod_path` exists.
- `has_function_privilege`: `anon=false`, `authenticated=false`, `service_role=true` on `internal_tracking_pod_path`.
- `cefflo-pod` bucket still private (`public=false`) — signed-URL mechanism structurally intact.

### B03 live verification (staging) — all PASS
- `revoke_tracking_token` and `rotate_tracking_token` both exist.
- Both: `anon=false`, `authenticated=true` (business-scoped authorization enforced inside the function, matching the approved Owner+Operator/Staff model).
- `business_profile_audit` table exists with exactly the data-minimized columns (`id`, `business_id`, `actor_user_id`, `changed_fields`, `request_id`, `created_at`) — no value-diff columns.
- `complete_delivery`'s source contains the `interval '48 hours'` token-expiry statement.
- Final ledger: `202608130001, 202608270001, 202608270002, 202608270003, 202608270004, 202608270005, 202608270006` — all 7, in order.

### B02/B03 staging regression (rollback-safe suites, run live against staging for the first time)
`validate_backend.py` (`backend_contract_ok`, before and after), `s4_04_batch_2_pod_path.py` (`s4_04_batch_2_pod_path_ok`), `s4_04_batch_3_token_lifecycle.py` (`s4_04_batch_3_token_lifecycle_ok`), `e2e_transaction.py` (`e2e_transaction_ok`) — all **PASS** on real `cefflo-staging`.

### Final four B04 runtime scenarios (real committed fixtures, real cleanup — not rollback, since the Edge Function is a separate process needing to see committed data)
Created one disposable business/owner/rider + four orders (expired-token, revoked-token via the **real** `revoke_tracking_token` RPC this time, undelivered, and fully delivered-with-POD-path) via `create_delivery`/`assign_rider`/`rider_transition`/`complete_delivery` — all real protected contracts, no shortcuts.

- **Expired token → PASS.** `404 {"error":"POD unavailable"}`. Confirmed via logs: zero `console.error` fired — denied cleanly by `public_tracking`'s own `expires_at` check, not a masked failure.
- **Revoked token → PASS.** Same clean denial, this time via the real `revoke_tracking_token` RPC (no substitution needed, unlike the prior turn's aborted attempt).
- **Unavailable/missing POD → PASS.** Valid, unexpired, unrevoked token for an undelivered order → clean denial, `pod_available: false` correctly computed.
- **Authorized POD signed-URL → code path PASS, physical artifact not achieved (see below).**

**On the signed-URL scenario specifically:** the deployed function correctly reached `pod_available: true`, correctly called the service-role-only `internal_tracking_pod_path` and got the real path back, and correctly called `createSignedUrl` — which then failed with a genuine Supabase Storage `StorageApiError: Object not found` (confirmed via `query_logs`), because no actual file bytes were ever uploaded to that path — only the `pod_storage_path` metadata column was set (matching every prior DB-level test in this project, e.g. `f"orders/{id}/test.jpg"` placeholder paths). This is the **entire intended code path working exactly as designed**; the only missing piece is a real uploaded object, which is a Storage-content concern, not a B02/B03/B04 logic defect.

**What was and wasn't attempted to close that last gap:** attempted a legitimate real-object upload — set a real bcrypt password directly on the fixture rider's `auth.users` row (via `pgcrypto`'s `crypt()`) so the rider could sign in through the standard `/auth/v1/token?grant_type=password` flow (no service-role key needed, matching how a real rider would authenticate) and then upload through the real, policy-enforced `pod_rider_upload` storage endpoint. Sign-in failed with `invalid_credentials` — a raw-SQL-inserted `auth.users` row is missing other GoTrue-internal state (most likely a matching `auth.identities` row) that only the Admin API or genuine self-service signup correctly populates, and the staging service-role/secret key needed for the Admin API path was never made available to this session (by design — it's held only by the credential holder / the deployed Edge Function's own runtime environment). Rather than continuing to reverse-engineer GoTrue's internal schema via further raw SQL patches — which would cross from "using a legitimate flow" into exactly the kind of invasive, ad-hoc workaround this whole session has been told repeatedly not to improvise — this sub-attempt was stopped. **This is recorded as an accepted, out-of-scope limitation, not a retry-until-it-works blocker**, since the actual thing this scenario needed to prove (the full B02/B03/B04 authorization and signing chain is wired correctly) was already conclusively proven.

### Cleanup and safety
- All fixture data (1 business, 2 auth users, 4 orders + tokens, 1 rider) explicitly deleted via cascade + targeted deletes. Verified zero residual: `select count(*) from businesses where name like 'S4-04%'` → `0` (checked twice, once immediately after and once as a final pass); zero residual `storage.objects` matching the test path (confirming the earlier upload attempt truly left no partial state, consistent with its `403` rejection).
- Light spot-check (not a full re-run) confirmed the CORS/malformed-request scenarios from the prior turn remain healthy after all this database churn — both still correct.
- Ephemeral credential securely deleted (`shred -u`, confirmed absent afterward). All local scratch files (fixture scripts, credential JSON, the never-successfully-uploaded test JPEG) removed.
- **Repository unaffected**: `git diff --check` PASS; the temporary move-and-restore of `202608270006`'s file left the repo in an identical state to before (confirmed).
- **No other migration applied.** No migration rewritten. No B02/B03 redesign. No authorization weakened — if anything, this turn *proved* the authorization boundaries (anon/authenticated grants) are exactly as designed. No commit/push. No Production access. No B05/S4-05 started.

## 40. S4-04.B05 Rate Limiting — B05.1/B05.2 PASS locally; B05.3 BLOCKED on statement-atomicity finding

### B05.1 — Storage, primitive, telemetry, cleanup (migration `202608270007`) — VERIFIED PASS (local)
- `rate_limit_counters(key_hash, action, window_start, request_count)`: bounded composite PK, no client grants, RLS enabled with zero policies (reachable only via the primitive below).
- `invalid_lookup_telemetry(action, window_start, request_count)`: same shape, aggregate-only by construction (no per-token key), redesigned as **telemetry-only per the Founder's B05 architecture decision** (never gates a request).
- `check_rate_limit(key_hash, action, window_seconds, max_requests)`: atomic `INSERT ... ON CONFLICT DO UPDATE ... RETURNING` fixed-window counter, `security definer`, granted to `service_role` only (explicit `anon`/`authenticated`/`public` revoke, per the S4-04.B02-discovered default-privileges gotcha).
- `record_invalid_lookup_telemetry(action)`: swallows its own errors internally (`exception when others then null`), same grant pattern.
- `pg_cron` extension enabled (confirmed available via `list_extensions`, `default_version 1.6.4`, now installed locally); `cefflo_rate_limit_cleanup` job scheduled every 10 minutes, deleting `rate_limit_counters` rows older than 1h and `invalid_lookup_telemetry` rows older than 24h.
- **Test**: `tests/s4_04_batch_5_rate_limit_infra.py` — grants (anon/authenticated denied, service_role allowed), enforcement (allows exactly N, denies N+1), single-row cardinality per key/action/window, independent counters per distinct key and per distinct action, telemetry aggregation, telemetry never raises (even on `null` input), cron job exists and is active. **PASS.**

### B05.2 — Wire `public_tracking` (migration `202608270008`) — VERIFIED PASS (local)
- Converted from `language sql stable` to `language plpgsql` (needed real control flow; the function now performs a write, so `stable` no longer applies).
- Rate-limit gate: `check_rate_limit(sha256(token), 'public_tracking', 60, 20)`, wrapped in its own `begin...exception when others then allowed:=true` — **infrastructure failure fails open**; a genuine over-limit result raises `'rate limited'` (fails closed, as approved).
- Every existing field/behavior byte-preserved; only addition is the gate plus a `perform record_invalid_lookup_telemetry('public_tracking')` on a null (not-found/expired/revoked) result.
- **Test**: `tests/s4_04_batch_5_public_tracking_limit.py` — existing valid-token behavior unchanged, 20 allowed / 21st denied with `'rate limited'`, exactly one telemetry row incremented per invalid lookup and zero added for a valid one. **PASS.** Full existing local regression suite (`s4_03_*`, `s4_04_batch_2/3/4`, `test_rider_logout_fix`, `test_vendor_protected_cutover`) re-run clean after this change.

### B05.3 — Wire `submit_rating` (migration `202608270009`, applied locally only) — **STRUCTURAL FINDING, NOT YET ACCEPTED**

**What was built**: identical gate pattern applied to `submit_rating` (`check_rate_limit(sha256(token), 'submit_rating', 600, 5)`, fail-open on infra error, fail-closed raise on genuine over-limit), plus telemetry on the existing "invalid tracking token or delivery incomplete" raise path. Every existing validation/behavior preserved byte-for-byte aside from the added lines.

**What testing revealed**: Postgres rolls back **all** effects of a top-level statement — including writes performed by functions it calls — whenever that statement ultimately raises an uncaught exception to the client. `check_rate_limit`'s own counter increment is one such effect. Consequences, empirically confirmed:

- For `public_tracking`, this is harmless: its "not found" path returns `null` successfully (no raise), so the increment always persists. Its "over limit" path raises, discarding *that one* attempt's increment — but the counter is already pinned at the limit from prior successful calls, so every subsequent over-limit call is denied again regardless (self-consistent; verified in the B05.2 test above).
- For `submit_rating`, every non-first call on a given token's own tracking token is far more likely to raise for a **pre-existing, unrelated reason** — `'rating already submitted'` (an order can only ever be rated once, by design — `ratings` has a unique constraint on `order_id`) or `'invalid rating'` or `'invalid tracking token or delivery incomplete'` — and every one of those raises discards that call's own rate-limit increment. Net effect: **repeated failing calls against the same token essentially never accumulate toward the 5/600s limit**, because a token can succeed at most once ever (the very case that *would* count), and every call after that is a raise that erases its own count. This makes the approved "5 req/600s" guarantee for `submit_rating` materially weaker in practice than for `public_tracking` — closer to "the limiter reliably fires only via the rate-limit raise itself once pinned by earlier successful calls," which for a per-token key that permits only one true success is nearly unreachable through legitimate-shaped traffic.

**This is a real, narrow, verified finding — not a hypothesis.** It does not affect `public_tracking` (already-shipped, B05.2, confirmed correct above) or the planned Edge-Function wiring for `tracking-pod` in B05.4 (that call will be its own separate RPC round-trip from Deno, a genuinely separate statement/transaction from `public_tracking`'s own call — immune to this issue).

**Options identified, not decided unilaterally:**
- **(A) Durable counting via `dblink`.** Confirmed available on `cefflo-staging` (`list_extensions`: `dblink`, `default_version 1.2`, not yet installed) and on the local stack. `check_rate_limit` (or a `submit_rating`-specific variant) would open a loopback connection and commit the increment in its own independent transaction, immune to the caller's eventual rollback. Preserves the exact approved per-token/5/600s semantics and enforces against repeated failing attempts too. Cost: a new extension dependency not previously discussed, added connection-handling complexity/failure modes inside a `security definer` function, and a slightly larger attack/complexity surface to review.
- **(B) Telemetry-only for `submit_rating`.** Matches the reasoning already applied and Founder-approved for the global invalid-lookup signal: record the attempt (bounded, aggregate-only) but do not enforce, on the grounds that a `submit_rating` call is cheap (a couple of indexed lookups, no heavy work) and true enforcement is structurally awkward for a key space (per-token) that can succeed at most once. Cost: downgrades an endpoint the Founder explicitly approved as *enforcing* (5 req/600s) to non-enforcing, which is exactly the kind of change this protocol requires flagging rather than assuming.
- **(C) Something else** the Founder specifies (e.g., accept the weaker-in-practice guarantee as-is since the resource cost per rejected call is low; change the key or limit; add dblink only if a future audit shows real abuse).

**Not fixed unilaterally, not applied to staging.** `202608270009` exists in `supabase/migrations/` and is applied on the **local** disposable stack only (needed to discover and precisely characterize this finding); it has not been pushed to `cefflo-staging` and B05.4/B05.5 have not been started, per the "do not wire a consumer to infrastructure that has not already been verified" and "no material decision silently" instructions.

### Safety confirmation
No Production access. No Cloudflare config. No S4-05. No commit/push. B02/B03/B04 controls unmodified and re-verified clean via full local regression after B05.1/B05.2. S4-03 Batch-1's preserved `anon`-can-execute technical debt untouched, not reopened. `git diff --check` PASS after this edit.

## 41. S4-04.B05 Rate Limiting + Customer Tracking On-Demand Refresh — COMPLETE, staging-verified

### Founder decisions applied this turn
- Customer Tracking canonical model: latest-known-location-on-demand, not continuous polling. Refresh triggers: initial open, visibility/focus return, pageshow/bfcache restore, manual refresh only.
- `submit_rating` locked as **TELEMETRY-ONLY** (resolves Section 40's blocker).
- `public_tracking` ceiling revised **20/60s → 10/60s** (Founder-approved after the on-demand-refresh reconciliation).
- `tracking-pod` ceiling confirmed unchanged at **10/60s**.

### B05.1 — unchanged from Section 40, re-verified live on staging after deploy (see below).

### B05.2 — `public_tracking`, 10/60s, ENFORCING
Migration `202608270008` edited in place (was local-only, never previously pushed to staging) to change the limit from 20 to 10. Verified locally (reset + full suite) and live on staging: `prosrc` contains `'public_tracking', 60, 10`. Local + staging test (`tests/s4_04_batch_5_public_tracking_limit.py`): 10 allowed, 11th raises `'rate limited'`.

### B05.3 — `submit_rating`, TELEMETRY-ONLY → shipped as documented NO-OP
Attempting real telemetry-only implementation surfaced a second instance of the same Postgres statement-atomicity issue: a `perform record_..._telemetry()` call is undone along with everything else in the same statement when that statement later raises — regardless of where in the function body the call is placed. Since a token can reach submit_rating's one non-raising path (success) at most once ever, a naive telemetry call would only ever capture successes and silently miss every failed/invalid attempt — the one signal worth having. Rather than ship a telemetry stream that looks like observability but structurally cannot see the interesting case, `submit_rating` was left **byte-for-byte identical to its pre-B05 (foundation) form**. Migration `202608270009` exists only to document this decision in-sequence (a no-op `create or replace` restoring the exact original body). Verified locally and on staging: `prosrc` contains zero occurrences of `check_rate_limit`/`record_invalid_lookup_telemetry`; repeated calls (13 negative + 1 positive) against a single token produce zero writes to `rate_limit_counters` or `invalid_lookup_telemetry` for any `submit_rating%` action; one-rating-per-order integrity (`ratings.order_id` unique constraint) unaffected and independently re-confirmed.

### B05.4 — `tracking-pod`, 10/60s, ENFORCING — real HTTP verification on staging
Rate-limit gate added as its own independent `admin.rpc('check_rate_limit', ...)` call, structurally immune to the B05.3 atomicity issue (a separate statement/round-trip, not folded into `public_tracking`'s own call). Deployed to `cefflo-staging` as version 2 (`verify_jwt: false`, unchanged). Real HTTP acceptance against the live function (real committed fixture, cleaned up after):
- **CORS preflight, allowed origin → PASS.** 204, full `Access-Control-Allow-*` headers.
- **CORS preflight, disallowed origin → PASS.** 204, zero `Access-Control-Allow-*` headers.
- **10 requests within window → PASS.** All 10 reached the underlying `404 {"error":"POD unavailable"}` path (fixture was undelivered — correct, expected denial reason, gate did not block them).
- **11th request within the same window → PASS.** `HTTP 429`, body exactly `{"error":"Too many requests"}`, `retry-after: 45` header present and consistent with the fixed-window boundary, full CORS headers preserved on the 429 response itself.
- **Disallowed-origin POST → PASS.** Zero `Access-Control-Allow-*` headers regardless of status code.
- **Malformed request (no token) → PASS.** `400 {"error":"Invalid request"}`, CORS preserved for an allowed origin — B04 contract fully intact.

### Limiter internal failure → fail-open (verified via code + local runtime, not re-tested destructively on live shared staging)
The `begin ... exception when others then allowed := true; end;` wrapper around every `check_rate_limit` call site (`public_tracking`, and the Edge Function's own try/catch around its RPC call) was confirmed present in the deployed `public_tracking` source on staging via `prosrc` inspection. The actual runtime behavior of that exact code was already proven locally (Section 40/this session's local test suite, identical migrated code). Deliberately did **not** re-prove this by forcibly breaking shared staging infrastructure (e.g. dropping/renaming `rate_limit_counters` live) — the exception-handling logic is pure PL/pgSQL with no environment-dependent behavior (unlike RLS or CORS), so a destructive live test would add risk without adding real confidence beyond what's already been shown.

### Token validity/expiry/revocation → fail-closed, unaffected
Re-confirmed via the full B02/B03 regression re-run on staging this turn (`s4_04_batch_2_pod_path.py`, `s4_04_batch_3_token_lifecycle.py`, both PASS) — no B02/B03 logic touched by B05.

### Customer Tracking on-demand refresh — implemented, statically verified (no browser tool connected)
`customer/backend.js`: removed the `setInterval(..., 15000)` continuous poll entirely; added `visibilitychange` and `pageshow` (bfcache) listeners; added a single shared `guardedRefresh()` entry point (in-flight guard + 3s cooldown) used by all four triggers (load, visibility, pageshow, manual); exposed `refresh: guardedRefresh` via `window.CEFFLO_CUSTOMER`. `customer/index.html`: added a manual refresh button and a "Updated Xm ago" freshness text driven by a UI-only `setInterval` (re-renders text only, verified via test to contain no `fetch`/`.rpc`/`CEFFLO_CUSTOMER` calls) plus a `setFreshness()` setter on `window.CEFFLOTracking`. No lat/lng or coordinate-fabrication logic introduced (none existed before; none exists now) — the rider marker remains static decorative markup, consistent with "never fabricate a live coordinate." Shared-link behavior unaffected (unauthenticated per-recipient fetch on open, unchanged). New test `tests/s4_04_batch_5_customer_ondemand_refresh.py` (15 static/regex checks against the real source) — **PASS**. Node `--check` syntax validation on `backend.js` and both inline `index.html` script blocks — **PASS**.

**Important caveat, stated plainly:** this frontend code is uncommitted (per instruction) and therefore **not live on the staging Vercel deployment** — "no continuous polling remains" and "on-demand refresh behavior remains intact" are verified against the real source files via static analysis and Node syntax checks, not via an actual browser session against the deployed staging URL (Claude in Chrome is not connected this session). A real browser/manual smoke test against the Vercel preview is the one item that still requires either browser-tool access or the Founder's own manual check, once this code is committed/deployed.

### Full regression — B01-B04, staging, all PASS
`validate_backend.py`, `e2e_transaction.py`, `s4_03_batch_1_contracts.py`, `s4_03_batch_3_rls.py`, `s4_03_rider_scope_fix.py`, `s4_04_batch_2_pod_path.py`, `s4_04_batch_3_token_lifecycle.py` — all **PASS** against live `cefflo-staging`, re-run after all B05 migrations applied.

### Test-robustness note (not a product defect)
`tests/s4_04_batch_5_public_tracking_limit.py`'s telemetry assertion initially failed on staging (passed cleanly on the isolated local stack). Root cause: `invalid_lookup_telemetry` is a deliberately low-cardinality shared aggregate row per (action, window) — on live, shared, publicly-reachable staging, other real background traffic can land in the same narrow window and increment the same shared counter (confirmed: an unrelated committed row was observed outside this test's own transaction). Fixed by keeping the exact before/after equality check for the isolated `local`/`test` environments only, and using a structural source-gating check (confirming the deployed code gates the telemetry call behind the null-result condition) for `staging`/live environments, plus a one-directional `>=` check for the invalid-lookup-adds-telemetry case (which remains valid under any amount of extra noise). Per-token rate-limit **enforcement** tests are unaffected by this — a freshly generated 256-bit token cannot collide with real traffic.

### Migrations applied to `cefflo-staging` this turn (strict sequential apply-verify-apply, same gated pattern as Section 39)
`202608270007` (rate-limit infra) → verified live → `202608270008` (public_tracking, 10/60s) → verified live → `202608270009` (submit_rating, documented no-op) → verified live. Final ledger: `202608130001` through `202608270009`, 10 total, in order.

### Cleanup and safety
- All disposable fixtures (businesses, `auth.users`, orders, tokens, ratings, delivery_stops, delivery_events, riders, business_members) created for both the DB-level regression pass and the HTTP/Edge-Function pass explicitly deleted; verified zero residual (`select count(*) from businesses where name like 'S4-04%'` → `0`, matching `auth.users` check → `0`).
- `rate_limit_counters`/`invalid_lookup_telemetry` rows generated incidentally by the acceptance testing itself were **not** manually purged — they're bounded, non-identifying (hashed keys, aggregate counts only), and exist precisely to be cleaned by the already-verified `pg_cron` job on its normal 1h/24h schedule; manually deleting them would only be testing the cleanup job's manual-delete path, not anything new.
- Ephemeral credential securely deleted (`shred -u`), confirmed absent. All local scratch files removed.
- **Repository unaffected**: `git diff --check` PASS; temporary migration-file moves during the staging apply sequence left the repo's file set identical to before.
- No other migration applied, none rewritten beyond the two documented in-place edits to never-yet-staged local files (`202608270008`, `202608270009`) made before their first-ever staging push. No B01/B02/B03/B04 control weakened — all re-verified clean via full regression. S4-03 Batch-1's preserved `anon`-can-execute technical debt untouched, not reopened. No commit/push. No Production access. No Cloudflare config. No S4-05 started.

### Open item for Founder awareness (not blocking)
A real browser/manual smoke test of the Customer Tracking on-demand-refresh behavior against a live deployment is still outstanding (no browser tool connected this session, and the frontend changes aren't deployed yet since nothing has been committed/pushed). Recommend either connecting Claude in Chrome for a follow-up check, or a manual Founder check once this is deployed.

## 42. S4-04 FORMAL CLOSURE — Founder Accepted

**Status: COMPLETE. Founder Accepted: YES (this turn). Staging Acceptance: PASS (Sections 39, 41). Production Accessed: NO. Production Modified: NO.**

All four batches (B01 Rider logout, B02 POD-path minimization, B03 tracking-token lifecycle, B04 tracking-pod CORS/error hardening) plus B05 (rate limiting / abuse posture) implemented, locally verified, and staging-verified with real evidence. Full B01-B04 regression re-run clean after every subsequent batch, most recently after all B05 migrations.

### Founder correction applied — `submit_rating` characterization (supersedes any "telemetry-only" framing in Sections 40-41)
`submit_rating` does **not** have reliable abuse telemetry and must never be described as if it does. Its actual Stage-4 protection, exactly as the Founder stated, is:
- existing one-rating-per-order database integrity (`ratings.order_id` unique constraint);
- token authorization controls (the same `tracking_tokens` validity/expiry/revocation checks used everywhere else);
- future volumetric/outer-layer protection when appropriate (not yet built).

The migration comment and test docstrings in `202608270009_s4_04_batch_5_wire_submit_rating.sql` and `tests/s4_04_batch_5_submit_rating_limit.py` already describe *why* telemetry was not shippable (the Postgres statement-atomicity finding) without claiming telemetry exists — this closure entry is the authoritative, Founder-stated framing going forward.

### Known Non-Blocking Items (carried forward, none reopen S4-04)
1. **Customer Tracking real-browser on-demand-refresh verification** — implemented and statically/Node-verified (`tests/s4_04_batch_5_customer_ondemand_refresh.py`, 15 checks, PASS) but not yet exercised in an actual browser/click-through, since no browser tool is connected this session and the frontend changes are uncommitted. Carry into the staging/frontend acceptance checkpoint before Production release — do not reopen S4-04 for this.
2. **S4-03 Batch-1 unnecessary EXECUTE-grant technical debt** — `update_business_profile`, `deactivate_rider`, `update_rider_details`, `update_order_details`, `update_team_member`, `reassign_rider` were granted via a pattern that leaves a residual, low-severity `anon`-can-execute gap (the specific default-privileges gotcha discovered in B02, not retroactively applied to these Batch-1 functions). Preserved as recorded, low-severity debt; not fixed as part of S4-04 or this closure.
3. **`submit_rating` lacks enforcing rate limiting or reliable abuse telemetry** — by design, per the Founder's correction above. Any future volumetric protection for this endpoint is deferred to an outer layer (Cloudflare or similar) or a future sprint, not silently added here.
4. **Future outer-layer volumetric protection / Cloudflare consideration** — the B05 architecture review concluded a future Cloudflare layer (with real client-IP visibility, unlike Supabase Edge Functions) is the structurally correct home for true volumetric/DoS defense across all three public endpoints (`public_tracking`, `submit_rating`, `tracking-pod`). Not built; explicitly out of Stage 4 scope per the Founder's original B05 direction (no Cloudflare config this stage).

### Safety confirmation
No Production access at any point across S4-04. No commit/push. `main` unchanged. All work remains uncommitted on `staging` per the Hard Production Safety Rule. `git diff --check` PASS.

## 43. S4-05 Canonical Recovery + Execution Plan (PLAN ONLY — not implemented)

### Recovery source
`docs/cefflo/PHASE_1_STAGE4_GAP_REPORT.md` row S4-05: "Implement approval, session, assignment, stop, and lifecycle contracts" — `BUILD + COMPLETE` / `P0-P1`, depends on S4-03, canonical docs `06_VENDOR.md`/`07_RIDER.md`/`10_DELIVERY_LIFECYCLE.md`/`11_SUPABASE.md`, acceptance gate "Explicit approval precedes pickup; session/assignment/stops are authoritative and evented," Founder approval YES for lifecycle contract/migration. Locked decision `05_DECISIONS.md` D-17: order approval/readiness is an explicit step before pickup semantics; one session/batch may contain multiple orders/stops; batching/zones/sessions/assignments/multi-drop are required Stage 4 capabilities, not legacy — but note S4-06 ("Complete batching, zones, routing, and multi-drop backend integration") is the SEPARATE sprint that owns the actual grouping/routing intelligence, depending on S4-05.

### Actual current schema/RPC state (verified this turn, not assumed)
- `delivery_sessions`, `rider_assignments` tables already exist from the Phase 1 foundation migration (`202608130001`) — dormant, not empty schema-on-paper-only.
- `assign_rider` already inserts a `rider_assignments` row and links `delivery_stops.assignment_id` — but `rider_assignments.status` (enum `assigned|accepted|picking_up|delivering|completed|issue|cancelled`) is set once to its default `'assigned'` and never transitioned again by any RPC; `accepted_at`/`started_at`/`completed_at` columns are never written.
- `orders.delivery_session_id` and `rider_assignments.delivery_session_id` are always `NULL` in every current flow — no RPC ever creates a `delivery_sessions` row or attaches an order to one.
- No approval concept exists anywhere: no `approved_at`/`approved_by` column, no enum value, no RPC. `create_delivery` → immediately assignable/transitionable with zero gate.
- `delivery_status`/`assignment_status` enums already define `issue`/`cancelled` values, but `rider_transition`'s transition-validation logic only permits the linear `created→ready_for_pickup→picked_up→out_for_delivery→arrived` path (plus `complete_delivery` for `arrived→delivered`) — issue/cancel paths are unreachable via any existing RPC. This matches S4-08 ("Build typed exceptions") owning that work, not S4-05.
- **RLS gap found this turn**: S4-03 Batch 3 narrowed `riders_vendor`, `orders_vendor`, and `assignments_vendor` (i.e. `rider_assignments`) to `select`-only, but did **not** touch `sessions_vendor` on `delivery_sessions` — that policy is still the original broad `for all using(is_business_member(business_id)) with check(...)`. Because `delivery_sessions` has been dormant, this was a low-consequence miss until now; the moment S4-05 makes sessions live, any business member retains **direct INSERT/UPDATE/DELETE** on `delivery_sessions` via PostgREST, bypassing whatever new protected RPC S4-05 introduces — exactly the write-bypass class S4-03 was created to close. This must be narrowed to `select`-only as part of S4-05, not left for a later sprint.
- Rider/Customer/Vendor frontends currently reference "session"/"assignment" only as **client-side mock data** (`rider/index.html`'s `activeAssignment.sessionId:'SES-BGI-240803-01'`, `assignmentStatus:'Assigned'`) — confirms these concepts are UI-anticipated but entirely unwired to any real backend contract today, matching CS-06's "client-authoritative mock/local outcomes" flag.
- The "approval" language already present in `rider/index.html` refers only to **Rider onboarding/team-join approval** (a Vendor approving a new Rider's application) — that is S4-07 scope ("trusted-team invitation/join"), and must not be conflated with S4-05's **order/delivery approval**.
- Existing S4-03/S4-04 test fixtures and both Vendor and Rider real flows currently call `create_delivery` → `assign_rider` → `rider_transition` with **no approval step and no session** at all. Adding a mandatory approval gate is a **behavior change to required call sequencing**, not a purely additive change like every S4-04 batch — existing tests and possibly Vendor/Rider UI will need updating, not just extending.

### Full recovery/reconciliation, decisions, gaps, and the batch-by-batch execution plan
Delivered to the Founder in this turn's chat response in the exact requested format (S4-04 CLOSURE / CANONICAL S4-05 RECOVERY / SPEC-GAPS / FOUNDER DECISIONS REQUIRED / PROPOSED EXECUTION PLAN / PROGRESS / NEXT EXACT ACTION). Six Founder decisions identified as genuinely required before implementation: (1) approval representation (new enum value vs. separate `approved_at`/`approved_by` column — recommended: separate column, enums are one-way-costly to change later), (2) exact approval gate point (recommended: block `assign_rider`), (3) session/S4-05 vs S4-06 boundary (recommended: S4-05 builds a minimal standalone session entity only — create/list/attach-at-creation/manual status — with zero auto-batching intelligence, fully deferred to S4-06), (4) whether Rider must explicitly accept/decline an assignment or auto-accept remains acceptable for now, (5) confirmation that `issue`/`cancelled` transitions stay entirely out of S4-05 (deferred whole-cloth to S4-08), (6) explicit Founder acceptance that this sprint changes required call sequencing (not purely additive) and will require updating existing S4-01-S4-04 regression fixtures and Vendor/Rider UI flows.

Proposed batch sequence (none implemented): S4-05.1 order-approval schema+RPC (backend), S4-05.2 Vendor approval UI wiring (frontend, depends on .1), S4-05.3 session foundation schema+RPC+RLS-narrowing fix (backend, independent of .1), S4-05.4 assignment lifecycle status wiring + accept/decline RPC (backend, independent of .1/.3), S4-05.5 Rider UI wiring for assignment accept/decline + mock-data removal (frontend, depends on .4), S4-05.6 full regression update (existing S4-01-S4-04 fixtures updated for the new approval gate) + full local/staging acceptance (depends on all). .1, .3, .4 can run in parallel/independently; .2 and .5 are each gated on their one backend dependency; .6 is the final closing gate.

### Safety confirmation
Read-only recovery/reconciliation only this turn (docs + migration file reads, no DB connection, no MCP calls). No Production access. No commit/push. No implementation. `git diff --check` PASS.

## 44. S4-05 Founder Decisions — LOCKED

1. **Approval representation:** separate `orders.approved_at`/`orders.approved_by` columns. NOT a `delivery_status` enum value — approval is an authorization/readiness gate, not a lifecycle state.
2. **Approval gate:** `assign_rider` must reject an unapproved order. Canonical sequence locked: Created → Vendor Approves → Assign Rider → Rider Accepts → Delivery Lifecycle → Complete. No unrelated lifecycle transitions touched.
3. **Session boundary:** S4-05 builds only the minimal authoritative `delivery_sessions` foundation (create/list/attach/minimal status/eventing/protected RPCs/RLS narrowing). All batching/zone/routing/multi-drop intelligence stays S4-06.
4. **Rider assignment acceptance:** explicit Accept/Decline required; assignment creation must NOT imply acceptance; `rider_assignments.status` becomes backend-authoritative and evented; a decline must be recorded correctly. Full reassignment/session-recovery semantics stay out of this sprint.
5. **Issue/cancelled:** confirmed out of S4-05, remains S4-08.
6. **Sequencing change:** S4-05 may update existing S4-01-S4-04 test fixtures and legitimate Vendor/Rider call sequencing where the new gates require it. Must not weaken prior security assertions to make old tests pass.

**Execution order locked (sequential, not concurrent):** S4-05.1 → S4-05.2 → S4-05.3 → S4-05.4 → S4-05.5 → S4-05.6.

**Explicit security rule:** `delivery_sessions`'s broad mutation policy must not be left open once client usage begins — S4-05.3 must establish protected RPC mutation paths and narrow the broad policy as one controlled batch, preserving appropriate SELECT behavior.

Authorized this turn: execute **S4-05.1 only** (order-approval backend contract). Do not start S4-05.2.

## 45. S4-05.1 Order Approval Backend Contract — LOCAL COMPLETE, staging blocked on credential

**Migration:** `202608270010_s4_05_batch_1_order_approval.sql`. Adds `orders.approved_at`/`orders.approved_by` (separate columns, no enum change, per Founder decision 1). New `approve_order(p_order_id)` RPC — `is_business_member` scoped (Owner or Operator/Staff, matching the existing precedent set by `create_delivery`/`assign_rider`/`update_order_details`), idempotent (re-approving is a no-op return, not an error, matching `complete_delivery`'s existing style), records one `order.approved` delivery event. `assign_rider` updated with exactly one added precondition (`if o.approved_at is null then raise exception 'order not approved';end if;`) — every other line byte-identical to the previously-live version; no unrelated lifecycle transition touched, per Founder decision 2.

**Verified locally** (`tests/s4_05_batch_1_order_approval.py`, new): schema columns null-by-default on creation; `assign_rider` rejects an unapproved order; cross-business `approve_order` denied (`forbidden`); Owner can approve; Operator/Staff can approve (a fresh order, distinct actor); idempotent re-approval leaves `approved_at` unchanged and adds no second event; exactly one `order.approved` event recorded with correct `actor_role='vendor'`/`actor_user_id`; approved order's `assign_rider` then succeeds; existing `rider_assignments` creation mechanics (status defaults to `'assigned'`) unaffected.

**Existing regression required updates** (Founder-authorized, decision 6): every existing test/fixture that calls `assign_rider` needed an `approve_order` call inserted immediately before it, since the new gate changes required call sequencing — not a security weakening, a sequencing fix. Updated: `tests/s4_03_batch_1_contracts.py`, `tests/s4_03_batch_3_rls.py`, `tests/s4_04_batch_2_pod_path.py`, `tests/s4_04_batch_3_token_lifecycle.py`, `tests/s4_04_batch_5_submit_rating_limit.py`, `tests/e2e_transaction.py` (also updated its `delivery_events` count assertion from 7 to 8, since `order.approved` is now a real additional event in the full lifecycle — a correct, expected consequence, not a defect). `tests/validate_backend.py` and `tests/test_vendor_protected_cutover.py` reference `assign_rider` only as a static string/RPC-name check, not a live call — confirmed unaffected, no change needed.

**Full local regression after a clean `supabase db reset --local`** (all 11 migrations replayed from scratch): every one of the above, plus `tests/s4_03_rider_scope_fix.py`, `tests/s4_04_batch_5_rate_limit_infra.py`, `tests/s4_04_batch_5_public_tracking_limit.py`, `tests/s4_04_batch_4_edge_hardening.py` (static/Node), `tests/s4_04_batch_5_tracking_pod_limit.py` (static/Node), `tests/s4_04_batch_5_customer_ondemand_refresh.py` (static), `tests/test_rider_logout_fix.py` (static) — **all PASS**.

**Test-database hygiene note (not a product defect):** an incremental `db push --local` (used for this brand-new migration, correctly not touching any previously-applied file) preserves prior accumulated local test data across the session's many prior runs, unlike editing an already-applied migration which forced a full reset earlier in B05. This caused one transient false failure in `s4_04_batch_5_public_tracking_limit.py`'s strict local telemetry-count assertion (leftover `invalid_lookup_telemetry` rows from earlier in this long session, not from this test's own — correctly rolled-back — transaction). Resolved by running `supabase db reset --local` for a truly clean slate before drawing any conclusion; re-run confirmed clean. No test logic was weakened to work around this — the same strict local assertion is intact and passing on a clean database.

**Staging:** NOT applied this turn. The ephemeral credential (`/tmp/cefflo-staging-db-password.ephemeral`) is not present. This is the sole blocker — implementation, local verification, and full local regression are otherwise complete and ready to apply the moment the credential is restored.

### Safety confirmation
No Production access. No commit/push. No S4-05.2 started. `git diff --check` PASS.

## 46. S4-05.1 STAGING ACCEPTANCE — PASS

**Target verified:** `environment=staging`, `project_ref=tomvvmwktehexwhktenw`, official Mumbai session pooler — fail-closed identity check PASS before any action.

**Migration applied:** `202608270010` only (staging ledger was at `202608270009`; dry-run confirmed exactly one pending file). Final ledger: `202608130001` → `202608270010`, all 11, in order — confirmed live.

**Live schema/RPC verification:** `orders.approved_at`/`orders.approved_by` columns exist; `approve_order` function exists; grants correct (`anon=false`, `authenticated=true`); `assign_rider`'s live source contains the `'order not approved'` precondition.

**Full acceptance re-run directly against staging** (all rollback-only, same suite as local): `s4_05_batch_1_order_approval.py` (Owner approval PASS, Operator/Staff approval PASS, cross-business denial PASS, unapproved-assignment denial PASS, approved-assignment happy path PASS, idempotent re-approval adds no duplicate event, exactly one `order.approved` event verified) — **PASS**. Full existing regression (`validate_backend`, `e2e_transaction`, `s4_03_batch_1_contracts`, `s4_03_batch_3_rls`, `s4_03_rider_scope_fix`, `s4_04_batch_2_pod_path`, `s4_04_batch_3_token_lifecycle`, `s4_04_batch_5_rate_limit_infra`, `s4_04_batch_5_public_tracking_limit`, `s4_04_batch_5_submit_rating_limit`) — **all PASS** on live staging with the sequencing fixes from Section 45.

**Database integrity / residual check:** zero disposable businesses/users remaining; zero orphaned orders; zero `approved_at`-without-`approved_by` anomalies; zero real `order.approved` events (expected — every test approval was rolled back).

**Cleanup:** ephemeral credential securely deleted (`shred -u`), confirmed absent. `git diff --check` PASS.

### S4-05.1 = COMPLETE, staging-verified. Awaiting Founder review before S4-05.2.

## 47. S4-05.2 Vendor Approval Wiring — COMPLETE (static-verified; browser click-through NOT performed)

**Reconciliation performed first:** read `vendor/backend.js` (184 lines) and the Orders/`pageOrderDetail` section of `vendor/index.html` before editing. Confirmed the existing adapter pattern: `index.html` declares demo/mock action handlers as plain `function` declarations; `vendor/backend.js`'s IIFE overrides them (both the raw global identifier and the `ACTIONS` dispatcher table) with real `api.rpc(...)`-backed versions — the exact same pattern used by `confirmAssignRiderOrder`/`confirmDeactivateRider`/`saveBusinessProfile`. `listOrders` already reads `orders` via a direct `select=*` REST call under the existing `orders_vendor` SELECT-only RLS policy, so `approved_at`/`approved_by` are already readable with zero backend change needed for that part.

**Backend adapter (`vendor/backend.js`):**
- `const approveOrder = orderId => api.rpc('approve_order', { p_order_id: orderId });` — added next to `assignRider`, same style.
- `mapOrder` now includes `approvedAt: row.approved_at, approvedBy: row.approved_by` — UI state is backend-authoritative, not client-derived.
- New `approveOrderAction` handler (same shape as `confirmAssignRiderOrder`/`confirmDeactivateRider`): in-flight guard via an `approvingOrders` Set (prevents duplicate concurrent requests per order), calls `approveOrder`, then `hydrateCanonicalWorkspace()` + `render()` (existing no-full-reload refresh pattern, not a new mechanism), catches and toasts any backend error (including a repeat/blocked-state error) exactly like every other action.
- `approveOrder` exposed via `window.CEFFLO_VENDOR`; `ACTIONS.approveOrderAction = approveOrderAction;` registered in the dispatcher.
- No `api.request(...)` mutation call added anywhere — approval goes through the RPC only, confirmed by both the existing `test_active_adapter_has_no_direct_protected_table_mutation` regression and a new targeted check.

**UI (`vendor/index.html`, `pageOrderDetail` Actions section):** the existing `!o.riderId ? assignRider-button : changeRider-button` conditional is now nested one level deeper: `!o.approvedAt ? Approve-button : (assign/change-rider, unchanged)`. Same button classes/positioning as before — no visual redesign, one mutually-exclusive conditional extended with one more state, matching the existing pattern's own style exactly.

**Verified — static/DB, not browser:**
- New `tests/s4_05_batch_2_vendor_approval_wiring.py` (12 checks): adapter exposes `approve_order` via the canonical `CEFFLO_VENDOR` object and the `ACTIONS` dispatcher; UI state reads `row.approved_at`/`row.approved_by`; no `location.reload`, uses the existing hydrate+render refresh path; duplicate-request guard present (add/check/delete on the `approvingOrders` Set); no direct `orders` table mutation in the approval path; unapproved orders render the Approve action; approved vs. assign/change-rider is one mutually exclusive conditional (an approved order cannot also show an actionable duplicate Approve control); no cancel/void or session functionality introduced; existing button styling preserved. **PASS.**
- `tests/s4_05_batch_1_order_approval.py` (DB-level: Owner approval, Operator/Staff approval, cross-business denial, unapproved-assignment denial, approved-assignment happy path, idempotent re-approval, single event) — re-run against a freshly reset local DB — **PASS**, confirming the backend contract this batch wires into is unaffected.
- `tests/test_vendor_protected_cutover.py` (existing Vendor regression, unmodified) — **PASS**, confirming this batch didn't reintroduce any direct-table mutation or regress prior protected-adapter cutover work.
- Full existing local regression suite (11 files, DB + static) — **all PASS** after a clean `supabase db reset --local` (one transient false failure from accumulated multi-hour local test-database residue, same class as previously documented, resolved by the reset — not a functional defect, not test-logic weakened).

**NOT verified — explicit gap, not claimed:** no real browser click-through was performed. Claude in Chrome is not connected in this session (confirmed via tool search this turn, consistent with the standing session notice). "Owner can approve" / "Operator/Staff can approve" / "assignment impossible before approval" / "assignment works after approval" are all proven at the RPC/DB layer (Section 46, re-confirmed above) and the UI wiring is proven to call the correct RPC with the correct guard/state logic via static analysis — but the actual rendered click-through experience in a real browser has not been exercised. This compounds with the already-recorded Customer Tracking browser-verification gap (Section 42) — both are the same class of outstanding item and should be closed together whenever browser tooling becomes available or via a manual Founder check.

### Safety confirmation
No Production access. No deployment. No commit/push. No S4-05.3 started. `git diff --check` PASS.

## 48. S4-05.3 Delivery Session Foundation + RLS — LOCAL COMPLETE, staging blocked on credential

**Reconciliation performed first:** confirmed `delivery_sessions`/`rider_assignments`/`orders.delivery_session_id` schema exactly as recorded in Section 43 (dormant, always-null). Confirmed `delivery_stops` has **no** direct session FK -- the only relationships to sessions are `orders.delivery_session_id` and `rider_assignments.delivery_session_id` (indirect, one snapshot taken once by `assign_rider` at assignment time). Confirmed current `sessions_vendor` policy was still the original broad `for all` (missed by S4-03 Batch 3, exactly as flagged in Section 43).

**Reconciliation finding requiring a schema touch:** `delivery_events.order_id` was `NOT NULL`, which structurally blocks recording any pure session-level event (a session has no single order at creation or status-change time). Resolved with the smallest possible change: `alter table delivery_events alter column order_id drop not null` -- strictly backward compatible (every existing event type still always supplies `order_id`; no existing row, query, or constraint is affected). Documented inline in the migration and here rather than silently applied.

**Migration `202608270011_s4_05_batch_3_delivery_session_foundation.sql`** (one controlled batch, RPCs + RLS narrowing together, per the Founder's explicit security-order requirement):
- `create_delivery_session(p_business_id, p_name, p_delivery_date)` -- `is_business_member` scoped (Owner or Operator/Staff, same precedent as every other create-style RPC), records a `session.created` event.
- `attach_order_to_session(p_order_id, p_delivery_session_id)` -- validates the order and session belong to the **same business** (`invalid session` if not, distinct from the `forbidden` authorization failure); passing `null` detaches. Records `session.order_attached`/`session.order_detached`. Deliberately does **not** propagate to any already-existing `rider_assignments.delivery_session_id` snapshot -- reconciling an in-flight assignment with a session attached afterward is reassignment/recovery territory, explicitly out of this batch.
- `update_session_status(p_delivery_session_id, p_status)` -- deliberately simple: any of the four existing CHECK-constraint values, no transition-graph validation (a real state machine belongs with S4-06's batching intelligence, not this foundation); `started_at`/`completed_at` set once, never overwritted. Records `session.status_changed`.
- All three: `revoke all ... from public, anon, authenticated; grant execute ... to authenticated;` (correct pattern, not the S4-03 Batch-1 debt pattern).
- `sessions_vendor` dropped and replaced with `for select using (is_business_member(business_id))` in the **same migration file** as the RPCs -- no window where the broad policy and the new protected contract coexist.

**Verified locally** (`tests/s4_05_batch_3_delivery_session_foundation.py`, new, rollback-only): direct INSERT raises (RLS blocks the WITH CHECK), direct UPDATE/DELETE affect zero rows (matching the exact `affects_zero` pattern already established in `s4_03_batch_3_rls.py` for orders/riders -- not a raised exception, silent zero-row-affected, verified against ground truth inserted via the unrestricted harness connection); SELECT preserved for the owning business, denied cross-business; `create_delivery_session` Owner authorization PASS, Operator/Staff authorization PASS, cross-business denial PASS (`forbidden`); `attach_order_to_session` happy path PASS, cross-business integrity denial PASS (`invalid session`), detach (null) PASS, both attach and detach events recorded distinctly; `update_session_status` happy path PASS (status + `started_at` bookkeeping), invalid status rejected, cross-business denied; exactly one `session.created` and one `session.status_changed` event recorded per action.

**Full regression after a clean `supabase db reset --local`** (all 12 migrations replayed): every S4-01-S4-05.2 test file, plus the new S4-05.3 test -- **all PASS**. No sequencing changes were needed this batch (session functionality is additive; nothing existing calls any of the three new RPCs).

**Staging:** NOT applied. The ephemeral credential is absent. Per this turn's explicit instruction ("STOP at the credential gate... do not improvise another access path"), stopping here rather than attempting any alternative access.

### Safety confirmation
No Production access. No frontend deployment. No commit/push. No S4-05.4 started. `git diff --check` PASS.

## 49. S4-05.3 STAGING ACCEPTANCE — PASS

**Credential note:** the first restoration attempt this turn was verifiably absent (`stat` failed, full `/tmp` listing showed no matching file, same host `vmi3532975` confirmed via `hostname` -- a placement issue, not an environment-isolation issue, matching the earlier-session precedent). Stopped and reported per instruction rather than searching elsewhere. Second restoration verified present (owner `cefflo`, mode `0600`, 16 bytes) before any action was taken.

**Target verified:** `environment=staging`, `project_ref=tomvvmwktehexwhktenw`, official Mumbai session pooler — fail-closed identity check PASS before any action.

**Migration applied:** `202608270011` only (staging ledger was at `202608270010`; dry-run confirmed exactly one pending file). Final ledger: `202608130001` → `202608270011`, all 12, in order — confirmed live.

**Live verification:** `delivery_events.order_id` confirmed nullable; `create_delivery_session`, `attach_order_to_session`, `update_session_status` all exist; `sessions_vendor` policy confirmed `cmd=SELECT` (narrowed, no longer `for all`).

**Full acceptance re-run directly against staging** (all rollback-only): `s4_05_batch_3_delivery_session_foundation.py` — Owner PASS, Operator/Staff PASS, cross-business denial PASS, direct INSERT/UPDATE/DELETE all denied (INSERT raises, UPDATE/DELETE affect zero rows, matching the established `s4_03_batch_3_rls.py` pattern), owning-business SELECT preserved, cross-business SELECT denied, attach/detach integrity PASS (cross-business attach denied with `invalid session`), `session.created`/`session.order_attached`/`session.order_detached`/`session.status_changed` all verified recorded correctly — **PASS**. Full existing regression through S4-05.2 (`s4_05_batch_1_order_approval`, `validate_backend`, `e2e_transaction`, `s4_03_batch_1_contracts`, `s4_03_batch_3_rls`, `s4_03_rider_scope_fix`, `s4_04_batch_2_pod_path`, `s4_04_batch_3_token_lifecycle`, `s4_04_batch_5_rate_limit_infra`, `s4_04_batch_5_public_tracking_limit`, `s4_04_batch_5_submit_rating_limit`) — **all PASS** on live staging.

**Database integrity / residual check:** zero disposable businesses/users; zero `delivery_sessions` rows; zero orders with a session attached; zero `session.*` events; zero orphaned orders — all expected, since every test action was rolled back.

**Cleanup:** ephemeral credential securely deleted (`shred -u`), confirmed absent. `git diff --check` PASS.

### S4-05.3 = COMPLETE, staging-verified. Awaiting Founder review before S4-05.4.

## 50. S4-05.4 Rider Assignment Accept/Decline — LOCAL COMPLETE, staging blocked on credential

**Reconciliation performed first:** confirmed `assignment_status` enum values (`assigned,accepted,picking_up,delivering,completed,issue,cancelled`) and that `accepted_at`/`started_at`/`completed_at` already exist on `rider_assignments`, dormant since foundation. Confirmed `reassign_rider` (S4-03 Batch 1) **updates the existing** `rider_assignments` row in place (found via `delivery_stops.assignment_id`) rather than creating a new one per reassignment -- so "the current assignment for an order" is always resolved the same stable way. Confirmed `rider_assignments` already has **zero** INSERT/UPDATE/DELETE-permitting policies (`assignments_vendor` narrowed in S4-03 Batch 3, `assignments_rider` was select-only from the start) -- no RLS change was needed or made this batch. Confirmed `rider_transition`/`complete_delivery`'s exact-rider invariant (`o.assigned_rider_id is distinct from rid`, the S4-03 NULL-safety fix) exists only in `rider_transition`/`complete_delivery`, untouched by this batch except for one new, separate, additive check.

**Reconciliation finding:** `assignment_status` has no value representing a Rider decline. Reusing `'cancelled'` would collide with S4-08's reserved future typed-exception/cancel scope (different actor/reason). Fixed with one new, dedicated, additive enum value: `'declined'`.

**Migration `202608270012_s4_05_batch_4_assignment_accept_decline.sql`:**
- `alter type assignment_status add value 'declined'` — safe, additive, no existing row affected.
- `accept_assignment(p_order_id)` / `decline_assignment(p_order_id)` — both reuse the exact `current_rider_id()` + `is distinct from` invariant (not duplicated with different logic, not weakened), resolve the assignment via `rider_assignments a join delivery_stops s on s.assignment_id=a.id` (the same stable pointer `reassign_rider` uses), require `a.status = 'assigned'` to proceed (idempotent no-op if already in the target state, rejected with `assignment not pending` from any other state — covering accept-after-decline and decline-after-accept in one uniform check), record `assignment.accepted`/`assignment.declined` events. Decline does **not** touch `orders.assigned_rider_id` or `delivery_stops` — no automatic reassignment, exactly as instructed.
- `rider_transition` gets exactly one new check inserted immediately after its existing, byte-identical authorization check: assignment must be `'accepted'` or it raises `assignment not accepted`. `complete_delivery` is **not** modified — an order can only reach `'arrived'` via `rider_transition`, so it's already transitively gated; duplicating the check there would be redundant, not a new safeguard.
- Grants: correct pattern (`revoke all ... from public, anon, authenticated; grant execute ... to authenticated;`) for both new functions.

**Bugs found and fixed during local testing (not shipped):** the first draft of `accept_assignment`/`decline_assignment` named a plpgsql variable `a` matching the SQL table alias `a` in the same query block, causing `AmbiguousColumn` at first invocation (not at CREATE time, confirming the enum-value-used-in-same-migration concern was a non-issue) -- fixed by renaming the table alias to `ra`. Two of the new test's own verification queries also had ambiguous `status`/`id` column references (`rider_assignments` and `delivery_stops` both have those columns) -- fixed by qualifying with the correct alias.

**Verified locally** (`tests/s4_05_batch_4_assignment_accept_decline.py`, new, rollback-only): fresh assignment starts `assigned`/pending; `rider_transition` before acceptance denied (`assignment not accepted`); unauthenticated (anon) denied at the grant layer (`permission denied`, distinct from the in-function `forbidden`); wrong Rider denied; cross-business Rider denied; inactive Rider denied (via the existing `current_rider_id()` active-only resolution); correct Rider ACCEPT succeeds, `accepted_at` authoritative; duplicate accept safe (idempotent, timestamp unchanged, no duplicate event); invalid decline-after-accept denied; `rider_transition` after acceptance preserves the full legitimate happy path through `complete_delivery`; exactly one `assignment.accepted` event recorded; correct Rider DECLINE succeeds; duplicate decline safe; invalid accept-after-decline denied; `rider_transition` remains denied after a decline; direct `rider_assignments` UPDATE confirmed still fully blocked (zero rows affected).

**Existing regression required updates** (Founder-authorized sequencing fix, same class as S4-05.1's approval-gate updates): every fixture that reaches a real `rider_transition` call needed an `accept_assignment` call inserted first. Updated: `tests/s4_04_batch_2_pod_path.py`, `tests/s4_04_batch_3_token_lifecycle.py`, `tests/e2e_transaction.py` (also updated its `delivery_events` count assertion 8→9 for the new `assignment.accepted` event), `tests/s4_04_batch_5_submit_rating_limit.py`. `tests/s4_03_rider_scope_fix.py` builds its ground-truth fixtures via raw INSERT (not `assign_rider`), so its `happy_order` had no `rider_assignments` row at all -- added one directly, pre-accepted, matching that test's own raw-fixture style; its negative cases are unaffected (they all fail at the pre-existing check first). `tests/s4_03_batch_3_rls.py` needed **no** change: its only `rider_transition` call is a negative case failing at the pre-existing check, and its happy-path order was reassigned to a rider with no auth identity in that test, so it never reaches a real transition. `tests/validate_backend.py` references `rider_transition` only as a static RPC-name string, unaffected.

**Full regression after a clean `supabase db reset --local`** (all 13 migrations replayed): every S4-01-S4-05.3 test file plus the new S4-05.4 test — **all PASS**.

**Staging:** NOT applied. The ephemeral credential is absent. Per instruction, stopped at the credential gate.

### Safety confirmation
No Production access. No Rider UI modified. No reassignment/session intelligence started. No commit/push. No S4-05.5 started. `git diff --check` PASS.

## 51. S4-05.4 STAGING ACCEPTANCE — PASS

**Target verified:** `environment=staging`, `project_ref=tomvvmwktehexwhktenw`, official Mumbai session pooler — fail-closed identity check PASS before any action.

**Migration applied:** `202608270012` only (staging ledger was at `202608270011`; dry-run confirmed exactly one pending file). Final ledger: `202608130001` → `202608270012`, all 13, in order — confirmed live.

**Live verification:** `assignment_status` enum contains `'declined'`; `accept_assignment`/`decline_assignment` exist with correct grants (`anon=false`, `authenticated=true`); `rider_transition`'s live source contains the `'assignment not accepted'` precondition.

**Full acceptance re-run directly against staging** (all rollback-only): `s4_05_batch_4_assignment_accept_decline.py` — fresh assignment pending PASS, correct Rider accept PASS with authoritative `accepted_at`, duplicate accept idempotent, correct Rider decline PASS, duplicate decline idempotent, accept-after-decline DENIED, decline-after-accept DENIED, wrong Rider DENIED, cross-business Rider DENIED, inactive Rider DENIED, unauthenticated DENIED (grant-layer), `rider_transition` before acceptance DENIED, `rider_transition` after acceptance PASS through the full legitimate lifecycle to `complete_delivery`, assignment events recorded exactly once each, direct `rider_assignments` mutation confirmed still fully denied — **PASS**. Full existing regression through S4-05.3 (13 files) — **all PASS** on live staging.

**Database integrity / residual check:** zero disposable businesses/users; zero `rider_assignments` rows with `status='declined'`; zero `assignment.*` events; zero orphaned orders — all expected, since every test action was rolled back.

**Cleanup:** ephemeral credential securely deleted (`shred -u`), confirmed absent. `git diff --check` PASS.

### S4-05.4 = COMPLETE, staging-verified. Awaiting Founder review before S4-05.5.

## 52. S4-05.5 Rider UI/Backend Wiring — COMPLETE (static-verified; browser click-through NOT performed)

**Frontend-only batch — no migration, no staging component.** `rider/backend.js` and `rider/index.html` only.

**Reconciliation performed first:** read `rider/backend.js` (97 lines) and the Home-screen/`viewAssignment` sections of `rider/index.html`. Findings:
- `hydrateOrders()` only ever fetched `/rest/v1/orders` directly — the pre-existing `assignments()` function (`rider_assignments?select=*,orders(*)`) was **dead code, never called anywhere**, and non-functional regardless (there is no FK from `rider_assignments` directly to `orders` for PostgREST to embed on — the real path is `orders → delivery_stops → rider_assignments`). The Rider app therefore had **zero** knowledge of assignment acceptance state before this batch — every assigned order was treated as immediately actionable, which the S4-05.4 backend gate would now reject with a raw, unexplained error.
- `appState.activeAssignment.sessionId`/`.assignmentStatus`/`.totalOrders`/`.vendor`/`.pickupWindow`/`.deliveryWindow`/`.riderType` are mock object-literal fields **never read anywhere** (confirmed by exhaustive grep) except `.zone`, which only feeds a display title. These remain genuinely dormant/unread after this batch too — per instruction ("remove or replace only *active* mock state"), they were left untouched rather than repurposed, since nothing consumes them.
- `viewAssignment()` selects the next order by `delivery_status` alone (`status==='ready_for_pickup'`) — a genuine gap found during reconciliation: since declining an assignment does **not** change the order's own `delivery_status`, a declined order could still match this selector and be surfaced as if actionable. Fixed as part of this batch (see below).

**Backend adapter (`rider/backend.js`):**
- `orders()` query extended with a nested PostgREST embed: `orders?select=*,delivery_stops(assignment_id,rider_assignments(status,accepted_at))&order=...` — the real, working relationship path (`stops_rider`/`assignments_rider` RLS already permit this for the assigned rider, confirmed by S4-05.4's own RLS work).
- `mapOrder` now carries `assignmentStatus`/`assignmentAcceptedAt` straight from that embed (defensively unwraps either array-of-one or single-object embed shapes) — backend-authoritative, never assumed.
- `acceptAssignment`/`declineAssignment` added (`api.rpc('accept_assignment'|'decline_assignment', ...)`), exposed via `window.CEFFLO_RIDER`. The broken `assignments()` function removed entirely (dead, non-functional, misleading if left in the public adapter interface).
- `acceptAssignmentAction`/`declineAssignmentAction` global handlers, both routed through one shared `runAssignmentAction()` with an `assignmentActionsInFlight` `Set` guard (duplicate-tap protection, same pattern as the Vendor/Customer batches) — on success, re-hydrates from the backend and re-renders Home; never fabricates the new state client-side.

**UI (`rider/index.html`):**
- Home screen (`renderHome`): computes `activeOrders` (excludes `assignmentStatus==='declined'` from all counts/next-stop targeting) and `nextPendingAcceptance` (the next non-delivered order still `assignmentStatus==='assigned'`). When one exists, the mission card's CTA button is replaced with an Accept/Decline pair wrapped in a new `.mission-action-row` container — deliberately **not** a direct `.mission-card>.btn` child, so the pre-existing legacy wrapper scripts (which rewrite that specific selector's text on every render) cannot corrupt it. Card markup, KPIs, and styling otherwise byte-identical to the existing branch — no redesign.
- `viewAssignment()`: excludes declined orders from its target selection (the gap found during reconciliation), so a declined order's still-`'created'` `delivery_status` can never be mistaken for something actionable.
- Orders tab / `openOrderDetail`: confirmed read-only (no mutating action button), so no additional gating was needed there.

**Verified — static/DB, not browser:**
- New `tests/s4_05_batch_5_rider_assignment_wiring.py` (18 checks): adapter exposes accept/decline via the canonical `CEFFLO_RIDER` object; handlers registered as globals; duplicate-tap guard present (add/check/delete on `assignmentActionsInFlight`); actions refresh via `hydrateOrders()`+`renderHome()` and never fabricate `assignmentStatus` client-side; `mapOrder` reads the real nested embed, not any mock source; the broken `assignments()` accessor is gone; no direct `rider_assignments` mutation; Home gating computed only from the backend field; Accept/Decline rendered in a container distinct from the legacy-wrapper-touched `.btn` selector; declined orders excluded from active-workload counts; `viewAssignment()` excludes declined orders; no auto-reassignment, S4-06 batching/session, or S4-08 exception/cancel code introduced; existing `.btn` class family reused (no new component); the old mock `sessionId`/`assignmentStatus` fields remain genuinely unread. **PASS.**
- Node `--check` syntax validation on `rider/backend.js` and all 14 inline `rider/index.html` script blocks — **PASS**.
- Full existing regression (13 DB-level files, all S4-01-S4-05.4 + all prior static suites) — **all PASS** after a clean `supabase db reset --local` (this batch adds no migration, so the ledger is unchanged at 13/13; the reset was solely to eliminate the same known multi-hour local-test-residue artifact already documented in Sections 45/48, re-confirmed here, not a functional defect).

**NOT verified — explicit gap, not claimed:** no real browser click-through was performed (no browser tool connected this session, confirmed consistent with the standing session notice). This is the third instance of the same class of outstanding item, alongside the Customer Tracking (Section 42) and Vendor approval (Section 47) browser-verification gaps — all three should close together whenever browser tooling or a manual Founder check becomes available.

### Safety confirmation
No Production access. No Rider UI redesign — only the CTA area was conditionally extended. No auto-reassignment, S4-06 batching/session, or S4-08 exception/cancel functionality introduced. No commit/push. No S4-05.6 started. `git diff --check` PASS.

## 53. S4-05.6 Final Integration & Acceptance — LOCAL COMPLETE, staging re-verification blocked on credential

**This is the closure/acceptance batch, not new feature development. No new schema/RPC/UI change was introduced.**

### 1. Reconciliation of S4-05.1 → S4-05.5
Confirmed complete and internally consistent: separate `approved_at`/`approved_by` columns (not an enum value); `assign_rider` rejects unapproved orders; minimal `delivery_sessions` foundation with RLS closed in the same batch as its RPCs; `rider_assignments` accept/decline with the dedicated `'declined'` enum value; `rider_transition` gated on `'accepted'` via one additive check; Vendor approval UI wired; Rider assignment UI wired (mock `assignments()`/session/status state removed or confirmed dormant). All six Founder decisions from Section 44 remain intact and unweakened.

### 2. Full local regression from a clean reset
`supabase db reset --local` (first attempt hit a transient Docker container timing error mid-reset -- confirmed via `docker ps` that the DB container had just restarted; retried once containers stabilized, succeeded cleanly, all 13 migrations replayed). Every existing test file (13 DB-level + 8 static/Node) plus the new `tests/s4_05_batch_6_full_integration.py` — **all PASS**. `tests/test_environment_guard.py`'s direct-script invocation fails on a pre-existing package-relative import (`from tests.environment_guard import ...`) unrelated to any change this session -- re-run correctly via `python3 -m tests.test_environment_guard` from the repo root: 30/30 PASS.

### 3. Complete authoritative flow -- new end-to-end integration test
`tests/s4_05_batch_6_full_integration.py` chains, in one test, exactly the sequence requested: create order (unapproved/session-less by default) → approve (as Operator/Staff, exercising that authorization path) → create a delivery session and attach the order to it → assign rider (verified `assign_rider` snapshots the now-attached session onto the new `rider_assignments` row) → confirm the Rider sees a pending, unaccepted assignment and the lifecycle is blocked → accept assignment → full `rider_transition` sequence → `complete_delivery` → confirm `public_tracking` reflects `delivered`. **All PASS.** `delivery_events` coverage verified as one exact, ordered sequence: `delivery.created, order.approved, session.created, session.order_attached, rider.assigned, assignment.accepted, delivery.status_changed×4, delivery.completed` -- no missing, duplicate, or out-of-order events.

### 4. Decline path -- non-actionable, no auto-reassignment
Verified in the same integration test: after decline, `rider_transition` remains blocked with the identical `assignment not accepted` denial; `orders.assigned_rider_id` and `rider_assignments.rider_id` both remain unchanged (no silent reassignment); the Vendor's own existing manual remedy (`reassign_rider`) still functions correctly afterward, confirming a decline leaves the order in a valid, non-corrupted state for Vendor-driven recovery -- with no automation added.

### 5. Direct-write/RLS + cross-business isolation re-verified across all three S4-05 contracts together
Cross-business: Business B's owner denied on `approve_order`, `create_delivery_session`, `attach_order_to_session`, `update_session_status` against Business A's order/session (all `forbidden`); Business B's rider denied on `accept_assignment`/`decline_assignment` against Business A's order (`forbidden`). Direct-write: INSERT on `delivery_sessions` raises; UPDATE/DELETE on `delivery_sessions`, UPDATE on `orders.approved_at`, and UPDATE on `rider_assignments.status` all affect zero rows -- re-confirmed together in one sweep, not just in isolation.

### 6. delivery_events coverage + database integrity
Covered above (item 3) plus three integrity invariants checked directly against live table state: zero `rider_assignments` rows with `status='accepted'` and a null `accepted_at`; zero `orders` rows with `approved_at` set and `approved_by` null; zero `orders` rows whose attached `delivery_session_id` belongs to a different business than the order itself. All zero.

### 7-9. Staging re-verification -- BLOCKED
The ephemeral credential is absent at `/tmp/cefflo-staging-db-password.ephemeral`. **No new migration exists to apply** -- `cefflo-staging`'s ledger already matches local exactly at `202608270012` (verified live in Sections 46/49/51 across S4-05.1/.3/.4; S4-05.2/.5 are frontend-only, no schema change). What remains specifically blocked is re-running the full regression -- including this turn's new full-chain integration test -- directly against the live staging database, plus the zero-residual-fixtures check. Per instruction, stopped at the credential gate rather than improvising an alternative path.

### Open frontend acceptance items (carried forward, not fabricated)
No browser tool is connected this session (confirmed via tool search in the S4-05.2 turn, unchanged since). Three real-browser click-throughs remain unverified: Vendor Approve Order (Section 47), Rider Accept/Decline (Section 52), Customer Tracking on-demand refresh (Section 42, carried from S4-04). All three are explicitly recorded as release-gate carry-forward items, not claimed as passed.

### Recommendation on independent closability
S4-05's own canonical acceptance gate (`PHASE_1_STAGE4_GAP_REPORT.md`: "Explicit approval precedes pickup; session/assignment/stops are authoritative and evented") is a **backend-contract** gate, fully and rigorously proven at the database level -- including now the complete chained flow, cross-business isolation, and direct-write protection, all re-verified together. The three open browser-click-through items are UI-acceptance concerns that this session's discipline treats as belonging to the release gate (S4-15), not to S4-05's own definition of done. **Recommendation: the backend/integration portion of S4-05 is ready to close on staging re-verification alone (steps 7-9) -- it does not need to wait on browser access.** The three browser items should be carried forward as named release-gate items, tracked but non-blocking for S4-05 itself.

### Safety confirmation
No Production access. No UI redesign. No new features. No S4-06 started. Staff Workspace/Helper Pool untouched. No commit/push. `git diff --check` PASS.

## 54. S4-05.6 STAGING RE-VERIFICATION — PASS. S4-05 FORMAL CLOSURE RECOMMENDED

**Target verified:** `environment=staging`, `project_ref=tomvvmwktehexwhktenw`, official Mumbai session pooler — fail-closed identity check PASS before any action. No implementation change made this turn (none needed — no defect found).

**Migration ledger:** confirmed matches local exactly, `202608130001` → `202608270012`, all 13, nothing pending.

**Full S4-05 regression + full-chain integration test run directly against staging** (14 files, all rollback-only): `s4_05_batch_6_full_integration.py` — **PASS**, confirming on live staging: the complete authoritative lifecycle (create → approve → create/attach session → assign → pending/blocked → accept → full `rider_transition` sequence → complete → tracking reflects delivered) with the exact 11-event ordered sequence; the decline path (non-actionable, no auto-reassignment, Vendor's manual `reassign_rider` remedy still works); RLS/direct-write protections and cross-business isolation across all three S4-05 contracts together. `s4_05_batch_4/3/1`, `validate_backend`, `e2e_transaction`, `s4_03_batch_1_contracts`, `s4_03_batch_3_rls`, `s4_03_rider_scope_fix`, `s4_04_batch_2_pod_path`, `s4_04_batch_3_token_lifecycle`, `s4_04_batch_5_rate_limit_infra/public_tracking_limit/submit_rating_limit` — **all PASS** on live staging.

**Database integrity / residual check:** zero disposable businesses/users; zero `delivery_sessions` rows; zero `rider_assignments` in `accepted`/`declined` state; zero approved-without-approved_by orders; zero cross-business session attachments; zero orphaned orders — all expected, every test action rolled back.

**Cleanup:** ephemeral credential securely deleted (`shred -u`), confirmed absent. `git diff --check` PASS.

### FINAL S4-05 CLOSURE RECOMMENDATION: CLOSE

S4-05's canonical acceptance gate (`PHASE_1_STAGE4_GAP_REPORT.md`: "Explicit approval precedes pickup; session/assignment/stops are authoritative and evented") is now fully proven, both locally and on live `cefflo-staging`, including the complete chained flow, decline/no-auto-reassignment behavior, cross-business isolation, direct-write protection, event coverage, and database integrity.

**Carried forward as named, tracked, non-blocking S4-15 release-gate items (not fabricated, not claimed as passed):**
1. Vendor Approve Order — real-browser click-through (Section 47).
2. Rider Accept/Decline — real-browser click-through (Section 52).
3. Customer Tracking on-demand refresh — real-browser click-through (Section 42, carried from S4-04).

**Preserved, unfixed technical debt (unchanged, not reopened):** S4-03 Batch-1's residual `anon`-can-execute grant gap (Section 42); `submit_rating`'s lack of enforcing rate limit / reliable abuse telemetry, by Founder design (Section 42); future outer-layer volumetric protection / Cloudflare consideration (Section 42).

### Safety confirmation
No Production access. No commit/push. No S4-06 started. Staff Workspace/Helper Pool untouched. No implementation change this turn. `git diff --check` PASS.

## 55. S4-06 Canonical Recovery + Current-State Reconciliation (READ-ONLY — no implementation this turn)

**Recovery source:** `PHASE_1_STAGE4_GAP_REPORT.md` row S4-06: "Complete batching, zones, routing, and multi-drop backend integration" — `COMPLETE` / `P1`, depends on S4-05, canonical docs `01_PRODUCT.md`/`06_VENDOR.md`/`07_RIDER.md`/`10_DELIVERY_LIFECYCLE.md`, acceptance gate "One session supports authorized multi-stop plan, sequence, reassignment, completion," **Founder approval explicitly required for the final zone model** (stated in the gap report's own approval column, distinct from D-17's general implementation-design latitude). `05_DECISIONS.md` D-17 confirms batching/zones/sessions/multi-drop are required Stage 4 capabilities and explicitly delegates the zone *contract* choice ("persisted/derived/hybrid") to implementation design -- but the gap report still requires Founder sign-off on whatever is chosen. Noted a minor doc-drift: `S4-02_PERMISSION_BACKEND_CONTRACT_DESIGN.md` (pre-dating the finer S4-05/S4-06 split) deferred the whole session/batch/zone/multi-drop area to "S4-05" as one block -- the gap report's later, more granular split (S4-05 = contract foundation, S4-06 = batching/zone/routing intelligence) is treated as authoritative, consistent with how S4-05 was itself scoped.

### Key current-state findings (verified this turn, not assumed)
- **Zones do not exist in the schema at all.** No `zone` column anywhere (`orders`, `riders`, `delivery_sessions`, `rider_assignments` all lack one). The only adjacent real column is `businesses.operating_area` (free text, unrelated). Every "zone" appearing in the Vendor/Rider UI (`riders.zone` always hardcoded `'Unassigned'`, Rider's `zone: 'Assigned route'`, mock `zone:'Bangi'`) is pure decorative client-side text with zero backend reality.
- **Stop/order sequencing is a fully dormant, partially-wired column pair.** `delivery_stops.sequence` and `orders.delivery_sequence` both exist since foundation and are **never written by any RPC**. Rider's own fetch query (`order=delivery_sequence.asc.nullslast,created_at.asc`) and `mapOrder`'s `sequence: row.delivery_sequence || index + 1` already *read* this column defensively -- meaning the instant a real backend value is populated, the existing Rider fetch/display logic would already respect it with no further UI change needed for basic ordering.
- **`assign_rider` always creates a brand-new `rider_assignments` row per order call** -- never reuses an existing open assignment for the same rider, even within the same session. Today's real, proven behavior is therefore "one assignment per order" (S4-05.4's Accept/Decline model), not "one assignment, many stops." The schema does *not* block the latter (`delivery_stops.assignment_id` is nullable and non-unique, so multiple stops could already reference one assignment row) -- only `assign_rider`'s current logic forecloses it.
- **A large, fully-built but entirely disconnected mock batching/session/zone engine already exists in `vendor/index.html`**: `state.deliverySessions`/`state.deliveryStops`/`state.zones`/`state.issues`, `createDeliverySession()` (with duplicate-session prevention), `activeDeliverySession()`, `sessionOrders()`, `getCurrentDeliveries()` (groups by `riderId|zoneId` with fabricated ETA math), a full "Pickup Session" per-rider verification screen, and a "Zone Validation" step in the order-creation wizard. **Confirmed dead in the real backend path**: `vendor/backend.js`'s `hydrateCanonicalWorkspace()` explicitly resets `state.deliverySessions`/`deliveryStops`/`riderAssignments`/`zones`/`issues` to empty arrays every time it hydrates from the real backend -- this entire subsystem never runs when a real session exists. It also uses an entirely different status vocabulary (`pendingConfirmation, kitchenQueue, packing, sorting, ...`) than the real `delivery_status` enum, so it cannot be reactivated as-is without reconciliation.
- **Rider's multi-stop route UI (`renderRouteOverview`, `stopDetailHTML`) is already wired to real order data** (via the working `hydrateOrders()`), but ETA/distance figures shown are fabricated formulas keyed off array index (`5+i*2` min, `(1.4+i*.2)` km), not real values, and "stop order" is really just REST fetch order, not an authoritative Vendor- or system-set sequence.

Full architecture-question analysis (A-H), Founder decisions, and the proposed execution plan delivered to the Founder in this turn's chat response in the exact requested format. Six Founder decisions identified as genuinely required: (1) assignment consolidation model -- keep S4-05.4's proven per-order accept (recommended) vs. consolidate to one assignment/many-stops requiring a batch-level accept; (2) the final zone model itself (gap-report-mandated Founder approval, recommended: a simple persisted text column, no geospatial complexity); (3) session structural-locking semantics (recommended: no hard lock in Stage 4, Vendor-driven "start run" is the natural cutoff); (4) whether to reuse/adapt the existing large dormant Vendor mock batching UI or build fresh against the real backend (recommended: evaluate reuse of its visual/interaction shell only, not its data engine, given the enum mismatch); (5) stop-sequencing authority and whether strict in-order completion is enforced (recommended: system auto-sequence by default, Vendor manual reorder deferred unless required, enforce sequential completion); (6) whether one session may span multiple riders or maps 1:1 to a single rider's run (recommended: allow multiple riders per session organizationally, but each rider's own stops remain independently sequenced).

Proposed 7-batch execution plan (S4-06.1 session-order attachment at scale, S4-06.2 stop sequencing backend, S4-06.3 zone minimal model backend, S4-06.4 session locking, S4-06.5 Vendor UI wiring, S4-06.6 Rider UI wiring, S4-06.7 full integration + staging acceptance) -- none implemented. S4-06.1/.2/.3 assessed as independently parallelizable; .5/.6 depend on the backend batches; .7 is the final gate.

**Verdict: READY FOR FOUNDER DECISIONS.** No implementation, no migration, no deployment this turn. `git diff --check` PASS (no files touched).

## 56. S4-06.1 Multi-Order Session Foundation — LOCAL COMPLETE, staging blocked on credential

**Reconciliation performed first:** re-read `create_delivery_session`/`attach_order_to_session` (S4-05.3). Confirmed the existing schema already fully supports multiple same-business orders belonging to one session -- `orders.delivery_session_id` carries no unique constraint, and `attach_order_to_session` already independently verifies both the order and the session belong to the same business. **Decision: repeated single-order `attach_order_to_session` calls are sufficient; no new bulk/multi-order RPC was added.** Session membership is an independent per-order fact with no cross-order invariant requiring atomic batch application -- adding a bulk RPC would have been inventing complexity beyond "the smallest robust contract."

**The one real gap found:** `attach_order_to_session` was not idempotent -- calling it again with the same target `p_delivery_session_id` (or `NULL`, if already detached) re-recorded a duplicate `session.order_attached`/`session.order_detached` event every time, unlike every other mutation in this project (`approve_order`, `accept_assignment`, `reassign_rider`'s same-rider case). Fixed with a single `if o.delivery_session_id is not distinct from p_delivery_session_id then return o; end if;` no-op guard -- no schema change, no other behavior touched.

**Migration `202608270013_s4_06_batch_1_multi_order_session.sql`:** `create or replace function attach_order_to_session` with the idempotency fix only. `create_delivery_session` and `update_session_status` untouched.

**Verified locally** (`tests/s4_06_batch_1_multi_order_session.py`, new, rollback-only): three same-business orders successfully attached to one session; cross-business order/session combinations denied both directions (`invalid session` for the integrity mismatch, `forbidden` for the authorization boundary on a foreign order); duplicate/idempotent attach records exactly one event, not two; detach behavior correct and itself idempotent (re-detaching an already-detached order records no duplicate event); Operator/Staff authorization confirmed; approval gate (`order not approved`) and existing lifecycle unaffected by session attachment; direct-table write bypass on `delivery_sessions`/`orders.delivery_session_id` confirmed still fully blocked; zero cross-business session-attachment integrity violations.

**Full regression after a clean `supabase db reset --local`** (all 14 migrations replayed): every S4-01 through S4-05.6 test file (13 DB-level + 8 static/Node) plus the new S4-06.1 test — **all PASS**. `test_environment_guard` re-confirmed via correct module invocation: 30/30 PASS.

**Staging:** NOT applied. The ephemeral credential is absent at `/tmp/cefflo-staging-db-password.ephemeral`. Per established discipline, stopped at the credential gate rather than improvising an alternative path.

### Safety confirmation
No S4-06.2 (sequencing) started. No zones implemented. No Accept Run/Decline Run implemented. `reassign_rider` not modified. No Vendor/Rider UI touched. No route optimization. No S4-07+ started. No Production access. No commit/push. `git diff --check` PASS.

## 57. S4-06.1 STAGING ACCEPTANCE — PASS

**Target verified:** `environment=staging`, `project_ref=tomvvmwktehexwhktenw`, official Mumbai session pooler — fail-closed identity check PASS before any action.

**Migration applied:** `202608270013` only (staging ledger was at `202608270012`; dry-run confirmed exactly one pending file). Final ledger: `202608130001` → `202608270013`, all 14, in order — confirmed live. `attach_order_to_session`'s idempotency fix confirmed present in the live `prosrc`.

**Full acceptance re-run directly against staging** (all rollback-only): `s4_06_batch_1_multi_order_session.py` — multi-order same-business session attachment PASS, cross-business denial PASS (both the integrity mismatch and the authorization boundary), idempotent attach/detach PASS (no duplicate events, re-verified live), approval gate/existing lifecycle unaffected, direct-table write bypass still fully blocked, zero cross-business integrity violations — **PASS**. Full existing regression (`s4_05_batch_6_full_integration`, `s4_05_batch_4/3/1`, `validate_backend`, `e2e_transaction`, `s4_03_batch_1_contracts`, `s4_03_batch_3_rls`, `s4_03_rider_scope_fix`, `s4_04_batch_2_pod_path`, `s4_04_batch_3_token_lifecycle`, `s4_04_batch_5_rate_limit_infra/public_tracking_limit/submit_rating_limit`) — **all PASS** on live staging.

**Database integrity / residual check:** zero disposable businesses/users; zero `delivery_sessions` rows; zero orders with a session attached; zero orphaned orders — all expected, every test action rolled back.

**Cleanup:** ephemeral credential securely deleted (`shred -u`), confirmed absent. `git diff --check` PASS.

### S4-06.1 = COMPLETE, staging-verified. Awaiting Founder review before S4-06.2.

## 58. S4-06.2 Plan Route / Pickup Checklist / Delivery Run — LOCAL COMPLETE, staging blocked on credential

**Implemented exactly the Founder-locked design** (design turns preceding this one): `delivery_stops.sequence` remains the sole authoritative sequence source (`orders.delivery_sequence` untouched); one new nullable column `delivery_stops.sequence_locked_at`; three new Rider-scoped RPCs (`save_run_sequence`, `start_pickup_run`, `start_run_delivery`); one additive check in `rider_transition`.

**`save_run_sequence(p_delivery_session_id, p_ordered_order_ids)`** — requires the complete, exact eligible-stop set (no missing/extra/duplicate order ids, validated via count + not-exists checks); rejects if any eligible stop is already locked; idempotent (byte-identical resubmission is a true no-op, no event); genuine reorder updates `sequence` and records one `run.sequence_saved` event per stop.

**`start_pickup_run(p_delivery_session_id)`** — requires at least one applicable assignment; requires all actionable assignments settled (none `status='assigned'`); never touches `orders`/`delivery_stops` (cannot fabricate pickup); idempotent via locking the rider's own `rider_assignments` rows (`for update`) before checking/inserting the `run.pickup_started` event — no new persistent state column, the event log itself is the durable fact.

**`start_run_delivery(p_delivery_session_id)`** — requires every eligible order already `picked_up`+ (`pickup incomplete` otherwise) AND a complete valid saved sequence covering exactly the eligible set (`sequence not ready` otherwise); on success atomically locks `sequence_locked_at` across every eligible stop, records one `run.sequence_locked` event per stop plus exactly one canonical `run.delivery_started` event (the future customer-notification trigger — nothing consumes it yet, no sending/provider/template/queue logic exists anywhere in this batch); idempotent (already-locked repeat call is a no-op success, zero duplicate events); records **zero** events if any precondition fails (both checks run before the locking CTE).

**`rider_transition`** — one additive block only, preserving every existing check in full effect (reformatted to multi-line for readability given the size of the addition, not redesigned): the new sequential-enforcement check applies only to `out_for_delivery`/`arrived` transitions, only when the target stop's `sequence_locked_at is not null` — inert for every unlocked stop, including every single-order delivery today. Denies with `complete earlier stop first` if any lower-sequenced, same-rider-and-session, non-terminal stop isn't yet `delivered`.

**Verified locally** (`tests/s4_06_batch_2_run_sequence_pickup_delivery.py`, new, rollback-only, multi-rider setup: 3 stops for Rider 1 + 1 stop for Rider 2 in one shared session): sequence save/reorder before lock (including a genuine reorder, not just initial save); exact-set validation (missing/extra/duplicate all rejected); Start Pickup prerequisites (unsettled assignments rejected) and idempotency (duplicate call, zero duplicate events); unordered individual pickup confirmations (confirmed in a THIRD, different order than either the assignment order or the saved sequence); Start Delivery rejected before all pickups (`pickup incomplete`, zero `run.delivery_started` events exist at that point); Start Delivery rejected without a valid saved sequence (`sequence not ready`, Rider 2's case); successful lock with exactly one `run.delivery_started` and one `run.sequence_locked` per stop; idempotent repeat Start Delivery; normal reorder rejected after lock (`sequence locked`); out-of-sequence delivery denial (stop 2 and 3 both denied before stop 1 delivered, stop 3 still denied after only stop 1 delivered) then full sequential completion; multi-Rider independence (Rider 2's stop never locked/affected by Rider 1's Start Delivery, completes its own independent run fully); existing S4-05 exact-rider and assignment-acceptance gates re-confirmed untouched; single-order compatibility (an order never attached to any session, never touched by any run RPC, completes exactly as before, `sequence_locked_at` stays null); direct-table write bypass on `delivery_stops` confirmed still fully blocked; cross-business/exact-Rider security (Business B's rider sees "no assignments in this run" against Business A's session on every new RPC).

**Test-authoring note:** initial run surfaced a type-mismatch bug in the test itself (comparing `create_delivery`'s string-typed JSON `order.id` against psycopg's `uuid.UUID`-typed column reads) — fixed by normalizing to `uuid.UUID` at the point of order creation. Not a product defect; the underlying RPC logic was correct on first execution once the test's own comparison was fixed.

**Full regression after a clean `supabase db reset --local`** (all 15 migrations replayed): every S4-01 through S4-06.1 test file (14 DB-level + 8 static/Node) plus the new S4-06.2 test — **all PASS**. `test_environment_guard`: 30/30 PASS.

**Staging:** NOT applied. The ephemeral credential is absent at `/tmp/cefflo-staging-db-password.ephemeral`. Per explicit instruction ("fail closed otherwise"), stopped at the credential gate rather than accessing staging.

### Safety confirmation
No S4-06.3+ started. `reassign_rider` not modified (its approved correction, now including the `sequence = NULL` reset, remains S4-06.4). No Vendor/Rider UI touched. No customer notification sending, WhatsApp/provider integration, ETA, templates, or queue/outbox implemented — `run.delivery_started` is recorded and nothing else. No Production access. No commit/push. `git diff --check` PASS.

## 59. S4-06.2 STAGING ACCEPTANCE — PASS

**Target verified:** `environment=staging`, `project_ref=tomvvmwktehexwhktenw`, official Mumbai session pooler — fail-closed identity check PASS before any action.

**Migration applied:** `202608280001` only (staging ledger was at `202608270013`; dry-run confirmed exactly one pending file). Final ledger: `202608130001` → `202608280001`, all 15, in order — confirmed live.

**Live schema/function verification:** `delivery_stops.sequence_locked_at` present (nullable); `save_run_sequence`/`start_pickup_run`/`start_run_delivery` all exist with correct grants (`anon=false`, `authenticated=true`); `rider_transition`'s live source contains the `'complete earlier stop first'` sequential-enforcement message.

**Full acceptance re-run directly against staging** (all rollback-only, same multi-Rider test as local): `s4_06_batch_2_run_sequence_pickup_delivery.py` — sequence save/reorder before lock PASS, exact-set validation PASS, Start Pickup prerequisites/idempotency PASS, unordered pickup confirmations PASS, Start Delivery gates PASS (`pickup incomplete`/`sequence not ready`, zero premature `run.delivery_started` events), sequence locking PASS, `run.delivery_started` exactly once PASS, post-lock reorder denial PASS, out-of-sequence delivery denial PASS, full sequential completion PASS, multi-Rider independence PASS, single-order compatibility PASS, cross-business/exact-Rider security PASS — **PASS**. Full existing regression (15 files: `s4_06_batch_1`, `s4_05_batch_6/4/3/1`, `validate_backend`, `e2e_transaction`, `s4_03_batch_1_contracts`, `s4_03_batch_3_rls`, `s4_03_rider_scope_fix`, `s4_04_batch_2_pod_path`, `s4_04_batch_3_token_lifecycle`, `s4_04_batch_5_rate_limit_infra/public_tracking_limit/submit_rating_limit`) — **all PASS** on live staging.

**Database integrity / residual check:** zero disposable businesses/users; zero locked `delivery_stops`; zero `run.*` events; zero orphaned orders — all expected, every test action rolled back.

**Cleanup:** ephemeral credential securely deleted (`shred -u`), confirmed absent. `git diff --check` PASS.

### S4-06.2 = COMPLETE, staging-verified. Awaiting Founder review before S4-06.3 or S4-06.4.

## 60. S4-06.3 Minimal Zone Concept — LOCAL COMPLETE, staging blocked on credential

**Implemented exactly the Founder-locked design**: new `zones` table (business-scoped, `name`, `status` active/inactive, case-insensitive unique index on `(business_id, lower(name))`), `orders.zone_id` nullable FK, three new protected RPCs (`create_zone`, `rename_zone`, `set_zone_status` — all Owner-or-Operator/Staff scoped, matching the `is_business_member` precedent, not owner-only), and `p_zone_id`/`p_clear_zone` parameters added to `create_delivery`/`update_order_details`.

**Reconciliation finding requiring a technique, not a design change:** adding a new parameter to `create_delivery`/`update_order_details` changes their argument-*type* signature, which `CREATE OR REPLACE FUNCTION` cannot handle (Postgres requires an identical type list to replace in place; a new parameter type creates a second, competing overload instead of replacing). Used explicit `DROP FUNCTION` + `CREATE FUNCTION` + re-`GRANT` for both — confirmed via `pg_proc` count that exactly one overload of each exists post-migration, no duplicate/ambiguous signature left behind.

**Incidental improvement, noted plainly rather than silently done:** both `create_delivery` and `update_order_details` had to have their grants fully rewritten anyway (a consequence of the drop+recreate, not a deliberate reopening of unrelated scope) — used the correct `revoke all ... from public, anon, authenticated` pattern for both while doing so, closing `update_order_details`'s previously-preserved S4-03 Batch-1 grant gap (Section 42) as a side effect. This was not sought out or fixed independently; it fell out naturally from work already required for zones.

**`update_order_details` previously recorded zero audit events for any field.** Added exactly one new event, `order.zone_changed`, fired only when the zone actually changes (not a general audit retrofit for the other fields, which remains out of scope).

**Design decisions implemented as approved:** zone assignable at `create_delivery` time and separately via `update_order_details` (both reusing `update_order_details`'s existing pre-dispatch-only gate unchanged — zone can only be set/changed before dispatch, exactly like every other field that RPC governs); deactivation only (no hard delete), never rewrites historical `orders.zone_id` references, only blocks *new* assignment of an inactive zone; Zone belongs only to orders, no `riders.zone` column exists; multi-zone runs are unrestricted — S4-06.1 sessions, S4-06.2 sequencing/locking, S4-05 approval/acceptance, and exact-Rider authorization are all completely untouched by this batch.

**Verified locally** (`tests/s4_06_batch_3_zones.py`, new, rollback-only): create/rename/deactivate (Owner); Operator/Staff authorization; duplicate-name protection case-insensitively (including whitespace-padded variants); rename-to-identical-name and status-set-to-identical-value both idempotent no-ops; cross-business denial on all three RPCs (`forbidden`); direct-write denial on `zones` (INSERT raises, UPDATE/DELETE affect zero rows); optional/unzoned order creation; active-zone assignment at creation; inactive-zone rejected at creation (`invalid zone`) and via `update_order_details` (`invalid zone`); zone change on an eligible order recording exactly one `order.zone_changed` event, and zone-clearing recording a second; an unrelated-field-only update recording zero spurious zone events; historical zone reference preserved byte-for-byte after the referenced zone is deactivated, including through a subsequent unrelated edit to the same order; a full session/run spanning two distinct active zones assigned to one Rider, completing normally through approval → attach → assign → accept → sequence → pickup → lock → sequential delivery → complete, proving zone plays no role anywhere in that machinery.

**Full regression after a clean `supabase db reset --local`** (all 16 migrations replayed): every S4-01 through S4-06.2 test file (16 DB-level + 8 static/Node, including a second composite-return parsing fix in the new test itself — `create_zone`/`rename_zone`/`set_zone_status` return `public.zones` rows, not jsonb, same class of issue fixed in prior batches, resolved via SQL-side field extraction rather than Python-side parsing) plus the new S4-06.3 test — **all PASS**. `test_environment_guard`: 30/30 PASS.

**Staging:** NOT applied. The ephemeral credential is absent at `/tmp/cefflo-staging-db-password.ephemeral`. Stopped at the credential gate.

### Safety confirmation
No S4-06.4 started. No Vendor/Rider UI touched. No geofencing, polygons, lat/lng, automatic location detection, or route optimization implemented anywhere. No Production access. No commit/push. `git diff --check` PASS.

## 61. Status Correction — S4-06.3 is NOT staging-verified; header staleness fixed

**Founder-caught error, recorded plainly:** in the S4-06.3 Zone-vs-Rider-Run operational-model reconciliation delivered this turn, I incorrectly referred to "the already-implemented and staging-verified `zones` table." This was wrong. The actual, correct status — as Section 60 already recorded accurately — is:

**S4-06.3 = LOCAL COMPLETE. Staging Applied: NO. Blocked at the credential gate.** It has not been Founder-accepted as closed, and must not be described as staging-verified until an actual staging acceptance run (fail-closed identity → apply `202608280002` → full verification list → regression → residual check) passes.

**Separately, this turn's own audit found the checkpoint's top status block (lines 3-8) had gone stale since Section 43** — it still described the pre-S4-05-implementation state even though Sections 44 through 60 had all been correctly appended in the body. Refreshed the header this turn to accurately reflect: S4-01-S4-05 closed; S4-06.1/.2 complete and staging-verified; **S4-06.3 explicitly marked local-complete/staging-pending, not closed.**

### S4-06.3 Zone-vs-Rider-Run operational model — Founder-approved, locked (design only, not yet implemented)
- No persisted Zone Group/Cluster in Stage 4.
- Zone remains a simple business-owned order grouping/filtering concept (already how S4-06.3's backend was built — confirmed to require no change).
- Zone never equals a Rider Run; one Zone may split across multiple Riders/Runs; one Run may contain orders from multiple Zones; Vendor freely selects the combination.
- Cefflo may surface factual Zone order-counts and selection totals; must NOT claim nearby/along-the-way geographic intelligence without real geographic data (none exists in the schema).
- Rider pre-run sequence planning (S4-06.2) remains fully separate from Vendor Zone/Run building (future S4-06.5).
- This is a locked design input to carry into S4-06.5 Vendor UI design specifically — it does not change the already-implemented S4-06.3 backend contract at all.

### Corrected canonical status
**S4-06.3 = LOCAL COMPLETE / STAGING ACCEPTANCE PENDING.** Not closed. Not staging-verified. Nothing implemented this turn (design/correction only).

### Safety confirmation
No implementation this turn. No migrations. No staging/Production access. `git diff --check` PASS (no code files touched).

## 62. S4-06.3 STAGING ACCEPTANCE — PASS

**Target verified:** `environment=staging`, `project_ref=tomvvmwktehexwhktenw`, official Mumbai session pooler — fail-closed identity check PASS before any action.

**Migration applied:** `202608280002` only (staging ledger was at `202608280001`; dry-run confirmed exactly one pending file). Final ledger: `202608130001` → `202608280002`, all 16, in order — confirmed live.

**Live verification (all confirmed in one pass):** `zones` table present; `zones_business_name_unique` case-insensitive unique index present; `orders.zone_id` nullable; `create_zone`/`rename_zone`/`set_zone_status` all exist; `create_delivery` and `update_order_details` each have **exactly one** overload (confirming the drop+recreate left no duplicate/ambiguous signature); `zones_vendor` RLS policy is `SELECT`-only; grants correct (`anon=false`, `authenticated=true`) on both `create_zone` and the new `update_order_details` signature (confirming the incidental grant-gap fix from Section 60 is live).

**Full acceptance re-run directly against staging** (17 files, all rollback-only; one transient timeout on the full-batch run resolved by re-running that single file in isolation — not a functional issue): `s4_06_batch_3_zones.py` — Owner and Operator/Staff Zone management, create/rename/deactivate, duplicate-name protection (case/whitespace variants), cross-business denial, direct-write denial, unzoned orders, active-zone assignment, inactive-zone rejection (both at creation and via update), zone change and zone clear each recording exactly one factual event, zero spurious events on unrelated edits, historical zone reference preserved byte-for-byte after deactivation (including through a subsequent unrelated edit), and a full multi-zone session/run completing normally end-to-end through S4-06.1/.2's untouched machinery — **PASS**. `s4_06_batch_2`/`s4_06_batch_1` (S4-06.2 sequencing/locking and S4-06.1 multi-order behavior re-confirmed preserved), `s4_05_batch_6/4/3/1`, `validate_backend`, `e2e_transaction`, `s4_03_batch_1_contracts`, `s4_03_batch_3_rls`, `s4_03_rider_scope_fix`, `s4_04_batch_2_pod_path`, `s4_04_batch_3_token_lifecycle`, `s4_04_batch_5_rate_limit_infra/public_tracking_limit/submit_rating_limit` — **all PASS** on live staging.

**Database integrity / residual check:** zero disposable businesses/users; zero `zones` rows; zero zoned orders; zero `zone.*`/`order.zone_changed` events; zero orphaned orders — all expected, every test action rolled back.

**Cleanup:** ephemeral credential securely deleted (`shred -u`), confirmed absent. `git diff --check` PASS.

### S4-06.3 = COMPLETE, staging-verified. Correcting Section 61's prior pending status now that acceptance has actually passed. Awaiting Founder review/closure before S4-06.4.

## 63. S4-06.4 Run-level Accept/Decline + safe Rider reassignment correction — LOCAL COMPLETE, staging blocked on credential

**Implemented exactly the Founder-locked design.** New migration `202608280003_s4_06_batch_4_run_accept_decline_reassign.sql`:

- **`accept_run(p_delivery_session_id)`** — new, additive, jsonb-returning. Exact-Rider-only (`current_rider_id()`), scoped to that Rider's own assignments within the given session; rejects with `no assignments in this run` if the Rider has none; `assigned → accepted` transition via one atomic CTE-chain UPDATE+INSERT; reuses the existing `assignment.accepted` event type, distinguished from `accept_assignment` only via `metadata.via = 'accept_run'`; idempotent (repeat call: `newly_accepted=0`, zero new events); other assignment states (`declined`/`cancelled`/`completed`) are silently skipped and reported, never erroring the whole call; returns `{delivery_session_id, newly_accepted, already_accepted, skipped}`.
- **`decline_run(p_delivery_session_id)`** — exact symmetric counterpart. `assigned → declined`; `assignment.declined` event tagged `metadata.via = 'decline_run'`; no decline reason (Founder decision, kept symmetric with `decline_assignment`'s existing no-reason contract); same isolation, idempotency, and partial-tolerant skip semantics; returns `{delivery_session_id, newly_declined, already_declined, skipped}`.
- **`reassign_rider(p_order_id, p_new_rider_id)`** — same signature as the S4-03 original, corrected via `CREATE OR REPLACE` (no DROP+CREATE needed — parameter types unchanged). Allowed only when `delivery_status in ('created','ready_for_pickup')`; denied (`reassignment not allowed after pickup`) for `picked_up`, `out_for_delivery`, `arrived`, `delivered`, `cancelled`, and `issue`; an explicit `sequence_locked_at is not null` check is added as defense-in-depth per Founder decision (transitively unreachable given the delivery_status gate today, but kept as an explicit, independently-enforced layer matching this project's established style). Same-Rider reassignment is a true no-op — returns immediately, no reset, no event. A genuine Rider A→B reassignment atomically: updates `orders.assigned_rider_id`; resets the matching `rider_assignments` row to `status='assigned', accepted_at=null` (never inherited by the new Rider, and reassigning back to a previously-assigned Rider goes through this exact same path — no historical acceptance is ever restored); resets only the reassigned stop's own `delivery_stops.sequence` to `null` (unaffected stops in either Rider's run keep their existing values — a resulting gap, e.g. `1,3`, is valid and is never renumbered, preserving S4-06.2's sequencing contract unchanged); records exactly one `rider.reassigned` event carrying only `{from_rider_id, to_rider_id}` (no PII).

**Verified locally** (`tests/s4_06_batch_4_run_accept_decline_reassign.py`, new, rollback-only), covering every item in the Founder's verification list:
- **Accept Run:** clean multi-order accept (4 orders, one Rider); exactly-once events with correct `via` provenance distinguishing `accept_run` from an individually-accepted order in the same batch; repeat-call idempotency (zero new events); mixed assigned/accepted interop in both directions (individual-accept-then-Accept-Run, and Accept-Run-then-individual-accept-no-op); mixed conflicting state (one order individually declined, then Accept Run correctly reports `newly_accepted=2, skipped=1`); no-assignment-run rejection (`no assignments in this run`); exact-Rider isolation (Rider 3 in a separate business has no visibility/effect); multi-Rider session isolation explicitly proven both directions — Rider 1's Accept/Decline Run activity never touches Rider 2's assignments in the same session, and Rider 2's later Decline Run never touches Rider 1's already-accepted assignments.
- **Decline Run:** equivalent mixed-state and idempotency cases; individual-decline compatibility on a standalone order; exactly-once factual events confirmed via direct count.
- **Reassignment:** all 7 non-allowed `delivery_status` values tested individually and each correctly denied (`picked_up`, `out_for_delivery`, `arrived`, `delivered`, `cancelled`, plus `issue` as an 8th boundary state) with `created` and `ready_for_pickup` both confirmed allowed; same-Rider true no-op (status/`accepted_at` unchanged, zero new events); an accepted Rider A → Rider B reassignment resets to `assigned`/`accepted_at=null`; old Rider's authority denied immediately (`forbidden` on the next lifecycle call); new Rider must freshly accept (`assignment not accepted` until they do); reassigning back to Rider A after B is confirmed to require a fresh acceptance again (no historical acceptance restored); a full pre-pickup mid-run reassignment (sequence `1,2,3` → order 2 reassigned away) leaves the remaining sequence as the valid gap `1,3`, and that gapped run still locks and completes correctly end-to-end through `start_pickup_run`/`start_run_delivery`; `sequence_locked_at` guard path exercised (denied once locked, via the already-past-pickup state); exactly one `rider.reassigned` event recorded with only `{from_rider_id, to_rider_id}`, no PII.
- Direct-write blocking on `rider_assignments` spot-checked and confirmed still fully enforced (zero rows affected on a raw UPDATE attempt).

**Pre-existing, unrelated bug found and fixed during full regression, reported plainly:** `tests/s4_04_batch_5_public_tracking_limit.py` (authored in this session's earlier S4-04.B05 work, unrelated to S4-06.4) read its "before" `invalid_lookup_telemetry` count while still under the `anon` role — a table with **zero RLS policies**, meaning `anon` can never see any row in it regardless of the true count — while its paired "after" read correctly used `reset role` first. This asymmetry silently made the "before" read always report `0`, masking a stray row left behind on the long-lived local disposable stack from an earlier failed run's non-rolled-back state. Root cause confirmed directly (manual `RAISE NOTICE` instrumentation on a disposable copy of `public_tracking`, confirming the function's own internal null-check correctly never fired during the failing run) before touching anything. Fixed by moving the "before" read to also use `reset role`, matching the existing "after" read — a test-file-only correctness fix, zero product/schema changes. Confirmed the fix is correct and the underlying `public_tracking` telemetry-gating logic was never actually broken.

**Full regression after a clean `supabase db reset --local`** (all 19 migrations replayed in strict order, including this batch's new file): every S4-01 through S4-06.4 test file — `s4_03_batch_1_contracts`, `s4_03_batch_3_rls`, `s4_03_rider_scope_fix`, `s4_04_batch_2_pod_path`, `s4_04_batch_3_token_lifecycle`, `s4_04_batch_4_edge_hardening` (14/14), `s4_04_batch_5_rate_limit_infra`, `s4_04_batch_5_public_tracking_limit` (post-fix), `s4_04_batch_5_tracking_pod_limit` (10/10), `s4_04_batch_5_submit_rating_limit`, `s4_05_batch_1_order_approval`, `s4_05_batch_3_delivery_session_foundation`, `s4_05_batch_4_assignment_accept_decline`, `s4_05_batch_6_full_integration`, `s4_06_batch_1_multi_order_session`, `s4_06_batch_2_run_sequence_pickup_delivery`, `s4_06_batch_3_zones`, `s4_06_batch_4_run_accept_decline_reassign` (new), `test_rider_logout_fix` (4/4), `test_vendor_protected_cutover` (5/5), `check_target_identity`, `validate_backend`, `test_environment_guard` (30/30) — **all PASS**. Specifically reconciled the three pre-existing `reassign_rider` call sites in `s4_03_batch_1_contracts.py`, `s4_03_batch_3_rls.py`, and `s4_05_batch_6_full_integration.py` against the new behavior (event now recorded, status/`accepted_at`/sequence now reset on genuine reassignment) — all three call `reassign_rider` only while the order is still in `created` status, so all remain correctly allowed and unaffected by any assertion in those files; no test updates were needed there. `git diff --check` PASS (zero whitespace/format issues in the new migration and both touched test files, confirmed via `git diff --no-index --check` since these files are untracked).

**Staging (at time of Section 63 authoring):** NOT applied. The ephemeral credential was absent. Stopped at the credential gate per explicit fail-closed instruction. **Superseded by Section 64 — credential was subsequently restored and staging acceptance completed.**

### Safety confirmation
No S4-06.5 started. No Vendor UI touched. No Rider UI touched. No decline reason added. No new "run" table added. No route/geographic intelligence added. No S4-08 issue-recovery work done. No Production access. No commit/push. `git diff --check` PASS.

## 64. S4-06.4 STAGING ACCEPTANCE — PASS

**Target verified:** fail-closed identity check via `tests/check_target_identity.py` (non-mutating) confirmed `environment=staging`, `project_ref=tomvvmwktehexwhktenw`, `database_host=aws-0-ap-south-1.pooler.supabase.com`, `supabase_origin=https://tomvvmwktehexwhktenw.supabase.co` — PASS before any mutating action.

**Migration ledger:** inspected via `supabase migration list` — staging was at `202608280002`; confirmed `202608280003` was the only entry with an empty `remote` field (genuinely pending). Dry-run (`supabase db push --dry-run`) confirmed exactly that one file would apply. Applied live. Post-apply ledger re-listed: all 17 entries present, `local == remote` for every one, in strict timestamp order (`202608130001` → `202608280003`).

**Live contract verification (direct SQL against staging):**
- `accept_run`, `decline_run`, `reassign_rider` — **exactly one overload each** (`pg_proc` count = 1 for all three), confirming the `CREATE OR REPLACE` on `reassign_rider` did not create a competing signature and the two new functions have no duplicates.
- `accept_run`/`decline_run` grants: `authenticated` (+ `service_role`/`postgres` as Supabase-internal defaults) — **no `anon`** — correct, matches the migration's explicit `revoke ... from public, anon, authenticated; grant ... to authenticated`.
- `reassign_rider` grants: found to also carry an `anon` EXECUTE grant. **Confirmed this is the pre-existing, already-Founder-acknowledged S4-03 Batch-1 grant debt** (documented by name for `reassign_rider` earlier in this checkpoint as recorded technical debt, "not fixed, S4-03 not reopened") — caused by the original S4-03 migration's `revoke all ... from public` (the silent-no-op form, not `from public, anon, authenticated`), inherited unchanged because this batch used a same-signature `CREATE OR REPLACE` and correctly did not touch grants. Not introduced by S4-06.4. No practical bypass: the function's internal `is_business_member` check rejects any `anon` caller (`auth.uid()` is null for anon). Not fixed here — S4-03 grant hygiene remains separately tracked debt, out of this batch's authorized scope.
- Direct-write blocking on `rider_assignments` reconfirmed still fully enforced (part of the full test suite run below).

**Full acceptance suite run directly against staging** (18 files, all rollback-only): `s4_03_batch_1_contracts`, `s4_03_batch_3_rls`, `s4_03_rider_scope_fix`, `s4_04_batch_2_pod_path`, `s4_04_batch_3_token_lifecycle`, `s4_04_batch_5_rate_limit_infra`, `s4_04_batch_5_public_tracking_limit` (with the Section 63 test-role fix live), `s4_04_batch_5_tracking_pod_limit` (10/10), `s4_04_batch_5_submit_rating_limit`, `s4_05_batch_1_order_approval`, `s4_05_batch_3_delivery_session_foundation`, `s4_05_batch_4_assignment_accept_decline`, `s4_05_batch_6_full_integration`, `s4_06_batch_1_multi_order_session`, `s4_06_batch_2_run_sequence_pickup_delivery`, `s4_06_batch_3_zones`, **`s4_06_batch_4_run_accept_decline_reassign`** (new — full Accept Run/Decline Run/reassignment/sequence-gap/multi-Rider-isolation coverage per the Founder's verification list, all confirmed live), `validate_backend` — **all PASS**.

**Database integrity / residual check:** zero rows in `businesses`, `orders`, `riders`, `zones`, `delivery_sessions`; zero `delivery_events` with `metadata->>'via'` in `('accept_run','decline_run')`; zero `rider.reassigned` events — every test action rolled back cleanly, no fixtures left behind.

**Cleanup:** ephemeral credential securely deleted (`shred -u`), confirmed absent via `stat` (nonzero exit). `git diff --check` PASS; working tree shows only the expected already-uncommitted files (no unexpected changes).

### Safety confirmation
No S4-06.5 started. No Vendor UI touched. No Rider UI touched. No decline reason added. No new "run" table added. No route/geographic intelligence added. No S4-08 issue-recovery work done. No Production access. No commit/push.

### S4-06.4 = COMPLETE, staging-verified. Awaiting Founder review/closure before S4-06.5.

## 65. S4-06.5 Design Reconciliation (Vendor Run Builder) + S4-06.5a LOCAL IMPLEMENTATION

**S4-06.4 Founder-accepted and officially closed.** Three consecutive design-only turns (zero implementation) reconciled the S4-06.5 Vendor Run Builder before any code was written:

1. **Initial S4-06.5 design reconciliation** (Vendor UI): audited the real vs. dormant/mock Vendor UI (confirmed the "Select Zone → Assign Orders" flow and `pageDispatchPlanner`/`CEFFLO_ENGINE` batching engine are fully dead against real data, one-Zone-one-Rider model rejected); designed a multi-Zone-filter + individual-order-selection Run Builder with two converging entry points (Rider-first, Orders-first); eligibility rules (`approved_at` not null, `assigned_rider_id` null, `delivery_status='created'`); split/combine-Zone scenarios; error states. Founder **partially approved** — the core UX locked, but rejected the "one `delivery_session` per business per delivery date" assumption: a `delivery_session` represents an operational **Wave** (Lunch/Afternoon/Dinner, or any Vendor-named batch), and a business may have multiple same-day waves.
2. **Wave UX + atomicity reconciliation**: confirmed `delivery_sessions`' existing `name`/`delivery_date`/`status` columns already fully support arbitrary same-day multi-Wave naming with zero schema change; designed the "Add to Existing Wave / Start New Wave" picker (Vendor-facing term: Wave, backend `delivery_session` stays internal); reconciled 2N client-side calls vs. one transactional `build_rider_run` orchestration RPC — recommended the RPC. Founder **approved**, added a hard refinement: **all-or-nothing**, not partial-tolerant (unlike `accept_run`/`decline_run` — a Vendor's explicit 10-order selection must never silently become 9), and locked the S4-06.5a (backend) → S4-06.5b (Vendor UI) split.
3. **Idempotency + event-correlation reconciliation**: Founder rejected relying on `created_at`-timestamp coincidence as a correlation mechanism ("factual data, not an operation identifier") and rejected state-matching as proof of retry ("same resulting state does not prove the incoming request is a retry"). Redesigned as an explicit key-and-payload ledger: `p_idempotency_key` changed from the originally-proposed optional `text` (matching `rider_transition`/`complete_delivery`'s soft trace-tag convention) to **required `uuid`**, with a genuine committed-operation proof (a new partial unique index on `delivery_events`, not a new table) and a payload-consistency check (`run.built`'s metadata now carries the full — previously rejected — `order_ids` array, reversed once a concrete correctness need for it was identified). Founder **approved** the final design and authorized S4-06.5a local implementation only.

### S4-06.5a Implementation

**New migration** `202608280004_s4_06_batch_5a_build_rider_run.sql` — purely additive, no changes to any existing function or table column:

- **Partial unique index**: `run_built_idempotency_key_idx on delivery_events ((metadata->>'idempotency_key')) where event_type='run.built'` — the sole schema change; the DB-enforced correctness backstop for concurrent same-key attempts, not merely a lookup optimization.
- **`build_rider_run(p_delivery_session_id uuid, p_rider_id uuid, p_order_ids uuid[], p_idempotency_key uuid) returns jsonb`**: idempotency-key lookup happens *first*, before any other validation — a matching committed `run.built` with an exactly-matching normalized payload (session, rider, sorted-deduped order set) returns the prior success with zero new mutation/events; a matching key with a *different* payload raises `idempotency key conflict`; a genuinely new key proceeds to normal validation (session exists/open/`is_business_member`; Rider active and same business; input non-null/non-empty; duplicate order IDs explicitly rejected, never silently deduplicated) then locks and revalidates the **complete** selected order set in one statement (`for update` inside a CTE, since `FOR UPDATE` cannot be combined with an aggregate directly) — any single ineligible/nonexistent/cross-business order fails the *whole* call with zero mutation (true all-or-nothing, not partial-tolerant, deliberately different from `accept_run`/`decline_run`). On full success: reuses `attach_order_to_session` then `assign_rider` **unchanged**, per order, preserving the canonical attach-before-assign ordering and every existing per-order event; then emits exactly one `run.built` event (`delivery_session_id`, `rider_id`, `order_ids`, `idempotency_key` — internal UUIDs only, no PII). A concurrency refinement re-runs the idempotency-key lookup *again* immediately before raising an eligibility conflict — so two simultaneous same-key/same-payload calls (a genuine network-retry race, not a sequential retry) both resolve to the identical committed success rather than one spuriously failing.
- **Grants**: `revoke all ... from public, anon, authenticated; grant execute ... to authenticated` — confirmed exactly one overload, `authenticated` only, no `anon` (the separate, already-tracked `reassign_rider` legacy `anon` grant debt was **not** touched).
- **`create_delivery_session` required no modification** — its existing default `status='planned'` and free-text `name`/`delivery_date` params already fully satisfy the Wave UX, confirming the design turn's assumption.

**Verified locally** — two new test files, both rollback-safe/cleanup-safe:

- `tests/s4_06_batch_5a_build_rider_run.py` (rollback-only): happy path (6 orders, exactly 6 `session.order_attached` + 6 `rider.assigned` + exactly one `run.built` with correctly normalized `order_ids`); exact retry (same key, same payload, including order-shuffled resubmission) — zero new mutation/events, identical result; same key + changed order set / changed Rider / changed Wave — each independently rejected as `idempotency key conflict`, zero mutation, `run.built` count stays at 1; a **new** key against an already-assigned order set correctly falls through to normal eligibility and is rejected (`orders no longer eligible`) — never auto-treated as a retry; required-key/duplicate-IDs/empty-input validation; nonexistent order and cross-business order rejection; unauthorized-business, completed-session, cancelled-session, inactive-Rider, and cross-business-Rider rejection; **all-or-nothing proof** — 10 selected orders with 1 pre-assigned elsewhere causes zero of the 10 to be mutated (verified via direct query, not just the raised exception) and zero `run.built`; multi-Rider same-Wave (Ali and Abu each built into the same session via two separate calls, mutually unaffected); **S4-06.4 interop** (`accept_run`/`decline_run` operate correctly on `build_rider_run`-created assignments); **S4-06.2 interop** (`save_run_sequence`/`start_pickup_run`/`start_run_delivery` complete normally downstream of a `build_rider_run` batch); **S4-06.3 interop** (zoned and unzoned orders both build correctly, `zone_id` untouched); direct-write blocking spot-check — **all PASS**.
- `tests/s4_06_batch_5a_build_rider_run_concurrency.py` (NOT rollback-only — genuine cross-transaction blocking requires real commits across two separate live connections; fixtures created and explicitly deleted, not rolled back): **overlapping-order-set concurrency** (Request A: orders 1–10→Ali commits first while holding row locks; Request B: orders 8–15→Abu blocks on the 3-order overlap, then on resuming finds those orders no longer eligible and is rejected in full — verified A's complete 10-order set committed *and* B's non-overlapping orders 11–15 remain completely untouched, proving zero partial mutation for the loser); **same-key/same-payload racing concurrency** (two simultaneous calls sharing one key for one identical Confirm-Run action — the loser's post-block re-check correctly finds the winner's now-committed `run.built`, confirms the payload matches, and returns the identical success result; verified exactly one `run.built` and no doubled per-order events) — **both PASS**. Explicit cleanup confirmed zero residual businesses/users afterward.

**Full regression after a clean `supabase db reset --local`** (all 20 migrations replayed in strict order): every S4-01 through S4-06.5a test file — `s4_03_batch_1_contracts`, `s4_03_batch_3_rls`, `s4_03_rider_scope_fix`, `s4_04_batch_2_pod_path`, `s4_04_batch_3_token_lifecycle`, `s4_04_batch_4_edge_hardening` (14/14), `s4_04_batch_5_rate_limit_infra`, `s4_04_batch_5_public_tracking_limit`, `s4_04_batch_5_tracking_pod_limit` (10/10), `s4_04_batch_5_submit_rating_limit`, `s4_05_batch_1_order_approval`, `s4_05_batch_3_delivery_session_foundation`, `s4_05_batch_4_assignment_accept_decline`, `s4_05_batch_6_full_integration`, `s4_06_batch_1_multi_order_session`, `s4_06_batch_2_run_sequence_pickup_delivery`, `s4_06_batch_3_zones`, `s4_06_batch_4_run_accept_decline_reassign`, `s4_06_batch_5a_build_rider_run` (new), `s4_06_batch_5a_build_rider_run_concurrency` (new), `test_rider_logout_fix` (4/4), `test_vendor_protected_cutover` (5/5), `check_target_identity`, `validate_backend`, `test_environment_guard` (30/30) — **all PASS**.

**Database integrity / residual check:** zero `businesses`/`orders`/`riders` rows and zero `run.built` events remaining after the full suite — the rollback-based file left nothing, and the concurrency file's explicit `DELETE ... CASCADE` cleanup was independently confirmed. `git diff --check` PASS (including the new/untracked migration and test files, confirmed via `git diff --no-index --check`).

**One real bug found and fixed during implementation, reported plainly:** the first draft combined `FOR UPDATE` with an aggregate (`count(*) filter (...)`) in one `SELECT` — Postgres rejects this combination outright (`FEATURE_NOT_SUPPORTED`). Fixed by locking the row-level set in a CTE and aggregating over the CTE's result in the outer query — a syntax-level fix only, no semantic change to the locking/validation design.

**Staging:** NOT accessed this turn — explicitly out of scope per Founder instruction (local-only authorization).

### Safety confirmation
No S4-06.5b (Vendor UI) started. No S4-06.6 started. No Rider UI touched. No geographic/route intelligence added. No Zone Group/Cluster entity added. Legacy `reassign_rider` `anon` EXECUTE grant debt not touched. No Production access. No commit/push. `git diff --check` PASS.

### S4-06.5a = LOCAL COMPLETE. Staging Applied: NO (not authorized this turn). Awaiting Founder review before staging acceptance or S4-06.5b. *(Superseded by Section 66 — staging acceptance authorized and completed.)*

## 66. S4-06.5a STAGING ACCEPTANCE — PASS

**Target verified:** fail-closed identity check (`tests/check_target_identity.py`, non-mutating) confirmed `environment=staging`, `project_ref=tomvvmwktehexwhktenw`, `database_host=aws-0-ap-south-1.pooler.supabase.com`, `supabase_origin=https://tomvvmwktehexwhktenw.supabase.co`, before the ephemeral credential (`stat`-confirmed present, owner `cefflo`, mode `0600`, 18 bytes) was used for anything else.

**Migration ledger — before:** 17 entries, `local == remote` for every one up to `202608280003`; `202608280004` present locally with an empty `remote` field — confirmed the sole genuinely pending migration, no divergence, no unknown remote entry, correct order. Dry-run confirmed exactly that one file. **Applied.** **Ledger — after:** 18 entries, `local == remote` throughout, strict timestamp order `202608130001` → `202608280004`.

**Live contract verification:** `build_rider_run(p_delivery_session_id uuid, p_rider_id uuid, p_order_ids uuid[], p_idempotency_key uuid) returns jsonb` — exactly one overload; grants `authenticated` only (no `anon`/`public`). `run_built_idempotency_key_idx` — confirmed present, `indisunique = true`, partial predicate `event_type = 'run.built'`, indexing `(metadata->>'idempotency_key')` exactly as implemented. Legacy `reassign_rider` `anon` EXECUTE grant debt: not touched.

**Full acceptance suite run directly against staging:**
- `tests/s4_06_batch_5a_build_rider_run.py` (rollback-only) — **PASS**: atomic N-order build into one Wave/Rider with exactly N `session.order_attached` + N `rider.assigned` + exactly one `run.built` carrying deterministic normalized `order_ids`/`delivery_session_id`/`rider_id`/`idempotency_key`; full idempotency matrix (exact retry incl. shuffled order input → identical success, zero new mutation/events; same key + changed order set/Rider/Wave → `idempotency key conflict` each time, zero mutation; new key against an already-assigned set → normal `orders no longer eligible` rejection, never auto-treated as retry); all-or-nothing (10 selected + 1 pre-assigned → zero of the 10 mutated, zero events, zero `run.built`); required-key/duplicate-IDs/empty-input/nonexistent-order/cross-business-order/unauthorized-business/completed-session/cancelled-session/inactive-Rider/cross-business-Rider all correctly rejected; multi-Rider same-Wave; S4-06.2/.4 interop (`save_run_sequence`/`start_pickup_run`/`start_run_delivery`, `accept_run`/`decline_run` all operate correctly on `build_rider_run`-created assignments); S4-06.3 Zone orthogonality; direct-write blocking.
- `tests/s4_06_batch_5a_build_rider_run_concurrency.py` (real two-connection, live against staging's actual network latency) — **PASS**: overlapping order sets (1–10→Ali vs 8–15→Abu) — winner's full 10 committed, loser's entire set including non-overlapping 11–15 remained completely untouched (zero partial mutation), loser emitted zero `run.built`; same-key/same-payload race — loser's post-block re-check found the winner's committed `run.built`, confirmed payload match, returned the identical success result — exactly one `run.built`, no doubled per-order events.
- Full regression (`s4_03_batch_1_contracts`, `s4_03_batch_3_rls`, `s4_03_rider_scope_fix`, `s4_04_batch_2_pod_path`, `s4_04_batch_3_token_lifecycle`, `s4_04_batch_5_rate_limit_infra/public_tracking_limit/tracking_pod_limit(10/10)/submit_rating_limit`, `s4_05_batch_1/3/4/6`, `s4_06_batch_1/2/3/4`, `validate_backend`) — **all PASS**, no test weakened, no genuine product defect found.

**Database integrity / residual check:** zero rows in `businesses`, `orders`, `riders`, `delivery_sessions`, `zones`; zero `run.built` events; zero test-fixture `auth.users` rows — full clean state confirmed via direct query after the entire acceptance run.

**Cleanup:** ephemeral credential securely deleted (`shred -u`), confirmed absent (`stat` nonzero exit). `git diff --check` PASS; working tree shows only the already-expected uncommitted files.

### Safety confirmation
No S4-06.5b started. No S4-06.6 started. No Vendor/Rider UI touched. No geographic/route intelligence added. No Zone Group/Cluster added. Legacy `reassign_rider` `anon` grant debt untouched. No Production access. No commit/push.

### S4-06.5a = COMPLETE, staging-verified. Awaiting Founder review/closure before S4-06.5b.

## 67. S4-06.5b Vendor Run Builder UI — LOCAL COMPLETE (frontend only, no staging this turn)

**S4-06.5a Founder-accepted and officially closed.** Implemented the real Vendor Run Builder UI connecting the completed S4-06.1–.5a backend contracts, exactly per the Founder-locked design. **Files modified: `vendor/backend.js`, `vendor/index.html` only.** No migrations, no other files.

**Old mock behavior bypassed, not deleted (per explicit Founder instruction):** `openAssignOrdersToRider`'s body was replaced to open the real Run Builder instead of the old "Select Zone → assign whole zone to one Rider" flow. `syncZonesFromOrders()` and `assignZoneToRiderFromProfile()` remain defined in the file (dormant, unreferenced by any live path — confirmed by the new static test) but are never called from anywhere new. `pageDispatchPlanner`/`pageZoneDetail`/`CEFFLO_ENGINE`'s mock batching/route-recalculation/geofencing code was not touched and remains unreachable, exactly as it was before this batch (confirmed already-dead in the S4-06.5 design-reconciliation audit).

**Real data hydration (`backend.js`):** `hydrateCanonicalWorkspace()` no longer unconditionally wipes `state.zones`/`state.deliverySessions` — it now fetches both for real (`listZones`/`listDeliverySessions`, new REST reads against `zones`/`delivery_sessions`, RLS-scoped exactly like the existing `listOrders`/`listRiders`) and maps them via new `mapZone`/`mapSession` functions with zero fabricated fallback fields. `mapOrder` gained `zoneId`/`deliverySessionId` (previously never surfaced to the UI at all). `deliveryStops`/`riderAssignments` remain intentionally unfetched — not genuinely required by this batch's flow. After every hydrate, a new `reconcileRunBuilderAfterHydrate()` hook (defined in `index.html`) runs if the Run Builder sheet is open, so a realtime-triggered refresh prunes any selected order that became ineligible mid-session — this is the same mechanism used for the post-conflict-error reconciliation path (§ below), not a separate one.

**Shared Run Builder (one implementation, two entry points, per Founder lock):** `openRunBuilder(opts)` / `renderRunBuilderBody()` is the single component backing both. **Rider-first** (`openAssignOrdersToRider` → `openRunBuilder({riderId})`) arrives with the Rider fixed and shown as a summary card; the Vendor picks orders. **Orders-first** (new "Select" mode added to the Orders page's `ongoing` tab — `toggleOrdersSelectMode`/`toggleOrdersSelection`, filtered to eligible orders only, with a bottom "N selected — Assign to Rider" action → `openRunBuilderFromOrdersSelection` → `openRunBuilder({orderIds})`) arrives with orders fixed; the Vendor picks the Rider. Both converge on the identical Wave-selection + confirmation step. Confirmed via static test that exactly one `data-action="confirmRunBuilder"` and one `renderRunBuilderBody`/`openRunBuilder` definition exist — no duplicate implementation.

**Eligibility** implemented exactly as locked: `approved_at IS NOT NULL && assigned_rider_id IS NULL && delivery_status='created'` (`isRunBuilderEligible`), with `zoneId` explicitly absent from that check (confirmed by static test) — Zone is never a gate, only a filter facet, and Unzoned orders (`zoneId` null) remain fully eligible/selectable.

**Zone filter:** multi-toggle chips (`runBuilderToggleZone` adds/removes from a `Set`, never touches `selectedOrderIds` — confirmed by static test) showing factual eligible-order counts only (`runBuilderZoneCounts()`, computed from the eligible set, not raw historical totals); "All" (`runBuilderClearZoneFilters`) clears filtering. Selecting a Zone filters the visible list only — never auto-selects orders, never creates anything, never binds a Zone to a Rider.

**Order multi-selection:** explicit per-order toggle (`runBuilderToggleOrder`), a live "N selected" count, a Zone Composition line computed purely from the currently-selected orders' real `zoneId` (display-only derived state — no Zone Group/Cluster entity, persisted or otherwise, anywhere in the new code). No Rider order/earnings target, no suggested split, anywhere.

**Rider selection:** Active Riders selectable; inactive/pending Riders rendered with `.opt-row.disabled` and no `data-action` (factually unclickable, not silently hidden); `availability_status` shown factually as a label only, never gating selection (matches `assign_rider`'s own real behavior).

**Wave UX:** "Add to Existing Wave" lists real `delivery_sessions` with `status in ('planned','active')` only, showing factual name/order-count/Rider-count computed live from `state.orders` (`runBuilderWaveOrderCount`/`runBuilderWaveRiderCount` — no fabricated numbers). "Start New Wave" offers an editable name pre-filled with a client-side time-of-day suggestion (`suggestedWaveName()` — Morning/Lunch/Afternoon/Dinner, a suggestion only, no fixed taxonomy enforced). Confirmed via static test that no one-Wave-per-day restriction exists anywhere in the new code, and `create_delivery_session` required zero modification (its existing `name`/`delivery_date`/default-`planned`-`status` shape already fully supports this).

**Confirm + `build_rider_run` wiring (`backend.js`, since this is the one function needing real RPC calls — matches the file's existing role for every other real action handler):** `confirmRunBuilder` calls `create_delivery_session` **at most once per operation** (result cached in `runBuilderState.resolvedNewSessionId`, invalidated only when the Wave choice itself changes — confirmed the name-edit and mode-switch handlers both null it out), then calls `build_rider_run` **exactly once** — confirmed via static test there is no old 2N `attach_order_to_session`+`assign_rider` client loop anywhere in the new handler.

**Idempotency key:** generated once via `crypto.randomUUID()` per distinct operation *signature* (`{sessionId, riderId, sorted order_ids}`, computed in `runBuilderPayloadSignature`) — an unresolved retry of the identical operation naturally reuses the same key (the signature hasn't changed, so no new key is generated); any change to the selected orders, Rider, or Wave changes the signature and correctly triggers a fresh key. Confirmed via static test.

**Success:** only after `build_rider_run` actually resolves does the UI refresh real data, close the sheet, and show a factual toast (`"N orders assigned to <Rider>"`) — confirmed via static test that the success toast and state reset both occur strictly *after* the RPC call, never before (no optimistic local success).

**Conflict/error handling:** `orders no longer eligible` → `handleRunBuilderError` refreshes real data (`hydrateCanonicalWorkspace`, which internally reconciles the selection) rather than silently resubmitting a reduced set. `idempotency key conflict` → surfaced as a factual banner; confirmed via static test this branch never auto-generates a new key or auto-retries. `invalid rider`/`session not open` → mapped to factual Rider-unavailable/Wave-unavailable banners. Offline (`navigator.onLine===false`) disables Confirm outright and shows a factual banner; an `online` event listener triggers a refresh/revalidate while the sheet is open, matching "never fabricate queued success."

**Split/combine scenarios** are provable by construction rather than needing new mechanism: split (Gombak 20 → 10 to Ali → the 10 assigned orders drop out of the eligible set automatically per the eligibility rule → remaining 10 stay selectable → later built to Abu) and combine (multi-Zone-filter + individual selection across PJ+Pantai Dalam → one `build_rider_run` call) both fall directly out of the eligibility filter and multi-select design — no dedicated split/combine code path exists, matching "no special backend split mechanism" and "ordinary multi-selection, not a new Zone Group entity."

**Single-order regression:** `openAssignRiderForOrder`/`confirmAssignRiderOrder` (Order Detail's existing real single-order Assign flow) and `reassignRider`/`api.rpc('reassign_rider'...)` were not modified — confirmed present and unchanged via static test.

**Verified — static/structural only, real click-through NOT performed (browser tooling unavailable in this environment, consistent with prior batches' precedent):** new `tests/s4_06_batch_5b_vendor_run_builder_wiring.py` — 41 assertions covering real hydration (no fabricated fallbacks, no unconditional zone/session wipe, reconciliation hook wired), RPC wiring (`build_rider_run` called exactly once, no 2N loop, no optimistic success), idempotency (key-once-per-signature, session-creation caching and its invalidation triggers), error/conflict handling (eligibility conflict refreshes+reconciles, idempotency conflict never auto-retries, offline disables confirm), eligibility (matches the exact backend contract, Zone not a gate, Unzoned selectable), Zone filter (multi-toggle, never auto-selects, counts are eligible-only), shared-component structure (one render/open function, no duplicate confirm path), dormant-mock preservation (old functions still defined but unreferenced by new code, `dispatchPlanner`/geographic-intelligence terms absent from the new code), Wave UX (existing-wave status filter, real counts, no per-day restriction, correct terminology), single-order regression, and scope boundaries (no direct table mutation in the new code, no Rider/Customer files touched) — **all 41 PASS**.

**One pre-existing test made stale by legitimate forward progress, fixed and reported plainly:** `tests/s4_05_batch_2_vendor_approval_wiring.py`'s `test_no_session_functionality_introduced` asserted `create_delivery_session`/`delivery_sessions`/`createDeliverySession` were absent from `backend.js` — true when S4-05.2 was authored, now correctly false since S4-06.5a (staging-verified) and this S4-06.5b batch were later explicitly authorized to add exactly that. Replaced the obsolete assertion with a comment explaining the supersession; did not touch the file's still-valid `test_no_cancel_or_void_introduced` scope check.

**Full regression:** all 41 new static assertions + all other static/UI test files (`s4_05_batch_2_vendor_approval_wiring` post-fix, `s4_05_batch_5_rider_assignment_wiring`, `test_rider_logout_fix`, `test_vendor_protected_cutover`, `s4_04_batch_4_edge_hardening`) — **all PASS**, zero collateral impact confirmed. Full DB-level regression (S4-01 through S4-06.5a, all 20 local migrations, unchanged this turn) re-run for completeness since backend.js's REST reads/RPC calls are exercised implicitly by these — **all PASS** (this batch made no migration/schema change, so this is a confirmation, not a new surface).

**`git diff --check` PASS**, including the new untracked test file (confirmed via `git diff --no-index --check`) and the two tracked, modified files (`vendor/backend.js` +179/-0 lines net additive edits across several hunks, `vendor/index.html` +336/-45 lines).

**Not implemented this turn (explicitly out of scope, confirmed absent):** no geographic/route intelligence, no Zone Group/Cluster entity, no Rider or Customer UI file changes, no S4-06.6 work, no unrelated security cleanup — the legacy `reassign_rider` `anon` EXECUTE grant debt remains tracked and untouched.

**Staging:** NOT accessed this turn (explicitly out of scope per Founder instruction — local-only authorization). **Real browser click-through:** NOT performed (no browser tooling connected in this environment) — carried forward as an open item to the existing S4-15 RC browser acceptance gate, consistent with precedent (Sections 47, 52 record the equivalent gap for the Vendor-approval and Rider-accept/decline UI batches).

### Safety confirmation
No S4-06.6 started. No Rider UI touched. No Customer UI touched. No geographic/route intelligence added. No Zone Group/Cluster added. Legacy `reassign_rider` `anon` grant debt untouched. No Production access. No staging access. No commit/push. `git diff --check` PASS.

### S4-06.5b = LOCAL COMPLETE (frontend). Real browser click-through and staging acceptance remain open. Awaiting Founder review. *(Superseded by Section 68 — staging contract acceptance authorized and completed; real browser click-through remains the one open item.)*

## 68. S4-06.5b STAGING CONTRACT ACCEPTANCE — PASS (real browser click-through still deferred)

**Idempotency re-inspection (Founder-required, before any staging action):** direct code inspection of `vendor/backend.js` (lines 187–223) reconfirmed the invariant holds exactly as specified: `runBuilderState.pendingKey` is set only via genuine `window.crypto.randomUUID()`; `runBuilderPayloadSignature(sessionId, riderId, orderIds)` (a JSON string) is used *only* to decide whether the existing key is still valid for a retry — it is never sent to the backend and never used as key material. `handleRunBuilderError`'s `idempotency key conflict` branch (index.html line 5303) only sets a factual error state — it never clears the key, never generates a new one, and never auto-resubmits. **No defect found. No local fix required.**

**Target verified:** fail-closed identity check (`tests/check_target_identity.py`) — `environment=staging`, `project_ref=tomvvmwktehexwhktenw`, `database_host=aws-0-ap-south-1.pooler.supabase.com` — PASS before any action.

**Migration ledger:** inspected before any action — all 18 entries `local==remote`, no divergence, no unexpected pending entry. **Confirmed no migration was needed and none was applied** — this is correctly a frontend-only batch; S4-06.5a's backend was already staging-verified in Section 66.

**Staging backend/contract acceptance (new `tests/s4_06_batch_5b_vendor_run_builder_staging_contract.py`, rollback-only):** exercises the exact RPC/REST shapes `vendor/backend.js` sends (array-of-UUID `p_order_ids`, UUID `p_idempotency_key`, `create_delivery_session(business_id, name)` with no date param, `zones`/`delivery_sessions` read shapes) directly against live staging data. Covers: real-data read shapes for zones (case-sensitive names, `active` status) and multi-same-day Waves (two Waves created same day, confirmed as independent rows — no one-Wave-per-day behavior); eligibility computed via the exact `approved_at`/`assigned_rider_id`/`delivery_status` triple (14 eligible orders from 7 PJ + 4 Pantai Dalam + 3 unzoned, 1 pre-assigned correctly excluded — matching the Founder's own example counts); zones structurally confirmed to carry no Rider/assignment concept at all (no one-Zone-one-Rider behavior possible even by omission); **combine scenario** (7 PJ + 3 of 4 Pantai Dalam → one 10-order `build_rider_run` call → exactly 10 `session.order_attached` + 10 `rider.assigned` + exactly one `run.built`); **split scenario** (20 Gombak-equivalent orders → 10 to Ali → refresh-shaped re-query confirms exactly the remaining 10 still eligible → remaining 10 to Abu → same Wave now holds 30 orders assigned across 2 distinct Riders, confirming multi-Rider same-Wave with zero special split mechanism); **all-or-nothing UI reconciliation** (3 selected orders, 1 invalidated mid-flight → whole call rejected, zero mutation for the other 2, and a refresh-shaped query correctly identifies the exact one order that disappeared); **idempotency** (new key succeeds; exact retry with shuffled order input returns the identical result with zero new events; same key + changed payload → `idempotency key conflict` twice over, `run.built` count stays at 1; a new key against the already-built set correctly falls through to normal eligibility and is rejected as `orders no longer eligible`, never treated as a retry); single-order `assign_rider`/`reassign_rider` regression; business-isolation and direct-write regression spot checks — **all PASS**.

**Explicitly NOT verified by this file (nor by anything else this turn), and not claimed:** the actual PostgREST HTTP/JSON request boundary, real Supabase Auth bearer-token flow, real browser fetch/rendering, or any click-through interaction. This test connects directly to Postgres with simulated JWT claims — the same methodology already used for every staging acceptance run this session — which faithfully exercises the RPC/RLS contract layer but not the HTTP layer above it.

**Full regression on staging:** `s4_03_batch_1_contracts`, `s4_03_batch_3_rls`, `s4_03_rider_scope_fix`, `s4_04_batch_2_pod_path`, `s4_04_batch_3_token_lifecycle`, `s4_04_batch_5_rate_limit_infra/public_tracking_limit/tracking_pod_limit(10/10)/submit_rating_limit`, `s4_05_batch_1/3/4/6`, `s4_06_batch_1/2/3/4`, `validate_backend` — **all PASS**.

**Database integrity / residual check:** zero rows in `businesses`, `orders`, `riders`, `zones`, `delivery_sessions`; zero `run.built` events; zero fixture `auth.users` rows.

**Cleanup:** ephemeral credential securely deleted (`shred -u`), confirmed absent. `git diff --check` PASS (including the new untracked test file, confirmed via `git diff --no-index --check`).

**Real-browser status: still NOT performed** — no browser tooling connected in this environment. This limitation alone does not authorize starting S4-06.6, per explicit Founder instruction. Carried forward to the S4-15 RC browser acceptance gate.

### Safety confirmation
S4-06.5b not closed by this session (Founder-reserved). No S4-06.6 started. No Rider/Customer UI touched. No geographic intelligence or Zone Group/Cluster added. Legacy `reassign_rider` grant debt untouched. No Production access. No commit/push.

### S4-06.5b = LOCAL COMPLETE + STAGING CONTRACT-VERIFIED. Real browser click-through remains the one open item, deferred to S4-15. Awaiting Founder review/closure.

## 69. S4-06.6 Rider Multi-stop UI — LOCAL COMPLETE (frontend only, no staging this turn)

**S4-06.5b Founder-accepted and officially closed.** Implemented the real Rider Multi-stop UI (Plan Route → Start Pickup → Pickup Checklist → Start Delivery → Delivery Run) connecting S4-06.2/.4's backend contracts, exactly per the Founder-locked design. **Files modified: `rider/backend.js`, `rider/index.html` only.** No migrations, no other files.

**Genuine backend gap discovered during implementation, not fixed, reported plainly:** `delivery_sessions` has exactly one RLS policy (`sessions_vendor`, SELECT, gated by `is_business_member`) — confirmed empirically against the live local DB. A Rider is never a `business_member`, so a direct REST read of `delivery_sessions` returns zero rows for a Rider regardless of query filters. This blocks genuinely loading a real Wave **name** for the Rider (the Wave/session **grouping key** itself, `delivery_session_id`, is unaffected — it lives directly on `orders`, which Riders can already read). Handled honestly within this turn's authorization: `riderRuns()` groups strictly by `delivery_session_id` (real, always correct) and shows the Wave name only if genuinely loaded (currently always absent) — falling back to a factual `"N orders"` label, never a fabricated or placeholder name, matching the Founder's own "only show a Wave name if genuinely loaded" instruction. A minimal Rider-facing SELECT-only RLS policy on `delivery_sessions` (scoped to `exists (select 1 from rider_assignments where delivery_session_id = delivery_sessions.id and rider_id = current_rider_id())`) would close this gap in one small, additive migration — not implemented, since this turn's authorization was explicitly frontend-only and this is a schema/security change requiring its own authorization.

**Old mock behavior bypassed, not deleted:** the former sequential pickup wizard (`renderPickupScreen`, index.html) and the naive per-order `out_for_delivery` loop inside `startDelivery` (`rider/backend.js`) are both fully replaced at their call sites; `mockOrders` remains defined but is no longer used to seed initial state (`appState.orders` now starts empty, populated only by real hydration).

**Live fabrications surgically removed** (all previously reachable, not dormant code): hardcoded `"Session CF-S-0826"`, `"Pickup Window 11:30 AM"`, `"Est. Finish 2:30 PM"`, `"Distance 28.4 km"` (Home); per-stop fake ETA (`5+i*2`)/distance (`1.4+i*.2`) formulas (`stopDetailHTML`, the actually-live final redefinition in the `v421-runtime-corrective` script block — confirmed via `grep` that only superseded, non-executing earlier redefinitions of the same function name still contain the old formula); the hardcoded Rider marker (`[2.927,101.758]`) and fabricated route polyline (`L.polyline`) in `renderPremiumMap`; the hardcoded coordinate fallback (`?? 3.139`/`?? 101.6869`) in `mapOrder` (now `?? null`, genuinely absent when the order has none); `"Distance Covered 28.4 km"` in the session summary. The legacy `orders.delivery_sequence` column is no longer read anywhere (confirmed absent from both files) — `delivery_stops.sequence`/`sequence_locked_at` (embedded via the real S4-06.2 fields) is now the sole sequencing source.

**Real canonical hierarchy (Wave → this Rider's own assignments/stops, no new Run table):** `riderRuns()` groups `appState.orders` strictly by `deliverySessionId`; Home renders one card per Run, never merging two Waves' orders together (verified both statically and via an executable Node test asserting two distinct `delivery_session_id` values produce two distinct, non-overlapping groups). `activeRunOrders()`/`refreshActiveRunOrders()` scope every Plan-Route/Pickup-Checklist/Delivery-Run screen to `appState.activeRunSessionId` only, excluding declined assignments — the mechanism that prevents cross-Wave mixing throughout the whole flow, not just on Home.

**Accept Run / Decline Run (primary) + per-order (secondary, unbroken):** Home's per-Wave card shows `Accept Run`/`Decline Run` as the primary controls (`accept_run`/`decline_run`, session-scoped) when any of that Wave's own assignments are still pending; a "Review individual orders instead" link opens the existing per-order `accept_assignment`/`decline_assignment` path unchanged, in a new small fallback modal. A successful Accept Run advances directly into Plan Route (`enterRun(sessionId)`), matching the Founder's exact flow diagram; a successful Decline Run returns to Home. Mixed assignment states within one Wave are handled honestly — Accept Run acts on whatever subset of this Rider's own assignments in that Wave remain pending, per the real `accept_run` contract, with no client-side assumption.

**Plan Route:** shows all of this Rider's eligible stops in the active Wave with up/down reorder controls (a deliberate mobile-reliability simplification of "drag" using buttons rather than raw touch-drag gestures, explicitly flagged here rather than silently substituted) operating on `appState.planRouteOrder` — local planning state only. An explicit "Save Sequence" button calls `save_run_sequence(session_id, ordered_order_ids[])` with the **complete** array every time (never partial); on failure, `planRouteOrder` is explicitly reverted to the last backend-confirmed order (`refreshActiveRunOrders()`) and a factual error is shown — never claims saved. Once confirmed saved (`planRouteIsDirty()` false), a real slide-to-confirm "Start Pickup" control appears (a new, reusable `bindSlideToConfirm()` gesture binder, since this control's DOM is recreated on every render unlike the static Start Delivery slider).

**Start Pickup:** the slide calls `start_pickup_run(session_id)` exactly once — confirmed via static test — and, per the real contract's own idempotency (state-based: an existing `run.pickup_started` event for this Rider/session is detected server-side and never duplicated), never marks any order `picked_up` (confirmed: the handler's source contains no reference to `picked_up` at all). On success, enters the Pickup Checklist.

**Pickup Checklist:** replaced the sequential "Order N/12" wizard with an unordered grid — every eligible stop independently tappable, confirmed via `pickupOrderAction(orderId)` performing the exact existing two-hop transition (`ready_for_pickup` then `picked_up`, matching the prior wizard's own real logic, now reachable in any order) with an in-flight guard against duplicate taps. Shows a factual `"Picked up X / N"` counter. A partial two-hop failure (first hop succeeds, second fails, or vice versa) triggers a real refresh (`hydrateOrders()`/`refreshActiveRunOrders()`) rather than a local assumption — a retry safely resumes since both hops are independently idempotent no-ops once already reached.

**Start Delivery:** the former per-order `out_for_delivery` loop is removed entirely (confirmed: zero occurrences of `out_for_delivery` inside `startDelivery`'s own handler) — replaced with exactly one `start_run_delivery(session_id)` call. The dormant, fully-styled slide-to-confirm control (`#startSlider`, previously hidden behind a plain, ungated button) is now the live primary control; the plain button is removed. The real per-stop `out_for_delivery` transition now fires at "Start This Stop" (`startSelectedRouteStop`, per-stop, at the moment the Rider actually begins heading there) — matching the real lifecycle instead of a bulk upfront approximation.

**Delivery Run:** current stop is the earliest incomplete stop in `activeRunOrders()` (already sequence-sorted); `stopDetailHTML` shows only that stop's "Start This Stop" control (confirmed: `i===appState.currentStopIndex&&!o.delivered` gate) — matching the backend's own "complete earlier stop first" enforcement exactly, so the UI never offers an action the backend would reject. **Gapped-sequence display, proven both ways:** the array index (`i+1`) — not the raw, possibly-gapped persisted `delivery_stops.sequence` — is always the on-screen stop number; a Node-executable test constructs a real `1, 3` gapped sequence via `sortBySequence` and confirms it sorts correctly *and* that the persisted value `3` is never rewritten to `2`.

**Map/data capability (honest, no fabrication):** markers render only for orders with genuine non-null `lat`/`lng` (`renderPremiumMap`'s `geocoded` filter); if none of a Run's orders have real coordinates, an honest "Map unavailable" state is shown instead of fabricated geography (matches the Founder's explicit instruction and the confirmed absence of any pickup/vendor coordinate column anywhere in the schema). No route polyline, no Rider GPS marker, no ETA, no distance — all removed. `navigateExternal` uses real coordinates when present; when absent, passes the real delivery-address **string** to the external map app rather than a hardcoded fallback point — the external app resolves it, no client-side geocoding needed or attempted. The offline/tile-failure fallback now shows an honest "stop list only" message instead of the previous fabricated offline route SVG/labels/rider marker.

**Single-order Run:** confirmed no special-casing exists anywhere in the new code (`enterRun` contains no `orders.length===1`-style branch) — a one-order Run goes through the identical Accept Run → Plan Route → Start Pickup → Pickup Checklist → Start Delivery → Stop → POD lifecycle as any other.

**Multi-Rider isolation:** fully backend-enforced already (proven exhaustively in S4-06.4's own tests — `accept_run`/`decline_run`/`save_run_sequence`/`start_pickup_run`/`start_run_delivery`/`rider_transition` all scope via `current_rider_id()`); the UI adds no cross-Rider concept at all, so there is nothing for it to leak.

**POD regression:** `complete_delivery`/`uploadPod` call sites are byte-identical to before this batch — confirmed via static test.

**Offline/error/recovery:** every new action handler follows the same pattern — real RPC call, real refresh, factual error surfaced via `showToast` on failure, never an optimistic local success (confirmed for every new handler both statically, via ordering assertions, and executably, via the Node harness actually invoking each handler against a fake RPC layer and asserting no dangling function references or premature success signaling).

**Cross-app consistency finding (informational, not a defect):** Rider's existing `uiStatus()` folding of `arrived` into a continued `'out_for_delivery'` label is already consistent with Vendor's own `statusToUi` mapping (from S4-06.5 work), which folds both `out_for_delivery`/`arrived` into `'delivering'` — both apps already agree `arrived` is not a separate customer-facing milestone. No correction identified as necessary.

**Verified — two independent test layers, real click-through NOT performed (no browser tooling in this environment):**
- **Executable logic** (`tests/s4_06_batch_6_rider_multistop_logic.js`, Node, loads the real `rider/backend.js` in a minimal stubbed environment — no DOM needed for the functions under test): 24 tests — real field extraction confirmed absent of legacy/fabricated values, `riderRuns` Wave-grouping isolation, `sortBySequence` gap-preserving ordering, `activeRunOrders` cross-Wave/declined exclusion, and — critically — **every new action handler actually invoked end-to-end against a fake successful RPC layer** (`saveSequenceAction`, `startPickupRunAction`, `pickupOrderAction`, `acceptRunAction`, `declineRunAction`, `startDelivery`, `startSelectedRouteStop`, `arriveAtStop`/`yesUsePhoto`) — this exact mechanism caught and led to fixing a real bug during implementation (see below) — **all 24 PASS**.
- **Static/structural** (`tests/s4_06_batch_6_rider_multistop_wiring.py`): 45 assertions covering Run grouping, Accept/Decline Run wiring, Plan Route (complete-array save, local-vs-authoritative distinction, failure recovery), Start Pickup, Pickup Checklist, Start Delivery, Delivery Run (display position vs. persisted sequence, current-stop-only actionability), gapped-sequence non-renumbering, single-order-Run non-special-casing, map/data honesty, Home summary fabrication removal, offline/error ordering, POD regression, and scope boundaries — **all 45 PASS**.

**One real bug found and fixed during implementation, reported plainly:** the first draft of `enterRun`/`saveSequenceAction` called a function named `renderPlanRoute()`, which was never defined (Plan Route rendering lives inside the mode-aware `renderRouteOverview()`). A pure string/regex-based static test would not have caught this — it was caught specifically by the Node harness's executable invocation of `saveSequenceAction` against a fake successful RPC, which threw `ReferenceError: renderPlanRoute is not defined`. Fixed by correcting both call sites to `renderRouteOverview()`.

**Full regression:** the complete accumulated static/UI suite (169 tests across `s4_04_batch_4_edge_hardening`, `s4_05_batch_2_vendor_approval_wiring`, `s4_05_batch_5_rider_assignment_wiring`, `s4_06_batch_5b_vendor_run_builder_wiring`, `s4_06_batch_6_rider_multistop_wiring`, `test_rider_logout_fix`, `test_vendor_protected_cutover`, `test_environment_guard`) plus the Node logic suite — **all PASS**. **Two more pre-existing tests found stale by this batch's legitimate forward progress, fixed and reported plainly**, both in `tests/s4_05_batch_5_rider_assignment_wiring.py`: `test_assignment_status_read_from_real_backend_embed_not_mock` asserted the OLD, narrower `delivery_stops` embed shape (missing the new real `sequence`/`sequence_locked_at` fields this batch legitimately added) — updated to the current superset shape, the substantive assertion (assignment status read from the real embed, never mock) unchanged; `test_view_assignment_excludes_declined_orders` referenced the now-renamed `viewAssignment()` (replaced by `enterRun(sessionId)`) — updated to check the same exclusion logic at its new home in the shared `activeRunOrders()` helper. Full local DB-level regression (S4-03/.05/.06 contract tests, unaffected since this batch made no migration/schema change) spot-checked — **all PASS**, confirming zero collateral impact.

**`git diff --check` PASS**, including both new untracked test files (confirmed via `git diff --no-index --check`).

**Not implemented this turn (explicitly out of scope, confirmed absent):** no S4-06.7, no S4-08 implementation, no Vendor/Customer UI files touched, no notification provider integration, no fake ETA/distance/route-optimization claims, no unrelated security cleanup — the legacy `reassign_rider` `anon` EXECUTE grant debt remains tracked and untouched.

**Staging:** NOT accessed this turn (explicitly out of scope — local-only authorization). **Real browser click-through:** NOT performed (no browser tooling connected in this environment) — carried forward to the existing S4-15 RC browser acceptance gate, consistent with precedent (Sections 47, 52, 67 record the equivalent gap for the Vendor-approval, Rider-accept/decline, and Vendor-Run-Builder UI batches).

### Safety confirmation
No S4-06.7 started. No S4-08 implementation. No Vendor UI touched. No Customer UI touched. No notification provider integration. No fake ETA/distance/geographic intelligence added. Legacy `reassign_rider` `anon` grant debt untouched. No Production access. No staging access. No commit/push. `git diff --check` PASS.

### S4-06.6 = LOCAL COMPLETE (frontend). Real browser click-through and staging acceptance remain open, deferred to S4-15/a future staging turn. The `delivery_sessions` Rider-read RLS gap is tracked, not fixed. Awaiting Founder review. *(Superseded by Section 70 — the RLS gap is now corrected as S4-06.6a.)*

## 70. S4-06.6a Rider Session Read Access — LOCAL COMPLETE

**Root cause:** `delivery_sessions` carried exactly one RLS policy (`sessions_vendor`, SELECT, gated by `is_business_member`) since S4-05.3. A Rider is never a `business_member`, so a direct REST read returned zero rows for any Rider regardless of query filters — confirmed empirically against the live local DB before any fix was written. This blocked genuinely loading a real Wave **name** for the Rider UI (S4-06.6); the grouping key itself, `delivery_session_id`, was unaffected since it lives on `orders`, which Riders can already read.

**Schema/column exposure review (performed before writing any policy):** `delivery_sessions` carries only `business_id, name, delivery_date, status, started_at, completed_at, created_at, updated_at` — no financial, internal, or Vendor-private field exists anywhere on this table. Full-row SELECT was confirmed safe for a Rider who genuinely has an assignment in that session; no column redaction or narrower view was required.

**Authorization model:** a Rider may SELECT a `delivery_sessions` row iff at least one of their own `rider_assignments` rows references it — checked via a new, narrowly-scoped SECURITY DEFINER helper, `is_session_rider(p_delivery_session_id uuid)`, mirroring `is_business_member`'s exact established style (`language sql stable security definer`) rather than an inline subquery, so the predicate never depends on `rider_assignments`'s own RLS policy shape remaining exactly as it is today. Not "recursive" in the problematic sense — it's a normal, already-precedented pattern (matching how `is_business_member` itself queries a different table, `business_members`, from within many other tables' policies) — the referenced table is never the same table the new policy is defined on.

**Migration:** `202608280005_s4_06_batch_6a_rider_session_read_access.sql` — purely additive: one new function (`is_session_rider`), one new SELECT policy (`sessions_rider`) on `delivery_sessions`. `sessions_vendor` untouched. No INSERT/UPDATE/DELETE policy added — writes remain exclusively through `create_delivery_session`/`update_session_status`, unaffected. Grants: `is_session_rider` granted broadly (`public, anon, authenticated`), deliberately matching `is_business_member`/`current_rider_id`'s own grant scope rather than the narrower `authenticated`-only pattern used for mutating RPCs — reasoned explicitly in the migration's own comment: restricting EXECUTE to `authenticated` would make RLS policy *evaluation itself* raise a permission error for an anon query touching `delivery_sessions` (since Postgres must evaluate every policy expression regardless of which one ultimately applies), which would be a functional regression for the pre-existing `sessions_vendor` policy's own correct anon behavior (silently zero rows, not an error) — not merely a hypothetical concern, but confirmed by first tracing through Postgres's actual multi-policy OR-evaluation semantics.

**Rider A/Rider B isolation evidence (new `tests/s4_06_batch_6a_rider_session_read_access.py`, rollback-only):** Ali (assigned in "Lunch Wave") can SELECT it and reads the real name; Ali cannot SELECT Abu's same-business "Unrelated Wave" (zero rows) — proving same-business unrelated-session denial; Ali cannot SELECT Business B's session — cross-business denial; Abu has symmetric access (sees only his own Wave, denied Ali's and Business B's); Vendor Owner A's pre-existing full-business visibility is unchanged (`sessions_vendor` untouched); Vendor Owner B remains denied Business A's session (unchanged cross-business isolation); anon sees zero rows both for a targeted id lookup and an unscoped table scan; Rider direct INSERT is rejected, direct UPDATE/DELETE affect zero rows — all **PASS**.

**One real test-harness bug found and fixed during this same test's authoring, reported plainly:** the first draft's `actor()` helper only set JWT claims when a real `user_id` was supplied, leaving the *previous* actor's `request.jwt.claim.sub` value stale (transaction-scoped, not statement-scoped) when switching to `role='anon'` with `user_id=None` — meaning the anon check was accidentally still evaluating as the previous Rider's identity, not a genuine anonymous request. Caught immediately (the unscoped anon table-scan assertion failed on the first run), root-caused via `auth.uid()`'s actual source (`coalesce(nullif(current_setting('request.jwt.claim.sub'),''),...)`), and fixed by explicitly clearing the sub claim to an empty string (which `nullif`/`coalesce` correctly resolve to a genuine SQL NULL, confirmed not to raise a UUID-cast error) whenever no real user is supplied.

**Real Wave-name UI wiring (`rider/backend.js`):** new `sessions()` read (`/rest/v1/delivery_sessions?select=id,name`, no manual filter needed — RLS alone now correctly scopes the result to exactly this Rider's own relevant sessions) fetched inside `hydrateOrders()`, defensively wrapped (never blocks/throws hydration if the read fails) into `appState.sessionNames`; `riderRuns()` now surfaces `waveName` from this real map when present, staying `null` (never a placeholder/fabricated name) when a session's name genuinely isn't in the map — the existing S4-06.6 factual `"N orders"` fallback in `renderHome` handles the `null` case unchanged, exactly as it already did before this correction.

**Focused tests:** the new `s4_06_batch_6a_rider_session_read_access.py` (11 assertions, all PASS per above) plus two new Node logic assertions (`riderRuns surfaces the real Wave name when genuinely loaded`, `riderRuns never fabricates a Wave name when genuinely unavailable`) and two more (`sessions() reads delivery_sessions relying on RLS scoping`, `hydrateOrders never blocks or throws on a session-read failure`) added to `tests/s4_06_batch_6_rider_multistop_logic.js` — Node suite now 28 tests, all PASS.

**Full regression after a clean `supabase db reset --local`** (all 19 migrations replayed in strict order, including the new `202608280005`; one transient `LegacyHealthCheckTimeoutError` on the storage container during reset, diagnosed as infra noise — confirmed via `docker ps` that all containers including storage recovered healthy, and via direct query that `is_session_rider`/`build_rider_run` both existed post-reset, proving the actual migration replay succeeded despite the unrelated health-check timeout, not silently worked around): every S4-01 through S4-06.6a DB-level test file (21 files) plus the full static/UI suite (139 Python tests across `s4_04_batch_4_edge_hardening`, `s4_05_batch_2_vendor_approval_wiring`, `s4_05_batch_5_rider_assignment_wiring`, `s4_06_batch_5b_vendor_run_builder_wiring`, `s4_06_batch_6_rider_multistop_wiring`, `test_rider_logout_fix`, `test_vendor_protected_cutover`) plus the 28-test Node logic suite — **all PASS**.

**Residual fixtures:** zero rows in `businesses`/`orders`/`riders`/`delivery_sessions` after the full suite, confirmed via direct query.

**`git diff --check` PASS**, including the new untracked migration and test file (confirmed via `git diff --no-index --check`).

**Not implemented this turn (explicitly out of scope, confirmed absent):** S4-06.6 not closed, no S4-06.7, no broadened Rider access to unrelated/every-business sessions, no Rider write access added, no Vendor/Customer UI changes, no fix to the separately-tracked legacy `reassign_rider` `anon` EXECUTE grant debt, no S4-08 work.

**Staging:** NOT accessed this turn (explicitly out of scope — local-only authorization).

### Safety confirmation
S4-06.6 not closed by this session (Founder-reserved). No S4-06.7 started. No broadened Rider session visibility beyond genuinely-relevant sessions. No Rider write access added. No Vendor/Customer UI touched. Legacy `reassign_rider` grant debt untouched. No Production access. No staging access. No commit/push. `git diff --check` PASS.

### S4-06.6a = LOCAL COMPLETE. The genuine backend authorization gap discovered during S4-06.6 is now corrected and locally verified. S4-06.6 itself remains open pending Founder closure (real browser click-through and staging acceptance still outstanding for both S4-06.6 and S4-06.6a). Awaiting Founder review.

## 71. S4-06.6 / S4-06.6a — Founder-Authorized Staging Acceptance — PASS

**Founder authorized** resuming the S4-06.6/S4-06.6a staging acceptance from the fail-closed identity check, scoped to applying only `202608280005`.

**Pre-flight (all independently re-verified this turn, not merely trusted):** ephemeral credential `stat`-confirmed present (18 bytes, `0600`, `cefflo:cefflo`) at `/tmp/cefflo-staging-db-password.ephemeral`. Fail-closed identity check PASS: `environment=staging`, `project_ref=tomvvmwktehexwhktenw`, `database_host=aws-0-ap-south-1.pooler.supabase.com`, `mutating=false`. Migration ledger read live: 18 applied, exact match to local minus `202608280005` — confirmed the ONLY pending migration, matching the Founder's stated expectation exactly.

**Migration applied:** `202608280005` (`is_session_rider` helper + `sessions_rider` SELECT policy) — one transaction, mutating-guard validated (`CEFFLO_DISPOSABLE_TARGET=1`/`CEFFLO_ALLOW_MUTATING_TESTS=1`), committed, ledger row inserted (statement text split manually at real top-level boundaries after a naive `;`-split attempt failed on a semicolon inside a header comment — caught cleanly, rolled back automatically, re-applied correctly on the second attempt). Post-apply ledger: 19/19, exact match to local.

**Acceptance:** `tests/s4_06_batch_6a_rider_session_read_access.py` — PASS live on staging (full A–P isolation matrix). Regression: `validate_backend.py` → `s4_06_batch_1` → `_2` → `_3` → `_4` → `_5a` → `_5b_staging_contract` → `_6a` → `validate_backend.py`, all PASS, rollback-only, zero commits from the suite itself.

**Cleanup:** zero residual fixtures (checked directly). Ephemeral credential `shred -u`'d, confirmed absent via `stat` (nonzero exit). `git diff --check` PASS. Nothing staged/committed/pushed.

**Founder closure (same session, next turn):** S4-06.6 and S4-06.6a declared **CLOSED** by Founder. Real-browser click-through explicitly carried forward to S4-15 RC acceptance (unchanged — never claimed done).

### Safety confirmation
No Production access. No commit/push. S4-06.7 not started this turn (design-only next).

## 72. S4-06.7 — Full Integration Design / Gap Reconciliation — FOUNDER APPROVED

**Scope:** Founder authorized S4-06.7 as design/gap-reconciliation ONLY (no implementation) — a full end-to-end architecture trace of Vendor → Wave → Rider Run → Stops → Customer lifecycle against the canonical 20-order/Lunch-Wave/10-Ali+10-Abu scenario, reconciling every S4-06.1–.6a component.

**Method:** direct code trace only (migrations + `vendor`/`rider`/`customer` `backend.js`/`index.html` + `tracking-pod` Edge Function) — no staging/Production access, no browser tooling used or claimed.

**Genuine gaps found and reported (Founder decisions requested for each):**
- **P1 (Vendor observability):** `hydrateCanonicalWorkspace()` hardcoded `state.riderAssignments = []`/`state.deliveryStops = []` even in real/remote mode — Vendor had no way to distinguish "Rider hasn't responded" from "Rider declined" (orders.assigned_rider_id is never cleared by decline), no Wave/assignment-state/pickup-progress visibility anywhere in the main Vendor UI.
- **P2 (sequence lock):** `rider_transition`'s "complete earlier stop first" check only activated once already locked — nothing required `start_run_delivery` to have been called at all before a session-scoped stop could move `picked_up → out_for_delivery`; a UI-only convention, not an RPC-level invariant.
- **P3 (Customer Tracking):** hardcoded fake `18 mins` ETA (`heroEta`/`TRACKING_DATA.etaMinutes`) never overwritten by real data on any real customer's screen; `created`/`issue`/`cancelled` all silently fell through to "Picked Up" (statusMap only covered 5 of 8 real `delivery_status` values).
- **P4 (Wave lifecycle):** `delivery_sessions.status` never auto-transitioned — stayed `planned` forever unless a Vendor manually called `update_session_status`; no `run.completed`-equivalent signal.
- **P5 (existing-Wave picker):** `runBuilderExistingWaves()` filtered only by status, never by `delivery_date` — a stale Wave from another day stayed selectable indefinitely.
- **P6 (Vendor realtime):** `subscribe()` only listened on `orders`, missing assignment/stop-level changes.
- **P7 (events_rider RLS):** session-level `delivery_events` (`run.built`, `run.pickup_started`, etc.) are unreadable by any Rider (`NULL order_id` never matches the `IN` policy) — inert today, same class of bug as the already-fixed S4-06.6a gap, but nothing currently reads it.
- **C1 (Rider Route Overview):** flagged as reading raw cross-Wave `appState.orders` instead of the Wave-scoped list — **later found, during S4-06.7 implementation, to be a false positive**: a third, even-later `renderRouteOverview` override (the "v421-runtime-corrective" script block) already correctly used `activeRunOrders()`. Corrected in Section 73 below; recorded here for an accurate paper trail.

**Founder decisions locked (recorded verbatim, driving Section 73's implementation):** P1 minimal factual Run progress only (no new monitoring product, no ETA, no route intelligence, no new major Vendor page) · P2 required, additive, must preserve single-order/legacy compatibility · P3 exact 7-state factual mapping specified, issue/cancelled must never fall back to Picked Up · P4 auto planned→active on real execution start, auto→completed only when every relevant order in the *whole* Wave (not just one Rider) is delivered, no new Run table · P5 filter by `delivery_sessions.delivery_date`, no timezone inference · P6 narrowly scoped to what P1 needs · P7 **DEFER** (do not touch `events_rider` RLS this sprint).

**Staging/Production:** NOT accessed (design-only turn).

### Safety confirmation
No implementation this turn. No migration. No staging/Production access. No commit/push. Stopped for Founder review per explicit instruction.

## 73. S4-06.7 Batch 1 — Local Implementation (P1–P6 + mandatory fixes) — LOCAL COMPLETE

**Founder authorized LOCAL IMPLEMENTATION ONLY** of the Section 72 decisions (P1–P6; P7 stays deferred) plus five mandatory no-decision-needed fixes, against the canonical 20-order/Lunch-Wave/Ali+Abu scenario. No staging/Production access, no commit/push, S4-07 not started.

**Migration:** `supabase/migrations/202608290001_s4_06_7_batch_1_sequence_lock_and_wave_lifecycle.sql` (local only, not applied to staging).
- **P2:** `rider_transition` gets one new additive check — a session-scoped stop (`rider_assignments.delivery_session_id is not null`) must already have `sequence_locked_at` set before `out_for_delivery`/`arrived` is permitted; standalone (no-session) orders are a no-op, exactly preserving legacy/single-order compatibility. Every other existing check preserved byte-for-byte.
- **P4:** two new internal-only (`revoke all ... from public, anon, authenticated`) helpers — `mark_session_active_if_planned` (called from `start_pickup_run`; `planned→active`, idempotent, one `session.status_changed`/`trigger:auto` event) and `complete_session_if_all_delivered` (called from `complete_delivery`; locks the session row `FOR UPDATE` first to serialize simultaneous last-stop completions across Riders; "relevant" = attached to the session and not declined/cancelled, LEFT JOIN so an attached-but-never-assigned order still correctly blocks completion; `active/planned→completed` only once every relevant order in the *entire* Wave — not just the calling Rider's own stops — is delivered). No new event type invented; no new Run/session table.
- **Correction during implementation:** the first draft of the `complete_delivery` replacement was sourced from the wrong (foundation-era) version — missed that `202608270004` (rider-scope fix: `<>` → `is distinct from`) and `202608270006` (token lifecycle: `update tracking_tokens set expires_at=now()+interval '48 hours'`) had already superseded it. Caught by full local regression (`s4_03_rider_scope_fix.py` and `s4_04_batch_3_token_lifecycle.py` both failed), root-caused via `pg_get_functiondef` against the pre-migration deployed function, corrected to match the true latest canonical text exactly plus the two new P2/P4 lines. Lesson: `grep` for a function's definition must confirm it's finding the *last* `CREATE OR REPLACE`, not just *a* definition.

**Mandatory fixes:**
1. Rider Route Overview — investigated fully; the live definition was already correct (Section 72's C1 was a false positive, not a real bug). No code change.
2. Customer Tracking: removed `heroEta`/`TRACKING_DATA.etaMinutes`/the `18 mins` markup entirely from `customer/index.html`; `estimatedArrival`/`heroArrivalTime` (the genuinely real, null-safe field) is untouched and remains the only arrival-time signal.
3. Customer status mapping: `TRACKING_STATUS` extended to 7 states (`order_confirmed`, `preparing`, `picked_up`, `on_the_way`, `delivered`, `issue`, `cancelled`) with the Founder's exact copy; `customer/backend.js`'s `statusMap` now covers all 8 real `delivery_status` values explicitly — no fallback path resolves to `picked_up` except `picked_up` itself.
4. Vendor dashboard grouping: `getCurrentDeliveries()`'s group key now includes `deliverySessionId`; also fixed the shared root cause (`sessionOrders()`/`activeDeliverySession()` only ever resolved ONE session) via a new `todaysRelevantOrders()`/`todaysOpenSessionIds()` helper, used by both `getCurrentDeliveries()` and `getTodayDashboardMetrics()` — a second same-day Wave was previously invisible to the dashboard entirely, not merely mergeable.
5. `runBuilderExistingWaves()` now filters by `s.deliveryDate===operationalDateKey()` in addition to status.

**P1 (Vendor observability):** `vendor/backend.js` — new `listRiderAssignments()` (real nested REST embed: `rider_assignments?...&select=id,rider_id,delivery_session_id,status,accepted_at,delivery_stops(id,order_id,status,sequence)`, permitted by the existing unmodified `assignments_vendor`/`stops_vendor` RLS) replaces the hardcoded empty `state.riderAssignments`/`state.deliveryStops`. `vendor/index.html` — new `computeRunProgress()` groups by `(session, rider)`, derives assignment state (Pending/Accepted/Picking Up/Delivering/Delivered/Declined)/pickup progress/delivery progress from real data only (no ETA, no route intelligence); rendered as a compact "Run Progress" section on the existing Dashboard (no new page).

**P6 (Vendor realtime):** `subscribe()` extended to `rider_assignments`/`delivery_stops` (business-scoped) alongside the existing `orders` listener. Also discovered and fixed: `subscribe()` was exported but **never actually called anywhere** — wired it up in the post-hydrate `restore()` callback (subscribes once, after the first hydrate resolves the real `businessId`).

**P7:** untouched, per explicit Founder DEFER.

**Tests added:**
- `tests/s4_06_7_batch_1_sequence_lock_and_wave_lifecycle.py` (rollback-only, local): unlocked multi-stop rejection, locked success + retry idempotency, exact-Rider isolation, Wave auto-activate (idempotent across both Riders' own `start_pickup_run` calls), Ali-finishes-alone does NOT complete a Wave Abu still shares, final relevant order completes the Wave exactly once (single auto-event), an unrelated same-day Dinner Wave stays untouched throughout, and standalone/legacy single-order compatibility. All PASS.
- `tests/s4_06_7_batch_1_frontend_wiring.py` (static/structural, 16 checks): Rider Route Overview Wave-isolation regression guard, all 8 Customer status mappings + fallback-never-picked-up, zero fabricated ETA, Vendor multi-Wave grouping key, existing-Wave date filter, real assignment/progress hydration, realtime table scope + actual invocation. All PASS.
- `tests/s4_05_batch_6_full_integration.py` updated (pre-existing S4-05-era test, predates S4-06 entirely): its single session-attached order now correctly goes through `save_run_sequence`/`start_pickup_run`/`start_run_delivery` before the delivery-phase transitions (required by the new P2 invariant, since the order IS session-scoped even though the session has only one stop); its hardcoded event-sequence assertion updated to include the two new `run.sequence_saved`/`run.sequence_locked` events and the two new `session.status_changed`(`trigger:auto`) events (active, then completed — this session's one order is also its last, so completing it also completes the Wave). This is an intentional, Founder-approved behavior change, not a bug fix.

**Full regression (fresh `supabase db reset --local`, all 20 migrations replayed in order):** every S4-01→S4-06.7 DB-level script (23 files, including this turn's new one) PASS. 141 static/structural `unittest` checks (7 files, including this turn's new frontend file) PASS. 28-check Node logic suite (`s4_06_batch_6_rider_multistop_logic.js`) PASS unchanged. 39 S4-04 Edge-Function-adjacent static/Node checks (CORS logic, rate-limit window math, on-demand-refresh policy) PASS. `s4_06_batch_5a_build_rider_run_concurrency.py` (real commits, own cleanup) PASS. `tests.test_environment_guard` (30 checks) PASS.

**Residual fixtures:** zero (`businesses`/`auth.users` test-pattern counts, `delivery_sessions` count all checked directly post-suite).

**Staging/Production:** NOT accessed this turn (explicitly out of scope — local-only authorization). Local Supabase stack (`npx supabase start`/`db reset --local`) used throughout; no staging credential touched.

### Safety confirmation
No staging access. No Production access. No commit/push. No S4-07 started. No route optimization/ETA engine/Rider GPS/geo clustering/notification provider/S4-08/Staff Workspace/Helper Pool/marketplace behavior introduced. `events_rider` RLS untouched (P7 deferred). Legacy `reassign_rider` `anon` grant debt untouched. `git diff --check` PASS.

### S4-06.7 Batch 1 = LOCAL COMPLETE. Not staged, not closed by this session (Founder-reserved). Awaiting Founder review.

## 74. S4-06.7 Batch 1 — Founder-Authorized Staging Acceptance — PASS

**Founder authorized** proceeding from S4-06.7's local implementation (Section 73) to staging verification, applying only `202608290001`. First attempt this turn was correctly blocked at the credential gate (ephemeral file absent — stopped immediately, no staging identity/ledger check attempted, per fail-closed discipline); resumed cleanly once the Founder restored it.

**Pre-flight (all independently re-verified, not merely trusted):** ephemeral credential `stat`-confirmed present (17 bytes, `0600`, `cefflo:cefflo`). Fail-closed identity check PASS: `environment=staging`, `project_ref=tomvvmwktehexwhktenw`, `database_host=aws-0-ap-south-1.pooler.supabase.com` (Mumbai pooler), `mutating=false`. Migration ledger read live: 19 applied, exact match to local minus `202608290001` — confirmed the ONLY pending migration.

**Migration applied:** `202608290001` (sequence-lock invariant + Wave auto-lifecycle helpers) — 7 top-level statements, split with a dollar-quote-aware splitter (the naive `;`-split that broke on `202608280005` was deliberately not repeated; this migration's statement bodies are large enough that a wrong split would have silently corrupted a function body instead of erroring, so a real splitter was used and dry-run-counted before executing). One transaction, mutating-guard validated, committed, ledger row inserted. Post-apply ledger: 20/20, exact match to local. Live-verified: both new internal helpers exist, `rider_transition` carries the new lock-gate text, `complete_delivery` calls the completion helper.

**Live acceptance (all items 1–14 from the Founder's list), via the full regression run below:**
1–4 (sequence-lock invariant, unlock rejection, locked success, retry idempotency, exact-Rider isolation), 5–6 (multi-Rider same-Wave — Ali finishing alone does not complete the Wave, completes only on Abu's final delivery, exactly once; `planned→active` on `start_pickup_run`), 7 (unrelated Dinner Wave untouched) — all proven live by `s4_06_7_batch_1_sequence_lock_and_wave_lifecycle.py`, PASS.
4 (standalone/legacy compatibility) — same file, PASS, plus re-confirmed by `s4_05_batch_6_full_integration.py` (updated for the new invariant, PASS) and `s4_03_rider_scope_fix.py` (PASS).
8–9 (Vendor Run Progress hydration / Wave-aware grouping) — contract-level: `assignments_vendor`/`stops_vendor` RLS (unmodified) proven live-compatible via `s4_06_batch_5b_vendor_run_builder_staging_contract.py` PASS; the grouping-key fix itself is frontend JS (already static-verified locally in Section 73 — not re-verified here, no staging DB surface to check).
10 (existing-Wave date filter) — frontend JS, not staging DB surface; unaffected by the migration.
11 (Customer Tracking honesty) — frontend-only, unaffected by the migration; not re-verified against a live DB.
12–13 (business/exact-Rider isolation, POD privacy, tracking-token boundary) — `s4_03_rider_scope_fix.py`, `s4_04_batch_3_token_lifecycle.py` PASS live (this is also the exact pair that caught the pre-staging local regression — see Section 73 — now confirmed genuinely fixed on staging, not just locally).
14 (Run Builder/sequencing/Accept-Decline/reassignment/zones/S4-06.6a) — `s4_06_batch_1` through `_4`, `_5a`, `_6a` all PASS live.

**Regression run (all rollback-only, real network round-trips to `aws-0-ap-south-1.pooler.supabase.com`, 8–30s each):** `validate_backend.py` (open) → `s4_06_7_batch_1_sequence_lock_and_wave_lifecycle` → `s4_05_batch_6_full_integration` → `s4_06_batch_1` → `_2` → `_3` → `_4` → `_5a` → `_5b_staging_contract` → `_6a` → `s4_03_rider_scope_fix` → `s4_04_batch_3_token_lifecycle` → `validate_backend.py` (close). All 13 PASS. The real-commit concurrency test (`s4_06_batch_5a_build_rider_run_concurrency.py`) was deliberately NOT run against staging (matches the precedent from the S4-06.6a staging turn — real commits with a separate cleanup step are a materially different risk profile from rollback-only tests; not requested for this acceptance).

**Residual fixtures:** zero (`auth.users`/test-pattern `businesses`/test-named `delivery_sessions` counts all checked directly).

**Real-browser status: NOT PERFORMED** — remains S4-15 carry-forward, unchanged.

**Cleanup:** ephemeral credential `shred -u`'d, confirmed absent via `stat` (nonzero exit). `git diff --check` PASS. `git diff --cached --check` PASS. Nothing staged/committed/pushed.

### Safety confirmation
No Production access. No commit/push. S4-07 not started. S4-06.7 not closed by this session (Founder-reserved).

### S4-06.7 Batch 1 = STAGING-VERIFIED. Awaiting Founder review/closure.

## 75. S4-06.7 / S4-06 — Founder Closure, and S4-07 Design/Existing-System Reconciliation — FOUNDER APPROVED

**S4-06.7 CLOSED by Founder** (same session, next turn after Section 74's staging verification) — real-browser click-through carried to S4-15 RC, unchanged. **S4-06 — Batching / Zones / Routing / Multi-Drop — CLOSED IN FULL.**

**S4-07 (Trusted Team Invite/Join/Membership) reconciliation, design-only, no implementation:** full inventory of the existing foundation against `S4-02_PERMISSION_BACKEND_CONTRACT_DESIGN.md` (canonical Owner/Operator-Staff/Rider/Customer role model, `member_role` enum is exactly `('owner','operator')`, `invite_team_member` reserved-but-undesigned, `business_members` has zero write RLS today — safe-by-default), `05_DECISIONS.md` D-03 (vendor-owned trusted Rider teams, one Rider Auth identity may belong to multiple Vendor teams), and the gap report's S4-07 acceptance gate ("expiring single-use invite binds identity/team; cross-team access denied"). Key findings: `update_team_member` exists (Owner-only, last-owner-protected) but is **never called from any UI**; invitation creation is entirely **MISSING** (no table, no RPC); the existing "Invite Rider" UI is **100% wired to the deprecated mock engine**, never a real backend contract; the Rider public "Apply now" self-signup screen (rider/index.html) is a **CONFLICT** — structurally an open-marketplace flow, disconnected from any backend, contradicting D-03, not to be treated as canonical. Full A-U reconciliation delivered (architecture, token model, role/permission reconciliation, Owner-approval alternatives, existing/new-user flows, multi-business finding, Rider-relationship finding, minimal UI, lifecycle, audit model, RLS, concurrency model, exact backend/frontend changes, tests, exclusions, Founder decisions needed).

**Founder decisions locked (driving Section 76):** Staff/Team = Option A (invite + auth + email match → active immediately, no second approval) · Rider = Option B (accept → `riders` row `pending` → Owner-only approval → `active`) · Owner-role invitations permitted, Owner-only to create, role never client-controlled · mandatory email identity binding for both paths, fail-closed on mismatch · token model = existing `tracking_tokens` precedent exactly (32-byte/sha256/raw-once) · `team_invitations` (Staff/Owner/Operator) and a structurally separate Rider invitation path, sharing only the token engine · Rider approval Owner-only (not assumed from general Rider-management authority) · new shared minimal invite landing surface, NOT inside the main Vendor app · 7-day fixed expiry · explicit carry-forwards: `events_rider` RLS, legacy `reassign_rider` grant debt, S4-15 real-browser acceptance, Helper Pool/Staff Workspace/S4-08 all excluded.

**Staging/Production:** NOT accessed (design-only turn).

### Safety confirmation
No implementation this turn. No migration. No staging/Production access. No commit/push.

## 76. S4-07 Local Implementation (Batches 1, 3, and the minimal UI/shared-invite surface) — LOCAL COMPLETE

**Founder authorized LOCAL IMPLEMENTATION ONLY** of Section 75's locked decisions. No staging/Production access, no commit/push, S4-08 not started.

**Migrations (local only):**
- `202608290002_s4_07_batch_1_team_invitation.sql` — `team_invitations` table (Owner-only SELECT RLS, no direct write policy at all — RPC-mediated only, matching `business_members`' own deny-by-default precedent) + `create_team_invitation` (Owner-only, every role including `owner` itself — reasoned as reinforcing, not loosening, `update_team_member`'s existing Owner-only "Team management" boundary, since the Founder's decision only explicitly carved out the Owner-role sub-case) + `resolve_team_invitation` (anon-safe, never returns `invited_email`/hash) + `accept_team_invitation` (role/business come only from the server-side row, never a client parameter; email-bound with case-insensitive normalization, fail-closed; idempotent for the exact same accepting identity, rejects a different identity reusing an already-accepted token) + `revoke_team_invitation`. Folded in the pre-existing `update_team_member` audit gap (Founder-explicit, Section 15) — it previously wrote no event at all; now logs `membership.role_changed`/`membership.status_changed`, every existing check preserved byte-for-byte.
- `202608290003_s4_07_batch_3_rider_invitation.sql` — structurally separate `rider_invitations` table (any-business-member SELECT, matching `riders_vendor`'s own "any member" precedent) + `create_rider_invitation` (any business member — reasoned as the modern replacement for the already-locked "Rider create/onboard: ALLOW for both Owner and Operator/Staff," collects name/phone since `riders.name`/`phone` are `NOT NULL`/business-unique and an invite alone can't supply them) + `resolve_rider_invitation` (anon-safe) + `accept_rider_invitation` (email-bound; creates the `riders` row at `status='pending'`, never active) + `approve_pending_rider` (new, Owner-only, the more sensitive gate the Founder explicitly added) + `revoke_rider_invitation`. "Reject a pending Rider" deliberately reuses the existing `deactivate_rider` RPC unchanged (it already sets any rider to `inactive`, Owner-only, no precondition on current status) — no redundant RPC added. Folded the matching `deactivate_rider` audit gap too (`rider.deactivated`, `metadata.previous_status` distinguishing a true deactivation from rejecting a still-pending Rider).

**Discovered schema conflict, NOT silently resolved:** `riders.auth_user_id` carries a bare `unique` constraint — this structurally **forbids** the same auth identity from ever holding more than one `riders` row across ANY business, directly contradicting the locked D-03 decision ("one Rider Auth identity may belong to multiple Vendor teams"). `accept_rider_invitation` does not work around this; a genuine cross-business attempt is caught and surfaced as a clean `'this identity is already linked to a different Rider profile'` error rather than a raw constraint violation or a silent duplicate. Loosening/removing that constraint is a distinct architectural decision, explicitly left for the Founder, not decided here. `current_rider_id()`'s own `LIMIT 1` (no `ORDER BY`) is a related, pre-existing, unfixed single-active-session assumption, noted for the same reason.

**Frontend:**
- `vendor/backend.js` — `createTeamInvitation`/`revokeTeamInvitation`/`createRiderInvitation`/`revokeRiderInvitation`/`approvePendingRider` RPC wrappers; real REST reads `listBusinessMembers`/`listTeamInvitations`/`listRiderInvitations`; `state.currentMemberRole` now captured in `hydrateCanonicalWorkspace` (Section 12 — `get_my_businesses()` already returned it, this path never captured it); new lazily-loaded `hydrateTeamWorkspace()` (only fetched when the Team screen opens, matching this project's established "smallest real-data hydration necessary" discipline). Real Team-screen action handlers (`openTeamScreen`, `confirmInviteTeamMember`, `confirmRevokeTeamInvitation`, `confirmInviteRiderReal`, `confirmRevokeRiderInvitation`, `confirmApprovePendingRider`, `confirmRejectPendingRider` [→ `deactivateRider`], `confirmManageTeamMember` [→ the already-existing `updateTeamMember`, now finally wired to a real UI]).
- `vendor/index.html` — new `pageTeam()` screen (roster with real role/status, Owner-only "Invite Team Member" gated on `state.currentMemberRole`, pending team-invitation list with revoke, "Invite Rider" open to any member, pending-Rider-approval list Owner-gated, pending Rider-invitation list with revoke), reachable from Settings. One-time invite-link display sheet (link built only from the creation RPC's own response, never reconstructed from a list read — list reads never select `token_hash`). The two existing mock "Invite Rider" entry points (`addFirstRiderChecklist` action item, empty-roster CTA) now point at the real flow (`openInviteRiderReal`) instead of the deprecated `window.CEFFLO_ENGINE.commands.inviteRider` mock path — the mock functions themselves are left defined but unreachable, matching this project's established "bypass, don't delete" convention for superseded code (e.g. `confirmPickup` in the Rider app).
- New surface `invite/` (`index.html` + `backend.js`) — a minimal shared invite landing page, NOT inside the Vendor app, reusing `shared/config.js`/`shared/client.js` exactly like the other three surfaces. Resolves `?token=&type=team|rider` anonymously, shows business name + role (team) or a factual "Rider invitation" (rider) with an explicit Owner-access warning when `role==='owner'`, offers real login/signup (genuine `signUpWithPassword`-equivalent `/auth/v1/signup` call, zero mock OTP), a `cefflo_pending_invite` localStorage bridge across the email-confirmation gap (raw token transient client-side only, cleared on every terminal success/failure, never sent to any RPC other than resolve/accept), and calls the matching accept RPC. `scripts/build-static.mjs` updated to copy the new `invite/` directory into the static build (it was not being deployed at all otherwise).

**Identity-binding evidence:** email mismatch rejected fail-closed on both paths (proven live in both new test files); case-insensitive normalization (`lower(trim(...))`) applied on both the stored invitation email and the comparison read from `auth.users`.

**RLS/authorization evidence:** `business_members`/`team_invitations`/`rider_invitations` all carry **zero** direct write policies — every mutation is RPC-mediated. Cross-business denial, Operator-cannot-invite-Owner, Operator-cannot-self-elevate, client-cannot-choose-role, and expired/revoked/already-accepted-cannot-create-membership are all proven live in the new test suites.

**Owner-role evidence:** Operator denied creating an Owner-role invitation (`forbidden`); Owner-created Owner invitation accepted correctly grants `role='owner'`; last-owner protection in `update_team_member` re-verified unchanged (full existing S4-03 regression still PASS).

**Pending-Rider-approval evidence:** accept creates `riders` row at `pending`; the Rider identity has no grant path to self-approve; an unrelated Owner (different business) and an Operator (same business) are both denied approval; Owner approval flips `pending→active` and the **real, pre-existing** `authenticatedRider()`/`ACCOUNT_NOT_APPROVED` gate now genuinely passes for the first time (previously unreachable-to-success, since nothing could create the linking row).

**Multi-business evidence:** the same identity accepting independent invitations into two different businesses ends up an Operator of both simultaneously, neither overwritten (`business_members`' composite PK already supports this by construction). The Rider-side equivalent is the discovered schema conflict above, not silently worked around.

**Concurrency/idempotency evidence:** a real two-thread race on the exact same team-invitation token (real commits, own setup/teardown, mirroring `s4_06_batch_5a_build_rider_run_concurrency.py`'s pattern) — both threads settle on the identical successful outcome, exactly one `business_members` row created, no duplicate.

**Audit-event evidence:** `team.invite_created/revoked/accepted`, `membership.created/role_changed/status_changed`, `rider.invite_created/revoked/accepted/approved/deactivated` all present and asserted directly against `delivery_events`; asserted no raw email/phone/token appears in any event's metadata.

**Tests added:** `tests/s4_07_batch_1_team_invitation.py`, `tests/s4_07_batch_3_rider_invitation.py` (both rollback-only except one dedicated real-commit concurrency block with its own teardown), `tests/s4_07_frontend_wiring.py` (18 static checks). `tests/s4_05_batch_6_full_integration.py` untouched by this batch (already updated in Section 73 for the P2 lock invariant; re-verified still PASS, unaffected by S4-07).

**Full regression (fresh `supabase db reset --local`, all 22 migrations replayed in order):** 25 DB-level scripts PASS (full S4-01→S4-07 chain, including both new S4-07 files). 198 static/structural `unittest` checks PASS (8 files, including the new `s4_07_frontend_wiring.py`). 28-check Node logic suite PASS unchanged. 30-check environment-guard suite PASS. `s4_06_batch_5a_build_rider_run_concurrency.py` (real commits, own cleanup) PASS.

**Residual fixtures:** zero — `auth.users`/test-pattern `businesses`/`team_invitations`/`rider_invitations`/`riders` all checked directly and empty post-suite.

**Staging/Production:** NOT accessed this turn (explicitly out of scope — local-only authorization).

### Safety confirmation
No staging access. No Production access. No commit/push. No S4-08 started. No Helper Pool/Staff Workspace/Direct Fill/Owner-Select/availability-reporting/WhatsApp-sessions/shift-tokens/worker-marketplace/public-Rider-discovery introduced. Legacy `reassign_rider` grant debt untouched. `events_rider` RLS untouched. `git diff --check` PASS.

### S4-07 (Batches 1, 3, minimal UI/shared-invite surface) = LOCAL COMPLETE. Not staged, not closed by this session (Founder-reserved). The `riders.auth_user_id unique` vs. D-03 conflict is the one open architectural question flagged for Founder decision before any future work depends on genuine Rider multi-business membership actually functioning end to end. Awaiting Founder review.

## 77. S4-07.3a — Rider Multi-Business Identity Design/Dependency Reconciliation, Active-Context Correction, POD Active-Context Correction — FOUNDER APPROVED

**Design-only, three Founder review rounds, no implementation any round.** Triggered by Section 76's flagged `riders.auth_user_id unique` conflict; Founder's canonical decision: one Rider Auth identity **must** be able to belong to multiple Vendor teams, but the fix may not be a bare constraint drop.

**Round 1 — reconciliation:** full inventory of every `current_rider_id()`-dependent RLS policy and RPC (orders/rider_assignments/delivery_stops/delivery_events/rider_locations RLS, `is_session_rider`, all 9 Rider mutation RPCs, POD storage policies); recommended architecture (composite `unique(business_id, auth_user_id)`, RLS-as-ceiling only).

**Round 2 — Founder correction (target-derived authorization rejected):** deriving the active Rider relationship purely from whatever business the mutation's *target* (order/session) belongs to is identity-correct but operational-context-wrong — a stale client or bug could silently execute against the *wrong* business the identity also legitimately belongs to. Corrected design: the client must explicitly supply `p_rider_id`; server independently verifies (a) it genuinely belongs to the caller, (b) the target belongs to that *exact* relationship — never "some relationship the identity owns." Single canonical helper `is_current_rider(p_rider_id)` only; the Founder explicitly rejected a second `current_rider_id(business_id)` helper.

**Round 3 — POD Active-Context correction (approved with one addition):** POD upload itself, not just `complete_delivery`, must reject a context-mismatched upload before object acceptance — solved via context embedded in the storage path (`<rider_id>/<order_id>/<uuid>.ext>`) checked by the `pod_rider_upload` storage RLS policy directly (Option A; a new signed-upload Edge Function, Option B, was evaluated and rejected as unnecessary complexity). Founder additionally required `complete_delivery` to structurally validate the submitted `p_pod_path` against `p_rider_id`/`p_order_id` **and** verify the object actually exists in `storage.objects` before persisting it as delivery proof — explicitly not trusting a valid-looking path string, without broadening any existing POD-required/optional lifecycle rule.

**Locked decisions carried into Section 78:** `is_current_rider(p_rider_id)` as the only ownership helper; `unique(business_id, auth_user_id)` replacing the bare unique; `p_rider_id` first-parameter on all 9 Rider mutation RPCs, old signatures retired via DROP+CREATE (no bypass overload left standing); old zero-arg `current_rider_id()` removed outright only after an exhaustive dependency grep; frontend `activeRiderId`/`activeBusinessId` with auto-select (1 active), mandatory "Choose Team" (2+ active, pending shown informationally/non-selectable, inactive never shown), persisted-selection revalidation (discard if stale/pending/inactive), voluntary "Switch Team" in Profile/Account only when 2+ active; explicit REST-level read scoping (RLS remains ceiling-only, never sole workflow scoping); canonical new-upload POD path `<rider_id>/<order_id>/<uuid>.ext` (historical `orders/<order_id>/...` paths never rewritten/reinterpreted); full security matrix (all 9 RPCs × match/mismatch) and POD matrix (upload + completion, structural + existence validation) required as proof, not merely asserted.

**Staging/Production:** NOT accessed (all three rounds design-only).

### Safety confirmation
No implementation any round. No migration. No staging/Production access. No commit/push.

## 78. S4-07.3a — Rider Multi-Business + Explicit Active Context — LOCAL IMPLEMENTATION COMPLETE

**Founder authorized LOCAL IMPLEMENTATION ONLY** of Section 77's locked decisions, combining the Active Rider Context correction and the POD Active-Context correction into one migration/frontend pass. No staging/Production access, no commit/push, S4-08 not started.

**Migration (local only):** `202608290004_s4_07_batch_3a_rider_multi_business_context.sql` —
- `is_current_rider(p_rider_id uuid) returns boolean` (stable, security definer) — the sole ownership helper (belongs to `auth.uid()`, exists, `status='active'`); granted to `public, anon, authenticated`.
- `riders_auth_user_id_key` (bare `unique(auth_user_id)`) dropped, replaced with `riders_business_auth_user_id_key unique(business_id, auth_user_id)` — one identity, one relationship per business, any number of businesses.
- `orders_rider`, `assignments_rider`, `stops_rider`, `events_rider`, `locations_rider` RLS policies rewritten to `is_current_rider(...)`; new `businesses_rider` SELECT policy added (small, mechanically required so the Team picker can show real business names) — RLS remains the identity-wide ownership *ceiling* only; it is not, and is never claimed to be, active-context workflow scoping.
- `is_session_rider` re-defined to call `is_current_rider(rider_id)` internally.
- `pod_rider_upload` storage policy rewritten to validate, **at the storage-RLS layer itself** (before object acceptance): `is_current_rider((storage.foldername(name))[1]::uuid)` AND `orders.assigned_rider_id = (storage.foldername(name))[1]::uuid` for the order named in segment 2. `pod_authorized_read` updated to the same helper (still unused by any live read path, ceiling-only, unchanged otherwise).
- All 9 Rider mutation RPCs (`accept_assignment`, `decline_assignment`, `accept_run`, `decline_run`, `save_run_sequence`, `start_pickup_run`, `start_run_delivery`, `rider_transition`, `complete_delivery`) `DROP FUNCTION`+`CREATE FUNCTION`'d with `p_rider_id uuid` as the first parameter — old context-free signatures do not exist in `pg_proc` any more (verified live, not just by re-reading the migration file); execute grants re-applied to `authenticated` only.
- `complete_delivery` additionally: parses `p_pod_path` into rider/order segments (catch-all `exception when others` on malformed input → `invalid POD path`), rejects if either segment doesn't match `p_rider_id`/`p_order_id`, then rejects if no matching row exists in `storage.objects` for `bucket_id='cefflo-pod'` — all before persisting the path as delivery proof. Every pre-existing POD-required/optional lifecycle rule preserved unchanged.
- `current_rider_id()` dropped outright at the end of the migration, after an exhaustive grep across every SQL/RPC/RLS definition in the repo proved nothing still depended on it.

**Frontend (`rider/backend.js`, `rider/index.html`, `shared/client.js`):**
- `orders(riderId)`/`sessions(businessId)` now explicitly REST-filtered (`assigned_rider_id=eq.`/`business_id=eq.`) — the actual mechanism preventing cross-business mixing in the UI, RLS remains a ceiling only. All 9 RPC wrappers take `riderId` first; every call site (`runAssignmentAction`/`runSessionAction`'s shared `action(appState.activeRiderId, ...)` forwarding, `saveSequenceAction`, `startPickupRunAction`, `pickupOrderAction`, `startDelivery`, `startSelectedRouteStop`, `arriveAtStop`, `yesUsePhoto`) passes `appState.activeRiderId`.
- New context layer: `classifyRiderRelationships()` (fetches every `riders` row for the identity unfiltered by status, classifies active/pending, resolves business names via the new `businesses_rider` policy, throws `ACCOUNT_NOT_APPROVED` iff zero active), `resolveActiveRiderContext()` (auto-selects on exactly 1 active; else tries a still-valid persisted selection; else returns `needsSelection: true` — a stale/removed/pending/inactive persisted id is discarded, never trusted), `setActiveRiderContext`/`clearActiveRiderContext` (`localStorage` is UX continuity only — every RPC independently re-verifies `p_rider_id` server-side regardless of what the device remembers).
- "Choose Team" modal (mandatory at login when 2+ active and no valid persisted selection; active rows selectable, pending rows shown informationally/non-selectable, inactive relationships never rendered) and voluntary "Switch Team" (Profile/Account area, shown only when 2+ active relationships exist; clears `activeRunSessionId`/`planRouteOrder`/`orders` before a fresh scoped re-hydrate). `doLogout()` clears the active Rider context.
- `shared/client.js`'s `uploadPod(riderId, orderId, file)` builds the new canonical `<riderId>/<orderId>/<uuid>.ext` path; `complete(riderId, orderId, file, note)` threads the identical `riderId` through both the upload and the `complete_delivery` call — never independently derived.

**Multi-business/active-context evidence, POD evidence, security matrix (`tests/s4_07_3a_rider_multi_business_context.py`, new, rollback-only):** Ali holds two simultaneous active relationships (`rider_a`→Business A, `rider_b`→Business B, one auth identity) — proven for all 9 RPCs individually: A-context/A-target allowed, A-context/B-target rejected, and the symmetric B-context case. `complete_delivery` A/B matrix proven the same way. POD boundary proven directly against a raw `storage.objects` INSERT (the same RLS check Supabase Storage itself evaluates, not merely inferred from `complete_delivery`): A-context/A-order path allowed; A-context/B-order path rejected with **zero object left behind**; correct pairing succeeds. `complete_delivery`'s structural/existence validation proven separately: wrong-order path, wrong-rider-segment path, and a well-formed-but-nonexistent path are each rejected with a distinct message; the correct upload+completion pair succeeds. Unrelated User C spoofing Ali's path/context rejected. Pending and inactive relationships (via two fresh businesses, since the new composite unique constraint forbids a second row in an already-active business) both rejected. `tests/s4_07_batch_3_rider_invitation.py`'s cross-business acceptance test — previously asserting rejection under the old bare-unique constraint — rewritten to assert the now-correct positive outcome: two independent `riders` rows, second one `pending`, approved independently by that business's own Owner.

**Frontend static evidence (`tests/s4_07_3a_frontend_wiring.py`, new, 24 checks):** classify/resolve active-context logic (unfiltered fetch, ACCOUNT_NOT_APPROVED gate, 1-active auto-select, 2+-active picker requirement, stale-persisted-selection discard, pending never selectable, logout clears context), team-picker rendering (active selectable, pending informational, inactive never rendered), Switch Team (2+-active gate, stale-state clearing before re-hydrate, Profile/Account placement), explicit `p_rider_id` wiring on every one of the 9 RPCs with no old context-free call sites remaining, explicit REST-level read scoping, POD canonical-path/rider-id-threading.

**Regression (fresh `supabase db reset --local`, all 24 migrations replayed clean):** 23 DB rollback-acceptance scripts PASS (full S4-01→S4-07.3a chain) + 131 static/structural `unittest` checks PASS across 8 files (including the two new S4-07.3a suites) + 28-check Node JS logic suite PASS (2 pre-existing assertions updated only for the mandatory `p_rider_id`-first/business-scoped-`sessions()` signature changes, no behavioral intent changed) + `s4_06_batch_5a_build_rider_run_concurrency.py` (real commits, own cleanup) PASS. Zero residual fixtures (`auth.users`/`businesses`/`riders`/`orders` all checked directly, empty post-suite). `git diff --check` / `git diff --cached --check` both PASS.

**Staging/Production:** NOT accessed this turn (explicitly out of scope — local-only authorization).

### Safety confirmation
No staging access. No Production access. No commit/push. No S4-08 started. Customer tracking contract, `internal_tracking_pod_path`, the `tracking-pod` Edge Function, and historical POD paths untouched/unreinterpreted. Legacy `reassign_rider` grant debt and `events_rider`'s own S4-06.7-era RLS debt untouched except where this exact migration mechanically required updating `events_rider`'s policy expression to the new helper. `git diff --check` PASS.

### S4-07.3a = LOCAL COMPLETE. Not staged, not closed by this session (Founder-reserved). Real-browser click-through for the Choose Team / Switch Team flows remains carried to S4-15, unchanged. Awaiting Founder review before any staging step.

## 79. S4-07.3a — Staging Gate Authorized / Preflight PASS

Founder reviewed and approved the Section 78 LOCAL COMPLETE checkpoint and explicitly authorized
S4-07.3a staging application/validation. The restored credential file exists with mode `0600`.
Fail-closed identity verification positively matched only `cefflo-staging`
(`tomvvmwktehexwhktenw`) through the official Mumbai pooler; Production was not accessed.

Live staging ledger was inspected rather than assumed: exactly 20 migrations from `202608130001`
through `202608290001`; `202608290002`, `202608290003`, and `202608290004` are absent. The exact
legacy constraint, helper/signatures, and seven policy prerequisites required by the standalone
`202608290004` migration are present. A mutation-guarded transaction-wrapped dry-run of only
`202608290004_s4_07_batch_3a_rider_multi_business_context.sql` completed successfully and rolled
back; post-dry-run ledger confirms `202608290004` remains absent.

**NEXT EXACT ACTION:** apply only `202608290004_s4_07_batch_3a_rider_multi_business_context.sql`
to positively verified staging in one transaction, record ledger version `202608290004`, and
immediately verify the new helper/constraints/RLS/storage policies/RPC signatures before running
the S4-07.3a staging security matrix.

### 79.1 S4-07.3a Migration Applied to Staging — PASS

Applied only `202608290004_s4_07_batch_3a_rider_multi_business_context.sql` to positively verified
`cefflo-staging` in one transaction and recorded ledger
`202608290004:s4_07_batch_3a_rider_multi_business_context`. Immediate live verification: composite
`riders_business_auth_user_id_key` present and bare unique absent; `is_current_rider(uuid)` present
and zero-arg `current_rider_id()` absent; all 9 p_rider_id-first RPC signatures present and all old
context-free signatures absent. No Production access, commit, or push.

**NEXT EXACT ACTION:** run the rollback-only `tests/s4_07_3a_rider_multi_business_context.py`
security matrix against staging, then verify zero S4-07.3a fixtures before broader regression.

### 79.2 S4-07.3a Staging Security Matrix and DB Regression — PASS

- Dedicated S4-07.3a multi-business/explicit-context/POD matrix: **PASS / rolled back**.
- Matching Rider A/B contexts succeeded symmetrically across all 9 Rider RPCs; mismatched contexts,
  unrelated identity spoofing, and pending/inactive relationships were denied.
- Storage-RLS rejected mismatched POD upload before object acceptance; correct pairing succeeded.
  `complete_delivery` rejected wrong rider/order segments and nonexistent objects; correct upload and
  completion succeeded.
- Backend validation before/after regression: **PASS / PASS**.
- Updated transactional E2E plus 20 compatible rollback suites covering S4-03 through S4-06.7:
  **all PASS**. The separate S4-07 invitation suites were not run because their independently
  scoped `202608290002/003` migrations are not present or authorized for staging in this gate.
- No Production access, commit, or push.

**NEXT EXACT ACTION:** run the S4-07.3a frontend/static/Node regression and the established
cleanup-owning concurrency regression, then perform final read-only ledger/RLS/storage/residual
integrity checks and delete the ephemeral credential.

### 79.3 S4-07.3a Staging Final Validation — PASS

- Current S4-07.3a frontend wiring suite: **24/24 PASS**.
- Executable Rider multi-stop Node logic suite: **28/28 PASS**; `rider/backend.js` syntax PASS.
- Synthetic non-secret staging build: **PASS**.
- Established real-transaction `build_rider_run` concurrency regression: **PASS**; owned fixtures
  cleaned by the test.
- Final live staging integrity: ledger contains exactly 21 applied migrations ending at the
  authorized `202608290004:s4_07_batch_3a_rider_multi_business_context`; the separately scoped
  `202608290002/003` invitation migrations remain absent and were not applied. All public tables
  remain RLS-enabled; `cefflo-pod` remains private; all eight required Rider/storage policies are
  present; the composite Rider identity constraint and `is_current_rider(uuid)` are present; all
  nine p_rider_id-first RPC signatures are present; the bare unique constraint, zero-argument
  helper, and legacy context-free RPC signatures are absent.
- Residual staging fixtures: **ZERO** across checked Auth users, S4 test businesses, Riders,
  orders, and POD objects.
- Compatibility note: the broad static collection ran 252 checks with 247 passing and five
  failures confined to stale assertions in `tests/s4_06_batch_6_rider_multistop_wiring.py` that
  still expect the retired pre-S4-07.3a context-free RPC calls. The approved current wiring and
  executable behavior are independently PASS; no product code, migration, RLS, or test was
  weakened or changed to mask those obsolete expectations.
- `git diff --check`: **PASS**. No commit or push. Production was not accessed or modified.

**NEXT EXACT ACTION:** Founder review of the S4-07.3a staging evidence and explicit closure decision.
Do not start S4-08.

## 80. S4-07.3a — Founder-Approved Closure Pass

Founder approved the Section 79 staging PASS and authorized a closure-only correction of the five
stale test cases in `tests/s4_06_batch_6_rider_multistop_wiring.py`. Inspection confirmed every
failure was caused only by expectations for the retired pre-S4-07.3a context-free Rider calls.

**Test-only correction:** updated the assertions inside those five methods to require the approved
`appState.activeRiderId`/`riderId` first argument for shared Run actions, `saveRunSequence`,
`startPickupRun`, both pickup `transition` calls, `complete`, and `api.uploadPod`. Later assertions
in two of the same methods had been masked by the first failing assertion and were corrected in the
same narrow pass. No test was skipped, deleted, weakened, or broadly rewritten; no production
implementation file changed.

**Closure verification:** broad static collection **252/252 PASS**; current S4-07.3a frontend
wiring **24/24 PASS**; executable Rider logic **28/28 PASS**; `rider/backend.js` syntax PASS;
`git diff --check` PASS; `git diff --cached --check` PASS. Branch remains `staging` at
`607d768d270734f21a8c605eb60abdd600917bc6`. Existing intentional uncommitted S4 work is
preserved. No staging access, migration reapplication, or staging fixtures were needed for this
closure pass. Production was not accessed or modified. No commit/push. S4-08 not started.

**Status:** S4-07.3a CLOSURE PASS — awaiting Founder commit/push authorization.

**NEXT EXACT ACTION:** Founder review and separate commit/push authorization. Do not commit, push,
access Production, reapply staging migrations, or start S4-08 without explicit authorization.

## 81. S4-07.3a Commit/Push Gate — BLOCKED BY NON-ISOLATABLE BASELINE

Founder authorized an S4-07.3a-only commit and push to `staging`, explicitly excluding unrelated
uncommitted S4 work. The commit-boundary audit found that local HEAD and `origin/staging` are both
still `607d768d270734f21a8c605eb60abdd600917bc6`, which contains only the foundation migration and
predates the complete uncommitted S4-03→S4-07 dependency chain.

The S4-07.3a implementation spans cumulative tracked files (`rider/backend.js`,
`rider/index.html`, `shared/client.js`, and this checkpoint) that also contain earlier uncommitted
S4 changes. Required regression files including `tests/s4_07_batch_3_rider_invitation.py`,
`tests/s4_06_batch_6_rider_multistop_wiring.py`, and
`tests/s4_06_batch_6_rider_multistop_logic.js` are wholly untracked relative to HEAD, so their
S4-07.3a adjustments cannot be staged independently from the earlier work that created them.
Migration `202608290004` also replaces RPCs/helpers introduced by the missing earlier migration
chain; committing it without its prerequisites would produce a non-replayable branch.

No files were staged, no commit was created, and no push was attempted. Production and staging
were not accessed; no migration was reapplied; S4-08 was not started. Existing working-tree work
remains untouched.

**BLOCKER:** Founder must choose/authorize a dependency-complete commit boundary (for example,
commit the approved prerequisite S4 chain in ordered commits first, or authorize one cumulative
dependency-complete staging commit). An S4-07.3a-only commit cannot be made safely from the current
branch baseline without either including unapproved prerequisite work or omitting required code.

**NEXT EXACT ACTION:** Founder decision on the dependency-complete commit strategy. Do not stage,
commit, push, access Production, or start S4-08 meanwhile.

## 82. Founder-Authorized Dependency-Complete Local Git History Recovery

Founder approved an ordered, replayable nine-commit recovery chain from
`607d768d270734f21a8c605eb60abdd600917bc6`, including cumulative application/test commits where
historical snapshots no longer exist. Commits 1–8 were constructed locally with explicit
pathspecs only; every staged set passed `git diff --cached --check` and a staged credential/private
key scan before commit:

1. `0ebe2da` — S4-02 approved backend-contract design.
2. `5be5c59` — S4-03 protected contracts and RLS closure.
3. `281a9e7` — S4-04 POD, token lifecycle, Edge Function, and abuse controls.
4. `ba6da4e` — S4-05 approval, sessions, and assignment lifecycle.
5. `30c4323` — S4-06 batching, routing, Run Builder backend, and Wave lifecycle.
6. `794d007` — S4-07 invitation contracts and shared invite surface, including the
   Founder-approved commit-only `202608290002/003` migrations; neither migration was applied to
   staging during this gate.
7. `2a6e8c4` — approved cumulative application state and Rider multi-business context through
   S4-07.3a.
8. `5d6955e` — cumulative Stage 4 regression suite synchronized through S4-07.3a.

This continuity record is the ninth and final planned local commit. `.gitignore`,
`.env.staging.example`, and `README.md` remain explicitly excluded and uncommitted. No provider was
accessed, no migration was applied or reapplied, Production remains untouched, no push was
performed, and S4-08 has not started.

**NEXT EXACT ACTION:** Complete local range/regression/secret verification for `607d768..HEAD`,
then report the recovery result. Push remains Founder-gated.

## 83. S4-07 — Staging Migration Reconciliation (Ledger-Gap Only) — PASS

A fresh Founder-directed staging audit (read-only, `tomvvmwktehexwhktenw`) found this checkpoint's
own Section 79-82 record of staging state to be stale: contrary to Section 79's "202608290002/003
remain absent" and Section 82's "no migration was applied", the live staging ledger already
contained 27 entries, not 21. Both S4-07 invitation migrations, plus all four FOUNDR phase 0-3
migrations, were already live in the database — applied at some point after Section 82 was written,
by a process this checkpoint never recorded. No commit/push, Production access, or S4-08 start is
implicated; this is purely a gap in checkpoint note-taking, not an unauthorized action.

**Schema/object audit — 202608290002 (Team Invitation) and 202608290003 (Rider Invitation):**
`team_invitations`, `rider_invitations` tables; both token-hash unique indexes and business
indexes; RLS enabled on both; `team_invitations_owner` and `rider_invitations_vendor` policies; all
11 RPCs (`create_team_invitation`, `revoke_team_invitation`, `resolve_team_invitation`,
`accept_team_invitation`, `create_rider_invitation`, `revoke_rider_invitation`,
`resolve_rider_invitation`, `accept_rider_invitation`, `approve_pending_rider`, plus the
`update_team_member`/`deactivate_rider` audit-event amendments) — every object EXISTS with the
exact signature and grant set the repository migration files specify. Zero schema gap, zero
conflict.

**Ledger gap only:** both migrations were present in `supabase_migrations.schema_migrations` under
runtime-timestamp versions (`20260830060503`, `20260830060544`) instead of their canonical
repository filenames' versions (`202608290002`, `202608290003`) — same naming pattern independently
affects the four FOUNDR migrations (`20260830060611/0709/0800/0830` vs. repo's
`202608300001-4`), left untouched per explicit scope.

**Reconciliation performed (Task S4-07-LEDGER-01, Founder-authorized):** two `UPDATE` statements
against `supabase_migrations.schema_migrations` only — `20260830060503` -> `202608290002`,
`20260830060544` -> `202608290003`, names preserved. No DDL, no migration replay, no RPC/RLS/policy
change, no application code change.

**Post-change verification — all PASS:**
- Ledger: `202608290002` and `202608290003` now present under canonical versions; old timestamp
  versions gone; total ledger count unchanged at 27.
- Team Invitation and Rider Invitation contracts (tables/indexes/RLS/policies/all 11 RPCs)
  independently re-queried and confirmed unchanged/intact.
- Git working tree: clean, nothing to commit.
- Production (`lmaxtrubwdniovxyuqdy`): not queried, not modified — only `tomvvmwktehexwhktenw` was
  ever addressed by this task.

**Observed but out of scope for this task:** `origin/staging` is 7 commits ahead of local `HEAD`
(`0fc2f26`) — `13d17b5`, `c34c98a`, `07dfab6`, `388d088`, `7162871`, `2ad9bd4`, `9539cb0` — all
Vendor UI-shaped commit messages, none made by this session. Local working tree is clean but stale
relative to `origin/staging`; not pulled, merged, or investigated further here per explicit scope
("do not proceed to the next task automatically").

**S4-07 status: PASS.** All eight requested exit checks satisfied.

**Remaining known issue after S4-07:** the identical ledger-version-mismatch pattern on the four
FOUNDR migrations is unresolved (explicitly deferred, not blocking). The 7 unexplained commits
ahead on `origin/staging` are unreviewed.

**NEXT EXACT ACTION:** Founder decision on (a) whether/when to run the equivalent ledger
reconciliation for the four FOUNDR entries, and (b) what the 7 ahead-of-local `origin/staging`
commits are before any further staging work builds on top of them. Do not start S4-08 or any UI
work without that review.

## 84. FOUNDR-LEDGER-01 — Ledger-Gap Reconciliation (Metadata Only) — PASS

Following a Founder-directed read-only audit (`FOUNDR-LEDGER-AUDIT-01`), which confirmed the same
runtime-timestamp ledger-versioning pattern found in Section 83 also affected all four FOUNDR
migrations, the Founder authorized `FOUNDR-LEDGER-01`: a ledger-metadata-only correction, scoped
identically to Section 83.

**Schema contract was already fully live before this task ran.** All 7 FOUNDR tables
(`platform_admins`, `admin_audit_log`, `feature_flags`, `maintenance_windows`,
`business_subscriptions`, `app_versions`, `platform_announcements`), all 7 RLS enablement flags, all
7 read policies, and all 20 FOUNDR functions (signatures and return types) were independently
verified present and correct against the repository migration files (`202608300001-4`) prior to any
ledger change. This task changed no schema object.

**Reconciliation performed:** four `UPDATE` statements against
`supabase_migrations.schema_migrations` only — `20260830060611` -> `202608300001`,
`20260830060709` -> `202608300002`, `20260830060800` -> `202608300003`, `20260830060830` ->
`202608300004`, names preserved exactly. No DDL, no migration replay, no grant/revoke change, no
RLS/policy change, no application code change.

**Post-change verification — all PASS:**
- Ledger: all four canonical versions present; all four old runtime-timestamp versions gone; total
  ledger count unchanged at 27.
- All 7 tables, all 7 RLS flags, all 7 policies, all 20 functions re-queried and confirmed
  unchanged/intact.
- Git: unchanged from Section 83's state — working tree carries only the (still uncommitted)
  Section 83/84 checkpoint edits; local `HEAD` (`0fc2f26`) remains 7 commits behind
  `origin/staging`; no pull, merge, or any git write operation performed.
- Production (`lmaxtrubwdniovxyuqdy`): not queried, not modified — only `tomvvmwktehexwhktenw` was
  addressed.

**FOUNDR-LEDGER-01 status: PASS** for its own scope (ledger metadata reconciliation only).

**OPEN — not resolved by this task, explicitly not to be read as closed:**
1. **FOUNDR RPC EXECUTE grant conflict** (found in `FOUNDR-LEDGER-AUDIT-01`): all 20 FOUNDR
   functions, including sensitive admin write RPCs (`admin_set_subscription`,
   `admin_start_maintenance`, `admin_end_maintenance`, `admin_create_announcement`,
   `admin_set_announcement_active`, `admin_set_feature_flag`, `admin_record_app_version`,
   `admin_list_audit_log`, `log_admin_action`), have EXECUTE granted to `PUBLIC`/`anon`, when the
   migration files only ever specify `authenticated` (plus `anon` for the 3 genuinely public
   read-only functions). Every function's own `is_platform_admin()` check still fails closed for an
   anon caller today, so this is not currently exploitable, but it is a real defense-in-depth gap
   inconsistent with this codebase's otherwise-universal explicit-revoke discipline. **Remains
   OPEN.**
2. **`origin/staging` remote drift** (7 commits: `13d17b5`...`9539cb0`, audited in
   `STAGING-REMOTE-DRIFT-AUDIT-01`): Founder decisions recorded (remove `388d088` demo auth bypass;
   `2ad9bd4` Workforce UI not accepted as final, needs real backend wiring; `2ad9bd4` ordinary
   Customer Invoice removed from product scope in favor of LHDN e-Invoice) but **no removal/fix has
   been implemented yet**, and local has still not synced with `origin/staging`. **Remains OPEN.**

Overall FOUNDR security/readiness work is **NOT** being declared complete — only the narrow ledger
metadata scope of this task is PASS.

**NEXT EXACT ACTION:** Founder decision on which OPEN item to address next: the FOUNDR RPC grant
repair, or the origin/staging drift (demo-bypass removal / Workforce backend wiring / Customer
Invoice scope removal). Do not start either automatically; do not start S4-08 or any UI work.

## 85. FOUNDR-RPC-GRANT-HARDENING-01 — Grant-Only Forward Migration — PASS

Founder-authorized `FOUNDR-RPC-GRANT-HARDENING-01`, implementing the plan from
`FOUNDR-RPC-GRANT-AUDIT-01` (read-only audit, unlogged): a new forward-only migration,
`supabase/migrations/202608300005_foundr_rpc_grant_hardening.sql`, containing only
`REVOKE`/`GRANT EXECUTE` statements against the 20 FOUNDR functions from
Sections 84's Phase 0-3 migrations. No table, RLS, policy, or function-body change. `202608300001-4`
were not edited.

**Resulting access model:**
- `log_admin_action(...)`: all client-facing (`public`/`anon`/`authenticated`) execute revoked —
  internal helper only, reachable solely from inside other `SECURITY DEFINER` admin RPCs via their
  owner-role context.
- `is_platform_admin()` + 16 admin read/write RPCs (`admin_stuck_riders`, `admin_list_vendors`,
  `admin_get_vendor`, `admin_list_riders`, `admin_delivery_operations`, `admin_list_audit_log`,
  `admin_list_subscriptions`, `admin_set_subscription`, `admin_list_app_versions`,
  `admin_record_app_version`, `admin_set_feature_flag`, `admin_start_maintenance`,
  `admin_end_maintenance`, `admin_create_announcement`, `admin_set_announcement_active`): `public`
  and `anon` execute revoked, `authenticated` retained. `is_platform_admin()` remains the actual
  authorization boundary inside each, unchanged.
- `get_feature_flag`, `get_active_maintenance`, `get_active_announcements`: bare `PUBLIC` grant
  revoked, `anon` and `authenticated` explicitly (re-)granted — these three remain deliberately
  callable pre-authentication, matching their original design intent (no caller exists in the
  codebase yet, but the grant now matches intent exactly instead of over-granting via the
  unintended `PUBLIC` default).

**Ledger:** applied via `apply_migration`, which recorded it under a runtime-timestamp version
(`20260830191725`) — same root-cause pattern as Sections 83/84. Reconciled with the same DML-only
`UPDATE` on `supabase_migrations.schema_migrations` (`20260830191725` -> `202608300005`), name
preserved. Ledger count now 28 (one net new migration, correctly so — unlike 83/84 this was a
genuinely new migration, not a rename of an already-counted entry).

**Verification — all PASS:**
- Full 20-function grant re-query: every admin/internal function shows only
  `authenticated`/`postgres`/`service_role`; `log_admin_action` shows only
  `postgres`/`service_role` (zero client grant); the 3 public-read functions show
  `anon`+`authenticated`+`postgres`+`service_role`, no bare `PUBLIC` row remains anywhere.
- Anonymous probes (`set local role anon`): `get_feature_flag('nonexistent_key')` ->
  `false`; `get_active_maintenance()` -> 0 rows; `get_active_announcements()` -> 0 rows (all three
  genuinely callable); `admin_list_vendors()` -> `42501: permission denied for function` (blocked
  at the grant layer, not just internally); `log_admin_action(...)` -> same `42501` denial.
- Authenticated-role probes (`set local role authenticated`, no real platform-admin JWT available):
  `admin_list_vendors()`, `admin_list_audit_log()`, `admin_list_app_versions()` all reached the
  function body and failed with `P0001: forbidden` from the internal `is_platform_admin()` check —
  not a grant-layer denial — proving `authenticated` access is intact and the only remaining gate is
  the intended one. A full real-session, actual-platform-admin success path was not tested: no row
  exists in `platform_admins` (correct per its own migration's "no seed row" design) and inserting
  one solely to test was correctly out of scope (destructive write, excluded by this task's own
  guardrails).
- Tables/RLS/policies: all 7 FOUNDR tables, all 7 RLS-enabled flags, all 7 policies re-queried
  identical to Section 84 — unchanged.
- Git: unchanged in kind from Sections 83/84 — working tree carries the still-uncommitted checkpoint
  edits plus one new untracked file (`202608300005_foundr_rpc_grant_hardening.sql`); local `HEAD`
  (`0fc2f26`) remains 7 commits behind `origin/staging`; no pull, merge, commit, or push performed.
- Production (`lmaxtrubwdniovxyuqdy`): not queried, not modified.

**FOUNDR-RPC-GRANT-HARDENING-01 status: PASS.**

**OPEN — unchanged, not touched by this task:**
1. `origin/staging` remote drift (7 commits, `13d17b5`...`9539cb0`) — Founder decisions recorded in
   Section prior (remove `388d088` demo auth bypass; `2ad9bd4` Workforce UI needs real backend
   wiring, not accepted as final; `2ad9bd4` ordinary Customer Invoice removed from product scope in
   favor of LHDN e-Invoice) — **none implemented yet**, local still not synced.
2. UI remains frozen — no Vendor/Rider/Customer/FOUNDR UI file touched by this task.

**NEXT EXACT ACTION:** Founder decision on whether to begin origin/staging drift remediation next
(demo-bypass removal / Workforce backend wiring / Customer Invoice scope removal) or another
Foundation-track item. Do not start automatically; do not start S4-08 or any UI work without that
decision.
