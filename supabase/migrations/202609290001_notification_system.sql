-- CEFFLO Notification System (Master MD: CEFFLO_NOTIFICATION_SYSTEM_MASTER.md)
--
-- Why new schema (N0 gap map, proven before adding anything):
--   * platform_announcements (FOUNDR Phase 3) is a global, time-windowed
--     banner that anon can read through get_active_announcements(). It has no
--     recipient, no audience, no per-user read state, so it cannot carry a
--     targeted broadcast (a business-scoped message would leak publicly) or a
--     personal operational alert. It stays as-is for platform banners.
--   * No notification, read-state, preference or push-token storage existed.
--   * delivery_events is the canonical, immutable operational event log. It
--     IS reused: every operational notification below is derived from a
--     committed delivery_events row, never from client input.
--
-- Doctrine kept from docs/cefflo/18_GROW_NOTIFICATION_ARCHITECTURE.md:
--   * notification work never drives or rolls back lifecycle state -- the
--     trigger swallows its own failures (warning only);
--   * a stable idempotency key per (recipient, purpose) prevents duplicates;
--   * no provider is selected or called here: this is in-app persistence and
--     realtime only. Customer channels (WhatsApp/SMS/push) stay deferred.

-- ===== Broadcasts (FOUNDR) =====
create table public.notification_broadcasts (
  id uuid primary key default gen_random_uuid(),
  title text not null check (length(trim(title)) between 1 and 120),
  body text not null check (length(trim(body)) between 1 and 1000),
  audience text not null check (audience in ('all', 'vendors', 'riders', 'business')),
  business_id uuid references public.businesses on delete set null,
  reason text not null check (length(trim(reason)) > 0),
  recipient_count integer not null default 0,
  created_by uuid references auth.users on delete set null,
  created_at timestamptz not null default now(),
  check ((audience = 'business') = (business_id is not null))
);
alter table public.notification_broadcasts enable row level security;
create policy notification_broadcasts_admin_read on public.notification_broadcasts
  for select using (public.is_platform_admin());
grant select on public.notification_broadcasts to authenticated;

-- ===== Per-user notifications (the notification centre) =====
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_user_id uuid not null references auth.users on delete cascade,
  app text not null check (app in ('vendor', 'rider')),
  business_id uuid references public.businesses on delete cascade,
  event_key text not null,
  category text not null check (category in ('operational', 'announcement', 'account')),
  priority text not null default 'normal' check (priority in ('normal', 'urgent')),
  title text not null,
  body text not null default '',
  -- Deep-link contract: {"screen": "order"|"runs"|"riders"|"rider"|"none", "id": "<uuid>"}
  target jsonb not null default '{"screen":"none"}',
  -- Template variables for client-side localisation of known event keys.
  params jsonb not null default '{}',
  source_event_id bigint references public.delivery_events on delete set null,
  broadcast_id uuid references public.notification_broadcasts on delete set null,
  dedupe_key text not null,
  created_at timestamptz not null default now(),
  read_at timestamptz,
  unique (recipient_user_id, dedupe_key)
);
create index notifications_recipient_created on public.notifications (recipient_user_id, created_at desc);
create index notifications_recipient_unread on public.notifications (recipient_user_id) where read_at is null;
create index notifications_broadcast on public.notifications (broadcast_id) where broadcast_id is not null;

alter table public.notifications enable row level security;
-- A user only ever sees and removes their own notifications. There is no
-- insert/update policy: rows are written only by the SECURITY DEFINER
-- functions below, and read state changes only through mark_notifications_read.
create policy notifications_own_read on public.notifications
  for select using (recipient_user_id = auth.uid());
create policy notifications_own_delete on public.notifications
  for delete using (recipient_user_id = auth.uid());
grant select, delete on public.notifications to authenticated;

-- Realtime: postgres_changes honours the select policy above, so each client
-- receives only its own rows.
alter publication supabase_realtime add table public.notifications;

-- ===== Preferences (minimum per Master MD §3.5) =====
create table public.notification_preferences (
  user_id uuid primary key references auth.users on delete cascade,
  enabled boolean not null default true,
  sound boolean not null default true,
  updated_at timestamptz not null default now()
);
alter table public.notification_preferences enable row level security;
create policy notification_preferences_own on public.notification_preferences
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
grant select, insert, update on public.notification_preferences to authenticated;

