import os
import psycopg

EXPECTED_TABLES = {'businesses','business_members','riders','orders','rider_assignments','delivery_stops','delivery_events','rider_locations','tracking_tokens','ratings'}
EXPECTED_RPCS = {'bootstrap_business','get_my_businesses','create_delivery','assign_rider','rider_transition','complete_delivery','public_tracking','submit_rating'}

with psycopg.connect(os.environ['DATABASE_URL']) as conn:
    with conn.cursor() as cur:
        cur.execute("select table_name from information_schema.tables where table_schema='public'")
        tables = {r[0] for r in cur.fetchall()}
        assert EXPECTED_TABLES <= tables, EXPECTED_TABLES - tables
        cur.execute("select routine_name from information_schema.routines where routine_schema='public'")
        routines = {r[0] for r in cur.fetchall()}
        assert EXPECTED_RPCS <= routines, EXPECTED_RPCS - routines
        cur.execute("select relname, relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and relkind='r'")
        assert all(enabled for name, enabled in cur.fetchall()), 'RLS disabled'
        cur.execute("select public_tracking('invalid-token')")
        assert cur.fetchone()[0] is None
        cur.execute("select public from storage.buckets where id='cefflo-pod'")
        assert cur.fetchone() == (False,)
print('backend_contract_ok')
