"""Rollback-only S4-05.6 full integration acceptance.

Exercises the complete authoritative S4-05 flow in one chain:
  create order -> approve order -> create/attach delivery session
  -> assign rider -> Rider sees pending assignment -> accept assignment
  -> delivery lifecycle -> complete delivery
plus the decline path (non-actionable, no auto-reassignment) and a
cross-business isolation sweep across every S4-05 contract together.
Individual behaviors are already covered in isolation by
tests/s4_05_batch_1/3/4_*.py -- this file's job is the CHAIN and the
cross-contract interactions, not re-proving each piece alone.
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


def affects_zero(cur, statement, params=()):
    cur.execute(statement, params)
    assert cur.rowcount == 0, f"direct mutation affected {cur.rowcount} row(s): {statement}"


owner_a, operator_a, rider_a_user, owner_b, rider_b_user = [uuid.uuid4() for _ in range(5)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in (
            (owner_a, "owner-a"),
            (operator_a, "operator-a"),
            (rider_a_user, "rider-a"),
            (owner_b, "owner-b"),
            (rider_b_user, "rider-b"),
        ):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"s4-05-b6-{label}-{uuid.uuid4()}@test.invalid"),
            )
        cur.execute("insert into businesses(name) values('S4-05 B6 Business A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-05 B6 Business B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values"
            "(%s,%s,'owner'),(%s,%s,'operator'),(%s,%s,'owner')",
            (business_a, owner_a, business_a, operator_a, business_b, owner_b),
        )
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) "
            "values(%s,%s,'B6 Rider A',%s,'active') returning id",
            (business_a, rider_a_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider_a = cur.fetchone()[0]
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) "
            "values(%s,%s,'B6 Rider B',%s,'active') returning id",
            (business_b, rider_b_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider_b = cur.fetchone()[0]

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),"
                "set_config('request.jwt.claim.role',%s,true)",
                (str(user_id), role),
            )
            cur.execute(f"set local role {role}")

        # =====================================================================
        # PART 1 -- the complete authoritative happy-path chain, in order.
        # =====================================================================

        # 1. Create order.
        actor(owner_a)
        cur.execute("select create_delivery(%s,'B6 Customer','+60180000000','Addr')", (business_a,))
        created = cur.fetchone()[0]
        order_id, token = created["order"]["id"], created["tracking_token"]
        cur.execute("reset role")
        cur.execute("select approved_at, delivery_session_id from orders where id=%s", (order_id,))
        approved_at, session_id = cur.fetchone()
        assert approved_at is None and session_id is None, "a freshly created order starts unapproved and session-less"

        # 2. Approve order (Operator/Staff, to also exercise that authorization path).
        actor(operator_a)
        cur.execute("select approve_order(%s)", (order_id,))
        cur.execute("reset role")
        cur.execute("select approved_at from orders where id=%s", (order_id,))
        assert cur.fetchone()[0] is not None, "order must be approved before continuing the chain"

        # 3. Create a delivery session and attach the order to it ("where applicable").
        actor(owner_a)
        cur.execute("select create_delivery_session(%s,'B6 Morning Run', current_date)", (business_a,))
        cur.execute("reset role")
        cur.execute("select id from delivery_sessions where business_id=%s order by created_at desc limit 1", (business_a,))
        session_id = cur.fetchone()[0]
        actor(owner_a)
        cur.execute("select attach_order_to_session(%s,%s)", (order_id, session_id))
        cur.execute("reset role")
        cur.execute("select delivery_session_id from orders where id=%s", (order_id,))
        assert cur.fetchone()[0] == session_id, "the order must be attached to the session before assignment"

        # 4. Assign rider. assign_rider must snapshot the now-attached session
        # onto the new rider_assignments row (existing S4-05.1-era behavior,
        # re-verified here in the full chain rather than in isolation).
        actor(owner_a)
        cur.execute("select assign_rider(%s,%s)", (order_id, rider_a))
        cur.execute("reset role")
        cur.execute(
            "select a.status, a.accepted_at, a.delivery_session_id "
            "from rider_assignments a join delivery_stops s on s.assignment_id=a.id where s.order_id=%s",
            (order_id,),
        )
        assignment_status, accepted_at, assignment_session_id = cur.fetchone()
        assert assignment_status == "assigned" and accepted_at is None, "5. Rider sees a pending, unaccepted assignment"
        assert assignment_session_id == session_id, "assign_rider must snapshot the order's already-attached session"

        # 5 (continued). Lifecycle must not be startable before acceptance.
        actor(rider_a_user)
        rejected(cur, "select rider_transition(%s,%s,'ready_for_pickup')", (rider_a, order_id), "assignment not accepted")

        # 6. Accept assignment.
        actor(rider_a_user)
        cur.execute("select accept_assignment(%s,%s)", (rider_a, order_id))
        cur.execute("reset role")
        cur.execute(
            "select a.status, a.accepted_at is not null "
            "from rider_assignments a join delivery_stops s on s.assignment_id=a.id where s.order_id=%s",
            (order_id,),
        )
        assignment_status, has_accepted_at = cur.fetchone()
        assert assignment_status == "accepted" and has_accepted_at is True

        # 7. Delivery lifecycle now proceeds normally. S4-06.7 (P2, Founder-
        # approved): an order that belongs to a session (this one does --
        # step 3 attached it) now requires that session's Run sequence to be
        # genuinely locked via start_run_delivery before it may move past
        # picked_up -- even a session with only this one stop. This is new
        # since this test was first written (S4-05, before S4-06 existed);
        # the pickup-phase transitions remain exactly as before.
        actor(rider_a_user)
        cur.execute("select save_run_sequence(%s,%s,%s)", (rider_a, session_id, [order_id]))
        cur.execute("select start_pickup_run(%s,%s)", (rider_a, session_id))
        for status in ("ready_for_pickup", "picked_up"):
            cur.execute("select rider_transition(%s,%s,%s)", (rider_a, order_id, status))
        cur.execute("select start_run_delivery(%s,%s)", (rider_a, session_id))
        for status in ("out_for_delivery", "arrived"):
            cur.execute("select rider_transition(%s,%s,%s)", (rider_a, order_id, status))

        # 8. Complete delivery.
        pod_path = f"{rider_a}/{order_id}/test.jpg"
        cur.execute("reset role")
        cur.execute("insert into storage.objects(bucket_id, name) values ('cefflo-pod', %s)", (pod_path,))
        actor(rider_a_user)
        cur.execute("select complete_delivery(%s,%s,%s,'Delivered')", (rider_a, order_id, pod_path))
        cur.execute("reset role")
        cur.execute("select delivery_status from orders where id=%s", (order_id,))
        assert cur.fetchone()[0] == "delivered", "the full chain must reach a real, backend-recorded delivered state"

        # Customer tracking still works end to end after the full chain.
        actor(owner_a, "anon")
        cur.execute("select public_tracking(%s)", (token,))
        snapshot = cur.fetchone()[0]
        assert snapshot["status"] == "delivered"

        # delivery_events coverage across the whole chain, in order, exactly once each.
        cur.execute("reset role")
        cur.execute(
            "select event_type from delivery_events where order_id=%s or "
            "(order_id is null and business_id=%s and event_type like 'session.%%') order by created_at",
            (order_id, business_a),
        )
        chain_events = [row[0] for row in cur.fetchall()]
        expected_prefix = [
            "delivery.created",
            "order.approved",
            "session.created",
            "session.order_attached",
            "rider.assigned",
            "assignment.accepted",
            "run.sequence_saved",
            "session.status_changed",  # S4-06.7 (P4): auto planned -> active, from start_pickup_run
            "delivery.status_changed",
            "delivery.status_changed",
            "run.sequence_locked",
            "delivery.status_changed",
            "delivery.status_changed",
            "delivery.completed",
            "session.status_changed",  # S4-06.7 (P4): auto active -> completed, from complete_delivery (the session's one and only order)
        ]
        assert chain_events == expected_prefix, f"unexpected event sequence: {chain_events}"

        # =====================================================================
        # PART 2 -- decline path: non-actionable, no auto-reassignment.
        # =====================================================================
        actor(owner_a)
        cur.execute("select create_delivery(%s,'B6 Customer 2','+60180000001','Addr')", (business_a,))
        order_2 = cur.fetchone()[0]["order"]["id"]
        cur.execute("select approve_order(%s)", (order_2,))
        cur.execute("select assign_rider(%s,%s)", (order_2, rider_a))

        actor(rider_a_user)
        cur.execute("select decline_assignment(%s,%s)", (rider_a, order_2))

        # Non-actionable: lifecycle remains blocked exactly as if never accepted.
        rejected(cur, "select rider_transition(%s,%s,'ready_for_pickup')", (rider_a, order_2), "assignment not accepted")

        # No auto-reassignment: assigned_rider_id and rider_assignments.rider_id
        # both remain rider_a -- the system never silently reassigns.
        cur.execute("reset role")
        cur.execute("select assigned_rider_id from orders where id=%s", (order_2,))
        assert cur.fetchone()[0] == rider_a, "decline must not trigger any automatic reassignment"
        cur.execute(
            "select a.status, a.rider_id from rider_assignments a join delivery_stops s on s.assignment_id=a.id where s.order_id=%s",
            (order_2,),
        )
        decline_status, decline_rider = cur.fetchone()
        assert decline_status == "declined" and decline_rider == rider_a

        # The Vendor's own remedy path (reassign_rider) still works afterward --
        # confirming decline doesn't corrupt the order for future vendor action --
        # without this batch having implemented any automation for it.
        cur.execute("reset role")
        cur.execute("insert into riders(business_id,auth_user_id,name,phone,status) values(%s,null,'B6 Rider A2',%s,'active') returning id", (business_a, f"+60{uuid.uuid4().int % 10**9:09d}"))
        rider_a2 = cur.fetchone()[0]
        actor(owner_a)
        cur.execute("select (reassign_rider(%s,%s)).assigned_rider_id", (order_2, rider_a2))
        assert cur.fetchone()[0] == rider_a2, "Vendor can still manually reassign a declined order (no automation, but not corrupted)"

        # =====================================================================
        # PART 3 -- cross-business isolation sweep across all S4-05 contracts.
        # =====================================================================
        actor(owner_b)
        rejected(cur, "select approve_order(%s)", (order_id,), "forbidden")
        rejected(cur, "select create_delivery_session(%s,'Intrusion', current_date)", (business_a,), "forbidden")
        rejected(cur, "select attach_order_to_session(%s,%s)", (order_id, session_id), "forbidden")
        rejected(cur, "select update_session_status(%s,'active')", (session_id,), "forbidden")

        actor(rider_b_user)
        rejected(cur, "select accept_assignment(%s,%s)", (rider_b, order_id), "forbidden")
        rejected(cur, "select decline_assignment(%s,%s)", (rider_b, order_id), "forbidden")

        # =====================================================================
        # PART 4 -- direct-write/RLS protections re-verified across all three
        # S4-05 tables together in one sweep.
        # =====================================================================
        actor(owner_a)
        rejected(cur, "insert into delivery_sessions(business_id,name) values(%s,'Bypass')", (business_a,))
        affects_zero(cur, "update delivery_sessions set name='bypass' where id=%s", (session_id,))
        affects_zero(cur, "delete from delivery_sessions where id=%s", (session_id,))
        affects_zero(cur, "update orders set approved_at=null where id=%s", (order_id,))
        cur.execute("reset role")
        cur.execute(
            "select a.id from rider_assignments a join delivery_stops s on s.assignment_id=a.id where s.order_id=%s",
            (order_id,),
        )
        assignment_id = cur.fetchone()[0]
        actor(owner_a)
        affects_zero(cur, "update rider_assignments set status='cancelled' where id=%s", (assignment_id,))

        # =====================================================================
        # PART 5 -- database integrity: no orphaned/contradictory state.
        # =====================================================================
        cur.execute("reset role")
        cur.execute(
            "select count(*) from rider_assignments a join delivery_stops s on s.assignment_id=a.id "
            "where s.order_id=%s and a.status='accepted' and a.accepted_at is null",
            (order_id,),
        )
        assert cur.fetchone()[0] == 0, "an accepted assignment must always carry accepted_at"
        cur.execute("select count(*) from orders where approved_at is not null and approved_by is null")
        assert cur.fetchone()[0] == 0, "an approved order must always carry approved_by"
        cur.execute(
            "select count(*) from orders o where o.delivery_session_id is not null "
            "and not exists(select 1 from delivery_sessions s where s.id=o.delivery_session_id and s.business_id=o.business_id)"
        )
        assert cur.fetchone()[0] == 0, "an attached session must always belong to the order's own business"

        conn.rollback()

print("s4_05_batch_6_full_integration_ok")
