-- Founder 2026-10-17: a business receives orders only after Cefflo verified
-- its SSM registration and owner IC (business_verifications). Enforced on
-- the orders table itself, so every path is covered: Vendor app and web,
-- storefront, public order page, imports and integrations.
create or replace function public.orders_require_verified_business()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from business_verifications
                  where business_id = new.business_id and status = 'verified') then
    raise exception 'business not verified';
  end if;
  return new;
end $$;
revoke all on function public.orders_require_verified_business() from public, anon, authenticated;

drop trigger if exists orders_require_verified_business on public.orders;
create trigger orders_require_verified_business before insert on public.orders
  for each row execute function public.orders_require_verified_business();
