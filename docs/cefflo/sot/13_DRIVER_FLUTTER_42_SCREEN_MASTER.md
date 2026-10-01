**Status:** ACTIVE MASTER — the sole canonical Driver Flutter UI/UX screen-inventory authority, effective 2026-09-14 (see `docs/cefflo/05_DECISIONS.md` D-37). Supplied verbatim by the Founder as `CEFFLO_DRIVER_FLUTTER_UI_UX_MASTER_SOT_v2.md`; content below is unedited except for this provenance header. Like its predecessor, this document is a "WORKING MASTER BASELINE" per its own §0 — it is NOT YET Founder-locked (Definition of Done in §23 is unchecked) and NOT YET IMPLEMENTED (no `pubspec.yaml` for a Driver Flutter app exists anywhere in this repository as of this status line). Do not treat this file as authorizing Driver Flutter implementation to begin.

**Supersession note (2026-09-14, D-37):** this file replaces `docs/cefflo/sot/08_RIDER_FLUTTER_33_SCREEN_MASTER.md` (33 screens, R-01–R-33) as the active Driver/Rider Flutter UI/UX screen-inventory master. That file is now marked SUPERSEDED/HISTORICAL — see its own status line — and remains in the repo for traceability, not deleted. The two documents describe different screen architectures (33 vs 42 screens, `R-##` vs `D##` IDs, different screen lists) — this is a full replacement of the UI/UX authority, not a renumbering of the same inventory. This file's own §21 provides an "Old 36-screen → v2" reconciliation table; that table does not map onto `08_RIDER_FLUTTER_33_SCREEN_MASTER.md`'s R-01–R-33 register (no matching 36-screen `D01`–`D36` document exists anywhere in this repository's git history, any branch, or any prior session's uploads — this was verified by repo-wide search before this supersession, and confirmed by the Founder as the intended predecessor despite the mismatch).

**Terminology scope note — LOCKED (2026-09-14, D-38):** this document's own text names "Cefflo Driver" as the product itself throughout (§1, §13, etc.), not merely a UI/UX surface label. That framing was installed here as supplied at D-37, and is now the **locked, decided** product terminology: "Cefflo Driver" is the permanent user-facing product name. This does not touch, weaken, or reopen the separate, equally permanent backend/schema/API lock: the product/backend/schema/API role stays exactly **"Rider"** — the `riders` table and `rider_vehicle_type` enum are unchanged, and must not be renamed to match this UI product label. The two are intentionally distinct, permanent namespaces, not a pending or partial rename in either direction. See `docs/cefflo/sot/01_PRODUCT_TRUTH.md` §4 for the canonical workforce-terminology statement and `docs/cefflo/05_DECISIONS.md` D-38 for the full decision record (closing the gate first raised at D-28, left open at D-37).

---

# CEFFLO DRIVER FLUTTER — UI/UX MASTER SOT v2

**Status:** WORKING MASTER BASELINE — supersedes the previous 33-screen Rider Flutter screen inventory (`docs/cefflo/sot/08_RIDER_FLUTTER_33_SCREEN_MASTER.md`)
**Product:** Cefflo Driver Flutter Mobile
**Scope:** Driver/Rider mobile application only
**Canonical full-screen count:** **42 screens (D01–D42)**
**Theme:** Light Mode only for current release
**Font:** Manrope
**Primary navigation:** Today / Runs / History / Profile

---

## 0. PURPOSE OF THIS REVISION

This revision supersedes the previous 36-screen Driver screen register because the earlier inventory did not fully model:

- vendor invitation entry;
- invited new driver vs invited existing driver;
- self-registered driver with no vendor/business connection;
- account resolution after opening an invitation;
- business-join acceptance;
- required vehicle/document completion;
- review-before-submit;
- pending vendor review;
- approved/ready transition into operations.

The operational delivery spine, visual doctrine, backend guardrails, and non-marketplace boundary remain intact unless explicitly revised below.

The old 36-screen master remains historical reference only. **v2 is the active UI/UX target.**

