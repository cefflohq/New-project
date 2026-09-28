"""Rollback-only D-64 acceptance: human-facing order number "#CF-NNN" is
per business, resets on the business-local day, is never capped or
recycled, is concurrency-safe, leaves ids untouched, and is not a way to
reach an order (tracking stays token-only)."""

import threading
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

INSERT = (
    "insert into orders(business_id,customer_name,customer_phone,delivery_address,created_at) "
    "values(%s,'D64','+60100000000','Addr',%s) returning id,order_seq,order_number,order_date::text"
)

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        cur.execute("insert into businesses(name,timezone) values('D64 Biz A','Asia/Kuala_Lumpur') returning id")
        biz_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name,timezone) values('D64 Biz B','Asia/Kuala_Lumpur') returning id")
        biz_b = cur.fetchone()[0]

        # 2026-09-26 08:00 MYT (00:00 UTC) .. business day 2026-09-26.
        day = "2026-09-26 00:00:00+00"
        rows = [cur.execute(INSERT, (biz_a, day)).fetchone() for _ in range(1000)]
        numbers = {r[1]: r[2] for r in rows}
        for seq, expected in ((1, "#CF-001"), (2, "#CF-002"), (9, "#CF-009"), (99, "#CF-099"),
                              (100, "#CF-100"), (999, "#CF-999"), (1000, "#CF-1000")):
            assert numbers[seq] == expected, (seq, numbers[seq])
        assert {r[3] for r in rows} == {"2026-09-26"}

        assert cur.execute(INSERT, (biz_b, day)).fetchone()[2] == "#CF-001", "business B has its own sequence"

        # 23:59 MYT on 26 Sep is still the 26th; 16:00 UTC is 00:00 MYT on the 27th.
        late = cur.execute(INSERT, (biz_a, "2026-09-26 15:59:00+00")).fetchone()
        assert (late[3], late[2]) == ("2026-09-26", "#CF-1001"), late
        nxt = cur.execute(INSERT, (biz_a, "2026-09-26 16:00:00+00")).fetchone()
        assert (nxt[3], nxt[2]) == ("2026-09-27", "#CF-001"), nxt

        # Immutable: id, public_ref and number survive an update attempt.
        oid = rows[0][0]
        cur.execute("select public_ref from orders where id=%s", (oid,))
        ref = cur.fetchone()[0]
        cur.execute("update orders set order_seq=77, notes='x' where id=%s returning id,public_ref,order_number", (oid,))
        assert cur.fetchone() == (oid, ref, "#CF-001")

        # Tracking returns the number but only via its token; the number is
        # not a lookup key in public_tracking.
        cur.execute("select public_tracking(%s)", ("#CF-001",))
        assert cur.fetchone()[0] is None
    conn.rollback()

# Concurrency: parallel committed inserts for one business and day.
with psycopg.connect(target.database_url, autocommit=True) as setup:
    biz = setup.execute("insert into businesses(name) values('D64 Concurrency') returning id").fetchone()[0]
try:
    barrier = threading.Barrier(12)
    results, errors = [], []

    def worker():
        try:
            with psycopg.connect(target.database_url) as c:
                barrier.wait()
                results.append(c.execute(INSERT, (biz, "2026-09-26 02:00:00+00")).fetchone()[1])
        except Exception as error:  # noqa: BLE001
            errors.append(error)

    threads = [threading.Thread(target=worker) for _ in range(12)]
    [t.start() for t in threads]
    [t.join() for t in threads]
    assert not errors, errors
    assert sorted(results) == list(range(1, 13)), sorted(results)
finally:
    with psycopg.connect(target.database_url, autocommit=True) as cleanup:
        cleanup.execute("delete from orders where business_id=%s", (biz,))
        cleanup.execute("delete from businesses where id=%s", (biz,))

print("d64_order_number: PASS")
