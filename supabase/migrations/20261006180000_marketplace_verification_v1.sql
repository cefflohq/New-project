-- Marketplace Verification V1 (Founder 2026-10-06, approved).
--
-- Supersedes the Owner licence model of 20261006170000:
-- * Vendor-invited drivers are FREE and never need Marketplace Verification:
--   build_rider_run / accept_run no longer check any licence.
-- * Businesses (Owner / Operator / Helper) never see the IC, the IC hash,
--   the licence image, the vehicle photo or any screening evidence.
--   verify_rider_licence, is_owner_of_driver, riders.licence_* and the Owner
--   read policies are removed.
--
-- IC: HMAC-SHA256(normalized 12-digit IC, secret) — the key lives only in
-- Supabase Vault ('driver_ic_hmac_key', created per environment, never in
-- the repo). Unique; never readable by any client; only ic_last4 returned.
-- (Staging rows hashed with the old unkeyed SHA-256 were reset separately;
-- production has none.)
--
-- Licence: ONE image. Vehicle: type + declared plate + ONE live photo.
-- Screening (OCR via Google Cloud Vision) runs server-side in the Edge
-- Function verify-marketplace-driver, which only EXTRACTS fields and hands
-- them to record_marketplace_screening (service_role only). The decision
-- rules live here, in SQL: missing/failed OCR can never verify a driver.
-- OCR is document screening, not JPJ verification.
-- States: not_started (incl. retake requested) / pending / verified /
-- needs_review / rejected. 'rejected' is set only by a Cefflo platform
-- admin (FOUNDR exception review), never automatically.
-- Find Jobs: applying (request_job_opening) requires has_marketplace_access,
-- which today means verified; the future paid RM49 activation is added
-- there once the payment architecture exists. Browsing stays open.
-- No biometric data of any kind (face recognition is on HOLD).
--
-- Rollback: restore functions from 20261006170000 / 20261006160000, drop
-- driver_marketplace_verifications and the new functions.

-- 1. remove the Owner licence model ------------------------------------
drop function if exists public.verify_rider_licence(uuid, boolean, text);
drop policy if exists driver_licences_read on public.driver_licences;
drop policy if exists driver_documents_own_read on storage.objects;
drop function if exists public.is_owner_of_driver(uuid);
alter table public.riders
  drop column if exists licence_verified_at,
  drop column if exists licence_verified_by,
  drop column if exists licence_reject_reason;

create policy driver_documents_own_read on storage.objects
  for select to authenticated
  using (bucket_id = 'cefflo-driver-documents'
         and ((storage.foldername(name))[1] = auth.uid()::text or public.is_platform_admin()));

-- 2. identity record: IC (HMAC) + ONE licence image ----------------------
drop function if exists public.submit_driver_licence(text, text, text);
drop function if exists public.review_driver_licence(uuid, boolean, text);
alter table public.driver_licences rename column front_path to licence_path;
alter table public.driver_licences
  drop column if exists back_path,
  drop column if exists status,
  drop column if exists reject_reason,
  drop column if exists reviewed_at,
  drop column if exists reviewed_by;
-- no client reads this table directly (Driver uses my_marketplace_verification)
revoke all on public.driver_licences from anon, authenticated;
create policy driver_licences_admin_read on public.driver_licences
  for select to authenticated using (public.is_platform_admin());
grant select (user_id, ic_last4, licence_path, submitted_at) on public.driver_licences to authenticated;

create or replace function public._ic_normalize(p_ic text)
returns text language sql immutable as $$
  select regexp_replace(coalesce(p_ic, ''), '\D', '', 'g')
$$;

create or replace function public._ic_hash(p_ic text)
returns text language plpgsql stable security definer set search_path = public, extensions as $$
declare k text;
begin
  select decrypted_secret into k from vault.decrypted_secrets where name = 'driver_ic_hmac_key';
  if k is null or length(k) < 32 then raise exception 'IC key not configured'; end if;
  return encode(hmac(_ic_normalize(p_ic), k, 'sha256'), 'hex');
