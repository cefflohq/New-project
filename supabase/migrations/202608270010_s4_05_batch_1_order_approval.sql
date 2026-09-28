-- S4-05 Batch 1: explicit order-approval gate before assignment.
-- Approval is an authorization/readiness gate, not a delivery_status
-- lifecycle state (Founder decision) -- represented as separate columns,
-- not a new enum value.

alter table public.orders
  add column approved_at timestamptz,
  add column approved_by uuid references auth.users on delete set null;

-- Owner or Operator/Staff (any active business member) may approve, matching
-- the existing precedent for other pre-dispatch order mutations
-- (create_delivery, assign_rider, update_order_details all use the same
-- is_business_member scoping -- no owner-only restriction was specified for
-- this action). Idempotent: approving an already-approved order is a no-op
-- return, matching the existing complete_delivery/rider_transition style,
-- rather than raising on a harmless repeat action.
create function public.approve_order(p_order_id uuid) returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  o orders;
begin
  select * into o from orders where id = p_order_id for update;
  if o.id is null or not is_business_member(o.business_id) then
    raise exception 'forbidden';
  end if;
  if o.approved_at is not null then
    return o;
  end if;
  update orders set approved_at = now(), approved_by = auth.uid(), updated_at = now()
    where id = o.id
    returning * into o;
  insert into delivery_events(business_id, order_id, event_type, actor_user_id, actor_role)
    values (o.business_id, o.id, 'order.approved', auth.uid(), 'vendor');
  return o;
end;
$$;

revoke all on function public.approve_order(uuid) from public, anon, authenticated;
grant execute on function public.approve_order(uuid) to authenticated;

-- assign_rider: add the approval precondition only. Every other line is
-- byte-identical to the currently-live version (foundation + unchanged since)
-- -- no unrelated lifecycle transition touched.
create or replace function public.assign_rider(p_order_id uuid,p_rider_id uuid) returns public.orders language plpgsql security definer set search_path=public as $$declare o orders;a rider_assignments;begin select * into o from orders where id=p_order_id for update;if o.id is null or not is_business_member(o.business_id) then raise exception 'forbidden';end if;if o.approved_at is null then raise exception 'order not approved';end if;if not exists(select 1 from riders where id=p_rider_id and business_id=o.business_id and status='active') then raise exception 'invalid rider';end if;insert into rider_assignments(business_id,delivery_session_id,rider_id) values(o.business_id,o.delivery_session_id,p_rider_id) returning * into a;update orders set assigned_rider_id=p_rider_id,updated_at=now() where id=o.id returning * into o;update delivery_stops set assignment_id=a.id,rider_id=p_rider_id,updated_at=now() where order_id=o.id;insert into delivery_events(business_id,order_id,delivery_stop_id,assignment_id,event_type,actor_user_id,actor_role) select o.business_id,o.id,s.id,a.id,'rider.assigned',auth.uid(),'vendor' from delivery_stops s where s.order_id=o.id;return o;end$$;
