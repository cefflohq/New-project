"""Rollback-only acceptance for the international country foundation
(20261014100000_country_foundation.sql): the countries reference table
(public read, MY the only live pack), country on businesses (existing rows
MY), set_business_country (owner only, never a planned country, locked once
the business has orders) and set_my_country."""

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


owner, stranger = uuid.uuid4(), uuid.uuid4()

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in ((owner, "owner"), (stranger, "stranger")):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"country-{label}-{uuid.uuid4()}@test.invalid"),
            )
        cur.execute("insert into businesses(name) values('Country Biz A') returning id, country_iso2")
        business_a, country = cur.fetchone()
        assert country == "MY", "existing and default businesses are Malaysian"
        cur.execute("insert into businesses(name) values('Country Biz B') returning id")
        business_b = cur.fetchone()[0]
        for business in (business_a, business_b):
            cur.execute("insert into business_members(business_id,user_id,role) values(%s,%s,'owner')", (business, owner))

        cur.execute("select count(*) filter (where status='live'), array_agg(iso2) filter (where status='live') from countries")
        live_count, live = cur.fetchone()
        assert live_count == 1 and live == ["MY"], live

        def actor(user_id):
            cur.execute("reset role")
            cur.execute("select set_config('request.jwt.claim.sub',%s,true)", (str(user_id),))
            cur.execute("set local role authenticated")

        actor(owner)
        rejected(cur, "select set_business_country(%s,'SG')", (business_a,), "country not available")

        cur.execute("reset role")
        cur.execute("update countries set status='beta' where iso2='SG'")
        actor(owner)
        cur.execute("select country_iso2, currency, timezone from set_business_country(%s,'sg')", (business_a,))
        assert cur.fetchone() == ("SG", "SGD", "Asia/Singapore")

        cur.execute("reset role")
        cur.execute("insert into orders(business_id,customer_name,customer_phone,delivery_address) values(%s,'C','0123456789','Addr')", (business_b,))
        actor(owner)
        rejected(cur, "select set_business_country(%s,'SG')", (business_b,), "country locked")

        actor(stranger)
        rejected(cur, "select set_business_country(%s,'MY')", (business_a,), "forbidden")
        cur.execute("select set_my_country('my')")
        assert cur.fetchone()[0] == "MY"

        cur.execute("reset role")
        cur.execute("set local role anon")
        cur.execute("select count(*) from countries")
        assert cur.fetchone()[0] >= 30, "first-launch picker reads countries before sign-in"
        rejected(cur, "update countries set status='live' where iso2='SG'")

        conn.rollback()

print("country_foundation_ok")
