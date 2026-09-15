-- S4-05 Batch 3: minimal authoritative delivery-session foundation.
-- IN SCOPE ONLY: create/list(select)/attach an order/minimal status
-- lifecycle/eventing/protected RPCs/RLS narrowing. No batching, zone,
-- routing, multi-drop, or automatic-grouping logic is introduced here --
-- that is S4-06.
--
-- Reconciliation finding: delivery_events.order_id is currently NOT NULL,
-- which structurally prevents recording any pure session-level event (a
-- session has no order at creation time, and its status can change
-- independent of any single order). This is the smallest schema change
-- needed to make the explicitly in-scope "delivery_events coverage"
-- requirement achievable: relax order_id to nullable. This is strictly
-- backward compatible -- every existing event type continues to always
-- supply order_id (unchanged), no existing row or query is affected, and
-- no other constraint is loosened.
alter table public.delivery_events alter column order_id drop not null;

-- Protected create: Owner or Operator/Staff (business member), matching the
-- existing precedent set by create_delivery/approve_order/assign_rider --
-- no owner-only restriction is introduced for this action either.
create function public.create_delivery_session(
  p_business_id uuid,
  p_name text default 'Delivery Session',
  p_delivery_date date default current_date
) returns public.delivery_sessions
language plpgsql
security definer
set search_path = public
as $$
declare
  s delivery_sessions;
begin
  if not is_business_member(p_business_id) then
    raise exception 'forbidden';
  end if;
  insert into delivery_sessions(business_id, name, delivery_date)
    values (
      p_business_id,
      coalesce(nullif(trim(p_name), ''), 'Delivery Session'),
      coalesce(p_delivery_date, current_date)
    )
    returning * into s;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role)
    values (p_business_id, 'session.created', auth.uid(), 'vendor');
  return s;
end;
$$;

-- Attach (or, passing null, detach) an order to/from a session. Both must
-- belong to the same business -- a mismatch is a distinct integrity failure
-- from a plain authorization failure, matching the existing style of
-- assign_rider's separate 'invalid rider' message. Does not touch any
-- already-existing rider_assignments row's own delivery_session_id
-- snapshot (taken once, at assignment time, by assign_rider) -- reconciling
-- an assignment already in flight with a session attached afterward is
-- reassignment/recovery territory, explicitly out of this batch's scope.
create function public.attach_order_to_session(
  p_order_id uuid,
  p_delivery_session_id uuid
) returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  o orders;
  s delivery_sessions;
begin
  select * into o from orders where id = p_order_id for update;
  if o.id is null or not is_business_member(o.business_id) then
    raise exception 'forbidden';
  end if;
  if p_delivery_session_id is not null then
    select * into s from delivery_sessions where id = p_delivery_session_id;
    if s.id is null or s.business_id is distinct from o.business_id then
      raise exception 'invalid session';
    end if;
  end if;
  update orders set delivery_session_id = p_delivery_session_id, updated_at = now()
    where id = o.id
    returning * into o;
  insert into delivery_events(business_id, order_id, event_type, actor_user_id, actor_role, metadata)
    values (
      o.business_id, o.id,
      case when p_delivery_session_id is null then 'session.order_detached' else 'session.order_attached' end,
      auth.uid(), 'vendor',
      jsonb_build_object('delivery_session_id', p_delivery_session_id)
    );
  return o;
end;
$$;

-- Minimal, deliberately simple status setter: any of the four values the
-- existing CHECK constraint already allows, no transition-graph validation
-- (unlike rider_transition's well-defined order sequence) -- a real
-- transition graph belongs with the batching/lifecycle intelligence that is
-- S4-06's job, not this foundation. started_at/completed_at are set once,
-- the first time their corresponding status is reached, never overwritten.
create function public.update_session_status(
  p_delivery_session_id uuid,
  p_status text
) returns public.delivery_sessions
language plpgsql
security definer
set search_path = public
as $$
declare
  s delivery_sessions;
begin
  select * into s from delivery_sessions where id = p_delivery_session_id for update;
  if s.id is null or not is_business_member(s.business_id) then
    raise exception 'forbidden';
  end if;
  if p_status not in ('planned','active','completed','cancelled') then
    raise exception 'invalid status';
  end if;
  update delivery_sessions set
    status = p_status,
    started_at = case when p_status = 'active' and started_at is null then now() else started_at end,
    completed_at = case when p_status = 'completed' and completed_at is null then now() else completed_at end,
    updated_at = now()
    where id = s.id
    returning * into s;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (s.business_id, 'session.status_changed', auth.uid(), 'vendor', jsonb_build_object('delivery_session_id', s.id, 'status', p_status));
  return s;
end;
$$;

revoke all on function public.create_delivery_session(uuid,text,date) from public, anon, authenticated;
grant execute on function public.create_delivery_session(uuid,text,date) to authenticated;
revoke all on function public.attach_order_to_session(uuid,uuid) from public, anon, authenticated;
grant execute on function public.attach_order_to_session(uuid,uuid) to authenticated;
revoke all on function public.update_session_status(uuid,text) from public, anon, authenticated;
grant execute on function public.update_session_status(uuid,text) to authenticated;

-- Close the broad direct-write bypass: sessions_vendor was a "for all"
-- policy (select+insert+update+delete for any business member), the exact
-- same write-bypass class S4-03 Batch 3 closed for orders/riders/
-- rider_assignments -- delivery_sessions was simply dormant at the time and
-- missed. Narrowed to select-only in the SAME migration as the RPCs above,
-- so there is no window where the protected contract exists but the broad
-- policy is still separately live.
drop policy sessions_vendor on public.delivery_sessions;
create policy sessions_vendor on public.delivery_sessions
  for select using (public.is_business_member(business_id));
