-- Customer Tracking approved fields (Founder, 2026-10-05, "safer version").
-- public_tracking additively returns, for the tracking-link holder only:
--   items          orders.items -> name + quantity (max 20), always
--   pickup_address businesses.address, always
--   business_phone businesses.phone (Call / Message target), always
--   rider_vehicle  riders.vehicle_type, picked_up/out_for_delivery/arrived only
--   rider_plate    riders.vehicle_plate, same window
-- NOT exposed: Driver phone, customer delivery address, orders.notes, POD
-- note, prices/IDs/product metadata. Token isolation, rate limit, telemetry
-- and grants unchanged (CREATE OR REPLACE keeps grants). No table/RLS change.
-- Rollback: re-apply 20261004090000_tracking_privacy_and_link_admin.sql's
-- public_tracking definition.

CREATE OR REPLACE FUNCTION public.public_tracking(p_token text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  key text;
  allowed boolean;
  result jsonb;
  eta_result jsonb;
  order_id_lookup uuid;
  live_result jsonb;
begin
  key := encode(digest(p_token, 'sha256'), 'hex');

  begin
    allowed := check_rate_limit(key, 'public_tracking', 60, 10);
  exception when others then
    allowed := true;
  end;

  if not allowed then
    raise exception 'rate limited';
  end if;

  select t.order_id into order_id_lookup
  from tracking_tokens t
  where t.token_hash = key
    and t.revoked_at is null
    and (t.expires_at is null or t.expires_at > now());

  if order_id_lookup is not null then
    -- Multi-drop privacy (Founder 2026-10-04): never reveal how many other
    -- customers' stops precede this one.
    eta_result := compute_order_eta(order_id_lookup) - 'stops_ahead';

    -- Live block: only for a trackable order with an assigned run.
    select jsonb_build_object(
      'rider_location', (
        select jsonb_build_object(
          'lat', round(l.latitude::numeric, 4),
          'lng', round(l.longitude::numeric, 4),
          'accuracy_m', round(l.accuracy::numeric),
          'recorded_at', l.recorded_at)
        from rider_locations l
        where l.rider_id = o.assigned_rider_id
          and l.recorded_at > now() - interval '15 minutes'
          and l.recorded_at >= coalesce(
            (select min(e.created_at) from delivery_events e
              where e.order_id = o.id and e.to_status = 'picked_up'),
            now())
        order by l.recorded_at desc
        limit 1),
      'live', jsonb_build_object(
        'topic', 'trk:' || a.live_topic::text,
        'key', tracking_live_key(key, a.live_topic))
    ) into live_result
    from orders o
    join delivery_stops s on s.order_id = o.id
    join rider_assignments a on a.id = s.assignment_id
    where o.id = order_id_lookup
      and o.delivery_status in ('picked_up', 'out_for_delivery', 'arrived');
  end if;

  select jsonb_build_object(
    'order_id', o.public_ref,
    'order_number', o.order_number,
    'store_name', b.name,
    'status', o.delivery_status,
    'eta', eta_result,
    'rider_name', r.name,
    'completed_at', o.completed_at,
    'picked_up_at', (select min(e.created_at) from delivery_events e where e.order_id = o.id and e.to_status = 'picked_up'),
    'pod_available', (o.delivery_status = 'delivered' and s.pod_storage_path is not null),
    'rating_submitted', rt.id is not null,
    -- Founder-approved (2026-10-05): item name + quantity only.
    'items', (select jsonb_agg(jsonb_build_object(
                'name', left(btrim(x.i ->> 'name'), 80),
                'qty', case when coalesce(x.i ->> 'qty', x.i ->> 'quantity') ~ '^[0-9]{1,4}$'
                            then coalesce(x.i ->> 'qty', x.i ->> 'quantity')::int else 1 end))
              from (select i from jsonb_array_elements(case when jsonb_typeof(o.items) = 'array' then o.items else '[]'::jsonb end) i
                    where nullif(btrim(i ->> 'name'), '') is not null limit 20) x),
    -- The store's pickup address and business contact number (never the
    -- Driver's personal phone).
    'pickup_address', nullif(btrim(b.address), ''),
    'business_phone', nullif(btrim(b.phone), '')
  ) || case when o.delivery_status in ('picked_up', 'out_for_delivery', 'arrived') then jsonb_strip_nulls(jsonb_build_object(
    -- Vehicle type + plate only while the delivery is in progress.
    'rider_vehicle', r.vehicle_type::text,
    'rider_plate', nullif(btrim(r.vehicle_plate), '')))
  else '{}'::jsonb end
    || coalesce(live_result, '{}'::jsonb) into result
  from tracking_tokens t
  join orders o on o.id = t.order_id
  join businesses b on b.id = o.business_id
  left join riders r on r.id = o.assigned_rider_id
  join delivery_stops s on s.order_id = o.id
  left join ratings rt on rt.order_id = o.id
  where t.token_hash = key
    and t.revoked_at is null
    and (t.expires_at is null or t.expires_at > now());

  if result is null then
    perform record_invalid_lookup_telemetry('public_tracking');
  end if;

  return result;
end;
$function$;
