"""Rollback-only checks for 20261004090000_tracking_privacy_and_link_admin:

- public_tracking never reveals multi-drop information (no `stops_ahead`,
  in the live block or inside `eta`) and exposes this order's `picked_up_at`;
- rotate/revoke_tracking_token: Owner and Operator allowed; Helper, another
  business's Owner and anon refused.
"""

import uuid

import psycopg

from environment_guard import TargetRefused, validate_database_target

try:
    target = validate_database_target(mutating=True, allowed_environments=frozenset({"local", "staging", "test"}))
except TargetRefused as error:
    raise SystemExit(f"target_refused: {error}") from error


def rejected(cur, statement, params=(), contains=None):
    sp = f"denied_{uuid.uuid4().hex}"
    cur.execute(f"savepoint {sp}")
    try:
        cur.execute(statement, params)
    except psycopg.Error as error:
        cur.execute(f"rollback to savepoint {sp}")
        if contains:
            assert contains in str(error), str(error)
    else:
        raise AssertionError(f"expected rejection: {statement}")


owner, operator, helper, owner_b, rider_user = [uuid.uuid4() for _ in range(5)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for u in (owner, operator, helper, owner_b, rider_user):
            cur.execute("insert into auth.users(id,aud,role,email,created_at,updated_at) values(%s,'authenticated','authenticated',%s,now(),now())", (u, f"trk-{u}@test.invalid"))
        cur.execute("insert into businesses(name) values('TRK A') returning id"); biz = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('TRK B') returning id"); biz_b = cur.fetchone()[0]
        cur.execute("insert into business_members(business_id,user_id,role) values(%s,%s,'owner'),(%s,%s,'operator'),(%s,%s,'helper'),(%s,%s,'owner')",
                    (biz, owner, biz, operator, biz, helper, biz_b, owner_b))
        cur.execute("insert into riders(business_id,auth_user_id,name,phone,status) values(%s,%s,'R','+60100000001','active') returning id", (biz, rider_user))
        rider = cur.fetchone()[0]

        def actor(u, role="authenticated"):
            cur.execute("reset role")
            cur.execute("select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claim.role',%s,true)", (str(u) if u else "", role))
            cur.execute(f"set local role {role}")

        actor(owner)
        cur.execute("select create_delivery(%s,'C1','+60111','Addr 1','',3.14,101.69,'[]'::jsonb,null,'any')", (biz,))
        first = cur.fetchone()[0]
        cur.execute("select create_delivery(%s,'C2','+60112','Addr 2','',3.15,101.70,'[]'::jsonb,null,'any')", (biz,))
        second = cur.fetchone()[0]
        o1, o2 = first["order"]["id"], second["order"]["id"]
        token2 = second["tracking_token"]

        # Put both orders on one rider run, o1 before o2, o2 out for delivery.
        cur.execute("reset role")
        cur.execute("insert into delivery_sessions(business_id,name) values(%s,'S') returning id", (biz,)); sess = cur.fetchone()[0]
        cur.execute("insert into rider_assignments(business_id,rider_id,delivery_session_id,status) values(%s,%s,%s,'accepted') returning id", (biz, rider, sess)); asg = cur.fetchone()[0]
        for seq, oid in ((1, o1), (2, o2)):
            cur.execute("update orders set delivery_session_id=%s, assigned_rider_id=%s, delivery_status='out_for_delivery' where id=%s", (sess, rider, oid))
            cur.execute("update delivery_stops set assignment_id=%s, rider_id=%s, sequence=%s, sequence_locked_at=now(), status='out_for_delivery' where order_id=%s", (asg, rider, seq, oid))
            cur.execute("insert into delivery_events(business_id,order_id,event_type,from_status,to_status,actor_role) values(%s,%s,'rider.transition','ready_for_pickup','picked_up','rider')", (biz, oid))

        actor(None, "anon")
        cur.execute("select public_tracking(%s)", (token2,))
        snap = cur.fetchone()[0]
        assert snap and snap["status"] == "out_for_delivery", snap
        assert "stops_ahead" not in snap, "multi-drop count leaked at top level"
        assert "stops_ahead" not in (snap.get("eta") or {}), "multi-drop count leaked inside eta"
        assert snap.get("eta", {}).get("state") == "estimated_range", snap.get("eta")
        assert snap.get("picked_up_at"), "own pickup time missing"
        for leak in ("C1", "Addr 1", "+60111", str(o1), str(rider)):
            assert leak not in str(snap), f"leaked {leak}"

        # Tracking-link administration.
        for who in (helper, owner_b):
            actor(who)
            rejected(cur, "select rotate_tracking_token(%s)", (o2,), "forbidden")
            rejected(cur, "select revoke_tracking_token(%s)", (o2,), "forbidden")
        actor(None, "anon")
        rejected(cur, "select rotate_tracking_token(%s)", (o2,), "permission denied")
        for who in (operator, owner):
            actor(who)
            cur.execute("select rotate_tracking_token(%s)", (o2,))
            assert cur.fetchone()[0]
        actor(operator)
        cur.execute("select revoke_tracking_token(%s)", (o2,))
        assert cur.fetchone()[0] is True
        conn.rollback()

print("sec_tracking_privacy_link_admin_ok")