end $$;
revoke all on function public._ic_hash(text) from public, anon, authenticated;

-- 3. verification state ---------------------------------------------------
create table if not exists public.driver_marketplace_verifications (
  user_id uuid primary key references auth.users(id) on delete cascade,
  status text not null default 'not_started'
    check (status in ('not_started', 'pending', 'verified', 'needs_review', 'rejected')),
  retake text check (retake in ('licence', 'vehicle')),
  reasons text[] not null default '{}',
  vehicle_type public.rider_vehicle_type,
  vehicle_plate text,
  vehicle_photo_path text,
  licence_result jsonb,
  plate_result jsonb,
  attempts int not null default 0,
  submitted_at timestamptz,
  screened_at timestamptz,
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id),
  updated_at timestamptz not null default now()
);
alter table public.driver_marketplace_verifications enable row level security;
revoke all on public.driver_marketplace_verifications from anon, authenticated;
create policy marketplace_verifications_admin_read on public.driver_marketplace_verifications
  for select to authenticated using (public.is_platform_admin());
grant select on public.driver_marketplace_verifications to authenticated; -- admin only via RLS

create or replace function public._plate_normalize(p text)
returns text language sql immutable as $$
  select upper(regexp_replace(coalesce(p, ''), '[^A-Za-z0-9]', '', 'g'))
$$;

-- one character apart, or equal after folding OCR-confusable characters
create or replace function public._plate_near(a text, b text)
returns boolean language plpgsql immutable as $$
declare i int; d int := 0;
begin
  if translate(a, 'O0I1L8BS5Z2', 'OOIIIBBSSZZ') = translate(b, 'O0I1L8BS5Z2', 'OOIIIBBSSZZ') then return true; end if;
  if length(a) = length(b) then
    for i in 1..length(a) loop if substr(a, i, 1) <> substr(b, i, 1) then d := d + 1; end if; end loop;
    return d = 1;
  end if;
  if abs(length(a) - length(b)) = 1 then
    return position(a in b) > 0 or position(b in a) > 0;
  end if;
  return false;
end $$;

create or replace function public._name_tokens(p text)
returns text[] language sql immutable as $$
  select coalesce(array_agg(t), '{}') from unnest(regexp_split_to_array(upper(regexp_replace(coalesce(p, ''), '[^A-Za-z ]', ' ', 'g')), '\s+')) t
   where length(t) > 1 and t not in ('BIN', 'BINTI', 'BTE', 'BT', 'AL', 'AP')
$$;

/* Decision rules. Confidence threshold 0.85. Retake after 3 failed
   screenings becomes needs_review ('repeated_retakes'). */
