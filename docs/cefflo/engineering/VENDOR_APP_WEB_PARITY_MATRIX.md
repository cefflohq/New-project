# Vendor App ↔ Vendor Web — Capability Parity Matrix

**Date:** 2026-10-04 · **Baseline:** `official/staging` @ `e4abcb6`
**Rule (Founder, 2026-10-04):** parity means the same *capability*, not the
same layout. Requirements decide features; code alone never proves approval.
Packing/Sorting are Helper PWA only. Email invitations are retired: both
surfaces use the permanent invite link + QR (Link/QR → Sign in → Join request
→ Pending → Owner approval → Active).

**Authorities used:** `sot/09_VENDOR_FLUTTER_60_SCREEN_MASTER.md` (V-01…V-60),
`sot/03_VENDOR_WEB_DESKTOP.md` (Web SOT), `05_DECISIONS.md` (D-46, D-49,
D-54, D-55, D-61, D-64, D-66, D-73, D-74), `security/CEFFLO_SECURITY_AND_ACCESS_MASTER_SPEC.md`.

Legend — App / Web: ✅ present · ❌ absent · ⚪ intentionally absent.

## A. Already equivalent

| Capability | Source | App | Web |
|---|---|---|---|
| Sign in / Sign up / Forgot / Reset / 6-digit verify | V-01–V-05 | ✅ | ✅ |
| Business setup (info, address, service area, complete) | V-06–V-10 | ✅ | ✅ |
| Today overview + Need Attention list | V-11, Web SOT §2 | ✅ | ✅ |
| Orders list, Order detail, Approve order | V-12–V-13, D-61 | ✅ | ✅ |
| New order (canonical `create_delivery`) + geocode | V-14, Web SOT §7 | ✅ | ✅ |
| Order import CSV / Excel (`import_orders_batch`) | V-12/V-14 intake | ✅ | ✅ |
| Zones: create, rename, enable/disable | V-16, V-28–V-30, D-61 | ✅ | ✅ |
| Planning (`propose_delivery_plan`) and dispatch via run (`build_rider_run`) | V-17–V-18, D-61 | ✅ | ✅ |
| Active run detail (assignments, stops) | V-19, D-61 | ✅ | ✅ |
| Riders list, Rider detail (incl. aggregate customer rating) | V-20–V-21, D-46 | ✅ | ✅ |
| Rider Pending approve / reject (Owner-only) | Master Part III §13 | ✅ | ✅ |
| Remove rider (typed CONFIRM, active-work guard, read-back) | Master Part III §20–23 | ✅ | ✅ |
| Team list, Team → Pending approve / reject (Owner-only) | Master Part III §12 | ✅ | ✅ |
| Remove member (typed CONFIRM, read-back) | Master Part III §19 | ✅ | ✅ |
| Permanent invite link + QR for Rider, Operator, Helper (`get_invite_link`; email invites retired in both) | Founder 2026-10-04; Master Part III §9–11 | ✅ | ✅ (#1) |
| Vehicle capacity check before dispatch (`check_run_vehicle_capacity` per run; dispatch blocked until compatible, no override) | D-61 | ✅ | ✅ (#2) |
| Report delivery issue (`vendor_report_delivery_issue`, 5 enum reasons; App had the repository call but no UI — wired in both) | Web SOT §10, S4-08 | ✅ (#3) | ✅ (#3) |
| Delivery recovery (`initiate_delivery_recovery`: release an assigned order back to unassigned, Owner/Operator only, idempotent) | Web SOT §2/§10, F2-09 | ✅ (#4) | ✅ (#4) |
| Edit order before dispatch (`update_order_details`: customer, phone, address, zone, items, notes; re-geocode on address change) | V-15, D-61 | ✅ | ✅ (#5) |
| Order coverage status on Order detail (`order_coverage_status`: unconfigured / awaiting location / in / outside). App had the repository call only — wired in both. `is_within_coverage` (coordinate check) has no caller: neither surface takes typed coordinates | V-26/V-27, Web SOT §2 | ✅ (#6) | ✅ (#6) |
| Delivery events on Order detail (`delivery_events`, oldest first) | Web SOT §2 + §5.8 | ✅ (#7) | ✅ |
| Service Area / coverage configuration | V-26–V-27 | ✅ | ✅ |
| Business Profile, information, address | V-37–V-39 | ✅ | ✅ |
| Profile, edit profile, profile photo | V-42–V-43 | ✅ | ✅ |
| Security, change password | V-44–V-45 | ✅ | ✅ |
| Notification inbox + preferences | V-47, notification system | ✅ | ✅ |
| Privacy, Terms, About | V-58–V-60 | ✅ | ✅ |

## B. Missing — approved, to implement

| Capability | Source | App | Web | Work |
|---|---|---|---|---|
| Business hours | V-40 | ✅ | ❌ | Web: `set_business_hours` |
| Storefront / Appearance / Preview (publish, link, QR, share, templates) | V-31–V-33, D-55, Storefront V1 (Founder 2026-10-01) | ✅ | ❌ | Web: storefront management |
| Products: list, add, edit, categories, up to 5 photos | V-34–V-36, product media multi (Founder 2026-10-01) | ✅ | ❌ | Web: catalogue |
| Subscription: current plan, choose plan, billing history (payments demo-only) | V-50–V-54, D-54 | ✅ | ❌ | Web: subscription surfaces |
| Help & Support, FAQ, Contact Support | V-55–V-57 | ✅ | ❌ (help marked "not connected") | Web: real FAQ + contact |

## Verification debt (clear before production qualification)

| Item | Debt |
|---|---|
| #2 capacity check | Browser QA of the failure path (violations listed, Create runs blocked) — demo mode always returns compatible; verify on staging data |
| Email-invite backend RPCs | `create_team_invitation`, `create_rider_invitation`, `claim_my_team_invitations`, `revoke_*` still granted; retire in the final production/security cleanup after a dependency audit |

## C. Helper PWA only (must not appear in Owner/Operator surfaces)

| Capability | Source | App today | Web | Work |
|---|---|---|---|---|
| Preparation, Packing, Sorting, Ready for pickup (`my_fulfilment_tasks`, `advance_preparation`, `confirm_packing`, `confirm_sorting`) | Founder 2026-10-04; D-74; Master Part III §5 | inside Vendor App Helper workspace | ⚪ | Move to the Helper PWA (work order step 5); remove from Vendor App |

## D. Needs decision (no locked requirement found)

| Item | Current code | Why it needs a decision |
|---|---|---|
| Live rider location for the Vendor | Web ✅ (`latest_rider_locations`), App ❌ | D-66 defines customer-facing location only; no decision grants Vendor live location |
| Per-order rider assignment (`assign_rider`) | Web ✅, App ❌ | D-61: "canonical assignment path is run-based `build_rider_run`… Mobile adds no per-order assignment flow" — keep in Web, remove from Web, or add to App? |
| Full rating history / rating detail UI | Neither (only aggregate rating) | D-46 approves the aggregate rating only |
| Google Drive import | Web ✅ (Integrations), App ❌ ("Google sign-in not connected") | No D-decision; came with a Vendor Web commit |
| Light / Dark mode | Web ✅ (dark mode), App ⚪ (D-54: accent colours, "No light/dark mode") | Same capability across both, or keep different? |
| Language set | App: BM, EN, 中文, தமிழ் (D-54) · Web: EN, BM | Add 中文/தமிழ் to Web, or limit both to EN/BM? |
| Delivery Settings | V-41 "RECONCILIATION REQUIRED"; unreachable in App, absent in Web | Keep hidden in both until defined (Founder 2026-10-04: leave as is) |
| Real subscription payment | Demo-only in App (D-54) | Payment architecture still HOLD |
| Operator entry | `?access=operator` in both | Own entry/auth on shared code — work order step 4 |
