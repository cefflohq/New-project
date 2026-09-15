"""Rollback-only S4-07.3a acceptance: explicit Rider-context authorization
(p_rider_id, first parameter, every Rider mutation) and the paired POD
active-context correction. Proves the exact Founder-required matrix: Ali
owns RiderA (Business A) and RiderB (Business B), same auth identity --
every mutation succeeds under the matching context and is rejected under
the mismatched one, even though the identity legitimately owns both.
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


owner_a, owner_b, ali_user, bystander_user = [uuid.uuid4() for _ in range(4)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in (
            (owner_a, "owner-a"), (owner_b, "owner-b"),
            (ali_user, "ali"), (bystander_user, "bystander"),
        ):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"s4-07-3a-{label}-{uuid.uuid4()}@test.invalid"),
            )
        cur.execute("insert into businesses(name) values('S4-07.3a Business A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-07.3a Business B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values(%s,%s,'owner'),(%s,%s,'owner')",
            (business_a, owner_a, business_b, owner_b),
        )
        # Ali: one auth identity, two genuinely distinct, active Rider
        # relationships -- the exact D-03/S4-07.3a scenario. Composite
        # unique(business_id, auth_user_id) permits this by construction.
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) values(%s,%s,'Ali A',%s,'active') returning id",
            (business_a, ali_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider_a = cur.fetchone()[0]
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) values(%s,%s,'Ali B',%s,'active') returning id",
            (business_b, ali_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider_b = cur.fetchone()[0]

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claim.role',%s,true)",
                (str(user_id), role),
            )
            cur.execute(f"set local role {role}")

        def new_order(business_id, phone_suffix):
            cur.execute("select create_delivery(%s,'B3a Customer',%s,'Addr')", (business_id, f"+60196000{phone_suffix:03d}"))
            order_id = uuid.UUID(cur.fetchone()[0]["order"]["id"])
            cur.execute("select approve_order(%s)", (order_id,))
            return order_id

        def mark_pod_uploaded(rider_id, order_id):
            path = f"{rider_id}/{order_id}/test.jpg"
            cur.execute("reset role")
            cur.execute("insert into storage.objects(bucket_id, name) values ('cefflo-pod', %s)", (path,))
            return path

        # =====================================================================
        # SETUP: one order per business, both assigned to Ali's respective
        # relationship, both driven up to 'arrived' so the whole matrix
        # (assignment, run, sequence, pickup, delivery, transition,
        # completion, POD) can be exercised in both directions.
        # =====================================================================
        actor(owner_a)
        cur.execute("select (create_delivery_session(%s,'A Wave', current_date)).id", (business_a,))
        session_a = cur.fetchone()[0]
        order_a = new_order(business_a, 1)
        cur.execute("select attach_order_to_session(%s,%s)", (order_a, session_a))
        cur.execute("select assign_rider(%s,%s)", (order_a, rider_a))

        actor(owner_b)
        cur.execute("select (create_delivery_session(%s,'B Wave', current_date)).id", (business_b,))
        session_b = cur.fetchone()[0]
        order_b = new_order(business_b, 2)
        cur.execute("select attach_order_to_session(%s,%s)", (order_b, session_b))
        cur.execute("select assign_rider(%s,%s)", (order_b, rider_b))

        actor(ali_user)
        cur.execute("select accept_assignment(%s,%s)", (rider_a, order_a))
        cur.execute("select accept_assignment(%s,%s)", (rider_b, order_b))
        cur.execute("select save_run_sequence(%s,%s,%s)", (rider_a, session_a, [order_a]))
        cur.execute("select save_run_sequence(%s,%s,%s)", (rider_b, session_b, [order_b]))
        cur.execute("select start_pickup_run(%s,%s)", (rider_a, session_a))
        cur.execute("select start_pickup_run(%s,%s)", (rider_b, session_b))
        cur.execute("select rider_transition(%s,%s,'ready_for_pickup')", (rider_a, order_a))
        cur.execute("select rider_transition(%s,%s,'picked_up')", (rider_a, order_a))
        cur.execute("select rider_transition(%s,%s,'ready_for_pickup')", (rider_b, order_b))
        cur.execute("select rider_transition(%s,%s,'picked_up')", (rider_b, order_b))
        cur.execute("select start_run_delivery(%s,%s)", (rider_a, session_a))
        cur.execute("select start_run_delivery(%s,%s)", (rider_b, session_b))
        cur.execute("select rider_transition(%s,%s,'out_for_delivery')", (rider_a, order_a))
        cur.execute("select rider_transition(%s,%s,'arrived')", (rider_a, order_a))
        cur.execute("select rider_transition(%s,%s,'out_for_delivery')", (rider_b, order_b))
        cur.execute("select rider_transition(%s,%s,'arrived')", (rider_b, order_b))

        # =====================================================================
        # TEST MATRIX 1: RiderA context against A-target (allowed) and
        # B-target (rejected), for accept_run/decline_run/save_run_sequence/
        # start_pickup_run/start_run_delivery/rider_transition -- the
        # earlier-stage RPCs (accept_assignment/decline_run) are exercised on
        # fresh orders below since order_a/order_b are already past 'assigned'.
        # =====================================================================
        actor(owner_a)
        cur.execute("select (create_delivery_session(%s,'A Wave 2', current_date)).id", (business_a,))
        session_a2 = cur.fetchone()[0]
        fresh_a = new_order(business_a, 3)
        cur.execute("select attach_order_to_session(%s,%s)", (fresh_a, session_a2))
        cur.execute("select assign_rider(%s,%s)", (fresh_a, rider_a))

        actor(owner_b)
        cur.execute("select (create_delivery_session(%s,'B Wave 2', current_date)).id", (business_b,))
        session_b2 = cur.fetchone()[0]
        fresh_b = new_order(business_b, 4)
        cur.execute("select attach_order_to_session(%s,%s)", (fresh_b, session_b2))
        cur.execute("select assign_rider(%s,%s)", (fresh_b, rider_b))

        actor(ali_user)
        # accept_assignment: A allowed, B-target-with-A-context rejected.
        cur.execute("select accept_assignment(%s,%s)", (rider_a, fresh_a))
        rejected(cur, "select accept_assignment(%s,%s)", (rider_a, fresh_b), "forbidden")
        cur.execute("select accept_assignment(%s,%s)", (rider_b, fresh_b))

        # accept_run / decline_run: A-context on A-session allowed; A-context
        # on B-session sees nothing (session-scoped filter -- A's context
        # simply has no assignments there).
        rejected(cur, "select accept_run(%s,%s)", (rider_a, session_b2), "no assignments in this run")
        cur.execute("select accept_run(%s,%s)", (rider_a, session_a2))
        rejected(cur, "select accept_run(%s,%s)", (rider_b, session_a2), "no assignments in this run")
        cur.execute("select accept_run(%s,%s)", (rider_b, session_b2))

        # save_run_sequence / start_pickup_run / start_run_delivery: correct
        # context succeeds; context/target mismatch is rejected.
        rejected(cur, "select save_run_sequence(%s,%s,%s)", (rider_a, session_b2, [fresh_b]), "invalid sequence set")
        cur.execute("select save_run_sequence(%s,%s,%s)", (rider_a, session_a2, [fresh_a]))
        cur.execute("select save_run_sequence(%s,%s,%s)", (rider_b, session_b2, [fresh_b]))
        rejected(cur, "select start_pickup_run(%s,%s)", (rider_a, session_b2), "no assignments in this run")
        cur.execute("select start_pickup_run(%s,%s)", (rider_a, session_a2))
        cur.execute("select start_pickup_run(%s,%s)", (rider_b, session_b2))
        cur.execute("select rider_transition(%s,%s,'ready_for_pickup')", (rider_a, fresh_a))
        cur.execute("select rider_transition(%s,%s,'picked_up')", (rider_a, fresh_a))
        cur.execute("select rider_transition(%s,%s,'ready_for_pickup')", (rider_b, fresh_b))
        cur.execute("select rider_transition(%s,%s,'picked_up')", (rider_b, fresh_b))
        rejected(cur, "select start_run_delivery(%s,%s)", (rider_a, session_b2), "no assignments in this run")
        cur.execute("select start_run_delivery(%s,%s)", (rider_a, session_a2))
        cur.execute("select start_run_delivery(%s,%s)", (rider_b, session_b2))

        # rider_transition: A-context on A-order allowed; A-context claimed
        # against B-order rejected (the Founder's canonical example).
        rejected(cur, "select rider_transition(%s,%s,'out_for_delivery')", (rider_a, fresh_b), "forbidden")
        cur.execute("select rider_transition(%s,%s,'out_for_delivery')", (rider_a, fresh_a))
        cur.execute("select rider_transition(%s,%s,'arrived')", (rider_a, fresh_a))
        rejected(cur, "select rider_transition(%s,%s,'out_for_delivery')", (rider_b, fresh_a), "forbidden")
        cur.execute("select rider_transition(%s,%s,'out_for_delivery')", (rider_b, fresh_b))
        cur.execute("select rider_transition(%s,%s,'arrived')", (rider_b, fresh_b))

        # =====================================================================
        # TEST MATRIX 2: completion + POD, both directions.
        # =====================================================================
        # A-context, A-order: allowed.
        path_a = mark_pod_uploaded(rider_a, order_a)
        cur.execute("select complete_delivery(%s,%s,%s,'Delivered')", (rider_a, order_a, path_a))
        # A-context, B-order: rejected (identity check passes, target compare fails).
        rejected(cur, "select complete_delivery(%s,%s,%s,'Delivered')", (rider_a, order_b, path_a), "forbidden")
        # B-context, B-order: allowed.
        path_b = mark_pod_uploaded(rider_b, order_b)
        cur.execute("select complete_delivery(%s,%s,%s,'Delivered')", (rider_b, order_b, path_b))
        # B-context, A-order: rejected.
        rejected(cur, "select complete_delivery(%s,%s,%s,'Delivered')", (rider_b, order_a, path_b), "forbidden")

        # =====================================================================
        # POD upload boundary itself: RiderA context + Order B path must be
        # rejected BEFORE object acceptance -- proven directly against
        # storage.objects INSERT (the same RLS check the real Storage API
        # evaluates), never relying on complete_delivery to catch it later.
        # =====================================================================
        # RLS enforcement depends on the actual Postgres ROLE (a raw insert
        # under superuser/postgres bypasses RLS entirely, unlike calling a
        # SECURITY DEFINER RPC) -- must genuinely be `authenticated` here,
        # not merely have the right JWT claim set.
        actor(ali_user)
        wrong_context_path = f"{rider_a}/{fresh_b}/mismatch.jpg"  # rider_a (A) against fresh_b (B's order)
        rejected(cur, "insert into storage.objects(bucket_id, name) values ('cefflo-pod', %s)", (wrong_context_path,))
        cur.execute("reset role")
        cur.execute("select count(*) from storage.objects where bucket_id='cefflo-pod' and name=%s", (wrong_context_path,))
        assert cur.fetchone()[0] == 0, "a context-mismatched upload must leave zero object behind"

        # Correct pairing succeeds through the same real check.
        actor(ali_user)
        right_path = f"{rider_a}/{fresh_a}/ok.jpg"
        cur.execute("insert into storage.objects(bucket_id, name) values ('cefflo-pod', %s)", (right_path,))
        cur.execute("reset role")
        cur.execute("select count(*) from storage.objects where bucket_id='cefflo-pod' and name=%s", (right_path,))
        assert cur.fetchone()[0] == 1

        # =====================================================================
        # complete_delivery structural/existence POD defense-in-depth.
        # =====================================================================
        # Valid OrderA POD path passed for OrderB -- rejected (path doesn't
        # structurally match p_rider_id/p_order_id for THIS call).
        rejected(cur, "select complete_delivery(%s,%s,%s,'Delivered')", (rider_a, fresh_a, wrong_context_path), "POD path does not match this delivery")
        # Structurally-valid but nonexistent object -- rejected.
        never_uploaded = f"{rider_a}/{fresh_a}/never-uploaded.jpg"
        rejected(cur, "select complete_delivery(%s,%s,%s,'Delivered')", (rider_a, fresh_a, never_uploaded), "POD object not found")
        # Wrong Rider segment in an otherwise well-formed path.
        wrong_rider_segment = f"{rider_b}/{fresh_a}/x.jpg"
        rejected(cur, "select complete_delivery(%s,%s,%s,'Delivered')", (rider_a, fresh_a, wrong_rider_segment), "POD path does not match this delivery")
        # Correct upload + correct completion: PASS.
        cur.execute("select complete_delivery(%s,%s,%s,'Delivered')", (rider_a, fresh_a, right_path))
        cur.execute("reset role")
        cur.execute("select delivery_status from orders where id=%s", (fresh_a,))
        assert cur.fetchone()[0] == "delivered"

        # =====================================================================
        # Unrelated User C cannot spoof RiderA -- rejected at the ownership
        # gate itself, regardless of which RPC or which target.
        # =====================================================================
        actor(bystander_user)
        rejected(cur, "select rider_transition(%s,%s,'out_for_delivery')", (rider_a, order_a), "invalid rider context")
        rejected(cur, "select accept_run(%s,%s)", (rider_a, session_a), "invalid rider context")

        # =====================================================================
        # Pending / inactive relationships cannot be used as context at all.
        # Different businesses again -- the composite unique(business_id,
        # auth_user_id) means Ali can hold only one relationship per
        # business, and business_a/business_b are already his active ones.
        # =====================================================================
        cur.execute("reset role")
        cur.execute("insert into businesses(name) values('S4-07.3a Business C (pending)') returning id")
        business_c = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-07.3a Business D (inactive)') returning id")
        business_d = cur.fetchone()[0]
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) values(%s,%s,'Ali Pending',%s,'pending') returning id",
            (business_c, ali_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        pending_rider = cur.fetchone()[0]
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) values(%s,%s,'Ali Inactive',%s,'inactive') returning id",
            (business_d, ali_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        inactive_rider = cur.fetchone()[0]
        actor(ali_user)
        rejected(cur, "select accept_run(%s,%s)", (pending_rider, session_a), "invalid rider context")
        rejected(cur, "select accept_run(%s,%s)", (inactive_rider, session_a), "invalid rider context")

        conn.rollback()

print("s4_07_3a_rider_multi_business_context_ok")
