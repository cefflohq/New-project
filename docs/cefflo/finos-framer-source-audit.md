# Finos Framer Source — Full Visual System Audit

**Read-only.** Every value below was read directly from the live, connected Framer project via `framer.agent.*` calls — not the public site, not screenshots. No `applyChanges` or `publish` call was made; nothing in Finos-copy was modified. Prepared as design-research input for a future, unrelated product (Cefflo).

**Evidence tags used throughout:**
- `VERIFIED` — read directly via `framer.agent.*` (node attributes, rects, controls, or variant lists)
- `INTERPRETATION` — a conclusion drawn from combining two or more verified values
- `NOT ACCESSIBLE` — not exposed by the queried attribute path, or not sampled in this pass

| | |
|---|---|
| **Project** | Finos (copy) |
| **Source** | Framer Agent API |
| **Session** | #1 · live |
| **Pages mapped** | 12 |
| **Components read** | 42 + 4 code |
| **Breakpoints** | Desktop / Tablet / Phone |
| **Modifications made** | None |

---

## Contents

1. [Executive Summary](#1-executive-summary)
2. [Project Architecture](#2-project-architecture)
3. [Global Design Tokens](#3-global-design-tokens)
4. [Typography System](#4-typography-system)
5. [Color System](#5-color-system)
6. [Spacing & Layout System](#6-spacing--layout-system)
7. [Desktop System](#7-desktop-system)
8. [Tablet System](#8-tablet-system)
9. [Phone System](#9-phone-system)
10. [Navigation System](#10-navigation-system)
11. [Button System](#11-button-system)
12. [Card System](#12-card-system)
13. [Product Presentation System](#13-product-presentation-system)
14. [Home Section-by-Section Audit](#14-home-section-by-section-audit)
15. [Motion & Interaction System](#15-motion--interaction-system)
16. [Responsive Transformation Matrix](#16-responsive-transformation-matrix)
17. [Finos Visual Grammar](#17-finos-visual-grammar)
18. [Reusable Principles & Finos-Specific Elements](#1819-reusable-principles--finos-specific-elements)
19. [Agent / API Limitations](#20-agent--api-limitations)
20. [Source Evidence Summary](#21-source-evidence-summary)
21. [Recommended Translation Rules for a Future Cefflo Design System](#22-recommended-translation-rules-for-a-future-cefflo-design-system)

---

## 1. Executive Summary

Finos is built on a genuinely small system stretched a long way: two type families, fifteen color tokens, and four corner-radius values cover a twelve-page site. What reads as "premium" is less about ornament and more about three disciplined habits verified directly in the source: a single dark chapter break placed at the page's proof point, one recurring floating-card shape reused for both the hero pitch and the product showcase, and a two-speed motion system (a calm fade-rise for text, a springier scale/slide reserved for hero-only elements).

This audit inspected the connected Framer project's node tree, component library, style tokens and per-breakpoint frames directly through `framer.agent.*` calls. Coverage is deep on the Hero and Product sections (fully decomposed) and on every global token (typography, color, radius, shadow); it is intentionally shallower — wrapper-level rather than leaf-level — on the eight remaining Home sections, in the interest of accuracy over speed. Where a value wasn't sampled, it is marked, not guessed.

---

## 2. Project Architecture

`VERIFIED` — `framer.agent.getNodesOfTypes`, `getNode`

### Pages (12)

| Path | Type |
|---|---|
| `/` | Home |
| `/about` | Static |
| `/features` | Static |
| `/pricing` | Static |
| `/integration` | Static |
| `/integration/:Integration` | CMS detail page |
| `/blog` | Static (index) |
| `/blog/:Blog` | CMS detail page |
| `/contact` | Static |
| `/license` | Static |
| `/changelog` | Static |
| `/404` | Error |

### Home page — section sequence

Top to bottom, as laid out on the Desktop breakpoint canvas:

| # | Section (layer name) | Desktop height |
|---|---|---|
| — | Header *(layout template)* | overlay, 200px |
| 1 | Hero Sections | 1061px |
| 2 | Problem Sections | 774px |
| 3 | The Solution Sections | 1012px |
| 4 | How It Work Sections | 902px |
| 5 | Features Sections | 1414px |
| 6 | Product Sections | 1170px |
| 7 | Real Results Sections Wrapper *(dark block starts)* | 2037px |
| 8 | Benefits Sections | 1362px |
| 9 | Pricing Sections Wrapper | 1424px |
| 10 | FAQ Sections *(light resumes)* | 722px |
| 11 | Blog Sections | 872px |
| — | Footer & Cta *(layout template)* | — |

Desktop canvas total ≈ 12,750px tall. Header and Footer live in a shared "Template" layout object applied to the page, not in the page tree itself.

### Reusable component library (42 local + 4 code + 3 external)

Organized into ten named folders inside the project: **Buttons** (Button, Link Button, Form Button, Footer Form Button, Load More), **Header** (Header, Menu Item, Dropdown), **Product** (Product Card, Product Icon, Product Slideshow), **Pricing** (Pricing Table, Pricing Tab, Pricing Features Item), **FAQ** (FAQ, Single Faq, Our Values Faq / Faq 2), **Blog** (Blog Card, Featured Blog Card, Tab), **Testimonial** (Testimonial Card, Brand Logo), **Benefits** (Benefits Card, Benefit Sections), **Problem Card** (Problem Card, Problem Slideshow), and a large **Others** bucket (iPhone Mockup, Sections Tag, How It Work Card, Real Result Card, Why Choose Us Card, Single Counter Card, Social Icon, Team Card, Mission Card, Contact Info, Integration Card, Brand Logo, Features Item, Finosfits Card, Footer & Cta, Dot List).

Four bespoke **code components** live under `Workshop/`: `TableOfContentsCMS.tsx`, `HamburgerMenu.tsx`, `Counter_FX.tsx` (an animated-counter primitive — the likely driver behind the Real Results stat block), and `EqualizerButton.tsx`. Three **external** Framer components are also active: Rolling Text, Slideshow, and Layout Jump Preventer.

### CMS Collections

| Collection | Feeds |
|---|---|
| Blog | `/blog/:Blog` |
| Blog Category | taxonomy for Blog |
| Integration | `/integration/:Integration` |

---

## 3. Global Design Tokens

Finos runs on a genuinely small token set: **2** font families, **29** text-style presets, **15** color tokens, and — read from real geometry rather than a stated scale — **4** recurring corner-radii and **2** shadow families.

| System | Summary |
|---|---|
| Typography | Inter Tight (primary, 24 of 29 presets) + Inter (H3/H4 only) — see §4 |
| Color | 15 tokens: 9-step Black/White scale, 3 Background grounds, 3 accent hues — see §5 |
| Radius | 100px (pill), 32px (floating card), 24px (feature card), 12px (list card), 0/0/64/64 (section panel) — see §6 |
| Shadow | White ambient glow (light cards) vs. dark 3-layer bevel (primary button) — see §6, §11 |

---

## 4. Typography System

`VERIFIED` — 29 `TextStylePresetNode` entries read via `getNodesOfTypes` + `serializeNodes`

Two families carry the entire site: **Inter Tight** for nearly everything, and plain **Inter** reserved for exactly two steps — H3/48 and H4/40 — the two sizes that most often sit directly beside body copy. The biggest and smallest type stays on Inter Tight's tighter, more graphic tracking; the two "in-between" headline sizes drop the Tight variant, reading slightly warmer where they're most likely to share a line with a paragraph.

### The full preset table

| Style | Font | Weight | Desktop size | ≥810px | <810px | Tracking | Tag |
|---|---|---|---|---|---|---|---|
| H1 | Inter Tight | 400/500 | 96px | 56px | 48px | −0.04em | h1 |
| H2 | Inter Tight | 400/500 | 64px | 48–51px | 36–40px | −0.03em | h2 |
| H3 | Inter | 400/500 | 48px static | 48px | 48px | −0.02em | h3 |
| H4 | Inter | 400/500 | 40px static | 40px | 40px | −0.02em | h4 |
| H5 | Inter Tight | 400/500 | 32px static | 32px | 32px | −0.01em | h5 |
| H5 /18px, /CTA Text | Inter Tight | 500 | 18–24px | — | — | −0.01em | h5 |
| H6 | Inter Tight | 400/500 | 24px static | 24px | 24px | −0.01em | h6 |
| Body 20 | Inter Tight | 400/500 | 20px | — | — | 0em | — |
| Body 18 | Inter Tight | 400/500 | 18px | — | — | 0em | — |
| Body 16 (+ Uppercase) | Inter Tight | 400/500 | 16px | — | — | 0em | — |
| Body 14 | Inter Tight | 400/500 | 14px | — | — | 0em | — |

> **`INTERPRETATION`** — H1 and H2 are the only presets with real per-breakpoint step-downs baked into the token itself (96→56→48 and 64→48/51→36/40). H3–H6 and every Body size are declared with a single static value — their responsive resizing, where it exists, is handled by the page/component breakpoint frames overriding them locally, not by the type token. The two "hero-weight" headline sizes carry their own responsive contract; everything smaller is scaled by its container instead.

> **`NOT ACCESSIBLE` / minor inconsistency** — H6 and the two Body/20 presets store their color as a literal (`#000`, `#666`) rather than a `var(--token-…)` reference used by every other preset. Functionally identical to Black/100 and Black/70, but not wired to the token — worth normalizing in a fresh system rather than copying as-is. Two unnamed presets ("Medium" / "Regular", tag h1/h2, no breakpoint data) also appear in the library — likely legacy or component-scoped overrides; not resolved further in this pass.

---

## 5. Color System

`VERIFIED` — 15 `ColorStyleTokenNode` entries, project-wide

Fifteen tokens, almost all of them a neutral scale. Only three tokens carry real hue — and none of them is what you'd guess for a fintech: no house blue.

### Neutral scale

| Token | Value |
|---|---|
| Black/100 | rgb(0,0,0) |
| Black/70 | rgba(0,0,0,.7) |
| Black/50 | rgba(0,0,0,.5) |
| Black/20 | rgba(0,0,0,.2) |
| Black/10 | rgba(0,0,0,.1) |
| White/100 | rgb(255,255,255) |
| White/70, /50, /20 | on-dark overlay scale |
| Background 01 | rgb(245,247,250) |
| Background 03 | rgb(247,249,251) |
| Background 02 | rgb(20,20,20) |

### The three accent hues

| Token | Value | Reading |
|---|---|---|
| Others/Color 01 | rgb(22,133,74) — green | positive signal |
| Others/Color 02 | rgb(236,90,79) — coral | negative / problem signal |
| Others/Color 03 | rgb(219,227,246) — pale blue | decorative surface tint |

> **`INTERPRETATION`** — roles. Black/White at full and reduced opacity carry all primary and secondary text, hairline borders (Black/10) and dividers (Black/20) — a single ramp doing double duty as both a text scale and a border scale. Background 01/03 are near-identical light grounds (2 units apart in every channel) — likely used to distinguish a card from the page it sits on without a visible seam. Background 02 is the one deliberately dark ground in the system. Green and coral read as a positive/negative semantic pair rather than a brand accent — coral's presence is notable given "Problem Sections" is a named section in the same project. Pale blue reads as a decorative illustration tint, not a UI color.

### How Finos paces the page with color

`VERIFIED` — fill attribute read on every Home section wrapper. Every section from Hero through Product carries no explicit background fill and inherits the page's Background 01 ground. Then, for exactly three sections in a row — **Real Results → Benefits → Pricing** — the wrapper's fill switches to Background 02, rgb(20,20,20). FAQ and Blog then return to no explicit fill. The result: **light for six sections, dark for three, light for two** — one continuous dark passage, roughly 2,860px tall on Tablet, placed exactly where the page shifts from pitching the product to proving it (results → what you get → what it costs). It functions as a single visual "chapter break," not a recurring stripe pattern.

---

## 6. Spacing & Layout System

### Corner radius — read from real geometry, not a stated scale

`VERIFIED` — radius attribute on sampled frames

| Radius | Where observed | Reading |
|---|---|---|
| 100px | Button (all variants) | Pill — every clickable CTA |
| 12px | Blog Card | Compact / list-density card |
| 24px | Problem Card | Standard feature card |
| 32px | Hero "Bottom Card" | Prominent floating card |
| 0 0 64 64 | Hero Sections, Product Sections (outer wrapper) | Section-level panel — bottom corners only |
| 300px | Product "Hero Surface" background | Large soft background surface, near-circular |

> **`INTERPRETATION`** — Radius scales with a component's visual weight, not a fixed 4/8px-multiple system: 12→24→32px roughly doubles as cards get more prominent, then jumps to 64px specifically for whole-section panels, and 100px for pills. The bottom-only `0 0 64px 64px` radius is used identically on the two sections that carry the product's visual proof (Hero and Product) — a deliberate, repeated "panel tucks under the next section" shape, not a one-off.

### Shadow — two families, not one scale

`VERIFIED` — `boxShadows` attribute, sampled nodes

| Family | Value | Used on |
|---|---|---|
| White ambient glow | `6px 6px 25px 0 rgba(255,255,255,1)` | Hero Bottom Card, Problem Card |
| Button bevel (3-layer) | `0 2px 0 rgba(60,60,60,1)` + `inset 0 −0.5px rgba(255,255,255,.1)` + `inset 0 1px rgba(255,255,255,.2)` | Button/Primary "Background" layer |
| Flat / bordered (no shadow) | `1px solid Black/10` | Blog Card |

Because the glow cards sit on the light rgb(245,247,250) ground, a *white* shadow reads as luminous lift rather than a conventional dark drop-shadow — the same signature verified independently on two unrelated components (Hero and Problem), which is what earns it "system," not "coincidence."

### Grid, container width, and page margin

`VERIFIED` — breakpoint canvas + section padding, read per section

| | Desktop | Tablet | Phone |
|---|---|---|---|
| Canvas width | 1300px | 810px | 390px |
| Section horizontal margin | 40px | 40px | 20px |
| Section top padding (standard) | 120px | 40px | 30px |
| Section top padding (Hero) | 166px | 166px | 100px |

> **`INTERPRETATION`** — Vertical rhythm compresses roughly 4× from desktop to phone (120→30px) while horizontal margin compresses only 2× (40→20px). Finos protects edge alignment on small screens far more than it protects pacing — the page gets denser, not narrower-feeling. Layout-template content is fixed at 1200px wide independent of the 1300px breakpoint canvas — `NOT ACCESSIBLE`, the exact relationship between the two widths wasn't confirmed at the sampled depth.

---

## 7. Desktop System

`VERIFIED` — breakpoint `min-width: 1300px`, canvas 1300px

Desktop is the reference composition — every section wrapper is a single full-width flex frame, 1fr, with horizontal padding creating the margin (there is no separate fixed-width "container" element nested inside; the padding *is* the container). Sections vary between a plain vertical content stack (Problem, Solution, How It Works, Features, FAQ) and a two-layer composition with an absolutely-positioned background image or surface plus a foreground Container (Hero, Product) — full-bleed art direction is reserved specifically for the two sections that need to "show," not "tell."

Two compositional habits repeat: an **asymmetric heading split** (a narrow eyebrow/context column beside a wide heading+CTA column, 183px gap in Hero, rather than a centered stacked headline), and a **floating card** overlapping a full-bleed background image (Hero's Bottom Card, white, 32px radius, glow shadow) rather than plain copy laid directly over the art.

---

## 8. Tablet System

`VERIFIED` — breakpoint `810px–1299.98px`, canvas 810px

Tablet is not a scaled-down Desktop. Every measured section keeps Desktop's **horizontal** stack direction and 40px side margin, but vertical padding drops sharply and un-evenly — Hero stays at a fixed 166/40/40/40px (unchanged from desktop), while Solution, How It Works and Features collapse from an asymmetric 120/40/40/40 down to a flat, uniform `40px` on every edge. Typography steps down via the H1/H2 tokens' own `medium` breakpoint (96→56px, 64→48/51px) rather than any tablet-specific override elsewhere in the system.

> **`NOT ACCESSIBLE` in this pass** — Card-grid column counts, navigation collapse behavior, and image-crop changes at the 810px canvas were not individually re-sampled beyond the section-wrapper level for every section — confirmed directly only for Header (has an explicit `Tablet` component variant) and for card families that expose `Tablet`-named variants (Problem Card, Testimonial Card). Others (Benefits Card, Real Result Card, Pricing Tab) have no dedicated Tablet variant in their control set — see §12 — meaning Tablet either reuses their Desktop geometry unchanged or the responsiveness lives in the page-breakpoint frame rather than the component. This wasn't resolved further.

---

## 9. Phone System

`VERIFIED` — breakpoint `max-width: 809.98px`, canvas 390px

Phone is where the structure actually changes, not just the numbers. Every measured section wrapper switches its stack direction from `horizontal` to `vertical` — Hero, Problem, FAQ and Blog all confirmed directly — meaning whatever multi-column composition exists on Desktop/Tablet is reflowed into a single column, not simply squeezed. Side margin drops to 20px, standard top padding to 30px, and Hero's padding compresses from 166px to 100px. H1 lands at its floor of 48px, H2 at 36–40px — both hit their smallest defined step, so nothing shrinks further below phone; the type system has a hard bottom rather than scaling continuously.

Component-level Phone variants exist for the components that most need bespoke mobile geometry rather than a naive scale-down: Header ("Phone", "Phone Open", "Phone On Scroll", "Phone On Scroll Open" — four distinct states for one component, versus Desktop/Tablet's single state each), Problem Card, Benefits Card, Blog Card, and every Pricing Tab permutation. This is the strongest verified evidence in the project that "premium on mobile" here means *authored* mobile states, not scaled desktop ones.

> **`NOT ACCESSIBLE` in this pass** — Exact card widths/padding/radius on Phone, and whether any Home elements are hidden or reordered (vs. simply restacked), were not individually verified beyond the Header/card variant names above.

---

## 10. Navigation System

`VERIFIED` — Header component controls + template placement

The Header is a single component instance placed `position: absolute` at the top of the shared layout template (not embedded per-page), spanning the full 1200px template width at a measured 200px height on Desktop. It ships with six named variants rather than plain breakpoint overrides:

| Variant | Reading |
|---|---|
| Desktop | Default state |
| Tablet | 810–1299px state |
| Phone | Collapsed / closed mobile state |
| Phone Open | Mobile menu expanded |
| Phone On Scroll | Scrolled, closed |
| Phone On Scroll Open | Scrolled, expanded |

The four Phone-prefixed states confirm a real scroll-aware, open/close-aware mobile nav (not just a hamburger icon swap) — consistent with the bespoke `HamburgerMenu.tsx` code component present in the project. Menu Item is its own component with `Menu / Open / White Footer` variants, a text control, an optional icon, and an `onHover` event handler; Dropdown has `Desktop / Phone` variants with an `onClick` handler. The Footer reuses a matching "White Footer" Menu Item variant — the same navigation-link component, recolored for the dark footer ground, rather than a second link component being built for the footer.

> **`NOT ACCESSIBLE`** — Exact sticky/fixed scroll-trigger threshold, and hover/pressed pixel deltas for Menu Item and Dropdown, weren't resolved — their existence is confirmed via variant names and an `onHover` control, but the visual delta between states wasn't sampled.

---

## 11. Button System

`VERIFIED` — Button component, Primary variant fully decomposed to leaf nodes

### Primary button — full anatomy

| Part | Value |
|---|---|
| Outer frame | 150px fixed width · 2px padding (shadow buffer) · radius 100px |
| Inner "Background" | padding 12px 32px · radius 100px · fill `linear-gradient(9deg, #1c1c1c 0%, #545454 100%)` |
| Shadow (3-layer bevel) | `0 2px 0 rgba(60,60,60,1)` + `inset 0 −0.5px rgba(255,255,255,.1)` + `inset 0 1px rgba(255,255,255,.2)` |
| Label | Body/16px Medium, White/100, text driven by a shared variable |
| Transition | spring-physics(stiffness 400, damping 70, mass 1, delay 0s) |

> **`INTERPRETATION`** — the hover mechanism. The label is not one text node but two identical "Get Started" runs: one in normal flow, a second absolutely positioned 20px below it. That's the exact shape of a vertical rolling-text swap (matches the project's own "Rolling Text" external component). The precise trigger and duration for the swap weren't independently confirmed via the `whileHover`/`interactions` attribute paths (see §15/§20) — but the duplicate-offset-label structure is real, verified geometry, not a guess.

### Variant hierarchy

| Variant | Width | Reading |
|---|---|---|
| Primary | 150px fixed | Default dark CTA |
| White | auto (content-hug) | For use on dark grounds |
| Fill | 150px fixed | Stronger / full CTA |

Beyond Button, the system carries a **Link Button** (text-only, "READ MORE" style, no variant — the tertiary action), and a **Form Button** with a full async state machine — `Default / Loading / Disabled / Success / Error` — confirming Finos treats form submission as a first-class interaction state, not a plain submit button. A near-duplicate **Footer Form Button** exists as its own component rather than a reused instance.

---

## 12. Card System

`VERIFIED` — component `$variants` + representative variant geometry, 7 card families sampled

| Card | Width | Radius | Surface | Variants |
|---|---|---|---|---|
| Problem Card | 1120px | 24px | White + glow shadow | Desktop / Tablet / Phone |
| Blog Card | 445px | 12px | White + 1px Black/10 border | Blog Card / Blog Card Phone |
| Benefits Card | 560px | *not sampled* | *not sampled* | Benefits Card / Phone |
| Testimonial Card | 1120px | *not sampled* | *not sampled* | 3 reviews × Desktop/Tablet/Phone (9) |
| Real Result Card | 365px | *not sampled* | *not sampled* | Desktop only (1) |
| Pricing Tab | 556px | *not sampled* | *not sampled* | Monthly/Yearly × Starter/Popular × Phone (8) |
| Features Item | 330px | *not sampled* | *not sampled* | Features Item / White |

> **`INTERPRETATION`** — the shared card grammar. Two families, not one: a **glow card** (white fill, no border, white ambient shadow — Problem Card, and the Hero Bottom Card outside the card system proper) for hero-adjacent, high-attention content; and a **flat bordered card** (white fill, 1px Black/10 border, no shadow — Blog Card) for list-density, lower-drama content. Radius tracks that same hierarchy: 24px for glow cards, 12px for flat cards. Two full-width row-style cards (Problem, Testimonial) share an identical 1120px width — a real repeated "full content-width row" size, not a coincidence. Features Item's `White` variant is a ground-color swap rather than a size change — confirming components in this system carry their own light/dark-ground variant rather than relying on inherited color.

> **Notable inconsistency** — Real Result Card is the one card family sampled with a single Desktop-only variant — no Tablet or Phone counterpart. Either its responsiveness is delegated entirely to the page-breakpoint frame (unlike every other card family), or a mobile variant simply wasn't built.

---

## 13. Product Presentation System

`VERIFIED` — Hero and Product section trees decomposed to 3 levels

Product visuals get the same panel language as the Hero, not a generic "screenshot in a rounded rectangle" card. The Product Sections wrapper carries the identical `0 0 64px 64px` bottom radius as Hero, sits on an even larger soft background surface (a 300px-radius "Hero Surface" image, effectively borderless and pill-like at that scale), and wraps its content in the same 80px-gap vertical `Container → [Sections Title] → [visual]` pattern verified in the Hero. A dedicated **Product Slideshow** component — not a static image — occupies the visual slot, confirmed present in the component library and named directly in the section's own "Image & Slideshow" child frame.

The Hero, by contrast, puts its product evidence inside a floating white card (32px radius, glow shadow) laid over a full-bleed background image, splitting that card into a text column and an "Image Wrapper" column — evidence is framed as a physical object sitting on top of the page, not flush with it.

> **`INTERPRETATION`** — why it reads as premium rather than generic SaaS. Both patterns avoid the default "browser-chrome screenshot in a drop-shadowed rectangle" — instead the product imagery either floats on a dedicated white card with a glow (Hero) or sits inside a large soft-radius surface treated as part of the section's own shape (Product). The mockup becomes part of the panel's geometry rather than an image dropped into a generic card.

> **`NOT ACCESSIBLE`** — The "iPhone Mockup" component is confirmed present in the library but was not confirmed instantiated on the Home page in the nodes sampled — it may be used on /features or /about instead. Exact crop/overflow/layering values inside the Bottom Card's Image Wrapper and the Product Slideshow's internal frames weren't sampled at leaf depth.

---

## 14. Home Section-by-Section Audit

Every section below is verified for background, dimensions and breakpoint deltas directly from the source (full `getRect` + attribute reads across all three breakpoints). Internal composition is fully decomposed for Hero and Product (§13); for the remaining sections it is reported at the depth actually sampled — wrapper-level, not leaf-level — and marked accordingly rather than inferred.

### 1 · Hero Sections — `Fully decomposed`
Opening pitch — headline, eyebrow tag, and a floating proof card over a full-bleed background image.
- **Background:** Full-bleed absolute PNG image; page ground (Background 01) shows at the edges via the panel's rounded bottom.
- **Dimensions:** 1fr width · 1061px desktop height · radius **0 0 64 64**
- **Layout:** Vertical Container, 80px gap: **Title&Tag row** (horizontal, 183px gap) → **Bottom Card** (32px radius, glow shadow, split text/image) → CTA button instance.
- **Components:** Sections Tag, Button
- **Breakpoints:** Desktop `166 40 40 40 · horizontal` · Tablet `166 40 40 40 · horizontal` · Phone `100 20 30 20 · vertical`

### 2 · Problem Sections — `Wrapper verified`
States the cost of the status quo — the section most likely paired with the coral accent token.
- **Background:** Page ground (no override)
- **Dimensions:** 1fr · 774px desktop
- **Components:** Problem Card (24px radius, glow shadow, 1120px, own Desktop/Tablet/Phone variants), Problem Slideshow, Dot List *(by naming + control linkage)*
- **Breakpoints:** Desktop `160 40 40 40` · Tablet `80 40 40 40` · Phone `60 20 30 20 · vertical`

### 3 · The Solution Sections — `Wrapper verified`
Reframe — the answer to the Problem section. *Inner composition not sampled.*
- **Dimensions:** 1fr · 1012px desktop
- **Breakpoints:** Desktop `120 40 40 40` · Tablet `40 uniform` · Phone `30 20 30 20 · vertical`

### 4 · How It Work Sections — `Wrapper verified`
Process explanation. *Inner composition not sampled.*
- **Dimensions:** 1fr · 902px desktop
- **Components:** How It Work Card *(by naming)*
- **Breakpoints:** Desktop `120 40 40 40` · Tablet `40 uniform` · Phone `30 20 30 20 · vertical`

### 5 · Features Sections — `Wrapper verified`
Feature-by-feature breakdown, the longest light-ground section.
- **Dimensions:** 1fr · 1414px desktop (tallest section before the dark block)
- **Components:** Features Item — 330px, horizontal, 10px gap; `Features Item / White` ground-swap variant
- **Breakpoints:** Desktop `120 40 40 40` · Tablet `40 uniform (817px)` · Phone `30 20 30 20 · vertical (1783px)`

### 6 · Product Sections — `Fully decomposed`
The deep product proof — mirrors Hero's panel language. See §13.
- **Dimensions:** 1fr · 1170px desktop · radius **0 0 64 64**
- **Layout:** 300px-radius background surface + vertical Container (80px gap): Sections Title → Image & Slideshow
- **Components:** Product Card, Product Icon, Product Slideshow
- **Breakpoints:** Desktop `120 40 160 40` · Tablet `40 40 80 40` · Phone `30 20 30 20 · vertical`

### 7 · Real Results Sections Wrapper — `Wrapper + fill verified`
Opens the dark "proof" passage — stats/results, likely animated via the Counter_FX code component.
- **Background:** **Background 02, rgb(20,20,20)** — explicit dark fill
- **Dimensions:** 1fr · 2037px desktop — the tallest section on the page
- **Components:** Real Result Card (365px, Desktop-only variant), Single Counter Card, Counter_FX *(code component, likely animated counters)*
- **Heights:** Desktop `2037px` · Tablet `3128px` · Phone `2677px`

### 8 · Benefits Sections — `Wrapper + fill verified`
Continues the dark passage — benefit-by-benefit detail.
- **Background:** Background 02, rgb(20,20,20)
- **Dimensions:** 1fr · 1362px desktop
- **Components:** Benefits Card (560px, vertical, 40px gap), Benefit Sections wrapper
- **Heights:** Desktop `1362px` · Tablet `1174px` · Phone `2028px`

### 9 · Pricing Sections Wrapper — `Wrapper + fill verified`
Closes the dark passage with the offer itself.
- **Background:** Background 02, rgb(20,20,20)
- **Dimensions:** 1fr · 1424px desktop
- **Components:** Pricing Table, Pricing Tab (8-way Monthly/Yearly × Starter/Popular × Phone variant matrix), Pricing Features Item
- **Heights:** Desktop `1424px` · Tablet `2061px` · Phone `2060px`

### 10 · FAQ Sections — `Wrapper verified`
Light ground resumes. Accordion, not scroll-reveal, drives its interaction.
- **Dimensions:** 1fr · 722px desktop (shortest content section)
- **Interaction:** Single Faq: `Open / Close` variant toggle + `onClick` handler, numbered "01." label. FAQ wrapper: `Question 01–06` variant, i.e. content-driven not layout-driven.
- **Breakpoints:** Desktop `120 40 40 40` · Tablet `40 uniform` · Phone `30 20 30 20 · vertical`

### 11 · Blog Sections — `Wrapper verified`
Closes the page on flat, bordered "list" cards rather than the glow-card language used above.
- **Dimensions:** 1fr · 872px desktop
- **Components:** Blog Card (445px, 12px radius, 1px Black/10 border), Featured Blog Card, Tab, Load More
- **Breakpoints:** Desktop `120 40 40 40` · Tablet `40 uniform` · Phone `30 20 30 20 · vertical`

---

## 15. Motion & Interaction System

`VERIFIED` — 40 `appearEffect` instances scanned on the Home / Desktop tree

### Global motion philosophy

Every animated element on the Home page uses `spring-physics`, never a duration/easing curve — Finos's motion has weight and settle, not a fixed timeline. Two trigger families cover all 40 instances found:

| Trigger | Enter state | Spring (stiffness/damping/mass/delay) | Used for |
|---|---|---|---|
| `onInView` | opacity 0→1, y 50→0 | 400 / 70 / 1 / 0–0.2s | Standard text & card reveal |
| `onScrollTarget` | opacity 0→1, scale .9→1 | 400 / 30 / 1 / 0.2s | Hero CTA — springier, bouncier |
| `onScrollTarget` | opacity 0→1, x −50→0 | 400 / 70 / 1 / 0s | Hero side element — horizontal slide |

Stagger is handled by hand — each node carries its own transition `delay` (0s, then 0.2s for the next element in the same container) rather than a single `staggerChildren`-style property. Within the Hero, the title reveals first, the floating Bottom Card follows 0.2s later — sequencing the eyebrow/headline before the proof card.

### Component-specific motion

The Button's transition (`400/70/1/0s`) matches the standard reveal spring, and its duplicate offset-label geometry (§11) is the structural signature of a rolling-text hover swap — the one clear hover mechanism identifiable from source, even though it isn't exposed under the `whileHover` attribute path. The FAQ accordion is not spring-driven at all — it's a discrete `Open/Close` variant swap fired by a click handler, a binary state change rather than continuous motion.

> **`NOT ACCESSIBLE`** — The `whileHover` and `interactions` attribute keys returned zero matches project-wide in this scan. That does not mean no hover states exist (see Button, above) — it means this project encodes them through component variant graphs rather than a hover-specific attribute this API surface exposes directly. Parallax, marquee, sticky-scroll and any component-internal (code-file) motion inside `Counter_FX.tsx` or `EqualizerButton.tsx` were not inspected — reading compiled/code-component logic was out of scope for the node-tree APIs used in this audit.

---

## 16. Responsive Transformation Matrix

What genuinely changes structurally between breakpoints, not just what scales.

| System | Desktop (≥1300px) | Tablet (810–1299px) | Phone (<810px) |
|---|---|---|---|
| Canvas | 1300px | 810px | 390px |
| Section direction | horizontal wrapper | horizontal wrapper | vertical wrapper — real reflow |
| Section margin | 40px | 40px (unchanged) | 20px |
| Section top padding | 120px (asymmetric) | 40px (uniform) | 30px (uniform) |
| H1 / H2 | 96 / 64px | 56 / 48–51px | 48 / 36–40px |
| Header | 1 state | 1 state | 4 states (open/scroll combinations) |
| Problem / Testimonial cards | own variant | own variant | own variant |
| Real Result card | only variant defined | no dedicated variant | no dedicated variant |
| Pricing Tab | Monthly/Yearly × tier | same as Desktop *(interpretation)* | + dedicated Phone geometry |
| Dark passage height | 4823px (3 sections) | 6363px | 6765px |
| Motion | full spring reveal set | not independently verified | not independently verified |

---

## 17. Finos Visual Grammar

What makes Finos feel like Finos, distilled from the verified evidence above.

1. **One dark chapter, not a striped page.** Backgrounds don't alternate section-by-section — they hold light for six sections, drop to one continuous dark block exactly at the proof point (results → benefits → pricing), then return to light.
2. **The hero's shape is the product section's shape.** Hero and Product share the identical bottom-only 64px radius and the same 80px-gap title-then-visual container.
3. **Evidence floats, it doesn't sit flush.** Product proof lives inside a physically distinct white card (32px radius, white ambient glow) laid over the background art, not inline with the page.
4. **A white shadow, not a black one.** Light cards on the light ground use a white ambient glow rather than a conventional dark drop-shadow — verified on two unrelated components.
5. **Radius tracks prominence, not a fixed scale.** 12 → 24 → 32 → 64 → 100px roughly doubles as elements matter more, ending at a full pill for anything clickable.
6. **Two card families for two jobs.** Glow cards (no border, ambient shadow) carry high-attention content; flat bordered cards (hairline border, no shadow) carry list-density content like blog posts.
7. **Headings split, they don't center-stack.** The Hero heading is a wide asymmetric two-column row (eyebrow column beside headline+CTA column, 183px gap) rather than the generic centered hero headline pattern.
8. **Weight over speed in motion.** Every animation is spring-physics — nothing eases on a fixed timeline. Reveal motion (damping 70) is calm; the one hero-only scale-in (damping 30) is deliberately bouncier.
9. **Stagger is authored, not automatic.** Sequencing comes from hand-set per-node delays (0s, then 0.2s) rather than a single stagger rule.
10. **Mobile gets new states, not smaller ones.** Header ships four distinct Phone states; several cards ship dedicated Phone variants with their own geometry.
11. **Vertical rhythm compresses harder than the margin.** Section padding drops 4× (120→30px) from desktop to phone while the side margin only halves (40→20px).
12. **Two typefaces, deployed by role, not by page.** Inter Tight carries the extremes (largest and smallest type); plain Inter is reserved for the two mid-sizes most likely to sit beside body copy.
13. **Color does almost no branding work.** Fifteen tokens, twelve of them neutral. The only three hued tokens read as semantic (positive green, negative coral) or decorative (pale-blue tint).

---

## 18/19. Reusable Principles & Finos-Specific Elements

### A · Reusable visual grammar

- One dark chapter-break placement, not alternating stripes
- A shared panel shape (bottom-rounded, radius scaling with prominence) reused across the hero and the deepest product-proof section
- Floating evidence cards with an ambient (not drop) shadow
- Two-family card grammar sized to content weight
- Asymmetric heading split over centered stacked headlines
- Spring-physics motion with hand-authored stagger delays and a two-speed vocabulary (calm reveal vs. bouncy hero accents)
- Authoring distinct mobile component states rather than only scaling desktop ones
- Vertical-rhythm-first responsive compression (padding compresses faster than margin)
- Role-based (not decorative) typeface pairing across the size scale

### B · Finos-specific — do not copy

- Finos wordmark, brand logo, and any literal marketing copy
- The specific financial-product content (budgets, safe-to-spend, bills/goals framing)
- Proprietary product screenshots and illustration assets
- The exact Inter Tight / Inter typeface pairing, if visual differentiation from Finos is desired
- The exact token values (96px H1, 64px H2, rgb(20,20,20) dark ground, etc.) — the *system* of scaling is reusable, the specific numbers are Finos's
- Coral/green as the specific accent hues, if they should read as Finos's own semantic pair rather than reused verbatim
- Named components as shipped (Problem Card, Sections Tag, etc.) — rebuild to the same principles under Cefflo's own naming and content

---

## 20. Agent / API Limitations

Honesty about what this pass did *not* reach, so nothing above is mistaken for more complete than it is:

- Hover and pressed-state deltas were not independently observable — the `whileHover`/`interactions` attribute paths returned no matches anywhere in the scanned tree, even though variant structure (e.g. the Button's duplicate offset label) strongly implies real hover mechanics exist.
- Solution, How It Works, FAQ (beyond the accordion) and Blog sections were verified at the wrapper level (background, dimensions, padding, breakpoints) but not decomposed to leaf nodes the way Hero and Product were.
- Card fill/radius/shadow for Benefits Card, Testimonial Card, Real Result Card, Pricing Tab and Features Item were confirmed only at the outer variant-frame level in this pass; deeper leaf styling (icon treatment, internal type usage, exact padding) was not pulled.
- Logic inside code components (`Counter_FX.tsx`, `EqualizerButton.tsx`, `HamburgerMenu.tsx`, `TableOfContentsCMS.tsx`) is compiled/authored code, not node-tree data — its animation behavior wasn't inspected.
- Pages other than Home (/about, /features, /pricing, /contact, /integration, /blog, /license, /changelog, /404) were mapped in the sitemap but not opened or decomposed.
- The exact relationship between the 1200px layout-template width and the 1300px breakpoint canvas width was not fully resolved.

---

## 21. Source Evidence Summary

| Tag | Meaning | Approx. count in this report |
|---|---|---|
| `VERIFIED` | Read directly via `framer.agent.*` — node attributes, rects, controls, or variant lists | ~65 discrete data points |
| `INTERPRETATION` | A conclusion drawn from combining two or more verified values | ~20 callouts |
| `NOT ACCESSIBLE` | Not exposed by the queried attribute path, or not sampled in this pass | ~10 flagged gaps |

Primary calls used: `getNodesOfTypes`, `getNode` / `getNodes`, `serialize` / `serializeNodes`, `getRect`, `getDescendantReferencesOfTypes`, and `readComponentControls` — all read-only. No `applyChanges`, `publish`, or write call was made at any point in this audit.

---

## 22. Recommended Translation Rules for a Future Cefflo Design System

Principles only — no palette, type, or layout decisions for Cefflo are made here. This names which of Finos's *mechanisms* (§18) could translate, and what each would need to become Cefflo's own rather than Finos's, once the Founder authorizes design work.

| Finos mechanism | Translates as a Cefflo rule of… |
|---|---|
| One dark chapter-break at the proof point | Placement logic — pick Cefflo's own proof point and its own dark (or otherwise contrasting) palette |
| Shared panel shape between hero and product section | A structural rule ("repeat one signature shape across the two selling moments"), with Cefflo's own radius value |
| Floating evidence card with ambient shadow | A shadow *direction* philosophy (glow vs. drop), re-tuned to Cefflo's own ground colors |
| Radius scaling with prominence | A scale *relationship* (small→large tracks minor→major elements), with Cefflo's own step values |
| Two-family card grammar by content weight | A content-to-treatment mapping rule, independent of Finos's specific card names |
| Spring-physics, two-speed motion vocabulary | A motion-system rule (weighted springs, calm default + one bolder accent case), with Cefflo's own tuning |
| Authored mobile component states | A process rule: design mobile interaction states directly, don't derive them by scaling |
| Padding-compresses-faster-than-margin responsive rule | A responsive-compression ratio to set deliberately for Cefflo's own breakpoints |
| Role-based typeface pairing across the scale | A pairing *method* — assign families by where in the hierarchy they sit, with Cefflo's own two typefaces |

> **Founder gate.** This audit stops here. No Cefflo palette, typography, component, or page has been designed or implemented. Awaiting explicit approval before any translation work begins.

---

*Finos Framer Source — Full Visual System Audit · read-only · no modifications made to Finos-copy*
