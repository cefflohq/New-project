# Cefflo — Personal Data Map (DRAFT for privacy counsel)

Status: **DRAFT v0.1, 2026-10-07.** Prepared from the actual staging schema
(Supabase `tomvvmwktehexwhktenw`), storage buckets and app code on
`official/staging`. Technical inventory only — not legal advice. Columns
marked *TBD (counsel)* need a decision by the privacy lawyer / Founder
(legal checklist L-039 to L-046).

Law in scope: Personal Data Protection Act 2010 as amended by Act A1727
(2024). Hosting: Supabase **ap-south-1 (Mumbai, India)** today — Founder
decision 2026-10-07: production must not stay in Mumbai (see §7).

---

## 1. Data subjects

| # | Data subject | How they enter Cefflo | Surfaces |
|---|---|---|---|
| S1 | **Business Owner** (Vendor) | Signs up (email/password or Google) and creates a business | Vendor App, Vendor Web |
| S2 | **Operator** (staff) | Joins via permanent invite link, approved by Owner | Operator PWA, Vendor Web |
| S3 | **Helper** (packing/sorting staff) | Joins via invite link, approved | Helper PWA |
| S4 | **Driver** | Registers in Driver app; joins a business via invite link or Find Jobs | Driver App |
| S5 | **End customer** (orders a delivery) | Entered by the business (manual/CSV) or self-ordered on the Storefront | Storefront, Customer Tracking |
| S6 | **Cefflo platform admin** | Granted by Cefflo | FOUNDR |

## 2. Personal data inventory

Legend — Access: who can read it under current RLS. Retention "none" = kept
indefinitely today (no cleanup job exists).

### 2.1 Identity & account (S1–S4, S6)

| Data | Stored in | Purpose | Access | Current retention | Proposed retention |
|---|---|---|---|---|---|
| Email, password hash, phone, provider ids (Google) | `auth.users` (Supabase Auth) | Sign-in | The user; Supabase service | None (until account deleted; no self-delete exists) | TBD (counsel) |
| Name, phone, avatar (photo) | `profiles`; bucket `cefflo-avatars` (private) | Display in apps/team | The user; business colleagues where shown | None | TBD (counsel) |
| Driver registration: full name, phone, vehicle type, plate | `auth.users.raw_user_meta_data.driver_registration` | Pre-fill driver onboarding | The user; server functions | None | TBD (counsel) |
| Preferred language, timezone | `auth.users` metadata | App settings | The user | None | Keep with account |
| Notification preferences | `notification_preferences` | Alerts/sound settings | The user | None | Keep with account |

### 2.2 Business & team (S1–S3)

| Data | Stored in | Purpose | Access | Current retention | Proposed retention |
|---|---|---|---|---|---|
| Business name, phone, email, address, pickup coordinates | `businesses` | Run deliveries; shown on tracking page (pickup address, business phone) | Owner/Operator; customers via tracking token (address, phone) | None | Life of business account + TBD |
| Membership (role, status) | `business_members` | Authorisation | Owner/Operator | None (removed = `inactive`, kept — decision 2026-10-07) | TBD (counsel) |
| Join requests: name, phone, role | `team_join_requests` | Approval of staff | Owner (all), Operator (Helper requests), the requester | None | Anonymise after TBD period |
| Legacy invitations: email, name, phone | `team_invitations`, `rider_invitations`, `helper_workers` | Old email-invite flow (retired) | Owner | None | Review for deletion (legacy) |
| Subscription plan/status | `business_subscriptions` | Billing (payments on HOLD) | Owner; FOUNDR | None | Statutory accounting period (TBD) |

### 2.3 Drivers (S4) — includes identity documents

| Data | Stored in | Purpose | Access | Current retention | Proposed retention |
|---|---|---|---|---|---|
| Name, phone, plate, vehicle type, status (per business) | `riders` | Assign deliveries | The driver; the business's Owner/Operator | None (removed = `inactive`, kept) | TBD (counsel) |
| **IC number** — stored only as keyed HMAC + last 4 digits (never in full) | `driver_licences.ic_hash`, `ic_last4` (HMAC key in Vault) | Marketplace identity check, duplicate prevention | Server only; FOUNDR (exceptions) | None | TBD (counsel) |
| **Driving licence photos** (front/back) | bucket `cefflo-driver-documents` (private); paths in `driver_licences` | Marketplace verification (Find Jobs only) | Server; FOUNDR reviewer. **Businesses never see them** | None — 939 objects on staging | Short, e.g. delete after verification decision + TBD |
| Vehicle photo, plate OCR result | bucket `cefflo-driver-documents`; `driver_marketplace_verifications` | Verification | Server; FOUNDR | None | Same as above |
| **Live location** (lat/lng, accuracy, heading, speed) | `rider_locations` | Customer tracking, during an active run only | The business; the customer of that order via tracking token | None | Short, e.g. 30–90 days (TBD) |
| Job requests (Find Jobs) | `rider_job_requests` | Hiring | Driver; the business | None | TBD |
| Ratings + free-text feedback from customers | `ratings` | Quality | The business | None | TBD |
| Face / biometrics | **Not collected** (HOLD, absolute) | — | — | — | — |

### 2.4 End customers (S5)

