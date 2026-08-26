# CEFFLO — Phase 1 Active vs Legacy Classification and Reachability Trace

Status: P1.2 static code trace only

Baseline inspected: `main` at `cf8da040bec18932a048d384fe74f9510a1566f8`

Authority: `00_AGENTS.md`, `04_CURRENT_STATE.md`,
`PHASE_1_REPOSITORY_INVENTORY.md`, and routed domain contracts
`06_VENDOR.md`, `07_RIDER.md`, `08_CUSTOMER_TRACKING.md`,
`10_DELIVERY_LIFECYCLE.md`, `11_SUPABASE.md`, `12_SECURITY.md`, and `15_PWA.md`

## 1. Scope and evidence boundary

This register traces current imports, parser/script order, initializers, global
rebinding, DOM handlers, event listeners, state stores, and backend calls. It
does not assert that a repository-reachable path is deployed or working in
production. In this document, **production-reachable** means reachable from the
current built client without a developer-only switch; no production system was
accessed.

Classifications:

- **CANONICAL-CANDIDATE** — recommended eventual single owner, subject to Founder approval and later validation.
- **ACTIVE** — reachable in current code and intentionally wired to an entry point.
- **PROTOTYPE-EMBEDDED** — reachable mock, demo, local-only, or simulated behavior inside an active surface.
- **LEGACY-CANDIDATE** — superseded or ownerless path whose reachability/removal still needs a decision.
- **DEAD** — no current import, call, handler, build, manifest, or runtime consumer was found.
- **UNKNOWN** — static evidence cannot resolve runtime reachability or ownership.

## 2. Script and ownership topology

| Surface | Parser/runtime order | Resulting ownership |
|---|---|---|
| Vendor | Inline config → monolithic inline app and initialization → session-key declaration → `shared/config.js` → `shared/client.js` → `vendor/backend.js` → service-worker registration | Inline auth and engine are installed first. The adapter later replaces hydration, sync, order creation, single-order assignment, and tracking-link handlers. All other inline handlers remain callable. |
| Rider | Multiple inline app/refinement scripts → Leaflet CDN → session-key declaration → `shared/config.js` → `shared/client.js` → `rider/backend.js` → service-worker registration | The adapter replaces login, pickup, delivery start, arrival, POD selection, and completion. Signup, password reset, logout, session completion, availability, profile, issues, route display, and startup recovery remain inline. |
| Customer Tracking | Inline seeded tracking/rating UI renders immediately → session-key declaration → `shared/config.js` → `shared/client.js` → `customer/backend.js` | Seeded UI is visible before backend refresh. The adapter updates state on load and every 15 seconds but does not replace POD fallback or rating-submit UI behavior. |

## 3. Vendor reachability register

