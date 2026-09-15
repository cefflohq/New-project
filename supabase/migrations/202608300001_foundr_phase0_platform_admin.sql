-- FOUNDR Phase 0: platform-admin authorization foundation.
-- Nothing FOUNDR-facing is safe to build before this exists -- there is
-- currently no concept anywhere in this schema of "who may act across every
-- business," only per-business membership (is_business_member/is_business_owner).
-- This migration adds exactly that, as an explicit, auditable allowlist --
-- never a role fabricated from an existing column, never self-provisioned by
-- any client flow (unlike bootstrap_business, there is deliberately no
-- "become a platform admin" RPC). A row must be inserted here manually by
-- whoever has direct database access, after the Founder decides who that is.

create table public.platform_admins (
  user_id uuid primary key references auth.users on delete cascade,
  role text not null default 'founder' check (role in ('founder', 'ops')),
  granted_by uuid references auth.users on delete set null,
  created_at timestamptz not null default now()
);

alter table public.platform_admins enable row level security;

-- Defined before the policy below references it -- CREATE POLICY resolves
-- its USING expression immediately and requires the function to already
-- exist (unlike a deferred FK constraint).
create function public.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.platform_admins where user_id = auth.uid()
  )
$$;

-- A platform admin may see the allowlist (so FOUNDR can show "who has
-- access"); nobody may write to it through RLS/RPC -- membership changes are
-- a direct-database action only, matching the no-self-provision rule above.
create policy platform_admins_read on public.platform_admins
  for select using (public.is_platform_admin());

grant select on public.platform_admins to authenticated;
grant execute on function public.is_platform_admin() to authenticated;

-- No seed row: an empty allowlist is the correct, safe default. Insert the
-- first Founder row directly (e.g. via the Supabase SQL editor, not this
-- migration) once the real auth.users id is known:
--   insert into public.platform_admins (user_id, role) values ('<uuid>', 'founder');
