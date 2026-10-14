# CEFFLO — Google Maps Platform API Key Setup (Phase 0)

Status: guide, 2026-10-14. Done by the Founder / ops in the Google Cloud
Console. Never paste a key into chat, a commit or a screenshot. Google
renames console menus from time to time; the names below were correct when
written.

## Ringkasan (BM)

1. Buat projek Google Cloud **"cefflo-maps"** (asingkan staging dan
   production jika boleh).
2. Sambung **Billing account** (kad diperlukan walaupun guna kuota
   percuma).
3. **Enable 6 API**: Maps JavaScript, Places API (New), Geocoding, Maps SDK
   for Android, Maps SDK for iOS, (pilihan) Map Tiles.
4. Buat **4 kunci**: server, browser, Android, iOS — setiap satu
   **dihadkan** (API + domain / app).
5. Pasang **bajet + had kuota harian** supaya testing tak boleh habiskan
   duit tanpa disedari.
6. Simpan kunci sebagai **secret / env** di tempat yang betul (§6) — bukan
   dalam kod.

## 1. Project and billing

1. Go to `console.cloud.google.com` with the company Google account.
2. Project picker → **New project** → name `cefflo-maps-staging` (later a
   second one, `cefflo-maps-prod`). Separate projects keep test usage out
   of production quotas and bills.
3. **Billing** → link a billing account (Google requires one even inside the
   free usage). Use the company card, not a personal one.

## 2. Enable the APIs

**APIs & Services → Library**, search and **Enable** each:

| API | Used for (Cefflo) |
|---|---|
| Maps JavaScript API | Web maps: Vendor Web, Customer Tracking, Storefront pin |
| Places API (New) | Address search / autocomplete (Storefront, Business Profile) |
| Geocoding API | Text addresses from imports and integrations (`geocode-order`) |
| Maps SDK for Android | Driver App and Vendor App maps on Android |
| Maps SDK for iOS | Driver App and Vendor App maps on iPhone |
| Map Tiles API (optional) | Only if we later draw Google tiles in `flutter_map` |

Do **not** enable Directions / Routes / Navigation SDK: navigation is a deep
link into the Google Maps app, which needs no key and is not billed.

## 3. Create the keys (APIs & Services → Credentials → Create credentials → API key)

Create one key per use and restrict each one immediately (**Edit API key**).

| Key name | Application restriction | API restriction |
|---|---|---|
| `cefflo-server` | None (Supabase Edge Functions have no fixed IP) | Geocoding API, Places API (New) |
| `cefflo-browser` | **Websites**: `https://vendor.cefflo.com/*`, `https://track.cefflo.com/*`, `https://cefflo.com/*`, `https://www.cefflo.com/*`, the staging hosts, `http://localhost:*/*` (staging key only) | Maps JavaScript API, Places API (New) |
| `cefflo-android` | **Android apps**: package `com.cefflo.cefflo_rider_mobile` and `com.cefflo.cefflo_vendor_mobile`, each with its **SHA-1** signing fingerprint (debug and release / Play App Signing) | Maps SDK for Android |
| `cefflo-ios` | **iOS apps**: bundle ids `com.cefflo.driver` and `com.cefflo.vendor` | Maps SDK for iOS |

SHA-1 fingerprint: `cd android && ./gradlew signingReport` (debug), and the
**App signing key certificate** SHA-1 in Play Console → Setup → App
integrity for release builds.

Because the server key cannot be IP-restricted, it must never leave the
server: it lives only in Supabase secrets.

## 4. Protect the bill

1. **Billing → Budgets & alerts → Create budget**: e.g. USD 50 / month for
   staging, alerts at 50 %, 80 %, 100 % to the Founder and ops emails.
2. **APIs & Services → each API → Quotas & System Limits**: set a
   **per-day request cap** (staging example: Geocoding 500/day, Places
   1,000/day, Maps JavaScript 2,000 loads/day). A cap stops traffic instead
   of billing past it.
3. Optional: **Billing → Billing export** to BigQuery for a monthly cost
   report.

## 5. Check the free usage and prices

Open **Google Maps Platform → Pricing** for the live numbers before
production (per-SKU free caps since 1 March 2025; see the Auto Zone master
guideline §B1). Confirm the Places Autocomplete billing model (per request
vs per session) there.

