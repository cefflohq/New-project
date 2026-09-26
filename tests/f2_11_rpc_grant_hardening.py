"""Rollback-only F2-11 (CEFFLO Flow 2 Canonical Backend Completion Master)
acceptance: sensitive mutation RPCs are rejected for anon at the GRANT
layer (not merely by their own internal is_business_member check), while
RLS-protected table reads remain transparently empty for anon (not a hard
permission error) -- proving the fix correctly distinguishes "function
called directly by a client" from "function referenced inside an RLS
policy," which a first, reverted attempt at this hardening got wrong."""

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


owner_a = uuid.uuid4()

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        cur.execute(
            "insert into auth.users(id,aud,role,email,created_at,updated_at) "
            "values(%s,'authenticated','authenticated',%s,now(),now())",
            (owner_a, f"f2-11-owner-{uuid.uuid4()}@test.invalid"),
        )
        cur.execute("insert into businesses(name) values('F2-11 Grant Hardening') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into business_members(business_id,user_id,role) values(%s,%s,'owner')", (business_a, owner_a))
        cur.execute("reset role")
        cur.execute("select set_config('request.jwt.claim.sub',%s,true)", (str(owner_a),))
        cur.execute("set local role authenticated")
        cur.execute("select create_delivery(%s,'F2-11 C1','+60140000001','Addr')", (business_a,))
        order_id = cur.fetchone()[0]["order"]["id"]

        # =====================================================================
        # Sensitive mutations: rejected for anon at the GRANT layer (a real
        # "permission denied for function X" from Postgres itself, proving
        # the ACL was actually tightened -- not merely relying on the
        # function's own internal check, which anon would also fail, but
        # only after already being allowed to invoke it).
        # =====================================================================
        cur.execute("reset role")
        cur.execute("select set_config('request.jwt.claim.sub','',true)")
        cur.execute("set local role anon")

        for statement, params in (
            ("select assign_rider(%s, %s)", (order_id, uuid.uuid4())),
            ("select bootstrap_business(%s)", ("Anon Business",)),
            ("select get_my_businesses()", ()),
            ("select deactivate_rider(%s)", (uuid.uuid4(),)),
            ("select reassign_rider(%s, %s)", (order_id, uuid.uuid4())),
            ("select update_business_profile(%s,%s,%s,%s,%s,%s,%s,%s,%s)",
             (business_a, "x", "x", "x", "x", "x", "x", "x", None)),
            ("select update_team_member(%s,%s,%s,%s)", (business_a, owner_a, "operator", "active")),
            ("select compute_order_eta(%s)", (order_id,)),
        ):
            rejected(cur, statement, params, "permission denied")

        # =====================================================================
        # RLS-protected reads: anon still gets a transparently empty result,
        # NEVER a permission error -- is_business_member/is_business_owner/
        # is_current_rider/is_session_rider (referenced inside RLS policies)
        # deliberately kept anon-executable so policy evaluation itself
        # never breaks.
        # =====================================================================
        cur.execute("select count(*) from orders where business_id=%s", (business_a,))
        assert cur.fetchone()[0] == 0, "anon must see zero rows via RLS, not an error"

        cur.execute("select count(*) from delivery_sessions where business_id=%s", (business_a,))
        assert cur.fetchone()[0] == 0

        # =====================================================================
        # Regression check: the legitimate owner can still do everything --
        # this hardening narrows anon only, never authenticated.
        # =====================================================================
        cur.execute("reset role")
        cur.execute("select set_config('request.jwt.claim.sub',%s,true)", (str(owner_a),))
        cur.execute("set local role authenticated")
        cur.execute("select count(*) from get_my_businesses()")
        assert cur.fetchone()[0] == 1

        conn.rollback()

print("f2_11_rpc_grant_hardening_ok")
