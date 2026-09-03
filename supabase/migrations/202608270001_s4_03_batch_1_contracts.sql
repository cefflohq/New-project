-- S4-03 Batch 1: additive protected backend contracts.
-- Existing broad mutation RLS policies intentionally remain unchanged until Batch 3.

create table public.business_profile_audit (
  id bigint generated always as identity primary key,
  business_id uuid not null references public.businesses on delete cascade,
  actor_user_id uuid references auth.users on delete set null,
  changed_fields text[] not null check (cardinality(changed_fields) > 0),
  request_id text,
  created_at timestamptz not null default now()
);

alter table public.business_profile_audit enable row level security;

create policy business_profile_audit_read on public.business_profile_audit
  for select using (public.is_business_member(business_id));

grant select on public.business_profile_audit to authenticated;

create function public.update_business_profile(
  p_business_id uuid,
  p_name text default null,
  p_phone text default null,
  p_email text default null,
  p_address text default null,
  p_operating_area text default null,
  p_timezone text default null,
  p_currency text default null,
  p_idempotency_key text default null
) returns public.businesses
language plpgsql
security definer
set search_path = public
as $$
declare
  b public.businesses;
  changed text[] := '{}';
begin
  if not public.is_business_owner(p_business_id) then
    raise exception 'forbidden';
  end if;

  select * into b from public.businesses where id = p_business_id for update;
  if b.id is null then
    raise exception 'forbidden';
  end if;

  if p_name is not null and p_name is distinct from b.name then changed := changed || 'name'; end if;
  if p_phone is not null and p_phone is distinct from b.phone then changed := changed || 'phone'; end if;
  if p_email is not null and p_email is distinct from b.email then changed := changed || 'email'; end if;
  if p_address is not null and p_address is distinct from b.address then changed := changed || 'address'; end if;
  if p_operating_area is not null and p_operating_area is distinct from b.operating_area then changed := changed || 'operating_area'; end if;
  if p_timezone is not null and p_timezone is distinct from b.timezone then changed := changed || 'timezone'; end if;
  if p_currency is not null and p_currency is distinct from b.currency then changed := changed || 'currency'; end if;

  if cardinality(changed) > 0 then
    update public.businesses set
      name = coalesce(p_name, name),
      phone = coalesce(p_phone, phone),
      email = coalesce(p_email, email),
      address = coalesce(p_address, address),
      operating_area = coalesce(p_operating_area, operating_area),
      timezone = coalesce(p_timezone, timezone),
      currency = coalesce(p_currency, currency),
      updated_at = now()
    where id = p_business_id
    returning * into b;

    insert into public.business_profile_audit(
      business_id, actor_user_id, changed_fields, request_id
    ) values (
      p_business_id, auth.uid(), changed, p_idempotency_key
    );
  end if;

  return b;
end;
$$;

create function public.deactivate_rider(p_rider_id uuid)
returns public.riders
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.riders;
begin
  select * into r from public.riders where id = p_rider_id for update;
  if r.id is null or not public.is_business_owner(r.business_id) then
    raise exception 'forbidden';
  end if;

  update public.riders
  set status = 'inactive', updated_at = now()
  where id = p_rider_id
  returning * into r;
  return r;
end;
$$;

create function public.update_rider_details(
  p_rider_id uuid,
  p_name text default null,
  p_phone text default null,
  p_vehicle_plate text default null
) returns public.riders
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.riders;
begin
  select * into r from public.riders where id = p_rider_id for update;
  if r.id is null or not public.is_business_member(r.business_id) then
    raise exception 'forbidden';
  end if;

  update public.riders set
    name = coalesce(p_name, name),
    phone = coalesce(p_phone, phone),
    vehicle_plate = coalesce(p_vehicle_plate, vehicle_plate),
    updated_at = now()
  where id = p_rider_id
  returning * into r;
  return r;
end;
$$;