| Implementation path | Entry point | Owner | Call / reachability chain | State / data source | Production-reachable? | Competing path | Classification | Evidence | Risk | Recommended eventual treatment | Founder decision? |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Inline email signup/login/reset/session restore | Auth buttons and `initializeSprint13()` | `vendor/index.html` | DOM `onclick` → `submitProduction*` → `authRequest()` / `storeAuthSession()` → `hydrateAuthenticatedWorkspace()` | Supabase Auth plus `cefflo_auth_session` local storage | YES | Shared client session/login | ACTIVE | Buttons bind directly to inline functions; adapter does not replace them | Two auth clients share one stored session; refresh/error semantics can diverge | Retain as current owner until one auth facade is approved and tested | YES |
| Shared session bridge | Shared script load and inline `storeAuthSession()` | `shared/client.js` | `storeAuthSession()` → optional `CEFFLO.setSession()`; adapter also imports the same local session on load | In-memory session plus `cefflo_auth_session` | YES | Inline `productionState.authSession` | CANONICAL-CANDIDATE | Shared client is loaded by every surface and consumed by adapters | Parallel memory owners may drift during refresh/logout timing | Make shared session/auth facade the eventual owner; preserve inline UI orchestration only | YES |
| Inline REST repository | Inline engine initialization and functions using `BackendRepository` | `vendor/index.html` | `backendRequest()` → PostgREST; repository supports select/upsert/delete | Inline state and Supabase tables | YES | `vendor/backend.js` plus shared client | LEGACY-CANDIDATE | Adapter later rebinds hydrate/sync; direct repository calls remain for inline auth RPC, audit/GPS helpers | Parallel generic writes can bypass canonical RPC/business rules; some referenced tables are absent from migration | Trace remaining direct consumers, then retire generic business-data sync in favor of explicit protected operations | YES |
| Shared REST/RPC client | Adapter load | `shared/client.js` | `CEFFLO.request/rpc` → Supabase REST/Auth | Shared session and shared config | YES | Inline `backendRequest/authRequest` | CANONICAL-CANDIDATE | All three adapters call this client | Error/session behavior is basic and coexists with embedded clients | Adopt as sole low-level browser transport after auth convergence | YES |
| Adapter remote hydration | Login/restore and adapter restore timers | `vendor/backend.js` | `hydrateAuthenticatedWorkspace()` → `CEFFLO_VENDOR.hydrate()` → `get_my_businesses` + orders/riders/ratings queries → state mapping | Supabase rows | YES | Inline `hydrateOperationalStateFromBackend()` | ACTIVE | `vendor/backend.js` reassigns the global hydrate function and exports `CEFFLO_VENDOR.hydrate` | Hydrates only orders/riders/ratings and then erases other operational arrays | Retain as current remote owner; expand only in later implementation sprint after contracts are approved | YES |
| Inline full-state hydration | Realtime callback or fallback when adapter is unavailable | `vendor/index.html` | `startRealtime()` callback → global `hydrateOperationalStateFromBackend()` | Generic table queries | UNKNOWN | Adapter hydration | LEGACY-CANDIDATE | Adapter rebinds the global name; fallback branch exists in `hydrateAuthenticatedWorkspace()` | Timing/failure can select different record shapes | Remove fallback only after adapter availability and startup ordering are proven | YES |
| Inline full-state sync/offline queue | Any inline engine transaction → `persistOperationalStore()` → queued sync; online/flush events | `vendor/index.html` | local mutation → `queueBackendSync()` / `flushOfflineQueue()` → global sync | Full local state, including sessions/zones/issues/history | YES, but adapter later makes sync a successful no-op | Adapter RPC mutations | PROTOTYPE-EMBEDDED | Adapter assigns `syncOperationalStateToBackend = async () => true`; queue calls resolve without remote writes | UI can claim/presume persistence while only local storage changed; queued work can be discarded as successful | Disable only after each reachable mutation has a canonical server path and explicit failure UX | YES |
| Order list | Hydration after authenticated login/restore | `vendor/backend.js` | adapter `listOrders()` → REST orders → `mapOrder()` → `state.orders` | Supabase `orders` | YES | Inline/local restored orders | ACTIVE | Remote hydrate overwrites `state.orders` | Before successful hydrate, locally restored/demo state may exist; row-shape compatibility varies | Keep adapter as owner; gate authenticated UI on verified hydrate in later implementation | NO |
| Manual order creation | Order wizard final action | `vendor/backend.js` | delegated `ACTIONS.wizSubmit` → adapter `create_delivery` RPC → token storage → rehydrate | Supabase RPC plus browser token storage | YES | Inline `wizSubmit()` local random order | CANONICAL-CANDIDATE | Adapter replaces both global function and captured `ACTIONS` reference | Canonical RPC path is active, but cleartext tracking token persists only locally | Preserve adapter/RPC owner; remove local creator only after regression proof | YES |
| CSV/import order creation | Import UI actions | `vendor/index.html` | delegated inline handlers → local `state.orders` → `persistOperationalStore()` | Parsed client data and local storage | YES | Adapter/RPC manual create | PROTOTYPE-EMBEDDED | Adapter replaces only `wizSubmit`; CSV handlers remain in `ACTIONS` | Imported orders may appear in UI without server persistence | Block or replace in a later approved sprint; do not silently retain for production | YES |
| Single-order rider assignment | Order detail sheet | `vendor/backend.js` | `ACTIONS.confirmAssignRiderOrder` → `assign_rider` RPC → rehydrate | Supabase RPC | YES | Inline direct order mutation | CANONICAL-CANDIDATE | Adapter replaces captured `ACTIONS` reference | RPC creates assignment per order; may not satisfy planned batch/session model | Keep as current protected owner pending lifecycle design | YES |
| Zone/session assignment | Dispatch planner/profile actions | Inline engine in `vendor/index.html` | `ACTIONS.assignZoneRider` → ensure local session → engine assignment → local persistence/no-op sync | Local arrays | YES | `assign_rider` RPC and schema assignments | PROTOTYPE-EMBEDDED | Action was rebound to engine command before adapter; adapter does not replace it | Produces assignments/stops not persisted to canonical backend | Do not expose as authoritative until backed by approved RPC/model | YES |
| Sessions and stops | Dispatch/pickup/delivery engine actions and selectors | Inline engine in `vendor/index.html` | UI → `CEFFLO_ENGINE.commands` → local transaction → local persistence | `state.deliverySessions`, `state.deliveryStops` | YES | Migration tables, but no active adapter owner | PROTOTYPE-EMBEDDED | Engine commands are registered and UI actions call them; adapter clears arrays on hydrate | Active UI can operate on empty/local-only records that disagree with backend | Preserve for UX reference; later bind to canonical backend or explicitly remove from Stage 4 scope | YES |
| Zones | Address derivation, dispatch planner, assignment/profile actions | Inline engine | UI/engine → derive/create/update `state.zones` | Local arrays; no `zones` table in tracked migration | YES | None in canonical backend | PROTOTYPE-EMBEDDED | Direct calls and selectors remain; adapter sets zones to `[]` on hydrate | Zone behavior is authoritative only in one browser session | Founder define Stage 4 zone contract before implementation | YES |
| Issues and status history | Vendor issue/reschedule/delivery actions | Inline handlers and engine | delegated actions → local state transitions/issues/history → local persistence | Local arrays; no `issues` or `order_status_history` table in migration | YES | Backend enum/events but no matching issue RPC | PROTOTYPE-EMBEDDED | Actions remain in `ACTIONS`; adapter does not replace them | Local status can contradict server lifecycle | Later replace with protected lifecycle/exception operations | YES |
| Rider invite/profile/business profile | Rider/settings actions | Inline engine and local storage | UI → inline commands → local arrays/profile keys → no-op sync | Local storage and memory | YES | Supabase riders/businesses schema | PROTOTYPE-EMBEDDED | Adapter does not replace these actions | UI success may not persist remotely; sensitive profile fields remain local | Require explicit RPC-backed ownership before production claim | YES |
| Realtime | `initializeProductionIntegration()`, auth hydrate, online event | Inline dynamic Supabase client | `startRealtime()` → CDN Supabase client → table channels → global hydrate | Supabase Realtime | YES | `vendor/backend.js.subscribe()` | ACTIVE | Inline initializer and events call it when CDN/config succeeds; adapter `subscribe()` has no consumer | Dynamic CDN dependency; callback uses whichever global hydrate currently owns | Keep inline realtime temporarily; consolidate under shared/adaptor owner later | YES |
| Adapter `subscribe()` | Export only | `vendor/backend.js` | No call site found | Supabase Realtime | NO | Inline realtime | DEAD | Repository-wide reference search found definition/export only | Dead parallel implementation obscures owner | Safe-cleanup candidate after Founder confirms inline realtime remains temporary owner | YES |
| Tracking-token persistence and link opening | Successful create and order action | `vendor/backend.js` | `create_delivery` result → `localStorage[cefflo_tracking_token_<uuid>]` → hydrate map → `ACTIONS.openCustomerTracking` | Cleartext token in one browser profile | YES | No recoverable vendor backend endpoint | ACTIVE | Adapter stores/reads token and opens query-string link | Existing order links are unavailable on another browser or after storage loss | Design protected recovery/rotation path; do not store token in order-list payload | YES |
| Inline storage upload | Exposed production engine API | `vendor/index.html` | `CEFFLO_ENGINE.production.storage.upload()` → direct storage request | Bucket captured as `cefflo-assets` before shared config loads | UNKNOWN | Shared `uploadPod()` uses `cefflo-pod` | LEGACY-CANDIDATE | Inline config is evaluated before `shared/config.js`; no direct UI call found | Conflicting bucket ownership and possible public-URL construction | Remove or repurpose only after consumer and bucket contract review | YES |

