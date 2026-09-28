# CEFFLO Engineering Baseline Reconciliation

**Status:** HISTORICAL FG-ENG-02 EVIDENCE PACKET — APPROVED WITH AMENDMENTS
**Evidence date:** 2026-09-19  
**Mode:** Non-destructive Git and dependency analysis  
**Merge/integration performed when captured:** No

> **D-40 approval addendum (2026-09-19):** Founder approved the curated
> clean-integration strategy using current stop
> `e8793900cc387c48c4cc30cd4328df5f0799043c` and Experience snapshot
> `e5d47cc7e310f91e71e9220bdda79eae08686ea3`. Recommendations below to
> restore Manrope or force historical `12 / 13 / 11 / 20 / 60 / 14` compact
> values are superseded. Inter remains active; safe current token values are
> preserved pending FG-ENG-03. This packet remains unchanged elsewhere as the
> pre-decision evidence record; the integration result records actual execution.

## 1. Branch snapshot

| Item | SHA |
|---|---|
| Shared merge base | `1b69084b9f955eba8c4be6af39fd3102af5b07c3` |
| Current product/decision snapshot before Engineering bootstrap | `2e02edc4d6e0eabdc15d4e9c028e9bce37a87ae1` |
| Current bootstrap input snapshot used by the packet generator | `734cc1c3990c81402df67b5d563df918f73da7cb` |
| Experience implementation snapshot | `e5d47cc7e310f91e71e9220bdda79eae08686ea3` |

The complete commit/file inventory is in `branch-inventory.json`. It contains
full 40-character SHAs, parents, dates, authors, subjects, touched paths, tree
hashes and branch-level changed-file inventories.

At the generated snapshot:

- Current had 3 unique commits: D-37/D-38, canonical master tracking, and the
  Engineering bootstrap contracts/configuration.
- Experience had 53 unique commits.
- Current changed 32 files from the merge base, predominantly canonical
  documentation and the new Engineering bootstrap package.
- Experience changed 103 files: 96 under `apps/`, plus static surfaces,
  shared brand assets and a prototype.
- The two unique path sets have **zero exact file-path overlap**. Git therefore
  presents no direct textual merge conflict at this snapshot.
- Semantic/product conflicts still exist and block a blind merge.

## 2. Unique commit inventory

### Current lineage

| Commit | Classification |
|---|---|
| `2e02edc4` | D-37/D-38: 42-screen Driver authority and Driver/Rider naming lock — KEEP |
| `5c01ab36` | Track Engineering and Cyber Security masters; record FG-ENG-01 — KEEP |
| `734cc1c3` | Phase 01 contracts, policies and documentation — KEEP |

### Experience lineage — web/shared foundation

| Commits | Classification |
|---|---|
| `db474a2e`, `ce55ce56`, `147c4166` | Invite/Marketing/Vendor/Rider Experience System consolidation — KEEP |
| `144881f4` | Yellow/Navy production logo adoption — KEEP |
| `d27b3a58`, `5f93e9a4`, `6505159e`, `68d68c5b`, `4f23bf82`, `51a6e4c2`, `a836afed` | Vendor Web C1–C4 and Rider Web repairs — KEEP |

### Experience lineage — Driver/Rider Flutter

| Commit | Classification |
|---|---|
| `21f002c3` | Incomplete 33-screen Rider scaffold predating D-37/D-38 — EXCLUDE FROM ACTIVE BASELINE |

The scaffold has no screen implementation or app entrypoint. Its route graph is
based on the superseded R-01–R-33 master and its user-facing naming predates
D-38. Backend repository research may be consulted later, but the scaffold must
not survive as an active parallel Driver architecture.

### Experience lineage — Vendor Flutter foundation and product UI

