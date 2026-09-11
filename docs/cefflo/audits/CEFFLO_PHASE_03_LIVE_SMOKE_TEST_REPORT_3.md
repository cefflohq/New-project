# CEFFLO Phase 03 — Live Smoke Test, Third Pass — Master Concept Persistence Fix (PASS)

Date: 2026-09-11. Founder Option (a): add `master_concepts` persistence to `CEFFLO - 03 - Master Concept Builder` rather than relax the Marketing Memory foreign key.

---

## Root cause

`cefflo_content_engine.master_concepts` (in the already-approved `202609100001_content_engine_roi.sql` migration) has foreign keys to **both** `content_engine_runs(run_id)` and `content_angles(angle_id)`, not just being referenced *by* `marketing_memory`. Before this fix, **no node anywhere in the 16-workflow family wrote to any of these three tables** — only `10 - Marketing Memory` and `99 - Error & Recovery` had Postgres nodes at all, and `persist_marketing_memory()`'s FK to `master_concepts` assumed a fuller pipeline that had never actually been built.

## Exact workflow/schema change

1. **New migration** `automation/n8n/content-engine/migrations/202609130003_persist_master_concept.sql` — one new `SECURITY DEFINER` function, `cefflo_content_engine.persist_master_concept(p_payload JSONB) RETURNS TEXT`, that upserts all three rows (`content_engine_runs` → `content_angles` → `master_concepts`, in FK dependency order) from the single envelope JSONB already present when `CEFFLO - 03`'s existing "Build Core Experiment" node finishes — no new table, no new schema, reuses the exact `CEFFLO-YYYY-Wxx-E###` Core Experiment ID contract as the `master_concepts` primary key. Idempotent: `ON CONFLICT (run_id) DO UPDATE`, `ON CONFLICT (angle_id) DO NOTHING`, `ON CONFLICT (master_concept_id) DO UPDATE` — reruns of the same smoke test update rather than error or duplicate (verified: this pass reused the same `run_id`/`angle_id`/`master_concept_id` as the two prior failed attempts, and succeeded cleanly).
2. **Generator change** (`scripts/generate-workflows.mjs`): added a `concept` entry to the existing Postgres-node-injection loop (the same mechanism already used for `10`/`memory` and `99`/`error` — no new pattern invented), calling `persist_master_concept($1::jsonb)` via the same `CEFFLO_CONTENT_ENGINE_POSTGRES` credential reference.
3. **Fixed a real bug found while implementing this**: a Postgres node's output is its query result, not a passthrough of its input. For `10`/`99` (terminal workflows) this never mattered; for `03` (which `04` through `10` still run after) it broke the envelope, and the first live rerun proved it — `04` failed on missing envelope fields because `03`'s output had collapsed to `{"master_concept_id": "..."}`. Fixed by adding one more small Code node, `Confirm Master Concept Persisted`, that re-emits the full original envelope via `$('Build Core Experiment').item.json` (a standard n8n cross-node reference, not a workaround) after the persistence write.

## Files changed

- `automation/n8n/content-engine/migrations/202609130003_persist_master_concept.sql` (new)
- `automation/n8n/content-engine/scripts/generate-workflows.mjs` (the Postgres-node-injection loop, +restore-step handling)
- `automation/n8n/content-engine/workflows/03_-_Master_Concept_Builder.json` (regenerated; only file among the 16 with a real content change this round)

`angle_id` (Research working ID) and `master_concept_id` (Core Experiment ID) roles are unchanged — the new function persists both under their existing meanings, doesn't redefine either.

## Tests run

`node tests/validate_artifacts.mjs`, `node tests/cil_test.mjs`, `node tests/phase03_test.mjs`, `node tests/roi_smoke.mjs` — all PASS, both immediately after the generator change and again after the fix for the passthrough bug. `roi_smoke.mjs`'s existing call to workflow 03 (`runCode('CEFFLO - 03 - Master Concept Builder', state)`, no node name given) is unaffected — it still resolves to the first Code-type node (`Build Core Experiment`), unchanged by the new Postgres/restore nodes.

## Live execution / run ID

Disposable harness execution **`65`** — **`status: success, finished: true`**.

## Stage-by-stage result

