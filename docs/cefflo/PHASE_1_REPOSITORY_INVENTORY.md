# CEFFLO — Phase 1 Repository Inventory and Classification Register

Status: P1.1 repository evidence only

Baseline inspected: `main` at `11d2f415398fabcdd9d5a0f86fb296763dabd802`

Scope: tracked repository artifacts and explicitly required missing surfaces
Not established here: live deployment, production database, DNS, provider, or runtime state

## 1. Authority and evidence boundary

This register implements R1.1 from `03_ROADMAP.md`. It is subordinate to
`00_AGENTS.md` and does not change the requirements in `01_PRODUCT.md` through
`17_AI_WORKFLOW.md`.

Evidence marked **high** was read directly from a tracked path or Git metadata.
Evidence marked **medium** is a structural inference from tracked wiring but has
not been exercised against a runtime. **Unknown** means the repository cannot
prove the external or production fact. No production system was accessed.

Classification describes repository state, not Stage 4 readiness:

- **CANONICAL** — repository source of truth or canonical instruction/contract.
- **ACTIVE** — wired into the tracked application/build, without implying live verification.
- **PROTOTYPE-EMBEDDED** — mock, local-only, demo, or prototype behavior inside an active artifact.
- **LEGACY-CANDIDATE** — potentially obsolete artifact requiring P1.2 evidence.
- **DUPLICATE** — confirmed parallel implementation of the same owned behavior.
- **GENERATED** — derived output, not primary source.
- **CONFIG** — tracked build, runtime, hosting, environment, or repository configuration.
- **TEST** — validation code; presence does not mean it has passed.
- **MISSING** — required or planned surface has no tracked implementation.
- **UNKNOWN** — external/runtime ownership or state cannot be established from this repository.

## 2. Inventory register