create or replace function public._marketplace_decide(p_user uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v driver_marketplace_verifications;
  l driver_licences;
  lr jsonb; pr jsonb;
  v_reasons text[] := '{}';
  v_retake text;
  v_lic_ok boolean := false; v_plate_ok boolean := false;
  v_name text; v_classes text[]; v_expiry date; v_declared text; v_best jsonb; v_p text;
  v_status text;
  v_missing boolean := false;
begin
  select * into v from driver_marketplace_verifications where user_id = p_user for update;
  select * into l from driver_licences where user_id = p_user;
  if v.user_id is null or v.status in ('verified', 'rejected') then return; end if;
  lr := v.licence_result; pr := v.plate_result;

  -- licence
  if l.user_id is null then
    v_missing := true;
  elsif lr is null then
    null; -- not screened yet
  elsif coalesce((lr ->> 'text_found')::boolean, false) is false or nullif(lr ->> 'ic', '') is null then
    v_retake := 'licence'; v_reasons := array_append(v_reasons, 'licence_unreadable');
  elsif _ic_hash(lr ->> 'ic') <> l.ic_hash then
    v_reasons := array_append(v_reasons, 'ic_mismatch');
  else
    v_classes := array(select upper(jsonb_array_elements_text(coalesce(lr -> 'classes', '[]'))));
    v_expiry := nullif(lr ->> 'expiry', '')::date;
    if cardinality(v_classes) = 0 or v_expiry is null then
      v_retake := 'licence'; v_reasons := array_append(v_reasons, 'licence_fields_missing');
    else
      select coalesce(nullif(btrim(raw_user_meta_data -> 'driver_registration' ->> 'full_name'), ''),
                      (select name from riders where auth_user_id = p_user order by updated_at desc limit 1))
        into v_name from auth.users where id = p_user;
      if coalesce((lr ->> 'confidence')::numeric, 0) < 0.85 then v_reasons := array_append(v_reasons, 'low_confidence'); end if;
      if nullif(lr ->> 'name', '') is null or v_name is null
         or not (_name_tokens(v_name) <@ _name_tokens(lr ->> 'name') or _name_tokens(lr ->> 'name') <@ _name_tokens(v_name))
         or cardinality(_name_tokens(v_name)) = 0 then
        v_reasons := array_append(v_reasons, 'name_mismatch');
      end if;
      if v_expiry < current_date then v_reasons := array_append(v_reasons, 'licence_expired'); end if;
      if v_expiry > current_date + interval '15 years' then v_reasons := array_append(v_reasons, 'expiry_suspicious'); end if;
      if v.vehicle_type is not null and not (v_classes && case v.vehicle_type
           when 'motorcycle' then array['B', 'B1', 'B2', 'B FULL']
           else array['D', 'DA', 'E', 'E1', 'E2'] end) then
        v_reasons := array_append(v_reasons, 'class_incompatible');
      end if;
      v_lic_ok := cardinality(v_reasons) = 0;
    end if;
  end if;

  -- vehicle / plate
  v_declared := _plate_normalize(v.vehicle_plate);
  if v.vehicle_photo_path is null or v_declared = '' then
    v_missing := true;
  elsif pr is null then
    null;
  else
    select e into v_best from jsonb_array_elements(coalesce(pr -> 'plates', '[]')) e
      order by (_plate_normalize(e ->> 'text') = v_declared) desc, (e ->> 'confidence')::numeric desc nulls last limit 1;
    v_p := _plate_normalize(v_best ->> 'text');
    if v_best is null or v_p = '' then
      v_retake := coalesce(v_retake, 'vehicle'); v_reasons := array_append(v_reasons, 'plate_unreadable');
    elsif v_p = v_declared and coalesce((v_best ->> 'confidence')::numeric, 0) >= 0.85 then
      v_plate_ok := true;
    elsif v_p = v_declared then
      v_reasons := array_append(v_reasons, 'plate_low_confidence');
    elsif _plate_near(v_p, v_declared) then
      v_reasons := array_append(v_reasons, 'plate_ambiguous');
    else
      v_reasons := array_append(v_reasons, 'plate_mismatch');
    end if;
  end if;

  if v_retake is not null and v.attempts >= 3 then
    v_reasons := array_append(v_reasons, 'repeated_retakes');
  end if;
  v_status := case
    when cardinality(array_remove(array_remove(array_remove(v_reasons,
           'licence_unreadable'), 'licence_fields_missing'), 'plate_unreadable')) > 0 then 'needs_review'
    when v_retake is not null then 'not_started'
    when v_missing then 'not_started'
    when v_lic_ok and v_plate_ok then 'verified'
    else 'pending' end;

  update driver_marketplace_verifications
     set status = v_status,
         retake = case when v_status = 'not_started' then v_retake end,
         reasons = v_reasons, updated_at = now()
   where user_id = p_user;
end $$;
revoke all on function public._marketplace_decide(uuid) from public, anon, authenticated;

-- 4. Driver RPCs -----------------------------------------------------------
create or replace function public.submit_driver_licence(p_ic_number text, p_licence_path text)
returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_norm text := _ic_normalize(p_ic_number);
  v_hash text;
  v_mine driver_licences;
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  if v_norm !~ '^[0-9]{12}$'
     or substr(v_norm, 3, 2)::int not between 1 and 12
     or substr(v_norm, 5, 2)::int not between 1 and 31 then
    raise exception 'invalid IC number';
  end if;
  if p_licence_path is null or split_part(p_licence_path, '/', 1) <> auth.uid()::text
     or not exists (select 1 from storage.objects o where o.bucket_id = 'cefflo-driver-documents' and o.name = p_licence_path) then
    raise exception 'licence photo not uploaded';
  end if;
  v_hash := _ic_hash(v_norm);
  if exists (select 1 from driver_licences where ic_hash = v_hash and user_id <> auth.uid()) then
    raise exception 'IC already registered to another account';
  end if;
  select * into v_mine from driver_licences where user_id = auth.uid() for update;
  if v_mine.user_id is not null and v_mine.ic_hash <> v_hash
     and exists (select 1 from driver_marketplace_verifications where user_id = auth.uid() and status = 'verified') then
    raise exception 'a verified identity cannot be replaced; contact Cefflo support';
  end if;
  insert into driver_licences(user_id, ic_hash, ic_last4, licence_path, submitted_at)
    values (auth.uid(), v_hash, right(v_norm, 4), p_licence_path, now())
  on conflict (user_id) do update
    set ic_hash = excluded.ic_hash, ic_last4 = excluded.ic_last4,
        licence_path = excluded.licence_path, submitted_at = now();
  insert into driver_marketplace_verifications(user_id, status, submitted_at)
    values (auth.uid(), 'pending', now())
  on conflict (user_id) do update
    set status = case when driver_marketplace_verifications.status in ('verified', 'rejected')
                      then driver_marketplace_verifications.status else 'pending' end,
        licence_result = case when driver_marketplace_verifications.status in ('verified', 'rejected')
                      then driver_marketplace_verifications.licence_result end,
        retake = null, submitted_at = now(), updated_at = now();
  perform _marketplace_decide(auth.uid());
  return my_marketplace_verification();
end $$;

create or replace function public.submit_marketplace_vehicle(p_vehicle_type text, p_vehicle_plate text, p_photo_path text)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_plate text := _plate_normalize(p_vehicle_plate);
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  if p_vehicle_type not in ('motorcycle', 'car', 'van') then raise exception 'invalid vehicle type'; end if;
  if v_plate !~ '^[A-Z]{1,4}[0-9]{1,4}[A-Z]{0,3}$' then raise exception 'invalid plate'; end if;
  if p_photo_path is null or split_part(p_photo_path, '/', 1) <> auth.uid()::text
     or not exists (select 1 from storage.objects o where o.bucket_id = 'cefflo-driver-documents' and o.name = p_photo_path) then
    raise exception 'vehicle photo not uploaded';
  end if;
  if exists (select 1 from driver_marketplace_verifications where user_id = auth.uid() and status in ('verified', 'rejected')) then
    raise exception 'verification already decided';
  end if;
  insert into driver_marketplace_verifications(user_id, status, vehicle_type, vehicle_plate, vehicle_photo_path, submitted_at)
    values (auth.uid(), 'pending', p_vehicle_type::public.rider_vehicle_type, v_plate, p_photo_path, now())
  on conflict (user_id) do update
    set status = 'pending', retake = null, plate_result = null,
        vehicle_type = excluded.vehicle_type, vehicle_plate = excluded.vehicle_plate,
        vehicle_photo_path = excluded.vehicle_photo_path, submitted_at = now(), updated_at = now();
  perform _marketplace_decide(auth.uid());
  return my_marketplace_verification();
end $$;

/* Marketplace (Find Jobs) access boundary. Today: verified. The future
   one-time RM49 activation is ANDed in here once payments exist. */
create or replace function public.has_marketplace_access(p_user uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from driver_marketplace_verifications where user_id = p_user and status = 'verified')
$$;

-- user-facing status only: no evidence, no hash, no paths
create or replace function public.my_marketplace_verification()
returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'status', coalesce(v.status, 'not_started'),
    'retake', v.retake,
    'ic_last4', l.ic_last4,
    'licence_submitted', l.user_id is not null,
    'vehicle_type', v.vehicle_type,
    'vehicle_plate', v.vehicle_plate,
    'vehicle_submitted', v.vehicle_photo_path is not null,
    'marketplace_access', has_marketplace_access(auth.uid()))
  from (select auth.uid() as uid) me
  left join driver_marketplace_verifications v on v.user_id = me.uid
  left join driver_licences l on l.user_id = me.uid
