-- Security batch 2A (Founder-approved 2026-09-30, staging first): FOUNDR MFA
-- foundation. CEFFLO_SECURITY_AND_ACCESS_MASTER_SPEC s0B / s20.
--
-- NO enforcement here: is_platform_admin() is unchanged, so aal1 admin
-- sessions keep today's access until Migration B is separately approved.

-- The caller's own admin/MFA state, so FOUNDR can route a signed-in admin to
-- Set up authenticator or Verify instead of treating the gap as a denial.
-- Self-context only: auth.uid() / auth.jwt() of the caller, never another
-- user's row. The allowlist check mirrors is_platform_admin() exactly.
create or replace function public.platform_admin_status()
 returns jsonb
 language sql
 stable
 security definer
 set search_path to 'public'
as $function$
  select jsonb_build_object(
    'admin', exists(select 1 from public.platform_admins where user_id = auth.uid()),
    'aal', coalesce(auth.jwt() ->> 'aal', 'aal1'),
    'verified_factors', (
      select count(*) from auth.mfa_factors
       where user_id = auth.uid() and status = 'verified'));
$function$;

revoke execute on function public.platform_admin_status() from public, anon;
grant execute on function public.platform_admin_status() to authenticated;

-- Least privilege (spec s51): the unused staging test admin
-- (created 2026-08-30, never signed in, no sessions, no business
-- memberships) loses platform_admin. Its auth account is kept.
with revoked as (
  delete from public.platform_admins a
   using auth.users u
   where u.id = a.user_id
     and u.email like 'test%@cefflo.test'
     and u.last_sign_in_at is null
  returning a.user_id
)
insert into public.admin_audit_log (admin_user_id, action, target_type, target_id, reason, metadata)
select null, 'platform_admin.revoked', 'user', user_id::text,
       'Unused staging test admin removed (security batch 2A, Founder-approved)',
       jsonb_build_object('migration', 'foundr_mfa_foundation')
  from revoked;