---

# 1. MASTER PRODUCT RULE

Cefflo Driver is the dedicated Flutter mobile app for drivers operating **vendor-owned local same-day deliveries**.

It is NOT:

- a rider marketplace;
- a Cefflo-owned rider network;
- an earnings/job marketplace;
- a Vendor administration app;
- a Rider Web/PWA product target.

Core product principle:

> **One screen = one main focus.**

During active delivery, the driver must immediately understand the next required action with minimum reading and interaction.

---

# 2. DRIVER ACCOUNT + BUSINESS CONNECTION MODEL

A Cefflo Driver account and a vendor/business connection are related but different concepts.

A driver may:

1. receive a vendor invitation before having a Cefflo account;
2. receive a vendor invitation while already having a Cefflo account;
3. install Cefflo Driver and create an account before receiving any vendor invitation;
4. return later as an already-connected active driver.

The UI must not force these four cases through one fake linear flow.

## 2.1 Invited new driver

**Vendor invitation → Invitation Landing → Create Account → Accept Business Invitation → Complete Driver Setup → Review & Submit → Pending Vendor Review → Approved → Today**

Rules:

- Invitation context must survive authentication/account creation.
- Invite-bound email/phone may be prefilled where supported.
- Do not ask the driver to create the same account twice.
- Vendor review/approval must never be fabricated.

## 2.2 Invited existing driver

**Vendor invitation → Invitation Landing → Sign In if required → Accept Business Invitation → Complete only missing/required information → Review if required → Pending/Approved → Today**

Rules:

- Existing valid profile/vehicle/document information should be reused where canonical.
- Do not force full onboarding again when data is already complete and accepted.
- Missing, expired, changed, or business-required information may require completion.
- After sign-in, return the driver to the pending invitation context.

## 2.3 Self-registered driver with no vendor invitation

**Splash → Sign Up → Create Account → Driver Setup as allowed → No Business Connected**

The driver may have a Cefflo account without being connected to a business.

The app must NOT show:

- Browse Jobs;
- Find Deliveries;
- Marketplace;
- Earnings opportunities;
- Available Cefflo jobs.

Instead:

> **You're not connected to a business yet.**

The driver waits for or opens a trusted vendor invitation.

## 2.4 Returning active driver

**Splash/session bootstrap → Sign In if needed → Today**

No repeated onboarding unless canonical account/business requirements make it necessary.

## 2.5 Multi-business membership

v2 does **not** assume simultaneous multi-vendor membership or business switching.

Do not design:

- business switcher;
- multi-business roster;
- multiple active vendor contexts;

unless backend/product scope explicitly supports it later.

---

# 3. AUTHENTICATION PRINCIPLES

Authentication is account access. Driver onboarding is operational identity/setup. They must remain separate.

## Create Account minimum account fields

- Full Name
- Email
- Phone Number
- Password
- Password confirmation where required by implementation

Driver-specific operational information belongs in onboarding:

- profile photo;
- vehicle;
- registration/plate;
- licence;
- required documents.

## Invitation-aware auth behavior

If an invite opens while signed out:

- preserve invitation token/context;
- allow Sign In for an existing account;
- allow Create Account for a new user;
- resume the invitation after successful authentication.

If the authenticated account does not match an invite-bound identity constraint, show a clear resolution state rather than silently joining the wrong account.

---

# 4. CANONICAL 42-SCREEN REGISTER

