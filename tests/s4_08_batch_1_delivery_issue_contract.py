"""Rollback-only S4-08 Batch-1 acceptance: authoritative delivery-issue
contract (vendor_report_delivery_issue / rider_report_delivery_issue) --
typed reason, real status transition, real audit event, cross-business/
cross-actor denial, invalid-transition denial, idempotent retry.
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


with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:

        def new_user(label):
            user_id = uuid.uuid4()
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"{label}-{uuid.uuid4()}@test.invalid"),
            )
            return user_id

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claim.role',%s,true)",
                (str(user_id) if user_id else "", role),
            )
            cur.execute(f"set local role {role}")

        # =====================================================================
        # Fixtures: two businesses (A, B), an Owner + Operator on A, an Owner
        # on B, one active Rider assigned+accepted on an order in each of A
        # and B, plus a second unassigned Rider on A (for the "not assigned"
        # denial case). Superuser-inserted directly, matching this suite's
        # established fixture-setup convention (e.g. s4_07 batch 1).
        # =====================================================================
        owner_a, operator_a, owner_b, rider_a_auth, rider_a2_auth, rider_b_auth, bystander = [
            new_user(label) for label in ("owner-a", "operator-a", "owner-b", "rider-a", "rider-a2", "rider-b", "bystander")
        ]

        cur.execute("insert into businesses(name) values('S4-08 B1 Business A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-08 B1 Business B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values(%s,%s,'owner'),(%s,%s,'operator'),(%s,%s,'owner')",
            (business_a, owner_a, business_a, operator_a, business_b, owner_b),
        )

        def new_rider(business_id, auth_user_id, label):
            cur.execute(
                "insert into riders(business_id,auth_user_id,name,phone,status) values(%s,%s,%s,%s,'active') returning id",
                (business_id, auth_user_id, label, f"+601{uuid.uuid4().int % 10**8:08d}"),
            )
            return cur.fetchone()[0]

        rider_a = new_rider(business_a, rider_a_auth, "Rider A")
        rider_a2 = new_rider(business_a, rider_a2_auth, "Rider A2 (unassigned)")
        rider_b = new_rider(business_b, rider_b_auth, "Rider B")

        def new_order_with_accepted_assignment(business_id, rider_id):
            cur.execute("reset role")
            cur.execute(
                "insert into orders(business_id,customer_name,customer_phone,delivery_address,assigned_rider_id) "
                "values(%s,'Test Customer','+60123456789','1 Test Street',%s) returning id",
                (business_id, rider_id),
            )
            order_id = cur.fetchone()[0]
            cur.execute(
                "insert into rider_assignments(business_id,rider_id,status) values(%s,%s,'accepted') returning id",
                (business_id, rider_id),
            )
            assignment_id = cur.fetchone()[0]
            cur.execute(
                "insert into delivery_stops(business_id,order_id,assignment_id,rider_id) values(%s,%s,%s,%s)",
                (business_id, order_id, assignment_id, rider_id),
            )
            return order_id

        order_a = new_order_with_accepted_assignment(business_a, rider_a)
        order_b = new_order_with_accepted_assignment(business_b, rider_b)

        # =====================================================================
        # POSITIVE 1-4: authorized Vendor (Operator, not just Owner -- matches
        # create_delivery/assign_rider's "any member" precedent) reports a
        # real typed issue; authoritative status + typed reason + audit event.
        # =====================================================================
        actor(operator_a)
        cur.execute(
            "select delivery_status from vendor_report_delivery_issue(%s,'customer_unreachable','Called 3 times, no answer')",
            (order_a,),
        )
        assert cur.fetchone()[0] == "issue", "delivery_status must become 'issue' authoritatively"

        cur.execute("reset role")
        cur.execute("select delivery_status from orders where id=%s", (order_a,))
        assert cur.fetchone()[0] == "issue", "the row itself, read back with no actor context, must show 'issue'"
        cur.execute("select status from delivery_stops where order_id=%s", (order_a,))
        assert cur.fetchone()[0] == "issue", "delivery_stops.status must stay in sync with orders.delivery_status"

        cur.execute(
            "select event_type,from_status,to_status,actor_role,metadata from delivery_events "
            "where order_id=%s and event_type='delivery.issue_reported' order by created_at desc limit 1",
            (order_a,),
        )
        event_type, from_status, to_status, actor_role, metadata = cur.fetchone()
        assert event_type == "delivery.issue_reported"
        assert from_status == "created" and to_status == "issue"
        assert actor_role == "vendor"
        assert metadata["reason_type"] == "customer_unreachable"
        assert metadata["note"] == "Called 3 times, no answer"

        # =====================================================================
        # POSITIVE 5: authorized assigned+accepted Rider reports an issue on
        # their own order in a fresh business (order_b, untouched so far).
        # =====================================================================
        actor(rider_b_auth)
        cur.execute(
            "select delivery_status from rider_report_delivery_issue(%s,%s,'access_problem',null)",
            (rider_b, order_b),
        )
        assert cur.fetchone()[0] == "issue"
        cur.execute("reset role")
        cur.execute(
            "select actor_role,metadata->>'reason_type' from delivery_events "
            "where order_id=%s and event_type='delivery.issue_reported'",
            (order_b,),
        )
        assert cur.fetchone() == ("rider", "access_problem")

        # =====================================================================
        # NEGATIVE 6: anonymous denied at the grant layer (not merely the
        # internal check) -- matches the FOUNDR RPC grant-hardening standard.
        # =====================================================================
        actor(None, "anon")
        rejected(cur, "select vendor_report_delivery_issue(%s,'vendor_not_ready',null)", (order_b,))
        rejected(cur, "select rider_report_delivery_issue(%s,%s,'vendor_not_ready',null)", (rider_b, order_b))

        # =====================================================================
        # NEGATIVE 7-8: unrelated authenticated user denied; cross-business
        # Vendor (Owner of B) denied on an order belonging to A.
        # =====================================================================
        actor(bystander)
        rejected(cur, "select vendor_report_delivery_issue(%s,'vendor_not_ready',null)", (order_a,), "forbidden")

        actor(owner_b)
        rejected(cur, "select vendor_report_delivery_issue(%s,'vendor_not_ready',null)", (order_a,), "forbidden")

        # =====================================================================
        # NEGATIVE 9-10: cross-business Rider (genuinely their own identity,
        # but that Rider is not assigned to this order) denied 'forbidden';
        # a genuine Rider of the SAME business who is simply not assigned to
        # this order is denied the same way. A bystander who is not any
        # Rider at all, impersonating a real rider_id in the call, is denied
        # 'invalid rider context' (the identity check itself, distinct from
        # the assignment check).
        # =====================================================================
        actor(rider_b_auth)
        rejected(cur, "select rider_report_delivery_issue(%s,%s,'vendor_not_ready',null)", (rider_b, order_a), "forbidden")

        actor(rider_a2_auth)
        rejected(cur, "select rider_report_delivery_issue(%s,%s,'vendor_not_ready',null)", (rider_a2, order_a), "forbidden")

        actor(bystander)
        rejected(cur, "select rider_report_delivery_issue(%s,%s,'vendor_not_ready',null)", (rider_a, order_a), "invalid rider context")

        # =====================================================================
        # NEGATIVE 11: nonexistent target denied.
        # =====================================================================
        actor(owner_a)
        rejected(cur, "select vendor_report_delivery_issue(%s,'vendor_not_ready',null)", (uuid.uuid4(),), "forbidden")

        # =====================================================================
        # NEGATIVE 12-13: terminal states never regress into 'issue'. A fresh
        # order per case, superuser-forced into the terminal state (no RPC
        # produces 'cancelled' at all -- confirmed by the audit this
        # migration responds to -- so this is the only honest way to
        # construct that fixture).
        # =====================================================================
        delivered_order = new_order_with_accepted_assignment(business_a, rider_a)
        cur.execute("reset role")
        cur.execute("update orders set delivery_status='delivered' where id=%s", (delivered_order,))
        actor(owner_a)
        rejected(cur, "select vendor_report_delivery_issue(%s,'vendor_not_ready',null)", (delivered_order,), "invalid transition")

        cancelled_order = new_order_with_accepted_assignment(business_a, rider_a)
        cur.execute("reset role")
        cur.execute("update orders set delivery_status='cancelled' where id=%s", (cancelled_order,))
        actor(owner_a)
        rejected(cur, "select vendor_report_delivery_issue(%s,'vendor_not_ready',null)", (cancelled_order,), "invalid transition")

        # =====================================================================
        # NEGATIVE 14: an invalid (non-enum) reason type is rejected by
        # Postgres itself before the function body ever runs -- genuine type
        # safety, not app-level string validation.
        # =====================================================================
        actor(owner_a)
        rejected(cur, "select vendor_report_delivery_issue(%s,'not_a_real_reason',null)", (order_a,))

        # =====================================================================
        # POSITIVE/NEGATIVE 15: duplicate/retry is a safe idempotent no-op --
        # same status, and critically no second audit event is created.
        # =====================================================================
        actor(owner_a)
        cur.execute(
            "select count(*) from delivery_events where order_id=%s and event_type='delivery.issue_reported'",
            (order_a,),
        )
        before_count = cur.fetchone()[0]
        cur.execute("select delivery_status from vendor_report_delivery_issue(%s,'address_problem','retry attempt')", (order_a,))
        assert cur.fetchone()[0] == "issue", "repeat call on an already-issue order must stay 'issue', not error"
        cur.execute(
            "select count(*) from delivery_events where order_id=%s and event_type='delivery.issue_reported'",
            (order_a,),
        )
        assert cur.fetchone()[0] == before_count, "an already-issue retry must not create a duplicate audit event"

        conn.rollback()

# =====================================================================
# SECURITY 16: no unintended PUBLIC/anon EXECUTE remains on either new
# function -- checked in its own short-lived connection/transaction so the
# preceding rollback cannot mask a real grant-table state.
# =====================================================================
with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        cur.execute(
            "select routine_name,grantee from information_schema.role_routine_grants "
            "where routine_schema='public' and routine_name in "
            "('vendor_report_delivery_issue','rider_report_delivery_issue') "
            "and grantee not in ('postgres','service_role')"
        )
        grants = sorted(cur.fetchall())
        assert grants == [
            ("rider_report_delivery_issue", "authenticated"),
            ("vendor_report_delivery_issue", "authenticated"),
        ], f"unexpected grant surface: {grants}"
    conn.rollback()

print("s4_08_batch_1_delivery_issue_contract_ok")