$$;

-- 5. server-side screening (Edge Function, service_role) ------------------
create or replace function public.record_marketplace_screening(p_user_id uuid, p_licence jsonb, p_plate jsonb)
returns jsonb
language plpgsql security definer set search_path = public as $$
begin
  update driver_marketplace_verifications
     set licence_result = coalesce(p_licence, licence_result),
         plate_result = coalesce(p_plate, plate_result),
         attempts = attempts + 1, screened_at = now(), updated_at = now()
   where user_id = p_user_id and status not in ('verified', 'rejected');
  perform _marketplace_decide(p_user_id);
  return (select jsonb_build_object('status', status, 'retake', retake, 'reasons', reasons)
            from driver_marketplace_verifications where user_id = p_user_id);
end $$;

-- 6. FOUNDR exception decision (platform admin) ---------------------------
create or replace function public.decide_marketplace_verification(p_user_id uuid, p_decision text, p_reason text default null)
returns jsonb
language plpgsql security definer set search_path = public as $$
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  if p_decision not in ('verified', 'rejected', 'retake_licence', 'retake_vehicle') then raise exception 'invalid decision'; end if;
  update driver_marketplace_verifications
     set status = case when p_decision like 'retake_%' then 'not_started' else p_decision end,
         retake = case p_decision when 'retake_licence' then 'licence' when 'retake_vehicle' then 'vehicle' end,
         licence_result = case when p_decision = 'retake_licence' then null else licence_result end,
         plate_result = case when p_decision = 'retake_vehicle' then null else plate_result end,
         reasons = case when nullif(btrim(p_reason), '') is null then reasons else array_append(reasons, 'foundr:' || btrim(p_reason)) end,
         reviewed_at = now(), reviewed_by = auth.uid(), updated_at = now()
   where user_id = p_user_id;
  if not found then raise exception 'verification not found'; end if;
  return (select jsonb_build_object('status', status, 'retake', retake) from driver_marketplace_verifications where user_id = p_user_id);
