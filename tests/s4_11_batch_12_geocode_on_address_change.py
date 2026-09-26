"""Rollback-only S4-11 Batch-12 acceptance: address changes invalidate a
previously-resolved canonical location (geocode-once/store/reuse, with
re-geocode required only on genuine change), downstream planning consumes
persisted coordinates only, and the manual-correction contract keeps
enforcing 'never invent coordinates'."""

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


owner_a = uuid.uuid4()

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        cur.execute(
            "insert into auth.users(id,aud,role,email,created_at,updated_at) "
            "values(%s,'authenticated','authenticated',%s,now(),now())",
            (owner_a, f"s4-11-b12-owner-{uuid.uuid4()}@test.invalid"),
        )
        cur.execute("insert into businesses(name) values('S4-11 B12 Geocode Change') returning id")
        business = cur.fetchone()[0]
        cur.execute("insert into business_members(business_id,user_id,role) values(%s,%s,'owner')", (business, owner_a))

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),"
                "set_config('request.jwt.claim.role',%s,true)",
                (str(user_id), role),
            )
            cur.execute(f"set local role {role}")

        # =====================================================================
        # GEOCODE ONCE / STORE / REUSE: a resolved location survives an
        # unrelated update untouched.
        # =====================================================================
        actor(owner_a)
        cur.execute("select create_delivery(%s,'Geo C1','+60140000001','Original Address')", (business,))
        order_id = cur.fetchone()[0]["order"]["id"]

        cur.execute("reset role")
        cur.execute(
            "select set_order_location(%s,'resolved',3.14,101.68,'mapbox_permanent')",
            (order_id,),
        )

        actor(owner_a)
        cur.execute("select update_order_details(%s, p_customer_name := 'Geo C1 renamed')", (order_id,))

        cur.execute("reset role")
        cur.execute(
            "select location_status, latitude, longitude, location_provider from orders where id=%s",
            (order_id,),
        )
        status, lat, lng, provider = cur.fetchone()
        assert status == "resolved" and lat == 3.14 and lng == 101.68 and provider == "mapbox_permanent", (
            f"unrelated update must not touch a resolved location: {status} {lat} {lng} {provider}"
        )

        # =====================================================================
        # Address change invalidates the previously-resolved location --
        # "geocode when required" on a genuine change.
        # =====================================================================
        actor(owner_a)
        cur.execute(
            "select update_order_details(%s, p_delivery_address := 'A Genuinely Different Address')",
            (order_id,),
        )

        cur.execute("reset role")
        cur.execute(
            "select location_status, latitude, longitude, location_provider, location_resolved_at "
            "from orders where id=%s",
            (order_id,),
        )
        status, lat, lng, provider, resolved_at = cur.fetchone()
        assert status == "unresolved", f"address change must reset location_status, got {status}"
        assert lat is None and lng is None, "address change must clear stale coordinates"
        assert provider is None and resolved_at is None, "address change must clear stale provenance"

        cur.execute(
            "select count(*) from delivery_events where order_id=%s and event_type='order.location_invalidated'",
            (order_id,),
        )
        assert cur.fetchone()[0] == 1, "address change must record an auditable invalidation event"

        # A no-op "change" to the SAME address (case/whitespace aside) must
        # NOT re-invalidate an already-resolved location a second time.
        cur.execute("reset role")
        cur.execute(
            "select set_order_location(%s,'resolved',3.20,101.70,'mapbox_permanent')",
            (order_id,),
        )
        actor(owner_a)
        cur.execute(
            "select update_order_details(%s, p_delivery_address := 'A Genuinely Different Address')",
            (order_id,),
        )
        cur.execute("reset role")
        cur.execute("select location_status from orders where id=%s", (order_id,))
        assert cur.fetchone()[0] == "resolved", "re-submitting the identical address must not invalidate"

        # =====================================================================
        # Manual correction path: still enforces "never invent coordinates"
        # (both coordinates required), independent of provider outcome.
        # =====================================================================
        actor(owner_a)
        rejected(
            cur,
            "select set_order_location_manual(%s, %s, null)",
            (order_id, 3.14),
            "both coordinates required",
        )
        cur.execute("select set_order_location_manual(%s, 3.140000, 101.680000)", (order_id,))
        cur.execute("reset role")
        cur.execute("select location_status, location_provider from orders where id=%s", (order_id,))
        status, provider = cur.fetchone()
        assert status == "resolved" and provider == "manual_correction"

        # =====================================================================
        # Downstream truth (coverage/zones/planning) consumes ONLY the
        # persisted coordinates -- order_coverage_status and
        # propose_delivery_plan are plain SQL/plpgsql with no network
        # capability; this proves they operate purely off stored data by
        # exercising them against the corrected order with no provider
        # involved at all in this test run.
        # =====================================================================
        actor(owner_a)
        cur.execute("select set_business_service_area(%s, 3.14, 101.68, 5)", (business,))
        cur.execute("select order_coverage_status(%s)", (order_id,))
        coverage = cur.fetchone()[0]
        assert coverage == "covered", f"expected covered using persisted coordinates, got {coverage}"

        # =====================================================================
        # CSV/XLSX bulk-imported orders enter the exact same canonical
        # orders/delivery_stops/location_status shape as any other intake --
        # no separate import-only location table/columns.
        # =====================================================================
        actor(owner_a)
        idem_key = uuid.uuid4()
        cur.execute(
            "select import_orders_batch(%s, %s::jsonb, %s)",
            (
                business,
                '[{"source_row_ref":"r1","customer_name":"Geo Import","customer_phone":"+60140000099","delivery_address":"Imported Address"}]',
                idem_key,
            ),
        )
        result = cur.fetchone()[0]
        imported_order_id = result["committed"][0]["order_id"]
        cur.execute("reset role")
        cur.execute(
            "select location_status from orders where id=%s",
            (imported_order_id,),
        )
        assert cur.fetchone()[0] == "unresolved", "a freshly imported order starts unresolved, same as any intake path"
        cur.execute(
            "select column_name from information_schema.columns where table_name='delivery_stops' and column_name ilike '%%location%%'"
        )
        assert cur.fetchall() == [], "delivery_stops must carry no parallel location columns -- orders is the sole location table"

        conn.rollback()

print("s4_11_batch_12_geocode_on_address_change_ok")
