"""Batch planning acceptance: capacity split and multi-driver allocation
(migration 20261012120000).

Live staging test, NOT rollback-only: retries and concurrency need separately
committing connections. Every fixture lives in disposable businesses and auth
users created here and deleted (cascade) at the end.

Run from tests/ with the staging environment loaded."""

import json
import os
import threading
import urllib.error
import urllib.request
import uuid

import psycopg
from psycopg.types.json import Jsonb

from environment_guard import TargetRefused, validate_database_target

try:
    target = validate_database_target(
        mutating=True,
        allowed_environments=frozenset({"local", "staging", "test"}),
    )
except TargetRefused as error:
    raise SystemExit(f"target_refused: {error}") from error

conn = psycopg.connect(target.database_url, autocommit=True)
cur = conn.cursor()
created_businesses, created_users = [], []
results = []


def check(name, cond, extra=""):
    results.append((name, bool(cond), extra))
    print(f"{'PASS' if cond else 'FAIL'}  {name}" + (f"  -> {extra}" if extra and not cond else ""))


def actor(c, user_id):
    c.execute("reset role")
    c.execute(
        "select set_config('request.jwt.claim.sub',%s,false),set_config('request.jwt.claim.role','authenticated',false)",
        (str(user_id),),
    )
    c.execute("set role authenticated")


def as_admin(c):
    c.execute("reset role")


def new_business(name):
    owner = uuid.uuid4()
    as_admin(cur)
    cur.execute(
        "insert into auth.users(id,aud,role,email,created_at,updated_at) values(%s,'authenticated','authenticated',%s,now(),now())",
        (owner, f"batch-plan-{uuid.uuid4()}@test.invalid"),
    )
    created_users.append(owner)
    cur.execute(
        "insert into businesses(name,service_origin_latitude,service_origin_longitude) values(%s,3.1,101.6) returning id",
        (f"[TEST] Batch planning {name}",),
    )
    biz = cur.fetchone()[0]
    created_businesses.append(biz)
    cur.execute("insert into business_members(business_id,user_id,role) values(%s,%s,'owner')", (biz, owner))
    return biz, owner


def new_rider(biz, name, vehicle, status="active"):
    as_admin(cur)
    cur.execute(
        "insert into riders(business_id,name,phone,status,vehicle_type) values(%s,%s,%s,%s,%s) returning id",
        (biz, name, f"+60{uuid.uuid4().int % 10**9:09d}", status, vehicle),
    )
    return cur.fetchone()[0]


def new_zone(biz, name):
    as_admin(cur)
    cur.execute("insert into zones(business_id,name) values(%s,%s) returning id", (biz, name))
    return cur.fetchone()[0]


def new_orders(biz, owner, n, zone=None, req="any", prep="not_started", resolved=True, spread=0):
    ids = []
    actor(cur, owner)
    for i in range(n):
        cur.execute(
            "select create_delivery(%s,%s,%s,'Addr','')",
            (biz, f"Customer {i}", f"+60197{uuid.uuid4().int % 10**6:06d}"),
        )
        ids.append(uuid.UUID(cur.fetchone()[0]["order"]["id"]))
    as_admin(cur)
    for i, oid in enumerate(ids):
        # Deterministic positions along a line, so the sequence is reproducible.
        cur.execute(
            "update orders set latitude=%s, longitude=%s, location_status=%s, approved_at=now(), zone_id=%s, vehicle_requirement=%s where id=%s",
            (3.1 + 0.001 * (i + 1 + spread), 101.6, "resolved" if resolved else "unresolved", zone, req, oid),
        )
        cur.execute("update delivery_stops set preparation_status=%s where order_id=%s", (prep, oid))
    return ids


def propose(owner, biz, riders=None, policy=None):
    actor(cur, owner)
    args, sql = [biz], "p_business_id=>%s"
    if riders is not None:
        sql += ",p_rider_ids=>%s::uuid[]"
        args.append(riders)
    if policy is not None:
        sql += ",p_policy=>%s"
        args.append(policy)
    cur.execute(f"select propose_delivery_plan({sql})", args)
    out = cur.fetchone()[0]
    as_admin(cur)
    return out