## 4. Rider reachability register

| Implementation path | Entry point | Owner | Call / reachability chain | State / data source | Production-reachable? | Competing path | Classification | Evidence | Risk | Recommended eventual treatment | Founder decision? |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Adapter login and approval check | Login button | `rider/backend.js` via shared client | global `doLogin()` → shared `login()` → `/auth/v1/user` → active rider query → remote hydrate | Supabase Auth, riders and orders | YES | Inline `doLogin()` | CANONICAL-CANDIDATE | Adapter loads last and reassigns global `doLogin`; inline onclick resolves current global | Phone provider readiness remains unknown; wrapper tutorial behavior is superseded | Preserve adapter/shared owner; later add explicit provider/error validation | YES |
| Inline login and tutorial wrapper | Earlier global definitions | `rider/index.html` | Superseded by later adapter assignment | Would call `CEFFLO_AUTH.login` | NO after adapter load | Adapter login | DEAD | Adapter reassigns `doLogin` after all inline wrappers | Dead wrapper makes intended first-login tutorial unreliable | Remove only with regression coverage and an approved tutorial decision | YES |
| Mock signup/OTP/application | Apply-now/signup buttons | `rider/index.html` | DOM onclick → mock OTP `123456` → `doSignUp()` → local rider record → pending screen | Browser files and local storage only | YES | No backend signup/application path | PROTOTYPE-EMBEDDED | Direct DOM handlers remain; adapter does not replace signup | Users can receive false application/verification success; sensitive images are not submitted | Must be blocked or implemented before production use | YES |
| Mock password recovery | Forgot/reset screens | `rider/index.html` | inline handlers → mock code `123456` → local success screen | Browser-only state | YES | Supabase Auth recovery absent | PROTOTYPE-EMBEDDED | Direct DOM handlers remain after adapter load | False security-sensitive success | Must be blocked or replaced by approved Auth recovery | YES |
| Logout | Profile confirmation | `rider/index.html` | `doLogout()` removes `cefflo_session` flag and shows login | Local UI flag only | YES | Shared `api.logout()` | PROTOTYPE-EMBEDDED | Adapter does not replace `doLogout` | Supabase access token remains in `cefflo_rider_auth_session`; restore adapter can reopen session | Replace with shared logout and state cleanup | YES |
| Startup local recovery | 1700 ms timer | `rider/index.html` | stored local profile + `cefflo_session` → show home with current `appState` | Local profile/session flag and initial mock orders | YES | Adapter restore at 1800 ms | PROTOTYPE-EMBEDDED | Inline timer executes before adapter restore timer | Mock orders/home can flash as authenticated; failure timing can misrepresent state | Gate home on verified shared session/hydration | YES |
| Remote order hydration | Successful login and adapter restore | `rider/backend.js` | `orders()` → REST orders ordered by sequence → map → replace `appState.orders` | Supabase orders under RLS | YES | Initial `mockOrders` | ACTIVE | Called on login and delayed restore | Query does not explicitly filter assignment; relies on RLS and does not hydrate assignment metadata/stops | Keep as current data owner; later use explicit assignment/read model | YES |
| Adapter assignments fetch | Export only | `rider/backend.js` | No call site found | Intended `rider_assignments` plus embedded orders | NO | Direct orders fetch | DEAD | Repository search found definition/export only | `activeAssignment` retains seeded metadata rather than backend assignment truth | Replace with an approved assignment read model, then remove unused export | YES |
| Initial `mockOrders` | Page evaluation | `rider/index.html` | constant → `appState.orders` before any auth/hydrate | Seeded browser data | YES until remote hydrate; reachable again on session completion | Remote order hydrate | PROTOTYPE-EMBEDDED | Direct initialization and `yesCompleteSession()` reset | Demo customer/order data can appear as real work | Remove from production path after fixture strategy is approved | YES |
| Session completion reset | “Yes, Complete” modal | `rider/index.html` | `yesCompleteSession()` → replace orders with `mockOrders` → home | Seeded browser data | YES | Remote order hydrate | PROTOTYPE-EMBEDDED | Direct DOM onclick; adapter does not replace it | Completed remote route is immediately replaced with demo route | Replace with rehydrate/empty completed state | YES |
| Assignment header/details | Home render | `rider/index.html` plus partial adapter update | seeded `activeAssignment`; adapter changes only `zone` based on order count | Mixed seeded metadata and remote order count | YES | Unused assignments endpoint | PROTOTYPE-EMBEDDED | Vendor/session/window/distance values remain hard-coded | Remote jobs display fictional assignment metadata | Replace with canonical assignment/session read model | YES |
| Route/stops display | Pickup/start/route screens | Inline UI over adapter orders | remote `appState.orders` → local index/sequence → map/navigation | Orders only; default coordinates if null | YES | Backend delivery stops/assignments not queried | ACTIVE | Adapter sets order sequence and current index; inline renderers consume them | “Stops” are projected from orders; coordinates default to Kuala Lumpur values | Keep UI shell; later hydrate explicit stop/route contract | YES |
| Lifecycle mutation | Pickup/start/arrival buttons | `rider/backend.js` | rebound globals → `rider_transition` RPC with idempotency key | Supabase order lifecycle | YES | Inline local status mutations | CANONICAL-CANDIDATE | Adapter replaces all four happy-path handlers | Only happy path is protected; UI exceptions remain local | Preserve RPC owner; extend only through approved lifecycle contract | YES |
| POD capture and completion | Camera input and confirmation | Inline preview + `rider/backend.js` | file input → rebound selection stores file + inline data URL preview → shared upload → `complete_delivery` RPC | Local `File`, private bucket, RPC | YES | Inline local-only completion | CANONICAL-CANDIDATE | Adapter wraps photo handler and replaces `yesUsePhoto` | Preview data URL remains memory-only as expected; retry/resume across reload absent | Keep shared upload + completion RPC as owner; add recoverable UX later | YES |
| Exception behavior | Issue sheet/actions | `rider/index.html` | direct handlers mutate current order and `appState.issues`, then show success | In-memory only | YES | Backend `issue` enum without exception RPC | PROTOTYPE-EMBEDDED | Adapter does not replace any issue handler | Claims vendor notification/approval without remote mutation | Block false claims or implement protected exception commands later | YES |
| Availability | Profile toggle | `rider/index.html` | local-storage flag → UI label; no backend write or GPS controller | `cefflo_rider_online` local storage | YES | Rider schema availability field | PROTOTYPE-EMBEDDED | Direct handler remains; adapter has no availability operation | Vendor/backend never receives availability truth | Define authoritative availability/GPS contract before implementation | YES |
| Profile edits/photo/preferences | Profile controls | `rider/index.html` | local mutations and data-URL/local-storage writes | Browser local storage | YES | Supabase rider/profile rows | PROTOTYPE-EMBEDDED | Direct controls remain; adapter only hydrates name/phone/plate at login | UI success is not server truth; photo can consume local storage | Decide read-only versus editable Stage 4 scope; then bind or remove | YES |
| `cefflo_rider_orders` cache | Adapter hydrate | `rider/backend.js` | raw remote rows saved to local storage | Browser local storage | YES write; NO read consumer found | `appState.orders` | LEGACY-CANDIDATE | Search found write only | Stores customer/order PII without operational benefit | Remove after confirming no external consumer and privacy requirements | YES |

