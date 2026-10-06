-- Business Owner verifies a Driver's licence; verified licence required to
-- take runs (Founder 2026-10-06). Cefflo only provides the system.
--
-- * driver_licences keeps ONE identity per account (IC unique, global) with
--   the licence photo FRONT and BACK. The IC number is never shown: only the
--   last 4 digits; ic_hash is not readable by any client (column grants).
-- * Verification is per business: riders.licence_verified_at / _by /
--   licence_reject_reason. verify_rider_licence: the Owner of that business
--   only. Re-submitting the IC / photos clears every verification.
-- * The Owner of a business the Driver belongs to (any status) may read the
--   Driver's licence row (masked) and photos; other businesses may not.
-- * build_rider_run and accept_run refuse a driver whose licence is not
--   verified for that business ('driver licence not verified').
-- Rollback: re-apply build_rider_run / accept_run from their previous
-- migrations, drop verify_rider_licence, restore submit_driver_licence
-- (20261006160000), drop the riders columns and the owner read policies.

alter table public.driver_licences rename column photo_path to front_path;
alter table public.driver_licences add column if not exists back_path text;

alter table public.riders
  add column if not exists licence_verified_at timestamptz,
  add column if not exists licence_verified_by uuid references auth.users(id),
  add column if not exists licence_reject_reason text;

-- column grants: no client can read ic_hash
revoke select on public.driver_licences from authenticated;
grant select (user_id, ic_last4, front_path, back_path, status, reject_reason, submitted_at, reviewed_at)
  on public.driver_licences to authenticated;

create or replace function public.is_owner_of_driver(p_user uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from riders r where r.auth_user_id = p_user and is_business_owner(r.business_id))
$$;
revoke all on function public.is_owner_of_driver(uuid) from public, anon;
grant execute on function public.is_owner_of_driver(uuid) to authenticated;

drop policy if exists driver_licences_read on public.driver_licences;
create policy driver_licences_read on public.driver_licences
  for select to authenticated
  using (user_id = auth.uid() or public.is_platform_admin() or public.is_owner_of_driver(user_id));

drop policy if exists driver_documents_own_read on storage.objects;
create policy driver_documents_own_read on storage.objects
  for select to authenticated
  using (bucket_id = 'cefflo-driver-documents'
         and ((storage.foldername(name))[1] = auth.uid()::text
              or public.is_platform_admin()
              or public.is_owner_of_driver(((storage.foldername(name))[1])::uuid)));

drop function if exists public.submit_driver_licence(text, text);
create or replace function public.submit_driver_licence(p_ic_number text, p_front_path text, p_back_path text)
returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_norm text := regexp_replace(coalesce(p_ic_number, ''), '\D', '', 'g');
  v_hash text;
  v_mine driver_licences;
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  if v_norm !~ '^[0-9]{12}$'
     or substr(v_norm, 3, 2)::int not between 1 and 12
     or substr(v_norm, 5, 2)::int not between 1 and 31 then
    raise exception 'invalid IC number';
  end if;
  if p_front_path is null or p_back_path is null or p_front_path = p_back_path
     or split_part(p_front_path, '/', 1) <> auth.uid()::text
     or split_part(p_back_path, '/', 1) <> auth.uid()::text then
    raise exception 'invalid licence photos';
  end if;
  if (select count(*) from storage.objects o where o.bucket_id = 'cefflo-driver-documents'
        and o.name in (p_front_path, p_back_path)) <> 2 then
    raise exception 'licence photos not uploaded';
  end if;
  v_hash := _ic_hash(v_norm);
  if exists (select 1 from driver_licences l where l.ic_hash = v_hash and l.user_id <> auth.uid()) then
    raise exception 'IC already registered to another account';
  end if;
  select * into v_mine from driver_licences where user_id = auth.uid() for update;
  if v_mine.user_id is not null and v_mine.ic_hash <> v_hash
     and exists (select 1 from riders where auth_user_id = auth.uid() and licence_verified_at is not null) then
    raise exception 'a verified identity cannot be replaced; contact the business';
  end if;
  insert into driver_licences(user_id, ic_hash, ic_last4, front_path, back_path, status, submitted_at)
    values (auth.uid(), v_hash, right(v_norm, 4), p_front_path, p_back_path, 'submitted', now())
  on conflict (user_id) do update
    set ic_hash = excluded.ic_hash, ic_last4 = excluded.ic_last4,
        front_path = excluded.front_path, back_path = excluded.back_path,
        status = 'submitted', reject_reason = null, submitted_at = now();
  -- new documents: every business verifies them again
  update riders set licence_verified_at = null, licence_verified_by = null, licence_reject_reason = null
   where auth_user_id = auth.uid();
  return jsonb_build_object('status', 'submitted', 'ic_last4', right(v_norm, 4));
