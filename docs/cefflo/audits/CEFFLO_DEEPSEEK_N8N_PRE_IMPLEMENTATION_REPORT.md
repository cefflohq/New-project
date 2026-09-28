**Status:** PRE-IMPLEMENTATION AUDIT — no implementation performed. No workflows activated, no credentials created, no files committed/pushed, no infra created.
**Date:** 2026-09-10
**Scope:** Audit + reconciliation + architecture/implementation plan for making DeepSeek V4 Pro the primary LLM/AI agent for the Cefflo AI Content Engine, per new Founder-approved direction. n8n remains orchestrator.
**Result:** BLOCKED — FOUNDER DECISION REQUIRED (see §K/§L). No doctrine conflict found; the blockers are unresolved *operational* facts, not SOT conflicts.

---

## A. ENVIRONMENT TRUTH

**Repository**
- Working directory: `/home/cefflo/New-project`. Branch: `claude/flow-3-vendor-web-desktop-completion`. HEAD: `2e51dca` (2026-09-04, "docs: reconcile Pricing/Vendor Flutter/Marketing Memory into docs/cefflo/sot/").
- Working tree: not clean — carries the 7 modified + 2 new files from the prior AI Content Engine v1.1 SOT reconciliation (D-25), all uncommitted, all preserved untouched by this audit. Pre-existing untracked scratch content (`.claude/`, `docs/cefflo/finos-framer-source-audit.*`, `previews/*`) also preserved untouched.
- This session runs **directly on the Contabo VPS** (`vmi3532975`), not an isolated sandbox — the "live n8n environment" the task asks about is this machine.
- No `.env` file exists in the repo; only `.env.example` / `.env.staging.example` (placeholders only, `CEFFLO_` prefix convention).

**n8n**
- Live instance: Docker container `cefflo-n8n-new`, image `docker.n8n.io/n8nio/n8n:2.36.8`, bound to `127.0.0.1:5678` only, `N8N_HOST=n8n.cefflo.com` / `N8N_PROTOCOL=https` (reverse-proxied, not independently re-verified which edge service terminates TLS). Health check `GET /healthz` → `{"status":"ok"}`. Up ~8 hours at audit time.
- Backed by dedicated Postgres container `cefflo-n8n-postgres` (`postgres:16-alpine`), healthy, separate from the product's Supabase Postgres.
- A second, **stopped** legacy container `cefflo-n8n-old` (`n8nio/n8n:latest`, plain HTTP, no dedicated Postgres — likely SQLite-backed) exists, defined by `/home/cefflo/orchestrator/n8n/compose.yml`. A backup `/home/cefflo/n8n-backup-before-postgres.tar.gz` (439 KB, same day) is consistent with a same-day migration from that old stack to the new dedicated-Postgres one (`/home/cefflo/n8n-stack/docker-compose.yml`).
- No workflow is active. No webhook is registered. Confirmed by direct read-only SQL against `cefflo-n8n-postgres` (`workflow_entity.active` = false for all 18 rows; `webhook_entity` empty).

**Infrastructure**
- Ports 80/443/22 listening on the host; local Supabase stack (`supabase_db_cefflo-local` etc.) running and healthy, unrelated to n8n's own Postgres.
- Two separate PostgreSQL domains exist: n8n's own internal Postgres (workflow/credential storage — must not be repurposed for content-engine data, per the ROI skeleton's own README) and the Supabase stack (product backend). The content-engine ROI migration targets a new `cefflo_content_engine` schema; **which Postgres instance it is meant to run against, and whether it has actually been applied anywhere, was not confirmed** — flagged as an open item, not assumed either way.
- Secret handling: exactly **one** n8n credential exists (`OpenAI account`, type `openAiApi`) — name/type only read, no values. No `DeepSeek` credential exists yet. No secret value of any kind was displayed at any point in this audit (env var inspection was name-only via `docker inspect ... | cut -d= -f1`; `.env` files were value-redacted before display; credential table query selected only `id, name, type`).

---

## B. EXISTING WORKFLOW TRUTH

The live n8n instance currently holds **18 workflows, all inactive**:

