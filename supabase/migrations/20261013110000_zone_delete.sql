-- Delete zone (Founder 2026-10-13): a deleted zone leaves the zone list and
-- its name can be used again. It is still never hard-deleted: the row stays
-- (deleted_at set, inactive, no boundary) so past orders keep their zone_id
-- and history. A zone with orders still in progress cannot be deleted.

alter table public.zones add column if not exists deleted_at timestamptz;

-- Names are unique among the zones that still exist.
drop index if exists public.zones_business_name_unique;
create unique index if not exists zones_business_name_unique
  on public.zones (business_id, lower(name)) where deleted_at is null;

create or replace function public.delete_zone(p_zone_id uuid)
returns public.zones
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  z zones;
begin
  select * into z from zones where id = p_zone_id for update;
  if z.id is null or not is_business_operational(z.business_id) then
    raise exception 'forbidden';
  end if;
  if z.deleted_at is not null then
    return z;
  end if;
  if exists (select 1 from orders where zone_id = z.id
             and delivery_status not in ('delivered', 'cancelled')) then
    raise exception 'zone has orders in progress';
  end if;
  update zones set deleted_at = now(), status = 'inactive', boundary = null, updated_at = now()
    where id = z.id returning * into z;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (z.business_id, 'zone.deleted', auth.uid(), 'vendor', jsonb_build_object('zone_id', z.id, 'name', z.name));
  return z;
end;
$function$;

revoke all on function public.delete_zone(uuid) from public, anon;
grant execute on function public.delete_zone(uuid) to authenticated;

create or replace function public.create_zone(p_business_id uuid, p_name text)
 returns zones
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  z zones;
  clean_name text;
begin
  if not is_business_operational(p_business_id) then
    raise exception 'forbidden';
  end if;
  clean_name := nullif(trim(p_name), '');
  if clean_name is null then
    raise exception 'invalid zone name';
  end if;
  if exists (select 1 from zones where business_id = p_business_id and lower(name) = lower(clean_name)
             and deleted_at is null) then
    raise exception 'zone name already exists';
  end if;
  insert into zones(business_id, name) values (p_business_id, clean_name) returning * into z;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (p_business_id, 'zone.created', auth.uid(), 'vendor', jsonb_build_object('zone_id', z.id, 'name', z.name));
  return z;
end;
$function$;

create or replace function public.rename_zone(p_zone_id uuid, p_name text)
 returns zones
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  z zones;
  clean_name text;
begin
  select * into z from zones where id = p_zone_id for update;
  if z.id is null or z.deleted_at is not null or not is_business_operational(z.business_id) then
    raise exception 'forbidden';
  end if;
  clean_name := nullif(trim(p_name), '');
  if clean_name is null then
    raise exception 'invalid zone name';
  end if;
  if clean_name = z.name then
    return z;
  end if;
  if exists (select 1 from zones where business_id = z.business_id and lower(name) = lower(clean_name)
             and id <> z.id and deleted_at is null) then
    raise exception 'zone name already exists';
  end if;
  update zones set name = clean_name, updated_at = now() where id = z.id returning * into z;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (z.business_id, 'zone.renamed', auth.uid(), 'vendor', jsonb_build_object('zone_id', z.id, 'name', z.name));
  return z;
end;
$function$;

create or replace function public.set_zone_status(p_zone_id uuid, p_status text)
 returns zones
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  z zones;
begin
  select * into z from zones where id = p_zone_id for update;
  if z.id is null or z.deleted_at is not null or not is_business_operational(z.business_id) then
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
$function$;
