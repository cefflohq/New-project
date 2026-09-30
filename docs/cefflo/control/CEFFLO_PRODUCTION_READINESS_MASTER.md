# CEFFLO PRODUCTION READINESS MASTER

**Status:** Canonical — Production Readiness Execution Control  
**Authority:** Execution control for Production Readiness. Does not override Product Truth or higher canonical product/architecture SOTs.  
**Purpose:** Canonical execution control document for moving Cefflo from current staging state through full-stack integration, production readiness, and production launch.

---

## 1. Mission

Cefflo is now entering the **Full-Stack Integration → Production Readiness → Production** phase.

The objective is not merely to “connect the backend.”

Production readiness means every in-scope user-facing surface, screen, interaction, backend read/mutation, authentication flow, communication flow, cross-surface state transition, and critical failure/recovery state works truthfully against canonical backend state and survives end-to-end validation.

A screen existing does not mean it is complete.  
A button existing does not mean it works.  
A successful toast does not prove persistence.  
A frontend restriction does not prove authorization.  
A passing unit test does not prove a real staging journey.

**Production readiness requires evidence.**

---

## 2. Whole-Platform Fleet Rule — Critical

Cefflo moves toward production as **ONE PLATFORM FLEET**.

The program must never be interpreted as “finish Vendor first, then Driver, then Customer, then FOUNDR.” Every execution package must consider **all applicable launch surfaces together**.

Current platform fleet:

| Surface | Architecture |
|---|---|
| Vendor Mobile | Vendor application |
| Vendor Web | Vendor web application |
| Operator Access | Role/access mode through Vendor Mobile and Vendor Web; NOT a separate app |
| Helper Access | Access through Vendor Mobile only; NO Helper Web |
| Driver Mobile | Separate Driver mobile application |
| Customer Tracking | Customer Tracking PWA; no customer login |
| FOUNDR | Platform administration web application |
| Marketing | Marketing surface/PWA where applicable to launch scope |

For every package P1–P8:

1. Identify every applicable surface.
2. Audit all applicable surfaces as one package.
3. Record all package gaps before implementation.
4. Batch implementation/fixes across applicable surfaces.
5. Validate backend persistence and cross-surface truth.
6. Record evidence.
7. Do not mark the platform package VERIFIED while an applicable critical surface remains unresolved.

“Move together” does **not** mean forcing the same feature onto every surface.

Use:
- APPLICABLE
- NOT APPLICABLE
- DEFERRED
- OUT OF SCOPE

Examples:
- Customer Tracking has no user login; do not create one merely to satisfy P1.
- Helper has no Web surface; do not create Helper Web.
- Operator is a role through Vendor surfaces; do not create an Operator app.
- FOUNDR has platform-admin authentication/authorization requirements distinct from Vendor.

---

## 3. Package Completion Model

Every package must report status at two levels:

### 3.1 Surface Status
Example for P1:

| Surface | P1 Status |
|---|---|
| Vendor Mobile | VERIFIED / IN PROGRESS / etc. |
| Vendor Web | VERIFIED / IN PROGRESS / etc. |
| Operator Access | VERIFIED / IN PROGRESS / etc. |
| Helper Access | VERIFIED / IN PROGRESS / etc. |
| Driver Mobile | VERIFIED / IN PROGRESS / etc. |
| Customer Tracking | N/A where appropriate |
| FOUNDR | VERIFIED / IN PROGRESS / etc. |
| Marketing | N/A / applicable status |

### 3.2 Platform Package Status

A package can become **PLATFORM VERIFIED** only when every applicable critical surface has been reconciled and verified.

Example:

> Driver recovery E2E remains unverified → P1 PLATFORM STATUS remains IN PROGRESS even if Vendor and FOUNDR already pass.

No surface may silently be left behind.

---

## 4. Canonical Backend Principle

All applicable surfaces operate against the same canonical business truth.

This does not mean every client shares identical frontend code. It means the platform must not maintain contradictory versions of the same business object.

Example:

**Vendor dispatches an order → Driver receives it → Customer tracks it → FOUNDR observes it**

This is the **same canonical order and delivery state**.

Authorization determines what each role may see or mutate.

All clients are untrusted. Backend authorization remains authoritative.

---

## 5. Status Vocabulary

Use one status vocabulary throughout this program:

| Status | Meaning |
|---|---|
| ⬜ NOT STARTED | Work/evidence not started |
| 🟡 IN PROGRESS | Active reconciliation/implementation/QA |
| 🟢 VERIFIED | Evidence proves required behavior |
| 🔴 BLOCKED | Cannot proceed due to real blocker |
| 🟣 FOUNDER GATE | Founder decision/approval required |
| ⚪ DEFERRED | Explicitly postponed |
| — OUT OF SCOPE | Not part of current launch |

Do not use unsupported completion percentages.

---

# 6. Execution Architecture

The detailed readiness gates are grouped into **8 platform-wide execution packages**, not dozens of isolated sequential tasks.

## P1 — Auth + Communication
Platform-wide authentication, authorization entry flows, auth/security email and communication foundation.

## P2 — Core Backend Wiring
Every applicable screen/action/control connected truthfully to canonical backend behavior.

## P3 — Delivery End-to-End
Prove the complete delivery business journey across Vendor → Driver → Customer Tracking → FOUNDR.

## P4 — Notification System
Event-to-channel architecture, in-app notification truth, messaging/email/WhatsApp scope and delivery evidence.

## P5 — FOUNDR + Control
Real platform administration, operational visibility and control.

## P6 — Security + Reliability
RLS/RPC/authz/security hardening plus failure, retry, offline and resilience behavior.

## P7 — Full QA + Launch Audit
Every screen, interaction, role, device/browser and cross-surface journey validated.

## P8 — Production Cutover
Production infrastructure, migrations, domains, secrets, deployment, smoke tests and launch.

---

# 7. Execution Rounds

Packages may execute in parallel where dependencies allow. Parallelism **does not break the fleet rule**.

| Round | Execution |
|---|---|
| **Round 1** | P1 Auth + Communication + P2 Core Backend Wiring + P4 Notification System + P5 FOUNDR + Control — parallel where safe |
| **Round 2** | P3 Delivery End-to-End after required Round 1 dependencies are ready |
| **Round 3** | P6 Security + Reliability across the integrated platform |
| **Round 4** | P7 Full QA + Launch Audit across all launch surfaces |
| **Round 5** | P8 Production Cutover |

Round 1 worktrees may specialize by package, but each package remains platform-wide.

Before dependent later rounds, outputs must be reconciled into one platform state.

---

# 8. P1 — Auth + Communication

## 8.1 Auth Matrix

Audit applicable flows across:

- Vendor Mobile
- Vendor Web
- Operator Access
- Helper Access
- Driver Mobile
- FOUNDR

Inventory:

- Splash/auth entry
- Sign Up
- Verify Email
- Sign In
- Forgot Password
- Reset Password
- Session persistence
- Session refresh
- Expired session
- Invalid/expired recovery
- Logout
- Invitation claim where applicable
- No-access state
- Authorization after authentication

Authentication and authorization are separate.

A query parameter or UI mode may change presentation but may never grant role authority.

### 8.1.00 FOUNDER FINAL LOCK — V1 AUTH PROVIDERS, APPLE DEFERRED (2026-09-29, supersedes 8.1.0 for Apple)

| Surface | Providers |
|---|---|
| Vendor Mobile Android | Continue with Google · Continue with Email |
| Vendor Mobile iOS | Continue with Email only |
| Vendor Web | Continue with Google · Continue with Email |
| Operator / Helper | inherit the Vendor surface they use |
| Driver Mobile (Android + iOS) | Email only |
| FOUNDR | Google only (Email/password kept as transitional staging access per FG-9 until cutover) |

**Sign in with Apple is DEFERRED / OUT OF V1** on every surface. Consequences: FG-8 (Apple Hide My Email) no longer blocks P1; iOS Guideline 4.8 is not triggered (no third-party login on iOS); Apple token revocation is not needed for V1 deletion. FG-10 (account deletion) moves to **P6** and does not block P1; it remains required before any iOS submission (Guideline 5.1.1(v)).

### 8.1.0 FOUNDER LOCKED — CEFFLO V1 AUTH PROVIDER ARCHITECTURE (2026-09-29, final)

Supersedes 8.1.1 for Driver Mobile. **Vendor = Email + ecosystem provider · Driver = Email only · FOUNDR = Google only.**

| Surface | iOS | Android | Web |
|---|---|---|---|
| Vendor Mobile | Continue with Apple · Continue with Email | Continue with Google · Continue with Email | — |
| Vendor Web | — | — | Continue with Google · Continue with Email (Apple web OUT-OF-SCOPE V1) |
| Operator Access (role via Vendor) | Apple · Email | Google · Email | Google · Email |
| Helper Access (role via Vendor Mobile; no Helper Web) | Apple · Email | Google · Email | — |
| Driver Mobile | **Email only** | **Email only** | — |
| FOUNDR | — | — | **Google only** (no Email, no Apple) |
| Customer Tracking / Marketing | no login | no login | no login |

Driver V1 authentication = Email + password: Sign Up/onboarding per the Driver account architecture, Sign In, Forgot Password, Reset Password, Email Verification, Invitation Claim. NO Google, NO Apple, NO SMS OTP, phone auth, magic link or passwordless in this phase (future evaluation only). Existing Driver Google/Apple buttons that open Email Sign In are FAKE UI TO REMOVE — not providers to configure. Driver Sign In hierarchy: Email · Password · [Sign In] · Forgot password? · invitation/onboarding messaging, reflowed with no empty provider space; no self-service access that bypasses business/rider authorization. Driver invitation identity stays on the canonical email-based claim.

`?access=operator|helper` controls presentation only; Operator and Helper authorization is server-side.

Rationale: no auth parity across surfaces; fewer provider integrations, less account-linking complexity, smaller QA matrix, no Apple private-relay complication for Driver invitations.

### 8.1.1 (SUPERSEDED for Driver by 8.1.0) PLATFORM-SPECIFIC AUTH PROVIDERS (2026-09-29)

