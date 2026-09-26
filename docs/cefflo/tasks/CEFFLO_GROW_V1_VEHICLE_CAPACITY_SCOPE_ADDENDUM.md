# CEFFLO GROW V1 --- VEHICLE & CAPACITY SCOPE ADDENDUM

**Document type:** Founder-approved scope addendum\
**Applies to:** Cefflo Grow V1 / Flow 1 Scope Lock\
**Purpose:** Add vehicle-aware and capacity-aware delivery planning
requirements\
**Implementation authorization:** NONE --- scope/truth definition only\
**Production authorization:** NONE

------------------------------------------------------------------------

## 1. Founder Decision

Cefflo Grow V1 must NOT assume that every delivery is performed using a
motorcycle.

Cefflo serves businesses operating local same-day delivery. Depending on
the vendor and delivery workload, delivery may be performed using:

-   Motorcycle
-   Car
-   Van

Examples include businesses such as catering operations where some
delivery loads may require a car or van rather than a motorcycle.

This requirement is part of the Grow V1 planning/optimization scope.

------------------------------------------------------------------------

## 2. Rider vs Driver Product Terminology

For Grow V1, do **not** create separate operational products or
workspace roles called `Rider` and `Driver`.

Use **Rider** as the canonical Cefflo operational delivery-person role.

A Rider may operate different vehicle types.

Conceptually:

**Rider** → Motorcycle\
→ Car\
→ Van

The vehicle is an attribute/capability of the Rider, not a separate
workspace identity.

Claude must audit existing repository terminology and data models before
recommending exact schema or UI changes.

------------------------------------------------------------------------

## 3. Vehicle Type Requirement

Grow V1 must support a vehicle classification for delivery personnel.

Minimum launch vehicle classes to scope:

-   `MOTORCYCLE`
-   `CAR`
-   `VAN`

Exact database enum/value naming is an implementation decision for Flow
2 and must follow verified repository architecture.

Do not implement schema changes in this addendum task.

------------------------------------------------------------------------

## 4. Vehicle-Aware Planning

The Grow V1 AI Optimization / Delivery Planning Layer must be
**vehicle-aware**.

Planning must not optimize only for geographic distance or stop
sequence.

Before producing an executable delivery plan, Cefflo must be capable of
considering whether the assigned Rider's vehicle is appropriate for the
delivery workload.

Conceptual planning chain:

**Orders** → **Location** → **Delivery requirements** → **Available
Riders** → **Vehicle compatibility** → **Capacity compatibility** →
**Geographic grouping** → **Run proposal** → **Stop-sequence
optimization** → **Vendor review/manual adjustment** → **Dispatch**

Vehicle compatibility and capacity constraints therefore occur upstream
of final route sequencing.

------------------------------------------------------------------------

## 5. Capacity-Aware Planning

Grow V1 planning must also be **capacity-aware**.

Do not hard-code an assumption such as:

-   motorcycle = X orders
-   car = Y orders
-   van = Z orders

until the current repository and product requirements have been audited.

Flow 1 must determine the most practical V1 capacity model.

Candidate models to evaluate may include:

-   maximum active orders/stops;
-   configurable capacity per Rider;
-   vehicle-based default capacity with vendor override;
-   simple delivery-load categories;
-   another bounded model supported by repository/product evidence.

The final V1 model must be simple enough to operate reliably but must
prevent obviously incompatible planning.

------------------------------------------------------------------------

## 6. Order / Delivery Vehicle Requirement

Flow 1 must determine whether Grow V1 needs an order-level or
delivery-level vehicle requirement.

The product must support the operational reality that some deliveries
may:

-   work with any vehicle;
-   be suitable for motorcycle;
-   require at least a car;
-   require a van.

The exact UX and data model are NOT locked by this addendum.

Claude must audit and recommend the simplest reliable V1 contract.

Do not introduce complex kilogram/volume/dimension logistics unless
evidence shows it is necessary for Grow V1.

------------------------------------------------------------------------

## 7. Vendor Control

The Vendor / Owner Workspace must ultimately allow the business to
understand and control vehicle-aware planning.

Flow 1 must define the minimum V1 requirement for:

-   registering/maintaining a Rider's vehicle type;
-   understanding vehicle compatibility in Delivery Planning;
-   seeing capacity conflicts;
-   changing Rider assignment;
-   manually adjusting a proposed plan;
-   understanding why an assignment is incompatible.

Manual override must not silently create an invalid plan.