end $$;
revoke all on function public.submit_driver_licence(text, text, text) from public, anon;
grant execute on function public.submit_driver_licence(text, text, text) to authenticated;

create or replace function public.verify_rider_licence(p_rider_id uuid, p_approve boolean, p_reason text default null)
returns public.riders
language plpgsql security definer set search_path = public as $$
declare r riders;
begin
  select * into r from riders where id = p_rider_id for update;
  if r.id is null or not is_business_owner(r.business_id) then raise exception 'forbidden'; end if;
  if not exists (select 1 from driver_licences where user_id = r.auth_user_id and front_path is not null and back_path is not null) then
    raise exception 'driver has not submitted a licence';
  end if;
  update riders
     set licence_verified_at = case when p_approve then now() end,
         licence_verified_by = case when p_approve then auth.uid() end,
         licence_reject_reason = case when p_approve then null else nullif(btrim(p_reason), '') end,
         updated_at = now()
   where id = r.id returning * into r;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (r.business_id, case when p_approve then 'rider.licence_verified' else 'rider.licence_rejected' end,
            auth.uid(), 'vendor', jsonb_build_object('rider_id', r.id));
  return r;
end $$;
revoke all on function public.verify_rider_licence(uuid, boolean, text) from public, anon;
grant execute on function public.verify_rider_licence(uuid, boolean, text) to authenticated;

