# CEFFLO — ACTIVE EXECUTION CHECKPOINT

Updated: 2026-08-27 (Claude session, staging branch committed locally; push to origin BLOCKED on invalid GitHub credentials)
Active agent: Claude
Current Stage: Stage 4
Current Sprint: S4-01 — isolated preview/staging/test configuration and disposable test target
Current Sub-sprint / Work Package: S4-01E — Hosted Acceptance (E2E complete) → staging branch created + committed locally → BLOCKED on git push authentication
Status: BLOCKED. `staging` branch created from `main`'s HEAD, 20-file reconciled baseline committed (`47d126fce22511018b1318818103f49d5bf0d451`). `git push -u origin staging` failed: no valid GitHub credentials in this environment (`gh auth status` reports the stored token for `cefflohq` is invalid/expired). No workaround attempted (did not try the SSH key present at `~/.ssh/id_ed25519`, did not change remote transport, did not re-authenticate interactively). `main` remains byte-identical at `15a551bdb26b79536138f16bd1370e3dfb4c4a5a`, confirmed both locally and on the remote via `git ls-remote`. No Vercel action taken — nothing exists at origin for Vercel to build yet.

## 1. Current Objective
Hosted transactional E2E against `cefflo-staging` is now PASS. Remaining objective: complete the Vercel Preview/Staging acceptance preflight (review/prepare requirements only — Vercel itself stays unconfigured until explicit authorization), then proceed to actual Vercel configuration under required authorization. This is the final gate of S4-01 before S4-02 may begin.

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
**RESOLVED — no current blocker.** The staging credential/capture-path issue and the hosted transactional E2E gate are both resolved/passed:
- Non-mutating staging identity check: PASS.
- Pre-E2E `validate_backend.py`: PASS (`backend_contract_ok`).
- Hosted transactional E2E (`e2e_transaction.py`): PASS (`e2e_transaction_ok`).
- Post-E2E `validate_backend.py`: PASS (`backend_contract_ok`).

All four executed out-of-band by the credential holder in the VPS shell; credential and mutation env vars (`DATABASE_URL`, `CEFFLO_DISPOSABLE_TARGET`, `CEFFLO_ALLOW_MUTATING_TESTS`) were reported removed from the shell afterward. The credential never entered chat or any tool-call transcript at any point in this process.

Remaining item before S4-01 fully closes: Vercel Preview/Staging acceptance — not yet started, gated on separate authorization for actual provider configuration.

## 10. NEXT EXACT ACTION
**Preflight complete.** Awaiting Founder decision on Preview/Staging scoping strategy before any Vercel configuration:
- Option A: dedicated long-lived `staging` git branch, deployed via Vercel's automatic Preview mechanism, with branch-scoped env var overrides for the staging Supabase target (works on current Hobby plan).
- Option B: a second, separate Vercel project dedicated to staging (also works on Hobby, but is a distinct provider resource with its own cost/ownership).
- Native Vercel "Custom Environments" (a true third named environment beyond Production/Preview) requires a Pro/Enterprise plan upgrade — not available on the current Hobby team plan.

**No Vercel configuration or provider call is authorized yet.** Preflight was read-only (repo files + Vercel MCP `list_teams`/`list_projects`/`get_project`/`list_deployments` — no writes). Actual Vercel changes remain out of scope until Founder authorization is given.

## 11. After That
- Under required authorization: pick the Preview/Staging scoping option, configure the corresponding Vercel environment variables (see Section 6 preflight findings — B/C variable sets), and run the deployment acceptance checklist recorded in Section 6.
- Only after Vercel Preview/Staging acceptance passes does S4-01 sprint acceptance close and S4-02 become eligible to start.

