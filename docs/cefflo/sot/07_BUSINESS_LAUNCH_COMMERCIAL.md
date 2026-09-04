**Status:** CANONICAL — Founder-approved, merged into repo 2026-09-04
**Repo-reconciliation note:** Net-new commercial/launch governance layer. Distinct from and complementary to `docs/cefflo/launch/CEFFLO_GROW_V1_SCOPE_LOCK.md` (Founder-approved, FROZEN, 2026-09-03), which defines WHAT product/feature scope is in the V1 launch — this file defines the commercial/billing/go-live PROCESS governance around that scope. Neither supersedes the other. See also `docs/cefflo/16_QA_RELEASE.md` and `docs/cefflo/05_DECISIONS.md` D-07/D-08 for existing release-process detail.

---

# CEFFLO — BUSINESS, LAUNCH & COMMERCIAL SOT
**Status:** Canonical Launch Governance
**Version:** 1.0 — 2026-09-04
**Owner:** Founder
**Primary Launch Market:** Malaysia

## 1. Purpose
Define what must be true before Cefflo can move from staging/product completion into controlled commercial launch without mixing product, pricing, billing, marketing and production readiness.

## 2. Launch Doctrine
**Malaysia-first. Asia-ready. International-capable.**

Do not launch additional countries merely because architecture can display their currency.

Malaysia must first prove product, pricing, COGS, acquisition and operational reliability.

## 3. Commercial Product Boundary
Cefflo sells SaaS access to Vendors/businesses.

Cefflo does not currently process vendor-customer commerce, deposits, balances or payouts.

Vendor-to-Cefflo subscription billing is a separate commercial flow.

## 4. Pricing Authority
Pricing must come from the current Founder-approved Pricing Master.

Current international framework values are candidates/simulations unless separately locked.

Never publish a candidate price as final solely because it exists in an MD.

Pricing system should support:
- one canonical plan architecture;
- regional price books;
- currency/locale;
- entitlements;
- tax presentation rules;
- versioned effective dates.

## 5. Subscription Gateway — Malaysia
Founder-locked primary gateway:
**Razorpay Curlec**

Scope:
**Vendor → Cefflo SaaS subscription/billing only.**

This does not authorize vendor-customer payment handling.

## 6. Curlec Activation Gate
When subscription implementation is released, complete:
1. Curlec merchant onboarding/KYC;
2. merchant account configuration;
3. test/sandbox mode;
4. settlement configuration;
5. recurring subscription/payment integration;
6. server-side webhook verification;
7. subscription state machine;
8. failed payment/retry/cancel handling;
9. reconciliation;
10. production credentials;
11. production activation;
12. monitoring/support runbook.

No UI may show payment/subscription success before verified server-side truth.

## 7. Subscription Truth
Canonical backend should own:
- plan;
- entitlement;
- billing customer/reference;
- subscription state;
- current period;
- renewal/cancel state;
- payment event reconciliation;
- grace/failed state where designed.

Client UI is a projection of server-side commercial truth.

## 8. Commercial States
At minimum design explicit states for:
- free/no paid subscription;
- checkout/pending;
- active;
- payment failed;
- past due/grace where applicable;
- canceled at period end;
- canceled/ended;
- plan change pending/applied;
- webhook/reconciliation exception.

Exact provider mapping is implementation-specific.

## 9. Release Candidate Gate
Before Production:
- full Vendor → Rider → Customer E2E;
- negative/exception paths;
- security regression;
- cross-client status consistency;
- mobile/browser regression;
- performance/health checks;
- hosting/Supabase integration health;
- backup/recovery/rollback readiness;
- no unresolved launch-blocking P0/P1;
- Founder review of UI-visible surfaces.

