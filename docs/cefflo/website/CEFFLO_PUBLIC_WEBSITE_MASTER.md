# CEFFLO PUBLIC WEBSITE MASTER

**Document authority (D-67):** the single maintained master for the CEFFLO
Public Website. It incorporates *CEFFLO Public Website — Final Visual Spec V2*
(§1–§37, content-identical to `CEFFLO_PUBLIC_WEBSITE_VISUAL_SPEC_V2_FINAL.md`,
which is not kept as a separate file, so the two cannot drift) plus the
2026-09-26 commercial/product-truth update (§38–§42). Input report:
`reports/CEFFLO_PUBLIC_WEBSITE_POLISH_REPORT.md` (historical). Founder
decisions still open in that report (e.g. launch posture/CTA, Storefront
presence, hero Vendor surface) are **not** resolved by this document unless a
section below states them. The Public Website remains NOT IMPLEMENTED as a
product surface (D-62) until the Founder approves publication.

**Status (visual direction, §1–§37):** Final Visual Direction / Gate 1 Locked\
**Purpose:** Canonical visual and implementation direction for the
CEFFLO Public Website.\
**Supersedes:** `CEFFLO_PUBLIC_WEBSITE_VISUAL_SPEC.md` and, as a maintained
file, `CEFFLO_PUBLIC_WEBSITE_VISUAL_SPEC_V2_FINAL.md`

------------------------------------------------------------------------

## 1. Design Direction

CEFFLO should feel like a serious operating system whose complexity has
been made visually simple.

The final direction combines a small number of clearly assigned
reference roles rather than blending entire templates.

### Primary visual references

**AppDrop** - cleanliness - simplicity - calm composition - clear page
hierarchy - generous whitespace - clean product presentation - problem →
solution storytelling

**Makro** - premium typography - large scale hierarchy - editorial
whitespace - product-first storytelling - strong section pacing -
oversized product presentation

### Secondary pattern references

**PayGin** - numbered "How it works" communication - direct product
explanation - useful micro-UI demonstrations

**Zappy** - layered product composition - floating product states -
controlled visual energy

Use sparingly. Do not inherit its consumer-fintech visual busyness.

**Upwize** - dedicated mobile-product showcase - especially useful for
the Driver App - one large phone surrounded by small supporting
capabilities

**Arewno** - legal/static content page language - Terms and Privacy page
hierarchy - large legal heading + numbered sections + generous
whitespace

### Priority rule

If references conflict:

1.  CEFFLO product/brand truth wins.
2.  AppDrop cleanliness wins.
3.  Makro premium hierarchy wins.
4.  Secondary references contribute only specific patterns.

Do not combine every reference feature into one page.

------------------------------------------------------------------------

## 2. Core Principle

> **Simple first. Product first. Operations made clear.**

Do not make CEFFLO look like: - a generic logistics template - a fintech
clone - a card-heavy SaaS template - an enterprise dashboard landing
page - a colourful consumer app - a collection of six Framer templates

The website should feel intentionally restrained.

------------------------------------------------------------------------

## 3. CEFFLO Product Truth

CEFFLO is a **local same-day delivery operating system** for businesses
that run their own local delivery.

Typical businesses: - F&B - bakeries - meal prep - florists - gifts /
hampers - beauty / skincare - local retail and similar businesses

CEFFLO is **not**: - a delivery marketplace - a rider marketplace - a
food marketplace - an ordering marketplace - a courier aggregator

The business owns its: - customers - sales channel - riders/drivers -
delivery operation

CEFFLO provides the operating system.

### Canonical operating model

**Orders → Coverage → Zones → Delivery Plan → Multi-drop Runs → Riders /
Drivers → Delivered Today**

### Doctrine

**GROW = OPERATE**

------------------------------------------------------------------------

## 4. Canonical Product Surfaces

1.  **Vendor** --- Flutter Mobile + Web/Desktop
2.  **Driver** --- Flutter Mobile
3.  **Customer Tracking** --- PWA/Web
4.  **Founder** --- Web/PWA

The Public Website is a separate product surface.

For the public website, the core ecosystem story is:

> **Vendor → Driver → Customer Tracking**

Founder Admin should not dominate customer-facing marketing.

------------------------------------------------------------------------

## 5. Brand System

### Typography

**Inter**

### Core palette

- CEFFLO cool white / very light cool-grey canvas
- white product surfaces
- dark navy / near-black primary text
- cool neutral grey secondary text
- canonical CEFFLO blue family
- canonical CEFFLO blue gradient only in selected moments
- CEFFLO mustard yellow for selected primary actions/accent
- semantic status colors only where the real canonical product uses them
- near-black sections only where contrast materially improves storytelling

**Signal Lime is retired. Never use it.**

### Canonical CEFFLO Brand Color Lock — NON-NEGOTIABLE

