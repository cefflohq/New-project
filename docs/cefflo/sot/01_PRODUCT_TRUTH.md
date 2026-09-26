**Status:** CANONICAL — Founder-approved, merged into repo 2026-09-04
**Repo-reconciliation note:** Supersedes `docs/cefflo/CEFFLO_BRAND_BRAIN.md` §§1-4 for product-truth doctrine specifically; `docs/cefflo/01_PRODUCT.md` remains valid as current Stage-4 implementation-routing detail and does not conflict.

---

# CEFFLO PRODUCT TRUTH — CANONICAL SOT
**Version:** 1.0 — 2026-09-04
**Authority:** Founder-approved Product Truth
**Purpose:** The single marketing/agent-readable truth about what Cefflo is, is not, does, and may claim.

## 1. Canonical Definition
Cefflo is a **local same-day delivery operating system for businesses that manage deliveries within their own service area**.

The product boundary is the operating model, not the merchandise category.

Canonical operating spine:
**Many local orders → Coverage → Delivery Zones → Delivery Plan → Multi-drop Runs → Riders → Delivered Today**

Launch doctrine: **Grow = Operate.** Cefflo launches around operating local same-day delivery. Future expansion must not distort this launch identity.

## 2. Who Cefflo Is For
Businesses that receive multiple local orders and coordinate delivery within their own service area, including food, bakery, meal-prep, florist, gifts/hampers, beauty/skincare and other suitable local-delivery businesses.

Do not define Cefflo as food-only, home-chef-only, kitchen-only or category-first.

## 3. What Cefflo Is NOT
Cefflo is not:
- a marketplace;
- a rider marketplace;
- a courier/rider company;
- a Cefflo-owned independent rider network;
- GrabFood, Foodpanda or Lalamove equivalent;
- a generic CRM;
- a generic accounting suite;
- a vendor-customer payment processor;
- a payout/settlement system for vendor-customer commerce;
- a quotation/deposit/outstanding-balance workflow;
- a product whose boundary is food.

Vendor owns the rider relationship and customer channel unless a future Founder-approved model explicitly changes this.

## 4. Connected Product Workspaces
### Vendor / Owner — CONTROL
Owns the business operation: today's orders, coverage/zones, planning/review, dispatch, active runs, riders/workforce, exceptions and business configuration.

### Operations / Helper — PREPARE
Supports operational preparation where implemented/authorized. No public Helper marketplace and no cross-vendor Helper discovery.

### Rider — EXECUTE
Receives assigned work and executes pickup/delivery runs. Execution-level stop resequencing is Rider-owned where the canonical contract permits it.

**Workforce/product terminology — LOCKED (2026-09-14, `docs/cefflo/05_DECISIONS.md` D-38, closing the gate opened at D-28 and left open at D-37; reconciled 2026-09-12 per D-29):**

- **"Cefflo Driver" is the locked user-facing mobile product name** — what appears in the app itself, app-store listing, UI copy, and product/marketing communications for the Flutter mobile delivery-workforce app.
- **"Rider" is the locked internal/backend/schema/API role name** — the product/backend/schema/API role stays exactly **"Rider"**, unchanged, no migration, matching every existing decision (D-03, D-09, D-14, D-16, D-18, D-19, D-21) and the real `riders`/`rider_vehicle_type` schema.
- These are two permanently distinct, intentionally different namespaces — not a pending or partial rename in either direction. Backend/schema/API identifiers (tables, enums, RPCs, API contracts, auth roles) must **not** be renamed to match the "Driver" product label; the UI product label must not revert to "Rider."

For general/unscoped references to the delivery workforce (not naming a specific vehicle), use **Driver / Delivery Driver / Delivery Team** — "Rider" is not the universal term. Vehicle-contextual: Motorcycle → Rider is natural, Driver is also acceptable; Car → Driver/Delivery Driver; Van → Driver/Van Driver/Delivery Driver. The target-state mobile surface this workspace maps to is `docs/cefflo/sot/13_DRIVER_FLUTTER_42_SCREEN_MASTER.md` (active master as of 2026-09-14 D-37, superseding `08_RIDER_FLUTTER_33_SCREEN_MASTER.md`) — its UI/UX names the product "Cefflo Driver," consistent with this lock.