Supersedes the earlier requirement that Vendor and Driver expose Email + Google + Apple on every surface. Provider availability is platform-specific by design, not a temporary limitation.

| Surface | Platform | Sign-in options |
|---|---|---|
| Vendor Mobile | iOS | Email · Sign in with Apple |
| Vendor Mobile | Android | Email · Continue with Google |
| Vendor Web | Web | Email · Continue with Google |
| Operator Access | via Vendor surfaces | iOS: Email + Apple · Android: Email + Google · Web: Email + Google (role, not an app) |
| Helper Access | Vendor Mobile only | iOS: Email + Apple · Android: Email + Google · NO Helper Web (role, not an app) |
| Driver Mobile | iOS | Email · Sign in with Apple |
| Driver Mobile | Android | Email · Continue with Google |
| FOUNDR | Web | Google only (no Email, no Apple) |
| Customer Tracking | — | No login |
| Marketing | — | No login |

UI rule: each surface shows only options that work on that platform — no disabled decorative OAuth buttons, no provider button that opens Email Sign In, no fake provider error, no "Coming Soon" provider on production sign-in. Layouts: iOS `[Continue with Apple] [Continue with Email]`; Android and Vendor Web `[Continue with Google] [Continue with Email]`; FOUNDR `[Continue with Google]`.

Apple compliance evidence: see E8–E9 (Section 17.1). The locked matrix does not conflict with Guideline 4.8 (Section 8.8.5).

Backend/server state decides Owner, Operator, Helper, Driver and FOUNDR authority.

## 8.2 Auth/Security Email

Current verified staging foundation:

**Sender:** `Cefflo <no-reply@auth.cefflo.com>`  
**Flow:** Supabase Auth → Resend Custom SMTP → recipient inbox  
**DNS:** Cloudflare DNS only

Known verified evidence:
- `auth.cefflo.com` verified.
- Supabase staging Custom SMTP configured.
- Real FOUNDR password-recovery email delivered.
- Recovery redirect worked.
- Password update succeeded.
- Reopening the same one-time recovery link was correctly rejected.

Do not mark other email types verified without evidence.

Inventory every required auth/security email, including where applicable:
- Verify Email
- Password Reset
- Signup confirmation
- Email-change/security message
- Invitation/claim message

For every communication record:

`EVENT → SENDER → RECIPIENT → TRIGGER → TEMPLATE → CTA → REDIRECT → EXPIRY → RETRY → FAILURE STATE → LOGGING → STAGING QA → PRODUCTION QA`

## 8.3 Support Email

`support@cefflo.com` must be treated as a separate system from auth no-reply.

Do not assume it exists or works until verified.

Determine:
- mailbox provider
- inbound delivery
- reply capability
- routing/ownership
- Reply-To behavior
- support footer usage
- spam protection
- staging/production test evidence

## 8.4 Operational Communication

Inventory all V1 operational communication events against product truth.

Potential events to verify, not assume:
- invitation
- rider/driver assignment
- run dispatched
- pickup/start delivery
- delivery approaching
- customer tracking link
- delivered
- failed delivery / Need Attention
- operational alerts

For each event define:

`EVENT → ACTOR → RECIPIENT → CHANNEL → TRIGGER → BACKEND SOURCE → RETRY → FAILURE HANDLING → LOGGING → USER PREFERENCE → COST`

Do not invent providers.

## 8.5 WhatsApp / Messaging

If WhatsApp remains deferred, state it clearly.

No UI may claim WhatsApp was sent when no provider exists.

If moved into V1, require a Founder Gate for:
- provider
- pricing
- templates
- consent
- phone normalization
- retry/failure handling
- backend architecture
- cost controls

## 8.6 In-App Notifications

Audit:
- event source
- persistence
- unread/read state
- badge/count
- deep link/action
- refresh/realtime behavior
- preferences
- failure state

No fake badge, fake count, fake success toast, or fabricated “sent” state.

## 8.7 Marketing Communication

Marketing communication must remain logically separate from transactional authentication.

If campaigns are in launch scope, define:
- consent
- unsubscribe
- audience/source
- sender identity
- sender reputation
- campaign delivery system


## 8.8 P1 Audit Results — 2026-09-29 (audit only, no fixes applied)

Classification keys: VERIFIED-STAGING (V) · IMPLEMENTED-UNVERIFIED (I) · PARTIAL (P) · MISSING (M) · FAKE · DEFERRED · FOUNDER-GATE (FG) · OUT-OF-SCOPE · N/A. Evidence IDs refer to Section 17.

### 8.8.1 Auth Matrix

| # | Flow | Vendor Mobile | Vendor Web | Operator (VM + VW) | Helper (VM only) | Driver Mobile | FOUNDR |
|---|---|---|---|---|---|---|---|
| 1 | Entry / Splash | I | I | I (`?access=operator`, presentation only) | I (`?access=helper`, presentation only) | I | I |
| 2 | Sign Up (email) | I | I | N/A (invitation) | N/A (invitation) | I (full name + phone in user metadata) | N/A (no sign-up by design) |
| 2b | Google (target: VM Android + VW + FOUNDR; Driver OUT-OF-SCOPE) | Android: P — calls `signInWithOAuth`, provider not configured → provider error; iOS: button must NOT be shown | M (no button) | inherits VM/VW | inherits VM (Android only) | OUT-OF-SCOPE — existing button is FAKE (opens Email Sign In): REMOVE | M — FOUNDR currently Email + password (see FG-9) |
| 2c | Apple (target: VM iOS only; Driver OUT-OF-SCOPE) | iOS: P — calls `signInWithOAuth`, provider not configured; Android: must NOT be shown | OUT-OF-SCOPE | inherits VM (iOS) | inherits VM (iOS) | OUT-OF-SCOPE — existing button is FAKE (opens Email Sign In): REMOVE | OUT-OF-SCOPE |
| 3 | Email verification | P: Verify / Verified / Expired screens exist; confirm deep link emits `signedIn` but the root widget has no `setState` for it | I (verify + resend) | N/A | N/A | M: no Verify screen, error line only; no resend | N/A |
| 4 | Sign In (email/password) | I | V (E2) | I | I | I (email or phone) | V (E1) |
| 5 | Forgot Password | I | V (E2) | I | I | I | V (E1) |
| 6 | Reset Password | P: native reset never completed on staging (E3) | V (E2) | P | P | P: never completed (E3) | V (E1) |
| 6b | Invalid / expired link | M: link errors are not routed to Link Expired | I | as parent | as VM | M | V (E1, second use rejected) |
| 7–9 | Session create / persist / refresh | I (supabase_flutter) | I (manual refresh on 401) | as parent | as VM | I (supabase_flutter) | I (manual refresh) |
| 10 | App / browser reopen | I | I | I | I | I | I |
| 11 | Expired session | I | I (401 → Sign In) | I | I | I | I |
| 12 | Logout | I | I (`/auth/v1/logout` + clear) | I | I | I | I |
| 13 | Invitation claim | I (`claim_my_team_invitations`) | I | I | I | I (`claim_my_rider_invitations`) | N/A |
| 14 | Role resolution | I (`get_my_businesses`) | I (Helper-only → signed out with message; no Helper Web) | I | I | I (rider relationships) | I (`is_platform_admin`) |
| 15 | No-access state | I (no business → setup; Operator/Helper entry → no-access copy) | I (Operator no-access screen) | I | I | I (no business → onboarding) | V (Access denied) |
| 16 | Cross-business protection | I (RLS; depth owned by P6) | I | I | I | I | N/A |
| 17–20 | Operator / Helper / Driver / FOUNDR authority | server-decided (E5) | server-decided | I | I | I | I |

Backend facts (E5): claim RPCs require `email_confirmed_at` and use `auth.uid()`; all auth/role RPCs are SECURITY DEFINER; anon may execute only `resolve_*` / `consent_*` invitation RPCs. `?access=` never grants a role.

### 8.8.2 Communication Matrix

| Item | Status | Evidence / note |
|---|---|---|
| Auth sender `Cefflo <no-reply@auth.cefflo.com>` | V | Resend DKIM + `send.auth` SPF/MX live (E6); FOUNDR + Vendor Web recovery delivered (E1, E2) |
| Password Reset email | V (FOUNDR, Vendor Web) | E1, E2 |
| Confirm Signup / Verify Email | I | Last confirmation sent 2026-09-28, before Custom SMTP; not sent via Cefflo sender yet |
| Resend verification | I (VM, VW); M (Driver: static disabled "Resend email (58s)") | code |
| Email change / security notifications | M / unused | 0 email-change sends |
| GoTrue invite email | N/A | Invitations use Cefflo Invitation PWA links |
| Invitation delivery to invitee | P | Link shared manually by vendor; no send |
| Templates, Site URL, link expiry, rate limits | FG (FG-1, FG-2) | Not readable with current tools; Site URL proven `http://localhost:3000` (E4) |
| DMARC | M | none on `cefflo.com` / `auth.cefflo.com` (E6) |
| `support@cefflo.com` | M | `cefflo.com` has no MX (E6); address shown in Vendor Web Help |
| Vendor Mobile V-57 Contact Support | FAKE | `action: () async {}` then "Your support request has been sent."; demo address prefilled |
| In-app notifications | I | `notifications` + preferences + realtime on staging (`202609290001`); not E2E-verified |
| Push (FCM/APNs/Web Push) | DEFERRED | no provider |
| WhatsApp / SMS | DEFERRED | no provider; existing WhatsApp controls are user-initiated `wa.me` links; no UI claims a message was sent |
| Rider approval "we'll notify you" | I | backed by in-app `rider.approved` |
| Customer operational messages | DEFERRED | tracking link shared manually |
| Marketing / Website | N/A for auth | static, no login |

### 8.8.3 P1 Gaps by Root Cause

