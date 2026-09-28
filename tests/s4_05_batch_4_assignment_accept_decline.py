"""Rollback-only S4-05 Batch-4 assignment accept/decline acceptance."""

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


owner_a, rider_a, rider_a_inactive, owner_b, rider_b = [uuid.uuid4() for _ in range(5)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in (
            (owner_a, "owner-a"),
            (rider_a, "rider-a"),
            (rider_a_inactive, "rider-a-inactive"),
            (owner_b, "owner-b"),
            (rider_b, "rider-b"),
        ):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"s4-05-b4-{label}-{uuid.uuid4()}@test.invalid"),
            )
        cur.execute("insert into businesses(name) values('S4-05 B4 Business A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-05 B4 Business B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values(%s,%s,'owner'),(%s,%s,'owner')",
            (business_a, owner_a, business_b, owner_b),
        )
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) "
            "values(%s,%s,'B4 Rider A',%s,'active') returning id",
            (business_a, rider_a, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider_a_id = cur.fetchone()[0]
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) "
            "values(%s,%s,'B4 Rider A Inactive',%s,'inactive') returning id",
            (business_a, rider_a_inactive, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider_a_inactive_id = cur.fetchone()[0]
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) "
            "values(%s,%s,'B4 Rider B',%s,'active') returning id",
            (business_b, rider_b, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider_b_id = cur.fetchone()[0]

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),"
                "set_config('request.jwt.claim.role',%s,true)",
                (str(user_id), role),
            )
            cur.execute(f"set local role {role}")

        def new_assigned_order(phone_suffix):
            actor(owner_a)
            cur.execute("select create_delivery(%s,'B4 Customer',%s,'Addr')", (business_a, f"+601600{phone_suffix:04d}"))
            order_id = cur.fetchone()[0]["order"]["id"]
            cur.execute("select approve_order(%s)", (order_id,))
            cur.execute("select assign_rider(%s,%s)", (order_id, rider_a_id))
            return order_id

        # ---- Newly assigned assignment has the correct pending state. ----
        order_1 = new_assigned_order(1)
        cur.execute("reset role")
        cur.execute(
            "select a.status, a.accepted_at from rider_assignments a join delivery_stops s on s.assignment_id=a.id where s.order_id=%s",
            (order_1,),
        )
        status, accepted_at = cur.fetchone()
        assert status == "assigned" and accepted_at is None, "a fresh assignment must be pending, not pre-accepted"

        # ---- rider_transition before acceptance denied. ----
        actor(rider_a)
        rejected(cur, "select rider_transition(%s,%s,'ready_for_pickup')", (rider_a_id, order_1), "assignment not accepted")

        # ---- Unauthenticated actor denied (grant-layer denial for anon,
        # distinct from the in-function 'forbidden' check for a wrong
        # authenticated actor -- same distinction already established in
        # tests/s4_04_batch_3_token_lifecycle.py). ----
        actor(owner_a, "anon")
        rejected(cur, "select accept_assignment(%s,%s)", (rider_a_id, order_1), "permission denied")

        # ---- Wrong Rider (genuinely owns rider_b_id, a real active
        # relationship -- just the wrong one for this order/business) denied. ----
        actor(rider_b)
        rejected(cur, "select accept_assignment(%s,%s)", (rider_b_id, order_1), "forbidden")
        # An identity with no relationship at all to rider_a_id cannot spoof
        # it either -- rejected at the ownership gate itself (S4-07.3a).
        rejected(cur, "select accept_assignment(%s,%s)", (rider_a_id, order_1), "invalid rider context")

        # ---- Cross-business Rider denied (rider_b belongs to business_b entirely). ----
        actor(owner_b)
        cur.execute("select create_delivery(%s,'B4 Customer B','+60170000000','Addr')", (business_b,))
        order_b = cur.fetchone()[0]["order"]["id"]
        cur.execute("select approve_order(%s)", (order_b,))
        cur.execute("select assign_rider(%s,%s)", (order_b, rider_b_id))
        actor(rider_a)
        rejected(cur, "select accept_assignment(%s,%s)", (rider_a_id, order_b), "forbidden")

        # ---- Inactive Rider relationship cannot be used at all, even by its
        # own genuine owner (is_current_rider requires status='active'). ----
        actor(rider_a_inactive)
        rejected(cur, "select accept_assignment(%s,%s)", (rider_a_inactive_id, order_1), "invalid rider context")

        # ---- Correct Rider ACCEPT succeeds; accepted_at is authoritative. ----
        actor(rider_a)
        cur.execute("select accept_assignment(%s,%s)", (rider_a_id, order_1))
        cur.execute("reset role")
        cur.execute(
            "select a.status, a.accepted_at is not null from rider_assignments a join delivery_stops s on s.assignment_id=a.id where s.order_id=%s",
            (order_1,),
        )
        status, has_accepted_at = cur.fetchone()
        assert status == "accepted" and has_accepted_at is True

        # ---- Duplicate accept safe (idempotent, timestamp unchanged). ----
        cur.execute(
            "select accepted_at from rider_assignments a join delivery_stops s on s.assignment_id=a.id where s.order_id=%s",
            (order_1,),
        )
        first_accepted_at = cur.fetchone()[0]
        actor(rider_a)
        cur.execute("select accept_assignment(%s,%s)", (rider_a_id, order_1))
        cur.execute("reset role")
        cur.execute(
            "select accepted_at from rider_assignments a join delivery_stops s on s.assignment_id=a.id where s.order_id=%s",
            (order_1,),
        )
        assert cur.fetchone()[0] == first_accepted_at, "duplicate accept must not change accepted_at"

        # ---- Invalid decline-after-accept denied. ----
        actor(rider_a)
        rejected(cur, "select decline_assignment(%s,%s)", (rider_a_id, order_1), "assignment not pending")

        # ---- rider_transition after acceptance preserves the legitimate happy path. ----
        actor(rider_a)
        for status_name in ("ready_for_pickup", "picked_up", "out_for_delivery", "arrived"):
            cur.execute("select rider_transition(%s,%s,%s)", (rider_a_id, order_1, status_name))
        pod_path = f"{rider_a_id}/{order_1}/test.jpg"
        cur.execute("reset role")
        cur.execute("insert into storage.objects(bucket_id, name) values ('cefflo-pod', %s)", (pod_path,))
        actor(rider_a)
        cur.execute("select complete_delivery(%s,%s,%s,'Delivered')", (rider_a_id, order_1, pod_path))
        cur.execute("reset role")
        cur.execute("select delivery_status from orders where id=%s", (order_1,))
        assert cur.fetchone()[0] == "delivered"

        # ---- Assignment events recorded exactly once. ----
        cur.execute(
            "select count(*) from delivery_events where order_id=%s and event_type='assignment.accepted'", (order_1,)
        )
        assert cur.fetchone()[0] == 1, "exactly one acceptance event, even after the idempotent duplicate accept"

        # ---- Correct Rider DECLINE succeeds (fresh order). ----
        order_2 = new_assigned_order(2)
        actor(rider_a)
        cur.execute("select decline_assignment(%s,%s)", (rider_a_id, order_2))
        cur.execute("reset role")
        cur.execute(
            "select a.status from rider_assignments a join delivery_stops s on s.assignment_id=a.id where s.order_id=%s",
            (order_2,),
        )
        assert cur.fetchone()[0] == "declined"
        cur.execute(
            "select count(*) from delivery_events where order_id=%s and event_type='assignment.declined'", (order_2,)
        )
        assert cur.fetchone()[0] == 1

        # ---- Duplicate decline safe. ----
        actor(rider_a)
        cur.execute("select decline_assignment(%s,%s)", (rider_a_id, order_2))
        cur.execute("reset role")
        cur.execute(
            "select count(*) from delivery_events where order_id=%s and event_type='assignment.declined'", (order_2,)
        )
        assert cur.fetchone()[0] == 1, "duplicate decline must not add a second event"

        # ---- Invalid accept-after-decline denied. ----
        actor(rider_a)
        rejected(cur, "select accept_assignment(%s,%s)", (rider_a_id, order_2), "assignment not pending")

        # ---- rider_transition still denied after a decline. ----
        actor(rider_a)
        rejected(cur, "select rider_transition(%s,%s,'ready_for_pickup')", (rider_a_id, order_2), "assignment not accepted")

        # ---- No direct rider_assignments mutation reopened. ----
        actor(rider_a)
        cur.execute(
            "select a.id from rider_assignments a join delivery_stops s on s.assignment_id=a.id where s.order_id=%s",
            (order_1,),
        )
        assignment_id = cur.fetchone()[0]
        savepoint = "denied_direct"
        cur.execute(f"savepoint {savepoint}")
        cur.execute("update rider_assignments set status='cancelled' where id=%s", (assignment_id,))
        assert cur.rowcount == 0, "direct UPDATE on rider_assignments must remain fully blocked"
        cur.execute(f"rollback to savepoint {savepoint}")

        conn.rollback()

print("s4_05_batch_4_assignment_accept_decline_ok")