1. **14 workflows matching the canonical `CEFFLO - 00` .. `12`, `99` family** — imported 2026-09-10 15:57:55 UTC. These exactly match the JSON files in `automation/n8n/content-engine/workflows/` found in a **separate git worktree** of this same repository, at `/tmp/cefflo-n8n-content-engine`, on branch `codex/n8n-content-engine-roi` (HEAD `2e51dca`, same base as this branch). That directory is **uncommitted and untracked** in that worktree, and the branch has **not been pushed to `origin`**. It corresponds to `/home/cefflo/CEFFLO_N8N_CONTENT_ENGINE_ROI_IMPLEMENTATION_MASTER.md`, a task file at the home directory (not git-tracked — evidently handed to Codex directly, out-of-band).
   - Per that skeleton's own `README.md`: "All provider modes are stubbed and every workflow is inactive." `CEFFLO_AI_MODE=stub`, `CEFFLO_MEDIA_MODE=stub`, `CEFFLO_PUBLISH_MODE=stub`, `CEFFLO_ANALYTICS_MODE=stub`, `CEFFLO_PAID_GROWTH_MODE=stub` (its `.env.example`). Publisher rejects anything but `APPROVE`/`APPROVED`; Paid Growth always reports zero spend and rejects live mode; Founder Approval is mandatory.
   - This skeleton **already converged independently** on the same `CEFFLO-00..12,99` naming, the 3-lane Meta-shared model, and the split CEFFLO-11/12 weekly workflows that this session's separate SOT reconciliation (D-25) approved today — good alignment, no naming conflict between what's already built and what the SOT now says.
   - No AI provider is wired into any of these 14 workflows — confirmed no `deepseek|openai|anthropic|claude|gpt-` string match beyond generic doc-comment references to the concept; the one `Bearer`-pattern grep hit was a false positive (a `description` field, no token).

2. **2 workflows outside that set, pre-dating the ROI import (created 07:49–10:06 UTC, before the 15:57 import):**
   - `CEFFLO - 00 - Orchestrator Test` (2 nodes: manual trigger + a Set node). Matches `08_AI_CONTENT_ENGINE_ORCHESTRATOR.md` §21's explicitly-preserved smoke-test prototype. Trivial, no AI node.
   - `CEFFLO -  Content Creator` (double space in name; 8 nodes: manual trigger → Set → Switch (routes by channel) → per-platform brief Set nodes for TikTok/Instagram/Facebook/Threads → one `@n8n/n8n-nodes-langchain.openAi` node named "CEFFLO - Content AI", wired to the sole existing OpenAI credential). **Undocumented** — not mentioned in the ROI master, the ROI skeleton's own README, or any SOT/decision record found. It is inactive with no webhook, so it poses no live risk, but it is the only place in the entire instance where an AI provider is actually wired to a real credential today, and it hardcodes OpenAI directly with no router/abstraction layer.

Nothing was deleted, activated, deactivated (already inactive), or modified during this audit. All 18 workflows, the one credential, and both containers are exactly as found.

---

## C. SOT RECONCILIATION — does DeepSeek-primary conflict with canonical doctrine?

Checked for an explicit LLM-vendor requirement in every canonical document that could plausibly name one:
- `docs/cefflo/sot/marketing/06_AI_MARKETING_ENGINE_MASTER.md` §9 Model Routing — defines FAST/REASONING/CREATIVE/REVIEWER **classes**, names no vendor.
- `docs/cefflo/sot/marketing/08_AI_CONTENT_ENGINE_ORCHESTRATOR.md` §0, §4 — "LLMs / AI workers," "Media provider is not permanently locked" — vendor-agnostic throughout.
- `docs/cefflo/sot/marketing/04_CREATIVE_PLAYBOOK.md` §14 Creative Tool Router — "Provider names belong in configuration, not doctrine."
- `docs/cefflo/sot/marketing/05_PAID_GROWTH_PLAYBOOK.md` — silent on LLM vendor (only names ad platforms: Meta/TikTok/Google).

**No canonical SOT document names a required LLM vendor. No conflict exists.** The new Founder decision (DeepSeek V4 Pro primary, n8n remains orchestrator, OpenAI/Anthropic optional-only) fills a gap the SOT deliberately left open for configuration, per its own doctrine. This is confirmed, not assumed — every document that could have pinned a vendor was checked and does not.

The only "OpenAI" footprint anywhere is the undocumented `Content Creator` prototype (§B.2) — not SOT doctrine, not a Founder decision record, and per `00_MARKETING_KNOWLEDGE_PACK_INDEX.md`'s own Authority rule ("Founder decision wins"), does not bind or conflict with this new direction.

