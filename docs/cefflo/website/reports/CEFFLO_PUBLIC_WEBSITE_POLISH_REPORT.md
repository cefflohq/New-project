# CEFFLO PUBLIC WEBSITE — COMMERCIAL + PRODUCT STORY POLISH REPORT

> **HISTORICAL REPORT / INPUT TO MASTER (D-67). Not authoritative.**
> Implementation-state observations here are point-in-time findings from
> 2026-09-26 and may be superseded by later engineering decisions and state
> (e.g. D-62 removed the Rider PWA; D-63 made Driver Flutter the live Driver
> client on staging; D-65 Customer Tracking). It must **not** be treated as
> current Product Truth. Current website authority:
> `../CEFFLO_PUBLIC_WEBSITE_MASTER.md`; product truth: `docs/cefflo/sot/`.

**Status:** Polish Report for Founder Review — no implementation performed
**Date:** 2026-09-26
**Input:** `CEFFLO_PUBLIC_WEBSITE_VISUAL_SPEC_V2_FINAL.md` (visual direction — LOCKED, untouched)
**Method:** Direct repository/product-truth inspection. Every classification below cites its evidence. Nothing in this report modifies the website, the spec, canonical products, or backend.
**Next step:** Founder review → `CEFFLO_PUBLIC_WEBSITE_MASTER.md`

**Primary evidence set:**
`docs/cefflo/sot/01_PRODUCT_TRUTH.md` · `docs/cefflo/sot/11_CEFFLO_WEBSITE.md` · `docs/cefflo/sot/10_PRICING.md` (CANDIDATE) · `docs/cefflo/sot/07_BUSINESS_LAUNCH_COMMERCIAL.md` · `docs/cefflo/sot/marketing/02_CLAIMS_REGISTRY.md` · `docs/cefflo/launch/CEFFLO_GROW_V1_SCOPE_LOCK.md` (FROZEN 2026-09-03) · `docs/cefflo/flow3/VENDOR_BEHAVIOURAL_CONTRACT_PACK.md` (Flow 3 exit contract, complete) · `docs/cefflo/04_CURRENT_STATE.md` · `docs/cefflo/05_DECISIONS.md` (D-29…D-45) · `supabase/migrations/*` (51 migrations, inspected through F2-09) · live clients `vendor/`, `rider/`, `customer/` · `apps/vendor_mobile/` (DEV/STAGING).

---

## 0. ONE GLOBAL TRUTH THE WHOLE WEBSITE MUST RESPECT

Two different facts must never be blended:

1. **The product spine is substantially real.** Since the Scope Lock snapshot (2026-09-03), Flow 2 built the entire missing engine (geocoding, coverage, vehicle/capacity, deterministic planning, CSV/XLSX canonical commit, truthful ETA, recovery — migrations `202609030001–0012`, `202609040001–0005`) and Flow 3 wired it into the live Vendor Web client and verified it screen by screen. "LIVE" in this report means: **implemented, canonical, wired into a shipped client, verified in the Flow 3/staging environment.**
2. **CEFFLO is commercially pre-launch.** No production go-live has occurred; `cefflo.com` is parked; product subdomains were NXDOMAIN at last verification (`04_CURRENT_STATE.md` CS-05); the Release Candidate and Go-Live gates of `07_BUSINESS_LAUNCH_COMMERCIAL.md` §9–§15 have not run; subscription billing (Curlec) is not implemented (V-50–V-54 HOLD).

Consequence for the website: **capability claims can be truthful and confident** ("this is what CEFFLO does"), but **availability claims and the CTA are governed by launch state** (`11_CEFFLO_WEBSITE.md` Phase 03 = pre-launch landing with Early Access/Waitlist CTA; `07_BUSINESS_LAUNCH_COMMERCIAL.md` §13 "CTA matches availability"). This is Founder Decision FD-01 in section L.

---

## A. WHAT V2 ALREADY GETS RIGHT

1. **Reference discipline is correct and should not be reopened.** Assigned roles (AppDrop/Makro primary; PayGin/Zappy/Upwize/Arewno as specific patterns), explicit conflict-priority order, and the anti-Frankenstein rule are all sound.
2. **Color lock is correct and matches product truth.** The canonical token set exists in code (`apps/vendor_mobile/lib/core/theme.dart`: brand `#0B5FE3`, gradient `#0633A8 → #0848CC → #0A6BE6`, mustard `#FEC819`, navy `#12213E`) — the spec's "use exact repo values" rule is executable today. Signal Lime retirement matches D-33.
3. **Real Product Visual Lock (§18) is exactly right** and aligns 1:1 with `02_CLAIMS_REGISTRY.md` §16 (visual claim gate) and §7 (prototype presented as production = RED).
4. **The operational story arc is truthful.** §14–§16 (Plan/Dispatch/Deliver → numbered How-It-Works → Orders/Zones/Runs/Driver/Tracking) maps directly onto the verified operating spine — nothing in that arc overclaims.
5. **Trust rules (§27–§28) already prevent the classic failure modes** (fake logos, testimonials, invented pricing). The report below only extends them with evidence, it does not need to correct them.
6. **The §31 sequence is a strong skeleton.** The recommended architecture in section F keeps most of it; the commercial gap is filled by *inserting and sharpening*, not redesigning.
7. **Driver dedicated showcase (§17)** is the right call — execution is one of the strongest verified parts of the product (enforced stop order, POD, issue reporting all LIVE in the Rider PWA).

