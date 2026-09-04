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
