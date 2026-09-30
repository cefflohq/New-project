# Cefflo Storefront V1: architecture proposal (DRAFT, awaiting Founder approval)

Status: design only. Nothing here is applied. Drafts are in `supabase/drafts/`:

| Draft | What it does |
|---|---|
| `DRAFT_storefront_v1.sql` | permanent slug, storefront persistence, public catalogue, public orders |
| `DRAFT_business_hours.sql` | weekly hours, Owner-only writes, "open now" |
| `DRAFT_product_media_multi.sql` | 5 photos per product, ordered, 5 MB |
| `DRAFT_subscription_owner_read.sql` | Owner can read their own plan |

## 1. What already exists (verified on staging, 2026-10-01)

- **`public_order_pages`**: one page per business, a unique normalized `slug`, an `enabled` flag, and a secret access token stored only as a hash. It has 0 rows on staging, and no client calls `create_order_page` yet.
- **`public_order_catalog(token)`**: the public catalogue from `products`, `product_categories` and `product_media`, rate-limited.
- **`submit_public_order(token, …)`** creates a real order through the existing pipeline:
  - price snapshots come from `products`, not the client;
  - it validates items and quantities and is idempotent through `submission_idempotency_key`;
  - it inserts into `orders` with `origin = 'public'` and adds the order's delivery stop (`delivery_stops`);
  - it writes a tracking token for the existing tracking surface (`track.cefflo.com` / `customer/`) and a `delivery_events` entry;
  - it is rate-limited.
- **Conclusion:** Storefront V1 must build on this. No second catalogue and no second order system.

## 2. Architectural conflict (needs a Founder decision)

The existing public page is reached by a **secret token**. Only the hash is stored, so the link can't be shown again. Rotating the token changes the link.

A permanent storefront URL (`cefflo.com/nari`) is the opposite model: public and stable.

**Proposal:** the slug becomes the public identifier of a published storefront.

- The token functions stay untouched for now (no callers).
- Founder decides later whether to retire them.

## 3. Permanent public URL

- **Shape:** `https://cefflo.com/{slug}`, for example `cefflo.com/nari`.
- **Routing:** production `cefflo.com` is served by the Vercel project `new-project`. `vercel.json` routes by host, and the root host serves the public website.
  - Add one rewrite, `/:slug` → `/store/index.html` (a new static storefront surface).
  - Vercel serves existing files first, so website paths are unaffected.
  - Reserved slugs cover every current and planned top-level path.
- **Slug format:** 3–30 characters, `[a-z0-9-]`, no leading or trailing hyphen.
  - Normalized from the business name at creation.
  - Uniqueness is enforced by the existing unique index.
- **Slug change:** Owner only. The old slug is kept in `storefront_slug_history`.
  - It keeps redirecting to the new one.
  - It can never be claimed by another business (prevents link hijacking).
- **No "Reset link":** the slug is public identity. Unpublishing is the off switch.

## 4. Storefront settings in the Vendor app (after approval)

- **YOUR STOREFRONT**: `[cefflo.com/nari]` with Copy, QR and Share. This is the same component as the permanent invite link: a centred QR pop-up and a Share pop-up with the official brand icons.
- **Published / Unpublished** switch: Owner and Operator.
- **Template and accent:** saved through `save_storefront_appearance`, replacing today's in-memory settings. Keys are validated server-side.
- **Change URL:** Owner only.

## 5. Public catalogue and public ordering

Customers need no account and reach only two `SECURITY DEFINER` functions:

- **`public_storefront(slug)`**:
  - returns name, area, template/theme, categories, and active products with approved images;
  - returns null for unknown or unpublished stores;
  - old slugs return the canonical one.
- **`submit_storefront_order(slug, …)`**: the same order creation as `submit_public_order`. It moves into one shared internal function, `_create_public_order`, so both entry points behave identically.

Rate limits:

- Per caller: client address from `x-forwarded-for` + action.
- Per store: a ceiling of 120 orders a minute.
- The current per-token limit would throttle all of a store's real customers together once the identifier is public.

No table gains an anonymous policy, and no RLS is loosened.

**Security fix included:** `create_order_page`, `set_order_page_enabled` and `rotate_order_page_token` (and the product-media functions) currently allow any member, including Helpers. The drafts switch these to `is_business_operational` (Owner and Operator).

Later hardening, flagged but not in V1:

- a bot challenge on order submit (for example Cloudflare Turnstile);
- phone verification for first-time customers.

## 6. Business already has a website (V1)

No integration is needed. The vendor puts `https://cefflo.com/{slug}` behind an "Order Online" button.

## 7. Custom domains: architecture only, not implemented

Goal: `order.nari.com` → the Nari storefront, with `cefflo.com/nari` still working.

**Option A: Vercel (production host today)**

- The project adds `order.nari.com` through the Vercel Domains API.
- The vendor creates a `CNAME order → cname.vercel-dns.com`.
- Vercel verifies it and issues TLS automatically.
- Middleware maps `Host` → slug.
- **Limits:** project domain quotas and plan tier.

**Option B: Cloudflare for SaaS (Custom Hostnames)**

- Requires the Cefflo zone on Cloudflare and a fallback origin.
- The vendor creates a `CNAME order → stores.cefflo.com`, plus a TXT record if pre-validation is used.
- Cloudflare issues and renews TLS.
- A Worker maps `Host` → slug and serves the storefront.
- Better suited to thousands of vendor domains. This is a paid add-on beyond the free quota, so it's a Founder decision.

**Needed in both cases** (future migration, not drafted yet):

- A `storefront_domains` table: `business_id`, `hostname` (unique, lower-case), `status` (`pending_dns`, `verifying`, `active`, `failed`, `removed`), `verification` record, `created_at` and `verified_at`.
- Owner-only add and remove.
- Hostname uniqueness across businesses (the unique index).
- No "connected" state until the provider reports the certificate active.
- On removal or failure the storefront keeps serving on `cefflo.com/{slug}`, which always stays valid.

## 8. Website embed or order widget: future only

Nothing blocks it. `public_storefront` and `submit_storefront_order` are plain JSON RPCs, so a future `<script>` widget or iframe can call them.

To decide then: `frame-ancestors` / CSP per domain, and CORS allow-listing.

## 9. Business Hours (draft)

- **Table:** `business_hours(business_id, weekday 1–7, is_open, opens_at, closes_at)`.
  - Times are wall-clock in `businesses.timezone`; overnight hours and 24-hour days are supported.
  - A constraint forces closed days to have no times.
- **Writes:** only through `set_business_hours(business_id, 7 days)`, Owner only. It replaces the whole week atomically and is logged in `delivery_events`.
- **Reads:** members read through RLS. `business_open_now()` answers in the business's timezone.
- **Storefront:** exposes open or closed through `public_storefront` only after approval.
- **Mobile:** the Business Hours row returns, with the existing designed form, when this is applied.

## 10. Product photos (draft)

- Replace the two one-photo unique indexes with one active photo per position (1–5).
- A trigger enforces at most 5 photos per product.
- Create and approve archive only the photo at the same position.
- Add remove and reorder functions.
- Set both buckets to 5 MB.
- Tighten authorization to Owner and Operator.
- `product_media` has 0 rows on staging, so no data needs migrating.
