-- PROPOSAL — NOT APPLIED (awaiting Founder approval).
-- docs/cefflo/security/DELIVERY_PIN_AND_PLACE_PHOTOS_PROPOSAL.md §7.
-- Vendors cannot write orders.latitude/longitude directly (no UPDATE policy on
-- orders for members), so manual / phone orders cannot get a pin. This adds one
-- narrow, audited write path: Owner/Operator pins the drop point of an order
-- that is not yet delivered or cancelled. Helper and Driver cannot (is_business_member
-- is Owner/Operator only since 20260928); cross-business and anon are refused.
create or replace function public.set_order_pin(
  p_order_id uuid,
  p_latitude double precision,
  p_longitude double precision
) returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  o public.orders;
begin
  if auth.uid() is null then
    raise exception 'forbidden';
  end if;
  if p_latitude is null or p_longitude is null
     or p_latitude <> p_latitude or p_longitude <> p_longitude          -- NaN
     or p_latitude not between 0.5 and 7.6 or p_longitude not between 99.5 and 119.5 then
    raise exception 'pin outside Malaysia';
  end if;
  select * into o from public.orders where id = p_order_id for update;
  if o.id is null or not public.is_business_member(o.business_id) then
    raise exception 'forbidden';
  end if;
  if o.delivery_status in ('delivered', 'cancelled') then
    raise exception 'order already closed';
  end if;

  -- A vendor pin is a deliberate correction, so the location counts as
  -- resolved (same bookkeeping as set_order_location_manual) and accuracy is
  -- unknown rather than carried over from a customer GPS fix.
  update public.orders set
    latitude = p_latitude,
    longitude = p_longitude,
    location_source = 'vendor',
    location_accuracy_m = null,
    location_status = 'resolved',
    location_provider = 'vendor_pin',
    location_resolved_at = now(),
    location_error = null,
    updated_at = now()
  where id = p_order_id
  returning * into o;

  insert into public.delivery_events(business_id, order_id, event_type, actor_user_id, actor_role, metadata)
    values (o.business_id, o.id, 'order.pin_set', auth.uid(), 'vendor',
            jsonb_build_object('source', 'vendor'));

  return o;
end;
$$;

revoke all on function public.set_order_pin(uuid, double precision, double precision) from public, anon;
grant execute on function public.set_order_pin(uuid, double precision, double precision) to authenticated;