| ID | Screen | Primary responsibility |
|---|---|---|
| D01 | Splash | Cefflo Driver brand entry + session/invite bootstrap |
| D02 | Sign In | Apple / Google / Email entry + Sign Up + language access |
| D03 | Email Sign In | Email + password + Forgot Password |
| D04 | Create Account | Full Name + Email + Phone + Password |
| D05 | Forgot Password | Request password-reset link |
| D06 | Check Your Email | Recovery confirmation + resend |
| D07 | Set New Password | New password + confirm password |
| D08 | Password Updated | Success → Sign In |
| D09 | Invitation Landing | Show vendor/business invitation context before acceptance |
| D10 | Accept Business Invitation | Confirm authenticated driver joining invited business |
| D11 | No Business Connected | Self-registered/unconnected driver state |
| D12 | Driver Details | Photo + full name + phone |
| D13 | Vehicle Information | Motorbike / Car / Van + vehicle details + plate |
| D14 | Driving Licence | Licence details/upload |
| D15 | Required Documents | Vehicle/document upload list and statuses |
| D16 | Review & Submit | Final review of driver + vehicle + documents |
| D17 | Pending Vendor Review | Submitted state; vendor review pending |
| D18 | Approved / Ready | Connection/driver approval success → Today |
| D19 | Today | Availability/operational state + today's assigned work + next action |
| D20 | Assigned Runs | Driver's assigned runs |
| D21 | Run Detail | Run ID, vendor, stops, distance/time, Start Run |
| D22 | Route Overview | Canonical map/route + ordered stops |
| D23 | Active Run | Progress + remaining stops + next stop |
| D24 | Stop Detail | Customer/address/contact/instructions/order summary |
| D25 | Navigation | Destination context + navigation-provider handoff |
| D26 | Delivery Confirmation | Confirm delivery completion |
| D27 | Proof of Delivery | Required photo/recipient/notes |
| D28 | Delivery Issue | Select supported delivery problem |
| D29 | Report Issue Detail | Issue notes/evidence + submit |
| D30 | Run Completed | Completed-run operational summary |
| D31 | Delivery History | Completed runs/deliveries |
| D32 | History Detail | Read-only historical detail |
| D33 | Notifications | Driver operational notifications |
| D34 | Profile | Driver identity / vehicle / documents / settings hub |
| D35 | Edit Profile | Permitted personal/profile edits |
| D36 | Vehicle Details | Current vehicle information |
| D37 | Edit Vehicle | Permitted vehicle changes |
| D38 | Documents | Licence/document status and permitted updates |
| D39 | Settings | Notifications / Language / Security / Help / About |
| D40 | Security | Password/security settings |
| D41 | Help & Support | Help Centre / FAQ / Contact Support |
| D42 | About / Legal | Cefflo Driver / version / Privacy / Terms |

**Canonical total: 42 full screens.**

---

# 5. SCREEN GROUPS + SCREEN SUMMARIES

## 5.1 Brand & authentication — D01–D08

### D01 — Splash
Purpose:
- genuine Cefflo Driver brand moment;
- bootstrap session;
- detect trusted invitation entry where present.

Current visual direction:
- approved cinematic Driver direction is allowed;
- exact canonical Cefflo logo;
- `Driver` product label;
- motorbike + car + van visual direction where Founder-approved;
- concise line such as `Drive. Deliver. Today.`;
- no marketplace/earnings copy.

Do not redraw or AI-invent the production logo asset.

### D02 — Sign In
- Apple;
- Google;
- Email;
- Sign Up entry;
- language access;
- clean focused screen.

### D03 — Email Sign In
- Email;
- Password;
- show/hide;
- Forgot Password;
- primary Sign In CTA.

### D04 — Create Account
Required account fields only:
- Full Name;
- Email;
- Phone Number;
- Password;
- password confirmation if implementation requires it.

Invite-aware behavior:
- prefill invite-bound values where supported;
- preserve invite context after account creation.

### D05 — Forgot Password
- Email;
- Send Reset Link.

### D06 — Check Your Email
- recovery message;
- masked/known email;
- resend;
- open email app where supported;
- return to Sign In.

### D07 — Set New Password
- New Password;
- Confirm Password;
- concise password requirements;
- Update Password CTA.

### D08 — Password Updated
- success state;
- clear return to Sign In.

---

## 5.2 Invitation & business connection — D09–D11

### D09 — Invitation Landing
Purpose: make the vendor invitation explicit before auth/join resolution.

Show:
- `You're invited to join [Business Name]`;
- role = Driver;
- trusted vendor/business identity;
- invited email/phone only where appropriate;
- primary `Continue` / `Accept Invitation`.

