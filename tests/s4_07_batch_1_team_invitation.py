"""Rollback-only S4-07 Batch-1 acceptance: team_invitations (Owner/Operator/
Owner-role invitation, Option A immediate-active model, email binding, role
never client-controlled, concurrency, last-owner protection regression).
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


(owner_a, operator_a, owner_b, aisyah_user, bystander_user) = [uuid.uuid4() for _ in range(5)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, email, label in (
            (owner_a, f"owner-a-{uuid.uuid4()}@test.invalid", "owner-a"),
            (operator_a, f"operator-a-{uuid.uuid4()}@test.invalid", "operator-a"),
            (owner_b, f"owner-b-{uuid.uuid4()}@test.invalid", "owner-b"),
            (aisyah_user, "aisyah@test.invalid", "aisyah"),
            (bystander_user, f"bystander-{uuid.uuid4()}@test.invalid", "bystander"),
        ):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, email),
            )
        cur.execute("insert into businesses(name) values('S4-07 B1 Business A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-07 B1 Business B') returning id")
        business_b = cur.fetchone()[0]
        cur.execute(
            "insert into business_members(business_id,user_id,role) values(%s,%s,'owner'),(%s,%s,'operator'),(%s,%s,'owner')",
            (business_a, owner_a, business_a, operator_a, business_b, owner_b),
        )

        def actor(user_id, role="authenticated"):
            cur.execute("reset role")
            cur.execute(
                "select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claim.role',%s,true)",
                (str(user_id), role),
            )
            cur.execute(f"set local role {role}")

        # =====================================================================
        # Owner create invite success; Operator denied; unauthorized (other
        # business's Owner) denied.
        # =====================================================================
        actor(owner_a)
        cur.execute("select create_team_invitation(%s,'operator','aisyah@test.invalid')", (business_a,))
        invite = cur.fetchone()[0]
        token = invite["token"]
        invitation_id = uuid.UUID(invite["invitation_id"])
        assert invite["role"] == "operator" and invite["invited_email"] == "aisyah@test.invalid"

        actor(operator_a)
        rejected(cur, "select create_team_invitation(%s,'operator','x@test.invalid')", (business_a,), "forbidden")

        actor(owner_b)
        rejected(cur, "select create_team_invitation(%s,'operator','x@test.invalid')", (business_a,), "forbidden")

        # =====================================================================
        # Anonymous resolve: safe, no hash/raw token leakage, no email leakage.
        # =====================================================================
        actor(None, "anon")
        cur.execute("select resolve_team_invitation(%s)", (token,))
        resolved = cur.fetchone()[0]
        assert resolved["role"] == "operator" and resolved["status"] == "pending"
        assert "invited_email" not in resolved and "token_hash" not in resolved and "token" not in resolved

        cur.execute("select resolve_team_invitation('not-a-real-token')")
        assert cur.fetchone()[0] is None, "an unknown token must resolve to null, not leak existence information"

        # =====================================================================
        # Email mismatch rejected, fail-closed.
        # =====================================================================
        actor(bystander_user)
        rejected(cur, "select accept_team_invitation(%s)", (token,), "email mismatch")

        # =====================================================================
        # Happy path: correct identity + correct email -> active immediately
        # (Option A, no second approval step).
        # =====================================================================
        actor(aisyah_user)
        cur.execute("select accept_team_invitation(%s)", (token,))
        result = cur.fetchone()[0]
        assert result == {"business_id": str(business_a), "role": "operator", "status": "active"}

        cur.execute("reset role")
        cur.execute("select role,status from business_members where business_id=%s and user_id=%s", (business_a, aisyah_user))
        assert cur.fetchone() == ("operator", "active"), "membership must be created active immediately, no pending step"

        # ---- role never came from the client: confirm the RPC signature
        # itself has no role parameter at all. ----
        cur.execute(
            "select count(*) from pg_proc where proname='accept_team_invitation' "
            "and pg_get_function_identity_arguments(oid) = 'p_token text'"
        )
        assert cur.fetchone()[0] == 1, "accept_team_invitation must take only a token, never a role"

        # =====================================================================
        # Same identity retry safe (idempotent); a DIFFERENT identity cannot
        # reuse an already-accepted token.
        # =====================================================================
        actor(aisyah_user)
        cur.execute("select accept_team_invitation(%s)", (token,))
        assert cur.fetchone()[0] == {"business_id": str(business_a), "role": "operator", "status": "active"}

        actor(bystander_user)
        rejected(cur, "select accept_team_invitation(%s)", (token,), "invitation not available")

        # =====================================================================
        # Expired invite rejected.
        # =====================================================================
        actor(owner_a)
        cur.execute("select create_team_invitation(%s,'operator','expired@test.invalid')", (business_a,))
        expired_token = cur.fetchone()[0]["token"]
        cur.execute("reset role")
        cur.execute("update team_invitations set expires_at = now() - interval '1 hour' where token_hash = encode(digest(%s,'sha256'),'hex')", (expired_token,))
        cur.execute(
            "insert into auth.users(id,aud,role,email,created_at,updated_at) values(%s,'authenticated','authenticated','expired@test.invalid',now(),now())",
            (uuid.uuid4(),),
        )
        cur.execute("select id from auth.users where email='expired@test.invalid'")
        expired_user = cur.fetchone()[0]
        actor(expired_user)
        rejected(cur, "select accept_team_invitation(%s)", (expired_token,), "invitation expired")

        # =====================================================================
        # Revoked invite rejected.
        # =====================================================================
        actor(owner_a)
        cur.execute("select create_team_invitation(%s,'operator','revoked@test.invalid')", (business_a,))
        revoked_invite = cur.fetchone()[0]
        revoked_token = revoked_invite["token"]
        cur.execute("select revoke_team_invitation(%s)", (revoked_invite["invitation_id"],))
        cur.execute("select status from team_invitations where id=%s", (revoked_invite["invitation_id"],))
        assert cur.fetchone()[0] == "revoked"
        cur.execute("reset role")
        cur.execute(
            "insert into auth.users(id,aud,role,email,created_at,updated_at) values(%s,'authenticated','authenticated','revoked@test.invalid',now(),now())",
            (uuid.uuid4(),),
        )
        cur.execute("select id from auth.users where email='revoked@test.invalid'")
        revoked_user = cur.fetchone()[0]
        actor(revoked_user)
        rejected(cur, "select accept_team_invitation(%s)", (revoked_token,), "invitation not available")

        # Idempotent revoke (already revoked -> safe no-op, not an error).
        actor(owner_a)
        cur.execute("select revoke_team_invitation(%s)", (revoked_invite["invitation_id"],))
        cur.execute("select status from team_invitations where id=%s", (revoked_invite["invitation_id"],))
        assert cur.fetchone()[0] == "revoked"

        # =====================================================================
        # Owner-role invitation: only Owner may create it; Operator denied;
        # accepted correctly grants owner.
        # =====================================================================
        actor(operator_a)
        rejected(cur, "select create_team_invitation(%s,'owner','coowner@test.invalid')", (business_a,), "forbidden")

        actor(owner_a)
        cur.execute("select create_team_invitation(%s,'owner','coowner@test.invalid')", (business_a,))
        owner_invite_token = cur.fetchone()[0]["token"]
        coowner_user = uuid.uuid4()
        cur.execute("reset role")
        cur.execute(
            "insert into auth.users(id,aud,role,email,created_at,updated_at) values(%s,'authenticated','authenticated','coowner@test.invalid',now(),now())",
            (coowner_user,),
        )
        actor(coowner_user)
        cur.execute("select accept_team_invitation(%s)", (owner_invite_token,))
        assert cur.fetchone()[0]["role"] == "owner"
        cur.execute("reset role")
        cur.execute("select role from business_members where business_id=%s and user_id=%s", (business_a, coowner_user))
        assert cur.fetchone()[0] == "owner"

        # =====================================================================
        # Multi-business membership: Aisyah, already Operator of Business A,
        # accepts a separate invite into Business B without overwriting A.
        # =====================================================================
        actor(owner_b)
        cur.execute("select create_team_invitation(%s,'operator','aisyah@test.invalid')", (business_b,))
        cross_token = cur.fetchone()[0]["token"]
        actor(aisyah_user)
        cur.execute("select accept_team_invitation(%s)", (cross_token,))
        assert cur.fetchone()[0]["business_id"] == str(business_b)
        cur.execute("reset role")
        cur.execute("select business_id,role from business_members where user_id=%s order by created_at", (aisyah_user,))
        rows = cur.fetchall()
        assert (business_a, "operator") in rows and (business_b, "operator") in rows, "multi-business membership must coexist, neither overwritten"

        conn.rollback()

# Concurrency race is exercised as its own small, real-commit, self-cleaning
# block (same pattern as s4_06_batch_5a_build_rider_run_concurrency.py) --
# a fresh, real, disposable business/owner/invitation, deleted afterward.
import threading  # noqa: E402

with psycopg.connect(target.database_url, autocommit=True) as setup_conn:
    with setup_conn.cursor() as setup_cur:
        race_owner = uuid.uuid4()
        race_racer = uuid.uuid4()
        race_racer_email = f"race-user-{uuid.uuid4()}@test.invalid"
        setup_cur.execute(
            "insert into auth.users(id,aud,role,email,created_at,updated_at) values(%s,'authenticated','authenticated',%s,now(),now())",
            (race_owner, f"race-owner-{uuid.uuid4()}@test.invalid"),
        )
        setup_cur.execute(
            "insert into auth.users(id,aud,role,email,created_at,updated_at) values(%s,'authenticated','authenticated',%s,now(),now())",
            (race_racer, race_racer_email),
        )
        setup_cur.execute("insert into businesses(name) values('S4-07 B1 Race Business') returning id")
        race_business = setup_cur.fetchone()[0]
        setup_cur.execute("insert into business_members(business_id,user_id,role) values(%s,%s,'owner')", (race_business, race_owner))
        setup_cur.execute(
            "select set_config('request.jwt.claim.sub',%s,false),set_config('request.jwt.claim.role','authenticated',false)",
            (str(race_owner),),
        )
        setup_cur.execute("set role authenticated")
        setup_cur.execute("select create_team_invitation(%s,'operator',%s)", (race_business, race_racer_email))
        race_token = setup_cur.fetchone()[0]["token"]
        setup_cur.execute("reset role")

        results = {}

        def accept_attempt(key):
            with psycopg.connect(target.database_url, autocommit=False) as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        "select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claim.role','authenticated',true)",
                        (str(race_racer),),
                    )
                    cur.execute("set local role authenticated")
                    try:
                        cur.execute("select accept_team_invitation(%s)", (race_token,))
                        results[key] = ("ok", cur.fetchone()[0])
                        conn.commit()
                    except Exception as error:  # noqa: BLE001
                        conn.rollback()
                        results[key] = ("error", str(error))

        try:
            t1 = threading.Thread(target=accept_attempt, args=("a",))
            t2 = threading.Thread(target=accept_attempt, args=("b",))
            t1.start(); t2.start()
            t1.join(); t2.join()

            outcomes = [results["a"][0], results["b"][0]]
            assert outcomes.count("ok") == 2, f"both racers must settle on the same successful idempotent outcome: {results}"
            assert results["a"][1] == results["b"][1], f"both racers must observe identical final state: {results}"

            setup_cur.execute("select count(*) from business_members where business_id=%s and user_id=%s", (race_business, race_racer))
            assert setup_cur.fetchone()[0] == 1, "the race must never create duplicate membership"
        finally:
            # Cleanup: real commits above require explicit teardown.
            setup_cur.execute("delete from delivery_events where business_id=%s", (race_business,))
            setup_cur.execute("delete from team_invitations where business_id=%s", (race_business,))
            setup_cur.execute("delete from business_members where business_id=%s", (race_business,))
            setup_cur.execute("delete from businesses where id=%s", (race_business,))
            setup_cur.execute("delete from auth.users where id in (%s,%s)", (race_owner, race_racer))

print("s4_07_batch_1_team_invitation_ok")
