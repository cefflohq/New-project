"""Rollback-only F2-08 (CEFFLO Flow 2 Canonical Backend Completion Master)
acceptance: the Rider location backend contract -- authorized writes,
spoofed rider_id / anonymous / cross-tenant business_id denial, out-of-
range coordinate rejection, and tenant-scoped reads. Flow 2 does not
implement Flutter background GPS (that remains Flow 5); this proves the
backend itself is ready for real writes."""

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


owner_a, rider_a_user = uuid.uuid4(), uuid.uuid4()

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in ((owner_a, "owner-a"), (rider_a_user, "rider-a")):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"f2-08-{label}-{uuid.uuid4()}@test.invalid"),
            )
        cur.execute("insert into businesses(name) values('F2-08 Biz A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('F2-08 Biz B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute("insert into business_members(business_id,user_id,role) values(%s,%s,'owner')", (business_a, owner_a))
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status,vehicle_type) "
            "values(%s,%s,'Rider A',%s,'active','motorcycle') returning id",
            (business_a, rider_a_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider_a = cur.fetchone()[0]
        cur.execute(
            "insert into riders(business_id,name,phone,status,vehicle_type) "
            "values(%s,'Rider B',%s,'active','motorcycle') returning id",
            (business_b, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider_b = cur.fetchone()[0]

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),"
                "set_config('request.jwt.claim.role',%s,true)",
                (str(user_id), role),
            )
            cur.execute(f"set local role {role}")

        # =====================================================================
        # Authorized write: business_id is derived server-side, never from
        # caller input -- record_rider_location takes no business_id param
        # at all.
        # =====================================================================
        actor(rider_a_user)
        cur.execute(
            "select business_id, rider_id, latitude, longitude, accuracy "
            "from record_rider_location(%s, 3.14, 101.68, 5.0, 90.0, 12.0)",
            (rider_a,),
        )
        biz_out, rider_out, lat, lng, acc = cur.fetchone()
        assert biz_out == business_a and rider_out == rider_a and lat == 3.14 and lng == 101.68 and acc == 5.0

        # =====================================================================
        # Spoofed rider_id: an authenticated Rider cannot write location for
        # a Rider identity that isn't their own (a different business's
        # Rider row here, but the check is identity-based, not just tenant).
        # =====================================================================
        rejected(cur, "select record_rider_location(%s, 3.14, 101.68)", (rider_b,), "forbidden")

        # =====================================================================
        # Anonymous write denied.
        # =====================================================================
        cur.execute("reset role")
        cur.execute("select set_config('request.jwt.claim.sub','',true)")
        cur.execute("set local role authenticated")
        rejected(cur, "select record_rider_location(%s, 3.14, 101.68)", (rider_a,), "forbidden")

        # =====================================================================
        # Out-of-range coordinates rejected -- never invent/accept nonsense.
        # =====================================================================
        actor(rider_a_user)
        rejected(cur, "select record_rider_location(%s, 999, 101.68)", (rider_a,), "coordinates out of range")
        rejected(cur, "select record_rider_location(%s, 3.14, -999)", (rider_a,), "coordinates out of range")
        rejected(cur, "select record_rider_location(%s, null, 101.68)", (rider_a,), "coordinates required")

        # =====================================================================
        # Tenant-scoped read: the owner sees their own business's latest
        # per-Rider location; a foreign business is denied outright.
        # =====================================================================
        actor(owner_a)
        cur.execute("select rider_id, latitude, longitude from latest_rider_locations(%s)", (business_a,))
        rows = cur.fetchall()
        assert len(rows) == 1 and rows[0][0] == rider_a

        rejected(cur, "select * from latest_rider_locations(%s)", (business_b,), "forbidden")

        # =====================================================================
        # Defense-in-depth: a raw table insert (bypassing the RPC) with a
        # spoofed business_id must still be blocked by RLS directly.
        # =====================================================================
        actor(rider_a_user)
        rejected(
            cur,
            "insert into rider_locations(business_id, rider_id, latitude, longitude) values (%s, %s, 1, 1)",
            (business_b, rider_a),
        )

        # A correctly-scoped raw insert (matching business_id) is still
        # allowed -- the RLS policy validates correctness, not the raw-vs-
        # RPC path itself.
        cur.execute(
            "insert into rider_locations(business_id, rider_id, latitude, longitude) values (%s, %s, 1, 1)",
            (business_a, rider_a),
        )

        conn.rollback()

print("f2_08_rider_location_backend_ok")
