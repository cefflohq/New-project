# CEFFLO — Phase 1 Backend, Security, Test & Configuration Baseline

Status: P1.5 read-only technical audit — Founder review required

Baseline inspected: `main` at `de1b96c325e260762e0ca7b63fde4a7958a23fc9`

Scope: tracked repository evidence only; no Supabase project, production data, provider settings, or external environment was accessed

## 1. Authority, evidence labels, and status vocabulary

This audit reconciles the tracked backend with [02_ARCHITECTURE.md](02_ARCHITECTURE.md), [04_CURRENT_STATE.md](04_CURRENT_STATE.md), [10_DELIVERY_LIFECYCLE.md](10_DELIVERY_LIFECYCLE.md), [11_SUPABASE.md](11_SUPABASE.md), [12_SECURITY.md](12_SECURITY.md), [16_QA_RELEASE.md](16_QA_RELEASE.md), and the approved Phase 1 audits [PHASE_1_REPOSITORY_INVENTORY.md](PHASE_1_REPOSITORY_INVENTORY.md), [PHASE_1_ACTIVE_LEGACY_CLASSIFICATION.md](PHASE_1_ACTIVE_LEGACY_CLASSIFICATION.md), [PHASE_1_DEPLOYMENT_DOMAIN_MAP.md](PHASE_1_DEPLOYMENT_DOMAIN_MAP.md), and [PHASE_1_PRODUCT_LIFECYCLE_BASELINE.md](PHASE_1_PRODUCT_LIFECYCLE_BASELINE.md).

Evidence labels are deliberately separate from component status:

- **VERIFIED FROM CODE** — directly established from tracked source, migration, policy, or call-path inspection.
- **TESTED PASS** — executed in this sprint and passed; the test type and scope are stated.
- **INSPECTED ONLY** — test or behavior was read but not executed.
- **UNKNOWN EXTERNAL STATE** — repository evidence cannot establish deployed schema, provider settings, production configuration, or runtime behavior.

Component status uses only the canonical vocabulary from [04_CURRENT_STATE.md](04_CURRENT_STATE.md): `VERIFIED DONE`, `PARTIAL`, `MISSING`, `BLOCKED`, `FUTURE`, `DECISION REQUIRED`, and `UNKNOWN / NEEDS AUDIT`.

No database test was executed. `DATABASE_URL` was not set, no local Supabase configuration or CLI was present, and neither Docker nor Podman was available. The tracked tests explicitly require a disposable/staging database, so executing them without a verified disposable target would have been unsafe.

## 2. Tracked backend topology

The tracked backend consists of one foundation migration, one Tracking POD Edge Function, three browser surface adapters, one shared browser client/configuration pair, and two Python database tests. There is no generated Supabase type file, local Supabase project configuration, seed file, test fixture database, additional migration history, server application, rate-limit service, security-event pipeline, or FOUNDR backend.

The single migration defines 12 public tables, 4 enums, 3 authorization helpers, 8 application RPCs, 20 public-table RLS policies, 2 storage-object policies, one private bucket, and Realtime publication for 3 tables. Repository coverage is broad, but several Stage 4 contracts are either missing or bypassable through direct table policies.

## 3. Schema capability matrix