end $$;

revoke all on function public.submit_driver_licence(text, text) from public, anon;
revoke all on function public.submit_marketplace_vehicle(text, text, text) from public, anon;
revoke all on function public.my_marketplace_verification() from public, anon;
revoke all on function public.has_marketplace_access(uuid) from public, anon, authenticated;
revoke all on function public.record_marketplace_screening(uuid, jsonb, jsonb) from public, anon, authenticated;
revoke all on function public.decide_marketplace_verification(uuid, text, text) from public, anon;
grant execute on function public.submit_driver_licence(text, text) to authenticated;
grant execute on function public.submit_marketplace_vehicle(text, text, text) to authenticated;
grant execute on function public.my_marketplace_verification() to authenticated;
grant execute on function public.record_marketplace_screening(uuid, jsonb, jsonb) to service_role;
grant execute on function public.decide_marketplace_verification(uuid, text, text) to authenticated;

-- 7. vendor-assigned work: no licence / verification checks --------------
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

-- 8. Find Jobs: applying requires Marketplace Verification -------------
CREATE OR REPLACE FUNCTION public.request_job_opening(p_opening_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
  -- Independent Marketplace: Marketplace Verification required to apply
  -- (future: + paid activation, inside has_marketplace_access).
  if not has_marketplace_access(auth.uid()) then
    raise exception 'marketplace verification required';
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
  -- the vehicle checked in Marketplace Verification comes first
  select vehicle_type, vehicle_plate into v_vehicle, v_plate
    from driver_marketplace_verifications where user_id = auth.uid() and status = 'verified';
  v_plate := coalesce(v_plate, nullif(btrim(v_prev.vehicle_plate), ''), nullif(btrim(v_meta ->> 'vehicle_plate'), ''));
  v_vehicle := coalesce(v_vehicle, v_prev.vehicle_type,
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
end $function$;
