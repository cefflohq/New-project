"""Rollback-only S4-06 Batch-2 Plan Route / Pickup Checklist / Delivery Run
backend contract acceptance.

Updated for S4-07.3a: every Rider RPC now takes explicit p_rider_id as its
first parameter; POD completion now requires a real storage.objects row to
exist for the submitted path before complete_delivery accepts it.
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


owner_a, rider1_user, rider2_user, owner_b, rider3_user = [uuid.uuid4() for _ in range(5)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in (
            (owner_a, "owner-a"), (rider1_user, "rider1"), (rider2_user, "rider2"),
            (owner_b, "owner-b"), (rider3_user, "rider3"),
        ):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"s4-06-b2-{label}-{uuid.uuid4()}@test.invalid"),
            )
        cur.execute("insert into businesses(name) values('S4-06 B2 Business A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-06 B2 Business B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values(%s,%s,'owner'),(%s,%s,'owner')",
            (business_a, owner_a, business_b, owner_b),
        )
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) values(%s,%s,'Rider 1',%s,'active') returning id",
            (business_a, rider1_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider1 = cur.fetchone()[0]
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) values(%s,%s,'Rider 2',%s,'active') returning id",
            (business_a, rider2_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider2 = cur.fetchone()[0]
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) values(%s,%s,'Rider 3',%s,'active') returning id",
            (business_b, rider3_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider3 = cur.fetchone()[0]

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claim.role',%s,true)",
                (str(user_id), role),
            )
            cur.execute(f"set local role {role}")

        def new_order(business_id, phone_suffix):
            cur.execute("select create_delivery(%s,'B2 Customer',%s,'Addr')", (business_id, f"+60195000{phone_suffix:03d}"))
            order_id = uuid.UUID(cur.fetchone()[0]["order"]["id"])
            cur.execute("select approve_order(%s)", (order_id,))
            return order_id

        def mark_pod_uploaded(rider_id, order_id):
            path = f"{rider_id}/{order_id}/test.jpg"
            cur.execute("reset role")
            cur.execute("insert into storage.objects(bucket_id, name) values ('cefflo-pod', %s)", (path,))
            return path

        # ---- Setup: one session, 3 orders assigned to rider1, 1 to rider2 (multi-rider). ----
        actor(owner_a)
        cur.execute("select create_delivery_session(%s,'B2 Run', current_date)", (business_a,))
        cur.execute("reset role")
        cur.execute("select id from delivery_sessions where business_id=%s order by created_at desc limit 1", (business_a,))
        session_a = cur.fetchone()[0]

        actor(owner_a)
        r1_orders = []
        for i in range(3):
            oid = new_order(business_a, i)
            cur.execute("select attach_order_to_session(%s,%s)", (oid, session_a))
            cur.execute("select assign_rider(%s,%s)", (oid, rider1))
            r1_orders.append(oid)
        r2_order = new_order(business_a, 9)
        cur.execute("select attach_order_to_session(%s,%s)", (r2_order, session_a))
        cur.execute("select assign_rider(%s,%s)", (r2_order, rider2))

        # ---- Cross-business/exact-Rider security: Business B's rider has no
        # assignments in Business A's session -- every run RPC must see nothing. ----
        actor(rider3_user)
        rejected(cur, "select start_pickup_run(%s,%s)", (rider3, session_a), "no assignments in this run")
        rejected(cur, "select start_run_delivery(%s,%s)", (rider3, session_a), "no assignments in this run")
        rejected(cur, "select save_run_sequence(%s,%s,%s)", (rider3, session_a, r1_orders), "invalid sequence set")

        # ---- Start Pickup prerequisites: rejected while any assignment
        # remains unsettled ('assigned', not yet accepted/declined). ----
        actor(rider1_user)
        rejected(cur, "select start_pickup_run(%s,%s)", (rider1, session_a), "unsettled assignments remain")

        # Accept all of rider1's + rider2's assignments (individual accept, matching S4-05.4).
        actor(rider1_user)
        for oid in r1_orders:
            cur.execute("select accept_assignment(%s,%s)", (rider1, oid))
        actor(rider2_user)
        cur.execute("select accept_assignment(%s,%s)", (rider2, r2_order))

        # ---- save_run_sequence: exact-set validation. ----
        actor(rider1_user)
        rejected(cur, "select save_run_sequence(%s,%s,%s)", (rider1, session_a, r1_orders[:2]), "invalid sequence set")  # missing one
        rejected(cur, "select save_run_sequence(%s,%s,%s)", (rider1, session_a, r1_orders + [r2_order]), "invalid sequence set")  # extra (foreign to this rider)
        rejected(cur, "select save_run_sequence(%s,%s,%s)", (rider1, session_a, [r1_orders[0], r1_orders[0], r1_orders[1]]), "invalid sequence set")  # duplicate

        # ---- save_run_sequence: happy path + idempotency + reorder. ----
        desired_order = [r1_orders[2], r1_orders[0], r1_orders[1]]
        cur.execute("select save_run_sequence(%s,%s,%s)", (rider1, session_a, desired_order))
        cur.execute("reset role")
        cur.execute("select order_id, sequence from delivery_stops where order_id = any(%s) order by sequence", (r1_orders,))
        rows = cur.fetchall()
        assert [r[0] for r in rows] == desired_order, "sequence must reflect the Rider-selected order"
        cur.execute(
            "select count(*) from delivery_events where event_type='run.sequence_saved' and order_id = any(%s)", (r1_orders,)
        )
        events_after_first_save = cur.fetchone()[0]
        assert events_after_first_save == 3

        actor(rider1_user)
        cur.execute("select save_run_sequence(%s,%s,%s)", (rider1, session_a, desired_order))  # identical resubmission
        cur.execute("reset role")
        cur.execute(
            "select count(*) from delivery_events where event_type='run.sequence_saved' and order_id = any(%s)", (r1_orders,)
        )
        assert cur.fetchone()[0] == events_after_first_save, "idempotent resubmission must not record new events"

        reordered = [r1_orders[1], r1_orders[2], r1_orders[0]]
        actor(rider1_user)
        cur.execute("select save_run_sequence(%s,%s,%s)", (rider1, session_a, reordered))
        cur.execute("reset role")
        cur.execute("select order_id from delivery_stops where order_id = any(%s) order by sequence", (r1_orders,))
        assert [r[0] for r in cur.fetchall()] == reordered, "genuine reorder before lock must be honored"

        # ---- Start Delivery rejected: pickups not yet confirmed. ----
        actor(rider1_user)
        rejected(cur, "select start_run_delivery(%s,%s)", (rider1, session_a), "pickup incomplete")
        cur.execute("reset role")
        cur.execute("select count(*) from delivery_events where event_type='run.delivery_started'")
        assert cur.fetchone()[0] == 0, "no run.delivery_started event may exist before Start Delivery succeeds"

        # ---- Start Pickup: succeeds once all settled; idempotent; does not
        # mark any order picked_up. ----
        actor(rider1_user)
        cur.execute("select start_pickup_run(%s,%s)", (rider1, session_a))
        cur.execute("reset role")
        cur.execute(
            "select count(*) from delivery_events where event_type='run.pickup_started' and metadata->>'delivery_session_id'=%s and actor_user_id=%s",
            (str(session_a), rider1_user),
        )
        assert cur.fetchone()[0] == 1
        cur.execute("select delivery_status from orders where id = any(%s)", (r1_orders,))
        assert all(row[0] == "created" for row in cur.fetchall()), "start_pickup_run must never mark any order picked_up"

        actor(rider1_user)
        cur.execute("select start_pickup_run(%s,%s)", (rider1, session_a))  # idempotent repeat
        cur.execute("reset role")
        cur.execute(
            "select count(*) from delivery_events where event_type='run.pickup_started' and metadata->>'delivery_session_id'=%s and actor_user_id=%s",
            (str(session_a), rider1_user),
        )
        assert cur.fetchone()[0] == 1, "duplicate Start Pickup must not record a second event"

        # ---- Pickup confirmation remains unordered: confirm out of sequence order. ----
        # reordered = [stop2(seq1), stop0(seq2), stop1(seq3)] logically, but
        # confirm pickups in yet another order entirely -- must all succeed.
        actor(rider1_user)
        pickup_confirm_order = [r1_orders[0], r1_orders[2], r1_orders[1]]
        for oid in pickup_confirm_order:
            cur.execute("select rider_transition(%s,%s,'ready_for_pickup')", (rider1, oid))
            cur.execute("select rider_transition(%s,%s,'picked_up')", (rider1, oid))
        cur.execute("reset role")
        cur.execute("select delivery_status from orders where id = any(%s)", (r1_orders,))
        assert all(row[0] == "picked_up" for row in cur.fetchall())

        # ---- Start Delivery rejected: sequence not (re-)saved after a change? It
        # was saved above, so this should now succeed -- but first prove the
        # "no valid sequence" rejection on rider2's still-unsequenced run. ----
        actor(rider2_user)
        cur.execute("select start_pickup_run(%s,%s)", (rider2, session_a))
        cur.execute("select rider_transition(%s,%s,'ready_for_pickup')", (rider2, r2_order))
        cur.execute("select rider_transition(%s,%s,'picked_up')", (rider2, r2_order))
        rejected(cur, "select start_run_delivery(%s,%s)", (rider2, session_a), "sequence not ready")

        # ---- Start Delivery: success path for rider1 (all picked up + sequenced). ----
        actor(rider1_user)
        cur.execute("select start_run_delivery(%s,%s)", (rider1, session_a))
        cur.execute("reset role")
        cur.execute("select sequence_locked_at is not null from delivery_stops where order_id = any(%s)", (r1_orders,))
        assert all(row[0] for row in cur.fetchall()), "all of rider1's eligible stops must be locked"
        cur.execute(
            "select count(*) from delivery_events where event_type='run.delivery_started' and metadata->>'delivery_session_id'=%s and actor_user_id=%s",
            (str(session_a), rider1_user),
        )
        assert cur.fetchone()[0] == 1, "exactly one run.delivery_started event for rider1's run"
        cur.execute(
            "select count(*) from delivery_events where event_type='run.sequence_locked' and order_id = any(%s)", (r1_orders,)
        )
        assert cur.fetchone()[0] == 3, "one run.sequence_locked event per locked stop"

        # ---- Idempotent Start Delivery: repeat call is a no-op, no duplicate events. ----
        actor(rider1_user)
        cur.execute("select start_run_delivery(%s,%s)", (rider1, session_a))
        cur.execute("reset role")
        cur.execute(
            "select count(*) from delivery_events where event_type='run.delivery_started' and metadata->>'delivery_session_id'=%s and actor_user_id=%s",
            (str(session_a), rider1_user),
        )
        assert cur.fetchone()[0] == 1

        # ---- Normal reorder rejected after lock. ----
        actor(rider1_user)
        rejected(cur, "select save_run_sequence(%s,%s,%s)", (rider1, session_a, reordered), "sequence locked")

        # ---- Out-of-sequence delivery denial + sequential execution. ----
        cur.execute("reset role")
        cur.execute("select order_id, sequence from delivery_stops where order_id = any(%s) order by sequence", (r1_orders,))
        ordered_stops = [row[0] for row in cur.fetchall()]
        first_stop, second_stop, third_stop = ordered_stops

        actor(rider1_user)
        rejected(cur, "select rider_transition(%s,%s,'out_for_delivery')", (rider1, second_stop), "complete earlier stop first")
        rejected(cur, "select rider_transition(%s,%s,'out_for_delivery')", (rider1, third_stop), "complete earlier stop first")

        # Complete stop 1 fully, then stop 2 becomes unblocked (stop 3 still isn't).
        cur.execute("select rider_transition(%s,%s,'out_for_delivery')", (rider1, first_stop))
        cur.execute("select rider_transition(%s,%s,'arrived')", (rider1, first_stop))
        path = mark_pod_uploaded(rider1, first_stop)
        actor(rider1_user)
        cur.execute("select complete_delivery(%s,%s,%s,'Delivered')", (rider1, first_stop, path))
        rejected(cur, "select rider_transition(%s,%s,'out_for_delivery')", (rider1, third_stop), "complete earlier stop first")
        cur.execute("select rider_transition(%s,%s,'out_for_delivery')", (rider1, second_stop))
        cur.execute("select rider_transition(%s,%s,'arrived')", (rider1, second_stop))
        path = mark_pod_uploaded(rider1, second_stop)
        actor(rider1_user)
        cur.execute("select complete_delivery(%s,%s,%s,'Delivered')", (rider1, second_stop, path))
        cur.execute("select rider_transition(%s,%s,'out_for_delivery')", (rider1, third_stop))
        cur.execute("select rider_transition(%s,%s,'arrived')", (rider1, third_stop))
        path = mark_pod_uploaded(rider1, third_stop)
        actor(rider1_user)
        cur.execute("select complete_delivery(%s,%s,%s,'Delivered')", (rider1, third_stop, path))
        cur.execute("reset role")
        cur.execute("select delivery_status from orders where id = any(%s)", (r1_orders,))
        assert all(row[0] == "delivered" for row in cur.fetchall())

        # ---- Multi-Rider independence: rider2's own run is untouched by
        # rider1's lock/sequence/delivery -- still fully separate and
        # workable, never blocked by rider1. ----
        cur.execute("select sequence_locked_at from delivery_stops where order_id=%s", (r2_order,))
        assert cur.fetchone()[0] is None, "rider2's stop must remain unlocked -- rider1's Start Delivery must not affect it"
        actor(rider2_user)
        cur.execute("select save_run_sequence(%s,%s,%s)", (rider2, session_a, [r2_order]))
        cur.execute("select start_run_delivery(%s,%s)", (rider2, session_a))
        cur.execute("select rider_transition(%s,%s,'out_for_delivery')", (rider2, r2_order))
        cur.execute("select rider_transition(%s,%s,'arrived')", (rider2, r2_order))
        path = mark_pod_uploaded(rider2, r2_order)
        actor(rider2_user)
        cur.execute("select complete_delivery(%s,%s,%s,'Delivered')", (rider2, r2_order, path))
        cur.execute("reset role")
        cur.execute("select delivery_status from orders where id=%s", (r2_order,))
        assert cur.fetchone()[0] == "delivered", "rider2's own run must complete independently of rider1's"

        # ---- Existing S4-05 gates preserved: exact-rider authorization,
        # assignment-acceptance gate untouched by this batch. ----
        actor(rider2_user)
        rejected(cur, "select rider_transition(%s,%s,'ready_for_pickup')", (rider2, r1_orders[0]), "forbidden")

        actor(owner_a)
        oid_unaccepted = new_order(business_a, 5)
        cur.execute("select assign_rider(%s,%s)", (oid_unaccepted, rider1))
        actor(rider1_user)
        rejected(cur, "select rider_transition(%s,%s,'ready_for_pickup')", (rider1, oid_unaccepted), "assignment not accepted")

        # ---- Single-order compatibility: an order never attached to any
        # session, never touched by any run RPC, still works exactly as
        # before -- sequence_locked_at stays null, no sequential gate applies. ----
        actor(owner_a)
        solo_order = new_order(business_a, 6)
        cur.execute("select assign_rider(%s,%s)", (solo_order, rider1))
        actor(rider1_user)
        cur.execute("select accept_assignment(%s,%s)", (rider1, solo_order))
        for status in ("ready_for_pickup", "picked_up", "out_for_delivery", "arrived"):
            cur.execute("select rider_transition(%s,%s,%s)", (rider1, solo_order, status))
        path = mark_pod_uploaded(rider1, solo_order)
        actor(rider1_user)
        cur.execute("select complete_delivery(%s,%s,%s,'Delivered')", (rider1, solo_order, path))
        cur.execute("reset role")
        cur.execute("select delivery_status, sequence_locked_at from orders o join delivery_stops s on s.order_id=o.id where o.id=%s", (solo_order,))
        row = cur.fetchone()
        assert row[0] == "delivered" and row[1] is None, "single-order delivery unaffected by run machinery"

        # ---- No direct-table write bypass reopened. ----
        actor(rider1_user)
        cur.execute("select id from delivery_stops where order_id=%s", (first_stop,))
        stop_id = cur.fetchone()[0]
        savepoint = "denied_direct_stop"
        cur.execute(f"savepoint {savepoint}")
        cur.execute("update delivery_stops set sequence_locked_at=null where id=%s", (stop_id,))
        assert cur.rowcount == 0, "direct UPDATE on delivery_stops must remain fully blocked"
        cur.execute(f"rollback to savepoint {savepoint}")

        conn.rollback()

print("s4_06_batch_2_run_sequence_pickup_delivery_ok")