## 10. Production Readiness
Verify:
- production environment inventory;
- domain/DNS/SSL;
- environment variables/secrets;
- RLS/grants;
- storage policies;
- database migrations;
- backup;
- rollback/forward-fix plan;
- monitoring/alerting;
- analytics where required;
- error reporting;
- rate limits;
- support contacts/process;
- legal/privacy/terms required for launch;
- app/web version behavior;
- deployment runbook.

## 11. External Integration Matrix
Before Go-Live classify each:
**REQUIRED / IMPLEMENTED / PARTIAL / FUTURE / DECISION REQUIRED**

Include:
- auth/OTP provider;
- transactional email;
- Curlec;
- analytics;
- error monitoring;
- maps/geocoding/navigation;
- customer messaging/WhatsApp/SMS;
- external logistics;
- other discovered third-party dependencies.

Listing a provider does not authorize implementation.

## 12. Product Truth Gate
Marketing and pricing pages may only claim:
- LIVE verified capability;
- current approved commercial terms;
- current supported market;
- current availability.

Roadmap/prototype is not launch truth.

## 13. Marketing Launch Gate
Before paid acquisition:
- Product Truth current;
- Claims Registry current;
- Brand Brain current;
- Audience/ICP current;
- landing destination works;
- analytics/UTM attribution adequate;
- CTA matches availability;
- onboarding path works;
- support can handle expected enquiries;
- no campaign promises unavailable product behavior.

## 14. Founder Approval Gates
Explicit Founder approval required for:
- Production deployment/go-live;
- final Malaysia pricing changes;
- activating paid subscription billing;
- material spend/autonomy policy;
- new market/country;
- major paid provider;
- major legal/commercial policy;
- destructive production change;
- public commitment of future capability.

## 15. Go-Live Sequence
1. freeze release candidate;
2. backup/snapshot;
3. verify secrets/environment;
4. apply controlled migrations;
5. deploy backend;
6. deploy clients;
7. smoke tests;
8. real E2E;
9. payment E2E if billing released;
10. monitoring verification;
11. Founder Go-Live approval;
12. controlled traffic/marketing ramp;
13. watch incidents/conversion;
14. rollback if gate fails.

## 16. Rollback
Rollback must define:
- code rollback;
- database forward-fix/rollback policy;
- feature flag/kill switch where available;
- payment disable path;
- marketing pause path;
- incident owner;
- customer/vendor communication path.

Never improvise rollback after incident begins.

## 17. Launch Metrics
Product:
- signup/onboarding completion;
- order creation success;
- dispatch success;
- Rider execution success;
- completion;
- customer tracking errors;
- crash/error rate.

Commercial:
- signup → paid;
- payment success/failure;
- renewal/churn once measurable;
- plan mix;
- COGS;
- support burden.

Growth:
- qualified traffic;
- lead/early-access;
- conversion;
- CAC only when attribution credible;
- retention/LTV only after real cohorts exist.

Do not treat planning assumptions as production metrics.

## 18. Support Readiness
Before meaningful paid traffic:
- support channel;
- issue triage;
- account/billing escalation;
- incident severity;
- response ownership;
- refund/cancellation policy where applicable;
- known-issues log;
- customer-safe status messaging.

## 19. Legal / Privacy / Compliance
Before launch, confirm applicable Malaysian requirements with qualified advice where needed:
- privacy/data processing;
- terms;
- subscription/cancellation;
- tax/accounting;
- marketing/affiliate promotions;
- customer/rider data exposure;
- payment provider obligations.

This MD is product/business governance, not legal advice.

## 20. International Gate
For each future country:
- market audit;
- pricing;
- payment support;
- currency;
- taxes;
- language;
- address/geocoding;
- messaging;
- support;
- privacy/legal;
- Founder approval.

Do not fork the core product unless genuine regulatory/product necessity exists.

## 21. Definition of Done
Cefflo is commercially launch-ready only when product E2E, production security/reliability, current pricing, subscription truth, legal/support basics, analytics and marketing claims all agree—and Founder explicitly approves Go-Live.
