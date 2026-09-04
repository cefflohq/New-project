**Status:** WORKING MASTER BASELINE — Founder Review Required (merged into repo 2026-09-04)
**Repo-reconciliation note:** Fills the "no Vendor Flutter master exists" gap flagged in `docs/cefflo/sot/00_INDEX.md` §1 and `docs/cefflo/05_DECISIONS.md` D-23. This is a screen-map/scope baseline only — **not** blanket implementation authorization. Its own internal HOLD/reconciliation flags (Subscription/payment V-50–V-54, and V-41 Delivery Settings) must be preserved exactly as written below, not softened or silently resolved. The current LIVE Vendor client remains Vendor Web/Desktop (`docs/cefflo/06_VENDOR.md`, `docs/cefflo/sot/03_VENDOR_WEB_DESKTOP.md`); this file describes a FUTURE companion Flutter app per `docs/cefflo/sot/02_ARCHITECTURE.md`'s target multi-client architecture, gated the same way as Rider Flutter under `docs/cefflo/05_DECISIONS.md` D-13/D-23.

---

# CEFFLO Vendor Flutter — 60 Full Screen Master Map

**Document Type:** Product / UX Screen Inventory  
**Platform:** Cefflo Vendor Flutter Mobile  
**Status:** Working Master Baseline — Founder Review Required  
**Date:** 2026-09-04  

> This document is a screen-map and scope baseline. It is **not** blanket implementation authorization. Subscription/payment architecture remains **HOLD / Founder Decision Pending** until explicitly resolved.

---

## 1. Purpose

Define the current end-to-end Vendor Flutter mobile screen inventory from app launch through authentication, onboarding, daily operations, business management, account settings, subscription, support, and legal/about surfaces.

This document separates:
- **Full screens** — counted in the 60-screen inventory.
- **Tabs / states** — not counted as separate full screens.
- **Components / sections** — not counted separately.
- **Bottom sheets / dialogs / confirmation flows** — not counted separately unless later promoted to a full screen.

The inventory is intended to prevent missing screens, duplicate responsibilities, and accidental expansion during Flutter implementation.

---

## 2. Product / Architecture Guardrails

1. Vendor Mobile is a **pure Flutter app**.
2. Canonical operational truth remains in the Cefflo backend: **cefflo_api → Supabase / Postgres / RPC**.
3. Flutter owns presentation and client state only. Do not recreate canonical coverage, zones, vehicle compatibility, capacity, optimization/planning eligibility, ETA, recovery eligibility, or other operational business rules in the client.
4. Primary Vendor bottom navigation remains: **Today · Orders · Zones · Riders · Menu**.
5. Secondary navigation remains grouped into **Business**, **Account**, and **Support**.
6. Zones operational workspace uses the Founder-approved primary states: **Ready · Ongoing · Completed**.
7. Recent Orders should preserve the approved compact Draft B treatment.
8. Cefflo visual foundation: **Black / White / Graphite**, with **Signal Lime candidate #C7F000** used deliberately as the operational signal. Exact lime HEX remains subject to final Founder lock.
9. Support both **Light and Dark** modes. Current experience direction: Draft B structural baseline; Dark retains that structure with the approved sectional treatment direction.
10. Cefflo does **not** manage vendor-customer payments. Do not introduce customer balance, deposit, payment status, or ordinary invoice/receipt workflows.
11. Subscription/payment in this document refers only to a Vendor paying **Cefflo for Cefflo service**, and its final architecture is not yet approved.

---

# 3. Master Screen Inventory

## A. ENTRY

| ID | Full Screen | Purpose / Notes |
|---|---|---|
| V-01 | **Splash** | Brand launch, app initialization, session/bootstrap checks and routing. |

## B. AUTHENTICATION

| ID | Full Screen | Purpose / Notes |
|---|---|---|
| V-02 | **Sign In** | Existing Vendor authentication entry. |
| V-03 | **Sign Up / Register** | New Vendor account registration. |
| V-04 | **Forgot Password** | Initiate password recovery. |
| V-05 | **Reset Password** | Set new password from valid recovery flow. |

## C. FIRST-TIME ONBOARDING

| ID | Full Screen | Purpose / Notes |
|---|---|---|
| V-06 | **Welcome / Setup Intro** | Explain initial setup and progress into Vendor workspace. |
| V-07 | **Business Setup — Information** | Capture required business identity/setup information. |
| V-08 | **Business Setup — Address / Location** | Capture operational business address/location. |
| V-09 | **Business Setup — Service Area** | Initial coverage/service-area setup. Must use canonical backend rules. |
| V-10 | **Setup Complete** | Confirm minimum onboarding completion and enter operational workspace. |