Possible routing:
- signed out + existing account → Sign In;
- signed out + new user → Create Account;
- already authenticated → D10.

Do not show:
- jobs marketplace;
- earnings;
- public rider recruitment language.

### D10 — Accept Business Invitation
Purpose: confirm the authenticated account is joining the invited business.

Show:
- business/vendor identity;
- driver account identity;
- Driver role;
- concise explanation;
- `Accept & Join`.

After acceptance:
- complete missing onboarding data if needed;
- otherwise route to review/pending/Today according to canonical backend state.

### D11 — No Business Connected
For a valid Cefflo Driver account that has no trusted business connection.

Show:
- clear empty state;
- explanation that deliveries are provided by the driver's business/vendor;
- `I Have an Invitation` / open trusted invite path where supported.

Do not invent:
- Browse Jobs;
- Find Work;
- Cefflo rider pool;
- earnings marketplace.

---

## 5.3 Driver setup & approval — D12–D18

### D12 — Driver Details
- profile photo;
- full name;
- phone number;
- no unnecessary HR data.

Do not add DOB, gender, IC, home address, or unrelated employment fields without a real product requirement.

### D13 — Vehicle Information
- Motorbike / Car / Van;
- selected state may use light-blue fill + blue outline;
- model where required;
- registration/plate number;
- primary yellow CTA.

### D14 — Driving Licence
- licence photo/document;
- required licence details only;
- upload/validation state;
- no invented government verification claim.

### D15 — Required Documents
Purpose: separate required documents from one overloaded licence screen.

Possible canonical items where required:
- Driving Licence;
- Vehicle Registration;
- Vehicle Photo(s).

Statuses:
- Required;
- Added;
- Needs Update;
- Under Review;
- Approved only where backend says approved.

### D16 — Review & Submit
Final pre-submission review:
- Driver Details;
- Vehicle;
- Licence/Documents;
- small Edit actions;
- one primary `Submit for Review`.

No editable long form on this screen.

### D17 — Pending Vendor Review
Purpose:
- explicitly communicate that submission is waiting for vendor review.

Show canonical statuses only.

No fake:
- approval ETA;
- guaranteed review time;
- fake progress percentage.

If vendor requests changes, this screen may present a supporting `Needs Update` state linking back to the relevant setup screen.

### D18 — Approved / Ready
Purpose:
- successful activation/connection transition.

Recommended copy:
> `You're ready to drive with [Business Name].`

Primary CTA:
- `Go to Today`.

No earnings/incentive language.

---

# 6. CORE DRIVER OPERATIONS — D19–D30

Operational spine:

> **Today → Assigned Run → Run Detail → Route → Active Run → Stop → Navigate → Deliver / Issue → Next Stop → Run Complete**

### D19 — Today
- avatar left;
- notification right;
- no centered repeated Cefflo logo;
- availability/operational status only where backend-supported;
- today's assigned run/work;
- one obvious next action;
- compact progress.

### D20 — Assigned Runs
- Run ID;
- vendor/business context;
- status;
- stop count;
- canonical distance/time where available.

### D21 — Run Detail
- Run ID;
- vendor;
- stops;
- distance;
- estimated duration only where supported;
- primary `Start Run`.

No client-side route resequencing.

### D22 — Route Overview
- map;
- canonical route;
- ordered stops;
- current driver location only where genuinely available.

Flutter must not independently optimize the route.

### D23 — Active Run
- progress;
- delivered/remaining;
- next stop;
- route/map context;
- one obvious primary action.

### D24 — Stop Detail
- customer name;
- address;
- contact action where permitted;
- delivery instructions;
- compact order/item summary;
- stop status.

### D25 — Navigation
- destination;
- navigation context;
- provider handoff where implemented;
- clear return to active run/stop.

### D26 — Delivery Confirmation
- confirm completion;
- only actual proof requirements;
- one clear confirmation action.

### D27 — Proof of Delivery
- photo;
- recipient information;
- notes;
only where required.

