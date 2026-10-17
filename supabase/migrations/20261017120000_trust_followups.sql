-- Trust follow-ups (Founder 2026-10-17):
--  3. Find Jobs manual review: the platform admin may see a driver's licence
--     while that driver's verification waits for review (pending /
--     needs_review), as with business verification; sealed again once
--     decided. Incidents still unseal at any time.
--  4. Suspending or banning a business restricts every active member
--     (owner, operators, helpers), not only the owner.
--  5. A customer who reported from the tracking page sees the case status
--     and outcome there (no email needed).

-- 3 ---------------------------------------------------------------------
create or replace function public.driver_documents_unsealed(p_user uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select is_platform_admin() and (
    exists (select 1 from driver_incident_cases c
             where c.rider_user_id = p_user and c.status = 'open' and c.expires_at > now())
    or exists (select 1 from driver_marketplace_verifications v
                where v.user_id = p_user and v.status in ('pending', 'needs_review')))
$$;

-- 4 ---------------------------------------------------------------------
create or replace function public.admin_decide_complaint(
  p_id uuid, p_decision text, p_action text, p_note text,
  p_target text default null, p_suspend_days int default 7)
returns void language plpgsql security definer set search_path = public as $$
declare c complaints; v_user uuid; v_users uuid[] := '{}';
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  if coalesce(length(trim(p_note)), 0) < 10 then raise exception 'explain the decision'; end if;
  p_action := coalesce(p_action, 'none');
  update complaints set status = 'resolved', decision = p_decision, account_action = p_action,
         decision_note = trim(p_note), decided_by = auth.uid(), decided_at = now()
   where id = p_id and status <> 'resolved' returning * into c;
  if c.id is null then raise exception 'not found or already decided'; end if;
  if p_action in ('suspend', 'ban') then
    if p_target = 'driver' then
      select array_agg(auth_user_id) into v_users from riders where id = c.rider_id and auth_user_id is not null;
    elsif p_target = 'business' then
      select array_agg(user_id) into v_users from business_members
       where business_id = c.business_id and status = 'active';
    elsif p_target = 'complainant' and c.complainant_user_id is not null then
      v_users := array[c.complainant_user_id];
    end if;
    if coalesce(array_length(v_users, 1), 0) = 0 then raise exception 'no account to restrict'; end if;
    foreach v_user in array v_users loop
      -- A platform admin is never locked out (e.g. a founder testing as owner).
      continue when exists (select 1 from platform_admins where user_id = v_user);
      perform _restrict_account(v_user, p_action, p_suspend_days, c.id, c.ref || ': ' || trim(p_note));
    end loop;
  end if;
  insert into admin_audit_log (admin_user_id, action, target_type, target_id, reason, metadata)
  values (auth.uid(), 'complaint_decided', 'complaint', c.id::text, trim(p_note),
          jsonb_build_object('ref', c.ref, 'decision', p_decision, 'account_action', p_action,
                             'target', p_target, 'restricted_users', v_users));
end $$;

-- 5 ---------------------------------------------------------------------
create or replace function public.complaints_by_tracking(p_token text)
returns jsonb language sql stable security definer set search_path = public, extensions as $$
  select coalesce(jsonb_agg(jsonb_build_object('ref', c.ref, 'category', c.category, 'status', c.status,
           'decision', c.decision, 'decision_note', c.decision_note, 'created_at', c.created_at)
           order by c.created_at desc), '[]'::jsonb)
  from tracking_tokens t
  join complaints c on c.order_id = t.order_id and c.complainant_role = 'customer'
  where t.token_hash = encode(digest(p_token, 'sha256'), 'hex')
    and t.revoked_at is null and (t.expires_at is null or t.expires_at > now())
$$;
grant execute on function public.complaints_by_tracking(text) to anon, authenticated;