The Public Website must inherit its color identity from the actual canonical CEFFLO product surfaces. Reference websites may influence composition, hierarchy, spacing, storytelling and presentation, but **must never redefine CEFFLO colors**.

The CEFFLO blue gradient is **not** a generic SaaS blue gradient. Its visual direction is the same family used by the canonical Vendor product: deep CEFFLO navy / royal blue → CEFFLO primary blue → brighter blue / cyan-blue.

**Implementation rule:** if exact color tokens, gradient stops, CSS variables, Flutter theme values or other canonical color definitions exist in the repository, use those exact values. The supplied real Vendor screens are visual acceptance references for verifying that the website remains in the same CEFFLO family.

Do **not**:
- approximate the gradient by eye
- invent new blue values
- sample or inherit colors from AppDrop, Makro, PayGin, Zappy, Upwize or Arewno
- create a new “premium blue”
- replace the canonical gradient with a generic SaaS gradient
- change CEFFLO product colors for marketing aesthetics

The transition **cefflo.com → authentication → Vendor / Driver / Customer product** must feel like one company and one visual system.

### Character

-   clean
-   minimal
-   premium
-   calm
-   product-first
-   operational
-   confident
-   spacious
-   modern

### Avoid

-   excessive gradients
-   glassmorphism everywhere
-   excessive borders
-   excessive cards
-   icon grids
-   generic illustrations
-   stock delivery riders
-   vans as decorative hero imagery
-   decorative blobs
-   giant shadows
-   fake dashboards
-   excessive animation

------------------------------------------------------------------------

## 6. Cleanliness Rule

AppDrop establishes the restraint standard.

Every section should answer:

> Does this element help explain CEFFLO?

If not, remove it.

Prefer: - one strong headline - one short explanation - one strong
visual

over: - six cards - six icons - multiple paragraphs - decorative widgets

Do not fill whitespace simply because space exists.

------------------------------------------------------------------------

## 7. Typography & Scale

Use strong Makro-style hierarchy while retaining AppDrop cleanliness.

Starting system:

``` text
Display XL
clamp(56px, 7vw, 112px)

Display
clamp(44px, 5.2vw, 80px)

H2
clamp(38px, 4vw, 64px)

H3
clamp(26px, 2.5vw, 40px)

Body Large
18–22px

Body
16–18px

Label
12–14px
```

Headline line-height: **0.95--1.05**

Body line-height: **1.45--1.60**

### Rule

Big typography requires short copy.

Do not place long paragraphs below oversized headings.

------------------------------------------------------------------------

## 8. Layout System

``` text
Content max-width: 1440px

Desktop gutter: 48–64px
Tablet gutter: 32px
Mobile gutter: 20px

Desktop section rhythm: 140–220px
Tablet: 100–150px
Mobile: 72–110px
```

Use a conceptual 12-column desktop grid.

Do not expose a rigid "template grid" feeling.

Product visuals may break the normal grid where intentional.

------------------------------------------------------------------------

## 9. Geometry

``` text
Small radius: 10–12px
Normal radius: 16–20px
Large surface: 24–32px
Pill: 999px
Border: subtle neutral 1px
Shadow: minimal
```

Create depth using: - scale - layering - overlap - whitespace

Not heavy shadows.

------------------------------------------------------------------------

# HOMEPAGE

## 10. Navigation

Keep navigation minimal.

Recommended:

**Cefflo \| Product \| How it works \| Solutions \| Resources \| Sign in
\| Get started**

Desktop: - logo left - compact nav - Sign in secondary - Get started
primary

Mobile: - logo - menu trigger - clean menu sheet

Do not introduce a mega-menu for v1.

------------------------------------------------------------------------

## 11. Hero --- Clean First

AppDrop cleanliness + Makro scale.

The hero should not contain excessive floating UI.

### Structure

small category label\
→ large proposition\
→ one short explanation\
→ CTA\
→ one dominant product composition

### Working direction

**LOCAL SAME-DAY DELIVERY**

# Run local delivery.

# Without the chaos.

Supporting direction:

**Turn today's orders into zones, multi-drop runs and rider execution
--- all in one operating system.**

Primary CTA: **Get started**

Optional secondary: **See how it works**

Final copy remains subject to Founder approval.

### Hero visual

Primary: **Vendor Web/Desktop**

Secondary: **Driver Mobile**

Tertiary: **Customer Tracking**

Vendor remains the dominant visual.

Driver may overlap.

Customer Tracking should be subtle.

Zappy-style floating states may be used sparingly, for example:

-   `24 Deliveries`
-   `8 Active Riders`
-   `Run Started`
-   `Delivered`

Do not surround the hero with dozens of floating widgets.

------------------------------------------------------------------------

## 12. The Challenge

Borrow AppDrop's clarity: explain the problem before dumping features.

Label:

**THE CHALLENGE**

Working headline:

# More orders shouldn't create more delivery chaos.

Short supporting copy should explain that local delivery becomes harder
as volume grows across orders, zones, riders and today's delivery plan.

