# CEFFLO --- LOCKED DECISIONS

Brand/product doctrine authority: `docs/cefflo/CEFFLO_BRAND_BRAIN.md`.
Where a decision below conflicts with the Brand Brain, the Brand Brain
wins; the decision is retained here for history and marked accordingly.

## D-01 Positioning

**STATUS: SUPERSEDED.** This decision reflected an earlier home-food-only
positioning. Current canonical positioning: Cefflo is a local same-day
delivery operating system for businesses that manage deliveries within
their own service area; food is an example, not the category boundary.
See `docs/cefflo/CEFFLO_BRAND_BRAIN.md` §1.1, §4. Retained below for
decision history only — not current doctrine.

> Cefflo = Operating System for Home-Based Food Businesses. Not primarily
> marketplace/rider company/GrabFood-style delivery platform.

The non-marketplace / non-rider-company / non-GrabFood-style framing
itself remains current doctrine (Brand Brain §3) — only the food-only
category boundary is superseded.

## D-02 Acquisition

Primary acquisition focus is vendors, not building a proprietary rider
network.

## D-03 Rider Model

Support vendor-owned/trusted rider teams through protected invitation/join,
not an open Cefflo Rider marketplace. One Rider Auth identity may belong to
multiple Vendor teams with explicit membership and strict authorization
boundaries.

## D-04 Customer Tracking

Tokenized customer tracking; no customer account required. The normal entry is
the shared tokenized link; manual token entry is not core Stage 4 scope. Tokens
require explicit expiry, revocation, rotation and protected recovery policy.

## D-05 Client Strategy

PWA-first for Stage 4. Future native Rider app does not block Stage 4
unless Founder explicitly changes scope.

## D-06 Code SOT

GitHub `main` is canonical code SOT unless explicitly superseded.

## D-07 Backend/Deployment

Supabase is current backend direction. Vercel is current web deployment
direction. Cloudflare remains part of the intended production DNS/edge
architecture. Preview/staging/production backend separation is required before
mutating test suites or production release.

## D-08 Release Policy

Normal updates should not require maintenance mode. Maintenance is
emergency/exception only. Prefer low-activity release windows,
backward-compatible backend changes, health checks and rollback. Cloudflare,
DNS, SSL and production-domain cutover belong only to the controlled
production-release phase after release, recovery and rollback gates pass.

## D-09 Payments

Vendor-controlled direct payment direction; COD is not core; riders
should not handle Cefflo cash.

## D-10 Engineering Method

No patchwork final fixes. Use scoped clean/root-cause implementation. Do
not redesign/refactor unrelated working areas. Preserve existing Vendor, Rider
and Customer UI shells and working protected backend foundations wherever
practical; integrate or adjust rather than rebuild wholesale.

## D-11 AI Ownership

**STATUS: SUPERSEDED.** This decision reflected an earlier fixed
single-executor model. Current agent roles and task routing are defined
by `docs/cefflo/agent-os/CEFFLO_AGENT_OS_CORE.md` §3 and §6: Claude is
the primary implementer for substantial Cefflo work (repo-wide audits,
architecture/reconciliation, multi-file implementation, large rollouts);
Codex is the bounded implementer/finisher for small, focused work;
ChatGPT orchestrates/plans for substantial tasks. Founder instruction
overrides normal routing. Retained below for decision history only —
not current doctrine.

> Codex is primary engineering executor and canonical code integrator.
> Claude is optional UI/prototype/review/specialist support, not parallel
> code SOT.

## D-12 Founder Authority

Founder approves protected production/security/billing/destructive
operations and final phase gates.

## D-13 Stage Discipline

Design future systems when useful, but build only when the current stage
needs them. Do not delay Stage 4 with later-stage
automation/native/regional features. Native Rider Flutter, complex autonomous
multi-agent orchestration, regional expansion and later-stage growth systems
are explicitly deferred.

## D-14 UI Launch Review

Before calling Vendor/Rider UI launch-ready verify: 1. exception/error
states; 2. urgent action hierarchy; 3. cross-app lifecycle/status
consistency.

## D-15 Naming

Brand: Cefflo. Administrative command center: FOUNDR.

## D-16 Business Authorization

Founder is final platform authority. Owner is the highest Vendor-business
authority. Operators/members receive explicit scoped permissions. Riders are
authorized only through team membership and delivery scope. Customers are
authorized only through valid tracking tokens. Lifecycle-sensitive writes must
use protected backend contracts; broad direct-table authority is not the target.

## D-17 Order and Delivery Planning

Vendor order approval/readiness is an explicit step before pickup semantics.
One delivery session/batch may contain multiple orders/stops. Batching, zones,
sessions, assignments and multi-drop delivery are required Stage 4 capabilities,
not legacy. Choose the simplest robust persisted/derived/hybrid zone contract
during implementation design. Operational outcomes must be backend-authoritative.

## D-18 Exceptions and Offline Promise

Exceptions use typed report/resolve/reassign/redelivery workflows with event
history. Vendor Stage 4 does not promise protected offline mutations; show
graceful network failure and retry. Rider Stage 4 supports practical PWA
degraded/network handling; native-grade offline/background GPS is future.
Availability remains simple and operationally necessary only.

## D-19 POD Integrity

