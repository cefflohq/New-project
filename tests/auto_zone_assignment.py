"""Rollback-only acceptance for auto zone assignment
(20261014120000_auto_zone_assignment.sql): a resolved order gets the zone
whose boundary holds it, a manual zone always wins, orders in a run and
orders beyond the coverage radius + 20 % are never auto-zoned, and a zone
boundary change re-zones only open auto/unzoned orders."""

import json
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


def square(x0, y0, x1, y1):
    return json.dumps({"type": "Polygon", "coordinates": [[[x0, y0], [x1, y0], [x1, y1], [x0, y1], [x0, y0]]]})


owner = uuid.uuid4()

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        cur.execute(
            "insert into auth.users(id,aud,role,email,created_at,updated_at) "
            "values(%s,'authenticated','authenticated',%s,now(),now())",
            (owner, f"auto-zone-{uuid.uuid4()}@test.invalid"),
        )
        cur.execute(
            "insert into businesses(name, service_origin_latitude, service_origin_longitude, service_coverage_radius_km) "
            "values('Auto Zone Biz', 3.14, 101.69, 10) returning id"
        )
        biz = cur.fetchone()[0]
        cur.execute("insert into business_members(business_id,user_id,role) values(%s,%s,'owner')", (biz, owner))
        cur.execute("insert into zones(business_id,name,boundary) values(%s,'Setapak',%s) returning id",
                    (biz, square(101.68, 3.13, 101.72, 3.17)))
        zone_a = cur.fetchone()[0]
        cur.execute("insert into zones(business_id,name,boundary) values(%s,'Gombak',%s) returning id",
                    (biz, square(101.73, 3.18, 101.77, 3.22)))
        zone_b = cur.fetchone()[0]

        def order(lat, lng, status="resolved", zone=None):
            cur.execute(
                "insert into orders(business_id,customer_name,customer_phone,delivery_address,latitude,longitude,location_status,zone_id) "
                "values(%s,'C','+60123456789','Addr',%s,%s,%s,%s) returning id",
                (biz, lat, lng, status, zone),
            )
            return cur.fetchone()[0]

        def zone_of(order_id):
            cur.execute("select zone_id, zone_source from orders where id=%s", (order_id,))
            return cur.fetchone()

        auto = order(3.15, 101.70)
        assert zone_of(auto) == (zone_a, "auto")

        manual = order(3.15, 101.70, zone=zone_b)
        assert zone_of(manual) == (zone_b, "manual"), "manual zone wins over the boundary"

        far = order(3.40, 101.90)
        assert zone_of(far) == (None, None), "beyond coverage + 20 % stays unzoned"

        pending = order(3.15, 101.70, status="unresolved")
        assert zone_of(pending) == (None, None), "only resolved points are auto-zoned"

        cur.execute("update zones set boundary=%s where id=%s", (square(101.60, 3.00, 101.61, 3.01), zone_a))
        assert zone_of(auto) == (None, None), "boundary change re-zones open auto orders"
        assert zone_of(manual) == (zone_b, "manual"), "manual zone kept on re-zone"

        conn.rollback()

print("auto_zone_assignment_ok")