-- ===== Internal writer =====
create function public.notify_user(
  p_recipient uuid, p_app text, p_business uuid, p_event_key text, p_category text,
  p_priority text, p_title text, p_body text, p_target jsonb, p_params jsonb,
  p_dedupe_key text, p_source_event bigint default null, p_broadcast uuid default null
) returns boolean
language sql
security definer
set search_path = public
as $$
  with ins as (
    insert into public.notifications (recipient_user_id, app, business_id, event_key, category, priority,
      title, body, target, params, dedupe_key, source_event_id, broadcast_id)
    values (p_recipient, p_app, p_business, p_event_key, p_category, p_priority,
      p_title, coalesce(p_body, ''), coalesce(p_target, '{"screen":"none"}'), coalesce(p_params, '{}'),
      p_dedupe_key, p_source_event, p_broadcast)
    on conflict (recipient_user_id, dedupe_key) do nothing
    returning 1
  )
  select exists (select 1 from ins)
$$;
revoke all on function public.notify_user(uuid, text, uuid, text, text, text, text, text, jsonb, jsonb, text, bigint, uuid) from public, anon, authenticated;

-- Vendor operational recipients: active Owners/Operators of the business,
-- excluding whoever caused the event (nobody is alerted about their own act).
create function public.notify_business_team(
  e public.delivery_events, p_event_key text, p_priority text, p_title text, p_body text,
  p_target jsonb, p_params jsonb
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare m record;
begin
  for m in
    select user_id from public.business_members
    where business_id = e.business_id and status = 'active' and role in ('owner', 'operator')
      and user_id is distinct from e.actor_user_id
  loop
    perform public.notify_user(m.user_id, 'vendor', e.business_id, p_event_key, 'operational', p_priority,
      p_title, p_body, p_target, p_params, 'de:' || e.id, e.id, null);
  end loop;
end;
$$;
revoke all on function public.notify_business_team(public.delivery_events, text, text, text, text, jsonb, jsonb) from public, anon, authenticated;

create function public.notify_rider(
  e public.delivery_events, p_rider_id uuid, p_event_key text, p_priority text, p_category text,
  p_title text, p_body text, p_target jsonb, p_params jsonb, p_dedupe text
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare uid uuid;
begin
  select auth_user_id into uid from public.riders where id = p_rider_id;
  if uid is null or uid is not distinct from e.actor_user_id then return; end if;
  perform public.notify_user(uid, 'rider', e.business_id, p_event_key, p_category, p_priority,
    p_title, p_body, p_target, p_params, p_dedupe, e.id, null);
end;
$$;
revoke all on function public.notify_rider(public.delivery_events, uuid, text, text, text, text, text, jsonb, jsonb, text) from public, anon, authenticated;

-- ===== Event matrix (see docs/cefflo/NOTIFICATION_EVENT_MATRIX.md) =====
-- Only events that the backend already records are mapped. Anything else
-- produces no notification.
create function public.notifications_from_delivery_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  e public.delivery_events := new;
  ref text;
  biz text;
  n int;
  r uuid;
begin
  select public_ref into ref from public.orders where id = e.order_id;
  select name into biz from public.businesses where id = e.business_id;

  if e.event_type = 'delivery.created' and e.actor_role = 'customer' then
    perform public.notify_business_team(e, 'order.new_customer', 'normal',
      'New customer order ' || coalesce(ref, ''), 'A customer placed an order from your order page.',
      jsonb_build_object('screen', 'order', 'id', e.order_id), jsonb_build_object('ref', ref));

  elsif e.event_type = 'delivery.issue_reported' and e.actor_role = 'rider' then
    perform public.notify_business_team(e, 'delivery.issue', 'urgent',
      'Delivery issue on ' || coalesce(ref, 'an order'), coalesce(nullif(e.metadata->>'note', ''), 'A rider reported a problem with this delivery.'),
      jsonb_build_object('screen', 'order', 'id', e.order_id), jsonb_build_object('ref', ref, 'reason', e.metadata->>'reason_type'));

  elsif e.event_type = 'assignment.declined' and e.actor_role = 'rider' then
    perform public.notify_business_team(e, 'run.declined', 'urgent',
      'A rider declined a run', 'Reassign the orders so they can go out.',
      jsonb_build_object('screen', 'runs'), jsonb_build_object('ref', ref));

  elsif e.event_type = 'rider.invite_accepted' then
    perform public.notify_business_team(e, 'rider.joined', 'normal',
      'A rider accepted your invitation', 'Review and approve them before assigning runs.',
      jsonb_build_object('screen', 'rider', 'id', e.metadata->>'rider_id'), '{}');

  elsif e.event_type = 'session.status_changed' and e.metadata->>'status' = 'completed' then
    perform public.notify_business_team(e, 'run.completed', 'normal',
      'Run completed', 'Every stop in the run is finished.',
      jsonb_build_object('screen', 'runs'), jsonb_build_object('session', e.metadata->>'delivery_session_id'));

  elsif e.event_type = 'run.built' and e.metadata ? 'rider_id' then
    n := coalesce(jsonb_array_length(e.metadata->'order_ids'), 0);
    perform public.notify_rider(e, (e.metadata->>'rider_id')::uuid, 'run.assigned', 'urgent', 'operational',
      'New run from ' || coalesce(biz, 'your business'),
      n || case when n = 1 then ' order' else ' orders' end || ' assigned to you. Open it to accept.',
      jsonb_build_object('screen', 'runs'), jsonb_build_object('business', biz, 'orders', n),
      'run:' || coalesce(e.metadata->>'delivery_session_id', e.id::text) || ':' || (e.metadata->>'rider_id'));

  elsif e.event_type = 'run.rider_replaced' then
    r := (e.metadata->>'new_rider_id')::uuid;
    if r is not null then
      perform public.notify_rider(e, r, 'run.assigned', 'urgent', 'operational',
        'Run reassigned to you', coalesce(biz, 'Your business') || ' moved a run to you. Open it to accept.',
        jsonb_build_object('screen', 'runs'), jsonb_build_object('business', biz),
        'run:' || coalesce(e.metadata->>'delivery_session_id', e.id::text) || ':' || r);
    end if;
    for r in select jsonb_array_elements_text(coalesce(e.metadata->'previous_rider_ids', '[]'))::uuid loop
      perform public.notify_rider(e, r, 'run.removed', 'urgent', 'operational',
        'Run moved to another rider', coalesce(biz, 'Your business') || ' reassigned a run you were on.',
        jsonb_build_object('screen', 'runs'), jsonb_build_object('business', biz), 'de:' || e.id || ':' || r);
    end loop;

  elsif e.event_type = 'rider.approved' and e.metadata ? 'rider_id' then
    perform public.notify_rider(e, (e.metadata->>'rider_id')::uuid, 'rider.approved', 'normal', 'account',
      'You are approved', coalesce(biz, 'The business') || ' approved you as a rider.',
      jsonb_build_object('screen', 'none'), jsonb_build_object('business', biz), 'de:' || e.id);

  elsif e.event_type = 'rider.deactivated' and e.metadata ? 'rider_id' then
    perform public.notify_rider(e, (e.metadata->>'rider_id')::uuid, 'rider.deactivated', 'normal', 'account',
      'Access changed', coalesce(biz, 'A business') || ' deactivated you as a rider.',
      jsonb_build_object('screen', 'none'), jsonb_build_object('business', biz), 'de:' || e.id);
  end if;
  return null;
exception when others then
  -- Notification failure must never affect the operational transaction.
  raise warning 'notification fan-out skipped for delivery_event %: %', new.id, sqlerrm;
  return null;
end;
$$;
revoke all on function public.notifications_from_delivery_event() from public, anon, authenticated;

create trigger delivery_events_notify
  after insert on public.delivery_events
  for each row execute function public.notifications_from_delivery_event();

-- ===== Client RPCs =====
-- Marks the caller's own notifications read. p_ids null = all of them.
-- Returns how many changed. Idempotent.
create function public.mark_notifications_read(p_ids uuid[] default null, p_app text default null)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare n int;
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  update public.notifications set read_at = now()
  where recipient_user_id = auth.uid() and read_at is null
    and (p_ids is null or id = any(p_ids))
    and (p_app is null or app = p_app);
  get diagnostics n = row_count;
  return n;
end;
$$;
revoke all on function public.mark_notifications_read(uuid[], text) from public, anon;
grant execute on function public.mark_notifications_read(uuid[], text) to authenticated;

-- Marks one of the caller's notifications unread again (Vendor Mobile X-01).
create function public.mark_notification_unread(p_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  update public.notifications set read_at = null where id = p_id and recipient_user_id = auth.uid();
  return found;
end;
$$;
revoke all on function public.mark_notification_unread(uuid) from public, anon;
grant execute on function public.mark_notification_unread(uuid) to authenticated;

-- ===== FOUNDR broadcast =====
-- Audiences are only those the data model can honour:
--   vendors  = active Owners/Operators of every business (Vendor app)
--   riders   = active riders with a signed-in account (Rider app)
--   all      = both
--   business = active Owners/Operators of one business
-- A reason is required and stored in admin_audit_log.
create function public.admin_broadcast_notification(
  p_title text, p_body text, p_audience text, p_business_id uuid default null, p_reason text default null
) returns public.notification_broadcasts
language plpgsql
security definer
set search_path = public
as $$
declare
  b public.notification_broadcasts;
  u record;
  n int := 0;
begin
  if not public.is_platform_admin() then raise exception 'forbidden'; end if;
  if p_title is null or length(trim(p_title)) = 0 then raise exception 'title is required'; end if;
  if p_body is null or length(trim(p_body)) = 0 then raise exception 'message is required'; end if;
  if p_reason is null or length(trim(p_reason)) = 0 then raise exception 'reason is required'; end if;
  if p_audience not in ('all', 'vendors', 'riders', 'business') then raise exception 'invalid audience'; end if;
  if p_audience = 'business' and not exists (select 1 from public.businesses where id = p_business_id) then
    raise exception 'business not found';
  end if;

  insert into public.notification_broadcasts (title, body, audience, business_id, reason, created_by)
  values (trim(p_title), trim(p_body), p_audience, case when p_audience = 'business' then p_business_id end, trim(p_reason), auth.uid())
  returning * into b;

  if p_audience in ('all', 'vendors', 'business') then
    for u in
      select distinct user_id from public.business_members
      where status = 'active' and role in ('owner', 'operator')
        and (p_audience <> 'business' or business_id = p_business_id)
    loop
      if public.notify_user(u.user_id, 'vendor', case when p_audience = 'business' then p_business_id end,
          'platform.announcement', 'announcement', 'normal', b.title, b.body, '{"screen":"none"}', '{}',
          'broadcast:' || b.id, null, b.id) then n := n + 1; end if;
    end loop;
  end if;
  if p_audience in ('all', 'riders') then
    for u in
      select distinct auth_user_id as user_id from public.riders where status = 'active' and auth_user_id is not null
    loop
      if public.notify_user(u.user_id, 'rider', null, 'platform.announcement', 'announcement', 'normal',
          b.title, b.body, '{"screen":"none"}', '{}', 'broadcast:' || b.id, null, b.id) then n := n + 1; end if;
    end loop;
  end if;

  update public.notification_broadcasts set recipient_count = n where id = b.id returning * into b;
  perform public.log_admin_action('broadcast_notification', 'notification_broadcast', b.id::text, b.reason,
    jsonb_build_object('audience', p_audience, 'business_id', b.business_id, 'recipients', n));
  return b;
end;
$$;
revoke all on function public.admin_broadcast_notification(text, text, text, uuid, text) from public, anon;
grant execute on function public.admin_broadcast_notification(text, text, text, uuid, text) to authenticated;

-- Broadcast history with in-app read progress (the only delivery status that
-- genuinely exists: there is no push provider yet).
create function public.admin_list_broadcasts(p_limit integer default 100)
returns table (
  id uuid, title text, body text, audience text, business_id uuid, business_name text,
  reason text, recipient_count integer, read_count bigint, created_by uuid, created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_platform_admin() then raise exception 'forbidden'; end if;
  return query
    select b.id, b.title, b.body, b.audience, b.business_id, bz.name, b.reason, b.recipient_count,
      (select count(*) from public.notifications n where n.broadcast_id = b.id and n.read_at is not null),
      b.created_by, b.created_at
    from public.notification_broadcasts b
    left join public.businesses bz on bz.id = b.business_id
    order by b.created_at desc
    limit least(coalesce(p_limit, 100), 500);
end;
$$;
revoke all on function public.admin_list_broadcasts(integer) from public, anon;
grant execute on function public.admin_list_broadcasts(integer) to authenticated;

-- Audience size preview for the FOUNDR confirmation step (same predicates as
-- the send, so the number shown is the number that will be targeted).
create function public.admin_broadcast_audience_size(p_audience text, p_business_id uuid default null)
returns integer
language plpgsql
stable
security definer
set search_path = public
as $$
declare v int := 0; r int := 0;
begin
  if not public.is_platform_admin() then raise exception 'forbidden'; end if;
  if p_audience in ('all', 'vendors', 'business') then
    select count(distinct user_id) into v from public.business_members
    where status = 'active' and role in ('owner', 'operator') and (p_audience <> 'business' or business_id = p_business_id);
  end if;
  if p_audience in ('all', 'riders') then
    select count(distinct auth_user_id) into r from public.riders where status = 'active' and auth_user_id is not null;
  end if;
  return v + r;
end;
$$;
revoke all on function public.admin_broadcast_audience_size(text, uuid) from public, anon;
grant execute on function public.admin_broadcast_audience_size(text, uuid) to authenticated;
