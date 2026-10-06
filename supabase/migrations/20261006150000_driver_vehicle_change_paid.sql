-- Driver vehicle / plate change is paid (Founder 2026-10-06: RM50 per change,
-- Curlec in Malaysia, Stripe internationally). Payments are not connected yet
-- (global V1 gate: no fake success), so update_my_driver_profile now refuses
-- any change to vehicle type or plate; name and phone stay self-service.
-- The paid path will apply a vehicle change only after a confirmed payment.
-- Rollback: re-apply 20261006120000_driver_self_edit_profile.sql.

create or replace function public.update_my_driver_profile(
  p_full_name text,
  p_phone text,
  p_vehicle_type public.rider_vehicle_type,
  p_vehicle_plate text
)
returns int
language plpgsql security definer set search_path = public as $$
declare
  v_name text := nullif(btrim(p_full_name), '');
  v_phone text := nullif(btrim(p_phone), '');
  v_plate text := nullif(btrim(p_vehicle_plate), '');
  v_rows int;
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  if v_name is null or char_length(v_name) not between 2 and 80 then raise exception 'name is required'; end if;
  if v_phone is null or length(regexp_replace(v_phone, '\D', '', 'g')) not between 8 and 15 then raise exception 'invalid phone'; end if;
  if v_plate is not null and char_length(v_plate) > 20 then raise exception 'invalid plate'; end if;
  if p_vehicle_type is null then raise exception 'vehicle is required'; end if;
  -- Founder 2026-10-06: a plate or vehicle-type change is PAID (RM50 per
  -- change, Curlec / Stripe). Until a confirmed payment exists, this free
  -- path refuses any vehicle change; name and phone stay free.
  if exists (select 1 from riders r where r.auth_user_id = auth.uid()
             and (r.vehicle_type is distinct from p_vehicle_type
                  or coalesce(nullif(btrim(r.vehicle_plate), ''), '') is distinct from coalesce(v_plate, ''))) then
    raise exception 'vehicle change requires payment';
  end if;
  if exists (
    select 1 from riders r
    where r.auth_user_id = auth.uid() and r.vehicle_type <> p_vehicle_type
      -- Active work = an open stop or order (assignments are never marked
      -- completed, so their status is not a reliable signal).
      and (exists (select 1 from delivery_stops s where s.rider_id = r.id and s.status not in ('delivered', 'cancelled'))
           or exists (select 1 from orders o where o.assigned_rider_id = r.id and o.delivery_status not in ('delivered', 'cancelled')))
  ) then
    raise exception 'finish your active deliveries before changing vehicle';
  end if;
  begin
    update riders set name = v_name, phone = v_phone, vehicle_type = p_vehicle_type,
                      vehicle_plate = v_plate, updated_at = now()
      where auth_user_id = auth.uid();
    get diagnostics v_rows = row_count;
  exception when unique_violation then
    raise exception 'phone already used by another driver of a business';
  end;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    select r.business_id, 'rider.profile_updated', auth.uid(), 'rider', jsonb_build_object('rider_id', r.id)
    from riders r where r.auth_user_id = auth.uid();
  return v_rows;
end $$;
