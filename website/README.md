# CEFFLO Public Website — homepage

Static, dependency-free homepage (`index.html` + `img/` + `fonts/`).

English is the default language. Bahasa Melayu is built in: every translated
element carries its BM text in `data-ms`, the nav **BM / EN** button switches
language and remembers the choice on the device, and `?lang=ms` opens the BM
version directly (for BM campaign links).

Inter is self-hosted in `fonts/` (Latin subset of the Inter files the Vendor app
bundles, SIL OFL 1.1, see `fonts/LICENSE`), so the page makes no third-party requests.

## Authority

- Visual direction and structure: `CEFFLO_PUBLIC_WEBSITE_MASTER.md` (Founder-supplied),
  §38–§42.
- Pricing: `docs/cefflo/sot/10_PRICING.md`, locked by the Founder on 2026-09-28
  (`docs/cefflo/05_DECISIONS.md` D-73). Only values that file lists as locked appear.
- Colours: canonical Vendor Mobile tokens (`apps/vendor_mobile/lib/core/theme.dart`, D-70).
- Product claims: `docs/cefflo/sot/01_PRODUCT_TRUTH.md` and the Claims Registry.

## Product imagery

Every phone screen is an unaltered capture of a locked Cefflo surface on
`official/staging` @ 22cef3d, run in its prototype/demo mode (demo data, no
backend), at the iPhone 15 app area (393 × 759 pt @2x = 786 × 1518). The capture
is extended with the screen's own top and bottom edge rows to 786 × 1704 for the
status-bar and home-indicator areas. The page draws the iPhone 15 frame, Dynamic
Island, side buttons and iOS status bar around it in CSS.

| File | Source |
|---|---|
| `s_v_today` | Vendor App `/audit/V11` (Today), built with the demo owner name set to "Fida" (Founder request: the default demo name is a real person) |
| `s_v_orders` | Vendor App `/audit/V12` (Orders) |
| `s_v_zones` | Vendor App `/audit/V16` (Zones) |
| `s_v_drivers` | Vendor App `/audit/V20` (Drivers) |
| `s_d_home`, `s_d_run`, `s_d_stops`, `s_d_pod` | Cefflo Driver `?screen=D19`, `D20`, `D21`, `D23` |
| `s_c_done` | Customer Tracking `?demo=1&state=delivered` |

Screens deliberately not used (marketing truth rules): Vendor zone detail V17
(per-stop minutes), active run V19 and Driver navigation D22 (route maps / ETA),
Customer Tracking Pickup / On the Way (estimated arrival and live-map entry),
Service area V26 (demo shows "Not set"), Order detail V13 (WhatsApp action).

Logos: `logo_mark` / `logo_word` are the official white assets and are only
placed on dark surfaces (graphite nav, blue footer). `favicon-32` and
`apple-touch-icon` are exported from the official navy app icon
(`docs/cefflo/brand/assets/logo/cefflo-logo-icon-navy.png`).


## Storefront gallery

`s_sf_brew`, `s_sf_pour`, `s_sf_botanic`, `s_sf_care`, `s_sf_warung` and
`s_sf_atelier` are captures of the locked Public Storefront (`dist/store`, built
from e93f464) rendered with a demo payload (demo shop names, products and
prices; no backend call). Product and hero photos inside them are CC0 (public
domain dedication) images found through Openverse; no brand logos. Sources:

| Key | Title | Creator | Source | Link |
|---|---|---|---|---|
| `bake_1` | strawberry cupcake | ani! | flickr | https://www.flickr.com/photos/53018729@N00/14397002993 |
| `bake_2` | A cupcake | clvs7 | flickr | https://www.flickr.com/photos/182866455@N04/49613651581 |
| `bake_3` | Chocolatechip Cookies | JESHOOTS.com | stocksnap | https://stocksnap.io/photo/chocolatechip-cookies-8AAE528F08 |
| `bake_4` | Coffee/Chocolate Cake | Dennis S. Hurd | flickr | https://www.flickr.com/photos/43296902@N00/50321152717 |
| `bake_5` | Birthday Cupcake 3 | megforce1 | flickr | https://www.flickr.com/photos/35608308@N05/25956069823 |
| `bake_hero` | Gingerbread cookies and milk | freestocks.org | flickr | https://www.flickr.com/photos/135396164@N05/31275892750 |
| `bot_1` | Free essential oil image. Cosmetic | unknown | rawpixel | https://www.rawpixel.com/image/5910591/photo-image-flower-public-domain-free |
| `bot_2` |  | unknown | rawpixel | https://www.rawpixel.com/image/5956132/free-public-domain-cc0-photo |
| `bot_3` |  | unknown | rawpixel | https://www.rawpixel.com/image/5958811/free-public-domain-cc0-photo |
| `bot_4` | Soy wax scented candle | unknown | rawpixel | https://www.rawpixel.com/image/5918468/image-public-domain-table-white |
| `bot_5` |  | unknown | rawpixel | https://www.rawpixel.com/image/5947458/free-public-domain-cc0-photo |
| `bot_hero` |  | unknown | rawpixel | https://www.rawpixel.com/image/5955952/free-public-domain-cc0-photo |
| `brew_1` | macro view cold latte glass | unknown | rawpixel | https://www.rawpixel.com/image/3283433/free-photo-image-coffee-iced-drink |
| `brew_2` | Cappuccino with Whipped Cream in White Cup | Image Catalog | flickr | https://www.flickr.com/photos/132795455@N08/19265315782 |
| `brew_3` | Green tea, matcha latte | unknown | rawpixel | https://www.rawpixel.com/image/6028471/photo-image-public-domain-free-tea |
| `brew_4` | Croissant Pastry | JESHOOTS.com | stocksnap | https://stocksnap.io/photo/croissant-pastry-3020ACDE09 |
| `brew_5` | Today's Flat White | cogdogblog | flickr | https://www.flickr.com/photos/37996646802@N01/26488792749 |
| `brew_hero` | Dials lights coffee machine | unknown | rawpixel | https://www.rawpixel.com/image/3303548/free-photo-image-espresso-machine-alloy-wheel-barista |
| `fash_1` | White beige dresses hangers store | unknown | rawpixel | https://www.rawpixel.com/image/3303632/free-photo-image-apparel-boutique-cc0 |
| `fash_2` | Women clothes on hangers | Artem Beliaikin | flickr | https://www.flickr.com/photos/157635012@N07/50179598477 |
| `fash_3` | Women clothes in the store | Artem Beliaikin | flickr | https://www.flickr.com/photos/157635012@N07/48124880907 |
| `fash_4` | Woman clothes in the store. Fashion store. Shopping mall. | Artem Beliaikin | flickr | https://www.flickr.com/photos/157635012@N07/49174901528 |
| `fash_hero` | Woman clothes in the store. Fashion store. Shopping mall. | Artem Beliaikin | flickr | https://www.flickr.com/photos/157635012@N07/49174902563 |
| `flo_1` | Flower Bouquet | Kelly Ishmael | stocksnap | https://stocksnap.io/photo/flower-bouquet-YLFU9GDFC5 |
| `flo_2` | Flowers Bouquet | Kelly Ishmael | stocksnap | https://stocksnap.io/photo/flowers-bouquet-CNEX3ZDN3G |
| `flo_3` | Flower Bouquet | Nature's Beauty | stocksnap | https://stocksnap.io/photo/flower-bouquet-AMPI6YOIXM |
| `flo_4` | Flowers Bouquet | Marina Pershina | stocksnap | https://stocksnap.io/photo/flowers-bouquet-SHXKTYF3C9 |
| `flo_hero` | Flower Bouquet | Tamara Menzi | stocksnap | https://stocksnap.io/photo/flower-bouquet-3RI84R6CYH |
| `war_1` | Satay at Dewi Sri in Rotterdam - Roland in NL (114) | roland | flickr | https://www.flickr.com/photos/35034347371@N01/275614969 |
| `war_2` | Chicken Satay and Shrimps at Bali Thai at Harbour Centre | roland | flickr | https://www.flickr.com/photos/35034347371@N01/73624995 |
| `war_3` | Satay at Indo Cafe | roland | flickr | https://www.flickr.com/photos/35034347371@N01/39418835 |
| `war_hero` | Grilling chicken satay | Jakub Kapusnak | rawpixel | https://www.rawpixel.com/image/447747/free-photo-image-grilling-grill-chicken-food-cart |

The QR code encodes the demo link `https://order.cefflo.com/kopi-kita`.

No CEFFLO screen is redrawn in HTML/CSS.

## CTA

The primary CTA is **Start free** and points to `https://vendor.cefflo.com/`.
iOS and Android are labelled **Coming soon** without fake store links.

## Not done here

The build copies this page, its images and its self-hosted fonts into the static
root. Serving it on `cefflo.com` remains a production deploy action that needs
Founder approval.