## B. WHAT IS MISSING / WEAK (commercially)

1. **No category-difference section.** V2 explains HOW CEFFLO works but never answers "why CEFFLO if Lalamove/Grab exist?" The distinction (fulfil delivery jobs vs. run your own delivery operation) is fully supported by Product Truth §1/§3 and Claims Registry §4/§11 — it is safe to say and currently unsaid.
2. **"The Challenge" (§12) states the problem but not the stakes.** GROW = OPERATE exists as doctrine but is not woven into the story ("more orders are good — until the operation cannot keep up"). Section D/E below supplies the verified language.
3. **No order-intake story.** "How do my orders enter CEFFLO?" is one of the ten commercial questions and is answerable with verified truth (manual + CSV + XLSX are LIVE) — V2 never addresses it.
4. **No outcome layer.** V2 sections show product surfaces; none states the problem removed or the business outcome (task §13). Section E supplies a verified Feature → Problem → Outcome matrix.
5. **No pricing architecture, even as a reserved structure.** Correctly omitted values, but the *section architecture* question was left unresolved. Section I resolves what it must communicate and what stays Founder-gated.
6. **Storefront is invisible in V2** — yet it is REQUIRED V1 canonical scope (Scope Lock §4.8) with a real backend contract. It cannot be sold as LIVE (see G), but pretending it doesn't exist forfeits the strongest future commercial story. It needs an explicit, gated position.
7. **FAQ topics don't cover the commercial objections** ("do I need my own website?", "can I keep my spreadsheet?", "what does it cost?"). Verified answers exist for the first two; the third is Founder-gated.
8. **Ecosystem loop is fragmented.** Vendor → Driver → Customer appears in three separate sections but the closed loop ("one connected delivery flow") is never shown as one picture.

---

## C. PRODUCT / COMMERCIAL TRUTH MATRIX

Classification per task §7, mapped onto Product Truth §10 states:
**LIVE** = implemented + wired into a shipped client + Flow-verified (staging; see §0 launch-state caveat) · **PLANNED** = canonical approved scope, not yet live end-to-end · **NOT SUPPORTED** = must not appear as a product claim · **FDR** = Founder decision required.

### C-A. Order intake

| Capability | State | Evidence |
|---|---|---|
| Manual New Order (wizard) | **LIVE** | `create_delivery` RPC; Flow 3 §2, F3-03 PASS |
| CSV bulk import → canonical orders | **LIVE** | `import_orders_batch` (migration `…batch_5_csv_xlsx_canonical_commit`); Flow 3 F3-03 "bulk import already canonical"; parse→validate→preview→fix-row→commit |
| Excel/XLSX bulk import | **LIVE** | Same pipeline (XLSX.js parse path, same commit RPC) |
| Storefront order intake (backend) | **PLANNED** (backend LIVE, no shipped customer page — see C-B) | `submit_public_order`, `public_order_catalog` exist; zero client references them |
| Google Sheets connected intake | **PLANNED (conditional)** — "Desirable V1 if low-risk", else Post-V1 | Scope Lock §5/§10; not built |
| Google Drive intake | **PLANNED (conditional)** | Scope Lock §8: MISSING |
| Website form / webhook intake | **NOT SUPPORTED** (Post-V1) | Scope Lock §6/§8 |
| E-commerce / POS / public API intake | **NOT SUPPORTED** (out of scope V1) | Scope Lock §7 "speculative POS/API integrations" |

### C-B. Storefront

| Capability | State | Evidence |
|---|---|---|
| Public order page contract (slug, tokenized link, enable/disable, token rotation) | Backend **LIVE**; end-to-end **PLANNED** | `create_order_page`, `rotate_order_page_token`, `set_order_page_enabled` (migration s4-10e) |
| Product catalog (categories, products, price, status, reorder, archive) | Backend **LIVE**; vendor UI in live web client **absent** | s4-10a RPCs; Flow 3 §12: no storefront feature exists in `vendor/` |
| Product media pipeline (upload → processing → approval) | Backend **LIVE** | s4-10b RPCs |
| Customer-facing storefront page (shipped client) | **PLANNED** | No client calls `public_order_catalog`/`submit_public_order` (verified by repo-wide search); only `previews/s4-10d-order-page-theme` static preview |
| Storefront themes | **PLANNED**, deliberately bounded: **4 curated themes**, not a free brand builder | Scope Lock §7; Flow 3 §12 "no theming feature exists anywhere in this codebase" |
| Arbitrary color/brand customization | **NOT SUPPORTED** (explicitly out of scope) | Scope Lock §7 |
| Vendor Mobile storefront management screens (V-31–V-36) | **PLANNED** (DEV/STAGING, UI not locked) | `09_VENDOR_FLUTTER_60_SCREEN_MASTER.md` header; D-40 |

