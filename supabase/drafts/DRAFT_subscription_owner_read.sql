-- DRAFT — NOT APPLIED. Founder approval required (RLS change).
-- Subscription read-only in Vendor apps (Founder, 2026-10-01).
-- Today business_subscriptions is readable by platform admins only
-- (business_subscriptions_read: is_platform_admin()), so an Owner cannot
-- see their own plan and the app shows an honest "managed by Cefflo"
-- state. This adds ONE read policy: the Owner of a business may read that
-- business's row. No write access; FOUNDR stays the only administrator.
create policy business_subscriptions_owner_read on public.business_subscriptions
  for select to authenticated
  using (is_business_owner(business_id));
-- Note: mrr_cents and updated_by also become visible to the Owner. If that
-- is not wanted, expose a SECURITY DEFINER my_business_subscription(
-- p_business_id) returning only plan_key, status, trial_ends_at instead.