Non-doctrine findings that still need a Founder call are in §K, not here — they are facts about unmerged/undocumented work, not SOT conflicts.

---

## D. RECOMMENDED INTEGRATION ARCHITECTURE

```text
n8n stage workflow (02, 03, 05A/05B/05C, 06, 09, 10-synthesis)
        │
        ▼
CEFFLO - AI Router  (one shared n8n sub-workflow, called via Execute Sub-workflow —
        │             not copy-pasted into each stage)
        ▼
resolve: workload_type (LOW/HIGH/MAX) → provider + model + params
        │             (Code node reading CEFFLO_AI_PROVIDER / CEFFLO_AI_PRIMARY_MODEL,
        │              extending the existing CEFFLO_ env-var convention)
        ▼
DeepSeek Chat Model node (native `lmChatDeepSeek`, credential `deepSeekApi`)
        │
        ▼
normalized response + cost/usage envelope → cost log write → back to caller
```

- **V1:** the Router resolves to DeepSeek in every branch. OpenAI/Anthropic branches are defined in the Router's config schema but return "not configured" unless a Founder-approved credential is added later — satisfies "must not require reconstruction of the Content Engine" for future providers, without wiring them now.
- Deterministic operations (scheduling, DB reads/writes, workflow state, approval state, routing, publishing triggers, IDs, timestamps, retries, dedup, schema validation) stay in plain n8n nodes (Postgres node, Code node, Switch/If, Cron) — never routed through the AI Router. The ROI skeleton's stage workflows already separate deterministic Code-node contract validation from any AI call (confirmed by inspecting `contracts/stage-contracts.json` and the stub Code nodes), so the Router slots into an existing seam rather than requiring new ones.

---

## E. DEEPSEEK API VERIFICATION (verified today, 2026-09-10, against official docs and the exact package installed in the live instance — not from memory)