| ID | Root cause | Gaps | Class |
|---|---|---|---|
| G1 | Staging Auth config | Site URL `localhost:3000`; QA harness URLs not allowlisted; templates/expiry/rate limits unverified | FG-1, FG-2 |
| G2 | Mobile auth-callback handling (shared VM + Driver) | native recovery never completed (E3); link errors not routed to Link Expired; `signedIn` from deep link does not rebuild root | P / M |
| G3 | Driver verification UX | no Verify Email screen; fake static resend | M / FAKE |
| G4 | Support channel | `support@` has no mailbox; V-57 fake success | M / FAKE |
| G5 | Email-domain auth | no DMARC | M (FG-6) |
| G6 | Unverified journeys | sign-up/verify via Cefflo sender; invitation claim E2E (Operator/Helper/Driver); logout/reopen/expiry E2E | I |
| G7 | Vendor social auth incomplete; Driver fake OAuth UI | Final (8.1.0): VM iOS Apple REQUIRED + Google NOT SHOWN; VM Android Google REQUIRED + Apple NOT SHOWN; VW Google REQUIRED, Apple OUT-OF-SCOPE; Operator/Helper inherit Vendor; Driver Email only, Google/Apple OUT-OF-SCOPE; FOUNDR Google REQUIRED, Email/Apple OUT-OF-SCOPE. Today: VM providers unconfigured and shown on both platforms; VW/FOUNDR no Google; Driver Google/Apple buttons FAKE → REMOVE (not configure) | FG-5 (LOCKED 8.1.0) |
| G8 | Canonical state | all P1 work on `claude/notification-system`, not `main` | FG-7 (HOLD) |

### 8.8.5 Apple Compliance Check (for FG-5)

- **Guideline 4.8 (Login Services)** — E8: applies only when an app uses a third-party/social login (e.g. Google Sign-In) for the primary account; such apps must also offer an equivalent privacy-preserving login (name + email only, private email option, no ad tracking without consent). The locked iOS apps offer Email + Sign in with Apple and no third-party login, so 4.8's additional-option requirement is not triggered; Sign in with Apple itself satisfies those features. **No conflict** with the locked architecture.
- **Guideline 5.1.1(v)** — E9: apps that support account creation must offer account deletion within the app; apps using Sign in with Apple should revoke user tokens via the Sign in with Apple REST API on deletion. Neither Vendor Mobile nor Driver Mobile has in-app account deletion today (code search, no `delete account` flow or RPC). This is not a provider-matrix conflict but a **mandatory iOS submission gap** → FG-10.

### 8.8.6 Identity / Account-Linking Inspection (for FG-5)

| Topic | Current backend truth | Risk / plan |
|---|---|---|
| Existing identities | staging `auth.identities`: 120 × `email`, 0 social (E10) | No linked accounts exist yet |
| Email user → Google / Apple, same verified email | Supabase Auth links a new OAuth identity to an existing user with the same verified email (platform behaviour; to be confirmed on staging in Batch E before release) | Must be proven: same `auth.users.id`, memberships intact |
| Duplicate-account prevention | Relies on Supabase automatic identity linking by verified email; no custom merge exists | No custom merging without Founder approval |
| Invitation claim (Operator, Helper, Driver) | `claim_my_team_invitations` / `claim_my_rider_invitations` match `lower(auth.users.email)` of the confirmed caller to `invited_email` (E5, migration `202609280002`) | Works for Google/Apple when the provider email equals the invited email |
| Apple Hide My Email (private relay) | Provider email becomes `…@privaterelay.appleid.com`; it cannot equal the invited email | **Claim silently finds nothing → Operator/Helper/Driver lands in no-access.** Backend identity-rule change required to fix → **FG-8, STOP** |
| FOUNDR Google-only | FOUNDR today is Email + password (`/auth/v1/token?grant_type=password`), gated by `is_platform_admin()` on `platform_admins` | Moving to Google-only changes FOUNDR auth; admin access survives only if the Google identity links to the same user (same email) → **FG-9** |

### 8.8.4 Dependencies

- G2 native E2E needs a real Android/iOS build on device and FG-1 redirect set.
- G6 sign-up E2E needs FG-2 templates/config.
- G4 needs FG-3 mailbox provider.
- G7 (Vendor) needs Google Cloud (Web client; Android client only for a native flow) and Apple Developer (Services ID, key) credentials, plus FG-8 (Apple private relay vs Operator/Helper email claim) and FG-9 (FOUNDR Google-only vs current Email+password). Driver needs no provider credentials.
- iOS submission additionally needs in-app account deletion with Sign in with Apple token revocation (FG-10, Guideline 5.1.1(v)).
- P1 PLATFORM VERIFIED needs all surfaces evidenced, then FG-7.


## 8.9 P1 Implementation Plan (proposed 2026-09-29 — NOT STARTED, awaiting Founder authorization)

Batches follow Founder decisions FG-1…FG-7 (Section 16). Values marked *proposal* must be confirmed against the live dashboard before being applied; nothing here has been applied.

| Batch | Scope | Surfaces | Files / config | Depends on | Founder action | Tests | Staging evidence | Rollback | Owner |
|---|---|---|---|---|---|---|---|---|---|
| A — Staging Auth config | Site URL off localhost; one clean Redirect URL set (Section 8.9.1) | All authenticated surfaces | Supabase Dashboard → Auth → URL Configuration (no repo files) | — | Approve exact set; apply in dashboard (or authorise agent) | — | `/recover` from each origin resolves to its own redirect, never localhost | Re-enter previous list (captured before change) | Founder / config |
| B — Auth email templates + config | Branded Confirm Signup, Reset Password, Change Email; subjects; link expiry; secure email change; email rate limit (8.9.2) | All authenticated surfaces | Dashboard → Auth → Emails / Rate Limits; repo copy `supabase/templates/*.html` + `supabase/config.toml` for local parity | A | Approve copy + values | template render check; local Supabase mail (Inbucket) | real sign-up confirm + reset + email change through `no-reply@auth.cefflo.com` | restore default template text (captured before change) | W-config |
| C — Shared mobile auth callback | Root listener: rebuild + `loadSession` on `signedIn` from a link; route link errors (expired/used) to Link Expired; confirm recovery path on device | Vendor Mobile (+ Operator, Helper), Driver Mobile | `apps/vendor_mobile/lib/main.dart`, `.../ui/screens/auth.dart`; `apps/rider_mobile/lib/main.dart`, `.../ui/screens/auth.dart` | A | — | widget tests: `signedIn`, `passwordRecovery`, link error → expected screen | device: reset link → Set New Password → `PUT /user` 200 → sign-in; used link → Link Expired | revert commit | W1 `p1-mobile-auth` |
| D — Driver Email-only auth + Verify Email | Remove FAKE Google/Apple buttons and reflow Sign In (Email · Password · Sign In · Forgot); Verify Email screen with real resend, real cooldown, loading/success/rate-limit/error, invalid and expired link handling, confirmation transition; remove static "Resend email (58s)" | Driver Mobile | `apps/rider_mobile/lib/{ui/screens/auth.dart,core/routes.dart,data/rider_repository.dart,main.dart,l10n/*}` | B (template), C | — | widget tests: no provider buttons; sign-up → Verify Email; resend calls backend; cooldown; link error → expired state | sign-up → email → confirm → signed in; resend delivered; expired link handled | revert commit | W1 (AUTHORIZED) |
| E — Vendor social auth | E1 Google: Vendor Mobile Android, Vendor Web. E2 Apple: Vendor Mobile iOS. Operator/Helper inherit Vendor. Excluded: Driver, Customer Tracking, Marketing; FOUNDR only if its Google sign-in needs completion/verification (FG-9) | VM, VW, Operator, Helper | Supabase Auth providers (Google, Apple); VM auth screen (platform-conditional buttons); `vendor_repository.dart`; `apps/vendor_web/js/{api.js,pages/auth.js}` | A; credentials; FG-8 (FG-10 before iOS submission) | Google Cloud Web client; Apple Developer Services ID + key; FG-8 decision | per-platform button visibility; provider call + redirect | per platform/provider: new Owner, existing email Owner (same `auth.users.id`), invited Operator/Helper claim, Apple private relay | disable provider; revert commit | W1 (VM) + W2 `p1-web-auth` (VW) — NOT AUTHORIZED |
| F — `support@cefflo.com` | Real mailbox: provider, MX, SPF/DKIM for `cefflo.com`, reply capability, routing/ownership | Support (VW Help, VM V-57) | DNS `cefflo.com` (MX, SPF, DKIM); provider admin | Provider decision | Choose + purchase provider; approve DNS records | — | external → support inbound; support → external reply; headers show SPF/DKIM pass | remove MX / provider records | Founder / W-config |
| G — V-57 Contact Support | Replace fake success with real hand-off to the FG-3 channel (compose to `support@cefflo.com` with subject + business/app context); remove demo prefill; no fabricated "sent" | Vendor Mobile | `apps/vendor_mobile/lib/ui/screens/prototype.dart` (V-57), l10n | F (mailbox live for QA) | Confirm treatment of the screenshot-attachment area (mail compose cannot pre-attach) | widget test: no success state without a real hand-off | message reaches support inbox | revert commit | W1 |
| H — DMARC / domain hardening | DMARC monitoring for `cefflo.com` + `auth.cefflo.com` (8.9.3) | Email deliverability | DNS TXT `_dmarc.cefflo.com`, `_dmarc.auth.cefflo.com` | F for report mailbox (or external report address) | Approve exact records; apply in Cloudflare | — | `dig` shows records; aggregate reports received | delete TXT records | Founder / W-config |
| I — Full P1 staging E2E | Auth + communication matrix run on every surface; evidence into Section 17 | All | none (evidence only) | A–H | Device access (Android/iOS), test inboxes | — | per-flow Auth log IDs, screenshots, DB reads | n/a | W-QA |

### 8.9.1 Batch A — proposed final URL set (FG-1)

- Site URL *proposal*: the stable Vercel branch alias of the staging integration branch, Vendor Web root: `https://new-project-git-claude-notific-b5ee9a-cefflohq26-6353s-projects.vercel.app/web/`. Preferred long-term: a dedicated staging domain (e.g. `staging.cefflo.com`) mapped to that branch — requires a Founder DNS/Vercel domain decision.
- Redirect URLs *proposal* (complete list; everything else removed):
  - `https://new-project-git-claude-notific-b5ee9a-cefflohq26-6353s-projects.vercel.app/**` (Vendor Web `/web/`, FOUNDR `/foundr/`)
  - `cefflo-vendor://auth-callback`
  - `cefflo-driver://auth-callback`
  - `https://cefflo-vendor-app-staging.vercel.app/**` (QA HARNESS)
  - `https://cefflo-driver-app-staging.vercel.app/**` (QA HARNESS)
