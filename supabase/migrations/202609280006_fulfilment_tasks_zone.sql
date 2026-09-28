-- D-74 Helper workflow master: Zone is the main grouping for Packing,
-- Sorting and handover. Add the order's Zone (id + name only) to the
-- minimised fulfilment contract and group tasks by it. Nothing else widens.
create or replace function public.my_fulfilment_tasks(p_business_id uuid) returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not is_business_fulfilment(p_business_id) then
    raise exception 'forbidden';
  end if;
  return jsonb_build_object(
    'business_name', (select name from businesses where id = p_business_id),
    'tasks', coalesce((
      select jsonb_agg(jsonb_build_object(
        'order_id', o.id,
        'order_number', o.order_number,
        'customer_name', o.customer_name,
        'items', o.items,
        'notes', nullif(o.notes, ''),
        'order_date', o.order_date,
        'preparation_status', s.preparation_status,
        'preparation_updated_at', s.preparation_updated_at,
        'zone_id', o.zone_id,
        'zone_name', z.name,
        'run_name', ds.name,
        'run_date', ds.delivery_date,
        'stop_sequence', s.sequence,
        'handover_rider_name', case when s.preparation_status = 'ready' then r.name end,
        'created_at', o.created_at
      ) order by o.order_date nulls last, z.name nulls last, ds.name nulls last, s.sequence nulls last, o.created_at)
      from orders o
      join delivery_stops s on s.order_id = o.id
      left join delivery_sessions ds on ds.id = o.delivery_session_id
      left join zones z on z.id = o.zone_id
      left join riders r on r.id = o.assigned_rider_id
      where o.business_id = p_business_id
        and o.delivery_status in ('created', 'ready_for_pickup')
    ), '[]'::jsonb)
  );
end;
$$;
