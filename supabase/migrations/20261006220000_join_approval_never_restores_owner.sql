-- Security fix (staging first): approving a team join request must grant
-- exactly the requested role. Before, the upsert kept role 'owner' whenever
-- the existing membership row was an Owner -- including a REMOVED (inactive)
-- Owner. A removed Owner could open the Helper link and, once an Operator
-- (delegated Helper approval, 20261006110000) or the Owner approved the Helper
-- request, silently regain Owner. Now only an ACTIVE Owner row keeps 'owner'
-- (defensive; an active member never has a pending request); every other row
-- takes the request's role. Authorization is unchanged.
-- Rollback: re-apply decide_team_join_request from 20261006110000.

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
        set role = case when business_members.role = 'owner' and business_members.status = 'active'
                        then 'owner'::member_role else excluded.role end,
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
