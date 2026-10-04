"""Rollback-only SEC-RBAC / SEC-TENANT acceptance for active membership
removal (Security & Access Master Part III §19-23, Part IV §10, §14-15, §28):

- only the Owner of the same business can remove an Operator/Helper;
- an Operator, a Helper and another business's Owner are refused;
- removal ends business authorization while the auth account stays valid
  (protected reads go empty, protected writes are refused);
- the last active Owner cannot be removed.
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


owner_a, operator_a, helper_a, owner_b = [uuid.uuid4() for _ in range(4)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id in (owner_a, operator_a, helper_a, owner_b):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"sec-removal-{user_id}@test.invalid"),
            )
        cur.execute("insert into businesses(name) values('SEC removal Business A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('SEC removal Business B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values"
            "(%s,%s,'owner'),(%s,%s,'operator'),(%s,%s,'helper'),(%s,%s,'owner')",
            (business_a, owner_a, business_a, operator_a, business_a, helper_a, business_b, owner_b),
        )
        cur.execute(
            "insert into orders(business_id,customer_name,customer_phone,delivery_address) "
            "values(%s,'Customer','+60100000000','No. 1, Jalan Ujian') returning id",
            (business_a,),
        )
        order_a = cur.fetchone()[0]

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claim.role',%s,true)",
                (str(user_id), role),
            )
            cur.execute(f"set local role {role}")

        remove = "select update_team_member(%s,%s,p_status=>'inactive')"

        # Before removal the Operator is a working member of Business A.
        actor(operator_a)
        cur.execute("select public.is_business_member(%s)", (business_a,))
        assert cur.fetchone()[0] is True
        cur.execute("select count(*) from orders where id=%s", (order_a,))
        assert cur.fetchone()[0] == 1, "active Operator must read own business orders"

        # Refused: Operator, Helper and another business's Owner.
        actor(operator_a)
        rejected(cur, remove, (business_a, helper_a), "forbidden")
        actor(helper_a)
        rejected(cur, remove, (business_a, operator_a), "forbidden")
        actor(owner_b)
        rejected(cur, remove, (business_a, operator_a), "forbidden")

        # The last active Owner cannot be removed, even by themself.
        actor(owner_a)
        rejected(cur, remove, (business_a, owner_a))

        # Owner removes the Operator; fresh read-back shows inactive.
        actor(owner_a)
        cur.execute(remove + " is not null", (business_a, operator_a))
        cur.execute("reset role")
        cur.execute(
            "select status from business_members where business_id=%s and user_id=%s",
            (business_a, operator_a),
        )
        assert cur.fetchone()[0] == "inactive"

        # Revocation: the auth identity still exists, business access is gone.
        cur.execute("select count(*) from auth.users where id=%s", (operator_a,))
        assert cur.fetchone()[0] == 1, "removal must not delete the global account"
        actor(operator_a)
        cur.execute("select public.is_business_member(%s)", (business_a,))
        assert cur.fetchone()[0] is False
        cur.execute("select count(*) from orders where id=%s", (order_a,))
        assert cur.fetchone()[0] == 0, "removed Operator must not read business orders"
        rejected(cur, "select create_zone(%s,'After removal')", (business_a,))
        rejected(cur, remove, (business_a, helper_a), "forbidden")

        # Business B is untouched by any of this.
        cur.execute("reset role")
        cur.execute("select status from business_members where business_id=%s and user_id=%s", (business_b, owner_b))
        assert cur.fetchone()[0] == "active"

        conn.rollback()

print("sec_member_removal_revocation_ok")
