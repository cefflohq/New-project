# Cefflo Content Engine — ROI workflow family

Status: import-ready ROI production skeleton. All provider modes are stubbed and every workflow is inactive.

## Safety boundary

- `CEFFLO - 00 - Orchestrator Test` is instance-only prototype state and is not included, renamed, overwritten or converted here.
- No paid AI, media generation, social publishing, analytics provider, advertising API, ad spend or active schedule is used.
- `CEFFLO - 12 - Paid Growth` is a disabled stub boundary. It always reports zero spend and rejects live mode.
- Credentials are references only. Configure them in n8n's encrypted credential store; never commit secrets.
- Founder Approval is mandatory. Publisher rejects every state other than `APPROVE`/`APPROVED`.

## Canonical workflows

| Workflow | Responsibility | ROI activation |
|---|---|---|
| CEFFLO - 00 - Master Orchestrator | Lifecycle coordination | Inactive; manual trigger only, schedule node disabled |
| CEFFLO - 01 - SOT Retrieval | GitHub SOT adapter boundary and Context Pack validation | Inactive |
| CEFFLO - 02 - Research & Angle Miner | Research-only angle contract and memory duplication check | Inactive, deterministic stub |
| CEFFLO - 03 - Master Concept Builder | Core Experiment contract | Inactive, deterministic stub |
| CEFFLO - 04 - Creative Router | Exactly Meta, TikTok and Threads lanes | Inactive |
| CEFFLO - 05A - Meta Creator | Shared Instagram + Facebook package | Inactive, deterministic stub |
| CEFFLO - 05B - TikTok Creator | TikTok-native package | Inactive, deterministic stub |
| CEFFLO - 05C - Threads Writer | Threads-native text package | Inactive, deterministic stub |
| CEFFLO - 06 - AI QA | Automated QA and targeted revision | Inactive, deterministic stub |
| CEFFLO - 07 - Founder Approval | Separate APPROVE/REVISE/REJECT/HOLD gate | Inactive |
| CEFFLO - 08 - Publisher | Four idempotent destination records | Inactive, STUBBED only |
| CEFFLO - 09 - Analytics & Scoring | Platform-aware deterministic scoring | Inactive, deterministic stub |
| CEFFLO - 10 - Marketing Memory | Dynamic learning contract and PostgreSQL persistence node | Inactive; credential reference unresolved until authorized setup |
| CEFFLO - 11 - Weekly Winner Engine | Up to five weekly winners from Marketing Memory | Inactive; schedule node disabled |
| CEFFLO - 12 - Paid Growth | Founder/budget-gated production boundary | Inactive; schedule disabled, zero-spend stub only |
| CEFFLO - 99 - Error & Recovery | Standard errors, event logging and manual recovery | Inactive; credential reference unresolved until authorized setup |

`master_concept_id` is the Core Experiment ID and must match `CEFFLO-YYYY-Wxx-E###`. `angle_id` remains a Research working identifier and never replaces it.

The common envelope, Context Pack, and cross-stage decisions are versioned under `contracts/`. Workflow Code nodes enforce the executable parts of those contracts at each boundary.

## GitHub SOT retrieval boundary

The versioned ROI adapter `adapters/github-sot.mjs` resolves the canonical paths listed in `fixtures/sot_manifest.json` from immutable Git objects and attaches the resolved commit SHA to every source reference. This is the credential-free offline boundary for a GitHub-backed checkout. A live private-repository transport must fetch the same paths from `CEFFLO_GITHUB_REPOSITORY` and `CEFFLO_GITHUB_REF` using an n8n credential. Missing or unresolved sources return `ERROR_SOT`; no fallback summary may fabricate context.

The workflow accepts resolved document objects from that adapter and produces a task-specific Context Pack. This keeps full GitHub SOT authoritative without copying all doctrine into every workflow.

## PostgreSQL

The migration creates the isolated `cefflo_content_engine` schema, nine operational tables, indexes, the Marketing Memory persistence function and the event-log function. It does not modify n8n's internal tables.

Apply using the intended PostgreSQL operator connection:

```bash
psql -v ON_ERROR_STOP=1 -f migrations/202609100001_content_engine_roi.sql
```

The migration uses `IF NOT EXISTS`/`CREATE OR REPLACE` and may be rerun under the repository's idempotent migration convention.

## Generate and validate