| Data | Stored in | Purpose | Access | Current retention | Proposed retention |
|---|---|---|---|---|---|
| Name, phone, delivery address, notes, items | `orders` | Fulfil the delivery | The business's Owner/Operator; Helper (items/packing); assigned Driver (for their stops) | None | TBD (counsel) — e.g. 12–24 months then anonymise |
| Delivery coordinates (geocoded address) | `orders.latitude/longitude` | Routing | Same as above | None | Same as orders |
| **Proof-of-delivery photo** + note | bucket `cefflo-pod` (private); `delivery_stops.pod_*` | Proof of delivery | The business; the customer via tracking token | None — 110 objects on staging | TBD (e.g. 90 days) |
| Tracking token | `tracking_tokens` (hash only) | Customer tracking link | Token holder | Expires 2–7 days; row kept | OK; prune rows TBD |
| Rating + feedback | `ratings` | Quality | The business | None | TBD |
| Storefront order submission (name, phone, address) | `orders` (origin = storefront) | Self-ordering | The business | None | Same as orders |

### 2.5 Operational & audit records (all subjects)

| Data | Stored in | Purpose | Access | Current retention |
|---|---|---|---|---|
| Who did what (user ids, roles, status changes) | `delivery_events`, `business_profile_audit` | Audit trail, disputes | Owner/Operator (own business) | None |
| Work attribution (approved_by, packed_by, sorted_by, pod_submitted_by…) | `orders`, `delivery_stops`, `delivery_sessions` | Accountability | Business | None |
| In-app notifications (generic text + order ref) | `notifications` | Alerts | Recipient only | None |
| Admin actions | `admin_audit_log` | Platform audit | FOUNDR | None |
| Rate-limit counters (hashed keys), invalid lookups | `rate_limit_counters`, `invalid_lookup_telemetry` | Abuse protection | Server | **1 h / 24 h (cron)** |

## 3. Data flows per surface

| Surface | Collects | Shows to others |
|---|---|---|
| Vendor App / Vendor Web | Business profile, team decisions, orders (customer data), products, storefront | — |
| Operator / Helper PWA | Work actions (attribution) | — |
| Driver App | Registration, IC (hashed), licence/vehicle photos, live location during runs, POD photos | Location + name to the customer of the active order |
| Invite gateway | Name, phone (join request) | — |
| Storefront (public) | Customer name, phone, address, order | Business name/products only |
| Customer Tracking (public, token) | Rating/feedback | Driver name, live location, POD, business pickup address/phone, item names |
| FOUNDR (admin, MFA + Cloudflare Access) | Admin actions | Platform-wide data for support/verification |

## 4. Processors / third parties

| Processor | Data | Location | Status |
|---|---|---|---|
| **Supabase** (DB, Auth, Storage, Realtime, Edge Functions) | All of the above | **ap-south-1 Mumbai, India** | Active (staging); production project INACTIVE |
| Cloudflare (Workers static hosting; Access for FOUNDR) | Request metadata (IP, headers) | Global edge | Planned for production |
| Vercel (marketing website) | Visitor request metadata | Global | Active |
| Google (OAuth sign-in) | Email, name, avatar from Google | Global | Vendor/Driver sign-in |
| Google Cloud Vision (OCR of licence/vehicle images) | **Licence and vehicle images** | Google global | **HOLD** (billing disabled) |
| Mapbox (geocoding, maps) | Addresses, coordinates | US/global | **HOLD** |
| Google Fonts (Storefront, Invite pages) | Visitor IP address | Google global | Active — consider self-hosting fonts |
| Auth email delivery (SMTP for verification/recovery) | Email address | TBD (confirm provider) | Active |
| Curlec / Stripe (driver paid changes, subscriptions) | Payment data | MY / global | **HOLD** |

## 5. Sensitive / high-risk data (priority for counsel)

1. IC number (hashed + last 4) and licence images — identity documents.
2. Driver live location.
3. POD photos (may show a person or home).
4. Customer home addresses + phone numbers.
5. Biometrics: **not collected** (face recognition HOLD, absolute).

## 6. Gaps found (from the 2026-10-07 audit)

| Gap | Checklist |
|---|---|
| No approved Privacy Notice (EN/BM) on any surface; none at Storefront checkout, Tracking, Invite | L-034 |
| No versioned consent / terms-acceptance evidence | L-046 |
| No retention periods or cleanup for any personal data above | L-040 |
| No data-subject request process (access, correction, portability, deletion) | L-040 |
| No 72-hour breach notification procedure | L-041 |
| DPO not appointed / threshold not determined | L-045 |
| Data-controller registration status not determined | L-044 |
| Cross-border transfer not assessed (Mumbai hosting, Google, Mapbox, Cloudflare) | L-043 |
| Legacy tables with personal data (`team_invitations`, `rider_invitations`, `helper_workers`) | — |

## 7. Hosting location decision (Founder, 2026-10-07)

Founder: production must not stay in Mumbai; preference is Malaysia.

Fact check (2026-10-07): Supabase's managed regions do **not** include
Malaysia (AWS ap-southeast-5 Kuala Lumpur exists but Supabase does not offer
it). Nearest Supabase region: **ap-southeast-1 Singapore**. Options for the
Founder:

- **A. Supabase Singapore** — same platform and code; new production project
  in ap-southeast-1 (the current production project is INACTIVE and empty of
  real users, so no data migration is needed). Still a cross-border transfer
  (Singapore has its own PDPA 2012) to document.
- **B. Self-hosted Supabase on AWS Kuala Lumpur (ap-southeast-5)** — data in
  Malaysia, but Cefflo then operates the database, auth, storage, realtime,
  backups and security patching itself.
- **C. Another managed Postgres provider in Malaysia** — major re-platforming.

No hosting change has been made.
