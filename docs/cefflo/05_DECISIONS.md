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
