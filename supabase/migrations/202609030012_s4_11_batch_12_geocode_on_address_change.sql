-- S4-11 Batch 12 (Grow V1 Flow 2 continuation): address changes must
-- invalidate the previously-resolved canonical location, so the system
-- knows a re-geocode is required. Founder principle: "address changes /
-- location correction -> geocode when required -> persist canonical
-- lat/lng -> downstream operational engine reuses coordinates."
--
-- The A1 migration deliberately shipped without this (documented at the
-- time as "no trigger on address change... reduces edge-case risk within
-- V1 scope"). The Mapbox provider-gate work now requires it: without this,
-- an edited address would keep the OLD coordinates marked 'resolved'
-- forever, and the geocode-order Edge Function's own "already resolved,
-- skip" guard (GEOCODE ONCE) would never let the new address be resolved.
--
-- Scope stays narrow, matching the rest of this codebase's plain-RPC
-- style: only update_order_details (the sole path that can change
-- delivery_address post-creation) resets location truth, and only when
-- the address actually changes (not on every call, matching
-- update_order_details' own existing zone_changed-only-on-change pattern
-- immediately below it in the same function).

create or replace function public.update_order_details(
  p_order_id uuid,
  p_customer_name text default null,
  p_customer_phone text default null,
  p_delivery_address text default null,
  p_notes text default null,
  p_items jsonb default null,
  p_zone_id uuid default null,
  p_clear_zone boolean default false,
  p_vehicle_requirement public.vehicle_requirement default null
) returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  o public.orders;
  new_zone_id uuid;
  zone_changed boolean;
  address_changed boolean;
begin
  select * into o from public.orders where id = p_order_id for update;
  if o.id is null or not public.is_business_operational(o.business_id) then
    raise exception 'forbidden';
  end if;
  if o.delivery_status <> 'created' then
    raise exception 'order already dispatched';
  end if;

  if p_zone_id is not null then
    if not exists (select 1 from public.zones where id = p_zone_id and business_id = o.business_id and status = 'active') then
      raise exception 'invalid zone';
    end if;
    new_zone_id := p_zone_id;
  elsif p_clear_zone then
    new_zone_id := null;
  else
    new_zone_id := o.zone_id;
  end if;
  zone_changed := new_zone_id is distinct from o.zone_id;

  address_changed := p_delivery_address is not null and trim(p_delivery_address) <> '' and trim(p_delivery_address) is distinct from o.delivery_address;

  update public.orders set
    customer_name = coalesce(p_customer_name, customer_name),
    customer_phone = coalesce(p_customer_phone, customer_phone),
    delivery_address = coalesce(p_delivery_address, delivery_address),
    notes = coalesce(p_notes, notes),
    items = coalesce(p_items, items),
    zone_id = new_zone_id,
    vehicle_requirement = coalesce(p_vehicle_requirement, vehicle_requirement),
    -- Invalidate the previously-resolved canonical location on a genuine
    -- address change: back to 'unresolved', coordinates cleared -- never
    -- leave a stale lat/lng silently marked 'resolved' for an address that
    -- no longer matches it. The Vendor's own manual-correction path
    -- (set_order_location_manual) or the geocode-order Edge Function is
    -- then the way forward, exactly as for a brand-new order.
    location_status = case when address_changed then 'unresolved'::public.order_location_status else location_status end,
    latitude = case when address_changed then null else latitude end,
    longitude = case when address_changed then null else longitude end,
    location_provider = case when address_changed then null else location_provider end,
    location_resolved_at = case when address_changed then null else location_resolved_at end,
    location_error = case when address_changed then null else location_error end,
    updated_at = now()
  where id = p_order_id
  returning * into o;

  if zone_changed then
    insert into delivery_events(business_id, order_id, event_type, actor_user_id, actor_role, metadata)
      values (o.business_id, o.id, 'order.zone_changed', auth.uid(), 'vendor', jsonb_build_object('zone_id', o.zone_id));
  end if;
  if address_changed then
    insert into delivery_events(business_id, order_id, event_type, actor_user_id, actor_role, metadata)
      values (o.business_id, o.id, 'order.location_invalidated', auth.uid(), 'vendor', jsonb_build_object('reason', 'address_changed'));
  end if;

  return o;
end;
$$;