| Path / component | Owner / surface | Purpose | Current implementation evidence | Dependency | Classification | Confidence / evidence | Action recommendation | Founder decision required? |
|---|---|---|---|---|---|---|---|---|
| `AGENTS.md` | Codex / repository | Root instruction discovery | Routes only to `docs/cefflo/00_AGENTS.md` | Canonical context pack | CANONICAL | High: tracked file inspected | Preserve minimal router | No |
| `docs/cefflo/00_AGENTS.md`–`17_AI_WORKFLOW.md`, `README_PACK.md` | Product / engineering governance | Canonical modular requirements and routing | Nineteen pack files tracked; numbered sequence `00`–`17` plus pack README | Git `main` | CANONICAL | High: tracked files and prior byte validation | Do not rewrite to match implementation; update living state only from evidence | Founder approves phase gates and protected decisions |
| `README.md` | Repository | Repository usage, backend and hosting overview | Names Vendor, Rider, Tracking, shared backend, tests, Vercel host mapping, billing deferral | Current tree and external runtime claims | CANONICAL | Medium: tracked overview; runtime statements not independently verified | Reconcile factual runtime claims during P1.3–P1.5 | If changing product/deployment commitments |
| `.gitignore` | Repository | Excludes environment files, build output, dependencies, coverage, logs | Ignores `.env`, `dist/`, `node_modules/`, `coverage/`, logs while retaining `.env.example` | Git | CONFIG | High: tracked rules inspected | Preserve; verify no required audit evidence is hidden locally before baseline lock | No |
| `.env.example` | Backend / local validation | Documents `SUPABASE_URL`, publishable key and `DATABASE_URL` inputs | Placeholder values only; no production secret tracked here | Supabase and database tests | CONFIG | High: tracked file inspected | Keep secret-free; map actual environment ownership read-only in P1.3/P1.5 | Yes for secret/provider changes, not inventory |
| `.openai/hosting.json` | Static hosting | Identifies hosting project | Contains project ID `appgprj_6a7dfb5970888191b3b8989054705da0` | Static build/hosting platform | CONFIG | High for file; unknown for live ownership | Verify project/source/deployment relationship in P1.3 | Yes for production hosting changes |
| `package.json` | Build | Defines private static frontend package and build command | Only `npm run build` → `node scripts/build-static.mjs`; no declared dependencies or test scripts | Node.js | CONFIG | High: tracked manifest inspected | Preserve minimal build; document validation gaps | No |
| `scripts/build-static.mjs` | Build | Recreates `dist/`, copies four source directories, writes root redirect and hosting worker | Copies `vendor/`, `rider/`, `customer/`, `shared/`; creates `dist/server/index.js` and hosting metadata | Node.js, source directories, `.openai/hosting.json` | ACTIVE | High: source inspected; build not run in P1.1 | Exercise only in isolated/approved validation during later sprint | No unless deployment behavior changes |
| `scripts/pwa-icon.svg` | Build/design asset | Source-style CEFFLO icon asset | Tracked SVG; not referenced by current build script or manifests | Manual/icon generation workflow unknown | LEGACY-CANDIDATE | Medium: no tracked reference found | P1.2 determine whether it is canonical icon source or unused residue; do not delete | Yes if retiring or replacing brand asset |
| `dist/` (ignored, absent from Git) | Build output | Deployable static output | Build script generates it; `.gitignore` excludes it | `scripts/build-static.mjs` | GENERATED | High: build and ignore rules inspected | Never classify as code SOT; regenerate from known commit | No |
| `vercel.json` | Vercel / routing | Static build, output directory, hostname rewrites, service-worker/manifest headers | Maps `vendor.cefflo.com`, `rider.cefflo.com`, and `track.cefflo.com`; no marketing or FOUNDR mapping | Vercel, build output, DNS | CONFIG | High for repository intent; unknown live state | P1.3 verify project, domains, deployment commit, environment, headers and rollback | Yes for production/domain/environment changes |
| `shared/config.js` | Shared frontend / Supabase | Browser runtime endpoint, publishable key, schema and POD bucket | Defines project `lmaxtrubwdniovxyuqdy`, public key, `public` schema, `cefflo-pod` bucket; loaded by all three clients | Supabase project | CONFIG | High for tracked values; unknown live validity | P1.3/P1.5 verify environment separation and intended project; do not place secrets here | Yes for production endpoint/key changes |
| `shared/client.js` | Shared frontend / Supabase | REST/RPC/auth/session/POD upload client | Exposes `CEFFLO`; uses no-store requests, browser local-storage sessions and authenticated storage upload | `shared/config.js`, Supabase Auth/REST/Storage | ACTIVE | High: loaded by all clients; runtime untested | Preserve as shared contract; audit session/error/storage behavior in P1.4/P1.5 | Yes for material auth/security changes |
| `vendor/index.html` — application shell and production wiring | Vendor | Mobile operational UI, auth/onboarding, dashboard, orders, riders, delivery and settings flows | Loads manifest, shared config/client and `vendor/backend.js`; registers Vendor service worker; also contains inline Supabase production functions | Shared client/config, backend adapter, Supabase, PWA assets | ACTIVE | High for wiring; medium for functional behavior | Treat as current repository baseline; do not redesign or rebuild wholesale | Founder decision only for scope/architecture changes |
| `vendor/index.html` — local/prototype paths | Vendor | Demo/local persistence, offline queue, account/profile/settings and prototype operations | Contains extensive `localStorage` operational state, local password/profile data, prototype deletion copy and inline persistence paths | Same active HTML and adapter override order | PROTOTYPE-EMBEDDED | High: direct code evidence | P1.2 map every reachable handler and decide canonical owner before deactivation | Yes where behavior removal changes approved UX/data flow |
| `vendor/index.html` — inline Supabase layer | Vendor / backend integration | Auth, REST, Realtime and storage helpers embedded in HTML | Inline production functions overlap partly with `shared/client.js` and `vendor/backend.js` responsibilities | Supabase and script load order | PROTOTYPE-EMBEDDED | High for overlap; duplicate ownership not yet proven | P1.2 trace call graph and designate one owner; do not label confirmed duplicate yet | Yes if consolidation changes auth/data architecture |
| `vendor/backend.js` | Vendor / backend adapter | Hydrates businesses/orders/riders/ratings; creates deliveries; assigns riders; subscribes to orders | Loaded last; replaces selected UI handlers and hydration functions; clears several local operational arrays after remote hydrate | Shared client, migration RPCs/tables, inline globals in Vendor HTML | ACTIVE | High for wiring; runtime untested | P1.2 enumerate overridden versus still-local handlers; preserve until ownership is proven | Founder decision if retiring parallel paths |
| `vendor/manifest.webmanifest` | Vendor PWA | Install metadata and icons | Name, start URL, scope, standalone display and three icon entries | Vendor icons, Vercel rewrites | CONFIG | High: JSON parsed | Later test installability and custom-domain scope | No unless product identity changes |
| `vendor/sw.js` | Vendor PWA | Static shell caching and network-first navigation | Cache `cefflo-vendor-shell-v1`; caches shell only; ignores cross-origin/API requests | Vendor shell, shared assets, Vercel headers | ACTIVE | High: syntax checked; browser behavior untested | P1.3/P1.5 verify install/update/offline and rollback behavior | Yes for production cache/release changes if material |
| `vendor/icons/icon-192.png`, `icon-512.png`, `icon-maskable-512.png` | Vendor PWA | Install icons | All three files tracked and referenced by manifest; two cached by service worker | Vendor manifest/service worker | ACTIVE | High: path references inspected | Preserve; validate dimensions/maskability visually later | No |
| `rider/index.html` — application shell and production wiring | Rider | Auth, onboarding, assigned work, pickup, route/stops, POD, history/profile UI | Loads shared config/client and `rider/backend.js`; registers Rider service worker; includes 23 named screens/modals/sheets | Shared client/config, backend adapter, Leaflet CDN, Supabase, PWA assets | ACTIVE | High for wiring; medium for functional behavior | Treat as current repository baseline; do not rebuild wholesale | Founder decision only for scope/architecture changes |
| `rider/index.html` — mock/local paths | Rider | Initial demo orders, local session/profile/preferences, issue and availability simulations | Defines `mockOrders`; initializes application state from them; includes reset-to-mock and extensive `localStorage` behavior | Adapter hydration and global handler replacement | PROTOTYPE-EMBEDDED | High: direct code evidence | P1.2 prove reachability before removing or retaining any path | Yes where removal changes approved UX/offline behavior |
| `rider/backend.js` | Rider / backend adapter | Authenticates approved rider, hydrates assigned orders, performs transitions and POD completion | Loaded last; replaces login/pickup/start/arrival/POD handlers; calls migration RPCs and storage upload | Shared client, Supabase Auth/REST/Storage, inline Rider globals | ACTIVE | High for wiring; runtime untested | P1.2 map adapter coverage and exception paths; preserve current baseline | Founder decision if lifecycle/auth contracts change |
| `rider/manifest.webmanifest` | Rider PWA | Install metadata and icons | Name, start URL, scope, standalone display and three icon entries | Rider icons, Vercel rewrites | CONFIG | High: JSON parsed | Later test installability and custom-domain scope | No unless product identity changes |
| `rider/sw.js` | Rider PWA | Static shell caching and network-first navigation | Cache `cefflo-rider-shell-v1`; same strategy shape as Vendor with Rider cache namespace | Rider shell, shared assets, Vercel headers | ACTIVE | High: syntax checked; browser behavior untested | P1.3/P1.5 verify install/update/offline and rollback behavior | Yes for production cache/release changes if material |
| `rider/icons/icon-192.png`, `icon-512.png`, `icon-maskable-512.png` | Rider PWA | Install icons | All three files tracked and referenced by manifest; two cached by service worker | Rider manifest/service worker | ACTIVE | High: path references inspected | Preserve; validate dimensions/maskability visually later | No |
| `customer/index.html` — tracking UI | Customer Tracking | Public status/progress, POD and rating experience | Loads shared config/client and `customer/backend.js`; renders simplified tracking states and rating UI | Tracking token, backend adapter, Supabase RPC/Function | ACTIVE | High for wiring; runtime untested | Preserve current UI baseline and verify token/error/rating states later | No unless customer contract changes |
| `customer/index.html` — demo/local paths | Customer Tracking | Fallback POD image and local rating confirmation | Contains embedded demo POD image and stores rating success in `localStorage` before adapter persistence result is surfaced | Active tracking UI and asynchronous rating event | PROTOTYPE-EMBEDDED | High: direct code evidence | P1.2 decide whether fallback/local confirmation can remain; avoid false success | Yes if customer-visible contract changes materially |
| `customer/backend.js` | Customer Tracking / backend adapter | Loads public tracking, maps status, obtains signed POD URL and submits rating | Reads token from query string; calls `public_tracking`, `submit_rating`, and `tracking-pod`; polls every 15 seconds | Shared client/config, migration RPCs, Edge Function | ACTIVE | High for wiring; runtime untested | Verify invalid/expired token, polling, POD and mutation failure paths | Founder approval for security/public-contract changes |
| `supabase/migrations/202608130001_cefflo_foundation.sql` | Supabase / backend | Git-tracked schema, enums, tables, RLS, RPCs, storage policies and Realtime publication | Single migration defines businesses/members, riders, sessions, orders, assignments, stops, events, locations, tokens, ratings and eight RPCs | Supabase/Postgres/Auth/Storage/Realtime | CANONICAL | High for repository schema intent; unknown applied state | P1.5 compare read-only/staging schema to migration; never infer production parity | Yes before production migration or material RLS/security change |
| `supabase/functions/tracking-pod/index.ts` | Supabase Edge Function / Tracking | Exchanges valid delivered tracking token for five-minute signed POD URL | Uses service-role environment, calls `public_tracking`, signs private bucket object; permissive CORS; deployment/JWT setting only described in README | Supabase Function runtime, service-role secret, migration RPC/storage | ACTIVE | High for source; unknown deployment/config | P1.5 verify deployed version, JWT setting, CORS/rate limiting and secret ownership read-only | Yes for production deployment/security changes |
| `tests/validate_backend.py` | Backend QA | Contract presence, RLS enabled, invalid tracking token and private POD bucket checks | Requires `DATABASE_URL`; no database URL present in this audit environment | Psycopg and disposable/staging database | TEST | High: source parsed; not executed | Run only against approved disposable/staging target; expand evidence in P1.5 | Founder decision if production access would be required |
| `tests/e2e_transaction.py` | Cross-app/backend QA | Transactional owner/rider/outsider lifecycle through delivery and rating | Inserts test auth users and data, checks unauthorized transition and event count, then rolls back | Psycopg, full migrated disposable/staging database | TEST | High: source parsed; not executed | Run against disposable/staging only; never assume rollback makes production use acceptable | Founder decision if no safe test target exists |
| `foundr/` or equivalent (absent) | FOUNDR | Stage 4 command center | No tracked FOUNDR client, route, build input or Vercel rewrite | Backend/admin authorization and audit contracts | MISSING | High: tracked-tree search | Keep missing; define Stage 4 executable scope in later phase, not P1.1/P1.2 | Yes: required Stage 4 FOUNDR scope and architecture |
| Marketing implementation for `cefflo.com` (absent) | Marketing/acquisition | Public brand/acquisition surface named in architecture | No tracked marketing directory, root marketing page, hostname rewrite or build input; generated root redirects to Vendor | Product/brand, hosting and domain plan | MISSING | High: tracked-tree/build inspection | Founder classify as required now, externally owned, or future before baseline lock | Yes |
| Cloudflare/DNS configuration (absent from Git) | Domain/edge | DNS, proxy, SSL/TLS, WAF/cache/rate-limit controls | Canonical docs name Cloudflare, but no tracked Cloudflare configuration exists | External Cloudflare account and DNS zone | UNKNOWN | High that repo lacks config; external state uninspected | P1.3 collect read-only record/ownership evidence; do not create or change records | Yes for any production DNS/edge change |
| `api.cefflo.com` implementation (absent) | API boundary | Optional hostname only if canonical production architecture needs it | No tracked API client/server, route, domain rewrite or configuration | Architecture decision | UNKNOWN | High: absence proven; requirement conditional | Founder decide whether no dedicated API hostname is canonical | Yes |