> **Excluded:** Bank Details are not part of the current locked onboarding scope. Cefflo does not manage vendor-customer payments. Do not add them without a separately approved requirement.

## D. TODAY / DASHBOARD

| ID | Full Screen | Purpose / Notes |
|---|---|---|
| V-11 | **Today / Dashboard** | Primary operational overview for the current day. |

### V-11 embedded components — not separate screens
- KPI summary
- Current Deliveries
- Need Attention / Action Required
- Recent Orders — compact Draft B treatment
- Relevant quick operational actions

## E. ORDERS

| ID | Full Screen | Purpose / Notes |
|---|---|---|
| V-12 | **Orders** | Main Vendor order workspace/list. |
| V-13 | **Order Detail** | Canonical detail for one order. |
| V-14 | **New Order** | Create a delivery order through the canonical backend creation path. |
| V-15 | **Edit Order** | Edit only fields/actions permitted by canonical backend rules. |

### Order states / sections — not separate screens
- List tabs/filters where approved
- Order status
- Delivery history / events
- Search / filter / sort
- Empty / loading / error states

## F. ZONES / DELIVERY OPERATIONS

| ID | Full Screen | Purpose / Notes |
|---|---|---|
| V-16 | **Zones** | Today's operational zone workspace. Primary views: Ready / Ongoing / Completed. |
| V-17 | **Zone Detail / Delivery Plan** | Orders and delivery work for a selected zone; planning/preparation surface. |
| V-18 | **Review & Dispatch** | Review delivery plan/run before canonical dispatch. |
| V-19 | **Run Detail / Active Run** | Monitor a dispatched/active run and its stops/status. |

### V-16 states — not separate screens
- **Ready** — work ready for Optimize/Prepare → Review → Dispatch
- **Ongoing** — dispatched plans/runs currently active
- **Completed** — completed operational work

### Zone/run overlays — not separate screens
- Stop detail bottom sheet
- Rider selection
- Dispatch confirmation
- Error / conflict / capacity feedback

## G. RIDERS

| ID | Full Screen | Purpose / Notes |
|---|---|---|
| V-20 | **Riders** | Rider workforce/operational overview. |
| V-21 | **Rider Detail** | Individual rider information and relevant operational context. |
| V-22 | **Invite Rider** | Canonical rider invitation flow. |

### Rider states — not separate screens
- Pending invitation
- Available / ongoing / other approved filters
- Invitation status/actions

> Do not restore any local-only quick-add rider bypass. Rider onboarding/access must follow the canonical invitation model.

## H. BUSINESS — TEAM

| ID | Full Screen | Purpose / Notes |
|---|---|---|
| V-23 | **Team** | People/access management for business users. |
| V-24 | **Team Member Detail** | Member identity, role/access and permitted management actions. |
| V-25 | **Invite Team Member** | Invite a new business team member through the canonical access model. |

### Team states — not separate screens
- Pending invitations
- Invitation revoke/resend where backend permits
- Member status
- Role/access controls

## I. BUSINESS — SERVICE AREA

| ID | Full Screen | Purpose / Notes |
|---|---|---|
| V-26 | **Service Area** | Business coverage and zone configuration hub. |
| V-27 | **Coverage Setup / Edit** | Configure canonical business delivery coverage. |
| V-28 | **Zone Configuration** | Manage configured delivery zones outside the Today operational workspace. |
| V-29 | **Create Zone** | Create a new zone through the canonical backend path. |
| V-30 | **Edit Zone** | Rename/configure/enable-disable a zone where supported by backend rules. |

> Distinction: **Service Area** owns configuration. **Zones bottom nav** owns today's operational workspace.

## J. BUSINESS — STOREFRONT / APPEARANCE

| ID | Full Screen | Purpose / Notes |
|---|---|---|
| V-31 | **Storefront / Appearance** | Hub for vendor-facing branding/customer storefront configuration. |
| V-32 | **Storefront Preview** | Preview customer-facing storefront presentation. |
| V-33 | **Appearance / Branding** | Configure approved brand/storefront presentation properties. |
| V-34 | **Products** | Product/menu/catalog management surface. |
| V-35 | **Product Detail / Edit Product** | View/edit an existing product. |
| V-36 | **Add Product** | Add a product. |

### Product photography — tool/flow, not currently counted as permanent full screen
Cefflo Food Photography follows the principle: **same real food/product; environment is the creative area**. It must not silently recreate or materially alter the vendor's actual product.

## K. BUSINESS PROFILE

| ID | Full Screen | Purpose / Notes |
|---|---|---|
| V-37 | **Business Profile** | Business identity/settings hub. |
| V-38 | **Business Information** | Edit canonical business information. |
| V-39 | **Business Address** | Manage business address/location. |
| V-40 | **Business Hours** | Configure operating hours where relevant. |
| V-41 | **Delivery Settings** | **RECONCILIATION REQUIRED** — retain as inventory placeholder until responsibility is proven distinct from Service Area/Zones. |