**Net:** "Your own storefront / no website required" is a **PLANNED** commercial story. It may not be published as live capability (Claims Registry §6: "arbitrary storefront customization" is AMBER; presenting an unshipped surface as available is RED §7).

### C-C. Operations (Vendor)

| Capability | State | Evidence |
|---|---|---|
| Today dashboard (real KPIs, Current Deliveries, Action Required — zero fabrication) | **LIVE** | Flow 3 §1, F3-02 PASS |
| Order lifecycle + explicit approval gate before pickup | **LIVE** | `approve_order`; enum `created → ready_for_pickup → picked_up → out_for_delivery → arrived → delivered` (+`issue`/`cancelled`); Flow 3 §4 |
| Address → coordinates (geocoding) | **LIVE at contract level; runtime gated on credential** | Edge Function `geocode-order` (Mapbox Permanent, Founder-locked provider); Flow 3 §18: "Mapbox Gate A blocked on a genuinely-missing credential in every environment checked" — **FDR-08** |
| Coverage (service area, in/out decision, never silently bypassed) | **LIVE** | `is_within_coverage`, `order_coverage_status`, `set_business_service_area`; Flow 3 §5 |
| Delivery Zones (create/rename/enable-disable) | **LIVE** — zones are named operational groupings; geographic intelligence lives in coverage + planning | Flow 3 §6; Scope Lock §11 design record |
| Deterministic delivery planning ("Suggested Runs" proposal) | **LIVE** — *explicitly not "AI route optimization"* | `propose_delivery_plan`; Flow 3 §7 F3-05 PASS; architecture lock Scope Lock §12 |
| Vehicle classification (Motorcycle/Car/Van) + per-rider capacity override | **LIVE** | Migration s4-11 batch 3 (`rider_vehicle_type`, `capacity_override`, `default_capacity_for_vehicle`); Flow 3 §9 |
| Order-level vehicle requirement (`any / motorcycle_ok / car_or_larger / van_required`) | **LIVE** (backend enum + planning check) | Same migration, `vehicle_requirement` column |
| Run Builder → review → explicit dispatch confirm | **LIVE** — nothing auto-dispatches | `build_rider_run` idempotent; Flow 3 §7 |
| Multi-drop runs, sequence lock, enforced stop order | **LIVE** | s4-06 batches; `save_run_sequence` (Rider-owned by design — locked boundary, Flow 3 §7) |
| Active Runs / Run Detail (real stops, issues, timeline) | **LIVE** | Flow 3 F3-06 (built in Flow 3) |
| Need Attention (unplannable orders + open issues + offline riders) | **LIVE** | Flow 3 §11, F3-09 |
| Delivery issue reporting (vendor + rider, typed reasons) | **LIVE** | s4-08 contract |
| Recovery / reschedule (history preserved, auditable, re-enters planning) | **LIVE** (Vendor-authorized only) | s4-11 batch 9 + F2-09; Flow 3 §11 |
| Rider & team management (invite → approve → deactivate; separate Team invitations) | **LIVE** | Flow 3 §9–§10 |
| Reassignment (pre-/post-dispatch reassign path) | **LIVE** (`reassign_rider` wired) | Flow 3 §2 RPC map |
| Vendor-facing ETA | **NOT SUPPORTED** — `compute_order_eta` hardened internal-only (F2-11); no Vendor ETA surface | Flow 3 §8/§18 |
| Notification delivery (push/WhatsApp/SMS) | **NOT SUPPORTED** — no backend exists | Flow 3 §13/§17 |
| Operations/Helper Prepare→Pack→Ready workspace | Backend states/RPCs built (s4-11 batches 6–7, 10); distinct surface **PLANNED** | Vendor dashboard shows real work-session data "where configured" (Flow 3 §1) — keep off the homepage |
| Vendor Web true desktop layout | **NOT SUPPORTED today** — live client renders a centered mobile column (max-width 760px) on desktop | Flow 3 §16, disclosed gap — constrains hero imagery (K-6) |

### C-D. Driver

The **live** delivery-workforce client is the **Rider PWA** (`rider/`). The **Cefflo Driver Flutter app** (42-screen master) is **PLANNED — not implemented** (D-37/D-38; `07_RIDER.md`).

