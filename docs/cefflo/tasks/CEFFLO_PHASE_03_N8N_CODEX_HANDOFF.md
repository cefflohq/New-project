**Status:** EXECUTION STATUS — updated by Codex 2026-09-11. Nothing in this document authorizes activation.
**Owner:** Codex, per `CEFFLO_PHASE_03_MARKETING_ENGINE_CONTENT_PILOT_MASTER.md` §2/§3.3/§27 ("Codex is the designated implementation operator for n8n setup/configuration... Founder must NOT manually build n8n").
**Do not** ask the Founder to perform any of the steps below except the explicitly-marked unavoidable human actions.

---

# 1. WHAT'S ALREADY TRUE (do not redo)

- n8n is already running: Docker container `cefflo-n8n-new` (image `n8nio/n8n:2.36.8`), backed by dedicated Postgres (`cefflo-n8n-postgres`), bound to `127.0.0.1:5678`. Confirmed live and healthy as of the DeepSeek pre-implementation audit (`docs/cefflo/audits/CEFFLO_DEEPSEEK_N8N_PRE_IMPLEMENTATION_REPORT.md`).
- All 16 `CEFFLO - 00..12, 99` workflows from `automation/n8n/content-engine/workflows/` are **already imported into that live instance**, all inactive, all with disabled schedules where applicable. This satisfies most of §27's "workflow import" requirement already.
- Two pre-existing prototype workflows also live there, inactive, untouched, correctly out of scope: `CEFFLO - 00 - Orchestrator Test` and the legacy `CEFFLO - LEGACY - Content Creator` (renamed per D-27).
- One credential exists: `OpenAI account` (`openAiApi`), attached only to the legacy prototype. No DeepSeek, no Seedance credential exists yet.

# 2. WHAT CHANGED THIS PASS (re-import required)

`automation/n8n/content-engine/` gained new modules this pass: `content-script-engine.mjs`, `qa-engine.mjs`, `seedance-adapter.mjs`, `approval-state-machine.mjs`, `dry-run-batch.mjs`, plus a new migration (`202609130001_phase03_cost_and_waitlist.sql`). **The 16 workflow JSON files were NOT regenerated this pass** — `generate-workflows.mjs` was not run against them, so the already-imported workflows in n8n still reflect their original ROI-stub Code-node logic, not these new modules. Wiring the new deterministic content/QA/Seedance-stub logic into the actual `06 - AI QA`, `05A/05B/05C` creator, and `07/08` approval/publisher Code nodes is a follow-up regeneration step (extend `generate-workflows.mjs`'s `linear()` calls for those keys to call into the new `.mjs` modules' logic, or port the equivalent logic inline as Code-node JS, matching the existing stub pattern) — deliberately deferred this pass to keep the diff reviewable; flagged here rather than done silently.

# 3. CODEX TASKS (in order)

## Execution status (2026-09-11)

| Task | Status | Verified result / remaining action |
| --- | --- | --- |
| 1. Confirm target Postgres | DONE | Local disposable Supabase target (`supabase_db_cefflo-local`, `127.0.0.1:54322`) confirmed; n8n internal Postgres untouched. |
| 2. Apply migrations | DONE | All three migrations applied and the `cefflo_content_engine` tables verified. The later Code-node regeneration follow-up is also complete. |
| 3. Waitlist write path | DONE | RPC, PostgREST schema exposure, client wiring, and real HTTP validation complete. |
| 4. Credential placeholders | PARTIAL / OPEN | `DeepSeek` (`deepSeekApi`) created with encrypted empty `{}` data—no key or dummy secret. No installed Seedance/Volcano Engine ARK credential type exists; do not create a substitute type. Founder action is required only if a correctly typed provider credential becomes available or is selected. |
| 5. Regenerate and re-import | DONE | Approved deterministic Code-node content was regenerated and imported for the seven specified workflows; all remain inactive. |
| 6. Test suite | DONE | `validate_artifacts.mjs`, `cil_test.mjs`, `phase03_test.mjs`, and `roi_smoke.mjs` all passed on 2026-09-11. |
| 7. Live smoke test | BLOCKED / OPEN | Editor is reachable, but manual trigger is gated by n8n sign-in. No authorized authenticated session or Personal API Key was provided; do not create one or bypass access. Founder must provide an authorized trigger path. |
| 8. Backups/exports | DONE | Existing export/export-post/export-verify backups present; an additional pre-credential-placeholder export captured before task 4. |

