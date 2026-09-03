# CEFFLO — S4-02.A: Permission Matrix & Protected Backend Contract Design

**Sprint:** Stage 4 → S4-02 → Sub-sprint S4-02.A (Founder Decisions #1–#2 only)
**Status:** Role model **FOUNDER-APPROVED AND LOCKED** (this revision). Remainder of the design
(RPC signatures, RLS narrowing) is still DRAFT pending S4-02.B. Design/documentation only; nothing
in this document has been applied to any database, RLS policy, or environment.

**Revision note:** This document was updated per an explicit Founder decision to (1) finalize the
canonical role model as exactly four actors — Owner, Operator/Staff, Rider, Customer/Public
Tracking — removing the previously proposed `Member` application role, and (2) confirm several
security defaults (no hard `DELETE` on operational records, business-profile audit trail required,
rider deactivation stays Owner-only). See Section 1 and Section 8 for what changed and why.
**Scope boundary:** This document covers ONLY the permission matrix (Decision #1) and identifies,
at a conceptual level, which mutations must move to protected RPC contracts (Decision #2 —
detailed RPC signatures are S4-02.B, not designed here). Decisions #3–#9 (order-approval state
machine, session/batch/zone invariants, trusted-team invitation, exception workflows, POD/token
lifecycle redesign) are explicitly out of scope and marked `DEFERRED TO <sprint>` wherever the
matrix touches them.

---

## 1. Actors — Canonical Role Model (Founder-approved, locked)

Exactly **four** canonical application roles/actors exist. No fifth `Member` role is introduced.

| Actor | Definition | Current schema representation |
|---|---|---|
| **Owner** | *Pemilik vendor / pemilik bisnes.* Highest Vendor-business authority: ownership-level authority, business governance authority, authorized administrative authority — **plus every operational capability available to Operator/Staff** (see inheritance rule below). | `business_members.role = 'owner'` |
| **Operator / Staff** | *Pekerja dalaman vendor* — kitchen staff, packing staff, order/operations staff, and other internal workers performing vendor operational tasks. Receives only explicitly authorized operational capabilities; **does not** receive ownership, security/role-management, or business-ownership-transfer authority. | `business_members.role = 'operator'` |
| **Rider** | Delivery personnel bound to a business via `riders` row + linked `auth.users` identity. Authority is scoped strictly to authorized delivery responsibilities/contracts; does **not** inherit Owner or Operator/Staff authority. Authorized only through assignment/team membership, not an open marketplace (D-03). | `riders.auth_user_id`, resolved via `current_rider_id()` |
| **Customer / Public Tracking user** | Unauthenticated party holding a valid tracking token for one order. No account (D-04); access is token/public-contract scoped and does **not** inherit any internal vendor permission. | No `auth.users` row; identified only by `tracking_tokens.token_hash` |

### Inheritance rule (canonical, Founder-locked)

```
Owner
  ↓ inherits ALL Operator/Staff operational capabilities
Operator / Staff

Rider          = separate delivery-scoped actor (no inheritance from Owner/Operator)
Customer       = separate customer/public-scoped actor (no inheritance from Owner/Operator)
```

- **Owner inherits all Operator/Staff capabilities.** A solo vendor with no employees operates
  Cefflo entirely through the Owner account — never needing to create a fake Operator identity or
  switch roles to perform normal operational work: `Solo Vendor → Owner account → full authorized
  business + operational workflow`.
- **Operator/Staff does not inherit Owner authority.** Operator/Staff never automatically receives
  ownership, security/role-management, or business-transfer authority.
- Every row in the matrix below therefore satisfies **Owner ≥ Operator/Staff** (Owner has at least
  everything Operator/Staff has, often more) by construction — this was verified row-by-row when
  reconciling this revision, not merely asserted.

### `Member` removed — and why this doesn't conflict with `business_members`

`Member` is **removed as a canonical application role.** The current product model has no
sufficiently distinct business use-case for a role narrower than Operator/Staff, and the earlier
proposal to add a `member` value to `public.member_role` is **rejected** — no schema change is
needed for role representation.

This is a naming distinction, not a schema change: `business_members` is a **database
relationship table** — it records *which users belong to which business, and with what role*
(`owner` or `operator`). That relationship concept is unrelated to whether "Member" exists as a
user-facing authorization tier. The table name predates, and is independent of, this role-model
decision; it is not renamed or altered here (D-10: no unrelated refactor).

No additional production role is introduced. Founder/FOUNDR-console authority (D-12, D-15) is out
of scope for S4-02 (FOUNDR foundation is S4-12).

---

## 2. Actor × Action Permission Matrix

Legend: `ALLOW` / `DENY` / `SELF ONLY` / `BUSINESS SCOPED` / `ASSIGNED DELIVERY ONLY` /
`TOKEN SCOPED` / `RPC ONLY` / `OWNER ONLY`.

**"Current enforcement" reflects what the code actually does today** (verified from
`supabase/migrations/202608130001_cefflo_foundation.sql`), not the target design — used to show
exactly what S4-02.B must change.

| # | Action | Owner (target) | Operator/Staff (target) | Rider (target) | Customer/Public (target) | Current enforcement (today) |
|---|---|---|---|---|---|---|
| 1 | Business profile — **read** | BUSINESS SCOPED | BUSINESS SCOPED | DENY | DENY | `businesses_read`: any active member (RLS, direct table) |
| 2 | Business profile/settings — **update** (name, contact, address, currency, timezone) | OWNER ONLY, **audit-trail required** (Founder decision) | DENY | DENY | DENY | `businesses_update`: owner only (RLS, direct table) — access scoping **already aligned**; audit trail **not yet implemented** (no event row is written on this path today) — S4-02.B input |
| 3 | Business — **deactivate** (no hard delete; preserve operational history) | OWNER ONLY | DENY | DENY | DENY | **No contract exists at all** (no RPC, no RLS delete policy on `businesses`) — missing, but safe-by-default-deny. Terminology corrected from "delete" to "deactivate" per Founder no-hard-delete decision |
| 4 | Member/team — **view roster** | BUSINESS SCOPED | BUSINESS SCOPED | DENY | DENY | `members_read`: any active member (RLS, direct table) |
| 5 | Team — **invite new team member** (invitation creation, token/link, acceptance, joining) | DEFERRED TO S4-07 | DEFERRED TO S4-07 | DEFERRED TO S4-07 | DEFERRED TO S4-07 | **Missing contract** — no RPC, no RLS insert policy on `business_members` at all (deny-by-default). Founder decision: the entire invitation/join workflow belongs to S4-07; S4-02.B designs only the security *boundary* (Section 9) for an already-existing staff relationship, not invitation |
| 6 | Team — **change an existing team member's role or status** (promote/demote/deactivate, via `update_team_member`) | OWNER ONLY | DENY | DENY | DENY | **Missing contract** — no RPC, no RLS update policy (deny-by-default). In scope for S4-02.B as a boundary-only contract for an already-existing `business_members` relationship — not an invitation mechanism |
| 7 | Rider roster — **read** | BUSINESS SCOPED | BUSINESS SCOPED | SELF ONLY | DENY | `riders_vendor` (select part): any member. `riders_self`: rider's own row |
| 8 | Rider — **create/onboard** | ALLOW | ALLOW | DENY | DENY | `riders_vendor` `for all`: **any member including Operator/Staff, direct table write** — not RPC-mediated |
| 9 | Rider — **update** (status, plate, phone) | ALLOW | ALLOW | SELF ONLY (own profile fields only) | DENY | `riders_vendor` `for all`: any member, direct table write — no distinct rider-self-update policy exists today |
| 10 | Rider — **deactivate** (no hard delete; Founder-confirmed Owner-level authority for the current design) | OWNER ONLY | DENY | DENY | DENY | **Currently ALLOW for Operator/Staff too** — `riders_vendor` `for all` includes `DELETE` for any member. **Flagged gap: today's code performs a hard delete and does not restrict it to Owner; both must be corrected in S4-02.B/S4-03 (`deactivate_rider`, Owner-only, no hard `DELETE`).** |
| 11 | Order — **read** | BUSINESS SCOPED | BUSINESS SCOPED | ASSIGNED DELIVERY ONLY | TOKEN SCOPED (via `public_tracking` only, no direct table access) | `orders_vendor` (select part) / `orders_rider` / `public_tracking` RPC |
| 12 | Order — **create** | ALLOW (RPC ONLY, target) | ALLOW (RPC ONLY, target) | DENY | DENY | **Partially aligned**: `create_delivery` RPC exists and is correct, but `orders_vendor` `for all` RLS *also* permits any member to `INSERT` directly into `orders`, bypassing the RPC's tracking-token creation and audit-event logging |
| 13 | Order — **update** (address/items/notes pre-dispatch) | ALLOW | ALLOW | DENY | DENY | **No RPC exists.** Only path today is `orders_vendor` `for all` direct table write — no audit trail generated |
| 14 | Order — **cancel/void** (no hard delete; preserve operational history) | DEFERRED TO S4-05 | DEFERRED TO S4-05 | DEFERRED TO S4-05 | DEFERRED TO S4-05 | **Currently ALLOW hard-DELETE for Operator/Staff too** — `orders_vendor` `for all` includes `DELETE` for any member. S4-02.B establishes only that hard `DELETE` is prohibited and that the eventual cancel/void action must be a protected contract; **which actor may invoke it, when, and the resulting state machine are entirely DEFERRED TO S4-05** — no actor is assigned here, not even as a placeholder (Founder decision) |
| 15 | Delivery — **create** (session/stop scaffolding via `create_delivery`) | ALLOW (RPC ONLY) | ALLOW (RPC ONLY) | DENY | DENY | `create_delivery` RPC — **already aligned**, but see #12's RLS-bypass caveat (same underlying `orders`/`delivery_stops` rows) |
| 16 | Delivery session — **create/manage** | ALLOW | ALLOW | DENY | DENY | `sessions_vendor` `for all`: any member, direct table write, no RPC. **Session/batch invariants themselves are DEFERRED TO S4-05** — this row only concerns *who* may touch the table today, not the state machine |
| 17 | Rider — **assignment to delivery** | ALLOW (RPC ONLY, target) | ALLOW (RPC ONLY, target) | DENY | DENY | **Partially aligned**: `assign_rider` RPC exists and is correct, but `assignments_vendor` `for all` RLS *also* permits any member to write `rider_assignments` directly, bypassing the RPC |
| 18 | Rider — **reassignment/unassignment** | ALLOW | ALLOW | DENY | DENY | **Missing contract** — no RPC for reassignment exists; only the same broad `assignments_vendor` direct-write path. Full reassignment semantics are **DEFERRED TO S4-05** (assignment/session invariants, per Founder decision) |
| 19 | Delivery lifecycle transitions (`ready_for_pickup` → … → `arrived`) | READ ONLY (BUSINESS SCOPED) | READ ONLY (BUSINESS SCOPED) | ASSIGNED DELIVERY ONLY (RPC ONLY) | DENY | `rider_transition` RPC — **already aligned**: rider-only, own assignment, explicit allowed-transition list enforced in-function |
| 20 | Delivery — **completion** | READ ONLY | READ ONLY | ASSIGNED DELIVERY ONLY (RPC ONLY) | DENY | `complete_delivery` RPC — **already aligned**: requires `arrived` status + POD path, rider-own-assignment only |
| 21 | POD — **upload** | DENY | DENY | ASSIGNED DELIVERY ONLY | DENY | Storage policy `pod_rider_upload`: assigned rider only, path-scoped to their own order — **already aligned** |
| 22 | POD — **read** (internal) | BUSINESS SCOPED | BUSINESS SCOPED | ASSIGNED DELIVERY ONLY | DENY (no direct bucket access) | Storage policy `pod_authorized_read`: business member or assigned rider — **already aligned** |
| 23 | POD — **read** (customer-facing) | — | — | — | TOKEN SCOPED, time-limited signed URL only | `tracking-pod` Edge Function: service-role admin client, validates `public_tracking` reports `delivered` + a POD path before issuing a 300s signed URL — **already aligned**. (CORS/error-message hardening on this function is a separate SEC-08/SEC-09 item, tracked under **S4-04**, not a permission-matrix gap) |
| 24 | Tracking-token — **create** | ALLOW (RPC ONLY, implicit in `create_delivery`) | ALLOW (RPC ONLY, implicit) | DENY | DENY | `create_delivery` generates the token internally — **already aligned** |
| 25 | Tracking-token — **read/enumerate raw table** | DENY | DENY | DENY | DENY | `tracking_tokens` has RLS enabled with **zero policies defined** — correctly deny-by-default for every role; only reachable through the security-definer RPCs. **Already aligned — do not add a direct-read policy.** |
| 26 | Tracking-token — **expiry/revoke/rotate** | — | — | — | — | **Missing contract entirely** (no expiry ever set, no revoke/rotate RPC). Full policy design is **DEFERRED TO S4-04** (token lifecycle) — noted here only because it touches the token actor surface |
| 27 | Ratings — **read** | BUSINESS SCOPED | BUSINESS SCOPED | DENY | DENY (write-only, no read-back) | `ratings_vendor`: business member, select only — **already aligned** |
| 28 | Ratings — **submit** | DENY | DENY | DENY | TOKEN SCOPED (RPC ONLY) | `submit_rating` RPC: token-scoped, one per order, delivered-only — **already aligned** |
| 29 | Rider GPS location — **write** | DENY | DENY | ASSIGNED DELIVERY ONLY | DENY | `locations_rider`: insert-only, own `rider_id` — **already aligned** |
| 30 | Rider GPS location — **read** | BUSINESS SCOPED | BUSINESS SCOPED | DENY (no self-read policy exists) | DENY | `locations_vendor`: select, any member — **already aligned** for vendor side |
| 31 | Delivery/audit events — **read** | BUSINESS SCOPED | BUSINESS SCOPED | ASSIGNED DELIVERY ONLY | DENY | `events_vendor` / `events_rider` — **already aligned** |
| 32 | Delivery/audit events — **write** | DENY (RPC-internal only) | DENY | DENY (RPC-internal only) | DENY | No direct-write policy exists — all event rows are inserted only inside the security-definer RPCs — **already aligned, do not add a direct-write policy** |
| 33 | Exception report/resolve/reassign | — | — | — | — | **No contract exists.** Entire workflow is **DEFERRED TO S4-08** |
| 34 | Trusted-team invitation/join | — | — | — | — | **No contract exists.** Entire workflow is **DEFERRED TO S4-07** per Founder decision |
| 35 | Order approval/readiness gate before pickup | — | — | — | — | **No contract exists** (current flow has no explicit approval step). State machine is **DEFERRED TO S4-05** |

Every row above satisfies **Owner ≥ Operator/Staff** (Owner never has less access than
Operator/Staff) — verified during this reconciliation, consistent with the canonical inheritance
rule in Section 1.

---

## 3. READ vs. LIFECYCLE/MUTATING Split

**READ actions** (rows 1, 4, 7, 11, 22, 25/27, 30, 31 above): predominantly already correctly
scoped via RLS `select` policies keyed to `is_business_member` / `current_rider_id()` / RPC
token-validation. No READ-side gap was found that exposes cross-business or cross-rider data.

**LIFECYCLE/MUTATING actions** split into three buckets:

1. **Already RPC-only, already aligned** — `bootstrap_business`, `create_delivery` (business-side
   effect), `assign_rider` (business-side effect), `rider_transition`, `complete_delivery`,
   `public_tracking`, `submit_rating`. These correctly encode authorization inside the function
   body and are the pattern S4-02.B should extend, not replace.
2. **RPC exists but a parallel broad-RLS direct-write path also exists** (rows 12, 17) — `orders`
   and `rider_assignments` both have `for all` policies keyed only to `is_business_member`,
   meaning any Operator/Staff can `INSERT`/`UPDATE`/`DELETE` these tables
   directly via PostgREST, bypassing the RPC's audit-event and tracking-token logic entirely.
   **These must not remain broad direct table writes** — S4-02.B must design narrower RLS (or
   remove `insert`/`update`/`delete` from these policies entirely once equivalent RPCs cover every
   needed mutation) so the RPC becomes the only mutation path.
3. **No contract at all yet** (rows 5, 6, 10 [destructive], 13, 14 [destructive], 18, 26) — either
   entirely blocked today (safe, but functionally missing — member invite, role change) or
   dangerously broad today (destructive delete of riders/orders currently available to any
   Operator via direct RLS, rows 10 and 14). **The destructive-delete gap (rows 10, 14) is the
   most security-relevant finding in this matrix** and should be prioritized in S4-02.B's RPC
   design, alongside the missing member-management contract.

---

## 4. Mutations That Must Not Remain Broad Direct Table Writes

Conceptual mapping only — no RPC signatures are designed here (S4-02.B):

| Table | Current broad policy | Must move to |
|---|---|---|
| `riders` | `riders_vendor` (`for all`, any member) | RPC-only create/update; a separate OWNER-ONLY deactivate/delete RPC |
| `orders` | `orders_vendor` (`for all`, any member) | RPC-only create (already have `create_delivery`) + a new update RPC; OWNER-ONLY delete RPC (or disallow hard delete entirely in favor of a cancelled status) |
| `rider_assignments` | `assignments_vendor` (`for all`, any member) | RPC-only via `assign_rider` (already exists) + a new reassignment RPC — remove direct insert/update/delete from the RLS policy |
| `delivery_sessions` | `sessions_vendor` (`for all`, any member) | Table/invariant design itself is **DEFERRED TO S4-05**; this design only flags that the *access model* (not the state machine) needs the same RPC-only treatment eventually |
| `business_members` | No write policy exists (safe) | New OWNER-ONLY invite/role-change RPCs (currently missing entirely) |

No change is proposed to `tracking_tokens`, `delivery_events`, `ratings` (insert side), or the
storage bucket policies — all four are already correctly RPC-only / deny-by-default with no
direct-write RLS gap.

---

## 5. Reconciliation Against Existing Contracts

| Existing RPC | Alignment with target matrix |
|---|---|
| `bootstrap_business` | **Already aligned.** Owner-creation-on-business-creation is exactly the target behavior; no change needed. |
| `create_delivery` | **Partially aligned.** The RPC's own authorization (`is_business_member`) matches the target (Owner/Operator ALLOW), but the co-existing `orders_vendor` broad RLS policy lets that same authorization be bypassed via direct table write (Section 3, bucket 2). RLS narrowing is an S4-02.B item. |
| `assign_rider` | **Partially aligned.** Same pattern as `create_delivery` — RPC logic is correct, but `assignments_vendor` broad RLS policy provides a bypass. |
| `rider_transition` | **Already aligned.** Rider-only, own-assignment, explicit transition whitelist. No RLS bypass exists for this table's transition path (no `delivery_stops` write policy for vendors) — this is the pattern the others should match. |
| `complete_delivery` | **Already aligned.** Same reasoning as `rider_transition`; POD-required gate is already enforced in-function. |

**Missing contracts** requiring new RPC design in S4-02.B (conceptually identified here, not
specified): member invite, member role/status change, rider deactivate (owner-only), order update,
order/rider destructive-delete (or soft-cancel) path, rider reassignment.

---

## 6. Deferred to Later Sprints (explicitly out of S4-02)

- Order-approval/readiness state machine → **DEFERRED TO S4-05**
- Delivery session/batch/zone/multi-drop invariants → **DEFERRED TO S4-05**
- Rider reassignment *semantics* (who/when/how, beyond "who may call it") → **DEFERRED TO S4-05**
- Typed exception report/resolve/reassign/redelivery workflow → **DEFERRED TO S4-08**
- Trusted-team invitation/join token lifecycle and cross-team rider membership → **DEFERRED TO S4-07**
- Tracking-token expiry/rotation/revocation policy and POD/public-endpoint hardening (CORS, error
  normalization, rate limiting) → **DEFERRED TO S4-04**
- FOUNDR privileged-actor permissions → **DEFERRED TO S4-12/S4-13**

---

## 7. S4-02.B INPUTS

Exact questions S4-02.B (protected backend contract design) needs to resolve next, derived
directly from this matrix:

1. ~~Member role schema~~ — **REMOVED.** `Member` is not a canonical role (Section 1); no schema
   change is needed for role representation. The existing `public.member_role` enum
   (`owner`,`operator`) already matches the approved model exactly. (`business_members` remains the
   correct name for the underlying user↔business relationship table — that is a database
   relationship concept, not an application role, and is not touched.)
2. **Destructive-action RPCs**: design `deactivate_rider` (**Owner-only, Founder-confirmed**;
   no hard `DELETE` — must be a status change that preserves history) to replace the current
   unrestricted `DELETE` exposure in `riders_vendor`. For orders: S4-02.B establishes **only** that
   hard `DELETE` is prohibited and that the eventual cancel/void action must be a protected
   contract — **no actor, timing, or state-machine decision is made here, not even as a
   placeholder** (Founder decision — fully **DEFERRED TO S4-05**).
3. **RLS narrowing plan**: exact replacement policies for `riders_vendor`, `orders_vendor`,
   `assignments_vendor` once their equivalent RPCs exist — i.e., whether to drop `insert`/
   `update`/`delete` from `for all` down to `select`-only once RPCs cover every mutation, and the
   compatibility sequence so existing Vendor UI calls don't break mid-migration. Must eliminate
   hard `DELETE` capability on `orders`/`riders` per the Founder's no-hard-delete decision.
4. **Order-update RPC**: signature and allowed-field set for pre-dispatch order edits (currently
   no contract exists at all).
5. **Rider-update RPC**: signature for non-destructive rider field updates (status, plate, phone),
   separating it from the deactivate path.
6. **Team management RPC**: `update_team_member` (role/status change) only, OWNER ONLY, for an
   **already-existing** `business_members` relationship. Invitation creation, token/link,
   acceptance, and joining are **entirely DEFERRED TO S4-07** — `invite_team_member` is explicitly
   NOT designed in S4-02.B (Founder decision). Naming deliberately avoids "member" as a
   role-implying term — this is Owner/Operator-Staff team-authority management, not a third role.
7. **Reassignment RPC**: minimal `reassign_rider` contract sufficient to close the direct-write
   gap on `rider_assignments`, without designing the full S4-05 session/batch semantics.
8. **Business-profile audit trail**: **Founder-confirmed as required** (no longer open — see
   Section 8). S4-02.B must design how: move `businesses_update` to an RPC that also inserts an
   audit/event row, or keep the direct-table owner-only write but add a trigger-based audit log.
   Either approach is acceptable; the requirement (an audit trail must exist) is now fixed.

---

## 8. Founder Decisions Applied (this revision) and Remaining Open Questions

### Resolved by explicit Founder decision (this revision)

- ~~Exact Operator vs. Member boundary~~ — **moot.** `Member` is removed as a canonical role
  (Section 1). Operator/Staff receives only explicitly authorized operational capabilities and
  does not inherit Owner authority; Owner inherits all Operator/Staff capabilities.
- **Hard `DELETE` vs. soft lifecycle status for `orders`/`riders`** — **resolved:** normal
  application workflows must NOT use hard `DELETE` for operational records; use deactivate/cancel/
  void concepts that preserve operational history instead. (The exact order-side state machine and
  its actor authorization remain **DEFERRED TO S4-05** — only the "no hard delete" principle and
  rider-deactivate's Owner-only authority are decided now.)
- ~~Does Member need any write capability~~ — **moot**, Member removed.
- **Business-profile update audit trail** — **resolved: required.** S4-02.B must design the
  mechanism (RPC+event, or trigger-based log); the *requirement* is no longer open.

### Resolved by explicit Founder decision (S4-02.B authorization turn) — no longer open

1. **Order cancel/void — fully DEFERRED TO S4-05.** No actor, timing, or state-machine decision is
   made in S4-02 — not even as a placeholder. Row 14 of the matrix (Section 2) now reads
   `DEFERRED TO S4-05` for every actor. S4-02.B's only responsibility here is: prohibit hard
   `DELETE` on `orders`, and require that cancel/void eventually be a protected contract.
2. **Team invitation is entirely S4-07's.** S4-02.B designs only the security *boundary*
   (Owner-controlled team authority; Operator/Staff cannot self-grant Owner authority; protected
   contracts, not broad table writes) plus `update_team_member` for an **already-existing**
   `business_members` relationship. `invite_team_member` and the whole invitation/token/join flow
   are not designed here at all — no overlap ambiguity remains because S4-02.B does not touch
   invitation.

No unresolved permission questions remain that block S4-02 from proceeding to S4-02.B design (see
Section 9 onward).

---

# S4-02.B — Protected Backend Contract Design

**Status: DRAFT — awaiting Founder review/approval. Design only; nothing below has been applied
to any database, RLS policy, or environment.**

## 9. Existing Protected Contract Classification

| RPC | Classification | Why |
|---|---|---|
| `bootstrap_business` | **ALIGNED** | No competing write path exists: `businesses` has no `insert` RLS policy at all, so this security-definer function is the *only* way to create a business, and it atomically creates the owner membership row too. Nothing to change. |
| `create_delivery` | **PARTIALLY ALIGNED** | The RPC's own logic (`is_business_member` check, atomic order+stop+token+event creation) is correct. But `orders_vendor`'s `for all` RLS policy independently permits any business member to `INSERT` into `orders` directly via PostgREST, skipping tracking-token creation and the audit event. **The RPC does not require change; the co-existing RLS policy does.** |
| `assign_rider` | **PARTIALLY ALIGNED** | Same pattern: RPC logic (active-rider check, atomic assignment+event) is correct. `assignments_vendor`'s `for all` policy permits direct writes to `rider_assignments`, and `orders_vendor`'s `for all` policy separately permits a business member to set `orders.assigned_rider_id` directly, bypassing the RPC's rider-validity check entirely. **RPC unchanged; both RLS policies require narrowing.** |
| `rider_transition` | **PARTIALLY ALIGNED** | RPC logic (rider-own-assignment check, explicit transition whitelist) is correct and has no direct bypass on `delivery_stops` (no vendor write policy exists there). However, **`orders_vendor`'s `for all` policy lets a business member directly `UPDATE orders.delivery_status`**, bypassing this RPC's rider-only restriction and transition whitelist entirely — a business member could set an order to `arrived` without any rider action. This is a real bypass this design flags precisely, not previously stated at this level of detail in S4-02.A. **RPC unchanged; `orders_vendor` requires narrowing.** |
| `complete_delivery` | **PARTIALLY ALIGNED** | Same root cause as `rider_transition`: a business member could directly `UPDATE orders SET delivery_status='delivered'` via `orders_vendor`, skipping the POD-required gate and leaving `delivery_stops`/`completed_at` unsynchronized (a data-integrity risk, not just an authorization one). **RPC unchanged; `orders_vendor` requires narrowing** — this is the highest-value fix in this set, since it also protects the POD-completion business rule (D-19). |

**Summary:** none of the five existing RPCs need internal changes. The single root cause behind
every "partially aligned" verdict is the same: `orders_vendor`, `assignments_vendor`, and
`riders_vendor` are all `for all` policies that let any business member write directly to tables
that also have protected RPCs — the RLS layer, not the RPC layer, **requires change** (Section 11).

## 10. New Protected Contracts (minimum set)

Only the contracts explicitly required to close the identified gaps under the approved four-role
model. Nothing from S4-05/S4-07 is designed here.

| Contract | Actor | Purpose |
|---|---|---|
| `deactivate_rider(p_rider_id)` | **OWNER ONLY** | Soft-deactivate (`status='inactive'`) — replaces the current unrestricted `DELETE`. No hard delete; history preserved. |
| `update_rider_details(p_rider_id, p_name, p_phone, p_vehicle_plate)` | Owner or Operator/Staff (business member) | Non-destructive profile fields only — deliberately excludes `status`, which only `deactivate_rider` may change. |
| `update_order_details(p_order_id, p_customer_name, p_customer_phone, p_delivery_address, p_notes, p_items)` | Owner or Operator/Staff (business member) | Pre-dispatch edits only — guarded by the order's *current* `delivery_status = 'created'` (the only pre-dispatch state that exists in the schema today; does not invent a new approval state, which is S4-05's job). |
| `update_team_member(p_business_id, p_user_id, p_role, p_status)` | **OWNER ONLY** | Role/status change for an **already-existing** `business_members` row only — no insert capability, so it cannot be used to invite anyone. Includes a safety invariant: a business must always retain at least one active Owner (blocks the last owner from demoting/deactivating themselves). |
| `reassign_rider(p_order_id, p_new_rider_id)` — **minimum authorization boundary only** | Owner or Operator/Staff (business member), same shape as `assign_rider` | Establishes *who* may reassign (identical authorization to `assign_rider`), so `orders.assigned_rider_id` never needs a direct-write path. **Mid-flight rules, notifications, and session/batch impact are explicitly DEFERRED TO S4-05** — this function does not decide when reassignment is appropriate, only who is allowed to call it. |

Explicitly **not** designed here (per Founder boundary): rider *onboarding/creation* RPC (not in
the Founder's minimum list — `riders` `insert` stays as today's direct business-scoped write for
now), `invite_team_member`, any order cancel/void contract, any session/batch/exception contract.

## 11. RLS Narrowing Design

Every table below keeps its existing `select` policy **completely unchanged** — only
`insert`/`update`/`delete` are narrowed, so no legitimate read is affected (Section 12).

| Table | Keep (unchanged) | Remove | Replace with |
|---|---|---|---|
| `riders` | `select` (business member) | `update`, `delete` from the old `for all` policy | `update_rider_details` (fields), `deactivate_rider` (status) |
| `riders` | — | — | `insert` (business member) is **kept as-is** — rider onboarding is out of this design's minimum scope |
| `orders` | `select` (business member), `select` (assigned rider) | `insert`, `update`, `delete` from the old `for all` policy | `create_delivery`, `update_order_details`, `assign_rider`, `reassign_rider`, `rider_transition`, `complete_delivery` — all already exist or are designed here |
| `rider_assignments` | `select` (business member), `select` (own assignment) | `insert`, `update`, `delete` from the old `for all` policy | `assign_rider`, `reassign_rider` |

After this change, `orders`, `riders`, and `rider_assignments` have **zero** direct-write RLS
policies for any actor — every mutation is RPC-only, closing the bypass identified in Section 9.
No hard `DELETE` path remains for any actor, including Owner (Owner also only gets
`deactivate_rider`, never a raw `DELETE`) — matching the Founder's "no hard delete for anyone"
principle, not just "no hard delete for Operator."

## 12. Read Access Preservation

No `select` policy is touched anywhere in this design. `businesses_read`, `members_read`,
`riders_vendor` (select part), `riders_self`, `orders_vendor` (select part), `orders_rider`,
`assignments_vendor` (select part), `assignments_rider`, `stops_vendor`, `stops_rider`,
`events_vendor`, `events_rider`, `locations_vendor`, `ratings_vendor` all remain exactly as they
are today. Narrowing mutation authority never narrows read authority — verified by construction,
not merely stated.

## 13. Compatibility Sequence (zero-user-interruption)

Four ordered steps, each independently safe to pause at:

1. **Additive only.** Deploy all new RPCs (Section 10) alongside the *current, still-broad* RLS
   policies. Nothing is removed. Every existing direct-table-write code path keeps working exactly
   as today — this step cannot break anything, by construction.
2. **Client cutover** (implementation-time concern for whichever sprint touches Vendor UI —
   **not designed here**, this document only sequences it): update Vendor call-sites to use the
   new RPCs instead of any direct table write. Verified on `cefflo-staging` using the same
   non-mutating-check → hosted-E2E → surface-smoke-test pattern already proven in S4-01, before
   touching Production.
3. **RLS narrowing** (Section 11) — only after Step 2 is verified complete and passing on staging.
   This is the only step with any behavior-change risk, and it is fully reversible (re-add the
   dropped policy) if a regression appears. Applied to staging first, always, per the established
   S4-01 pattern — never Production-first.
4. **Regression verification** (Section 15's test plan) on staging, then a normal low-activity,
   backward-compatible, health-checked, rollback-ready release to Production (D-08) — no
   maintenance window, no forced user interruption at any step.

## 14. Business-Profile Audit Design (revised — Founder data-minimization clarification applied)

**Founder clarification (this revision):** do not automatically store raw before/after field
values. Record identity/timestamp/category by default; before/after *values* are added only where
a demonstrated operational/security requirement justifies retaining that specific data. This
section supersedes the earlier "JSON diff of from/to values" design — the architecture (RPC-first,
new audit table, Owner-only trigger action) is unchanged; only the payload shape is minimized.

- **What is audited:** any change made through the new `update_business_profile` RPC.
- **Actor identity:** `auth.uid()` of the caller (must be the business's Owner).
- **Business identity:** `business_id`, foreign-keyed to `businesses`.
- **Timestamp:** `created_at timestamptz default now()`.
- **Changed field/category:** a list of **field names only** that changed (e.g.
  `["name","phone"]`) — not their values. This answers "what category of change happened" without
  retaining the content.
- **Action/request identity:** an optional `p_idempotency_key` passthrough (same convention already
  used by `rider_transition`/`complete_delivery`), so an audit row can be correlated to a specific
  client-side action/request when the caller supplies one.
- **Explicitly NOT stored by default:** old or new field *values* of any kind — including business
  name/phone/email/address, which are not secrets but are still excluded by default per the
  Founder's data-minimization instruction, not because they were judged sensitive. No secrets,
  credentials, payment data, or other unnecessarily sensitive data is ever stored here.
- **If a future need justifies value-level audit** (e.g. a specific fraud/dispute investigation
  requirement), that would be a separate, explicitly scoped addition with its own Founder review —
  not a default behavior of this table. Not designed here.
- Implemented via the new `update_business_profile` RPC (Section 16 sketch) rather than a
  trigger, for consistency with the RPC-first pattern used everywhere else in this schema (D-10).

## 15. Test Plan (written only — not executed)

**Owner — positive (including inheritance):**
- Owner reads business profile/riders/orders/sessions/assignments/ratings/events (business-scoped).
- Owner calls every Operator/Staff-level action (`create_delivery`, `assign_rider`,
  `update_order_details`, `update_rider_details`) successfully without any separate identity —
  proves the inheritance rule holds in practice, not just on paper.
- Owner calls `update_business_profile` → succeeds, audit row created with correct diff.
- Owner calls `deactivate_rider` / `update_team_member` → succeeds.

**Operator/Staff — positive:**
- `create_delivery`, `assign_rider`, `update_order_details`, `update_rider_details`,
  `reassign_rider`, and all business-scoped reads succeed.

**Operator/Staff — negative (Owner-only actions denied):**
- `deactivate_rider`, `update_team_member`, `update_business_profile` each rejected with
  `forbidden` for an Operator/Staff caller.
- Direct PostgREST `INSERT`/`UPDATE`/`DELETE` on `orders`/`riders`/`rider_assignments` rejected
  once Section 11's narrowing is applied (the core regression guard for this sprint's fix).

**Rider:**
- `rider_transition` / `complete_delivery` succeed only for the caller's own assigned order;
  rejected for another rider's order.
- Rider cannot read another business's or another rider's data.
- Rider cannot call any vendor-only RPC (`create_delivery`, `assign_rider`, `update_order_details`,
  `deactivate_rider`, `update_team_member`, `update_business_profile`, `reassign_rider`).

**Customer/Public:**
- `public_tracking` / `submit_rating` succeed with a valid, unexpired, unrevoked token.
- Both reject invalid/expired/revoked tokens with no data leakage (D-20).
- No direct read access to `orders`/`tracking_tokens` tables (already true — regression guard).

**Direct-table-mutation bypass denied:**
- Post-narrowing, no actor (including Owner) can `INSERT`/`UPDATE`/`DELETE` `orders`, `riders`, or
  `rider_assignments` directly — everything routes through an RPC.
- Pre-narrowing baseline: confirm the bypass currently exists (documents the "before" state so the
  fix's effectiveness is measurable) — run only against a local/disposable target, never staging
  mutating tests against anything but `cefflo-staging`, never Production.

**Cross-business access denied:** Business A member cannot read/write Business B's riders, orders,
sessions, assignments, or ratings — extends the existing "outsider" actor pattern already present
in `tests/e2e_transaction.py`, not a new mechanism.

**Hard DELETE denied for everyone, including Owner:** raw `DELETE` on `riders`/`orders` fails for
every actor post-narrowing — Owner also only has `deactivate_rider`, never raw `DELETE`.

**Protected-RPC authorization:** one authorization test per new RPC per actor, matching Section 10's
table exactly.

**Regression of existing lifecycle RPCs:** re-run the existing `tests/e2e_transaction.py` (already
built, already proven in S4-01 — not redesigned here) once S4-03 actually applies the RLS
narrowing, to confirm the full `create_delivery → assign_rider → rider_transition ×4 →
complete_delivery → public_tracking → submit_rating` chain still passes unchanged. This is an
S4-03 acceptance step; not run now.

## 16. Draft Migration Sketch — **DRAFT, DO NOT APPLY**

Illustrative only. Deliberately kept as a fenced block in this document, **not** placed under
`supabase/migrations/`, to prevent any tooling from picking it up as a real migration.

```sql
-- ============================================================
-- DRAFT — DO NOT APPLY. Illustrative sketch for Founder/S4-03
-- review only. Not a real migration file. Not applied to any
-- database by this design task.
-- ============================================================

-- Step 1 (additive, non-breaking) -----------------------------

-- Data-minimized by design (Founder clarification): field NAMES only, never values.
create table if not exists public.business_profile_audit(
  id bigint generated always as identity primary key,
  business_id uuid not null references public.businesses on delete cascade,
  actor_user_id uuid references auth.users on delete set null,
  changed_fields text[] not null,      -- e.g. {name,phone} — names only, no values
  request_id text,                     -- optional caller-supplied correlation id
  created_at timestamptz not null default now()
);
alter table public.business_profile_audit enable row level security;
create policy business_profile_audit_read on public.business_profile_audit
  for select using (is_business_member(business_id));
-- no insert/update/delete policy: written only by update_business_profile()

create function public.update_business_profile(
  p_business_id uuid, p_name text default null, p_phone text default null,
  p_email text default null, p_address text default null,
  p_operating_area text default null, p_timezone text default null,
  p_currency text default null, p_idempotency_key text default null
) returns public.businesses language plpgsql security definer set search_path=public as $$
declare b businesses; changed text[] := '{}';
begin
  if not is_business_owner(p_business_id) then raise exception 'forbidden'; end if;
  select * into b from businesses where id = p_business_id;
  if p_name is not null and p_name is distinct from b.name then changed := changed || 'name'; end if;
  if p_phone is not null and p_phone is distinct from b.phone then changed := changed || 'phone'; end if;
  if p_email is not null and p_email is distinct from b.email then changed := changed || 'email'; end if;
  if p_address is not null and p_address is distinct from b.address then changed := changed || 'address'; end if;
  if p_operating_area is not null and p_operating_area is distinct from b.operating_area then changed := changed || 'operating_area'; end if;
  if p_timezone is not null and p_timezone is distinct from b.timezone then changed := changed || 'timezone'; end if;
  if p_currency is not null and p_currency is distinct from b.currency then changed := changed || 'currency'; end if;
  update businesses set
    name = coalesce(p_name, name), phone = coalesce(p_phone, phone),
    email = coalesce(p_email, email), address = coalesce(p_address, address),
    operating_area = coalesce(p_operating_area, operating_area),
    timezone = coalesce(p_timezone, timezone), currency = coalesce(p_currency, currency),
    updated_at = now()
  where id = p_business_id returning * into b;
  if array_length(changed, 1) > 0 then
    insert into business_profile_audit(business_id, actor_user_id, changed_fields, request_id)
    values (p_business_id, auth.uid(), changed, p_idempotency_key);
  end if;
  return b;
end$$;
grant execute on function update_business_profile to authenticated;

create function public.deactivate_rider(p_rider_id uuid) returns public.riders
language plpgsql security definer set search_path=public as $$
declare r riders;
begin
  select * into r from riders where id = p_rider_id;
  if r.id is null or not is_business_owner(r.business_id) then raise exception 'forbidden'; end if;
  update riders set status = 'inactive', updated_at = now() where id = p_rider_id returning * into r;
  return r;
end$$;
grant execute on function deactivate_rider to authenticated;

create function public.update_rider_details(
  p_rider_id uuid, p_name text default null, p_phone text default null, p_vehicle_plate text default null
) returns public.riders language plpgsql security definer set search_path=public as $$
declare r riders;
begin
  select * into r from riders where id = p_rider_id;
  if r.id is null or not is_business_member(r.business_id) then raise exception 'forbidden'; end if;
  update riders set
    name = coalesce(p_name, name), phone = coalesce(p_phone, phone),
    vehicle_plate = coalesce(p_vehicle_plate, vehicle_plate), updated_at = now()
  where id = p_rider_id returning * into r;
  return r;
end$$;
grant execute on function update_rider_details to authenticated;

create function public.update_order_details(
  p_order_id uuid, p_customer_name text default null, p_customer_phone text default null,
  p_delivery_address text default null, p_notes text default null, p_items jsonb default null
) returns public.orders language plpgsql security definer set search_path=public as $$
declare o orders;
begin
  select * into o from orders where id = p_order_id for update;
  if o.id is null or not is_business_member(o.business_id) then raise exception 'forbidden'; end if;
  if o.delivery_status <> 'created' then raise exception 'order already dispatched'; end if;
  update orders set
    customer_name = coalesce(p_customer_name, customer_name),
    customer_phone = coalesce(p_customer_phone, customer_phone),
    delivery_address = coalesce(p_delivery_address, delivery_address),
    notes = coalesce(p_notes, notes), items = coalesce(p_items, items), updated_at = now()
  where id = p_order_id returning * into o;
  return o;
end$$;
grant execute on function update_order_details to authenticated;

create function public.update_team_member(
  p_business_id uuid, p_user_id uuid, p_role public.member_role default null, p_status text default null
) returns public.business_members language plpgsql security definer set search_path=public as $$
declare m business_members; remaining_owners int;
begin
  if not is_business_owner(p_business_id) then raise exception 'forbidden'; end if;
  if p_status is not null and p_status not in ('active','inactive') then raise exception 'invalid status'; end if;
  select * into m from business_members where business_id = p_business_id and user_id = p_user_id;
  if m.business_id is null then raise exception 'not a team member'; end if;
  if m.role = 'owner' and (p_role = 'operator' or p_status = 'inactive') then
    select count(*) into remaining_owners from business_members
      where business_id = p_business_id and role = 'owner' and status = 'active' and user_id <> p_user_id;
    if remaining_owners = 0 then raise exception 'business must retain at least one active owner'; end if;
  end if;
  update business_members set role = coalesce(p_role, role), status = coalesce(p_status, status)
    where business_id = p_business_id and user_id = p_user_id returning * into m;
  return m;
end$$;
grant execute on function update_team_member to authenticated;

-- Minimum reassignment authorization boundary only.
-- Mid-flight rules / notifications / session impact: DEFERRED TO S4-05.
create function public.reassign_rider(p_order_id uuid, p_new_rider_id uuid) returns public.orders
language plpgsql security definer set search_path=public as $$
declare o orders;
begin
  select * into o from orders where id = p_order_id for update;
  if o.id is null or not is_business_member(o.business_id) then raise exception 'forbidden'; end if;
  if not exists(select 1 from riders where id = p_new_rider_id and business_id = o.business_id and status = 'active') then
    raise exception 'invalid rider';
  end if;
  update orders set assigned_rider_id = p_new_rider_id, updated_at = now() where id = o.id returning * into o;
  update rider_assignments set rider_id = p_new_rider_id, updated_at = now()
    where business_id = o.business_id and rider_id <> p_new_rider_id and status not in ('completed','cancelled')
      and id in (select assignment_id from delivery_stops where order_id = o.id);
  return o;
end$$;
grant execute on function reassign_rider to authenticated;

-- Step 3 (RLS narrowing — apply ONLY after Step 1+2 verified on staging) ------

drop policy if exists riders_vendor on public.riders;
create policy riders_vendor_select on public.riders for select using (is_business_member(business_id));
create policy riders_vendor_insert on public.riders for insert with check (is_business_member(business_id));
-- no update/delete policy: update_rider_details / deactivate_rider only

drop policy if exists orders_vendor on public.orders;
create policy orders_vendor_select on public.orders for select using (is_business_member(business_id));
-- no insert/update/delete policy: create_delivery / update_order_details / assign_rider /
-- reassign_rider / rider_transition / complete_delivery only

drop policy if exists assignments_vendor on public.rider_assignments;
create policy assignments_vendor_select on public.rider_assignments for select using (is_business_member(business_id));
-- no insert/update/delete policy: assign_rider / reassign_rider only

-- ============================================================
-- DRAFT — DO NOT APPLY.
-- ============================================================
```

## 17. Deferred Items — Full Summary

- **S4-04:** tracking-token expiry/rotation/revocation policy; public-endpoint hardening (CORS,
  error normalization, rate limiting on `tracking-pod` Edge Function and `public_tracking`/
  `submit_rating`).
- **S4-05:** order-approval/readiness state machine; delivery session/batch/zone/multi-drop
  invariants; full rider-reassignment semantics (mid-flight rules, notifications, session impact —
  beyond the minimum "who may call it" boundary designed in Section 10); **order cancel/void —
  entirely, including which actor may invoke it.**
- **S4-07:** trusted-team invitation/join workflow in full (invitation creation, token/link,
  acceptance, joining, cross-team rider membership rules).
- **S4-08:** typed exception report/resolve/reassign/redelivery workflow.

## 18. Downstream Implementation Plan — this is S4-03's work, not S4-02's

**Sprint-attribution correction:** applying this design (adding RPCs, cutting over Vendor call
sites, narrowing RLS) is **RLS/direct-write repair** — that is canonically **S4-03** ("Repair
RLS/direct writes and cross-business integrity," dependency: S4-02), per
`docs/cefflo/PHASE_1_STAGE4_GAP_REPORT.md` §7 and the explicit rule in
`docs/cefflo/STAGE_4_EXECUTION_HANDOFF.md` §3: *"No RLS or lifecycle remediation begins before
that design and its approvals."* S4-02's own deliverable was the design itself (Sections 1-17),
now Founder-approved. The batches below are **S4-03's execution plan**, informed by and directly
implementing this now-approved S4-02 design — they are not part of S4-02, and none of them starts
merely because this design document is approved. They require their own S4-03 entry/authorization.

| Batch (S4-03) | Objective | Scope | Files | Tests | Acceptance | Effort | Independent? |
|---|---|---|---|---|---|---|---|
| S4-03-Batch-1 | Ship new RPCs additively (Section 10/16 Step 1) | New migration: 5 new functions + `business_profile_audit` table, zero policy drops | New `supabase/migrations/*_s4_03_contracts.sql` | Positive/negative RPC tests (Section 15, RPC-specific rows) on local disposable target first, then staging | All 5 RPCs behave per Section 10's actor table; zero existing behavior changes (old direct-write paths still work) | MEDIUM | YES — safe to ship alone, nothing else depends on it existing first |
| S4-03-Batch-2 | Vendor call-site cutover to new RPCs | Vendor UI/adapter changes only (no schema change) | `vendor/index.html` / `vendor/backend.js` | Vendor surface smoke test on staging (mirrors S4-01E pattern) | Vendor UI uses RPCs exclusively for the actions in Section 10; no regression in existing Vendor smoke tests | MEDIUM | NO — depends on Batch-1 existing on the same target first |
| S4-03-Batch-3 | RLS narrowing (Section 11/16 Step 3) | Drop `for all` policies, add explicit `select`-only + narrow `insert`-only policies | Migration only (no app code) | Full negative bypass suite (Section 15's "direct-table-mutation bypass denied" + "hard DELETE denied" rows) + full regression of `tests/e2e_transaction.py` | Zero direct-write bypass remains; all existing lifecycle tests still pass unchanged | SMALL (migration is small; verification is the real weight) | NO — depends on Batch-2 being verified complete, per the compatibility sequence (Section 13) |

No batch touches Rider or Customer surfaces (their existing RPC-only paths are already aligned and
untouched by this design). No batch starts S4-05, S4-07, or S4-08 work. **None of these batches
are executed by S4-02's approval — they require S4-03 to formally begin.**