This should be a calm section.

No giant feature grid.

------------------------------------------------------------------------

## 13. Who CEFFLO Is For

Use genuine categories instead of fake logos:

**F&B · Bakeries · Meal Prep · Florists · Gifts · Beauty · Local
Retail**

Keep it visually simple.

No fabricated "trusted by" statement.

------------------------------------------------------------------------

## 14. Plan / Dispatch / Deliver

This is CEFFLO's first mental model.

### PLAN

Turn orders into delivery zones and runs.

### DISPATCH

Put the right run with the right rider.

### DELIVER

Execute every stop and keep everyone updated.

Presentation should remain simple.

Do not make these three oversized generic feature cards unless the
visual treatment genuinely adds value.

------------------------------------------------------------------------

## 15. How CEFFLO Works

Use PayGin's numbered communication clarity.

### 01 --- Orders

Today's orders enter the operation.

### 02 --- Plan

Organize coverage, zones and delivery runs.

### 03 --- Dispatch

Assign the right run to the right rider.

### 04 --- Deliver

Riders execute stops while delivery progress stays visible.

The visual flow may later expose more detail:

**Orders → Zones → Runs → Riders → Delivered**

But the first communication layer should remain easy to understand.

------------------------------------------------------------------------

## 16. Operational Story

After the simple numbered explanation, zoom into real product surfaces.

### TODAY'S ORDERS

**Every delivery starts in one place.**

Use real Vendor Orders presentation.

### DELIVERY ZONES

**Organize where today's orders need to go.**

Use Vendor map/zone UI.

### MULTI-DROP RUNS

**Turn a busy delivery day into clear runs.**

Use Zone Detail / run planning UI.

### DRIVER APP

**Every rider knows what comes next.**

Use a dedicated mobile-product moment.

### CUSTOMER TRACKING

**Keep customers informed without extra calls.**

Use Customer Tracking PWA.

------------------------------------------------------------------------

## 17. Driver Showcase

Use Upwize's dedicated mobile-product composition pattern.

Give the Driver App one major moment instead of repeatedly showing tiny
phones.

Concept:

``` text
          NEXT STOP

             ┌───────────┐
             │           │
             │  DRIVER   │
             │   APP     │
             │           │
             └───────────┘

DELIVERY STATUS       ISSUE / PROOF
```

The phone remains the visual anchor.

Small supporting capability callouts may sit around it.

Do not overload the composition.

------------------------------------------------------------------------

## 18. Real Product Visual Lock — NON-NEGOTIABLE

> **Real product. Marketing composition.**

Every CEFFLO product UI displayed on the Public Website must originate from a **real render of the canonical application**.

This applies to:
- Vendor Mobile
- Vendor Web/Desktop
- Driver Mobile
- Customer Tracking
- Storefront
- any other CEFFLO product surface shown publicly

### Required capture pipeline

```text
CANONICAL APP
→ RUN REAL APP
→ NAVIGATE TO REAL SCREEN
→ CAPTURE REAL SCREENSHOT
→ USE THAT CAPTURE IN WEBSITE COMPOSITION
```

Never use this pipeline:

```text
REFERENCE / EXISTING SCREEN
→ REDRAW / RECREATE / APPROXIMATE
→ FAKE MARKETING UI
```

Claude/Fable must **not** manually reproduce a CEFFLO screen using HTML/CSS, React, SVG, image generation, newly created mock components, or visual approximation. It must not “improve” the underlying product UI for marketing.

The underlying captured product screen must not have its text, values, cards, icons, colors, spacing, controls, navigation, statuses or screen structure altered.

### Allowed website presentation treatment

Once a real product capture exists, the website may use:
- crop
- scale
- mask
- device frame
- browser frame
- controlled perspective
- clipping
- subtle shadow
- composition / overlap
- surrounding website background treatment

These treatments must not alter the underlying product UI.

### Product data and floating states

Do not invent operational numbers or states and present them as if they came from the product. If a marketing composition needs values such as order counts, rider counts, run states or delivery states, use values from an intentional real demo/seeded environment or clearly separate the element as website copy rather than product UI.

### Failure rule

If the required canonical product screen cannot be rendered or captured, **STOP AND REPORT IT**. Do not substitute a recreated mockup.

### Storefront visual rule

Storefront visuals must follow the same real-render rule. Supplied Storefront concept/reference imagery may guide investigation of the intended capability, but it is not permission to recreate or advertise a Storefront capability that is not verified in the canonical product/repository.

------------------------------------------------------------------------

## 19. Capability Micro-UI

Use only if it improves the story.

Possible modules:

**CAPTURE** --- Orders\
**ORGANIZE** --- Zones\
**PLAN** --- Runs\
**DISPATCH** --- Riders\
**TRACK** --- Customers\
**CONTROL** --- Today's operation

Use real micro-UI.

Avoid generic icons.

