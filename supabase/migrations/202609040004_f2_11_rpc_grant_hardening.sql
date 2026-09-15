-- CEFFLO Flow 2 Canonical Backend Completion Master, F2-11: "No sensitive
-- mutation/admin function to PUBLIC. Preserve only explicitly justified
-- narrow anon/authenticated grants."
--
-- Same root cause and same fix pattern as the existing
-- 202608300005_foundr_rpc_grant_hardening.sql precedent (its own comment
-- explains it precisely): a function that never received an explicit
-- `revoke all ... from public, anon` keeps Postgres/Supabase's default
-- EXECUTE grant to PUBLIC (and, on this project, anon/authenticated via
-- the platform's own ALTER DEFAULT PRIVILEGES) regardless of what an
-- accompanying `grant ... to authenticated` line says -- the explicit
-- grant is redundant, not exclusive, unless a revoke precedes it. A full
-- schema sweep (querying pg_proc.proacl directly, not relying on any
-- single migration's grant statement) found 27 functions still carrying
-- an anon grant; 16 are genuinely deliberate and are re-affirmed
-- unchanged below for the record, not touched. 11 are hardened here.
--
-- Every one of the 11 already enforces its own internal authorization
-- (is_business_member / is_business_operational / auth.uid() is null
-- checks) -- this closes a defense-in-depth gap, exactly like the FOUNDR
-- precedent, not a currently-exploitable hole, with one partial
-- exception noted below (compute_order_eta).

-- ============================================================
-- Sensitive mutations/reads that were never hardened (S4-03/S4-06 era,
-- predates this project's later revoke-then-grant convention).
-- ============================================================
revoke all on function public.assign_rider(uuid, uuid) from public, anon;
grant execute on function public.assign_rider(uuid, uuid) to authenticated;

revoke all on function public.bootstrap_business(text, text, text, text, text, text, text) from public, anon;
grant execute on function public.bootstrap_business(text, text, text, text, text, text, text) to authenticated;

revoke all on function public.get_my_businesses() from public, anon;
grant execute on function public.get_my_businesses() to authenticated;

revoke all on function public.deactivate_rider(uuid) from public, anon;
grant execute on function public.deactivate_rider(uuid) to authenticated;

revoke all on function public.reassign_rider(uuid, uuid) from public, anon;
grant execute on function public.reassign_rider(uuid, uuid) to authenticated;

revoke all on function public.update_business_profile(uuid, text, text, text, text, text, text, text, text) from public, anon;
grant execute on function public.update_business_profile(uuid, text, text, text, text, text, text, text, text) to authenticated;

revoke all on function public.update_team_member(uuid, uuid, public.member_role, text) from public, anon;
grant execute on function public.update_team_member(uuid, uuid, public.member_role, text) to authenticated;

-- compute_order_eta: this one IS a real gap, not only defense-in-depth --
-- it has no internal tenant/token check at all (it was written to be an
-- internal helper called only from inside public_tracking, itself
-- token-gated). Directly granted to anon/authenticated by A5 "for
-- potential future direct FE polling" -- nothing ever used that path, and
-- as shipped it would let any authenticated user (any business) or anon
-- caller read any order's live ETA state by guessing/enumerating order
-- UUIDs. Revoked from both; public_tracking's own internal call is
-- unaffected (a SECURITY DEFINER function's internal calls run under the
-- definer's privileges, not the invoking client's grants).
revoke all on function public.compute_order_eta(uuid) from public, anon, authenticated;

-- ============================================================
-- NOT touched, deliberately: is_business_member, is_business_owner,
-- is_current_rider and is_session_rider are referenced DIRECTLY inside
-- RLS policy USING/WITH CHECK clauses throughout this schema (e.g.
-- orders_rider, sessions_vendor, the S4-06.6a session-read policy). A
-- policy's function calls are evaluated under the QUERYING role's own
-- privileges, not the table owner's -- unlike a plain internal function-
-- to-function call, so revoking anon's execute here does not just deny
-- anon "false" from the check, it makes Postgres reject the query itself
-- with a permission error before RLS ever gets to filter it. Confirmed
-- by a real regression caught in this same pass (s4_03_batch_3_rls.py /
-- s4_06_batch_6a_rider_session_read_access.py / s4_10e_public_order_page
-- _contract.py all failed with exactly "permission denied for function
-- is_business_member" once anon's grant was removed) -- reverted before
-- landing. is_business_operational is safe to harden: it is only ever
-- called from inside plpgsql function bodies (never a policy), where a
-- SECURITY DEFINER function's internal calls run under the definer's own
-- privileges regardless of the invoking client's grants.
revoke all on function public.is_business_operational(uuid) from public, anon;
grant execute on function public.is_business_operational(uuid) to authenticated;

revoke all on function public.is_vehicle_compatible(public.rider_vehicle_type, public.vehicle_requirement) from public, anon;
grant execute on function public.is_vehicle_compatible(public.rider_vehicle_type, public.vehicle_requirement) to authenticated;

revoke all on function public.default_capacity_for_vehicle(public.rider_vehicle_type) from public, anon;
grant execute on function public.default_capacity_for_vehicle(public.rider_vehicle_type) to authenticated;

revoke all on function public.haversine_km(double precision, double precision, double precision, double precision) from public, anon;
grant execute on function public.haversine_km(double precision, double precision, double precision, double precision) to authenticated;

revoke all on function public.rider_active_stop_count(uuid) from public, anon;
grant execute on function public.rider_active_stop_count(uuid) to authenticated;

revoke all on function public.rider_effective_capacity(uuid) from public, anon;
grant execute on function public.rider_effective_capacity(uuid) to authenticated;

-- ============================================================
-- Re-affirmed, unchanged -- two genuinely different reasons:
--
-- 1. Deliberately anonymous-safe by design (a bearer token, not the
--    grant, is the real authorization for the first group; the second
--    group is intentionally public runtime info, already the explicit,
--    documented FOUNDR precedent from 202608300005):
--      public_tracking, submit_rating, resolve_rider_invitation,
--      resolve_team_invitation, public_order_catalog, submit_public_order
--      get_feature_flag, get_active_maintenance, get_active_announcements
--
-- 2. MUST stay anon-executable regardless of sensitivity, because they
--    are referenced directly inside RLS policy USING/WITH CHECK clauses
--    (see the note above is_business_operational) -- revoking anon here
--    breaks the query itself with a permission error instead of letting
--    RLS transparently filter it to zero rows, exactly as caught by this
--    migration's own first attempt:
--      is_business_member, is_business_owner, is_current_rider,
--      is_session_rider
-- ============================================================
