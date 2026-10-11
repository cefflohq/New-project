# Storefront business templates (2026-10-11)

There are ten customer-facing storefront layouts, one for each type of business. They render through the shared public storefront engine:

- `store/templates.js`: layout
- `store/store.css`: styles, with the `bz-` shared system plus one prefix per template
- `store/store.js`: data, cart, checkout and the bottom dock

The Vendor App and Vendor Web preview the same code through `?embed=1`.

The Template Library order is `window.CEFFLO_TEMPLATE_ORDER`. It must match:

- the Vendor App registry (`apps/vendor_mobile/lib/ui/screens/storefront/templates/web/web_templates.dart`)
- the Vendor Web `TEMPLATES` list (`apps/vendor_web/js/pages/storefront.js`)

`tests/storefront_templates.test.mjs` checks that the three lists match.

The 18 earlier V1 templates are listed in `window.CEFFLO_TEMPLATE_LEGACY`. They are no longer offered in the library, but they still render for any storefront saved on one. In the library, such a storefront sees its template marked as active.

## Templates

| Key | Business | Structure, and why |
|---|---|---|
| `homefood` | Home-based food | A "today" card showing the date and hours, then meal rows (96px photo, description, price, inline quantity) grouped by category. Add-on dishes are a category of their own, and the product page offers them as "Add to your order". |
| `bakery` | Bakery & dessert | An editorial 4:5 hero, quiet collection tabs and a two-column gallery of tall 3:4 photos, set in a serif face. The product page leads with a 1:1 photo and shows an availability chip based on opening hours. |
| `eatery` | Restaurant & outlet | Menu search, sticky category tabs, a "Popular" strip and compact rows (text, 64px thumbnail, one-tap add). Built for people who already know what they want. |
| `cafe` | Cafe & beverage | A segmented category control and a three-across drink grid on soft stages with one-tap add. The product page centres the drink and shows a "You may also like" rail. |
| `catering` | Catering & corporate | A dark business-card header (area, hours), numbered package cards (wide image plus summary), and a scheduled-order note pointing to the delivery notes field. |
| `frozen` | Frozen & ready-to-cook | A bulk catalogue: search, tabs, and bordered two-up cards with the quantity always visible. The product page has a "Product information" panel, taken from the description. |
| `florist` | Florist & gift | A full-bleed editorial hero, occasions (categories) as photo tiles, one large 4:5 photo per gift, and serif type. |
| `laundry` | Laundry & services | Service area and hours cards, then a grouped price list in which each row states what the price covers (from the description) and has a quick add. |
| `retail` | Retail & local products | A centred logo and tagline, a banner, a numbered bestseller rail, underline collection tabs and a bordered square grid. The product page has a thumbnail gallery. |
| `outlets` | Multi-outlet SME | A brand band, a "Serving" location card (business area plus hours), and a category rail beside a grid on wide screens (chips on phones). |

## Shared components (all ten)

- **Engine:** routes, cart, checkout, done screen, the closed-store note, and the pinned bottom dock on product pages, cart and checkout.
- **`bz-` system:** logo mark (vendor logo or initials), icon buttons, product-page bar, thumbnails, and the `+` control that becomes `− n +` once the item is in the cart.
- **Shared context helpers:** `c.img` (photo, or cut-out on templates marked `cutout`), `c.hero`, `c.logo`, `c.searchInput`, `chips`, and `groups` (products grouped by category).
- **Theme:**
  - `--accent` is used for actions.
  - `--accent2` is used for soft panels.
  - `--bg` is used for the page.
  - Surfaces stay white and neutral.

## What the templates do not show

Cefflo's product and order model does not yet have the following, so no template shows them:

- variants (size, flavour, sugar or ice)
- priced add-ons
- preorder, event or pickup dates
- pax or minimum order
- pack sizes or weights
- branches or branch-specific stock
- repeat-order history

The only free-text channel on an order is `p_delivery_notes`. The catering template points customers to it for event dates.

## Vendor customisation

Vendors can change the following:

- template
- logo (`theme.logo_path`, `{business}/logo-<uuid>`, added in 20261011120000)
- brand and second colour
- tagline
- hero image

Checkout, delivery zones and delivery rules are not part of the theme, and templates cannot change them.

Saving (Apply) updates the live storefront straight away when it is published, because there is no separate draft. Vendor Web shows a note about this next to the Apply button. Until Apply, the preview shows unsaved changes.