> **Founder Gate:** V-41 must not duplicate Service Area, coverage, zone, planning or Rider operational settings. Merge/remove if no unique responsibility survives reconciliation.

## L. ACCOUNT — PROFILE

| ID | Full Screen | Purpose / Notes |
|---|---|---|
| V-42 | **Profile** | Logged-in user's account profile. Distinct from Business Profile. |
| V-43 | **Edit Profile** | Edit permitted personal/account profile fields. |

## M. ACCOUNT — SECURITY

| ID | Full Screen | Purpose / Notes |
|---|---|---|
| V-44 | **Security** | Account security hub. |
| V-45 | **Change Password** | Authenticated password change flow. |

### Security flow/state — not separate screen unless later promoted
- 2FA/security controls where actually supported
- Session/security feedback

## N. ACCOUNT — SETTINGS

| ID | Full Screen | Purpose / Notes |
|---|---|---|
| V-46 | **Settings** | General Vendor app/account settings hub. |
| V-47 | **Notifications** | Notification preferences/settings where supported. |
| V-48 | **Language** | App language preference. |
| V-49 | **Appearance** | Light / Dark / System preference. |

## O. SUBSCRIPTION / CEFFLO BILLING — **HOLD**

> **FOUNDER DECISION PENDING.** The screens below remain in the 60-screen inventory so the complete product journey is visible, but their payment provider, checkout model, renewal model, failure handling, billing architecture and final UX are **NOT LOCKED**. Do not implement payment architecture from assumptions in this document.

| ID | Full Screen | Purpose / Notes |
|---|---|---|
| V-50 | **Subscription / Plan** | Show current Cefflo subscription/entitlement. **HOLD for final model.** |
| V-51 | **Choose / Change Plan** | Plan selection/upgrade/downgrade. **HOLD.** |
| V-52 | **Subscription Checkout / Payment** | Vendor → Cefflo subscription payment. **HOLD.** |
| V-53 | **Payment Success** | Successful subscription transaction/activation result. **HOLD.** |
| V-54 | **Subscription Details** | Renewal/plan/subscription information. **HOLD.** |

### Billing states — not separate screens yet
- Processing
- Payment failure
- Payment cancellation
- Subscription expired/access gate
- Renewal issue
- Cancel subscription confirmation
- Upgrade/downgrade confirmation

### Explicit billing guardrails
- Do not infer a payment gateway.
- Do not infer cards, FPX, DuitNow, recurring debit, bank transfer or any specific payment method.
- Do not implement vendor-customer payment functionality.
- Do not implement ordinary customer invoices/receipts under this scope.
- Founder must explicitly resolve the Cefflo subscription/payment solution before V-50–V-54 become implementation-ready.

## P. SUPPORT

| ID | Full Screen | Purpose / Notes |
|---|---|---|
| V-55 | **Help & Support** | Support hub. |
| V-56 | **FAQ / Help Centre** | Self-service help content. |
| V-57 | **Contact Support** | Approved support contact/request flow. |

## Q. LEGAL / ABOUT

| ID | Full Screen | Purpose / Notes |
|---|---|---|
| V-58 | **Privacy Policy** | Cefflo privacy policy surface. |
| V-59 | **Terms of Service** | Cefflo terms surface. |
| V-60 | **About / App Information** | Version/build and relevant app/legal information. |

---

# 4. Navigation Map

## Primary Bottom Navigation

1. **Today** → V-11
2. **Orders** → V-12
3. **Zones** → V-16
4. **Riders** → V-20
5. **Menu** → secondary navigation surface; not counted as an additional full screen in this inventory unless final UI architecture promotes it to one.

## Secondary Navigation

### BUSINESS
- Team → V-23
- Service Area → V-26
- Storefront / Appearance → V-31
- Business Profile → V-37

### ACCOUNT
- Profile → V-42
- Security → V-44
- Settings → V-46
- Subscription → V-50 **[HOLD]**

### SUPPORT
- Help & Support → V-55
- Log Out → action/confirmation, not a full screen

### Legal/About discovery
Privacy Policy, Terms of Service and About/App Information should normally be reachable through Settings/About/support-related surfaces rather than cluttering primary navigation.

---

# 5. Full Screen Count

| Group | Count |
|---|---:|
| Entry | 1 |
| Authentication | 4 |
| Onboarding | 5 |
| Today | 1 |
| Orders | 4 |
| Zones / Delivery Operations | 4 |
| Riders | 3 |
| Team | 3 |
| Service Area | 5 |
| Storefront / Appearance | 6 |
| Business Profile | 5 |
| Profile | 2 |
| Security | 2 |
| Settings | 4 |
| Subscription / Billing | 5 |
| Support | 3 |
| Legal / About | 3 |
| **TOTAL** | **60** |

