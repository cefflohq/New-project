# CEFFLO --- AGENTS ROUTER

Status: Canonical Primary executor: Codex Final authority: Founder

## A-00 Purpose

This file is the mandatory router for every Cefflo engineering task. It
tells Codex which small canonical documents to load, how to scope work,
and which actions require approval.

## A-01 Source of Truth

-   GitHub `main` is canonical code SOT unless Founder explicitly
    approves another baseline.
-   Canonical docs live in `docs/cefflo/`.
-   Do not treat old exports, prototypes, screenshots, duplicate HTML
    files, historical deployments, or local snapshots as SOT without
    verification.
-   If code and docs materially conflict, report the conflict before
    changing architecture or locked behaviour.

## A-02 Mandatory Start

Before implementation: 1. confirm repository/branch; 2. inspect working
tree; 3. read this router; 4. read `04_CURRENT_STATE.md`; 5. route only
to documents relevant to the task; 6. identify exact scope and
acceptance criteria.

## A-03 Context Routes

-   Product/positioning → `01_PRODUCT.md`
-   Cross-system architecture → `02_ARCHITECTURE.md`
-   Phase/sprint/gate → `03_ROADMAP.md`
-   Current implementation/blockers → `04_CURRENT_STATE.md`
-   Locked decisions → `05_DECISIONS.md`
-   Vendor → `06_VENDOR.md`
-   Rider → `07_RIDER.md`
-   Customer tracking → `08_CUSTOMER_TRACKING.md`
-   FOUNDR → `09_FOUNDR.md`
-   Delivery status/assignment/POD contract → `10_DELIVERY_LIFECYCLE.md`
-   Supabase/backend → `11_SUPABASE.md`
-   Security/auth/privilege → `12_SECURITY.md`
-   Vercel/deployment → `13_VERCEL.md`
-   Cloudflare/domain/DNS/edge → `14_CLOUDFLARE.md`
-   PWA/cache/version/offline → `15_PWA.md`
-   QA/release/go-live → `16_QA_RELEASE.md`
-   Codex/Claude/VPS/Remote workflow → `17_AI_WORKFLOW.md`

Load multiple domain docs only when the task genuinely crosses those
contracts.

## A-04 Engineering Method

Use **Scoped Clean Implementation**: Scope narrowly → inspect
dependencies → identify root cause → implement completely → remove
obsolete/duplicate logic exposed by the change → validate proportionally
→ review diff → report accurately.

Do not use patchwork as a final solution. Do not stack CSS overrides,
duplicate handlers/business logic, preserve dead parallel
implementations, or rewrite unrelated working areas.

## A-05 Normal Autonomy

Within an approved non-sensitive scope Codex may
inspect/edit/create/refactor relevant files, run tests/lint/build,
perform non-destructive validation, commit logically related work, and
push normal-development work when repository policy permits.

## A-06 Founder Approval Required

Before executing: - production DB/schema migration; - production data
deletion/irreversible mutation; - secrets/API keys/credential changes; -
material auth/RLS/security-policy changes; - destructive Git/force
push/history rewrite; - production infrastructure/DNS changes; -
billing/payment/merchant changes; - disabling security controls; -
irreversible external-service actions.

Analysis/proposals are allowed without execution.

## A-07 Git Rules

Start from known state. Never overwrite unrelated work. Inspect diff
before commit. No secrets. No force push without Founder approval. One
logical task per commit where practical.

## A-08 Validation

Never claim PASS for tests not run. State: tested/pass, tested/fail,
inspected-only, blocked, or not testable.

## A-09 Completion Report

Report: scope; root cause/implementation; files changed; validation; Git
branch/commit/push; remaining risks/blockers.

## A-10 Efficiency Rule

Do not re-audit the whole repository for a small task. Read only the
routed context plus affected code/dependencies. Broaden scope only when
evidence requires it.