```bash
node scripts/generate-workflows.mjs
node tests/validate_artifacts.mjs
node tests/roi_smoke.mjs
```

Database rollback-only smoke:

```bash
psql -v ON_ERROR_STOP=1 -f tests/db_smoke.sql
```

## Founder paths

- `APPROVE` continues to the STUBBED publisher.
- `HOLD` and `REJECT` stop before Publisher.
- `REVISE` returns only the named stage/lane.
- QA targeted revisions preserve passed lanes and stop after `CEFFLO_MAX_RETRIES`.
- Manual recovery starts from the recorded failed stage while preserving run/task/Core Experiment identifiers.

## Live-mode gate

Live AI, media, publishing, analytics, weekly scheduling and Paid Growth require a separate Founder authorization. Importing these artifacts does not authorize activation.

## Phase 03 additions (2026-09-13, wired into workflow JSON 2026-09-11 Founder Gate correction pass)

Source: `CEFFLO_PHASE_03_MARKETING_ENGINE_CONTENT_PILOT_MASTER.md`. New modules, all deterministic/stub by default (SAFE / NON-PUBLISHING MODE, §32). As of the 2026-09-11 correction pass, `scripts/generate-workflows.mjs` embeds the real source of `cil-scenario-engine.mjs`, `content-script-engine.mjs`, `cil-validate.mjs` and `qa-engine.mjs` verbatim into the `CEFFLO - 02/04/05A/05B/05C/06` Code nodes (n8n Code nodes cannot `import` local files, so this is generation-time embedding of the actual tested source, not a re-implementation -- re-run `node scripts/generate-workflows.mjs` after any change to those four files to keep the workflow JSON in sync). `02 - Research & Angle Miner` builds a real CIL scenario via `buildScenario()`; `04 - Creative Router` builds the real shared content package via `buildContentPackage()`; `05A/05B/05C` adapt its `platform_packages` per lane instead of returning hardcoded example copy; `06 - AI QA` runs the real `preProductionQA()`/`validateScenario()` gate (verified in `tests/roi_smoke.mjs` and by a manual implausible-scenario check that a 1-motorcycle/500-order scenario is genuinely rejected with `VEHICLE_FIT`, not passed through). Import into the live n8n instance and activation remain Codex's job per `docs/cefflo/tasks/CEFFLO_PHASE_03_N8N_CODEX_HANDOFF.md`:

- `scripts/content-script-engine.mjs` -- Batch 03D. Deterministic hook/script/caption/platform-adaptation generation from a CIL scenario. Zero cost, no live LLM call by default (§9). `routeToAIRouter()` is the documented, unused seam for a future live DeepSeek call.
- `scripts/qa-engine.mjs` -- Batch 03E. `preProductionQA()` (§15) and `postProductionQA()` (§16) as testable functions, extending `cil-validate.mjs`.
- `scripts/seedance-adapter.mjs` -- Batch 03G. Stub Seedance adapter (async submit/poll shape, AK/SK-style Volcano Engine ARK auth noted but not implemented), the §12 one-targeted-retry policy, and Veo explicitly never auto-escalated.
- `scripts/approval-state-machine.mjs` -- Batch 03I. The §17 `DRAFT -> QA_PASS -> FOUNDER_REVIEW -> APPROVED -> SCHEDULED -> PUBLISHED` chain as one pure function; `canPublish()` is the single enforcement point nothing may bypass.
- `scripts/dry-run-batch.mjs` -- Batch 03L. Generates a 30-50 scenario batch end-to-end (scenario -> content -> pre-QA -> stub production -> post-QA) with zero cost; run via `node scripts/dry-run-batch.mjs [count]`.
- `contracts/content-package.schema.json` -- formalizes the content-package shape Batch 03D/E/G/I produce and consume.
- `migrations/202609130001_phase03_cost_and_waitlist.sql` -- CPAC/CPPC cost telemetry (§24-25) and the pre-launch waitlist table (§18-19). **Not applied** -- same Postgres-target confirmation gap as the earlier migrations.
- `tests/phase03_test.mjs` -- acceptance tests for all of the above, including a real 40-candidate dry-run assertion.
- `../../../marketing/prelaunch/` -- the §18 lightweight pre-launch landing page + waitlist form. Not yet connected to a live backend (see that directory's `backend.js` header).

Run `node tests/phase03_test.mjs` after any change to the above.
