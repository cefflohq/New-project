# CEFFLO Phase 03 — Live Smoke Test, Second Pass (Postgres Credential Added)

Date: 2026-09-11. Continuation of the first smoke test (`CEFFLO_PHASE_03_LIVE_SMOKE_TEST_REPORT.md`), which reached `10 - Marketing Memory` and failed there because `CEFFLO_CONTENT_ENGINE_POSTGRES` didn't exist as an n8n credential. This pass creates that credential and reruns.

---

## Credential creation result

Created `CEFFLO_CONTENT_ENGINE_POSTGRES` (type `postgres`) via `n8n import:credentials`, assigned to the same project as the existing DeepSeek credential (`N4WQmamUf4HvJTgN`). Two attempts:
1. First import connected but failed with `The server does not support SSL connections` — the credential's `ssl`/`allowUnauthorizedCerts` fields weren't set to the combination n8n's Postgres credential type actually requires to disable SSL (confirmed by reading the credential type's own source: the `ssl` dropdown is only honored when `allowUnauthorizedCerts: false`; I had it `true`, so the dropdown was ignored and it still attempted SSL).
2. Corrected to `allowUnauthorizedCerts: false, ssl: "disable"` and re-imported (same id, upserted) — connection then succeeded and the query actually executed against the real database.

The plaintext password was never printed to any output I produced — read directly from `supabase_db_cefflo-local`'s own container config into a shell variable, written straight to a JSON file, copied into the n8n container, imported, and the file deleted immediately after (confirmed gone) on both passes.

## Credential usage scope

