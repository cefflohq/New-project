"""Rollback-only S4-05 Batch-3 delivery-session foundation acceptance."""

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


owner_a, operator_a, owner_b = [uuid.uuid4() for _ in range(3)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in (
            (owner_a, "owner-a"),
            (operator_a, "operator-a"),
            (owner_b, "owner-b"),
        ):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"s4-05-b3-{label}-{uuid.uuid4()}@test.invalid"),
            )

        cur.execute("insert into businesses(name) values('S4-05 B3 Business A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-05 B3 Business B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values"
            "(%s,%s,'owner'),(%s,%s,'operator'),(%s,%s,'owner')",
            (business_a, owner_a, business_a, operator_a, business_b, owner_b),
        )

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),"
                "set_config('request.jwt.claim.role',%s,true)",
                (str(user_id), role),
            )
            cur.execute(f"set local role {role}")

        def affects_zero(cur, statement, params=()):
            cur.execute(statement, params)
            assert cur.rowcount == 0, f"direct mutation affected {cur.rowcount} row(s): {statement}"

        # ---- Direct INSERT/UPDATE/DELETE denied for any business member.
        # A select-only RLS policy makes INSERT/UPDATE/DELETE affect zero
        # rows (matching the exact pattern already established and verified
        # for orders/riders in tests/s4_03_batch_3_rls.py), not necessarily a
        # raised exception -- ground truth is set up via the unrestricted
        # harness connection (bypasses RLS), matching that same precedent. ----
        cur.execute("reset role")
        cur.execute("insert into delivery_sessions(business_id,name) values(%s,'Seed Session') returning id", (business_a,))
        ground_truth_session = cur.fetchone()[0]

        actor(owner_a)
        rejected(cur, "insert into delivery_sessions(business_id,name) values(%s,'Direct Insert')", (business_a,))
        affects_zero(cur, "update delivery_sessions set name='Hacked' where id=%s", (ground_truth_session,))
        affects_zero(cur, "delete from delivery_sessions where id=%s", (ground_truth_session,))

        cur.execute("reset role")
        cur.execute("select name, count(*) from delivery_sessions where id=%s group by name", (ground_truth_session,))
        row = cur.fetchone()
        assert row is not None and row[0] == "Seed Session", "direct INSERT/UPDATE/DELETE must not have altered the row"
        cur.execute("delete from delivery_sessions where id=%s", (ground_truth_session,))  # ground-truth cleanup

        # ---- SELECT behavior preserved: business member can read. ----
        actor(owner_a)
        cur.execute("select create_delivery_session(%s,'Morning Run', current_date)", (business_a,))
        cur.execute("reset role")
        cur.execute("select id from delivery_sessions where business_id=%s order by created_at desc limit 1", (business_a,))
        created_session_id = cur.fetchone()[0]
        actor(owner_a)
        cur.execute("select name, status from delivery_sessions where id=%s", (created_session_id,))
        row = cur.fetchone()
        assert row is not None, "business member must retain SELECT access"
        assert row[0] == "Morning Run"
        assert row[1] == "planned"

        # ---- Cross-business SELECT denied (RLS still enforces isolation). ----
        actor(owner_b)
        cur.execute("select count(*) from delivery_sessions where id=%s", (created_session_id,))
        assert cur.fetchone()[0] == 0, "a different business must not see another business's session"

        # ---- Protected create-session: Owner authorization. ----
        cur.execute("reset role")
        cur.execute(
            "select count(*) from delivery_events where event_type='session.created' and business_id=%s",
            (business_a,),
        )
        assert cur.fetchone()[0] == 1

        # ---- Operator/Staff authorization. ----
        actor(operator_a)
        cur.execute("select create_delivery_session(%s,'Afternoon Run', current_date)", (business_a,))
        cur.execute("reset role")
        cur.execute(
            "select id from delivery_sessions where business_id=%s and name='Afternoon Run'", (business_a,)
        )
        operator_session_id = cur.fetchone()[0]
        assert operator_session_id is not None, "Operator/Staff must be authorized to create a session"

        # ---- Cross-business denial: Business B cannot create a session for Business A. ----
        actor(owner_b)
        rejected(cur, "select create_delivery_session(%s,'Intrusion', current_date)", (business_a,), "forbidden")

        # ---- Order/session attachment integrity. ----
        actor(owner_a)
        cur.execute("select create_delivery(%s,'B3 Customer','+60150000000','Addr')", (business_a,))
        order_id = cur.fetchone()[0]["order"]["id"]
        cur.execute("select attach_order_to_session(%s,%s)", (order_id, created_session_id))
        cur.execute("reset role")
        cur.execute("select delivery_session_id from orders where id=%s", (order_id,))
        assert cur.fetchone()[0] == created_session_id

        # Cross-business attach denied: an order from Business A cannot be
        # attached to a session belonging to Business B.
        actor(owner_b)
        cur.execute("select create_delivery_session(%s,'B Session', current_date)", (business_b,))
        cur.execute("reset role")
        cur.execute("select id from delivery_sessions where business_id=%s order by created_at desc limit 1", (business_b,))
        business_b_session = cur.fetchone()[0]
        actor(owner_a)
        rejected(cur, "select attach_order_to_session(%s,%s)", (order_id, business_b_session), "invalid session")

        # Detach (null) works and is recorded distinctly.
        actor(owner_a)
        cur.execute("select attach_order_to_session(%s,%s)", (order_id, None))
        cur.execute("reset role")
        cur.execute("select delivery_session_id from orders where id=%s", (order_id,))
        assert cur.fetchone()[0] is None
        cur.execute(
            "select event_type from delivery_events where order_id=%s and event_type like 'session.order_%%' order by created_at",
            (order_id,),
        )
        events = [r[0] for r in cur.fetchall()]
        assert events == ["session.order_attached", "session.order_detached"]

        # ---- Minimal status lifecycle. ----
        actor(owner_a)
        cur.execute("select update_session_status(%s,'active')", (created_session_id,))
        cur.execute("reset role")
        cur.execute("select status, started_at is not null from delivery_sessions where id=%s", (created_session_id,))
        status, has_started_at = cur.fetchone()
        assert status == "active" and has_started_at is True

        actor(owner_a)
        rejected(cur, "select update_session_status(%s,'bogus')", (created_session_id,), "invalid status")

        actor(owner_b)
        rejected(cur, "select update_session_status(%s,'completed')", (created_session_id,), "forbidden")

        cur.execute("reset role")
        cur.execute(
            "select count(*) from delivery_events where event_type='session.status_changed' and business_id=%s",
            (business_a,),
        )
        assert cur.fetchone()[0] == 1

        conn.rollback()

print("s4_05_batch_3_delivery_session_foundation_ok")