### Restraint rule

This section must not become six equal cards merely because six
capabilities exist.

Use asymmetric composition, grouped demonstrations, or fewer visible
modules where cleaner.

------------------------------------------------------------------------

## 20. Built for Today

A Makro-style visual reset after denser product storytelling.

Label:

**BUILT FOR TODAY**

# One delivery day.

# One operating view.

Possible supporting concepts:

**Visibility**\
Know what's happening now.

**Control**\
Know what needs attention.

**Execution**\
Move orders from ready to delivered.

Anchor with one large Vendor Today visual.

------------------------------------------------------------------------

## 21. Product Ecosystem

Keep this compact.

### Vendor

Operate today's delivery.

### Driver

Execute assigned runs and stops.

### Customer Tracking

Keep customers informed once delivery begins.

The section should communicate that these surfaces operate as one
system.

Do not turn it into another feature-card wall.

------------------------------------------------------------------------

## 22. FAQ

Conversion FAQ, not Help Centre.

Suggested topics: - What is CEFFLO? - Is CEFFLO a delivery
marketplace? - Do I need my own riders? - Can customers track
deliveries? - Can I organize deliveries by zone? - Does CEFFLO work for
bakeries, meal prep, florists and similar businesses? - Can riders use
their phones?

Answers must come from CEFFLO product truth.

------------------------------------------------------------------------

## 23. Final CTA

Borrow Zappy's idea of closing with product energy, but keep AppDrop
restraint.

Working direction:

# More orders shouldn't mean more chaos.

or:

# Ready to run delivery differently?

Primary CTA: **Get started**

A controlled Vendor + Driver composition may rise into the CTA section.

Do not create another giant feature section.

------------------------------------------------------------------------

## 24. Footer

Clean and functional.

Suggested groups:

**Product** - Product - How it works - Solutions

**Company** - About - Contact

**Resources** - Cefflo Academy - Help

**Legal** - Privacy - Terms

Include Sign in / Get started where appropriate.

Do not invent unavailable social channels.

------------------------------------------------------------------------

# SECONDARY PAGES

## 25. Legal Page System

Use Arewno as presentation inspiration only.

Create one reusable legal-page system for:

-   Terms of Service
-   Privacy Policy

Structure:

``` text
LEGAL

Terms of Service.

Short introduction
Last updated: [real date]


01
Section title
Body

02
Section title
Body

03
...
```

Characteristics: - oversized page title - large whitespace - numbered
sections - strong typography - same public navigation/footer -
comfortable reading width

Do not copy Arewno's legal wording.

Legal content must be CEFFLO-specific and appropriate to the actual
business/legal requirements.

------------------------------------------------------------------------

## 26. Cefflo Academy

Future content may cover: - same-day delivery planning - delivery
zones - multi-drop operations - rider execution - operational growth -
F&B/bakery delivery operations

Do not delay v1 website waiting for a full content engine.

------------------------------------------------------------------------

# TRUST & CONTENT RULES

## 27. No Fabricated Proof

Do not invent: - customer logos - testimonials - ratings - user counts -
delivery counts - GMV - ROI - savings - awards - media coverage -
partner logos - statistics

The website must look credible without fake proof.

------------------------------------------------------------------------

## 28. Pricing

Do not invent pricing.

If CEFFLO pricing is not formally locked: - omit pricing from v1, or -
use a non-price conversion section if approved

Never fabricate RM tiers.

------------------------------------------------------------------------

# MOTION

## 29. Motion Language

Motion supports product storytelling.

### Page load

-   soft hero text reveal
-   slightly delayed product reveal

### Scroll

-   approximately 20--40px Y movement
-   opacity transition
-   subtle stagger

### Product surfaces

-   extremely light independent motion if useful

### Hover

-   approximately 2--4px response
-   subtle border/surface response

### Buttons

-   approximately 150--220ms

### Section reveal

-   starting range approximately 450--700ms

Avoid: - aggressive parallax - constant floating - excessive spring
animation - motion for decoration alone

Support:

`prefers-reduced-motion`

------------------------------------------------------------------------

# RESPONSIVE

## 30. Required QA Widths

-   390px
-   430px
-   768px
-   1440px
-   1920px

Mobile must be intentionally composed.

Do not simply shrink desktop.

### Hero

Desktop:

``` text
TEXT                  PRODUCT
```

Mobile:

``` text
TEXT
CTA

PRODUCT
SECONDARY PRODUCT
```

### Feature sections

Desktop can alternate.

Mobile generally becomes:

``` text
LABEL
HEADLINE
BODY
VISUAL
```

### Product visuals

Crop/recompose rather than shrinking until unreadable.

------------------------------------------------------------------------

# FINAL HOMEPAGE ARCHITECTURE

## 31. v2 Recommended Sequence

The homepage should stay focused.

### 01 --- Navigation + Hero

Clean proposition + dominant product visual.

### 02 --- The Challenge

