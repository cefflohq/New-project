# Integrations Phase 1 — security proposal (staging only)

Status: PROPOSAL — awaiting Founder approval before any migration, RPC, RLS or
Edge Function is applied (Security & Access Master §27 / §30 Part IV).
Scope: API / Webhooks, WooCommerce, Shopify (custom-app token). Google Sheets,
Google Drive and Wix are out of scope (credentials / Google OAuth HOLD).

## 1. Current truth (staging `tomvvmwktehexwhktenw`, 2026-10-08)

- Orders are created by Vendor RPCs, CSV/Excel import and the public
  Storefront (`_create_public_order`, `orders.origin in ('vendor','public')`).
- `orders.submission_idempotency_key` (uuid, unique per business) already
  provides replay protection for public submissions.
- No integration tables, no API keys, no inbound webhook endpoint exist.
  Vendor App/Web Integrations screens list Shopify, WooCommerce, Wix,
  Google Sheets, Google Drive and API/Webhooks as Coming soon.
- `is_business_member(business)` = Owner + Operator (Helper excluded).

## 2. Design

### Tables (RLS on, no direct client write)

| Table | Purpose | Client access |
|---|---|---|
| `integration_connections` | one row per business × provider (`api`, `woocommerce`, `shopify`): status, shop domain, created/revoked by/at, last event at | SELECT for Owner/Operator of the business (secrets never selectable) |
| `integration_secrets` | provider credentials and webhook secrets, encrypted with Supabase Vault (`vault.create_secret`); row holds only the Vault id | none |
| `integration_api_keys` | API keys: prefix (8 chars) + SHA-256 hash only; created/revoked by/at; last used | SELECT prefix/created/last-used for Owner/Operator |
| `integration_events` | inbound log: provider, external order id, signature result, outcome, order id, received at. UNIQUE (connection, external_id) = dedup | SELECT for Owner/Operator |

### RPCs (SECURITY DEFINER, `auth.uid()` + Owner/Operator check)

- `integration_create_api_key(business)` → returns the full key ONCE
  (`cfk_live_…`, 32 random bytes); stores hash only.
- `integration_revoke_api_key(key_id)`.
- `integration_connect_woocommerce(business, store_url, webhook_secret)`;
  `integration_connect_shopify(business, shop_domain, webhook_secret)`.
- `integration_disconnect(connection_id)` — revokes and deletes the Vault secret.
- Internal `_integration_ingest_order(connection, external_id, normalized jsonb)`
  — EXECUTE revoked from anon/authenticated; called only by the Edge Function
  with the service role. Creates a normal Cefflo order: origin `integration`
  (CHECK widened), items stored as name/quantity/price snapshot (no Cefflo
  product id required), delivery stop + tracking token + `delivery.created`
  event — the same records the Storefront creates.

### Edge Function `integrations-inbound` (staging)

- `POST /api/orders` — `Authorization: Bearer cfk_live_…`; key hash looked up;
  revoked/unknown → 401; per-key rate limit (60/min).
- `POST /woocommerce/{connection_id}` — verify `X-WC-Webhook-Signature`
  (base64 HMAC-SHA256 of raw body with the connection secret).
- `POST /shopify/{connection_id}` — verify `X-Shopify-Hmac-Sha256`; check
  `X-Shopify-Shop-Domain` equals the stored shop domain.
- All: body ≤ 64 KB, strict schema validation, business taken ONLY from the
  server-side connection/key (payload tenant ids ignored), dedup on
  external order id, timestamp window 10 min where provided, failures logged
  to `integration_events` without storing raw PII beyond what the order needs.

## 3. Exploit review

| Threat | Mitigation |
|---|---|
| Forged webhook | HMAC per connection; constant-time compare; unknown connection → 404 with no detail |
| Replay | dedup UNIQUE(connection, external_id); timestamp window |
| Cross-tenant injection | tenant from connection/key only; payload ids ignored |
| Key theft from client | key shown once; only hash stored; revocable; prefix for identification |
| Secret leak via RLS | secrets in Vault, table has no client grants |
| Helper/Driver misuse | RPCs require Owner/Operator; Helper denied (tested) |
| Abuse / flooding | per-key and per-connection rate limits; 64 KB body cap |
| PII over-collection | only name, phone, address, notes, item names/qty/price kept |

## 4. Least privilege

Edge Function uses the service role only to call `_integration_ingest_order`
and read connection/key metadata; all Vendor-facing actions go through
Owner/Operator-checked RPCs. Disconnect deletes credentials.

## 5. Tests (staging, positive + negative)

Owner/Operator create & revoke key; Helper/Driver/anon denied; valid API order
→ order + stop + token; invalid key 401; revoked key 401; duplicate external
id = one order; Woo/Shopify valid HMAC accepted, bad HMAC rejected, wrong shop
rejected; cross-business id in payload ignored; secrets not selectable.

## 6. Not in Phase 1

Google Sheets / Drive (Google OAuth HOLD), Wix (app credentials), Shopify
one-click public app (Partner account), order status sync back to providers,
production rollout.