| Execution ID | Stage | Status |
|---|---|---|
| 66 | `01 - SOT Retrieval` | SUCCESS |
| 67 | `02 - Research & Angle Miner` | SUCCESS |
| 68 | `03 - Master Concept Builder` | **SUCCESS** |
| 69 | `04 - Creative Router` | SUCCESS |
| 70 | `05A - Meta Creator` | SUCCESS |
| 71 | `05B - TikTok Creator` | SUCCESS |
| 72 | `05C - Threads Writer` | SUCCESS |
| 73 | `06 - AI QA` | SUCCESS |
| 74 | `07 - Founder Approval` | SUCCESS |
| 75 | `08 - Publisher` | SUCCESS |
| 76 | `09 - Analytics & Scoring` | SUCCESS |
| 77 | `10 - Marketing Memory` | **SUCCESS** |

**13 of 13 real, live sub-workflow calls succeeded.**

## Workflow 03 persistence result

Confirmed directly in the database, not inferred from execution status alone:

```
master_concept_id     | run_id                               | angle_id      | status
CEFFLO-2026-W37-E001  | 00000000-0000-4000-8000-000000000001 | angle-roi-001 | CONCEPT_READY
```

`content_engine_runs` and `content_angles` rows also confirmed present with matching, correctly-linked ids. Uses the exact Core Experiment ID contract (`CEFFLO-YYYY-Wxx-E###`).

## Workflow 10 result

Succeeded — the FK violation from the prior two passes is gone. Confirmed real rows landed in `marketing_memory`: 4 rows (`instagram`, `facebook`, `tiktok`, `threads`), each referencing `master_concept_id = CEFFLO-2026-W37-E001`, with the deterministic platform baseline scores (72/68/75/64) matching `09 - Analytics & Scoring`'s known stub logic exactly.

## Run Summary result

**Reached, `success`.** Output:
```json
{ "result": 4, "roi_summary": { "paid_calls": 0, "live_posts": 0, "schedules_active": false, "destinations": [] } }
```
`paid_calls`, `live_posts`, and `schedules_active` are all correct. **One honest, minor residual note, not fixed in this round:** `destinations` is empty rather than listing the 4 platforms — `10 - Marketing Memory`'s own Postgres node has the exact same input-truncation characteristic I fixed in `03` (its raw query result, `{result: 4}`, is what actually reaches Run Summary), just not yet given the same restore step, because that wasn't part of this round's authorization (fixing `03`'s FK chain only). It doesn't affect correctness of any persisted data or any safety property — only this one cosmetic summary field. Flagging it plainly rather than either fixing it unprompted or leaving it undisclosed.

## Safety restoration evidence

- All 12 temporarily-activated workflows restored to inactive — confirmed, **0 active workflows** in the database.
- Disposable harness deleted; runner container removed (`--rm`, confirmed absent).
- **Zero unexpected differences** anywhere in the 18-workflow family versus the true pre-session baseline, except the one authorized change to workflow `03` itself (which matches the repo file exactly, byte for byte, and is `active: false`).
- Canonical `founder_status || 'HOLD'` default: unchanged, confirmed.
- Schedules: unchanged, still `disabled: true`.
- Publisher: re-confirmed stub-only on this run — all 4 records `STUBBED`, `external_post_id: null`.
- Credentials: exactly 3 rows (`OpenAI account`, `DeepSeek`, `CEFFLO_CONTENT_ENGINE_POSTGRES`) — no unrelated credential touched or rotated.
- Paid Growth / `11` / `12`: never activated, untouched, spend remains 0.
- No secret printed at any point across all three passes of this exercise.

---

## FINAL TASK 7: **PASS**

## FINAL PHASE 03 STATUS: **COMPLETE**

All required stages (`00` harness entry → `01` → `02` → `03` → `04` → `05A` → `05B` → `05C` → `06` → `07` → `08` → `09` → `10` → Run Summary) ran successfully against the live n8n instance, using the real, production-imported Phase 03 logic, with real database persistence now verified end-to-end. Every safety condition (inactive workflows, disabled schedules, no webhook, stubbed Publisher/Analytics/Paid Growth, zero spend, canonical HOLD default, no secret exposure) held throughout and was independently re-verified after cleanup.

Nothing committed or pushed.
