-- Sealed driver documents (Founder 2026-10-16, PDPA): IC and licence
-- images and the full IC number are readable by no one -- not vendors, not
-- Cefflo staff -- unless a vendor reports an incident about that driver and
-- a platform admin opens the case with a written reason. Access lasts 72
-- hours, every opening is audited and the driver is told.

create table if not exists public.driver_incident_cases (
  id uuid primary key default gen_random_uuid(),
  rider_user_id uuid not null references auth.users(id) on delete cascade,
  rider_id uuid references public.riders(id) on delete set null,
  business_id uuid references public.businesses(id) on delete cascade,
  reported_by uuid not null references auth.users(id),
  report text not null check (length(trim(report)) between 5 and 2000),
  status text not null default 'reported' check (status in ('reported','open','closed')),
  opened_by uuid references auth.users(id),
  open_reason text,
  opened_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);
create table if not exists public.driver_document_access_log (
  id bigint generated always as identity primary key,
  case_id uuid not null references public.driver_incident_cases(id) on delete cascade,
  actor uuid not null references auth.users(id),
  action text not null,
  at timestamptz not null default now()
);
alter table public.driver_incident_cases enable row level security;
alter table public.driver_document_access_log enable row level security;
create policy incident_cases_reporter on public.driver_incident_cases
  for select using (reported_by = auth.uid() or is_platform_admin());
create policy access_log_admin on public.driver_document_access_log
  for select using (is_platform_admin());

-- True only while an opened case for this driver is live.
create or replace function public.driver_documents_unsealed(p_user uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select is_platform_admin() and exists (
    select 1 from driver_incident_cases c
     where c.rider_user_id = p_user and c.status = 'open' and c.expires_at > now())
$$;

-- Admin reads now need an open case (was: any platform admin, any time).
drop policy if exists driver_documents_own_read on storage.objects;
create policy driver_documents_own_read on storage.objects for select using (
  bucket_id = 'cefflo-driver-documents' and (
    (storage.foldername(name))[1] = auth.uid()::text
    or driver_documents_unsealed(((storage.foldername(name))[1])::uuid)
    -- The vehicle photo is basic profile: the driver's businesses see it.
    or exists (
      select 1 from driver_marketplace_verifications v
        join riders r on r.auth_user_id = v.user_id
       where v.vehicle_photo_path = name and is_business_member(r.business_id))
  ));
drop policy if exists driver_licences_admin_read on public.driver_licences;
create policy driver_licences_admin_read on public.driver_licences
  for select using (driver_documents_unsealed(user_id));

-- A vendor reports an incident about one of its drivers.
create or replace function public.report_driver_incident(p_rider_id uuid, p_report text)
returns uuid language plpgsql security definer set search_path = public as $$
declare r riders; v_id uuid;
begin
  select * into r from riders where id = p_rider_id;
  if r.id is null or r.auth_user_id is null or not is_business_member(r.business_id) then
    raise exception 'forbidden';
  end if;
  insert into driver_incident_cases (rider_user_id, rider_id, business_id, reported_by, report)
  values (r.auth_user_id, r.id, r.business_id, auth.uid(), trim(p_report)) returning id into v_id;
  return v_id;
end $$;

-- A platform admin opens a reported case (72 h) with a written reason.
create or replace function public.open_driver_incident(p_case_id uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare c driver_incident_cases;
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  if coalesce(length(trim(p_reason)), 0) < 10 then raise exception 'reason required'; end if;
  update driver_incident_cases set status = 'open', opened_by = auth.uid(),
         open_reason = trim(p_reason), opened_at = now(), expires_at = now() + interval '72 hours'
   where id = p_case_id and status in ('reported','open') returning * into c;
  if c.id is null then raise exception 'case not found'; end if;
  insert into driver_document_access_log (case_id, actor, action) values (c.id, auth.uid(), 'opened');
  perform notify_user(c.rider_user_id, 'rider', c.business_id, 'account.documents_opened', 'account',
    'normal', 'Your documents were opened for an incident review',
    'Cefflo opened your verification documents to investigate a reported incident.',
    '{"screen":"none"}'::jsonb, jsonb_build_object('case_id', c.id), 'docs-opened:' || c.id);
end $$;

-- What a business sees about a driver: basic profile only, never the IC
-- or licence images or the full IC number.
create or replace function public.driver_basic_profile(p_rider_id uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select case when r.id is null or not is_business_member(r.business_id) then null else
    jsonb_build_object(
      'name', r.name, 'phone', r.phone,
      'vehicle_type', coalesce(v.vehicle_type::text, r.vehicle_type::text),
      'vehicle_plate', coalesce(v.vehicle_plate, r.vehicle_plate),
      'vehicle_photo_path', v.vehicle_photo_path,
      'address', u.raw_user_meta_data->'driver_registration'->>'address',
      'ic_last4', l.ic_last4,
      'licence_submitted', l.user_id is not null,
      'verification', v.status)
  end
  from riders r
  left join driver_licences l on l.user_id = r.auth_user_id
  left join driver_marketplace_verifications v on v.user_id = r.auth_user_id
  left join auth.users u on u.id = r.auth_user_id
  where r.id = p_rider_id
$$;

revoke all on function public.driver_documents_unsealed(uuid) from public, anon;
revoke all on function public.report_driver_incident(uuid, text) from public, anon;
revoke all on function public.open_driver_incident(uuid, text) from public, anon;
revoke all on function public.driver_basic_profile(uuid) from public, anon;
grant execute on function public.driver_documents_unsealed(uuid) to authenticated;
grant execute on function public.report_driver_incident(uuid, text) to authenticated;
grant execute on function public.open_driver_incident(uuid, text) to authenticated;
grant execute on function public.driver_basic_profile(uuid) to authenticated;
