"""Rollback-only S4-04 Batch-2 POD-path minimization acceptance."""

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


owner_a, owner_b, rider_user, outsider = [uuid.uuid4() for _ in range(4)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in (
            (owner_a, "owner-a"),
            (owner_b, "owner-b"),
            (rider_user, "rider-a"),
            (outsider, "outsider"),
        ):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"s4-04-b2-{label}-{uuid.uuid4()}@test.invalid"),
            )

        cur.execute("insert into businesses(name) values('S4-04 B2 Business A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-04 B2 Business B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values(%s,%s,'owner'),(%s,%s,'owner')",
            (business_a, owner_a, business_b, owner_b),
        )
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) "
            "values(%s,%s,'B2 Rider A',%s,'active') returning id",
            (business_a, rider_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider_a = cur.fetchone()[0]

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),"
                "set_config('request.jwt.claim.role',%s,true)",
                (str(user_id), role),
            )
            if role == "authenticated":
                cur.execute("set local role authenticated")
            elif role == "anon":
                cur.execute("set local role anon")
            elif role == "service_role":
                cur.execute("set local role service_role")
            else:
                raise AssertionError(f"unsupported actor role: {role}")

        # Full happy path through protected contracts, undelivered order first.
        actor(owner_a)
        cur.execute("select create_delivery(%s,'B2 Customer','+60120000000','Addr')", (business_a,))
        created = cur.fetchone()[0]
        order_id, token = created["order"]["id"], created["tracking_token"]
        cur.execute("select approve_order(%s)", (order_id,))
        cur.execute("select assign_rider(%s,%s)", (order_id, rider_a))

        actor(outsider, "anon")
        cur.execute("select public_tracking(%s)", (token,))
        pre_delivery = cur.fetchone()[0]
        assert "pod_path" not in pre_delivery, "raw pod_path key must never be present"
        assert pre_delivery["pod_available"] is False, "undelivered order must report pod_available=false"

        actor(rider_user)
        cur.execute("select accept_assignment(%s,%s)", (rider_a, order_id))
        for status in ("ready_for_pickup", "picked_up", "out_for_delivery", "arrived"):
            cur.execute("select rider_transition(%s,%s,%s)", (rider_a, order_id, status))
        pod_path = f"{rider_a}/{order_id}/test.jpg"
        cur.execute("reset role")
        cur.execute("insert into storage.objects(bucket_id, name) values ('cefflo-pod', %s)", (pod_path,))
        actor(rider_user)
        cur.execute(
            "select complete_delivery(%s,%s,%s,'Delivered')",
            (rider_a, order_id, pod_path),
        )

        # Public/customer contract: boolean only, never the raw path, in any form.
        actor(outsider, "anon")
        cur.execute("select public_tracking(%s)", (token,))
        post_delivery = cur.fetchone()[0]
        assert "pod_path" not in post_delivery, "raw pod_path key must never be present"
        assert post_delivery["pod_available"] is True, "delivered order must report pod_available=true"
        for value in post_delivery.values():
            assert not (isinstance(value, str) and pod_path in value), (
                f"public_tracking leaked a raw storage path: {value!r}"
            )

        # Public/anon and ordinary authenticated callers must never reach the internal lookup.
        rejected(cur, "select internal_tracking_pod_path(%s)", (token,), "permission denied")
        actor(owner_a)
        rejected(cur, "select internal_tracking_pod_path(%s)", (token,), "permission denied")
        actor(rider_user)
        rejected(cur, "select internal_tracking_pod_path(%s)", (token,), "permission denied")

        # Cross-business: Business B's owner gets nothing from a Business A token either way.
        actor(owner_b)
        rejected(cur, "select internal_tracking_pod_path(%s)", (token,), "permission denied")

        # Only the Edge Function's privileged role can resolve the real path, and only via a
        # valid, non-expired, non-revoked token for a delivered order.
        cur.execute("reset role")
        cur.execute("set local role service_role")
        cur.execute("select internal_tracking_pod_path(%s)", (token,))
        real_path = cur.fetchone()[0]
        assert real_path == pod_path, real_path

        cur.execute("select internal_tracking_pod_path('not-a-real-token')")
        assert cur.fetchone()[0] is None

        conn.rollback()

print("s4_04_batch_2_pod_path_ok")
