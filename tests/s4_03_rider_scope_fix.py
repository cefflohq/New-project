"""Rollback-only regression for the S4-03 NULL-safe rider assignment fix."""

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


def rejected(cur, statement, params, expected):
    savepoint = f"rejected_{uuid.uuid4().hex}"
    cur.execute(f"savepoint {savepoint}")
    try:
        cur.execute(statement, params)
    except psycopg.Error as error:
        cur.execute(f"rollback to savepoint {savepoint}")
        assert expected in str(error), str(error)
    else:
        raise AssertionError(f"expected rejection containing {expected!r}")


owner_a, owner_b, rider_a_user, rider_a2_user, rider_b_user, inactive_user, unknown_user = [
    uuid.uuid4() for _ in range(7)
]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in (
            (owner_a, "owner-a"),
            (owner_b, "owner-b"),
            (rider_a_user, "rider-a"),
            (rider_a2_user, "rider-a2"),
            (rider_b_user, "rider-b"),
            (inactive_user, "inactive"),
        ):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"s4-03-scope-{label}-{uuid.uuid4()}@test.invalid"),
            )

        cur.execute("insert into businesses(name) values('S4-03 Scope Business A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-03 Scope Business B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values(%s,%s,'owner'),(%s,%s,'owner')",
            (business_a, owner_a, business_b, owner_b),
        )

        def rider(business_id, user_id, name, status="active"):
            cur.execute(
                "insert into riders(business_id,auth_user_id,name,phone,status) values(%s,%s,%s,%s,%s) returning id",
                (business_id, user_id, name, f"+60{uuid.uuid4().int % 10**9:09d}", status),
            )
            return cur.fetchone()[0]

        rider_a = rider(business_a, rider_a_user, "Scope Rider A")
        rider_a2 = rider(business_a, rider_a2_user, "Scope Rider A2")
        rider_b = rider(business_b, rider_b_user, "Scope Rider B")
        inactive_rider = rider(business_a, inactive_user, "Scope Inactive", "inactive")

        def order(business_id, assigned_rider_id=None, status="created"):
            cur.execute(
                "insert into orders(business_id,customer_name,customer_phone,delivery_address,assigned_rider_id,delivery_status) "
                "values(%s,'Scope Customer',%s,'Scope Address',%s,%s) returning id",
                (business_id, f"+60{uuid.uuid4().int % 10**9:09d}", assigned_rider_id, status),
            )
            order_id = cur.fetchone()[0]
            cur.execute(
                "insert into delivery_stops(business_id,order_id,rider_id,status) values(%s,%s,%s,%s)",
                (business_id, order_id, assigned_rider_id, status),
            )
            return order_id

        happy_order = order(business_a, rider_a)
        # This test builds ground-truth fixtures via raw INSERT (not the
        # create_delivery/assign_rider RPCs), so happy_order has no
        # rider_assignments row at all. S4-05.4 requires an accepted
        # assignment before rider_transition proceeds -- insert one directly,
        # pre-accepted, matching this test's own raw-fixture style. The
        # negative cases below are unaffected: they all fail at the earlier,
        # untouched authorization check before ever reaching the new one.
        cur.execute(
            "insert into rider_assignments(business_id,rider_id,status,accepted_at) "
            "values(%s,%s,'accepted',now()) returning id",
            (business_a, rider_a),
        )
        happy_assignment_id = cur.fetchone()[0]
        cur.execute(
            "update delivery_stops set assignment_id=%s where order_id=%s",
            (happy_assignment_id, happy_order),
        )
        other_rider_order = order(business_a, rider_a2)
        null_order_a = order(business_a)
        null_order_b = order(business_b)
        assigned_order_b = order(business_b, rider_b)
        inactive_order = order(business_a, inactive_rider)
        null_arrived = order(business_a, None, "arrived")

        def actor(user_id):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),"
                "set_config('request.jwt.claim.role','authenticated',true)",
                (str(user_id),),
            )
            cur.execute("set local role authenticated")

        actor(rider_a_user)
        rejected(cur, "select rider_transition(%s,%s,'ready_for_pickup')", (rider_a, other_rider_order), "forbidden")
        rejected(cur, "select rider_transition(%s,%s,'ready_for_pickup')", (rider_a, null_order_a), "forbidden")
        rejected(cur, "select rider_transition(%s,%s,'ready_for_pickup')", (rider_a, null_order_b), "forbidden")
        rejected(cur, "select rider_transition(%s,%s,'ready_for_pickup')", (rider_a, assigned_order_b), "forbidden")
        rejected(cur, "select complete_delivery(%s,%s,%s)", (rider_a, null_arrived, "scope/null.jpg"), "forbidden")

        # An identity with no rider row at all cannot spoof ownership of
        # someone else's relationship id -- rejected at the ownership gate
        # itself (S4-07.3a), before ever reaching the per-order comparison.
        actor(unknown_user)
        rejected(cur, "select rider_transition(%s,%s,'ready_for_pickup')", (rider_a, happy_order), "invalid rider context")

        # A genuinely-owned but inactive relationship cannot be used either.
        actor(inactive_user)
        rejected(cur, "select rider_transition(%s,%s,'ready_for_pickup')", (inactive_rider, inactive_order), "invalid rider context")

        actor(rider_a_user)
        for status in ("ready_for_pickup", "picked_up", "out_for_delivery", "arrived"):
            cur.execute("select (rider_transition(%s,%s,%s)).delivery_status", (rider_a, happy_order, status))
            assert cur.fetchone()[0] == status

        rejected(cur, "select complete_delivery(%s,%s,%s)", (rider_a, happy_order, ""), "arrival and POD required")
        pod_path = f"{rider_a}/{happy_order}/scope.jpg"
        cur.execute("reset role")
        cur.execute("insert into storage.objects(bucket_id, name) values ('cefflo-pod', %s)", (pod_path,))
        actor(rider_a_user)
        cur.execute(
            "select (complete_delivery(%s,%s,%s,%s)).delivery_status",
            (rider_a, happy_order, pod_path, "Scope complete"),
        )
        assert cur.fetchone()[0] == "delivered"

        conn.rollback()

print("s4_03_rider_scope_fix_ok")