### Customer — ORDER + TRACK
Customer-facing order/storefront/tracking experience where available. Public-facing information must remain truthful to canonical state.

## 5. Operational Doctrine
Cefflo should reduce the mental load of coordinating many local deliveries by turning operational state into a clear next action.

Product behavior must preserve:
- one canonical backend source of operational truth;
- truthful state;
- clear ownership of actions;
- explicit coverage/zones;
- review before dispatch where required;
- multi-drop run execution;
- recovery/exception handling where implemented;
- auditable transitions.

Flutter/web clients own presentation and client state only. They must not independently recreate canonical business rules such as coverage, zone logic, compatibility, capacity, optimization, ETA, recovery eligibility or dispatch rules.

## 6. Vendor Canonical Operational Spine
**TODAY → ORDERS → ZONES → PLAN / REVIEW → DISPATCH → ACTIVE RUNS → NEED ATTENTION → DONE**

Mobile Vendor DNA may present Zones operationally as **Ready / Ongoing / Completed** where this matches canonical behavior.

## 7. Rider Canonical Execution Doctrine
Canonical multi-stop concept:
**Plan Route → Pickup Checklist → Delivery Run**

Rider may use local knowledge to reorder stops where the canonical backend authorizes Rider resequencing. Do not widen this permission to Vendor merely for UI convenience.

**Run editing boundary (D-70):**
- **Before dispatch:** Vendor/Dispatcher run editing is approved **FUTURE**
  direction (not LIVE). It may eventually support reordering stops,
  adding/removing eligible orders, moving orders between proposed runs,
  changing the intended rider, and overriding the suggested sequence
  (system suggests → vendor reviews → vendor overrides if needed → dispatch).
- **After dispatch:** run integrity takes priority. No unrestricted Vendor
  editing of an active run. Any active-run intervention (e.g. reassignment,
  recovery, issue handling, cancellation) requires an explicit controlled
  contract.
- The Rider-owned resequencing above is unchanged.

Critical Rider actions use deliberate slide interactions where applicable, including Start Pickup, Start Delivery, Arrive, Next Stop and Complete Order.

Never claim active GPS/live tracking unless real location data is being collected and surfaced through the canonical implementation.

## 8. Customer Truth Doctrine
Customer tracking may show only information genuinely available from canonical state.

Do not invent:
- ETA;
- rider location;
- delivery status;
- notification delivery;
- proof;
- timestamps.

Any customer invoice/receipt/e-Invoice capability must follow the latest explicitly approved scope. Historical invoice documents are not automatically authoritative.

## 9. Payments Boundary
Cefflo does **not** manage vendor-customer payments unless Founder explicitly reintroduces that scope.

Separate boundary:
Cefflo may charge Vendors for Cefflo's own SaaS subscription. For Malaysia, Razorpay Curlec is the locked primary gateway for Vendor-to-Cefflo subscription billing. This does not make Cefflo the payment processor for vendor-customer transactions.

## 10. Capability Truth States
Every capability exposed to agents/marketing must have one state:
- **LIVE** — verified usable implementation.
- **LOCKED / IN DEVELOPMENT** — approved and being built, not marketable as live.
- **FUTURE** — intended direction, not current capability.
- **IDEA / EXPLORATION** — uncommitted.
- **OUT OF SCOPE** — explicitly excluded.

A schema, RPC, mock UI, dead code or historical MD does not by itself make a capability LIVE.

## 11. High-Risk Claim Registry
Require runtime/repository evidence before claiming LIVE:
- CSV/Excel/bulk import;
- third-party/POS/API integrations;
- automatic/AI route optimization;
- live rider GPS/location;
- ETA;
- WhatsApp/SMS/customer notifications;
- arbitrary storefront customization;
- recovery automation;
- customer invoice/e-Invoice;
- any payment/settlement capability.

## 12. Optimization Language
Do not claim route-optimization intelligence merely because users can plan, sequence or reorder stops.

If an optimizer is later implemented and verified, describe exactly what it optimizes and what remains human-reviewed. Until then, use truthful planning/review language.

## 13. Product Truth Gate for Marketing
Before publication:
1. identify each material capability claim;
2. map it to a capability state;
3. require evidence for LIVE;
4. rewrite/reject unsupported claims;
5. never turn roadmap language into present-tense product truth.