Explain why growing local delivery becomes difficult.

### 03 --- Who It's For

Business categories.

### 04 --- Plan / Dispatch / Deliver

Three-part mental model.

### 05 --- How CEFFLO Works

01 Orders → 02 Plan → 03 Dispatch → 04 Deliver.

### 06 --- Operational Story

Orders → Zones → Runs → Driver → Tracking.

### 07 --- Driver Showcase

Dedicated mobile-product moment.

### 08 --- Built for Today

Large visual reset around Vendor Today.

### 09 --- Product Ecosystem

Vendor → Driver → Customer Tracking.

### 10 --- FAQ

Resolve objections.

### 11 --- Final CTA + Footer

Strong product-led close.

### Optional

Capability micro-UI can be integrated inside the operational story
rather than becoming a separate large section if the page is cleaner
without it.

This is intentionally simpler than Visual Spec V1.

------------------------------------------------------------------------

# REPOSITORY SAFETY

## 32. Independent Workstream

Public Website implementation must use a dedicated branch/worktree.

Do not modify:

-   `apps/vendor_mobile/`
-   `apps/rider_mobile/`
-   `vendor/`
-   `customer/`
-   `foundr/`
-   `invite/`
-   backend lifecycle
-   DB schema
-   migrations
-   canonical RPCs
-   active Phase 2B work
-   another Claude session's worktree

Do not merge directly into `claude/canonical-integration`.

------------------------------------------------------------------------

# IMPLEMENTATION WORKFLOW

## 33. Gate 2

### Step 1 --- Read SOT

Read CEFFLO website, brand and product truth.

### Step 2 --- Isolate

Create dedicated Public Website branch/worktree.

### Step 3 --- Foundation

Implement only necessary: - typography - spacing - container - color
tokens - buttons - product frames - navigation - breakpoints - basic
motion primitives

Do not build a giant design system.

### Step 4 --- NAV + HERO ONLY

Implement only: - navigation - hero - product composition

Render:

**1440px + 390px**

Then visually inspect.

Do not continue until hero quality is acceptable.

### Step 5 --- Section-by-Section

For every section:

``` text
IMPLEMENT
↓
RENDER
↓
SCREENSHOT
↓
REVIEW
↓
FIX
↓
LOCK
↓
NEXT
```

### Step 6 --- Motion

Only after static composition works.

### Step 7 --- Responsive

Intentional tablet/mobile compositions.

### Step 8 --- Full QA

Check all required widths.

### Step 9 --- Cleanup

Remove: - dead CSS - abandoned variants - duplicate components - unused
assets - temporary experiments

### Step 10 --- Qualification

-   build
-   test
-   route checks
-   no secrets
-   no canonical product/backend modifications
-   clean branch
-   commit
-   push
-   report exact SHA

Do not merge without Founder approval.

------------------------------------------------------------------------

## 34. Stop Conditions

Stop and report rather than guessing if:

-   product truth conflicts with website copy
-   required product visual does not exist
-   canonical product UI would need modification
-   backend work appears necessary
-   deployment conflicts with existing routes
-   another active workstream owns the same files
-   pricing/social proof would need fabrication

------------------------------------------------------------------------

# DEFINITION OF DONE

## 35. Quality Bar

The website is ready for integration only when:

-   CEFFLO identity is unmistakable
-   hero communicates the product quickly
-   page feels clean before it feels clever
-   operational story is understandable
-   real product UI drives the visual system
-   no fake proof/pricing exists
-   desktop is polished
-   mobile is intentionally composed
-   motion is restrained
-   legal/static pages share the same design language
-   canonical products/backend remain untouched
-   dead code is removed
-   build/tests pass
-   branch is clean
-   exact pushed SHA is reported
-   Founder approves the visual result

------------------------------------------------------------------------

# FINAL LOCK

## 36. Reference Responsibilities

**AppDrop** → cleanliness and simplicity

**Makro** → premium hierarchy and product storytelling

**PayGin** → numbered operational communication

**Zappy** → small doses of layered product energy

**Upwize** → dedicated Driver/mobile showcase

**Arewno** → legal/static page presentation

**CEFFLO** → identity, product truth, terminology, lifecycle and brand

------------------------------------------------------------------------

## 37. Final Visual Principle

> **Clean first. Premium second. Product always.**

And:

> **Large type. Massive space. Short copy. Real product. Strong crops.
> Controlled layering. Minimal palette. Restrained motion.**

The storytelling spine remains:

> **Orders come in → CEFFLO organizes → riders execute → customers track
> → delivered today.**

Do not add complexity merely because the references contain it.
------------------------------------------------------------------------

# 38. COMMERCIAL / PRODUCT TRUTH UPDATE — 2026-09-26

This section supersedes any older website assumption that conflicts with the
repository/product-truth audit.

The visual direction above remains locked. The commercial story below is now
the current website truth.

## 38.1 Current Publishable Product Story