Where an override would violate a hard operational constraint, the scope
must define whether Cefflo should block the action or require an
explicit exception mechanism.

------------------------------------------------------------------------

## 8. Optimization Requirement Update

The existing Grow V1 requirement:

> AI Optimization Layer is REQUIRED V1.

is extended to mean:

> **The Grow V1 optimization layer must be location-aware, vehicle-aware
> and capacity-aware.**

It must help determine:

1.  which orders should be grouped;
2.  which delivery workload is compatible with which available
    Rider/vehicle;
3.  how workload should be divided into executable runs;
4.  which Rider/run allocation should be recommended where applicable;
5.  how stops should be sequenced efficiently;
6.  which orders cannot currently be planned because of location,
    vehicle or capacity conflicts;
7.  how the Vendor can review and safely adjust the proposal before
    dispatch.

A shortest-route-only implementation is not sufficient if it ignores
vehicle/capacity compatibility.

------------------------------------------------------------------------

## 9. Four Workspace Impact

### Vendor / Owner

Needs visibility/control over Rider vehicle type, compatibility,
capacity conflicts and plan adjustment.

### Operations / Helper

No separate Driver workspace is introduced. Operations/Helper remains
focused on Prepare → Pack → Ready, while any vehicle-related handoff
requirement discovered during audit should be documented.

### Rider

Canonical role remains Rider regardless of Motorcycle / Car / Van.

The Rider receives an executable run compatible with their assigned
vehicle/capacity.

### Customer

No vehicle-selection complexity should be exposed unless genuinely
required by the customer journey. Flow 1 should document only
customer-facing implications that are operationally necessary.

------------------------------------------------------------------------

## 10. Required Repository Audit

Flow 1 audit must now explicitly search for and establish current truth
for:

-   rider vehicle fields;
-   vehicle type;
-   motorcycle/motorbike;
-   car;
-   van;
-   driver terminology;
-   rider capacity;
-   max active orders;
-   run capacity;
-   order load/size;
-   delivery vehicle requirement;
-   assignment compatibility;
-   planning constraints;
-   route/run optimization constraints.

For each relevant capability classify:

**Launch Priority** - REQUIRED V1 - DESIRABLE V1 - POST-V1 - OUT OF
SCOPE - FOUNDER DECISION REQUIRED

**Current Truth** - LIVE - PARTIAL - MISSING - LEGACY / NON-CANONICAL -
UNVERIFIED

------------------------------------------------------------------------

## 11. Founder Gate Questions

The Flow 1 final report must explicitly answer:

1.  Does the current repository already model Rider vehicle type?
2.  Does it distinguish Motorcycle / Car / Van anywhere?
3.  Does current planning consider vehicle compatibility?
4.  What capacity model currently exists?
5.  Does current planning enforce capacity?
6.  Is an order-level vehicle requirement needed for Grow V1?
7.  What is the simplest reliable V1 capacity model?
8.  What should happen when a Vendor manually assigns an incompatible
    Rider/vehicle?
9.  Are any existing screens/backend functions motorcycle-only by
    assumption?
10. What exact vehicle/capacity gaps must enter Flow 2?

Any genuinely unresolved product decision must be surfaced to Founder
rather than silently invented.

------------------------------------------------------------------------

## 12. Required Update to Flow 1 Deliverables

When Claude executes the main Flow 1 Scope Lock audit, incorporate this
addendum into:

`docs/cefflo/launch/CEFFLO_GROW_V1_SCOPE_LOCK.md`

and:

`docs/cefflo/audits/CEFFLO_GROW_V1_SCOPE_LOCK_AUDIT_REPORT.md`

The capability matrix and Flow 2 dependency proposal must include
vehicle/capacity findings.

------------------------------------------------------------------------

## 13. Guardrails

This addendum does NOT authorize:

-   implementation;
-   migrations;
-   schema changes;
-   Rider UI changes;
-   Vendor UI changes;
-   route-engine changes;
-   deployment;
-   Production access.

It expands the **scope that Flow 1 must audit and lock**.

Do not rebuild or rewrite the existing Flow 1 Task Master merely to
apply this requirement.

------------------------------------------------------------------------

## 14. Definition of Done

This addendum is successfully incorporated when Flow 1 no longer assumes
motorcycle-only delivery and the proposed Grow V1 scope explicitly
accounts for:

**Rider → Vehicle Type → Capacity → Compatibility → Planning →
Optimization → Vendor Review → Dispatch**

with Motorcycle, Car and Van included in the launch model.

**STOP at the existing Flow 1 Founder Gate.**
