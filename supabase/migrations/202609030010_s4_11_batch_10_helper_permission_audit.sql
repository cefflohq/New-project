-- S4-11 Batch 10 (Grow V1 Flow 2 continuation): bounded Helper permission
-- audit, per Founder instruction "do not assume every is_business_member()
-- RPC should be available to Operations/Helper."
--
-- Classification principle applied: narrow to is_business_operational
-- (Owner/Operator only) every RPC that represents order/rider/zone/session
-- MANAGEMENT authority -- the class of decision that defines what work
-- exists and who executes it, which is squarely Vendor/Operator territory,
-- not Prepare->Pack->Ready. Left untouched (still is_business_member,
-- Helper-visible): read-only/preview functions (list_plannable_orders,
-- order_coverage_status, check_run_vehicle_capacity, propose_delivery_plan
-- -- already correctly scoped this way since Batch 2/3/4), and every
-- Storefront/product-catalog RPC (create_product*, product_media*,
-- order_page*, tracking-token rotation) -- a separate feature surface from
-- the Grow V1 operational engine this addendum concerns; narrowing those
-- here would be an unreviewed scope expansion, not a bounded audit, so
-- they are explicitly left for a dedicated pass, not silently ignored.
--
-- Every body below is byte-identical to its current, verified-latest
-- version (traced past every prior redefinition, not the oldest match) --
-- the ONLY change in each is_business_member -> is_business_operational.

create or replace function public.create_zone(p_business_id uuid, p_name text) returns public.zones
language plpgsql security definer set search_path = public
as $$
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
  if exists (select 1 from zones where business_id = p_business_id and lower(name) = lower(clean_name)) then
    raise exception 'zone name already exists';
  end if;
  insert into zones(business_id, name) values (p_business_id, clean_name) returning * into z;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (p_business_id, 'zone.created', auth.uid(), 'vendor', jsonb_build_object('zone_id', z.id, 'name', z.name));
  return z;
end;
$$;

create or replace function public.rename_zone(p_zone_id uuid, p_name text) returns public.zones
language plpgsql security definer set search_path = public
as $$
declare
  z zones;
  clean_name text;
begin
  select * into z from zones where id = p_zone_id for update;
  if z.id is null or not is_business_operational(z.business_id) then
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

create or replace function public.set_zone_status(p_zone_id uuid, p_status text) returns public.zones
language plpgsql security definer set search_path = public
as $$
declare
  z zones;
begin
  select * into z from zones where id = p_zone_id for update;
  if z.id is null or not is_business_operational(z.business_id) then
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

create or replace function public.create_rider_invitation(
  p_business_id uuid,
  p_invited_email text,
  p_invited_name text,
  p_invited_phone text
) returns jsonb
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_invitation rider_invitations;
  v_email text;
  v_name text;
  v_phone text;
  v_token text;
begin
  if not is_business_operational(p_business_id) then
    raise exception 'forbidden';
  end if;
  v_email := lower(trim(p_invited_email));
  if v_email = '' or v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'invalid email';
  end if;
  v_name := nullif(trim(p_invited_name), '');
  v_phone := nullif(trim(p_invited_phone), '');
  if v_name is null or v_phone is null then
    raise exception 'name and phone are required';
  end if;
  if exists (select 1 from riders where business_id = p_business_id and phone = v_phone) then
    raise exception 'phone already on file for this business';
  end if;

  v_token := encode(gen_random_bytes(32), 'hex');
  insert into rider_invitations(business_id, invited_email, invited_name, invited_phone, invited_by, token_hash, expires_at)
    values (p_business_id, v_email, v_name, v_phone, auth.uid(), encode(digest(v_token, 'sha256'), 'hex'), now() + interval '7 days')
    returning * into v_invitation;

  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (p_business_id, 'rider.invite_created', auth.uid(), 'vendor',
            jsonb_build_object('invitation_id', v_invitation.id));

  return jsonb_build_object(
    'invitation_id', v_invitation.id, 'business_id', p_business_id,
    'invited_email', v_email, 'expires_at', v_invitation.expires_at, 'token', v_token
  );
end;
$$;

create or replace function public.revoke_rider_invitation(p_invitation_id uuid) returns public.rider_invitations
language plpgsql security definer set search_path = public
as $$
declare
  v_invitation rider_invitations;
begin
  select * into v_invitation from rider_invitations where id = p_invitation_id for update;
  if v_invitation.id is null or not is_business_operational(v_invitation.business_id) then
    raise exception 'forbidden';
  end if;
  if v_invitation.status <> 'pending' then
    return v_invitation;
  end if;
  update rider_invitations set status = 'revoked', updated_at = now()
    where id = v_invitation.id
    returning * into v_invitation;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (v_invitation.business_id, 'rider.invite_revoked', auth.uid(), 'vendor',
            jsonb_build_object('invitation_id', v_invitation.id));
  return v_invitation;