CEFFLO is the local same-day delivery operating system for businesses that
run their own delivery operation.

Core category message:

> **Don't just send deliveries. Run delivery.**

CEFFLO is not a food marketplace, rider marketplace, courier aggregator or
delivery marketplace.

The business owns:
- its customers
- its sales channel
- its riders/drivers
- its delivery operation

CEFFLO organizes the operation:

> **Orders → Coverage → Zones → Delivery Plan → Multi-drop Runs → Riders → Delivered Today**

The commercial story must explain not only HOW CEFFLO works, but WHY the
business needs it.

Use the doctrine:

> **GROW = OPERATE**

Meaning: more orders are valuable only when the business can organize, plan,
dispatch and deliver them reliably every day.

## 38.2 Capabilities Safe to Present as Current Product Capability

The repository/product-truth audit verified these operational capabilities:

- Manual order creation
- CSV bulk import into canonical orders
- Excel/XLSX bulk import into canonical orders
- Today dashboard
- Order lifecycle and approval gate
- Coverage checks
- Delivery zones
- Deterministic Suggested Runs / delivery planning
- Human review before dispatch
- Motorcycle / Car / Van classification
- Rider capacity handling
- Order vehicle requirements
- Run Builder
- Multi-drop runs
- Enforced stop order
- Active Runs / Run Detail
- Need Attention
- Delivery issue reporting
- Recovery / reschedule with history preserved
- Rider/team invitation, approval and deactivation
- Rider reassignment
- Driver/Rider run execution
- POD
- Customer tokenized tracking
- Truthful delivery status
- Coarse stop-count-based arrival window
- POD availability after delivery
- Customer rating

Do not convert deterministic planning into an "AI route optimization" claim.

Do not claim live GPS, real-time rider tracking or precise arrival-time
prediction.

## 38.3 Order Intake Story

The website may truthfully communicate:

> **Bring your orders in.**

Current supported intake story:
- Manual entry
- CSV import
- Excel/XLSX import

Do not claim:
- Google Sheets sync
- Google Drive sync
- public API
- POS integrations
- e-commerce integrations
- webhook intake
- WhatsApp/SMS integrations

until those capabilities genuinely ship.

Do not create a fake integrations logo wall.

Preferred commercial framing:

> **Keep taking orders your way. CEFFLO runs what happens next.**

When referring to spreadsheets, say import. Never imply continuous sync.

## 38.4 Storefront Boundary

Storefront has real backend foundations, but the customer-facing storefront
is not yet a shipped live product surface.

Therefore:

- Do not present Storefront as a current LIVE capability.
- Do not present "No website required" as a current LIVE promise.
- Do not use prototype Storefront UI as though it were a shipped product.
- Do not imply arbitrary brand customization.
- Do not imply an unrestricted website builder.

The long-term commercial direction remains useful:

> **Your own storefront. Your brand. Your customers. Orders flow into the same delivery operation.**

Until the real Storefront ships, keep this out of the main current-capability
story unless it is explicitly labelled as in development.

## 38.5 Pricing Boundary

Pricing architecture exists internally but current numerical prices, limits,
allowances and tier values are not publication-ready.

Therefore:

- Never invent RM prices.
- Never publish candidate prices as final.
- Never invent quotas, rider limits, delivery caps, trials or discounts.
- The website architecture may reserve Pricing for later.
- If pricing is not Founder-locked at implementation time, omit public price
  values rather than filling the section with placeholders.

## 38.6 Feature → Problem → Outcome

Do not market CEFFLO as a list of software features.

Every major capability should communicate:

> **Feature → Problem removed → Business outcome**

Examples:

**Today + Need Attention**
→ owner no longer reconstructs the operation from chats and memory
→ one view of today's delivery operation and its exceptions.

**Manual / CSV / Excel intake**
→ orders from existing workflows do not need to remain scattered
→ they enter one delivery operation.

**Coverage + Zones**
→ delivery area decisions stop being ad-hoc
→ orders can be organized before dispatch.

**Suggested Runs + review**
→ the owner does not build every run from zero
→ CEFFLO proposes an operational plan and the business confirms it.

**Vehicle + capacity**
→ unsuitable loads are less likely to be assigned to the wrong rider/vehicle
→ plans are more operationally executable.

**Multi-drop Driver execution**
→ riders do not rely on scattered WhatsApp instructions
→ the next stop and delivery progression are organized in one flow.

**Customer Tracking**
→ customers do not need to depend entirely on manual status messages
→ they can see truthful delivery progress themselves.

**Recovery / reschedule**
→ failed deliveries do not silently disappear
→ they remain part of the operational record and can re-enter planning.

------------------------------------------------------------------------

# 39. FINAL HOMEPAGE ARCHITECTURE

Use this as the current homepage structure.

## 01 — Navigation

Minimal. Clear. No oversized SaaS navigation system.

## 02 — Hero

