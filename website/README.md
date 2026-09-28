# CEFFLO Public Website — homepage

Static, dependency-free homepage (`index.html` + `img/`), Bahasa Melayu.

## Authority

- Visual direction and structure: `CEFFLO_PUBLIC_WEBSITE_MASTER.md` (Founder-supplied),
  §38–§42.
- Pricing: `docs/cefflo/sot/10_PRICING.md`, locked by the Founder on 2026-09-28
  (`docs/cefflo/05_DECISIONS.md` D-73). Only values that file lists as locked appear.
- Colours: canonical Vendor Mobile tokens (`apps/vendor_mobile/lib/core/theme.dart`, D-70).
- Product claims: `docs/cefflo/sot/01_PRODUCT_TRUTH.md` and the Claims Registry.

## Product imagery

Phone images (`*_ph`) are captured at the iPhone 15 app area (393 × 764 pt, @3x)
and extended with the app's own top and bottom edge colour for the status bar
and home-indicator areas. The page draws the iPhone 15 frame, Dynamic Island,
status bar and home indicator around them. Card crops use the earlier 390 pt
captures.

Every screen in `img/` is an unaltered capture of a canonical app on
`claude/canonical-integration`, run in its prototype/demo mode:

| File | Source |
|---|---|
| `v11_ph`, `v12_ph`, `v16_ph`, `v17_ph`, `v19_ph` | Vendor Mobile `/audit/V11`, `V12`, `V16`, `V17`, `V19` (phone frames) |
| `v12`, `v17`, `v14_top`, `v20_top`, `v11_attn` | Vendor Mobile `V12`, `V17`, `V14` (top crop), `V20` (top crop), `V11` (Need Attention crop) |
| `d19_ph`, `d21_ph`, `d23_ph` | Cefflo Driver `?screen=D19`, `D21`, `D23` (phone frames) |
| `d20`, `d23` | Cefflo Driver `D20`, `D23` (card crops) |
| `c_done_ph`, `c_way_top` | Customer Tracking `?state=delivered` (phone frame), `?state=on_the_way` (status crop) |

Crops are deliberate:

- `v14_top` omits the demo "Recent Imports" list. It shows Google Sheets / Drive
  as connected, and connected spreadsheet intake is not live.
- `c_way_top` omits the precise arrival time and the illustrative map. The site
  must not show a precise ETA or GPS map.

No CEFFLO screen is redrawn in HTML/CSS.

## CTA

The primary CTA is downloading the Vendor app. The store URLs live in the `STORE`
constant at the bottom of `index.html`. While they are empty, the badges read
"Akan datang di …" and scroll to the download section.

## Not done here

This directory is not wired into `scripts/build-static.mjs` or `vercel.json`.
Serving it on `cefflo.com` is a production DNS/deploy action that needs Founder
approval.