- **Points at:** the already-existing, already-migrated local Supabase Postgres (`supabase_db_cefflo-local`), reached from the n8n container via its own bridge gateway (`172.20.0.1:54322`, the same host-exposed port used throughout this session's earlier work) — not a new database, not a new schema. Verified reachable with a plain TCP connect test before creating the credential.
- **No new architecture:** no new container, no new network attachment (n8n's existing bridge gateway route to the already-exposed host port was sufficient), no new schema or table.
- **No unrelated credential touched:** `OpenAI account` and `DeepSeek` unchanged — confirmed by re-querying `credentials_entity` before and after; exactly 3 rows now, matching the 2 pre-existing plus this 1 new one.

## Smoke execution / run ID

Second-pass harness execution: **`47`** (same disposable harness workflow, rebuilt fresh since the first pass's copy was already deleted per the prior report's own cleanup instructions).

## Stage-by-stage result

| Execution ID | Stage | Status |
|---|---|---|
| 48 | `01 - SOT Retrieval` | SUCCESS |
| 49 | `02 - Research & Angle Miner` | SUCCESS |
| 50 | `03 - Master Concept Builder` | SUCCESS |
| 51 | `04 - Creative Router` | SUCCESS |
| 52 | `05A - Meta Creator` | SUCCESS |
| 53 | `05B - TikTok Creator` | SUCCESS |
| 54 | `05C - Threads Writer` | SUCCESS |
| 55 | `06 - AI QA` | SUCCESS |
| 56 | `07 - Founder Approval` | SUCCESS |
| 57 | `08 - Publisher` | SUCCESS |
| 58 | `09 - Analytics & Scoring` | SUCCESS |
| 59 | `10 - Marketing Memory` | **ERROR (new reason, not the credential)** |

## Workflow 10 result

**Credential now resolves and connects correctly** — this is real, confirmed progress. But the query itself now fails on a genuine data-integrity constraint:

```
insert or update on table "marketing_memory" violates foreign key constraint "marketing_memory_master_concept_id_fkey"
Key (master_concept_id)=(CEFFLO-2026-W37-E001) is not present in table "master_concepts".
```

**This is a newly-discovered, genuine architectural gap, not a credential issue and not something I fixed or attempted to fix.** `persist_marketing_memory()` (in the already-approved `202609100001_content_engine_roi.sql` migration) requires a matching row to already exist in `master_concepts`. Checking which workflows actually write to Postgres in the current 16-workflow family: **only `10 - Marketing Memory` and `99 - Error & Recovery` contain a Postgres node at all.** `03 - Master Concept Builder` builds the concept as an in-memory envelope field and passes it along the chain — it never inserts a `master_concepts` row. The same is true for the other five tables in that migration (`content_engine_runs`, `content_angles`, `creative_packages`, `founder_reviews`, `publish_records`, `content_analytics`) — none of them are written by any node anywhere in this workflow family. The ROI-skeleton's Postgres integration was evidently always scoped to just the two end-of-chain writes (Marketing Memory, Error events), and `persist_marketing_memory`'s FK to `master_concepts` assumes a fuller pipeline that was never actually built.

## Run Summary result

**Not reached** — same reason as the first pass: the harness's `Execute Workflow` call to `10` has no continue-on-fail, so execution `47` is recorded `error` and never proceeds to its `Run Summary` node.

## Restoration / safety verification

- All 12 temporarily activated workflows restored to inactive — confirmed via direct query (0 active workflows in `workflow_entity`).
- Disposable harness deleted (workflow count back to exactly 18).
- Temporary runner container removed (ran with `--rm`; confirmed absent from `docker ps -a`).
- Schedules: unchanged throughout, still `disabled: true` at the node level.
- **Canonical workflow definitions: byte-for-byte identical to the true pre-session baseline** — `nodes`, `connections`, and `active` state compared for all 18 workflows against `export-takeover-current`, zero differences.
- Canonical `founder_status || 'HOLD'` default: confirmed still present, unchanged.
- **The only persistent change from this whole exercise is the new `CEFFLO_CONTENT_ENGINE_POSTGRES` n8n credential** — verified via `credentials_entity`: exactly the 2 pre-existing rows plus this 1 new one, nothing else.
- Publisher: re-confirmed stub-only on this run too — all 4 records `STUBBED`, `external_post_id: null`.
- Paid Growth / `11` / `12`: never activated, untouched, spend remains 0 (nothing in this chain reaches them).
- No webhook, no new external trigger surface — harness used only a `Manual Trigger`, same as before.
- No secret printed — the corrected credential file's password was never echoed to output; only its length was ever printed as a sanity check, both times.

---

## FINAL TASK 7: **FAIL** — closer than the first attempt (credential issue fully resolved; a genuine, distinct database-integrity gap now blocks the very last stage) but not a PASS.

## FINAL PHASE 03 STATUS: **BLOCKED — FOUNDER DECISION REQUIRED**

This is a new decision point, not a retry of the last one. The gap is real and precisely located, but fixing it properly means the ROI-skeleton's Postgres integration needs to actually populate `master_concepts` (and, by the same logic, likely the other five never-written tables) somewhere in the chain — most naturally in `03 - Master Concept Builder`, which already builds the concept object but currently only passes it through the envelope. That means **adding a new Postgres write node to at least one more canonical workflow** — a real change to the n8n graph, not a credential fix, and exactly the kind of "broaden architecture" action I was told not to take without explicit authorization.

**Narrower alternative, worth naming since it doesn't touch the n8n graph at all:** relax `persist_marketing_memory()`'s foreign key (e.g., make it `DEFERRABLE`, or have the function itself upsert a minimal `master_concepts` row from the JSONB payload it already receives before inserting into `marketing_memory`) — a change confined to the already-approved SQL migration function, not new n8n nodes. I have not made this change either; it's a real modification to already-approved infrastructure and I'd rather you choose the direction than have me pick.

Tell me which way you want this closed: (a) add the missing `master_concepts` insert as a new Postgres node in `03`, (b) relax/adjust `persist_marketing_memory()`'s constraint handling instead, or (c) treat the 11/12-stage live pass plus the already-complete offline verification as sufficient and close Task 7 on that basis without forcing the last stage through.
