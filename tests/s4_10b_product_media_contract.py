"""Rollback-only S4-10B Product Media + Storage contract acceptance."""

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


owner_a, operator_a, owner_b, rider_a, outsider = [uuid.uuid4() for _ in range(5)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user, label in ((owner_a, "owner-a"), (operator_a, "operator-a"), (owner_b, "owner-b"), (rider_a, "rider-a"), (outsider, "outsider")):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) values(%s,'authenticated','authenticated',%s,now(),now())",
                (user, f"s4-10b-{label}-{uuid.uuid4()}@test.invalid"),
            )
        cur.execute("insert into businesses(name) values('S4-10B A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-10B B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values(%s,%s,'owner'),(%s,%s,'operator'),(%s,%s,'owner')",
            (business_a, owner_a, business_a, operator_a, business_b, owner_b),
        )
        cur.execute(
            "insert into riders(business_id,auth_user_id,name,phone,status) values(%s,%s,'Rider A',%s,'active')",
            (business_a, rider_a, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )

        def actor(user, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claim.role',%s,true)",
                (str(user), role),
            )
            cur.execute(f"set local role {role}")

        # S4-10A catalog fixture: media attaches to a real product.
        actor(owner_a)
        cur.execute("select (create_product_category(%s,'Makanan')).id", (business_a,))
        food = cur.fetchone()[0]
        cur.execute("select (create_product(%s,%s,'Nasi Lemak Ayam',null,12,'active')).id", (business_a, food))
        product_a = cur.fetchone()[0]

        actor(owner_b)
        cur.execute("select (create_product_category(%s,'Category B')).id", (business_b,))
        food_b = cur.fetchone()[0]
        cur.execute("select (create_product(%s,%s,'Product B',null,1,'active')).id", (business_b, food_b))
        product_b = cur.fetchone()[0]

        def object_path(business_id, product_id, media_id, kind, ext):
            return f"{business_id}/{product_id}/{media_id}/{kind}.{ext}"

        def register_original(cur, business_id, product_id, media_id, ext="jpg", content_type="image/jpeg"):
            # Fixture-level stand-in for a real client Storage upload: insert
            # the storage.objects metadata row directly (no real bytes are
            # needed for RLS/path-existence contract testing).
            cur.execute("reset role")
            cur.execute(
                "insert into storage.objects(bucket_id,name,owner) values('cefflo-product-originals',%s,null)",
                (object_path(business_id, product_id, media_id, "original", ext),),
            )

        # Owner uploads V1 original, registers it as product_media.
        actor(owner_a)
        media_v1 = uuid.uuid4()
        register_original(cur, business_a, product_a, media_v1)
        actor(owner_a)
        cur.execute("select (create_product_media(%s,%s,'image/jpeg')).status", (product_a, media_v1))
        assert cur.fetchone()[0] == "queued"

        # Operator has the same day-to-day media authority.
        actor(operator_a)
        cur.execute("select status from product_media where id=%s", (media_v1,))
        assert cur.fetchone()[0] == "queued"

        # Registering without a real uploaded object is rejected.
        actor(owner_a)
        rejected(cur, "select create_product_media(%s,%s,'image/jpeg')", (product_a, uuid.uuid4()), "original upload not found")

        # Only the future worker (service_role) may drive processing --
        # the Vendor's own authenticated session must never be able to
        # self-report a fabricated 'processing'/'prepared' state.
        rejected(cur, "select mark_product_media_processing(%s)", (media_v1,))
        rejected(cur, "select mark_product_media_prepared(%s,'image/jpeg',1)", (media_v1,))
        rejected(cur, "select mark_product_media_failed(%s,'boom')", (media_v1,))

        # Simulate the future S4-10C worker (service_role) preparing V1.
        cur.execute("reset role")
        cur.execute("set local role service_role")
        cur.execute("select (mark_product_media_processing(%s)).status", (media_v1,))
        assert cur.fetchone()[0] == "processing"
        cur.execute(
            "insert into storage.objects(bucket_id,name,owner) values('cefflo-product-originals',%s,null)",
            (object_path(business_a, product_a, media_v1, "prepared", "jpg"),),
        )
        cur.execute("select (mark_product_media_prepared(%s,'image/jpeg',1)).status", (media_v1,))
        assert cur.fetchone()[0] == "prepared"

        # Vendor reviews and approves V1: the only path to customer-reachable.
        actor(owner_a)
        cur.execute("select status,approved_at is not null from approve_product_media(%s)", (media_v1,))
        row = cur.fetchone()
        assert row == ("approved", True)
        cur.execute("select count(*) from product_media where product_id=%s and status='approved' and archived_at is null", (product_a,))
        assert cur.fetchone()[0] == 1

        # Deterministic current-approved invariant is enforced by the DB
        # itself (partial unique index), independent of the RPC layer --
        # proven directly as superuser so the privilege-level rejection
        # (tested separately below) cannot mask it.
        cur.execute("reset role")
        rejected(
            cur,
            "insert into product_media(business_id,product_id,original_storage_path,original_content_type,status,approved_at) "
            "values(%s,%s,'bogus','image/jpeg','approved',now())",
            (business_a, product_a),
        )

        # V2 upload supersedes nothing approved -- V1 stays the current
        # display image until V2 is itself approved.
        media_v2 = uuid.uuid4()
        register_original(cur, business_a, product_a, media_v2)
        actor(owner_a)
        cur.execute("select (create_product_media(%s,%s,'image/jpeg')).status", (product_a, media_v2))
        assert cur.fetchone()[0] == "queued"
        cur.execute("select status,archived_at is null from product_media where id=%s", (media_v1,))
        assert cur.fetchone() == ("approved", True), "uploading V2 must not silently touch the still-current approved V1"

        # A second concurrent pending upload supersedes (soft-archives) the
        # first pending one rather than creating an ambiguous pending state.
        media_v2b = uuid.uuid4()
        register_original(cur, business_a, product_a, media_v2b)
        cur.execute("select (create_product_media(%s,%s,'image/jpeg')).status", (product_a, media_v2b))
        assert cur.fetchone()[0] == "queued"
        cur.execute("select archived_at is not null from product_media where id=%s", (media_v2,))
        assert cur.fetchone()[0] is True, "the superseded pending upload must be archived, not left ambiguous"
        cur.execute(
            "select count(*) from product_media where product_id=%s and status in ('queued','processing','prepared') and archived_at is null",
            (product_a,),
        )
        assert cur.fetchone()[0] == 1

        # Approving V2b must not happen before it is genuinely prepared.
        rejected(cur, "select approve_product_media(%s)", (media_v2b,), "media is not ready for approval")

        # Failure + retry: a failed attempt can safely retry without
        # disturbing the still-current approved display image.
        cur.execute("reset role")
        cur.execute("set local role service_role")
        cur.execute("select (mark_product_media_processing(%s)).status", (media_v2b,))
        assert cur.fetchone()[0] == "processing"
        cur.execute("select (mark_product_media_failed(%s,'segmentation timeout')).status", (media_v2b,))
        assert cur.fetchone()[0] == "failed"
        actor(owner_a)
        cur.execute("select status,failure_reason from product_media where id=%s", (media_v2b,))
        assert cur.fetchone() == ("failed", "segmentation timeout")
        cur.execute("select (retry_product_media_processing(%s)).status", (media_v2b,))
        assert cur.fetchone()[0] == "queued"
        cur.execute("select failure_reason from product_media where id=%s", (media_v2b,))
        assert cur.fetchone()[0] is None
        cur.execute("select status,archived_at is null from product_media where id=%s", (media_v1,))
        assert cur.fetchone() == ("approved", True), "a retry on V2b must not disturb the current approved V1"

        # Now genuinely prepare and approve V2b; V1 is superseded (archived
        # history), not deleted.
        cur.execute("reset role")
        cur.execute("set local role service_role")
        cur.execute("select (mark_product_media_processing(%s)).status", (media_v2b,))
        assert cur.fetchone()[0] == "processing"
        cur.execute(
            "insert into storage.objects(bucket_id,name,owner) values('cefflo-product-originals',%s,null)",
            (object_path(business_a, product_a, media_v2b, "prepared", "jpg"),),
        )
        cur.execute("select (mark_product_media_prepared(%s,'image/jpeg',1)).status", (media_v2b,))
        assert cur.fetchone()[0] == "prepared"
        actor(owner_a)
        cur.execute("select status from approve_product_media(%s)", (media_v2b,))
        assert cur.fetchone()[0] == "approved"
        cur.execute("select id,status,archived_at is not null from product_media where product_id=%s and status='approved'", (product_a,))
        rows = {r[0]: (r[1], r[2]) for r in cur.fetchall()}
        assert rows[media_v1] == ("approved", True), "V1 must remain approved-history but archived once superseded"
        assert rows[media_v2b] == ("approved", False), "V2b is now the sole current display image"
        cur.execute("select count(*) from product_media where product_id=%s and status='approved' and archived_at is null", (product_a,))
        assert cur.fetchone()[0] == 1

        # Cross-business: owner_b cannot attach media to business_a's
        # product, read business_a's media, or approve/archive it.
        actor(owner_b)
        rejected(cur, "select create_product_media(%s,%s,'image/jpeg')", (product_a, uuid.uuid4()), "forbidden")
        rejected(cur, "select approve_product_media(%s)", (media_v2, ), "forbidden")
        rejected(cur, "select archive_product_media(%s)", (media_v2,), "forbidden")
        cur.execute("select count(*) from product_media where product_id=%s", (product_a,))
        assert cur.fetchone()[0] == 0
        rejected(cur, "select create_product_media(%s,%s,'image/jpeg')", (product_b, uuid.uuid4()))  # no matching storage object -> still safely rejected, never a silent success across tenants

        # A cross-business product id can never be used to attach media
        # even by a legitimate member of a different business.
        media_cross = uuid.uuid4()
        register_original(cur, business_b, product_a, media_cross)  # object path uses business_b's id but targets business_a's product
        actor(owner_b)
        rejected(cur, "select create_product_media(%s,%s,'image/jpeg')", (product_a, media_cross), "forbidden")

        # Rider and unrelated outsider: no read, no mutation.
        for denied_user in (rider_a, outsider):
            actor(denied_user)
            cur.execute("select count(*) from product_media where product_id=%s", (product_a,))
            assert cur.fetchone()[0] == 0
            rejected(cur, "select create_product_media(%s,%s,'image/jpeg')", (product_a, uuid.uuid4()), "forbidden")
            rejected(cur, "select archive_product_media(%s)", (media_v2b,), "forbidden")

        # Anonymous cannot mutate.
        cur.execute("reset role")
        cur.execute("set local role anon")
        rejected(cur, "select create_product_media(%s,%s,'image/jpeg')", (product_a, uuid.uuid4()))
        rejected(cur, "select archive_product_media(%s)", (media_v2b,))

        # Direct authenticated writes are unavailable even to Owner.
        actor(owner_a)
        rejected(cur, "insert into product_media(business_id,product_id,original_storage_path,original_content_type) values(%s,%s,'bypass','image/jpeg')", (business_a, product_a))
        rejected(cur, "update product_media set status='approved' where id=%s", (media_v2b,))
        rejected(cur, "delete from product_media where id=%s", (media_v1,))

        # Invalid content type rejected.
        media_bad = uuid.uuid4()
        register_original(cur, business_a, product_a, media_bad, ext="gif", content_type="image/gif")
        rejected(cur, "select create_product_media(%s,%s,'image/gif')", (product_a, media_bad), "invalid content type")

        # Archiving a product does not require or cascade a media archive --
        # media rows simply become vestigial once their product is archived
        # (an archived product is unreachable through any catalog/public
        # read path regardless of its media rows' own archived_at).
        cur.execute("select (archive_product(%s)).archived_at is not null", (product_a,))
        assert cur.fetchone()[0] is True
        cur.execute("select status,archived_at is null from product_media where id=%s", (media_v2b,))
        assert cur.fetchone() == ("approved", True), "archiving the product must not itself mutate the media row"

        # Explicit media archive is idempotent and preserves the row.
        cur.execute("select (archive_product_media(%s)).archived_at is not null", (media_v2,))
        assert cur.fetchone()[0] is True
        cur.execute("select (archive_product_media(%s)).archived_at is not null", (media_v2,))
        assert cur.fetchone()[0] is True
        cur.execute("select count(*) from product_media where id=%s", (media_v2,))
        assert cur.fetchone()[0] == 1

        # S4-10A Product Catalog contract remains intact.
        cur.execute("reset role")
        cur.execute("select data_type from information_schema.columns where table_schema='public' and table_name='products' and column_name='display_price'")
        assert cur.fetchone()[0] == "numeric"
        cur.execute("select conname from pg_constraint where conname='products_category_same_business_fk'")
        assert cur.fetchone() is not None
        cur.execute("select pg_get_function_identity_arguments('public.create_delivery'::regproc)")
        assert "p_items jsonb" in cur.fetchone()[0]
        cur.execute("select data_type from information_schema.columns where table_schema='public' and table_name='orders' and column_name='items'")
        assert cur.fetchone()[0] == "jsonb"

        conn.rollback()

print("s4_10b_product_media_contract_ok")
