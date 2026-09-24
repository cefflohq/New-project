# CEFFLO Backend Wiring Audit

**Status:** Phase 1 audit complete; implementation is not authorized.

**Date:** 2026-09-24

**Scope:** Vendor Mobile, Driver Mobile and Customer Tracking PWA.
**Evidence basis:** repository code and tracked Supabase migrations only.

## 1. Executive finding

The repository contains a substantial Supabase backend and two Flutter repository
adapters, but the three current product branches do not yet form one working,
end-to-end real-data delivery loop.

- Vendor Mobile can authenticate and read/write several canonical domains in a
  non-prototype build. The current normalized UI nevertheless keeps storefront,
  subscription, notifications, online/offline state, accent colour and several
  settings in memory. Some repository methods exist but are not connected to a
  screen action. First-business onboarding has no `bootstrap_business` adapter.
- Driver Mobile has a useful real `RiderRepository`, but the UI only uses it for
  session hydration, scoped reads and sign-out. Sign-in, invitation acceptance,
  onboarding, assignment/run actions, stop sequencing, status transitions,
  delivery issues, POD completion, profile/documents and location are still
  prototype-local or disconnected from the repository.
- Customer Tracking has a real token-based read path, rating RPC bridge and
  protected POD Edge Function path. It is refresh-on-demand, not realtime. Its
  rating adapter marks the local UI successful before the asynchronous backend
  result is known, so a failed backend submission can still look persisted.
- The SQL migrations define most of the delivery contracts needed for a real
  loop, including tenant RLS, invitations, sessions, multi-stop runs, POD,
  token lifecycle, truthful ETA and rider-location RPCs. Their deployment and
  staging parity were not verified in this audit and remain `UNKNOWN / NEEDS
  AUDIT`.

Phase 2 must start with shared identity and role/context verification, then wire
Vendor, Driver and Customer in that order. Preview builds using
`CEFFLO_UI_PROTOTYPE=true` must continue to use demo data and must never be used
as evidence of backend persistence.

## 2. Audit boundary and evidence

### 2.1 Worktrees inspected

| Surface | Branch | Worktree | Observed role |
|---|---|---|---|
| Vendor Mobile | `claude/vendor-mobile-ui-normalization-3wvl4d` | `/tmp/cefflo-vendor-normalization` | Current normalized Flutter UI and current repository adapter |
| Driver Mobile | `claude/driver-flutter-implementation` | `/tmp/cefflo-driver-flutter-build` | Current Flutter Driver UI and repository adapter |
| Customer Tracking | `claude/customer-tracking-pwa` | `/tmp/cefflo-customer-pwa-build` | Current tokenized PWA, adapters and backend bridge |
| Earlier Vendor backend work | `claude/vendor-mobile-backend-integration` | `/tmp/cefflo-vmbi` | Migration/repository precedent and canonical backend implementation evidence |

The Vendor worktree already contained an unrelated modification to
`apps/vendor_mobile/analysis_options.yaml`. This audit did not touch it.

### 2.2 Verification limit

No Supabase MCP was available in this session. No credentials were read and no
remote database query was made. Therefore:

- tracked migration intent is verified by inspection;
- deployed schema, grants, RLS, buckets, Edge Functions, Auth provider settings,
  realtime publication and staging data are not verified;
- no staging flow, API mutation or paid call occurred;
- no application code, migration, UI, pipeline, Worker or domain was changed.

## 3. Supabase schema inventory

### 3.1 Tables in tracked migrations

| Domain | Tables |
|---|---|
| Identity and tenancy | `profiles`, `businesses`, `business_members` |
| Driver workforce | `riders`, `rider_invitations`, `team_invitations` |
| Delivery operation | `delivery_sessions`, `orders`, `rider_assignments`, `delivery_stops`, `delivery_events`, `rider_locations`, `zones` |
| Public tracking | `tracking_tokens`, `ratings`, `rate_limit_counters`, `invalid_lookup_telemetry` |
| Catalog/storefront | `product_categories`, `products`, `product_media`, `public_order_pages` |
| Platform administration | `platform_admins`, `admin_audit_log`, `business_profile_audit`, `feature_flags`, `maintenance_windows`, `business_subscriptions`, `app_versions`, `platform_announcements` |