| Domain | Tracked capability | Status | Evidence | Gap / risk |
|---|---|---|---|---|
| Profiles | Auth-user keyed display name/phone row | `PARTIAL` | `VERIFIED FROM CODE` | No tracked trigger creates profiles despite Vendor comments referring to a `user_profiles` trigger; no FOUNDR/admin role model |
| Businesses | Identity, contact, address, operating area, timezone, currency | `VERIFIED DONE` | `VERIFIED FROM CODE` | Runtime/deployed schema remains `UNKNOWN EXTERNAL STATE` |
| Business members | Business/user composite key, owner/operator role, active/inactive status | `PARTIAL` | `VERIFIED FROM CODE` | Read-only membership policy; no invite/add/remove/change-role contract |
| Riders | Business ownership, optional auth user, identity/contact/vehicle, status, availability | `PARTIAL` | `VERIFIED FROM CODE` | No invitation/application entity; globally unique `auth_user_id` prevents one user from holding rider records for multiple vendor teams |
| Delivery sessions | Business, name/date, planned/active/completed/cancelled timestamps | `PARTIAL` | `VERIFIED FROM CODE` | No protected create/start/complete/cancel RPC or invariant enforcement |
| Orders | Customer/address/items/payment, session, rider, sequence, ETA, delivery lifecycle | `PARTIAL` | `VERIFIED FROM CODE` | No explicit approval state/contract; broad direct Vendor writes can bypass lifecycle rules |
| Rider assignments | Business/session/rider/status and lifecycle timestamps | `PARTIAL` | `VERIFIED FROM CODE` | No order/stop collection relationship other than stops; no acceptance/transition RPC; reassignment can leave stale assignment rows |
| Delivery stops | One stop per order, assignment/rider/sequence/status/ETA/POD | `PARTIAL` | `VERIFIED FROM CODE` | No protected route-plan/resequence operation; one-order/one-stop uniqueness supports multi-drop only by grouping separate stops |
| Delivery events | Append-oriented event rows with actor/status/metadata | `VERIFIED DONE` | `VERIFIED FROM CODE` | No authorized UI read model or security/admin event taxonomy; external append-only behavior untested |
| Rider locations | Rider/assignment coordinates and telemetry timestamp | `PARTIAL` | `VERIFIED FROM CODE` | Insert policy does not bind row `business_id` or `assignment_id` to the authenticated rider's business/assignment |
| Tracking tokens | Unique hash per order, expiry, revocation, creation timestamp | `PARTIAL` | `VERIFIED FROM CODE` | Creation sets no expiry; no recover/rotate/revoke contract; one token row per order prevents rotation history |
| Ratings | One delivered-order rating, rider link, 1–5 check, feedback list | `PARTIAL` | `VERIFIED FROM CODE` | No feedback count/length constraints or abuse controls; UI confirmation is not backend-owned |
| Zones | None | `MISSING` | `VERIFIED FROM CODE` | Stage 4 must decide persisted, derived, or hybrid zone contract |
| Operational issues/exceptions | Generic `issue` enum values only | `MISSING` | `VERIFIED FROM CODE` | No issue entity, typed exception, report/resolve/reassign/redelivery RPC, or exception event contract |
| Security/admin events | Delivery events only | `MISSING` | `VERIFIED FROM CODE` | No auth/security-event or privileged FOUNDR audit schema |

## 4. RLS and authorization matrix

| Resource / operation | Policy or server check | Status | Evidence | Authorization conclusion |
|---|---|---|---|---|
| Own profile | `profiles_self` permits all operations where `id = auth.uid()` | `PARTIAL` | `VERIFIED FROM CODE` | Self-isolated, but delete/insert/update behavior is not product-governed or tested |
| Business read/update | Active members read; active owners update | `VERIFIED DONE` | `VERIFIED FROM CODE` | Appropriate basic owner/member separation |
| Membership read | Active member of the same business | `VERIFIED DONE` | `VERIFIED FROM CODE` | Cross-business read constrained; membership mutation is absent |
| Rider records | Any active member has `FOR ALL`; rider can read own row | `PARTIAL` | `VERIFIED FROM CODE` | Tenant check exists, but operators can create/update/delete riders and bind `auth_user_id`; owner-only team governance is not enforced |
| Delivery sessions | Any active member has `FOR ALL` | `PARTIAL` | `VERIFIED FROM CODE` | Tenant-isolated by row business ID, but lifecycle and destructive mutations bypass protected commands |
| Orders | Any active member has `FOR ALL`; assigned active rider can select | `PARTIAL` | `VERIFIED FROM CODE` | Rider read is assignment-bound; Vendor direct insert/update/delete can bypass creation, approval, assignment, transition, event, and deletion rules |
| Assignments | Any active member has `FOR ALL`; assigned rider can select | `PARTIAL` | `VERIFIED FROM CODE` | Direct Vendor mutations can bypass same-business rider/session integrity and assignment lifecycle |
| Stops | Same-business members and assigned riders can select; no direct client write policy | `VERIFIED DONE` | `VERIFIED FROM CODE` | Reads are scoped and mutations are server-owned in the tracked path |
| Delivery events | Same-business members and assigned-order riders can select; no client write/update/delete policy | `VERIFIED DONE` | `VERIFIED FROM CODE` | Strongest append-only domain in the migration; negative behavior remains untested |
| Rider locations | Vendor reads same-business rows; current rider inserts rows bearing own rider ID | `PARTIAL` | `VERIFIED FROM CODE` | Insert does not require `business_id` or `assignment_id` to match that rider; cross-business row injection is possible if foreign IDs are known |
| Tracking tokens | RLS enabled with no direct table policies | `VERIFIED DONE` | `VERIFIED FROM CODE` | Browser table access is closed; only definer functions/service role can reach tokens |
| Ratings | Vendor reads ratings for member-owned orders; public mutation only through RPC | `VERIFIED DONE` | `VERIFIED FROM CODE` | Direct anonymous table access is closed |
| POD objects | Assigned rider inserts under `orders/<order UUID>/...`; authorized business members/assigned rider read | `PARTIAL` | `VERIFIED FROM CODE` | Private/read-scoped design is good; completion does not verify that supplied path is an existing object for that order |
| Anonymous tracking/rating | Token-validating security-definer RPCs | `PARTIAL` | `VERIFIED FROM CODE` | Token checks exist; no rate limiting, abuse logging, or constrained feedback size |

