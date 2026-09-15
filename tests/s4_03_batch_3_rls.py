"""Rollback-only S4-03 Batch-3 RLS bypass and scope acceptance."""

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


owner_a, operator_a, owner_b, rider_user, outsider = [uuid.uuid4() for _ in range(5)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        # Harness setup runs as the database test principal, never as an application actor.
        for user_id, label in (
            (owner_a, "owner-a"),
            (operator_a, "operator-a"),
            (owner_b, "owner-b"),
            (rider_user, "rider-a"),
            (outsider, "outsider"),
        ):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"s4-03-b3-{label}-{uuid.uuid4()}@test.invalid"),
            )

        cur.execute("insert into businesses(name) values('S4-03 B3 Business A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-03 B3 Business B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values"
            "(%s,%s,'owner'),(%s,%s,'operator'),(%s,%s,'owner')",
            (business_a, owner_a, business_a, operator_a, business_b, owner_b),
        )
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) "
            "values(%s,%s,'B3 Rider A1',%s,'active') returning id",
            (business_a, rider_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider_a1 = cur.fetchone()[0]
        cur.execute(
            "insert into riders(business_id,name,phone,status) "
            "values(%s,'B3 Rider A2',%s,'active') returning id",
            (business_a, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider_a2 = cur.fetchone()[0]
        cur.execute(
            "insert into riders(business_id,name,phone,status) "
            "values(%s,'B3 Rider B',%s,'active') returning id",
            (business_b, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider_b = cur.fetchone()[0]
        cur.execute(
            "insert into orders(business_id,customer_name,customer_phone,delivery_address) "
            "values(%s,'B3 Customer B',%s,'B Address') returning id",
            (business_b, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        order_b = cur.fetchone()[0]

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),"
                "set_config('request.jwt.claim.role',%s,true)",
                (str(user_id), role),
            )
            if role == "authenticated":
                cur.execute("set local role authenticated")
            elif role == "anon":
                cur.execute("set local role anon")
            else:
                raise AssertionError(f"unsupported actor role: {role}")

        # Protected happy path still writes through SECURITY DEFINER functions.
        actor(owner_a)
        cur.execute("select create_delivery(%s,'B3 Customer A','+60120000000','A Address')", (business_a,))
        created = cur.fetchone()[0]
        order_a, token = created["order"]["id"], created["tracking_token"]
        cur.execute("select approve_order(%s)", (order_a,))
        cur.execute("select assign_rider(%s,%s)", (order_a, rider_a1))
        cur.execute("select (update_order_details(%s,p_notes=>%s)).notes", (order_a, "protected"))
        assert cur.fetchone()[0] == "protected"
        cur.execute("select (update_rider_details(%s,p_vehicle_plate=>%s)).vehicle_plate", (rider_a1, "B3-1"))
        assert cur.fetchone()[0] == "B3-1"
        cur.execute("select (reassign_rider(%s,%s)).assigned_rider_id", (order_a, rider_a2))
        assert cur.fetchone()[0] == rider_a2
        cur.execute("select (update_business_profile(%s,p_phone=>%s)).phone", (business_a, "+60121111111"))
        assert cur.fetchone()[0] == "+60121111111"
        cur.execute("select (update_team_member(%s,%s,p_status=>%s)).status", (business_a, operator_a, "inactive"))
        assert cur.fetchone()[0] == "inactive"
        cur.execute("select (update_team_member(%s,%s,p_status=>%s)).status", (business_a, operator_a, "active"))
        assert cur.fetchone()[0] == "active"

        # Owner cannot bypass contract-owned direct mutations, including hard DELETE.
        rejected(cur, "insert into orders(business_id,customer_name,customer_phone,delivery_address) values(%s,'Bypass','+1','X')", (business_a,))
        affects_zero(cur, "update orders set notes='bypass' where id=%s", (order_a,))
        affects_zero(cur, "update orders set delivery_status='delivered' where id=%s", (order_a,))
        affects_zero(cur, "delete from orders where id=%s", (order_a,))
        rejected(cur, "insert into riders(business_id,name,phone,status) values(%s,'Bypass','+2','active')", (business_a,))
        affects_zero(cur, "update riders set name='bypass' where id=%s", (rider_a1,))
        affects_zero(cur, "update riders set status='inactive' where id=%s", (rider_a1,))
        affects_zero(cur, "delete from riders where id=%s", (rider_a1,))
        rejected(cur, "insert into rider_assignments(business_id,rider_id) values(%s,%s)", (business_a, rider_a1))
        cur.execute("reset role")
        cur.execute("select id from rider_assignments where business_id=%s limit 1", (business_a,))
        assignment_a = cur.fetchone()[0]
        actor(owner_a)
        affects_zero(cur, "update rider_assignments set rider_id=%s where id=%s", (rider_a1, assignment_a))
        affects_zero(cur, "delete from rider_assignments where id=%s", (assignment_a,))

        # Business and authority boundaries remain enforced through protected contracts.
        actor(owner_b)
        rejected(cur, "select update_order_details(%s,p_notes=>%s)", (order_a, "cross"), "forbidden")
        rejected(cur, "select update_rider_details(%s,p_name=>%s)", (rider_a1, "cross"), "forbidden")
        affects_zero(cur, "update orders set notes='cross' where id=%s", (order_a,))
        affects_zero(cur, "update riders set name='cross' where id=%s", (rider_a1,))

        actor(operator_a)
        rejected(cur, "select deactivate_rider(%s)", (rider_a1,), "forbidden")
        rejected(cur, "select update_business_profile(%s,p_name=>%s)", (business_a, "forbidden"), "forbidden")
        rejected(cur, "select update_team_member(%s,%s,p_status=>%s)", (business_a, operator_a, "inactive"), "forbidden")

        # Rider sees only the assigned delivery and cannot mutate directly or cross businesses.
        actor(rider_user)
        cur.execute("select count(*) from orders where id=%s", (order_a,))
        assert cur.fetchone()[0] == 0  # reassigned to rider A2, which has no auth identity
        cur.execute("select count(*) from orders where id=%s", (order_b,))
        assert cur.fetchone()[0] == 0
        affects_zero(cur, "update orders set delivery_status='delivered' where id=%s", (order_a,))
        rejected(cur, "select rider_transition(%s,%s,'ready_for_pickup')", (rider_a1, order_b), "forbidden")

        # Public actors have no table scope; the tokenized contract remains their only read path.
        actor(outsider, "anon")
        cur.execute("select count(*) from orders where id in (%s,%s)", (order_a, order_b))
        assert cur.fetchone()[0] == 0
        cur.execute("select public_tracking(%s)", (token,))
        assert cur.fetchone()[0]["order_id"] == created["order"]["public_ref"]
        rejected(cur, "insert into orders(business_id,customer_name,customer_phone,delivery_address) values(%s,'Public','+3','X')", (business_a,))

        # Owner-only soft deactivation remains available; direct hard delete never did.
        actor(owner_a)
        cur.execute("select (deactivate_rider(%s)).status", (rider_a1,))
        assert cur.fetchone()[0] == "inactive"

        conn.rollback()

print("s4_03_batch_3_rls_ok")
