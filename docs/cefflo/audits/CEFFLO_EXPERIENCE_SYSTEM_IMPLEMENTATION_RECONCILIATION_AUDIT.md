# CEFFLO Experience System — Implementation Reconciliation Audit

**Date:** 2026-09-11. **Canonical documentation checkpoint:** commit `cb766a7e8eab1f89f1f925f4489e283894ea8fe2`.
**Read-only.** No code, no documentation, no commit, no push, no merge, no deploy.
**Canonical visual authority for this audit:** `docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md` (locked, D-33).

---

## 1. Executive verdict

**BLOCKED — IMPLEMENTATION RECONCILIATION REQUIRED.**

Not because the Experience System is wrong — because the gap between it and reality is bigger than the documentation-side audit (`CEFFLO_PHASE_04_VISUAL_DNA_REPOSITORY_RECONCILIATION_AUDIT.md`) could see. That audit correctly found Lime live in one Flutter branch. This audit finds Lime live in **four full production web surfaces** (`vendor/index.html`, `rider/index.html`, `invite/index.html`, `marketing/prelaunch/index.html`), **zero shared token infrastructure** anywhere in the repository (every surface is an independent, self-contained HTML file — no shared stylesheet, no shared component layer), **three different typefaces already in production** (none of them Manrope), **internal token duplication inside the two largest files** (Vendor Web has 5 separate `:root` blocks, Rider has 6), and a genuine coverage gap in the new SOT itself (no Warning semantic token, even though the live Vendor client already has one). None of this blocks approving the *direction* — it blocks starting a blind, repo-wide token sweep, which would break things. A sequenced, surface-by-surface plan is required first.

## 2. Current implementation topology

Every CEFFLO product surface is a large, self-contained, single-file (or near-single-file) HTML/CSS/JS application. There is no build step for these web surfaces beyond the static-asset copy in `scripts/build-static.mjs`, no CSS framework, no component library, no shared stylesheet. Vendor Flutter is the one surface with real architectural separation (tokens/screens/widgets in distinct files), but it lives on an unmerged branch, not `HEAD`.

## 3. Branch/worktree truth

| Branch | Contains | Last commit | Status |
|---|---|---|---|
| `claude/flow-3-vendor-web-desktop-completion` (current, = HEAD `cb766a7`) | All live web surfaces, the now-canonical Experience System doc | 2026-09-11 | Canonical checkpoint for this audit |
| `claude/vendor-mobile-backend-integration` | `apps/vendor_mobile/` — the leading Vendor Flutter evidence | 2026-09-08 | Real, structured, partial (16/60 screens) — not merged |
| `codex/cefflo-vendor-flutter-prototype` | Single-file `lib/main.dart` (2,502 lines) + `lib/scenes.dart` (496 lines) | 2026-09-05 | Older, less disciplined, heavier Lime usage — de-prioritized per D-33 |
| `codex/cefflo-vendor-mobile-prototype`, `codex/full-app-ui-system`, `codex/vendor-auth-production` | No Flutter/rider `.dart` files found; contain non-Flutter preview/migration work | various | Not Flutter implementation evidence |
| No branch anywhere | Rider Flutter | — | Confirmed, does not exist |

## 4. Surface-by-surface compliance matrix

