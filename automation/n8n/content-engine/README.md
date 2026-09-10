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
