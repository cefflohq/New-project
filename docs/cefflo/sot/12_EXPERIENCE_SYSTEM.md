**Status:** CANONICAL — v1.1, locked 2026-09-11 by Founder decision `docs/cefflo/05_DECISIONS.md` D-33 (palette/typography/surface system) and D-34 (Warning semantic token, Founder Gate 0). This is the single visual implementation authority for Vendor Web/Desktop, Vendor Flutter, Rider Flutter, and future CEFFLO product surfaces. It supersedes `docs/cefflo/05_DECISIONS.md` D-30 **only where D-30 named Signal Lime as the current primary/signature colour** — D-30 itself is preserved unedited as the historical record of that earlier decision; nothing here rewrites it.
**Implementation boundary — read this before doing anything with it:** this document is documentation/SOT canonicalization only. It does **not** authorize Flutter palette migration, Vendor screen redesign, Rider Flutter build-out, backend changes, or merging `claude/vendor-mobile-backend-integration`. Those are separate, later, not-yet-authorized execution stages.

---

# CEFFLO — EXPERIENCE SYSTEM (VISUAL DNA)
**Version:** 1.1 — 2026-09-11 (Warning semantic token added, D-34)
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
CEFFLO Yellow is a controlled brand/action signal, never a surface colour. Used for: primary CTA, active navigation state, selected state, small brand accent, important action emphasis. Never: permanent background chrome, a card background, decorative scatter, or a semantic-status substitute.

### 1.2 Accessibility
Near-black foreground text (`#181818` or `#000000`, both verified — §13) on CEFFLO Yellow controls. Never white text on the accent.

## 2. Semantic palette — LOCKED, with accessibility adjustments made and documented

The Founder-confirmed candidates from the prior review round were contrast-checked against white Surface (§13) before lock. Two of the three needed a small, hue-preserving adjustment to clear WCAG AA for normal text (4.5:1) — documented here in full, nothing silently changed:

| Token | Founder-confirmed candidate | **Locked value** | Adjustment made |
|---|---|---|---|
| **Attention / Error** | `#D8402F` (4.47:1 on white — just under AA) | **`#D73C2B`** | Minimal — 1% lightness reduction, same hue/saturation. Now 4.59:1. |
| **Success** | `#2FAE5E` (2.86:1 on white — real failure, below even the lenient UI/large-text threshold) | **`#248648`** | Deepened — 10% lightness reduction, same hue family (still unambiguously the same green). Now 4.59:1. This was the one candidate that genuinely needed a visible shift; bright mint-greens are a well-known contrast failure mode on white and a deeper green is the standard fix, not a novel choice. |
| **Route / Info** | `#3D7BEE` (3.99:1 on white — under AA) | **`#2A6EEC`** | Moderate — 4% lightness reduction, same hue/saturation. Now 4.63:1. |

**Constraint carried forward unchanged from the Founder's own instruction:** these are semantic operational colours only, never secondary CEFFLO brand colours. Route/Info in particular must never be used for emphasis, selection, or CTA purposes — those belong to CEFFLO Yellow alone.

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
3. Navy `#12213E` — selective raised surface (status/hero cards, auth screen).
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

## 4. Typography — LOCKED

**Manrope is the primary CEFFLO product typeface**, for both display and body use. No separate monospace family is used as a default — tabular (lining) numerals come from Manrope's own numeral set wherever digits stack in a column (KPI tiles, earnings, distance/duration/time fields, order counts), enabled via font-feature settings, not a second typeface.

IBM Plex Sans and Public Sans remain documented alternatives from the evaluation (§4, prior revision) — not rejected, not canonical, retained for reference only.

### 4.1 Scale (unchanged from prior revision)
Page/section title 18/600 (−0.2 tracking) · Card primary 16/600 · Card secondary 15/600 · Body/supporting 14/500 · Small body 13/500 · Label 14/600 · KPI/display 29/600 (−0.8 tracking).

### 4.2 Line heights
1.2 titles/display, 1.4–1.5 body/secondary text, 1.3 labels/chips.

## 5. Surface system — LOCKED

