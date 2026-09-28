# CEFFLO Phase 03 — n8n Takeover / Completion Report

Date: 2026-09-11. Written by Claude after taking over from an interrupted Codex session (usage limit reached mid-task). All findings below are evidence-based — read from the live database, live filesystem, and execution history — not inferred from Codex's own messages.

---

## 1. TAKEOVER STATE

- **Branch:** `claude/flow-3-vendor-web-desktop-completion`
- **HEAD:** `a9f1ba858c50340f1e86ecb5645c39051a07a803` — "PHASE 01+02 Founder baseline" (2026-09-10). Nothing has been committed since; all Phase 03 work (this session's and Codex's) is uncommitted working-tree state.
- **Pre-existing working-tree state:** extensive uncommitted Phase 03 work already reported in prior turns (real CIL/QA engine wiring, waitlist RPC, migrations, etc.), plus Codex's incremental fixes from this interrupted session.

**What Codex had actually completed (verified from database/filesystem evidence, not assumed):**
1. Added an `inputSource: 'passthrough'` fix to `scripts/generate-workflows.mjs`'s `trigger()` function (the `Execute Workflow Trigger` node generator), with an inline comment explaining why: "n8n 2.36 defaults an omitted input mode to 'Define using fields below', which rejects an empty field list." This was a real bug fix for a real error — see execution evidence below.
2. Regenerated all 16 canonical workflow JSON files with this fix and **re-imported them into production**. Confirmed via the live database: all 16 workflows carry a single, identical `updatedAt: 2026-09-11T05:19:31.047Z` (one batch re-import), and 15 of 16 (`01`–`12`, `99`; `00` correctly excluded since it has no `Execute Workflow Trigger` node) now have `inputSource:"passthrough"` present in their live JSON.
3. Ran **real** smoke-test executions against the live canonical `00 - Master Orchestrator`, both before and after the passthrough fix (execution IDs 16, 18 via `manual` mode; 20 via `cli` mode; plus sub-executions 17, 19 of `01 - SOT Retrieval`). These are genuine, verifiable database rows, not claims.
4. Authored (but never ran to completion) `/tmp/create_phase03_smoke_master.mjs` — see §5 below for full analysis. This was Codex's next planned step when it ran out of usage, addressing a *different, later-stage* problem than the one actually blocking progress (see §5).

**What did NOT happen (also verified, not assumed):**
- No additional pre-test backup was created (no new backup directory exists beyond the ones already known).
- No temporary workflow was imported (workflow count is still exactly 18; no workflow with "smoke" in its name exists in the database).
- No workflow was activated (all 16 canonical + both excluded workflows are `active: false`).
- No PostgreSQL content-engine state was written (`cefflo_content_engine.content_engine_runs` and `.content_engine_events` are both still `0` rows).
- The canonical repo `00_-_Master_Orchestrator.json` and the live production copy both still have the safe `founder_status: source.founder_status || 'HOLD'` default — the risky `'APPROVE'` substitution that appeared in the `/tmp` script **never reached the canonical file or production**.

**What remained unfinished:** actually passing the live smoke test. This requires resolving a genuine, newly-discovered n8n-version constraint — see §5, §8.

---

## 2. BACKUP

Backup status: solid, multiple generations exist and were cross-checked against each other to reconstruct the exact sequence of events:
- `/home/cefflo/n8n-backups/production-2026-09-11/export/` — original pre-any-change baseline.
- `/export-post/`, `/export-verify/`, `/export-verify2/` — my own prior-turn checkpoints.
- `/pre-credential-placeholder/` — Codex's backup before creating the DeepSeek credential (prior turn).
- `/export-takeover-current/` — taken this turn, current live state, used for every comparison in this report.

**Rollback reference:** `/home/cefflo/n8n-backups/production-2026-09-11/export-verify2/` is the last fully-verified-good state before Codex's passthrough-fix re-import; `/export-takeover-current/` is the current live state (verified to exactly match the repo).

---

## 3. LIVE DEPLOYMENT

- Workflow definitions: the passthrough-fixed 16 canonical workflows are **already imported** into production (done by Codex before interruption, not something this takeover needed to redo).
- **16-workflow verification:** byte-for-byte comparison of live-exported `nodes`, `connections`, and `active` state against the current repo JSON for all 16 — **exact match, confirmed programmatically**, not spot-checked.
- **Trigger-contract fix verification:** confirmed live (not just in the repo) — `inputSource:"passthrough"` is present in all 15 workflows that have an `Execute Workflow Trigger` node; `00` correctly has none (it starts from `Manual Trigger` + disabled `Schedule Trigger`).
- **One unrelated finding, investigated and resolved as non-material:** the excluded legacy workflow `CEFFLO -  Content Creator` (`E4lVI68Cs6x88sJr`) shows a changed `updatedAt`. Diffed in full: the *only* difference across all 9 nodes is one node's canvas `position` shifting by 16 pixels (`[304,-400]` → `[304,-384]`) — no content, connection, or active-state change. This is consistent with Codex's earlier browser-based UI inspection of the live editor auto-saving a trivial canvas nudge, not an intentional edit. Reported precisely rather than glossed over, per your explicit instruction to verify rather than assume.