end;
$$;

create or replace function public.reassign_rider(p_order_id uuid, p_new_rider_id uuid)
returns public.orders
language plpgsql security definer set search_path = public
as $$
declare
  o public.orders;
  old_rider_id uuid;
begin
  select * into o from public.orders where id = p_order_id for update;
  if o.id is null or not public.is_business_operational(o.business_id) then
    raise exception 'forbidden';
  end if;

  if o.delivery_status not in ('created', 'ready_for_pickup') then
    raise exception 'reassignment not allowed after pickup';
  end if;

  if exists (
    select 1 from public.delivery_stops where order_id = o.id and sequence_locked_at is not null
  ) then
    raise exception 'reassignment not allowed after pickup';
  end if;

  if not exists (
    select 1 from public.riders
    where id = p_new_rider_id
      and business_id = o.business_id
      and status = 'active'
  ) then
    raise exception 'invalid rider';
  end if;

  old_rider_id := o.assigned_rider_id;

  if old_rider_id = p_new_rider_id then
    return o;
  end if;

  update public.orders
  set assigned_rider_id = p_new_rider_id, updated_at = now()
  where id = o.id
  returning * into o;

  update public.rider_assignments
  set rider_id = p_new_rider_id, status = 'assigned', accepted_at = null, updated_at = now()
  where business_id = o.business_id
    and rider_id = old_rider_id
    and status not in ('completed', 'cancelled')
    and id in (
      select assignment_id from public.delivery_stops where order_id = o.id
    );

  update public.delivery_stops
  set rider_id = p_new_rider_id, sequence = null, updated_at = now()
  where order_id = o.id;

  insert into delivery_events(business_id, order_id, delivery_stop_id, assignment_id, event_type, actor_user_id, actor_role, metadata)
  select o.business_id, o.id, s.id, s.assignment_id, 'rider.reassigned', auth.uid(), 'vendor',
         jsonb_build_object('from_rider_id', old_rider_id, 'to_rider_id', p_new_rider_id)
  from public.delivery_stops s where s.order_id = o.id;

  return o;
end;
$$;

create or replace function public.decline_order(p_order_id uuid, p_reason text default null)
returns public.orders
language plpgsql security definer set search_path = public
as $$
declare o public.orders;
begin
  select * into o from public.orders where id = p_order_id for update;
  if o.id is null or not public.is_business_operational(o.business_id) then raise exception 'forbidden'; end if;
  if o.approved_at is not null then raise exception 'order already approved'; end if;
  if o.delivery_status <> 'created' then raise exception 'order not in needs review state'; end if;
  update public.orders set delivery_status = 'cancelled', updated_at = now() where id = o.id returning * into o;
  insert into public.delivery_events(business_id, order_id, event_type, from_status, to_status, actor_user_id, actor_role, metadata)
    values (o.business_id, o.id, 'order.declined', 'created', 'cancelled', auth.uid(), 'vendor',
            jsonb_build_object('reason', nullif(btrim(coalesce(p_reason, '')), '')));
  return o;
end;
$$;

create or replace function public.vendor_report_delivery_issue(
  p_order_id uuid,
  p_reason_type public.delivery_issue_reason,
  p_note text default null
) returns public.orders
language plpgsql security definer set search_path = public
as $$
declare
  o orders;
  old delivery_status;
begin
  select * into o from orders where id = p_order_id for update;
  if o.id is null or not is_business_operational(o.business_id) then
    raise exception 'forbidden';
  end if;

  old := o.delivery_status;
  if old = 'issue' then
    return o;
  end if;
  if old not in ('created','ready_for_pickup','picked_up','out_for_delivery','arrived') then
    raise exception 'invalid transition % -> issue', old;
  end if;

  update orders set delivery_status = 'issue', updated_at = now() where id = o.id returning * into o;
  update delivery_stops set status = 'issue', updated_at = now() where order_id = o.id;

  insert into delivery_events(business_id, order_id, delivery_stop_id, assignment_id, event_type, from_status, to_status, actor_user_id, actor_role, metadata)
    select o.business_id, o.id, s.id, s.assignment_id, 'delivery.issue_reported', old, 'issue', auth.uid(), 'vendor',
           jsonb_build_object('reason_type', p_reason_type::text, 'note', nullif(trim(coalesce(p_note, '')), ''))
    from delivery_stops s where s.order_id = o.id;

  return o;
end;
$$;

create or replace function public.create_delivery_session(
  p_business_id uuid,
  p_name text default 'Delivery Session',
  p_delivery_date date default current_date
) returns public.delivery_sessions
language plpgsql security definer set search_path = public
as $$
declare
  s delivery_sessions;
