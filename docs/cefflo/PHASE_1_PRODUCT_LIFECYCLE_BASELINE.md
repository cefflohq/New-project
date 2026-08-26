# CEFFLO — Phase 1 Product Surface & Cross-App Lifecycle Baseline

Status: P1.4 repository product/code reconciliation — Founder review required

Baseline inspected: `main` at `5920578738bb87c0cd903258658f4531f82f926f`

Scope: static repository evidence only; no production system, provider, database, or deployed application was accessed

## 1. Authority, method, and classification

This audit reconciles the current repository with [01_PRODUCT.md](01_PRODUCT.md), [04_CURRENT_STATE.md](04_CURRENT_STATE.md), [06_VENDOR.md](06_VENDOR.md), [07_RIDER.md](07_RIDER.md), [08_CUSTOMER_TRACKING.md](08_CUSTOMER_TRACKING.md), [09_FOUNDR.md](09_FOUNDR.md), [10_DELIVERY_LIFECYCLE.md](10_DELIVERY_LIFECYCLE.md), and the approved Phase 1 audits [PHASE_1_REPOSITORY_INVENTORY.md](PHASE_1_REPOSITORY_INVENTORY.md), [PHASE_1_ACTIVE_LEGACY_CLASSIFICATION.md](PHASE_1_ACTIVE_LEGACY_CLASSIFICATION.md), and [PHASE_1_DEPLOYMENT_DOMAIN_MAP.md](PHASE_1_DEPLOYMENT_DOMAIN_MAP.md).

The trace followed actual script order, global handler replacement, UI actions, browser stores, surface adapters, shared transport, migration tables/RPCs, Edge Function behavior, and database-test intent. Documentation intent alone is not implementation evidence.

Classifications:

- **VERIFIED IMPLEMENTED** — the repository contains a traced implementation path for the stated capability; this is not a live-production PASS.
- **PARTIAL** — meaningful implementation exists but the contract, state coverage, or cross-surface result is incomplete.
- **UI-ONLY** — a reachable UI represents the capability without an authoritative backend operation/read model.
- **BACKEND-ONLY** — a backend schema/operation exists but is not properly exposed by the current product surface.
- **LOCAL-MOCK** — reachable browser-only, seeded, fabricated, or simulated behavior.
- **MISSING** — no relevant implementation was found.
- **BLOCKED** — implementation or validation cannot safely proceed until a prerequisite is resolved.
- **DECISION REQUIRED** — product or architecture direction must be confirmed by the Founder.

## 2. Current product baseline

The repository contains three built static surfaces: Vendor, Rider, and Customer Tracking. Vendor and Rider are visually substantial mobile-first PWAs; Customer Tracking is a token-oriented public page. FOUNDR, the marketing site, and a vendor customer-facing sales/order page are absent.

The protected repository happy path is:

1. Vendor authenticates and creates an order through `create_delivery`.
2. Vendor assigns one rider to one order through `assign_rider`.
3. Rider authenticates as an active rider and reads RLS-filtered orders.
4. Rider advances `created → ready_for_pickup → picked_up → out_for_delivery → arrived` through `rider_transition`.
5. Rider uploads POD to the private bucket and calls `complete_delivery`.
6. Customer polls `public_tracking`, retrieves delivered POD through the Tracking Edge Function, and can call `submit_rating`.

That chain is statically wired, protected by RPC/RLS checks in the tracked migration, and represented in the database transaction test. It is not the whole approved Stage 4 product. Order approval, team invitation, operational batching/zone/session ownership, protected exceptions, resilient offline mutation, tracking-token recovery, and truthful Customer failure states remain incomplete.

## 3. Vendor capability matrix

