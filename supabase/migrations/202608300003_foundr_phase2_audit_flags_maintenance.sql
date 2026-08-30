-- FOUNDR Phase 2: contained new schema for privileged platform controls.
-- Every write RPC in this file logs itself via log_admin_action() before
-- returning -- FOUNDR's own spec (docs/cefflo/09_FOUNDR.md, F-07) requires
-- privileged actions to be recorded and auditable; this is that mechanism,
-- not bolted on after the fact.

create table public.admin_audit_log (
  id bigint generated always as identity primary key,
  admin_user_id uuid references auth.users on delete set null,
  action text not null,
  target_type text,
  target_id text,
  reason text,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);

alter table public.admin_audit_log enable row level security;

create policy admin_audit_log_read on public.admin_audit_log
  for select using (public.is_platform_admin());

grant select on public.admin_audit_log to authenticated;

-- Internal helper, not exposed directly to clients (no grant to
-- authenticated) -- every privileged write RPC below calls this itself
-- after its own is_platform_admin() check has already passed, so this
-- function does not re-check authorization; it only records the fact.
create function public.log_admin_action(
  p_action text,
  p_target_type text default null,
  p_target_id text default null,
  p_reason text default null,
  p_metadata jsonb default '{}'
) returns void
language sql
security definer
set search_path = public
as $$
  insert into public.admin_audit_log (admin_user_id, action, target_type, target_id, reason, metadata)
  values (auth.uid(), p_action, p_target_type, p_target_id, p_reason, coalesce(p_metadata, '{}'));
$$;

create function public.admin_list_audit_log(p_limit integer default 100)
returns setof public.admin_audit_log
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
    select * from public.admin_audit_log
    order by created_at desc
    limit least(coalesce(p_limit, 100), 500);
end;
$$;

-- ===== Feature Flags =====
-- Simple boolean-per-key registry. Client apps may read a single flag's
-- state (get_feature_flag) without being a platform admin -- the flag VALUE
-- is not sensitive, only who may change it is.
create table public.feature_flags (
  key text primary key,
  enabled boolean not null default false,
  description text,
  updated_by uuid references auth.users on delete set null,
  updated_at timestamptz not null default now()
);

alter table public.feature_flags enable row level security;

create policy feature_flags_read_admin on public.feature_flags
  for select using (public.is_platform_admin());

grant select on public.feature_flags to authenticated;

create function public.get_feature_flag(p_key text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select enabled from public.feature_flags where key = p_key), false)
$$;

create function public.admin_set_feature_flag(p_key text, p_enabled boolean, p_description text default null)
returns public.feature_flags
language plpgsql
security definer
set search_path = public
as $$
declare
  f public.feature_flags;
begin
  if not public.is_platform_admin() then
    raise exception 'forbidden';
  end if;
  if p_key is null or length(trim(p_key)) = 0 then
    raise exception 'flag key is required';
  end if;

  insert into public.feature_flags (key, enabled, description, updated_by, updated_at)
  values (p_key, p_enabled, p_description, auth.uid(), now())
  on conflict (key) do update set
    enabled = excluded.enabled,
    description = coalesce(excluded.description, public.feature_flags.description),
    updated_by = excluded.updated_by,
    updated_at = excluded.updated_at
  returning * into f;

  perform public.log_admin_action('set_feature_flag', 'feature_flag', p_key, null, jsonb_build_object('enabled', p_enabled));
  return f;
end;
$$;

grant execute on function public.get_feature_flag(text) to authenticated, anon;
grant execute on function public.admin_set_feature_flag(text, boolean, text) to authenticated;
grant execute on function public.admin_list_audit_log(integer) to authenticated;

-- ===== Maintenance windows =====
-- FOUNDR's own spec (F-05) is explicit that maintenance mode is emergency/
-- exception only, never routine, and the UI itself requires scope + reason +
-- expected duration + rollback condition before allowing the action -- a
-- plain boolean flag would lose all of that, so this is a dedicated table
-- (a history of windows, not a single mutable switch) rather than a
-- feature_flags row.
create table public.maintenance_windows (
  id uuid primary key default gen_random_uuid(),
  scope text not null,
  reason text not null,
  expected_duration_minutes integer,
  rollback_condition text not null,
  started_by uuid references auth.users on delete set null,
  started_at timestamptz not null default now(),
  ended_by uuid references auth.users on delete set null,
  ended_at timestamptz
);

alter table public.maintenance_windows enable row level security;

create policy maintenance_windows_read on public.maintenance_windows
  for select using (public.is_platform_admin());

grant select on public.maintenance_windows to authenticated;

-- Public read of "is maintenance active right now, and for what scope" --
-- client apps need this without being a platform admin; it deliberately
-- exposes only scope + reason, never who started it or the full row.
create function public.get_active_maintenance()
returns table (scope text, reason text, started_at timestamptz)
language sql
stable
security definer
set search_path = public
as $$
  select scope, reason, started_at
  from public.maintenance_windows
  where ended_at is null
  order by started_at desc
$$;

create function public.admin_start_maintenance(
  p_scope text,
  p_reason text,
  p_expected_duration_minutes integer default null,
  p_rollback_condition text default null
) returns public.maintenance_windows
language plpgsql
security definer
set search_path = public
as $$
declare
  w public.maintenance_windows;
begin
  if not public.is_platform_admin() then
    raise exception 'forbidden';
  end if;
  if p_scope is null or length(trim(p_scope)) = 0 then
    raise exception 'scope is required';
  end if;
  if p_reason is null or length(trim(p_reason)) = 0 then
    raise exception 'reason is required';
  end if;
  if p_rollback_condition is null or length(trim(p_rollback_condition)) = 0 then
    raise exception 'rollback condition is required';
  end if;

  insert into public.maintenance_windows (scope, reason, expected_duration_minutes, rollback_condition, started_by)
  values (p_scope, p_reason, p_expected_duration_minutes, p_rollback_condition, auth.uid())
  returning * into w;

  perform public.log_admin_action('start_maintenance', 'maintenance_window', w.id::text, p_reason,
    jsonb_build_object('scope', p_scope, 'expected_duration_minutes', p_expected_duration_minutes));
  return w;
end;
$$;

create function public.admin_end_maintenance(p_id uuid)
returns public.maintenance_windows
language plpgsql
security definer
set search_path = public
as $$
declare
  w public.maintenance_windows;
begin
  if not public.is_platform_admin() then
    raise exception 'forbidden';
  end if;

  update public.maintenance_windows
  set ended_at = now(), ended_by = auth.uid()
  where id = p_id and ended_at is null
  returning * into w;

  if w.id is null then
    raise exception 'maintenance window not found or already ended';
  end if;

  perform public.log_admin_action('end_maintenance', 'maintenance_window', w.id::text, null, '{}');
  return w;
end;
$$;

grant execute on function public.get_active_maintenance() to authenticated, anon;
grant execute on function public.admin_start_maintenance(text, text, integer, text) to authenticated;
grant execute on function public.admin_end_maintenance(uuid) to authenticated;
