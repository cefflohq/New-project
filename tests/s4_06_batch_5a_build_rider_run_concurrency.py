"""Live-connection concurrency acceptance for build_rider_run (S4-06.5a).

NOT rollback-only: genuine cross-transaction row-lock blocking and the
same-key racing-retry re-check both require two real, separately
committing connections. Creates its own disposable fixtures via real
commits and explicitly deletes them (cascade) at the end -- there is no
enclosing transaction to roll back."""

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


def actor(cur, user_id):
    # Session-scoped (not LOCAL) -- the setup connection runs in autocommit
    # mode, where each statement is its own transaction, so a transaction-
    # scoped SET LOCAL would revert before the next statement.
    cur.execute("reset role")
    cur.execute(
        "select set_config('request.jwt.claim.sub',%s,false),set_config('request.jwt.claim.role','authenticated',false)",
        (str(user_id),),
    )
    cur.execute("set role authenticated")


def new_order(cur, business_id, phone_suffix):
    cur.execute(
        "select create_delivery(%s,'B5a Concurrency Customer',%s,'Addr')",
        (business_id, f"+60195{phone_suffix:06d}"),
    )
    order_id = uuid.UUID(cur.fetchone()[0]["order"]["id"])
    cur.execute("select approve_order(%s)", (order_id,))
    return order_id


setup_conn = psycopg.connect(target.database_url, autocommit=True)
setup_cur = setup_conn.cursor()
business = None
owner = uuid.uuid4()