## 14. Superseded Doctrine
The following must never regain authority:
- Home Food OS / home-food-only positioning;
- purple/blue primary brand doctrine;
- Cefflo-owned rider marketplace/network assumptions;
- vendor-customer payment/deposit/balance assumptions;
- fabricated GPS/ETA/optimization/notification claims;
- fake success states;
- any old MD that conflicts with newer Founder-approved truth.

## 15. Governance
Authority order:
**Latest Founder decision → Canonical Product Truth / Brand Brain → verified backend/runtime contracts → active implementation docs → historical material**

If documents conflict, do not average them. Reconcile them and mark the stale doctrine superseded.

## 16. Marketing-Safe Core Claims
Safe at positioning level:
- Cefflo is built for businesses operating their own local same-day delivery.
- Cefflo organizes the operation around orders, coverage, zones, delivery planning, multi-drop runs, riders and delivery completion.
- Cefflo is not a marketplace or rider company.
- Cefflo is designed to make today's local delivery operation clearer and easier to control.

Specific feature claims still require current capability-state verification.

## 17. Product Truth Definition of Done
This SOT is functioning correctly when every agent can answer:
- What is Cefflo?
- Who is it for?
- What is it not?
- Who owns riders/customers?
- What is the operational spine?
- Which workspace owns which action?
- What may marketing claim today?
- Which claims require evidence?
- Which old doctrines are forbidden?
without contradicting the product or another canonical SOT.

## 18. Product Capability Direction (D-69, 2026-09-27)

Founder-approved **direction**, not current capability. This section does
**not** expand current production scope, and it does not change the Phase 2B
execution sequence. Truth states use §10. Priority is a separate axis and
never implies LIVE.

### 18.1 Optimisation philosophy
Cefflo optimisation is primarily about **delivery run economics and
operational density**: building multi-drop runs that are geographically
sensible, dense enough, operationally practical and worthwhile. It is not
about winning a mathematical route-optimisation benchmark.

**Advanced route optimisation is not a current strategic requirement.** The
preferred direction is:

> Orders → Smart Zone Clustering → primary delivery area → Corridor Fill →
> target run size → proposed multi-drop run → human review → rider
> assignment → suggested stop sequence → dispatch.

This refines, and does not unfreeze, the deterministic optimisation
architecture in `launch/CEFFLO_GROW_V1_SCOPE_LOCK.md` §12. That deterministic
foundation stays authoritative, and an LLM is never the route calculator.

Rules:
- **Zones define the primary cluster.** A zone is not an absolute boundary
  that forbids sensible cross-zone or corridor runs.
- **Corridor Fill** may add compatible orders lying along, or reasonably near,
  the fulfilment-point → primary-area corridor to raise run density. It must
  never add geographically unrelated orders just to hit a number. No
  geography is a product default. Place names in Founder examples are
  illustrative only.
- **Target run size** is configurable per business or run profile (min /
  target / max). Figures such as 10 / 12 / 15 drops are examples only, not
  universal Cefflo truth.
- **Suggested stop sequence** is guidance, not truth. Human and rider
  override is always preserved.
- Future measures: drops per run, orders per zone, distance per drop,
  minutes per drop, run duration, rider utilisation and corridor-fill rate.
  Rider earnings per run and merchant cost per delivery come later, once the
  data exists. No values may be fabricated.

### 18.2 Capability classification

