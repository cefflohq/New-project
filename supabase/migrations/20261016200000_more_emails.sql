-- More Cefflo emails (Founder 2026-10-16): rejected applications, new
-- applications (to the business owner) and opened driver documents. The one
-- dispatcher replaces 20261016190000's approval-only version.
create or replace function public.approval_email_dispatch()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
declare v_url text; v_secret text; v_kind text;
begin
  if tg_table_name = 'riders' then
    if tg_op = 'UPDATE' and old.status = 'pending' and new.status in ('active', 'inactive') and new.auth_user_id is not null then
      v_kind := 'rider';
    elsif new.status = 'pending' and new.auth_user_id is not null
          and (tg_op = 'INSERT' or old.auth_user_id is distinct from new.auth_user_id) then
      v_kind := 'new_rider';
    end if;
  elsif tg_table_name = 'team_join_requests' then
    if tg_op = 'UPDATE' and old.status = 'pending' and new.status in ('approved', 'rejected') then
      v_kind := 'team';
    elsif tg_op = 'INSERT' and new.status = 'pending' then
      v_kind := 'new_team';
    end if;
  elsif tg_table_name = 'driver_incident_cases' then
    if new.status = 'open' and new.opened_at is distinct from old.opened_at then
      v_kind := 'docs_opened';
    end if;
  end if;
  if v_kind is null then return null; end if;
  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'push_function_url';
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'push_webhook_secret';
  if v_url is null or v_secret is null then return null; end if;
  perform net.http_post(
    url := regexp_replace(v_url, '/push(/send)?/?$', '/approval-email'),
    body := jsonb_build_object('kind', v_kind, 'id', new.id),
    headers := jsonb_build_object('content-type', 'application/json', 'x-push-secret', v_secret),
    timeout_milliseconds := 5000);
  return null;
exception when others then
  raise warning 'email skipped: %', sqlerrm;
  return null;
end $$;
revoke all on function public.approval_email_dispatch() from public, anon, authenticated;

drop trigger if exists riders_approval_email on public.riders;
create trigger riders_approval_email after insert or update of status, auth_user_id on public.riders
  for each row execute function public.approval_email_dispatch();
drop trigger if exists team_join_approval_email on public.team_join_requests;
create trigger team_join_approval_email after insert or update of status on public.team_join_requests
  for each row execute function public.approval_email_dispatch();
drop trigger if exists incident_docs_opened_email on public.driver_incident_cases;
create trigger incident_docs_opened_email after update of status, opened_at on public.driver_incident_cases
  for each row execute function public.approval_email_dispatch();