| Capability | State | Evidence |
|---|---|---|
| Receive assigned runs; accept/decline | **LIVE** | s4-05/s4-06 contracts; Scope Lock §4.11 LIVE |
| Ordered multi-drop execution, enforced next-stop (cannot skip ahead) | **LIVE** | Sequence lock migration; Scope Lock §13 |
| Rider-owned stop resequencing (local knowledge) | **LIVE** — deliberately Rider-only | `save_run_sequence` gate; Flow 3 §7 |
| POD capture/upload | **LIVE** | s4-04 protected POD path |
| Issue reporting (typed reasons incl. vehicle breakdown) | **LIVE** | s4-08 |
| Live GPS / background location reporting | **NOT SUPPORTED as a claim** — backend tables/RPCs exist (F2-08), **no live client write path**; Rider Flutter background GPS is Flow 5 | Flow 3 §8; truthful-ETA migration comment records a prior "Remove false Rider GPS tracking claim" correction |
| Navigation handoff to maps app | **UNVERIFIED** — treat as NOT SUPPORTED for claims | Scope Lock §13 |
| History/profile | **LIVE** (as approved scope) | `07_RIDER.md` RI-03 |

### C-E. Customer

| Capability | State | Evidence |
|---|---|---|
| Tokenized tracking link, no account required | **LIVE** — token created with the order (`create_delivery` returns it) | Foundation migration; CT-04 |
| Truthful status (Picked Up → On The Way → Delivered mapping) | **LIVE** | `public_tracking`; `10_DELIVERY_LIFECYCLE.md` L-03 |
| Truthful coarse arrival window (stop-count-based range — never fabricated precision, never GPS-derived) | **LIVE** | s4-11 batch 8 (`compute_order_eta` inside `public_tracking`); customer client renders it ("arriving soon" state) |
| POD visibility after delivery | **LIVE** (availability flag; controlled access) | `public_tracking.pod_available`; s4-04 minimization |
| Rating after completion | **LIVE** | `submit_rating` |
| Live map / rider location for customer | **NOT SUPPORTED** | No GPS write path (C-D); Claims Registry §9 |
| Precise ETA ("arrives 3:47pm") | **NOT SUPPORTED** | Truthful-range doctrine, Scope Lock §16 |

### C-F. Integrations