Delivery completion must verify that the POD object exists in the correct
protected bucket/path, belongs to the order, was supplied under assigned-rider
authorization and has valid upload state. Fabricated, nonexistent, malformed,
foreign-order or foreign-rider POD paths must fail.

## D-20 Production Truth

Production must not confirm operational outcomes from mock, seeded, demo or
local-only state. Invalid tracking tokens expose no seeded customer/order data;
fabricated POD fallback is prohibited; rating success follows confirmed backend
persistence. Performance metrics derive from authoritative backend events/data.

## D-21 FOUNDR Stage 4 Scope

Minimum FOUNDR scope is Overview/Platform Health, Vendors, Riders, Delivery
Operations, required privileged controls, emergency Maintenance Control,
Feature Flags, Client Version Control, Audit Log, Integrations Health and
System/Security Health. Privileged actions require authorization,
confirmation/reason controls and append-only audit. Developer Mode remains
minimal and operational/diagnostic.

## D-22 Business Configuration and External Integrations

Business concepts/types primarily share configurable architecture; create
separate backend behavior only when genuinely required. The Vendor sales/order
page is required and feeds customer orders into the Vendor's Cefflo workflow.
External integrations are implemented only when required for functional Stage
4 or security/release requirements.

## D-23 Knowledge Reconciliation (2026-09-04)

A newer, Founder-approved, more granular SOT pack was reconciled into the repo at `docs/cefflo/sot/` on 2026-09-04 (see `docs/cefflo/sot/00_INDEX.md`). It supersedes `docs/cefflo/CEFFLO_BRAND_BRAIN.md` for brand/product/architecture doctrine (that file is retained, marked superseded, not deleted). Two clarifications from this reconciliation:

1. The new Architecture/Vendor-Web/Rider-Flutter-Master doctrine names Vendor Flutter and Rider Flutter as target first-class clients in Cefflo's canonical multi-client architecture. This describes the TARGET end-state, not a change to build sequencing. D-13's stage-gating for native Rider Flutter remains in force: it is a FUTURE capability per the Capability Truth States system, and its own source master (`docs/cefflo/sot/08_RIDER_FLUTTER_33_SCREEN_MASTER.md`) is self-labeled "Founder Review Required" with an unchecked Definition of Done. No Vendor Flutter master exists in this repo yet.
2. `docs/cefflo/sot/07_BUSINESS_LAUNCH_COMMERCIAL.md` (commercial/billing/go-live governance) is a new layer complementary to `docs/cefflo/launch/CEFFLO_GROW_V1_SCOPE_LOCK.md` (frozen V1 product/feature scope, 2026-09-03) — the two are not duplicates and neither supersedes the other.

Open gap surfaced by this reconciliation (not resolved, flagged for Founder attention): no Cefflo Pricing Master exists anywhere in this repository or in the reconciled knowledge pack. `docs/cefflo/sot/07_BUSINESS_LAUNCH_COMMERCIAL.md` §4 requires pricing to come from a Founder-approved Pricing Master, which does not yet exist.

## D-24 Knowledge Reconciliation, Second Pass (2026-09-04)

Three of D-23's four flagged gaps were filled by newly-supplied Founder documents, reconciled into `docs/cefflo/sot/`:

1. `docs/cefflo/sot/10_PRICING.md` (was: CEFFLO_PRICING_PLAN_MASTER_AUDIT.md) — status **CANDIDATE, NOT Founder-locked**. Every price/allowance in it (RM0/RM99/RM199/RM499/Custom, delivery/rider/zone/team caps) remains open per its own §16/§19 Definition of Done. This is the working input to `docs/cefflo/sot/07_BUSINESS_LAUNCH_COMMERCIAL.md` §4's Pricing Authority requirement, not itself a satisfaction of it — do not publish any figure from this file as final commercial truth.
2. `docs/cefflo/sot/09_VENDOR_FLUTTER_60_SCREEN_MASTER.md` (was: CEFFLO_VENDOR_FLUTTER_60_FULL_SCREEN_MASTER.md) — status **Working Master Baseline, Founder Review Required**, not implemented. Its own internal HOLD flags are preserved as-is: Subscription/billing screens V-50–V-54 remain HOLD pending a separately-approved Cefflo-subscription payment architecture (this is Vendor-paying-Cefflo billing, not vendor-customer payment — that boundary is unchanged), and V-41 Delivery Settings needs reconciliation against Service Area/Zones before lock. Same stage-gating logic as D-23 item 1 applies: this describes target scope, not authorization to begin Vendor Flutter implementation. The current LIVE Vendor client remains Vendor Web/Desktop.
3. `docs/cefflo/sot/marketing/07_MARKETING_MEMORY.md` (was: CEFFLO_MARKETING_MEMORY.md) — schema/doctrine only. Per its own §22, performance memory is intentionally EMPTY at initialization; no AI Marketing Engine implementation, n8n workflow, or real campaign evidence exists in this repo. Do not treat anything in this file as evidence of actual marketing results.

**Remaining open gap (unchanged from D-23):** `docs/cefflo/sot/08_RIDER_FLUTTER_33_SCREEN_MASTER.md` is still Founder-review-pending — no new Rider Flutter material was supplied in this pass.

No conflicts were found between the three new documents and existing doctrine; all three are additive fills of previously-flagged gaps, correctly labeled CANDIDATE/HOLD/Working-Master rather than promoted to LOCKED/LIVE.
