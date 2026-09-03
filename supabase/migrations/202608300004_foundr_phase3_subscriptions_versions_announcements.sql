-- FOUNDR Phase 3: honest data model for modules this codebase cannot fully
-- back yet. None of these compute anything from a real transaction, a real
-- payment gateway, or a real client-reported version -- because none of
-- those exist anywhere else in this codebase. What IS real: the schema and
-- the admin-facing control surface, so a platform admin can record the true
-- state by hand (audited) instead of FOUNDR showing fabricated numbers.

-- ===== Business subscriptions (manually admin-set; no payment gateway) =====
create table public.business_subscriptions (
  business_id uuid primary key references public.businesses on delete cascade,
  plan_key text not null default 'trial',
  status text not null default 'trial' check (status in ('trial', 'active', 'past_due', 'suspended', 'cancelled')),
  mrr_cents integer,
  trial_ends_at timestamptz,
  updated_by uuid references auth.users on delete set null,
  updated_at timestamptz not null default now()
);

alter table public.business_subscriptions enable row level security;

create policy business_subscriptions_read on public.business_subscriptions
  for select using (public.is_platform_admin());

grant select on public.business_subscriptions to authenticated;

create function public.admin_list_subscriptions()
returns table (
  business_id uuid,
  business_name text,
  plan_key text,
  status text,
  mrr_cents integer,
  trial_ends_at timestamptz,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_platform_admin() then
    raise exception 'forbidden';
  end if;
  return query
    select b.id, b.name, s.plan_key, s.status, s.mrr_cents, s.trial_ends_at, s.updated_at
    from public.businesses b
    left join public.business_subscriptions s on s.business_id = b.id
    order by b.name;
end;
$$;

create function public.admin_set_subscription(
  p_business_id uuid,
  p_plan_key text,
  p_status text,
  p_mrr_cents integer default null,
  p_trial_ends_at timestamptz default null
) returns public.business_subscriptions
language plpgsql
security definer
set search_path = public
as $$
declare
  s public.business_subscriptions;
begin
  if not public.is_platform_admin() then
    raise exception 'forbidden';
  end if;
  if p_status not in ('trial', 'active', 'past_due', 'suspended', 'cancelled') then
    raise exception 'invalid status';
  end if;

  insert into public.business_subscriptions (business_id, plan_key, status, mrr_cents, trial_ends_at, updated_by, updated_at)
  values (p_business_id, p_plan_key, p_status, p_mrr_cents, p_trial_ends_at, auth.uid(), now())
  on conflict (business_id) do update set
    plan_key = excluded.plan_key, status = excluded.status, mrr_cents = excluded.mrr_cents,
    trial_ends_at = excluded.trial_ends_at, updated_by = excluded.updated_by, updated_at = excluded.updated_at
  returning * into s;

  perform public.log_admin_action('set_subscription', 'business', p_business_id::text, null,
    jsonb_build_object('plan_key', p_plan_key, 'status', p_status, 'mrr_cents', p_mrr_cents));
  return s;
end;
$$;

-- ===== Client app version registry (nothing reports real versions yet) =====
-- No Vendor/Rider/Customer client currently sends its own build version to
-- the backend, so this table starts empty and stays empty until that
-- client-side instrumentation is built separately -- this migration only
-- gives FOUNDR a real (if currently unpopulated) place to read from instead
-- of a hardcoded mock list.
create table public.app_versions (
  id bigint generated always as identity primary key,
  app text not null check (app in ('vendor', 'rider', 'customer', 'foundr', 'invite')),
  version text not null,
  min_supported_version text,
  released_at timestamptz not null default now(),
  released_by uuid references auth.users on delete set null,
  notes text
);

alter table public.app_versions enable row level security;

create policy app_versions_read on public.app_versions
  for select using (public.is_platform_admin());

grant select on public.app_versions to authenticated;

create function public.admin_list_app_versions()
returns setof public.app_versions
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_platform_admin() then
    raise exception 'forbidden';
  end if;
  return query select * from public.app_versions order by released_at desc;
end;
$$;

create function public.admin_record_app_version(
  p_app text,
  p_version text,
  p_min_supported_version text default null,
  p_notes text default null
) returns public.app_versions
language plpgsql
security definer
set search_path = public
as $$
declare
  v public.app_versions;
begin
  if not public.is_platform_admin() then
    raise exception 'forbidden';
  end if;
  if p_app not in ('vendor', 'rider', 'customer', 'foundr', 'invite') then
    raise exception 'invalid app';
  end if;

  insert into public.app_versions (app, version, min_supported_version, released_by, notes)
  values (p_app, p_version, p_min_supported_version, auth.uid(), p_notes)
  returning * into v;

  perform public.log_admin_action('record_app_version', 'app_versions', v.id::text, null,
    jsonb_build_object('app', p_app, 'version', p_version));
  return v;
end;
$$;

-- ===== Platform announcements =====
create table public.platform_announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  severity text not null default 'info' check (severity in ('info', 'warning', 'critical')),
  active boolean not null default true,
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  created_by uuid references auth.users on delete set null,
  created_at timestamptz not null default now()
);