Do not collect unnecessary personal data.

### D28 — Delivery Issue
Supported taxonomy only, e.g.:
- cannot reach customer;
- address/access problem;
- delivery cannot be completed;
- other backend-supported issue.

### D29 — Report Issue Detail
- selected issue;
- required notes;
- photo/evidence where relevant;
- Submit.

Flutter must not invent recovery decisions.

### D30 — Run Completed
- completion confirmation;
- stops completed;
- distance/duration only if canonical;
- compact operational summary;
- Return to Today / History.

Never show:
- Total Earnings;
- Base Fare;
- Incentive;
- Paid;
- delivery payout.

---

# 7. ACTIVE-DELIVERY CRITICAL RULE — D23–D29

These are the most operationally sensitive screens.

Mandatory:

1. One obvious primary action.
2. Critical information before secondary detail.
3. Large touch targets.
4. No long forms while driving/delivering.
5. Avoid excessive cards.
6. Avoid tiny metadata.
7. Avoid unnecessary scrolling for the next action.
8. Contact/navigation actions must be immediately understandable.
9. Issue reporting must be fast.
10. Never expose backend terminology.

Locked principle:

> **D23–D29 = one clear primary action + minimum critical information.**

---

# 8. HISTORY & NOTIFICATIONS — D31–D33

### D31 — Delivery History
- completed runs/deliveries;
- date;
- concise completion information;
- filters only when useful.

### D32 — History Detail
- read-only historical run/stop/completion detail;
- historical operational state is not editable.

### D33 — Notifications
- run assignment;
- relevant run/delivery changes;
- issue updates;
- account/system notices.

Preferences belong in Settings.

---

# 9. PROFILE, VEHICLE & DOCUMENTS — D34–D38

### D34 — Profile
- driver photo;
- full name;
- concise identity;
- vehicle;
- documents;
- Settings entry.

### D35 — Edit Profile
Editable where appropriate:
- photo;
- full name;
- phone.

Email/auth identity and controlled role/status remain read-only where applicable.

### D36 — Vehicle Details
- type;
- model;
- registration/plate;
- canonical status/details.

### D37 — Edit Vehicle
- permitted vehicle changes only;
- vehicle change must not bypass vendor review/reapproval rules.

### D38 — Documents
- licence/document list;
- canonical verification/status;
- expiry/update data only where canonical;
- permitted replacement/update flow.

---

# 10. SETTINGS & SUPPORT — D39–D42

### D39 — Settings
- Notification Preferences;
- Language;
- Security;
- Help & Support;
- About / Legal.

Current Driver release remains Light Mode only.

### D40 — Security
- password/change-password path;
- only real security features.

Do not fabricate:
- 2FA;
- biometric auth;
- session/device management.

### D41 — Help & Support
- Help Centre / FAQ;
- Contact Support;
- common Driver topics.

### D42 — About / Legal
- official Cefflo identity;
- `Cefflo Driver`;
- version/build;
- About;
- Privacy Policy;
- Terms of Service.

---

# 11. SUPPORTING STATES — NOT FULL SCREENS

These remain states/components unless explicitly promoted later:

### Authentication
- loading;
- signing in;
- invalid credentials;
- password mismatch;
- connection error;
- rate limit.

### Invitation
- invite expired;
- invite invalid;
- invite already accepted;
- invite revoked;
- existing account detected;
- authenticated account mismatch;
- invitation loading/resolution;
- invitation acceptance failure.

### Driver/business lifecycle
- no business connected inline variants;
- missing required profile data;
- missing/expired document;
- upload progress;
- upload failure;
- submission failure;
- review `Needs Update`;
- rejected/declined state where backend supports it;
- approval refresh/loading.

### Operations
- empty Today;
- empty runs;
- empty history;
- offline banner/state;
- location permission;
- camera permission;
- notification permission;
- GPS unavailable;
- route loading;
- delivery success confirmation;
- issue confirmation;
- generic error/retry;
- logout confirmation;
- confirmation dialogs.

