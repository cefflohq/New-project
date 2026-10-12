-- Sorting requires a Run (Founder decision, 2026-10-12; amends D-74 and the
-- Helper lock fe99e46).
--
-- An order sorted before any Run existed was locked to its Zone group by
-- orders_plan_lock_guard (202609280009) and refused by build_rider_run, with
-- no path into a Run: it stayed Ready with no driver. Sorting now needs the
-- order's Run; packing (and confirm_packing) may still start before a Run.
--
--   advance_preparation(order, 'sorted')  refused when the order has no Run
--   confirm_sorting(..., run = null, ...) refused (the per-order-date group
--                                         without a Run is retired)
--
-- Every other transition, the plan-lock guard, build_rider_run and the
-- pickup gate are unchanged. CREATE OR REPLACE keeps both signatures and
-- their grants.

CREATE OR REPLACE FUNCTION public.advance_preparation(p_order_id uuid, p_next preparation_status)
 RETURNS delivery_stops
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  st delivery_stops;
  o orders;
  old public.preparation_status;
begin
  select * into o from orders where id = p_order_id for update;
  if o.id is null or not is_business_fulfilment(o.business_id) then
    raise exception 'forbidden';
  end if;
  if o.delivery_status not in ('created', 'ready_for_pickup') then
    raise exception 'task not available';
  end if;
  select * into st from delivery_stops where order_id = p_order_id for update;
  if st.id is null then
    raise exception 'delivery stop not found';
  end if;

  old := st.preparation_status;
  if old = p_next then
    return st;
  end if;
  if p_next = 'ready' then
    raise exception 'ready requires sorting confirmation';
  end if;
  -- Sorting puts an order into its Run's pickup group, so it needs a Run.
  -- Packing may still start before any Run exists.
  if p_next = 'sorted' and o.delivery_session_id is null then
    raise exception 'sorting requires a run';
  end if;
  if not preparation_transition_allowed(old, p_next) then
    raise exception 'invalid preparation transition % -> %', old, p_next;
  end if;
  if p_next = 'sorted' and st.packing_confirmed_at is null then
    raise exception 'packing not confirmed';
  end if;

  update delivery_stops set
    preparation_status = p_next,
    preparation_updated_at = now(),
    preparation_updated_by = auth.uid(),
    preparation_updated_by_helper = null,
    packed_at = case when p_next = 'packed' then now() else packed_at end,
    packed_by = case when p_next = 'packed' then auth.uid() else packed_by end,
    sorted_at = case when p_next = 'sorted' then now() else sorted_at end,
    sorted_by = case when p_next = 'sorted' then auth.uid() else sorted_by end,
    updated_at = now()
  where id = st.id
  returning * into st;

  insert into delivery_events(business_id, order_id, delivery_stop_id, event_type, from_status, to_status, actor_user_id, actor_role)
    values (o.business_id, o.id, st.id, 'preparation.status_changed', old::text, p_next::text, auth.uid(),
            case when is_business_operational(o.business_id) then 'vendor' else 'helper' end);

  return st;
end;
$function$;

CREATE OR REPLACE FUNCTION public.confirm_sorting(p_business_id uuid, p_zone_id uuid, p_delivery_session_id uuid, p_order_date date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_total int;
  v_sorted int;
  v_ids uuid[];
  v_role text;
begin
  if not is_business_fulfilment(p_business_id) then
    raise exception 'forbidden';
  end if;
  if p_delivery_session_id is null then
    raise exception 'sorting requires a run';
  end if;
  if p_delivery_session_id is not null and not exists(
    select 1 from delivery_sessions where id = p_delivery_session_id and business_id = p_business_id
  ) then
    raise exception 'forbidden';
  end if;
  v_role := case when is_business_operational(p_business_id) then 'vendor' else 'helper' end;

  perform 1 from delivery_stops s join orders o on o.id = s.order_id
    where o.business_id = p_business_id
      and o.zone_id is not distinct from p_zone_id
      and o.delivery_session_id is not distinct from p_delivery_session_id
      and (p_delivery_session_id is not null or o.order_date is not distinct from p_order_date)
      and o.delivery_status in ('created', 'ready_for_pickup')
    for update of s;

  select count(*), count(*) filter (where s.preparation_status in ('sorted', 'ready')),
         array_agg(o.id) filter (where s.preparation_status = 'sorted')
    into v_total, v_sorted, v_ids
    from delivery_stops s join orders o on o.id = s.order_id
    where o.business_id = p_business_id
      and o.zone_id is not distinct from p_zone_id
      and o.delivery_session_id is not distinct from p_delivery_session_id
      and (p_delivery_session_id is not null or o.order_date is not distinct from p_order_date)
      and o.delivery_status in ('created', 'ready_for_pickup');

  if v_total = 0 then
    raise exception 'no orders in this group';
  end if;
  if v_sorted < v_total then
    raise exception 'sorting incomplete: % / % sorted', v_sorted, v_total;
  end if;

  update delivery_stops set
    preparation_status = 'ready',
    preparation_updated_at = now(),
    preparation_updated_by = auth.uid(),
    preparation_updated_by_helper = null,
    ready_at = now(),
    ready_by = auth.uid(),
    updated_at = now()
  where order_id = any(coalesce(v_ids, '{}'));
  insert into delivery_events(business_id, order_id, delivery_stop_id, event_type, from_status, to_status, actor_user_id, actor_role, metadata)
    select p_business_id, s.order_id, s.id, 'preparation.status_changed', 'sorted', 'ready', auth.uid(), v_role,
           jsonb_build_object('via', 'confirm_sorting', 'zone_id', p_zone_id, 'delivery_session_id', p_delivery_session_id)
    from delivery_stops s where s.order_id = any(coalesce(v_ids, '{}'));
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (p_business_id, 'fulfilment.sorting_confirmed', auth.uid(), v_role,
            jsonb_build_object('zone_id', p_zone_id, 'delivery_session_id', p_delivery_session_id,
                               'order_date', p_order_date, 'orders', v_total,
                               'newly_ready', coalesce(array_length(v_ids, 1), 0)));

  return jsonb_build_object('orders', v_total, 'sorted', v_sorted,
                            'newly_ready', coalesce(array_length(v_ids, 1), 0));
end;
$function$;
