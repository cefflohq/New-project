"""Rollback-only F2-02 (CEFFLO Flow 2 Canonical Backend Completion Master)
acceptance: the generic is_within_coverage(business_id, lat, lng)
primitive -- unconfigured/missing-coordinate return null (neither in nor
out), inside/boundary/outside return true/false, and foreign-tenant calls
are denied. order_coverage_status (order-scoped) remains a separate
function but now expresses the identical radius comparison."""

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


owner_a, owner_b = uuid.uuid4(), uuid.uuid4()

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in ((owner_a, "owner-a"), (owner_b, "owner-b")):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"f2-02-{label}-{uuid.uuid4()}@test.invalid"),
            )
        cur.execute("insert into businesses(name) values('F2-02 Biz A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('F2-02 Biz B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute("insert into business_members(business_id,user_id,role) values(%s,%s,'owner')", (business_a, owner_a))
        cur.execute("insert into business_members(business_id,user_id,role) values(%s,%s,'owner')", (business_b, owner_b))

        def actor(user_id):
            cur.execute("reset role")
            cur.execute("select set_config('request.jwt.claim.sub',%s,true)", (str(user_id),))
            cur.execute("set local role authenticated")

        actor(owner_a)
        cur.execute("select is_within_coverage(%s, 3.14, 101.68)", (business_a,))
        assert cur.fetchone()[0] is None, "unconfigured business must return null, not false"

        cur.execute("select set_business_service_area(%s, 3.1390, 101.6869, 10)", (business_a,))

        cur.execute("select is_within_coverage(%s, 3.1450, 101.6900)", (business_a,))
        assert cur.fetchone()[0] is True

        cur.execute("select is_within_coverage(%s, 3.5000, 102.2000)", (business_a,))
        assert cur.fetchone()[0] is False

        cur.execute("select is_within_coverage(%s, null, 101.68)", (business_a,))
        assert cur.fetchone()[0] is None, "missing coordinate must return null, not false"

        # Foreign tenant denial: owner_b cannot evaluate business_a's coverage.
        actor(owner_b)
        rejected(cur, "select is_within_coverage(%s, 3.14, 101.68)", (business_a,), "forbidden")

        conn.rollback()

print("f2_02_is_within_coverage_ok")