Supporting states do not automatically receive new D-numbers.

---

# 12. ROUTING / JOURNEY MATRIX

## Journey A — invited driver, no account

D01 → D09 → D04 → D10 → D12 → D13 → D14 → D15 → D16 → D17 → D18 → D19

D14/D15 may vary according to actual required documents, but the user must not bypass required backend/vendor requirements.

## Journey B — invited driver, existing account

D01 / deep link → D09 → D02/D03 if signed out → D10

Then:

- if profile incomplete → relevant D12–D16 steps;
- if submission/review required → D17;
- if already approved/valid → D19;
- if newly approved → D18 → D19.

## Journey C — self-register, no vendor

D01 → D02 → D04 → D12/D13/etc. as permitted → D11

When a trusted vendor invitation arrives:

D09 → D10 → complete missing requirements → D16/D17/D18 → D19

## Journey D — returning approved driver

D01 → active session → D19

or:

D01 → D02/D03 → D19

## Password recovery

D03 → D05 → D06 → D07 → D08 → D03

---

# 13. VISUAL SYSTEM

Driver shares the canonical Cefflo visual language with Vendor. Do not create a separate brand.

## Typography
**Manrope**

- Hero / major state: 24–28 px
- Screen title: 20–22 px
- Section title: 16–18 px
- Body / control: 14–16 px
- Supporting / metadata: 12–13 px

Principles:
- compact;
- highly legible;
- strong hierarchy;
- no oversized headings.

## Spacing
Canonical rhythm:
**4 / 8 / 12 / 16 / 24 / 32**

Working horizontal gutter:
**12–16 px**

## Radius
Primary radius family:
**~14 px**

Not every section needs a card.

Prefer:
- cardless sections;
- thin dividers;
- flat lists;
- white surfaces;
- spacing-based grouping.

---

# 14. COLOUR SYSTEM

## Foundation
- Surface: `#FFFFFF`
- Workspace / near-white: `#F7F8FA`

## Primary Cefflo identity
- Anchor Blue / Navy: `#12213E`

Use for:
- structure;
- headings/emphasis;
- selected informational states;
- route/map structure;
- controlled blue surfaces/gradients.

Current controlled gradient direction:
- top `#102344`
- middle `#1B3668`
- bottom `#27427E`

Gradient is selective, not a default background.

## Primary action
- Cefflo Yellow: `#FEC819`

Use for:
- primary CTA;
- important action signal;
- small intentional brand/action accents.

## Semantic
- Success / Available / Online: around `#248648`
- Attention / Error: around `#D73C2B`
- Route / Info: around `#2A6EEC`

Availability/online uses green, not yellow.

Visual priority:
1. White / near-white
2. Anchor Blue / Navy
3. Cefflo Yellow
4. Semantic colors only when meaningful

No Signal Lime.

---

# 15. COMPONENT RULES

## Buttons
- Primary: Cefflo Yellow
- Secondary: restrained neutral/outline
- Destructive: restrained red outline/text
- operational touch targets must be large

## Vehicle selection
Selected:
- light-blue fill;
- blue outline/radio.

Unselected:
- white / neutral.

## Lists
Prefer:
- cardless rows;
- separators;
- clear icon + label + metadata;
- compact but touch-safe spacing.

## Maps
- operational, not decorative;
- canonical route/location only;
- route/info blue;
- no fabricated GPS/ETA/route/location.

## Bottom navigation
**Today / Runs / History / Profile**

---

# 16. LOGO & BRAND USAGE

Use official canonical Cefflo logo assets in implementation.

Never:
- redraw;
- approximate;
- trace;
- AI-invent;
- substitute production logo geometry.

Brand moments:
- Splash;
- About.

Do not repeat the logo on normal operational screens.

---

# 17. PREVIEW / VISUAL REVIEW FORMAT

Current Driver visual-review board rule:

- canvas aspect ratio: **3:4**
- **4 screens per board**
- arrangement: **2 × 2**
- all four phone frames must use the exact same:
  - width;
  - height;
  - aspect ratio;
  - bezel;
  - Dynamic Island size.