try:
    setup_cur.execute(
        "insert into auth.users(id,aud,role,email,created_at,updated_at) "
        "values(%s,'authenticated','authenticated',%s,now(),now())",
        (owner, f"s4-06-b5a-conc-owner-{uuid.uuid4()}@test.invalid"),
    )
    setup_cur.execute("insert into businesses(name) values('S4-06 B5a Concurrency') returning id")
    business = setup_cur.fetchone()[0]
    setup_cur.execute(
        "insert into business_members(business_id,user_id,role) values(%s,%s,'owner')",
        (business, owner),
    )
    # vehicle_type='van' (S4-11 Batch 3, Grow V1 Flow 2): this test's order
    # counts exercise row-locking/idempotency concurrency, not the separate
    # vehicle/capacity eligibility feature -- default motorcycle capacity
    # (6) would otherwise cap what this scenario can construct. Van gives
    # enough headroom (20) without the test needing to reason about capacity
    # at all.
    setup_cur.execute(
        "insert into riders(business_id,name,phone,status,vehicle_type) values(%s,'Ali',%s,'active','van') returning id",
        (business, f"+60{uuid.uuid4().int % 10**9:09d}"),
    )
    ali = setup_cur.fetchone()[0]
    setup_cur.execute(
        "insert into riders(business_id,name,phone,status,vehicle_type) values(%s,'Abu',%s,'active','van') returning id",
        (business, f"+60{uuid.uuid4().int % 10**9:09d}"),
    )
    abu = setup_cur.fetchone()[0]

    actor(setup_cur, owner)
    setup_cur.execute("select (create_delivery_session(%s,'Concurrency Wave', current_date)).id", (business,))
    session_id = setup_cur.fetchone()[0]

    overlap_orders = [new_order(setup_cur, business, i) for i in range(15)]
    same_key_orders = [new_order(setup_cur, business, 100 + i) for i in range(5)]
    setup_cur.execute("reset role")

    # =========================================================================
    # OVERLAPPING-SET CONCURRENCY
    # Request A: orders[0:10] -> Ali (commits first, holds the lock)
    # Request B: orders[7:15] -> Abu (blocks on the overlap, must lose fully)
    # =========================================================================
    conn_a = psycopg.connect(target.database_url, autocommit=False)
    conn_b = psycopg.connect(target.database_url, autocommit=False)
    cur_a = conn_a.cursor()
    cur_b = conn_b.cursor()
    actor(cur_a, owner)
    actor(cur_b, owner)

    key_a = uuid.uuid4()
    key_b = uuid.uuid4()

    cur_a.execute(
        "select build_rider_run(%s,%s,%s,%s)",
        (session_id, ali, overlap_orders[0:10], key_a),
    )

    b_outcome = {}

    def run_b():
        try:
            cur_b.execute(
                "select build_rider_run(%s,%s,%s,%s)",
                (session_id, abu, overlap_orders[7:15], key_b),
            )
            b_outcome["value"] = cur_b.fetchone()[0]
        except psycopg.Error as error:
            b_outcome["error"] = str(error)

    thread_b = threading.Thread(target=run_b)
    thread_b.start()
    conn_a.commit()
    thread_b.join(timeout=10)
    assert not thread_b.is_alive(), "request B did not resolve after A committed"
    conn_b.rollback()

    assert "error" in b_outcome, f"request B should have been rejected, got {b_outcome}"
    assert "orders no longer eligible" in b_outcome["error"], b_outcome["error"]

    verify_conn = psycopg.connect(target.database_url, autocommit=True)
    verify_cur = verify_conn.cursor()
    verify_cur.execute(
        "select assigned_rider_id from orders where id = any(%s)", (overlap_orders[0:10],)
    )
    assert all(row[0] == ali for row in verify_cur.fetchall()), "A's full 10-order set must be committed"
    verify_cur.execute(
        "select assigned_rider_id from orders where id = any(%s)", (overlap_orders[10:15],)
    )
    assert all(row[0] is None for row in verify_cur.fetchall()), (
        "B's non-overlapping orders (11-15) must remain untouched -- zero partial mutation for the loser"
    )
    verify_cur.execute(
        "select count(*) from delivery_events where event_type='run.built' and (metadata->>'idempotency_key')::uuid = %s",
        (key_b,),
    )
    assert verify_cur.fetchone()[0] == 0, "the losing request must never emit run.built"

    # =========================================================================
    # SAME-KEY, SAME-PAYLOAD CONCURRENCY (racing retries of one Confirm Run)
    # Both C and D submit session_id/Ali/same_key_orders with the SAME key.
    # C commits first; D, on resuming, must re-check and return C's success.
    # =========================================================================
    conn_c = psycopg.connect(target.database_url, autocommit=False)
    conn_d = psycopg.connect(target.database_url, autocommit=False)
    cur_c = conn_c.cursor()
    cur_d = conn_d.cursor()
    actor(cur_c, owner)
    actor(cur_d, owner)

    key_cd = uuid.uuid4()

    cur_c.execute(
        "select build_rider_run(%s,%s,%s,%s)",
        (session_id, ali, same_key_orders, key_cd),
    )
    c_result = cur_c.fetchone()[0]

    d_outcome = {}

    def run_d():
        try:
            cur_d.execute(
                "select build_rider_run(%s,%s,%s,%s)",
                (session_id, ali, same_key_orders, key_cd),
            )
            d_outcome["value"] = cur_d.fetchone()[0]
        except psycopg.Error as error:
            d_outcome["error"] = str(error)

    thread_d = threading.Thread(target=run_d)
    thread_d.start()
    conn_c.commit()
    thread_d.join(timeout=10)
    assert not thread_d.is_alive(), "request D did not resolve after C committed"
    conn_d.rollback()

    assert "error" not in d_outcome, f"the racing same-key/same-payload request must resolve to success, got {d_outcome}"
    assert d_outcome["value"] == c_result, "D must resolve to the exact same committed result as C"

    verify_cur.execute(
        "select count(*) from delivery_events where event_type='run.built' and (metadata->>'idempotency_key')::uuid = %s",
        (key_cd,),
    )
    assert verify_cur.fetchone()[0] == 1, "racing same-key/same-payload calls must produce exactly one run.built"
    verify_cur.execute(
        "select count(*) from delivery_events where event_type in ('session.order_attached','rider.assigned') "
        "and order_id = any(%s)",
        (same_key_orders,),
    )
    assert verify_cur.fetchone()[0] == 2 * len(same_key_orders), (
        "racing same-key/same-payload calls must not double the per-order events"
    )

    print("s4_06_batch_5a_build_rider_run_concurrency_ok")
finally:
    cleanup_conn = psycopg.connect(target.database_url, autocommit=True)
    cleanup_cur = cleanup_conn.cursor()
    if business is not None:
        cleanup_cur.execute("delete from businesses where id = %s", (business,))
    cleanup_cur.execute("delete from auth.users where id = %s", (owner,))
    cleanup_conn.close()
    setup_conn.close()
