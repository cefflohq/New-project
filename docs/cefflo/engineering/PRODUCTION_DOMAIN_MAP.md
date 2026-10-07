# CEFFLO Production Domain Map (FINAL / LOCKED, Founder 2026-10-05)

Authoritative. Supersedes earlier host plans (release plan §6 table,
`store.cefflo.com`, `rider.cefflo.com` as Driver, Operator/Helper via
`vendor.cefflo.com`, path-based public URLs). Prepared in the repo; **not
deployed, no DNS changed**.

| Domain | Surface | Source | Production artifact | Hosting |
|---|---|---|---|---|
| `cefflo.com`, `www.cefflo.com` | Marketing website | `website/index.html` | existing deployment | Vercel `new-project` (unchanged) |
| `vendor.cefflo.com` | Owner / Vendor Web (+ native Cefflo Vendor app) | `apps/vendor_web` | `dist-surfaces/vendor` | Worker `cefflo-prod-vendor` |
| `operator.cefflo.com` | Operator (Web + PWA) | `apps/vendor_mobile` (Flutter web, Operator entry) | `dist-surfaces/operator` | Worker `cefflo-prod-operator` |
| `helper.cefflo.com` | Helper (PWA) | `apps/vendor_mobile` (Flutter web, Helper entry) | `dist-surfaces/helper` | Worker `cefflo-prod-helper` |
| `driver.cefflo.com` | Driver (App) | `apps/rider_mobile` (Flutter web; native Cefflo Driver app) | `dist-surfaces/driver` | Worker `cefflo-prod-driver` |
| `invite.cefflo.com` | Team Invite gateway (Driver / Operator / Helper) | `invite/` | `dist-surfaces/invite` | Worker `cefflo-prod-invite` |
| `tracking.cefflo.com` | Customer Tracking PWA | `customer/` | `dist-surfaces/tracking` | Worker `cefflo-prod-tracking` |
| `order.cefflo.com` | Storefront / customer ordering | `store/` | `dist-surfaces/order` | Worker `cefflo-prod-order` |
| `foundr.cefflo.com` | FOUNDR (internal; Cloudflare Access) | `foundr/` | `dist-surfaces/foundr` | Worker `cefflo-prod-foundr` |
| `rider.cefflo.com` | legacy — retirement worker only | `retired/` | — | Vercel (unchanged) |

Every product host serves its surface **at its root**; `/web/`, `/invite/`,
`/customer/`, `/store/`, `/foundr/` are build/staging details only.
Operator and Helper reuse the one Vendor app build: the entry host
(`operator.` / `helper.`) selects the Sign-In entry; the server decides the
role (`get_my_businesses`). Owner/Vendor is not a Team Invite role.

## Build and deploy (prepared)

1. `npm run build` with the production identity and the canonical URLs below
   → `dist/` (staging keeps using `dist/` unchanged).
2. Flutter web builds with production `--dart-define`s:
   `apps/vendor_mobile` (`CEFFLO_INVITE_BASE_URL`, `CEFFLO_TRACKING_BASE_URL`,
   `CEFFLO_STOREFRONT_BASE_URL`, production Supabase) and `apps/rider_mobile`.
3. `CEFFLO_VENDOR_APP_WEB_DIR=<vendor build/web> CEFFLO_DRIVER_APP_WEB_DIR=<driver build/web> npm run build:surfaces`
   → `dist-surfaces/<surface>/` (root-served artifacts).
4. `node scripts/deploy-production.mjs --founder-approved` — refuses unless
   every artifact is packaged and is a production build. Deploys
   `deploy/cloudflare/<surface>.jsonc` (static-assets Workers, SPA fallback,
   custom domain). **Attaching each custom domain creates its DNS record**
   (and replaces the current Vercel record for `vendor`, `tracking`,
   `foundr`): record the current DNS first for rollback.

## Production hosting region (Founder-approved 2026-10-07)

Target Supabase region for production V1: **ap-southeast-1 (Singapore)**
(Supabase has no Malaysia region). Not executed: no new project, migration,
DNS, secrets, Auth or Storage change; the current production project
(ap-south-1) stays unchanged and INACTIVE. A PDPA cross-border transfer
assessment is still required before real-user production
(`docs/cefflo/security/PDPA_DATA_MAP.md` §7).

## Canonical production configuration

Static build (`scripts/environment.mjs`):

    CEFFLO_ENVIRONMENT=production
    CEFFLO_INVITE_BASE_URL=https://invite.cefflo.com/
    CEFFLO_TRACKING_BASE_URL=https://tracking.cefflo.com/
    CEFFLO_STOREFRONT_BASE_URL=https://order.cefflo.com/
    CEFFLO_DRIVER_WEB_URL=https://driver.cefflo.com/
    CEFFLO_OPERATOR_WEB_URL=https://operator.cefflo.com/
    CEFFLO_HELPER_WEB_URL=https://helper.cefflo.com/
    CEFFLO_VENDOR_CONSOLE_URL=https://vendor.cefflo.com/
    # CEFFLO_VENDOR_WEB_URL: not set in production (staging-only fallback:
    # shared Vendor app build + ?access= for Operator/Helper invites)

`CEFFLO_VENDOR_CONSOLE_URL` (Founder-approved production requirement,
2026-10-07; not a domain change): the Owner Vendor Web origin. The
Storefront (order.cefflo.com) accepts Live Preview data only from configured
app origins; without it the Vendor Web Storefront page cannot show the Live
Preview (saving still works). Configurable; never hard-coded.

Vendor app (`--dart-define`): `CEFFLO_INVITE_BASE_URL=https://invite.cefflo.com/`,
`CEFFLO_TRACKING_BASE_URL=https://tracking.cefflo.com/`,
`CEFFLO_STOREFRONT_BASE_URL=https://order.cefflo.com/` (these are also the
code defaults).

Supabase Auth (production) redirect allow-list, narrowest: the web origins
where a user signs in — `https://vendor.cefflo.com/**`,
`https://operator.cefflo.com/**`, `https://helper.cefflo.com/**`,
`https://driver.cefflo.com/**`, `https://foundr.cefflo.com/**` — plus the
native callbacks `cefflo-vendor://auth-callback`, `cefflo-driver://auth-callback`.
The Invite gateway has no sign-in and needs no entry. `tracking-pod`:
`CEFFLO_TRACKING_CORS_ORIGINS=https://tracking.cefflo.com`.

## Team Invite routing

`invite.cefflo.com/<token>` or `invite.cefflo.com/?link=<token>` →
`resolve_invite_link` (server) → Continue:

- Driver token → `https://driver.cefflo.com/?join=<token>`
- Operator token → `https://operator.cefflo.com/?access=operator&join=<token>`
- Helper token → `https://helper.cefflo.com/?access=helper&join=<token>`

The app keeps the token through sign-in and submits `join_via_invite_link`;
business and role come only from the token. Generated invite links and QR
codes use `https://invite.cefflo.com/?link=<token>` (accepted by the gateway
alongside `/<token>`).