## 5. Customer Tracking reachability register

| Implementation path | Entry point | Owner | Call / reachability chain | State / data source | Production-reachable? | Competing path | Classification | Evidence | Risk | Recommended eventual treatment | Founder decision? |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Seeded tracking render and `?status=` override | Inline page evaluation | `customer/index.html` | seeded `TRACKING_DATA` → `renderTracking()` before adapter loads | Hard-coded order/customer/rider/status | YES | Backend refresh | PROTOTYPE-EMBEDDED | Inline script always renders; query `status` can select state | Missing/invalid/slow backend can expose fictional delivery data | Replace with neutral loading/error state; keep fixtures outside production path | YES |
| Backend tracking refresh | Window load and 15-second timer | `customer/backend.js` via shared client | query token → `public_tracking` RPC → status map → `CEFFLOTracking.setStatus` | Tokenized Supabase RPC | YES | Seeded state | CANONICAL-CANDIDATE | Adapter installs load listener and polling timer | Poll failures after first load are silently ignored; stale UI persists | Keep adapter/shared RPC as owner; add explicit stale/error handling later | YES |
| Token handling | Adapter evaluation | `customer/backend.js` | `URLSearchParams(location.search).get('token')` → RPC and Edge Function body | Cleartext query token held in closure | YES | `?status=` demo query | ACTIVE | Direct source trace | URL token can leak through browser/history/referrer controls; entropy/expiry are backend concerns | Retain current transport pending security review; remove demo query from production path | YES |
| Demo POD fallback | Delivered render | `customer/index.html` | adapter signed-POD request failure → `podPhoto: null` → `TRACKING_DATA.podPhoto || DEFAULT_POD_PHOTO` | Embedded SVG demo | YES | Signed Edge Function URL | PROTOTYPE-EMBEDDED | Adapter catches `podUrl()` failure to null; renderer always substitutes demo | Customers can see fabricated proof of delivery | Remove fallback from production path; show explicit unavailable/pending state | YES |
| Signed POD access | Delivered refresh | `customer/backend.js` | tracking RPC says delivered/path → `tracking-pod` function → signed URL | Edge Function and private bucket | YES | Demo fallback | CANONICAL-CANDIDATE | Direct adapter call | CORS/rate limiting/deployment state unverified; failures hidden by demo | Preserve as sole POD data owner and expose recoverable error | YES |
| Rating UI submit | Rating button | `customer/index.html` | save local payload → immediately hide form/show thanks → dispatch custom event | Browser local storage | YES | Adapter `submit_rating` RPC | PROTOTYPE-EMBEDDED | UI confirms before listener promise resolves | False success on network/server rejection | Move success state after confirmed RPC; retain pending/retry state | YES |
| Rating persistence | Custom event listener | `customer/backend.js` | `cefflo:delivery-rated` → `submit_rating` RPC → rejection logged only | Tokenized Supabase RPC | YES | Local rating record | ACTIVE | Listener is installed after inline UI | No result is returned to initiating UI | Make adapter/RPC the canonical owner and return explicit outcome to UI | YES |
| Rating restore | Delivered render | `customer/index.html` and adapter | local key can hide form; server `rating_submitted=true` also hides form | Mixed browser and server truth | YES | Server snapshot | PROTOTYPE-EMBEDDED | Local restore executes whenever delivered; server false does not clear it | Local stale record can override server truth | Server snapshot must own submitted state; local storage may be pending cache only | YES |