alter table public.platform_announcements enable row level security;

create policy platform_announcements_read_admin on public.platform_announcements
  for select using (public.is_platform_admin());

grant select on public.platform_announcements to authenticated;

-- Public read of currently-live announcements only (not the full admin
-- table -- no created_by, no inactive/expired history) so any client app
-- could poll this without being a platform admin.
create function public.get_active_announcements()
returns table (id uuid, title text, body text, severity text, starts_at timestamptz, ends_at timestamptz)
language sql
stable
security definer
set search_path = public
as $$
  select id, title, body, severity, starts_at, ends_at
  from public.platform_announcements
  where active
    and starts_at <= now()
    and (ends_at is null or ends_at > now())
  order by starts_at desc
$$;

create function public.admin_create_announcement(
  p_title text, p_body text, p_severity text default 'info',
  p_starts_at timestamptz default now(), p_ends_at timestamptz default null
) returns public.platform_announcements
language plpgsql
security definer
set search_path = public
as $$
declare
  a public.platform_announcements;
begin
  if not public.is_platform_admin() then
    raise exception 'forbidden';
  end if;
  if p_severity not in ('info', 'warning', 'critical') then
    raise exception 'invalid severity';
  end if;
  if p_title is null or length(trim(p_title)) = 0 then
    raise exception 'title is required';
  end if;

  insert into public.platform_announcements (title, body, severity, starts_at, ends_at, created_by)
  values (p_title, p_body, p_severity, coalesce(p_starts_at, now()), p_ends_at, auth.uid())
  returning * into a;

  perform public.log_admin_action('create_announcement', 'platform_announcement', a.id::text, null,
    jsonb_build_object('severity', p_severity));
  return a;
end;
$$;

create function public.admin_set_announcement_active(p_id uuid, p_active boolean)
returns public.platform_announcements
language plpgsql
security definer
set search_path = public
as $$
declare
  a public.platform_announcements;
begin
  if not public.is_platform_admin() then
    raise exception 'forbidden';
  end if;

  update public.platform_announcements set active = p_active where id = p_id
  returning * into a;

  if a.id is null then
    raise exception 'announcement not found';
  end if;

  perform public.log_admin_action('set_announcement_active', 'platform_announcement', p_id::text, null,
    jsonb_build_object('active', p_active));
  return a;
end;
$$;

grant execute on function public.admin_list_subscriptions() to authenticated;
grant execute on function public.admin_set_subscription(uuid, text, text, integer, timestamptz) to authenticated;
grant execute on function public.admin_list_app_versions() to authenticated;
grant execute on function public.admin_record_app_version(text, text, text, text) to authenticated;
grant execute on function public.get_active_announcements() to authenticated, anon;
grant execute on function public.admin_create_announcement(text, text, text, timestamptz, timestamptz) to authenticated;
grant execute on function public.admin_set_announcement_active(uuid, boolean) to authenticated;
