# Production read-only inspection (release gate G2)

Establishes the real Production state before any write. Nothing here can
write: every statement runs in `begin transaction read only` and the session
default is forced read-only.

## Inputs (Founder)

- A **read-only** Production DB connection string, exported only in the
  operator's shell as `INSPECT_DATABASE_URL`. Never committed, printed or
  pasted into chat or logs.
- Backup / PITR confirmed in the Dashboard (Database → Backups), with the
  restore point recorded.

## Run

```bash
cd scripts/production-inspection
INSPECT_DATABASE_URL="…read-only…" ./run-readonly-inspection.sh production > production.txt
diff <(grep -v '^# ' ../../docs/cefflo/engineering/evidence/STAGING_SCHEMA_BASELINE_2026-09-27.txt | grep -v '^count|') \
     <(grep -v '^# ' production.txt | grep -v '^count|')
```

## What the output answers

| Question | Lines |
|---|---|
| 1. Schema state vs canonical | `migration`, `column`, `function` |
| 2. Exact migration gap | `migration` lines missing from Production (staging holds all 54) |
| 3. `pg_cron` available / configured | `available_extension|pg_cron`, `extension|pg_cron`, `cron_present` |
| 4. Out-of-band buckets | `bucket` lines not in {`cefflo-pod`, `cefflo-product-display`, `cefflo-product-originals`} |
| 5. Order count before the D-64 backfill | `count|orders` |
| 6. RPC presence | `function`, `grant` |
| 7. RLS state | `rls`, `policy` |
| 8. Drift that makes the sequence unsafe | any object present on Production but absent from staging, or the same name with a different signature |

The expected gap is "about 53" from public probes; this run establishes the
actual number. Any unexpected difference stops the release (gate G2 → STOP).
