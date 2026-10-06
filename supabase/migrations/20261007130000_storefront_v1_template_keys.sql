-- Storefront V1 templates (Founder references 2026-10-06; staging first).
-- Problem: public_order_pages.template_key only allowed the retired pre-V1
-- templates (arena, market, ritual, feast, stride), so no V1 template could
-- be saved. New: exactly the 18 V1 keys (store/templates.js
-- CEFFLO_TEMPLATE_ORDER == Vendor App registry); default 'care'. Pages on a
-- retired key move to 'care' -- the public renderer already showed 'care'
-- for any unknown key, so customers see no change. Theme (colours, tagline,
-- hero) is kept. Grants / RLS unchanged.
-- Rollback: restore the old check + default 'arena' (pages then need a
-- retired key again).

alter table public.public_order_pages drop constraint if exists public_order_pages_template_key;
update public.public_order_pages
   set template_key = 'care', updated_at = now()
 where template_key not in ('care', 'capsule', 'kit', 'brew', 'crimson', 'lift', 'harvest', 'botanic', 'combo',
                            'discover', 'atelier', 'pour', 'tailor', 'sprint', 'splash', 'service', 'warung', 'collector');
alter table public.public_order_pages alter column template_key set default 'care';
alter table public.public_order_pages add constraint public_order_pages_template_key check (template_key in (
  'care', 'capsule', 'kit', 'brew', 'crimson', 'lift', 'harvest', 'botanic', 'combo',
  'discover', 'atelier', 'pour', 'tailor', 'sprint', 'splash', 'service', 'warung', 'collector'));