## 6. Shared/backend and asset reachability

| Implementation path | Entry point | Owner | Call / reachability chain | State / data source | Production-reachable? | Competing path | Classification | Evidence | Risk | Recommended eventual treatment | Founder decision? |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Shared browser transport | Script import in all three clients | `shared/client.js` | surface adapter → `CEFFLO.request/rpc/login/uploadPod` | Shared config and per-surface session key | YES | Vendor embedded transport | CANONICAL-CANDIDATE | Imported before every adapter; all adapters dereference `window.CEFFLO` | Lacks token refresh coordination and structured error typing | Standardize as sole transport after Vendor auth migration | YES |
| Vendor embedded auth/REST client | Inline page | `vendor/index.html` | auth UI and engine → inline fetch helpers | Inline captured config/session | YES | Shared client | ACTIVE | Auth buttons call inline functions directly | Duplicate session/network owners and different bucket/config capture | Retain only UI orchestration; migrate transport ownership to shared layer | YES |
| Vendor dynamic Supabase client | Inline realtime initializer | `vendor/index.html` | inject CDN script → create client → subscribe | Inline runtime config | YES | Adapter dead `subscribe()` | ACTIVE | Called by initializer/login/online event when CDN loads | Third client mechanism and runtime CDN dependency | Consolidate realtime under one shared/adaptor module later | YES |
| Adapter backend paths | Surface script imports | `vendor/backend.js`, `rider/backend.js`, `customer/backend.js` | current global handlers → shared client → RPC/REST/storage/function | Supabase | YES | Inline/local fallbacks | CANONICAL-CANDIDATE | Explicit final script order and global rebindings | Partial handler coverage leaves mixed truth | Adopt adapters as surface orchestration owners, with complete contracts before cleanup | YES |
| `scripts/pwa-icon.svg` | None found | Build/design | No import, build copy, manifest reference, HTML reference, or script consumer | Tracked SVG only | NO | Six active PNG PWA icons | DEAD | Repository-wide search plus build/manifest inspection; introduced with PWA launch commit | Deleting may discard manual source provenance even though runtime does not use it | Keep until Founder identifies it as source asset or approves archival/removal | YES |