create function public.update_order_details(
  p_order_id uuid,
  p_customer_name text default null,
  p_customer_phone text default null,
  p_delivery_address text default null,
  p_notes text default null,
  p_items jsonb default null
) returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  o public.orders;
begin
  select * into o from public.orders where id = p_order_id for update;
  if o.id is null or not public.is_business_member(o.business_id) then
    raise exception 'forbidden';
  end if;
  if o.delivery_status <> 'created' then
    raise exception 'order already dispatched';
  end if;

  update public.orders set
    customer_name = coalesce(p_customer_name, customer_name),
    customer_phone = coalesce(p_customer_phone, customer_phone),
    delivery_address = coalesce(p_delivery_address, delivery_address),
    notes = coalesce(p_notes, notes),
    items = coalesce(p_items, items),
    updated_at = now()
  where id = p_order_id
  returning * into o;
  return o;
end;
$$;

create function public.update_team_member(
  p_business_id uuid,
  p_user_id uuid,
  p_role public.member_role default null,
  p_status text default null
) returns public.business_members
language plpgsql
security definer
set search_path = public
as $$
declare
  m public.business_members;
  remaining_owners integer;
begin
  if not public.is_business_owner(p_business_id) then
    raise exception 'forbidden';
  end if;
  if p_status is not null and p_status not in ('active', 'inactive') then
    raise exception 'invalid status';
  end if;

  select * into m
  from public.business_members
  where business_id = p_business_id and user_id = p_user_id
  for update;
  if m.business_id is null then
    raise exception 'not a team member';
  end if;

  if m.role = 'owner' and m.status = 'active'
     and (p_role = 'operator' or p_status = 'inactive') then
    select count(*) into remaining_owners
    from public.business_members
    where business_id = p_business_id
      and role = 'owner'
      and status = 'active'
      and user_id <> p_user_id;
    if remaining_owners = 0 then
      raise exception 'business must retain at least one active owner';
    end if;
  end if;

  update public.business_members set
    role = coalesce(p_role, role),
    status = coalesce(p_status, status)
  where business_id = p_business_id and user_id = p_user_id
  returning * into m;
  return m;
end;
$$;

create function public.reassign_rider(p_order_id uuid, p_new_rider_id uuid)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  o public.orders;
begin
  select * into o from public.orders where id = p_order_id for update;
  if o.id is null or not public.is_business_member(o.business_id) then
    raise exception 'forbidden';
  end if;
  if not exists (
    select 1 from public.riders
    where id = p_new_rider_id
      and business_id = o.business_id
      and status = 'active'
  ) then
    raise exception 'invalid rider';
  end if;

  update public.orders
  set assigned_rider_id = p_new_rider_id, updated_at = now()
  where id = o.id
  returning * into o;

  update public.rider_assignments
  set rider_id = p_new_rider_id, updated_at = now()
  where business_id = o.business_id
    and rider_id <> p_new_rider_id
    and status not in ('completed', 'cancelled')
    and id in (
      select assignment_id from public.delivery_stops where order_id = o.id
    );

  update public.delivery_stops
  set rider_id = p_new_rider_id, updated_at = now()
  where order_id = o.id;

  return o;
end;
$$;

revoke all on function public.update_business_profile(uuid,text,text,text,text,text,text,text,text) from public;
revoke all on function public.deactivate_rider(uuid) from public;
revoke all on function public.update_rider_details(uuid,text,text,text) from public;
revoke all on function public.update_order_details(uuid,text,text,text,text,jsonb) from public;
revoke all on function public.update_team_member(uuid,uuid,public.member_role,text) from public;
revoke all on function public.reassign_rider(uuid,uuid) from public;

grant execute on function public.update_business_profile(uuid,text,text,text,text,text,text,text,text) to authenticated;
grant execute on function public.deactivate_rider(uuid) to authenticated;
grant execute on function public.update_rider_details(uuid,text,text,text) to authenticated;
grant execute on function public.update_order_details(uuid,text,text,text,text,jsonb) to authenticated;
grant execute on function public.update_team_member(uuid,uuid,public.member_role,text) to authenticated;
grant execute on function public.reassign_rider(uuid,uuid) to authenticated;