## 3. Coverage check

The register accounts for every tracked non-context path at the baseline commit.
Repeated icon files are grouped by surface; the canonical pack is grouped as an
immutable authority set. Missing/external surfaces are included explicitly but
are not represented as repository files.

No separate tracked legacy export, duplicate HTML file, FOUNDR client, marketing
client, Cloudflare configuration, or second migration was found. This does not
prove that historical or external copies do not exist.

## 4. Ambiguous or conflicting implementation paths for P1.2

1. **Vendor data ownership:** `vendor/index.html` contains local operational
   persistence and an inline Supabase layer while `vendor/backend.js` overrides
   selected handlers through `shared/client.js`. Script order proves coexistence,
   not which paths remain reachable in every workflow.
2. **Vendor state reduction after hydrate:** `vendor/backend.js` populates orders
   and riders from Supabase but resets delivery sessions, stops, assignments,
   zones, issues and status history to empty local arrays. It is unclear whether
   those active UI areas are intentionally local-only, incomplete, or stale.
3. **Vendor tracking-token ownership:** newly returned cleartext tokens are kept
   in browser local storage. Repository evidence does not show a vendor-authorized
   server path to recover an existing link on another browser/session.
4. **Rider boot state:** `rider/index.html` starts from `mockOrders`, while the
   adapter hydrates remote orders only after authentication/restore. Failure,
   latency and logout paths require reachability testing to prove mock data cannot
   appear as real work.