Important enums include `member_role` (`owner`, `operator`, later `helper`),
`rider_status`, `delivery_status`, `assignment_status`,
`delivery_issue_reason`, `order_location_status`, `rider_vehicle_type`,
`vehicle_requirement`, `preparation_status` and `product_media_status`.

### 3.2 RLS policy inventory

Tracked migrations enable RLS and define these policy families:

| Domain | Policies and effective intent |
|---|---|
| Profile/business | `profiles_self`; business members may read their business; owners may update it; members may read memberships |
| Riders | vendor members may access riders in their business; a rider identity may read its own relationships; multi-business checks use `is_current_rider(rider_id)` |
| Orders/runs | vendor reads/mutations are tenant-scoped; Driver reads for orders, assignments, stops, events and sessions are restricted to that Driver identity/relationship |
| Location | vendor members may read their business locations; Driver insert is restricted to its own rider id and matching business id |
| Tracking/rating | public access is through security-definer RPCs, not direct anonymous table policies; vendors may read ratings for their orders |
| Invitations | owners manage team invitations; business members manage rider invitations; token resolution/acceptance is through RPCs |
| Catalog/storefront | authenticated vendor reads for categories/products/media/order pages are tenant-scoped by policies and RPC checks |
| POD storage | Driver upload and authenticated read require an authorized order relationship; later policy uses the multi-business rider check |
| FOUNDR/platform | platform-admin checks protect admin audit, feature flags, maintenance, subscriptions, versions and announcements |

Tracked policy names include: `profiles_self`, `businesses_read`,
`businesses_update`, `businesses_rider`, `members_read`, `riders_vendor`,
`riders_self`, `sessions_vendor`, `sessions_rider`, `orders_vendor`,
`orders_rider`, `assignments_vendor`, `assignments_rider`, `stops_vendor`,
`stops_rider`, `events_vendor`, `events_rider`, `locations_vendor`,
`locations_rider`, `ratings_vendor`, `zones_vendor`,
`team_invitations_owner`, `rider_invitations_vendor`,
`product_categories_vendor_read`, `products_vendor_read`,
`product_media_vendor_read`, `public_order_pages_vendor_read`,
`pod_rider_upload`, `pod_authorized_read`, and the platform-admin policy set.

Risk found: normalized Vendor code directly updates/deletes `zones`, while the
tracked `zones_vendor` policy is select-only. The canonical mutation RPCs cover
create, rename and status, but no delete-zone RPC was found. Direct rename/delete
should be treated as non-working until a staging RLS test proves otherwise;
delete needs an explicit contract and referential rule.

### 3.3 RPC/function inventory

The migrations define the following function families. Several functions are
replaced by later migrations; Phase 2 must validate the final deployed
signatures rather than relying on an earlier overload.