| Surface | Path | Status | Font | Lime hits | Dark mode | Shadow | Radius | Duplication |
|---|---|---|---|---|---|---|---|---|
| Vendor Web | `vendor/index.html` (8,322 lines) | LIVE, first-class | Poppins | 3 (root vars) | **None** | 98 uses, already established | pill buttons + 12px inputs already | **5 separate `:root` blocks** |
| Vendor Flutter | `claude/vendor-mobile-backend-integration` branch | Partial evidence, not merged | System default | 1 (seed color) | Full token pair exists | **Zero** (deliberately flat) | 14px cards, no pill buttons yet | Clean, single source |
| Rider Web/PWA | `rider/index.html` (4,116 lines) | LIVE, current Rider client | Poppins | 38 (heaviest) | **Substantial — 123 `data-theme="dark"` references** | 96 uses, already established | 219 radius declarations | 6 `:root` blocks (mostly density-tier overrides, needs direct inspection) |
| Rider Flutter | — | **Does not exist** | — | — | — | — | — | — |
| Invite | `invite/index.html` (97 lines) | LIVE, minimal | **Inter** (differs from Poppins elsewhere) | 1 | None | 2 uses | small | 1 root block, clean |
| Customer | `customer/index.html` (115 lines) | LIVE, minimal, "narrow public projection" per `00_INDEX.md` | Poppins | **0** | None | 6 uses | small | clean |
| Marketing (prelaunch) | `marketing/prelaunch/index.html` (133 lines) | Built this session, not yet publicly live | Inter | 1 | None | 0 | small | clean |
| Marketing (main site) | `marketing/index.html` (1,467 lines) | LIVE public site | **System font stack** (a third, different typeface entirely) | **0** | None | 47 uses | moderate | clean |
| FOUNDR | `foundr/index.html` (2,246 lines) | LIVE, internal Command Center | Poppins + **SF Mono** (dedicated data mono face already in use) | **0** | None | 10 uses | moderate | clean |
| Shared tokens/components | — | **Do not exist** | — | — | — | — | — | — |

## 5. Signal Lime implementation inventory

Every remaining `#C7F000` occurrence in a `.html`/`.css`/`.js`/`.dart` file, classified:

| File | Count | Classification |
|---|---|---|
| `rider/index.html` | 38 | **Live implementation** — CSS variables (`--purple`, `--purple-strong`) and direct literals across route/map/action components |
| `vendor/index.html` | 3 | **Live implementation** — `--primary`, `--card-outline-active` |
| `invite/index.html` | 1 | **Live implementation** — `--action` |
| `marketing/prelaunch/index.html` | 1 | **Live implementation** — `--lime` |
| `apps/vendor_mobile/lib/core/theme.dart` (branch, not HEAD) | 1 | **Branch evidence, not live on HEAD** — `CefColors.lime` seed |
| `lib/main.dart` (branch `codex/cefflo-vendor-flutter-prototype`, not HEAD) | many | **Branch evidence, not live on HEAD**, de-prioritized |
| Doctrine files (`05_BRAND_BRAIN.md`, `06_BRAND_ASSETS_GOVERNANCE.md`, both Flutter masters, two marketing docs) | multiple | **Historical, now annotated superseded** — resolved by D-33, not implementation |
| `docs/cefflo/05_DECISIONS.md` (D-25 through D-33) | multiple | **Decision ledger — correctly immutable history** |

**43 live implementation occurrences across four production web surfaces remain unresolved.** This is the real number, not the smaller Flutter-only figure the documentation-side audit reported.

## 6. Hard-coded colour inventory

Rough count of hex literals appearing **outside** any `:root` token block (i.e., not token-driven):

| File | Hardcoded hex literals |
|---|---|
| `rider/index.html` | 482 |
| `vendor/index.html` | 267 |

This is the single most important number in this audit for scoping the work: token migration alone (editing `:root` values) reaches a minority of the actual colour usage in the two largest surfaces. The majority of colour decisions in both files are hardcoded inline, not token references — genuine structural repair, not a find-and-replace.

## 7. Design-token/component inventory

**No shared design-token file or shared stylesheet exists anywhere in the repository.** Confirmed: no `<link rel="stylesheet">` in any product HTML file; `shared/client.js` and `shared/config.js` are pure JavaScript (API/session logic and environment config respectively) with zero styling content. Every product surface embeds its own complete `<style>` block and re-derives its own token names independently — `vendor/index.html` uses `--primary`/`--bg-app`/`--card-bg`; `rider/index.html` uses `--purple`/`--page`/`--border`; these are two different naming conventions for conceptually the same tokens, with no shared source of truth between them.

**Within `vendor/index.html` itself**, the two `:root` blocks shown side-by-side in this audit's evidence gathering already disagree with each other: the first (line 15) has no semantic colour tokens at all; the second (line 656) adds `--success`/`--warning`/`--danger` with soft-tint variants that the Experience System doesn't yet define an equivalent for (no Warning token exists in `12_EXPERIENCE_SYSTEM.md` §2). **This is a real, disclosed gap in the new canonical SOT**, not an implementation problem — Warning needs to be added to `12_EXPERIENCE_SYSTEM.md` before Vendor Web's existing Warning usage can be reconciled against it.