def propose_error(owner, biz, **kw):
    try:
        propose(owner, biz, **kw)
    except psycopg.Error as error:
        as_admin(cur)
        return str(error).splitlines()[0]
    return None


def sizes(plan):
    return [len(g["stops"]) for g in plan["groups"]]


def reasons(plan):
    out = {}
    for u in plan["unplannable_orders"]:
        out[u["reason"]] = out.get(u["reason"], 0) + 1
    return out


def conserved(plan, eligible):
    seen = [s["order_id"] for g in plan["groups"] for s in g["stops"]]
    seen += [u["order_id"] for u in plan["unplannable_orders"] if u["reason"] != "declined_awaiting_recovery"]
    return sorted(seen) == sorted(str(x) for x in eligible) and len(seen) == len(set(seen))


def capacity_ok(plan, caps):
    riders = [g["candidate_rider_id"] for g in plan["groups"]]
    if len(riders) != len(set(riders)):
        return False
    return all(len(g["stops"]) <= caps[g["candidate_rider_id"]] for g in plan["groups"])


def build(owner, session, rider, orders, key):
    actor(cur, owner)
    try:
        cur.execute("select build_rider_run(%s,%s,%s,%s)", (session, rider, orders, key))
        return cur.fetchone()[0], None
    except psycopg.Error as error:
        return None, str(error).splitlines()[0]
    finally:
        as_admin(cur)


def new_session(owner, biz):
    actor(cur, owner)
    cur.execute("select (create_delivery_session(%s,'[TEST] plan',(now() at time zone 'Asia/Kuala_Lumpur')::date)).id", (biz,))
    sid = cur.fetchone()[0]
    as_admin(cur)
    return sid


def group_orders(g):
    return [uuid.UUID(s["order_id"]) for s in g["stops"]]


