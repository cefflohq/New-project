"""Rollback-only acceptance for migration 20261012140000: sorting requires a
Run. Packing may start before a Run; sorting (per order or per group) is
refused without one; with a Run the existing flow, plan lock and
preparation rules are unchanged.

Everything runs in one transaction that is rolled back. If the target does
not have the migration yet, it is applied inside that same transaction, so
nothing persists either way."""

import pathlib
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

MIGRATION = pathlib.Path(__file__).resolve().parent.parent / "supabase/migrations/20261012140000_sorting_requires_run.sql"
results = []


def check(name, cond, extra=""):
    results.append(bool(cond))
    print(f"{'PASS' if cond else 'FAIL'}  {name}" + (f"  -> {extra}" if extra and not cond else ""))


def act(cur, user_id):
    cur.execute("reset role")
    cur.execute(
        "select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claim.role','authenticated',true)",
        (str(user_id),),
    )
    cur.execute("set local role authenticated")


def admin(cur):
    cur.execute("reset role")


def attempt(cur, sql, params=()):
    """Run in a savepoint; return (value, error message)."""
    sp = f"sp_{uuid.uuid4().hex}"
    cur.execute(f"savepoint {sp}")
    try:
        cur.execute(sql, params)
        row = cur.fetchone() if cur.description else None
        cur.execute(f"release savepoint {sp}")
        return (row[0] if row else None), None
    except psycopg.Error as error:
        cur.execute(f"rollback to savepoint {sp}")
        return None, str(error).splitlines()[0]


with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        cur.execute("select prosrc like '%sorting requires a run%' from pg_proc where proname = 'advance_preparation'")
        if not cur.fetchone()[0]:
            cur.execute(MIGRATION.read_text())
            print("note: migration applied inside the test transaction (rolled back at the end)")

        owner = uuid.uuid4()
        cur.execute(
            "insert into auth.users(id,aud,role,email,created_at,updated_at) values(%s,'authenticated','authenticated',%s,now(),now())",
            (owner, f"sorting-run-{uuid.uuid4()}@test.invalid"),
        )
        cur.execute("insert into businesses(name) values('[TEST] Sorting requires run') returning id")
        biz = cur.fetchone()[0]
        cur.execute("insert into business_members(business_id,user_id,role) values(%s,%s,'owner')", (biz, owner))
        cur.execute("insert into zones(business_id,name) values(%s,'Alpha') returning id", (biz,))
        zone = cur.fetchone()[0]
        cur.execute(
            "insert into riders(business_id,name,phone,status,vehicle_type) values(%s,'Ali',%s,'active','car') returning id",
            (biz, f"+60{uuid.uuid4().int % 10**9:09d}"),
        )
        rider = cur.fetchone()[0]

        act(cur, owner)
        orders = []
        for i in range(3):
            cur.execute("select create_delivery(%s,%s,%s,'Addr','')", (biz, f"C{i}", f"+60198{uuid.uuid4().int % 10**6:06d}"))
            orders.append(uuid.UUID(cur.fetchone()[0]["order"]["id"]))
            cur.execute("select approve_order(%s)", (orders[-1],))
        admin(cur)
        cur.execute("update orders set zone_id = %s where id = any(%s)", (zone, orders))
        cur.execute("select order_date from orders where id = %s", (orders[0],))
        day = cur.fetchone()[0]
        no_run, in_run, extra = orders

        # 1. Packing without a Run is still allowed.
        act(cur, owner)
        ok_prep = all(attempt(cur, "select (advance_preparation(%s,'preparing')).preparation_status", (o,))[1] is None for o in orders)
        ok_pack = all(attempt(cur, "select (advance_preparation(%s,'packed')).preparation_status", (o,))[1] is None for o in orders)
        _, err_cp = attempt(cur, "select confirm_packing(%s,%s,%s)", (biz, zone, day))
        check("packing without a run: preparing -> packed and confirm_packing", ok_prep and ok_pack and err_cp is None, err_cp)

        # 2. Sorting without a Run is refused, per order and per group.
        _, err_sort = attempt(cur, "select advance_preparation(%s,'sorted')", (no_run,))
        check("advance_preparation(sorted) without a run is refused", err_sort and "sorting requires a run" in err_sort, err_sort)
        _, err_group = attempt(cur, "select confirm_sorting(%s,%s,null,%s)", (biz, zone, day))
        check("confirm_sorting without a run is refused", err_group and "sorting requires a run" in err_group, err_group)
        admin(cur)
        cur.execute("select preparation_status from delivery_stops where order_id = %s", (no_run,))
        check("the refused order stays packed", cur.fetchone()[0] == "packed")

        # 3. With a Run the existing sorting flow works.
        act(cur, owner)
        cur.execute("select (create_delivery_session(%s,'Run 1',current_date)).id", (biz,))
        session = cur.fetchone()[0]
        _, err_build = attempt(cur, "select build_rider_run(%s,%s,%s,%s)", (session, rider, [in_run, extra], uuid.uuid4()))
        check("a packed order can join a run (build_rider_run)", err_build is None, err_build)
        _, err_sorted = attempt(cur, "select advance_preparation(%s,'sorted')", (in_run,))
        _, err_sorted2 = attempt(cur, "select advance_preparation(%s,'sorted')", (extra,))
        check("advance_preparation(sorted) with a run works", err_sorted is None and err_sorted2 is None, (err_sorted, err_sorted2))
        res, err_cs = attempt(cur, "select confirm_sorting(%s,%s,%s,null)", (biz, zone, session))
        check("confirm_sorting with a run makes the group ready", err_cs is None and res and res.get("newly_ready") == 2, (err_cs, res))
        admin(cur)
        cur.execute("select preparation_status from delivery_stops where order_id = any(%s)", ([in_run, extra],))
        check("both run orders are ready", {r[0] for r in cur.fetchall()} == {"ready"})

        # 4. Existing guards and transitions are unchanged.
        cur.execute("select sorting_started_at is not null from delivery_sessions where id = %s", (session,))
        check("first sort still locks the run plan", cur.fetchone()[0])
        act(cur, owner)
        cur.execute("select (create_delivery_session(%s,'Run 2',current_date)).id", (biz,))
        session2 = cur.fetchone()[0]
        _, err_move = attempt(cur, "select attach_order_to_session(%s,%s)", (in_run, session2))
        check("plan-lock guard still refuses moving a sorted order", err_move and "delivery plan locked" in err_move, err_move)
        _, err_ready = attempt(cur, "select advance_preparation(%s,'ready')", (no_run,))
        check("per-order ready is still refused", err_ready and "ready requires sorting confirmation" in err_ready, err_ready)
        _, err_skip = attempt(cur, "select advance_preparation(%s,'preparing')", (no_run,))
        check("backward transition is still refused", err_skip and "invalid preparation transition" in err_skip, err_skip)
        # The packed order without a run can still join a new run and be sorted there.
        _, err_build2 = attempt(cur, "select build_rider_run(%s,%s,%s,%s)", (session2, rider, [no_run], uuid.uuid4()))
        _, err_sort3 = attempt(cur, "select advance_preparation(%s,'sorted')", (no_run,))
        check("the waiting packed order joins a run later and is then sortable", err_build2 is None and err_sort3 is None, (err_build2, err_sort3))
        admin(cur)
    conn.rollback()

print(f"\n{sum(results)}/{len(results)} passed (rolled back)")
if not all(results):
    raise SystemExit(1)
print("sorting_requires_run_ok")
