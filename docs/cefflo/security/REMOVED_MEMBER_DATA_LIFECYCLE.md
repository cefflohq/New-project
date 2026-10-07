# Removed Team Member — Data Lifecycle (V1 decision)

Founder decision, 2026-10-07: **keep the current behaviour for V1** (audit
Options A/C). No code, migration or RLS change. Audited read-only on staging.

## Rule

Removing a member revokes business access immediately; it never deletes the
person's account, profile or history.

| Role | Removal | What is kept |
|---|---|---|
| Operator / Helper | `update_team_member(p_status => 'inactive')` (Owner only) | `business_members` row (inactive), `team_join_requests` (name, phone), all attribution columns |
| Driver | `deactivate_rider` (refused while the driver has open work) | `riders` row (inactive: name, phone, plate, vehicle), `rider_assignments`, `ratings`, `rider_locations`, POD attribution |

- Authority is evaluated per request (`is_business_owner`,
  `is_business_operational`, `is_business_helper`, `is_current_rider` all
  require `status = 'active'`); a still-valid JWT has no business authority
  after removal.
- `auth.users` and `profiles` are untouched: the account belongs to the
  person (it may own another business or work elsewhere).
- The same account can join another business, and can rejoin the original
  business through the invite link (a new pending request / the riders row
  back to `pending`), approved again by the Owner (or Operator for Helpers /
  Driver applicants).
- Events recorded: `membership.status_changed`, `rider.deactivated`,
  `team.join_*`, `rider.rejoined_via_link` in `delivery_events`.
- No automatic cleanup exists for removed members (the only cron job clears
  rate-limit counters and lookup telemetry).

## Rejected: permanent deletion after 24 hours

- Deleting `auth.users` CASCADEs every membership of that person (all
  businesses), profile, notifications and Driver identity records.
- It fails on NO ACTION / RESTRICT foreign keys whenever the user ever
  created an invite link, decided a join request, updated the storefront or
  hours, or reviewed a Marketplace verification
  (`business_invite_links.created_by`, `team_join_requests.decided_by`,
  `public_order_pages.updated_by`, `business_hours.updated_by`,
  `driver_marketplace_verifications.reviewed_by`, legacy
  `helper_workers.invited_by`, `rider_invitations.invited_by`,
  `team_invitations.invited_by`).
- SET NULL on `delivery_events.actor_user_id`, `orders.approved_by`,
  `delivery_stops.*_by`, etc. erases who did what; deleting a `riders` row
  CASCADEs run history (`rider_assignments`) and nulls the driver on orders,
  stops and ratings.
- It brings no security gain (access is already revoked) and 24 hours has no
  technical basis in this architecture.

## Future (not V1, needs a Founder decision)

- Self-service "Delete my account" for the person themselves, designed
  around the foreign keys above (anonymise, do not cascade history).
- If a PDPA retention period is set: anonymise name/phone in
  `team_join_requests` and inactive `riders` rows after that period (not 24 h),
  keeping IDs so history stays intact.