| Commits | Classification |
|---|---|
| `5210f85c`, `5d53101a` | Vendor Flutter import and first Experience System reconciliation — KEEP WITH MANUAL TOKEN VERIFICATION |
| `5d52fb28` | Vendor auth implementation — KEEP |
| `bc1d1be4`, `2370bcfa`, `60a203b4` | Full prototype, screen pass and onboarding — KEEP, prior visual-match claims remain unverified without canonical images |
| `606615b6`, `e0a21d16`, `f410b210`, `9e90f07a` | Audit routes and canonical navigation/path handling — KEEP |
| `f6510cc6`, `d97be6ff` | Responsive density and splash timing — KEEP SUBJECT TO BUILD/BEHAVIOUR TESTS |
| `5ac05945` | Inter typography migration — REQUIRES MANUAL INTEGRATION; Inter conflicts with locked Manrope |
| `36f1987b`, `ebdb32f8` | Operations screen/FAB/order-tracker polish — KEEP |
| `17e4121f`, `ee114a96` | Subscription/checkout work — EXCLUDE FROM ACTIVE ROUTES; V-50–V-54 remain HOLD |
| `3ca428ea`, `40294883`, `3dccab6e` | Settings, Today and active-navigation polish — KEEP |
| `a695b1fe`, `ace34a81`, `5647280d`, `0d4a9d63` | Density/input/operations/Today repairs — KEEP, reconcile locked token values |
| `c3373f52`, `42d11302` | Browser/PWA chrome behaviour — KEEP |
| `9320b102`, `a6470edc` | Modal and primary-button repairs — KEEP |
| `e22325c3`, `664baa05` | Storefront selector and sign-out/dead-control fixes — KEEP |
| `2ad65d58`, `6b41464f`, `cf7c66f3` | Edge-to-edge and Storefront template system — KEEP, source-reference claims remain evidence-only |
| `eb9fc0be`, `48f415dd`, `e4640e00`, `09b34761` | Template defect repairs — KEEP |
| `941ef28a`, `2e04cf7c`, `e5d47cc7` | V-13/V-14/order-entry/import work — KEEP |

### Experience lineage — superseded supporting artifact

| Commit/path | Classification |
|---|---|
| `97945118` / `previews/vendor-auth-prototype/` | EXCLUDE; standalone prototype superseded by real Flutter auth, no tracked consumer found |
| `apps/vendor_mobile/CLAUDE_UI_HANDOFF.md` | EXCLUDE; session handoff replaced by canonical masters and Task Packs |

## 3. Decision mapping

The shared merge base already contains D-33 through D-36. The current lineage
adds D-37/D-38 and the Engineering D-39 decision. Experience continued product
implementation without those later active pointers.

Material decision effects:

1. D-37 makes the 42-screen Driver master the only active UI/UX authority.
2. D-38 locks Cefflo Driver for the user-facing app and Rider for backend/API.
3. D-33 locks Manrope and the compact surface tokens.
4. The Vendor Flutter master keeps V-50–V-54 on HOLD.
5. D-39 authorizes only the Engineering work through this baseline gate.

`decision-map.json` records the machine-readable mapping.

## 4. Dependency mapping

Vendor Mobile is not a standalone mock. Its normal path uses
`supabase_flutter` and the canonical product backend; explicit
`CEFFLO_UI_PROTOTYPE=true` builds use deterministic demo data. V11 Today uses
the shared operations implementation through `today_content.dart`, making it a
valid future pilot surface after later gates.

Static Vendor/Rider/Invite/Marketing changes depend on the shared Experience
System and brand assets but introduce no schema migration.

The Rider/Driver scaffold depends on the superseded 33-screen route graph. Its
backend models/repository contain potentially reusable research, but keeping
the scaffold active would create two competing Driver architectures.

The full graph is in `dependency-map.json`.

## 5. Conflicts

No same-path Git conflict exists between the unique branch changes. The
blocking conflicts are semantic:

1. **Driver authority:** `apps/rider_mobile` implements a partial R-01–R-33
   architecture superseded by D-37/D-38.
2. **Typography:** Vendor Mobile uses Inter; canonical Experience System locks
   Manrope.
3. **Surface tokens:** Vendor Mobile currently uses 20px gutter, 16px card
   padding, 12px card gap, 22px section gap, 64px chrome and 18px card/input
   radius. Canonical values are 12/13/11/20/60/14.
4. **HOLD scope:** V-50–V-54 are implemented and reachable despite the
   canonical payment/subscription HOLD.
5. **Truth status:** SOT still says Vendor Flutter is not implemented, while
   the branch contains a substantial implementation.
6. **Reference evidence:** Original images used by visual-polish commits are
   not in a canonical reference registry, so previous “match” claims cannot be
   treated as current visual verification.

The complete conflict register and proposed resolution are in
`conflict-register.json`.

## 6. Superseded implementation

The following should not become active baseline truth:

- the incomplete `apps/rider_mobile` R-01–R-33 scaffold;
- the standalone Vendor Auth HTML prototype;
- the session-specific Claude UI handoff;
- Inter as Vendor Mobile's primary typeface;
- active/navigable Vendor subscription/payment V-50–V-54;
- untracked Wrangler, Android-generated, prototype and local audit files.