- Base URL: `https://api.deepseek.com` (OpenAI-compatible surface). An Anthropic-compatible surface also exists at `/anthropic`, not needed here.
- Auth: `Authorization: Bearer <api_key>`.
- **Time-sensitive fact — verify again before pinning a literal model ID:** DeepSeek's own pricing/model docs state that from **12:00 Beijing Time, 2026-09-14** (4 days from this audit) — until "V4.1 Pro" ships — requests to model id `deepseek-v4-pro` will be **rerouted to V4.1 Flash and billed at Flash pricing**. `deepseek-flash` (→ DeepSeek-V4.1-Flash) is the current GA/preferred identifier. Older identifiers `deepseek-v4-flash`, `deepseek-v4-flash-vision-exp` are retired-but-still-accepted.
- **Ground-truth check against the exact installed package** (`@n8n/n8n-nodes-langchain`, bundled, v2.36.5, inside the running `cefflo-n8n-new` container — inspected directly, not assumed from n8n's public docs): a **native `DeepSeek Chat Model` node** (`lmChatDeepSeek`) and **native `DeepSeek` credential type** (`deepSeekApi`) already ship with this exact n8n version — no community-node install needed. This is the cleanest of the three options the Founder's brief asked to evaluate (native > OpenAI-compatible hack > raw HTTP), and it is directly confirmed available today.
  - Credential fields (from the installed `.credentials.js`): `apiKey` (string, password, required), `url` (hidden field, fixed default `https://api.deepseek.com`) — base URL is not user-editable in the UI.
  - Node model parameter: free `options` field with a dynamic `loadOptions` call to `GET /models` on the real API to populate the live current list; static default `deepseek-chat`. The node's own built-in hint text says *"deepseek-chat = V3.2 non-thinking, deepseek-reasoner = V3.2 thinking... avoid older V3 and R1 snapshots"* — this is **inconsistent** with DeepSeek's current V4.1/V4-Pro naming found in official docs today, i.e. the bundled node's hint text is stale relative to DeepSeek's naming as of this audit. **Do not trust either source blindly — resolve the exact production model id from the node's live `/models` call once a real key is configured**, per the Founder's own instruction not to invent parameters.
  - Other exposed options: `frequencyPenalty`, `maxTokens` (UI caps at 32768 — DeepSeek's actual context window was not independently re-confirmed and may differ), `responseFormat` (`text`/`json_object` — JSON mode supported), `presencePenalty`, `temperature`, `timeout` (default 360000 ms), `maxRetries` (default 2), `topP`.
- **Gap found:** the installed node does **not** expose DeepSeek's `reasoning_effort` / `thinking` parameters anywhere in its UI, even though DeepSeek's official API documents them (`"reasoning_effort": "high"`, `"thinking": {"type": "enabled"}`). This means the Founder's LOW/HIGH/MAX reasoning-routing policy (§3 of the brief) **cannot be fully implemented through the native node as installed today**. MAX-tier calls needing explicit reasoning control would require a plain HTTP Request node hitting `/chat/completions` directly for that tier only, or an n8n/langchain-node upgrade. LOW/HIGH tiers are approximable today via model choice (`deepseek-chat` vs `deepseek-reasoner`) and temperature/maxTokens tuning without the raw parameter.
- Token usage / cached-token reporting and exact current rate limits were **not** confirmed in this pass — DeepSeek's docs relegate these to separate Pricing/Rate-Limit pages not yet fetched. Must be re-verified immediately before building §G's cost-observability node, per the "verify, don't invent" instruction.

---

## F. SECURITY PLAN

- The DeepSeek key lives **only** in n8n's own encrypted credential store, as a new `DeepSeek` credential (type `deepSeekApi`) — the same mechanism already used for the existing `OpenAI account` credential. Never in workflow JSON, never in a repo-committed `.env`, never logged.
- The repo's app-level `.env.example` / `.env.staging.example` are a **separate secret domain** (web app ↔ Supabase) from n8n's credential store. Do not add DeepSeek keys there — that would create the duplicate configuration system the Founder's brief explicitly says to avoid.
- Naming: reconcile the Founder brief's suggested `DEEPSEEK_API_KEY` / `DEEPSEEK_BASE_URL` / `DEEPSEEK_PRIMARY_MODEL` to the **already-established** `CEFFLO_` prefix convention used both by the repo's `.env.example` and the ROI skeleton's own `.env.example` (`CEFFLO_AI_MODE`, `CEFFLO_MEDIA_MODE`, etc.) — i.e. `CEFFLO_AI_PROVIDER=deepseek`, `CEFFLO_AI_PRIMARY_MODEL=<id resolved per §E>`. The API key itself is **not** an env var at all under this design — it lives in n8n's credential store, referenced by credential ID from the Router sub-workflow, matching how the existing OpenAI credential already works.
- No secret value of any kind was read, requested, or displayed anywhere in this audit.

---

## G. COST OBSERVABILITY PLAN

- Every AI Router call writes one row to a `cefflo_content_engine.ai_call_log`-style table (extending the ROI skeleton's existing `cefflo_content_engine` schema/migration rather than a parallel one) with: workflow, stage/task, provider, model, reasoning tier (LOW/HIGH/MAX), input tokens, output tokens, cached tokens (if/when DeepSeek exposes them — unconfirmed, §E), execution time, success/failure, retry count, estimated cost, timestamp.
- Pricing lives in one small config/lookup, never hardcoded per node — DeepSeek's own pricing is demonstrably mid-change this very month (§E's Sept 14 routing/pricing notice is a live example of exactly why this requirement matters, not a hypothetical).

---

## H. FAILURE & RECOVERY PLAN

Maps directly onto the already-built `CEFFLO - 99 - Error & Recovery` workflow and the Failure/Retry Matrix in `08_AI_CONTENT_ENGINE_ORCHESTRATOR.md` §19 — no new failure-handling model is needed, DeepSeek just becomes another provider plugged into what the ROI skeleton already stubs:
- Timeout / temporary failure → bounded retry (node's own `maxRetries`/`timeout`, default 2/360s, tunable).
- Rate limit → backoff (exact numbers still unconfirmed, §E — tune once verified).
- Invalid structured response → routed through the existing AI QA (06) validation/revision path, never a silent pass.
- Repeated failure → `WAITING_AI`/`ERROR` state per the existing Workflow State enum, routed to 99.

---

## I. IMPLEMENTATION PLAN (sequenced — none of this executed yet)

1. Founder resolves the three blockers in §K.
2. Merge/reconcile the `codex/n8n-content-engine-roi` worktree onto a real, pushed branch (or explicitly supersede it) so the AI Router is built on committed, reviewable ground rather than a local-only worktree.
3. Create the `DeepSeek` credential in n8n's UI — Founder/credential-holder supplies the key out-of-band, per this repo's established pattern (never pasted into agent chat).
4. Call the node's live `GET /models` once with the real key to resolve the exact current production model id (closing the §E ambiguity empirically instead of guessing).
5. Build the `CEFFLO - AI Router` sub-workflow (provider/model/reasoning-tier resolution, cost-log write, normalized response envelope).
6. Wire it into CEFFLO-02/03/05A/05B/05C/06/09/10's existing stub Code nodes, replacing each stub with a real Execute-Sub-workflow call to the Router; each stage's deterministic contract validation stays untouched.
7. Apply the `cefflo_content_engine` migration — first confirming its target Postgres instance, which is not yet verified — extended with the `ai_call_log` table from §G.
8. Flip `CEFFLO_AI_MODE` from `stub` to `live` for one workflow only, in isolation, with every workflow still left inactive/manual-trigger.
9. Confirm QA (06) / Founder Approval (07) gates still hard-stop before Publisher (08) regardless of DeepSeek's QA score — do not let a high AI score bypass approval.
10. Only after Founder review of one manual, single-concept, end-to-end run: consider activating any schedule. Explicitly out of scope for this pass.

---

## J. TESTS & ACCEPTANCE CRITERIA

- Router unit test: given `workload_type` (LOW/HIGH/MAX) and a provider config, resolves the correct model/params without a live call (fixture-based, matching the ROI skeleton's existing `tests/` pattern).
- Live smoke test: one real DeepSeek call through the Router from a manually-triggered CEFFLO-02 run; response validated against `contracts/stage-contracts.json`'s existing schema; a cost-log row is written.
- Failure-path test: forced timeout / invalid-JSON response → correct REVISE/ERROR routing, never a silent pass to Founder Approval.
- Security test: no workflow JSON or repo file contains a literal DeepSeek key; the credential is reference-only.
- Regression test: `CEFFLO - 00 - Orchestrator Test` and `CEFFLO -  Content Creator` remain untouched and inactive, per the ROI skeleton's own safety boundary.
- All of the above still gated behind: no workflow set Active, no schedule enabled, no webhook registered, Publisher/Paid Growth remain zero-spend stubs.

---

## K. RISKS / BLOCKERS REQUIRING FOUNDER DECISION

1. **Unmerged foundation.** The entire 14-workflow ROI skeleton this AI Router would be built on top of exists only as uncommitted, untracked files in a local git worktree (`codex/n8n-content-engine-roi`), not pushed to `origin`. Building on top of it before a merge decision risks wasted work if that branch is later changed, rejected, or superseded. **Decision needed:** merge it (where — a PR against `main`, or reconciled into this session's branch?), or treat it as reference-only and rebuild.
2. **Undocumented live workflow.** `CEFFLO -  Content Creator` is wired to the one real OpenAI credential and is not described in the ROI master, the ROI skeleton's README, or any SOT/decision record found. **Decision needed:** what is it, and should it be migrated to DeepSeek via the new Router, left as an OpenAI-only prototype, or removed? (Untouched in this audit.)
3. **Model-identifier timing risk.** `deepseek-v4-pro` gets rerouted to V4.1-Flash pricing/tier on 2026-09-14 — 4 days from this audit — pending "V4.1 Pro." Pinning that literal string today risks a silent quality/cost change within days, with no code change on Cefflo's side. **Decision needed:** confirm intent to track whichever identifier DeepSeek's top reasoning tier carries at deploy time (recommended — resolved via the live `/models` call in Implementation step 4), rather than a fixed literal.

Lower-severity, non-blocking notes (tracked, not stopping implementation on their own):
4. The native n8n DeepSeek node doesn't expose `reasoning_effort`/`thinking` — MAX-tier reasoning needs an HTTP-node fallback (§E).
5. The `cefflo_content_engine` migration's target Postgres instance and applied status are unconfirmed (§A/§I.7).

---

## L. GO / BLOCKED RECOMMENDATION

**BLOCKED — FOUNDER DECISION REQUIRED**

No SOT/doctrine conflict exists (§C) — DeepSeek V4 Pro as V1 primary LLM is fully compatible with canonical Cefflo marketing/content-engine doctrine. The block is on three unresolved operational facts (§K.1–K.3), not on Founder policy. Once those three are decided, the architecture in §D is ready to build without further audit.