## 7. Production-reachable prototype/mock paths

1. Vendor CSV import, sessions/stops, zone assignment, issues/history, rider
   invite/profile and business-profile mutations can report success while only
   changing local state.
2. Vendor offline/full-state sync remains callable but is rebound by the adapter
   to a successful no-op, allowing local operations or queued work to appear synced.
3. Rider signup uses mock OTP `123456` and stores an application locally.
4. Rider password recovery is simulated locally.
5. Rider logout does not terminate the shared Supabase session.
6. Rider startup can show mock orders from local-session recovery before remote
   validation, and session completion deliberately restores `mockOrders`.
7. Rider assignment metadata, availability, profile editing and all exception
   actions remain local simulations.
8. Customer Tracking always renders seeded order data before remote refresh;
   `?status=` can directly select a demo state.
9. Customer delivered view substitutes a fabricated POD image whenever the signed
   POD is missing or retrieval fails.
10. Customer rating UI confirms locally before the backend mutation succeeds and
    can restore that local success against server truth.

## 8. Dead and legacy candidates

- **DEAD:** `vendor/backend.js` `subscribe()` export; no call site.
- **DEAD:** `rider/backend.js` `assignments()` export; no call site.
- **DEAD:** the superseded inline Rider login and first-login tutorial wrapper
  after `rider/backend.js` reassigns global `doLogin`.
