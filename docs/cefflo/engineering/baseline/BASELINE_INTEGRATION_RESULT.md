# CEFFLO Engineering Baseline Integration Result

**Gate:** FG-ENG-02 — APPROVED WITH AMENDMENTS (D-40)
**Branch:** `claude/engineering-baseline-phase-01`
**Base:** `e8793900cc387c48c4cc30cd4328df5f0799043c`
**Experience snapshot:** `e5d47cc7e310f91e71e9220bdda79eae08686ea3`
**Method:** curated file integration in an isolated worktree; no merge,
cherry-pick, rebase, source-branch mutation or deletion

The final baseline SHA is reported in the FG-ENG-02 gate response after this
evidence file is committed, because a commit cannot contain its own SHA.

## Integration commits

| Commit | Purpose |
|---|---|
| `0e611d8514214c92e7d5d369c04c319998990396` | Selected Experience web/shared surfaces and curated Vendor Mobile implementation |
| `88928aeb8bb1240a572105fd3fddb1d14d8fa93b` | D-40 decision, SOT lifecycle, typography/token and gate metadata reconciliation |

## Source commit accounting

The exact 53-commit Experience inventory, including every full SHA, subject and
touched path, is retained in `branch-inventory.json`. The inclusion rule is
deterministic: commits from the Experience snapshot that contribute to
`apps/vendor_mobile/**`, `invite/index.html`, `marketing/prelaunch/index.html`,
`rider/index.html`, `vendor/index.html`, or `shared/brand/**` are represented in
the selected tree, subject to the exact partial exclusions below.

Fully excluded Experience commits:

- `21f002c38c60d0fe5141b1c879e969407c3f4097` — obsolete Rider Flutter
  R-01–R-33 scaffold (`apps/rider_mobile/**`).
- `97945118ef1582aea1590397ecb4872dd01c6b7e` — superseded standalone Vendor
  Auth prototype (`previews/vendor-auth-prototype/**`).

Partially included commits:

- `bc1d1be4bdea2e21e2b0fa8313f95933a0b3c25a` — useful Vendor Mobile
  implementation retained; obsolete `CLAUDE_UI_HANDOFF.md` and active V-50–V-54
  implementation removed.
- `17e4121f41d57bc8f707f042f4748f038facd61b` — non-HOLD contributions, if
  present in the final snapshot, retained; Subscription Details route/screen
  excluded.
- `ee114a962f33827cd10864579131940f5f34612e` — reusable non-billing component
  changes retained; Subscription/Choose Plan/Checkout screens excluded.

The entire current lineage through
`e8793900cc387c48c4cc30cd4328df5f0799043c` is retained as the baseline parent,
including D-37, D-38, D-39, both canonical masters, bootstrap contracts and the
FG-ENG-02 evidence packet. Source branches remain unchanged and recoverable.

## Included implementation

- Vendor Web/Desktop Experience System consolidation and C1–C4 repairs.
- Rider Web styling/dark-mode consolidation and marker repair.
- Invite and Marketing Prelaunch Experience System presentation.
- Yellow/Navy shared brand assets.
- Vendor Mobile application, backend adapter, authentication, onboarding,
  operations, planning, storefront templates, responsive system, audit routes
  and tests, in DEV/STAGING lifecycle state.
- Inter plus locally bundled Noto Sans SC/Tamil fallbacks.

## Excluded or inactive implementation

- `apps/rider_mobile/**` — absent from the resulting tree.
- `previews/vendor-auth-prototype/**` — absent from the resulting tree.
- `apps/vendor_mobile/CLAUDE_UI_HANDOFF.md` — absent from the resulting tree and
  normal runtime context.
- V-50–V-54 — no enum, route specification, router mapping, Menu navigation or
  executable screen implementation; the preview audit manifest retains HOLD
  entries with no URL.
- Driver rebuild/reconciliation, Vendor V11, Engineering workflow activation,
  production deployment and n8n PostgreSQL upgrade — not performed.
- Static Vendor rollback bodies remain quarantined in place because dependency
  and rollback proof is incomplete; later verified removal remains open.

## Manual reconciliations

1. Removed V-50–V-54 active routes, router cases, screen implementations and
   Menu entry; changed their audit-manifest entries to HOLD with no route.
2. Updated route tests to assert 55 active master routes and the deliberate
   absence of V-50–V-54.
3. Kept Inter and amended D-33-derived active context under D-40; marked
   historical Manrope instructions superseded for Vendor and Driver app UI.
4. Preserved the current Vendor spacing/radius implementation and removed the
   claim that historical compact values were mandatory. Exact visual values
   remain unresolved until FG-ENG-03.
5. Reconciled Vendor Mobile lifecycle truth to IMPLEMENTED / INTEGRATION IN
   PROGRESS / UI NOT YET LOCKED / DEV-STAGING without claiming production
   readiness.

## Validation record

| Check | Result |
|---|---|
| `flutter analyze` | PASS — no issues |
| `flutter test` | PASS — 53 passed; 11 live staging-contract cases skipped because no staging config was supplied |
| `flutter build web --no-wasm-dry-run --dart-define=CEFFLO_UI_PROTOTYPE=true` | PASS — `build/web` produced; informational missing-CupertinoIcons font warning only, no build failure |
| Local static `npm run build` with loopback/local identity and a non-secret validation key | PASS |
| `npm run test:environment` | PASS — 30 tests |
| `python3 -m unittest discover -s tests -p 'f3_*.py'` | PASS — 96 tests |
| JSON parse of Engineering configuration/evidence | PASS |
| `git diff --check` | PASS |
| Active V-50–V-54 route/screen search | PASS — none present |
| Excluded-path check | PASS — all three obsolete path groups absent |

Generated `.dart_tool/`, Flutter `build/` and root `dist/` artifacts are ignored
and are not part of the baseline commit.

## Remaining failures and ambiguities

- Live staging-contract tests were not executed because FG-ENG-02 did not
  provide or authorize a new credential envelope. The tests skipped cleanly;
  no credential was fabricated or exposed.
- Exact spacing, radius, type scale, component density and screen-by-screen
  visual fidelity remain intentionally unresolved until a Founder-approved
  canonical reference is selected at FG-ENG-03.
- Prior visual-match commit claims are provenance only; the reference images
  are not present in a canonical versioned reference registry.
- Vendor V-41 Delivery Settings remains a documented reconciliation item.
- Static Vendor rollback bodies need dependency and rollback verification
  before safe removal.

## Security boundary

All work remained local and DEV/STAGING scoped. No production credential,
production DB administration, production Supabase service role, VPS/root,
Docker socket, generic remote shell, unrestricted generated command, workflow
activation, deployment or production action was introduced. Existing
deny-by-default Engineering role/tool/network/deployment configuration remains
unchanged. Flutter package resolution and SDK cache access were used only for
the approved local validation.

## Next gate

`FG-ENG-03 — Canonical Reference` is required before any Vendor V11 visual
pilot, E3 reference matching, or visual-token lock. FG-ENG-04 through FG-ENG-08
remain unapproved.
