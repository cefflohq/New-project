# CEFFLO — Asia Expansion Readiness Audit (DRAFT)

Status: DRAFT audit, 2026-10-14. Launch market: **Malaysia**. Target:
Asia — Brunei, Singapore, Indonesia, Thailand, Philippines, Vietnam,
Cambodia, possibly China. Nothing here changes product truth; it lists what
is Malaysia-only today and what must change before each country.

## Ringkasan (BM)

Sistem teras (order, zon, run, rider, POD, tracking) **tidak terikat pada
Malaysia** dan boleh dipakai di negara lain. Yang terikat ialah lapisan
"tempatan": **mata wang RM ditulis terus dalam kod**, **telefon +60**,
**zon masa default Kuala Lumpur**, **bahasa EN/BM sahaja**, **poskod 5
digit**, **sempadan kawasan Malaysia sahaja**, **dokumen pemandu MyKad**,
dan **bayaran Curlec (Malaysia)**. Data asas sudah sedia (setiap business
ada `currency` dan `timezone`), jadi kerja utama ialah buang nilai Malaysia
yang ditulis terus dan jadikan ia ikut negara business. Paling mudah selepas
Malaysia: **Brunei, Singapura**, kemudian **Indonesia**. **China** perlu
platform berasingan (Google, Supabase, Vercel tidak boleh digunakan di sana).

## 1. What is already country-neutral

- Delivery lifecycle, zones, runs, rider resequencing, POD, tracking
  tokens, notifications, integrations (Shopify / Woo / Wix / Sheets / API).
- `businesses.timezone` exists and drives `business_today`, business
  hours, order numbering, helper backlog (fallback `Asia/Kuala_Lumpur`).
- `businesses.currency` column exists (`update_business_profile` accepts
  `p_currency`) — but no UI reads it (see §2).
- Coordinates, distance (km) and the planning engine are global.
- Vendor App already ships a CJK font fallback (Simplified Chinese).

## 2. Malaysia-only today (found in code)

| # | Area | Today | Where (examples) | Needed |
|---|---|---|---|---|
| 1 | Currency | "RM" hard-coded in UI strings and formatters; storefront delivery fee `6.00`; subscription table `monthly_price_myr`; hiring min "RM3.00 per drop" | `vendor_web/js/hiring.js`, `i18n.js`; `rider_mobile/.../jobs.dart`, `operations.dart`, `data/payments.dart` (`ringgit()`); `vendor_mobile/.../hiring.dart`, `storefront_common.dart`, `subscription.dart` | One money formatter driven by `businesses.currency` (ISO 4217); prices per currency; minimums per country |
| 2 | Phone | Driver app phone field fixed "+60" with MY flag; WhatsApp links turn leading `0` into `60`; MY-local number rules | `rider_mobile/lib/ui/widgets.dart:957`, `vendor_web/js/pages/riders.js:96`, `rider_mobile/lib/data/payments.dart:77` | Country picker, store E.164 (`+65…`, `+62…`), libphonenumber-style validation |
| 3 | Time zone | Fallback `Asia/Kuala_Lumpur` in SQL and clients; Vendor Web display tz fixed | `vendor_web/js/i18n.js:642`, `data.js:26`, migrations `business_today`, `business_hours` | Set tz at business setup from country/location; drop the KL fallback for new countries |
| 4 | Language | EN + BM only (Vendor Web, Vendor App, Driver, Storefront chrome) | `i18n.js`, ARB files, `store/i18n-ms.js` | Add per market: Bahasa Indonesia, Thai, Vietnamese, Filipino (EN usable), Khmer, Chinese |
| 5 | Locale formats | Dates/numbers `en-MY` / `ms-MY` | `vendor_web/js/i18n.js:638` | Locale from language + country |
| 6 | Address / postcode | Setup validates "5-digit Malaysian postcode" | `vendor_web/js/pages/setup.js`, `i18n.js:37` | Per-country postcode rule (SG 6, ID 5, TH 5, PH 4, VN 6, KH 5–6, BN alphanumeric "BA1234") or optional |
| 7 | Place search / boundaries | Place search and zone boundaries restricted to `country=my`; `admin_areas` loaded from geoBoundaries **MYS** only | `rider_mobile/lib/data/place_search.dart:17`, `functions/zone-boundary` | Country from the business; load geoBoundaries per country (ADM2/ADM3 level differs by country) |
| 8 | Geocoding | Mapbox now; Google planned with `components=country:MY` | `functions/geocode-order`, master guideline §B3 | Pass the business country instead of MY |
| 9 | Driver identity | Marketplace verification expects **MyKad 12-digit IC**; MY plate / licence | `rider_mobile/.../documents.dart:240`, `20261006180000_marketplace_verification_v1.sql` | Per-country ID types (SG NRIC, ID KTP/NIK, TH ID, PH PhilSys, VN CCCD…) and licence classes; data-protection review per country |
| 10 | Payments | Curlec (MY) + Stripe (intl) planned, not connected; subscription prices in MYR | `rider_mobile/lib/data/payments.dart`, `subscription_plans` | Gateway per market (e.g. Stripe/Adyen/Xendit for ID & PH, 2C2P / Omise for TH, local e-wallets) and price books per currency |
| 11 | Tax / invoices | None yet (payment HOLD) | — | SST (MY), GST (SG), VAT/PPN (ID, TH, PH, VN, KH) when invoicing is built |
| 12 | Legal / privacy | PDPA (Malaysia) readiness in progress | `CLOUD_HANDOFF.md` | SG PDPA, ID PDP Law, TH PDPA, PH DPA, VN PDPD — data residency and consent to be checked by counsel |
| 13 | Demo / sample data | Malaysian names, plates, "+60", KL address | `vendor_web/js/demo.js`, `rider_mobile` `DemoData` | Per-market demo set (low priority) |
| 14 | Hosting | Supabase Singapore project planned for production | `CLOUD_HANDOFF.md` §146 | Singapore region suits all ASEAN targets; China needs its own stack |

