-- Helper board: business-local "today" (Founder 2026-10-06, Helper PWA
-- backend completion). my_fulfilment_tasks gains one read-only field,
-- business_today = now() in businesses.timezone (same rule as the
-- orders.order_date trigger). Fixes the Helper workspace showing an older
-- day when unfinished orders from earlier days exist. No authorization,
-- RLS or schema change.
-- Rollback: re-apply my_fulfilment_tasks without 'business_today'.

CREATE OR REPLACE FUNCTION public.my_fulfilment_tasks(p_business_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not is_business_fulfilment(p_business_id) then
    raise exception 'forbidden';
  end if;
  return jsonb_build_object(
    'business_name', (select name from businesses where id = p_business_id),
    -- The business's working day in its own timezone (the same rule that
    -- stamps orders.order_date), so the Helper board never uses the device
    -- clock or UTC.
    'business_today', (select (now() at time zone coalesce(timezone, 'Asia/Kuala_Lumpur'))::date
                         from businesses where id = p_business_id),
    -- Public storefront display images by product name (public bucket
    -- cefflo-product-display), for the Preparation list. Nothing private.
    'item_images', coalesce((
      select jsonb_object_agg(x.name, x.path) from (
        select distinct on (lower(p.name)) p.name, pm.prepared_storage_path as path
        from products p join product_media pm on pm.product_id = p.id
        where p.business_id = p_business_id and pm.prepared_storage_path is not null
        order by lower(p.name), pm.created_at desc
      ) x
    ), '{}'::jsonb),
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
        'packing_confirmed', s.packing_confirmed_at is not null,
        'zone_id', o.zone_id,
        'zone_name', z.name,
        'run_id', o.delivery_session_id,
        'run_name', ds.name,
        'run_date', ds.delivery_date,
        'pickup_at', ds.pickup_at,
        'stop_sequence', s.sequence,
        'handover_rider_name', case when s.preparation_status = 'ready' or o.delivery_status = 'picked_up' then r.name end,
        'handover_rider_vehicle_type', case when s.preparation_status = 'ready' or o.delivery_status = 'picked_up' then r.vehicle_type end,
        'handover_rider_vehicle_plate', case when s.preparation_status = 'ready' or o.delivery_status = 'picked_up' then r.vehicle_plate end,
        'handover_external', case when (s.preparation_status = 'ready' or o.delivery_status = 'picked_up') and ob.id is not null
          then jsonb_build_object('provider_name', ob.provider_name, 'driver_name', ob.driver_name, 'vehicle', ob.vehicle) end,
        'picked_up_at', pu.at,
        'created_at', o.created_at
      ) order by o.order_date nulls last, z.name nulls last, ds.name nulls last, s.sequence nulls last, o.created_at)
      from orders o
      join delivery_stops s on s.order_id = o.id
      left join delivery_sessions ds on ds.id = o.delivery_session_id
      left join zones z on z.id = o.zone_id
      left join riders r on r.id = o.assigned_rider_id
      left join delivery_outsourcing ob on ob.delivery_session_id = o.delivery_session_id and ob.status in ('active', 'handed_over')
      left join lateral (
        select max(e.created_at) as at from delivery_events e
        where e.order_id = o.id and e.to_status = 'picked_up'
      ) pu on o.delivery_status = 'picked_up'
      where o.business_id = p_business_id
        and (o.delivery_status in ('created', 'ready_for_pickup')
             or (o.delivery_status = 'picked_up' and pu.at > now() - interval '24 hours'))
    ), '[]'::jsonb)
  );
end;
$function$;