| Capability | Classification | Repository evidence | Product reconciliation / required treatment |
|---|---|---|---|
| Onboarding and authentication | `PARTIAL` | Vendor provides signup, email login, reset callback, business bootstrap, session restore, and logout. Inline auth/session transport competes with `shared/client.js` | Preserve auth screens and business onboarding flow; consolidate transport/session ownership and validate provider/error states rather than redesigning |
| Business/store context | `PARTIAL` | `bootstrap_business` and `get_my_businesses` exist; authenticated hydration applies one selected business. Profile editing remains local/no-op sync | Preserve business identity UI; bind profile mutation to an approved protected backend contract |
| Dashboard | `PARTIAL` | Dashboard, KPIs, Current Deliveries, Action Required, notifications, and empty states are visually present | Preserve layout. Remote hydration clears sessions/stops/assignments/issues, so operational cards lack authoritative read models and need data-binding adjustment |
| Orders list/detail/history tabs | `PARTIAL` | Remote orders and ratings hydrate through `vendor/backend.js`; ongoing/issue/completed tabs and detail views exist | Preserve list/detail shell. Status meaning, issue data, tracking availability, money fields, and event history need canonical mapping |
| Manual customer/order intake | `VERIFIED IMPLEMENTED` | Final wizard handler is replaced by `create_delivery`; returned token is stored and orders rehydrate | Retain as current protected intake path; add approval semantics and token recovery without rebuilding the wizard |
| CSV/import intake | `LOCAL-MOCK` | Parser, correction UI, and import confirmation insert into browser state; adapter does not replace the handlers and sync is a successful no-op | Preserve import UX as design evidence; block or connect it to protected bulk intake before production use |
| Customer-facing vendor sales/order landing page | `MISSING` | No storefront, catalog, public vendor order route, or public order-submission contract exists | Build only after exact Stage 4 sales/order scope is approved; do not confuse the internal Vendor intake wizard with customer sales intake |
| Supported business concepts/types | `MISSING` | Generic business name/profile and arbitrary order items exist; no bakery/catering/frozen-food/meal-prep/dessert/preorder concept model or UI selection exists | Founder must decide whether Stage 4 needs explicit types, type-specific fulfillment behavior, or only configurable generic businesses |
| Order approval | `MISSING` | Backend `create_delivery` creates status `created`; adapter maps `created` directly to Vendor `readyForPickup`. No Vendor approve/reject RPC or reachable approval action exists | Define acceptance/approval states and a protected mutation; do not reuse old local fulfillment/payment statuses without contract review |
| Batching | `UI-ONLY` | Local engine groups session/zone assignments and multiple orders; no protected batching operation owns the result | Preserve dispatch concepts and screens; implement against approved session/assignment/stop contracts |
| Delivery zones | `LOCAL-MOCK` | Address-derived zones, zone cards, capacity, assignment, and route logic exist locally; tracked migration has no zones table | Preserve the useful UI/route logic; decide whether zones are persisted entities, derived plans, or both |
| Multi-drop route/session creation | `PARTIAL` | Migration has `delivery_sessions`, assignments, stops, sequence, and ETA fields; local engine creates/recalculates them. Active adapter does not persist or hydrate the full model | This is split `BACKEND-ONLY` foundation plus `UI-ONLY` orchestration. Connect them through protected contracts; do not rebuild the route UI |
| Rider team management | `UI-ONLY` | Rider list/profile/filter/deactivate/invite screens exist; remote hydration can list riders, but mutations and performance data are local | Preserve list/profile shell; add protected team-member lifecycle and authoritative aggregates |
| Rider invitation/join link | `MISSING` | “Invite Rider” immediately creates an active local rider. No invitation token, join link, pending membership, acceptance, expiry, or approval backend contract exists | Build a protected invitation/join workflow before production team onboarding |
| Single-order rider assignment | `VERIFIED IMPLEMENTED` | Order detail calls protected `assign_rider`, validates active same-business rider, creates assignment, updates order/stop, and records event | Retain as current protected baseline; reconcile it with session/batch assignment to prevent one assignment row per order from becoming the long-term route model accidentally |
| Zone/session rider assignment | `UI-ONLY` | Dispatch/profile actions create local sessions, assignments, stops, and route sequence; adapter sync resolves without server writes | Preserve UI and validation ideas; replace local success with protected session/route commands |
| Current Deliveries | `PARTIAL` | Cards derive from local session/stop/assignment state; remote adapter clears those arrays | Preserve component structure. Add an authoritative active-delivery read model instead of redesigning |
| Delivery history | `PARTIAL` | Completed order tab exists and backend provides completed orders/timestamps; detailed event history is local-only and adapter clears it | Preserve completed-order views; expose append-only `delivery_events` through an authorized read model |
| Rider performance | `UI-ONLY` | Vendor shows delivered count, success rate, average time, and issues from local/seeded rider fields; no backend aggregate contract exists | Preserve presentation only if metrics are approved; define metric semantics and backend aggregation before displaying as truth |
| Tracking-link creation | `VERIFIED IMPLEMENTED` | `create_delivery` generates a high-entropy token and Vendor opens Customer Tracking with it | Protected creation is implemented; browser-only retention makes the product capability incomplete over time |
| Tracking-link recovery | `MISSING` | Token is stored only as cleartext in the creating browser; backend retains only its hash and provides no vendor recovery/rotation operation | Implement the approved protected recovery/rotation contract; never expose token hashes as substitutes |
| Exception states | `LOCAL-MOCK` | Vendor can report/reschedule/resolve issue-like states locally; backend enum has `issue` but no protected exception command/model | Preserve issue UI patterns; define protected issue types, ownership, resolution, retry, and event semantics |
| Offline/network states | `PARTIAL` | Network/offline state, queue, realtime status, and banners exist, but adapter replaces full-state sync with a successful no-op | Preserve status UX; define which reads/mutations can work offline and ensure queued operations cannot report false persistence |

