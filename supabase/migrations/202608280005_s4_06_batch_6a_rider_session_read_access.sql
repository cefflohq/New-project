-- S4-06 Batch 6a: Rider session read access -- the genuine backend
-- authorization gap discovered while implementing S4-06.6 (Rider
-- Multi-stop UI). delivery_sessions has exactly one RLS policy
-- (sessions_vendor, business-member SELECT); a Rider is never a
-- business_member, so a Rider could not read the real Wave name of a
-- session they genuinely have assignments in. Purely additive: one new
-- SELECT policy, one narrowly-scoped SECURITY DEFINER helper mirroring
-- is_business_member's exact style. No INSERT/UPDATE/DELETE policy is
-- added -- writes remain exclusively through create_delivery_session/
-- update_session_status, unchanged. sessions_vendor is untouched.
--
-- Data exposure reviewed: delivery_sessions carries only
-- (business_id, name, delivery_date, status, started_at, completed_at,
-- created_at, updated_at) -- no financial, internal, or Vendor-private
-- field exists on this table. Full-row SELECT is safe for a Rider who
-- genuinely has an assignment in that session.
--
-- Authorization model: a Rider may read a session iff they have at least
-- one rider_assignments row for it -- checked via a SECURITY DEFINER
-- helper (not a raw inline subquery) so this predicate never depends on
-- rider_assignments' own RLS policy shape remaining exactly as it is
-- today, matching this project's established is_business_member pattern
-- for cross-table RLS predicates.
create function public.is_session_rider(p_delivery_session_id uuid) returns boolean
language sql stable security definer set search_path = public
as $$
  select exists(
    select 1 from rider_assignments
    where delivery_session_id = p_delivery_session_id
      and rider_id = current_rider_id()
  )
$$;

-- Broad EXECUTE, matching is_business_member/current_rider_id's own grant
-- exactly (not the narrower authenticated-only pattern used for mutating
-- RPCs): this function is invoked implicitly by Postgres while evaluating
-- the RLS policy below for ANY querying role, including anon. Restricting
-- EXECUTE to authenticated would make policy evaluation itself raise a
-- permission error for an anon query against delivery_sessions (breaking
-- the existing sessions_vendor policy's own anon behavior of returning
-- zero rows), rather than the function's own internal auth.uid() check
-- correctly returning false. The function reveals nothing sensitive to a
-- direct caller either way (only a boolean tied to the caller's own
-- identity).
grant execute on function public.is_session_rider(uuid) to public, anon, authenticated;

create policy sessions_rider on public.delivery_sessions
  for select using (is_session_rider(id));
