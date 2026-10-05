-- PROPOSAL (not applied): Driver invite join keeps the driver's vehicle.
-- P1: join_via_invite_link inserted the rider row without vehicle_type /
-- vehicle_plate, so a car/van driver joined as the column default
-- 'motorcycle' with no plate (affects dispatch vehicle compatibility and
-- what the business sees). This copies the driver's own latest vehicle +
-- plate, else their Driver registration values -- the rule
-- request_job_opening already uses. Only the caller's OWN data is read
-- (auth.uid()); no new parameter, no client input, role/business still come
-- from the link. Grants unchanged (CREATE OR REPLACE).
-- Rollback: re-apply 20260930072634_open_invite_links.sql's definition.

CREATE OR REPLACE FUNCTION public.join_via_invite_link(p_token text, p_name text, p_phone text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v business_invite_links;
  v_name text := nullif(trim(p_name), '');
  v_phone text := nullif(trim(p_phone), '');
  v_rider riders;
  v_req team_join_requests;
  v_prev riders;
  v_meta jsonb;
  v_vehicle public.rider_vehicle_type;
  v_plate text;
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  select * into v from business_invite_links where token = p_token;
  if v.id is null or v.revoked_at is not null then
    raise exception 'invitation not available';
  end if;
  if v_name is null then raise exception 'name is required'; end if;

  if v.kind = 'rider' then
    if v_phone is null then raise exception 'phone is required'; end if;
    select * into v_rider from riders where business_id = v.business_id and auth_user_id = auth.uid();
    if v_rider.id is not null then
      return jsonb_build_object('business_id', v.business_id, 'kind', 'rider', 'status', v_rider.status);
    end if;
    -- P1 fix: carry the driver's own vehicle + plate (latest relationship,
    -- else Driver registration), the same rule request_job_opening uses.
    select * into v_prev from riders where auth_user_id = auth.uid() order by updated_at desc limit 1;
    select raw_user_meta_data -> 'driver_registration' into v_meta from auth.users where id = auth.uid();
    v_vehicle := coalesce(v_prev.vehicle_type,
      case when v_meta ->> 'vehicle_type' in ('motorcycle','car','van') then (v_meta ->> 'vehicle_type')::public.rider_vehicle_type end);
    v_plate := coalesce(nullif(btrim(v_prev.vehicle_plate), ''), nullif(btrim(v_meta ->> 'vehicle_plate'), ''));
    begin
      insert into riders(business_id, auth_user_id, name, phone, vehicle_type, vehicle_plate, status)
        values (v.business_id, auth.uid(), v_name, v_phone, coalesce(v_vehicle, 'motorcycle'), v_plate, 'pending')
        returning * into v_rider;
    exception when unique_violation then
      raise exception 'phone already on file for this business';
    end;
    insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
      values (v.business_id, 'rider.joined_via_link', auth.uid(), 'rider', jsonb_build_object('rider_id', v_rider.id));
    return jsonb_build_object('business_id', v.business_id, 'kind', 'rider', 'status', 'pending');
  end if;

  if exists (select 1 from business_members
             where business_id = v.business_id and user_id = auth.uid() and status = 'active') then
    return jsonb_build_object('business_id', v.business_id, 'kind', v.kind, 'status', 'active');
  end if;
  select * into v_req from team_join_requests
    where business_id = v.business_id and user_id = auth.uid() and status = 'pending';
  if v_req.id is null then
    insert into team_join_requests(business_id, user_id, role, name, phone, link_id)
      values (v.business_id, auth.uid(), v.kind::member_role, v_name, v_phone, v.id)
      returning * into v_req;
    insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
      values (v.business_id, 'team.join_requested', auth.uid(), 'vendor',
              jsonb_build_object('request_id', v_req.id, 'role', v.kind));
  end if;
  return jsonb_build_object('business_id', v.business_id, 'kind', v.kind, 'status', 'pending');
end $function$;
