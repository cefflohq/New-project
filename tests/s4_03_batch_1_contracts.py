"""Rollback-based authorization tests for S4-03 Batch 1 contracts."""

import uuid

import psycopg

from environment_guard import TargetRefused, validate_database_target


def expect_rejected(cur, statement, params, expected):
    savepoint = f"rejected_{uuid.uuid4().hex}"
    cur.execute(f"savepoint {savepoint}")
    try:
        cur.execute(statement, params)
    except psycopg.Error as error:
        cur.execute(f"rollback to savepoint {savepoint}")
        assert expected in str(error), str(error)
    else:
        raise AssertionError(f"expected rejection containing {expected!r}")


try:
    target = validate_database_target(
        mutating=True,
        allowed_environments=frozenset({"local", "staging", "test"}),
    )
except TargetRefused as error:
    raise SystemExit(f"target_refused: {error}") from error

owner_a, operator_a, owner_b, rider_user = [uuid.uuid4() for _ in range(4)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in (
            (owner_a, "owner-a"),
            (operator_a, "operator-a"),
            (owner_b, "owner-b"),
            (rider_user, "rider-a"),
        ):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"s4-03-{label}-{uuid.uuid4()}@test.invalid"),
            )

        cur.execute("insert into businesses(name) values('S4-03 Business A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-03 Business B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values"
            "(%s,%s,'owner'),(%s,%s,'operator'),(%s,%s,'owner')",
            (business_a, owner_a, business_a, operator_a, business_b, owner_b),
        )
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) "
            "values(%s,%s,'Rider A1',%s,'active') returning id",
            (business_a, rider_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider_a1 = cur.fetchone()[0]
        cur.execute(
            "insert into riders(business_id,name,phone,status) "
            "values(%s,'Rider A2',%s,'active') returning id",
            (business_a, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider_a2 = cur.fetchone()[0]
        cur.execute(
            "insert into riders(business_id,name,phone,status) "
            "values(%s,'Rider B',%s,'active') returning id",
            (business_b, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider_b = cur.fetchone()[0]
        cur.execute(
            "insert into orders(business_id,customer_name,customer_phone,delivery_address) "
            "values(%s,'Customer A',%s,'Address A') returning id",
            (business_a, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        order_a = cur.fetchone()[0]
        cur.execute("insert into delivery_stops(business_id,order_id) values(%s,%s)", (business_a, order_a))

        def actor(user_id):
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),"
                "set_config('request.jwt.claim.role','authenticated',true)",
                (str(user_id),),
            )

        actor(owner_a)
        cur.execute(
            "select (update_business_profile(%s,p_name=>%s,p_phone=>%s,p_idempotency_key=>%s)).name",
            (business_a, "S4-03 Business A Updated", "+60123456789", "s4-03-audit"),
        )
        assert cur.fetchone()[0] == "S4-03 Business A Updated"
        cur.execute(
            "select actor_user_id,changed_fields,request_id from business_profile_audit "
            "where business_id=%s",
            (business_a,),
        )
        assert cur.fetchone() == (owner_a, ["name", "phone"], "s4-03-audit")
        cur.execute(
            "select column_name from information_schema.columns "
            "where table_schema='public' and table_name='business_profile_audit' order by ordinal_position"
        )
        assert [row[0] for row in cur.fetchall()] == [
            "id", "business_id", "actor_user_id", "changed_fields", "request_id", "created_at"
        ]

        cur.execute("select (update_rider_details(%s,p_name=>%s)).name", (rider_a1, "Owner Updated"))
        assert cur.fetchone()[0] == "Owner Updated"
        cur.execute("select (update_order_details(%s,p_notes=>%s)).notes", (order_a, "Owner note"))
        assert cur.fetchone()[0] == "Owner note"

        actor(operator_a)
        cur.execute("select (update_rider_details(%s,p_vehicle_plate=>%s)).vehicle_plate", (rider_a1, "OP-1"))
        assert cur.fetchone()[0] == "OP-1"
        cur.execute("select (update_order_details(%s,p_notes=>%s)).notes", (order_a, "Operator note"))
        assert cur.fetchone()[0] == "Operator note"
        expect_rejected(cur, "select deactivate_rider(%s)", (rider_a1,), "forbidden")
        expect_rejected(
            cur,
            "select update_team_member(%s,%s,p_status=>%s)",
            (business_a, operator_a, "inactive"),
            "forbidden",
        )
        expect_rejected(
            cur,
            "select update_business_profile(%s,p_name=>%s)",
            (business_a, "Forbidden"),
            "forbidden",
        )

        actor(owner_b)
        expect_rejected(cur, "select update_rider_details(%s,p_name=>%s)", (rider_a1, "Cross"), "forbidden")
        expect_rejected(cur, "select update_order_details(%s,p_notes=>%s)", (order_a, "Cross"), "forbidden")
        expect_rejected(cur, "select reassign_rider(%s,%s)", (order_a, rider_a2), "forbidden")

        actor(owner_a)
        expect_rejected(
            cur,
            "select update_team_member(%s,%s,p_role=>%s::member_role)",
            (business_a, owner_a, "operator"),
            "business must retain at least one active owner",
        )
        cur.execute(
            "select (update_team_member(%s,%s,p_status=>%s)).status",
            (business_a, operator_a, "inactive"),
        )
        assert cur.fetchone()[0] == "inactive"
        cur.execute(
            "select (update_team_member(%s,%s,p_status=>%s)).status",
            (business_a, operator_a, "active"),
        )
        assert cur.fetchone()[0] == "active"

        cur.execute("select approve_order(%s)", (order_a,))
        cur.execute("select assign_rider(%s,%s)", (order_a, rider_a1))
        cur.execute("select (reassign_rider(%s,%s)).assigned_rider_id", (order_a, rider_a2))
        assert cur.fetchone()[0] == rider_a2
        cur.execute("select rider_id from delivery_stops where order_id=%s", (order_a,))
        assert cur.fetchone()[0] == rider_a2
        expect_rejected(cur, "select reassign_rider(%s,%s)", (order_a, rider_b), "invalid rider")

        actor(operator_a)
        cur.execute("select (reassign_rider(%s,%s)).assigned_rider_id", (order_a, rider_a1))
        assert cur.fetchone()[0] == rider_a1

        cur.execute("update orders set delivery_status='ready_for_pickup' where id=%s", (order_a,))
        expect_rejected(
            cur,
            "select update_order_details(%s,p_notes=>%s)",
            (order_a, "Too late"),
            "order already dispatched",
        )

        actor(owner_a)
        cur.execute("select (deactivate_rider(%s)).status", (rider_a1,))
        assert cur.fetchone()[0] == "inactive"

        conn.rollback()

print("s4_03_batch_1_contracts_ok")