try:
    # --- S1: 30 orders, one zone, motorcycle 6 / motorcycle 6 / car 12 -------
    biz, owner = new_business("S1")
    z = new_zone(biz, "Alpha")
    m1, m2, c1 = new_rider(biz, "Moto 1", "motorcycle"), new_rider(biz, "Moto 2", "motorcycle"), new_rider(biz, "Car 1", "car")
    orders = new_orders(biz, owner, 30, zone=z)
    caps = {str(m1): 6, str(m2): 6, str(c1): 12}
    plan = propose(owner, biz)
    check("S1 default policy is balance", plan["policy"] == "balance", plan["policy"])
    check("S1 balance 30 orders, 6/6/12 riders -> runs 6,6,12", sorted(sizes(plan)) == [6, 6, 12], sizes(plan))
    check("S1 6 orders insufficient_capacity", reasons(plan) == {"insufficient_capacity": 6}, reasons(plan))
    check("S1 every order exactly once", conserved(plan, orders))
    check("S1 capacity respected, one group per rider", capacity_ok(plan, caps))
    check("S1 runs are consecutive straight-line segments (part 1..3 of 3)", [g["part"] for g in plan["groups"]] == [1, 2, 3] and all(g["parts"] == 3 for g in plan["groups"]))
    again = propose(owner, biz)
    plan.pop("generated_at"); again.pop("generated_at")
    check("S1 deterministic: same input, same plan", plan == again)
    fill = propose(owner, biz, policy="fill")
    check("S1 fill gives the same feasible 6,6,12", sorted(sizes(fill)) == [6, 6, 12], sizes(fill))
    check("S1 invalid policy refused", "invalid policy" in (propose_error(owner, biz, policy="fastest") or ""))

    # --- S2: 30 orders, three cars ------------------------------------------
    biz2, owner2 = new_business("S2")
    z2 = new_zone(biz2, "Alpha")
    cars = [new_rider(biz2, f"Car {i}", "car") for i in range(3)]
    orders2 = new_orders(biz2, owner2, 30, zone=z2)
    bal = propose(owner2, biz2)
    check("S2 balance, three cars -> 10/10/10", sizes(bal) == [10, 10, 10], sizes(bal))
    check("S2 every order exactly once", conserved(bal, orders2))
    fl = propose(owner2, biz2, policy="fill")
    check("S2 fill, three cars -> 12/12/6", sizes(fl) == [12, 12, 6], sizes(fl))
    small = propose(owner2, biz2, riders=[str(c) for c in cars])
    check("S2 explicit selection equals all active", sizes(small) == [10, 10, 10])

    # S2 commit: retry with the same key, then a concurrent overlapping commit.
    sess = new_session(owner2, biz2)
    g0 = bal["groups"][0]
    key = uuid.uuid4()
    r1, e1 = build(owner2, sess, uuid.UUID(g0["candidate_rider_id"]), group_orders(g0), key)
    r2, e2 = build(owner2, sess, uuid.UUID(g0["candidate_rider_id"]), group_orders(g0), key)
    check("S2 commit group 1", r1 is not None, e1)
    check("S2 retry with the same key returns the same result", r2 == r1, e2)
    g1, g2 = bal["groups"][1], bal["groups"][2]
    overlap = group_orders(g1)
    ca = psycopg.connect(target.database_url, autocommit=False)
    cb = psycopg.connect(target.database_url, autocommit=False)
    xa, xb = ca.cursor(), cb.cursor()
    actor(xa, owner2)
    actor(xb, owner2)
    xa.execute("select build_rider_run(%s,%s,%s,%s)", (sess, uuid.UUID(g1["candidate_rider_id"]), overlap, uuid.uuid4()))
    outcome = {}

    def other():
        try:
            xb.execute("select build_rider_run(%s,%s,%s,%s)", (sess, uuid.UUID(g2["candidate_rider_id"]), overlap, uuid.uuid4()))
            outcome["ok"] = True
        except psycopg.Error as error:
            outcome["error"] = str(error)

    t = threading.Thread(target=other)
    t.start()
    ca.commit()
    t.join(timeout=15)
    cb.rollback()
    ca.close(); cb.close()
    check("S2 concurrent overlapping commit: one wins, the other is refused", "orders no longer eligible" in outcome.get("error", ""), outcome)
    cur.execute("select count(distinct assigned_rider_id), count(*) from orders where id = any(%s)", (overlap,))
    one_rider, n = cur.fetchone()
    check("S2 contested orders belong to exactly one rider", one_rider == 1 and n == 10)

    # Repeated planning: riders with an open run are excluded.
    re = propose(owner2, biz2)
    ex = {e["rider_id"]: e["reason"] for e in re["excluded_riders"]}
    check("S2 replanning excludes riders with an open run", ex.get(g0["candidate_rider_id"]) == "rider_has_open_run" and ex.get(g1["candidate_rider_id"]) == "rider_has_open_run", ex)
    remaining_orders = [o for o in orders2 if o not in group_orders(g0) and o not in overlap]
    check("S2 replanning puts the remaining 10 on the free rider", sizes(re) == [10] and re["groups"][0]["candidate_rider_id"] == g2["candidate_rider_id"], sizes(re))
    check("S2 replanning conserves the remaining orders", conserved(re, remaining_orders))

    # --- S3: two zones of 8 share one car -----------------------------------
    biz3, owner3 = new_business("S3")
    za, zb = new_zone(biz3, "Alpha"), new_zone(biz3, "Beta")
    car = new_rider(biz3, "Car", "car")
    oa = new_orders(biz3, owner3, 8, zone=za)
    ob = new_orders(biz3, owner3, 8, zone=zb, spread=100)
    p3 = propose(owner3, biz3)
    check("S3 zone Alpha (name order on equal size) planned on the car", sizes(p3) == [8] and p3["groups"][0]["zone_id"] == str(za), sizes(p3))
    check("S3 zone Beta reported insufficient_capacity", reasons(p3) == {"insufficient_capacity": 8} and all(u["zone_id"] == str(zb) for u in p3["unplannable_orders"]))
    check("S3 every order exactly once", conserved(p3, oa + ob))
    s3 = new_session(owner3, biz3)
    _, err3 = build(owner3, s3, car, oa, uuid.uuid4())
    check("S3 commit Alpha", err3 is None, err3)
    p3b = propose(owner3, biz3)
    check("S3 replanning while Alpha is open: car excluded, Beta still unplanned",
          p3b["groups"] == [] and p3b["excluded_riders"][0]["reason"] == "rider_has_open_run" and reasons(p3b) == {"insufficient_capacity": 8})
    # Alpha run finishes (fixture: the Driver completes every stop).
    cur.execute("update delivery_stops set status='delivered' where order_id = any(%s)", (oa,))
    cur.execute("update orders set delivery_status='delivered' where id = any(%s)", (oa,))
    cur.execute("update rider_assignments set status='completed', completed_at=now() where rider_id=%s", (car,))
    p3c = propose(owner3, biz3)
    check("S3 after Alpha completes, Beta plans on the car in a new run", sizes(p3c) == [8] and p3c["groups"][0]["zone_id"] == str(zb), sizes(p3c))

    # --- S4: mixed vehicle requirements -------------------------------------
    biz4, owner4 = new_business("S4")
    z4 = new_zone(biz4, "Alpha")
    moto4, car4 = new_rider(biz4, "Moto", "motorcycle"), new_rider(biz4, "Car", "car")
    vans = new_orders(biz4, owner4, 2, zone=z4, req="van_required")
    anys = new_orders(biz4, owner4, 10, zone=z4, spread=50)
    p4 = propose(owner4, biz4)
    check("S4 no van: 2 orders vehicle_incompatible", reasons(p4) == {"vehicle_incompatible": 2}, reasons(p4))
    check("S4 the other 10 balanced over moto + car (5/5)", sorted(sizes(p4)) == [5, 5], sizes(p4))
    check("S4 every order exactly once", conserved(p4, vans + anys))
    van = new_rider(biz4, "Van", "van")
    p4b = propose(owner4, biz4)
    vg = [g for g in p4b["groups"] if g["tier"] == "van_required"]
    check("S4 van takes the van orders first", len(vg) == 1 and vg[0]["candidate_rider_id"] == str(van) and len(vg[0]["stops"]) == 2)
    check("S4 remaining 10 on moto + car, no shortfall", sorted(len(g["stops"]) for g in p4b["groups"] if g["tier"] == "any") == [5, 5] and reasons(p4b) == {})
    check("S4 every order exactly once (with van)", conserved(p4b, vans + anys))

    # --- S5: preparation and location states --------------------------------
    biz5, owner5 = new_business("S5")
    z5 = new_zone(biz5, "Alpha")
    new_rider(biz5, "Car", "car")
    prep = new_orders(biz5, owner5, 1, zone=z5, prep="preparing") + new_orders(biz5, owner5, 1, zone=z5, prep="sorted", spread=10)
    ready = new_orders(biz5, owner5, 1, zone=z5, prep="packed", spread=20) + new_orders(biz5, owner5, 1, zone=z5, prep="not_started", spread=30)
    staged = new_orders(biz5, owner5, 1, zone=z5, prep="ready", spread=35)
    unres = new_orders(biz5, owner5, 1, zone=z5, resolved=False, spread=40)
    p5 = propose(owner5, biz5)
    check("S5 preparing/sorted/ready (refused by build_rider_run or the plan lock) -> in_preparation", reasons(p5).get("in_preparation") == 3, reasons(p5))
    check("S5 unresolved location -> location_unresolved", reasons(p5).get("location_unresolved") == 1, reasons(p5))
    check("S5 not_started/packed orders are planned", sizes(p5) == [2])
    check("S5 every order exactly once", conserved(p5, prep + ready + staged + unres))
    s5 = new_session(owner5, biz5)
    g5 = p5["groups"][0]
    _, err5 = build(owner5, s5, uuid.UUID(g5["candidate_rider_id"]), group_orders(g5), uuid.uuid4())
    check("S5 the proposed run commits (build_rider_run agrees with the planner)", err5 is None, err5)

    # --- S6: rider selection --------------------------------------------------
    biz6, owner6 = new_business("S6")
    z6 = new_zone(biz6, "Alpha")
    a6, b6 = new_rider(biz6, "Car A", "car"), new_rider(biz6, "Car B", "car")
    inactive6 = new_rider(biz6, "Car C", "car", status="inactive")
    o6 = new_orders(biz6, owner6, 6, zone=z6)
    foreign = new_rider(biz, "Elsewhere", "car")
    p6 = propose(owner6, biz6, riders=[str(a6)])
    check("S6 subset: only the selected rider is used", [g["candidate_rider_id"] for g in p6["groups"]] == [str(a6)])
    check("S6 empty selection refused", "no drivers selected" in (propose_error(owner6, biz6, riders=[]) or ""))
    p6b = propose(owner6, biz6, riders=[str(a6), str(foreign), str(inactive6), str(a6)])
    ex6 = {e["rider_id"]: e["reason"] for e in p6b["excluded_riders"]}
    check("S6 other business's rider -> not_eligible", ex6.get(str(foreign)) == "not_eligible", ex6)
    check("S6 inactive rider -> not_eligible", ex6.get(str(inactive6)) == "not_eligible", ex6)
    check("S6 duplicate ids counted once", len(p6b["groups"]) == 1 and len(p6b["excluded_riders"]) == 2)
    check("S6 not_eligible reveals no rider details", all(set(e) == {"rider_id", "reason"} for e in p6b["excluded_riders"]))
    # A rider whose load fills its capacity without an open run -> no_capacity.
    s6 = new_session(owner6, biz6)
    full = new_orders(biz6, owner6, 12, zone=z6, spread=200)
    _, err6 = build(owner6, s6, b6, full, uuid.uuid4())
    cur.execute("update rider_assignments set status='issue' where rider_id=%s", (b6,))
    cur.execute("update delivery_stops set status='issue' where rider_id=%s", (b6,))
    p6c = propose(owner6, biz6)
    ex6c = {e["rider_id"]: e["reason"] for e in p6c["excluded_riders"]}
    check("S6 rider at capacity (issue stops still count) -> no_capacity", err6 is None and ex6c.get(str(b6)) == "no_capacity", (err6, ex6c))
    check("S6 every eligible order exactly once", conserved(p6c, o6))

    # --- S7: declined runs ---------------------------------------------------
    biz7, owner7 = new_business("S7")
    z7 = new_zone(biz7, "Alpha")
    d7, e7 = new_rider(biz7, "Car D", "car"), new_rider(biz7, "Car E", "car")
    o7 = new_orders(biz7, owner7, 3, zone=z7)
    s7 = new_session(owner7, biz7)
    _, err7 = build(owner7, s7, d7, o7, uuid.uuid4())
    cur.execute("select rider_active_stop_count(%s)", (d7,))
    before = cur.fetchone()[0]
    # Fixture for decline_run's effect (the Driver app has no decline control):
    cur.execute("update rider_assignments set status='declined' where rider_id=%s and status='assigned'", (d7,))
    cur.execute("select rider_active_stop_count(%s)", (d7,))
    after = cur.fetchone()[0]
    check("S7 load counts an assigned run, not a declined one", err7 is None and before == 3 and after == 0, (err7, before, after))
    cur.execute("select count(*) from orders where id = any(%s) and assigned_rider_id = %s", (o7, d7))
    check("S7 decline leaves the orders assigned (unchanged behaviour)", cur.fetchone()[0] == 3)
    p7 = propose(owner7, biz7)
    check("S7 declined orders reported declined_awaiting_recovery, not planned", reasons(p7) == {"declined_awaiting_recovery": 3} and p7["groups"] == [], (reasons(p7), sizes(p7)))
    check("S7 declining rider is free again", not any(e["rider_id"] == str(d7) for e in p7["excluded_riders"]))
    _, err7b = build(owner7, s7, e7, o7, uuid.uuid4())
    check("S7 declined orders cannot be committed to another rider", err7b is not None and "orders no longer eligible" in err7b, err7b)
    actor(cur, owner7)
    cur.execute("select initiate_delivery_recovery(%s,%s,%s,%s)", (o7[0], "rider_unable_to_proceed", "test", uuid.uuid4()))
    as_admin(cur)
    p7b = propose(owner7, biz7)
    planned = {s["order_id"] for g in p7b["groups"] for s in g["stops"]}
    check("S7 after recovery the order is plannable again", str(o7[0]) in planned and reasons(p7b) == {"declined_awaiting_recovery": 2}, (sizes(p7b), reasons(p7b)))

    # --- S8: authorization ---------------------------------------------------
    outsider_biz, outsider = new_business("S8")
    err8 = propose_error(outsider, biz)
    check("S8 authenticated non-member -> forbidden", err8 is not None and "forbidden" in err8, err8)
    cur.execute("select has_function_privilege('anon','public.propose_delivery_plan(uuid,uuid[],text)','execute'), has_function_privilege('authenticated','public.propose_delivery_plan(uuid,uuid[],text)','execute')")
    anon_x, auth_x = cur.fetchone()
    check("S8 anon has no execute; authenticated has", anon_x is False and auth_x is True, (anon_x, auth_x))
    cur.execute("select count(*) from pg_proc where proname='propose_delivery_plan' and pronamespace='public'::regnamespace")
    check("S8 exactly one propose_delivery_plan signature", cur.fetchone()[0] == 1)

    # REST: PostgREST resolution of the one-argument call, as both clients make it.
    url, key = os.environ["SUPABASE_URL"], os.environ["SUPABASE_PUBLISHABLE_KEY"]

    def rest(token, body):
        req = urllib.request.Request(f"{url}/rest/v1/rpc/propose_delivery_plan", data=json.dumps(body).encode(), method="POST",
                                     headers={"apikey": key, "authorization": f"Bearer {token}", "content-type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                return r.status, json.loads(r.read())
        except urllib.error.HTTPError as e:
            return e.code, json.loads(e.read() or b"null")

    st, body = rest(key, {"p_business_id": str(biz)})
    check("S8 REST anon call refused", st in (401, 403) or (isinstance(body, dict) and "permission denied" in str(body.get("message", ""))), (st, body))
    tok_req = urllib.request.Request(f"{url}/auth/v1/token?grant_type=password", method="POST",
                                     data=json.dumps({"email": os.environ["STAGING_VENDOR_EMAIL"], "password": os.environ["STAGING_VENDOR_PASSWORD"]}).encode(),
                                     headers={"apikey": key, "content-type": "application/json"})
    with urllib.request.urlopen(tok_req, timeout=30) as r:
        vendor_token = json.loads(r.read())["access_token"]
    breq = urllib.request.Request(f"{url}/rest/v1/rpc/get_my_businesses", data=b"{}", method="POST",
                                  headers={"apikey": key, "authorization": f"Bearer {vendor_token}", "content-type": "application/json"})
    with urllib.request.urlopen(breq, timeout=30) as r:
        vendor_biz = json.loads(r.read())[0]["business_id"]
    st, body = rest(vendor_token, {"p_business_id": vendor_biz})
    check("S8 REST one-argument named call resolves (no ambiguity) for a member", st == 200 and "groups" in body and body.get("policy") == "balance", (st, str(body)[:200]))
    st, body = rest(vendor_token, {"p_business_id": vendor_biz, "p_policy": "fill"})
    check("S8 REST call with p_policy resolves", st == 200 and body.get("policy") == "fill", st)
    st, body = rest(vendor_token, {"p_business_id": str(biz)})
    check("S8 REST member of another business -> forbidden", st >= 400 and "forbidden" in str(body), (st, body))

    # --- S9: local business date ---------------------------------------------
    cur.execute("select (timestamptz '2026-10-12 16:30:00+00' at time zone 'Asia/Kuala_Lumpur')::date")
    check("S9 16:30 UTC is the next local day in Kuala Lumpur", str(cur.fetchone()[0]) == "2026-10-13")
    cur.execute("select (now() at time zone 'Asia/Kuala_Lumpur')::date")
    check("S9 plan_date is the business-local date", bal["plan_date"] == str(cur.fetchone()[0]), bal["plan_date"])
finally:
    as_admin(cur)
    for biz_id in created_businesses:
        cur.execute("delete from businesses where id = %s", (biz_id,))
    for user_id in created_users:
        cur.execute("delete from auth.users where id = %s", (user_id,))
    conn.close()

failed = [r for r in results if not r[1]]
print(f"\n{len(results) - len(failed)}/{len(results)} passed")
if failed:
    raise SystemExit(1)
print("batch_planning_capacity_split_ok")
