"""Rollback-only F2-09 (CEFFLO Flow 2 Canonical Backend Completion Master)
acceptance -- Founder closure decision: "reassignment/recovery ownership
changes are Vendor-authorized only; Rider may report an issue/request
assistance but must not independently release/reassign the order."

Proves initiate_delivery_recovery: (1) Vendor (Owner/Operator) succeeds --
order returns to created/unassigned, the original rider_assignments row is
preserved as cancelled (never deleted), and the delivery.recovery_initiated
audit event carries actor_role='vendor'; (2) the assigned Rider themselves
is denied outright -- the RPC no longer accepts any Rider-identifying
argument at all, so there is no input shape left for a Rider to even
attempt this call through; (3) a Helper (active business member, but not
Owner/Operator) is denied too, consistent with every other dispatch-
authority RPC (assign_rider/reassign_rider/build_rider_run/approve_order);
(4) a foreign business's owner is denied; (5) idempotent replay still
returns the same order state without acting twice."""

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


owner_a, helper_a, rider_a_user, owner_b = [uuid.uuid4() for _ in range(4)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in (
            (owner_a, "owner-a"), (helper_a, "helper-a"),
            (rider_a_user, "rider-a"), (owner_b, "owner-b"),
        ):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"f2-09-{label}-{uuid.uuid4()}@test.invalid"),
            )

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),"
                "set_config('request.jwt.claim.role',%s,true)",
                (str(user_id), role),
            )
            cur.execute(f"set local role {role}")

        # Setup runs under the default (unrestricted) connection role, same
        # as s4_11_batch_10_cancelled_order_boundary.py's own precedent --
        # business_members has no RLS INSERT policy for a plain client
        # (membership changes go through invitation RPCs, not raw inserts),
        # so fixture rows are seeded directly before any actor() switch.
        cur.execute("insert into businesses(name) values('F2-09 Recovery Biz A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values(%s,%s,'owner'),(%s,%s,'helper')",
            (business_a, owner_a, business_a, helper_a),
        )
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status,vehicle_type) "
            "values(%s,%s,'Rider A',%s,'active','motorcycle') returning id",
            (business_a, rider_a_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider_a = cur.fetchone()[0]

        cur.execute("insert into businesses(name) values('F2-09 Recovery Biz B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute("insert into business_members(business_id,user_id,role) values(%s,%s,'owner')", (business_b, owner_b))

        def fresh_order():
            actor(owner_a)
            cur.execute(
                "select create_delivery(%s,'F2-09 Customer','+60177777777','Recoverable Addr')",
                (business_a,),
            )
            order_id = cur.fetchone()[0]["order"]["id"]
            cur.execute("select approve_order(%s)", (order_id,))
            cur.execute("select assign_rider(%s,%s)", (order_id, rider_a))
            actor(rider_a_user)
            cur.execute("select accept_assignment(%s,%s)", (rider_a, order_id))
            cur.execute("select rider_transition(%s,%s,'ready_for_pickup')", (rider_a, order_id))
            cur.execute("select rider_transition(%s,%s,'picked_up')", (rider_a, order_id))
            cur.execute("select rider_transition(%s,%s,'out_for_delivery')", (rider_a, order_id))
            cur.execute(
                "select assignment_id from delivery_stops where order_id=%s", (order_id,)
            )
            assignment_id = cur.fetchone()[0]
            return order_id, assignment_id

        # =====================================================================
        # Rider denial: the assigned Rider themselves cannot recover their own
        # order -- p_rider_id no longer exists as an input at all, so there is
        # no way for a Rider identity to even shape a call that could pass;
        # is_business_operational(business_a) is simply false for a Rider
        # who holds no business_members row.
        # =====================================================================
        order_id, assignment_id = fresh_order()
        actor(rider_a_user)
        rejected(
            cur,
            "select initiate_delivery_recovery(%s,'customer_unreachable','Customer asked to reschedule',%s)",
            (order_id, uuid.uuid4()),
            "forbidden",
        )
        cur.execute("select delivery_status, assigned_rider_id from orders where id=%s", (order_id,))
        status, assigned = cur.fetchone()
        assert status == "out_for_delivery" and assigned == rider_a, "denied Rider call must not mutate the order"

        # =====================================================================
        # Helper denial: an active business member who is not Owner/Operator
        # cannot recover either -- matches the dispatch-authority boundary
        # already enforced on assign_rider/reassign_rider/build_rider_run.
        # =====================================================================
        actor(helper_a)
        rejected(
            cur,
            "select initiate_delivery_recovery(%s,'customer_unreachable','',%s)",
            (order_id, uuid.uuid4()),
            "forbidden",
        )

        # =====================================================================
        # Foreign-tenant denial: Business B's owner cannot touch Business A's
        # order.
        # =====================================================================
        actor(owner_b)
        rejected(
            cur,
            "select initiate_delivery_recovery(%s,'customer_unreachable','',%s)",
            (order_id, uuid.uuid4()),
            "forbidden",
        )

        # =====================================================================
        # Vendor success: Owner (or Operator -- same is_business_operational
        # gate) recovers the order -- returns to created/unassigned, the prior
        # rider_assignments row is cancelled (not deleted), and the audit
        # event records actor_role='vendor'.
        # =====================================================================
        actor(owner_a)
        idem = uuid.uuid4()
        cur.execute(
            "select id, delivery_status, assigned_rider_id, completed_at "
            "from initiate_delivery_recovery(%s,'customer_unreachable','Customer asked to reschedule',%s)",
            (order_id, idem),
        )
        recovered_id, status, assigned, completed_at = cur.fetchone()
        assert str(recovered_id) == order_id
        assert status == "created"
        assert assigned is None
        assert completed_at is None

        cur.execute("select status from rider_assignments where id=%s", (assignment_id,))
        assert cur.fetchone()[0] == "cancelled", "prior assignment must be preserved as cancelled, never deleted"

        cur.execute(
            "select actor_role, from_status, to_status, metadata->>'reason', metadata->>'previous_rider_id' "
            "from delivery_events where order_id=%s and event_type='delivery.recovery_initiated'",
            (order_id,),
        )
        actor_role, from_status, to_status, reason, prev_rider = cur.fetchone()
        assert actor_role == "vendor"
        assert from_status == "out_for_delivery" and to_status == "created"
        assert reason == "customer_unreachable"
        assert prev_rider == str(rider_a)

        cur.execute("select sequence, assignment_id, rider_id from delivery_stops where order_id=%s", (order_id,))
        seq, stop_assignment, stop_rider = cur.fetchone()
        assert seq is None and stop_assignment is None and stop_rider is None

        # =====================================================================
        # Idempotent replay: the same idempotency key returns the same order
        # state without acting twice -- Vendor gate is still enforced on
        # replay too.
        # =====================================================================
        cur.execute(
            "select delivery_status from initiate_delivery_recovery(%s,'customer_unreachable','Customer asked to reschedule',%s)",
            (order_id, idem),
        )
        assert cur.fetchone()[0] == "created"

        actor(rider_a_user)
        rejected(
            cur,
            "select initiate_delivery_recovery(%s,'customer_unreachable','',%s)",
            (order_id, idem),
            "forbidden",
        )

        conn.rollback()

print("f2_09_recovery_vendor_only_ok")