| Integration | State | Evidence |
|---|---|---|
| CSV / Excel file import | **LIVE** (an import capability — honest to present under "bring your orders in", not as a logo-wall "integration") | C-A |
| Google Sheets / Google Drive | **PLANNED (conditional)** — must not appear on the site until built | Scope Lock §10 |
| Public API | **NOT SUPPORTED** (Enterprise/API entitlement is a pricing-candidate idea only) | Scope Lock §7; Pricing §9 |
| POS / e-commerce platforms | **NOT SUPPORTED** | Scope Lock §7 |
| WhatsApp / SMS customer messaging | **NOT SUPPORTED** | No backend; Claims Registry §6 |
| Mapbox (geocoding) | Internal provider, **not a vendor-facing integration claim** | geocode-order function |
| Razorpay Curlec (CEFFLO's own subscription billing) | **PLANNED** — locked gateway choice, zero implementation (V-50–V-54 HOLD) | `07_BUSINESS_LAUNCH_COMMERCIAL.md` §5–§6; 00_INDEX §10 |

**Net: CEFFLO currently has zero third-party integrations to display.** Section H handles this honestly.

### C-G. Customization (vendor-facing)

| Capability | State | Evidence |
|---|---|---|
| Business profile (name, phone, email, address, operating area) | **LIVE** | `update_business_profile`; Flow 3 §12 |
| Language (EN / BM / 中文 / தமிழ்) per user | **LIVE** (client-side, real) | Flow 3 §13 |
| Business logo | **NOT SUPPORTED** as shared asset — device-local only, honestly disclosed in-product | Flow 3 §12 |
| Storefront themes (4 curated) | **PLANNED** | C-B |
| Arbitrary brand builder | **NOT SUPPORTED** | Scope Lock §7 |

### C-H. Pricing / commercial model

| Item | State | Evidence |
|---|---|---|
| Tier architecture FREE RM0 / GROW RM99 / OPERATE RM199 ⭐ / SCALE RM499 / ENTERPRISE Custom | **FDR** — approved *direction candidate*, explicitly **NOT Founder-locked**; publication forbidden until locked | `10_PRICING.md` header + §16/§19; `00_INDEX.md` §9; `11_CEFFLO_WEBSITE.md` §2 (pricing on website only after lock, Phase 06) |
| Usage metric: 1 completed delivery = 1 unit; server-side ledger | Locked *principle* (P-05), values open | Pricing §3, §11 |
| Free tier exists permanently, full core loop, capped | Locked *principle* (P-01–P-03), caps open (100 vs 150 gate F-01) | Pricing §5 |
| Never interrupt an active delivery on quota | Locked principle (P-06 / Gate F) | Pricing §10, §18 |
| Subscription billing implementation | **PLANNED** (Curlec locked as gateway; nothing built) | C-F |

---

## D. VERIFIED CEFFLO USP

Every USP below is backed by LIVE capability (section C) and GREEN/verified-AMBER claim status (`02_CLAIMS_REGISTRY.md`). Ordered by commercial strength:

1. **YOU RUN DELIVERY — CEFFLO IS THE OPERATING SYSTEM.** The category difference itself. GREEN positioning (Claims §4). No competitor names needed (Claims §11).
2. **MANY ORDERS → ONE ORGANIZED DELIVERY DAY.** Orders → coverage → zones → plan → runs → riders → delivered today. The whole spine is LIVE (C-C).
3. **MULTI-DROP BY DESIGN.** Runs are multi-stop with locked sequence and enforced execution order — not one-order-one-trip. LIVE (C-C/C-D).
4. **YOUR OWN DELIVERY TEAM, PROPERLY EQUIPPED.** Trusted invitation → approval → vehicle type (motorcycle/car/van) → capacity → assigned runs. LIVE. Reinforces "not a rider marketplace" (GREEN).
5. **YOUR CUSTOMERS STAY YOURS.** No marketplace between the business and its customer; the business remains the customer-facing brand. GREEN doctrine (Claims §4).
6. **REVIEW BEFORE DISPATCH — THE PLAN IS YOURS TO CONFIRM.** Deterministic suggested runs + human review + explicit confirm. LIVE, and it converts the "no AI hype" constraint into a trust message (truthful planning language, Product Truth §12).
7. **ONE VIEW OF TODAY + KNOW WHAT NEEDS ATTENTION.** Real dashboard + Need Attention aggregation of real exceptions. LIVE.
8. **CUSTOMERS SEE PROGRESS WITHOUT CALLING YOU.** Tokenized tracking, truthful status, honest arrival window, POD, rating. LIVE — word carefully: no "live/real-time/GPS" language (Claims §9).
9. **WHEN A DELIVERY FAILS, THE OPERATION RECOVERS.** Auditable recovery/reschedule with history preserved. LIVE. (Understated but real differentiator vs. spreadsheets/chat coordination.)
10. *(HELD — not publishable yet)* **YOUR OWN STOREFRONT, NO WEBSITE REQUIRED** — PLANNED (C-B). **KEEP EXISTING SPREADSHEET WORKFLOW** is publishable *today* only in its import form: "Keep taking orders your way — bring the spreadsheet in; CEFFLO imports CSV/Excel into the canonical operation." Connected/sync wording is forbidden until Sheets exists.

## E. FEATURE → PROBLEM → OUTCOME MATRIX

| # | FEATURE (LIVE) | PROBLEM REMOVED | BUSINESS OUTCOME |
|---|---|---|---|
| 1 | Today dashboard + Need Attention | Owner reconstructs "where is everything?" from chat threads and memory | One operating view of the day; exceptions surface themselves |
| 2 | Manual + CSV/XLSX intake into one canonical order pool | Orders scattered across WhatsApp, forms and spreadsheets get re-keyed or lost | Every order enters one pipeline with the same tracking, history and plan |
| 3 | Coverage + zones | "Can we even deliver there?" decided ad-hoc per order | Deliverable area is explicit; out-of-coverage orders are caught before they burn a rider trip |
| 4 | Deterministic delivery planning (suggested runs) + review + explicit dispatch | Grouping today's orders into sensible runs takes an hour of manual puzzling | A proposed plan in front of you; the owner adjusts and confirms instead of building from zero |
| 5 | Vehicle & capacity aware assignment | A van-sized load lands on a motorcycle; one rider gets 14 stops, another gets 2 | Plans that are physically executable before dispatch, not after failure |
| 6 | Multi-drop runs with locked, enforced stop order | Riders freelance the route; stops get skipped and disputed | Every rider knows exactly what's next; execution matches the plan |
| 7 | Driver execution flow (run → stops → POD → complete) | "Delivered? Got proof? Which stop are you at?" over the phone | Progression and proof captured per stop, without calls |
| 8 | Customer tracking (status, honest window, POD, rating) | Customers ping the business for updates all day | Customers self-serve delivery visibility; the business stops being the status hotline |
| 9 | Recovery / reschedule with preserved history | A failed delivery falls out of the system and gets forgotten or double-handled | Failed deliveries re-enter the plan on record — nothing silently disappears |
| 10 | Trusted rider/team onboarding (invite → approve) | Workforce access managed by sharing logins and group chats | Controlled team access with real roles, without a marketplace in the middle |

Rule for the page (task §13): each homepage section leads with the PROBLEM or OUTCOME line; the FEATURE is what the real product visual demonstrates. Never ship a feature list without its outcome.

## F. RECOMMENDED FINAL HOMEPAGE ARCHITECTURE

Audit of the task's 18-section proposal: it is directionally right but 4 sections violate ONE SECTION = ONE IDEA or current product truth. Merges: **06+14** (intake and integrations are one truthful story today), **09+12** (Operate Today already shows the connected flow's vendor half; the closed loop belongs in a compact ecosystem moment, not two sections), **07** (Storefront) is gated by FD-03. Result — 14 sections:

| # | Section | One idea | Visual truth source |
|---|---|---|---|
| 01 | Navigation | — | — |
| 02 | **HERO** — what CEFFLO is | "Run local delivery. Without the chaos." + dominant real product composition | Per FD-04 (Vendor surface choice); floating states only from seeded demo data (spec §18) |
| 03 | **THE PROBLEM** | More orders are good — until the operation cannot keep up. (GROW = OPERATE woven here, not as an isolated slogan) | Calm, typographic; no product UI needed |
| 04 | **THE CATEGORY DIFFERENCE** | Delivery services fulfil delivery jobs. CEFFLO is the operating system for running your own delivery operation. "Don't just send deliveries. Run delivery." No competitor names. | Typographic + one contrast device |
| 05 | **BUILT FOR LOCAL DELIVERY** | F&B · Bakeries · Meal Prep · Florists · Gifts · Beauty · Local Retail (Product Truth §2 — real categories, no logos) | Text strip — keep small |
| 06 | **HOW CEFFLO WORKS** | 01 Orders → 02 Plan → 03 Dispatch → 04 Deliver (PayGin numbering) | Real micro-crops per step |
| 07 | **BRING YOUR ORDERS IN** | Keep taking orders your way — type them in or import the spreadsheet (Manual · CSV · Excel — all LIVE). *No Sheets/API/webhook claims.* | Real import UI capture (Vendor Web import preview table is real and impressive) |
| 08 | **OPERATE TODAY** | Vendor showcase: Today → Orders → Zones → Runs → Need Attention | Real Vendor captures |
| 09 | **DRIVER EXECUTION** | Every rider knows what comes next (Upwize composition) | **Real Rider client captures** (see K-2) |
| 10 | **CUSTOMER TRACKING** | Customers see progress without calling you | Real Customer Tracking PWA capture; no map/GPS visuals |
| 11 | **WHY BUSINESSES USE CEFFLO** | 3–4 outcome statements from section E (not six cards) | Typographic + small real crops |
| 12 | **PRICING** | Per FD-02: reserved architecture, or omitted in v1 | See section I |
| 13 | **FAQ** | Conversion objections (see below) | — |
| 14 | **FINAL CTA + FOOTER** | CTA per FD-01 (launch-state) | Controlled product rise (Zappy dose) |

