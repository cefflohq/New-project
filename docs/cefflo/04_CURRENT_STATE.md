# CEFFLO --- CURRENT STATE

Status: Living document. Update only from verified evidence.

## CS-00 Current Phase

Current planned phase: **Phase 1 --- Baseline & SOT Lock** after Phase 0
workstation completion.

## CS-01 Verified AI Workstation

Verified during setup: - Contabo Ubuntu 24.04 desktop accessible; -
Linux user `cefflo` operational with sudo; - Git/curl/build tools
installed; - Node/npm available; - GitHub CLI authenticated as
`cefflohq`; - repo `cefflohq/New-project` cloned; - branch `main` clean
and tracking `origin/main` at verification time; - GitHub push dry-run
succeeded; - Codex installed and authenticated with ChatGPT; - Codex
sandbox warning resolved for current session/config; - ChatGPT Desktop
Linux installed; - Android Remote connected to VPS/workspace
`New-project`; - Remote read-only repo/GitHub verification succeeded.

Re-verify mutable facts before relying on them later.

## CS-02 Known Product/Code History

Historically available implementations include Vendor PWA, Rider PWA,
Customer Tracking, Supabase foundation and tests. Historical PASS
results are not proof of current production state. Phase 1 must verify
current repo/deployments.

## CS-03 Historical Backend Evidence

Previous work reported migrations for businesses/members, riders,
delivery sessions, orders, assignments, stops, events, locations,
tracking tokens and ratings; RLS/negative/E2E local tests had passed at
points in development. Treat as leads to verify, not current truth.

## CS-04 Known Production Risk

Phone/SMS auth has previously been disabled/not operational in
production. Re-verify before Stage 4.

## CS-05 Vendor Baseline Risk

Historical confusion existed between older local Vendor files and a
Vercel deployment. Phase 1 must identify the actual active canonical
Vendor implementation and deactivate/label obsolete duplicates without
deleting blindly.

## CS-06 Current Required Work

1.  complete repository inventory;
2.  map deployments/domains;
3.  identify active/legacy implementations;
4.  audit current backend/tests/config;
5.  produce verified Stage 4 gap report;
6.  update this file from evidence.

## CS-07 Status Vocabulary

For every component use only: - VERIFIED DONE - PARTIAL - MISSING -
BLOCKED - FUTURE - DECISION REQUIRED - UNKNOWN / NEEDS AUDIT

Never convert historical claims into VERIFIED DONE without evidence.
