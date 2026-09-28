# CEFFLO Phase 03 — Production n8n Diff Report (backup vs. repo-regenerated)

Date: 2026-09-11
Backup source: `/home/cefflo/n8n-backups/production-2026-09-11/export/` (18 files, `n8n export:workflow --backup`)
Repo source: `/home/cefflo/New-project/automation/n8n/content-engine/workflows/` (freshly regenerated via `node scripts/generate-workflows.mjs`)
Scope: the 16 canonical `CEFFLO - 00`..`12`,`99` workflows only. `CEFFLO - 00 - Orchestrator Test` (`2qzoTGpjs2iFhJob`) and `CEFFLO -  Content Creator` (`E4lVI68Cs6x88sJr`) were not opened, diffed, or touched.

**No import, update, or activation has occurred. This is comparison only.**

## What is ignored, and why

The production export carries n8n-internal/server-managed fields the repo JSON never contains and never should: `createdAt`, `updatedAt`, `versionId`, `versionCounter`, `activeVersionId`, `versionMetadata`, `nodeGroups`, `shared` (project/owner assignment), `sourceWorkflowId`, `triggerCount`. These are regenerated/preserved by n8n's own `import:workflow` command when it matches an existing workflow by `id` — they are not meaningful diff targets and are excluded below. Node `position` (canvas x/y coordinates) is also ignored as purely cosmetic.

## Per-workflow comparison

| # | ID | Name | Prod file | Repo file | Structural |
|---|---|---|---|---|---|
| 1 | `...0000` | CEFFLO - 00 - Master Orchestrator | `10000000-...-000000000000.json` | `00_-_Master_Orchestrator.json` | IDENTICAL |
| 2 | `...0001` | CEFFLO - 01 - SOT Retrieval | `10000000-...-000000000001.json` | `01_-_SOT_Retrieval.json` | IDENTICAL |
| 3 | `...0002` | CEFFLO - 02 - Research & Angle Miner | `10000000-...-000000000002.json` | `02_-_Research_and_Angle_Miner.json` | CHANGED |
| 4 | `...0003` | CEFFLO - 03 - Master Concept Builder | `10000000-...-000000000003.json` | `03_-_Master_Concept_Builder.json` | IDENTICAL |
| 5 | `...0004` | CEFFLO - 04 - Creative Router | `10000000-...-000000000004.json` | `04_-_Creative_Router.json` | CHANGED |
| 6 | `...0005` | CEFFLO - 05A - Meta Creator | `10000000-...-000000000005.json` | `05A_-_Meta_Creator.json` | CHANGED |
| 7 | `...0006` | CEFFLO - 05B - TikTok Creator | `10000000-...-000000000006.json` | `05B_-_TikTok_Creator.json` | CHANGED |
| 8 | `...0007` | CEFFLO - 05C - Threads Writer | `10000000-...-000000000007.json` | `05C_-_Threads_Writer.json` | CHANGED |
| 9 | `...0008` | CEFFLO - 06 - AI QA | `10000000-...-000000000008.json` | `06_-_AI_QA.json` | CHANGED |
| 10 | `...0009` | CEFFLO - 07 - Founder Approval | `10000000-...-000000000009.json` | `07_-_Founder_Approval.json` | CHANGED |
| 11 | `...0010` | CEFFLO - 08 - Publisher | `10000000-...-000000000010.json` | `08_-_Publisher.json` | IDENTICAL |
| 12 | `...0011` | CEFFLO - 09 - Analytics & Scoring | `10000000-...-000000000011.json` | `09_-_Analytics_and_Scoring.json` | IDENTICAL |
| 13 | `...0012` | CEFFLO - 10 - Marketing Memory | `10000000-...-000000000012.json` | `10_-_Marketing_Memory.json` | IDENTICAL |
| 14 | `...0013` | CEFFLO - 11 - Weekly Winner Engine | `10000000-...-000000000013.json` | `11_-_Weekly_Winner_Engine.json` | IDENTICAL |
| 15 | `...0014` | CEFFLO - 12 - Paid Growth | `10000000-...-000000000014.json` | `12_-_Paid_Growth.json` | IDENTICAL |
| 16 | `...0099` | CEFFLO - 99 - Error & Recovery | `10000000-...-000000000099.json` | `99_-_Error_and_Recovery.json` | IDENTICAL |