- Remove: `http://localhost:3000` and any per-deployment preview entries. The current list must be read from the dashboard before the change (not readable with agent tools) so removals are explicit.

### 8.9.2 Batch B — proposed auth email configuration (FG-2)

| Setting | Proposal | Basis |
|---|---|---|
| Sender | `Cefflo <no-reply@auth.cefflo.com>` | verified (E6) |
| Templates in use | Confirm signup, Reset password, Change email address; Invite / Magic link / Reauthentication unused (keep branded minimal) | client code uses signup, recovery, resend-signup only |
| Link format | keep `{{ .ConfirmationURL }}` | matches current client flows (implicit for web JS, PKCE for Flutter); `token_hash` would require client changes |
| Branding | Cefflo logo, one CTA, plain fallback URL, no marketing, footer `support@cefflo.com` once F is live | Master 8.7, auth email setup task |
| Link expiry | *proposal* keep 3600 s (1 h) — current value to be read from dashboard | security/usability balance |
| Secure email change | *proposal* ON (confirm on both addresses) | security |
| Email rate limit | *proposal* staging 30/h; production sized to the Resend plan quota (Founder to confirm plan) | avoid 429 during QA without exceeding provider quota |
| Redirects | per Batch A | FG-1 |

### 8.9.3 Batch H — proposed DMARC records (FG-6)

| Name | Type | Value (*proposal*) |
|---|---|---|
| `_dmarc.cefflo.com` | TXT | `v=DMARC1; p=none; rua=mailto:dmarc@cefflo.com; fo=1; adkim=r; aspf=r` |
| `_dmarc.auth.cefflo.com` | TXT | `v=DMARC1; p=none; rua=mailto:dmarc@cefflo.com; fo=1; adkim=r; aspf=r` |

`rua` needs a receiving mailbox (depends on F) or an external report address. Alignment: Resend DKIM `d=auth.cefflo.com` aligns with From `auth.cefflo.com`. Progression after 2–4 weeks of clean reports: `p=quarantine`, then `p=reject`. `cefflo.com` SPF/DKIM are defined in F with the chosen mailbox provider.

### 8.9.5 Batch E — VENDOR SOCIAL AUTH (supersedes previous Batch E; NOT AUTHORIZED)

**E1 — Google:** Vendor Mobile Android and Vendor Web only (Operator/Helper inherit). Supabase Google provider (Web client ID + secret, callback `https://tomvvmwktehexwhktenw.supabase.co/auth/v1/callback`). VM Android: browser OAuth to `cefflo-vendor://auth-callback`, button on Android only. VW: `/auth/v1/authorize?provider=google&redirect_to=<current page>`, parsed by `consumeAuthFragment`. Not on iOS, not on Driver.

**E2 — Apple:** Vendor Mobile iOS only (Operator/Helper inherit). Supabase Apple provider (Services ID, Team ID, Key ID, .p8; secret ≤ 6 months). Sign in with Apple capability on the Vendor iOS App ID; button on iOS only. Not on Vendor Web, Android, Driver or FOUNDR.

**Excluded:** Driver Mobile (Email only; fake buttons removed in Batch D), Customer Tracking, Marketing; FOUNDR unless FG-9 requires Google completion/verification.

### 8.9.6 P1 QA Matrix (provider scope per 8.1.0)

| Surface | Required QA | Not tested (out of scope) |
|---|---|---|
| Vendor iOS | Email; Apple | Google |
| Vendor Android | Email; Google | Apple |
| Vendor Web | Email; Google | Apple |
| Operator | applicable Vendor provider per platform; invitation claim; server-side role resolution; no-access | providers outside Vendor matrix |
| Helper | applicable Vendor Mobile provider; invitation claim; server-side role resolution; no-access | Web; providers outside matrix |
| Driver | Email Sign Up/onboarding; Verify Email; Sign In; Forgot; Reset; session persistence; session expiry; logout; invitation claim; Driver authorization; no-access | Google; Apple |
| FOUNDR | Google; platform-admin authorization; recovery/session per current architecture (FG-9) | Email, Apple (after FG-9) |

Each provider case: new account, existing email account keeps the same `auth.users.id`, sign-out/reopen.

### 8.9.4 Execution order

1. Founder: A (URL set) + B values + H records review; start F provider choice and E credentials in parallel.
2. W1 `p1-mobile-auth`: C → D (single worktree, mobile auth files only).
3. F live → G (W1) and H applied.
4. E (Vendor only) once credentials exist, FG-8/FG-9 are decided and E is authorized (W1 VM, W2 VW); FG-10 before any iOS submission.
5. I full platform E2E → evidence → P1 PLATFORM VERIFIED → FG-7 merge decision.

No batch touches migrations or RLS.


## 8.10 FG-8 — Apple Hide My Email: Identity Architecture Note (analysis only, 2026-09-29)

**Status:** analysis for Founder decision. No backend, schema, RLS or Auth-config change is authorized or made. Invitation email matching is NOT weakened. A private relay address is NOT treated as the same identity as any other email. No custom merging.

### 8.10.1 Verified facts

| # | Fact | Source |
|---|---|---|
| F1 | Supabase Auth automatically links identities with the same email to one user, only when the email is verified; when it links, it removes other unconfirmed identities of that user | Supabase docs "Identity linking" (fetched 2026-09-29), E11 |
| F2 | Manual linking (`linkIdentity()`) links an OAuth identity with a different email to the signed-in user; it must be enabled (`GOTRUE_SECURITY_MANUAL_LINKING_ENABLED` / dashboard) and requires the user to be signed in | same, E11 |
| F3 | Unlinking needs a signed-in user with at least 2 identities | same, E11 |
| F4 | Supabase Auth does not store provider tokens (`provider_token`, `provider_refresh_token`); the app must send them to a trusted server if needed later | Supabase docs "Social login" (fetched), E12 |
| F5 | Private relay addresses route to a verified Apple Account address; are identical across all apps of one developer team; carry a limit of 100 emails/day; can be managed/stopped by the user in Settings → Sign in with Apple; when the user stops forwarding, the relay rejects all future email | Apple "Communicating using the private email relay service" (fetched), E13 |
| F6 | To send to relay addresses, outbound emails/domains must be registered with Apple and authenticated with SPF | same, E13 |
| F7 | Invitation claims (`claim_my_team_invitations`, `claim_my_rider_invitations`) match `lower(trim(auth.users.email))` of the confirmed caller to `invited_email`; token acceptance (`accept_*_invitation`) exists server-side | migrations `202609280001/2`, E5 |
| F8 | Staging has 120 identities, all `email` | E10 |

### 8.10.2 Scenario analysis

| Scenario | What happens with the current architecture | Risk |
|---|---|---|
| Existing Vendor Owner (email account) → Apple, sharing real email | Apple identity auto-links to the existing user if that email is verified (F1) | Low; must be proven in Batch E |
| Existing Vendor Owner → Apple with Hide My Email | Relay address ≠ account email → **new, separate user**; no business, lands in Business Setup; could create a second business | **Duplicate account / duplicate business** |
| New Vendor Owner → Apple with Hide My Email | New user with relay email; works; all auth email (reset, notices) goes via relay (F5) | Relay must be registered (F6); if user stops forwarding, email recovery is lost (see recovery) |
| Operator invitation → Apple with Hide My Email | Claim compares relay email to invited email → no match → **no-access** | Invitee stuck; not a security hole (fails closed) |
| Helper invitation → Apple with Hide My Email | Same as Operator → no-access | Same |
| Driver | Driver is Email only (8.1.0) → not affected | None |
| Password recovery for an Apple-only user | No password exists; "Forgot password" does not apply; access is via Apple. Email reset links would go to the relay | Losing Apple ID access = losing Cefflo access unless another identity is linked |
| User stops relay forwarding | Cefflo can no longer email the user (security notices, receipts); login via Apple still works | Silent loss of communication channel |
| Account deletion (Apple user) | Needs Apple token revocation (FG-10 §8.11.5); Supabase does not hold Apple tokens (F4) | Revocation needs a token captured at sign-in or the manual path |

Security implications: the current design fails closed (a non-matching relay email never gains a membership). Any model that lets a relay-email user claim an invitation must bind to something the inviter controls (the invitation token) or to a verified real email — never to a name, phone or unverified claim.

### 8.10.3 Safe solution models (Founder to choose; none chosen or implemented)

| Model | How it works | Pros | Cons / work |
|---|---|---|---|
| **M1 — Real email required for invited roles and existing accounts** | Keep email-based claim. Operator/Helper invitations and existing Owners are told (Invitation PWA + sign-in copy) to share their real email with Apple or use Continue with Email. New Owners may use Hide My Email freely | No backend change; strongest invitation binding; simplest | UX friction; relies on the user choosing correctly; wrong choice still yields no-access (fails closed) and a possible duplicate Owner account |
| **M2 — Token-bound claim at acceptance** | The invitee signs in first (any provider, including relay), then accepts with the invitation token; the server binds the membership to `auth.uid()` via the existing `accept_*_invitation` token path instead of email equality | Works with Hide My Email; binding is to the secret token the inviter sent | Backend identity-rule change (Founder gate); token possession becomes the proof, so token handling, expiry and single use must be airtight; the invited email is no longer verified to match |
| **M3 — Manual identity linking** | Enable manual linking (F2). A signed-in email user links their Apple identity (with relay) from Settings; invitations and Owner accounts stay email-bound | No duplicate accounts for users who link; keeps email matching intact | Requires enabling a Supabase Auth setting; linking UI; does not help a brand-new invitee who only has Apple |

M1 can ship alone; M3 can complement M1 or M2. Duplicate Owner accounts are only prevented by M3 (or user choice under M1).

---

## 8.11 FG-10 — Account Lifecycle / Deletion Impact Audit (analysis only, 2026-09-29)