### Cross-business isolation conclusion

Read policies generally use business membership or assigned-rider identity and provide a credible isolation foundation. Isolation is incomplete at write/integrity boundaries:

- `orders`, `rider_assignments`, and `rider_locations` contain plain foreign keys plus independently supplied `business_id`; no composite constraint guarantees referenced session/rider/assignment belongs to the same business.
- Broad same-business `FOR ALL` policies allow direct REST writes that can create cross-business references when identifiers are known, bypassing the safer `assign_rider` checks.
- Rider-location inserts can declare a different business ID while retaining the authenticated rider ID.

These are `VERIFIED FROM CODE` findings. Exploitability and deployed policy parity are `UNKNOWN EXTERNAL STATE` because no database was accessed.

## 5. RPC and mutation ownership matrix

| Contract | Current owner and checks | Status | Evidence | Missing or bypass path |
|---|---|---|---|---|
| Business bootstrap | `bootstrap_business`; requires authenticated UID, creates owner membership | `VERIFIED DONE` | `VERIFIED FROM CODE` | No input length/format constraints; no tested abuse/duplicate-business policy |
| Business discovery | `get_my_businesses`; active membership filter | `VERIFIED DONE` | `VERIFIED FROM CODE` | No member-management operations |
| Order creation | `create_delivery`; member check, order + stop + token + event in one transaction | `VERIFIED DONE` | `VERIFIED FROM CODE` | Direct `orders_vendor FOR ALL` permits alternate creation without stop/token/event |
| Explicit order approval | None | `MISSING` | `VERIFIED FROM CODE` | Rider RPC can advance `created` to `ready_for_pickup`; Vendor approval ownership is absent |
| Session/batch creation and transition | None | `MISSING` | `VERIFIED FROM CODE` | Direct table policy and client-local engine are the only paths |
| Zone planning | None | `MISSING` | `VERIFIED FROM CODE` | No schema or server algorithm/contract |
| Rider invitation/team join | None | `MISSING` | `VERIFIED FROM CODE` | Rider UI application and Vendor invite remain local/mock |
| Single-order assignment | `assign_rider`; member check and active same-business rider validation | `PARTIAL` | `VERIFIED FROM CODE` | Creates a new assignment each call, has no acceptance flow, and can be bypassed by direct table/order writes |
| Assignment acceptance/lifecycle | None | `MISSING` | `VERIFIED FROM CODE` | Assignment enum exists without protected transition owner |
| Pickup/in-transit/arrival | `rider_transition`; current assigned active rider and allowed transition graph | `VERIFIED DONE` | `VERIFIED FROM CODE`; DB test `INSPECTED ONLY` | Idempotency key is recorded but not enforced for deduplication; direct Vendor order writes bypass graph |
| Exception report/resolve/retry | None | `MISSING` | `VERIFIED FROM CODE` | Generic enum cannot represent approved exception workflow |
| POD completion | `complete_delivery`; current assigned rider, arrival state, nonempty path | `PARTIAL` | `VERIFIED FROM CODE`; DB test uses a fabricated path and is `INSPECTED ONLY` | Does not verify storage object existence, bucket, order-prefix ownership, MIME, or uploader before marking delivered |
| Public tracking | `public_tracking`; hashes token, rejects revoked/expired, returns selected snapshot | `PARTIAL` | `VERIFIED FROM CODE` | No rate limit; returns internal POD path; no explicit status minimization/mapping at server boundary |
| Rating | `submit_rating`; valid token, delivered order, 1–5, one per order | `PARTIAL` | `VERIFIED FROM CODE`; DB test `INSPECTED ONLY` | No rate limit or feedback bounds; client falsely owns success state |
| Tracking-token recovery/revocation/rotation | None | `MISSING` | `VERIFIED FROM CODE` | Columns exist for expiry/revocation, but creation leaves expiry null and there is no management contract |

