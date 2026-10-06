-- Driver edits own name, phone, vehicle and plate (Founder-approved 2026-10-06; staging first).
-- V1 item "Driver self-edit profile/vehicle" (Founder 2026-10-05 split (1)).
-- Today Edit Profile / Vehicle Details are read-only in the real app because
-- no Driver-side update contract exists.
--
-- update_my_driver_profile updates ONLY the caller's own rider rows
-- (auth_user_id = auth.uid()) in every business, plus nothing else.
--   * name 2-80 chars, phone 8-15 digits, plate <= 20 chars, vehicle enum
--   * a vehicle-type change is refused while the driver has active work
--     (open runs / orders / stops) so dispatch capacity stays consistent
--   * a phone already used by another driver in the same business -> error
--   * one delivery_events row per business ('rider.profile_updated')
-- The Driver's registration metadata is updated client-side with Supabase
-- Auth updateUser (already supported). No RLS change; no new table.
-- Rollback: drop function public.update_my_driver_profile(text, text, public.rider_vehicle_type, text).

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

revoke all on function public.update_my_driver_profile(text, text, public.rider_vehicle_type, text) from public, anon;
grant execute on function public.update_my_driver_profile(text, text, public.rider_vehicle_type, text) to authenticated;
