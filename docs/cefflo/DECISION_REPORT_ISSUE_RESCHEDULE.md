# CEFFLO --- Vendor "Report Issue" / "Reschedule" — Decision Required

Status: PRODUCT DECISION REQUIRED before any backend contract is built.
No RPC or migration exists for either action; none should be created
until a Founder decision on the questions below is made.

## RI-00 Why this needs a decision, not just a wiring pass

Every other Vendor action reachable from Order Detail (Approve Order,
Assign Rider, Team invitations, Run Builder) is backed by a real,
tested RPC. Report Issue and Reschedule are the only two actions on
that same page that are still local-state-only — not because the UI
was never built, but because no backend contract for them has ever
been designed. Wiring them to a fabricated RPC now, without settling
the questions below, would encode an unreviewed guess into a
security-sensitive write path (order state, customer-visible status).

## RI-01 Current UI behavior (as-is, unchanged by this document)

`openReportIssue(el)` (vendor/index.html) opens a sheet with 5 fixed
reasons (Wrong address, Packaging issue, Customer unreachable, Payment
issue, Other). `confirmReportIssue(el)` then, entirely client-side:
sets the order's local `status` to `'issue'`, pushes a local
`state.issues` entry (`{id, orderId, type, status:'open', createdAt}`,
never persisted), and appends a local activity-log line. None of this
reaches the server — a page reload discards it.

`openReschedule(el)` opens a sheet asking for a new date + a fixed
time-slot (Morning/Afternoon/Evening). `confirmReschedule(el)` sets the
order's local `status` back to `'pickedUp'` and appends a local
activity line. Also entirely local, also discarded on reload.

## RI-02 Expected user intent

A vendor reporting an issue expects: the order to visibly reflect the
problem (to the vendor, to the rider, and — this is the important
part — to the customer tracking the delivery); the reason to be
recorded for later reference; and some resolution path (the order
either gets rescheduled, cancelled, or manually resolved).

A vendor rescheduling expects: the order to return to an
active/deliverable state with a new target window, and for that new
window to be visible to whoever picks the order back up.

## RI-03 What data/state would actually need to change

**Report Issue.** The real `orders.delivery_status` enum already has an
`issue` value (`created, ready_for_pickup, picked_up, out_for_delivery,
arrived, delivered, issue, cancelled` — confirmed in
`supabase/migrations/202608130001_cefflo_foundation.sql` and reused
throughout `rider/backend.js`'s `uiStatus` map and
`customer/backend.js`'s `statusMap`). Reporting an issue should very
likely just be a `rider_transition`-style call into that *already-real*
`issue` status — reusing the existing enum value, not inventing a new
one. What's missing is: (a) who is allowed to call it (today
`rider_transition` is Rider-authored only — a Vendor-authored issue
report is a *different* authorization path, since the order may not
even have started delivery yet, e.g. Wrong address discovered before
pickup), and (b) where the reason text (`data-reason`) is stored —
there is currently no `issue_reason`/`order_issues` table at all.

**Reschedule.** The current UI's `confirmReschedule` sets the order
back to `pickedUp`, which is almost certainly wrong as the real target
status — a genuinely rescheduled order that hasn't been re-attempted
yet should not silently claim to already be picked up again. This
needs its own explicit state (either a `rescheduled_for` timestamp
column on `orders` plus keeping the pre-issue status, or a dedicated
enum value) — the current UI's chosen target status should not be
carried forward as-is into a real RPC.

## RI-04 Which other apps would be affected

**Customer Tracking**: already has a real, distinct "Delivery Issue"
display state (`customer/index.html`'s `issueState()`, added this
session, wired to the real `issue` status value from
`public_tracking`). A Vendor-authored issue report reusing the same
`issue` enum value would surface there *automatically*, with zero
Customer Tracking changes needed — this is a strong argument for
reusing the existing enum value rather than inventing a
Vendor-specific one that Customer Tracking wouldn't recognize.

**Rider**: `rider/backend.js`'s own `uiStatus` map already has an
`issue` mapping too, but nothing currently transitions an order INTO
`issue` from the Rider side either — only `customer/backend.js`
*reads* it. A Vendor-side issue-report RPC would be the first thing
that actually writes this status; the Rider app would need to decide
how (or whether) to surface "this order has an open issue" on an
already-assigned order it's still carrying.

**FOUNDR**: `admin_audit_log` (this session's Phase 2 work) is the
natural home for "who reported this issue and why" if Founder-level
visibility into vendor-reported issues is wanted.

## RI-05 Audit/history requirements

Given FOUNDR already has a real, working audit-log mechanism
(`log_admin_action()`, `admin_audit_log` table, this session), a
Vendor-authored `report_order_issue` RPC should very likely call the
same kind of logging discipline this codebase already uses everywhere
else for privileged state changes (see `approve_order`,
`create_team_invitation`, etc. for the established pattern of
recording who/when/why). Whether that's the *same* `admin_audit_log`
table (platform-wide) or a business-scoped equivalent is itself a
decision — `admin_audit_log` was built for FOUNDR's platform-level
actions, not Vendor's own business-scoped ones; reusing it for Vendor
actions would mix scopes that have so far been kept separate
throughout S4.

## RI-06 Suggested minimal backend contract (proposal only — NOT created)

```
-- report_order_issue(p_order_id uuid, p_reason text)
--   Vendor-authored (is_business_owner/is_business_member gate, same
--   pattern as update_order_details). Transitions orders.delivery_status
--   to the existing 'issue' value. Reason needs a real home -- either a
--   new order_issues table (id, order_id, reason, reported_by,
--   reported_at, resolved_at) or, if history isn't required beyond the
--   current state, a plain orders.issue_reason text column. Given
--   Customer Tracking and FOUNDR both plausibly want to show *why*,
--   not just *that*, a table (not a single overwritable column) is the
--   safer default -- but that's exactly the kind of call this document
--   is deferring to Founder review, not deciding here.

-- reschedule_order(p_order_id uuid, p_rescheduled_for timestamptz,
--                   p_slot text)
--   Needs the RI-03 state-model decision (new column(s) vs new enum
--   value) settled first -- the RPC shape follows from that, not the
--   other way around.
```

Neither RPC has been created. No migration exists for either. This
document is the entire deliverable for this item.
