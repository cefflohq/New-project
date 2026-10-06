-- Vendor Today (staging first). Problem: the Vendor App "Today" KPIs and
-- Recent Delivery counted every order ever created, not the business's
-- working day. The working day is server authority (no device time, no
-- hardcoded Malaysia), the same rule the locked Helper board uses:
-- now() in businesses.timezone, matching orders.order_date (set by
-- assign_order_number in the same timezone).
-- New read-only RPC; members of the business only (Owner / Operator).
-- Grants: authenticated only. No table, RLS or existing-function change.
-- Rollback: drop function public.business_today(uuid).

create or replace function public.business_today(p_business_id uuid)
returns date
language sql
stable
security definer
set search_path to 'public'
as $$
  select (now() at time zone coalesce(b.timezone, 'Asia/Kuala_Lumpur'))::date
  from public.businesses b
  where b.id = p_business_id and public.is_business_operational(p_business_id)
$$;

revoke all on function public.business_today(uuid) from public, anon;
grant execute on function public.business_today(uuid) to authenticated;