Purpose: explain what CEFFLO is immediately.

Direction:

> **Run local delivery. Without the chaos.**

Support the category:
CEFFLO is the operating system for businesses running their own local
same-day delivery.

The dominant visual must be REAL CEFFLO product capture(s).

## 03 — The Problem

Story:

> **More orders are good — until the operation cannot keep up.**

Use GROW = OPERATE naturally here.

Show the operational problem, not generic startup pain.

## 04 — The Category Difference

Core idea:

> **Don't just send deliveries. Run delivery.**

Explain the distinction between fulfilling individual delivery jobs and
running the business's whole local delivery operation.

Do not name competitors in the default page.

## 05 — Built for Local Delivery

Keep compact.

Relevant examples may include:
- F&B
- bakeries
- meal prep
- florists
- gifts
- beauty
- local retail

Do not use fake customer logos.

## 06 — How CEFFLO Works

Use the PayGin-style numbered clarity:

01 Orders
02 Plan
03 Dispatch
04 Deliver

Use real product crops where useful.

## 07 — Bring Your Orders In

Show the current truthful intake methods:

Manual · CSV · Excel

Use a REAL import/product capture.

No fake integrations.

## 08 — Operate Today

Primary Vendor product showcase.

Story:
Today → Orders → Zones → Runs → Need Attention

Use real CEFFLO Vendor capture(s).

## 09 — Driver Execution

Dedicated mobile execution moment.

Story:
assigned run → next stop → delivery progression → POD / issue → completion.

Use only real current product captures.

## 10 — Customer Tracking

Show the real Customer Tracking product.

Communicate:
customers can see delivery progress without relying entirely on manual status
communication.

Do not show invented GPS maps or precise ETA.

## 11 — Why Businesses Use CEFFLO

Keep this outcome-led, not a six-card feature dump.

Prioritize:
- many orders become one organized delivery day
- multi-drop by design
- own delivery team
- customers remain the business's customers
- review before dispatch
- one view of today
- customer delivery visibility
- operational recovery when things go wrong

Use 3–4 strong ideas rather than every feature.

## 12 — Pricing

Only show public pricing if Founder-locked values exist at implementation
time.

Otherwise omit the public pricing values/section cleanly.

Do not fabricate.

## 13 — FAQ

Cover real commercial objections:

- What is CEFFLO?
- Is CEFFLO a delivery marketplace?
- Do I need my own riders?
- Can I import my spreadsheet?
- Can customers track deliveries?
- What businesses is CEFFLO built for?
- Do I need my own website? — answer only from current Storefront truth.
- What does CEFFLO cost? — answer only when pricing is locked.

## 14 — Final CTA + Footer

CTA must match actual availability at implementation time.

Do not imply self-serve production access if it does not exist.

------------------------------------------------------------------------

# 40. CANONICAL CEFFLO COLOR VALUES — HARD LOCK

Do not use a random blue.

Use the canonical values already present in CEFFLO product code:

- Brand Blue: `#0B5FE3`
- Gradient Start: `#0633A8`
- Gradient Mid: `#0848CC`
- Gradient End: `#0A6BE6`
- Mustard Yellow: `#FEC819`
- Dark Navy: `#12213E`

Canonical gradient direction:

> **#0633A8 → #0848CC → #0A6BE6**

The supplied CEFFLO product screenshots are the visual acceptance reference.

Do not:
- approximate these colors by eye
- invent a "premium blue"
- use AppDrop/Makro/Zappy colors
- replace the gradient with a generic SaaS gradient
- reintroduce Signal Lime

Reference websites influence composition, hierarchy, whitespace and
storytelling only.

CEFFLO controls the brand.

------------------------------------------------------------------------

# 41. REAL PRODUCT VISUAL LOCK — NON-NEGOTIABLE

> **Real product. Marketing composition.**

Every CEFFLO product UI displayed on the Public Website must originate from
a real rendered canonical CEFFLO product surface.

Applies to:
- Vendor Mobile
- Vendor Web/Desktop
- Driver/Rider product
- Customer Tracking
- Storefront, once it is genuinely shippable
- any other CEFFLO product surface shown publicly

Required pipeline:

> **CANONICAL APP → RUN REAL APP → OPEN REAL SCREEN → CAPTURE REAL SCREENSHOT → USE CAPTURE IN WEBSITE**

Forbidden pipeline:

> **LOOK AT CEFFLO → REDRAW / RECREATE / APPROXIMATE → MARKET AS PRODUCT UI**

Never:
- manually rebuild CEFFLO UI in HTML/CSS for marketing
- recreate it in React/SVG
- AI-generate a CEFFLO screen
- draw a fake "close enough" product screen
- change product text, values, cards, icons, colors, controls or layout inside
  the capture
- invent floating product states that appear to be actual CEFFLO UI

Allowed presentation treatment:
- crop
- scale
- mask
- device frame
- browser frame
- clipping
- controlled perspective
- subtle shadow
- overlap/composition
- website background treatment

