-- FOUNDR Support (Founder 2026-10-16): the platform admin sees the support
-- tickets drivers send to Cefflo (app, account, other) and marks them
-- resolved. Tickets meant for a business stay with that business.
alter table public.support_tickets add column if not exists resolved_at timestamptz;
alter table public.support_tickets add column if not exists resolution_note text;

create or replace function public.admin_list_support_tickets()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  return (select coalesce(jsonb_agg(x), '[]'::jsonb) from (
    select jsonb_build_object('id', t.id, 'category', t.category, 'audience', t.audience,
      'description', t.description, 'status', t.status, 'created_at', t.created_at,
      'resolved_at', t.resolved_at, 'resolution_note', t.resolution_note,
      'email', u.email, 'phone', r.phone,
      'name', coalesce(r.name, u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'name'),
      'business_name', b.name) as x
    from support_tickets t
    left join auth.users u on u.id = t.auth_user_id
    left join riders r on r.id = t.rider_id
    left join businesses b on b.id = t.business_id
    where t.audience = 'cefflo'
    order by (t.status = 'resolved'), t.created_at desc limit 500) s);
end $$;

create or replace function public.admin_resolve_support_ticket(p_id uuid, p_note text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not is_platform_admin() then raise exception 'forbidden'; end if;
  if coalesce(length(trim(p_note)), 0) < 3 then raise exception 'note required'; end if;
  update support_tickets set status = 'resolved', resolved_at = now(), resolution_note = trim(p_note)
   where id = p_id and audience = 'cefflo' and status = 'open';
  if not found then raise exception 'not found or already resolved'; end if;
  insert into admin_audit_log (admin_user_id, action, target_type, target_id, reason, metadata)
  values (auth.uid(), 'support_ticket_resolved', 'support_ticket', p_id::text, trim(p_note), '{}'::jsonb);
end $$;

revoke all on function public.admin_list_support_tickets() from public, anon;
revoke all on function public.admin_resolve_support_ticket(uuid, text) from public, anon;
grant execute on function public.admin_list_support_tickets() to authenticated;
grant execute on function public.admin_resolve_support_ticket(uuid, text) to authenticated;