The migration grants intended functions to authenticated or anonymous roles but does not explicitly revoke default function execution from `PUBLIC`. Effective deployed grants are `UNKNOWN EXTERNAL STATE`; least-privilege migration repair should explicitly revoke and re-grant every security-definer entry point.

## 6. Lifecycle backend coverage

| Lifecycle domain | Backend coverage | Status | Evidence-backed conclusion |
|---|---|---|---|
| Order requested/created | Atomic `created` order, stop, token, event | `VERIFIED DONE` | Strong foundation for internal Vendor creation |
| Vendor approval | No state or mutation distinct from pickup readiness | `MISSING` | Approved Stage 4 direction cannot be expressed coherently |
| Session/batch | Table only | `PARTIAL` | Persistence exists; protected orchestration and invariants do not |
| Assignment | Protected single-order assignment plus table/enum | `PARTIAL` | Happy path exists; session/multi-stop and acceptance ownership incomplete |
| Ready/pickup | Rider can advance `created → ready_for_pickup → picked_up` | `PARTIAL` | Protected graph exists, but Rider currently owns readiness that should follow explicit Vendor approval |
| In transit/arrival | Protected `picked_up → out_for_delivery → arrived` | `VERIFIED DONE` | Order and stop update plus event are atomic |
| Exception/failure/retry | Enum only | `MISSING` | No backend-authoritative cross-app exception state |
| POD/delivered | Arrival + nonempty path required; stop/order/event updated | `PARTIAL` | Lifecycle atomicity exists, storage-object integrity does not |
| Assignment/session completion | Assignment/session fields only | `MISSING` | Rider completion does not close either backend entity |
| Customer mapping | Raw internal status returned | `PARTIAL` | Client maps states and currently misrepresents unknown/pre-pickup/issue values |
| Append-only history | Delivery events created by protected RPCs | `PARTIAL` | Protected paths append; direct Vendor table mutations do not |

## 7. Rider-team and invitation backend gap

`riders` can represent a business-owned active rider linked to one Auth user, and RLS can authorize that rider. It cannot represent the approved onboarding process. Missing backend concepts include invitation token/hash, inviter and business, invited contact, pending/accepted/expired/revoked state, expiration, single-use acceptance, authenticated-user binding, resend/revoke, audit event, and owner/operator permission rules.

The globally unique `riders.auth_user_id` also encodes one rider record per Auth user across the entire platform. Founder must decide whether a trusted rider may belong to multiple vendor teams; the Stage 4 membership model and schema must agree before implementation.

## 8. Batching, session, zone, and multi-stop backend gap

- Sessions, assignments, stops, sequence, ETA, and rider locations provide a meaningful multi-drop schema foundation.
- `assign_rider` creates an assignment for one order and does not establish or validate a full session route.
- No unique/invariant constraint prevents duplicate active assignments for the same rider/session or repeated assignment rows for one order reassignment.
- No protected session create/start/close, batch formation, route-plan, stop-resequence, assignment accept/start/complete, or route read-model RPC exists.
- Zones are entirely absent from the backend.
- Vendor broad table policies currently allow clients to write plans directly, which makes the browser authoritative for invariants.