**Status:** analysis for Founder decision. No deletion code, schema or RLS change. "Delete account" must never mean "delete business" unless explicitly decided; Owner identity lifecycle and Business lifecycle are separate.

### 8.11.1 Verified data model (staging schema, E14)

`auth.users` deletion today would:
- **CASCADE:** `profiles`, `business_members` (membership rows), `notifications`, `notification_preferences`, `platform_admins`, auth sessions/identities/tokens.
- **SET NULL (row kept, actor unlinked):** `riders.auth_user_id`, `orders.approved_by`, `delivery_sessions.sorting_started_by`, `delivery_stops.{ready_by, pod_submitted_by, packed_by, packing_confirmed_by, preparation_updated_by, sorted_by}`, `delivery_events.actor_user_id`, `business_profile_audit.actor_user_id`, `admin_audit_log.admin_user_id`, `team_invitations.accepted_by`, `rider_invitations.accepted_by`, `delivery_outsourcing.*_by`, `business_subscriptions.updated_by`, platform/admin tables' `*_by`.
- **RESTRICT (deletion fails):** `team_invitations.invited_by`, `rider_invitations.invited_by`, `helper_workers.invited_by` → **any user who ever sent an invitation cannot be deleted** without first handling those rows.

Business ownership is **only** `business_members.role = 'owner'` (`businesses` has no owner column); roles are `owner, operator, helper`. No trigger protects the last Owner. 15 staging businesses already have more than one Owner. `businesses` deletion cascades orders, stops, events, riders, zones, invitations, subscriptions, products, media, public pages, notifications. 2 staging Driver accounts are linked to more than one business (`riders` row per business). Storage buckets: `cefflo-pod` (private), `cefflo-product-originals` (private), `cefflo-product-display` (public).

Personal data columns: `profiles.{display_name, phone}`, `riders.{name, phone, vehicle_plate}` + `rider_locations`, `helper_workers.{display_name, contact}`, `rider_invitations.{invited_email, invited_name, invited_phone}`, `team_invitations.invited_email`, `businesses.{name, phone, email, address}` (business, not person), `orders.{customer_name, customer_phone, delivery_address, notes}` (customer data, business-owned), `ratings.feedback`, `delivery_stops.pod_note` + POD objects, `delivery_outsourcing.{contact, driver_name}`, JSON `metadata` in `delivery_events` / `admin_audit_log`.

### 8.11.2 Impact by role

| Area | A. Vendor Owner | B. Operator | C. Helper | D. Driver |
|---|---|---|---|---|
| auth user / profile | delete / delete | delete / delete | delete / delete | delete / delete |
| Membership | removed (cascade) | removed | removed | n/a (`riders` rows) |
| Business ownership | **must be resolved first** (see 8.11.3) | none | none | none |
| Orders / runs / stops / events | business-owned; retained; actor columns SET NULL | same | same | business-owned; retained; `rider_id` kept on anonymized rider row |
| Assignments / delivery history | retained (business record) | retained | retained | retained against anonymized `riders` row |
| Ratings | n/a | n/a | n/a | retained (rider-linked); `feedback` is customer text, business-owned |
| POD | n/a | n/a | n/a | photos are delivery evidence (business record); retention decision needed |
| Live location | n/a | n/a | n/a | `rider_locations` → delete |
| Notifications / prefs | delete (cascade) | delete | delete | delete |
| Audit logs | retain, actor unlinked | retain | retain | retain |
| Invitations sent | **blocks deletion (RESTRICT)** → reassign/anonymize `invited_by` | same if they invited | n/a | n/a |
| Invitations received | `invited_email` → anonymize after acceptance | same | same | `invited_email/name/phone` → anonymize |
| Subscriptions | business-level; not deleted with the person | n/a | n/a | n/a |
| Apple revocation | if Apple-linked | if Apple-linked | if Apple-linked | n/a (Email only) |

Classification: **delete** — auth user, identities, sessions, profile, notifications, preferences, live locations, device/local data. **Anonymize** — `riders` name/phone/plate, invitation contact fields, `helper_workers` contact, personal names inside JSON metadata. **Retain (business/legal/operational)** — orders, stops, events, assignments, ratings, audit logs, POD (subject to a retention period decision). Legal retention periods are a Founder/legal decision (not determined here).

### 8.11.3 Owner deletion vs Business lifecycle

- If another Owner exists → remove only this Owner's membership; business continues.
- If sole Owner → deletion must be **blocked until** the Owner either transfers ownership (promote an Operator/another member to Owner) or separately and explicitly chooses **Close business** (a distinct, confirmed business-lifecycle action with its own retention rules). Deleting the auth user alone today would leave an ownerless business (cascade removes the only owner membership).

### 8.11.4 Proposed deletion architecture (not implemented)

User requests deletion → re-authentication/confirmation (fresh sign-in; typed confirmation) → server pre-checks (sole-Owner block; sent-invitation rows) → **Apple authorization revoked where applicable** → Cefflo identity lifecycle (single server-side RPC/Edge Function with service role, idempotent, audited) → personal data deleted/anonymized per 8.11.2 → operational records retained with actor unlinked → memberships removed → sessions invalidated (all devices) → confirmation shown in-app (and by email if a deliverable address exists) → client returns to signed-out state and clears local data.

### 8.11.5 Apple token revocation (Vendor Apple users; Driver not applicable)

- Endpoint `POST https://appleid.apple.com/auth/revoke` with `client_id` (App ID / Services ID), `client_secret` (JWT signed with the Sign in with Apple key), `token` (refresh or access token), `token_type_hint` (E15).
- Supabase does not store Apple tokens (F4) → Batch E must capture a refresh token (or authorization code) at Apple sign-in and store it server-side, encrypted, for later revocation; or use Apple's manual path: delete account data, direct the user to revoke in Apple ID settings, and handle the credential-revoked notification (TN3194, E15).
- If revocation is skipped, a returning user is not shown the initial Apple authorization again (TN3194).

### 8.11.6 Backend areas eventually affected

New deletion RPC/Edge Function (service role); `invited_by` RESTRICT handling on `team_invitations`, `rider_invitations`, `helper_workers`; sole-Owner guard and ownership transfer on `business_members`; anonymization of `riders`, invitation tables, `helper_workers`, JSON metadata; `rider_locations` purge; storage (`cefflo-pod`) retention; Apple token store (if M chosen for revocation); audit event for deletion; RLS for any new tables. All are P6-sensitive and need Founder gates.

### 8.11.7 Security risks

Account takeover via weak re-auth before deletion; deletion by a stolen session (require fresh auth); partial deletion leaving orphaned PII; ownerless business; retained PII in JSON metadata/logs; Apple token storage (secret handling); relay-email duplicates enabling a second business; invitation token replay if M2 is chosen.

### 8.11.8 Recommended UI placement

- Vendor Mobile (Owner/Operator/Helper): More → Settings → Account → **Delete account** (separate from any business setting). Owner sees the ownership-transfer/close-business step when sole Owner.
- Driver Mobile: Profile/Settings → Account → **Delete account**.
- Vendor Web: Settings → Account → Delete account (not an Apple requirement; recommended for parity — Founder decision).
- FOUNDR: out of scope (platform admins managed in the database).

### 8.11.9 Dependency graph (Batch E, P1, P6)

```
FG-1 stable staging URLs ──┐
FG-8 identity model ───────┼─► Batch E (Vendor Google + Apple) ─► P1 Batch I (E2E)
Provider credentials ──────┤
Apple config (App ID,      │
  Services ID, key, relay  │
  domain registration F6) ─┘
FG-10 deletion architecture ─► P6 backend design (deletion RPC, anonymization,
  (8.11) + Founder gates        RESTRICT handling, sole-Owner guard) ─► implementation
                              ─► Apple token capture decided before Batch E ships Apple
iOS App Store submission ◄── Batch E (Apple) + FG-10 implemented + Batch I
```

## 8.12 P1 Execution Status (2026-09-29)

| Batch | Status | Evidence / next step |
|---|---|---|
| A — Staging Auth URLs | ✅ COMPLETE (staging, Founder-applied 2026-09-29) | Supabase `cefflo-staging` → Authentication → URL Configuration, confirmed by the Founder: Site URL `https://new-project-git-claude-notific-b5ee9a-cefflohq26-6353s-projects.vercel.app/web/`; Redirect URLs exactly `cefflo-vendor://auth-callback`, `cefflo-driver://auth-callback`, `https://new-project-git-claude-notific-b5ee9a-cefflohq26-6353s-projects.vercel.app/**`, `https://cefflo-vendor-app-staging.vercel.app/**`, `https://cefflo-driver-app-staging.vercel.app/**`. Matches the 8.9.1 set exactly; `localhost:3000`, the temporary `staging.cefflo.com` and the old trycloudflare Vendor URL removed. Native Vendor callback proven by E17/E18. Dashboard values are Founder-reported (not agent-readable). `staging.cefflo.com` remains unconfigured (NXDOMAIN) and is not used |
| B — Auth email templates/config | 🟡 PARTIAL | Templates applied in `cefflo-staging` → Authentication → Emails. **Confirm sign up VERIFIED-STAGING** (branded, sender "Cefflo", E17). Reset password delivery observed via native recovery (E18). Change email not yet exercised |
| C — Mobile link handling | 🟡 PARTIAL — Vendor Android VERIFIED (8.12.1); Vendor iOS, Operator, Helper, Driver not verified | Vendor Android: sign-up confirmation and password-recovery links return through `cefflo-vendor://auth-callback` into the installed app (E17, E18) |
| D — Driver Verify Email | 🟡 IMPLEMENTED-UNVERIFIED | `32ff558`; real-device E2E pending |
| E — Google Auth | 🟡 IMPLEMENTED (code) | Vendor Mobile: Google + Email on Android and web harness, Email only on iOS, Apple removed, Google `redirectTo` = app return URL. Vendor Web: Continue with Google → `/auth/v1/authorize?provider=google`, returns to current page. FOUNDR: Continue with Google on top, Email/password below as transitional access (FG-9). Blocked on Google Cloud OAuth Web client + Supabase Google provider (redirect `https://tomvvmwktehexwhktenw.supabase.co/auth/v1/callback`) |
| F — `support@cefflo.com` | 🔴 PENDING | Founder: mailbox provider + MX/SPF/DKIM |
| G — V-57 Contact Support | 🟡 IMPLEMENTED | Send opens the mail app to `support@cefflo.com` with subject, message and business/role/account context; demo prefill and fake attachment area removed; no fabricated "sent"; empty message rejected. Live delivery needs F |
| H — DMARC | 🔴 PENDING | Founder applies 8.9.3 records |
| I — Full P1 staging E2E | ⏳ WAITING | after A–H |

