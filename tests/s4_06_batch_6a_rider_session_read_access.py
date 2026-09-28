"""Rollback-only S4-06 Batch-6a Rider session read access (RLS) acceptance.

Proves the exact isolation matrix the Founder required: a Rider may SELECT
a delivery_session only when they genuinely have an assignment in it --
never a same-business unrelated session, never another business's session,
and anon/write access remain fully denied throughout.
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


owner_a, owner_b, ali_user, abu_user, rider_c_user = [uuid.uuid4() for _ in range(5)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in (
            (owner_a, "owner-a"), (owner_b, "owner-b"),
            (ali_user, "ali"), (abu_user, "abu"), (rider_c_user, "rider-c"),
        ):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"s4-06-b6a-{label}-{uuid.uuid4()}@test.invalid"),
            )
        cur.execute("insert into businesses(name) values('S4-06 B6a Business A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-06 B6a Business B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values(%s,%s,'owner'),(%s,%s,'owner')",
            (business_a, owner_a, business_b, owner_b),
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
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) values(%s,%s,'Rider C',%s,'active') returning id",
            (business_b, rider_c_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider_c = cur.fetchone()[0]

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            # A genuine anonymous request carries no JWT at all -- the sub
            # claim must be explicitly cleared here, not merely left unset,
            # since set_config(...,true) is transaction-local and would
            # otherwise leak the previous actor's identity into this one.
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claim.role',%s,true)",
                (str(user_id) if user_id is not None else "", role),
            )
            cur.execute(f"set local role {role}")

        def new_order(business_id, phone_suffix):
            cur.execute(
                "select create_delivery(%s,'B6a Customer',%s,'Addr')",
                (business_id, f"+60193{phone_suffix:06d}"),
            )
            order_id = uuid.UUID(cur.fetchone()[0]["order"]["id"])
            cur.execute("select approve_order(%s)", (order_id,))
            return order_id

        # =====================================================================
        # SETUP: session_x (business_a, Ali's Lunch Wave), session_y
        # (business_a, Abu's own Wave -- Ali has NO assignment here),
        # session_z (business_b, Rider C's Wave).
        # =====================================================================
        actor(owner_a)
        cur.execute("select (create_delivery_session(%s,'Lunch Wave')).id", (business_a,))
        session_x = cur.fetchone()[0]
        cur.execute("select (create_delivery_session(%s,'Unrelated Wave')).id", (business_a,))
        session_y = cur.fetchone()[0]

        oid_ali = new_order(business_a, 1)
        cur.execute("select attach_order_to_session(%s,%s)", (oid_ali, session_x))
        cur.execute("select assign_rider(%s,%s)", (oid_ali, ali))

        oid_abu = new_order(business_a, 2)
        cur.execute("select attach_order_to_session(%s,%s)", (oid_abu, session_y))
        cur.execute("select assign_rider(%s,%s)", (oid_abu, abu))

        actor(owner_b)
        cur.execute("select (create_delivery_session(%s,'Business B Wave')).id", (business_b,))
        session_z = cur.fetchone()[0]
        oid_c = new_order(business_b, 3)
        cur.execute("select attach_order_to_session(%s,%s)", (oid_c, session_z))
        cur.execute("select assign_rider(%s,%s)", (oid_c, rider_c))

        # =====================================================================
        # A. Ali can SELECT session_x (has a genuine assignment there).
        # =====================================================================
        actor(ali_user)
        cur.execute("select id, name from delivery_sessions where id=%s", (session_x,))
        row = cur.fetchone()
        assert row is not None and row[1] == "Lunch Wave", "Ali must read the real Wave name of his own session"

        # =====================================================================
        # B. Ali cannot SELECT session_y (only Abu is assigned there, same business).
        # C. (equivalent -- same-business unrelated session denial.)
        # =====================================================================
        cur.execute("select id from delivery_sessions where id=%s", (session_y,))
        assert cur.fetchone() is None, "Ali must not see a same-business session he has no assignment in"

        # =====================================================================
        # D. Ali cannot SELECT session_z (different business entirely).
        # =====================================================================
        cur.execute("select id from delivery_sessions where id=%s", (session_z,))
        assert cur.fetchone() is None, "Ali must not see another business's session"

        # =====================================================================
        # E. Abu has symmetric access: sees session_y, not session_x or session_z.
        # =====================================================================
        actor(abu_user)
        cur.execute("select id, name from delivery_sessions where id=%s", (session_y,))
        row = cur.fetchone()
        assert row is not None and row[1] == "Unrelated Wave"
        cur.execute("select id from delivery_sessions where id=%s", (session_x,))
        assert cur.fetchone() is None, "Abu must not see Ali's session"
        cur.execute("select id from delivery_sessions where id=%s", (session_z,))
        assert cur.fetchone() is None, "Abu must not see another business's session"

        # =====================================================================
        # F. Vendor Owner/Operator/Staff existing legitimate access unchanged
        # (sessions_vendor untouched, purely additive policy).
        # =====================================================================
        actor(owner_a)
        cur.execute("select id from delivery_sessions where business_id=%s", (business_a,))
        visible = {r[0] for r in cur.fetchall()}
        assert visible == {session_x, session_y}, "Vendor Owner must still see every session in their own business"
        actor(owner_b)
        cur.execute("select id from delivery_sessions where id=%s", (session_x,))
        assert cur.fetchone() is None, "Vendor Owner B must still be denied Business A's session (unchanged cross-business isolation)"

        # =====================================================================
        # G. anonymous cannot gain Rider session visibility.
        # =====================================================================
        actor(None, role="anon")
        cur.execute("select id from delivery_sessions where id=%s", (session_x,))
        assert cur.fetchone() is None, "anon must never see any session"
        cur.execute("select id from delivery_sessions")
        assert cur.fetchall() == [], "anon must never see any session, unscoped query"

        # =====================================================================
        # H/I/J. Rider cannot INSERT/UPDATE/DELETE delivery_sessions.
        # K. direct-write protections remain intact.
        # =====================================================================
        actor(ali_user)
        rejected(
            cur,
            "insert into delivery_sessions(business_id, name) values (%s, 'Malicious Wave')",
            (business_a,),
        )
        cur.execute("update delivery_sessions set name='Hacked' where id=%s", (session_x,))
        assert cur.rowcount == 0, "Rider must not be able to UPDATE delivery_sessions directly"
        cur.execute("delete from delivery_sessions where id=%s", (session_x,))
        assert cur.rowcount == 0, "Rider must not be able to DELETE delivery_sessions directly"

        # =====================================================================
        # O. S4-06.6 Rider grouping now displays a real Wave name when
        # readable (proven above in A/E). P. covered by the existing
        # riderRuns()/renderHome fallback (already tested statically) --
        # confirming here only that the backend-side name IS genuinely
        # readable, matching what the UI now expects.
        # =====================================================================

        conn.rollback()

print("s4_06_batch_6a_rider_session_read_access_ok")
