# Integrations Phase 2: Wix, Google Sheets, Google Drive

**Status:** Built on staging 2026-10-10 (Founder: "bina je semua terus"). Not production.
**Code:** `supabase/migrations/20261010090000_integrations_phase2.sql`,
`supabase/functions/integrations-inbound/` (`index.ts`, `scripts.ts`),
Vendor Web Settings → Integrations, Vendor App Integrations.
**Tests:** `tests/staging/integrations_phase2.test.mjs` 32/32; Phase 1 suite 43/43 (no regression).

## Design
| Provider | How orders arrive | Credential |
|---|---|---|
| Wix | Wix Automation "Order placed" → Send HTTP request → `POST /integrations-inbound/wix/{connection}/{token}` | 48-hex token generated server-side, stored in Vault, shown once; reconnect replaces it |
| Google Sheets | Apps Script in the owner's sheet sends new rows every 5 min to `/api/orders` | `cfk_live_` key bound to the `google_sheets` connection, shown once inside the script |
| Google Drive | Apps Script imports CSV / xlsx / Google Sheets files in one folder every 10 min, then moves them to "Cefflo imported" | key bound to the `google_drive` connection |

- No Google OAuth and no Wix app credentials: the scripts run in the owner's own
  Google account; Cefflo never holds a Google token. The Phase 1 Google OAuth HOLD is not touched.
- All orders go through `_integration_ingest_order` (same validation, dedup by
  external id, business only from the server-side connection).
- Owner/Operator only (`is_business_member`); Helper, outsiders and anon denied.
- Reconnect or disconnect revokes the previous token/key immediately.
- `integration_list` lists only general API keys; Sheets/Drive keys stay with their connection.
- `GET /integrations-inbound/script/{sheets|drive}` serves the template with placeholders only (no secret).

## Known limits
- Wix Automation payload shapes vary; the mapper reads the eCom order (billing/shipping
  contact, address, line items) and also accepts a customised flat body with Cefflo field names.
- Rate limit 60 orders/min per key; the scripts pace at about 1 per second.
- Drive: rows that fail are listed in the file description; the file is still moved.
- Production rollout needs this migration and the function deploy in the prod plan.
