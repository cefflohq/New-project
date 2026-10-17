-- Storefront: the Template Library is now five templates (Founder 2026-10-17):
-- warung (Menu), tailor (Showcase), care (Basket), service (Service), pour (Spotlight).
-- New storefronts start on 'warung'. The template_key constraint already allows
-- all five; pages saved on earlier templates keep them (nothing is migrated).
-- Rollback: alter table public.public_order_pages alter column template_key set default 'homefood';
alter table public.public_order_pages alter column template_key set default 'warung';
