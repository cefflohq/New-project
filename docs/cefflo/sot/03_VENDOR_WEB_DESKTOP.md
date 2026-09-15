**Status:** CANONICAL — Founder-approved, merged into repo 2026-09-04
**Repo-reconciliation note:** Canonical behavioural doctrine for Vendor Web/Desktop. The concrete, currently-verified exit contract is `docs/cefflo/flow3/VENDOR_BEHAVIOURAL_CONTRACT_PACK.md` (Flow 3, complete). `docs/cefflo/06_VENDOR.md` remains valid current-implementation routing detail.

---

# CEFFLO — VENDOR WEB / DESKTOP SOT
**Status:** Canonical Product-Surface SOT
**Version:** 1.0 — 2026-09-04
**Owner:** Founder
**Reference:** Flow 3 Vendor Web/Desktop completion + Vendor Behavioural Contract Pack.

## 1. Role
Vendor Web/Desktop is a first-class Cefflo client and the broad operational/control workspace for a business.

It is not a temporary prototype to be replaced by Flutter.

Vendor Web/Desktop and Vendor Flutter must share the same canonical backend truth.

## 2. Product Responsibility
Vendor Web/Desktop owns Vendor-facing control over:
- today's operational overview;
- orders/intake;
- location/coverage visibility;
- Zones;
- delivery planning/review;
- dispatch;
- active runs/stops/events;
- Need Attention/recovery;
- Riders;
- Team/permissions;
- Service Area;
- Storefront/Appearance where current scope supports it;
- Business Profile;
- account/security/settings/support;
- subscription surfaces only when released from HOLD.

## 3. Operational Spine
TODAY → ORDERS → ZONES → PLAN / REVIEW → DISPATCH → ACTIVE RUNS → NEED ATTENTION → DONE

Desktop may expose greater information density and configuration depth than mobile, but must not create different business rules.

## 4. Architecture
Vendor Web/Desktop → `cefflo_api` / canonical adapters → Supabase/Postgres/RPC/Storage.

Backend owns:
- tenant authorization;
- coverage;
- zone rules;
- vehicle/capacity logic;
- planning eligibility;
- run construction truth;
- sequence validation;
- assignment/dispatch authorization;
- recovery eligibility;
- completion truth;
- canonical ETA;
- audit/events.

Web owns presentation, interaction and client state only.

## 5. Behavioural Contract Pack
The Flow 3 exit contract is the behavioural reference for Flow 4 and future Vendor clients.

It must cover:
1. information architecture;
2. API/RPC map;
3. auth/session/business context;
4. order states/actions;
5. location/coverage;
6. Zones;
7. planning/review/dispatch;
8. runs/stops/events;
9. Rider/invitation/capacity;
10. Team/permissions;
11. Need Attention/recovery;
12. Storefront/Business Profile;
13. account/settings/language/theme;
14. loading/error/empty;
15. status-label mapping;
16. responsive/experience decisions;
17. HOLD/POST-V1;
18. backend limitations clients must not solve locally.

## 6. Vendor vs Rider Ownership
Vendor plans/builds/reviews/dispatches.

Rider owns execution-level resequencing where the canonical contract authorizes it.

Do not widen `save_run_sequence` or equivalent Rider-owned execution authorization merely because Vendor UI can visually reorder something.

## 7. Order Truth
Order creation must use the canonical backend path.

Never restore dead/local creation engines or maintain a second local order source.

Refresh/hydration must reconcile canonical state after mutation.

## 8. Zones
Service Area is configuration.
Zones is operational organization.

Zone create/edit/enable/disable and assignment actions must use canonical contracts where supported.

No local-only quick assignment or fake success.

## 9. Planning & Dispatch
Planning surfaces show server-valid proposals/conflicts.

Vendor may make only adjustments permitted by canonical contracts.

Dispatch is successful only after backend confirmation.

Do not market or label ordinary sequencing/planning as AI optimization unless that capability is verified.

## 10. Runs & Need Attention
Active work must survive refresh and reflect canonical sessions/stops/events.

Exceptions must surface with enough context for a permitted recovery action.

Recovery uses narrow backend authorization and audit; never local reassignment.

## 11. Riders & Team
Rider management follows real invitation/approval/membership models.

No quick-add bypass that creates a local fake Rider.

Team UI must respect backend permissions, not just hide buttons.

## 12. Business vs User Identity
Business Profile = business identity.
Profile = logged-in human/user identity.

Do not merge these concepts.

## 13. Service Area vs Zones
Service Area defines business coverage/configuration.
Zones organizes operational delivery work.

They may interact but are not interchangeable navigation labels.

## 14. Storefront / Appearance
Only expose customization actually supported.

Do not promise arbitrary branding/color freedom if implementation is curated/limited.

## 15. Subscription
Vendor-to-Cefflo SaaS billing is separate from vendor-customer commerce.

Subscription/payment screens remain gated until released and verified.

## 16. Responsive / Desktop Quality
Web/Desktop must be genuinely usable on desktop/tablet, not merely a stretched mobile layout.

Validate:
- information density;
- keyboard/mouse interactions;
- responsive breakpoints;
- long tables/lists;
- empty/loading/error;
- Light/Dark where supported;
- accessibility;
- browser resilience.

## 17. Truth Rules
Never show fake:
- dispatch success;
- Rider availability;
- GPS;
- ETA;
- notification delivery;
- payment success;
- assignment;
- recovery;
- persisted settings.

## 18. Cross-Client Contract
Vendor Web change → Vendor Flutter reflects canonical state.
Vendor Flutter change → Vendor Web reflects canonical state.
Vendor dispatch → Rider canonical assignment.
Rider progress → Vendor surfaces update.
Customer tracking → customer-safe projection of same delivery.

## 19. Security
- tenant/business isolation;
- authenticated business context;
- permission-aware direct actions;
- no service-role secret in client;
- safe session expiry;
- idempotent mutations where retry likely;
- storage access by policy/signed URLs;
- audit privileged/operational transitions.

## 20. Evidence Standard
Completion claims require:
- exact repo/branch/SHA;
- tests;
- browser/runtime evidence;
- preview URL where UI-visible;
- security results;
- known limitations;
- no hidden P0/P1 blocker.

## 21. Known Flow-3 Completion Context
Flow 3 is the stable behavioural reference for Vendor Flutter. Any future implementation must inspect the actual current Contract Pack/repository rather than infer behavior from this summary alone.

## 22. Definition of Done
Vendor Web/Desktop remains a real, synchronized, secure operational client capable of controlling a local same-day delivery day without critical outcomes depending on mock/local-only truth.
