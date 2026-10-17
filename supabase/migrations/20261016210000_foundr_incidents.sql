-- FOUNDR Incidents (Founder 2026-10-16): the platform admin lists reported
-- driver incidents, opens one with a written reason (72 h access to the
-- sealed documents) and closes it. Opening, viewing and closing are written
-- to driver_document_access_log and admin_audit_log.

create or replace function public.admin_list_incidents()
returns table (
  id uuid, status text, report text, created_at timestamptz,
  rider_user_id uuid, driver_name text, driver_phone text,
  business_id uuid, business_name text, reported_by_name text,
  open_reason text, opened_at timestamptz, expires_at timestamptz, live boolean)
language plpgsql stable security definer set search_path = public as $$
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  return query
  select c.id, c.status, c.report, c.created_at,
         c.rider_user_id, r.name, r.phone,
         c.business_id, b.name,
         coalesce(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'name', split_part(u.email, '@', 1))::text,
         c.open_reason, c.opened_at, c.expires_at,
         (c.status = 'open' and c.expires_at > now())
    from driver_incident_cases c
    left join riders r on r.id = c.rider_id
    left join businesses b on b.id = c.business_id
    left join auth.users u on u.id = c.reported_by
   order by (c.status = 'reported') desc, c.created_at desc
   limit 500;
end $$;

-- Opening now also writes the admin audit log (the 20261016170000 version
-- only wrote driver_document_access_log).
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
  insert into admin_audit_log (admin_user_id, action, target_type, target_id, reason, metadata)
    values (auth.uid(), 'incident_opened', 'driver_incident_case', c.id::text, trim(p_reason),
            jsonb_build_object('rider_user_id', c.rider_user_id, 'expires_at', c.expires_at));
  perform notify_user(c.rider_user_id, 'rider', c.business_id, 'account.documents_opened', 'account',
    'normal', 'Your documents were opened for an incident review',
    'Cefflo opened your verification documents to investigate a reported incident.',
    '{"screen":"none"}'::jsonb, jsonb_build_object('case_id', c.id), 'docs-opened:' || c.id || ':' || extract(epoch from c.opened_at)::bigint);
end $$;

-- Each time FOUNDR shows the documents of an open case.
create or replace function public.admin_log_incident_view(p_case_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  if not exists (select 1 from driver_incident_cases where id = p_case_id and status = 'open' and expires_at > now()) then
    raise exception 'case not open';
  end if;
  insert into driver_document_access_log (case_id, actor, action) values (p_case_id, auth.uid(), 'viewed');
end $$;

-- Closing seals the documents again at once.
create or replace function public.admin_close_incident(p_case_id uuid, p_note text)
returns void language plpgsql security definer set search_path = public as $$
declare c driver_incident_cases;
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  if coalesce(length(trim(p_note)), 0) < 5 then raise exception 'note required'; end if;
  update driver_incident_cases set status = 'closed', expires_at = least(coalesce(expires_at, now()), now())
   where id = p_case_id and status <> 'closed' returning * into c;
  if c.id is null then raise exception 'case not found'; end if;
  insert into driver_document_access_log (case_id, actor, action) values (c.id, auth.uid(), 'closed');
  insert into admin_audit_log (admin_user_id, action, target_type, target_id, reason, metadata)
    values (auth.uid(), 'incident_closed', 'driver_incident_case', c.id::text, trim(p_note), '{}'::jsonb);
end $$;

revoke all on function public.admin_list_incidents() from public, anon;
revoke all on function public.admin_log_incident_view(uuid) from public, anon;
revoke all on function public.admin_close_incident(uuid, text) from public, anon;
grant execute on function public.admin_list_incidents() to authenticated;
grant execute on function public.admin_log_incident_view(uuid) to authenticated;
grant execute on function public.admin_close_incident(uuid, text) to authenticated;