- **DEAD:** `scripts/pwa-icon.svg` in the current build/runtime graph; provenance
  remains a Founder question.
- **LEGACY-CANDIDATE:** Vendor generic full-state repository/hydration/sync once
  explicit adapter/RPC ownership is complete.
- **LEGACY-CANDIDATE:** Vendor inline storage upload using the early-captured
  `cefflo-assets` bucket; no direct UI consumer found.
- **LEGACY-CANDIDATE:** `cefflo_rider_orders`; written after hydration but never
  read by tracked code.

No cleanup is authorized or performed.

## 9. Canonical Ownership Recommendation

| Contract | Proposed single owner | Supporting UI owner | Paths to retire or constrain eventually |
|---|---|---|---|
| Vendor auth | Shared auth/session facade in `shared/client.js` | Vendor auth UI in `vendor/index.html` | Inline transport/session implementation after equivalent recovery/refresh behavior exists |
| Vendor data access | `vendor/backend.js` using `shared/client.js` and protected RPC/read models | Vendor selectors/renderers | Generic full-state repository and local-success mutation paths |
| Rider auth | `rider/backend.js` using shared auth/session | Rider auth UI | Mock signup/reset/logout and superseded inline login |
| Rider data access | `rider/backend.js` using explicit assignment/order/stop read models | Rider route/profile renderers | Seeded assignment truth, mock orders and write-only order cache |
| Customer tracking data access | `customer/backend.js` using tokenized RPC/Edge Function through shared transport | `CEFFLOTracking` renderer | Seeded/demo runtime data and silent polling failure behavior |
| Lifecycle mutation | Supabase protected RPCs defined by the canonical backend contract | Vendor/Rider adapters | Direct local status/issue/session mutations presented as persisted truth |
| POD | Rider adapter + shared protected upload + `complete_delivery`; Customer adapter + signed Edge Function read | Rider capture and Customer display UI | Local-only completion and demo POD fallback |
| Tracking-token recovery | New protected backend recovery/rotation contract exposed through Vendor adapter | Vendor tracking-link action | Browser-only cleartext token as the sole recoverability mechanism |