| Family | Functions |
|---|---|
| Identity/tenancy | `bootstrap_business`, `get_my_businesses`, `is_business_member`, `is_business_owner`, `current_rider_id`, `is_current_rider`, `is_session_rider`, `is_business_operational` |
| Vendor profile/team | `update_business_profile`, `update_team_member`, `create_team_invitation`, `resolve_team_invitation`, `accept_team_invitation`, `revoke_team_invitation` |
| Driver team | `create_rider_invitation`, `resolve_rider_invitation`, `accept_rider_invitation`, `revoke_rider_invitation`, `approve_pending_rider`, `update_rider_details`, `deactivate_rider` |
| Orders | `create_delivery`, `update_order_details`, `approve_order`, `decline_order`, `assign_rider`, `reassign_rider`, `import_orders_batch`, `advance_preparation` |
| Zones/coverage | `create_zone`, `rename_zone`, `set_zone_status`, `set_business_service_area`, `is_within_coverage`, `order_coverage_status`, `list_plannable_orders`, `haversine_km` |
| Planning/runs | `propose_delivery_plan`, `sequence_group_nearest_neighbor`, `create_delivery_session`, `attach_order_to_session`, `update_session_status`, `build_rider_run`, `check_run_vehicle_capacity`, `is_vehicle_compatible`, `rider_effective_capacity`, `rider_active_stop_count`, `default_capacity_for_vehicle` |
| Driver execution | `accept_assignment`, `decline_assignment`, `accept_run`, `decline_run`, `save_run_sequence`, `start_pickup_run`, `start_run_delivery`, `rider_transition`, `complete_delivery` |
| Exceptions/recovery | `vendor_report_delivery_issue`, `rider_report_delivery_issue`, `initiate_delivery_recovery` |
| Location/ETA | `record_rider_location`, `latest_rider_locations`, `compute_order_eta` |
| Tracking/rating | `public_tracking`, `submit_rating`, `revoke_tracking_token`, `rotate_tracking_token`, `internal_tracking_pod_path`, `check_rate_limit`, `record_invalid_lookup_telemetry` |
| Catalog/storefront | `create_product_category`, `update_product_category`, `archive_product_category`, `reorder_product_categories`, `create_product`, `update_product`, `archive_product`, `set_product_status`, `reorder_products`, product-media functions, `create_order_page`, `rotate_order_page_token`, `set_order_page_enabled`, `public_order_catalog`, `submit_public_order` |
| Platform administration | `is_platform_admin`, audit/flags/maintenance functions, vendor/rider/operations reads, subscription/version/announcement functions |

Grant-hardening migrations revoke broad execution and re-grant by role for many
functions. Signature drift is material: assignments, runs, transitions and
completion have older one-context overloads and later explicit `p_rider_id`
variants. Flutter adapters target the later explicit-context signatures.

### 3.4 Storage

| Bucket | Visibility | Purpose | Guard |
|---|---|---|---|
| `cefflo-pod` | Private | Proof-of-delivery images | Driver upload and authorized authenticated read; public customer access only through a 5-minute signed URL from `tracking-pod` |
| `cefflo-product-originals` | Private | Vendor-uploaded source product media | Authenticated vendor policies and media RPC workflow |
| `cefflo-product-display` | Public | Prepared storefront display media | Vendor write policy; catalog functions expose prepared assets |

The `tracking-pod` Edge Function validates allowed origins, rate-limits by token
hash, resolves public tracking, obtains the private path using a service-role-only
RPC, and returns a short-lived signed URL. Deployment and environment parity are
unverified.

### 3.5 Realtime

The foundation migration adds only these tables to `supabase_realtime`:

- `orders`
- `rider_assignments`
- `delivery_stops`

No tracked publication entry was found for `rider_locations`,
`delivery_sessions`, `delivery_events`, invitations or notifications. Neither
Flutter repository currently opens a Supabase channel. Customer Tracking does
not subscribe to realtime; it refreshes on initial load, visible refocus,
back/forward cache restoration and manual refresh with a three-second cooldown.

## 4. Vendor Mobile audit

### 4.1 Runtime boundary

`main.dart` has two explicit modes:

- `CEFFLO_UI_PROTOTYPE=true` creates `VendorRepository.demo()` and never
  initializes Supabase;
- non-prototype requires `CEFFLO_ENVIRONMENT=staging|local`, `SUPABASE_URL` and
  `SUPABASE_PUBLISHABLE_KEY`, then creates a real `VendorRepository`.

The preview URL therefore demonstrates UI/demo behavior only. It is not a real
backend verification environment.

### 4.2 Repository method matrix