5. **Rider exception ownership:** several issue, availability, profile and route
   behaviors are local simulations; the adapter replaces core lifecycle actions
   but does not visibly persist every exception path.
6. **Assignment model:** the migration can represent sessions, assignments and
   stops, but `assign_rider` creates an assignment per order and current adapters
   do not prove session/batch/multi-stop ownership expected by the product model.
7. **Customer rating truth:** the UI records local success and emits an event;
   backend failure is logged asynchronously rather than reconciled visibly.
8. **Customer POD truth:** a demo image fallback exists in the active HTML even
   though the adapter requests a signed live URL.
9. **Shared versus embedded clients:** `shared/client.js` is the common client,
   but Vendor also contains inline auth/REST/Realtime/storage helpers. Functional
   duplication cannot be declared until P1.2 call-path tracing.
10. **Environment identity:** a Supabase project and publishable key are embedded
    in tracked browser configuration, but repository evidence does not establish
    whether they are preview, production, current, or retired.

## 5. New P1.1 findings

- `scripts/pwa-icon.svg` has no tracked consumer and is a legacy candidate pending
  provenance, despite the six surface-specific PNG icons being actively referenced.
- The generated root `dist/index.html` redirects to Vendor; there is no marketing
  root in the build, reinforcing the marketing-surface gap.
