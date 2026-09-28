"""Rollback-only S4-06 Batch-3 minimal Zone concept acceptance."""

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


owner_a, operator_a, rider_a_user, owner_b = [uuid.uuid4() for _ in range(4)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in (
            (owner_a, "owner-a"), (operator_a, "operator-a"), (rider_a_user, "rider-a"), (owner_b, "owner-b"),
        ):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"s4-06-b3-{label}-{uuid.uuid4()}@test.invalid"),
            )
        cur.execute("insert into businesses(name) values('S4-06 B3 Business A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-06 B3 Business B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values(%s,%s,'owner'),(%s,%s,'operator'),(%s,%s,'owner')",
            (business_a, owner_a, business_a, operator_a, business_b, owner_b),
        )
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) values(%s,%s,'B3 Rider A',%s,'active') returning id",
            (business_a, rider_a_user, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider_a = cur.fetchone()[0]

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claim.role',%s,true)",
                (str(user_id), role),
            )
            cur.execute(f"set local role {role}")

        # ---- create/rename/deactivate + Owner authorization. ----
        # create_zone/rename_zone/set_zone_status return composite `zones`
        # rows, not jsonb -- extract fields via SQL (function(...)).field
        # rather than parsing the composite in Python, matching the
        # established pattern for every other composite-returning RPC.
        actor(owner_a)
        cur.execute("select (create_zone(%s,'Kajang')).id", (business_a,))
        zone_kajang = cur.fetchone()[0]
        cur.execute("select (create_zone(%s,'Bangi')).id", (business_a,))
        zone_bangi = cur.fetchone()[0]

        cur.execute("select (rename_zone(%s,'Kajang Town')).name", (zone_kajang,))
        assert cur.fetchone()[0] == "Kajang Town"

        cur.execute("select (set_zone_status(%s,'inactive')).status", (zone_bangi,))
        assert cur.fetchone()[0] == "inactive"

        # ---- Operator/Staff authorization. ----
        actor(operator_a)
        cur.execute("select (create_zone(%s,'Cheras')).id", (business_a,))
        zone_cheras = cur.fetchone()[0]
        cur.execute("select (rename_zone(%s,'Cheras Area')).name", (zone_cheras,))
        assert cur.fetchone()[0] == "Cheras Area"

        # ---- Duplicate-name protection, case-insensitively. ----
        actor(owner_a)
        rejected(cur, "select create_zone(%s,'kajang town')", (business_a,), "zone name already exists")
        rejected(cur, "select create_zone(%s,'  BANGI  ')", (business_a,), "zone name already exists")
        rejected(cur, "select rename_zone(%s,'bangi')", (zone_cheras,), "zone name already exists")

        # ---- Idempotency: rename to the same name / set to the same status. ----
        actor(owner_a)
        cur.execute("select (rename_zone(%s,'Kajang Town')).updated_at", (zone_kajang,))
        first_updated_at = cur.fetchone()[0]
        cur.execute("select (rename_zone(%s,'Kajang Town')).updated_at", (zone_kajang,))
        assert cur.fetchone()[0] == first_updated_at, "renaming to the identical name must be a no-op"

        # ---- Cross-business denial. ----
        actor(owner_b)
        rejected(cur, "select create_zone(%s,'Intrusion')", (business_a,), "forbidden")
        rejected(cur, "select rename_zone(%s,'Hijack')", (zone_kajang,), "forbidden")
        rejected(cur, "select set_zone_status(%s,'inactive')", (zone_kajang,), "forbidden")

        # ---- Direct-write denial on zones. ----
        actor(owner_a)
        rejected(cur, "insert into zones(business_id,name) values(%s,'Bypass')", (business_a,))
        affects_zero(cur, "update zones set name='bypass' where id=%s", (zone_kajang,))
        affects_zero(cur, "delete from zones where id=%s", (zone_kajang,))

        # ---- Optional/unzoned orders: create_delivery with no zone at all. ----
        actor(owner_a)
        cur.execute("select create_delivery(%s,'B3 Customer','+60196000000','Addr')", (business_a,))
        unzoned_order = uuid.UUID(cur.fetchone()[0]["order"]["id"])
        cur.execute("select approve_order(%s)", (unzoned_order,))
        cur.execute("reset role")
        cur.execute("select zone_id from orders where id=%s", (unzoned_order,))
        assert cur.fetchone()[0] is None, "orders must be creatable with no zone at all"

        # ---- Active zone assignment at creation time. ----
        actor(owner_a)
        cur.execute("select create_delivery(%s,'B3 Customer',%s,'Addr',p_zone_id=>%s)", (business_a, "+60196000001", zone_kajang))
        zoned_order = uuid.UUID(cur.fetchone()[0]["order"]["id"])
        cur.execute("reset role")
        cur.execute("select zone_id from orders where id=%s", (zoned_order,))
        assert cur.fetchone()[0] == zone_kajang

        # ---- Inactive zone rejected for NEW assignment (creation time). ----
        actor(owner_a)
        rejected(cur, "select create_delivery(%s,'B3 Customer',%s,'Addr',p_zone_id=>%s)", (business_a, "+60196000002", zone_bangi), "invalid zone")

        # ---- Zone change on an eligible (pre-dispatch) order via update_order_details. ----
        actor(owner_a)
        cur.execute("select (update_order_details(%s,p_zone_id=>%s)).zone_id", (unzoned_order, zone_kajang))
        assert cur.fetchone()[0] == zone_kajang
        cur.execute("reset role")
        cur.execute("select count(*) from delivery_events where order_id=%s and event_type='order.zone_changed'", (unzoned_order,))
        assert cur.fetchone()[0] == 1

        # Clearing a zone explicitly.
        actor(owner_a)
        cur.execute("select (update_order_details(%s,p_clear_zone=>true)).zone_id", (unzoned_order,))
        assert cur.fetchone()[0] is None
        cur.execute("reset role")
        cur.execute("select count(*) from delivery_events where order_id=%s and event_type='order.zone_changed'", (unzoned_order,))
        assert cur.fetchone()[0] == 2, "clearing a zone must also record a factual event"

        # Inactive zone rejected for new assignment via update_order_details too.
        actor(owner_a)
        rejected(cur, "select update_order_details(%s,p_zone_id=>%s)", (unzoned_order, zone_bangi), "invalid zone")

        # No-op zone field (touching an unrelated field) must not fire a zone event.
        actor(owner_a)
        cur.execute("select update_order_details(%s,p_notes=>%s)", (zoned_order, "unrelated edit"))
        cur.execute("reset role")
        cur.execute("select count(*) from delivery_events where order_id=%s and event_type='order.zone_changed'", (zoned_order,))
        assert cur.fetchone()[0] == 0, "editing an unrelated field must not record a spurious zone-change event"

        # ---- Historical zone reference preserved after deactivation --
        # zoned_order already references zone_kajang while it's active;
        # deactivate it now and confirm the order is untouched. ----
        actor(owner_a)
        cur.execute("select set_zone_status(%s,'inactive')", (zone_kajang,))
        cur.execute("reset role")
        cur.execute("select zone_id from orders where id=%s", (zoned_order,))
        assert cur.fetchone()[0] == zone_kajang, "deactivating a zone must never rewrite historical order references"
        # An unrelated field-only update on that same order must not be
        # blocked or altered by its zone having since gone inactive.
        actor(owner_a)
        cur.execute("select (update_order_details(%s,p_notes=>%s)).notes", (zoned_order, "still editable"))
        assert cur.fetchone()[0] == "still editable"
        cur.execute("reset role")
        cur.execute("select zone_id from orders where id=%s", (zoned_order,))
        assert cur.fetchone()[0] == zone_kajang, "an unrelated edit must not disturb the existing (now-inactive) zone reference"

        # ---- Multi-zone session/run compatibility: two zoned orders (different
        # zones) assigned to the same Rider in the same session/run -- fully
        # preserved S4-05/S4-06.1/.2 machinery, zone plays no role in it. ----
        actor(owner_a)
        cur.execute("select (create_zone(%s,'Semenyih')).id", (business_a,))
        zone_semenyih = cur.fetchone()[0]
        cur.execute("select (create_zone(%s,'Puchong')).id", (business_a,))
        zone_puchong = cur.fetchone()[0]
        cur.execute("select create_delivery(%s,'B3 Customer',%s,'Addr',p_zone_id=>%s)", (business_a, "+60196000004", zone_semenyih))
        order_zone_1 = uuid.UUID(cur.fetchone()[0]["order"]["id"])
        cur.execute("select create_delivery(%s,'B3 Customer',%s,'Addr',p_zone_id=>%s)", (business_a, "+60196000005", zone_puchong))
        order_zone_2 = uuid.UUID(cur.fetchone()[0]["order"]["id"])
        cur.execute("select create_delivery_session(%s,'B3 Multi-zone Run', current_date)", (business_a,))
        cur.execute("reset role")
        cur.execute("select id from delivery_sessions where business_id=%s order by created_at desc limit 1", (business_a,))
        session_a = cur.fetchone()[0]
        actor(owner_a)
        for oid in (order_zone_1, order_zone_2):
            cur.execute("select approve_order(%s)", (oid,))
            cur.execute("select attach_order_to_session(%s,%s)", (oid, session_a))
            cur.execute("select assign_rider(%s,%s)", (oid, rider_a))
        actor(rider_a_user)
        for oid in (order_zone_1, order_zone_2):
            cur.execute("select accept_assignment(%s,%s)", (rider_a, oid))
        cur.execute("select save_run_sequence(%s,%s,%s)", (rider_a, session_a, [order_zone_1, order_zone_2]))
        cur.execute("select start_pickup_run(%s,%s)", (rider_a, session_a))
        for oid in (order_zone_1, order_zone_2):
            cur.execute("select rider_transition(%s,%s,'ready_for_pickup')", (rider_a, oid))
            cur.execute("select rider_transition(%s,%s,'picked_up')", (rider_a, oid))
        cur.execute("select start_run_delivery(%s,%s)", (rider_a, session_a))
        cur.execute("select rider_transition(%s,%s,'out_for_delivery')", (rider_a, order_zone_1))
        cur.execute("select rider_transition(%s,%s,'arrived')", (rider_a, order_zone_1))
        pod_path_1 = f"{rider_a}/{order_zone_1}/test.jpg"
        cur.execute("reset role")
        cur.execute("insert into storage.objects(bucket_id, name) values ('cefflo-pod', %s)", (pod_path_1,))
        actor(rider_a_user)
        cur.execute("select complete_delivery(%s,%s,%s,'Delivered')", (rider_a, order_zone_1, pod_path_1))
        cur.execute("select rider_transition(%s,%s,'out_for_delivery')", (rider_a, order_zone_2))
        cur.execute("select rider_transition(%s,%s,'arrived')", (rider_a, order_zone_2))
        pod_path_2 = f"{rider_a}/{order_zone_2}/test.jpg"
        cur.execute("reset role")
        cur.execute("insert into storage.objects(bucket_id, name) values ('cefflo-pod', %s)", (pod_path_2,))
        actor(rider_a_user)
        cur.execute("select complete_delivery(%s,%s,%s,'Delivered')", (rider_a, order_zone_2, pod_path_2))
        cur.execute("reset role")
        cur.execute("select delivery_status from orders where id = any(%s)", ([order_zone_1, order_zone_2],))
        assert all(row[0] == "delivered" for row in cur.fetchall()), "a run spanning two distinct zones must complete normally"

        conn.rollback()

print("s4_06_batch_3_zones_ok")