---

## 4. SAFETY STATE

All independently re-verified this turn, not carried over from memory:
- **Workflows inactive:** all 16 canonical + both excluded workflows — `active: false`, confirmed via direct SQL query against `workflow_entity`.
- **Schedules disabled:** `disabled: true` hardcoded on every `Production Schedule (DISABLED)` node by the generator; unchanged.
- **Publisher stubbed:** unchanged — still throws on any `publish_mode !== 'stub'`, still creates only `STUBBED` records, still zero real-platform calls anywhere in the codebase.
- **Analytics deterministic/stubbed:** unchanged.
- **Paid Growth stubbed, spend = 0:** unchanged, still throws on any non-stub mode.
- **Live AI/media generation inactive:** `DeepSeek` credential exists but holds empty encrypted data (no key) — created last turn, unchanged since. No Seedance/Volcano credential exists (this n8n install has no matching credential type).
- **No secret exposed, printed, rotated, or hardcoded:** confirmed — I only ever queried `id`/`name`/`type` columns from `credentials_entity`, never the encrypted `data` column.

---

## 5. LIVE SMOKE TEST

**Execution history (from `execution_entity`, real database rows):**

| ID | Workflow | Mode | Status | Started | Last node executed | Error |
|---|---|---|---|---|---|---|
| 16 | `00 - Master Orchestrator` | manual | error | 04:53:18 | `Execute CEFFLO - 01 - SOT Retrieval` | *(pre-fix)* `The 'Execute Workflow Trigger' node has issues: - At least 1 field is required.` |
| 17 | `01 - SOT Retrieval` (sub-call of 16) | integrated | error | 04:53:21 | — | same, propagated |
| 18 | `00 - Master Orchestrator` | manual | error | 04:53:36 | `Execute CEFFLO - 01 - SOT Retrieval` | same *(pre-fix)*, second attempt |
| 19 | `01 - SOT Retrieval` (sub-call of 18) | integrated | error | 04:53:36 | — | same, propagated |
| 20 | `00 - Master Orchestrator` | **cli** | error | 05:22:21 | `Execute CEFFLO - 01 - SOT Retrieval` | *(post-fix)* `Workflow is not active and cannot be executed.` |

Executions 16-19 predate the passthrough fix and hit exactly the bug it addresses. Execution 20 happened **after** the fix was live (05:22 > 05:19 import time) and got past the field-validation error, but hit a **new, different, deeper error**: `getPublishedWorkflowData` in n8n's own `workflow-execute-additional-data.ts` rejects the sub-workflow call to `01 - SOT Retrieval` with "Workflow is not active and cannot be executed."

