"""Rollback-only S4-06 Batch-1 multi-order session foundation acceptance."""

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


owner_a, operator_a, owner_b = [uuid.uuid4() for _ in range(3)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in ((owner_a, "owner-a"), (operator_a, "operator-a"), (owner_b, "owner-b")):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"s4-06-b1-{label}-{uuid.uuid4()}@test.invalid"),
            )
        cur.execute("insert into businesses(name) values('S4-06 B1 Business A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-06 B1 Business B') returning id")
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

        # ---- Setup: three orders in Business A, one in Business B; one session in each. ----
        actor(owner_a)
        cur.execute("select create_delivery_session(%s,'B1 Run', current_date)", (business_a,))
        cur.execute("reset role")
        cur.execute("select id from delivery_sessions where business_id=%s order by created_at desc limit 1", (business_a,))
        session_a = cur.fetchone()[0]

        order_ids_a = []
        for i in range(3):
            actor(owner_a)
            cur.execute("select create_delivery(%s,'B1 Customer',%s,'Addr')", (business_a, f"+601900000{i:02d}"))
            order_ids_a.append(cur.fetchone()[0]["order"]["id"])

        actor(owner_b)
        cur.execute("select create_delivery_session(%s,'B1 Run B', current_date)", (business_b,))
        cur.execute("reset role")
        cur.execute("select id from delivery_sessions where business_id=%s order by created_at desc limit 1", (business_b,))
        session_b = cur.fetchone()[0]
        actor(owner_b)
        cur.execute("select create_delivery(%s,'B1 Customer B','+60190000099','Addr')", (business_b,))
        order_b = cur.fetchone()[0]["order"]["id"]

        # ---- Invariant: multiple same-business orders can belong to one session. ----
        actor(owner_a)
        for order_id in order_ids_a:
            cur.execute("select attach_order_to_session(%s,%s)", (order_id, session_a))
        cur.execute("reset role")
        cur.execute("select count(*) from orders where delivery_session_id=%s", (session_a,))
        assert cur.fetchone()[0] == 3, "all three same-business orders must be attachable to one session"

        # ---- Cross-business order/session combinations denied, both directions. ----
        actor(owner_a)
        rejected(cur, "select attach_order_to_session(%s,%s)", (order_ids_a[0], session_b), "invalid session")
        actor(owner_b)
        rejected(cur, "select attach_order_to_session(%s,%s)", (order_b, session_a), "invalid session")
        # Cross-business authorization (not just integrity): Business B cannot
        # even act on Business A's own order, regardless of session target.
        rejected(cur, "select attach_order_to_session(%s,%s)", (order_ids_a[0], session_b), "forbidden")

        # ---- Duplicate/idempotent attachment is safe: no duplicate event. ----
        actor(owner_a)
        cur.execute(
            "select count(*) from delivery_events where order_id=%s and event_type='session.order_attached'",
            (order_ids_a[0],),
        )
        before_count = cur.fetchone()[0]
        cur.execute("select attach_order_to_session(%s,%s)", (order_ids_a[0], session_a))
        cur.execute("select attach_order_to_session(%s,%s)", (order_ids_a[0], session_a))
        cur.execute(
            "select count(*) from delivery_events where order_id=%s and event_type='session.order_attached'",
            (order_ids_a[0],),
        )
        after_count = cur.fetchone()[0]
        assert after_count == before_count == 1, "re-attaching to the same session must not record a duplicate event"

        # ---- Existing detach behavior remains correct, and is itself idempotent. ----
        actor(owner_a)
        cur.execute("select attach_order_to_session(%s,%s)", (order_ids_a[0], None))
        cur.execute("reset role")
        cur.execute("select delivery_session_id from orders where id=%s", (order_ids_a[0],))
        assert cur.fetchone()[0] is None
        cur.execute(
            "select count(*) from delivery_events where order_id=%s and event_type='session.order_detached'",
            (order_ids_a[0],),
        )
        assert cur.fetchone()[0] == 1
        actor(owner_a)
        cur.execute("select attach_order_to_session(%s,%s)", (order_ids_a[0], None))  # already detached -- no-op
        cur.execute("reset role")
        cur.execute(
            "select count(*) from delivery_events where order_id=%s and event_type='session.order_detached'",
            (order_ids_a[0],),
        )
        assert cur.fetchone()[0] == 1, "detaching an already-detached order must not record a duplicate event"

        # Operator/Staff authorization for attach, matching every other RPC's precedent.
        actor(operator_a)
        cur.execute("select attach_order_to_session(%s,%s)", (order_ids_a[0], session_a))
        cur.execute("reset role")
        cur.execute("select delivery_session_id from orders where id=%s", (order_ids_a[0],))
        assert cur.fetchone()[0] == session_a

        # ---- Approval and existing lifecycle gates remain intact regardless
        # of session attachment (unaffected by this batch). ----
        actor(owner_a)
        rejected(cur, "select assign_rider(%s,%s)", (order_ids_a[0], uuid.uuid4()), "order not approved")
        cur.execute("select approve_order(%s)", (order_ids_a[0],))
        cur.execute("reset role")
        cur.execute("select approved_at from orders where id=%s", (order_ids_a[0],))
        assert cur.fetchone()[0] is not None, "approval gate is unaffected by session attachment"

        # ---- No direct-table write bypass on delivery_sessions or orders.delivery_session_id. ----
        actor(owner_a)
        rejected(cur, "insert into delivery_sessions(business_id,name) values(%s,'Bypass')", (business_a,))
        affects_zero(cur, "update delivery_sessions set name='bypass' where id=%s", (session_a,))
        affects_zero(cur, "update orders set delivery_session_id=null where id=%s", (order_ids_a[1],))

        # ---- Database integrity: no cross-business session attachment leaked through. ----
        cur.execute("reset role")
        cur.execute(
            "select count(*) from orders o where o.delivery_session_id is not null "
            "and not exists(select 1 from delivery_sessions s where s.id=o.delivery_session_id and s.business_id=o.business_id)"
        )
        assert cur.fetchone()[0] == 0

        conn.rollback()

print("s4_06_batch_1_multi_order_session_ok")