## 4. Rider capability matrix

| Capability | Classification | Repository evidence | Product reconciliation / required treatment |
|---|---|---|---|
| Authentication | `PARTIAL` | Adapter login uses shared Supabase auth, checks an active rider row, hydrates orders, and restores sessions | Preserve login UI. Replace local-only logout and recovery, then validate phone/email provider behavior |
| Team membership | `PARTIAL` | Active `riders.auth_user_id` and business ownership are backend-enforced for reads/mutations | There is no join/acceptance product flow. A pre-provisioned active rider can operate, but onboarding into the team is missing |
| Rider application/signup | `LOCAL-MOCK` | Guided application, document/selfie UI, fixed mock OTP, pending review, and local rider record are reachable | UI represents an older marketplace/application strategy and false verification. Reframe or replace with vendor-team invitation/join flow; preserve only reusable form components if approved |
| Invitation/join flow | `MISSING` | No invite token, link consumption, vendor/team binding, expiry, or acceptance path exists | Build the approved trusted-team join flow; do not treat mock open application as equivalent |
| Assignment receipt | `PARTIAL` | Rider reads RLS-filtered orders; exported assignment fetch is unused. Assignment card retains seeded vendor/session/window/distance data | Preserve assignment/home card shell; hydrate an explicit assignment/session/stop read model and remove fabricated metadata |
| Pickup | `VERIFIED IMPLEMENTED` | Rebound pickup handler calls protected transitions to `ready_for_pickup` and `picked_up` | Preserve pickup screens; add loading/idempotent refresh and assignment/session context validation |
| Route | `PARTIAL` | Multi-stop route/map UI consumes hydrated orders and sequence; missing coordinates default to Kuala Lumpur and ETA/distance are locally fabricated | Preserve route, map, and next-stop components. Bind to canonical stops/route data and label unavailable navigation data truthfully |
| Multiple stops | `PARTIAL` | UI executes an ordered array of orders; backend has delivery stops and sequence, but Rider does not query stops or group by one assignment/session | Use explicit assignment/stops, not an unscoped orders projection; preserve current stop-flow interaction |
| Lifecycle transitions | `VERIFIED IMPLEMENTED` | Adapter calls protected transition RPCs for pickup, dispatch start, and arrival with idempotency keys | Retain RPC owner. Handle refresh/race/error states and keep Vendor/Customer mapping consistent |
| POD capture/upload | `VERIFIED IMPLEMENTED` | Camera input captures a file, shared client uploads to private `cefflo-pod`, and `complete_delivery` requires arrival plus POD path | Preserve capture/confirmation UI. Add upload progress, retry, resumability policy, and explicit failure recovery |
| Completion | `PARTIAL` | Protected completion updates order/stop/event. UI advances to next stop/summary | “Complete Session” resets the app to mock orders rather than closing/rehydrating an authoritative assignment; replace this behavior |
| Exceptions | `LOCAL-MOCK` | Unreachable customer, alternate drop, breakdown, wrong address, and redelivery screens mutate local state and claim vendor notification/approval | Preserve the operational scenarios and SOP UI; implement protected issue commands and truthful pending/acknowledged states |
| Offline/network | `PARTIAL` | Offline banner and map fallback exist | No durable protected mutation queue/reconciliation exists for pickup, arrival, POD, completion, or issues; prevent offline false success and define retry rules |
| Availability | `LOCAL-MOCK` | Online/offline toggle only changes local storage and copy | Define whether availability is Stage 4, its backend owner, GPS relationship, and active-assignment constraints |
| Profile/history/performance | `LOCAL-MOCK` | Profile edits/photo/preferences are local; performance uses current orders plus fixed time/distance; history is derived from current browser state | Preserve profile and performance components selectively; bind approved fields/metrics or make them read-only |