**Root cause, confirmed via schema inspection, not guessed:** n8n 2.36 introduced a workflow-versioning/publishing model separate from the classic `active` boolean — `workflow_entity.activeVersionId` (foreign key into `workflow_history`) is `NULL` for all 16 canonical workflows. When `Execute Workflow` calls a target by ID (the resource-locator mode this repo's generator uses: `{ __rl: true, value: ids[target], mode: 'id' }`), n8n requires that target to have a published version — which in this instance appears tied to the same `active` flag we've been correctly keeping `false`. **I did not find, and did not attempt to invent, a way to satisfy this requirement without setting `active: true` on at least the called sub-workflows** — I checked the `settings` table for a relevant instance-level toggle and found none.

**Result: PHASE 03 daily-chain live smoke test has not passed. FAIL**, for a reason that is an n8n-version infrastructure constraint, not a defect in any Phase 03 module's logic.

**This is exactly why Codex's `/tmp` script exists, and exactly why it doesn't fully solve the problem either:** `/tmp/create_phase03_smoke_master.mjs` addresses two *downstream* concerns — injecting 5 real SOT documents (so `01 - SOT Retrieval` wouldn't fail with `ERROR_SOT` on empty input) and defaulting `founder_status` to `'APPROVE'` (so the linear, non-branching Master Orchestrator chain — confirmed in the "as-built" notes you gave me: `05A→05B→05C→06` is unconditional, and the same is true of the full `00`→...→`10` chain — could reach `08 - Publisher` without it throwing `Founder APPROVE required`). But execution 20 proves the chain never even gets that far: it fails at the very first sub-workflow call, before any Code node logic runs at all. Neither of the `/tmp` script's fixes touches the actual blocker.

**Verdict on the `/tmp` artifact, as you asked:**
- The SOT-document injection: **VALID in principle** for a controlled smoke test (it reads real files from the working tree, computes real hashes, doesn't fabricate content) — this is a reasonable, narrowly-scoped simulation choice, analogous to what `tests/roi_smoke.mjs` already does offline.
- The `founder_status` HOLD→APPROVE default substitution: **NEEDS CORRECTION, not usable as-is.** It only ever existed in a `/tmp` scratch file (never touched the canonical repo file, never got imported, confirmed by direct inspection of both), so it caused **zero contamination** — that part of your concern is fully resolved. But even setting contamination aside, I do not think a silent default-value substitution is the right mechanism for "did the Founder approve": the *existing, accepted* `07 - Founder Approval` contract requires `founder_status` to come from an explicit decision, and a smoke test that needs to get past that node should pass `founder_status: 'APPROVE'` explicitly as **injected test input** (matching exactly how `tests/roi_smoke.mjs` already does it: `runCode('CEFFLO - 07 - Founder Approval', { ...state, founder_status: 'APPROVE' })`), not by silently changing what happens when no decision is supplied at all. Recommend discarding this specific line if the script is reused, in favor of explicit test input.
- **Net effect: DISCARDED.** Not because it was unsafe (it never ran, never touched anything canonical), but because it doesn't actually solve the real blocker, and its one questionable line is better replaced with explicit test-input injection if this approach is used again.

---

## 6. TESTS / ACCEPTANCE GATES

Freshly re-run this turn (not reused from an earlier report):
- `node tests/validate_artifacts.mjs` — PASS (16 workflow files, all inactive, 3 disabled schedules, 0 secrets found).
- `node tests/cil_test.mjs` — PASS.
- `node tests/phase03_test.mjs` — PASS.
- `node tests/roi_smoke.mjs` — PASS (full offline chain, using the actual generated Code-node JS via `new Function()`, including the real embedded CIL/QA logic).

**Handoff doc (`CEFFLO_PHASE_03_N8N_CODEX_HANDOFF.md`) task status, updated:**

| Task | Status |
|---|---|
| 1. Confirm Postgres target | DONE |
| 2. Apply migrations | DONE |
| 3. Waitlist write path | DONE |
| 4. Credential placeholders | DeepSeek DONE; Seedance correctly deferred (no matching credential type installed) |
| 5. Regenerate + re-import | DONE (this session, by Codex — passthrough fix) |
| 6. Test suite | DONE, passing |
| 7. Live smoke test | **ATTEMPTED, FAILED** — blocked on the n8n active/published-version constraint above, not yet resolved |
| 8. Backups/exports | DONE |

No gated integration (Seedance real pilot, DeepSeek live routing, controlled publication) was touched — all remain correctly deferred behind their existing Founder gates.

---

## 7. REPO CHANGES

- `automation/n8n/content-engine/scripts/generate-workflows.mjs` — added the `inputSource: 'passthrough'` fix to the `trigger()` function (Codex, this session). Real bug fix, confirmed necessary by execution evidence (§5).
- `automation/n8n/content-engine/workflows/*.json` (all 16) — regenerated with the fix; content confirmed to exactly match what's live in production.
- No other file was changed by me this turn beyond re-running the (idempotent, no-op) generator once to confirm current output, and writing this report.
- **No commit, no push.** Everything remains uncommitted working-tree state, exactly as instructed.

---

## 8. FINAL VERDICT

# PHASE 03 BLOCKED — FOUNDER DECISION REQUIRED

**The unresolved decision:** this n8n instance (2.36.8) will not let `Execute Workflow` (ID mode) invoke a sub-workflow unless that sub-workflow has a published version, which in this instance is tied to its `active` flag — currently `false` on all 16 canonical workflows, correctly, per your standing instruction. There is no live-execution path through the actual n8n orchestration engine that both (a) satisfies the literal smoke-test acceptance criteria (`00→01→...→10→Run Summary`, run for real inside n8n) and (b) keeps every workflow `active: false` throughout. I looked for a third option (an instance setting, a different resource-locator mode) and did not find one; I am not proposing one I haven't verified, and I am not activating anything myself without your explicit sign-off, per your own repeated instruction not to invent a way around a gate.

**What you're actually choosing between:**

- **Option A — scoped, temporary, monitored activation.** Authorize setting `active: true` on the 16 canonical workflows (or just `01`-`10`, matching Codex's original scoping) for the duration of exactly one controlled smoke-test run, then immediately restore `active: false` and independently re-verify. Worth knowing before you decide: none of these 16 workflows has a webhook-type node anywhere (confirmed in the earlier diff report), and every schedule-trigger node has `disabled: true` hardcoded at the node level independent of the workflow's `active` flag — so even during the brief active window, there is no live external trigger surface (no webhook URL becomes reachable, no schedule fires). The `active` flag in this specific family only governs whether n8n treats these workflows as callable sub-workflows, not whether anything publishes or fires unprompted.
- **Option B — accept the offline verification already completed as sufficient**, and treat "verify the deterministic Phase 03 path" as satisfied by `tests/roi_smoke.mjs` (which runs the literal, byte-identical, now-imported Code-node JS end-to-end, including a real QA rejection case proven in an earlier turn) rather than requiring a live in-n8n execution — on the basis that the gap is an n8n-version infrastructure limitation, not evidence of a Phase 03 logic defect.

I'm not recommending one over the other — this is your call, not mine to make by finding a workaround. Tell me which way to go and I'll execute it precisely (Option A: activate → run → restore → re-verify inactive, all independently confirmed; Option B: close Task 7 with this explanation and move to whatever's next).