For every one of the 16: node count matches, node names/types/IDs match, `connections` (workflow topology/wiring) is byte-identical, `active=false` on both sides, `pinData={}` on both sides (no pinned test executions to lose), `staticData=null` on both sides, no webhook-type nodes present anywhere in this family.

## Detail for the 7 CHANGED workflows

### 3. `...0002` — CEFFLO - 02 - Research & Angle Miner
- **Code node changed:** `Mine Deterministic Angles` (prod 1,371 chars → repo 15,952 chars).
- **Content difference:** production still runs the pre-Phase-03 fixed-angle stub only. Repo adds real CIL scenario construction — embeds `cil-scenario-engine.mjs`'s `buildScenario`/`proposeVehicleMix`/`resolveWorkforceLabel` verbatim plus the real taxonomy fixture data, and attaches a `cil_scenario` field to the envelope. The original angle-mining logic (used by `03 - Master Concept Builder` downstream) is preserved unchanged inside the new code — this is additive, not a rewrite of the existing angle contract.
- **Credentials:** none on this node, no difference.
- **Webhooks:** none.
- **Risk:** **SAFE TO UPDATE.** Purely additive to this node's output; verified via `tests/roi_smoke.mjs` (full chain still passes) and a manual adversarial-scenario check (implausible scenario correctly triggers a QA rejection downstream).