## 5. Customer Tracking capability matrix

| Capability | Classification | Repository evidence | Product reconciliation / required treatment |
|---|---|---|---|
| Token entry | `PARTIAL` | Adapter reads only `?token=` and calls `public_tracking`; no manual entry or neutral loading gate exists | Query-link access is appropriate, but initial rendering must wait for validation. Manual token entry is a product decision, not automatically required |
| Customer-visible status | `PARTIAL` | Backend maps ready/picked-up/out/arrived/delivered into three customer states | `created`, `issue`, and `cancelled` fall through to `picked_up`; define safe mappings so pre-pickup or exception states never claim pickup |
| ETA/progress | `PARTIAL` | RPC can return `estimated_arrival_at`; UI has progress/map/ETA components | Map and motion are decorative; no live location is consumed. Show ETA only when backed by reliable data and expose stale/unavailable states |
| POD retrieval/display | `PARTIAL` | Delivered POD uses the Tracking Edge Function to mint a signed private URL | Retrieval failure is caught and replaced by a fabricated demo POD; remove fallback and show pending/unavailable/retry state |
| Rating | `PARTIAL` | `submit_rating` protects delivered-only, one-rating persistence | UI stores local success and thanks state before RPC confirmation; adapter only logs rejection. Backend result must control success |
| Invalid/expired/missing token | `LOCAL-MOCK` | RPC rejects/returns null, but error handling changes only the hero label after seeded content rendered | Replace with a neutral full-page invalid/expired state that exposes no seeded customer/order/rider/POD information |
| Network/stale/error states | `MISSING` | Initial error only changes hero text; polling failures are silently ignored | Add loading, offline, stale-data, retry, POD-unavailable, and rating-failure states without fabricating operational truth |
| No-account access | `VERIFIED IMPLEMENTED` | Public token RPC and Edge Function require no customer account | Preserve; do not add customer signup/login without a new Founder decision |

## 6. Cross-app lifecycle matrix