- **Storefront**: when FD-03 approves an in-development treatment, it becomes section 07b ("Where orders will come from next") or a labelled sub-block of 07 — never a LIVE-implying standalone section until shipped.
- **One Connected Flow**: expressed as the hero composition's job (Vendor dominant, Driver overlapping, Tracking subtle — already V2 §11) plus one line in section 11; a dedicated section would repeat sections 08–10.
- **FAQ set (all answerable from truth today):** What is CEFFLO? · Is CEFFLO a delivery marketplace? (no) · Do I need my own riders? (yes — yours; CEFFLO doesn't supply riders) · Can I keep my spreadsheet? (yes — import CSV/Excel) · Do I need my own website? (**answer depends on FD-03**; truthful today: CEFFLO is not a website builder; storefront is in development) · Can customers track deliveries? (yes — link, no app) · Does it work for bakeries/meal prep/florists? (yes) · What does it cost? (per FD-02).

## G. STOREFRONT POSITIONING

**Truth:** backend contract complete (shareable slug page, tokenized catalog, public order submission, enable/disable, product catalog, media pipeline); four curated themes exist as a static preview only; **no shipped customer-facing page and no vendor UI in the live web client**; Vendor Mobile storefront screens are DEV/STAGING. Canonical scope: REQUIRED V1 (Scope Lock §4.8). Bounded by design: 4 curated themes, no arbitrary brand builder (Scope Lock §7).

**Positioning recommendation:**
1. The long-term story is exactly the task's instinct — *"Your own storefront. No website required."* with the flow choose template → brand it → add products → share link → orders enter the operation. **Do not publish any of it as current capability.**
2. For v1 of the website: either omit entirely (cleanest under Claims Registry), or — with explicit Founder approval per Claims §6 — one restrained, clearly-labelled block: "**In development** — a storefront that feeds orders straight into your delivery operation." No screenshots implying a live surface; the s4-10d preview may not be shown as product (spec §18 storefront rule).
3. When it ships, Storefront gets the *second* major commercial section (after Operate Today), framed as ownership: your brand, your customers, your link — orders land in the same canonical operation as every other order (true by architecture: `submit_public_order` → same orders table, same tracking, same lifecycle).
4. Never frame Storefront as a marketplace listing; it is the business's own page (Product Truth §3).

## H. VERIFIED INTEGRATION POSITIONING

**Truth: there are no third-party integrations to show.** A logo wall is impossible without fabrication (Claims §7 "fabricated integration" = RED).

**Recommendation:** replace the "Integrations" concept with the **order-intake story** (section F-07): *"Keep the way you take orders. CEFFLO runs what happens next."* — supported today by what is genuinely true:
- Orders arrive however they arrive (WhatsApp, calls, forms, repeat customers) — **the business types them in or imports the spreadsheet**. Manual + CSV + XLSX are LIVE; the comparative framing "a spreadsheet records information; CEFFLO connects the delivery operation" is explicitly pre-approved wording (Claims §11).
- Say "import", never "sync/connect/integrates with Google Sheets" — connected intake does not exist (C-F). When/if Sheets ships, this section upgrades naturally without restructuring.
- Mapbox and Curlec are internal/commercial plumbing, not marketable integrations.

## I. PRICING STRUCTURE / OPEN DECISIONS

**What exists:** a full candidate model — FREE RM0 (100/mo candidate) / GROW RM99 (500) / OPERATE RM199 ⭐ hero (1,500) / SCALE RM499 (5,000) / ENTERPRISE Custom — with locked *principles*: permanent meaningful free tier, completed-delivery as the usage unit, no per-rider pricing, scale-not-crippled-features, never interrupt an active delivery, stable list price + campaign promos, regional price books. **Every number is explicitly NOT Founder-locked** (`10_PRICING.md` §16/§19), and two independent gates forbid publication before lock: `07_BUSINESS_LAUNCH_COMMERCIAL.md` §4/§12 and `11_CEFFLO_WEBSITE.md` §2 (pricing is Phase 06 scope, "once 10_PRICING.md is Founder-locked, not before").

**What the future pricing section must communicate** (architecture to reserve now, populate later): plan names + monthly price; the usage unit ("completed deliveries per month"); rider/zone/team-user allowances per tier; what Free really includes (the full core loop); the hero-plan marker; the safety promise ("we never stop an active delivery"); annual/promo slots; Enterprise contact path.

**Open (all FDR):** publish-vs-omit for website v1; Free cap 100 vs 150 (Gate F-01); all allowances/caps; overage model; annual model; trial framing; multi-location entitlement; Enterprise qualification. **Recommendation:** website v1 ships with no pricing values; at most a "Simple plans. A free tier that runs real deliveries." teaser only if Founder approves that wording (it commits to locked principles P-01/P-03 without numbers) — otherwise omit the section entirely and reserve the architecture in the MASTER doc.

## J. SECTIONS FROM V2 (§31 SEQUENCE): KEEP / MERGE / MOVE / REPLACE / REMOVE

| V2 §31 section | Verdict | Note |
|---|---|---|
| 01 Navigation + Hero | **KEEP** | Copy gains the category label; CTA per FD-01 |
| 02 The Challenge | **KEEP (sharpened)** | Becomes THE PROBLEM with GROW = OPERATE woven in (F-03) |
| — *(absent in V2)* | **ADD** | THE CATEGORY DIFFERENCE (F-04) — the largest commercial gap |
| 03 Who It's For | **KEEP (compressed)** | Small strip (F-05); not a full section's weight |
| 04 Plan / Dispatch / Deliver | **MERGE** into How CEFFLO Works | Two adjacent sections teach the same mental model; PayGin numbering wins, Plan/Dispatch/Deliver becomes its internal grouping |
| 05 How CEFFLO Works | **KEEP** | F-06 |
| — *(absent in V2)* | **ADD** | BRING YOUR ORDERS IN (F-07) — intake + honest integration story |
| 06 Operational Story | **KEEP (renamed)** | OPERATE TODAY (F-08); absorbs §20 "Built for Today"'s Vendor-Today anchor |
| 07 Driver Showcase | **KEEP** | F-09; visuals must be real Rider client renders (K-2) |
| — *(split from 06)* | **KEEP** | CUSTOMER TRACKING as its own beat (F-10) |
| 08 Built for Today | **MERGE** into Operate Today | Its Visibility/Control/Execution triplet becomes section 11's outcome language; avoids two Vendor-anchored resets |
| 09 Product Ecosystem | **REPLACE** | Compact card-triplet replaced by WHY BUSINESSES USE CEFFLO (outcome layer, F-11) + the connected-loop line; the ecosystem-as-one-system idea moves into the hero composition |
| 10 FAQ | **KEEP (extended)** | Commercial objections added (F-13) |
| 11 Final CTA + Footer | **KEEP** | CTA per FD-01 |
| §19 Capability Micro-UI (optional) | **REMOVE** as standalone | Micro-crops serve inside 06/07; a separate module section risks the six-card failure V2 itself warns against |

**Note on the currently built page** (`marketing/index.html` @ `claude/public-website`, AppDrop-style v3): it predates this spec's reference hierarchy and §18 in two ways — its Driver/Tracking panels are HTML micro-UI recreations (violates §18's no-recreation rule regardless of "preview" labels), and it is Vendor-Mobile-only where V2 makes Vendor Web/Desktop the primary hero. Treat it as a Gate-1 visual study, not the base for Gate 2 implementation. Its Vendor Mobile captures are genuinely real renders and remain reusable subject to FD-04.

## K. CONTRADICTIONS FOUND (website story vs product SOT)

