-- FOUNDR RPC grant hardening (forward-only, DCL only).
-- The four FOUNDR migrations (202608300001-4) never included the explicit
-- revoke-then-grant pattern every other privileged RPC in this codebase
-- uses (see e.g. 202608290002/3's create_team_invitation). As a result every
-- FOUNDR function ended up with Postgres's default PUBLIC execute grant
-- still in place. is_platform_admin() has always been enforced inside every
-- privileged function and remains the real authorization boundary
-- unchanged by this migration -- this closes a defense-in-depth gap, not a
-- currently-exploitable hole. No table, policy, RLS, or function-body
-- change; grants only.

-- Internal helper: never called by any client, only from inside other
-- SECURITY DEFINER admin RPCs, whose owner-role context covers the call
-- regardless of any client-facing grant on this function.
revoke all on function public.log_admin_action(text, text, text, text, jsonb) from public, anon, authenticated;

-- Internal helper used only inside other functions' own is_platform_admin()
-- checks; never called directly by any client.
revoke all on function public.is_platform_admin() from public, anon;
grant execute on function public.is_platform_admin() to authenticated;

-- Authenticated-only admin read/write RPCs -- each already enforces
-- is_platform_admin() internally; this closes the same gap at the grant
-- layer too.
revoke all on function public.admin_stuck_riders(integer) from public, anon;
grant execute on function public.admin_stuck_riders(integer) to authenticated;

revoke all on function public.admin_list_vendors() from public, anon;
grant execute on function public.admin_list_vendors() to authenticated;

revoke all on function public.admin_get_vendor(uuid) from public, anon;
grant execute on function public.admin_get_vendor(uuid) to authenticated;

revoke all on function public.admin_list_riders() from public, anon;
grant execute on function public.admin_list_riders() to authenticated;

revoke all on function public.admin_delivery_operations() from public, anon;
grant execute on function public.admin_delivery_operations() to authenticated;

revoke all on function public.admin_list_audit_log(integer) from public, anon;
grant execute on function public.admin_list_audit_log(integer) to authenticated;

revoke all on function public.admin_list_subscriptions() from public, anon;
grant execute on function public.admin_list_subscriptions() to authenticated;

revoke all on function public.admin_list_app_versions() from public, anon;
grant execute on function public.admin_list_app_versions() to authenticated;

revoke all on function public.admin_set_feature_flag(text, boolean, text) from public, anon;
grant execute on function public.admin_set_feature_flag(text, boolean, text) to authenticated;

revoke all on function public.admin_start_maintenance(text, text, integer, text) from public, anon;
grant execute on function public.admin_start_maintenance(text, text, integer, text) to authenticated;

revoke all on function public.admin_end_maintenance(uuid) from public, anon;
grant execute on function public.admin_end_maintenance(uuid) to authenticated;

revoke all on function public.admin_set_subscription(uuid, text, text, integer, timestamptz) from public, anon;
grant execute on function public.admin_set_subscription(uuid, text, text, integer, timestamptz) to authenticated;

revoke all on function public.admin_record_app_version(text, text, text, text) from public, anon;
grant execute on function public.admin_record_app_version(text, text, text, text) to authenticated;

revoke all on function public.admin_create_announcement(text, text, text, timestamptz, timestamptz) from public, anon;
grant execute on function public.admin_create_announcement(text, text, text, timestamptz, timestamptz) to authenticated;

revoke all on function public.admin_set_announcement_active(uuid, boolean) from public, anon;
grant execute on function public.admin_set_announcement_active(uuid, boolean) to authenticated;

-- Deliberately anonymous-safe runtime reads (no is_platform_admin() gate by
-- design, non-sensitive aggregate/boolean output only): keep anon, drop
-- only the redundant bare PUBLIC grant.
revoke all on function public.get_feature_flag(text) from public;
grant execute on function public.get_feature_flag(text) to authenticated, anon;

revoke all on function public.get_active_maintenance() from public;
grant execute on function public.get_active_maintenance() to authenticated, anon;

revoke all on function public.get_active_announcements() from public;
grant execute on function public.get_active_announcements() to authenticated, anon;