| Vendor action | Backend state / contract | Rider state / action | Customer-visible state | Classification and break |
|---|---|---|---|---|
| Customer submits on vendor sales page | No sales page or public order-intake contract | No assignment | No token/link | `MISSING`: approved sales direction has no entry path |
| Vendor manually creates order | `create_delivery` inserts order `created`, stop, token hash, and creation event | RLS order becomes readable only after assignment | Adapter incorrectly maps unrecognized `created` to `picked_up` if customer already has the link | Vendor creation `VERIFIED IMPLEMENTED`; customer pre-pickup mapping `PARTIAL` and misleading |
| Vendor reviews/approves order | No approval/rejection RPC; Vendor maps `created` to `readyForPickup` | May see an order treated as pickup-ready after assignment | `created` defaults to Picked Up | `MISSING`: acceptance and readiness are conflated |
| Vendor batches by zone/session | Migration provides sessions/assignments/stops; current UI builds zone/session plan locally | Rider does not read assignment/session/stop model | No reliable batch context is exposed | `UI-ONLY` plus `BACKEND-ONLY`: no protected orchestration joins the two |
| Vendor assigns one rider to one order | `assign_rider` validates business/active rider, creates assignment, updates order/stop, appends event | Assigned order becomes readable through RLS | Rider name may become visible; status mapping remains pre-pickup unsafe | `VERIFIED IMPLEMENTED`, but assignment granularity conflicts with planned multi-drop ownership |
| Vendor invites rider | Local UI immediately creates active rider | No token/join/auth binding occurs | Not applicable | `LOCAL-MOCK` / `MISSING`: false team success |
| Rider receives assignment | Orders query relies on RLS; explicit assignments function is unused | Home/route combines remote orders with seeded assignment metadata | No change until lifecycle mutation | `PARTIAL`: data source is real, assignment context is fabricated |
| Rider confirms pickup | `rider_transition` enforces `created → ready_for_pickup → picked_up` | UI advances through multi-order pickup | Customer sees Picked Up | `VERIFIED IMPLEMENTED` happy path; UI refresh/retry behavior remains partial |
| Rider starts delivery | Each picked-up order transitions to `out_for_delivery` in a client loop | Route screen becomes active | Customer sees On The Way | `PARTIAL`: protected per-order transitions exist, but there is no atomic assignment/session start |
| Rider arrives | `rider_transition` enforces `out_for_delivery → arrived` and updates stop | POD screen opens | Customer continues to see On The Way | `VERIFIED IMPLEMENTED` mapping, subject to refresh/error handling |
| Rider reports exception | Browser state only; no protected issue/event mutation | UI claims vendor notification, approval, pause, or redelivery | Backend may still show ordinary On The Way; `issue` would incorrectly map to Picked Up | `LOCAL-MOCK`: cross-app state diverges |
| Rider uploads POD and completes | Protected private upload plus `complete_delivery`; order/stop/event become delivered | UI advances to next stop or summary | Customer sees Delivered and requests signed POD | `VERIFIED IMPLEMENTED` happy path; POD retrieval failure becomes fabricated image |
| Rider completes assignment/session | No Rider backend call; UI resets to seeded mock orders | Mock route reappears | No direct change | `LOCAL-MOCK`: lifecycle closure is broken |
| Customer rates delivery | `submit_rating` persists only for delivered, valid token, one time | Vendor can read ratings on hydration | UI confirms before persistence result | Backend `VERIFIED IMPLEMENTED`; customer success contract `PARTIAL` / false-success risk |
| Vendor reopens tracking link later | No recoverable cleartext token contract | Not applicable | Customer cannot be reached without original browser token | `MISSING`: browser loss breaks link recovery |

## 7. Required gap summaries

### 7.1 Sales/order-page gap

The repository has an internal Vendor manual wizard and local CSV import, not a vendor-controlled public sales/order page. There is no catalog/business-concept model, public vendor slug, customer basket/order form, vendor approval queue, payment-direction UI, or protected public submission contract. Stage 4 scope must distinguish a minimal order-request page from a full storefront. The current internal wizard should be preserved and reused where appropriate, but it does not satisfy the sales direction.

### 7.2 Rider invitation/team gap

The Vendor invite screen creates an active local rider immediately. The Rider surface instead offers an open application with document/selfie capture, mock OTP, and simulated vendor review. Neither path creates a backend invitation, links an authenticated user to the inviting business, or models pending/accepted/expired/revoked states. This also reflects old product strategy: open rider application language conflicts with the approved vendor-owned/trusted-team model.

### 7.3 Batching, zone, and multi-drop gap

