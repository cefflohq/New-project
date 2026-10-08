"""Rollback-only acceptance for set_order_pin (proposal §7). Run on staging
only AFTER the Founder approves and the migration is applied.

Owner OK, Operator OK, Helper refused, Driver refused, other business refused,
anon refused, out-of-bounds refused, delivered refused. Everything rolls back.
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


owner, operator, helper, driver, stranger = (uuid.uuid4() for _ in range(5))

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for u in (owner, operator, helper, driver, stranger):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (u, f"pin-{u}@test.invalid"),
            )
        cur.execute("insert into businesses(name) values('Pin A') returning id")
        biz_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('Pin B') returning id")
        biz_b = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values(%s,%s,'owner'),(%s,%s,'operator'),(%s,%s,'helper'),(%s,%s,'owner')",
            (biz_a, owner, biz_a, operator, biz_a, helper, biz_b, stranger),
        )
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) values(%s,%s,'Pin Driver','+60111111112','active')",
            (biz_a, driver),
        )

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),"
                "set_config('request.jwt.claim.role',%s,true)",
                (str(user_id or ""), role),
            )
            cur.execute(f"set local role {role}")

        actor(owner)
        cur.execute("select create_delivery(%s,'Pin C1','+60140000002','Some Address')", (biz_a,))
        order_id = cur.fetchone()[0]["order"]["id"]

        for who in (owner, operator):
            actor(who)
            cur.execute("select latitude, longitude, location_source, location_accuracy_m from set_order_pin(%s, 3.139, 101.687)", (order_id,))
            assert cur.fetchone() == (3.139, 101.687, "vendor", None), "Owner/Operator may pin"
        cur.execute("reset role")
        cur.execute("select count(*) from delivery_events where order_id=%s and event_type='order.pin_set'", (order_id,))
        assert cur.fetchone()[0] == 2, "each pin is audited"

        for who in (helper, driver, stranger):
            actor(who)
            rejected(cur, "select set_order_pin(%s, 3.139, 101.687)", (order_id,), contains="forbidden")
        actor(None, "anon")
        rejected(cur, "select set_order_pin(%s, 3.139, 101.687)", (order_id,))

        actor(owner)
        for lat, lng in ((0.4, 101.0), (7.7, 101.0), (3.1, 99.4), (3.1, 119.6), (None, 101.0)):
            rejected(cur, "select set_order_pin(%s, %s, %s)", (order_id, lat, lng))

        cur.execute("reset role")
        cur.execute("update orders set delivery_status='delivered', completed_at=now() where id=%s", (order_id,))
        actor(owner)
        rejected(cur, "select set_order_pin(%s, 3.139, 101.687)", (order_id,), contains="closed")

        conn.rollback()

print("delivery_pin_set_order_pin_ok")