Existing unreachable rollback bodies in `vendor/index.html` remain a later
clean-replacement task. They are retained now because dependency and rollback
verification is incomplete.

## 7. KEEP FROM CURRENT

- The complete shared-base product/backend/test history.
- D-37 and D-38, including the 42-screen Driver master and active pointers.
- D-39, both canonical department/security masters and FG-ENG-01 limits.
- The Phase 01 contracts, role/risk/cost/egress policies and security docs.
- This baseline evidence packet.

## 8. KEEP FROM EXPERIENCE

- Invite and Marketing Prelaunch visual-token migrations.
- Vendor Web token consolidation and C1–C4 repairs.
- Rider Web token/dark-mode consolidation and marker repair.
- Yellow/Navy shared assets.
- Vendor Mobile backend adapter, auth, operations, canonical audit routes,
  non-HOLD screens, responsive fixes, tests and Storefront system, subject to
  the manual integration requirements below.

## 9. REQUIRES MANUAL INTEGRATION

1. Reconcile Vendor Mobile to Manrope and the exact D-33 compact tokens before
   it enters the active baseline.
2. Remove/disable V-50–V-54 routes, navigation and implementation while
   retaining their HOLD entries in the canonical screen manifest.
3. Update current-state/SOT status to acknowledge the selected Vendor Flutter
   implementation without calling it Founder-locked or production-ready.
4. Preserve the V11 shared implementation and deterministic audit path without
   running the pilot.
5. Keep the static Vendor rollback bodies until their dependencies and rollback
   value are proven; register them for later removal.

## 10. EXCLUDE FROM BASELINE

- `apps/rider_mobile/**`
- `previews/vendor-auth-prototype/**`
- `apps/vendor_mobile/CLAUDE_UI_HANDOFF.md`
- `apps/vendor_mobile/assets/fonts/inter/**`
- all unrelated untracked files in either worktree
- active V-50–V-54 route/navigation/screen implementation

Exclusion means absent from the new active tree. The original commits and
branches remain recoverable; no source branch is deleted or rewritten.

## 11. Recommended reconciliation specification

Use a **curated clean integration**, not a blind merge followed by repair
commits:

1. After FG-ENG-02, create `claude/engineering-baseline-phase-01` in a new
   isolated worktree from the exact FG-ENG-02 stop commit reported to Founder.
2. Import the selected Experience web/shared changes as one audited commit.
3. Import Vendor Mobile as a clean reconciled commit with Manrope/tokens fixed,
   HOLD scope absent, and excluded artifacts never introduced.
4. Update implementation-status documentation from verified evidence.
5. Run static and Flutter validation before recording the resulting tree.

This avoids importing known obsolete paths and constructing a patch mountain.

## 12. Exact proposed resulting baseline

The proposed active tree is:

```text
FG-ENG-02 stop tree from current branch
+ selected Experience Web/Rider/Invite/Marketing visual changes
+ selected shared Yellow/Navy assets
+ Vendor Flutter DEV/STAGING implementation
  - Inter primary typography
  - active V-50–V-54 subscription/payment scope
  - session handoff
  - obsolete Vendor Auth prototype
  - obsolete 33-screen Rider Flutter scaffold
+ canonical Manrope and D-33 compact tokens
+ evidence-backed status documentation
```

No resulting commit SHA is claimed before the Founder authorizes construction
of that tree. Fabricating a future SHA would not be exact evidence.

## 13. Risks

- Manual design-token reconciliation can cause broad screenshot changes and
  requires focused Flutter tests/render verification.
- Removing HOLD subscription routes may expose navigation/test assumptions.
- Prior visual polish cannot be independently confirmed without the original
  reference assets.
- Flutter SDK cache permissions and a reproducible renderer still need later
  Phase 01 work.
- GitHub CLI authentication remains invalid, although the separate Git remote
  dry-run path previously succeeded.
- Worktree-local untracked files must remain excluded and untouched.

## 14. Founder decision required

Approve, reject or amend the specification in `proposed-baseline.json` and
`founder-baseline-gate.json`.

Approval must explicitly confirm whether the curated result should:

- retain Current's D-37–D-39 authority and bootstrap package;
- integrate the selected Experience web and Vendor Mobile implementation;
- exclude the obsolete Rider scaffold/prototype/handoff;
- restore canonical Manrope and compact tokens;
- keep V-50–V-54 on HOLD and outside active implementation.

Until FG-ENG-02 is explicitly approved, no reconciliation worktree, merge,
cherry-pick, rebase, restore/import, branch deletion or product-code change is
authorized.