The most complete visual/algorithmic prototype is already present: Vendor sessions, zones, capacities, multi-order assignments, stop sequencing and route calculation; Rider pickup, route, map, ordered stops and summary. The migration also contains sessions, assignments, stops and sequences. The missing layer is protected orchestration and shared read models. Zones have no tracked backend table, Rider does not consume explicit assignments/stops, and Vendor remote hydration clears the operational structures. This area requires integration and contract adjustment, not wholesale UI reconstruction.

### 7.4 Exception and offline gap

Operational exception screens cover meaningful Stage 4 scenarios, but all outcomes are browser-local and some claim remote notification/approval. The backend only has generic `issue` enum values and append-only events; no issue entity or protected report/resolve/reassign/redelivery contract exists. Offline support is limited to shells, banners, map fallback, and a Vendor queue whose active sync owner is a successful no-op. No cross-app conflict/retry/idempotency UX exists for offline lifecycle mutations or POD.

### 7.5 FOUNDR minimum-scope gap

FOUNDR is absent: no source directory, route, build output, hostname rewrite, privileged auth boundary, or backend administrative contract exists.

Minimum canonical Stage 4 product capability, subject to detailed authorization design:

| FOUNDR capability | Current state | Minimum required outcome |
|---|---|---|
| Founder Overview | `MISSING` | Operational health and urgent action summary |
| Platform / system / integrations health | `MISSING` | Read-only visibility for critical application, Supabase, Vercel, Cloudflare/DNS, and release health where authorized |
| Vendors and riders | `MISSING` | Searchable status/relationship visibility with least-privilege protected actions only where Stage 4 requires |
| Delivery operations | `MISSING` | Cross-business operational visibility, exception awareness, and controlled intervention with reason capture |
| Platform controls and maintenance | `MISSING` | Emergency-only maintenance and controlled operational switches; no client-only trust |
| Feature and client-version control | `MISSING` | Safe release/PWA version controls required for production operation |
| Announcements/emergency | `MISSING` | Controlled communication path if included in Stage 4 release scope |
| Admin audit log | `MISSING` | Append-only record of privileged actions, actor, reason, and result |
| Developer mode | `DECISION REQUIRED` | Define whether it is required at Stage 4 and ensure it cannot weaken production controls |

FOUNDR must not be reduced to an unprotected CRUD dashboard. Its exact Stage 4 action set, roles, confirmation rules, and audit requirements need Founder approval before implementation.

## 8. Preserve vs Adjust vs Build matrix

| Product area | Preserve | Adjust / integrate | Build |
|---|---|---|---|
| Vendor | Mobile shell, dashboard hierarchy, order list/detail, manual intake wizard, dispatch/zone/session concepts, rider list/profile, Current Deliveries, issue scenarios | Shared auth ownership, authoritative read models, status mapping, remote mutations, truthful loading/error/offline states, approved metrics | Sales/order page, approval contract, protected bulk import, rider invitation/join, token recovery |
| Rider | Login shell, assignment/home layout, pickup flow, route/map/stops interaction, POD capture, next-stop/summary screens, exception scenario components | Team-bound auth, explicit assignment/session/stop hydration, real ETA/location handling, protected exceptions, logout/recovery, truthful offline behavior | Invitation acceptance/join flow, durable lifecycle retry/reconciliation, authoritative session completion |
| Customer Tracking | No-account page structure, three-state progress concept, summary, POD viewer, rating form | Neutral validation/loading, safe status mapping, signed-POD errors, backend-confirmed rating, stale/network/error states | No new account system; add only any approved token-entry/recovery experience |
| Shared/backend | Protected lifecycle RPCs, RLS intent, private POD bucket, Tracking Edge Function, append-only events | Assignment/session granularity, approved issue model, explicit surface read models, shared auth/session/transport | Protected invitation/join, order approval, tracking-token recovery, sales intake, any required zone contract |
| FOUNDR | Nothing implemented to preserve; canonical module list is requirements evidence | Decide Stage 4 minimum and privileged authorization model | Entire approved minimum command-center surface and protected server contracts |