---

# 6. Not Counted as Full Screens

Unless later explicitly promoted, the following are UI states/components rather than additional pages:

- Bottom navigation shell
- Hamburger/Menu overlay or drawer
- Tabs
- KPI cards
- Recent Orders card/list
- Current Deliveries card/list
- Need Attention card/list
- Search
- Filters and sort
- Date picker
- Rider picker
- Zone picker
- Stop detail bottom sheet
- Confirmation dialogs
- Logout confirmation
- Delete confirmation
- Dispatch confirmation
- Success toast/snackbar
- Error toast/snackbar
- Loading/skeleton states
- Empty states
- Offline/retry states
- Form validation states
- Permission prompts
- 2FA steps unless final flow requires dedicated screens
- Product Photography flow unless later formalized as dedicated screens
- Payment processing/failure/expired states until subscription architecture is approved

---

# 7. Shared UI Families

The 60-screen count must **not** lead to 60 unrelated designs. Reuse a coherent Cefflo experience system.

### Family A — Authentication
V-02–V-05

### Family B — Guided setup/form
V-06–V-10, V-14–V-15, V-22, V-25, V-27, V-29–V-30, V-35–V-36, V-38–V-41, V-43, V-45

### Family C — Operational list/workspace
V-11, V-12, V-16, V-20, V-23, V-26, V-28, V-34

### Family D — Operational detail
V-13, V-17–V-19, V-21, V-24

### Family E — Settings/detail list
V-37–V-49, V-54–V-60

### Family F — Subscription
V-50–V-54 — **HOLD until Founder resolves payment architecture**

---

# 8. Required Reconciliation Before Implementation Lock

Before treating this as implementation-ready, compare all 60 IDs against the actual repo/routes/backend contracts and classify each as:

- **KEEP** — correct existing screen/scope
- **MERGE** — responsibility should be combined with another screen
- **REMOVE** — obsolete, duplicate or unsupported
- **NEW** — required but not implemented
- **EXISTS / POLISH** — already implemented but needs Experience System migration/polish
- **HOLD** — unresolved Founder/product decision

At minimum, reconciliation must verify:

1. V-41 Delivery Settings does not duplicate Service Area/Zones.
2. Product/storefront scope V-31–V-36 exists in the intended Grow launch scope.
3. Auth and onboarding routes V-02–V-10 match real account/business creation contracts.
4. Rider/team invitations V-22/V-25 use canonical invitation workflows only.
5. Zone create/edit V-29/V-30 use canonical RPC/backend paths.
6. Zone operational flow V-16–V-19 matches Ready → Review → Dispatch → Ongoing → Completed semantics.
7. V-50–V-54 remain **HOLD** until Founder explicitly approves subscription/payment architecture.
8. No ordinary invoice/receipt or vendor-customer payment workflows are reintroduced.

---

# 9. Founder Gates

### Gate A — Screen Inventory
Founder reviews the 60-screen map and may add, remove, merge or rename screens.

### Gate B — Subscription / Payment
**OPEN / NOT RESOLVED.** No provider or payment architecture is approved by this document.

### Gate C — Delivery Settings
Determine whether V-41 has a unique responsibility. Otherwise merge/remove.

### Gate D — Repo Reconciliation
Actual routes/components/backend contracts must be audited before implementation scope is frozen.

### Gate E — Experience System
All implemented screens must follow the approved Cefflo Light/Dark experience direction and reusable component system rather than being designed independently.

---

# 10. Definition of Done for This Master Map

This document is considered finalized only when:

- [ ] Founder has reviewed all V-01 through V-60.
- [ ] Every full screen has a clear unique responsibility.
- [ ] Duplicate pages have been merged/removed.
- [ ] Tabs, components, states and overlays are not incorrectly counted as pages.
- [ ] Actual repo/routes have been reconciled against the inventory.
- [ ] Each screen is classified KEEP / MERGE / REMOVE / NEW / EXISTS-POLISH / HOLD.
- [ ] Backend ownership and client boundaries are documented for operational screens.
- [ ] Subscription/payment screens remain HOLD until a Founder-approved solution exists.
- [ ] Final screen count is recalculated after reconciliation.
- [ ] Founder explicitly locks the resulting Vendor Flutter Screen Map.

---

## Current Working Baseline

**60 full screens**  
**V-01 → V-60**  
**Subscription/payment V-50 → V-54: HOLD / Founder Decision Pending**  
**V-41 Delivery Settings: Reconciliation Required**
