-- FCM devices for the Android apps (Founder 2026-10-16): native push looks
-- like a normal app notification (full app icon, no site address).
-- push_unregister(p_endpoint) already removes either kind by its endpoint.
create or replace function public.push_register_fcm(p_app text, p_token text) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  if p_app not in ('vendor', 'rider') then raise exception 'invalid app'; end if;
  if coalesce(p_token, '') !~ '^[A-Za-z0-9_:\-]+$' or length(p_token) > 400 then raise exception 'invalid token'; end if;
  insert into push_subscriptions (user_id, app, kind, endpoint)
    values (auth.uid(), p_app, 'fcm', p_token)
  on conflict (endpoint) do update set
    user_id = excluded.user_id, app = excluded.app, kind = 'fcm', failures = 0, last_seen_at = now()
  returning id into v_id;
  return v_id;
end $$;

revoke all on function public.push_register_fcm(text, text) from public, anon;
grant execute on function public.push_register_fcm(text, text) to authenticated;