Status: schema foundation `PARTIAL`; Stage 4 orchestration `MISSING`.

## 9. Tracking-token lifecycle gap

Token generation uses 32 random bytes, returns cleartext once, and stores a SHA-256 hash. Lookup checks revocation and expiry, which is a strong baseline. However:

- `create_delivery` sets neither an expiry nor an explicit no-expiry policy;
- one unique token row per order prevents retaining rotation history;
- no protected Vendor recovery, rotate, revoke, or expire operation exists;
- no token-use audit/security event or abuse counter exists;
- no request throttling is tracked for `public_tracking`, `submit_rating`, or the POD Edge Function;
- the public tracking response exposes the internal storage object path after delivery, although the private object itself still requires authorized/signed access.

Status: creation/validation `PARTIAL`; lifecycle management and abuse protection `MISSING`.

## 10. POD, storage, and Edge Function baseline

| Area | Baseline | Status | Evidence |
|---|---|---|---|
| Bucket | `cefflo-pod`, private, 5 MiB limit, JPEG/PNG/WebP allowlist | `VERIFIED DONE` | `VERIFIED FROM CODE` |
| Browser upload path | `orders/<order UUID>/<random UUID>.<extension>`, authenticated bearer, no upsert | `VERIFIED DONE` | `VERIFIED FROM CODE` |
| Upload policy | Assigned current rider and order UUID derived from path | `PARTIAL` | `VERIFIED FROM CODE`; no executed storage test |
| Authenticated read | Same-business member or assigned rider | `VERIFIED DONE` | `VERIFIED FROM CODE` |
| Completion integrity | Only nonempty `p_pod_path` is required | `PARTIAL` | `VERIFIED FROM CODE`; object existence/ownership not checked |
| Customer retrieval | Edge Function validates token through `public_tracking`, requires delivered/path, signs for 300 seconds using service role | `PARTIAL` | `VERIFIED FROM CODE`; deployment/runtime `UNKNOWN EXTERNAL STATE` |
| CORS | `Access-Control-Allow-Origin: *`; allowed headers only `content-type` | `PARTIAL` | `VERIFIED FROM CODE` | Public-token design may permit broad origin access, but production origin/method/rate policy is undefined |
| Errors | All exceptions return HTTP 404 with the exception message | `PARTIAL` | `VERIFIED FROM CODE` | Conflates invalid token, unavailable POD, provider error; raw messages may reveal implementation detail |
| Rate limiting | None tracked | `MISSING` | `VERIFIED FROM CODE` |

No service-role secret value is tracked. The Edge Function references the environment variable name only. Actual secret storage, function JWT settings, deployment, logs, and rate limits are `UNKNOWN EXTERNAL STATE`.

## 11. Authentication baseline

| Surface / behavior | Baseline | Status | Evidence |
|---|---|---|---|
| Vendor signup/login | Email/password Auth, business bootstrap, email confirmation handling, reset callback | `PARTIAL` | `VERIFIED FROM CODE`; provider/runtime `UNKNOWN EXTERNAL STATE` |
| Vendor restoration | Local token restore, expiry refresh, `/auth/v1/user` validation, business hydrate | `PARTIAL` | `VERIFIED FROM CODE`; duplicate inline/shared session owners remain |
| Vendor logout | Calls Auth logout, clears session, stops realtime/GPS | `VERIFIED DONE` | `VERIFIED FROM CODE` |
| Rider login | Email or normalized Malaysian phone plus password; active linked rider check | `PARTIAL` | `VERIFIED FROM CODE`; phone/SMS/provider readiness `UNKNOWN EXTERNAL STATE` |
| Rider restoration | Shared stored token plus delayed active-rider/order validation | `PARTIAL` | `VERIFIED FROM CODE`; local startup gate can briefly expose mock state |
| Rider logout | Removes only local UI flag | `MISSING` | `VERIFIED FROM CODE` | Shared access/refresh token remains stored and may restore the session |
| Rider signup/recovery | Mock OTP/application/reset | `MISSING` | `VERIFIED FROM CODE` | Not production Auth; conflicts with trusted-team direction |
| Customer | No account; token-authorized public RPC/Edge Function | `PARTIAL` | `VERIFIED FROM CODE` | Correct architectural model, missing abuse/error controls |
| Session storage | Access/refresh session JSON stored in `localStorage` per surface | `PARTIAL` | `VERIFIED FROM CODE` | XSS can expose bearer tokens; CSP is not defined in tracked Vercel headers |
| FOUNDR auth | None | `MISSING` | `VERIFIED FROM CODE` |