1. **Phase boundary:** the full commercial homepage this task designs is **Phase 06 scope**; canonical current website scope is **Phase 03 pre-launch landing** (positioning + Early Access/Waitlist + lead capture) — `11_CEFFLO_WEBSITE.md` §2. Building the commercial architecture is fine as design; *launching* it as-is either needs Founder re-scoping or a Phase-03 posture (FD-01).
2. **§18 Real Product Visual Lock vs the built page:** the existing v3 page's Driver and Tracking panels are hand-built HTML recreations of product UI. Under §18 these must be replaced with real renders of the live Rider PWA and Customer Tracking PWA (both are real, runnable apps — captures are obtainable) or removed.
3. **Vendor surface identity:** V2 §11 makes Vendor **Web/Desktop** the hero; the live operational client *is* Vendor Web — but the built page fronts **Vendor Mobile**, which is DEV/STAGING / UI NOT LOCKED (D-40) and whose fresh D-45 gradient look doesn't exist in any shipped client. Claims §7 makes "prototype presented as current production" RED. Needs FD-04.
4. **Vendor Web has no true desktop layout** (Flow 3 §16: centered 760px mobile column). A wide "desktop dashboard" hero shot cannot be captured truthfully today. Compositions must crop honestly (mobile-column framing) or FD-04 accepts Vendor Mobile visuals with agreed labeling.
5. **"Get started" CTA vs availability:** no production deployment, no self-serve public signup, no billing. `07_BUSINESS_LAUNCH_COMMERCIAL.md` §13 requires CTA to match availability → Early Access/Waitlist wording until go-live (FD-01).
6. **Storefront:** Scope Lock's "LIVE (backend)" could tempt a "sell online with CEFFLO" claim; no customer-facing page is shipped. Website must stay silent or label in-development (FD-03).
7. **Driver naming:** "Cefflo Driver" is the locked name of the *future Flutter product* (D-38); the live executor is the Rider PWA. Marketing the Driver section under the app name "Cefflo Driver" would market an unbuilt app. Use capability language ("Driver App" / "your delivery team's app") until Flutter ships (FD-05).
8. **Geocoding runtime:** Founder-locked Mapbox provider is implemented but blocked on a missing credential in every checked environment (Flow 3 §18). Address-intelligence claims are contract-true but not E2E-verifiable until the credential lands (FD-08 operational item).
9. **No "AI optimization", no "live tracking", no "real-time":** planning is deterministic-by-design (locked architecture); no GPS write path exists. Any energetic copy drift into "AI route optimization", "live tracking" or precise ETA violates Product Truth §12 and Claims §8–§9. The V2 spec is already clean here; this locks the copywriting boundary for implementation.

## L. FOUNDER DECISIONS REQUIRED BEFORE IMPLEMENTATION

| ID | Decision | Options / recommendation |
|---|---|---|
| **FD-01** | **Launch posture of the website** | (a) Phase-03 pre-launch: full commercial storytelling but CTA = Early Access/Waitlist (recommended — honest, still premium); (b) re-scope Phase 03 to allow the commercial site with gated signup; (c) hold the commercial site for Phase 06 |
| **FD-02** | **Pricing on website v1** | Omit values (required until 10_PRICING lock). Sub-decision: allow a no-numbers teaser ("free tier that runs real deliveries") or omit the section entirely. Recommendation: omit in v1; reserve architecture in MASTER |
| **FD-03** | **Storefront presence** | (a) Omit (cleanest); (b) one clearly-labelled "in development" block (requires Founder approval per Claims §6). No LIVE-implying visuals either way |
| **FD-04** | **Which Vendor surface fronts the site** | (a) Vendor Web (live client; honest but visually a mobile column today); (b) Vendor Mobile DEV/STAGING with agreed presentation (real renders, seeded demo data, launch-state honest); (c) mix, Web-primary per V2 §11. Needs an explicit call because (b) is the better-looking but not-yet-shipped surface |
| **FD-05** | **Driver-surface naming pre-Flutter** | Recommendation: capability language ("Driver App for your delivery team") with real Rider PWA captures; reserve the "Cefflo Driver" brand name for the Flutter launch |
| **FD-06** | **Hero copy final approval** | V2 §11 already reserves it; carry into MASTER ("Run local delivery. Without the chaos." + category label + supporting line) |
| **FD-07** | **FAQ answer for "Do I need my own website?"** | Depends on FD-03; truthful v1 answer drafted in F-13 |
| **FD-08** | *(operational, not website copy)* **Mapbox credential provisioning** | Required before address-intelligence claims are E2E-demonstrable; A-06 credential change → Founder approval |
| **FD-09** | **Category-difference copy boundary** | Approve category-level contrast only (no named competitors); any named comparison needs separate review (Claims §11/§17) |
| **FD-10** | **Website v1 domain/deployment target** | cefflo.com currently parked (Hostinger); DNS/production infra changes are A-06 Founder-approval scope — decide target and timing at Gate 2, not by the implementer |

---

**STOP.** This report is analysis only. No website, product, backend or doc files were modified. Next step: Founder review of FD-01…FD-10, then `CEFFLO_PUBLIC_WEBSITE_MASTER.md`.
