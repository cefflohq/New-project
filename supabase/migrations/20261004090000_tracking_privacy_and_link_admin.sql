-- Customer Tracking privacy + tracking-link administration (Founder,
-- 2026-10-04, "PROCEED — CLEAR STAGING BLOCKERS" items 3, 5 and 7).
--
-- 1. public_tracking no longer reveals multi-drop information: the
--    `stops_ahead` count (in the live block and inside `eta`) is removed --
--    a customer sees only their own delivery. It gains `picked_up_at`, the
--    time this order (only) was picked up, for the status-first experience.
-- 2. rotate_tracking_token / revoke_tracking_token: Owner + Operator only
--    (is_business_operational). They were open to any business member, so a
--    Helper could rotate or cancel a customer's tracking link; tracking-link
--    administration is not part of the approved Helper role.
--
-- CREATE OR REPLACE keeps each function's existing grants. No data change.

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
    'rating_submitted', rt.id is not null
  ) || coalesce(live_result, '{}'::jsonb) into result
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

CREATE OR REPLACE FUNCTION public.rotate_tracking_token(p_order_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  o public.orders;
  t public.tracking_tokens;
  new_token text;
  new_expiry timestamptz;
begin
  select * into o from public.orders where id = p_order_id;
  if o.id is null or not public.is_business_operational(o.business_id) then
    raise exception 'forbidden';
  end if;

  select * into t from public.tracking_tokens where order_id = p_order_id for update;
  if t.id is null then
    raise exception 'tracking token not found';
  end if;

  new_token := encode(gen_random_bytes(32), 'hex');
  new_expiry := case when o.delivery_status = 'delivered' then now() + interval '48 hours' else null end;

  update public.tracking_tokens set
    token_hash = encode(digest(new_token, 'sha256'), 'hex'),
    expires_at = new_expiry,
    revoked_at = null
  where order_id = p_order_id;

  insert into public.delivery_events(
    business_id, order_id, event_type, actor_user_id, actor_role, metadata
  ) values (
    o.business_id, o.id, 'tracking_token_rotated', auth.uid(), 'vendor',
    jsonb_build_object('token_id', t.id)
  );

  return new_token;
end;
$function$;

CREATE OR REPLACE FUNCTION public.revoke_tracking_token(p_order_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  o public.orders;
  t public.tracking_tokens;
begin
  select * into o from public.orders where id = p_order_id;
  if o.id is null or not public.is_business_operational(o.business_id) then
    raise exception 'forbidden';
  end if;

  select * into t from public.tracking_tokens where order_id = p_order_id for update;
  if t.id is null then
    raise exception 'tracking token not found';
  end if;

  update public.tracking_tokens set revoked_at = now() where order_id = p_order_id;

  insert into public.delivery_events(
    business_id, order_id, event_type, actor_user_id, actor_role, metadata
  ) values (
    o.business_id, o.id, 'tracking_token_revoked', auth.uid(), 'vendor',
    jsonb_build_object('token_id', t.id)
  );

  return true;
end;
$function$;