These are recommendations, not implementation authorization.

## 10. Safe Cleanup Queue — perform none in P1.2

1. Add reachability/regression coverage before removing any global override.
2. Remove dead adapter exports only after confirming no external HTML/runtime consumer.
3. Move demo fixtures out of production entry paths before deleting fixture data.
4. Replace false-success local mutations with disabled/unavailable states or
   protected backend operations before removing their UI code.
5. Consolidate Vendor transport/auth/realtime only after session recovery,
   realtime refresh, error, and logout parity is proven.
6. Remove the Rider local startup gate and mock reset only after remote loading,
   empty, failure, and completed-session states are implemented.
7. Remove Customer demo POD/rating truth only alongside explicit unavailable,
   pending, retry, and confirmed-success states.
8. Remove `cefflo_rider_orders` only after privacy review and external-consumer check.
9. Archive or delete `scripts/pwa-icon.svg` only after Founder confirms provenance.

## 11. New P1.2 findings

- Vendor's inline runtime config captures `storageBucket: "cefflo-assets"` before
  `shared/config.js` replaces `window.CEFFLO_CONFIG` with `cefflo-pod`; two upload
  contracts therefore coexist.
- Adapter hydration makes Vendor full-state sync a successful no-op, so local
  engine writes can appear completed without a server mutation.
- Vendor inline generic sync references `zones`, `issues`, `order_status_history`
  and `audit_logs`, none of which exist in the single tracked migration.
- Rider logout leaves the shared access token intact, enabling delayed adapter
  restoration unless the remote session is independently invalidated.
- Rider session completion explicitly reinstates mock orders after a remote flow.
- Rider's exported assignment fetch is unused; the visible assignment card retains
  seeded vendor/session/time/distance metadata.
- Customer's demo POD is not merely initial placeholder content: adapter failure
  deliberately falls through to it in delivered state.
- Customer invalid/missing-token handling changes the hero label only; other seeded
  customer/order content can remain visible.

## 12. Founder decisions required before cleanup

1. Approve the ownership recommendations in Section 9 or specify alternatives.
2. Decide whether production clients may ever show demo/local fallback data; if
   yes, define an explicit visibly labelled demo/degraded mode.
3. Approve blocking mock Rider signup/recovery and local Vendor/Rider mutation
   paths until canonical backend operations exist.
4. Confirm whether Vendor sessions/zones/batching/issues are required Stage 4
   contracts and whether their current UI should be preserved as design evidence.
5. Approve shared-client ownership of auth/session/transport and eventual removal
   of Vendor's embedded competing transport.
6. Approve the tracking-token recovery requirement and desired security model.
7. Confirm `scripts/pwa-icon.svg` provenance and retention/archive decision.
8. Approve removal of fabricated Customer POD fallback and local-first rating
   success once replacement error/pending UX is specified.
9. Approve privacy cleanup of write-only local caches and stored customer/rider
   data after required behavior is verified.

## 13. P1.2 boundary

This sprint classifies static reachability only. It makes no production-state
claim, changes no application/configuration/backend behavior, performs no cleanup,
and does not begin P1.3.