1. **Confirm target Postgres for `cefflo_content_engine`.** Same open item since the DeepSeek AI Router Master's Phase 0 — still unconfirmed. Recommended default (from that Master): the product's Supabase instance, not `cefflo-n8n-postgres` (reserved for n8n's own tables). Do not apply any migration until this is confirmed.
2. **Apply `202609100001_content_engine_roi.sql`, `202609110001_cil_scenarios.sql`, and `202609130001_phase03_cost_and_waitlist.sql`** (in that order — later files reference tables from earlier ones) to the confirmed target, once (1) is resolved.
3. **Create the `prelaunch_waitlist` write path.** Write a `cefflo_content_engine.submit_waitlist_entry(jsonb) RETURNS uuid` function (matching the existing `SECURITY DEFINER`-style pattern of `persist_marketing_memory`/`log_event` in `202609100001_content_engine_roi.sql`), then expose the `cefflo_content_engine` schema (or just this one RPC) through PostgREST's exposed-schema config so `marketing/prelaunch/backend.js`'s `window.CEFFLO.rpc('submit_waitlist_entry', ...)` call resolves. This is genuinely new infrastructure work, not just an import.
4. **Create credential placeholders** in n8n's encrypted credential store — names only, Founder supplies the actual keys later, out-of-band, never in chat:
   - `DeepSeek` (type `deepSeekApi`, already confirmed available in the installed `@n8n/n8n-nodes-langchain` package per `docs/cefflo/audits/CEFFLO_DEEPSEEK_N8N_PRE_IMPLEMENTATION_REPORT.md`) — for any future live AI Router wiring (`docs/cefflo/tasks/CEFFLO_DEEPSEEK_AI_ROUTER_IMPLEMENTATION_MASTER.md`), not required for Phase 03's deterministic-by-default content engine.
   - `Seedance` / Volcano Engine ARK (AK/SK-style credential, per `automation/n8n/content-engine/scripts/seedance-adapter.mjs`'s header) — **do not create this yet**, it is gated behind Founder Gate 2 (`CEFFLO_PHASE_03_MARKETING_ENGINE_CONTENT_PILOT_MASTER.md` §38 item 2, paid activation). Preparing the placeholder is fine; entering a real key is not authorized by this document.
5. **Re-run `node scripts/generate-workflows.mjs`** if/when the Code-node wiring described in §2 above is done, and re-import the regenerated JSON — still inactive, still `activationProhibited: true`.
6. **Run the test suite** (`node tests/validate_artifacts.mjs`, `node tests/cil_test.mjs`, `node tests/phase03_test.mjs`, `node tests/roi_smoke.mjs` once the SOT-manifest commit gap from D-27/D-29 is resolved) after any change, before considering the change complete.
7. **Smoke test against the live instance**: trigger `CEFFLO - 00 - Master Orchestrator` manually (its own manual trigger, schedule stays disabled) and confirm the run completes through to `Run Summary` without activating anything external — this is the existing ROI smoke path, now exercised against the live n8n instance rather than only the offline `roi_smoke.mjs` fixture runner.
8. **Document backups/exports** for the current workflow set (n8n's own export mechanism) before making further structural changes, per §27's "backup/export setup."

# 4. UNAVOIDABLE FOUNDER ACTIONS (exception-only, per §2.3)

Do not turn these into a manual-setup tutorial — one short instruction each, at the point they're actually needed:
- Supplying the real DeepSeek API key into the `DeepSeek` credential (out-of-band, never in chat) — only once live AI Router wiring is actually being turned on, which is not part of this handoff.
- Supplying real Seedance/Volcano Engine ARK credentials — only after Founder Gate 2 (§38 item 2) is explicitly granted.
- Confirming the Postgres target (task 1 above) — a one-line decision, not a setup task.

# 5. DO NOT

- Do not activate any workflow (`active: true`) or enable any schedule.
- Do not create a Seedance credential with a real key without Founder Gate 2.
- Do not apply the migrations without the Postgres-target confirmation.
- Do not build a competing content-engine scaffold — extend what's committed.