## 8. Vendor Flutter reconciliation findings

Routes are fully registered (all 60 `V-IDs` present in `routes.dart`), but `router.dart`'s own `buildScreen()` switch statement shows the real picture honestly: **16 of 60 routes map to real implemented screens; the remaining 44 fall through to `NotMigratedScreen`**, a widget that states plainly *"This route is in the approved inventory but has not been migrated to Flutter yet... it is not a working screen."* This is exactly the kind of disclosed, non-fabricated completion state this whole reconciliation effort depends on being able to trust.

**Reusable, untouched by visual migration:** `AppScope`/state management, `vendor_repository.dart` (real backend wiring against canonical schema), the full route registry, `Gap`/`Sizes` spacing tokens (already validated reusable in `12_EXPERIENCE_SYSTEM.md` §5).

**Reusable architecture, needs token values updated, not rebuilt:** `CefColors` as a `ThemeExtension` (the pattern is sound, only the seed colour and shadow behaviour need to change), `CefCard`/`IconAction`/`SectionHeading`/`KpiTile` (structurally correct, currently zero-shadow and Lime-seeded).

**Obsolete styling specifically:** zero-shadow doctrine (now superseded by §5A's restrained-shadow lock), Lime seed color, no typography decision at all (Manrope now locked, nothing in this branch reflects it), no pill-radius buttons yet.

**16 already-built screens (Today, Orders, OrderDetail, NewOrder, EditOrder, Zones, ZoneDetail, ReviewDispatch, ServiceArea, CoverageEdit, Riders, RiderDetail, Team, Products, Settings, Appearance):** candidates for **visual-only repair** — token/shadow/typography swap, not structural rebuild. Their spacing/radius/geometry already matches the locked Experience System per the earlier Gate Matrix's KEEP classifications.

**44 stubbed screens:** genuinely missing, not a visual-repair task — building them is new screen construction against `09_VENDOR_FLUTTER_60_SCREEN_MASTER.md`'s behavioural spec, a separate and larger work item than this Experience System migration.

## 9. Rider Flutter repository truth

**No Rider Flutter implementation exists anywhere in this repository.** Checked every branch again for this audit, same result as the documentation-side audit. This is not inferred from the Rider Web/PWA's maturity — the PWA is a completely separate codebase (plain HTML/CSS/JS, not Flutter) and its existence says nothing about Flutter progress. **What genuinely can be shared with Vendor Flutter without incorrectly coupling the two apps:** the token/theme layer only (`CefColors`, `Gap`, `Sizes` — pure design values, product-agnostic), and possibly the `CefCard`/`IconAction` primitive widgets if extracted into a shared package. Routing, state management (`AppScope`), and data models are Vendor-specific and must not be shared or assumed reusable — Rider's operational model (runs/stops, one-handed use, GPS/navigation handoff per `08_RIDER_FLUTTER_33_SCREEN_MASTER.md` §9-11) is materially different from Vendor's.

## 10. Web/PWA reconciliation findings — migrate/retain/supersede classification

| Surface | Recommendation | Why |
|---|---|---|
| `invite/index.html` | **MIGRATE NOW** | Smallest surface (97 lines), 1 Lime reference, lowest risk — good pilot to prove the token-migration pattern before the two large surfaces |
| `marketing/prelaunch/index.html` | **MIGRATE NOW** | Built this session, not yet publicly live, small (133 lines), 1 Lime reference — no live-user risk |
| `vendor/index.html` | **MIGRATE DURING PRODUCT-SPECIFIC POLISH** | Live, first-class, large (8,322 lines), internally duplicated token system needs resolving as part of the work, not as a blocking prerequisite to everything else. Too large/risky for a blind sweep. |
| `rider/index.html` | **MIGRATE DURING PRODUCT-SPECIFIC POLISH** | Live, large (4,116 lines), and specifically: **its existing dark-mode implementation is valuable prior art** — more complete than the Experience System's own still-provisional dark values. Reconcile toward it, don't discard it. |
| `marketing/index.html` (main site) | **Founder call needed** | Zero current Lime usage, but a third distinct typeface already in place and the highest public-visibility surface in the audit. Leaning toward product-specific polish given size and stakes, but I don't have visibility into its own roadmap/redesign plans to be definitive. |
| `customer/index.html` | **RETAIN TEMPORARILY** | Minimal (115 lines), essentially no current branding applied — low priority, revisit when Customer Tracking gets real design investment |
| `foundr/index.html` | **RETAIN TEMPORARILY, open question** | Zero Lime usage already, but deliberately uses a dedicated data-mono typeface (SF Mono) for an internal admin/data tool — worth an explicit Founder decision on whether FOUNDR should adopt the consumer-facing Yellow/Navy identity identically, or keep a more utilitarian internal visual language, before migrating it either way |

**None recommended for REMOVE or SUPERSEDE** — every surface is live, functioning product, not obsolete material.

## 11. Shared-component opportunities

None exist today; several are worth creating **as part of**, not before, the migration: a single shared CSS custom-property token file (one canonical `--cefflo-*` naming convention, replacing the `vendor/index.html` vs `rider/index.html` divergent naming), a shared status-chip/button pattern (currently each surface hand-rolls its own), and — longer-term — extracting the Flutter `CefColors`/`Gap`/`Sizes` layer into a package Vendor and Rider Flutter can both depend on once Rider Flutter exists. None of this is a prerequisite to starting visual repair; it's an efficiency opportunity to flag alongside the first real migration pass.

## 12. Product-behaviour guardrails — must not change during visual migration

- Vendor Flutter's `vendor_repository.dart`, `app_state.dart`, `routes.dart`'s route *definitions* (styling of `NotMigratedScreen` may change; its existence and the route registry may not).
- Every web surface's inline JavaScript business logic (order/zone/rider state handling, `backend.js` files) — these files mix presentation and logic; visual repair must touch CSS/markup only, never the JS logic paths, and must be verified not to have moved/renamed any element an existing script selector depends on.
- `shared/client.js`/`config.js` — pure logic, out of scope entirely.
- Backend schema, migrations, RPCs — entirely out of scope, no visual work touches these.
- The 44 `NotMigratedScreen` stub routes' *honesty* — any visual work must not accidentally make a stub look like a finished screen.

## 13. Migration dependency order

1. **Add the missing Warning semantic token to `12_EXPERIENCE_SYSTEM.md`** (documentation fix, blocks nothing else but should happen before Vendor Web token work references it).
2. **Resolve `vendor/index.html`'s internal 5-root-block duplication into one canonical token set** — must happen before or during its migration, not after (migrating five divergent token sources independently would multiply the work and risk further drift).
3. **Pilot: `invite/index.html` and `marketing/prelaunch/index.html`** — smallest, lowest-risk, proves the pattern.
4. **Vendor Flutter token layer** (`theme.dart` only — well-contained, no screen-by-screen risk) — can happen in parallel with step 3, it's a different codebase entirely.
5. **`vendor/index.html` and `rider/index.html` full migration** — the two large, live, high-stakes surfaces. Rider specifically needs its dark-mode values reconciled *with* the Experience System's dark-mode plan (§3.2 of the SOT), not overwritten by it.
6. **`marketing/index.html`, `customer/index.html`, `foundr/index.html`** — lower priority, pending the open Founder questions noted above.
7. **The 16 built Vendor Flutter screens' visual-only repair** — can happen alongside step 4-5, same codebase.
8. **The 44 missing Vendor Flutter screens' construction** — explicitly a separate, later, larger work item, not part of this Experience System migration.

## 14. Claude heavy-implementation boundary

Claude should own: the Vendor Web token-duplication resolution (step 2 — requires judgment about *why* five root blocks exist and how to merge them safely, not mechanical find-and-replace), the Vendor Flutter `theme.dart` token/shadow update (step 4 — small, contained, architecturally significant), and the two pilot migrations (step 3 — establishes the pattern Codex batches will follow). These are the places where getting the *approach* right matters more than volume of files touched.

## 15. Codex UI-repair boundary

Codex should enter **after** steps 1-4 above are done and validated, for: the bulk of `vendor/index.html` and `rider/index.html`'s hardcoded-hex-literal cleanup (§6 — hundreds of individual, mostly-mechanical replacements once the canonical token set exists to point them at), the 16 built Vendor Flutter screens' visual-only repair (once the token layer is updated, each screen's own repair is bounded and repetitive), and — once real designs exist for them — basic visual shells for the 44 stub screens. Codex should work in isolated worktrees, batched by the groupings in §16, and should never touch `vendor_repository.dart`, `app_state.dart`, route definitions, or any `backend.js` file's logic.

## 16. Proposed screen/component repair batches

- **Batch A (Claude):** Vendor Web token consolidation (5 root blocks → 1), Warning token added to SOT.
- **Batch B (Claude):** `invite/index.html` + `marketing/prelaunch/index.html` full migration (pilot).
- **Batch C (Claude):** Vendor Flutter `theme.dart` — Yellow/Navy/Manrope/shadow token update only, no screen files touched yet.
- **Batch D (Codex):** Vendor Flutter — the 16 built screens, visual-only repair, one screen or logical group per worktree pass.
- **Batch E (Codex):** `vendor/index.html` — hardcoded-hex cleanup by page/section (this file is large enough that it likely has internal section boundaries worth batching by, e.g. auth flow, dashboard, orders, zones, settings).
- **Batch F (Codex):** `rider/index.html` — same approach, with explicit instruction to reconcile toward its existing dark-mode implementation rather than discard it.
- **Batch G (later, Founder-gated):** `marketing/index.html`, `foundr/index.html`, `customer/index.html` — pending the open questions in §10.

## 17. Tests/preview evidence required

This repository already has an established convention for exactly this kind of work: `tests/s4_10a_product_catalog_preview.py` through `s4_10d_order_page_theme_preview.py`, paired with static mockup boards in `previews/`. Recommend following this same pattern for each batch above — a preview artifact and a lightweight structural test per surface, not a new tooling investment. No visual-regression/screenshot-diff tooling (Playwright, Percy, etc.) exists in this repository today; worth a Founder decision on whether the scale of this migration justifies introducing one, but not a blocker to starting.

## 18. Exact files/directories expected to change

`docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md` (Warning token addition), `invite/index.html`, `marketing/prelaunch/index.html`, `vendor/index.html`, `rider/index.html`, `apps/vendor_mobile/lib/core/theme.dart` and `apps/vendor_mobile/lib/ui/widgets.dart` (on the `claude/vendor-mobile-backend-integration` branch, not `HEAD`), and eventually the individual Vendor Flutter screen files under `apps/vendor_mobile/lib/ui/screens/`.

## 19. Files/systems that must NOT change

Everything named in §12, plus: the master logo assets, `05_DECISIONS.md` (append-only), any Supabase migration/RPC, `shared/client.js`/`config.js`'s logic, and — until its own separate authorization — `codex/cefflo-vendor-flutter-prototype` (de-prioritized, not deleted).

## 20. Risks/blockers

- Vendor Web's 5-root-block duplication is not yet understood well enough to say confidently whether merging them is purely mechanical or hides an actual behavioural dependency (e.g. a section-specific override that matters) — needs direct line-by-line reading before Batch A starts, not assumed safe from this audit's evidence alone.
- Rider's dark-mode implementation is real and substantial; reconciling it against the Experience System's still-provisional dark values (flagged as open in `12_EXPERIENCE_SYSTEM.md` §3.2 itself) risks becoming a two-way negotiation rather than a one-way migration — budget for that.
- No visual-regression tooling means repair correctness relies on manual review and the existing preview-script convention — real but lower-fidelity safety net for changes at this scale (hundreds of hardcoded values across two 4,000-8,000-line files).
- The Warning-token gap must be closed in the SOT before Vendor Web's migration reaches its warning-state UI, or that work will stall on an undefined value.

## 21. Recommended implementation sequence

Batches A → B → C (Claude) first and validated, then D/E/F (Codex) in parallel once their respective token foundations exist, G deferred pending Founder decisions on `marketing/index.html` and `foundr/index.html`'s scope.

---

# BLOCKED — IMPLEMENTATION RECONCILIATION REQUIRED
