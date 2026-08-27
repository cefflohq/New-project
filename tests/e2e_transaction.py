"""Transactional E2E for explicit disposable local, staging, or test targets."""
import uuid

import psycopg

from environment_guard import TargetRefused, validate_database_target

try:
    target = validate_database_target(
        mutating=True,
        allowed_environments=frozenset({'local', 'staging', 'test'}),
    )
except TargetRefused as error:
    raise SystemExit(f'target_refused: {error}') from error

owner, rider, outsider = [uuid.uuid4() for _ in range(3)]
with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for uid, email in [(owner,'owner@test.invalid'),(rider,'rider@test.invalid'),(outsider,'outsider@test.invalid')]:
            cur.execute("insert into auth.users(id,aud,role,email,created_at,updated_at) values(%s,'authenticated','authenticated',%s,now(),now())", (uid,email))
        def actor(uid, role='authenticated'):
            cur.execute("select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claim.role',%s,true)", (str(uid),role))
        actor(owner)
        cur.execute("select bootstrap_business('CEFFLO Test')")
        business = cur.fetchone()[0]
        cur.execute("insert into riders(business_id,auth_user_id,name,phone,status) values(%s,%s,'Test Rider','+60111111111','active') returning id", (business,rider))
        rider_id = cur.fetchone()[0]
        cur.execute("select create_delivery(%s,'Customer','+60122222222','Test Address')", (business,))
        created = cur.fetchone()[0]
        order_id, token = created['order']['id'], created['tracking_token']
        cur.execute("select assign_rider(%s,%s)", (order_id,rider_id))
        actor(outsider)
        cur.execute('savepoint unauthorized')
        try:
            cur.execute("select rider_transition(%s,'ready_for_pickup')", (order_id,))
            raise AssertionError('unassigned rider was allowed')
        except psycopg.errors.RaiseException:
            cur.execute('rollback to savepoint unauthorized')
        actor(rider)
        for status in ('ready_for_pickup','picked_up','out_for_delivery','arrived'):
            cur.execute('select rider_transition(%s,%s)', (order_id,status))
        cur.execute("select complete_delivery(%s,%s,'Delivered safely')", (order_id,f'orders/{order_id}/test.jpg'))
        actor(outsider,'anon')
        cur.execute('select public_tracking(%s)', (token,))
        assert cur.fetchone()[0]['status'] == 'delivered'
        cur.execute("select submit_rating(%s,5,array['Fast delivery'])", (token,))
        assert cur.fetchone()[0]
        cur.execute('select count(*) from delivery_events where order_id=%s', (order_id,))
        assert cur.fetchone()[0] == 7
        conn.rollback()
print('e2e_transaction_ok')