| Capability | Truth state (§10) | Priority | Note |
|---|---|---|---|
| Deterministic suggested runs (`propose_delivery_plan`) + Run Builder + review before dispatch | LIVE (Vendor Web, staging-verified) | current | The existing base Smart Run Builder evolves from |
| Rider-owned stop resequencing (`save_run_sequence`) | LIVE | current | §7 boundary unchanged |
| Bulk CSV / Excel import (`import_orders_batch`) | LIVE (Vendor Web) | post-production (extend to other surfaces / harden) | Import only, never "sync" |
| Photo POD at delivery completion | LIVE | current | |
| Coarse truthful ETA window (`compute_order_eta`) | LIVE (where computable) | post-production (better ETA) | Window → progressively better → approaching, never false precision |
| Customer rider live location | LOCKED / IN DEVELOPMENT (Phase 2B.4, D-66) | current phase work | Not live until 2B.4 ships |
| Smart Zone Clustering | FUTURE | post-production high | By fulfilment point, coverage, zone and proximity |
| Smart Run Builder | FUTURE | post-production high | Algorithm not specified |
| Target Run Size / run profiles | FUTURE | post-production high | Configurable, no universal default |
| Corridor Fill | FUTURE | post-production high | No hard-coded geography |
| Manual Run Editing (reorder, add, remove, move orders between proposed runs, change intended rider, override suggested sequence) | FUTURE, pre-dispatch only (partial LIVE today: Run Builder, reassignment, rider resequencing) | post-production high | Active runs: no unrestricted Vendor editing, interventions only through explicit controlled contracts (§7, D-70) |
| Simple suggested stop sequencing | FUTURE | post-production high | Guidance only |
| Auto Assign Rider (which eligible rider runs this run) | FUTURE | post-production high | Not route optimisation. Manual assignment remains. |
| QR / barcode order verification (pack → run prep → rider pickup scan → mismatch detection) | FUTURE | post-production high | Distinct from POD. Vendor Web's manual pickup-verification tick is not scanning. |
| Customer notifications (Out for delivery, Approaching, Delivered, Issue when relevant) | FUTURE | post-production high | Event-based. No unlimited WhatsApp/SMS. Paid channels are subject to COGS/commercial decisions (`18_GROW_NOTIFICATION_ARCHITECTURE.md`). |
| Delivery analytics expansion (operational metrics, not vanity charts) | FUTURE | next / growth | Claim only metrics actually calculated |
| Operational reports (daily/weekly/monthly + export) | FUTURE | next / growth | Reports = a defined period, separate from live analytics |
| Public Order API | FUTURE | next / growth | No endpoint or payload names frozen |
| Webhooks (dispatched, out_for_delivery, arrived, delivered, failed, issue) | FUTURE | next / growth | Event names are conceptual |
| Native integrations (Shopify, WooCommerce, POS, ERP, merchant systems) | FUTURE | next / growth | Only where commercially justified |
| Multi-location / Fulfilment Point productisation | FUTURE | next / growth | Architecture must stay possible (§18.4) |
| Signature POD | FUTURE (optional capability) | optional | Never universally mandatory |
| Customer PIN / QR POD methods | IDEA / EXPLORATION | optional | |
| Rider Hub, portable rider identity, Find Work / Find Riders, external or peak capacity network | FUTURE (strategy) | future strategy | `strategy/CEFFLO_RIDER_NETWORK_STRATEGY.md`. Not V1. |

### 18.3 POD policy
- POD stays part of the delivery workflow.
- **Signature POD is optional, never universally mandatory.** A delivery must
  not be universally blocked from Delivered because no signature was captured.
- Photo POD is sufficient where the Vendor's delivery policy allows it.
- Possible future methods are Photo, Signature, Customer PIN, QR
  verification, and combinations where a Vendor requires them.
- QR/barcode *order verification* is an operational packing/pickup control,
  not customer POD.

### 18.4 Order ingestion and fulfilment points
- Integration ladder: **CSV import → Public Order API + Webhooks → native
  connectors where commercially justified.**
  - External systems will eventually create or update canonical Cefflo orders,
    which then flow through coverage, zone, plan, run, rider and delivery.
  - Cefflo will eventually notify merchant systems of meaningful delivery
    events.
- Architecture must not assume one business has one pickup location forever.
  The target model is Business → Fulfilment Point(s) → Coverage → Zones →
  Orders → Runs → Riders, and each fulfilment point may eventually have its own
  coverage, zones, orders, runs and rider allocation. Use "Fulfilment Point" /
  "Business Location". **Today** a business has a single service origin
  (`businesses.service_origin_*`).
- This does not make Cefflo a courier depot or hub network (§3; Rider Network
  Strategy §20).

### 18.5 Competitive principle
- Cefflo is not "another route planner" and not "the most advanced route
  optimisation software". It operates the complete local same-day delivery
  workflow.
- The Smart Run Builder exists to turn many local same-day orders into
  practical multi-drop runs.
- §12 Optimization Language still applies. Nothing in §18 may be marketed as
  current until it reaches LIVE with evidence.