begin
  if not is_business_operational(p_business_id) then
    raise exception 'forbidden';
  end if;
  insert into delivery_sessions(business_id, name, delivery_date)
    values (
      p_business_id,
      coalesce(nullif(trim(p_name), ''), 'Delivery Session'),
      coalesce(p_delivery_date, current_date)
    )
    returning * into s;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role)
    values (p_business_id, 'session.created', auth.uid(), 'vendor');
  return s;
end;
$$;

create or replace function public.update_session_status(
  p_delivery_session_id uuid,
  p_status text
) returns public.delivery_sessions
language plpgsql security definer set search_path = public
as $$
declare
  s delivery_sessions;
begin
  select * into s from delivery_sessions where id = p_delivery_session_id for update;
  if s.id is null or not is_business_operational(s.business_id) then
    raise exception 'forbidden';
  end if;
  if p_status not in ('planned','active','completed','cancelled') then
    raise exception 'invalid status';
  end if;
  update delivery_sessions set
    status = p_status,
    started_at = case when p_status = 'active' and started_at is null then now() else started_at end,
    completed_at = case when p_status = 'completed' and completed_at is null then now() else completed_at end,
    updated_at = now()
    where id = s.id
    returning * into s;
  insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
    values (s.business_id, 'session.status_changed', auth.uid(), 'vendor', jsonb_build_object('delivery_session_id', s.id, 'status', p_status));
  return s;
end;
$$;

-- My own Flow 2 functions: same narrowing, same signatures (no drop
-- needed), bodies otherwise byte-identical to their Batch 2/3/5 versions.
create or replace function public.set_business_service_area(
  p_business_id uuid,
  p_origin_latitude double precision,
  p_origin_longitude double precision,
  p_radius_km numeric
) returns public.businesses
language plpgsql security definer set search_path = public
as $$
declare
  b public.businesses;
begin
  if not is_business_operational(p_business_id) then
    raise exception 'forbidden';
  end if;
  if p_origin_latitude is null or p_origin_longitude is null or p_radius_km is null then
    raise exception 'origin and radius are all required to configure a service area';
  end if;
  if p_radius_km <= 0 then
    raise exception 'radius must be positive';
  end if;
  update public.businesses set
    service_origin_latitude = p_origin_latitude,
    service_origin_longitude = p_origin_longitude,
    service_coverage_radius_km = p_radius_km,
    updated_at = now()
  where id = p_business_id
  returning * into b;
  return b;
end;
$$;

create or replace function public.update_rider_details(
  p_rider_id uuid,
  p_name text default null,
  p_phone text default null,
  p_vehicle_plate text default null,
  p_vehicle_type public.rider_vehicle_type default null,
  p_capacity_override integer default null
) returns public.riders
language plpgsql security definer set search_path = public
as $$
declare
  r public.riders;
begin
  select * into r from public.riders where id = p_rider_id for update;
  if r.id is null or not public.is_business_operational(r.business_id) then
    raise exception 'forbidden';
  end if;
  if p_capacity_override is not null and p_capacity_override <= 0 then
    raise exception 'capacity override must be positive';
  end if;
  update public.riders set
    name = coalesce(p_name, name),
    phone = coalesce(p_phone, phone),
    vehicle_plate = coalesce(p_vehicle_plate, vehicle_plate),
    vehicle_type = coalesce(p_vehicle_type, vehicle_type),
    capacity_override = case when p_capacity_override is not null then p_capacity_override else capacity_override end,
    updated_at = now()
  where id = p_rider_id
  returning * into r;
  return r;
end;
$$;

create or replace function public.create_delivery(
  p_business_id uuid,
  p_customer_name text,
  p_customer_phone text,
  p_delivery_address text,
  p_notes text default '',
  p_latitude double precision default null,
  p_longitude double precision default null,
  p_items jsonb default '[]',
  p_zone_id uuid default null,
  p_vehicle_requirement public.vehicle_requirement default 'any'
) returns jsonb
language plpgsql security definer set search_path = public, extensions
as $$
declare
  o orders;
  t text;
begin
  if not is_business_operational(p_business_id) then
    raise exception 'forbidden';
  end if;
  if p_zone_id is not null and not exists(select 1 from zones where id = p_zone_id and business_id = p_business_id and status = 'active') then
    raise exception 'invalid zone';
  end if;
  insert into orders(business_id, customer_name, customer_phone, delivery_address, notes, latitude, longitude, items, zone_id, vehicle_requirement)
    values (p_business_id, p_customer_name, p_customer_phone, p_delivery_address, p_notes, p_latitude, p_longitude, coalesce(p_items,'[]'), p_zone_id, p_vehicle_requirement)
    returning * into o;
  insert into delivery_stops(business_id, order_id) values (p_business_id, o.id);
  t = encode(gen_random_bytes(32), 'hex');
  insert into tracking_tokens(order_id, token_hash) values (o.id, encode(digest(t,'sha256'),'hex'));
  insert into delivery_events(business_id, order_id, event_type, to_status, actor_user_id, actor_role)
    values (p_business_id, o.id, 'delivery.created', 'created', auth.uid(), 'vendor');
  return jsonb_build_object('order', to_jsonb(o), 'tracking_token', t);