The underlying product capture remains real and untouched.

If a required screen cannot be rendered, do not fake it. Use another genuine
surface or omit that visual until the real surface is available.

------------------------------------------------------------------------

# 42. EXECUTION — POLISH THE EXISTING WEBSITE NOW

This is an EXECUTION instruction.

Do not return another audit.
Do not return another strategy report.
Do not create another planning document.
Do not stop after describing what should change.
Do not rebuild the project from zero merely to make implementation easier.

Use this MASTER as the source of truth and directly improve the existing
CEFFLO Public Website implementation.

## 42.1 Goal

Take the existing Public Website HTML/site and bring it to the visual,
commercial and product-truth standard defined by this MASTER.

Preserve good existing work.

Replace what is wrong.

Remove what is obsolete.

Finish the website.

## 42.2 Required Work

1. Open the existing Public Website implementation.

2. Apply the final homepage architecture in §39.

3. Preserve the locked visual direction:
   - AppDrop cleanliness
   - Makro premium hierarchy and whitespace
   - PayGin numbered communication
   - small controlled Zappy product energy
   - Upwize-style dedicated Driver/mobile presentation
   - Arewno legal/static presentation
   - CEFFLO identity above all references

4. Apply the exact canonical CEFFLO colors from §40.

5. Replace any recreated/fake CEFFLO product UI currently used in the
   website with real rendered captures as required by §41.

   In particular, do not keep hand-built HTML approximations of Driver or
   Customer Tracking product UI.

6. Use real CEFFLO product captures for Vendor, Driver/Rider and Customer
   Tracking.

7. Do not redesign the canonical applications to make the marketing page
   easier.

8. Rewrite/polish website copy so the page answers:
   - What is CEFFLO?
   - Why do I need it?
   - What operational problem does it solve?
   - How do orders enter?
   - How does the operation work?
   - What happens for the rider?
   - What does the customer see?
   - Why is CEFFLO different from simply sending individual delivery jobs?

9. Add the truthful Manual / CSV / Excel order-intake story.

10. Do not add fake integrations.

11. Do not market Storefront as LIVE until it is genuinely shipped.

12. Do not invent pricing.

13. Do not use:
    - AI route optimization claims
    - live GPS claims
    - real-time rider tracking claims
    - precise ETA claims
    - fake testimonials
    - fake customer logos
    - fake usage metrics
    - fake social proof

14. Keep sections spacious.
    Do not solve every communication problem by creating another card.

15. Maintain:
    - large typography
    - strong hierarchy
    - massive whitespace
    - short copy
    - real product imagery
    - controlled layering
    - restrained motion
    - premium responsive composition

16. Desktop and mobile must both be intentionally composed.
    Do not simply shrink the desktop layout.

17. Ensure no horizontal overflow, broken crops, clipped text, awkward
    section gaps, or mobile stacking problems.

18. Keep canonical Vendor/Driver/Customer/backend code untouched except for
    the normal process required to run/capture the real product surfaces.
    The website consumes captures; it does not redesign those products.

## 42.3 Work Style

Do the work directly.

Do not pause after every section asking for permission.

Use the MASTER to resolve normal implementation decisions.

For each section internally follow:

> **IMPLEMENT → RENDER → VISUAL QA → FIX → CONTINUE**

Do not send intermediate audit reports unless a genuine blocker prevents
completion.

## 42.4 Visual QA

Render and review the completed website at minimum:

- 390px mobile
- 430px mobile
- 768px tablet
- 1440px desktop
- 1920px wide desktop

Check the entire page, not only the hero.

Verify:
- typography
- spacing
- hierarchy
- product screenshot integrity
- gradient accuracy
- responsive composition
- section transitions
- CTA clarity
- footer/legal consistency
- no fake product UI remains

## 42.5 Cleanup

Before completion:

- remove obsolete replaced markup/styles/assets
- remove dead CSS created by the old composition
- do not leave patch-on-patch overrides
- consolidate the final implementation cleanly
- run the relevant build/tests
- ensure the working tree contains only intentional website changes

## 42.6 Completion

Do not stop at a proposal.

Complete the website polish.

Then report only:

1. what was materially improved
2. which real CEFFLO product captures were used
3. build/test result
4. responsive QA result
5. any genuine blocker that could not be resolved
6. exact commit SHA
7. pushed branch

The implementation is complete only when the existing CEFFLO Public Website
has been materially polished to match this MASTER and the final rendered page
has passed visual QA.

------------------------------------------------------------------------

# FINAL MASTER LOCK

> **Clean first. Premium second. Product always.**

> **Real product. Marketing composition.**

> **Don't just send deliveries. Run delivery.**

> **Orders come in → CEFFLO organizes → riders execute → customers track → delivered today.**

No more audit phase is required before website polishing unless the underlying
product truth materially changes.
