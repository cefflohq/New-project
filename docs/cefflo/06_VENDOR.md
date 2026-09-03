# CEFFLO --- VENDOR PWA

## V-00 Purpose

Vendor PWA is the operational cockpit for the business — its owner
controls the operation (Brand Brain §5.1). Any specific business type
(e.g. a home food business) is an example, not the definition.

## V-01 Canonical Route

Planned production route: `vendor.cefflo.com`. Actual
deployment/baseline must be verified in Phase 1.

## V-02 Core Areas

-   onboarding/auth;
-   business/store context;
-   dashboard;
-   orders;
-   order intake/import where Stage 4 requires;
-   delivery preparation;
-   batching/zones/routes;
-   rider team/invite;
-   rider assignment;
-   current deliveries;
-   history;
-   rider performance where implemented/approved;
-   sales/order page Stage 4 scope;
-   settings/notifications.

## V-03 Dashboard

Expected principles: - clear header/business context; - concise KPIs; -
Current Deliveries; - Action Required; - urgent operational issues
visually outrank ordinary KPIs; - navigation remains mobile-first.

Historical desired Current Deliveries empty-state direction: three
consistent states/cards for Pending, Active and Completed. Verify
canonical UI baseline before implementation.

## V-04 Orders

Orders must enter a normalized Cefflo lifecycle. Verify
create/approve/filter/status behaviour and direct customer sales-page
flow where in Stage 4 scope.

## V-05 Delivery Operations

Support practical delivery preparation: batching, zones, route grouping,
assignment and progress. Avoid assuming one order = one dedicated rider
trip.

## V-06 Rider Team

Vendor can manage trusted riders and should support an invite/join path.
Assignment must respect authorization and lifecycle contracts.

## V-07 Sales/Order Page

Direction: vendor can share a sales/order page and receive customer
orders directly. Support multiple business concepts/types as approved.
Exact Stage 4 implementation must be confirmed in Phase 1/roadmap.

## V-08 Exception States

At minimum consider relevant paths: - customer unreachable; - wrong
address; - condo/access issue; - vendor not ready; - rider
unavailable/assignment issue; - POD failure downstream; -
offline/network failure; - stale/outdated client state.

## V-09 UI Rules

Mobile-first. Preserve canonical baseline. No unsolicited full redesign.
Natural Malaysian Malay where vendor-facing copy requires Malay. Do not
expose unnecessary technical/system language.

## V-10 Cross-Contracts

Read `10_DELIVERY_LIFECYCLE.md` for delivery statuses and
`11_SUPABASE.md` for backend contracts when affected.

## V-11 Stage 4 Gate

Vendor approved scope must work against canonical backend, include
relevant failure states, pass targeted/regression checks, and remain
lifecycle-consistent with Rider/Customer.
