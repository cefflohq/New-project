-- Business profile figures (Founder 2026-10-16): live products, orders
-- (not cancelled) and the average customer rating from tracking-page
-- ratings (submit_rating).
create or replace function public.business_stats(p_business uuid)
returns jsonb
language sql stable security definer set search_path = public as $$
  select case when not is_business_member(p_business) then null else jsonb_build_object(
    'products', (select count(*) from products where business_id = p_business and archived_at is null),
    'orders', (select count(*) from orders where business_id = p_business and delivery_status <> 'cancelled'),
    'rating', (select round(avg(r.rating)::numeric, 1) from ratings r join orders o on o.id = r.order_id where o.business_id = p_business),
    'ratings', (select count(*) from ratings r join orders o on o.id = r.order_id where o.business_id = p_business)
  ) end
$$;
revoke all on function public.business_stats(uuid) from public, anon;
grant execute on function public.business_stats(uuid) to authenticated;