## 12. Environment and configuration baseline

- `.env.example` contains placeholder names for Supabase URL, publishable key, and database URL; it contains no committed secret value. `VERIFIED FROM CODE`.
- The browser bundle necessarily exposes one Supabase project URL and publishable key in `shared/config.js`; these are public client configuration, not service-role secrets. Values are intentionally omitted from this report.
- Vendor also embeds a duplicate project reference and initially captures a different storage bucket name before shared configuration loads. `PARTIAL` configuration ownership.
- The static build performs no environment substitution and does not consume `.env.example`.
- Preview and production builds therefore cannot select separate backend targets from tracked build logic. `MISSING` Stage 4 separation.
- Surface session keys differ, but all browser sessions use local storage and one hard-coded backend target.
- A path-only secret scan found no private-key material or service-role value. README/Edge Function references are names/instructions, and `.env.example` contains placeholders. `TESTED PASS` for this limited static scan; it is not a full secret-history scan.
- Vercel environment values, Supabase project configuration, Auth providers, Edge Function secrets, database extensions/settings, backup/PITR, logs, and deployed migration parity remain `UNKNOWN EXTERNAL STATE`.

## 13. Test coverage matrix

| Test area | Tracked coverage | Sprint result | Status / gap |
|---|---|---|---|
| Python syntax | Both test files parse with Python AST | `TESTED PASS` — static only | Does not exercise database behavior |
| JavaScript syntax | Shared config/client, all adapters, service workers, and build script passed `node --check` | `TESTED PASS` — static only | Inline HTML scripts and TypeScript Edge Function were not runtime-tested |
| Schema presence | `validate_backend.py` checks selected tables/RPC names | `INSPECTED ONLY` | Omits `profiles` and `delivery_sessions`; does not compare columns, enums, constraints, grants, policies, publication, or function definitions |
| RLS enabled | Checks `relrowsecurity` for all public ordinary tables | `INSPECTED ONLY` | Does not prove policies deny unauthorized/cross-business operations |
| Unauthorized rider transition | Outsider transition expected to fail | `INSPECTED ONLY` | Only one negative mutation; no direct-table RLS tests |
| Cross-business access | None | `MISSING` | Needs two businesses and read/write matrix across every tenant table/RPC/storage path |
| Order creation/assignment/lifecycle | Happy path create, assign, four transitions, complete | `INSPECTED ONLY` | No explicit approval/session/multi-stop/exception; no direct-write bypass checks |
| Invalid transition/idempotency | None for assigned rider | `MISSING` | Duplicate idempotency keys and skipped/reversed transitions untested |
| POD | Completion passes a fabricated path string | `INSPECTED ONLY` | No object upload, bucket policy, object existence, wrong-order path, read denial, signed URL, MIME/size, or failure test |
| Public tracking | Valid delivered token plus one invalid-token null check | `INSPECTED ONLY` | Expired/revoked token, minimal data, pre-pickup/issue mapping, rate limiting, and Edge Function untested |
| Rating | One valid delivered rating | `INSPECTED ONLY` | Pre-delivery, invalid token/value, duplicate, oversized feedback, concurrency, and UI failure behavior untested |
| Delivery events | Expects seven happy-path events | `INSPECTED ONLY` | Event content/actor/order, append-only denial, direct-write gaps, and exception events untested |
| Auth/session | None | `MISSING` | Signup/login/refresh/logout, inactive rider, invitation join, phone readiness, and mock-path blocking untested |
| Realtime | None | `MISSING` | Authorization, publication, reconnect, duplicate/out-of-order updates untested |
| Browser/cross-app E2E | None | `MISSING` | No Vendor → Rider → Customer browser journey or failure-state coverage |
| Local/disposable DB execution | No safe environment available | Not executed | `BLOCKED` until an explicitly disposable local/staging target and dependencies are provided |

