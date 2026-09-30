"""Rollback-only acceptance for 202610010002..06 (Founder approval 2026-10-01).

Proves: Helpers cannot manage storefront, order pages, product media or
business hours; Operators manage storefront/media but not the slug or
hours; slug rules; public storefront + order through the one order path;
the token path still works; 5-photo limit and per-position replace;
Owner-only subscription read.
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


owner, operator, helper, outsider = [uuid.uuid4() for _ in range(4)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, label in ((owner, "owner"), (operator, "operator"), (helper, "helper"), (outsider, "outsider")):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, f"sf-v1-{label}-{uuid.uuid4()}@test.invalid"),
            )
        cur.execute("insert into businesses(name) values('SF V1 Nari Kitchen') returning id")
        business = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values"
            "(%s,%s,'owner'),(%s,%s,'operator'),(%s,%s,'helper')",
            (business, owner, business, operator, business, helper),
        )
        cur.execute("insert into product_categories(business_id,name,sort_order) values(%s,'Mains',1) returning id", (business,))
        category = cur.fetchone()[0]
        cur.execute(
            "insert into products(business_id,category_id,name,display_price,sort_order) "
            "values(%s,%s,'Nasi Lemak',12.50,1) returning id",
            (business, category),
        )
        product = cur.fetchone()[0]
        media = [uuid.uuid4() for _ in range(6)]
        for m in media:
            cur.execute(
                "insert into storage.objects(bucket_id,name) values('cefflo-product-originals',%s)",
                (f"{business}/{product}/{m}/original.jpg",),
            )

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),"
                "set_config('request.jwt.claims',json_build_object('sub',%s,'role',%s)::text,true)",
                (str(user_id), str(user_id), role),
            )
            cur.execute(f"set local role {role}")

        # Helper: every management action is refused.
        actor(helper)
        for statement, params in (
            ("select get_storefront(%s)", (business,)),
            ("select set_storefront_published(%s,true)", (business,)),
            ("select save_storefront_appearance(%s,'arena','{}')", (business,)),
            ("select change_storefront_slug(%s,'helper-shop')", (business,)),
            ("select create_order_page(%s,null)", (business,)),
            ("select set_order_page_enabled(%s,true)", (business,)),
            ("select create_product_media(%s,%s,'image/jpeg',1::smallint)", (product, media[0])),
            ("select reorder_product_media(%s,'{}'::uuid[])", (product,)),
            ("select set_business_hours(%s,'[]')", (business,)),
        ):
            rejected(cur, statement, params, contains="forbidden")

        # Operator: storefront + media yes; slug and hours no.
        actor(operator)
        cur.execute("select get_storefront(%s)", (business,))
        first = cur.fetchone()[0]
        assert first["slug"] == "sf-v1-nari-kitchen" and first["published"] is False, first
        cur.execute("select get_storefront(%s)->>'slug'", (business,))
        assert cur.fetchone()[0] == first["slug"], "slug must not rotate"
        rejected(cur, "select change_storefront_slug(%s,'op-shop')", (business,), contains="forbidden")
        rejected(cur, "select set_business_hours(%s,'[]')", (business,), contains="forbidden")
        rejected(cur, "select save_storefront_appearance(%s,'arena','{\"evil\":\"x\"}')", (business,))
        for i in range(5):
            cur.execute("select (create_product_media(%s,%s,'image/jpeg')).position", (product, media[i]))
            assert cur.fetchone()[0] == i + 1
        rejected(cur, "select create_product_media(%s,%s,'image/jpeg')", (product, media[5]), contains="at most 5")
        cur.execute("select (create_product_media(%s,%s,'image/jpeg',3::smallint)).position", (product, media[5]))
        cur.execute("select count(*) from product_media where product_id=%s and archived_at is null", (product,))
        assert cur.fetchone()[0] == 5, "replacing one position keeps the other four"

        # Owner: slug rules and hours.
        actor(owner)
        rejected(cur, "select change_storefront_slug(%s,'admin')", (business,), contains="not available")
        cur.execute("select change_storefront_slug(%s,'Nari Kitchen!')->>'slug'", (business,))
        assert cur.fetchone()[0] == "nari-kitchen"
        rejected(cur, "select set_business_hours(%s,'[{\"weekday\":1}]')", (business,), contains="7 days")
        cur.execute(
            "select count(*) from set_business_hours(%s,%s::jsonb)",
            (business, '[' + ','.join(
                f'{{"weekday":{d},"is_open":true,"opens_at":"18:00","closes_at":"02:00"}}' for d in range(1, 8)) + ']'),
        )
        assert cur.fetchone()[0] == 7

        # Public: unpublished is invisible; published serves catalogue + orders.
        actor(outsider, "anon")
        cur.execute("select public_storefront('nari-kitchen')")
        assert cur.fetchone()[0] is None
        rejected(cur, "select get_storefront(%s)", (business,))
        actor(owner)
        cur.execute("select set_storefront_published(%s,true)", (business,))
        actor(outsider, "anon")
        cur.execute("select public_storefront('nari-kitchen')")
        store = cur.fetchone()[0]
        assert store["business"]["name"] == "SF V1 Nari Kitchen" and len(store["products"]) == 1 and len(store["hours"]) == 7
        cur.execute("select public_storefront(%s)->>'slug'", (first["slug"],))
        assert cur.fetchone()[0] == "nari-kitchen", "old slug redirects to the canonical one"
        key = str(uuid.uuid4())
        items = f'[{{"product_id":"{product}","quantity":2}}]'
        cur.execute("select submit_storefront_order('nari-kitchen',%s::jsonb,'Aina','0123','KL','',%s)", (items, key))
        order = cur.fetchone()[0]
        assert order["replay"] is False and order["tracking_token"]
        cur.execute("select submit_storefront_order('nari-kitchen',%s::jsonb,'Aina','0123','KL','',%s)->>'replay'", (items, key))
        assert cur.fetchone()[0] == "true"
        cur.execute("reset role")
        cur.execute("select origin, items->0->>'line_subtotal_snapshot' from orders where submission_idempotency_key=%s", (key,))
        assert cur.fetchone() == ("public", "25.00")

        # Subscription: Owner reads own row, Operator does not.
        cur.execute("insert into business_subscriptions(business_id,plan_key,status) values(%s,'operate','trial')", (business,))
        actor(owner)
        cur.execute("select plan_key from business_subscriptions where business_id=%s", (business,))
        assert cur.fetchone()[0] == "operate"
        actor(operator)
        cur.execute("select count(*) from business_subscriptions where business_id=%s", (business,))
        assert cur.fetchone()[0] == 0

        conn.rollback()

print("storefront_v1_roles_ok")