| Repository method(s) | Adapter status | Current screen use |
|---|---|---|
| `sendEmailOtp`, `verifyEmailOtp`, `signInWithPassword`, `signUpWithPassword`, `sendPasswordReset`, `resendSignUpVerification`, `updatePassword`, `signInWithProvider`, `signOut` | Real Supabase Auth calls; OAuth provider configuration remains external/unverified | Password/signup/recovery/provider UI calls these in real mode; prototype auth is locally controlled |
| `myBusinesses` | Real `get_my_businesses`; demo fixture fallback | Used by `AppState.loadSession` |
| `orders`, `order` | Real tenant/order reads; demo fixtures | Used by Today, Orders, detail, zones, customers and storefront-derived screens |
| `createOrder`, `updateOrder` | Real RPC adapter; no internal demo fallback | UI branches around real calls in demo mode; real form path is connected |
| `approveOrder`, `reportIssue` | Real RPC adapters | No current normalized screen invocation found; effectively disconnected |
| `zones` | Real read; demo mutable list | Used |
| `createZone`, `setZoneStatus` | Real RPC adapters | Create is used; status action was not found in the normalized screen flow |
| `renameZone` | Demo mutation or direct table update | Screen uses it; likely blocked by select-only zone RLS in tracked migrations |
| `deleteZone` | Demo mutation or direct table delete | Screen uses it; no delete RPC/policy found, so real behavior is missing |
| `removeFromTodaysDeliveries` | Demo-only; real mode throws `isMissingContract` | Screen uses it and truthfully blocks real mode |
| `riders`, `team`, `products` | Real scoped reads with demo fallback | Used by list/detail/Today/storefront screens |
| `createRiderInvitation`, `createTeamInvitation` | Real RPC adapters | No screen invocation found; registration-link UI remains prototype presentation |
| `createProduct`, `updateProduct` | Real RPC adapters | Used in product form; demo mode has a separate local branch |
| `setServiceArea` | Real RPC with demo response | Used by Service Area |
| `orderCoverageStatus`, `isWithinCoverage`, `plannableOrders`, `proposePlan` | Real RPCs; planning reads have demo fixtures | Coverage/planning adapters exist; only proposal and service-area paths are visibly consumed by current normalized screens |
| `createDeliverySession`, `checkRunCapacity`, `buildRiderRun` | Real RPCs with demo responses | No invocation found in normalized UI; dispatch is not wired end-to-end |
| `business` | Real read/demo fixture | Used by Service Area |
| `updateBusinessProfile` | Real RPC | No invocation found from current business settings/setup screens |

### 4.3 Screen/data/action matrix

| Screens | Data state | Action state |
|---|---|---|
| V-01–V-05 auth | Real Auth available outside prototype | Real password/signup/recovery/provider calls; provider configuration unverified; prototype is local |
| V-06–V-10 first-business setup | Form values and progress are screen/session state | No `bootstrap_business` adapter or atomic onboarding save. V-10 explicitly says it persists nothing |
| V-11 Today | Real orders/riders outside prototype; hardcoded KPI/recent rows in demo | Online/offline toggle is `AppState.vendorOnline` only; notifications are local |
| V-12–V-15 Orders | Real list/detail/create/update paths outside prototype | Approve/issue adapters are disconnected; import source selection is UI-only and no canonical batch adapter is present in Flutter |
| V-16–V-19 Zones and run progress | Reads real zones/orders/plan/riders where called | Create is wired; rename/delete conflict with RLS/missing contract; remove-from-today is deliberately demo-only; run dispatch RPCs are disconnected |
| V-20–V-25 Riders and team | Real lists/details outside prototype | Invitation RPCs exist but link/create flows do not call them; member/rider editing and approval are not wired |
| V-26–V-30 Service area/zones | Business and service-area save can be real | Coverage/zone configuration is partial; deleted/consolidated inventory screens remain audit markers |
| V-31–V-36 Storefront/products | Products can be real; storefront template/branding comes from app memory | Product create/update real; `AppState.applyStorefront` only stores template/branding in memory; hero-image bytes are local; preview cart/payment/order success is explicitly prototype-only |
| X-05/X-06 Customers | Derived from orders, not a customer backend domain | Read-only derived presentation; no customer CRUD contract |
| V-37–V-45 Business/profile/security | Mostly prototype fields/defaults; business read exists elsewhere | Profile/address/hours/settings saves are not connected to `updateBusinessProfile`; change-password Auth path exists but other profile edits are local/inert |
| V-46–V-49 More/notifications/appearance | Notification feed and accent are `AppState` memory | Mark/read/delete notification, locale and accent changes are session-only; notification toggles are widget-local; Appearance is explicitly “Coming Soon” in product copy |
| V-50–V-54 Subscription | Plans, usage, invoices and renewal are local fixtures | `AppState.subscribe` succeeds only in demo and throws “Payments are not available yet” in real mode |
| V-55–V-60 Help/legal/about | Static/prototype content | Contact/support submission has no backend persistence |

