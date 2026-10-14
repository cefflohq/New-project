# CEFFLO — International Country Pack Guideline (DRAFT)

Status: DRAFT guideline, 2026-10-14. Builds on
`CEFFLO_ASIA_EXPANSION_READINESS_AUDIT.md`. Nothing here is built or
claimable. Facts marked **(verify)** must be confirmed with the official
source before build or launch.

## Ringkasan (BM)

- Cefflo ialah produk **antarabangsa**, bukan produk label Malaysia.
  **Bahasa default: English.** Bahasa tempatan ditambah per negara.
- **Kali pertama buka app** (Vendor dan Driver): pilih **Rantau** (Asia,
  Europe, …) → pilih **Negara**. Negara menentukan mata wang, kod telefon,
  zon masa, format alamat/poskod, data kawasan, jenis ID pemandu dan cara
  bayaran tempatan ("country pack").
- **Harga langganan Cefflo:** tetap. MYR untuk Malaysia, **USD untuk semua
  negara lain**. Wang operasi (harga produk, caj hantar, bayaran rider)
  ikut mata wang tempatan business.
- **China dikeluarkan dari skop.**
- Fokus pertama: ASEAN (Brunei, Singapura, Indonesia, Thailand, Filipina,
  Vietnam, Kemboja, Laos, Myanmar, Timor-Leste).
- Semua font: keluarga **Noto** (Google, percuma, lesen OFL) — senarai muat
  turun di §5.

## 1. Principles

1. **English is the default** language on every surface. A country adds its
   own language(s); the user can always switch back to English.
2. **One product, many country packs.** Core logic (orders, zones, runs,
   POD, tracking) is identical everywhere. Country differences live only in
   data (the country pack), never in `if (country == 'MY')` code.
3. **Country belongs to the business** (and to the driver profile). Once a
   business has orders, its country/currency change goes through support.
4. **Pricing:** Cefflo subscription price book in **MYR for Malaysia, USD
   elsewhere**, same plan structure. Operational money (product prices,
   delivery fee, rider pay per drop, minimums) is in the business's local
   currency (ISO 4217) with the correct number of decimals.
5. **Maps:** Google Maps Platform in every target country (see the auto
   zone master guideline). China is excluded (Google unavailable).
6. A country is **Planned → Beta → Live**. Only Live countries are
   selectable by default; Beta behind an invite flag.

## 2. First-launch structure (Vendor App, Driver App, Vendor Web sign-up)

```
Language (English default, device language suggested)
  → Region:  Asia | Europe | Middle East | Oceania | Americas | Africa
    → Country (only Live / Beta countries of that region)
      → sign in / sign up
```

- **Suggest, don't force:** pre-select region + country from the device
  locale / SIM country; the user confirms.
