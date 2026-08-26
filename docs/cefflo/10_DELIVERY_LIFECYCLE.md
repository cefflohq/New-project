# CEFFLO --- DELIVERY LIFECYCLE CONTRACT

## L-00 Purpose

This file is the canonical conceptual contract for delivery status
across Vendor, Rider and Customer Tracking. Exact enum/state names must
be verified from current code before modification.

## L-01 Principle

One lifecycle; multiple role-specific views. Clients may display
different labels but must not create contradictory states.

## L-02 Operational Domains

Lifecycle may include: - order accepted/ready state; - delivery
session/batch; - rider assignment; - pickup readiness; - picked up; -
route/in transit; - stop delivery; - delivered/completed; -
exception/failure/retry where designed.

Do not invent transitions from this conceptual list. Verify
implementation.

## L-03 Customer Mapping

Customer-facing flow historically simplifies to: **Picked Up → On The
Way → Delivered.** Map internal states safely.

## L-04 Transition Integrity

Status mutation should use protected canonical server/RPC paths where
designed. Prevent unauthorized/skipped/invalid transitions.

## L-05 Append-only Events

Delivery events should preserve operational history where current
architecture uses append-only event records.

## L-06 Assignment

Only authorized vendor/team/rider actors may create/accept/act on
assignments according to canonical backend rules.

## L-07 POD

Define when POD is required, when upload occurs, and whether completion
can proceed when upload fails. Never let UI and backend disagree.

## L-08 Exceptions

Model or explicitly handle operational exceptions rather than forcing
them into a false success state.

## L-09 Cross-App Test

Any lifecycle change requires affected Vendor + Rider + Customer
contract validation.

## L-10 Change Gate

A material lifecycle contract change is architecture-sensitive. Review
`02_ARCHITECTURE.md`, `11_SUPABASE.md`, `12_SECURITY.md` and obtain
protected approval where required.