## 5. Driver Mobile audit

### 5.1 Runtime boundary

Driver uses the same fail-closed pattern as Vendor: prototype mode creates
`RiderRepository.demo()` with no Supabase client; real mode requires explicit
staging/local build definitions before initializing Supabase.

### 5.2 Repository method matrix

| Repository method(s) | Adapter status | Current screen use |
|---|---|---|
| `signInWithPassword`, `signOut` | Real Supabase Auth | Sign-out is connected through `AppState`; no call from the current sign-in UI to `signInWithPassword` was found |
| `myRiderRelationships` | Real identity-scoped `riders` plus business-name reads | Used by session hydration |
| `myOrders` | Real explicit active-rider-scoped read with stops/assignment embed | Used by hydration/refresh |
| `sessions` | Real scoped read | Used only to label hydrated runs |
| `acceptAssignment`, `declineAssignment` | Real later-signature RPCs | Not invoked by UI |
| `acceptRun`, `declineRun` | Real later-signature RPCs | Not invoked by UI |
| `saveRunSequence` | Real RPC | Not invoked; UI reorders `currentRun` locally |
| `startPickupRun`, `startRunDelivery` | Real RPCs | Not invoked by sliders/UI |
| `transition` | Real `rider_transition` RPC with idempotency key | Not invoked by navigation/arrival UI |
| `reportDeliveryIssue` | Real RPC and canonical reason map | Not invoked; UI marks stop issue locally |
| `completeDelivery` / `_uploadPod` | Real private-storage upload then completion RPC | Not invoked; camera selection and delivery completion mutate local state only |

No repository method exists for invitation resolution/acceptance, rider
onboarding/profile/document persistence, notification read receipts, support
tickets, or rider location writes, despite tracked RPCs existing for invitation
and location domains.

### 5.3 Screen/data/action matrix

| Screens | Data state | Action state |
|---|---|---|
| D01–D08 Auth/recovery | DemoData/prototype flow; real Auth session can be restored at app boot | Sign-in/signup/recovery screens are not connected to `RiderRepository`; real sign-in cannot be initiated from this UI |
| D09–D18 Invitation/onboarding/join | Demo business/invite/profile/document data | Accept/join, details, document submission, pending/approved/active stages use navigation and `AppState.setStage`; no backend writes |
| D19 Today | Hydrated orders can form presentation runs in real mode; other profile/status content remains demo | Read/refresh only |
| D20–D21 Run/stop planning | `runs` groups real hydrated orders by session when real; `currentRun` remains a separate DemoData object used across UI | Accept/decline/reorder/confirm route are local; repository lifecycle methods are disconnected |
| D22 Navigation | Prototype map canvas and demo stop | No GPS, navigation provider, location write or arrival transition |
| D23 Confirm Delivery | Demo/currentRun stop and UI-local photo marker | No camera bytes reach storage; `markStopDelivered` is local; no `completeDelivery` call |
| D28–D29 Delivery issue | Issue reasons/photo/note are local controls | `markStopIssue` is local; no `rider_report_delivery_issue` call |
| D30 Run completed | Computed from local current run | No authoritative backend completion reconciliation |
| D31–D33 History/notifications | `DemoData.history` and `DemoData.notifications` | Notification read is local; no history query/read receipt |
| D34–D39 Profile/settings/documents/language | Demo profile/documents; language in `AppState` | Profile and document edits are local; no rider update/upload backend |
| D40 family Support | Demo categories/static UI | No ticket/contact persistence |