- never compress the bottom row;
- never stretch/squash a device;
- screen/page annotation may sit outside the phones at left/right;
- do not place large captions underneath if they force phone-frame compression.

Use actual iPhone 15 proportions inside the presentation system.

When Founder requests a targeted edit, change only the requested elements.

---

# 18. BACKEND & PRODUCT GUARDRAILS

Flutter owns presentation/client state. Canonical operational truth remains backend/API-owned.

The Driver app must not:

- create a second truth source;
- recreate coverage logic;
- recreate zone logic;
- recreate vehicle compatibility;
- recreate capacity rules;
- independently optimize routes;
- independently calculate authoritative ETA;
- perform post-dispatch resequencing;
- fabricate GPS/location;
- fabricate availability;
- fabricate notifications;
- fabricate assignment;
- fabricate recovery eligibility;
- bypass trusted invitation/onboarding;
- silently attach the wrong authenticated account to an invite;
- invent multi-business membership;
- introduce vendor-customer payment/accounting;
- introduce driver earnings/payout marketplace;
- introduce a Cefflo-owned rider network;
- deploy Production without Founder authorization.

Unsupported capability must not be presented as real.

---

# 19. TRUSTED DRIVER ONBOARDING — v2

Canonical model:

> **Vendor shares invitation → Driver resolves/creates account → Driver accepts business connection → Driver supplies required identity/vehicle/document information → Driver reviews/submits → Vendor reviews/approves where required → Driver enters Today.**

Existing account rule:

> **Reuse valid canonical driver information; request only missing/changed/required information.**

Self-register rule:

> **A Cefflo Driver account without a vendor connection does not create marketplace access.**

Vendor rule:

> Vendor does not manually create a complete driver identity as a shortcut.

---

# 20. LIGHT MODE RULE

Current Driver release is **Light Mode only**.

Do not create:
- Dark Mode screens;
- System/Light/Dark selector;
- theme settings;

until explicitly released for Driver.

---

# 21. OLD 36-SCREEN → v2 ID RECONCILIATION

| Old ID | Old screen | v2 target |
|---|---|---|
| D01 | Splash | D01 |
| D02 | Sign In | D02 |
| D03 | Email Sign In | D03 |
| D04 | Create Account | D04 |
| D05 | Forgot Password | D05 |
| D06 | Check Your Email | D06 |
| D07 | Set New Password | D07 |
| D08 | Password Updated | D08 |
| D09 | Driver Setup | D12 Driver Details |
| D10 | Vehicle Information | D13 |
| D11 | Driving Licence | D14 |
| D12 | Setup Complete | split into D16 Review & Submit / D17 Pending / D18 Approved |
| D13 | Today | D19 |
| D14 | Assigned Runs | D20 |
| D15 | Run Detail | D21 |
| D16 | Route Overview | D22 |
| D17 | Active Run | D23 |
| D18 | Stop Detail | D24 |
| D19 | Navigation | D25 |
| D20 | Delivery Confirmation | D26 |
| D21 | Proof of Delivery | D27 |
| D22 | Delivery Issue | D28 |
| D23 | Report Issue Detail | D29 |
| D24 | Run Completed | D30 |
| D25 | Delivery History | D31 |
| D26 | History Detail | D32 |
| D27 | Notifications | D33 |
| D28 | Profile | D34 |
| D29 | Edit Profile | D35 |
| D30 | Vehicle Details | D36 |
| D31 | Edit Vehicle | D37 |
| D32 | Documents | D38 |
| D33 | Settings | D39 |
| D34 | Security | D40 |
| D35 | Help & Support | D41 |
| D36 | About / Legal | D42 |

New v2-only full screens:
- D09 Invitation Landing
- D10 Accept Business Invitation
- D11 No Business Connected
- D15 Required Documents
- D16 Review & Submit
- D17 Pending Vendor Review
- D18 Approved / Ready

The net total becomes **42**, because the old single `Setup Complete` responsibility is decomposed and invitation/business lifecycle is now explicitly modeled.

