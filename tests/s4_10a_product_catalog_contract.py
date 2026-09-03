"""Rollback-only S4-10A Product Catalog contract acceptance."""

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
                (user, f"s4-10a-{label}-{uuid.uuid4()}@test.invalid"),
            )
        cur.execute("insert into businesses(name) values('S4-10A A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-10A B') returning id")
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

        # Owner creates deterministic category order.
        actor(owner_a)
        category_ids = []
        for name in ("Makanan", "Minuman", "Add-on"):
            cur.execute("select (create_product_category(%s,%s)).id", (business_a, name))
            category_ids.append(cur.fetchone()[0])
        food, drink, addon = category_ids
        cur.execute("select (update_product_category(%s,'Makanan Utama')).name", (food,))
        assert cur.fetchone()[0] == "Makanan Utama"

        # Operator/Staff has the same day-to-day catalog authority.
        actor(operator_a)
        cur.execute("select (create_product(%s,%s,'Nasi Lemak Ayam','Sambal house',12,'active')).id", (business_a, food))
        nasi = cur.fetchone()[0]
        cur.execute("select (create_product(%s,%s,'Mee Kari',null,10,'active')).id", (business_a, food))
        mee = cur.fetchone()[0]
        cur.execute("select (create_product(%s,%s,'Teh Ais Limau','Fresh lime',6.5,'hidden')).id", (business_a, drink))
        tea = cur.fetchone()[0]
        cur.execute("select (create_product(%s,%s,'Telur Mata',null,2,'active')).id", (business_a, addon))
        egg = cur.fetchone()[0]

        # Active/Hidden transition and full update.
        cur.execute("select (set_product_status(%s,'hidden')).status", (nasi,))
        assert cur.fetchone()[0] == "hidden"
        cur.execute("select (set_product_status(%s,'active')).status", (nasi,))
        assert cur.fetchone()[0] == "active"
        cur.execute("select (update_product(%s,%s,'Nasi Lemak Ayam Special','Sambal house',13.5,'active')).display_price", (nasi, food))
        assert cur.fetchone()[0] == 13.5

        # Reorder inside category is exact and deterministic.
        cur.execute("select id,sort_order from reorder_products(%s,%s)", (food, [mee, nasi]))
        assert cur.fetchall() == [(mee, 0), (nasi, 1)]
        rejected(cur, "select reorder_products(%s,%s)", (food, [nasi, nasi]), "invalid product order")
        rejected(cur, "select reorder_products(%s,%s)", (food, [nasi]), "invalid product order")

        # Move product to another same-business category through Edit; it is appended.
        cur.execute("select category_id,sort_order from update_product(%s,%s,'Teh Ais Limau','Fresh lime',6.5,'active')", (tea, addon))
        assert cur.fetchone() == (addon, 1)

        # Category reorder is exact and deterministic.
        cur.execute("select id,sort_order from reorder_product_categories(%s,%s)", (business_a, [drink, food, addon]))
        assert cur.fetchall() == [(drink, 0), (food, 1), (addon, 2)]

        # Cross-business category assignment and mutation fail.
        actor(owner_b)
        cur.execute("select (create_product_category(%s,'Business B Category')).id", (business_b,))
        category_b = cur.fetchone()[0]
        rejected(cur, "select create_product(%s,%s,'Intrusion',null,1,'active')", (business_a, food), "forbidden")
        rejected(cur, "select update_product(%s,%s,'Hijack',null,1,'active')", (nasi, category_b), "forbidden")
        rejected(cur, "select set_product_status(%s,'hidden')", (nasi,), "forbidden")

        # Cross-business reads are filtered by RLS.
        cur.execute("select count(*) from products where business_id=%s", (business_a,))
        assert cur.fetchone()[0] == 0
        cur.execute("select count(*) from product_categories where business_id=%s", (business_a,))
        assert cur.fetchone()[0] == 0

        # Rider and unrelated authenticated user have no catalog read/mutation authority.
        for denied_user in (rider_a, outsider):
            actor(denied_user)
            cur.execute("select count(*) from products where business_id=%s", (business_a,))
            assert cur.fetchone()[0] == 0
            rejected(cur, "select create_product_category(%s,'Denied')", (business_a,), "forbidden")
            rejected(cur, "select set_product_status(%s,'hidden')", (nasi,), "forbidden")

        # Direct authenticated writes are unavailable even to Owner.
        actor(owner_a)
        rejected(cur, "insert into products(business_id,category_id,name,display_price,status,sort_order) values(%s,%s,'Bypass',1,'active',99)", (business_a, food))
        rejected(cur, "update products set status='hidden' where id=%s", (nasi,))
        rejected(cur, "delete from products where id=%s", (nasi,))

        # Contract validation.
        rejected(cur, "select create_product(%s,%s,'Bad Status',null,1,'draft')", (business_a, food), "invalid status")
        rejected(cur, "select create_product(%s,%s,'Bad Price',null,-1,'active')", (business_a, food), "invalid price")
        rejected(cur, "select create_product(%s,%s,'Missing Category',null,1,'active')", (business_a, uuid.uuid4()), "invalid category")
        rejected(cur, "select create_product(%s,%s,'',null,1,'active')", (business_a, food), "invalid product name")

        # A category containing live products cannot be archived or orphaned.
        rejected(cur, "select archive_product_category(%s)", (food,), "category contains products")

        # Product archive is soft, hides it from the working catalog query and preserves row.
        cur.execute("select (archive_product(%s)).archived_at is not null", (egg,))
        assert cur.fetchone()[0] is True
        cur.execute("select count(*) from products where id=%s and archived_at is null", (egg,))
        assert cur.fetchone()[0] == 0
        cur.execute("reset role")
        cur.execute("select count(*) from products where id=%s and archived_at is not null", (egg,))
        assert cur.fetchone()[0] == 1

        # Empty category may be safely soft archived.
        actor(owner_a)
        cur.execute("select (archive_product_category(%s)).archived_at is not null", (drink,))
        assert cur.fetchone()[0] is True

        # Existing delivery data contracts remain untouched by this migration.
        cur.execute("reset role")
        cur.execute("select pg_get_function_identity_arguments('public.create_delivery'::regproc)")
        assert "p_items jsonb" in cur.fetchone()[0]
        cur.execute("select data_type from information_schema.columns where table_schema='public' and table_name='orders' and column_name='items'")
        assert cur.fetchone()[0] == "jsonb"

        conn.rollback()

print("s4_10a_product_catalog_contract_ok")