## 6. Customer Tracking PWA audit

| Capability | Current status |
|---|---|
| Tracking without `token` | Mock provider uses `TRACKING_FIXTURE`; query `state`/`dev=1` changes local demo state |
| Tracking with `token` | Loads shared config/client/backend scripts, holds a neutral loading state, calls anonymous `public_tracking`, and maps all canonical delivery statuses safely |
| Refresh | Initial load, visible refocus, bfcache restore and manual refresh; no timer and no realtime subscription by policy/current implementation |
| ETA | Real backend returns truthful state/range computed from locked stop sequence; no GPS-derived ETA |
| POD | Real token mode calls protected `tracking-pod` Edge Function and receives a five-minute signed URL; mock mode resolves a bundled asset |
| Rating | `submit_rating` RPC bridge exists, but `rating-adapter.js` dispatches an event, then immediately marks/stores local success; backend rejection is only logged asynchronously. This can falsely present persistence |
| Vendor/customer detail | Backend payload currently projects only reference, store name, status, rider name, ETA, completion and POD availability; fixture address/items/note can remain in the merged model unless token-loading state replaces the view fully. Customer-safe production payload requirements need an explicit contract review |
| Live Driver location | Not exposed. No realtime channel, no `rider_locations` read in `public_tracking`, and no Driver writer is connected |

## 7. Cross-app contract audit

### 7.1 Vendor ⇄ Driver

| Contract | Backend | Vendor client | Driver client | Result |
|---|---|---|---|---|
| Driver invitation | Tables/RPCs/RLS exist | Create adapter exists but UI disconnected | Resolve/accept adapter missing | Incomplete |
| Driver approval/membership | `approve_pending_rider`, multi-business rows and RLS exist | UI action not wired | Relationships read is real | Partial |
| Orders | Canonical table/RPC/RLS exists | Reads/create/update real | Scoped reads real | Read bridge exists |
| Approval | `approve_order` exists | Adapter disconnected | Driver relies on assigned orders | Incomplete trigger |
| Sessions/runs | Session/build/attach/capacity RPCs exist | Adapters disconnected | Reads group orders; accept/decline/start adapters disconnected | Incomplete |
| Stop sequence | `save_run_sequence` and locked sequence exist | Proposal read exists | Adapter exists but UI reorders locally | Incomplete |
| Status lifecycle | Server transition contracts exist | Vendor reflects order status | Driver UI does not call transition/start RPCs | Broken execution loop |
| Delivery issue/recovery | Typed issue/recovery RPCs exist | Adapter disconnected | Adapter disconnected | Incomplete |
| POD | Private bucket/policies/completion RPC exist | Vendor can read status, not POD in current Flutter UI | Upload/completion adapter exists but UI disconnected | Incomplete |

### 7.2 Driver → Customer

| Contract | Current truth | Gap |
|---|---|---|
| Delivery status | Customer reads canonical order status through `public_tracking` | Driver UI does not persist transitions, so customer will not advance from Driver Flutter actions |
| ETA | Server computes a coarse truthful range from stop sequence | Driver does not persist sequence/start state from UI; range cannot become authoritative through current flow |
| Latest location | `record_rider_location` and `latest_rider_locations` exist | Driver has no location adapter/service; customer RPC intentionally does not expose location |
| Realtime | Orders/stops/assignments are published | No clients subscribe; rider locations are not published |
| POD | Signed customer path exists | Driver UI does not upload/complete through repository |

## 8. Backend and wiring gaps, with risk