Compact operational surfaces. Spacing values preserved from the validated Founder Gate Matrix where they form part of the coherent system (screen gutter 12px, card padding 13px, card-to-card gap 11px, section gap 20px, base steps 4/8/12/16px, header/bottom-nav height 60px, icon 22px visual in a 44px tap target) — these are accessibility-driven or industry-standard 4pt-grid choices with no dependency on the retired Lime palette, re-justified independently rather than defaulted.

### 5.1 Radius — LOCKED
Card radius **14px**. Buttons **pill (999px)** — reference-informed, validated visually. Inputs **14px** (rectangular, matches card radius — not pill, reads more precise/operational).

## 5A. Shadow/elevation — LOCKED

**Restrained border + subtle two-layer soft shadow**, validated visually against both Vendor and Rider boards (Phase 04 visual validation). Not zero-shadow (too flat against Workspace/Surface's close lightness values, under-delivers the "mature surface hierarchy" direction). Not heavy elevation (fights CEFFLO's compact/operational character). Concretely: a lightened 1px border plus a tight near-layer (1–2px, <10% opacity) and a wider diffuse layer (~12–16px, <10% opacity), both Navy-tinted rather than pure black.

## 6. Iconography — LOCKED (unchanged)

Lucide, outline style, 22px visual size in a 44px tap target. No icon containers, tiles, or decorative backgrounds.

## 7. Components

### 7.1 Cards — LOCKED
White surface (dark: navy-tinted dark surface, §3.2), 14px radius, lightened border + soft shadow (§5A), accent-colour border when selected.

### 7.2 Status chips — LOCKED pattern
Small pill, semantic-coloured text (§2 locked values) on a ~12% tint of the same colour, never solid fill. Semantic palette only, never the brand accent.

### 7.3 Buttons — LOCKED pattern
Pill radius. Primary: solid CEFFLO Yellow fill, near-black text. Secondary: outline/neutral fill, same pill radius. Only one Yellow-filled primary action per screen.

### 7.4 Inputs — LOCKED pattern, component itself still to be built
14px radius, matching cards.

### 7.5 Sheets/dialogs, list rows, loading/empty/error/blocked/retry/offline states
Still genuinely missing from any audited implementation — not proposed here, real unfilled scope for the next execution stage.

### 7.6 KPI blocks — LOCKED (unchanged)
Existing `KpiTile` pattern, 29/600 display size.

## 8. Navigation — LOCKED

Bottom navigation: white background, neutral inactive icon/label, CEFFLO Yellow marks the active tab only. Header: flat white/chrome, no accent underline.

## 9. Brand mark and header text usage — LOCKED

**Master logo/wordmark** — the real, unaltered asset (`docs/cefflo/brand/assets/logo/`), never redrawn, approximated, regenerated, or reinterpreted — belongs to genuine brand moments: splash, authentication, onboarding, appropriate external brand surfaces. **Never repeated on normal internal operational screens** (Dashboard, Orders, Zones, Riders, Menu, and Rider equivalents).

**Business/store name text** (distinct from the logo) may appear contextually where useful — explicitly including Today/Dashboard — but is not mandatory global header branding. Evaluated screen-by-screen against whether it does real operational work there.

**Master logo geometry does not change.** Reconciling its presentation context with Navy (e.g. background colour behind it) remains deferred to the implementation stage, not performed here.

## 10. Flutter implementation baseline — evidence status only, no migration authorized

`claude/vendor-mobile-backend-integration` (`apps/vendor_mobile/`) remains the confirmed leading Vendor Flutter implementation evidence. **This canonicalization does not authorize merging that branch, migrating its tokens, or any other implementation change to it.** Token migration is a distinct, separately-authorized future execution stage.

`codex/cefflo-vendor-flutter-prototype` remains de-prioritized as forward evidence (heavier Lime usage, older naming scheme) — not deleted, not acted on here.

**No Rider Flutter implementation exists anywhere in the repository.** This document is now the visual authority Rider Flutter will build against once that work is authorized — nothing has been built yet.

## 11. Vendor / Rider scoping

Shared rules (§1–§9) apply to both surfaces. Vendor has real implementation evidence to reconcile against later (§10); Rider has none yet.

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
3. Flutter token migration, Vendor screen work, Rider Flutter build-out — all explicitly out of scope for this canonicalization, belong to the next authorized execution stage.

Resolved by v1.1 (D-34): the Warning semantic token gap is closed (§2.1).
