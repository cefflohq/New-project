-- FOUNDR completion (Founder-approved 2026-10-07, staging first).
--
-- 1. MFA is enforced on the server. is_platform_admin() -- the gate of every
--    admin RPC and of the admin RLS / storage policies -- now also requires
--    an authenticator-verified session (JWT aal = 'aal2'). A password-only
--    (aal1) admin session can no longer call admin RPCs directly against the
--    API. platform_admin_status() is unchanged: it still reports `admin` and
--    `aal` so the FOUNDR sign-in can route an admin to MFA setup / verify.
--
-- 2. Marketplace verification decisions are recorded in admin_audit_log
--    (log_admin_action, like every other FOUNDR mutation). Decision rules are
--    unchanged.

create or replace function public.is_platform_admin()
 returns boolean
 language sql
 stable security definer
 set search_path to 'public'
as $function$
  select exists (
    select 1 from public.platform_admins where user_id = auth.uid()
  ) and coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
$function$;

create or replace function public.decide_marketplace_verification(p_user_id uuid, p_decision text, p_reason text default null::text)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  v_result jsonb;
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
  v_result := (select jsonb_build_object('status', status, 'retake', retake) from driver_marketplace_verifications where user_id = p_user_id);
  perform public.log_admin_action('marketplace_decision', 'driver', p_user_id::text, nullif(btrim(p_reason), ''),
    jsonb_build_object('decision', p_decision) || v_result);
  return v_result;
end $function$;