| Priority | Gap | Risk |
|---|---|---|
| Critical | Deployed staging schema/function/RLS parity is unknown | Client wiring may target missing or wrong RPC overloads and produce false confidence |
| Critical | Driver auth UI is disconnected | A new Driver cannot establish a real session from the Flutter product |
| Critical | Driver operational actions are local | Vendor and customer never receive authoritative progress/POD/issue changes |
| Critical | Vendor first-business setup has no atomic backend path | A newly created account can authenticate but cannot complete a real business bootstrap flow |
| Critical | Customer rating acknowledges before backend success | Fake persistence and duplicate/retry inconsistency |
| High | Invitation create/resolve/accept/approve is not connected end-to-end | Trusted-team onboarding cannot operate safely |
| High | Vendor dispatch adapters are disconnected | Orders cannot move from plan into a real Driver run from normalized UI |
| High | Zone rename/delete uses direct writes without matching tracked policy/contract | Runtime authorization failures or unsafe future policy broadening |
| High | POD adapter is disconnected from the camera flow | Completion has no authoritative evidence despite UI success |
| High | No Driver location service/writer | No latest location, no route-aware tracking and no location-derived ETA |
| Medium | No realtime subscriptions in current clients | Status is stale until refresh; vendor operational views do not react to changes |
| Medium | Storefront config/branding has no canonical schema/adapter in Flutter | “Live” customization disappears on restart and can mislead vendors |
| Medium | Notifications/preferences/read receipts are local | Inconsistent state across devices and sessions |
| Medium | Business/profile/hours/delivery settings are mostly prototype UI | Edits can appear actionable without persistence |
| Medium | Subscription/billing is demo-only | Must stay explicitly unavailable until commercial/payment architecture is approved |
| Medium | Driver profile/documents/history/support are demo-only | Cannot support approval, compliance or service workflows |
| Low | Appearance/accent/locale are local | Preference resets; low operational impact if labeled honestly |

## 9. Phase plan and effort estimate

Estimates are engineering days for one experienced engineer, excluding Founder
decision latency, external Auth/OAuth setup, app-store work and production
release gates. Each phase includes repository tests, Flutter analyze/test/build,
staging fixtures, 393×852 screenshots and an honest REAL-vs-DEMO report.

| Phase | Scope | Estimate |
|---|---|---:|
| 2A — Staging truth and shared identity | Verify target identity and migration parity; exercise final RPC signatures/RLS/buckets/Edge Function; wire Vendor/Driver password auth and role/context selection; preserve prototype boot | 4–6 days |
| 2B — Vendor core | Atomic business bootstrap; profile/service area; orders/create/edit/approve/issues; zone mutations through RPC; invitations/approval; planning/session/capacity/dispatch; realtime refresh for operational tables | 8–12 days |
| 2C — Driver core | Real sign-in/recovery; invitation acceptance/onboarding; active business context; assignment/run actions; sequence/start/transition/issues; camera POD; refresh/realtime reconciliation | 10–15 days |
| 2D — Location and Customer Tracking | Foreground/location permission policy, throttled `record_rider_location`, customer contract choice, tracking refresh/realtime behavior, rating await/error/idempotency, POD end-to-end | 5–8 days |
| 2E — Secondary truthful boundaries | Storefront persistence decision/schema, notification/preferences boundaries, profile/documents/history/support, explicit HOLD for payments/subscription | 6–10 days |
| 2F — Cross-app release verification | Staging seed and cleanup, tenant-negative tests, full Vendor→Driver→Customer E2E, offline/error cases, builds/screenshots, rollback evidence | 4–6 days |

**Total:** approximately **37–57 engineering days**. A narrower operational
MVP through phases 2A–2D is approximately **27–41 days**. Schema work, if
approved, must use new migrations; existing migrations must not be edited.

## 10. Founder gate

Phase 1 stops here. No implementation is authorized by this report.

Founder approval is required to start **Phase 2A — Staging truth and shared
identity**. That approval should authorize read-only staging inspection and
controlled staging test data, then one app at a time in this fixed order:

1. Vendor Mobile
2. Driver Mobile
3. Customer Tracking PWA

Production access, production migration, production data mutation, UI redesign,
new infrastructure/domains, payment activation and preview-pipeline changes
remain outside this gate.