## 3. Country notes

| Country | Currency | Phone | Language | Maps (Google) | Notes |
|---|---|---|---|---|---|
| Malaysia | MYR | +60 | BM, EN | Yes | Launch market |
| Brunei | BND | +673 | Malay, EN | Yes | Closest to MY: BM UI works; BND pegged to SGD |
| Singapore | SGD | +65 | EN | Yes | English UI ready; 6-digit postcode; GST; NRIC rules strict |
| Indonesia | IDR (no decimals) | +62 | Bahasa Indonesia | Yes | BM ≠ BI, needs its own translation; large IDR amounts; PDP law, data-residency checks |
| Thailand | THB | +66 | Thai | Yes | Thai script fonts; PromptPay payments |
| Philippines | PHP | +63 | EN / Filipino | Yes | English UI usable; GCash / Maya payments |
| Vietnam | VND (no decimals) | +84 | Vietnamese | Yes | Diacritics in fonts; data-localisation decree to review |
| Cambodia | KHR / USD | +855 | Khmer, EN | Yes | USD widely used; Khmer script fonts |
| China | CNY | +86 | Chinese | **No** (Google blocked) | Supabase, Vercel, Google, WhatsApp unavailable; ICP licence and in-country data needed → separate China stack (e.g. Amap/Baidu maps, local cloud, WeChat). Treat as a later, separate project. |

## 4. Recommended order of work (not started)

1. **Foundation (before the 2nd country):** money formatter from
   `businesses.currency`; country on `businesses`; E.164 phone with country
   picker; timezone from country; postcode rule per country; remove hard
   `country=my`. These do not change Malaysian behaviour.
2. **Easiest next markets:** Brunei, Singapore (language already there).
3. **Translation markets:** Indonesia, Philippines (EN), Thailand, Vietnam,
   Cambodia — add locales, fonts, admin areas, driver ID types, payments.
4. **China:** separate decision and architecture; not on the current stack.

## 5. Open Founder decisions

1. Which country is #2 (suggested: Singapore or Brunei)?
2. One price book per currency, or USD-based pricing for new markets?
3. Payment gateway strategy for Asia (one regional vs local per country).
4. Is China in scope at all for the next 12–18 months?
5. Legal / privacy counsel per country before onboarding real vendors.
