-- Approval emails (Founder 2026-10-16, option B): when a business approves a
-- driver or a team join request, the approval-email function mails the
-- person (Brevo). Reuses the push hook's vault secrets; the URL is the push
-- function's with /push/send swapped for /approval-email.
create or replace function public.approval_email_dispatch()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
declare v_url text; v_secret text; v_kind text;
begin
  if tg_table_name = 'riders' then
    if not (old.status = 'pending' and new.status = 'active' and new.auth_user_id is not null) then return null; end if;
    v_kind := 'rider';
  else
    if not (old.status = 'pending' and new.status = 'approved') then return null; end if;
    v_kind := 'team';
  end if;
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
  raise warning 'approval email skipped: %', sqlerrm;
  return null;
end $$;
revoke all on function public.approval_email_dispatch() from public, anon, authenticated;

drop trigger if exists riders_approval_email on public.riders;
create trigger riders_approval_email after update of status on public.riders
  for each row execute function public.approval_email_dispatch();
drop trigger if exists team_join_approval_email on public.team_join_requests;
create trigger team_join_approval_email after update of status on public.team_join_requests
  for each row execute function public.approval_email_dispatch();