Path to close: A + B(dashboard) + E(credentials) + F + H → I → P1 VERIFIED → FG-7 canonical merge.

### 8.12.1 Founder Real-Device QA — Vendor Android native email auth (2026-09-29)

Build: `app-arm64-v8a-release.apk`, source `1d78d71`, `CEFFLO_ENVIRONMENT=staging`, Supabase `tomvvmwktehexwhktenw`, package `com.cefflo.cefflo_vendor_mobile`, debug-signed sideload, SHA-256 `7b99fe245be5bc2856cbabc883c1bd67413a2f6871ca19d274b5cfc807915a99`. Physical Android device, Email only.

| Step | Result | Evidence |
|---|---|---|
| Sign Up (new email, native app) | ✅ PASS | E17: `POST /signup` 18:56:52Z, referer `cefflo-vendor://auth-callback`, `user_confirmation_requested`; new `auth.users` row 18:56:50Z |
| Confirmation email delivered | ✅ PASS | Founder: "Confirm your Cefflo account", sender Cefflo, branded template |
| Confirm email → Supabase verify | ✅ PASS | E17: `GET /verify` 303, `user_signedup`, `email_confirmed_at` 18:58:53Z |
| Native callback → installed app opens | ✅ PASS | Founder observed app open (not browser); redirect `cefflo-vendor://auth-callback` |
| Authenticated session | ✅ PASS | E17: PKCE `/token` 200 at 18:58:53Z, `last_sign_in_at` 18:58:53Z. The PKCE verifier exists only in the app that started sign-up, so the exchange was made by the app. (The log `referer` on `/token` shows the Vendor Web URL; this is the GoTrue-recorded redirect context, not the caller.) |
| Business Setup reached | ✅ PASS | Founder observed |
| Password recovery via native link (existing user) | ✅ PASS | E18: `/recover` 18:50:09Z and `/verify` 18:50:26Z with referer `cefflo-vendor://auth-callback`, PKCE `/token` 200 18:50:27Z, password sign-in 200 18:50:51Z |

**Scope of this PASS:** Vendor Mobile **Android**, Email Sign Up confirmation and password recovery only. NOT covered: Google OAuth (Batch E), Vendor iOS, Operator/Helper invitation flows, Driver, FOUNDR, change-email, support mailbox, overall P1.

### 8.14 Profile Photo — backend capability (staging, Founder-approved 2026-09-30)

Migration `202609300001_profile_avatars.sql`, applied to `cefflo-staging` only:
- Bucket `cefflo-avatars`: private, 2 MB limit, JPEG / PNG / WebP only.
- `profiles.avatar_url text` + check `profiles_avatar_url_own_path` (value null or `<id>/avatar`).
- Storage policies `avatars_owner_{read,insert,update,delete}`: authenticated, `name = auth.uid() || '/avatar'` only. No other table, bucket, RPC or policy touched.
- Identity scope: every surface signs in through the same `auth.users` + `profiles` row (Vendor Owner / Operator / Helper, Driver, FOUNDR). The control is implemented only on Vendor Web → Settings → Profile; other surfaces can reuse the same path later.