### 5. `...0004` — CEFFLO - 04 - Creative Router
- **Code node changed:** `Create Three Lane Plan` (prod 981 chars → repo 20,229 chars).
- **Content difference:** production only emits the 3 lane declarations. Repo additionally builds a real, shared `content_package` (embeds `content-script-engine.mjs` + `cil-scenario-engine.mjs` verbatim) and requires `input.cil_scenario` to be present (throws `ERROR_VALIDATION: cil_scenario required before Creative Router` if missing — i.e. if run against an OLD `02` node that hasn't been updated). **This is why `02` and `04` must be updated together, not independently** — importing `04` alone without `02` would break the chain at this node.
- **Credentials:** none, no difference.
- **Risk:** **SAFE TO UPDATE, but paired with #3** — see coupling note below.

### 6-8. `...0005/0006/0007` — CEFFLO - 05A/05B/05C (Meta/TikTok/Threads Creators)
- **Code nodes changed:** each creator's single Code node (prod ~1,140-1,277 chars → repo ~990-1,001 chars — repo is *smaller* here, since the old hardcoded example copy is replaced by a short lookup into `content_package.platform_packages`).
- **Content difference:** production generates its own fixed literal hook/caption text per lane, independent of any upstream scenario. Repo pulls its lane's package from the real `content_package` built in `04`, and throws `ERROR_VALIDATION: content_package required from Creative Router` if `04` hasn't been updated first — same coupling as above.
- **Credentials/webhooks:** none, no difference.
- **Risk:** **SAFE TO UPDATE, but paired with #3 and #5** — these three plus `02`/`04` form one coupled unit.

### 9. `...0008` — CEFFLO - 06 - AI QA
- **Code node changed:** `Run Deterministic QA` (prod 1,565 chars → repo 21,313 chars).
- **Content difference:** production runs a naive regex check (missing lanes + a 3-term forbidden-phrase regex). Repo embeds `cil-validate.mjs` + `qa-engine.mjs` verbatim and runs the real `preProductionQA()`/`validateScenario()` gate (10 real checks: plausibility, business fit, vehicle fit, human fit, workforce-label correctness, product-truth capability allowlist, language register, creative value, anti-fabrication, novelty) — and requires `input.cil_scenario`/`input.content_package`, so it also depends on `02`/`04` being updated first.
- **Behavior preserved exactly:** the existing `qa_fixture.force_status` test-override mechanism and the targeted-retry-limit throw (`retry_count >= max_retries` → `ERROR_VALIDATION: targeted retry limit exhausted`) are untouched — verified because `tests/roi_smoke.mjs`'s existing assertions on this exact behavior still pass unmodified.
- **Credentials/webhooks:** none, no difference.
- **Risk:** **SAFE TO UPDATE, but paired with #3, #5, #6-8** — same coupled unit; this is the real replacement for the QA gate the Founder specifically asked to see proven non-decorative (confirmed separately: an implausible scenario is genuinely rejected, not passed through).

### 10. `...0009` — CEFFLO - 07 - Founder Approval
- **Code node changed:** `Apply Founder Decision` (prod 1,203 chars → repo 1,734 chars).
- **Content difference — this is the Founder-gate node itself, called out separately from the coupled content unit above:** production applies a Founder decision (`APPROVE`/`REVISE`/`REJECT`/`HOLD`) but on `REVISE` does not clear any downstream artifacts — a re-run after REVISE would carry forward stale `creative_packages`/`qa_status`/`publish_records` from the rejected attempt. Repo adds lane-preserving/concept-level invalidation logic: a `REVISE` targeting `MASTER_CONCEPT` clears `creative_packages`, `qa_status`, `qa_score`, `publish_records`, `analytics_records`, `marketing_memory_records`; a `REVISE` targeting one lane clears only that lane's package and any downstream publish/analytics/memory records, preserving the other passed lanes. **This logic pre-dates this diff pass** (it was added and tested earlier in the Phase 03 work, before the current Founder Gate correction) — it is not new in this session.
- **What it does NOT change:** the gate itself is identical and, if anything, strictly stronger — `APPROVE` still requires `qa_status === 'PASS'` (`ERROR_VALIDATION: Founder approval cannot bypass failed QA'`), the same four decisions are accepted, and `status` mapping is unchanged. No path exists in either version to reach `APPROVED` other than an explicit `APPROVE` decision.
- **Credentials/webhooks:** none, no difference.
- **Risk:** **REVIEW REQUIRED** — not because the change is unsafe (it is tested via `tests/roi_smoke.mjs`'s `metaRevision`/`conceptRevision` assertions and only strengthens stale-artifact handling), but because this is literally the human-approval boundary node and warrants your explicit look before being touched, independent of the technical risk assessment.

## Coupling note (important for the import step, not yet taken)

`02`, `04`, `05A`, `05B`, `05C`, and `06` are now interdependent: `02` produces `cil_scenario`, `04` consumes it to produce `content_package`, `05A/B/C` and `06` consume `content_package`. **These 6 must be imported together, not individually** — importing any subset would leave the chain broken (the downstream node's own `ERROR_VALIDATION` guard would fire on the next real execution, not silently). `07` is technically independent (no data dependency on the above) but is grouped in the same batch below since it's part of the same Phase 03 correction.

`00`, `01`, `03`, `08`, `09`, `10`, `11`, `12`, `99` are unchanged no-ops — reimporting them is harmless but has no effect.

## Summary

**SAFE UPDATE SET:**
`10000000-0000-4000-8000-000000000000`, `10000000-0000-4000-8000-000000000001`, `10000000-0000-4000-8000-000000000002`, `10000000-0000-4000-8000-000000000003`, `10000000-0000-4000-8000-000000000004`, `10000000-0000-4000-8000-000000000005`, `10000000-0000-4000-8000-000000000006`, `10000000-0000-4000-8000-000000000007`, `10000000-0000-4000-8000-000000000008`, `10000000-0000-4000-8000-000000000010`, `10000000-0000-4000-8000-000000000011`, `10000000-0000-4000-8000-000000000012`, `10000000-0000-4000-8000-000000000013`, `10000000-0000-4000-8000-000000000014`, `10000000-0000-4000-8000-000000000099`
(all of 00,01,02,03,04,05A,05B,05C,06,08,09,10,11,12,99 — the `02`/`04`/`05A/B/C`/`06` group must move together per the coupling note above; the rest are no-ops either way)

**REVIEW REQUIRED:**
`10000000-0000-4000-8000-000000000009` (CEFFLO - 07 - Founder Approval) — functional change to the Founder-approval gate's revision handling. Tested and strictly additive/strengthening, not weakening, but this is the approval boundary itself and I'm flagging it for your explicit look rather than bundling it silently with the others.

**BLOCKED:**
None. No credential changes, no webhook changes, no active-state changes, no node/connection topology changes, no deletions, anywhere in the 16.

---

## UPDATE 2026-09-11 — Import executed, Founder-approved 7-workflow batch

Founder approved the exact 7-workflow update set below (note: the Founder's approval message flagged a shorthand ambiguity in my prior chat summary — `ID ...0009` is `CEFFLO - 07 - Founder Approval`, not `CEFFLO - 09`; `CEFFLO - 09 - Analytics & Scoring` is `ID ...0011` and was correctly in the untouched/no-op set throughout). All IDs below are the full IDs from the table above, not shorthand.

**Staged, then imported via n8n's own `import:workflow --separate` CLI** (upserts by `id`, matching the existing workflow — not a create). Only these 7 files were staged/copied into the container; none of the 9 no-op files were present in the import batch.

UPDATED WORKFLOWS:
- `10000000-0000-4000-8000-000000000002` — CEFFLO - 02 - Research & Angle Miner
- `10000000-0000-4000-8000-000000000004` — CEFFLO - 04 - Creative Router
- `10000000-0000-4000-8000-000000000005` — CEFFLO - 05A - Meta Creator
- `10000000-0000-4000-8000-000000000006` — CEFFLO - 05B - TikTok Creator
- `10000000-0000-4000-8000-000000000007` — CEFFLO - 05C - Threads Writer
- `10000000-0000-4000-8000-000000000008` — CEFFLO - 06 - AI QA
- `10000000-0000-4000-8000-000000000009` — CEFFLO - 07 - Founder Approval

UNCHANGED NO-OPS (re-exported post-import and confirmed `versionId` byte-identical to the pre-import backup — proof nothing merely "happened to match" but was truly never written):
- `10000000-0000-4000-8000-000000000000` — CEFFLO - 00 - Master Orchestrator
- `10000000-0000-4000-8000-000000000001` — CEFFLO - 01 - SOT Retrieval
- `10000000-0000-4000-8000-000000000003` — CEFFLO - 03 - Master Concept Builder
- `10000000-0000-4000-8000-000000000010` — CEFFLO - 08 - Publisher
- `10000000-0000-4000-8000-000000000011` — CEFFLO - 09 - Analytics & Scoring
- `10000000-0000-4000-8000-000000000012` — CEFFLO - 10 - Marketing Memory
- `10000000-0000-4000-8000-000000000013` — CEFFLO - 11 - Weekly Winner Engine
- `10000000-0000-4000-8000-000000000014` — CEFFLO - 12 - Paid Growth
- `10000000-0000-4000-8000-000000000099` — CEFFLO - 99 - Error & Recovery
- `2qzoTGpjs2iFhJob` — CEFFLO - 00 - Orchestrator Test (untouched, as instructed)
- `E4lVI68Cs6x88sJr` — CEFFLO -  Content Creator (untouched, as instructed)

ACTIVE STATE: all 18 workflows confirmed `active: false` after import (re-ran `n8n list:workflow --active=true` equivalent via full export — zero active).

**Post-import verification performed (re-export + diff, per items 1-6):**
1. Re-exported all 18 via `n8n export:workflow --backup` a second time (`/home/cefflo/n8n-backups/production-2026-09-11/export-post/`).
2. Diffed each of the 7 updated workflows' exported JSON against the intended repo-generated file: **id match, name match, `active=false`, `connections` byte-identical, node names identical, and `jsCode` byte-identical** for every node in all 7 — the production import now contains exactly the intended real-engine logic, nothing more, nothing less.
3. Confirmed `active=false` on all 7 (and all 18) directly from the post-import export data.
4. Confirmed workflow IDs unchanged (upsert-by-id, not create) — same 18 IDs present before and after, no duplicates, no deletions.
5. Confirmed credentials unchanged: none of the 7 updated workflows carry credential-bearing nodes; the two Postgres-credentialed nodes (`10 - Marketing Memory`, `99 - Error & Recovery`) were not in this batch and their `versionId` is confirmed unchanged.
6. Confirmed `connections` (node wiring/topology) unchanged for all 7 — matches the pre-import diff report's finding that only Code node bodies changed, never topology.

**Test executions (item 7) — partial, honestly reported:**
- Could not run `n8n execute --id=<master>` inside the live container: it failed immediately with `n8n Task Broker's port 5679 is already in use` — a structural conflict because the container is already running the live `n8n start` server process, and the CLI `execute` subcommand needs its own task-runner. Stopping the live server to free that port would itself be a production mutation beyond this batch's authorization, so this was not attempted. Using the n8n Web UI or REST API instead would require either UI access or generating a new API credential — neither was available or requested for this batch.
- Additionally, even if `execute` could run, the Master Orchestrator's "Build Run Envelope" node defaults `sot_documents` to `[]` when run from a bare manual trigger with no injected input — which would correctly fail at `01 - SOT Retrieval` with `ERROR_SOT` before ever reaching the 7 updated nodes, since no live GitHub SOT credential is configured in this instance (a separate, pre-existing, not-yet-authorized gap documented in the repo's own README — not something this batch introduced or was asked to fix).
- **What was verified instead, with equal rigor:** the exact, byte-confirmed-identical code now running in production was executed via the same local harness this repo already uses for this purpose (`tests/roi_smoke.mjs`, `tests/phase03_test.mjs` — both PASS), plus a direct, standalone execution of the `Apply Founder Decision` node's JS **extracted straight from the post-import production export** (not the repo copy) confirming: `APPROVE` with `qa_status !== 'PASS'` throws `ERROR_VALIDATION: Founder approval cannot bypass failed QA`; `HOLD`/`REJECT`/`REVISE` never reach `APPROVED`; only `APPROVE` with `qa_status === 'PASS'` reaches `APPROVED`.

**Item 8 (02→04→05A/B/C→06 chain with real Phase 03 data):** proven via `tests/roi_smoke.mjs`'s full-chain run against this same byte-identical code (Research → Concept → Router → all 3 Creators → AI QA → Founder Approval → Publisher → Analytics → Memory → Weekly Winners → Paid Growth, all asserting on real intermediate values), and separately via the adversarial VEHICLE_FIT-rejection check from the prior turn (an implausible scenario is genuinely rejected by the real `06 - AI QA` logic, not passed through). Not proven via a live in-n8n execution, for the reason given above.

**Item 9 (Founder Approval blocks publication until APPROVE):** confirmed directly against the production-imported node, see above — PASS.

TEST RESULTS: PASS (local harness + direct extraction from the live production export). In-n8n live execution of the full chain remains blocked by the missing SOT-retrieval credential and the CLI/server port conflict — both pre-existing, out-of-scope-for-this-batch constraints, not failures introduced by this update.

UNEXPECTED DIFFS: none. No credential, webhook, active-state, topology, or unrelated-workflow change occurred anywhere. The 9 no-ops and the 2 excluded workflows have identical `versionId` before and after.

**Terminal state for this batch: import completed successfully and verified as specified. Phase 03 PASS is NOT declared.** Remaining gates unchanged: real Seedance pilot (blocked on credential) and controlled-publication Founder approval.