The database scripts use transactions and roll back test data, but they still insert into `auth.users` and require privileged database connectivity. Rollback is not sufficient authorization to point them at an unidentified environment.

## 14. Security findings

| Severity | Finding | Status | Evidence and impact | Required direction |
|---|---|---|---|---|
| Critical | Direct Vendor table mutations bypass protected lifecycle contracts | `PARTIAL` | `VERIFIED FROM CODE`: active members have `FOR ALL` on orders, sessions, assignments, and riders. Clients can update/delete records without RPC invariants or append-only events | Restrict mutations to least-privilege protected contracts; preserve required reads |
| Critical | POD completion trusts an arbitrary nonempty path | `PARTIAL` | `VERIFIED FROM CODE`: `complete_delivery` does not verify object existence or order-prefix ownership; tests use a nonexistent path. This can mark false completion and could sign the wrong private object path | Validate object, bucket, order/rider ownership, and upload state atomically or through a protected completion design |
| High | Cross-business relational integrity is not enforced on several writes | `PARTIAL` | `VERIFIED FROM CODE`: independent business/session/rider/assignment foreign keys plus broad policies permit mismatched references; rider-location insert can declare another business ID | Add same-business invariants and protected operations; test two-business negative matrix |
| High | Public token endpoints and POD function have no tracked rate limiting or abuse telemetry | `MISSING` | `VERIFIED FROM CODE`: anonymous tracking, rating, and Edge Function calls are unthrottled in the tracked implementation | Define backend/edge throttling, safe errors, monitoring, and incident signals |
| High | Rider logout does not revoke/clear the Auth session | `MISSING` | `VERIFIED FROM CODE`: UI flag is removed while shared bearer session remains | Shared logout must own server logout and local session cleanup |
| High | Tracking tokens have no recovery/rotation/revocation operations and default to indefinite lifetime | `PARTIAL` | `VERIFIED FROM CODE`: expiry/revocation columns exist but creation leaves expiry null and no management RPC exists | Approve lifecycle policy and protected token-management contract |
| Medium | Business `operator` effectively has full rider and operational write/delete power | `DECISION REQUIRED` | `VERIFIED FROM CODE`: most Vendor policies use membership, not owner role or scoped permissions | Define owner/operator permission matrix before RLS repair |
| Medium | Public tracking exposes internal POD object path | `PARTIAL` | `VERIFIED FROM CODE`: path is returned after delivery even though object remains private | Return only minimum public fields; keep path inside protected signing boundary |
| Medium | Edge Function uses wildcard CORS and returns raw exception messages | `PARTIAL` | `VERIFIED FROM CODE` | Define allowed-origin/method policy and normalized non-enumerating errors |
| Medium | Browser bearer sessions and operational/customer data persist in local storage | `PARTIAL` | `VERIFIED FROM CODE`; no tracked CSP | Minimize stored PII, consolidate session ownership, and apply production browser controls |
| Medium | Security-definer execution privileges are not explicitly revoked from `PUBLIC` | `UNKNOWN / NEEDS AUDIT` | Migration grants intended roles without explicit revokes; effective deployed grants were not inspected | Explicitly revoke/re-grant in reviewed migration and verify deployed ACLs |
| Medium | Rating feedback is unbounded and anonymous | `PARTIAL` | `VERIFIED FROM CODE`: array elements/count/length have no constraints; no rate limit | Add bounded validation and abuse controls |
| Medium | No security/admin audit-event model exists | `MISSING` | `VERIFIED FROM CODE` | Required for FOUNDR privileged operations and incident investigation |

No finding was exploited, and no production vulnerability claim is made. Severity reflects the consequence if the tracked migration is deployed as written and reachable through normal Supabase APIs.

## 15. Client-authoritative state that must move behind backend contracts

- Vendor CSV import results, zones, batching/session plans, route assignments, issue/reschedule outcomes, rider invite/deactivate, performance figures, and profile/password success paths.
- Rider signup/OTP/recovery, assignment metadata, availability, profile data, exceptions/redelivery/vendor notifications, session completion, and offline mutation results.
- Customer loading/invalid-token truth, POD fallback, rating success, and local rating restore.
- Vendor full-state offline queue currently resolves through an adapter-installed successful no-op.

