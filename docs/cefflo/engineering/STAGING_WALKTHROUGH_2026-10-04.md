# Staging Walkthrough — 2026-10-04

Follows `STAGING_VERIFICATION_2026-10-04.md`. Staging only
(`tomvvmwktehexwhktenw`); nothing deployed to production.

## Hosted staging surfaces

| Surface | Staging URL | Build | Role / login |
|---|---|---|---|
| Vendor Web | https://cefflo-staging-vendor.pages.dev/web/ | `bfc4ea7` | Owner / Operator test accounts |
| Vendor App (Flutter web) | https://cefflo-staging-app.pages.dev/ | `4c6b4e1` (no App change after) | Owner / Operator / Helper |
| Driver (Flutter web) | https://cefflo-staging-driver.vendor-mobile.workers.dev/ | `4c6b4e1` (no Driver change after) | Rider test accounts |
| Customer Tracking | https://cefflo-staging-tracking.pages.dev/customer/?token=… | `bfc4ea7` | none (link from Vendor) |
| Storefront | https://cefflo-staging-store.vendor-mobile.workers.dev/<slug> | `bfc4ea7` | none (public) |
| Invitation PWA | https://cefflo-staging-invite.pages.dev/invite/?link=… | `bfc4ea7` | invite link from Vendor |
| FOUNDR | https://cefflo-staging-foundr.pages.dev/foundr/ | `bfc4ea7` | platform admin |

Backend at `19655c9`: migration `20261004090000` applied (db push);
`tracking-pod` v5 deployed; `CEFFLO_TRACKING_CORS_ORIGINS=https://cefflo-staging-tracking.pages.dev`.
Runtime config: `storefrontBaseUrl`, `trackingBaseUrl` set for staging;
`mapboxPublicToken` not set.

## Verified on the hosted surfaces

- Vendor Web create order → customer tracking link shown (Copy/Share), on
  the staging tracking origin; same in the Vendor App (live repository test).
- Multi-drop run of two orders: the customer of stop 2 sees Picked up (with
  own pickup time) while queued, then On the way with the stored-state ETA,
  then Delivered, POD photo, rating persisted; never the other customer, a
  stop count, or an order id. Invalid token shows nothing.
- Opening or refreshing tracking makes no Mapbox request (0 across the
  session; reads are `public_tracking` only, coalesced by the page).
- Storefront: Vendor link = `{staging store base}{slug}`; QR encodes exactly
  that link; Share/Copy/Open use the same value; anonymous open and direct
  refresh work with real data; unpublished store is not served; republish.
- Helper refused rotate/revoke of tracking links; Operator allowed.

Found and fixed during hosting: Vendor Web create order failed against the
real backend (`vehicle_requirement` null) — `bfc4ea7`; POD photo blocked by
`tracking-pod` CORS preflight (`apikey` not allowed) — `19655c9`.

## Mapbox (blocked on credential)

`geocode-order` uses Mapbox Geocoding v6 forward with `permanent=true`
(stored results allowed), geocode once → store → reuse; it never calls Mapbox
for an already resolved order. **Not deployed:** no Mapbox credential exists
in staging or in the provided environment. Founder to provide:

1. `CEFFLO_MAPBOX_ACCESS_TOKEN` — a Mapbox access token for server-side
   geocoding (Supabase function secret, staging). Permanent geocoding must be
   enabled on the Mapbox account (it is billed differently from temporary
   geocoding).
2. `CEFFLO_MAPBOX_PUBLIC_TOKEN` — a public `pk.` token restricted to the
   staging tracking origin, for "View live map" (client build config).

Then: `supabase secrets set CEFFLO_MAPBOX_ACCESS_TOKEN=… --project-ref
tomvvmwktehexwhktenw`, `supabase functions deploy geocode-order`, rebuild
the static surfaces with `CEFFLO_MAPBOX_PUBLIC_TOKEN`, and run order → auto
geocode → coverage → plan without manual location.

## Proposals (not applied)

**Stored ETA.** Today `public_tracking` computes a heuristic range on every
read (no external call, so no cost, but not stored). Minimum change: write
`orders.estimated_arrival_at` (column exists) from a server function that
calls Mapbox Directions only on run start, active-stop change, or movement
beyond a threshold (e.g. 500 m or ETA drift > 5 min), at most once per
stop per 2 min; `public_tracking` returns the stored value. Needs a function
+ trigger and the Mapbox token.

**Re-sharing the tracking link.** The token is shown once at creation (hash
stored only). Imported orders and later re-sharing have no link without
`rotate_tracking_token`. Minimum safe change: derive the token as
HMAC(server secret in Vault, order id, token version) so an Owner/Operator
RPC can re-derive the same link; the stored hash and `public_tracking` stay
unchanged; rotation bumps the version. Needs a migration + Vault secret.