## 9. Backend capabilities present but underexposed

- `delivery_sessions`, `rider_assignments`, and `delivery_stops` exist, but Vendor remote hydration and Rider assignment receipt do not expose them coherently.
- `delivery_events` records create, assignment, transition, and completion events, but Vendor history and FOUNDR have no authorized event timeline.
- `business_members` and membership helpers exist, but the product has no team-member or invitation administration workflow.
- Rider RLS and protected lifecycle RPCs provide a credible authorization core, but the Rider UI still presents seeded assignment metadata.
- Tracking token expiry/revocation fields exist, but no Vendor recovery/rotation UI or protected contract exists.
- Ratings are protected and vendor-readable, but Vendor performance/reporting does not use a defined authoritative aggregate.
- Private POD storage and signed retrieval exist, but Customer error handling hides failures behind fabricated POD.

## 10. UI that represents old or conflicting product strategy

- Rider “Become a CEFFLO Rider,” application review, licence/selfie verification, and open signup imply a platform-managed rider supply/application model. Stage 4 direction is vendor-owned/trusted rider teams.
- Vendor subscription/plan/billing screens are present although billing activation is not part of this audit and must not distract from Stage 4 operational readiness.
- Vendor local kitchen/payment states (`pendingPayment`, `confirmed`, `kitchenQueue`, `packing`, `sorting`) are not represented in the protected backend lifecycle and must not silently become canonical delivery states.
- Vendor-side delivery execution and simulated POD overlap Rider ownership; useful components may remain as operational visibility or support tooling, but primary lifecycle mutation belongs to protected Rider/server contracts.
- Customer decorative live map/progress can imply real live tracking despite no current customer location feed.

## 11. Founder decisions required before implementation

1. Define the minimum Stage 4 vendor sales/order page: order request versus catalog/storefront, required product fields, payment messaging, and vendor approval behavior.
2. Decide whether explicit business concept/type selection is required at Stage 4 and which behavior, if any, varies by type.
3. Approve the canonical order acceptance/readiness contract and its mapping to the delivery lifecycle.
4. Approve the trusted-rider invitation/join lifecycle, including inviter authority, authentication method, expiry, approval, revocation, and whether any open application remains.
5. Define zones as persisted business entities, derived dispatch plans, or a hybrid, and approve the session/batch/assignment granularity.
6. Confirm that explicit assignment/session/stop read models replace Rider's unscoped orders projection and seeded assignment metadata.
7. Approve the Stage 4 exception model: issue types, who may report/resolve, reassign/redelivery rules, customer visibility, and append-only event requirements.
8. Define the offline promise per surface, including which actions are blocked, queued, retryable, or never allowed offline.
9. Confirm Customer mappings for pre-pickup, issue, cancelled, expired, unavailable, and stale states; no mapping may fabricate progress.
10. Approve the minimum FOUNDR Stage 4 modules and privileged actions, roles, confirmation/reason capture, and audit requirements.
11. Approve which Vendor/Rider performance metrics are Stage 4 requirements and define their formulas before backend aggregation/UI truth is implemented.
12. Confirm whether manual Customer token entry is required; tokenized links remain the default no-account access model.

Previously approved ownership and safety direction remains controlling: shared client for common auth/session/transport, surface adapters for orchestration, protected RPCs for lifecycle mutation, protected Rider POD plus Tracking Edge Function retrieval, protected tracking-token recovery, and no operational mock/demo fallback in production.

## 12. Recommended implementation entry after approval

The first executable product task should define and implement the canonical assignment/session/stop read contract used by both Vendor and Rider, without redesigning either surface. It should replace seeded Rider assignment truth and Vendor-cleared operational arrays with one authorized backend view while preserving the existing UI shells. This unlocks truthful batching, multi-drop, Current Deliveries, route context, lifecycle validation, and later exception work.

This recommendation is not implementation authorization. P1.4 changes no application, backend, configuration, infrastructure, or deployment behavior and does not begin P1.5.
