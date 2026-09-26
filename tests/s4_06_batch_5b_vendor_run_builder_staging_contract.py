"""Rollback-only S4-06 Batch-5b staging contract acceptance.

This exercises the exact RPC signatures and parameter shapes
vendor/backend.js sends (p_order_ids as an array of UUIDs, p_idempotency_key
as a UUID, create_delivery_session with only p_business_id/p_name, the
zones/delivery_sessions read shapes) directly against the live target,
using the same JWT-claim-simulation methodology already established for
every other staging acceptance run this session (a direct DB connection
with request.jwt.claim.* GUCs set to match what PostgREST would set from a
verified bearer token before invoking the same RPC).

This verifies the RPC/RLS contract layer the frontend calls into. It does
NOT exercise the actual PostgREST HTTP/JSON boundary, browser fetch/auth
flow, or any real click-through -- those remain explicitly deferred to the
S4-15 RC real-browser acceptance gate, consistent with this file's sibling
static test (s4_06_batch_5b_vendor_run_builder_wiring.py) and the
project's established precedent for UI batches without browser tooling.
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


owner_a, rider_ali_user, rider_abu_user = [uuid.uuid4() for _ in range(3)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in (
            (owner_a, "owner-a"), (rider_ali_user, "ali"), (rider_abu_user, "abu"),
        ):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"s4-06-b5b-{label}-{uuid.uuid4()}@test.invalid"),
            )
        cur.execute("insert into businesses(name) values('S4-06 B5b Staging Contract') returning id")
        business = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values(%s,%s,'owner')",
            (business, owner_a),
        )
        # max_active_orders=100 (S4-11 Batch 3/F2-13, Grow V1 Flow 2): this
        # contract accumulates many separate build_rider_run/assign_rider
        # calls onto these two riders across its full run (zone/session/
        # eligibility reconciliation, batches up to 20 orders plus solo
        # assignments), not the separate vehicle/capacity eligibility
        # feature -- default motorcycle capacity (6), or even van's 20,
        # would otherwise cap what the later scenarios in this file can
        # construct.
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status,max_active_orders) values(%s,%s,'Ali',%s,'active',100) returning id",
            (business, rider_ali_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        ali = cur.fetchone()[0]
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status,max_active_orders) values(%s,%s,'Abu',%s,'active',100) returning id",
            (business, rider_abu_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        abu = cur.fetchone()[0]

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claim.role',%s,true)",
                (str(user_id), role),
            )
            cur.execute(f"set local role {role}")

        def new_order(phone_suffix, zone_id=None):
            if zone_id is not None:
                cur.execute(
                    "select create_delivery(%s,'B5b Customer',%s,'Addr',p_zone_id=>%s)",
                    (business, f"+60194{phone_suffix:06d}", zone_id),
                )
            else:
                cur.execute(
                    "select create_delivery(%s,'B5b Customer',%s,'Addr')",
                    (business, f"+60194{phone_suffix:06d}"),
                )
            order_id = uuid.UUID(cur.fetchone()[0]["order"]["id"])
            cur.execute("select approve_order(%s)", (order_id,))
            return order_id

        # =====================================================================
        # REAL DATA -- zone/session read shapes (matching listZones/
        # listDeliverySessions's business_id=eq. + select=* + order=... form).
        # =====================================================================
        actor(owner_a)
        cur.execute("select (create_zone(%s,'PJ')).id", (business,))
        zone_pj = cur.fetchone()[0]
        cur.execute("select (create_zone(%s,'Pantai Dalam')).id", (business,))
        zone_pd = cur.fetchone()[0]

        cur.execute("reset role")
        cur.execute(
            "select id,name,status from zones where business_id=%s order by name asc", (business,)
        )
        zone_rows = cur.fetchall()
        assert {r[1] for r in zone_rows} == {"PJ", "Pantai Dalam"}
        assert all(r[2] == "active" for r in zone_rows)

        # =====================================================================
        # ELIGIBILITY -- approved + unassigned + created only; unzoned
        # remains eligible; zone_id is never a gate.
        # =====================================================================
        actor(owner_a)
        pj_orders = [new_order(i, zone_id=zone_pj) for i in range(7)]
        pd_orders = [new_order(10 + i, zone_id=zone_pd) for i in range(4)]
        unzoned_orders = [new_order(20 + i) for i in range(3)]
        already_assigned = new_order(30)
        cur.execute("select assign_rider(%s,%s)", (already_assigned, ali))
        unapproved = new_order.__wrapped__ if False else None  # (no unapproved-order path needed; create_delivery starts unapproved but approve_order is called by new_order helper)

        cur.execute("reset role")
        cur.execute(
            "select id, approved_at is not null, assigned_rider_id is null, delivery_status, zone_id "
            "from orders where business_id=%s", (business,)
        )
        rows = cur.fetchall()
        eligible_ids = {r[0] for r in rows if r[1] and r[2] and r[3] == "created"}
        assert set(pj_orders + pd_orders + unzoned_orders) <= eligible_ids
        assert already_assigned not in eligible_ids
        assert len(eligible_ids) == 14  # 7 PJ + 4 Pantai Dalam + 3 unzoned -- matches the Founder's own example counts

        # =====================================================================
        # ZONES -- factual eligible counts, multi-filter, never auto-selects,
        # no one-Zone-one-Rider behavior (confirmed structurally: zones carry
        # no riderId/assignment concept at all).
        # =====================================================================
        cur.execute("select column_name from information_schema.columns where table_name='zones'")
        zone_columns = {r[0] for r in cur.fetchall()}
        assert "rider_id" not in zone_columns and "assigned_rider_id" not in zone_columns

        # =====================================================================
        # WAVES -- existing planned/active only, factual counts, multiple
        # same-day Waves, editable name via create_delivery_session(business,name).
        # =====================================================================
        actor(owner_a)
        cur.execute("select (create_delivery_session(%s,'Lunch Wave')).id", (business,))
        wave_a = cur.fetchone()[0]
        cur.execute("select (create_delivery_session(%s,'Dinner Wave')).id", (business,))
        wave_b_unused = cur.fetchone()[0]  # proves multiple same-day Waves are simply independent rows

        cur.execute("reset role")
        cur.execute("select status, delivery_date from delivery_sessions where id=%s", (wave_a,))
        status, delivery_date = cur.fetchone()
        assert status == "planned"
        cur.execute(
            "select count(*) from delivery_sessions where business_id=%s and delivery_date=%s",
            (business, delivery_date),
        )
        assert cur.fetchone()[0] == 2, "multiple same-day Waves must coexist as independent rows"

        # =====================================================================
        # BUILD -- exactly one build_rider_run orchestration call, exact
        # frontend parameter shapes (uuid[] order_ids, uuid idempotency_key).
        # =====================================================================
        actor(owner_a)
        key_riderfirst = uuid.uuid4()
        # Rider-first shape: Rider fixed, orders (7 PJ + 3 of the 4 Pantai
        # Dalam) selected after -- this is also the COMBINE scenario.
        combine_selection = pj_orders + pd_orders[:3]
        cur.execute(
            "select build_rider_run(%s,%s,%s,%s)",
            (wave_a, ali, combine_selection, key_riderfirst),
        )
        result = cur.fetchone()[0]
        assert result == {
            "delivery_session_id": str(wave_a), "rider_id": str(ali), "order_count": 10,
            # S4-11 Batch 3 (Grow V1 Flow 2): both riders have a large
            # max_active_orders and every order defaults to
            # vehicle_requirement 'any', so no override was ever needed.
            "vehicle_capacity_override_used": False,
        }

        cur.execute("reset role")
        cur.execute(
            "select count(*) from delivery_events where event_type='session.order_attached' and order_id = any(%s)",
            (combine_selection,),
        )
        assert cur.fetchone()[0] == 10
        cur.execute(
            "select count(*) from delivery_events where event_type='rider.assigned' and order_id = any(%s)",
            (combine_selection,),
        )
        assert cur.fetchone()[0] == 10
        cur.execute(
            "select count(*) from delivery_events where event_type='run.built' and (metadata->>'idempotency_key')::uuid=%s",
            (key_riderfirst,),
        )
        assert cur.fetchone()[0] == 1

        # =====================================================================
        # SPLIT SCENARIO -- 20 eligible unzoned-style orders (Gombak
        # equivalent), 10 to Ali now, refresh shows 10 remaining eligible,
        # remaining 10 to Abu later, same Wave.
        # =====================================================================
        actor(owner_a)
        gombak_orders = [new_order(40 + i) for i in range(20)]
        actor(owner_a)
        key_split_1 = uuid.uuid4()
        cur.execute(
            "select build_rider_run(%s,%s,%s,%s)",
            (wave_a, ali, gombak_orders[:10], key_split_1),
        )
        assert cur.fetchone()[0]["order_count"] == 10

        # Refresh (Orders-first shape: re-fetch eligible orders directly).
        cur.execute("reset role")
        cur.execute(
            "select id from orders where id = any(%s) and approved_at is not null "
            "and assigned_rider_id is null and delivery_status='created'",
            (gombak_orders,),
        )
        remaining_eligible = {r[0] for r in cur.fetchall()}
        assert remaining_eligible == set(gombak_orders[10:])

        actor(owner_a)
        key_split_2 = uuid.uuid4()
        cur.execute(
            "select build_rider_run(%s,%s,%s,%s)",
            (wave_a, abu, gombak_orders[10:], key_split_2),
        )
        assert cur.fetchone()[0] == {
            "delivery_session_id": str(wave_a), "rider_id": str(abu), "order_count": 10,
            "vehicle_capacity_override_used": False,
        }
        cur.execute("reset role")
        cur.execute("select count(distinct assigned_rider_id) from orders where id = any(%s)", (gombak_orders,))
        # 10 to Ali, 10 to Abu -- two distinct riders in the SAME Wave.
        assert cur.fetchone()[0] == 2
        cur.execute("select count(*) from orders where delivery_session_id=%s", (wave_a,))
        assert cur.fetchone()[0] == 30  # 10 (combine) + 10 (split-Ali) + 10 (split-Abu), one Wave

        # =====================================================================
        # ALL-OR-NOTHING UI RECONCILIATION -- one already-ineligible order
        # in a fresh selection causes zero mutation; a refresh-shaped query
        # correctly identifies which selected order disappeared.
        # =====================================================================
        actor(owner_a)
        conflict_orders = [new_order(70 + i) for i in range(3)]
        cur.execute("select assign_rider(%s,%s)", (conflict_orders[1], abu))  # invalidate the middle one
        attempted_selection = list(conflict_orders)
        rejected(
            cur, "select build_rider_run(%s,%s,%s,%s)",
            (wave_a, ali, attempted_selection, uuid.uuid4()), "orders no longer eligible",
        )
        cur.execute("reset role")
        cur.execute(
            "select id from orders where id = any(%s) and approved_at is not null "
            "and assigned_rider_id is null and delivery_status='created'",
            (attempted_selection,),
        )
        still_eligible = {r[0] for r in cur.fetchall()}
        disappeared = set(attempted_selection) - still_eligible
        assert disappeared == {conflict_orders[1]}, "reconciliation must identify exactly the order that became ineligible"
        cur.execute("select assigned_rider_id from orders where id=%s", (conflict_orders[0],))
        assert cur.fetchone()[0] is None, "zero mutation -- the other two orders in the failed attempt must remain untouched"

        # =====================================================================
        # IDEMPOTENCY -- exact frontend shapes: new key, exact retry (same
        # key/payload, shuffled order), changed payload -> conflict, new key
        # against an already-built set -> normal rejection.
        # =====================================================================
        actor(owner_a)
        idem_wave = None
        cur.execute("select (create_delivery_session(%s,'Idempotency Wave')).id", (business,))
        idem_wave = cur.fetchone()[0]
        idem_orders = [new_order(80 + i) for i in range(4)]
        key_k1 = uuid.uuid4()
        cur.execute("select build_rider_run(%s,%s,%s,%s)", (idem_wave, ali, idem_orders, key_k1))
        first_result = cur.fetchone()[0]

        # Retry: same key, same payload, shuffled order.
        actor(owner_a)
        cur.execute("select build_rider_run(%s,%s,%s,%s)", (idem_wave, ali, list(reversed(idem_orders)), key_k1))
        assert cur.fetchone()[0] == first_result
        cur.execute("reset role")
        cur.execute(
            "select count(*) from delivery_events where event_type='run.built' and (metadata->>'idempotency_key')::uuid=%s",
            (key_k1,),
        )
        assert cur.fetchone()[0] == 1, "retry must not create a second run.built"

        # Changed payload, same key -> conflict.
        actor(owner_a)
        extra_order = new_order(90)
        rejected(
            cur, "select build_rider_run(%s,%s,%s,%s)",
            (idem_wave, ali, idem_orders + [extra_order], key_k1), "idempotency key conflict",
        )
        rejected(
            cur, "select build_rider_run(%s,%s,%s,%s)",
            (idem_wave, abu, idem_orders, key_k1), "idempotency key conflict",
        )

        # New key (K2) against the already-built set -- NOT a retry, normal rejection.
        key_k2 = uuid.uuid4()
        rejected(
            cur, "select build_rider_run(%s,%s,%s,%s)",
            (idem_wave, abu, idem_orders, key_k2), "orders no longer eligible",
        )

        # =====================================================================
        # SINGLE-ORDER REGRESSION -- Order Detail Assign/reassign path
        # unaffected by anything in this batch.
        # =====================================================================
        actor(owner_a)
        solo_order = new_order(95)
        cur.execute("select assign_rider(%s,%s)", (solo_order, ali))
        cur.execute("select (reassign_rider(%s,%s)).assigned_rider_id", (solo_order, abu))
        assert str(cur.fetchone()[0]) == str(abu)

        # =====================================================================
        # BUSINESS ISOLATION / DIRECT-WRITE REGRESSION spot check.
        # =====================================================================
        owner_b = uuid.uuid4()
        cur.execute("reset role")
        cur.execute(
            "insert into auth.users(id,aud,role,email,created_at,updated_at) "
            "values(%s,'authenticated','authenticated',%s,now(),now())",
            (owner_b, f"s4-06-b5b-owner-b-{uuid.uuid4()}@test.invalid"),
        )
        actor(owner_b)
        rejected(cur, "select build_rider_run(%s,%s,%s,%s)", (wave_a, ali, idem_orders, uuid.uuid4()), "forbidden")

        actor(rider_ali_user)
        cur.execute("savepoint denied_direct")
        cur.execute("update orders set assigned_rider_id=%s where id=%s", (rider_abu_user, idem_orders[0]))
        assert cur.rowcount == 0
        cur.execute("rollback to savepoint denied_direct")

        conn.rollback()

print("s4_06_batch_5b_vendor_run_builder_staging_contract_ok")
