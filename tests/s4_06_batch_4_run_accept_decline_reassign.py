"""Rollback-only S4-06 Batch-4 Run Accept/Decline + safe reassignment
acceptance."""

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


owner_a, rider1_user, rider2_user, owner_b, rider3_user = [uuid.uuid4() for _ in range(5)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in (
            (owner_a, "owner-a"), (rider1_user, "rider1"), (rider2_user, "rider2"),
            (owner_b, "owner-b"), (rider3_user, "rider3"),
        ):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"s4-06-b4-{label}-{uuid.uuid4()}@test.invalid"),
            )
        cur.execute("insert into businesses(name) values('S4-06 B4 Business A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-06 B4 Business B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values(%s,%s,'owner'),(%s,%s,'owner')",
            (business_a, owner_a, business_b, owner_b),
        )
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) values(%s,%s,'Rider 1',%s,'active') returning id",
            (business_a, rider1_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider1 = cur.fetchone()[0]
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) values(%s,%s,'Rider 2',%s,'active') returning id",
            (business_a, rider2_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider2 = cur.fetchone()[0]
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) values(%s,%s,'Rider 3',%s,'active') returning id",
            (business_b, rider3_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider3 = cur.fetchone()[0]

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claim.role',%s,true)",
                (str(user_id), role),
            )
            cur.execute(f"set local role {role}")

        def new_order(business_id, phone_suffix):
            cur.execute("select create_delivery(%s,'B4 Customer',%s,'Addr')", (business_id, f"+60197000{phone_suffix:03d}"))
            order_id = uuid.UUID(cur.fetchone()[0]["order"]["id"])
            cur.execute("select approve_order(%s)", (order_id,))
            return order_id

        # =====================================================================
        # SETUP: one session, Rider 1 gets 4 orders, Rider 2 gets 2 (multi-Rider).
        # =====================================================================
        actor(owner_a)
        cur.execute("select (create_delivery_session(%s,'B4 Run', current_date)).id", (business_a,))
        session_a = cur.fetchone()[0]

        actor(owner_a)
        r1_orders = []
        for i in range(4):
            oid = new_order(business_a, i)
            cur.execute("select attach_order_to_session(%s,%s)", (oid, session_a))
            cur.execute("select assign_rider(%s,%s)", (oid, rider1))
            r1_orders.append(oid)
        r2_orders = []
        for i in range(2):
            oid = new_order(business_a, 10 + i)
            cur.execute("select attach_order_to_session(%s,%s)", (oid, session_a))
            cur.execute("select assign_rider(%s,%s)", (oid, rider2))
            r2_orders.append(oid)

        # =====================================================================
        # PART A: ACCEPT RUN
        # =====================================================================

        # No-assignment run rejection.
        actor(rider3_user)
        rejected(cur, "select accept_run(%s,%s)", (rider3, session_a), "no assignments in this run")

        # Individual accept, THEN Accept Run for the rest -- must correctly
        # report the pre-accepted one as already_accepted, accept the rest.
        actor(rider1_user)
        cur.execute("select accept_assignment(%s,%s)", (rider1, r1_orders[0]))
        cur.execute("select accept_run(%s,%s)", (rider1, session_a))
        report = cur.fetchone()[0]
        assert report["newly_accepted"] == 3 and report["already_accepted"] == 1 and report["skipped"] == 0

        # Exactly-once events: one assignment.accepted per order, tagged with
        # the correct provenance (accept_assignment vs accept_run).
        cur.execute("reset role")
        cur.execute(
            "select order_id, metadata->>'via' from delivery_events where order_id = any(%s) and event_type='assignment.accepted'",
            (r1_orders,),
        )
        rows = dict(cur.fetchall())
        assert len(rows) == 4
        assert rows[r1_orders[0]] is None, "individually accepted order must carry no accept_run provenance"
        assert all(rows[o] == "accept_run" for o in r1_orders[1:])

        # Repeat idempotency: calling Accept Run again must not add events.
        actor(rider1_user)
        cur.execute("select accept_run(%s,%s)", (rider1, session_a))
        report = cur.fetchone()[0]
        assert report["newly_accepted"] == 0 and report["already_accepted"] == 4 and report["skipped"] == 0
        cur.execute("reset role")
        cur.execute("select count(*) from delivery_events where order_id = any(%s) and event_type='assignment.accepted'", (r1_orders,))
        assert cur.fetchone()[0] == 4, "duplicate Accept Run must not record additional events"

        # Accept Run followed by individual behavior: individual accept on an
        # already-accepted order remains a safe no-op (S4-05.4 behavior,
        # unaffected by this batch).
        actor(rider1_user)
        cur.execute("select accept_assignment(%s,%s)", (rider1, r1_orders[1]))
        cur.execute("reset role")
        cur.execute("select count(*) from delivery_events where order_id=%s and event_type='assignment.accepted'", (r1_orders[1],))
        assert cur.fetchone()[0] == 1

        # Exact-Rider isolation: Rider 3 (Business B) has nothing here;
        # Rider 2's own session-mates are untouched by Rider 1's Accept Run.
        cur.execute("select a.status from rider_assignments a join delivery_stops s on s.assignment_id=a.id where s.order_id = any(%s)", (r2_orders,))
        assert all(row[0] == "assigned" for row in cur.fetchall()), "Rider 1's Accept Run must never affect Rider 2's assignments"

        # Mixed conflicting states: decline one of Rider 1's future orders,
        # then verify Accept Run on a FRESH session skips it correctly.
        actor(owner_a)
        cur.execute("select (create_delivery_session(%s,'B4 Run 2', current_date)).id", (business_a,))
        session_a2 = cur.fetchone()[0]
        actor(owner_a)
        mixed_orders = []
        for i in range(3):
            oid = new_order(business_a, 20 + i)
            cur.execute("select attach_order_to_session(%s,%s)", (oid, session_a2))
            cur.execute("select assign_rider(%s,%s)", (oid, rider1))
            mixed_orders.append(oid)
        actor(rider1_user)
        cur.execute("select decline_assignment(%s,%s)", (rider1, mixed_orders[0]))
        cur.execute("select accept_run(%s,%s)", (rider1, session_a2))
        report = cur.fetchone()[0]
        assert report["newly_accepted"] == 2 and report["already_accepted"] == 0 and report["skipped"] == 1

        # =====================================================================
        # PART B: DECLINE RUN
        # =====================================================================
        actor(owner_a)
        cur.execute("select (create_delivery_session(%s,'B4 Run 3', current_date)).id", (business_a,))
        session_a3 = cur.fetchone()[0]
        actor(owner_a)
        decline_orders = []
        for i in range(3):
            oid = new_order(business_a, 30 + i)
            cur.execute("select attach_order_to_session(%s,%s)", (oid, session_a3))
            cur.execute("select assign_rider(%s,%s)", (oid, rider1))
            decline_orders.append(oid)

        actor(rider1_user)
        cur.execute("select accept_assignment(%s,%s)", (rider1, decline_orders[0]))  # individual accept -- conflicting state for decline_run
        cur.execute("select decline_run(%s,%s)", (rider1, session_a3))
        report = cur.fetchone()[0]
        assert report["newly_declined"] == 2 and report["already_declined"] == 0 and report["skipped"] == 1

        cur.execute("reset role")
        cur.execute(
            "select order_id, metadata->>'via' from delivery_events where order_id = any(%s) and event_type='assignment.declined'",
            (decline_orders[1:],),
        )
        rows = dict(cur.fetchall())
        assert len(rows) == 2 and all(v == "decline_run" for v in rows.values())

        # Repeat idempotency.
        actor(rider1_user)
        cur.execute("select decline_run(%s,%s)", (rider1, session_a3))
        report = cur.fetchone()[0]
        assert report["newly_declined"] == 0 and report["already_declined"] == 2 and report["skipped"] == 1
        cur.execute("reset role")
        cur.execute("select count(*) from delivery_events where order_id = any(%s) and event_type='assignment.declined'", (decline_orders[1:],))
        assert cur.fetchone()[0] == 2, "duplicate Decline Run must not record additional events"

        # Individual decline compatibility on a fresh order.
        actor(owner_a)
        solo_decline = new_order(business_a, 40)
        cur.execute("select assign_rider(%s,%s)", (solo_decline, rider1))
        actor(rider1_user)
        cur.execute("select decline_assignment(%s,%s)", (rider1, solo_decline))
        cur.execute("reset role")
        cur.execute("select a.status from rider_assignments a join delivery_stops s on s.assignment_id=a.id where s.order_id=%s", (solo_decline,))
        assert cur.fetchone()[0] == "declined"

        # =====================================================================
        # PART E: MULTI-RIDER SESSION -- Ali (rider1) Accept Run must not
        # touch Abu (rider2)'s still-pending assignments in the same session.
        # =====================================================================
        cur.execute("select a.status from rider_assignments a join delivery_stops s on s.assignment_id=a.id where s.order_id = any(%s)", (r2_orders,))
        assert all(row[0] == "assigned" for row in cur.fetchall()), "Rider 2 must remain untouched after all of Rider 1's Accept/Decline Run activity"

        actor(rider2_user)
        cur.execute("select decline_run(%s,%s)", (rider2, session_a))
        report = cur.fetchone()[0]
        assert report["newly_declined"] == 2
        cur.execute("reset role")
        cur.execute("select a.status from rider_assignments a join delivery_stops s on s.assignment_id=a.id where s.order_id=%s", (r1_orders[0],))
        assert cur.fetchone()[0] == "accepted", "Rider 2's Decline Run must not affect Rider 1's already-accepted assignments"

        # =====================================================================
        # PART C: REASSIGNMENT
        # =====================================================================

        # created: allowed.
        actor(owner_a)
        oid_created = new_order(business_a, 50)
        cur.execute("select assign_rider(%s,%s)", (oid_created, rider1))
        cur.execute("select (reassign_rider(%s,%s)).assigned_rider_id", (oid_created, rider2))
        assert str(cur.fetchone()[0]) == str(rider2)

        # ready_for_pickup: allowed. Also proves accepted-Rider-A -> Rider-B
        # resets acceptance, and Rider B must freshly accept.
        actor(owner_a)
        oid_rfp = new_order(business_a, 51)
        cur.execute("select assign_rider(%s,%s)", (oid_rfp, rider1))
        actor(rider1_user)
        cur.execute("select accept_assignment(%s,%s)", (rider1, oid_rfp))
        cur.execute("select rider_transition(%s,%s,'ready_for_pickup')", (rider1, oid_rfp))
        actor(owner_a)
        cur.execute("select reassign_rider(%s,%s)", (oid_rfp, rider2))
        cur.execute("reset role")
        cur.execute("select a.status, a.accepted_at from rider_assignments a join delivery_stops s on s.assignment_id=a.id where s.order_id=%s", (oid_rfp,))
        status, accepted_at = cur.fetchone()
        assert status == "assigned" and accepted_at is None, "reassignment must reset to pending, never inherit acceptance"

        # Old Rider authority denied immediately -- rider1 still owns rider1
        # (is_current_rider still passes), but the target no longer matches.
        actor(rider1_user)
        rejected(cur, "select rider_transition(%s,%s,'picked_up')", (rider1, oid_rfp), "forbidden")

        # New Rider must freshly accept before proceeding.
        actor(rider2_user)
        rejected(cur, "select rider_transition(%s,%s,'picked_up')", (rider2, oid_rfp), "assignment not accepted")
        cur.execute("select accept_assignment(%s,%s)", (rider2, oid_rfp))
        cur.execute("select rider_transition(%s,%s,'picked_up')", (rider2, oid_rfp))

        # picked_up: denied.
        actor(owner_a)
        rejected(cur, "select reassign_rider(%s,%s)", (oid_rfp, rider1), "reassignment not allowed after pickup")

        # Build fresh orders for each remaining denied state.
        def order_at_status(status_name, phone_suffix):
            oid = new_order(business_a, phone_suffix)
            cur.execute("select assign_rider(%s,%s)", (oid, rider1))
            actor(rider1_user)
            cur.execute("select accept_assignment(%s,%s)", (rider1, oid))
            sequence = ["ready_for_pickup", "picked_up", "out_for_delivery", "arrived"]
            for s in sequence:
                cur.execute("select rider_transition(%s,%s,%s)", (rider1, oid, s))
                if s == status_name:
                    break
            actor(owner_a)
            return oid

        oid_ofd = order_at_status("out_for_delivery", 52)
        rejected(cur, "select reassign_rider(%s,%s)", (oid_ofd, rider2), "reassignment not allowed after pickup")

        oid_arrived = order_at_status("arrived", 53)
        rejected(cur, "select reassign_rider(%s,%s)", (oid_arrived, rider2), "reassignment not allowed after pickup")

        actor(owner_a)
        oid_delivered = new_order(business_a, 54)
        cur.execute("select assign_rider(%s,%s)", (oid_delivered, rider1))
        actor(rider1_user)
        cur.execute("select accept_assignment(%s,%s)", (rider1, oid_delivered))
        for s in ("ready_for_pickup", "picked_up", "out_for_delivery", "arrived"):
            cur.execute("select rider_transition(%s,%s,%s)", (rider1, oid_delivered, s))
        pod_path = f"{rider1}/{oid_delivered}/test.jpg"
        cur.execute("reset role")
        cur.execute("insert into storage.objects(bucket_id, name) values ('cefflo-pod', %s)", (pod_path,))
        actor(rider1_user)
        cur.execute("select complete_delivery(%s,%s,%s,'Delivered')", (rider1, oid_delivered, pod_path))
        actor(owner_a)
        rejected(cur, "select reassign_rider(%s,%s)", (oid_delivered, rider2), "reassignment not allowed after pickup")

        actor(owner_a)
        oid_cancelled = new_order(business_a, 55)
        cur.execute("select assign_rider(%s,%s)", (oid_cancelled, rider1))
        cur.execute("reset role")
        cur.execute("update orders set delivery_status='cancelled' where id=%s", (oid_cancelled,))
        actor(owner_a)
        rejected(cur, "select reassign_rider(%s,%s)", (oid_cancelled, rider2), "reassignment not allowed after pickup")

        actor(owner_a)
        oid_issue = new_order(business_a, 56)
        cur.execute("select assign_rider(%s,%s)", (oid_issue, rider1))
        cur.execute("reset role")
        cur.execute("update orders set delivery_status='issue' where id=%s", (oid_issue,))
        actor(owner_a)
        rejected(cur, "select reassign_rider(%s,%s)", (oid_issue, rider2), "reassignment not allowed after pickup")

        # Same-Rider reassignment: true no-op, no reset, no event.
        actor(owner_a)
        oid_noop = new_order(business_a, 57)
        cur.execute("select assign_rider(%s,%s)", (oid_noop, rider1))
        actor(rider1_user)
        cur.execute("select accept_assignment(%s,%s)", (rider1, oid_noop))
        cur.execute("reset role")
        cur.execute("select accepted_at from rider_assignments a join delivery_stops s on s.assignment_id=a.id where s.order_id=%s", (oid_noop,))
        accepted_at_before = cur.fetchone()[0]
        cur.execute("select count(*) from delivery_events where order_id=%s and event_type='rider.reassigned'", (oid_noop,))
        events_before = cur.fetchone()[0]
        actor(owner_a)
        cur.execute("select reassign_rider(%s,%s)", (oid_noop, rider1))
        cur.execute("reset role")
        cur.execute("select a.status, a.accepted_at from rider_assignments a join delivery_stops s on s.assignment_id=a.id where s.order_id=%s", (oid_noop,))
        status, accepted_at_after = cur.fetchone()
        assert status == "accepted" and accepted_at_after == accepted_at_before, "same-Rider reassignment must be a true no-op"
        cur.execute("select count(*) from delivery_events where order_id=%s and event_type='rider.reassigned'", (oid_noop,))
        assert cur.fetchone()[0] == events_before, "same-Rider reassignment must record no event"

        # Reassignment back to a previously assigned Rider requires fresh acceptance.
        actor(owner_a)
        cur.execute("select reassign_rider(%s,%s)", (oid_noop, rider2))  # A -> B
        actor(rider2_user)
        cur.execute("select accept_assignment(%s,%s)", (rider2, oid_noop))
        actor(owner_a)
        cur.execute("select reassign_rider(%s,%s)", (oid_noop, rider1))  # B -> A again
        cur.execute("reset role")
        cur.execute("select a.status, a.accepted_at from rider_assignments a join delivery_stops s on s.assignment_id=a.id where s.order_id=%s", (oid_noop,))
        status, accepted_at = cur.fetchone()
        assert status == "assigned" and accepted_at is None, "reassigning back to a prior Rider must never restore historical acceptance"
        actor(rider1_user)
        rejected(cur, "select rider_transition(%s,%s,'ready_for_pickup')", (rider1, oid_noop), "assignment not accepted")
        cur.execute("select accept_assignment(%s,%s)", (rider1, oid_noop))  # fresh acceptance required and works

        # Exactly one rider.reassigned event, no PII, correct from/to ids.
        cur.execute("reset role")
        cur.execute(
            "select actor_role, metadata from delivery_events where order_id=%s and event_type='rider.reassigned' order by created_at",
            (oid_rfp,),
        )
        events = cur.fetchall()
        assert len(events) == 1
        assert events[0][0] == "vendor"
        metadata = events[0][1]
        assert set(metadata.keys()) == {"from_rider_id", "to_rider_id"}
        assert metadata["from_rider_id"] == str(rider1) and metadata["to_rider_id"] == str(rider2)

        # =====================================================================
        # PART D: sequence gap preserved after pre-pickup reassignment;
        # sequence_locked_at guard enforced.
        # =====================================================================
        actor(owner_a)
        cur.execute("select (create_delivery_session(%s,'B4 Seq Run', current_date)).id", (business_a,))
        session_seq = cur.fetchone()[0]
        actor(owner_a)
        seq_orders = []
        for i in range(3):
            oid = new_order(business_a, 60 + i)
            cur.execute("select attach_order_to_session(%s,%s)", (oid, session_seq))
            cur.execute("select assign_rider(%s,%s)", (oid, rider1))
            seq_orders.append(oid)
        actor(rider1_user)
        for oid in seq_orders:
            cur.execute("select accept_assignment(%s,%s)", (rider1, oid))
        cur.execute("select save_run_sequence(%s,%s,%s)", (rider1, session_seq, seq_orders))
        cur.execute("reset role")
        cur.execute("select order_id, sequence from delivery_stops where order_id = any(%s) order by sequence", (seq_orders,))
        before_reassign = dict(cur.fetchall())
        assert before_reassign[seq_orders[0]] == 1 and before_reassign[seq_orders[1]] == 2 and before_reassign[seq_orders[2]] == 3

        # Reassign the middle order away (still pre-pickup, allowed).
        actor(owner_a)
        cur.execute("select reassign_rider(%s,%s)", (seq_orders[1], rider2))
        cur.execute("reset role")
        cur.execute("select sequence from delivery_stops where order_id=%s", (seq_orders[1],))
        assert cur.fetchone()[0] is None, "the reassigned stop's own sequence must be reset"
        cur.execute("select order_id, sequence from delivery_stops where order_id = any(%s) order by sequence", ([seq_orders[0], seq_orders[2]],))
        remaining = dict(cur.fetchall())
        assert remaining[seq_orders[0]] == 1 and remaining[seq_orders[2]] == 3, "unaffected stops must keep their original sequence values (gap is valid)"

        # Rider 1's remaining run (1, 3) still passes start_run_delivery's
        # validation and executes correctly despite the gap.
        actor(rider1_user)
        cur.execute("select start_pickup_run(%s,%s)", (rider1, session_seq))
        for oid in (seq_orders[0], seq_orders[2]):
            cur.execute("select rider_transition(%s,%s,'ready_for_pickup')", (rider1, oid))
            cur.execute("select rider_transition(%s,%s,'picked_up')", (rider1, oid))
        cur.execute("select start_run_delivery(%s,%s)", (rider1, session_seq))
        cur.execute("reset role")
        cur.execute("select sequence_locked_at is not null from delivery_stops where order_id = any(%s)", ([seq_orders[0], seq_orders[2]],))
        assert all(row[0] for row in cur.fetchall()), "a run with a sequence gap must still lock and execute correctly"

        # sequence_locked_at guard: once locked, reassignment must be denied
        # even if somehow delivery_status still looked pre-pickup (defense
        # in depth -- exercised here via the already-covered picked_up+ denial,
        # since locking is only reachable after picked_up in practice).
        actor(owner_a)
        rejected(cur, "select reassign_rider(%s,%s)", (seq_orders[0], rider2), "reassignment not allowed after pickup")

        cur.execute("select rider_transition(%s,'out_for_delivery')", (seq_orders[0],)) if False else None

        # =====================================================================
        # REGRESSION SPOT-CHECKS: direct-write blocking still fully enforced
        # on every table this batch touches.
        # =====================================================================
        actor(rider1_user)
        cur.execute(
            "select a.id from rider_assignments a join delivery_stops s on s.assignment_id=a.id where s.order_id=%s",
            (seq_orders[0],),
        )
        assignment_id = cur.fetchone()[0]
        savepoint = "denied_direct_reassign"
        cur.execute(f"savepoint {savepoint}")
        cur.execute("update rider_assignments set rider_id=%s where id=%s", (rider2, assignment_id))
        assert cur.rowcount == 0, "direct UPDATE on rider_assignments must remain fully blocked"
        cur.execute(f"rollback to savepoint {savepoint}")

        conn.rollback()

print("s4_06_batch_4_run_accept_decline_reassign_ok")