RLS evidence (SQL, as `authenticated` with each user's JWT claims; every write undone, 0 objects / 0 avatar rows after): A inserts `A/avatar` ALLOWED; A inserts `B/avatar` DENIED (RLS); A inserts `A/other.png` DENIED; A updates `B/avatar` 0 rows; A sees `B/avatar` 0 rows (so cannot sign, read or delete it — Storage API delete is RLS-filtered the same way; direct SQL delete is blocked by Supabase); B sees own 1 row; A sets own `avatar_url` to B's path DENIED (check); A sets own path ALLOWED; A updates B's profile 0 rows; anon insert DENIED.
Pending: real upload / replace / remove / persistence after sign-out through the Web UI (Founder device QA).

### 8.13 6-Digit Email OTP Standardization — Audit and Migration Map (2026-09-30, PROPOSED — NOT APPLIED)

Founder direction: sign-up, password recovery and email change verify with a 6-digit Email OTP. Supabase Auth stays the only auth system: no custom OTP tables, generators, reset tokens or services. Nothing below is configured yet; UI is prepared behind injected handlers (Founder visual gate).

**Current state (audited 2026-09-30, branch `claude/otp-verify-ui` from `claude/notification-system`)**

| Surface | Sign up | Confirm | Recovery | Change email | Session |
|---|---|---|---|---|---|
| Vendor Mobile (Owner/Operator/Helper) | `auth.signUp(emailRedirectTo)` | emailed link → `cefflo-vendor://auth-callback` (PKCE) | `resetPasswordForEmail(redirectTo)` → link → Set New Password → `updateUser(password)` | not exposed (email read-only) | PKCE code exchange by supabase_flutter; `verifyOTP(type: email)` already exists (email sign-in helper) |
| Vendor Web (Owner/Operator) | `POST /auth/v1/signup?redirect_to` | link → web callback | `POST /auth/v1/recover?redirect_to` → link → `PUT /auth/v1/user {password}` | **exposed**: Settings → Profile → `PUT /auth/v1/user {email}` (secure change: both addresses) | token/fragment consumed by `api.js` |
| Driver Mobile | `auth.signUp(emailRedirectTo)` | link → `cefflo-driver://auth-callback` | `resetPasswordForEmail` → link → D07 | not exposed (read-only) | as Vendor Mobile |
| FOUNDR | no sign-up | n/a | `POST /auth/v1/recover` (transitional email access, FG-9) | not exposed | password grant; Google target |

Templates (`supabase/templates/*.html`, applied to staging Dashboard): confirmation, recovery, email_change — link only (`{{ .ConfirmationURL }}`); no `{{ .Token }}`.

**Supabase facts that shape the design (verify each on staging before rollout)**
- The same emails carry a one-time code when the template includes `{{ .Token }}`; `verifyOtp` accepts it with the flow's own `type`: `signup` (or `email`), `recovery`, `email_change`. The link keeps working alongside the code.
- Code length and validity are Auth settings (Email OTP length / expiration). The UI never shows or assumes a validity period.
- Resend is bound by the Auth email rate limits (one email per address per window); the UI's cooldown is only a fallback and adopts the backend's "retry after N seconds".
- GoTrue returns the same `otp_expired` for an expired and a mistyped code; the UI therefore shows "didn't work" by default and "expired" only when the backend is unambiguous.
- Sign-up for an address that is already confirmed returns an obfuscated success and sends no email (enumeration protection; observed on staging 2026-09-29 as `user_repeated_signup`). The code screen must not claim otherwise; copy stays "Enter the code we sent".
- Recovery via code yields a session only after `verifyOtp(type: recovery)`; Set New Password then uses the existing `updateUser(password)`.
- Secure email change sends codes to BOTH addresses; each is verified with `verifyOtp(type: email_change)` against its own address.

**Migration map**

| Flow | Current flow | Reusable infrastructure | Required change | Target OTP flow | Surfaces |
|---|---|---|---|---|---|
| Sign up | signUp → link email → callback → session | `signUp`, `resend(type: signup)`, confirmation template, session handling, Verify screen entry points | template adds `{{ .Token }}`; add `verifyOtp(signup)` per repository/api; route the existing Verify Email step to the code screen; keep link as fallback during rollout | Sign up → code email → enter 6 digits → `verifyOtp` → session → existing onboarding (Business Setup / workspace / Driver onboarding) | Vendor Mobile, Vendor Web, Driver |
| Password recovery | recover → link → callback → Set New Password | `resetPasswordForEmail` / `/recover`, recovery template, Set New Password screens, `updateUser(password)` | template adds `{{ .Token }}`; add `verifyOtp(recovery)`; Check-your-email step becomes the code screen (title "Reset your password", no verified state) | Forgot → email → code → `verifyOtp(recovery)` → Set New Password → done | Vendor Mobile, Vendor Web, Driver; FOUNDR only while its transitional email access exists |
| Change email | `PUT /user {email}` → links to both addresses | `updateUser`, email_change template, secure change | template adds `{{ .Token }}`; code screen for the new address (and the current one, since secure change is on) | Profile → new email → code(s) → `verifyOtp(email_change)` → updated | Vendor Web only (not exposed elsewhere) |

**Founder decisions needed before the real migration:** (1) keep links alongside codes during rollout (recommended) or codes only; (2) Email OTP length and expiry values on staging; (3) whether change-email verifies both addresses by code or keeps secure change as-is.

**UI prepared (Founder visual gate):** `VerifyEmailCodeScreen` in Vendor Mobile and Driver (each in its own design system), `renderVerifyCode` in Vendor Web; injected `onVerify` / `onResend`; not yet reachable from the live flows. FOUNDR: no sign-up; recovery code screen only if its email access is kept.


---

# 9. P2 — Core Backend Wiring

Build one **Interaction Ledger** across all applicable surfaces.

Minimum columns:

| Surface | Role | Screen | Control | User Action | Expected Result | Backend Contract | Persistence | Reload Proof | Error State | Status | Evidence | Package |
|---|---|---|---|---|---|---|---|---|---|---|---|---|

Audit:
- buttons
- links
- toggles
- forms
- slide/swipe controls
- modal CTAs
- retry
- refresh
- create/update/delete
- assign
- dispatch
- complete
- settings mutations

Classify every interaction:

- REAL
- BROKEN
- FAKE
- LOCAL-ONLY
- HIDDEN
- DEFERRED
- OUT OF SCOPE

A successful toast is not proof.

For mutations, normal proof should be:

**User action → backend response → canonical persisted state → reload/refetch → same state remains**

Core product areas include at minimum:
- Business Setup
- Business Profile
- Service Area
- Orders
- Zones
- Planning
- Runs
- Riders/Drivers
- Team
- Helper Pool where applicable
- Storefront
- Products
- Settings
- Integrations
- Customer Tracking
- Rating/POD
- FOUNDR operations

Do not add new product scope while reconciling.

---

# 10. P3 — Delivery End-to-End

This is a platform business-journey gate, not an isolated app test.

Validate:

**Owner authenticated  
→ business exists  
→ service area  
→ rider/driver available  
→ order created  
→ valid address/location  
→ zone/coverage  
→ planning  
→ run  
→ assignment  
→ Review & Dispatch  
→ Driver receives work  
→ PLAN ROUTE  
→ PICKUP CHECKLIST  
→ Start Pickup  
→ DELIVERY RUN  
→ Start Delivery  
→ customer visibility  
→ Arrive  
→ Complete  
→ POD where applicable  
→ Customer Tracking Delivered  
→ rating where applicable  
→ history/completed state  
→ FOUNDR sees correct operational truth**

Cross-surface state must agree.

## Customer Tracking

Validate:
- secure tracking access
- correct order
- Picked Up
- On the Way
- Delivered
- Tracking Unavailable
- refresh/refocus behavior
- rider data only where permitted
- ETA honesty
- Delivery Details
- POD
- rating
- rating persistence
- invalid/expired tracking access

No fabricated ETA, rider contact, POD, rating or notification.

---

# 11. P4 — Notification System

Create an Event → Channel Matrix:

| Event | Source | Recipient | In-App | Email | WhatsApp | V1 Required? | Provider | Status | Cost | Retry | Audit Log |
|---|---|---|---|---|---|---|---|---|---|---|---|

The system must prevent:
- duplicate communication
- fake notification UI
- unnecessary paid API calls
- missing critical events
- transactional/marketing mixing

Notification architecture must be driven by real product events and canonical backend state.

---

# 12. P5 — FOUNDR + Control

FOUNDR must observe and control platform truth, not demo data.

Audit:
- authentication
- platform-admin authorization
- password recovery
- operational visibility
- Need Attention
- admin delivery operations
- stuck rider/driver visibility where canonical
- maintenance
- feature/platform controls
- audit visibility
- version/platform information

Fabricated success behavior must be removed or explicitly blocked from launch.

FOUNDR changes that affect platform behavior must respect Founder/backend approval gates.

---

# 13. P6 — Security + Reliability

## Security

Audit:
- RLS
- RPC grants
- SECURITY DEFINER functions
- role escalation
- business isolation
- public tracking exposure
- invite abuse
- FOUNDR authorization
- secret handling
- rate limits
- auth enumeration
- replay/duplicate mutations
- idempotency
- audit logging

Frontend hiding is never authorization.

## Reliability

Validate:
- offline
- timeout
- duplicate tap
- 401
- 403
- 404
- 409 where applicable
- 429
- 5xx
- stale state
- partial failure
- retry
- recovery

Backend hardening gaps require explicit implementation plans and Founder Gates where architecture/security changes are involved.

---

# 14. P7 — Full QA + Launch Audit

Build matrices for:

A. Every screen  
B. Every interaction  
C. Every role  
D. Every cross-surface journey  
E. Device/browser coverage  
F. Failure/recovery states

Launch surfaces:
- Vendor Mobile
- Vendor Web
- Operator Access
- Helper Access
- Driver Mobile
- Customer Tracking
- FOUNDR
- Marketing where included in launch scope

Validate:
- supported mobile sizes
- desktop web
- mobile web
- relevant browsers
- refresh
- reopen
- session recovery
- cache/version refresh

Final E2E uses the real staging backend.

Mocks and unit tests support QA but do not replace staging E2E.

---

# 15. P8 — Production Cutover

Production is a separate approval gate.

Document and verify:
- production Supabase
- approved DB migrations
- production RLS
- production secrets
- environment variables
- Resend production configuration
- DNS
- production domains
- Auth Site URL
- Auth Redirect URLs
- rate limits
- map/geocode provider configuration
- notification provider configuration
- Flutter release configuration
- web deployment
- service-worker/cache versioning
- monitoring/logging
- rollback/recovery

No localhost or staging preview URL may leak into production communication.

## Production Smoke Test

After deployment, controlled production tests must cover at minimum:
- login
- signup where applicable
- verify email
- password reset
- business access
- critical create/read operation
- dispatch/delivery critical path
- Customer Tracking
- permissions
- FOUNDR access
- communication delivery

Use controlled production test accounts/data.

---

# 16. Founder Gate Register

Maintain one centralized register to prevent repeated decisions.

| Gate ID | Decision Required | Why | Options | Impact | Blocks | Status |
|---|---|---|---|---|---|---|
| FG-1 | Staging Site URL + final Redirect URL set | Site URL is `localhost:3000` (E4); harness URLs not allowed | Direction approved: no localhost; harness URLs allowed as QA HARNESS | All auth links on staging | P1 E2E | 🟣 APPROVED DIRECTION — exact set to be presented before change |
| FG-2 | Production-ready auth email config (templates, redirects, expiry, rate limits) | Unverified; sign-up via Cefflo sender untested | Direction approved | All auth email | P1 sign-up E2E, P8 | 🟣 APPROVED DIRECTION — exact config to be presented before change |
| FG-3 | `support@cefflo.com` real mailbox | No MX (E6) | LOCKED: real mailbox; provider/purchase may need approval | Support, V-57, Vendor Web Help | G4 | 🟣 LOCKED — provider decision pending |
| FG-4 | V-57 Contact Support | Fake success | LOCKED: route to FG-3 channel; no ticketing system; no fabricated "sent" | Vendor Mobile | — | 🟣 LOCKED |
| FG-5 | Sign-in providers | Google implemented in code (8.12 E); provider unconfigured | FOUNDER FINAL LOCK (8.1.00): Vendor Android Email+Google, Vendor iOS Email only, Vendor Web Email+Google, Driver Email only, FOUNDR Google only; Apple DEFERRED / OUT OF V1 | VM, VW, Operator, Helper, Driver, FOUNDR | G7 | 🟣 LOCKED — Google credentials pending |
| FG-6 | DMARC for `cefflo.com`, `auth.cefflo.com` | None (E6) | Approved: monitoring policy first | Deliverability | P8 | 🟣 APPROVED DIRECTION — exact records to be presented |
| FG-7 | Merge `claude/notification-system` → `main` | P1 work not canonical | HOLD until P1 evidence complete | Canonical state | P1 platform verification | 🟣 HOLD |
| FG-8 | Apple Hide My Email vs email-based invitation claim | Relay email never matches `invited_email`; duplicate Owner risk (8.10) | M1 real email for invited/existing users · M2 token-bound claim · M3 manual identity linking (8.10.3) | Vendor Owner, Operator, Helper on iOS | Batch E | ⚪ DEFERRED — Apple out of V1 (8.1.00); revisit only if Apple is added |
| FG-9 | FOUNDR Google-only vs current Email + password (DECIDED 2026-09-29: target Google only; keep Email/Password as transitional staging access until Google-only is implemented, staging-E2E verified, admin authorization verified, recovery/access reviewed and cutover approved — no premature lockout) | Locked target differs from current implementation (8.8.6) | confirm removal of FOUNDR email/password + recovery once Google is live; admin identity linking | FOUNDR | E1 FOUNDR | 🟣 OPEN — the Founder brief refers to an "existing Google architecture", but FOUNDR is Email + password today (no Google code or identity exists, E10); clarification needed |
| FG-10 | In-app account deletion + Apple token revocation | Mandatory (E9); CONFIRMED as Production Readiness requirement 2026-09-29 | Architecture in 8.11; open decisions: sole-Owner rule (transfer vs close business), retention periods, POD retention, Vendor Web placement, Apple token capture vs manual revocation | Vendor Mobile, Driver Mobile (+ Vendor Web optional) | iOS submission, P6 | 🟣 CONFIRMED — moved to P6 (does not block P1); required before iOS submission |

Founder approval is required before protected backend/schema/RLS/auth configuration changes, production deployment, or other decisions already governed by Cefflo’s canonical rules.

---

# 17. Evidence Register

Every important VERIFIED status must reference evidence.

Acceptable evidence may include:
- commit
- automated test
- staging E2E result
- DB result
- Supabase Auth log
- backend/function log
- deployment/version
- screenshot/preview where appropriate

A UI screenshot alone does not prove backend persistence or authorization.


## 17.1 Evidence Register — P1 (staging `cefflo-staging`, 2026-09-29 UTC)

| ID | Evidence | Source |
|---|---|---|
| E1 | FOUNDR recovery: 12:21:21 `POST /recover` → 12:21:39 `GET /verify` 303 (`login`) → 12:21:51 `PUT /user` 200 (`user_modified`); 12:23:16, 12:24:02 reopen → 403 "One-time token not found" | Supabase Auth logs |
| E2 | Vendor Web recovery: 12:29:30 `/recover` (redirect `/web/`) → 12:29:43 `/verify` 303 → 12:29:59 `PUT /user` 200 → 12:30:24 password `/token` 200 | Supabase Auth logs |
| E3 | Native deep links allowed: 12:51–12:55 five `/recover` with `cefflo-driver://` / `cefflo-vendor://auth-callback`, each `/verify` 303; no PKCE `/token` exchange and no `PUT /user` followed; eight rejected reopenings. Likely the pre-`d04ad34` web harness (inference) — native device E2E still absent | Supabase Auth logs |
| E4 | 13:10–13:11 four `/recover` resolved to `http://localhost:3000` → Site URL is localhost; harness URLs not allowlisted | Supabase Auth logs |
| E5 | Auth RPC posture: claim RPCs check `email_confirmed_at` + `auth.uid()`; all SECURITY DEFINER; anon only `resolve_*`/`consent_*` | staging `pg_proc` read |
| E6 | DNS: `cefflo.com` no MX, no DMARC; `_dmarc.auth.cefflo.com` none; `send.auth.cefflo.com` MX + SPF; `resend._domainkey.auth.cefflo.com` DKIM present | `dig` |
| E8 | Apple App Review Guideline 4.8 (re-checked for 8.1.0 on 2026-09-29: Vendor iOS offers Email + Sign in with Apple, no third-party login → 4.8 not triggered; Driver iOS Email only → not triggered) (Login Services), fetched 2026-09-29 from developer.apple.com/app-store/review/guidelines: extra equivalent login required only when a third-party/social login is used for the primary account | Apple official |
| E9 | Guideline 5.1.1(v) + "Offering account deletion in your app": in-app account deletion required when account creation is supported; Sign in with Apple apps should revoke tokens via the REST API | Apple official, fetched 2026-09-29 |
| E10 | staging `auth.identities`: 120 rows, all provider `email`; no Google/Apple identities | staging DB read |
| E11 | Supabase identity linking: automatic linking only for verified same-email identities (removes other unconfirmed identities); manual linking needs setting + signed-in user; unlink needs ≥2 identities | supabase.com/docs/guides/auth/auth-identity-linking (fetched 2026-09-29) |
| E12 | Supabase does not store provider tokens | supabase.com/docs/guides/auth/social-login (fetched 2026-09-29) |
| E13 | Apple private relay: same per developer team, 100 emails/day, user can stop forwarding (relay then rejects), outbound domains must be registered + SPF | developer.apple.com "Communicating using the private email relay service" (fetched 2026-09-29) |
| E14 | Staging FK/ON DELETE map, ownership model, roles, buckets, PII columns (8.11.1) | staging `pg_constraint` / `information_schema` reads 2026-09-29 |
| E15 | Apple revoke endpoint `POST https://appleid.apple.com/auth/revoke` (client_id, client_secret JWT, token, token_type_hint) and TN3194 manual revocation path | developer.apple.com Sign in with Apple REST API + TN3194 (fetched 2026-09-29) |
| E16 | P1 Batch C+D implemented in `32ff558`; tests Vendor 161/161, Driver 59/59 — IMPLEMENTED-UNVERIFIED (real-device E2E pending) | commit + local test runs |
| E7 | Automated tests: Vendor Mobile 159/159, Driver 55/55, FOUNDR recovery 10/10, repo 64/64 (support QA; not staging E2E) | local runs on `d04ad34` |
| E17 | Vendor Android native sign-up confirmation, staging auth logs + `auth.users` (user `a7bc4909…`), 2026-09-29 18:56–18:58Z | 8.12.1 |
| E18 | Vendor Android native password recovery, staging auth logs (request `01a0ee81-0035…`), 2026-09-29 18:50Z | 8.12.1 |

---

# 18. Parallel Worktree Rules

Parallel work is encouraged only when ownership is safe.

For every package/worktree record:
- owned directories/files
- backend dependencies
- shared migration risk
- shared canonical-document risk
- merge order
- prerequisite package

Do not allow two parallel agents to independently modify the same critical backend contract.

Round 1 may use separate package worktrees:

- P1: platform-wide Auth + Communication
- P2: platform-wide Core Backend Wiring
- P4: platform-wide Notification System
- P5: FOUNDR + platform control dependencies

These are **not app-specific worktrees** by definition.

---

# 19. Execution Workflow Per Package

Use:

**AUDIT PACKAGE  
→ collect ALL gaps across applicable surfaces  
→ classify evidence/status  
→ Founder Gate only where necessary  
→ batch implementation  
→ package tests  
→ real staging E2E  
→ cross-surface reconciliation  
→ evidence register  
→ platform package verification**

Do **not** use:

**audit one button → patch → audit next button → patch → repeat**

The package model exists to reduce duplicated work, token usage and regressions.

---

# 20. Current Known Evidence Snapshot

**Reconciled:** 2026-09-29 against the repository, staging Supabase Auth logs and Vercel deployments.

## 20.1 Auth / Security Email Foundation (staging)

- Resend domain `auth.cefflo.com` is verified for staging.
- Supabase staging (`cefflo-staging`) Custom SMTP is configured.
- Current auth sender: `Cefflo <no-reply@auth.cefflo.com>`.
- A real FOUNDR password-recovery email was delivered through this sender.
- `support@cefflo.com` must NOT be marked configured until its actual mailbox/routing state is verified.
- WhatsApp/provider-dependent delivery notifications must NOT be marked live unless a real provider is wired and verified.

## 20.2 Password Recovery — Implementation vs Canonical vs Evidence

| Item | Value |
|---|---|
| FOUNDR recovery + current FOUNDR Sign In UI | Branch `claude/notification-system`, commits `c4a4403` → `61a53dc` |
| Implementation exists | YES |
| Canonical (in `main`) | NO — must not be treated as canonical until integrated |
| FOUNDR staging recovery E2E | VERIFIED — Supabase Auth log 2026-09-29 12:21 UTC: `GET /verify` → 303 (`login`), `PUT /user` → 200 (`user_modified`); reopening the same one-time link → 403 "One-time token not found" (correctly rejected) |
| Vendor Web recovery | Code + automated tests exist; real staging E2E NOT VERIFIED |
| Vendor Mobile / Operator / Helper recovery | Mobile deep-link implementation exists (`cefflo-vendor://auth-callback`); web-build compatibility fix exists for QA (`d04ad34`); tests 159/159; real staging E2E NOT VERIFIED |
| Driver Mobile recovery | Implementation exists (`cefflo-driver://auth-callback`); web-build fix `d04ad34`; tests 55/55; real staging E2E NOT VERIFIED |

## 20.3 QA Harness / Staging Test Surfaces

Manual staging QA deployments (built from `claude/notification-system`, staging Supabase):

- `https://cefflo-vendor-app-staging.vercel.app/**` — Vendor Mobile web build
- `https://cefflo-driver-app-staging.vercel.app/**` — Driver Mobile web build

These URLs still require Auth Redirect URL / configuration verification where applicable. `d04ad34` contains the web-build Forgot Password correction used for staging QA.

**CRITICAL CLASSIFICATION — QA HARNESS / STAGING TEST SURFACE**

The Vendor Mobile web build and its `?access=operator` / `?access=helper` routes, and the Driver Mobile web build, are QA/testing representations of the mobile applications. They are NOT production surfaces and must NOT be added to the production surface architecture (Section 2).

Do NOT introduce:
- Helper Web
- a separate Operator Web application
- a Driver Web product

Helper remains Vendor Mobile only. Operator remains a role/access mode through Vendor surfaces per canonical architecture. Driver remains Driver Mobile. Any temporary Vercel/web build used to test mobile behaviour must be labelled **QA HARNESS / STAGING TEST SURFACE**.

## 20.4 P1 Status Snapshot — Password Recovery (updated after P1 audit)

| Surface | Recovery | Reason |
|---|---|---|
| FOUNDR | 🟢 VERIFIED-STAGING | E1 |
| Vendor Web | 🟢 VERIFIED-STAGING | E2 (was IN PROGRESS before the audit) |
| Vendor Mobile | 🟡 IN PROGRESS | E3: link accepted, reset never completed; native device E2E pending (G2) |
| Operator Access | 🟡 IN PROGRESS | Shares Vendor architecture; role/no-access E2E pending |
| Helper Access | 🟡 IN PROGRESS | Shares Vendor Mobile architecture; role/no-access E2E pending |
| Driver Mobile | 🟡 IN PROGRESS | E3; native device E2E pending (G2) |
| Customer Tracking | — NOT APPLICABLE | No customer login |

## 20.5 P1 Surface Status (whole package, after audit)

| Surface | P1 Status | Open gaps |
|---|---|---|
| FOUNDR | 🟡 IN PROGRESS | Recovery + access-denied verified; logout/expiry/reopen unverified; not canonical (FG-7) |
| Vendor Web | 🟡 IN PROGRESS | Sign-in + recovery verified; sign-up/verify, invitation, Google/Apple (G7), support email (G4) |
| Vendor Mobile | 🟡 IN PROGRESS | G2, G4 (V-57 FAKE), G6, G7 |
| Operator Access | 🟡 IN PROGRESS | Inherits VM + VW; claim E2E |
| Helper Access | 🟡 IN PROGRESS | Inherits VM; claim E2E |
| Driver Mobile | 🟡 IN PROGRESS | G2, G3, G6, G7 |
| Customer Tracking | — N/A | No auth |
| Marketing | — N/A | Static website, no auth |

**P1 PLATFORM STATUS = 🟡 IN PROGRESS.** Founder decisions FG-1…FG-7 are recorded in Section 16; implementation batches are defined in 8.9.

---

# 21. Launch Gate

GO LIVE requires:

- no unresolved critical blocker
- no fake functionality on launch surfaces
- P1 Auth + Communication PASS
- P2 Core Backend Wiring PASS
- P3 critical Delivery E2E PASS
- P4 required V1 Notifications PASS or explicitly approved deferred scope
- P5 FOUNDR/control launch requirements PASS
- P6 Security + Reliability PASS
- P7 Full QA PASS
- P8 Production configuration/deployment PASS
- cross-surface truth PASS
- monitoring/logging available
- rollback/recovery path understood

No surface may silently remain behind the platform launch state.

---

# 22. Definition of Done

Cefflo is Production Ready only when the approved launch fleet functions as one integrated platform against canonical backend truth.

The final proof is not that individual apps “look finished.”

The proof is that:

**real users can authenticate — with exactly the sign-in options locked for their surface and platform (8.1.0) — → perform their permitted work → produce canonical backend state → other relevant surfaces observe the correct state → communications occur truthfully → failures recover safely → permissions hold → the full business journey survives staging and production smoke validation.**

---

# 23. Control Rule for Claude / Codex

This Master is an execution control document.

Before implementation:
1. Reconcile current repository truth.
2. Update package matrices/evidence.
3. Identify genuine gaps.
4. Identify Founder Gates.
5. Respect worktree/package boundaries.

Do not:
- resurrect retired architecture
- invent product scope
- invent providers
- claim UI existence equals backend completion
- claim tests equal staging E2E
- merge protected/canonical branches without approval
- deploy production without approval
- modify schema/RLS/auth configuration without the required Founder gate
- clean or alter unrelated dirty working trees

All implementation must move Cefflo toward one verified platform state.
