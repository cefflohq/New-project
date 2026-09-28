-- S4-03 Batch 3: remove direct Vendor mutation bypasses after RPC cutover.
-- Preserve business-member reads; protected SECURITY DEFINER contracts own writes.

drop policy riders_vendor on public.riders;
create policy riders_vendor on public.riders
  for select using (public.is_business_member(business_id));

drop policy orders_vendor on public.orders;
create policy orders_vendor on public.orders
  for select using (public.is_business_member(business_id));

drop policy assignments_vendor on public.rider_assignments;
create policy assignments_vendor on public.rider_assignments
  for select using (public.is_business_member(business_id));
