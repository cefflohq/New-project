"""Rollback-only S4-04 Batch-5.1 rate-limit infrastructure acceptance.

Verifies ONLY the storage/primitive/cleanup mechanism added in
202608270007_s4_04_batch_5_rate_limit_infra.sql. Nothing is wired to any
consumer yet (public_tracking/submit_rating/tracking-pod) -- that is
Batches 5.2-5.4, verified separately.
"""

import uuid

import psycopg

from environment_guard import TargetRefused, validate_database_target

try:
    target = validate_database_target(
        mutating=True,
        allowed_environments=frozenset({"local", "staging", "test"}),
    )
except TargetRefused as error:
    raise SystemExit(f"target_refused: {error}") from error


def rejected(cur, statement, params=(), contains=None):
    savepoint = f"denied_{uuid.uuid4().hex}"
    cur.execute(f"savepoint {savepoint}")
    try:
        cur.execute(statement, params)
    except psycopg.Error as error:
        cur.execute(f"rollback to savepoint {savepoint}")
        if contains:
            assert contains in str(error), str(error)
    else:
        raise AssertionError(f"expected rejection: {statement}")


with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        def as_role(role):
            cur.execute("reset role")
            if role != "service_role":
                cur.execute(f"set local role {role}")

        key = f"testkey_{uuid.uuid4().hex}"
        action = f"test_action_{uuid.uuid4().hex}"

        # ---- Grants: only service_role may call the primitives directly. ----
        as_role("anon")
        rejected(cur, "select check_rate_limit(%s,%s,60,3)", (key, action), "permission denied")
        rejected(cur, "select record_invalid_lookup_telemetry(%s)", (action,), "permission denied")

        as_role("authenticated")
        rejected(cur, "select check_rate_limit(%s,%s,60,3)", (key, action), "permission denied")
        rejected(cur, "select record_invalid_lookup_telemetry(%s)", (action,), "permission denied")

        as_role("service_role")

        # ---- Enforcement: allows up to max, denies the (max+1)th within window. ----
        for i in range(3):
            cur.execute("select check_rate_limit(%s,%s,60,3)", (key, action))
            assert cur.fetchone()[0] is True, f"request {i+1}/3 should be allowed"
        cur.execute("select check_rate_limit(%s,%s,60,3)", (key, action))
        assert cur.fetchone()[0] is False, "4th request within the same window must be denied"

        # ---- Bounded cardinality: exactly one row for this key/action/window. ----
        cur.execute(
            "select count(*), max(request_count) from rate_limit_counters where key_hash=%s and action=%s",
            (key, action),
        )
        row_count, max_count = cur.fetchone()
        assert row_count == 1, "must aggregate into a single row per key/action/window, not one per request"
        assert max_count == 4

        # ---- A different key under the same action has an independent counter. ----
        other_key = f"testkey_{uuid.uuid4().hex}"
        cur.execute("select check_rate_limit(%s,%s,60,3)", (other_key, action))
        assert cur.fetchone()[0] is True, "a distinct key must not be affected by another key's counter"

        # ---- A different action under the same key has an independent counter. ----
        other_action = f"test_action_{uuid.uuid4().hex}"
        cur.execute("select check_rate_limit(%s,%s,60,3)", (key, other_action))
        assert cur.fetchone()[0] is True, "a distinct action must not be affected by another action's counter"

        # ---- Telemetry: aggregate-only, bounded per (action, window), never per token. ----
        for _ in range(5):
            cur.execute("select record_invalid_lookup_telemetry(%s)", (action,))
        cur.execute(
            "select count(*), max(request_count) from invalid_lookup_telemetry where action=%s",
            (action,),
        )
        telemetry_rows, telemetry_count = cur.fetchone()
        assert telemetry_rows == 1, "telemetry must aggregate into a single row per action/window"
        assert telemetry_count == 5

        # ---- Telemetry function must never raise, even under adverse input. ----
        cur.execute("select record_invalid_lookup_telemetry(null)")

        # ---- Cleanup mechanism: pg_cron job is scheduled and active. ----
        as_role("service_role")
        cur.execute("reset role")
        cur.execute(
            "select active, schedule from cron.job where jobname='cefflo_rate_limit_cleanup'"
        )
        job = cur.fetchone()
        assert job is not None, "cefflo_rate_limit_cleanup cron job must exist"
        assert job[0] is True, "cleanup job must be active"

        conn.rollback()

print("s4_04_batch_5_rate_limit_infra_ok")
