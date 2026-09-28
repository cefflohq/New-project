"""Rollback-only S4-04 Batch-5.3 submit_rating acceptance.

Founder policy: submit_rating is TELEMETRY-ONLY, never enforcing. During
implementation, telemetry itself was found to be undeliverable via a simple
DB-internal perform()+raise pattern (see migration 202608270009 and
checkpoint Section 40 for why) and was NOT shipped rather than ship a
telemetry signal that silently only ever counts successes. This test
confirms submit_rating is therefore byte-behaviorally unchanged from its
pre-B05 (foundation) form: no rate-limit gate, no telemetry side effect, all
existing validation intact.
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
        owner, rider_user = uuid.uuid4(), uuid.uuid4()
        for user_id, label in ((owner, "owner"), (rider_user, "rider")):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"s4-04-b5-sr-{label}-{uuid.uuid4()}@test.invalid"),
            )
        cur.execute("insert into businesses(name) values('S4-04 B5 SR Business') returning id")
        business = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values(%s,%s,'owner')",
            (business, owner),
        )
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) "
            "values(%s,%s,'B5 SR Rider',%s,'active') returning id",
            (business, rider_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider = cur.fetchone()[0]

        def new_delivered_order(phone_suffix):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claim.role',%s,true)",
                (str(owner), "authenticated"),
            )
            cur.execute("set local role authenticated")
            cur.execute(
                "select create_delivery(%s,'B5 Customer',%s,'Addr')",
                (business, f"+6013000{phone_suffix:04d}"),
            )
            created = cur.fetchone()[0]
            order_id, token = created["order"]["id"], created["tracking_token"]
            cur.execute("select approve_order(%s)", (order_id,))
            cur.execute("select assign_rider(%s,%s)", (order_id, rider))
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claim.role',%s,true)",
                (str(rider_user), "authenticated"),
            )
            cur.execute("set local role authenticated")
            cur.execute("select accept_assignment(%s,%s)", (rider, order_id))
            for status in ("ready_for_pickup", "picked_up", "out_for_delivery", "arrived"):
                cur.execute("select rider_transition(%s,%s,%s)", (rider, order_id, status))
            pod_path = f"{rider}/{order_id}/test.jpg"
            cur.execute("reset role")
            cur.execute("insert into storage.objects(bucket_id, name) values ('cefflo-pod', %s)", (pod_path,))
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claim.role',%s,true)",
                (str(rider_user), "authenticated"),
            )
            cur.execute("set local role authenticated")
            cur.execute("select complete_delivery(%s,%s,%s,'Delivered')", (rider, order_id, pod_path))
            return order_id, token

        # ---- No rate-limit/telemetry side effects: rate_limit_counters and
        # invalid_lookup_telemetry must be completely untouched by any
        # submit_rating call, of any outcome. ----
        cur.execute("reset role")
        cur.execute("select count(*) from rate_limit_counters where action like 'submit_rating%'")
        assert cur.fetchone()[0] == 0
        cur.execute("select coalesce(sum(request_count),0) from invalid_lookup_telemetry where action like 'submit_rating%'")
        telemetry_before = cur.fetchone()[0]

        _, token0 = new_delivered_order(1)
        cur.execute("reset role")
        cur.execute("set local role anon")

        # Positive: legitimate submit succeeds (unchanged foundation behavior).
        cur.execute("select submit_rating(%s,5,array['Great'])", (token0,))
        assert cur.fetchone()[0] is not None

        # Negative paths all preserved exactly, no new failure modes added,
        # and no rate limiting kicks in no matter how many times they repeat
        # (confirms telemetry/enforcement code was genuinely not wired in).
        for _ in range(12):
            rejected(cur, "select submit_rating(%s,4,array['Again'])", (token0,), "rating already submitted")
        for _ in range(3):
            rejected(cur, "select submit_rating(%s,9,array[]::text[])", (token0,), "invalid rating")
        rejected(cur, "select submit_rating('nonexistent-token-value',5,array[]::text[])", (), "invalid tracking token")

        cur.execute("reset role")
        cur.execute("select count(*) from rate_limit_counters where action like 'submit_rating%'")
        assert cur.fetchone()[0] == 0, "submit_rating must not write to rate_limit_counters at all"
        cur.execute("select coalesce(sum(request_count),0) from invalid_lookup_telemetry where action like 'submit_rating%'")
        telemetry_after = cur.fetchone()[0]
        assert telemetry_after == telemetry_before, "submit_rating must not write to invalid_lookup_telemetry at all"

        conn.rollback()

print("s4_04_batch_5_submit_rating_limit_ok")
