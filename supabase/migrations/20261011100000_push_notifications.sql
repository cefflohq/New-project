-- Push notifications P1: Web Push (Founder 2026-10-11, staging first).
-- See docs/cefflo/security/PUSH_NOTIFICATIONS.md.
--
-- Per-device subscriptions + an AFTER INSERT hook on notifications that asks
-- the `push` Edge Function to deliver. The hook only sends the notification
-- id; the function reads the content with the service role. Vault holds:
--   push_function_url   e.g. https://<ref>.supabase.co/functions/v1/push/send
--   push_webhook_secret same value as the function's CEFFLO_PUSH_WEBHOOK_SECRET
-- Both are created per environment outside this file (never committed).

create extension if not exists pg_net with schema extensions;

create table public.push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  app text not null check (app in ('vendor', 'rider')),
  kind text not null default 'webpush' check (kind in ('webpush', 'fcm')),
  endpoint text not null unique check (endpoint ~ '^https://' or kind = 'fcm'),
  p256dh text,
  auth_key text,
  base_url text check (base_url is null or base_url ~ '^https://'),
  user_agent text,
  failures integer not null default 0,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  check (kind <> 'webpush' or (p256dh is not null and auth_key is not null))
);
create index push_subscriptions_user_app on public.push_subscriptions (user_id, app);

alter table public.push_subscriptions enable row level security;
create policy push_subscriptions_own_read on public.push_subscriptions
  for select using (user_id = auth.uid());
create policy push_subscriptions_own_delete on public.push_subscriptions
  for delete using (user_id = auth.uid());
grant select, delete on public.push_subscriptions to authenticated;

-- Register (or move) this device's subscription to the signed-in user.
create or replace function public.push_register(
  p_app text, p_endpoint text, p_p256dh text, p_auth text, p_base_url text default null, p_user_agent text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  if p_app not in ('vendor', 'rider') then raise exception 'invalid app'; end if;
  if coalesce(p_endpoint, '') !~ '^https://' or length(p_endpoint) > 1000 then raise exception 'invalid endpoint'; end if;
  if coalesce(p_p256dh, '') = '' or coalesce(p_auth, '') = '' or length(p_p256dh) > 200 or length(p_auth) > 100 then
    raise exception 'invalid keys';
  end if;
  if p_base_url is not null and (p_base_url !~ '^https://' or length(p_base_url) > 300) then raise exception 'invalid base url'; end if;
  insert into push_subscriptions (user_id, app, kind, endpoint, p256dh, auth_key, base_url, user_agent)
    values (auth.uid(), p_app, 'webpush', p_endpoint, p_p256dh, p_auth, p_base_url, left(p_user_agent, 300))
  on conflict (endpoint) do update set
    user_id = excluded.user_id, app = excluded.app, p256dh = excluded.p256dh, auth_key = excluded.auth_key,
    base_url = excluded.base_url, user_agent = excluded.user_agent, failures = 0, last_seen_at = now()
  returning id into v_id;
  return v_id;
end $$;

create or replace function public.push_unregister(p_endpoint text) returns void
language sql security definer set search_path = public as $$
  delete from push_subscriptions where endpoint = p_endpoint and user_id = auth.uid();
$$;

revoke all on function public.push_register(text, text, text, text, text, text), public.push_unregister(text) from public, anon;
grant execute on function public.push_register(text, text, text, text, text, text), public.push_unregister(text) to authenticated;

-- Delivery hook. Never blocks or rolls back the notification insert.
create or replace function public.notifications_push_dispatch() returns trigger
language plpgsql security definer set search_path = public, extensions as $$
declare v_url text; v_secret text;
begin
  if not exists (select 1 from push_subscriptions s where s.user_id = new.recipient_user_id and s.app = new.app) then
    return null;
  end if;
  if exists (select 1 from notification_preferences p where p.user_id = new.recipient_user_id and not p.enabled) then
    return null;
  end if;
  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'push_function_url';
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'push_webhook_secret';
  if v_url is null or v_secret is null then return null; end if;
  perform net.http_post(
    url := v_url,
    body := jsonb_build_object('id', new.id),
    headers := jsonb_build_object('content-type', 'application/json', 'x-push-secret', v_secret),
    timeout_milliseconds := 5000);
  return null;
exception when others then
  raise warning 'push dispatch skipped: %', sqlerrm;
  return null;
end $$;
revoke all on function public.notifications_push_dispatch() from public, anon, authenticated;

create trigger notifications_push
  after insert on public.notifications
  for each row execute function public.notifications_push_dispatch();