## 12. DO NOT DO
- Do not access or modify Production.
- Do not use Production credentials.
- Do not start S4-02 before S4-01 acceptance passes.
- Do not reset staging blindly again.
- Do not configure Vercel until the hosted E2E gate and authorization sequence permit it.
- Do not commit/push unless authorized.
- Do not change Docker host security/permissions.
- Do not reset, restore, stash, or overwrite the existing uncommitted Codex work listed in Section 4.
- Do not paste the staging `DATABASE_URL` or password into chat/agent conversation under any circumstance — it must reach the shell environment out-of-band.
- Do not rotate the staging password — resolved via out-of-band export; no rotation was ever necessary.
- Do not run the hosted transactional E2E without the out-of-band-exported preconditions listed in Section 10, and do not pass the credential through chat or an inline Bash env-var prefix.
- **HARD RULE (Founder-approved, Section 16.2):** Never push or merge to `main` without explicit Founder Production authorization — GitHub auto-deploy means this immediately triggers a live Production Vercel deployment, not just a git action.
- Do not create the `staging` branch, commit, or push it yet — the sequence is drafted (Section 16.4) but not authorized to execute this turn.
- Do not add any Vercel environment variable, create a branch intended for deployment, or change `vercel.json` domain/rewrite rules until Founder has chosen the Preview/Staging scoping strategy (Section 10) and authorized it.

## 13. Acceptance Gate Remaining
- Non-mutating staging authentication/identity check: **PASS**.
- Pre-E2E `validate_backend.py`: **PASS** (`backend_contract_ok`).
- S4-01E hosted transactional E2E (`e2e_transaction.py`): **PASS** (`e2e_transaction_ok`).
- Post-E2E `validate_backend.py`: **PASS** (`backend_contract_ok`).
- Vercel Preview/Staging preflight (review-only): **DONE** — see Section 6 findings. No Preview/Staging exists today; all history is Production-target.
- Vercel Preview/Staging environment configuration and deployment acceptance: **NOT STARTED** — blocked on Founder decision (branch+Preview-override vs. second project) and authorization; actual configuration is the next action after that decision.
- Only after Vercel Preview/Staging acceptance passes: S4-01 sprint acceptance closes and S4-02 may begin.

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

### 16.8 Execution outcome (this turn)
**BEFORE COMMIT gates:** main HEAD recorded (`15a551bdb26b79536138f16bd1370e3dfb4c4a5a`); branch/status/diff verified; exact 20-file reconciliation against this checkpoint's Section 4 confirmed (9 modified + 11 untracked, including the 2 continuity files); staged explicitly by filename (no wildcards) — confirmed via `git diff --cached --name-status` (exactly 20 entries).
- First `git diff --cached --check` run **FAILED** (exit 2): trailing-whitespace Markdown line-breaks in `AI_CONTINUITY_README.md` (lines 5, 182-185), preserved verbatim from the earlier "install exactly as provided" instruction. Stopped per "if any check fails, STOP without workaround"; surfaced the conflict to the Founder rather than resolving unilaterally.
- Founder authorized stripping the trailing whitespace (whitespace-only; diff confirmed no wording/content change). Re-staged; `git diff --cached --check` then **PASSED** (exit 0).
- Also spot-checked the staged diff for secret-shaped strings: all matches were `.env.example` placeholders or literal `secret`/fake-ref fixtures inside `tests/test_environment_guard.py`'s negative-test suite — no real credential present.

**Committed** onto `staging` only: commit `47d126fce22511018b1318818103f49d5bf0d451`, 20 files, message "S4-01E: staging environment identity, disposable Supabase target, and continuity protocol". `main` confirmed unchanged immediately after (`15a551bdb26b79536138f16bd1370e3dfb4c4a5a`).

**Push BLOCKED:** `git push -u origin staging` failed — `fatal: could not read Username for 'https://github.com': No such device or address`. Diagnosis (read-only): `gh auth status` shows the stored token for GitHub account `cefflohq` is invalid/expired; no `credential.helper` configured. An SSH key exists at `~/.ssh/id_ed25519` but was deliberately **not** used (unverified scope, would be an unauthorized workaround; also would require changing `origin`'s transport, not part of what was authorized). `git ls-remote origin main staging` confirms the remote has no `staging` ref yet and `main` remains `15a551bdb26b79536138f16bd1370e3dfb4c4a5a`.

**Not attempted, sequenced behind the push:** Vercel Preview environment-variable configuration, triggering/observing a Preview deployment, the full deployment acceptance checklist (Section 16.7), retrieving the Supabase publishable key, marking S4-01 complete. None of these can proceed until `staging` exists at the remote.

No branch deleted. No commit undone. No Production access or modification. S4-02 not started.
