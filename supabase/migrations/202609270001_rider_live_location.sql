-- Phase 2B.4 / D-66: rider live location, Demand-Aware Adaptive Tracking.
-- Additive only. record_rider_location, rider_locations RLS and the Realtime
-- publication are unchanged. The Realtime channel is routing, not security:
-- coordinates are served only by the token-checked public_tracking below.

-- 1. Unguessable per rider-run channel name (never listable by anon).
alter table public.rider_assignments
  add column live_topic uuid not null default gen_random_uuid();

-- 2. Opaque per-order presence key. Only a holder of the order's tracking
--    token (via public_tracking) or the assigned rider (via rider_live_keys)
--    can know it; it reveals nothing about the order.
create function public.tracking_live_key(p_token_hash text, p_live_topic uuid) returns text
language sql immutable
set search_path = public, extensions
as $$ select left(encode(digest(p_token_hash || p_live_topic::text, 'sha256'), 'hex'), 16) $$;
revoke all on function public.tracking_live_key(text, uuid) from public, anon, authenticated;

-- 3. Rider-scoped key list for the Driver app's Presence validation: only the
--    caller's own orders that are currently trackable.
create function public.rider_live_keys(p_rider_id uuid) returns table(
  order_id uuid, live_topic uuid, live_key text
)
language plpgsql stable security definer
set search_path = public, extensions
as $$
begin
  if not is_current_rider(p_rider_id) then
    raise exception 'forbidden';
  end if;
  return query
    select o.id, a.live_topic, tracking_live_key(t.token_hash, a.live_topic)
    from orders o
    join delivery_stops s on s.order_id = o.id
    join rider_assignments a on a.id = s.assignment_id
    join tracking_tokens t on t.order_id = o.id
    where o.assigned_rider_id = p_rider_id
      and a.rider_id = p_rider_id
      and o.delivery_status in ('picked_up', 'out_for_delivery', 'arrived')
      and t.revoked_at is null
      and (t.expires_at is null or t.expires_at > now());
end;
$$;
revoke all on function public.rider_live_keys(uuid) from public, anon;
grant execute on function public.rider_live_keys(uuid) to authenticated;

-- 4. public_tracking: additive rider_location / live / stops_ahead, only while
--    the order is trackable. Everything else is unchanged from 202609260001.
create or replace function public.public_tracking(p_token text) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
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
    eta_result := compute_order_eta(order_id_lookup);

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
        'key', tracking_live_key(key, a.live_topic)),
      'stops_ahead', case when s.sequence_locked_at is null or s.sequence is null then null else (
        select count(*) from delivery_stops s2
        where s2.assignment_id = s.assignment_id
          and s2.sequence < s.sequence
          and s2.status not in ('delivered', 'cancelled', 'issue')) end
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
$$;
