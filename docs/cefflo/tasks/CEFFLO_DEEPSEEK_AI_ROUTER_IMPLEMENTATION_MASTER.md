**Status:** IMPLEMENTATION MASTER — DRAFTED, NOT EXECUTED. Awaiting Founder approval to begin Phase 0.
**Baseline evidence:** `docs/cefflo/audits/CEFFLO_DEEPSEEK_N8N_PRE_IMPLEMENTATION_REPORT.md` (audit) + this document's own reconciliation pass (below) against the approved ROI skeleton.
**Founder decisions this executes:** the three blocker resolutions and the DeepSeek/AI Router directives from the Founder's Blocker-Resolution message, 2026-09-10.
**Non-goal:** this document does not activate anything. No workflow is set Active, no credential is created, no migration is applied, no code is committed or pushed as part of writing this Master MD. Execution begins only after separate, explicit Founder approval.

---

## 0. RECONCILIATION FINDING (read before executing anything)

The approved base — worktree `codex/n8n-content-engine-roi` at `/tmp/cefflo-n8n-content-engine`, `automation/n8n/content-engine/` — was inspected directly (all files read, none modified) and reconciled against the current canonical SOT (`docs/cefflo/sot/marketing/`, including the newly-merged `08_AI_CONTENT_ENGINE_ORCHESTRATOR.md` and D-25). Result:

- **No conflict.** The ROI skeleton independently converged on the same architecture the SOT now codifies: workflow family `CEFFLO-00..12,99`, 3-lane creative model (`creative_lanes: {meta:[instagram,facebook], tiktok:[tiktok], threads:[threads]}` in `contracts/stage-contracts.json`), `master_concept_id` regex `^CEFFLO-[0-9]{4}-W[0-9]{2}-E[0-9]{3}$` (exact match to `07_MARKETING_MEMORY.md` §5 / Addendum A2's mapping), separate AI QA (06) and Founder Approval (07) gates, idempotent Postgres migration convention.
- **Both changesets are additive and non-overlapping.** This session's branch (`claude/flow-3-vendor-web-desktop-completion`) only touched `docs/`. The ROI worktree only added `automation/`. Both start from the same commit (`2e51dca`). A merge of the two is file-disjoint — no conflict markers expected.
- **Genuine gaps found (additive fixes, not conflicts), folded into Phase 0/11 below:**
  1. `fixtures/sot_manifest.json` resolves only 5 SOT domains (product, brand, audience, claims, content). It does not yet include `04_CREATIVE_PLAYBOOK.md`, `06_AI_MARKETING_ENGINE_MASTER.md`, `07_MARKETING_MEMORY.md`, `08_AI_CONTENT_ENGINE_ORCHESTRATOR.md`, or `05_PAID_GROWTH_PLAYBOOK.md` — it predates today's SOT reconciliation and was scoped to the offline ROI smoke test only.
  2. No AI Router, no provider config, and no cost-observability table exist yet — expected, this is exactly the boundary the ROI skeleton stopped at by design (`CEFFLO_AI_MODE=stub`).
  3. The target Postgres instance for `cefflo_content_engine` was not confirmed applied anywhere (n8n's own dedicated Postgres vs. the product's Supabase Postgres). Recommended default: **Supabase**, not n8n's internal Postgres (the ROI README itself states the migration "does not modify n8n's internal tables," implying a separate target was always intended). This must be confirmed, not assumed, in Phase 0.
- **Legacy workflow confirmed isolated already by design.** `CEFFLO -  Content Creator` (OpenAI-hardcoded prototype) and `CEFFLO - 00 - Orchestrator Test` are both outside the generated `CEFFLO-00..12,99` family and were untouched by the ROI import. Phase 1 makes this explicit/discoverable rather than merely incidental.

**Conclusion: GO. No new material conflict. This Master MD is safe to approve for execution.**

---

## 1. RULES (apply to every phase)

1. Inspect before changing. Never assume file/DB/credential state — verify empirically, as this document and its two predecessor audits did.
2. Preserve `CEFFLO - 00 - Orchestrator Test` and `CEFFLO -  Content Creator` exactly as found — see Phase 1. Do not delete either.
3. Do not delete, rename, archive, or overwrite existing Cefflo MD/SOT files. Extensions are additive.
4. Do not invent product claims, brand rules, audience facts, credentials, API keys, account IDs, model pricing, or rate limits. Where a fact must be current (model identifiers, pricing, rate limits, reasoning parameters), re-verify against official DeepSeek documentation and the exact installed n8n package at execution time — do not reuse this document's or the prior audit's snapshot as production truth without re-checking (see Phase 17).
5. GitHub remains the canonical/static SOT; PostgreSQL remains dynamic operational state and Marketing Memory; n8n remains the orchestrator; DeepSeek is a worker the AI Router calls, never the orchestrator.
6. One canonical `CEFFLO - AI Router` sub-workflow. No stage workflow calls a provider node directly. No business logic duplicated between the native-node path and the direct-API path.
7. Research & Angle Miner (02) and Master Concept Builder (03) stay separate stages. Meta stays one lane for Instagram+Facebook by default. AI QA (06) and Founder Approval (07) stay separate gates.
8. Retry only the failed/revision-targeted stage or lane. Never regenerate passed upstream work.
9. No live auto-publishing, no schedule activation, no advertising spend, at any point in this task.
10. All credentials/secrets are references only (n8n's encrypted credential store), never committed values, never echoed in chat, logs, or this document.
11. If a genuinely new material Founder-level conflict surfaces during execution (not covered by the three resolved blockers), STOP on that item and report it — do not resolve it silently.
12. Every phase below produces evidence (files, test output, query results) before being marked done. No "green" claim without it.

---

## 2. CANONICAL WORKFLOW INVENTORY (current state, verified)

| Workflow | n8n status | Source | AI wiring |
|---|---|---|---|
| CEFFLO - 00 - Master Orchestrator | Imported, inactive | `automation/n8n/content-engine/workflows/00_-_Master_Orchestrator.json` (generated) | none (deterministic) |
| CEFFLO - 01 - SOT Retrieval | Imported, inactive | `01_-_SOT_Retrieval.json` | none (git-adapter) |
| CEFFLO - 02 - Research & Angle Miner | Imported, inactive | `02_-_Research_and_Angle_Miner.json` | **AI Router target** |
| CEFFLO - 03 - Master Concept Builder | Imported, inactive | `03_-_Master_Concept_Builder.json` | **AI Router target** |
| CEFFLO - 04 - Creative Router | Imported, inactive | `04_-_Creative_Router.json` | none (deterministic routing) |
| CEFFLO - 05A - Meta Creator | Imported, inactive | `05A_-_Meta_Creator.json` | **AI Router target** |
| CEFFLO - 05B - TikTok Creator | Imported, inactive | `05B_-_TikTok_Creator.json` | **AI Router target** |
| CEFFLO - 05C - Threads Writer | Imported, inactive | `05C_-_Threads_Writer.json` | **AI Router target** |
| CEFFLO - 06 - AI QA | Imported, inactive | `06_-_AI_QA.json` | **AI Router target** |
| CEFFLO - 07 - Founder Approval | Imported, inactive | `07_-_Founder_Approval.json` | none (human gate) |
| CEFFLO - 08 - Publisher | Imported, inactive | `08_-_Publisher.json` | none, STUBBED |
| CEFFLO - 09 - Analytics & Scoring | Imported, inactive | `09_-_Analytics_and_Scoring.json` | optional AI Router target (interpretation only) |
| CEFFLO - 10 - Marketing Memory | Imported, inactive | `10_-_Marketing_Memory.json` | optional AI Router target (synthesis only) |
| CEFFLO - 11 - Weekly Winner Engine | Imported, inactive | `11_-_Weekly_Winner_Engine.json` | none (deterministic scoring) |
| CEFFLO - 12 - Paid Growth | Imported, inactive | `12_-_Paid_Growth.json` | none, zero-spend STUBBED |
| CEFFLO - 99 - Error & Recovery | Imported, inactive | `99_-_Error_and_Recovery.json` | none |
| CEFFLO - 00 - Orchestrator Test | Pre-existing prototype, inactive | n8n UI only (not in `automation/`) | none (Manual Trigger + Set) |
| CEFFLO -  Content Creator | Pre-existing prototype, inactive | n8n UI only (not in `automation/`) | **LEGACY — OpenAI hardcoded, see Phase 1** |

Every stage workflow above is currently a single deterministic `n8n-nodes-base.code` stub (confirmed by direct inspection of the generated JSON), triggered by `n8n-nodes-base.executeWorkflowTrigger`, produced by `automation/n8n/content-engine/scripts/generate-workflows.mjs`. AI wiring is added by extending that generator script and regenerating — never by hand-editing the JSON files directly, to keep one source of truth.

---

## 3. PHASE 0 — REPO/WORKTREE RECONCILIATION & TARGET CONFIRMATION

1. Confirm with the Founder (or the credential holder) which Postgres instance `cefflo_content_engine` should target — default recommendation: the product's Supabase Postgres, not n8n's dedicated internal Postgres (`cefflo-n8n-postgres`, reserved for n8n's own tables). Do not apply the migration until this is confirmed.
2. Merge the `codex/n8n-content-engine-roi` worktree's `automation/` directory into the working branch (`claude/flow-3-vendor-web-desktop-completion` or whatever branch the Founder designates), as one clean additive commit — no file overlap with this session's SOT-only changes, verified in §0 above.
3. Extend `automation/n8n/content-engine/fixtures/sot_manifest.json` with the missing canonical domains:
   ```json
   { "domain": "creative_playbook", "source": "docs/cefflo/sot/marketing/04_CREATIVE_PLAYBOOK.md", "section": "Creative Playbook" },
   { "domain": "marketing_memory", "source": "docs/cefflo/sot/marketing/07_MARKETING_MEMORY.md", "section": "Marketing Memory" },
   { "domain": "engine_master", "source": "docs/cefflo/sot/marketing/06_AI_MARKETING_ENGINE_MASTER.md", "section": "AI Marketing Engine Master" },
   { "domain": "orchestrator", "source": "docs/cefflo/sot/marketing/08_AI_CONTENT_ENGINE_ORCHESTRATOR.md", "section": "Orchestrator" },
   { "domain": "paid_growth", "source": "docs/cefflo/sot/marketing/05_PAID_GROWTH_PLAYBOOK.md", "section": "Paid Growth" }
   ```
   Verify each path resolves via `adapters/github-sot.mjs`'s `git show` mechanism against the merged commit before proceeding — `ERROR_SOT` must not occur.
4. Evidence: merge commit hash, extended manifest file, one successful `resolveCanonicalSot()` dry run covering all 10 domains.

---

## 4. PHASE 1 — LEGACY WORKFLOW ISOLATION

1. Rename `CEFFLO -  Content Creator` to `CEFFLO - LEGACY - Content Creator (non-canonical, OpenAI prototype)` in n8n (a name-only update via the n8n UI or REST API — no node/logic change, no activation).
2. Add a `n8n-nodes-base.stickyNote` node to that workflow reading: *"Legacy prototype. Not part of the canonical CEFFLO-00..12,99 family. Hardcodes an OpenAI credential directly. Excluded from the AI Router and from production routing. Preserved for reference only per Founder decision 2026-09-10. Do not reactivate or extend."*
3. Leave `CEFFLO - 00 - Orchestrator Test` exactly as-is (already correctly scoped as a smoke-test prototype per `08_AI_CONTENT_ENGINE_ORCHESTRATOR.md` §21 — no rename needed, it was never presented as canonical).
4. Do not touch the `OpenAI account` credential — leave it exactly as-is; it remains attached only to the now-clearly-labeled legacy workflow.
5. Do not migrate the legacy workflow's OpenAI wiring into the new AI Router. Do not delete the legacy workflow. Removal is a separate, later Founder decision, only after the DeepSeek AI Router passes validation (Phase 14/16).
6. Evidence: before/after workflow name, screenshot or exported JSON diff showing only the name + sticky-note change, confirmation the workflow remains inactive.

---

## 5. PHASE 2 — PROVIDER / MODEL CONFIGURATION BOUNDARY

One centralized config, reconciling the Founder's requested variable names with this repo's existing `CEFFLO_` prefix convention (already used in `.env.example`, `.env.staging.example`, and the ROI skeleton's own `automation/n8n/content-engine/.env.example`):

```
CEFFLO_PRIMARY_LLM_PROVIDER=deepseek
CEFFLO_PRIMARY_LLM_MODEL=<resolved current identifier — do not hardcode literally, see Phase 17>
CEFFLO_PRIMARY_LLM_TIER=pro
CEFFLO_FALLBACK_LLM_PROVIDER=            # empty by default — OpenAI/Anthropic are optional, not required for V1
CEFFLO_FALLBACK_LLM_MODEL=
```

Extends `automation/n8n/content-engine/.env.example` alongside the existing `CEFFLO_AI_MODE`, `CEFFLO_MEDIA_MODE`, etc. — same file, same convention, no parallel config system. This is the **single point of change**: updating `CEFFLO_PRIMARY_LLM_MODEL` (or provider) updates every stage that calls the AI Router, because no stage workflow ever names a model or provider itself.

The AI Router (Phase 4) reads this config once, at the top of its execution, via a Code node — not per-stage, not duplicated.

Evidence: extended `.env.example`, a config-resolution unit test (Phase 14) proving one env change updates the Router's resolved provider/model without touching any stage workflow.

---

## 6. PHASE 3 — DEEPSEEK CREDENTIAL SETUP

1. Founder or credential holder creates the `DeepSeek` credential directly in the n8n UI (`https://n8n.cefflo.com`, or `http://127.0.0.1:5678` on the VPS) — credential type `DeepSeek` (`deepSeekApi`), field `API Key`. Never pasted into agent chat or any tool-call transcript, per this repo's established out-of-band credential pattern (same as the Supabase staging credential handling in `AI_ACTIVE_CHECKPOINT.md`).
2. Base URL is fixed by the credential type itself (`https://api.deepseek.com`, hidden field) — nothing to configure there.
3. Confirm the credential test passes (`GET /models` — built into the credential type's own `test.request`).
4. Evidence: credential `id`/`name`/`type` visible via a read-only query (as done in the prior audit) — never the key value.

---

## 7. PHASE 4 — AI ROUTER SUB-WORKFLOW DESIGN

New workflow: `CEFFLO - AI Router` (added to `generate-workflows.mjs`'s `ids`/`names` maps, id convention `10000000-0000-4000-8000-0000000000AR`, or an equivalent free slot — do not collide with existing 00-99 ids).

```text
CEFFLO agent/stage workflow (Execute Sub-workflow call)
        │  input: { workload_type: LOW|HIGH|MAX, stage, task_payload, run_id, task_id, master_concept_id }
        ▼
CEFFLO - AI Router
  1. Resolve provider/model/tier from CEFFLO_PRIMARY_LLM_* config (Phase 2)
  2. Resolve reasoning tier → native node vs direct API path (Phase 5/6/7)
  3. Call the resolved path
  4. Validate response against the stage's structured-output contract (Phase 8)
  5. Write one cost/observability log row (Phase 9)
  6. Return normalized envelope: { status: OK|ERROR_AI, provider, requested_model, actual_model, output, usage, duration_ms }
        ▼
back to caller — caller never sees provider-specific shape
```

Every canonical CEFFLO AI workload (02, 03, 05A, 05B, 05C, 06, optionally 09/10 for interpretation/synthesis only) calls this one sub-workflow. No stage workflow embeds a provider node directly going forward — this retires the "stub AI mode" Code nodes in those stages in favor of a real call gated by `CEFFLO_AI_MODE`.

Evidence: generated `CEFFLO - AI Router` workflow JSON, one stage workflow (start with 03 - Master Concept Builder) regenerated to call it via Execute Sub-workflow instead of its current stub.

---

## 8. PHASE 5 — NATIVE n8n DEEPSEEK NODE INTEGRATION PATH

Use for LOW and HIGH tier calls (classification/tagging/metadata/formatting/extraction for LOW; research/angle-mining/hooks/scripts/copywriting/normal agent reasoning for HIGH), where the installed native node's exposed options are sufficient:

- Node: `@n8n/n8n-nodes-langchain.lmChatDeepSeek` (confirmed bundled in the exact running package, `@n8n/n8n-nodes-langchain` v2.36.5, no install needed).
- Credential: `deepSeekApi` (Phase 3).
- Model: set from `CEFFLO_PRIMARY_LLM_MODEL` (Phase 2), never hardcoded in the node itself.
- Options available and usable today: `temperature`, `maxTokens`, `responseFormat` (`json_object` for structured stage outputs — required for every stage's contract), `topP`, `frequencyPenalty`, `presencePenalty`, `timeout`, `maxRetries`.
- Before first use: call the node's live `loadOptions` (`GET /models`) with the real credential to confirm the exact valid current model list — do not trust this document's snapshot of identifiers (see Phase 17).

---

## 9. PHASE 6 — DIRECT DEEPSEEK API PATH (via the Router, not scattered)

Use only for **MAX tier** calls that need explicit reasoning control (`reasoning_effort` / `thinking`) the native node does not expose in its UI as installed, or any other verified-missing API feature:

- One `n8n-nodes-base.httpRequest` node, inside the AI Router sub-workflow only (never duplicated into stage workflows), calling `https://api.deepseek.com/chat/completions` (or `/v1/chat/completions` — confirm exact path against current docs at execution time, both forms have appeared in different DeepSeek doc pages and must be pinned down, not guessed) with the `deepSeekApi` credential's `apiKey` for the `Authorization: Bearer` header.
- Request body constructed from the same normalized input the native path receives, plus `reasoning_effort`/`thinking` fields resolved from the reasoning-tier config (Phase 7) — **verify the exact current field names and accepted values against official DeepSeek documentation at execution time**, not from this document alone (this document's audit snapshot is dated 2026-09-10 and DeepSeek's API surface is demonstrably changing this month).
- Response parsed into the same normalized envelope the native path returns, so stage workflows and the QA/cost-logging steps never know which path served the call. This satisfies the "one consistent contract, no duplicated business logic" requirement.

---

## 10. PHASE 7 — REASONING ROUTING POLICY

Router resolves `workload_type` → path + parameters:

| Tier | Examples | Path | Notes |
|---|---|---|---|
| LOW | classification, tagging, metadata, simple formatting/extraction, simple platform adaptation | Native node | Low `temperature`, `responseFormat: json_object` |
| HIGH | research, audience analysis, angle mining, hooks, script/copy generation, normal agent reasoning, content analysis | Native node | Default `temperature`, model default (e.g. reasoning-capable identifier resolved per Phase 17) |
| MAX | difficult strategy, complex conflicting evidence, exceptional QA, Product Truth/Brand Brain conflicts, high-impact reasoning | Direct API path (Phase 6) if the native node still lacks `reasoning_effort`/`thinking` at execution time; native node otherwise | Re-check the native node's exposed options at execution time — if a newer `@n8n/n8n-nodes-langchain` release has added these fields by then, prefer the native path per Phase 5's "use native where it cleanly supports the workload" rule |

The Router, not any stage workflow, owns this decision — a stage only declares its `workload_type`.

---

## 11. PHASE 8 — STRUCTURED CONTRACTS EXTENSION

Extend (never replace) the existing contracts:
- `contracts/global-envelope.schema.json`: no change needed — already carries `run_id`/`task_id`/`stage`/`status`/etc.; the AI Router's own request/response shape becomes a new schema file, `contracts/ai-router-envelope.schema.json`, with `required: [workload_type, stage, provider, requested_model, status]` and optional `actual_model`, `usage`, `duration_ms`.
- `contracts/stage-contracts.json`: add an `"ai_router"` block listing `workload_tiers: ["LOW","HIGH","MAX"]` and `response_format: "json_object"` requirement per AI-calling stage (02, 03, 05A, 05B, 05C, 06).
- Every AI Router response must validate against the calling stage's existing structured-output requirement before being handed back — reuse `tests/validate_artifacts.mjs`'s existing validation approach rather than writing a second validator.

---

## 12. PHASE 9 — COST OBSERVABILITY

New migration `automation/n8n/content-engine/migrations/202609100002_content_engine_ai_router.sql` (additive, `IF NOT EXISTS`/`CREATE OR REPLACE`, same idempotent convention as `202609100001_content_engine_roi.sql`), applied to the Postgres instance confirmed in Phase 0:

```sql
CREATE TABLE IF NOT EXISTS cefflo_content_engine.ai_call_log (
  call_id UUID PRIMARY KEY,
  run_id UUID NULL REFERENCES cefflo_content_engine.content_engine_runs(run_id) ON DELETE SET NULL,
  workflow_name TEXT NOT NULL,
  stage TEXT NOT NULL,
  provider TEXT NOT NULL,
  requested_model TEXT NOT NULL,
  actual_model TEXT NULL,
  reasoning_tier TEXT NOT NULL CHECK (reasoning_tier IN ('LOW','HIGH','MAX')),
  input_tokens INTEGER NULL,
  cached_input_tokens INTEGER NULL,
  output_tokens INTEGER NULL,
  duration_ms INTEGER NULL,
  success BOOLEAN NOT NULL,
  retry_count INTEGER NOT NULL DEFAULT 0,
  estimated_cost NUMERIC NULL,
  error_code TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS cefflo_content_engine.ai_provider_pricing (
  provider TEXT NOT NULL,
  model TEXT NOT NULL,
  input_price_per_1k NUMERIC NOT NULL,
  cached_input_price_per_1k NUMERIC NULL,
  output_price_per_1k NUMERIC NOT NULL,
  effective_from TIMESTAMPTZ NOT NULL,
  effective_to TIMESTAMPTZ NULL,
  PRIMARY KEY (provider, model, effective_from)
);
```

`ai_provider_pricing` is the one maintainable pricing boundary — the Router looks up the row matching `(provider, actual_model, now() BETWEEN effective_from AND COALESCE(effective_to, 'infinity'))` rather than any workflow node computing cost from a hardcoded number. This directly answers the Founder's "keep pricing data/config maintainable" requirement and the concrete, already-observed DeepSeek pricing change around 2026-09-14.

The Router writes one `ai_call_log` row per call via a small `cefflo_content_engine.log_ai_call(jsonb)` function, mirroring the existing `log_event`/`persist_marketing_memory` function pattern in the ROI migration.

---

## 13. PHASE 10 — FAILURE / RETRY CONTRACT

Reuses `08_AI_CONTENT_ENGINE_ORCHESTRATOR.md` §19's Failure/Retry Matrix and the ROI skeleton's existing `CEFFLO - 99 - Error & Recovery` workflow and error codes (`ERROR_AI` already exists in `contracts/stage-contracts.json`):

- Timeout / transient error → bounded retry inside the Router (native node's `maxRetries`/`timeout`, or equivalent retry loop around the HTTP node for the direct-API path) — capped at `CEFFLO_MAX_RETRIES` (already defined, default 2).
- Rate limit (HTTP 429 or provider-specific code, confirmed against current docs at execution time) → controlled backoff before retrying, same cap.
- Malformed/invalid structured response → Phase 8 validation failure → the stage's own targeted-revision path (per `stage-contracts.json`'s `qa.revision_targets`), never a silent pass.
- Repeated failure past the retry cap → `status: ERROR_AI`, routed to `CEFFLO - 99 - Error & Recovery`, run/task/master_concept identifiers preserved, manual recovery path available (already supported: `errors.manual_recovery_preserves_ids: true`).
- No AI failure or malformed output can reach `CEFFLO - 07 - Founder Approval` marked as passed — the Router's `status` field is checked by 06 AI QA before any concept proceeds.

---

## 14. PHASE 11 — PRODUCT TRUTH / BRAND BRAIN / MARKETING MEMORY INJECTION

Handled entirely through Phase 0 step 3's extended `sot_manifest.json` and the existing `CEFFLO - 01 - SOT Retrieval` → Context Pack boundary (`contracts/context-pack.schema.json`) — the AI Router never receives raw SOT text; it receives whatever Context Pack the calling stage already assembled, per `08_AI_CONTENT_ENGINE_ORCHESTRATOR.md` §6's "Retrieval is not summarization of the whole SOT... selection of relevant authoritative sections" rule. Marketing Memory injection specifically: `CEFFLO - 02 - Research & Angle Miner` and `CEFFLO - 10 - Marketing Memory` read from `cefflo_content_engine.marketing_memory` (already defined in the ROI migration) to avoid duplicate angles/hooks, per `07_MARKETING_MEMORY.md`.

No new injection mechanism is invented — this phase is "finish wiring what Phase 0 extended," not new design.

---

## 15. PHASE 12 — QA BOUNDARY WIRING

`CEFFLO - 06 - AI QA`'s current deterministic stub (`Run Deterministic QA`) is extended, not replaced, with an AI Router call at `HIGH` tier (or `MAX` for flagged Product-Truth/Brand-Brain conflicts) for the Truth/Brand/Creative/Duplication checks in `08_AI_CONTENT_ENGINE_ORCHESTRATOR.md` §14 — deterministic checks (schema validity, duplicate ID detection) remain in the existing Code node; only judgment-requiring checks (overclaiming, tone, hook strength, duplication *similarity*, not exact-match) go through the Router. `qa_status = PASS | REVISE | REJECT` output contract is unchanged. AI QA and Founder Approval remain two separate gates — the Router never touches 07.

---

## 16. PHASE 13 — WORKFLOW MIGRATION (regeneration, not hand-editing)

1. Extend `scripts/generate-workflows.mjs` with: the new `CEFFLO - AI Router` workflow definition, and — for 02, 03, 05A, 05B, 05C, 06 — replace each stage's stub Code node with an `executeWorkflow` node calling the Router, gated by `CEFFLO_AI_MODE` (stub path preserved for offline tests, live path calls the Router).
2. Run `node scripts/generate-workflows.mjs` to regenerate the `workflows/*.json` files — this is the single source of truth; no manual JSON edits.
3. Import the regenerated + new workflow JSON into n8n **as inactive**, exactly like the original ROI import (verified via the same read-only `workflow_entity` query pattern used in the audit).
4. Do not activate anything. Do not enable any schedule node. Do not register any webhook.

---

## 17. PHASE 14 — TESTS

- Extend `tests/validate_artifacts.mjs` to also validate the new `ai-router-envelope.schema.json` contract.
- Extend `tests/roi_smoke.mjs` with an `CEFFLO_AI_MODE=stub` path through the Router (deterministic fixture response, no real API call) — proves the wiring without spending anything.
- New `tests/ai_router_config_test.mjs`: proves changing `CEFFLO_PRIMARY_LLM_MODEL` alone changes the Router's resolved model with no other file edited (Phase 2's "one change updates everything" requirement).
- New `tests/ai_router_live_smoke.mjs` (run manually, only after Phase 3's credential exists and only with explicit go-ahead): one real DeepSeek call through the Router from a manually-triggered `CEFFLO - 02` run, response validated, one `ai_call_log` row confirmed written, cost estimate confirmed non-null.
- Failure-path test: force a timeout/malformed-JSON fixture → confirm `ERROR_AI` → 99 routing, confirm no pass to 07.
- Security test (static): grep the regenerated workflow JSON and this repo for any literal DeepSeek key pattern — must find none.
- Regression test: confirm `CEFFLO - 00 - Orchestrator Test` and the renamed `CEFFLO - LEGACY - Content Creator` are byte-for-byte unchanged except the Phase 1 rename/sticky-note, and remain inactive.
- `psql -v ON_ERROR_STOP=1 -f migrations/202609100002_content_engine_ai_router.sql` against the Phase-0-confirmed target, then `tests/db_smoke.sql`-style rollback-only check for the two new tables.

---

## 18. PHASE 15 — SECURITY VALIDATION

- Confirm the DeepSeek credential is reference-only everywhere (workflow JSON contains a credential `id` reference, never a key).
- Confirm `.env.example` additions (Phase 2) contain no real values.
- Confirm no secret value was displayed in any command output, chat, or generated file during this entire task (matches the standard already held throughout both prior reports).
- Confirm `ai_provider_pricing`/`ai_call_log` contain no PII, no customer data — cost/usage metadata only.
- Confirm least-privilege: the Postgres role used for `cefflo_content_engine` writes has no broader grant than that schema (verify against whatever role Phase 0 confirms, do not assume).

---

## 19. PHASE 16 — FOUNDER REVIEW GATES

Explicit stop-and-show-Founder points, matching `06_AI_MARKETING_ENGINE_MASTER.md` §31 and `05_PAID_GROWTH_PLAYBOOK.md` §5's existing gate doctrine — none of these are bypassed by a high AI score:

1. After Phase 0: confirmed merge target branch + confirmed Postgres target — before any file is committed.
2. After Phase 3: confirmed DeepSeek credential exists and passes its test — before any live call is attempted.
3. After Phase 14's live smoke test (one real call, one concept, manual trigger only): Founder reviews the actual output, cost-log row, and QA result before any further workflow is wired to the Router.
4. Before any schedule is ever enabled or any workflow set Active: separate, explicit Founder authorization — out of scope for this Master MD entirely.

---

## 20. PHASE 17 — PRODUCTION-READINESS CRITERIA (criteria only — activation is a separate future decision)

Before any future activation is even proposed:
- Re-verify, same-day, against official DeepSeek documentation: current model identifiers (the 2026-09-14 Flash-routing change identified in the audit will have passed by then — confirm what replaced it), pricing, rate limits, reasoning-parameter contract, and the exact chat-completions endpoint path.
- Re-check the installed `@n8n/n8n-nodes-langchain` version for whether `reasoning_effort`/`thinking` have been added to the native node (may retire the direct-API MAX-tier path if so).
- Confirm `ai_provider_pricing` has a current, non-expired row for whatever model is actually pinned.
- All Phase 14 tests green, including the live smoke test, with Founder having reviewed real output.
- Legacy `Content Creator` workflow's fate (delete/keep) explicitly decided by Founder, per the original blocker-resolution instruction ("removal can be decided after the new DeepSeek-based AI Router passes validation").

---

## 21. PHASE 18 — ROLLBACK PLAN

- Workflow level: the regenerated JSON files are deterministic build output of `generate-workflows.mjs` — reverting to the pre-Router commit and re-running the script restores the exact prior stub-only state. n8n import of the reverted JSON (still inactive) fully rolls back workflow behavior.
- Database level: both new tables (`ai_call_log`, `ai_provider_pricing`) are additive-only, referenced by nothing outside themselves except a `run_id` FK with `ON DELETE SET NULL` — they can be dropped independently without touching any ROI-skeleton table, via a paired `DROP TABLE IF EXISTS` rollback migration, written alongside Phase 9's migration before it is ever applied.
- Credential level: the `DeepSeek` credential can be deleted from n8n's UI at any time without affecting any other workflow (nothing else references it until Phase 13 wires stages to the Router).
- Legacy workflow: Phase 1's rename/sticky-note is trivially reversible (rename back, remove the note) if ever needed, though there's no reason to.
- No rollback step touches `main`, staging, or any production system — everything in this plan lives in the content-engine's own schema, the n8n instance's own workflow set (all inactive), and this repo's own docs/scripts.

---

## 22. DEFINITION OF DONE

This implementation is complete for its scope when:

1. `automation/n8n/content-engine` is merged into a real, reviewable branch (Phase 0), with the SOT manifest covering all 10 canonical domains.
2. `CEFFLO -  Content Creator` is clearly renamed/annotated as legacy/non-canonical, untouched otherwise, still inactive (Phase 1).
3. `CEFFLO_PRIMARY_LLM_PROVIDER`/`MODEL`/`TIER` is the single configuration boundary — proven by a passing config-resolution test (Phase 2/14).
4. A `DeepSeek` credential exists in n8n's encrypted store, tested, never exposed (Phase 3).
5. `CEFFLO - AI Router` exists as one shared sub-workflow; no stage workflow calls a provider node directly (Phase 4).
6. Native-node path (LOW/HIGH) and direct-API path (MAX, where needed) both work through the Router with one consistent output contract (Phase 5/6/7).
7. Structured contracts extended and validated (Phase 8).
8. `ai_call_log` + `ai_provider_pricing` exist, are written to on every call, and pricing is never hardcoded per-node (Phase 9).
9. Failure/retry/escalation behavior matches the existing Failure/Retry Matrix; no AI failure silently reaches Founder Approval as passed (Phase 10).
10. Product Truth/Brand Brain/Marketing Memory injection flows through the existing Context Pack boundary, nothing bypasses it (Phase 11).
11. AI QA (06) uses the Router only for judgment checks; deterministic checks stay deterministic; QA and Founder Approval remain separate gates (Phase 12).
12. All stage workflows are regenerated via the script (not hand-edited), reimported inactive, no schedule/webhook enabled (Phase 13).
13. All Phase 14 tests pass, including one real, Founder-reviewed, single-concept live smoke call (Phase 14/16).
14. Security validation passes: no secret ever exposed, credential reference-only, least-privilege DB role confirmed (Phase 15).
15. Every Founder Review Gate in Phase 16 was actually honored, not skipped.
16. Production-readiness criteria (Phase 17) are documented as a re-verification checklist for whenever activation is separately proposed — not satisfied by this document itself.
17. A tested rollback path exists at every layer touched (Phase 18).
18. Nothing was activated, committed, or pushed as a side effect of doing this work — this Master MD's own execution ends at "ready for Founder to decide on activation," exactly like the ROI skeleton it extends.
