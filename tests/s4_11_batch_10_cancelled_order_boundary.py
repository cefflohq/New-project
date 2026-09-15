"""Rollback-only regression for the cancelled-order boundary on
assign_rider/approve_order (S4-10E remediation, 202609010002) --
"terminal decline must be terminal": once an order is cancelled, neither
function may ever act on it again, even if it still carries a prior
approved_at from before cancellation. No dedicated regression test existed
for this specific boundary before Grow V1 Flow 2's S4-11 Batch 7/10
permission-audit rewrite of both functions; this closes that gap so a
future accidental rewrite (exactly the mistake this batch itself made and
had to correct) is caught by a test, not only by inspection."""

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


owner_a, helper_a = [uuid.uuid4() for _ in range(2)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in ((owner_a, "owner-a"), (helper_a, "helper-a")):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"s4-11-b10-cancel-{label}-{uuid.uuid4()}@test.invalid"),
            )

        cur.execute("insert into businesses(name) values('S4-11 B10 Cancelled Boundary') returning id")
        business = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values(%s,%s,'owner'),(%s,%s,'helper')",
            (business, owner_a, business, helper_a),
        )
        cur.execute(
            "insert into riders(business_id,name,phone,status) values(%s,'Cancel Boundary Rider',%s,'active') returning id",
            (business, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider_id = cur.fetchone()[0]

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),"
                "set_config('request.jwt.claim.role',%s,true)",
                (str(user_id), role),
            )
            cur.execute(f"set local role {role}")

        # =====================================================================
        # approve_order must reject a cancelled order, even pre-approval
        # (the exact case the S4-10E remediation closed: a declined order
        # could previously still be approved after the fact).
        # =====================================================================
        actor(owner_a)
        cur.execute("select create_delivery(%s,'Cancel Boundary C1','+60140000001','Addr')", (business,))
        order_a = cur.fetchone()[0]["order"]["id"]
        cur.execute("select decline_order(%s)", (order_a,))

        cur.execute("reset role")
        cur.execute("select delivery_status, approved_at from orders where id=%s", (order_a,))
        status, approved_at = cur.fetchone()
        assert status == "cancelled" and approved_at is None, "decline_order must cancel without ever approving"

        actor(owner_a)
        rejected(cur, "select approve_order(%s)", (order_a,), "order cancelled")

        # =====================================================================
        # assign_rider must reject a cancelled order as a direct, defensive
        # gate -- not merely relying on "cancelled implies never approved."
        # Force the otherwise-unreachable approved+cancelled combination
        # directly (bypassing the RPC layer, as the test's own setup step)
        # to prove this is a real independent check, not a transitive one.
        # =====================================================================
        actor(owner_a)
        cur.execute("select create_delivery(%s,'Cancel Boundary C2','+60140000002','Addr')", (business,))
        order_b = cur.fetchone()[0]["order"]["id"]
        cur.execute("select approve_order(%s)", (order_b,))

        cur.execute("reset role")
        cur.execute("update orders set delivery_status='cancelled' where id=%s", (order_b,))

        actor(owner_a)
        rejected(cur, "select assign_rider(%s,%s)", (order_b, rider_id), "order cancelled")

        cur.execute("reset role")
        cur.execute("select assigned_rider_id from orders where id=%s", (order_b,))
        assert cur.fetchone()[0] is None, "a rejected assign_rider call must never mutate the order"

        # =====================================================================
        # Helper permission boundary (S4-11 Batch 7/10): a Helper must be
        # blocked from approve_order/assign_rider regardless of the order's
        # cancelled state -- the permission check and the cancelled-state
        # check are independent gates, and this proves neither one silently
        # substitutes for the other.
        # =====================================================================
        actor(owner_a)
        cur.execute("select create_delivery(%s,'Cancel Boundary C3','+60140000003','Addr')", (business,))
        order_c = cur.fetchone()[0]["order"]["id"]

        actor(helper_a)
        rejected(cur, "select approve_order(%s)", (order_c,), "forbidden")
        rejected(cur, "select assign_rider(%s,%s)", (order_c, rider_id), "forbidden")

        conn.rollback()

print("s4_11_batch_10_cancelled_order_boundary_ok")
