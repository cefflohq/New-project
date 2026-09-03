-- S4-06 Batch 3: minimal Vendor-defined Zone concept. Operational grouping
-- only -- no geospatial data, no polygons, no lat/lng, no automatic
-- detection, no routing intelligence. Zone belongs to orders only, never to
-- Riders; multi-zone runs are unrestricted; nothing here touches approval,
-- assign_rider, delivery sessions, S4-06.1/.2, exact-Rider security, or
-- business isolation.

create table public.zones(
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses on delete cascade,
  name text not null,
  status text not null default 'active' check (status in ('active','inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Case-insensitive uniqueness per business (a UNIQUE INDEX, not a table
-- CONSTRAINT, since the key is an expression over name).
create unique index zones_business_name_unique on public.zones (business_id, lower(name));

alter table public.zones enable row level security;
create policy zones_vendor on public.zones for select using (public.is_business_member(business_id));
-- No insert/update/delete policy -- all mutation is through the protected
-- RPCs below, matching every other entity since S4-03.

alter table public.orders
  add column zone_id uuid references public.zones on delete set null;

-- Owner or Operator/Staff (business member) may manage zones -- matching
-- the precedent set by create_delivery_session/approve_order, not the
-- owner-only pattern used for the business profile itself.
create function public.create_zone(p_business_id uuid, p_name text) returns public.zones
language plpgsql
security definer
set search_path = public
as $$
declare
  z zones;
  clean_name text;
begin
  if not is_business_member(p_business_id) then
    raise exception 'forbidden';
  end if;
  clean_name := nullif(trim(p_name), '');
  if clean_name is null then
    raise exception 'invalid zone name';
  end if;
  if exists (select 1 from zones where business_id = p_business_id and lower(name) = lower(clean_name)) then
    raise exception 'zone name already exists';
  end if;
  insert into zones(business_id, name) values (p_business_id, clean_name) returning * into z;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (p_business_id, 'zone.created', auth.uid(), 'vendor', jsonb_build_object('zone_id', z.id, 'name', z.name));
  return z;
end;
$$;

-- Rename updates the zone entity only -- every order referencing it via
-- zone_id reflects the new name immediately through the FK join; no order
-- row is ever touched. Idempotent on a no-op resubmission.
create function public.rename_zone(p_zone_id uuid, p_name text) returns public.zones
language plpgsql
security definer
set search_path = public
as $$
declare
  z zones;
  clean_name text;
begin
  select * into z from zones where id = p_zone_id for update;
  if z.id is null or not is_business_member(z.business_id) then
    raise exception 'forbidden';
  end if;
  clean_name := nullif(trim(p_name), '');
  if clean_name is null then
    raise exception 'invalid zone name';
  end if;
  if clean_name = z.name then
    return z;
  end if;
  if exists (select 1 from zones where business_id = z.business_id and lower(name) = lower(clean_name) and id <> z.id) then
    raise exception 'zone name already exists';
  end if;
  update zones set name = clean_name, updated_at = now() where id = z.id returning * into z;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (z.business_id, 'zone.renamed', auth.uid(), 'vendor', jsonb_build_object('zone_id', z.id, 'name', z.name));
  return z;
end;
$$;

-- Deactivate only -- no hard delete in Stage 4. Never touches any order's
-- zone_id; only prevents the zone from being NEWLY assigned going forward
-- (enforced in create_delivery/update_order_details below). Idempotent.
create function public.set_zone_status(p_zone_id uuid, p_status text) returns public.zones
language plpgsql
security definer
set search_path = public
as $$
declare
  z zones;
begin
  select * into z from zones where id = p_zone_id for update;
  if z.id is null or not is_business_member(z.business_id) then
    raise exception 'forbidden';
  end if;
  if p_status not in ('active','inactive') then
    raise exception 'invalid status';
  end if;
  if z.status = p_status then
    return z;
  end if;
  update zones set status = p_status, updated_at = now() where id = z.id returning * into z;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (z.business_id, 'zone.status_changed', auth.uid(), 'vendor', jsonb_build_object('zone_id', z.id, 'status', z.status));
  return z;
end;
$$;

revoke all on function public.create_zone(uuid,text) from public, anon, authenticated;
grant execute on function public.create_zone(uuid,text) to authenticated;
revoke all on function public.rename_zone(uuid,text) from public, anon, authenticated;
grant execute on function public.rename_zone(uuid,text) to authenticated;
revoke all on function public.set_zone_status(uuid,text) from public, anon, authenticated;
grant execute on function public.set_zone_status(uuid,text) to authenticated;

-- create_delivery: add one optional trailing parameter. This changes the
-- function's argument-type signature, so CREATE OR REPLACE cannot be used
-- (Postgres requires an identical type list to replace; a new parameter
-- type would instead create a second, competing overload) -- drop the old
-- signature explicitly, then create the new one, then re-grant.
drop function if exists public.create_delivery(uuid,text,text,text,text,double precision,double precision,jsonb);

create function public.create_delivery(p_business_id uuid,p_customer_name text,p_customer_phone text,p_delivery_address text,p_notes text default '',p_latitude double precision default null,p_longitude double precision default null,p_items jsonb default '[]',p_zone_id uuid default null) returns jsonb language plpgsql security definer set search_path=public,extensions as $$declare o orders;t text;begin if not is_business_member(p_business_id) then raise exception 'forbidden';end if;if p_zone_id is not null and not exists(select 1 from zones where id=p_zone_id and business_id=p_business_id and status='active') then raise exception 'invalid zone';end if;insert into orders(business_id,customer_name,customer_phone,delivery_address,notes,latitude,longitude,items,zone_id) values(p_business_id,p_customer_name,p_customer_phone,p_delivery_address,p_notes,p_latitude,p_longitude,coalesce(p_items,'[]'),p_zone_id) returning * into o;insert into delivery_stops(business_id,order_id) values(p_business_id,o.id);t=encode(gen_random_bytes(32),'hex');insert into tracking_tokens(order_id,token_hash) values(o.id,encode(digest(t,'sha256'),'hex'));insert into delivery_events(business_id,order_id,event_type,to_status,actor_user_id,actor_role) values(p_business_id,o.id,'delivery.created','created',auth.uid(),'vendor');return jsonb_build_object('order',to_jsonb(o),'tracking_token',t);end$$;

revoke all on function public.create_delivery(uuid,text,text,text,text,double precision,double precision,jsonb,uuid) from public, anon, authenticated;
grant execute on function public.create_delivery(uuid,text,text,text,text,double precision,double precision,jsonb,uuid) to authenticated;

-- update_order_details: same signature-change reasoning -- drop, create,
-- re-grant. Reuses the function's existing pre-dispatch-only gate
-- unchanged ("order already dispatched" precondition, from S4-03 Batch 1) --
-- zone can only be assigned/changed before dispatch, exactly like every
-- other field this RPC already governs. p_clear_zone lets a Vendor
-- explicitly unset a zone (distinct from "don't touch it", matching the
-- null-means-unchanged convention already used for every other parameter
-- here). A factual order.zone_changed event is recorded only when the zone
-- actually changes -- this RPC previously recorded no audit event at all
-- for any field; this batch adds one narrowly for zone, not a general
-- retrofit.
drop function if exists public.update_order_details(uuid,text,text,text,text,jsonb);

create function public.update_order_details(
  p_order_id uuid,
  p_customer_name text default null,
  p_customer_phone text default null,
  p_delivery_address text default null,
  p_notes text default null,
  p_items jsonb default null,
  p_zone_id uuid default null,
  p_clear_zone boolean default false
) returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  o public.orders;
  new_zone_id uuid;
  zone_changed boolean;
begin
  select * into o from public.orders where id = p_order_id for update;
  if o.id is null or not public.is_business_member(o.business_id) then
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

  update public.orders set
    customer_name = coalesce(p_customer_name, customer_name),
    customer_phone = coalesce(p_customer_phone, customer_phone),
    delivery_address = coalesce(p_delivery_address, delivery_address),
    notes = coalesce(p_notes, notes),
    items = coalesce(p_items, items),
    zone_id = new_zone_id,
    updated_at = now()
  where id = p_order_id
  returning * into o;

  if zone_changed then
    insert into delivery_events(business_id, order_id, event_type, actor_user_id, actor_role, metadata)
      values (o.business_id, o.id, 'order.zone_changed', auth.uid(), 'vendor', jsonb_build_object('zone_id', o.zone_id));
  end if;

  return o;
end;
$$;

revoke all on function public.update_order_details(uuid,text,text,text,text,jsonb,uuid,boolean) from public, anon, authenticated;
grant execute on function public.update_order_details(uuid,text,text,text,text,jsonb,uuid,boolean) to authenticated;