These are product-integrity findings as well as security findings: browser state may support presentation/cache, but it must not authorize or confirm protected operational outcomes.

## 16. Preserve / Repair / Complete / Build backend matrix

| Treatment | Backend areas |
|---|---|
| Preserve | Core business/order/stop/event/token/rating schema; membership/rider helpers; private POD bucket; high-entropy hashed token creation; protected Rider transition graph; signed Customer POD pattern; RLS-enabled default |
| Repair | Direct Vendor mutation policies; same-business relational integrity; rider-location policy; POD completion/object validation; explicit function privileges; Rider logout/session ownership; public response minimization; CORS/error handling; configuration duplication |
| Complete | Order approval; session/batch/assignment lifecycle; multi-stop read/planning contracts; token expiry/revoke/rotate/recovery; assignment acceptance/completion; environment separation; negative/RLS/storage/Edge tests; Realtime authorization tests |
| Build | Trusted-team invitation/join; zone contract; typed exception/report/resolve/reassign/redelivery; sales/order-page backend intake; FOUNDR authorization/audit/security events; rate limiting/abuse monitoring; backup/recovery verification runbook |

## 17. Stage 4 blockers

1. Direct table mutation policies undermine protected lifecycle ownership and append-only event completeness.
2. Explicit Vendor order approval does not exist.
3. Session/batch/zone/multi-stop orchestration and authoritative shared read models are incomplete.
4. Trusted Rider invitation/team join has no backend contract.
5. Exception handling is not backend-authoritative.
6. POD completion can succeed without a verified order-owned storage object.
7. Tracking-token recovery/rotation/revocation policy and endpoint protection are missing.
8. Anonymous tracking/rating/POD endpoints lack tracked rate limiting and abuse monitoring.
9. Rider Auth logout/recovery and production provider readiness are incomplete or unknown.
10. Preview/production backend separation is absent from tracked build configuration.
11. FOUNDR privileged authorization and audit infrastructure is absent.
12. No current database, RLS, storage, Edge Function, browser E2E, or cross-app test has a `TESTED PASS` result against this commit.
13. Deployed migration parity, backups/PITR, Auth settings, secrets, logs, and external controls remain `UNKNOWN EXTERNAL STATE`.

## 18. Founder decisions required before backend implementation

1. Approve the owner/operator permission matrix, including who may manage riders, members, orders, sessions, assignments, exceptions, and destructive actions.
2. Approve moving lifecycle-sensitive writes from broad table policies to protected RPC/server contracts and the compatibility sequence for existing clients.
3. Confirm the explicit order approval/readiness state model and which actor owns each transition.
4. Approve session, batch, zone, assignment, and multi-stop invariants, including whether zones are persisted, derived, or hybrid.
5. Decide whether one Auth user may belong to multiple vendor teams as a rider.
6. Approve the trusted-team invitation/join token lifecycle and identity-binding rules.
7. Approve the exception entity/types, report/resolve/reassign/redelivery permissions, customer visibility, and event/audit rules.
8. Approve POD completion integrity: upload reservation/receipt, object verification, retry, replacement, retention, and deletion policy.
9. Approve tracking-token expiry, rotation, revocation, recovery, audit, and abuse-control policy.
10. Approve public endpoint rate limits, Cloudflare/backend responsibility split, safe CORS origins, and security-event monitoring.
11. Approve preview/staging/production Supabase separation and safe test-environment ownership before database tests run.
12. Approve the minimum FOUNDR role model, privileged actions, reason/confirmation requirements, and append-only audit schema.
13. Confirm Stage 4 backup/PITR and database rollback requirements for later provider verification.

## 19. Recommended next technical action after approval

Before product integration, define a reviewed backend contract package covering explicit order approval plus session/assignment/stop reads and protected mutations, together with a two-business negative-test matrix. The first implementation must close direct-write bypasses without breaking the current protected create/assign/Rider/POD happy path.

This recommendation is not implementation authorization. P1.5 changes no migration, RLS policy, Auth setting, Supabase resource, application/configuration file, infrastructure, or deployment and does not begin P1.6.