- **Vendor:** the country is saved on the business at creation
  (`bootstrap_business`) and sets currency, timezone (default the
  country's main zone; editable where a country has several), phone
  prefix, postcode rule, admin areas for zones, payment methods.
- **Driver:** country saved on the driver profile; drives phone field,
  ID documents for Marketplace verification, payout methods. A driver
  joining a business by invite inherits that business's country if none
  is set.
- **Customer surfaces** (Storefront, Tracking) need no picker: they
  follow the business's country, language from the browser with English
  fallback.
- **Country not available:** show "Not available in your country yet —
  join the waitlist" (store email + country), never a broken flow.
- Settings → "Country & region" shows the current country; changing it
  for a business with data goes through support.

## 3. Data model (proposed)

`public.countries` (reference data, read-only to users):

| Column | Example (MY) |
|---|---|
| `iso2` / `iso3` | `MY` / `MYS` |
| `region` | `asia` |
| `status` | `live` / `beta` / `planned` |
| `name_en`, `name_local` | Malaysia / Malaysia |
| `languages` | `{en, ms}` (first = default after English) |
| `currency`, `currency_decimals` | `MYR`, 2 |
| `subscription_currency` | `MYR` (all others `USD`) |
| `phone_code`, `phone_regex` | `+60`, national number rule |
| `timezones` | `{Asia/Kuala_Lumpur}` |
| `postcode_regex`, `postcode_required` | `^\d{5}$`, false |
| `address_format` | line order + labels |
| `admin_area_source`, `admin_area_level` | `geoBoundaries:MYS`, `ADM3` |
| `driver_id_types` | `[{code:'mykad', digits:12}]` |
| `licence_classes` | `{B2, D, DA}` |
| `payment_methods` | `{card, fpx, duitnow, tng, grabpay}` |
| `payment_gateways` | `{curlec, stripe}` |
| `maps_provider` | `google` |

`businesses.country_iso2` and `profiles.country_iso2` (FK). Existing
`businesses.currency` and `businesses.timezone` are filled from the
country at creation. Phones stored in **E.164** (`+60123456789`).

## 4. Country packs — ASEAN (first ring)

Facts below are from general knowledge plus the sources in §9; every row is
**(verify)** before that country moves to Beta.

| Country | Languages (locale) | Script / font | Currency (decimals) | Phone | Postcode | Time zone(s) |
|---|---|---|---|---|---|---|
| Malaysia | English `en`, Malay `ms-MY` | Latin — current Inter / Manrope | MYR (2) | +60 | 5 digits | Asia/Kuala_Lumpur |
| Brunei | Malay `ms-BN`, English | Latin | BND (2) | +673 | 2 letters + 4 digits (BA1234) | Asia/Brunei |
| Singapore | English `en-SG`, Chinese `zh-SG`, Malay, Tamil `ta-SG` | Latin + Noto Sans SC + Noto Sans Tamil | SGD (2) | +65 | 6 digits | Asia/Singapore |
| Indonesia | Indonesian `id-ID` | Latin | IDR (0) | +62 | 5 digits | Asia/Jakarta, Asia/Makassar, Asia/Jayapura |
| Thailand | Thai `th-TH` | Noto Sans Thai (+ Looped for body text optional) | THB (2) | +66 | 5 digits | Asia/Bangkok |
| Philippines | English `en-PH`, Filipino `fil-PH` | Latin | PHP (2) | +63 | 4 digits | Asia/Manila |
| Vietnam | Vietnamese `vi-VN` | Latin with diacritics — Inter supports Vietnamese; Manrope **(verify)**, else Noto Sans | VND (0) | +84 | 6 digits | Asia/Ho_Chi_Minh |
| Cambodia | Khmer `km-KH`, English | Noto Sans Khmer | KHR (0); USD widely used | +855 | 5–6 digits **(verify)** | Asia/Phnom_Penh |
| Laos | Lao `lo-LA` | Noto Sans Lao | LAK (0) | +856 | 5 digits | Asia/Vientiane |
| Myanmar | Burmese `my-MM` | Noto Sans Myanmar (Unicode, not Zawgyi) | MMK (0) | +95 | 5 digits | Asia/Yangon |
| Timor-Leste | Tetum `tet`, Portuguese `pt-TL` | Latin | USD (2) | +670 | none | Asia/Dili |

### 4.1 Admin areas for zones (data source)

All from **geoBoundaries gbOpen** unless noted — the loader
`scripts/load-admin-areas.mjs` already does this for `MYS`; it needs an ISO3
argument. API pattern: `https://www.geoboundaries.org/api/current/gbOpen/{ISO3}/{ADM}/`
(also on GitHub `wmgeolab/geoBoundaries`). Licence CC BY — credit on maps.
Check each country's max level before loading **(verify)**.

| Country | Suggested level for zones | Local name | Note |
|---|---|---|---|
| Malaysia | ADM3 (Sabah ADM2) | mukim / bandar | Loaded today |
| Brunei | ADM2 | mukim | small country, 4 districts |
| Singapore | Planning areas | URA Master Plan planning areas | geoBoundaries detail is coarse; use **data.gov.sg** URA planning-area boundaries (Open Data Licence) **(verify)** |
| Indonesia | ADM3 | kecamatan | Very large file; load per province on demand |
| Thailand | ADM2 | amphoe / khet (Bangkok) | |
| Philippines | ADM3 | city / municipality | Metro Manila cities |
| Vietnam | **(verify)** | — | 2025 reform merged provinces and removed the district level; geoBoundaries may predate it. Use current commune-level data from official / OSM sources |
| Cambodia | ADM2 | district / khan | |
| Laos | ADM2 | district (muang) | |
| Myanmar | ADM3 | township | |
| Timor-Leste | ADM2 | administrative post | |

If a country's data is missing or outdated, fallback: **OpenStreetMap**
administrative boundaries (ODbL) via Overpass / Geofabrik extracts.

### 4.2 Driver ID documents (Marketplace verification only)

Business-invited drivers need no ID check (unchanged rule). Store only a
hash + last 4, as today for MyKad.

| Country | Identity document | Format hint | Driving licence (motorcycle / car) |
|---|---|---|---|
| Malaysia | MyKad | 12 digits | B2 / D (JPJ) |
| Brunei | Smart IC (yellow citizen / purple PR / green) | 2-digit prefix + 6 digits **(verify)** | Brunei licence (JPD) |
| Singapore | NRIC / FIN | letter + 7 digits + letter | Class 2B / 3 (SPF) |
| Indonesia | KTP-el (NIK) | 16 digits | SIM C / SIM A (Polri) |
| Thailand | Thai ID card | 13 digits | Motorcycle / private car licence (DLT) |
| Philippines | PhilSys ID (PSN/PCN), or UMID / passport | 16 digits PCN **(verify)** | LTO licence, restriction codes A / B |
| Vietnam | CCCD (citizen ID) | 12 digits | GPLX A1 / B (new 2025 classes **verify**) |
| Cambodia | Khmer national ID | 9 digits **(verify)** | Cambodian licence A / B |
| Laos | Lao ID card | **(verify)** | Lao licence |
| Myanmar | NRC | region/township/number code | Myanmar licence |
| Timor-Leste | Bilhete de Identidade / voter card | **(verify)** | Timor-Leste licence |

OCR / Google Vision stays on HOLD everywhere; the full-ID data-minimisation
gate (CLOUD_HANDOFF §146) applies per country.

### 4.3 Local payments

Used for: Cefflo subscription (MYR / USD), Driver Marketplace fees, and
later customer payments on the Storefront.

| Country | Popular local methods | Gateway options |
|---|---|---|
| Malaysia | Card, FPX, DuitNow QR, Touch 'n Go, GrabPay | Curlec (decided), Stripe, Xendit |
| Brunei | Card, bank transfer | Stripe via SG entity / 2C2P **(verify)** |
| Singapore | Card, PayNow, GrabPay | Stripe, Xendit, 2C2P |
| Indonesia | QRIS, virtual accounts, GoPay, OVO, DANA, ShopeePay | Xendit, Midtrans; Stripe ID is "preview" only |
| Thailand | PromptPay QR, card, TrueMoney | Opn (Omise), Xendit, 2C2P |
| Philippines | GCash, Maya, QR Ph, card | Xendit, PayMongo |
| Vietnam | VietQR / NAPAS, MoMo, ZaloPay, VNPay | Xendit, 2C2P, local PSPs |
| Cambodia | KHQR (Bakong), ABA Pay, Wing | ABA PayWay, 2C2P **(verify)** |
| Laos | BCEL One, LaoQR | 2C2P / local bank **(verify)** |
| Myanmar | KBZPay, Wave Money, AYA Pay | 2C2P / local PSP **(verify)** |
| Timor-Leste | Card, bank transfer (USD) | **(verify)** |

Recommendation: one **regional gateway** (Xendit or 2C2P) for most ASEAN
countries + Curlec in Malaysia, so subscriptions in USD and local methods
are handled without one integration per country. **Founder decision.**

## 5. Fonts — what to download

All free, SIL Open Font Licence. Get them from Google Fonts
(fonts.google.com) or GitHub `notofonts/*` / `google/fonts`.

| Need | Font | GitHub |
|---|---|---|
| Latin incl. Vietnamese (MY, BN, SG, ID, PH, VN, TL) | Inter (already shipped; supports Vietnamese) | `rsms/inter` |
| Thai | Noto Sans Thai (UI), Noto Sans Thai Looped (optional body) | `notofonts/thai` |
| Khmer | Noto Sans Khmer | `notofonts/khmer` |
| Lao | Noto Sans Lao | `notofonts/lao` |
| Burmese | Noto Sans Myanmar | `notofonts/myanmar` |
| Chinese (Singapore) | Noto Sans SC (already a fallback in Vendor App) | `notofonts/noto-cjk` |
| Tamil (Singapore) | Noto Sans Tamil | `notofonts/tamil` |

Rules: keep Inter/Manrope as the brand font, add the Noto family as
`fontFamilyFallback` (Flutter) / CSS fallback; on web load the script font
only for that language (`unicode-range`) to keep pages light. Check that
Manrope covers Vietnamese diacritics; if not, Vietnamese falls back to
Inter **(verify)**.

## 6. Formats

- Money: `Intl.NumberFormat(locale, {style:'currency', currency})` (web) /
  `NumberFormat.simpleCurrency` (Flutter `intl`). Never hard-code "RM".
  IDR, VND, KHR, LAK, MMK have 0 decimals.
- Phone: E.164 storage, validate with libphonenumber
  (`libphonenumber-js` on web, `phone_numbers_parser` in Flutter).
  WhatsApp links use the E.164 number directly.
- Dates / times: business timezone; locale from the UI language.
- Address: free text + map pin (pin is the truth); postcode optional with
  a per-country rule.
- Distance: km everywhere in Asia (miles only if a future market needs it).

## 7. Second ring (later, not ASEAN)

Hong Kong (HKD, zh-HK, +852, no postcode), Taiwan (TWD, zh-TW), Japan
(JPY 0 decimals, ja), South Korea (KRW 0 decimals, ko; Google Maps is
limited there **verify**), India (INR, en/hi + many scripts, UPI), Bangladesh,
Sri Lanka, Pakistan, Gulf states (RTL Arabic needs a layout review), and
Europe (EUR/GBP, VAT, GDPR). English default lets these start in English.

## 8. Build order (proposed)

1. **Foundation (no visible change in Malaysia):** `countries` table with
   MY live; `country_iso2` on businesses and profiles; E.164 phones;
   money formatter from currency; timezone from country; remove
   hard-coded RM / +60 / `country=my` / 5-digit postcode.
2. **First-launch picker** (Region → Country) in Vendor App, Driver App,
   Vendor Web sign-up; waitlist for unavailable countries.
3. **English default** everywhere (today the Driver/Vendor apps follow the
   device or BM — confirm defaults per surface).
4. **First new country pack** (Founder picks; Singapore or Brunei is the
   lightest): admin areas, phone/postcode rules, payments, driver IDs,
   language if needed.
5. Repeat per country: translate → fonts → admin areas → payments → driver
   IDs → legal review → Beta → Live.

## 9. Founder decisions

1. Second country (suggested Singapore or Brunei).
2. Regional gateway: Xendit vs 2C2P (+ Curlec in MY).
3. Subscription: MYR for Malaysia, USD elsewhere — confirm USD price
   points (same numbers as MYR or converted).
4. English default on Malaysian installs too, or BM default in Malaysia
   only?
5. Legal / privacy counsel per country before real vendors.

## 10. Sources

- geoBoundaries API and GitHub: [wmgeolab/geoBoundaries](https://github.com/wmgeolab/geoBoundaries), [geobounds R docs](https://rdrr.io/cran/geobounds/man/gb_get_adm.html)
- Xendit coverage: [Shuttle — Xendit](https://www.shuttleglobal.com/payment-providers/xendit/), [Xendit vs 2C2P](https://paymentproviders.io/compare/xendit-vs-2c2p?focus=fees), [SEA processors 2026](https://www.paritydeals.com/blog/best-payment-processors-sea-2026/)
- Stripe in Asia: [Stripe unsupported / preview countries](https://startupowl.com/setup/stripe-unsupported-countries), [Stripe Singapore expansion](https://fintechnews.sg/136275/payments/stripe-singapore-expansion/)
- Fonts: Google Fonts / GitHub `notofonts`, `rsms/inter`
