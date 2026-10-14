-- Google geocoding storage rules (Auto Zone + Google Maps master guideline
-- Part B §B3, Phase 1, 2026-10-14).
--
-- * place_id is stored permanently (Google allows it).
-- * Google-derived coordinates (location_provider = 'google') are kept at
--   most 30 days. A daily job clears them:
--     - finished orders (delivered / cancelled): coordinates cleared; the
--       address text, place_id, POD and rider GPS stay as history;
--     - open orders not yet in a run: back to 'unresolved', so the next
--       geocode-order pending call resolves them again.
--   Orders inside a planned or active run are never touched.
-- * Our own points (customer_pin, vendor_pin, manual_correction) are never
--   expired.

alter table public.orders add column if not exists place_id text;
alter table public.businesses add column if not exists place_id text;

-- set_order_location gains p_place_id. Same rules as before; the place_id
-- is kept for ambiguous results too (Google's best candidate), never a
-- coordinate.
drop function if exists public.set_order_location(uuid, public.order_location_status, double precision, double precision, text, text);
create function public.set_order_location(
  p_order_id uuid,
  p_status public.order_location_status,
  p_latitude double precision default null,
  p_longitude double precision default null,
  p_provider text default null,
  p_error text default null,
  p_place_id text default null
) returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  o public.orders;
begin
  if p_status = 'unresolved' then
    raise exception 'unresolved is the default pre-attempt state, not a settable result';
  end if;
  if p_status = 'resolved' and (p_latitude is null or p_longitude is null) then
    raise exception 'resolved requires both coordinates';
  end if;
  if p_status in ('ambiguous','failed') and (p_latitude is not null or p_longitude is not null) then
    raise exception '% must not carry coordinates', p_status;
  end if;

  select * into o from public.orders where id = p_order_id for update;
  if o.id is null then
    raise exception 'order not found';
  end if;

  update public.orders set
    location_status = p_status,
    latitude = case when p_status = 'resolved' then p_latitude else null end,
    longitude = case when p_status = 'resolved' then p_longitude else null end,
    location_provider = p_provider,
    location_resolved_at = now(),
    location_error = p_error,
    place_id = coalesce(nullif(btrim(p_place_id), ''), place_id),
    updated_at = now()
  where id = p_order_id
  returning * into o;

  insert into delivery_events(business_id, order_id, event_type, actor_role, metadata)
    values (o.business_id, o.id, 'order.location_resolved', 'system',
            jsonb_build_object('status', p_status, 'provider', p_provider, 'error', p_error));

  return o;
end;
$$;

revoke all on function public.set_order_location(uuid, public.order_location_status, double precision, double precision, text, text, text) from public, anon, authenticated;
grant execute on function public.set_order_location(uuid, public.order_location_status, double precision, double precision, text, text, text) to service_role;

-- Daily 30-day expiry of Google coordinates. Returns rows changed.
create or replace function public._expire_google_coordinates()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  finished integer;
  reopened integer;
begin
  update orders set
    latitude = null, longitude = null,
    location_error = 'google_cache_expired',
    updated_at = now()
  where location_provider = 'google'
    and latitude is not null
    and location_resolved_at < now() - interval '30 days'
    and delivery_status in ('delivered', 'cancelled');
  get diagnostics finished = row_count;

  update orders set
    latitude = null, longitude = null,
    location_status = 'unresolved',
    location_provider = null,
    location_error = 'google_cache_expired',
    updated_at = now()
  where location_provider = 'google'
    and location_resolved_at < now() - interval '30 days'
    and delivery_status in ('created', 'ready_for_pickup')
    and delivery_session_id is null and assigned_rider_id is null;
  get diagnostics reopened = row_count;

  return finished + reopened;
end;
$$;

revoke all on function public._expire_google_coordinates() from public, anon, authenticated;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('cefflo_google_geocode_expiry', '17 3 * * *',
                          'select public._expire_google_coordinates()');
  end if;
end;
$$;