**Repo-reconciliation note (2026-09-14, D-37):** the table above is the v2 document's own account of what it supersedes, supplied by the Founder. No `D01`–`D36` file matching this "old" register exists anywhere in this repository's git history — this repo's actual predecessor document was `docs/cefflo/sot/08_RIDER_FLUTTER_33_SCREEN_MASTER.md` (33 screens, `R-01`–`R-33`, a structurally different register). The Founder confirmed treating that file as the predecessor to supersede despite the mismatch; see this file's own top-of-document supersession note and `docs/cefflo/05_DECISIONS.md` D-37 for the full record. This table is preserved as supplied for its own internal (D01–D36 → D01–D42) logic and is not a claim that a matching repo file existed.

---

# 22. DESIGN / IMPLEMENTATION WORKFLOW

For each screen batch:

1. Confirm screen purpose against this master.
2. Produce visual preview only for the requested screens.
3. Founder reviews.
4. Apply targeted corrections only.
5. Locked visual becomes presentation SOT.
6. Implementation reproduces the locked visual.
7. Preserve real backend/API wiring.
8. Do not redesign from an older repo baseline.
9. Flag backend/product mismatch instead of faking capability.
10. Run relevant analysis/tests.
11. Founder review before merge/deploy gates.
12. Production requires explicit Founder authorization.

---

# 23. DEFINITION OF DONE

Driver Flutter UI/UX v2 is complete when:

- [ ] D01–D42 each has an approved visual or explicit HOLD/REMOVE decision.
- [ ] Invitation flows support new-account and existing-account drivers coherently.
- [ ] Self-registered unconnected-driver behavior is defined.
- [ ] Invitation context survives auth.
- [ ] Existing drivers are not forced to recreate valid data.
- [ ] Supporting invitation/error states are mapped.
- [ ] Authentication and password recovery are coherent.
- [ ] Driver setup/document/review/approval lifecycle is coherent.
- [ ] Today/Run/Stop operational spine is complete.
- [ ] Delivery confirmation and issue flows are complete.
- [ ] History and notifications are complete.
- [ ] Profile/vehicle/documents are complete.
- [ ] Settings/security/support/legal are complete.
- [ ] D23–D29 follow one-primary-action rule.
- [ ] Light Mode is consistent.
- [ ] Manrope typography is consistent.
- [ ] White → Anchor Blue → Yellow hierarchy is preserved.
- [ ] Green/red remain semantic.
- [ ] No unsupported backend capability is presented as real.
- [ ] No Cefflo rider marketplace/network assumption exists.
- [ ] No earnings/payout UI exists.
- [ ] Official Cefflo assets are used.
- [ ] Old 36-screen route references are reconciled.
- [ ] Final implementation handoff is reconciled.

---

# 24. LOCKED v2 BASELINE

**Total full screens:** 42
**IDs:** D01–D42
**Product:** Cefflo Driver Flutter Mobile
**Primary nav:** Today / Runs / History / Profile
**Theme:** Light Mode only
**Font:** Manrope
**Spacing:** 4 / 8 / 12 / 16 / 24 / 32
**Gutter:** 12–16 px
**Radius:** ~14 px
**Identity:** Anchor Blue / Navy `#12213E`
**Controlled gradient:** `#102344 → #1B3668 → #27427E`
**Primary action:** Cefflo Yellow `#FEC819`
**Success/available:** Green
**Issue/error:** Red
**Preview board:** 3:4 canvas, 4 phones, 2×2, exact equal phone frames
**Doctrine:** Simple, compact, operational, one main focus per screen
**Critical operational rule:** D23–D29 = one clear primary action + minimum critical information
**Invitation rule:** trusted vendor invitation, not public marketplace
**Existing-driver rule:** reuse valid canonical data; do not force duplicate onboarding
**Self-register rule:** account creation does not create delivery-marketplace access

---

**END — CEFFLO DRIVER FLUTTER UI/UX MASTER SOT v2**