CREATE OR REPLACE FUNCTION public.build_rider_run(p_delivery_session_id uuid, p_rider_id uuid, p_order_ids uuid[], p_idempotency_key uuid, p_override_capacity boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  s delivery_sessions;
  r riders;
  requested_ids uuid[];
  requested_count int;
  distinct_count int;
  locked_count int;
  eligible_count int;
  existing_event delivery_events;
  existing_session_id uuid;
  existing_rider_id uuid;
  existing_order_ids uuid[];
  oid uuid;
  violations jsonb;
  current_load integer;
begin
  if p_idempotency_key is null then
    raise exception 'idempotency key required';
  end if;
  if p_order_ids is null or array_length(p_order_ids,1) is null or array_length(p_order_ids,1) = 0 then
    raise exception 'no orders selected';
  end if;

  requested_count := array_length(p_order_ids,1);
  select array_agg(x order by x) into requested_ids from (select distinct unnest(p_order_ids) as x) d;
  distinct_count := array_length(requested_ids,1);
  if requested_count <> distinct_count then
    raise exception 'duplicate order ids';
  end if;

  select * into existing_event
    from delivery_events
    where event_type = 'run.built' and (metadata->>'idempotency_key')::uuid = p_idempotency_key
    limit 1;

  if existing_event.id is not null then
    existing_session_id := (existing_event.metadata->>'delivery_session_id')::uuid;
    existing_rider_id := (existing_event.metadata->>'rider_id')::uuid;
    select array_agg((x)::uuid order by (x)::uuid) into existing_order_ids
      from jsonb_array_elements_text(existing_event.metadata->'order_ids') as x;

    if existing_session_id = p_delivery_session_id
       and existing_rider_id = p_rider_id
       and existing_order_ids = requested_ids then
      return jsonb_build_object(
        'delivery_session_id', existing_session_id,
        'rider_id', existing_rider_id,
        'order_count', array_length(existing_order_ids,1),
        'vehicle_capacity_override_used', coalesce((existing_event.metadata->>'vehicle_capacity_override')::boolean, false)
          and coalesce(jsonb_array_length(existing_event.metadata->'vehicle_capacity_violations'), 0) > 0
      );
    else
      raise exception 'idempotency key conflict';
    end if;
  end if;

  select * into s from delivery_sessions where id = p_delivery_session_id for update;
  if s.id is null or not is_business_operational(s.business_id) then
    raise exception 'forbidden';
  end if;
  if s.status not in ('planned','active') then
    raise exception 'session not open';
  end if;

  select * into r from riders where id = p_rider_id;
  if r.id is null or r.business_id is distinct from s.business_id or r.status <> 'active' then
    raise exception 'invalid rider';
  end if;
  -- Founder 2026-10-06: a driver takes runs only after this business's
  -- Owner verified their driving licence.
  if r.licence_verified_at is null then
    raise exception 'driver licence not verified';
  end if;

  with locked as (
    select o.business_id, o.approved_at, o.assigned_rider_id, o.delivery_status, ds.preparation_status
    from orders o
    join delivery_stops ds on ds.order_id = o.id
    where o.id = any(requested_ids)
    for update
  )
  select
    count(*),
    count(*) filter (
      where business_id = s.business_id
        and approved_at is not null
        and assigned_rider_id is null
        and delivery_status = 'created'
        and preparation_status not in ('preparing','sorted')
    )
  into locked_count, eligible_count
  from locked;

  if locked_count <> distinct_count or eligible_count <> distinct_count then
    select * into existing_event
      from delivery_events
      where event_type = 'run.built' and (metadata->>'idempotency_key')::uuid = p_idempotency_key
      limit 1;

    if existing_event.id is not null then
      existing_session_id := (existing_event.metadata->>'delivery_session_id')::uuid;
      existing_rider_id := (existing_event.metadata->>'rider_id')::uuid;
      select array_agg((x)::uuid order by (x)::uuid) into existing_order_ids
        from jsonb_array_elements_text(existing_event.metadata->'order_ids') as x;

      if existing_session_id = p_delivery_session_id
         and existing_rider_id = p_rider_id
         and existing_order_ids = requested_ids then
        return jsonb_build_object(
          'delivery_session_id', existing_session_id,
          'rider_id', existing_rider_id,
          'order_count', array_length(existing_order_ids,1),
          'vehicle_capacity_override_used', coalesce((existing_event.metadata->>'vehicle_capacity_override')::boolean, false)
            and coalesce(jsonb_array_length(existing_event.metadata->'vehicle_capacity_violations'), 0) > 0
        );
      else
        raise exception 'idempotency key conflict';
      end if;
    end if;

    raise exception 'orders no longer eligible';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
      'order_id', o.id,
      'reason', 'vehicle_incompatible',
      'vehicle_requirement', o.vehicle_requirement,
      'rider_vehicle_type', r.vehicle_type
    )), '[]'::jsonb)
  into violations
  from orders o
  where o.id = any(requested_ids)
    and not is_vehicle_compatible(r.vehicle_type, o.vehicle_requirement);

  current_load := rider_active_stop_count(p_rider_id);
  if current_load + distinct_count > rider_effective_capacity(p_rider_id) then
    violations := violations || jsonb_build_array(jsonb_build_object(
      'reason', 'capacity_exceeded',
      'current_load', current_load,
      'requested', distinct_count,
      'effective_capacity', rider_effective_capacity(p_rider_id)
    ));
  end if;

  if jsonb_array_length(violations) > 0 and not p_override_capacity then
    raise exception 'vehicle/capacity incompatible: call check_run_vehicle_capacity for details before overriding';
  end if;

  foreach oid in array requested_ids loop
    perform attach_order_to_session(oid, p_delivery_session_id);
    perform assign_rider(oid, p_rider_id);
  end loop;

  begin
    insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
      values (
        s.business_id, 'run.built', auth.uid(), 'vendor',
        jsonb_build_object(
          'delivery_session_id', p_delivery_session_id,
          'rider_id', p_rider_id,
          'order_ids', to_jsonb(requested_ids),
          'idempotency_key', p_idempotency_key,
          'vehicle_capacity_override', p_override_capacity,
          'vehicle_capacity_violations', violations
        )
      );
  exception when unique_violation then
    raise exception 'idempotency key conflict';
  end;

  return jsonb_build_object(
    'delivery_session_id', p_delivery_session_id,
    'rider_id', p_rider_id,
    'order_count', distinct_count,
    'vehicle_capacity_override_used', (jsonb_array_length(violations) > 0 and p_override_capacity)
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.accept_run(p_rider_id uuid, p_delivery_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  newly_accepted_count int;
  already_accepted_count int;
  skipped_count int;
begin
  if not is_current_rider(p_rider_id) then
    raise exception 'invalid rider context';
  end if;
  if (select licence_verified_at from riders where id = p_rider_id) is null then
    raise exception 'driver licence not verified';
  end if;

  if not exists (
    select 1 from rider_assignments where rider_id = p_rider_id and delivery_session_id = p_delivery_session_id
  ) then
    raise exception 'no assignments in this run';
  end if;

  select count(*) into already_accepted_count
    from rider_assignments
    where rider_id = p_rider_id and delivery_session_id = p_delivery_session_id and status = 'accepted';

  select count(*) into skipped_count
    from rider_assignments
    where rider_id = p_rider_id and delivery_session_id = p_delivery_session_id
      and status not in ('assigned','accepted');

  with newly_accepted as (
    update rider_assignments a
    set status = 'accepted', accepted_at = now(), updated_at = now()
    where a.rider_id = p_rider_id and a.delivery_session_id = p_delivery_session_id and a.status = 'assigned'
    returning a.id
  ),
  events as (
    insert into delivery_events(business_id, order_id, delivery_stop_id, assignment_id, event_type, actor_user_id, actor_role, metadata)
    select s.business_id, s.order_id, s.id, na.id, 'assignment.accepted', auth.uid(), 'rider', jsonb_build_object('via', 'accept_run')
    from newly_accepted na join delivery_stops s on s.assignment_id = na.id
    returning 1
  )
  select count(*) into newly_accepted_count from newly_accepted;

  return jsonb_build_object(
    'delivery_session_id', p_delivery_session_id,
    'newly_accepted', newly_accepted_count,
    'already_accepted', already_accepted_count,
    'skipped', skipped_count
  );
end;
$function$;
