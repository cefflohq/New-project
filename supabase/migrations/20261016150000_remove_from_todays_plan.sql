-- Swipe to remove one delivery from today's plan on Zone detail (Founder
-- 2026-10-16; D-61 contract). Only before pickup: the order leaves its run
-- and rider and goes back to the plannable pool; nothing is deleted.
create or replace function public.remove_from_todays_plan(p_order_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare o orders; st delivery_stops;
begin
  select * into o from orders where id = p_order_id for update;
  if o.id is null or not is_business_operational(o.business_id) then raise exception 'forbidden'; end if;
  if o.delivery_status not in ('created', 'ready_for_pickup') then
    raise exception 'already picked up: use recover delivery instead';
  end if;
  select * into st from delivery_stops where order_id = o.id for update;
  update orders set assigned_rider_id = null, delivery_session_id = null, updated_at = now()
   where id = o.id;
  update delivery_stops set assignment_id = null, rider_id = null, sequence = null,
         sequence_locked_at = null, updated_at = now()
   where order_id = o.id;
  if st.assignment_id is not null then
    update rider_assignments set status = 'cancelled', updated_at = now()
     where id = st.assignment_id
       and not exists (select 1 from delivery_stops s where s.assignment_id = st.assignment_id);
  end if;
  insert into delivery_events(business_id, order_id, delivery_stop_id, event_type, actor_user_id, actor_role, metadata)
  values (o.business_id, o.id, st.id, 'plan.order_removed', auth.uid(), 'vendor',
          jsonb_build_object('delivery_session_id', o.delivery_session_id, 'rider_id', o.assigned_rider_id));
end $$;
revoke all on function public.remove_from_todays_plan(uuid) from public, anon;
grant execute on function public.remove_from_todays_plan(uuid) to authenticated;
