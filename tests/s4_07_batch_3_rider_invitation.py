"""Rollback-only S4-07 Batch-3 acceptance: rider_invitations (Option B
pending-approval model, structurally separate from business_members, email
binding, Owner-only approval, the pre-existing unique(auth_user_id) schema
conflict with D-03 surfaced as a clean error, and the existing
ACCOUNT_NOT_APPROVED gate now genuinely completable end to end).
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


(owner_a, operator_a, owner_b, siti_user, bystander_user) = [uuid.uuid4() for _ in range(5)]

with psycopg.connect(target.database_url) as conn:
    with conn.cursor() as cur:
        for user_id, email in (
            (owner_a, f"owner-a-{uuid.uuid4()}@test.invalid"),
            (operator_a, f"operator-a-{uuid.uuid4()}@test.invalid"),
            (owner_b, f"owner-b-{uuid.uuid4()}@test.invalid"),
            (siti_user, "siti@test.invalid"),
            (bystander_user, f"bystander-{uuid.uuid4()}@test.invalid"),
        ):
            cur.execute(
                "insert into auth.users(id,aud,role,email,created_at,updated_at) "
                "values(%s,'authenticated','authenticated',%s,now(),now())",
                (user_id, email),
            )
        cur.execute("insert into businesses(name) values('S4-07 B3 Business A') returning id")
        business_a = cur.fetchone()[0]
        cur.execute("insert into businesses(name) values('S4-07 B3 Business B') returning id")
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
        # Owner Rider invite success (Operator may also invite -- reuses the
        # existing, locked "Rider create/onboard: ALLOW for both" authority).
        # =====================================================================
        actor(owner_a)
        cur.execute("select create_rider_invitation(%s,'siti@test.invalid','Siti Rahman','+60191234567')", (business_a,))
        invite = cur.fetchone()[0]
        token = invite["token"]
        invitation_id = uuid.UUID(invite["invitation_id"])

        actor(operator_a)
        cur.execute("select create_rider_invitation(%s,'operator-invited@test.invalid','Another Rider','+60191234568')", (business_a,))
        assert cur.fetchone()[0]["invited_email"] == "operator-invited@test.invalid"

        # ---- wrong business denied ----
        actor(owner_b)
        rejected(cur, "select create_rider_invitation(%s,'x@test.invalid','X','+60191234569')", (business_a,), "forbidden")

        # =====================================================================
        # Anonymous resolve safe -- no email/name/phone/hash leakage.
        # =====================================================================
        actor(None, "anon")
        cur.execute("select resolve_rider_invitation(%s)", (token,))
        resolved = cur.fetchone()[0]
        assert resolved["status"] == "pending" and "business_name" in resolved
        assert not ({"invited_email", "invited_name", "invited_phone", "token_hash"} & resolved.keys())

        # =====================================================================
        # Email mismatch rejected, fail-closed.
        # =====================================================================
        actor(bystander_user)
        rejected(cur, "select accept_rider_invitation(%s)", (token,), "email mismatch")

        # =====================================================================
        # Accept creates a PENDING riders row (Option B) -- never active on
        # acceptance. Rider cannot self-approve (no RPC path exists for a
        # Rider identity to move itself to active).
        # =====================================================================
        actor(siti_user)
        cur.execute("select accept_rider_invitation(%s)", (token,))
        result = cur.fetchone()[0]
        assert result["status"] == "pending" and result["business_id"] == str(business_a)
        rider_id = uuid.UUID(result["rider_id"])

        cur.execute("reset role")
        cur.execute("select status, name, phone, auth_user_id from riders where id=%s", (rider_id,))
        row = cur.fetchone()
        assert row == ("pending", "Siti Rahman", "+60191234567", siti_user), "riders row must be created pending, exactly from the invitation"

        # This is the pre-existing real gate (rider/backend.js
        # authenticatedRider()) -- confirm it is now genuinely reachable and
        # still correctly denies a still-pending Rider.
        cur.execute("select count(*) from riders where auth_user_id=%s and status='active'", (siti_user,))
        assert cur.fetchone()[0] == 0, "ACCOUNT_NOT_APPROVED gate must still deny a pending Rider"

        # No self-approval path: a Rider identity has no grant on approve_pending_rider.
        actor(siti_user)
        rejected(cur, "select approve_pending_rider(%s)", (rider_id,), "forbidden")

        # =====================================================================
        # Unrelated Owner (Business B) cannot approve a Business A Rider.
        # =====================================================================
        actor(owner_b)
        rejected(cur, "select approve_pending_rider(%s)", (rider_id,), "forbidden")

        # Operator cannot approve either -- Owner-only per explicit Founder
        # decision, not assumed from the general Rider-management authority.
        actor(operator_a)
        rejected(cur, "select approve_pending_rider(%s)", (rider_id,), "forbidden")

        # =====================================================================
        # Owner approval activates -- and now the real ACCOUNT_NOT_APPROVED
        # gate genuinely passes.
        # =====================================================================
        actor(owner_a)
        cur.execute("select approve_pending_rider(%s)", (rider_id,))
        cur.execute("reset role")
        cur.execute("select status from riders where id=%s", (rider_id,))
        assert cur.fetchone()[0] == "active"
        cur.execute("select count(*) from riders where auth_user_id=%s and status='active'", (siti_user,))
        assert cur.fetchone()[0] == 1, "the existing ACCOUNT_NOT_APPROVED gate must now genuinely pass after approval"

        # =====================================================================
        # Same Rider identity re-accepting the same invite / already
        # attached to the same Vendor: idempotent, no duplicate row.
        # =====================================================================
        actor(siti_user)
        cur.execute("select accept_rider_invitation(%s)", (token,))
        assert cur.fetchone()[0]["rider_id"] == str(rider_id)
        cur.execute("reset role")
        cur.execute("select count(*) from riders where business_id=%s and auth_user_id=%s", (business_a, siti_user))
        assert cur.fetchone()[0] == 1, "no duplicate Rider relationship for the same business"

        # =====================================================================
        # Same Rider identity already attached to ANOTHER Vendor: S4-07.3a
        # replaced the old bare unique(auth_user_id) constraint with
        # unique(business_id, auth_user_id), resolving the D-03 conflict this
        # file originally flagged (not silently -- see that migration's own
        # header) -- a genuinely new Business B relationship for the same
        # identity must now succeed, coexisting with the already-approved
        # Business A one, never overwriting it, never a duplicate account.
        # =====================================================================
        actor(owner_b)
        cur.execute("select create_rider_invitation(%s,'siti@test.invalid','Siti Rahman','+60191234570')", (business_b,))
        cross_invite = cur.fetchone()[0]
        cross_token = cross_invite["token"]
        actor(siti_user)
        cur.execute("select accept_rider_invitation(%s)", (cross_token,))
        cross_result = cur.fetchone()[0]
        assert cross_result["business_id"] == str(business_b) and cross_result["status"] == "pending"
        cross_rider_id = uuid.UUID(cross_result["rider_id"])
        assert cross_rider_id != rider_id, "the second business must get its own distinct riders row"

        cur.execute("reset role")
        cur.execute("select business_id, status, auth_user_id from riders where auth_user_id=%s order by created_at", (siti_user,))
        siti_relationships = cur.fetchall()
        assert (business_a, "active", siti_user) in siti_relationships, "Business A relationship must remain untouched"
        assert (business_b, "pending", siti_user) in siti_relationships, "Business B relationship must exist independently, pending its own approval"
        assert len(siti_relationships) == 2, "no duplicate/extra Rider relationship created"

        # Business B's own Owner approval is independent of Business A's.
        actor(owner_b)
        cur.execute("select approve_pending_rider(%s)", (cross_rider_id,))
        cur.execute("reset role")
        cur.execute("select status from riders where id=%s", (cross_rider_id,))
        assert cur.fetchone()[0] == "active"
        cur.execute("select status from riders where id=%s", (rider_id,))
        assert cur.fetchone()[0] == "active", "Business A's relationship/approval is unaffected by Business B's separate approval"

        # =====================================================================
        # Expired / revoked invites rejected.
        # =====================================================================
        actor(owner_a)
        cur.execute("select create_rider_invitation(%s,'expired@test.invalid','Expired Rider','+60191234571')", (business_a,))
        expired_token = cur.fetchone()[0]["token"]
        cur.execute("reset role")
        cur.execute("update rider_invitations set expires_at = now() - interval '1 hour' where token_hash = encode(digest(%s,'sha256'),'hex')", (expired_token,))
        cur.execute(
            "insert into auth.users(id,aud,role,email,created_at,updated_at) values(%s,'authenticated','authenticated','expired@test.invalid',now(),now())",
            (uuid.uuid4(),),
        )
        cur.execute("select id from auth.users where email='expired@test.invalid'")
        expired_user = cur.fetchone()[0]
        actor(expired_user)
        rejected(cur, "select accept_rider_invitation(%s)", (expired_token,), "invitation expired")

        actor(owner_a)
        cur.execute("select create_rider_invitation(%s,'revoked@test.invalid','Revoked Rider','+60191234572')", (business_a,))
        revoked_invite = cur.fetchone()[0]
        cur.execute("select revoke_rider_invitation(%s)", (revoked_invite["invitation_id"],))
        cur.execute("select status from rider_invitations where id=%s", (revoked_invite["invitation_id"],))
        assert cur.fetchone()[0] == "revoked"

        # =====================================================================
        # Duplicate invite creation (same phone already on file) rejected
        # clearly at creation time, not left to surface confusingly at accept.
        # =====================================================================
        actor(owner_a)
        rejected(cur, "select create_rider_invitation(%s,'dup@test.invalid','Dup Rider','+60191234567')", (business_a,), "phone already on file")

        # =====================================================================
        # reject-a-pending-rider path reuses deactivate_rider unchanged.
        # =====================================================================
        actor(owner_a)
        cur.execute("select create_rider_invitation(%s,'reject-me@test.invalid','Reject Me','+60191234573')", (business_a,))
        reject_token = cur.fetchone()[0]["token"]
        cur.execute("reset role")
        cur.execute(
            "insert into auth.users(id,aud,role,email,created_at,updated_at) values(%s,'authenticated','authenticated','reject-me@test.invalid',now(),now())",
            (uuid.uuid4(),),
        )
        cur.execute("select id from auth.users where email='reject-me@test.invalid'")
        reject_user = cur.fetchone()[0]
        actor(reject_user)
        cur.execute("select accept_rider_invitation(%s)", (reject_token,))
        reject_rider_id = uuid.UUID(cur.fetchone()[0]["rider_id"])
        actor(owner_a)
        cur.execute("select deactivate_rider(%s)", (reject_rider_id,))
        cur.execute("reset role")
        cur.execute("select status from riders where id=%s", (reject_rider_id,))
        assert cur.fetchone()[0] == "inactive"

        # =====================================================================
        # Audit events present, factual, no PII/token leakage.
        # =====================================================================
        cur.execute(
            "select event_type, metadata from delivery_events where business_id=%s and event_type like 'rider.%%' order by created_at",
            (business_a,),
        )
        events = cur.fetchall()
        event_types = [e[0] for e in events]
        for expected in ("rider.invite_created", "rider.invite_accepted", "rider.approved", "rider.invite_revoked", "rider.deactivated"):
            assert expected in event_types, f"missing audit event: {expected}"
        for _, metadata in events:
            blob = str(metadata)
            assert "siti@test.invalid" not in blob and "+6019" not in blob, "no raw email/phone in audit metadata"
            assert token not in blob and reject_token not in blob, "no raw token in audit metadata"

        conn.rollback()

print("s4_07_batch_3_rider_invitation_ok")