- The Edge Function's source allows any origin through CORS. Whether edge/backend
  rate limiting compensates is unknown from Git.
- `package.json` defines no automated test, lint or browser-validation command.
- Vendor and Rider service workers cache two standard icons but not the maskable
  icon; this may be acceptable and requires runtime validation rather than an
  assumed fix.
- The tracked migration includes `issue` and `cancelled` enum values, but the
  canonical rider transition RPC only advances the happy path through `arrived`;
  repository evidence does not show protected exception-transition mutations.

## 6. Founder decisions required before or during P1.2

1. Confirm that P1.2 may trace and label embedded prototype paths without yet
   deleting or changing them.
2. Decide whether `scripts/pwa-icon.svg` is the canonical icon source, retained
   historical evidence, or removable only after provenance is established.
3. Confirm intended ownership for Vendor auth/data access: shared client plus
   adapter, embedded layer, or a future consolidation proposal.
4. Confirm whether local/mock fallback behavior is permitted in authenticated
   Vendor and Rider production surfaces, and under which explicit degraded mode.
5. Confirm whether the marketing site is required in this repository for Stage 4,
   externally owned, or future.
6. Confirm that FOUNDR remains a required later-phase surface and approve its
   minimum Stage 4 scope before implementation planning.
7. Confirm whether a dedicated `api.cefflo.com` boundary is unnecessary or remains
   decision-required.
8. Authorize read-only access in P1.3/P1.5 to the relevant Vercel, Cloudflare/DNS
   and Supabase metadata needed to identify the actual runtime baseline. Any
   production change remains separately protected.

## 7. P1.1 result and boundary

R1.1 inventory is documented at repository level. Classifications that require
runtime reachability or ownership decisions remain explicitly provisional. P1.2
has not started; no artifact has been deleted, deactivated, moved, deployed, or
applied to Supabase.