## 6. Where each key goes in Cefflo

| Key | Where | Name |
|---|---|---|
| `cefflo-server` | Supabase → Project Settings → Edge Functions → Secrets (or `supabase secrets set …`) | `CEFFLO_GOOGLE_MAPS_SERVER_KEY` |
| `cefflo-browser` | Vercel → Project → Environment Variables (staging / production) for Vendor Web, Customer, Store | `CEFFLO_GOOGLE_MAPS_BROWSER_KEY` |
| `cefflo-android` | Flutter build: `--dart-define=CEFFLO_GOOGLE_MAPS_ANDROID_KEY=…` (CI secret), injected into `AndroidManifest.xml` | `CEFFLO_GOOGLE_MAPS_ANDROID_KEY` |
| `cefflo-ios` | Flutter build: `--dart-define=CEFFLO_GOOGLE_MAPS_IOS_KEY=…` (CI secret), read in `AppDelegate` | `CEFFLO_GOOGLE_MAPS_IOS_KEY` |

The code wiring for these names is part of Phase 1 (geocoding) and Phase 5
(maps); until then the keys can be created and stored without any app
change. Tell the developer only that the secret is **set**, never its value.

## 7. Checklist

- [ ] Project `cefflo-maps-staging` created, billing linked
- [ ] 5 APIs enabled (Map Tiles optional)
- [ ] 4 keys created and **restricted**
- [ ] Budget + alerts set; daily quota caps set
- [ ] `CEFFLO_GOOGLE_MAPS_SERVER_KEY` set in Supabase staging secrets
- [ ] `CEFFLO_GOOGLE_MAPS_BROWSER_KEY` set in Vercel staging env
- [ ] Android / iOS keys saved as CI secrets
- [ ] Repeat for `cefflo-maps-prod` before launch

## 8. Cloud Shell shortcut (one line per command)

Open Cloud Shell (`>_` at the top of the console) and paste one line at a
time. `BILLING_ID` comes from step 2's output (format `XXXXXX-XXXXXX-XXXXXX`).

```bash
# 1. Pick the project
gcloud config set project cefflo-maps-staging
# 2. List billing accounts, then link one (skip if already linked in the UI)
gcloud billing accounts list
gcloud billing projects link cefflo-maps-staging --billing-account=BILLING_ID
# 3. Enable the APIs
gcloud services enable maps-backend.googleapis.com places.googleapis.com geocoding-backend.googleapis.com maps-android-backend.googleapis.com maps-ios-backend.googleapis.com apikeys.googleapis.com billingbudgets.googleapis.com
# 4. Create the four restricted keys
gcloud services api-keys create --display-name=cefflo-server --api-target=service=geocoding-backend.googleapis.com --api-target=service=places.googleapis.com
gcloud services api-keys create --display-name=cefflo-browser --allowed-referrers="https://*.cefflo.com/*,https://cefflo.com/*,http://localhost:*/*" --api-target=service=maps-backend.googleapis.com --api-target=service=places.googleapis.com
gcloud services api-keys create --display-name=cefflo-ios --allowed-bundle-ids=com.cefflo.driver,com.cefflo.vendor --api-target=service=maps-ios-backend.googleapis.com
gcloud services api-keys create --display-name=cefflo-android --allowed-application=sha1_fingerprint=RIDER_SHA1,package_name=com.cefflo.cefflo_rider_mobile --allowed-application=sha1_fingerprint=VENDOR_SHA1,package_name=com.cefflo.cefflo_vendor_mobile --api-target=service=maps-android-backend.googleapis.com
# 5. Budget USD 50 / month with alerts at 50 / 80 / 100 %
gcloud billing budgets create --billing-account=BILLING_ID --display-name=cefflo-maps-staging --budget-amount=50USD --threshold-rule=percent=0.5 --threshold-rule=percent=0.8 --threshold-rule=percent=1.0
# 6. Check the keys; read one value only when storing it in Supabase / Vercel
gcloud services api-keys list --format="table(name.basename(),displayName)"
gcloud services api-keys get-key-string KEY_ID
```

The Android key needs the real SHA-1 values (§3); create it last, or add the
apps later in Credentials → `cefflo-android` → Android apps.