end;
$$;

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
language plpgsql security definer set search_path = public
as $$
declare
  o public.orders;
  new_zone_id uuid;
  zone_changed boolean;
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

  update public.orders set
    customer_name = coalesce(p_customer_name, customer_name),
    customer_phone = coalesce(p_customer_phone, customer_phone),
    delivery_address = coalesce(p_delivery_address, delivery_address),
    notes = coalesce(p_notes, notes),
    items = coalesce(p_items, items),
    zone_id = new_zone_id,
    vehicle_requirement = coalesce(p_vehicle_requirement, vehicle_requirement),
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

create or replace function public.import_orders_batch(
  p_business_id uuid,
  p_rows jsonb,
  p_idempotency_key uuid
) returns jsonb
language plpgsql security definer set search_path = public, extensions
as $$
declare
  existing_event delivery_events;
  row_obj jsonb;
  row_ref text;
  c_name text;
  c_phone text;
  c_addr text;
  c_notes text;
  c_zone_name text;
  c_items_desc text;
  matched_zone_id uuid;
  new_order jsonb;
  committed jsonb := '[]'::jsonb;
  rejected jsonb := '[]'::jsonb;
  items_payload jsonb;
begin
  if not is_business_operational(p_business_id) then
    raise exception 'forbidden';
  end if;
  if p_idempotency_key is null then
    raise exception 'idempotency key required';
  end if;
  if p_rows is null or jsonb_typeof(p_rows) <> 'array' or jsonb_array_length(p_rows) = 0 then
    raise exception 'no rows to import';
  end if;

  select * into existing_event
    from delivery_events
    where event_type = 'import.committed' and (metadata->>'idempotency_key')::uuid = p_idempotency_key
    limit 1;
  if existing_event.id is not null then
    if (existing_event.metadata->>'business_id')::uuid <> p_business_id
       or existing_event.metadata->'rows' <> p_rows then
      raise exception 'idempotency key conflict';
    end if;
    return jsonb_build_object(
      'committed', existing_event.metadata->'committed',
      'rejected', existing_event.metadata->'rejected'
    );
  end if;

  for row_obj in select * from jsonb_array_elements(p_rows) loop
    row_ref := row_obj->>'source_row_ref';
    c_name := nullif(trim(row_obj->>'customer_name'), '');
    c_phone := nullif(trim(row_obj->>'customer_phone'), '');
    c_addr := nullif(trim(row_obj->>'delivery_address'), '');
    c_notes := coalesce(row_obj->>'notes', '');
    c_zone_name := nullif(trim(row_obj->>'zone_name'), '');
    c_items_desc := nullif(trim(row_obj->>'items_description'), '');

    if c_name is null or c_phone is null or c_addr is null then
      rejected := rejected || jsonb_build_array(jsonb_build_object(
        'source_row_ref', row_ref,
        'reason', 'missing_required_field'
      ));
      continue;
    end if;

    matched_zone_id := null;
    if c_zone_name is not null then
      select id into matched_zone_id from zones
        where business_id = p_business_id and status = 'active' and lower(name) = lower(c_zone_name)
        limit 1;
    end if;

    if c_items_desc is not null then
      items_payload := jsonb_build_array(jsonb_build_object('description', c_items_desc, 'quantity', 1));
    else
      items_payload := '[]'::jsonb;
    end if;

    begin
      new_order := create_delivery(
        p_business_id, c_name, c_phone, c_addr, c_notes,
        null, null, items_payload, matched_zone_id, 'any'
      );
      committed := committed || jsonb_build_array(jsonb_build_object(
        'source_row_ref', row_ref,
        'order_id', new_order->'order'->>'id',
        'public_ref', new_order->'order'->>'public_ref'
      ));
    exception when others then
      rejected := rejected || jsonb_build_array(jsonb_build_object(
        'source_row_ref', row_ref,
        'reason', sqlerrm
      ));
    end;
  end loop;

  begin
    insert into delivery_events(business_id, event_type, actor_user_id, actor_role, metadata)
      values (p_business_id, 'import.committed', auth.uid(), 'vendor',
              jsonb_build_object(
                'idempotency_key', p_idempotency_key,
                'business_id', p_business_id,
                'rows', p_rows,
                'committed', committed,
                'rejected', rejected
              ));
  exception when unique_violation then
    raise exception 'idempotency key conflict';
  end;

  return jsonb_build_object('committed', committed, 'rejected', rejected);
end;
$$;
