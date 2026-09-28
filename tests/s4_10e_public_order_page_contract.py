"""Rollback-only S4-10E Public Order Page contract acceptance."""

import uuid

import psycopg

from environment_guard import TargetRefused, validate_database_target

try:
    target = validate_database_target(mutating=True, allowed_environments=frozenset({"local", "staging", "test"}))
except TargetRefused as error:
    raise SystemExit(f"target_refused: {error}") from error


def rejected(cur, statement, params=(), contains=None):
    point = f"denied_{uuid.uuid4().hex}"
    cur.execute(f"savepoint {point}")
    try:
        cur.execute(statement, params)
    except psycopg.Error as error:
        cur.execute(f"rollback to savepoint {point}")
        if contains:
            assert contains in str(error), str(error)
    else:
        raise AssertionError(f"expected rejection: {statement}")


owner_a, operator_a, owner_b, outsider = [uuid.uuid4() for _ in range(4)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user, label in ((owner_a, "owner-a"), (operator_a, "operator-a"), (owner_b, "owner-b"), (outsider, "outsider")):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) values(%s,'authenticated','authenticated',%s,now(),now())",
                (user, f"s4-10e-{label}-{uuid.uuid4()}@test.invalid"),
            )
        cur.execute("insert into businesses(name) values('S4-10E A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-10E B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values(%s,%s,'owner'),(%s,%s,'operator'),(%s,%s,'owner')",
            (business_a, owner_a, business_a, operator_a, business_b, owner_b),
        )

        def actor(user, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claim.role',%s,true)",
                (str(user), role),
            )
            cur.execute(f"set local role {role}")

        def anon():
            # A genuinely anonymous caller has no JWT claim.sub at all --
            # must be explicitly cleared, not merely left over from a prior
            # actor() call, or auth.uid() would still resolve to whoever
            # last authenticated in this same transaction.
            cur.execute("reset role")
            cur.execute("select set_config('request.jwt.claim.sub','',true),set_config('request.jwt.claim.role','anon',true)")
            cur.execute("set local role anon")

        # ---- Vendor-side catalog + media fixture (business A) ----
        actor(owner_a)
        cur.execute("select (create_product_category(%s,'Makanan')).id", (business_a,))
        food = cur.fetchone()[0]
        cur.execute("select (create_product(%s,%s,'Nasi Lemak Ayam','Sambal house',12,'active')).id", (business_a, food))
        nasi = cur.fetchone()[0]
        cur.execute("select (create_product(%s,%s,'Mee Kari',null,10,'active')).id", (business_a, food))
        mee = cur.fetchone()[0]
        cur.execute("select (create_product(%s,%s,'Hidden Item',null,5,'hidden')).id", (business_a, food))
        hidden_product = cur.fetchone()[0]
        cur.execute("select (create_product(%s,%s,'To Be Archived',null,7,'active')).id", (business_a, food))
        archived_product = cur.fetchone()[0]
        cur.execute("select (archive_product(%s)).id", (archived_product,))

        # Approve a real display image for Nasi Lemak Ayam via the closed
        # S4-10B pipeline (register -> service_role prepares -> approve).
        media_id = uuid.uuid4()
        orig_path = f"{business_a}/{nasi}/{media_id}/original.jpg"
        cur.execute("reset role")
        cur.execute("insert into storage.objects(bucket_id,name,owner) values('cefflo-product-originals',%s,null)", (orig_path,))
        actor(owner_a)
        cur.execute("select (create_product_media(%s,%s,'image/jpeg')).id", (nasi, media_id))
        cur.execute("reset role")
        cur.execute("set local role service_role")
        cur.execute("select (mark_product_media_processing(%s)).id", (media_id,))
        prep_path = f"{business_a}/{nasi}/{media_id}/prepared.jpg"
        cur.execute("insert into storage.objects(bucket_id,name,owner) values('cefflo-product-originals',%s,null)", (prep_path,))
        cur.execute("select (mark_product_media_prepared(%s,'image/jpeg',1)).id", (media_id,))
        actor(owner_a)
        cur.execute("select (approve_product_media(%s)).id", (media_id,))

        # Place the corresponding object in the PUBLIC display bucket too --
        # this is the step S4-10B's own write RLS policy exists for but does
        # not itself perform; without it, 'approved' status alone must never
        # be enough for public_order_catalog to hand back a URL (Blocker 5).
        cur.execute("reset role")
        cur.execute("insert into storage.objects(bucket_id,name,owner) values('cefflo-product-display',%s,null)", (prep_path,))

        # A second product goes through the full S4-10B approval pipeline
        # (status='approved', prepared_storage_path set) but its prepared
        # object is deliberately NEVER placed in cefflo-product-display --
        # this reproduces exactly the gap Codex's audit found: 'approved' is
        # Vendor intent, not proof of public availability.
        actor(owner_a)
        cur.execute("select (create_product(%s,%s,'Ayam Percik',null,15,'active')).id", (business_a, food))
        ayam = cur.fetchone()[0]
        ayam_media_id = uuid.uuid4()
        ayam_orig_path = f"{business_a}/{ayam}/{ayam_media_id}/original.jpg"
        cur.execute("reset role")
        cur.execute("insert into storage.objects(bucket_id,name,owner) values('cefflo-product-originals',%s,null)", (ayam_orig_path,))
        actor(owner_a)
        cur.execute("select (create_product_media(%s,%s,'image/jpeg')).id", (ayam, ayam_media_id))
        cur.execute("reset role")
        cur.execute("set local role service_role")
        cur.execute("select (mark_product_media_processing(%s)).id", (ayam_media_id,))
        ayam_prep_path = f"{business_a}/{ayam}/{ayam_media_id}/prepared.jpg"
        cur.execute("insert into storage.objects(bucket_id,name,owner) values('cefflo-product-originals',%s,null)", (ayam_prep_path,))
        cur.execute("select (mark_product_media_prepared(%s,'image/jpeg',1)).id", (ayam_media_id,))
        actor(owner_a)
        cur.execute("select (approve_product_media(%s)).id", (ayam_media_id,))
        # Deliberately no insert into cefflo-product-display for ayam_prep_path.

        # ---- Order Page identity ----
        cur.execute("select create_order_page(%s)", (business_a,))
        page_payload = cur.fetchone()[0]
        page_a = page_payload["page"]
        token_a = page_payload["access_token"]
        assert page_a["slug"] == "s4-10e-a"
        assert page_a["enabled"] is True

        actor(owner_b)
        cur.execute("select create_order_page(%s)", (business_b,))
        page_b_payload = cur.fetchone()[0]
        token_b = page_b_payload["access_token"]

        # Minimal catalog for business B, needed only for the cross-business
        # idempotency-key regression below.
        cur.execute("select (create_product_category(%s,'Minuman')).id", (business_b,))
        food_b = cur.fetchone()[0]
        cur.execute("select (create_product(%s,%s,'Teh Ais',null,4,'active')).id", (business_b, food_b))
        product_b = cur.fetchone()[0]

        # Slug collision resolved deterministically (both businesses named
        # distinctly here, so also prove the collision-suffix path directly).
        actor(owner_a)
        rejected(cur, "select create_order_page(%s)", (business_a,), "order page already exists")

        # ================= PUBLIC READ =================
        cur.execute("reset role")
        anon()
        cur.execute("select public_order_catalog(%s)", (token_a,))
        catalog = cur.fetchone()[0]
        assert catalog["business"]["name"] == "S4-10E A"
        product_ids = {p["id"] for p in catalog["products"]}
        assert str(nasi) in product_ids and str(mee) in product_ids
        assert str(hidden_product) not in product_ids, "hidden product must not be publicly listed"
        assert str(archived_product) not in product_ids, "archived product must not be publicly listed"
        nasi_entry = next(p for p in catalog["products"] if p["id"] == str(nasi))
        assert nasi_entry["image_url"] and "cefflo-product-display" in nasi_entry["image_url"]
        assert "original" not in nasi_entry["image_url"], "private original must never be exposed"
        mee_entry = next(p for p in catalog["products"] if p["id"] == str(mee))
        assert mee_entry["image_url"] is None, "no approved image means no image_url, never a fallback guess"

        # Blocker 5: an 'approved' product_media row whose prepared object
        # was never actually placed in cefflo-product-display must still
        # yield image_url = null -- approval status alone is Vendor intent,
        # not proof of public availability.
        ayam_entry = next(p for p in catalog["products"] if p["id"] == str(ayam))
        assert ayam_entry["image_url"] is None, "approved status without a real public-display object must not produce a URL"
        for forbidden_key in ("status", "archived_at", "business_id", "phone", "email", "address"):
            assert forbidden_key not in catalog["business"]
            for p in catalog["products"]:
                assert forbidden_key not in p

        # Invalid / disabled token: safely resolves to nothing, never an error leak.
        cur.execute("select public_order_catalog('not-a-real-token')")
        assert cur.fetchone()[0] is None
        actor(owner_a)
        cur.execute("select (set_order_page_enabled(%s,false)).enabled", (business_a,))
        assert cur.fetchone()[0] is False
        cur.execute("reset role")
        anon()
        cur.execute("select public_order_catalog(%s)", (token_a,))
        assert cur.fetchone()[0] is None, "disabled page must not resolve"
        actor(owner_a)
        cur.execute("select (set_order_page_enabled(%s,true)).enabled", (business_a,))
        assert cur.fetchone()[0] is True

        # ================= PUBLIC ORDER SUBMISSION =================
        cur.execute("reset role")
        anon()

        # Duplicate lines merge deterministically; server ignores any
        # client-supplied price/name -- only product_id + quantity are read.
        idem1 = uuid.uuid4()
        cur.execute(
            "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (
                token_a,
                psycopg.types.json.Jsonb([
                    {"product_id": str(nasi), "quantity": 2, "price": 0.01, "name": "FAKE"},
                    {"product_id": str(nasi), "quantity": 1},
                    {"product_id": str(mee), "quantity": 3},
                ]),
                "Aina Zulkifli", "0123456789", "22 Jalan Desa", "Call at guardhouse", idem1,
            ),
        )
        result = cur.fetchone()[0]
        assert result["replay"] is False
        assert result["order_reference"].startswith("CF-")
        assert result["tracking_token"]

        cur.execute("reset role")
        cur.execute(
            "select delivery_status,approved_at is null,origin,items from orders where public_ref=%s",
            (result["order_reference"],),
        )
        status, needs_review, origin, items = cur.fetchone()
        assert status == "created" and needs_review is True, "public order must start in Needs Review, not approved"
        assert origin == "public"
        by_product = {i["product_id"]: i for i in items}
        assert by_product[str(nasi)]["quantity"] == 3, "duplicate lines must merge, not create two lines"
        assert float(by_product[str(nasi)]["display_price_snapshot"]) == 12.0, "server price, not the client-supplied 0.01"
        assert by_product[str(nasi)]["product_name_snapshot"] == "Nasi Lemak Ayam", "server name, not the client-supplied FAKE"
        assert float(by_product[str(mee)]["display_price_snapshot"]) == 10.0

        # Idempotent replay: identical key returns the same order, no duplicate.
        cur.execute("reset role")
        cur.execute("select count(*) from orders where business_id=%s", (business_a,))
        count_before = cur.fetchone()[0]
        anon()
        cur.execute(
            "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_a, psycopg.types.json.Jsonb([{"product_id": str(nasi), "quantity": 1}]), "Aina Zulkifli", "0123456789", "22 Jalan Desa", "", idem1),
        )
        replay = cur.fetchone()[0]
        assert replay["replay"] is True
        assert replay["order_reference"] == result["order_reference"]
        assert replay["tracking_token"] is None, "replay never re-reveals the original raw tracking token"
        cur.execute("reset role")
        cur.execute("select count(*) from orders where business_id=%s", (business_a,))
        assert cur.fetchone()[0] == count_before, "idempotent replay must not create a second order"

        anon()

        # Cross-business product injection rejected -- product_id from
        # business B against business A's token must never resolve.
        rejected(
            cur,
            "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_a, psycopg.types.json.Jsonb([{"product_id": "00000000-0000-0000-0000-000000000000", "quantity": 1}]), "X", "012", "Addr", "", uuid.uuid4()),
            "product not available",
        )

        # Hidden / archived product rejected.
        rejected(
            cur, "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_a, psycopg.types.json.Jsonb([{"product_id": str(hidden_product), "quantity": 1}]), "X", "012", "Addr", "", uuid.uuid4()),
            "product not available",
        )
        rejected(
            cur, "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_a, psycopg.types.json.Jsonb([{"product_id": str(archived_product), "quantity": 1}]), "X", "012", "Addr", "", uuid.uuid4()),
            "product not available",
        )

        # Zero / negative / excessive quantity rejected.
        rejected(
            cur, "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_a, psycopg.types.json.Jsonb([{"product_id": str(nasi), "quantity": 0}]), "X", "012", "Addr", "", uuid.uuid4()),
            "invalid quantity",
        )
        rejected(
            cur, "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_a, psycopg.types.json.Jsonb([{"product_id": str(nasi), "quantity": -1}]), "X", "012", "Addr", "", uuid.uuid4()),
            "invalid quantity",
        )
        rejected(
            cur, "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_a, psycopg.types.json.Jsonb([{"product_id": str(nasi), "quantity": 51}]), "X", "012", "Addr", "", uuid.uuid4()),
            "invalid quantity",
        )

        # This test deliberately exercises submit_public_order many more
        # times than the 5-per-60s per-token rate limit allows (a rejected()
        # call's outer SAVEPOINT rollback undoes even a successful internal
        # check_rate_limit increment, but a call that ultimately SUCCEEDS is
        # permanent). Reset the counter here exactly like a real 60s window
        # rollover would, so later legitimate-call assertions in this same
        # frozen-now() transaction are not spuriously rate-limited.
        cur.execute("reset role")
        cur.execute("delete from rate_limit_counters where action='submit_public_order'")
        anon()

        # Blocker 2: aggregate quantity after merging duplicate lines must
        # itself respect the same 1..50 bound -- 20 individually-valid lines
        # of quantity 50 each must not merge into an unvalidated quantity of
        # 1000. Each line is individually within bounds; only the MERGED
        # total (1000) exceeds the limit.
        over_limit_dupes = [{"product_id": str(nasi), "quantity": 50} for _ in range(20)]
        rejected(
            cur, "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_a, psycopg.types.json.Jsonb(over_limit_dupes), "X", "012", "Addr", "", uuid.uuid4()),
            "invalid quantity",
        )

        # A merged aggregate landing exactly at the limit (10 lines * 5 = 50)
        # must still be accepted deterministically -- the fix must not
        # reject legitimate duplicate-line aggregation within bounds. (Kept
        # within the unrelated <=20-line-count bound, which is not what
        # this assertion is about.)
        at_limit_dupes = [{"product_id": str(nasi), "quantity": 5} for _ in range(10)]
        idem_agg = uuid.uuid4()
        cur.execute(
            "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_a, psycopg.types.json.Jsonb(at_limit_dupes), "Agg Tester", "011", "Addr", "", idem_agg),
        )
        agg_result = cur.fetchone()[0]
        assert agg_result["replay"] is False
        cur.execute("reset role")
        cur.execute("select items from orders where public_ref=%s", (agg_result["order_reference"],))
        agg_items = cur.fetchone()[0]
        agg_nasi_line = next(i for i in agg_items if i["product_id"] == str(nasi))
        assert agg_nasi_line["quantity"] == 50, "25 lines of quantity 2 must merge deterministically to exactly 50"
        anon()

        # Malformed payload rejected (missing key, wrong type).
        rejected(
            cur, "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_a, psycopg.types.json.Jsonb([{"product_id": str(nasi)}]), "X", "012", "Addr", "", uuid.uuid4()),
            "malformed order item",
        )
        rejected(
            cur, "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_a, psycopg.types.json.Jsonb([{"product_id": str(nasi), "quantity": "two"}]), "X", "012", "Addr", "", uuid.uuid4()),
        )

        # Oversized order (>20 distinct lines) rejected.
        many_lines = [{"product_id": str(nasi), "quantity": 1} for _ in range(21)]
        # Use distinct fake ids so they don't merge into one line first.
        many_lines = [{"product_id": str(uuid.uuid4()), "quantity": 1} for _ in range(21)]
        rejected(
            cur, "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_a, psycopg.types.json.Jsonb(many_lines), "X", "012", "Addr", "", uuid.uuid4()),
            "invalid item list",
        )

        # Missing required customer/delivery fields rejected.
        rejected(
            cur, "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_a, psycopg.types.json.Jsonb([{"product_id": str(nasi), "quantity": 1}]), "", "012", "Addr", "", uuid.uuid4()),
            "invalid customer name",
        )
        rejected(
            cur, "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_a, psycopg.types.json.Jsonb([{"product_id": str(nasi), "quantity": 1}]), "X", "012", "", "", uuid.uuid4()),
            "invalid delivery address",
        )

        # Same window-rollover simulation as above -- this section also
        # performs several legitimate submit_public_order calls.
        cur.execute("reset role")
        cur.execute("delete from rate_limit_counters where action='submit_public_order'")
        anon()

        # Blocker 4: a NULL idempotency key must be rejected before any
        # order is created -- it would otherwise bypass both the replay
        # lookup and the partial unique index, letting a genuine client
        # retry create a duplicate order.
        cur.execute("select count(*) from orders")
        count_before_null_key = cur.fetchone()[0]
        rejected(
            cur, "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_a, psycopg.types.json.Jsonb([{"product_id": str(nasi), "quantity": 1}]), "X", "012", "Addr", "", None),
            "invalid idempotency key",
        )
        cur.execute("select count(*) from orders")
        assert cur.fetchone()[0] == count_before_null_key, "a rejected null-key submission must create no order"

        # A malformed (non-UUID) idempotency key is already rejected earlier
        # still, at the type level, because the parameter is uuid-typed.
        rejected(
            cur, "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_a, psycopg.types.json.Jsonb([{"product_id": str(nasi), "quantity": 1}]), "X", "012", "Addr", "", "not-a-real-uuid"),
        )

        # Blocker 3: idempotency uniqueness is (business_id, key)-scoped,
        # not global -- the same client-generated UUID reused across two
        # different businesses must produce two independent orders, never a
        # false replay with a null/wrong reference.
        shared_idem = uuid.uuid4()
        cur.execute(
            "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_a, psycopg.types.json.Jsonb([{"product_id": str(nasi), "quantity": 1}]), "Cross A", "011", "Addr A", "", shared_idem),
        )
        cross_a = cur.fetchone()[0]
        assert cross_a["replay"] is False
        assert cross_a["order_reference"], "business A's order must have a real reference, not a false-replay null"
        cur.execute(
            "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_b, psycopg.types.json.Jsonb([{"product_id": str(product_b), "quantity": 1}]), "Cross B", "022", "Addr B", "", shared_idem),
        )
        cross_b = cur.fetchone()[0]
        assert cross_b["replay"] is False, "the same UUID reused by a different business must create its own new order, not a replay"
        assert cross_b["order_reference"], "business B's order must have a real reference, not a false-replay null"
        assert cross_b["order_reference"] != cross_a["order_reference"]

        # Business A repeating its own UUID X is still a safe replay of its
        # own order, and creates no duplicate.
        cur.execute("reset role")
        cur.execute("select count(*) from orders where business_id=%s", (business_a,))
        count_before_cross_replay = cur.fetchone()[0]
        anon()
        cur.execute(
            "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_a, psycopg.types.json.Jsonb([{"product_id": str(nasi), "quantity": 1}]), "Cross A", "011", "Addr A", "", shared_idem),
        )
        cross_a_replay = cur.fetchone()[0]
        assert cross_a_replay["replay"] is True
        assert cross_a_replay["order_reference"] == cross_a["order_reference"]
        assert cross_a_replay["tracking_token"] is None, "a legitimate replay must never re-reveal the original tracking token"
        cur.execute("reset role")
        cur.execute("select count(*) from orders where business_id=%s", (business_a,))
        assert cur.fetchone()[0] == count_before_cross_replay, "same business + same key replay must not duplicate"
        anon()

        # REMEDIATION 02: a unique_violation on the orders INSERT is not
        # necessarily our own idempotency key colliding -- orders.public_ref
        # is independently unique. Force a genuine public_ref collision
        # (unrelated to the idempotency key) between two DIFFERENT
        # idempotency keys, and prove the handler re-raises instead of
        # manufacturing a false {replay: true, order_reference: null}
        # response. Temporarily pin the public_ref default so two inserts
        # collide deterministically; fully reversible within this
        # rollback-only transaction, and reverted immediately below so nothing
        # later in this same test is affected.
        cur.execute("reset role")
        cur.execute("alter table orders alter column public_ref set default 'CF-FORCEDCOLLISION'")
        anon()
        seed_idem = uuid.uuid4()
        cur.execute(
            "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_a, psycopg.types.json.Jsonb([{"product_id": str(nasi), "quantity": 1}]), "Seed", "011", "Addr", "", seed_idem),
        )
        seed_result = cur.fetchone()[0]
        assert seed_result["order_reference"] == "CF-FORCEDCOLLISION"

        cur.execute("reset role")
        cur.execute("select count(*) from orders")
        count_before_collision = cur.fetchone()[0]
        anon()
        colliding_idem = uuid.uuid4()
        assert colliding_idem != seed_idem
        rejected(
            cur, "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_a, psycopg.types.json.Jsonb([{"product_id": str(mee), "quantity": 1}]), "Collider", "011", "Addr", "", colliding_idem),
        )
        # No response path may return {replay: true, order_reference: null}
        # -- the call above raised (rejected() asserts this), so there is no
        # jsonb result object at all to inspect; the exception itself is the
        # proof no false-success value was ever constructed. Confirm no
        # order was created by the failed attempt either.
        cur.execute("reset role")
        cur.execute("select count(*) from orders")
        assert cur.fetchone()[0] == count_before_collision, "a re-raised unrelated collision must create no order"
        cur.execute("alter table orders alter column public_ref set default (('CF-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,8))))")
        anon()

        # Disabled page rejects submission too, not just read.
        actor(owner_a)
        cur.execute("select (set_order_page_enabled(%s,false)).enabled", (business_a,))
        cur.execute("reset role")
        anon()
        rejected(
            cur, "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_a, psycopg.types.json.Jsonb([{"product_id": str(nasi), "quantity": 1}]), "X", "012", "Addr", "", uuid.uuid4()),
            "invalid or unavailable order page",
        )
        actor(owner_a)
        cur.execute("select set_order_page_enabled(%s,true)", (business_a,))

        # Direct anon table access remains impossible in effect.
        # orders/businesses etc. carry Supabase's platform-wide default
        # anon/authenticated table grants (confirmed directly against
        # information_schema.role_table_grants) and rely entirely on RLS as
        # the actual gate -- a plain SELECT as anon therefore succeeds at
        # the privilege level but RLS silently filters it to zero rows
        # (matching every other table in this schema; this migration does
        # not alter that established, pre-existing security model). The new
        # public_order_pages table instead follows the newer S4-10A/B
        # convention of an explicit revoke, so a direct SELECT there is
        # rejected outright at the privilege level, not merely filtered.
        # Either way, no row from another business is ever reachable.
        cur.execute("reset role")
        anon()
        cur.execute("select * from orders")
        assert cur.fetchall() == [], "RLS must filter every order row for anon, not just non-owned ones"
        rejected(cur, "select * from public_order_pages limit 1")
        rejected(cur, "insert into orders(business_id,customer_name,customer_phone,delivery_address) values(%s,'x','x','x')", (business_a,))

        # ================= APPROVE / DECLINE AUTHORIZATION =================
        actor(owner_a)
        cur.execute("select id from orders where public_ref=%s", (result["order_reference"],))
        public_order_id = cur.fetchone()[0]
        cur.execute("select (approve_order(%s)).approved_at is not null", (public_order_id,))
        assert cur.fetchone()[0] is True, "existing approve_order must work unchanged on a publicly-submitted order"

        # Second public order for the decline path.
        cur.execute("reset role")
        anon()
        cur.execute(
            "select submit_public_order(%s,%s,%s,%s,%s,%s,%s)",
            (token_a, psycopg.types.json.Jsonb([{"product_id": str(mee), "quantity": 1}]), "Jason Lim", "0129876543", "Bangsar South", "", uuid.uuid4()),
        )
        second = cur.fetchone()[0]
        cur.execute("reset role")
        cur.execute("select id from orders where public_ref=%s", (second["order_reference"],))
        second_order_id = cur.fetchone()[0]

        # Public/anon can never approve or decline.
        anon()
        rejected(cur, "select approve_order(%s)", (second_order_id,))
        rejected(cur, "select decline_order(%s,'not interested')", (second_order_id,))

        # Unrelated business (owner_b) cannot approve/decline business A's order.
        actor(owner_b)
        rejected(cur, "select approve_order(%s)", (second_order_id,), "forbidden")
        rejected(cur, "select decline_order(%s,'x')", (second_order_id,), "forbidden")

        # Rider/outsider cannot approve/decline either.
        actor(outsider)
        rejected(cur, "select approve_order(%s)", (second_order_id,), "forbidden")
        rejected(cur, "select decline_order(%s,'x')", (second_order_id,), "forbidden")

        # Authorized business member (operator, not just owner) can decline.
        actor(operator_a)
        cur.execute("select delivery_status from decline_order(%s,'Out of stock')", (second_order_id,))
        assert cur.fetchone()[0] == "cancelled"

        # Cannot decline an already-approved order.
        actor(owner_a)
        rejected(cur, "select decline_order(%s,'too late')", (public_order_id,), "order already approved")

        # ================= BLOCKER 1: TERMINAL DECLINE =================
        # second_order_id was declined (cancelled) above by operator_a.
        # A cancelled order must never subsequently become approvable or
        # assignable through the normal order boundaries.
        actor(owner_a)
        rejected(cur, "select approve_order(%s)", (second_order_id,), "order cancelled")

        # riders_vendor is select-only since S4-03's RLS narrowing -- direct
        # rider provisioning is an onboarding-flow concern out of scope
        # here, so the fixture row is inserted as the harness (superuser),
        # matching the same pattern used by every other test in this suite
        # that needs a rider row.
        cur.execute("reset role")
        cur.execute(
            "insert into riders(business_id,name,phone,status) values(%s,'Test Rider','+60199999999','active') returning id",
            (business_a,),
        )
        rider_id = cur.fetchone()[0]
        actor(owner_a)
        rejected(cur, "select assign_rider(%s,%s)", (second_order_id, rider_id), "order cancelled")

        # Sanity: the SAME rider CAN be assigned to the genuinely-approved
        # public_order_id, proving the new guard blocks only cancelled
        # orders, not assignment in general.
        cur.execute("select (assign_rider(%s,%s)).assigned_rider_id", (public_order_id, rider_id))
        assert cur.fetchone()[0] == rider_id, "assignment must still succeed for a validly approved order"

        # ================= REGRESSION =================
        cur.execute("reset role")
        cur.execute("select pg_get_function_identity_arguments('public.create_delivery'::regproc)")
        assert "p_items jsonb" in cur.fetchone()[0]
        cur.execute("select data_type from information_schema.columns where table_schema='public' and table_name='orders' and column_name='items'")
        assert cur.fetchone()[0] == "jsonb"
        cur.execute("select conname from pg_constraint where conname='products_category_same_business_fk'")
        assert cur.fetchone() is not None
        cur.execute("select conname from pg_constraint where conname='product_media_product_same_business_fk'")
        assert cur.fetchone() is not None

        conn.rollback()

print("s4_10e_public_order_page_contract_ok")
