-- D-75 Rider Hub V1: Find Jobs (Founder-approved 2026-10-05, staging first).
-- Rider Network Strategy §7-13; Security & Access Master §27/§30.
--
-- * An Owner posts openings (Owner only, like rider approval). Each opening
--   carries the vendor's preferred rider radius (5-20 km).
-- * Every authenticated Driver can browse every open opening in the country
--   (Founder: riders plan moves), sorted by distance from where they are.
--   Only a safe projection is returned: business name, area label, rounded
--   distance, shift, pay, vehicle. Never an address, phone, customer or order.
-- * A request puts the rider in Riders > Pending (same as an invite-link
--   join); only the Owner approves. Approval approves the job request.
-- * Booked times never overlap: same weekday overlap is refused, with a
--   60-minute travel buffer between different businesses.
-- * No direct table writes: RLS on, select policies only; RPCs own writes.

-- ------------------------------------------------------------------ tables
create table public.rider_job_openings (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  area_label text not null check (char_length(btrim(area_label)) between 2 and 60),
  shift_start time not null,
  shift_end time not null,
  days smallint[] not null,
  vehicle_type public.rider_vehicle_type not null,
  pay_amount numeric(8,2) not null check (pay_amount > 0 and pay_amount <= 10000),
  pay_unit text not null check (pay_unit in ('shift','drop','hour')),
  riders_needed int not null check (riders_needed between 1 and 50),
  radius_km numeric(4,1) not null default 10 check (radius_km between 5 and 20),
  status text not null default 'open' check (status in ('open','closed')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (shift_end > shift_start),
  check (cardinality(days) between 1 and 7 and days <@ array[1,2,3,4,5,6,7]::smallint[])
);
create index rider_job_openings_open_idx on public.rider_job_openings(status, business_id);

create table public.rider_job_requests (
  id uuid primary key default gen_random_uuid(),
  opening_id uuid not null references public.rider_job_openings(id) on delete cascade,
  business_id uuid not null references public.businesses(id) on delete cascade,
  auth_user_id uuid not null references auth.users(id) on delete cascade,
  rider_id uuid not null references public.riders(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','approved','rejected','withdrawn')),
  decided_at timestamptz,
  created_at timestamptz not null default now()
);
create unique index rider_job_requests_one_live_idx
  on public.rider_job_requests(opening_id, auth_user_id) where status in ('pending','approved');
create index rider_job_requests_user_idx on public.rider_job_requests(auth_user_id, status);
create index rider_job_requests_rider_idx on public.rider_job_requests(rider_id, status);

alter table public.rider_job_openings enable row level security;
alter table public.rider_job_requests enable row level security;

-- Business members read their own business's openings and requests; a rider
-- reads only their own requests. Riders browse openings via the RPC only.
create policy rider_job_openings_member_read on public.rider_job_openings
  for select to authenticated using (public.is_business_member(business_id));
create policy rider_job_requests_read on public.rider_job_requests
  for select to authenticated
  using (auth_user_id = auth.uid() or public.is_business_member(business_id));

revoke all on public.rider_job_openings, public.rider_job_requests from anon;
revoke insert, update, delete on public.rider_job_openings, public.rider_job_requests from authenticated;

-- ----------------------------------------------------------------- helpers
-- Clash with the user's approved bookings, or null. Overlap on a shared
-- weekday is refused; different businesses also need a 60-minute buffer.
create or replace function public._rider_job_clash(p_user uuid, p_opening uuid, p_exclude_request uuid default null)
returns text language sql stable security definer set search_path = public as $$
  select format('Clashes with %s (%s - %s)', b.name, to_char(date '2000-01-01' + o2.shift_start, 'FMHH12:MI AM'), to_char(date '2000-01-01' + o2.shift_end, 'FMHH12:MI AM'))
  from rider_job_openings o
  join rider_job_requests r on r.auth_user_id = p_user and r.status = 'approved'
       and (p_exclude_request is null or r.id <> p_exclude_request)
  join rider_job_openings o2 on o2.id = r.opening_id and o2.id <> o.id
  join businesses b on b.id = o2.business_id
  where o.id = p_opening
    and o.days && o2.days
    and o.shift_start < o2.shift_end + case when o2.business_id = o.business_id then interval '0' else interval '60 minutes' end
    and o2.shift_start < o.shift_end + case when o2.business_id = o.business_id then interval '0' else interval '60 minutes' end
  limit 1
$$;
revoke all on function public._rider_job_clash(uuid, uuid, uuid) from public, anon, authenticated;

-- -------------------------------------------------------------- vendor RPCs
create or replace function public.save_job_opening(
  p_business_id uuid,
  p_area_label text,
  p_shift_start time,
  p_shift_end time,
  p_days smallint[],
  p_vehicle_type public.rider_vehicle_type,
  p_pay_amount numeric,
  p_pay_unit text,
  p_riders_needed int,
  p_radius_km numeric default 10,
  p_opening_id uuid default null
) returns public.rider_job_openings
language plpgsql security definer set search_path = public as $$
declare v rider_job_openings;
begin
  if not is_business_owner(p_business_id) then raise exception 'forbidden'; end if;
  if p_opening_id is null then
    insert into rider_job_openings(business_id, area_label, shift_start, shift_end, days, vehicle_type,
                                   pay_amount, pay_unit, riders_needed, radius_km, created_by)
      values (p_business_id, btrim(p_area_label), p_shift_start, p_shift_end,
              (select array_agg(distinct d order by d) from unnest(p_days) d), p_vehicle_type,
              p_pay_amount, p_pay_unit, p_riders_needed, coalesce(p_radius_km, 10), auth.uid())
      returning * into v;
  else
    update rider_job_openings set
      area_label = btrim(p_area_label), shift_start = p_shift_start, shift_end = p_shift_end,
      days = (select array_agg(distinct d order by d) from unnest(p_days) d),
      vehicle_type = p_vehicle_type, pay_amount = p_pay_amount, pay_unit = p_pay_unit,
      riders_needed = p_riders_needed, radius_km = coalesce(p_radius_km, 10),
      status = 'open', updated_at = now()
    where id = p_opening_id and business_id = p_business_id
    returning * into v;
    if v.id is null then raise exception 'opening not found'; end if;
  end if;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (p_business_id, 'rider_job.saved', auth.uid(), 'vendor', jsonb_build_object('opening_id', v.id));
  return v;
end $$;

create or replace function public.close_job_opening(p_opening_id uuid)
returns public.rider_job_openings
language plpgsql security definer set search_path = public as $$
declare v rider_job_openings;
begin
  select * into v from rider_job_openings where id = p_opening_id for update;
  if v.id is null or not is_business_owner(v.business_id) then raise exception 'forbidden'; end if;
  update rider_job_openings set status = 'closed', updated_at = now() where id = v.id returning * into v;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (v.business_id, 'rider_job.closed', auth.uid(), 'vendor', jsonb_build_object('opening_id', v.id));
  return v;
end $$;

-- --------------------------------------------------------------- rider RPCs
-- Every open opening, nearest first. The caller's location is only used to
-- compute a rounded distance; it is never stored.
create or replace function public.find_job_openings(p_lat double precision default null, p_lng double precision default null)
returns table (
  opening_id uuid, business_name text, area_label text, distance_km numeric, within_radius boolean,
  radius_km numeric, shift_start time, shift_end time, days smallint[], vehicle_type public.rider_vehicle_type,
  pay_amount numeric, pay_unit text, riders_needed int, my_status text, clash text
)
language plpgsql stable security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  if (p_lat is null) <> (p_lng is null) or p_lat not between -90 and 90 or p_lng not between -180 and 180 then
    raise exception 'invalid location';
  end if;
  return query
  with base as (
    select o.*, b.name as bname,
      case when p_lat is null or b.service_origin_latitude is null or b.service_origin_longitude is null then null
        else 2 * 6371 * asin(sqrt(
          power(sin(radians(b.service_origin_latitude - p_lat) / 2), 2) +
          cos(radians(p_lat)) * cos(radians(b.service_origin_latitude)) *
          power(sin(radians(b.service_origin_longitude - p_lng) / 2), 2))) end as dist
    from rider_job_openings o join businesses b on b.id = o.business_id
    where o.status = 'open'
  )
  select x.id, x.bname, x.area_label,
    case when x.dist is null then null else round(x.dist * 2) / 2 end::numeric,
    case when x.dist is null then null else x.dist <= x.radius_km end,
    x.radius_km, x.shift_start, x.shift_end, x.days, x.vehicle_type, x.pay_amount, x.pay_unit, x.riders_needed,
    (select r.status from rider_job_requests r
      where r.opening_id = x.id and r.auth_user_id = auth.uid() and r.status in ('pending','approved') limit 1),
    _rider_job_clash(auth.uid(), x.id)
  from base x
  order by x.dist nulls last, x.created_at desc
  limit 200;
end $$;

create or replace function public.request_job_opening(p_opening_id uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v rider_job_openings;
  v_rider riders;
  v_prev riders;
  v_meta jsonb;
  v_name text;
  v_phone text;
  v_vehicle public.rider_vehicle_type;
  v_plate text;
  v_clash text;
  v_req rider_job_requests;
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  if not check_rate_limit(md5(auth.uid()::text), 'request_job_opening', 3600, 30) then
    raise exception 'too many requests';
  end if;
  select * into v from rider_job_openings where id = p_opening_id and status = 'open';
  if v.id is null then raise exception 'opening not available'; end if;
  if exists (select 1 from business_members m where m.business_id = v.business_id and m.user_id = auth.uid() and m.status = 'active') then
    raise exception 'team members cannot apply to their own business';
  end if;
  if exists (select 1 from rider_job_requests where opening_id = v.id and auth_user_id = auth.uid()
             and status in ('pending','approved')) then
    raise exception 'already requested';
  end if;
  v_clash := _rider_job_clash(auth.uid(), v.id);
  if v_clash is not null then raise exception '%', v_clash; end if;

  -- Who is applying: the rider's own latest details, else what they entered
  -- at Driver registration.
  select * into v_prev from riders where auth_user_id = auth.uid() order by updated_at desc limit 1;
  select raw_user_meta_data -> 'driver_registration' into v_meta from auth.users where id = auth.uid();
  v_name := coalesce(nullif(btrim(v_prev.name), ''), nullif(btrim(v_meta ->> 'full_name'), ''));
  v_phone := coalesce(nullif(btrim(v_prev.phone), ''), nullif(btrim(v_meta ->> 'phone'), ''));
  v_plate := coalesce(nullif(btrim(v_prev.vehicle_plate), ''), nullif(btrim(v_meta ->> 'vehicle_plate'), ''));
  v_vehicle := coalesce(v_prev.vehicle_type,
    case when v_meta ->> 'vehicle_type' in ('motorcycle','car','van') then (v_meta ->> 'vehicle_type')::public.rider_vehicle_type end);
  if v_name is null or v_phone is null then raise exception 'complete your driver details first'; end if;

  select * into v_rider from riders where business_id = v.business_id and auth_user_id = auth.uid() for update;
  if v_rider.id is null then
    begin
      insert into riders(business_id, auth_user_id, name, phone, vehicle_type, vehicle_plate, status)
        values (v.business_id, auth.uid(), v_name, v_phone, v_vehicle, v_plate, 'pending')
        returning * into v_rider;
    exception when unique_violation then
      raise exception 'phone already on file for this business';
    end;
  elsif v_rider.status = 'inactive' then
    update riders set status = 'pending', updated_at = now() where id = v_rider.id returning * into v_rider;
  end if;

  insert into rider_job_requests(opening_id, business_id, auth_user_id, rider_id, status, decided_at)
    values (v.id, v.business_id, auth.uid(), v_rider.id,
            case when v_rider.status = 'active' then 'approved' else 'pending' end,
            case when v_rider.status = 'active' then now() end)
    returning * into v_req;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (v.business_id, 'rider_job.requested', auth.uid(), 'rider',
            jsonb_build_object('opening_id', v.id, 'request_id', v_req.id, 'rider_id', v_rider.id));
  return jsonb_build_object('request_id', v_req.id, 'status', v_req.status, 'rider_status', v_rider.status);
end $$;

create or replace function public.withdraw_job_request(p_request_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  update rider_job_requests set status = 'withdrawn', decided_at = now()
   where id = p_request_id and auth_user_id = auth.uid() and status in ('pending','approved');
  if not found then raise exception 'request not found'; end if;
end $$;

-- The caller's own requests and bookings (My Schedule / My week).
create or replace function public.my_job_schedule()
returns table (
  request_id uuid, status text, opening_id uuid, business_name text, area_label text,
  shift_start time, shift_end time, days smallint[], pay_amount numeric, pay_unit text
)
language sql stable security definer set search_path = public as $$
  select r.id, r.status, o.id, b.name, o.area_label, o.shift_start, o.shift_end, o.days, o.pay_amount, o.pay_unit
  from rider_job_requests r
  join rider_job_openings o on o.id = r.opening_id
  join businesses b on b.id = o.business_id
  where r.auth_user_id = auth.uid() and r.status in ('pending','approved')
  order by o.shift_start
$$;

-- ----------------------------------------------- approval follows the rider
-- Owner approves the rider (approve_pending_rider): pending job requests are
-- approved too, oldest first, skipping any that would now clash. Owner
-- rejects / removes the rider: pending requests are rejected.
create or replace function public._rider_job_follow_rider()
returns trigger language plpgsql security definer set search_path = public as $$
declare q rider_job_requests;
begin
  if new.status = old.status then return new; end if;
  if new.status = 'active' then
    for q in select * from rider_job_requests where rider_id = new.id and status = 'pending' order by created_at loop
      if _rider_job_clash(q.auth_user_id, q.opening_id, q.id) is null then
        update rider_job_requests set status = 'approved', decided_at = now() where id = q.id;
      else
        update rider_job_requests set status = 'rejected', decided_at = now() where id = q.id;
      end if;
    end loop;
  elsif new.status = 'inactive' then
    update rider_job_requests set status = 'rejected', decided_at = now()
     where rider_id = new.id and status in ('pending','approved');
  end if;
  return new;
end $$;
revoke all on function public._rider_job_follow_rider() from public, anon, authenticated;

create trigger riders_job_requests_follow
  after update of status on public.riders
  for each row execute function public._rider_job_follow_rider();

-- ------------------------------------------------------------------ grants
revoke all on function public.save_job_opening(uuid, text, time, time, smallint[], public.rider_vehicle_type, numeric, text, int, numeric, uuid) from public, anon;
revoke all on function public.close_job_opening(uuid) from public, anon;
revoke all on function public.find_job_openings(double precision, double precision) from public, anon;
revoke all on function public.request_job_opening(uuid) from public, anon;
revoke all on function public.withdraw_job_request(uuid) from public, anon;
revoke all on function public.my_job_schedule() from public, anon;
grant execute on function public.save_job_opening(uuid, text, time, time, smallint[], public.rider_vehicle_type, numeric, text, int, numeric, uuid) to authenticated;
grant execute on function public.close_job_opening(uuid) to authenticated;
grant execute on function public.find_job_openings(double precision, double precision) to authenticated;
grant execute on function public.request_job_opening(uuid) to authenticated;
grant execute on function public.withdraw_job_request(uuid) to authenticated;
grant execute on function public.my_job_schedule() to authenticated;
