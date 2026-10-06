-- M2 follow-up (Founder 2026-10-06, option 1): the Operator may see and
-- approve / reject HELPER join requests. Operator requests stay Owner-only
-- (an Operator never admits Operators). Reads: a requester sees their own,
-- the Owner sees all, the Operator sees role = 'helper' only.
-- Rollback: restore the previous policy (user_id = auth.uid() or
-- is_business_owner(business_id)) and decide_team_join_request (20260930072634).

drop policy if exists team_join_requests_read on public.team_join_requests;
create policy team_join_requests_read on public.team_join_requests
  for select to authenticated
  using (user_id = auth.uid()
         or public.is_business_owner(business_id)
         or (role = 'helper' and public.is_business_operational(business_id)));

CREATE OR REPLACE FUNCTION public.decide_team_join_request(p_request_id uuid, p_approve boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v team_join_requests;
begin
  select * into v from team_join_requests where id = p_request_id for update;
  -- Owner decides any request; the Operator decides Helper requests only.
  if v.id is null or not (is_business_owner(v.business_id)
       or (v.role = 'helper' and is_business_operational(v.business_id))) then
    raise exception 'forbidden';
  end if;
  if v.status <> 'pending' then raise exception 'request already decided'; end if;
  if p_approve then
    insert into business_members(business_id, user_id, role, status)
      values (v.business_id, v.user_id, v.role, 'active')
      on conflict (business_id, user_id) do update
        set role = case when business_members.role = 'owner' then 'owner'::member_role else excluded.role end,
            status = 'active';
  end if;
  update team_join_requests
    set status = case when p_approve then 'approved' else 'rejected' end,
        decided_by = auth.uid(), decided_at = now()
    where id = v.id;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (v.business_id, case when p_approve then 'team.join_approved' else 'team.join_rejected' end,
            auth.uid(), 'vendor', jsonb_build_object('request_id', v.id, 'role', v.role));
  return jsonb_build_object('request_id', v.id, 'status', case when p_approve then 'approved' else 'rejected' end);
end $function$;
