"""Rollback-only S4-05 Batch-1 order-approval acceptance."""

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


owner_a, operator_a, owner_b, rider_a = [uuid.uuid4() for _ in range(4)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in (
            (owner_a, "owner-a"),
            (operator_a, "operator-a"),
            (owner_b, "owner-b"),
            (rider_a, "rider-a"),
        ):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"s4-05-b1-{label}-{uuid.uuid4()}@test.invalid"),
            )

        cur.execute("insert into businesses(name) values('S4-05 B1 Business A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-05 B1 Business B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values"
            "(%s,%s,'owner'),(%s,%s,'operator'),(%s,%s,'owner')",
            (business_a, owner_a, business_a, operator_a, business_b, owner_b),
        )
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) "
            "values(%s,%s,'B1 Rider A',%s,'active') returning id",
            (business_a, rider_a, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider_id = cur.fetchone()[0]

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),"
                "set_config('request.jwt.claim.role',%s,true)",
                (str(user_id), role),
            )
            cur.execute(f"set local role {role}")

        # ---- Schema: new columns exist, null by default. ----
        actor(owner_a)
        cur.execute("select create_delivery(%s,'B1 Customer','+60140000000','Addr')", (business_a,))
        order_id = cur.fetchone()[0]["order"]["id"]
        cur.execute("reset role")
        cur.execute("select approved_at, approved_by from orders where id=%s", (order_id,))
        approved_at, approved_by = cur.fetchone()
        assert approved_at is None and approved_by is None, "a newly created order must start unapproved"

        # ---- Gate: assign_rider rejects an unapproved order. ----
        actor(owner_a)
        rejected(cur, "select assign_rider(%s,%s)", (order_id, rider_id), "order not approved")

        # ---- Cross-business denial: Business B cannot approve Business A's order. ----
        actor(owner_b)
        rejected(cur, "select approve_order(%s)", (order_id,), "forbidden")

        # ---- Owner authorization: Owner can approve. (approve_order/assign_rider
        # return composite `orders` rows, not jsonb -- verify via ground-truth
        # SELECT rather than parsing the composite return value.) ----
        actor(owner_a)
        cur.execute("select approve_order(%s)", (order_id,))
        cur.execute("reset role")
        cur.execute("select approved_at, approved_by from orders where id=%s", (order_id,))
        first_approved_at, approved_by = cur.fetchone()
        assert first_approved_at is not None
        assert approved_by == owner_a

        # ---- Idempotent: re-approving is a harmless no-op, not an error. ----
        actor(owner_a)
        cur.execute("select approve_order(%s)", (order_id,))
        cur.execute("reset role")
        cur.execute("select approved_at from orders where id=%s", (order_id,))
        assert cur.fetchone()[0] == first_approved_at, "re-approval must not change the timestamp"

        # ---- Delivery event recorded exactly once (idempotent re-approve added none). ----
        cur.execute(
            "select actor_role, actor_user_id from delivery_events where order_id=%s and event_type='order.approved'",
            (order_id,),
        )
        events = cur.fetchall()
        assert len(events) == 1, "approval must record exactly one event, even after an idempotent re-approve"
        assert events[0][0] == "vendor"
        assert events[0][1] == owner_a

        # ---- Approved happy path: assign_rider now succeeds. ----
        actor(owner_a)
        cur.execute("select assign_rider(%s,%s)", (order_id, rider_id))
        cur.execute("reset role")
        cur.execute("select assigned_rider_id from orders where id=%s", (order_id,))
        assert cur.fetchone()[0] == rider_id

        # ---- Operator/Staff authorization: a fresh order, approved by an operator. ----
        actor(owner_a)
        cur.execute("select create_delivery(%s,'B1 Customer 2','+60140000001','Addr')", (business_a,))
        order_id_2 = cur.fetchone()[0]["order"]["id"]

        actor(operator_a)
        cur.execute("select approve_order(%s)", (order_id_2,))
        cur.execute("reset role")
        cur.execute("select approved_at from orders where id=%s", (order_id_2,))
        assert cur.fetchone()[0] is not None, "Operator/Staff must be authorized to approve"

        actor(operator_a)
        cur.execute("select assign_rider(%s,%s)", (order_id_2, rider_id))
        cur.execute("reset role")
        cur.execute("select assigned_rider_id from orders where id=%s", (order_id_2,))
        assert cur.fetchone()[0] == rider_id

        # ---- Existing rider_assignments/assign_rider mechanics unchanged. ----
        cur.execute("reset role")
        cur.execute(
            "select status from rider_assignments where rider_id=%s order by assigned_at desc limit 1",
            (rider_id,),
        )
        assert cur.fetchone()[0] == "assigned", "assign_rider's existing rider_assignments behavior is unaffected"

        conn.rollback()

print("s4_05_batch_1_order_approval_ok")
