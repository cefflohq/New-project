**Status:** CANONICAL — Founder-approved, merged into repo 2026-09-04
**Repo-reconciliation note:** Canonical behavioural doctrine, more detailed than `docs/cefflo/08_CUSTOMER_TRACKING.md`, which remains valid current-implementation routing detail and is not contradicted by this file.

---

# CEFFLO — CUSTOMER TRACKING & EXPERIENCE SOT
**Status:** Canonical Customer Experience Specification
**Version:** 1.0 — 2026-09-04
**Owner:** Founder
**Scope:** Customer-facing delivery tracking, POD, rating, public-data safety and experience truth.

## 1. Purpose
Define the narrow Customer responsibility in Cefflo so Vendor, Rider, backend, marketing and future Customer UI do not invent competing delivery truth.

Customer Tracking is not a second operations system. It is a safe public projection of canonical delivery state.

## 2. Customer Promise
The customer should be able to answer:
- What delivery is this?
- Which business is delivering it?
- What is its current customer-safe status?
- What genuinely useful timing/progress information is available?
- Has it been delivered?
- Is proof of delivery available?
- Can I rate the completed delivery?

The page must remain lightweight, mobile-first and understandable without operational jargon.

## 3. Access Model
MVP direction:
- no customer account required for tracking;
- access through a high-entropy, unguessable tracking token;
- order ID alone is not authorization;
- token validity/expiry/revocation behavior must be explicit;
- public access must be rate-limited;
- invalid/expired token fails safely;
- no protected operational table is exposed directly to public clients.

Conceptual contract:
`tracking token → customer-safe backend projection → tracking UI`

## 4. Source of Truth
Customer UI reads canonical backend state through a customer-safe API/RPC/projection.

Never derive production status from:
- query-string overrides;
- localStorage;
- hardcoded demo data;
- browser-only state;
- visual animation;
- a separate Customer delivery-state machine.

Vendor, Rider and Customer must observe the same underlying delivery lifecycle, with Customer receiving only audience-safe fields.

## 5. Customer-Safe Information
May include when permitted and genuinely available:
- vendor/store display identity;
- public order/delivery reference;
- delivery date/window;
- customer-safe status;
- progress;
- delivered timestamp;
- audience-safe delay/issue message;
- ETA only when canonical and credible;
- rider display/contact details only under explicit visibility policy;
- POD after eligible completion through controlled access;
- rating eligibility.

Never expose:
- internal business IDs;
- internal audit metadata;
- private customer phone/details beyond what the customer already owns;
- complete rider profile;
- raw rider location history;
- internal exception notes;
- private storage paths;
- other customers/orders/stops.

## 6. Status Doctrine
Customer labels are projections of canonical state, not a separate lifecycle.

Core public milestones may include:
- Preparing / Awaiting delivery where appropriate;
- Picked Up;
- On The Way;
- Delivered;
- audience-safe delay/issue state where necessary.

Exact mapping must be maintained against current backend contract.

Never show Delivered before backend-confirmed completion.

## 7. ETA & Location Truth
ETA/location is optional, not decorative.

Show ETA only when:
- a credible canonical writer exists;
- the value is fresh enough for the context;
- authorization/privacy rules permit it;
- the UI communicates uncertainty appropriately.

Never show a hardcoded/demo ETA as live.

Show rider location/map only when real location data exists, is permitted and is safe to expose. A stylized map is not live tracking.

If ETA/location is unavailable, degrade gracefully rather than fabricate precision.

## 8. POD
Canonical ownership:
Rider captures POD → private Storage stores it → protected backend reference links order/stop/rider/timestamp → Vendor may read → Customer receives controlled/signed access after eligible completion.

Rules:
- private storage by default;
- short-lived signed/protected customer access;
- no reusable raw private path;
- upload failure cannot falsely complete delivery;
- invalid/unrelated object paths rejected;
- privacy-sensitive proof must not be overexposed.

## 9. Rating
Rating is available only when delivery is eligible/completed.

Rules:
- tie submission to valid tracking/order context;
- prevent uncontrolled repeat submissions;
- server-side persistence;
- customer identity not publicly exposed;
- rating cannot mutate delivery truth;
- failures are shown honestly.

## 10. Contact Actions
Vendor/rider contact actions must come from current authorized backend policy, not hardcoded numbers.

Do not expose rider personal contact automatically without explicit product/privacy decision.

## 11. Notification Relationship
Tracking is the canonical destination for customer delivery visibility.

Notifications, if/when implemented, should deep-link to the tracking experience and never claim a state the backend has not confirmed.

WhatsApp/SMS/provider behavior remains capability-gated. UI must not claim "message sent" without provider evidence.

## 12. Error / Empty / Expired States
Required:
- invalid token;
- expired/revoked token;
- delivery not yet available;
- network failure;
- temporary backend error;
- POD unavailable;
- rating already submitted;
- delivery issue/delay with safe wording.

No internal stack traces or sensitive identifiers.

## 13. Privacy & Security
- least public data necessary;
- high-entropy tokens;
- rate limiting;
- safe cache headers appropriate to personal delivery data;
- protected POD;
- no service-role/client secret;
- no raw operational subscriptions for anonymous customer;
- abuse protection on rating/public endpoints;
- logs must avoid leaking tokens or PII unnecessarily.

## 14. Mobile Experience
Primary experience is phone-first:
- fast load;
- clear vendor identity;
- order reference;
- dominant current state;
- readable progress;
- one obvious next customer action;
- accessible contrast;
- resilient narrow viewport;
- no app installation required for basic tracking.

## 15. Truthful Visual Rules
Never visually imply:
- live GPS when map is illustrative;
- exact ETA when estimated data is absent;
- successful POD upload before confirmation;
- successful rating before server response;
- notification delivery without provider response.

## 16. Analytics
Permitted analytics should focus on experience health:
- tracking-page opens;
- token failure rate;
- page load/error rate;
- POD-view success;
- rating eligibility/submission;
- contact-action usage;
- customer-safe status freshness.

Do not turn public tracking into invasive surveillance.

## 17. Cross-Client E2E
Minimum proof:
1. Vendor creates/dispatches canonical delivery.
2. Rider receives correct assignment.
3. Rider progresses canonical states.
4. Customer tracking reflects permitted state.
5. Rider submits POD.
6. Customer sees controlled POD after completion.
7. Customer submits eligible rating.
8. Vendor/backend receives canonical rating.
9. Refresh/retry does not create contradictory state.

## 18. Explicit Non-Goals
Customer Tracking is not:
- customer account portal by default;
- marketplace;
- payment portal;
- vendor-customer payment processor;
- ordinary invoice/receipt module unless separately approved;
- rider-management interface;
- operational admin interface.

## 19. Acceptance Criteria
- valid token returns only permitted data;
- invalid/expired token fails safely;
- status matches canonical Vendor/Rider lifecycle;
- no fake ETA/GPS;
- POD access protected;
- rating constrained and persisted;
- public infrastructure protected from abuse;
- UI remains useful when optional real-time data is unavailable.

## 20. Definition of Done
Customer experience is canonical when one real delivery can move Vendor → Rider → Customer with one shared backend truth, safe public projection, protected POD and real rating persistence—without demo/local-only state.
