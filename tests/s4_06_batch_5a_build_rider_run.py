"""Rollback-only S4-06 Batch-5a build_rider_run acceptance (all-or-nothing
orchestration RPC + key/payload idempotency). True cross-connection
concurrency lives in s4_06_batch_5a_build_rider_run_concurrency.py."""

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


owner_a, owner_b, rider1_user, rider2_user = [uuid.uuid4() for _ in range(4)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in (
            (owner_a, "owner-a"), (owner_b, "owner-b"),
            (rider1_user, "rider1"), (rider2_user, "rider2"),
        ):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"s4-06-b5a-{label}-{uuid.uuid4()}@test.invalid"),
            )
        cur.execute("insert into businesses(name) values('S4-06 B5a Business A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-06 B5a Business B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values(%s,%s,'owner'),(%s,%s,'owner')",
            (business_a, owner_a, business_b, owner_b),
        )
        # capacity_override=100 (S4-11 Batch 3, Grow V1 Flow 2): this test
        # accumulates many separate build_rider_run calls onto the same two
        # riders across its full run (all-or-nothing, idempotency, multi-
        # rider mechanics), not the separate vehicle/capacity eligibility
        # feature -- default motorcycle capacity (6) would otherwise cap
        # what the later scenarios in this file can construct.
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status,capacity_override) values(%s,%s,'Ali',%s,'active',100) returning id",
            (business_a, rider1_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        ali = cur.fetchone()[0]
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status,capacity_override) values(%s,%s,'Abu',%s,'active',100) returning id",
            (business_a, rider2_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        abu = cur.fetchone()[0]
        cur.execute(
            "insert into riders(business_id,name,phone,status) values(%s,'Inactive Rider',%s,'inactive') returning id",
            (business_a, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        inactive_rider = cur.fetchone()[0]
        cur.execute(
            "insert into riders(business_id,name,phone,status) values(%s,'Cross Biz Rider',%s,'active') returning id",
            (business_b, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        cross_biz_rider = cur.fetchone()[0]

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claim.role',%s,true)",
                (str(user_id), role),
            )
            cur.execute(f"set local role {role}")

        def new_order(business_id, phone_suffix, zone_id=None):
            if zone_id is not None:
                cur.execute(
                    "select create_delivery(%s,'B5a Customer',%s,'Addr',p_zone_id=>%s)",
                    (business_id, f"+60196{phone_suffix:06d}", zone_id),
                )
            else:
                cur.execute(
                    "select create_delivery(%s,'B5a Customer',%s,'Addr')",
                    (business_id, f"+60196{phone_suffix:06d}"),
                )
            order_id = uuid.UUID(cur.fetchone()[0]["order"]["id"])
            cur.execute("select approve_order(%s)", (order_id,))
            return order_id

        def new_session(business_id, name):
            cur.execute("select (create_delivery_session(%s,%s, current_date)).id", (business_id, name))
            return cur.fetchone()[0]

        def event_counts(order_ids):
            cur.execute("reset role")
            cur.execute(
                "select event_type, count(*) from delivery_events where order_id = any(%s) "
                "and event_type in ('session.order_attached','rider.assigned') group by 1",
                (order_ids,),
            )
            return dict(cur.fetchall())

        # =====================================================================
        # HAPPY PATH
        # =====================================================================
        actor(owner_a)
        session_1 = new_session(business_a, "Lunch Wave")
        orders_1 = [new_order(business_a, i) for i in range(6)]
        key_1 = uuid.uuid4()

        cur.execute("select build_rider_run(%s,%s,%s,%s)", (session_1, ali, orders_1, key_1))
        result = cur.fetchone()[0]
        assert result == {
            "delivery_session_id": str(session_1),
            "rider_id": str(ali),
            "order_count": 6,
            # S4-11 Batch 3 (Grow V1 Flow 2): vehicle/capacity eligibility is
            # a distinct exception class from this test's original scope --
            # every successful build_rider_run result now also reports
            # whether a vehicle/capacity override was used to get there.
            # This run is well within Ali's default motorcycle capacity (6)
            # and fully vehicle-compatible (orders default to 'any'), so no
            # override was needed.
            "vehicle_capacity_override_used": False,
        }

        counts = event_counts(orders_1)
        assert counts.get("session.order_attached") == 6
        assert counts.get("rider.assigned") == 6

        cur.execute(
            "select count(*) from delivery_events where event_type='run.built' "
            "and (metadata->>'idempotency_key')::uuid = %s",
            (key_1,),
        )
        assert cur.fetchone()[0] == 1

        cur.execute(
            "select metadata from delivery_events where event_type='run.built' "
            "and (metadata->>'idempotency_key')::uuid = %s",
            (key_1,),
        )
        run_built_meta = cur.fetchone()[0]
        stored_order_ids = sorted(uuid.UUID(x) for x in run_built_meta["order_ids"])
        assert stored_order_ids == sorted(orders_1)
        assert run_built_meta["delivery_session_id"] == str(session_1)
        assert run_built_meta["rider_id"] == str(ali)

        cur.execute(
            "select assigned_rider_id, delivery_session_id, delivery_status from orders where id = any(%s)",
            (orders_1,),
        )
        for assigned_rider_id, delivery_session_id, delivery_status in cur.fetchall():
            assert assigned_rider_id == ali
            assert delivery_session_id == session_1
            assert delivery_status == "created"

        # =====================================================================
        # IDEMPOTENCY: exact retry, same key + same payload
        # =====================================================================
        actor(owner_a)
        cur.execute("select build_rider_run(%s,%s,%s,%s)", (session_1, ali, orders_1, key_1))
        retry_result = cur.fetchone()[0]
        assert retry_result == result

        counts_after_retry = event_counts(orders_1)
        assert counts_after_retry == counts, "retry must not add any new per-order events"
        cur.execute(
            "select count(*) from delivery_events where event_type='run.built' "
            "and (metadata->>'idempotency_key')::uuid = %s",
            (key_1,),
        )
        assert cur.fetchone()[0] == 1, "retry must not add a second run.built event"

        # Retry with order_ids submitted in a different order -- must still
        # match via canonical (sorted) normalization.
        actor(owner_a)
        shuffled = list(reversed(orders_1))
        cur.execute("select build_rider_run(%s,%s,%s,%s)", (session_1, ali, shuffled, key_1))
        assert cur.fetchone()[0] == result

        # =====================================================================
        # IDEMPOTENCY: same key, changed payload -> conflict, zero mutation
        # =====================================================================
        actor(owner_a)
        session_2 = new_session(business_a, "Afternoon Wave")
        fresh_pool = [new_order(business_a, 10 + i) for i in range(8)]

        rejected(
            cur, "select build_rider_run(%s,%s,%s,%s)",
            (session_1, ali, fresh_pool[0:6], key_1), "idempotency key conflict",
        )
        rejected(
            cur, "select build_rider_run(%s,%s,%s,%s)",
            (session_1, abu, orders_1, key_1), "idempotency key conflict",
        )
        rejected(
            cur, "select build_rider_run(%s,%s,%s,%s)",
            (session_2, ali, orders_1, key_1), "idempotency key conflict",
        )
        cur.execute(
            "select count(*) from delivery_events where event_type='run.built' "
            "and (metadata->>'idempotency_key')::uuid = %s",
            (key_1,),
        )
        assert cur.fetchone()[0] == 1, "conflicting reuse must not create a second run.built"

        # =====================================================================
        # IDEMPOTENCY: new key against an already-assigned set -- NOT a
        # retry; must go through normal eligibility and be rejected.
        # =====================================================================
        actor(owner_a)
        key_new = uuid.uuid4()
        rejected(
            cur, "select build_rider_run(%s,%s,%s,%s)",
            (session_1, abu, orders_1, key_new), "orders no longer eligible",
        )

        # =====================================================================
        # VALIDATION: required key, duplicates, empty input
        # =====================================================================
        actor(owner_a)
        rejected(cur, "select build_rider_run(%s,%s,%s,%s)", (session_2, ali, fresh_pool[0:2], None), "idempotency key required")
        rejected(cur, "select build_rider_run(%s,%s,%s,%s)", (session_2, ali, [fresh_pool[0], fresh_pool[0]], uuid.uuid4()), "duplicate order ids")
        rejected(cur, "select build_rider_run(%s,%s,%s,%s)", (session_2, ali, [], uuid.uuid4()), "no orders selected")
        rejected(cur, "select build_rider_run(%s,%s,%s,%s)", (session_2, ali, None, uuid.uuid4()), "no orders selected")

        # =====================================================================
        # VALIDATION: nonexistent order, cross-business order
        # =====================================================================
        actor(owner_a)
        rejected(
            cur, "select build_rider_run(%s,%s,%s,%s)",
            (session_2, ali, [uuid.uuid4()] + fresh_pool[0:2], uuid.uuid4()), "orders no longer eligible",
        )
        actor(owner_b)
        cross_biz_order = new_order(business_b, 900)
        actor(owner_a)
        rejected(
            cur, "select build_rider_run(%s,%s,%s,%s)",
            (session_2, ali, [cross_biz_order] + fresh_pool[0:2], uuid.uuid4()), "orders no longer eligible",
        )

        # =====================================================================
        # VALIDATION: unauthorized business (caller not a member of the
        # session's business), completed/cancelled session, bad Rider
        # =====================================================================
        actor(owner_b)
        rejected(cur, "select build_rider_run(%s,%s,%s,%s)", (session_2, ali, fresh_pool[0:2], uuid.uuid4()), "forbidden")

        actor(owner_a)
        cur.execute("select update_session_status(%s,'completed')", (session_2,))
        rejected(cur, "select build_rider_run(%s,%s,%s,%s)", (session_2, ali, fresh_pool[0:2], uuid.uuid4()), "session not open")

        session_3 = new_session(business_a, "Dinner Wave")
        cur.execute("select update_session_status(%s,'cancelled')", (session_3,))
        rejected(cur, "select build_rider_run(%s,%s,%s,%s)", (session_3, ali, fresh_pool[0:2], uuid.uuid4()), "session not open")

        session_4 = new_session(business_a, "Late Wave")
        rejected(cur, "select build_rider_run(%s,%s,%s,%s)", (session_4, inactive_rider, fresh_pool[0:2], uuid.uuid4()), "invalid rider")
        rejected(cur, "select build_rider_run(%s,%s,%s,%s)", (session_4, cross_biz_rider, fresh_pool[0:2], uuid.uuid4()), "invalid rider")

        # =====================================================================
        # ALL-OR-NOTHING: one ineligible order in a set of 10 -> zero mutation
        # =====================================================================
        actor(owner_a)
        session_5 = new_session(business_a, "All-Or-Nothing Wave")
        ten_orders = [new_order(business_a, 100 + i) for i in range(10)]
        # Make the 7th order (index 6) ineligible by pre-assigning it elsewhere.
        cur.execute("select assign_rider(%s,%s)", (ten_orders[6], abu))

        rejected(
            cur, "select build_rider_run(%s,%s,%s,%s)",
            (session_5, ali, ten_orders, uuid.uuid4()), "orders no longer eligible",
        )
        cur.execute(
            "select assigned_rider_id, delivery_session_id from orders where id = any(%s)",
            (ten_orders,),
        )
        rows = cur.fetchall()
        for assigned_rider_id, delivery_session_id in rows:
            assert delivery_session_id != session_5, "zero mutation required -- no order may be attached to the failed Wave"
        assert sum(1 for assigned_rider_id, _ in rows if assigned_rider_id == abu) == 1
        assert sum(1 for assigned_rider_id, _ in rows if assigned_rider_id == ali) == 0
        cur.execute(
            "select count(*) from delivery_events where event_type='run.built' and delivery_stop_id is null "
            "and metadata->>'delivery_session_id' = %s",
            (str(session_5),),
        )
        assert cur.fetchone()[0] == 0, "a failed all-or-nothing attempt must never emit run.built"

        # =====================================================================
        # MULTI-RIDER SAME-WAVE: Ali and Abu both built into session_5's
        # sibling wave via two separate build_rider_run calls.
        # =====================================================================
        actor(owner_a)
        session_6 = new_session(business_a, "Multi-Rider Wave")
        ali_orders = [new_order(business_a, 200 + i) for i in range(4)]
        abu_orders = [new_order(business_a, 210 + i) for i in range(3)]
        cur.execute("select build_rider_run(%s,%s,%s,%s)", (session_6, ali, ali_orders, uuid.uuid4()))
        cur.execute("select build_rider_run(%s,%s,%s,%s)", (session_6, abu, abu_orders, uuid.uuid4()))
        cur.execute(
            "select assigned_rider_id from orders where id = any(%s)", (ali_orders,),
        )
        assert all(row[0] == ali for row in cur.fetchall())
        cur.execute(
            "select assigned_rider_id from orders where id = any(%s)", (abu_orders,),
        )
        assert all(row[0] == abu for row in cur.fetchall())

        # =====================================================================
        # S4-06.4 INTEROP: accept_run/decline_run work on build_rider_run
        # created assignments exactly as on the 2N path.
        # =====================================================================
        actor(rider1_user)
        cur.execute("select accept_run(%s,%s)", (ali, session_6))
        accept_report = cur.fetchone()[0]
        assert accept_report["newly_accepted"] == len(ali_orders)
        cur.execute("reset role")
        cur.execute(
            "select a.status from rider_assignments a join delivery_stops s on s.assignment_id=a.id where s.order_id = any(%s)",
            (ali_orders,),
        )
        assert all(row[0] == "accepted" for row in cur.fetchall())

        actor(rider2_user)
        cur.execute("select decline_run(%s,%s)", (abu, session_6))
        decline_report = cur.fetchone()[0]
        assert decline_report["newly_declined"] == len(abu_orders)

        # =====================================================================
        # S4-06.2 INTEROP: save_run_sequence / start_pickup_run /
        # start_run_delivery work on build_rider_run created assignments.
        # =====================================================================
        actor(rider1_user)
        cur.execute("select save_run_sequence(%s,%s,%s)", (ali, session_6, ali_orders))
        cur.execute("select start_pickup_run(%s,%s)", (ali, session_6))
        for oid in ali_orders:
            cur.execute("select rider_transition(%s,%s,'ready_for_pickup')", (ali, oid))
            cur.execute("select rider_transition(%s,%s,'picked_up')", (ali, oid))
        cur.execute("select start_run_delivery(%s,%s)", (ali, session_6))
        cur.execute("reset role")
        cur.execute("select sequence_locked_at is not null from delivery_stops where order_id = any(%s)", (ali_orders,))
        assert all(row[0] for row in cur.fetchall())

        # =====================================================================
        # S4-06.3 ZONE REGRESSION: build_rider_run works identically for
        # zoned and unzoned orders; zone_id is left untouched.
        # =====================================================================
        actor(owner_a)
        cur.execute("select (create_zone(%s,'B5a Zone')).id", (business_a,))
        zone = cur.fetchone()[0]
        session_7 = new_session(business_a, "Zone Wave")
        zoned_order = new_order(business_a, 300, zone_id=zone)
        unzoned_order = new_order(business_a, 301)
        cur.execute("select build_rider_run(%s,%s,%s,%s)", (session_7, ali, [zoned_order, unzoned_order], uuid.uuid4()))
        cur.execute("select zone_id from orders where id=%s", (zoned_order,))
        assert cur.fetchone()[0] == zone
        cur.execute("select zone_id from orders where id=%s", (unzoned_order,))
        assert cur.fetchone()[0] is None

        # =====================================================================
        # REGRESSION SPOT-CHECK: direct-write blocking still enforced.
        # =====================================================================
        actor(rider1_user)
        savepoint = "denied_direct_write"
        cur.execute(f"savepoint {savepoint}")
        cur.execute("update orders set assigned_rider_id=%s where id=%s", (rider2_user, ali_orders[0]))
        assert cur.rowcount == 0, "direct UPDATE on orders must remain fully blocked"
        cur.execute(f"rollback to savepoint {savepoint}")

        conn.rollback()

print("s4_06_batch_5a_build_rider_run_ok")
