**Status:** CANONICAL — v1.4, amended 2026-09-23 by Founder decision D-45 (Vendor Mobile gradient-header visual system; supersedes §8's flat-white header and Yellow active navigation, and the Yellow "active navigation state" use in §1.1). Previously v1.3, amended 2026-09-19 by Founder decision D-40. D-33/D-34/D-35 remain the palette, semantic-colour, surface-principle and production-logo authorities; D-40 supersedes D-33 only for app typography and the mandatory status of its historical exact compact-token values.
**Implementation boundary:** FG-ENG-02 authorizes the isolated DEV/STAGING baseline integration recorded by D-40. It does not authorize visual retuning, Driver build-out, Vendor V11 execution, production deployment, or any later Engineering gate.

---

# CEFFLO — EXPERIENCE SYSTEM (VISUAL DNA)
**Version:** 1.3 — 2026-09-19 (FG-ENG-02 amendments, D-40)
**Owner:** Founder
**Scope:** How CEFFLO products look. Product/behaviour truth remains governed separately by `01_PRODUCT_TRUTH.md`, `02_ARCHITECTURE.md`, and the relevant product SOT.

## 0. Relationship to prior brand doctrine

Extends `05_BRAND_BRAIN.md` and `06_BRAND_ASSETS_GOVERNANCE.md` with implementation-level detail. Supersedes `06_BRAND_ASSETS_GOVERNANCE.md` §2's Signal Lime lock specifically — see that file's own in-place annotation. Brand character, voice, logo geometry, and the "near-black text on bright accent" accessibility principle from those documents remain in force, carried forward here.

## 1. Brand palette — LOCKED

| Token | Hex | Status |
|---|---|---|
| **CEFFLO Yellow** | `#FEC819` | **LOCKED — primary brand/action accent.** Verified: 11.4:1 contrast with near-black foreground text — comfortably exceeds WCAG AA at any size (§13). |
| **Navy** | `#12213E` | **LOCKED — dark anchor**, used selectively (brand moments, one status/hero surface per screen) — never permanent chrome. |
| **Workspace** | `#F7F8FA` | **LOCKED — light app background.** |
| **Surface** | `#FFFFFF` | **LOCKED — card white**, matches existing "Fresh White." |
| ~~Signal Lime~~ | ~~`#C7F000`~~ | **RETIRED as current primary/signature colour** (superseded, D-33). Historical record preserved at D-30 and in `06_BRAND_ASSETS_GOVERNANCE.md`'s own annotated history — not deleted, no longer current authority. |

### 1.1 Usage principle
CEFFLO Yellow is a controlled brand/action signal, never a surface colour. Used for: primary CTA, selected state, small brand accent, important action emphasis. (Active navigation state is CEFFLO Blue since D-45 — see §8; Yellow is an ACTION colour, not a navigation colour.) Never: permanent background chrome, a card background, decorative scatter, or a semantic-status substitute.

### 1.2 Accessibility
Near-black foreground text (`#181818` or `#000000`, both verified — §13) on CEFFLO Yellow controls. Never white text on the accent.

## 2. Semantic palette — LOCKED, with accessibility adjustments made and documented

The Founder-confirmed candidates from the prior review round were contrast-checked against white Surface (§13) before lock. Two of the three needed a small, hue-preserving adjustment to clear WCAG AA for normal text (4.5:1) — documented here in full, nothing silently changed:

| Token | Founder-confirmed candidate | **Locked value** | Adjustment made |
|---|---|---|---|
| **Attention / Error** | `#D8402F` (4.47:1 on white — just under AA) | **`#D73C2B`** | Minimal — 1% lightness reduction, same hue/saturation. Now 4.59:1. |
| **Success** | `#2FAE5E` (2.86:1 on white — real failure, below even the lenient UI/large-text threshold) | **`#248648`** | Deepened — 10% lightness reduction, same hue family (still unambiguously the same green). Now 4.59:1. This was the one candidate that genuinely needed a visible shift; bright mint-greens are a well-known contrast failure mode on white and a deeper green is the standard fix, not a novel choice. |
| **Route / Info** | `#3D7BEE` (3.99:1 on white — under AA) | **`#2A6EEC`** | Moderate — 4% lightness reduction, same hue/saturation. Now 4.63:1. |

**Constraint carried forward unchanged from the Founder's own instruction:** these are semantic operational colours only, never secondary CEFFLO brand colours. Route/Info in particular must never be used for emphasis, selection, or CTA purposes. CTAs belong to CEFFLO Yellow; navigation/selection emphasis belongs to the separate **CEFFLO Blue** brand token (§8, D-45), never to Route/Info.

**One narrow, disclosed residual gap:** on the low-opacity status-chip tint background (§7.2) these three land at 3.97–4.03:1 — short of the strict 4.5:1 normal-text threshold, though above the 3:1 UI-component/large-text threshold that applies to small bold chip labels under WCAG 1.4.11. Judged acceptable for chip use as-is; flagged rather than silently accepted. On dark surfaces specifically, all three land near 3.5:1 (§13) — acceptable for the UI-component threshold, not yet at full text-contrast — this is called out again in §3 as part of the still-open dark-mode fine-tuning, not blocking this light-mode-focused lock.

### 2.1 Warning — LOCKED 2026-09-11 (Founder Gate 0, D-34)

Closes the gap the implementation reconciliation audit found: no canonical Warning token existed even though the live Vendor client already had one. Recovered from real, already-shipped product evidence rather than invented — `vendor/index.html` and `invite/index.html` had already independently solved the text-contrast problem for one use case (the owner-access warning banner) without the fix ever reaching the token itself; this lock generalizes what was already correct.

| Role | Hex | Evidence / contrast |
|---|---|---|
| **Fill / icon** | `#F59E0B` | Unchanged from existing product usage. Fine as a fill with near-black foreground on top (8.27:1) — the failure mode was always text-on-light, not the fill itself. |
| **Text-on-tint, Light** | `#9A6700` | Adopted directly from the existing, already-shipped owner-warning banner in `vendor/index.html` and `invite/index.html`. 4.54:1 on the Warning tint, 4.87:1 on Surface — both PASS. The existing `--warning` token used directly as chip text (`#F59E0B` on `#FFF6E5`, 2.00:1) is a real, currently-shipped accessibility failure this correction fixes. |
| **Tint, Light** | `#FFF6E5` | Unchanged, already proven. |
| **Text-on-tint, Dark** | `#F5A524` | Adopted from `rider/index.html`'s existing dark-mode `--warning` value — already correct (9.65:1 on dark canvas, 7.96:1 on dark surface). Confirms the general principle that a semantic hue's *lightness direction* inverts between Light and Dark text roles, same pattern already established for the other semantic colours. |

**`#935C08`** (a third value found in `rider/index.html`, used only as a solid toast-notification background with white text) **is explicitly not promoted to a general canonical token.** It remains a component-specific choice for that one toast role only, documented here so it isn't mistaken for an orphaned/unauthorized colour during future audits — not because it fails accessibility (it passes, 5.56:1), but because no case was made for it beyond that single component.

## 3. Light / Dark mode

### 3.1 Light Mode surface hierarchy (bottom → top) — LOCKED
1. Workspace `#F7F8FA` — base canvas.
2. Surface `#FFFFFF` (cards) — separated via a restrained hairline border + subtle two-layer soft shadow (§5A).
3. Navy `#12213E` — selective raised surface (filled people avatars, dark accents). The raised brand surface for chrome, heroes and in-body hero panels is the Brand gradient (§8, D-45).
4. CEFFLO Yellow — top-layer accent only, never a surface.

### 3.2 Dark Mode — architecture APPROVED, exact values remain a follow-up pass
Three-level stack approved as the basis: **Dark Canvas → Dark/Tinted Surface → Navy raised/anchor surface.**

| Token | Value | Status |
|---|---|---|
| Dark canvas | `≈#0A0B0D` | Approved direction. Verified: existing dark text tokens (`#F4F6F8`/`#AFB6BD`) both pass AA comfortably against it (18.2:1 / 9.6:1 — §13). |
| Dark surface | `≈#1A2030` | Approved direction, navy-tinted rather than neutral grey. Existing dark text tokens pass AA against it too (15.0:1 / 7.9:1). |
| Navy anchor | `#12213E` | Same locked value as light mode — now the most-raised, most-saturated surface in the dark stack, solving the original "blends into canvas" problem. |
| CEFFLO Yellow in dark mode | `#FEC819` | Verified: 12.65:1 against dark canvas — stays fully legible and doesn't need a dark-mode-specific variant. |

**What is NOT yet final, and why this doesn't block the rest of this lock:** the semantic colours (§2) land around 3.5:1 against the dark surface — acceptable for UI components, not yet at full text contrast. Dark mode itself has no shipped screens to apply this to yet (§10) — this is flagged as the one specific, narrow follow-up item for whoever does the first real dark-mode implementation pass, not a reason to withhold the rest of this canonicalization. **Do not treat the dark-mode numbers above as final production values** — they are the approved *relationship*, contrast-checked for the core surface/text/accent combinations, with one disclosed semantic-on-dark gap still open.

## 4. Typography — LOCKED BY D-40

**Inter is the primary CEFFLO app UI typeface**, including Vendor Mobile and
future Driver Mobile work. The Vendor implementation bundles Inter locally and
retains Noto Sans SC/Tamil for validated multilingual fallback coverage.
Manrope is historical direction from D-33 and is no longer active runtime
truth. Tabular numerals should use the active font's numeral features rather
than introducing a separate default monospace family.

IBM Plex Sans and Public Sans remain documented alternatives from the evaluation (§4, prior revision) — not rejected, not canonical, retained for reference only.

### 4.1 Scale
Preserve the latest valid implementation during baseline integration. Exact
sizes, weights and tracking remain subject to reference-based validation at
FG-ENG-03; do not force the historical D-33 scale across the product without
that evidence.

### 4.2 Line heights
1.2 titles/display, 1.4–1.5 body/secondary text, 1.3 labels/chips.

## 5. Surface system — PRINCIPLES LOCKED; EXACT COMPACT VALUES PENDING FG-ENG-03

Keep compact operational surfaces and accessible tap targets. D-40 removes the
historical `12 / 13 / 11 / 20 / 60 / 14` sequence as mandatory current truth.
The selected Vendor baseline currently uses a 20px gutter, 16px card padding,
12px card gap, 22px section gap and 64px chrome; these are implementation
evidence, not a new global lock. Preserve them safely until exact values are
validated against a Founder-approved reference at FG-ENG-03.

### 5.1 Radius
Buttons remain pill-shaped. The selected Vendor implementation's 18px
card/input radius is retained as baseline evidence. Exact card/input radius is
not visually locked until FG-ENG-03.

## 5A. Shadow/elevation — LOCKED

**Restrained border + subtle two-layer soft shadow**, validated visually against both Vendor and Rider boards (Phase 04 visual validation). Not zero-shadow (too flat against Workspace/Surface's close lightness values, under-delivers the "mature surface hierarchy" direction). Not heavy elevation (fights CEFFLO's compact/operational character). Concretely: a lightened 1px border plus a tight near-layer (1–2px, <10% opacity) and a wider diffuse layer (~12–16px, <10% opacity), both Navy-tinted rather than pure black.

## 6. Iconography — LOCKED (unchanged)

Lucide, outline style, 22px visual size in a 44px tap target. No icon containers, tiles, or decorative backgrounds.

## 7. Components

### 7.1 Cards — LOCKED
White surface (dark: navy-tinted dark surface, §3.2), current implementation
radius, lightened border + soft shadow (§5A), accent-colour border when selected.

### 7.2 Status chips — LOCKED pattern (amended D-45)
Small pill, never solid fill. Default: neutral grey label on a light grey fill (ordinary list statuses). Semantic: semantic-coloured text (§2 locked values) on a ~12% tint where the state must stand out. Never the Yellow accent. See §8 for the hero variant.

### 7.3 Buttons — LOCKED pattern
Pill radius. Primary: solid CEFFLO Yellow fill, near-black text. Secondary: outline/neutral fill, same pill radius. Only one Yellow-filled primary action per screen.

### 7.4 Inputs — LOCKED pattern, component itself still to be built
Rectangular and matching cards; exact radius pending FG-ENG-03.

### 7.5 Sheets/dialogs, list rows, loading/empty/error/blocked/retry/offline states
Still genuinely missing from any audited implementation — not proposed here, real unfilled scope for the next execution stage.

### 7.6 KPI blocks — LOCKED (amended D-45)
One `KpiStrip`: equal columns of value + label (optional CEFFLO Blue icon) separated by hairline dividers, drawn directly on the white surface. The former navy summary panel and `KpiTile` are retired.

## 8. App chrome and navigation — LOCKED BY D-45 (Vendor Mobile)

~~Bottom navigation … CEFFLO Yellow marks the active tab only. Header: flat white/chrome, no accent underline.~~ **RETIRED by D-45 (2026-09-23).** There is no longer a flat-white authenticated header and Yellow is no longer the active-navigation colour. The Founder's gradient-header reference set is the canonical visual source; this section is its written form.

**Brand tokens added by D-45**
| Token | Value | Use |
|---|---|---|
| **CEFFLO Blue** | `#0B5FE3` | Active bottom-nav item + indicator, active tab label + underline, form-section icons, detail-row icons, inline links. Distinct from semantic Route/Info. |
| CEFFLO Blue tint | `#EAF2FF` | Accent icon discs (zone/location rows), tinted secondary action rows. |
| **Brand gradient** | linear `#0633A8 → #0848CC → #0A6BE6` (lower-left → upper-right) + radial cyan glow `#18A6FF` at the upper right | The ONE gradient: app chrome behind the header and status bar, detail heroes, in-body hero panels. Implemented once (`BrandBackdrop`). |
| Grouped page tone | `#F4F6FA` | Page behind grouped settings cards. |
| Text | primary `#0F1A36` (dark navy), secondary `#6B7489` (cool grey) | All app text on white. |

**Edge-to-edge system UI (mandatory)**
- Status bar and system navigation/gesture bar are always transparent; the app never paints its own status-bar or gesture-area strip.
- On gradient-header screens the same gradient continues behind the clock/signal/battery area — no seam.
- At the bottom, whatever app surface is underneath continues behind the gesture area: the white bottom navigation, or (without nav) the white content surface.
- Implemented once at the root (shell + `CefSystemBars`), never per screen.

**Header system** (one shell implementation, three variants)
1. Top-level (Today, Orders, Zones, Riders, Menu): large white title (28/700), white actions (search, filter, add, notifications), no back arrow.
2. Back-navigation: white back arrow + white title (auto-fits long titles, 28→20, never ellipsized at normal sizes).
3. Detail hero: white back arrow + centred white title; the identity (large avatar, name, status pill, meta) sits on the gradient.

**Content surface**: white surface enters below the gradient with 24px rounded top corners and runs to the bottom edge. Prefer dividers and spacing over nested cards; cards only where a group genuinely needs a container (grouped settings, info panels).

**Bottom navigation**: Today · Orders · Zones · Riders · Menu. White surface, hairline top border. Active = CEFFLO Blue filled icon + blue label + short blue indicator bar. Inactive = cool-grey outline icon + label. Page content never scrolls beneath it; it hides while the keyboard is open and on focused flows / detail heroes.

**Status pills**: neutral grey pill (grey label on a light grey fill) for ordinary list statuses; semantic tint only where the state must stand out (Issue red, Delivered green on Today, success/warning where relevant). On a detail hero: white pill with a semantic dot.

## 8A. Vendor Mobile screen archetypes — LOCKED BY D-45

Every Vendor Mobile screen is derived from one of these; no screen invents another visual system.

| | Archetype | Canonical reference | Composition |
|---|---|---|---|
| A | Today / Overview | Overview | Top-level header + bell; KPI strip (value + label, hairline column dividers) on white; Recent Delivery rows (avatar, green Delivered pill + time, chevron); Need Attention row. |
| B | Operational tabbed list | Orders | Top-level header with search/add; blue underline tabs; rows with grey icon disc, title, one-line subtitle, neutral pill, no chevron. |
| C | Zones list | Zones | As B with a blue-tinted location disc. |
| D | People list | Riders | As B with navy filled initials avatar. |
| E | Detail hero | Rider Detail | Deep gradient hero with large avatar, name, status pill, meta; white surface with icon stat strip, then blue-icon information rows. No bottom nav. |
| F | Menu / Settings | Settings | Grouped page tone; muted group labels; white rounded group cards; grey icon discs; inset dividers; chevrons. |
| G | Multi-section operational form | New Order | Back-nav header; sections with a blue icon + title + subtitle, divided by hairlines; shared fields; tinted blue secondary action rows; one yellow CTA. |
| H | Product / content form | Add Product | Back-nav header; dashed upload area; sectioned fields; availability switch row; yellow CTA; bottom nav. |

Authentication keeps its full-screen blue Sign In composition (also in the reference set); secondary auth screens use the same backdrop with a white sheet.

**Shared component rule**: one concept = one component (Flutter `lib/ui/widgets.dart` + `lib/ui/shell.dart`): `BrandBackdrop`, `ContentSurface`, `HeroPage`/`DetailHero`/`HeroStatusPill`, `KpiStrip`, `SegmentedTabs`, `CefListRow` (+`IconDisc`, `CefAvatar`), `CefListGroup`, `SectionHeading`, `CefField`, `CefSearchField`, `CefButton`, `CefActionRow`, `StatusChip`, `CefChoiceChip`, `CefSwitch`. Screens never declare their own gradients, headers, colours or type sizes.

## 9. Brand mark and header text usage — LOCKED

**Master logo/wordmark** — the real, unaltered asset (`docs/cefflo/brand/assets/logo/`), never redrawn, approximated, regenerated, or reinterpreted — belongs to genuine brand moments: splash, authentication, onboarding, appropriate external brand surfaces. **Never repeated on normal internal operational screens** (Dashboard, Orders, Zones, Riders, Menu, and Rider equivalents).

**Business/store name text** (distinct from the logo) may appear contextually where useful — explicitly including Today/Dashboard — but is not mandatory global header branding. Evaluated screen-by-screen against whether it does real operational work there.

**Master logo geometry does not change.** Its presentation context with Navy is resolved 2026-09-11 (D-35): the Founder supplied an updated production asset set with the arrow recoloured to CEFFLO Yellow and the icon's background moved to Navy — `docs/cefflo/brand/assets/logo/cefflo-logo-icon-navy.png` (app/icon), `cefflo-logo-mark.png` (standalone, transparent), `cefflo-logo-primary.png` (mark + wordmark, transparent), `cefflo-logo-wordmark.png` (wordmark-only, transparent). Full detail: `06_BRAND_ASSETS_GOVERNANCE.md` §5/§15.

## 10. Flutter implementation baseline — D-40

`apps/vendor_mobile/` is now part of the isolated Engineering baseline. Its
lifecycle state is **IMPLEMENTED / INTEGRATION IN PROGRESS / UI NOT YET LOCKED /
DEV-STAGING**. It is substantial working implementation evidence, not a
production-ready claim. V-50–V-54 remain HOLD and are excluded from active
routes/navigation.

`codex/cefflo-vendor-flutter-prototype` remains de-prioritized as forward evidence (heavier Lime usage, older naming scheme) — not deleted, not acted on here.

No active Driver Flutter implementation exists in this baseline. The obsolete
R-01–R-33 scaffold is excluded; the newer D-series authority governs future
Driver work under a separate gate.

## 11. Vendor / Rider scoping

Shared principles (§1–§9) apply to both surfaces. Vendor has the DEV/STAGING
implementation described in §10; Driver remains unimplemented in this baseline.

## 12. Preview / evidence format

Portrait 9:16 board, 2×2 grid of equal flat screens, no device frame, no perspective, light mode shown first, clean neutral presentation background.

---

## 13. Accessibility / contrast validation record

Computed via WCAG 2.1 relative-luminance contrast ratio, checked 2026-09-11 before lock:

| Pair | Ratio | Result |
|---|---|---|
| Near-black `#181818` text on CEFFLO Yellow `#FEC819` | 11.41:1 | PASS (AA, any size) |
| Pure black `#000000` text on CEFFLO Yellow | 13.49:1 | PASS |
| White text on Navy `#12213E` | 16.00:1 | PASS |
| Dark-mode label `#E2E5E9` on Navy | 12.66:1 | PASS |
| Text `#181818` on Workspace `#F7F8FA` | 16.71:1 | PASS |
| Secondary text `#454545` on Workspace | 9.02:1 | PASS |
| Text `#181818` on Surface `#FFFFFF` | 17.76:1 | PASS |
| Secondary text `#454545` on Surface | 9.59:1 | PASS |
| Dark textPrimary `#F4F6F8` on dark canvas `#0A0B0D` | 18.17:1 | PASS |
| Dark textSecondary `#AFB6BD` on dark canvas | 9.61:1 | PASS |
| Dark textPrimary on dark surface `#1A2030` | 14.99:1 | PASS |
| Dark textSecondary on dark surface | 7.93:1 | PASS |
| CEFFLO Yellow on dark canvas (as surface/accent) | 12.65:1 | PASS |
| Attention `#D8402F` on white (pre-adjustment) | 4.47:1 | Marginal FAIL → adjusted to `#D73C2B`, 4.59:1 PASS |
| Success `#2FAE5E` on white (pre-adjustment) | 2.86:1 | Real FAIL → adjusted to `#248648`, 4.59:1 PASS |
| Route/Info `#3D7BEE` on white (pre-adjustment) | 3.99:1 | FAIL (normal text) → adjusted to `#2A6EEC`, 4.63:1 PASS |
| Locked semantic values on chip-tint backgrounds | 3.97–4.03:1 | Below 4.5 normal-text, above 3.0 UI/large-text — accepted for chip use, disclosed |
| Locked semantic values on dark surface `#1A2030` | ~3.5:1 | Above UI threshold, below full text threshold — disclosed, open follow-up for dark-mode implementation |
| Warning `#F59E0B` fill with near-black text | 8.27:1 | PASS — fine as fill, not as light-mode text |
| Warning text-on-tint (pre-correction) `#F59E0B` on `#FFF6E5` | 2.00:1 | Real FAIL (currently shipped) → corrected to `#9A6700`, 4.54:1 PASS |
| Warning `#9A6700` on Surface | 4.87:1 | PASS |
| Warning Dark text `#F5A524` on dark canvas/surface | 9.65:1 / 7.96:1 | PASS |

No adjustment materially changed any hue's identity — every adjustment was a lightness-only shift within the same hue/saturation family, smallest value that cleared the threshold.

## 14. Status

**LOCKED.** Remaining open items, none of which block this canonicalization:
1. Semantic colour legibility on dark surfaces specifically (§2, §3.2) — narrow, disclosed, deferred to the first real dark-mode implementation pass.
2. Exact final dark-mode production values — architecture and relationship approved; final numbers get one more look when dark-mode screens are actually built.
3. Exact Vendor typography scale, compact spacing and radius values — pending
   reference-based validation at FG-ENG-03. Driver Flutter build-out remains a
   separately authorized future stage.

Resolved by v1.1 (D-34): the Warning semantic token gap is closed (§2.1).

Resolved by v1.2 (D-35): §9's deferred "presentation context with Navy" item is closed — the master logo production asset set now includes a Navy-background icon variant and Yellow-arrow transparent variants.

Resolved by v1.3 (D-40): Inter is current app UI typography; historical exact
compact-token values are no longer mandatory; Vendor Mobile is integrated as a
DEV/STAGING baseline with UI lock deferred to FG-ENG-03.
