"""Rollback-only S4-04 Batch-3 tracking-token lifecycle acceptance."""

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


owner_a, operator_a, owner_b, rider_user, outsider = [uuid.uuid4() for _ in range(5)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in (
            (owner_a, "owner-a"),
            (operator_a, "operator-a"),
            (owner_b, "owner-b"),
            (rider_user, "rider-a"),
            (outsider, "outsider"),
        ):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"s4-04-b3-{label}-{uuid.uuid4()}@test.invalid"),
            )

        cur.execute("insert into businesses(name) values('S4-04 B3 Business A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-04 B3 Business B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values"
            "(%s,%s,'owner'),(%s,%s,'operator'),(%s,%s,'owner')",
            (business_a, owner_a, business_a, operator_a, business_b, owner_b),
        )
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) "
            "values(%s,%s,'B3 Rider A',%s,'active') returning id",
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
            else:
                raise AssertionError(f"unsupported actor role: {role}")

        # ---- Active (undelivered) order: no arbitrary creation-time expiry. ----
        actor(owner_a)
        cur.execute("select create_delivery(%s,'B3 Customer','+60120000000','Addr')", (business_a,))
        created = cur.fetchone()[0]
        order_id, original_token = created["order"]["id"], created["tracking_token"]
        cur.execute("select approve_order(%s)", (order_id,))
        cur.execute("select assign_rider(%s,%s)", (order_id, rider_a))

        # tracking_tokens has zero SELECT policies by design (deny-by-default,
        # RPC-only) -- ground-truth checks here run as the unrestricted
        # harness connection, not as any simulated application actor.
        cur.execute("reset role")
        cur.execute("select expires_at, revoked_at from tracking_tokens where order_id=%s", (order_id,))
        expires_at, revoked_at = cur.fetchone()
        assert expires_at is None, "active delivery must not carry a creation-time expiry"
        assert revoked_at is None

        actor(outsider, "anon")
        cur.execute("select public_tracking(%s)", (original_token,))
        assert cur.fetchone()[0] is not None, "active order tracking must remain usable indefinitely"

        # ---- Cross-business / authorization boundary for revoke and rotate. ----
        actor(owner_b)
        rejected(cur, "select revoke_tracking_token(%s)", (order_id,), "forbidden")
        rejected(cur, "select rotate_tracking_token(%s)", (order_id,), "forbidden")

        actor(rider_user)
        rejected(cur, "select revoke_tracking_token(%s)", (order_id,), "forbidden")
        rejected(cur, "select rotate_tracking_token(%s)", (order_id,), "forbidden")

        # anon has no grant at all on these functions (denied before the function
        # body even runs), distinct from the in-function "forbidden" raised for
        # an authenticated caller from the wrong business -- two independent
        # layers, both verified here.
        actor(outsider, "anon")
        rejected(cur, "select revoke_tracking_token(%s)", (order_id,), "permission denied")
        rejected(cur, "select rotate_tracking_token(%s)", (order_id,), "permission denied")

        # ---- Operator/Staff may rotate an active-order token (positive, both roles allowed). ----
        actor(operator_a)
        cur.execute("select rotate_tracking_token(%s)", (order_id,))
        rotated_active_token = cur.fetchone()[0]
        assert rotated_active_token != original_token
        assert len(rotated_active_token) == 64  # 32 bytes hex-encoded

        cur.execute("reset role")
        cur.execute("select expires_at, revoked_at from tracking_tokens where order_id=%s", (order_id,))
        expires_at, revoked_at = cur.fetchone()
        assert expires_at is None, "rotating an active order's token must keep the active-lifecycle policy (no expiry)"
        assert revoked_at is None

        # Old token immediately dead; new token immediately usable.
        actor(outsider, "anon")
        cur.execute("select public_tracking(%s)", (original_token,))
        assert cur.fetchone()[0] is None, "rotation must invalidate the previous token immediately"
        cur.execute("select public_tracking(%s)", (rotated_active_token,))
        assert cur.fetchone()[0] is not None, "the freshly rotated token must be usable"

        # ---- Owner may revoke; revoked token denied everywhere, no reactivation path. ----
        actor(owner_a)
        cur.execute("select revoke_tracking_token(%s)", (order_id,))
        assert cur.fetchone()[0] is True
        actor(outsider, "anon")
        cur.execute("select public_tracking(%s)", (rotated_active_token,))
        assert cur.fetchone()[0] is None, "revoked token must be denied"

        # Recovery from a revoked token is rotation only, never un-revoking.
        actor(owner_a)
        cur.execute("select rotate_tracking_token(%s)", (order_id,))
        recovered_token = cur.fetchone()[0]
        actor(outsider, "anon")
        cur.execute("select public_tracking(%s)", (recovered_token,))
        assert cur.fetchone()[0] is not None
        cur.execute("select public_tracking(%s)", (rotated_active_token,))
        assert cur.fetchone()[0] is None, "the old revoked token must remain dead even after rotation"

        # ---- Audit events recorded, no secret material inside. ----
        actor(owner_a)
        cur.execute(
            "select event_type, actor_role, metadata from delivery_events "
            "where order_id=%s and event_type in ('tracking_token_revoked','tracking_token_rotated') "
            "order by created_at",
            (order_id,),
        )
        events = cur.fetchall()
        assert [e[0] for e in events] == [
            "tracking_token_rotated",
            "tracking_token_revoked",
            "tracking_token_rotated",
        ]
        for event_type, actor_role, metadata in events:
            assert actor_role == "vendor"
            assert set(metadata.keys()) <= {"token_id"}, f"unexpected audit metadata: {metadata}"
            assert recovered_token not in str(metadata)
            assert rotated_active_token not in str(metadata)

        # ---- Completed delivery: token bound to a 48-hour post-completion window. ----
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
        cur.execute("reset role")
        cur.execute(
            "select (extract(epoch from (expires_at - completed_at)) between 172700 and 172900) "
            "from tracking_tokens t join orders o on o.id=t.order_id where t.order_id=%s",
            (order_id,),
        )
        assert cur.fetchone()[0] is True, "delivered order's token must expire ~48h after completed_at"

        # ---- Rotation after delivery: fresh 48h window from rotation time, not the old anchor. ----
        actor(owner_a)
        cur.execute("select rotate_tracking_token(%s)", (order_id,))
        post_delivery_rotated = cur.fetchone()[0]
        cur.execute("reset role")
        cur.execute(
            "select (extract(epoch from (expires_at - now())) between 172700 and 172900) "
            "from tracking_tokens where order_id=%s",
            (order_id,),
        )
        assert cur.fetchone()[0] is True, "rotating a delivered order's token must grant a fresh 48h window"

        actor(outsider, "anon")
        cur.execute("select public_tracking(%s)", (post_delivery_rotated,))
        snapshot = cur.fetchone()[0]
        assert snapshot["status"] == "delivered"
        assert snapshot["pod_available"] is True

        # ---- Existing lifecycle RPCs and normal customer access unaffected. ----
        actor(outsider, "anon")
        cur.execute("select submit_rating(%s,5,array['Great'])", (post_delivery_rotated,))
        assert cur.fetchone()[0]
        # Normal customer access never rotates or extends the token.
        cur.execute("reset role")
        cur.execute(
            "select expires_at from tracking_tokens where order_id=%s", (order_id,)
        )
        expires_after_read = cur.fetchone()[0]
        actor(outsider, "anon")
        cur.execute("select public_tracking(%s)", (post_delivery_rotated,))
        cur.execute("reset role")
        cur.execute(
            "select expires_at from tracking_tokens where order_id=%s", (order_id,)
        )
        assert cur.fetchone()[0] == expires_after_read, "customer access must never mutate the token"

        conn.rollback()

print("s4_04_batch_3_token_lifecycle_ok")
