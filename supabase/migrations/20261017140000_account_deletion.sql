-- Account deletion (Founder 2026-10-17; Google Play + PDPA). A person asks
-- in the app (or by email via cefflo.com/delete-account). The account is
-- closed at once: signed out, sign-in refused, removed from every business
-- team and driver list. After 30 days (Privacy Policy: "account active +
-- 30 days") the personal details are erased; order records stay for 7 years
-- without the person's name, as the policy says.

create table if not exists public.account_deletion_requests (
  user_id uuid primary key references auth.users(id) on delete cascade,
  reason text,
  requested_at timestamptz not null default now(),
  purge_after timestamptz not null default now() + interval '30 days',
  purged_at timestamptz,
  source text not null default 'app' check (source in ('app', 'email'))
);
alter table public.account_deletion_requests enable row level security;
drop policy if exists deletion_admin_read on public.account_deletion_requests;
create policy deletion_admin_read on public.account_deletion_requests for select using (is_platform_admin());

create or replace function public._close_account(p_user uuid)
returns void language plpgsql security definer set search_path = public, auth as $$
begin
  update auth.users set banned_until = 'infinity' where id = p_user;
  delete from auth.sessions where user_id = p_user;
  update business_members set status = 'inactive' where user_id = p_user;
  update riders set status = 'inactive', availability_status = 'offline', updated_at = now() where auth_user_id = p_user;
  delete from push_subscriptions where user_id = p_user;
end $$;
revoke all on function public._close_account(uuid) from public, anon, authenticated;

-- The signed-in person closes their own account.
create or replace function public.request_account_deletion(p_reason text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_purge timestamptz;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  if exists (select 1 from platform_admins where user_id = auth.uid()) then
    raise exception 'platform admins cannot delete their account here';
  end if;
  insert into account_deletion_requests (user_id, reason)
  values (auth.uid(), nullif(left(trim(coalesce(p_reason, '')), 500), ''))
  on conflict (user_id) do update set reason = excluded.reason
  returning purge_after into v_purge;
  perform _close_account(auth.uid());
  return jsonb_build_object('purge_after', v_purge);
end $$;
revoke all on function public.request_account_deletion(text) from public, anon;
grant execute on function public.request_account_deletion(text) to authenticated;

-- Erase personal details (after 30 days, or by the admin on request).
create or replace function public._purge_account(p_user uuid)
returns void language plpgsql security definer set search_path = public, auth as $$
begin
  update riders set name = 'Deleted driver', phone = '-', vehicle_plate = null, updated_at = now() where auth_user_id = p_user;
  update profiles set display_name = 'Deleted user', phone = null, avatar_url = null, updated_at = now() where id = p_user;
  delete from driver_licences where user_id = p_user;
  update driver_marketplace_verifications set vehicle_photo_path = null where user_id = p_user;
  delete from notifications where recipient_user_id = p_user;
  update auth.users set email = 'deleted-' || id || '@deleted.cefflo.com', phone = null,
         raw_user_meta_data = '{}'::jsonb, encrypted_password = '', banned_until = 'infinity'
   where id = p_user;
  delete from auth.identities where user_id = p_user;
  update account_deletion_requests set purged_at = now() where user_id = p_user;
end $$;
revoke all on function public._purge_account(uuid) from public, anon, authenticated;

create or replace function public.purge_due_account_deletions()
returns int language plpgsql security definer set search_path = public as $$
declare r record; n int := 0;
begin
  for r in select user_id from account_deletion_requests where purged_at is null and purge_after <= now() loop
    perform _purge_account(r.user_id); n := n + 1;
  end loop;
  return n;
end $$;
revoke all on function public.purge_due_account_deletions() from public, anon, authenticated;
select cron.unschedule('purge-deleted-accounts') where exists (select 1 from cron.job where jobname = 'purge-deleted-accounts');
select cron.schedule('purge-deleted-accounts', '17 3 * * *', 'select public.purge_due_account_deletions()');

-- FOUNDR: the queue, and closing an account asked for by email.
create or replace function public.admin_list_account_deletions()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  return (select coalesce(jsonb_agg(jsonb_build_object('user_id', d.user_id, 'email', u.email, 'reason', d.reason,
            'source', d.source, 'requested_at', d.requested_at, 'purge_after', d.purge_after, 'purged_at', d.purged_at)
          order by d.requested_at desc), '[]'::jsonb)
    from account_deletion_requests d join auth.users u on u.id = d.user_id);
end $$;

create or replace function public.admin_close_account_by_email(p_email text, p_note text)
returns void language plpgsql security definer set search_path = public as $$
declare v_user uuid;
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  select id into v_user from auth.users where lower(email) = lower(trim(p_email));
  if v_user is null then raise exception 'account not found'; end if;
  if exists (select 1 from platform_admins where user_id = v_user) then raise exception 'cannot restrict a platform admin'; end if;
  insert into account_deletion_requests (user_id, reason, source) values (v_user, trim(p_note), 'email')
  on conflict (user_id) do nothing;
  perform _close_account(v_user);
  insert into admin_audit_log (admin_user_id, action, target_type, target_id, reason, metadata)
  values (auth.uid(), 'account_deletion_requested', 'user', v_user::text, trim(p_note), '{}'::jsonb);
end $$;

revoke all on function public.admin_list_account_deletions() from public, anon;
revoke all on function public.admin_close_account_by_email(text, text) from public, anon;
grant execute on function public.admin_list_account_deletions() to authenticated;
grant execute on function public.admin_close_account_by_email(text, text) to authenticated;
