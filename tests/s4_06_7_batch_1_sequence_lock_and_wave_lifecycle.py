"""Rollback-only S4-06.7 Batch-1 acceptance: the Founder-approved backend
sequence-lock invariant (P2) and Wave/session auto-lifecycle (P4).

Canonical model: one Lunch Wave, Ali gets 3 orders, Abu gets 2 orders,
mirroring the Founder-approved 10+10 scenario at a smaller, test-tractable
scale. A second, wholly unrelated Dinner Wave proves independence. A
standalone (no-session) order proves single-order/legacy compatibility is
untouched.

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


owner_a, ali_user, abu_user = [uuid.uuid4() for _ in range(3)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in ((owner_a, "owner-a"), (ali_user, "ali"), (abu_user, "abu")):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"s4-06-7-b1-{label}-{uuid.uuid4()}@test.invalid"),
            )
        cur.execute("insert into businesses(name) values('S4-06.7 B1 Business') returning id")
        business_a = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values(%s,%s,'owner')",
            (business_a, owner_a),
        )
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) values(%s,%s,'Ali',%s,'active') returning id",
            (business_a, ali_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        ali = cur.fetchone()[0]
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) values(%s,%s,'Abu',%s,'active') returning id",
            (business_a, abu_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        abu = cur.fetchone()[0]

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claim.role',%s,true)",
                (str(user_id), role),
            )
            cur.execute(f"set local role {role}")

        def new_order(business_id, phone_suffix):
            cur.execute("select create_delivery(%s,'B1 Customer',%s,'Addr')", (business_id, f"+60197100{phone_suffix:03d}"))
            order_id = uuid.UUID(cur.fetchone()[0]["order"]["id"])
            cur.execute("select approve_order(%s)", (order_id,))
            return order_id

        def session_status(session_id):
            cur.execute("reset role")
            cur.execute("select status from delivery_sessions where id=%s", (session_id,))
            return cur.fetchone()[0]

        def auto_event_count(session_id, status):
            cur.execute("reset role")
            cur.execute(
                "select count(*) from delivery_events where event_type='session.status_changed' "
                "and metadata->>'delivery_session_id'=%s and metadata->>'status'=%s and metadata->>'trigger'='auto'",
                (str(session_id), status),
            )
            return cur.fetchone()[0]

        def mark_pod_uploaded(rider_id, order_id):
            path = f"{rider_id}/{order_id}/test.jpg"
            cur.execute("reset role")
            cur.execute("insert into storage.objects(bucket_id, name) values ('cefflo-pod', %s)", (path,))
            return path

        # =====================================================================
        # SETUP: Lunch Wave -- Ali gets 3 orders, Abu gets 2. Dinner Wave --
        # one unrelated order, entirely untouched throughout. One standalone
        # (no-session) order for the single-order-compatibility proof.
        # =====================================================================
        actor(owner_a)
        cur.execute("select (create_delivery_session(%s,'Lunch Wave', current_date)).id", (business_a,))
        lunch = cur.fetchone()[0]
        cur.execute("select (create_delivery_session(%s,'Dinner Wave', current_date)).id", (business_a,))
        dinner = cur.fetchone()[0]

        ali_orders = []
        for i in range(3):
            oid = new_order(business_a, i)
            cur.execute("select attach_order_to_session(%s,%s)", (oid, lunch))
            cur.execute("select assign_rider(%s,%s)", (oid, ali))
            ali_orders.append(oid)
        abu_orders = []
        for i in range(2):
            oid = new_order(business_a, 10 + i)
            cur.execute("select attach_order_to_session(%s,%s)", (oid, lunch))
            cur.execute("select assign_rider(%s,%s)", (oid, abu))
            abu_orders.append(oid)

        dinner_order = new_order(business_a, 20)
        cur.execute("select attach_order_to_session(%s,%s)", (dinner_order, dinner))
        cur.execute("select assign_rider(%s,%s)", (dinner_order, ali))

        solo_order = new_order(business_a, 30)
        cur.execute("select assign_rider(%s,%s)", (solo_order, ali))

        assert session_status(lunch) == "planned", "Lunch Wave must start planned, never pre-active"
        assert session_status(dinner) == "planned"

        # =====================================================================
        # Ali: accept, plan, save sequence.
        # =====================================================================
        actor(ali_user)
        cur.execute("select accept_run(%s,%s)", (ali, lunch))
        cur.execute("select save_run_sequence(%s,%s,%s)", (ali, lunch, ali_orders))

        # ---- P2 TEST: multi-stop, UNLOCKED -- picked_up -> out_for_delivery
        # must be rejected before start_run_delivery has ever locked this run. ----
        for oid in ali_orders:
            cur.execute("select rider_transition(%s,%s,'ready_for_pickup')", (ali, oid))
            cur.execute("select rider_transition(%s,%s,'picked_up')", (ali, oid))
        rejected(cur, "select rider_transition(%s,%s,'out_for_delivery')", (ali, ali_orders[0]), "sequence not locked")

        # ---- P4 TEST: Start Pickup is real execution beginning -- Wave flips
        # planned -> active, exactly once, with a real auto-triggered event. ----
        cur.execute("select start_pickup_run(%s,%s)", (ali, lunch))
        assert session_status(lunch) == "active", "Wave must auto-activate once real execution begins"
        assert auto_event_count(lunch, "active") == 1
        cur.execute("select start_pickup_run(%s,%s)", (ali, lunch))  # idempotent repeat
        assert auto_event_count(lunch, "active") == 1, "repeat start_pickup_run must not duplicate the auto-active event"

        # ---- P2 TEST: locked Run -- delivery-phase transitions now succeed,
        # and retrying the exact same transition is a safe idempotent no-op. ----
        cur.execute("select start_run_delivery(%s,%s)", (ali, lunch))
        cur.execute("select rider_transition(%s,%s,'out_for_delivery')", (ali, ali_orders[0]))
        cur.execute("select rider_transition(%s,%s,'out_for_delivery')", (ali, ali_orders[0]))  # retry: no-op, not re-rejected
        cur.execute("select rider_transition(%s,%s,'arrived')", (ali, ali_orders[0]))
        path = mark_pod_uploaded(ali, ali_orders[0])
        actor(ali_user)
        cur.execute("select complete_delivery(%s,%s,%s,'Delivered')", (ali, ali_orders[0], path))

        # ---- P2 TEST: exact-Rider isolation -- Abu cannot act on Ali's stop,
        # even claiming Ali's own relationship id, locked or not, session-
        # scoped or not (is_current_rider's ownership check fails for Abu's
        # identity regardless of which rider_id he names). ----
        actor(abu_user)
        rejected(cur, "select rider_transition(%s,%s,'out_for_delivery')", (ali, ali_orders[1]), "invalid rider context")
        rejected(cur, "select rider_transition(%s,%s,'out_for_delivery')", (abu, ali_orders[1]), "forbidden")

        # Ali finishes his remaining two stops in order.
        actor(ali_user)
        for oid in ali_orders[1:]:
            cur.execute("select rider_transition(%s,%s,'out_for_delivery')", (ali, oid))
            cur.execute("select rider_transition(%s,%s,'arrived')", (ali, oid))
            path = mark_pod_uploaded(ali, oid)
            actor(ali_user)
            cur.execute("select complete_delivery(%s,%s,%s,'Delivered')", (ali, oid, path))

        # =====================================================================
        # P4 TEST (Multi-Rider same-Wave): Ali has now delivered all of his
        # own Lunch Wave orders -- the Wave must NOT complete while Abu's two
        # orders remain undelivered.
        # =====================================================================
        assert session_status(lunch) == "active", "Ali finishing alone must not complete a Wave Abu still shares"
        assert auto_event_count(lunch, "completed") == 0

        # Abu independently accepts, plans, starts pickup (Wave already
        # active -- his own start_pickup_run call must stay a safe no-op on
        # the already-flipped status), and delivers his two orders.
        actor(abu_user)
        cur.execute("select accept_run(%s,%s)", (abu, lunch))
        cur.execute("select save_run_sequence(%s,%s,%s)", (abu, lunch, abu_orders))
        cur.execute("select start_pickup_run(%s,%s)", (abu, lunch))
        assert auto_event_count(lunch, "active") == 1, "Abu's own start_pickup_run must not re-fire the active event"
        for oid in abu_orders:
            cur.execute("select rider_transition(%s,%s,'ready_for_pickup')", (abu, oid))
            cur.execute("select rider_transition(%s,%s,'picked_up')", (abu, oid))
        cur.execute("select start_run_delivery(%s,%s)", (abu, lunch))
        cur.execute("select rider_transition(%s,%s,'out_for_delivery')", (abu, abu_orders[0]))
        cur.execute("select rider_transition(%s,%s,'arrived')", (abu, abu_orders[0]))
        path = mark_pod_uploaded(abu, abu_orders[0])
        actor(abu_user)
        cur.execute("select complete_delivery(%s,%s,%s,'Delivered')", (abu, abu_orders[0], path))
        assert session_status(lunch) == "active", "Wave must stay open until every relevant order is delivered"

        # ---- P4 TEST: the FINAL relevant order's completion closes the
        # Wave exactly once. ----
        cur.execute("select rider_transition(%s,%s,'out_for_delivery')", (abu, abu_orders[1]))
        cur.execute("select rider_transition(%s,%s,'arrived')", (abu, abu_orders[1]))
        path = mark_pod_uploaded(abu, abu_orders[1])
        actor(abu_user)
        cur.execute("select complete_delivery(%s,%s,%s,'Delivered')", (abu, abu_orders[1], path))
        assert session_status(lunch) == "completed", "Wave must complete once every relevant order is genuinely delivered"
        assert auto_event_count(lunch, "completed") == 1, "completion event must be recorded exactly once"

        # =====================================================================
        # P4 TEST (multiple Waves independent): Dinner Wave was never touched
        # by any of Lunch Wave's activity above.
        # =====================================================================
        assert session_status(dinner) == "planned", "an unrelated same-day Wave must be entirely unaffected"

        # =====================================================================
        # P2 TEST (single-order/legacy compatibility): a standalone order,
        # never attached to any session, is entirely unaffected by the new
        # lock gate -- the full lifecycle succeeds without ever calling
        # start_pickup_run/start_run_delivery.
        # =====================================================================
        actor(ali_user)
        cur.execute("select accept_assignment(%s,%s)", (ali, solo_order))
        for status in ("ready_for_pickup", "picked_up", "out_for_delivery", "arrived"):
            cur.execute("select rider_transition(%s,%s,%s)", (ali, solo_order, status))
        path = mark_pod_uploaded(ali, solo_order)
        actor(ali_user)
        cur.execute("select complete_delivery(%s,%s,%s,'Delivered')", (ali, solo_order, path))
        cur.execute("reset role")
        cur.execute(
            "select delivery_status, sequence_locked_at from orders o join delivery_stops s on s.order_id=o.id where o.id=%s",
            (solo_order,),
        )
        row = cur.fetchone()
        assert row[0] == "delivered" and row[1] is None, "standalone order must stay entirely unaffected by the P2 lock gate"

        conn.rollback()

print("s4_06_7_batch_1_sequence_lock_and_wave_lifecycle_ok")
