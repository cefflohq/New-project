# CEFFLO PHASE 04 — VISUAL DNA REPOSITORY RECONCILIATION AUDIT

**Date:** 2026-09-11. Read-only. No files modified, deleted, committed, pushed, merged, or deployed as part of this audit.

---

## Executive verdict

**BLOCKED — REPOSITORY RECONCILIATION REQUIRED.**

The repository currently contains an explicit, dated, Founder-signed lock on Signal Lime (`docs/cefflo/05_DECISIONS.md` D-30, 2026-09-12) that directly conflicts with the Gold/Navy direction under evaluation. No new Visual DNA document exists anywhere in the repo or on any branch. No canonical design-token specification (typography, spacing, radius, elevation, icon family) exists anywhere in SOT — the only place these values are actually defined is inside Flutter source code on an unmerged feature branch. If Claude or Codex started Vendor/Rider UI implementation today from the repository alone, it would either build against Signal Lime (the only locked palette on record) or have no canonical basis for Gold/Navy at all.

## Current highest visual authority

For **Vendor Flutter**, `docs/cefflo/sot/00_INDEX.md` §1 states the authority chain explicitly:
> Product Truth → Architecture → Flow 3 Behavioural Contract → **approved Visual DNA** → Flutter implementation.

And explicitly: *"approved Design Lab/DNA outputs when locked — **none exist yet**."*

So the honest answer is: **there is no approved Visual DNA document today — the chain has an empty slot where one belongs.** In its absence, the next-highest authority any implementer would fall back to is `docs/cefflo/sot/06_BRAND_ASSETS_GOVERNANCE.md` (Signal Lime **locked** `#C7F000`, logo **locked**, both dated 2026-09-12), followed by `docs/cefflo/sot/05_BRAND_BRAIN.md`. Neither says anything about Gold or Navy.

## New Visual DNA MD status

**Does not exist.** Confirmed by:
- `find` across the full working tree for any file matching visual-dna/experience-system naming: no results.
- `grep` for the candidate hex codes `F0A83C` and `12213E` across the current branch and all local branches (`claude/*`, `codex/*`, `main`, `staging`): zero matches anywhere in the repository, in any `.md`, `.dart`, or `.json` file.

Everything from the Phase 04A exercise (the Navy/Gold analysis, the palette table, the four-screen board) exists **only** as a private Claude Artifact from this conversation — it was never written into this repository. This is exactly correct per your own instruction that "preview/reference work is NOT itself canonical implementation evidence," and it means item 1's answer is unambiguous: no path, no status, no authority, no commit — it isn't there.

## Canonical conflict table

| Document | Says | Conflicts with new direction? |
|---|---|---|
| `docs/cefflo/sot/06_BRAND_ASSETS_GOVERNANCE.md` §2 | "Signal Lime — **locked** at `#C7F000`" (dated 2026-09-12, D-30). "Purple and blue are **superseded** as Cefflo primary/signature colors." | **Yes — directly.** The new direction's primary accent (Gold) and dark anchor (Navy, a blue) are exactly the two things this document just finished explicitly ruling out. |
| `docs/cefflo/05_DECISIONS.md` D-30 | The decision record locking Lime and the logo, "Founder Baseline Closeout." | **Yes.** This is the actual authorization event being contradicted — not a stale doc, a **current, dated Founder decision**. |
| `docs/cefflo/sot/00_INDEX.md` §8 | "Signal Lime **LOCKED** at `#C7F000`" | **Yes**, restates the above at index level. |
| `docs/cefflo/sot/05_BRAND_BRAIN.md` | Lime/Black/White palette doctrine (original brand doctrine) | **Yes**, foundational version of the same conflict. |
| `docs/cefflo/CEFFLO_BRAND_BRAIN.md` (root, not `sot/`) | Older duplicate brand doctrine, already marked historical in §8 per the governance doc | Compatible-by-being-already-superseded — see Stale table below. |
| `apps/vendor_mobile/lib/core/theme.dart` (branch `claude/vendor-mobile-backend-integration`) | `CefColors.lime = Color(0xFFC7F000)`, used as the Material `ColorScheme.fromSeed` seed color and for selected-card outlines | **Yes — this is real, working implementation code**, not just doctrine. |
| `lib/main.dart` (branch `codex/cefflo-vendor-flutter-prototype`) | Ink/Graphite/Soft/Line/**Lime**/Muted palette, seeded the same way | **Yes**, same conflict, older/simpler prototype. |

## Stale/superseded file table

| Document | Recommended disposition | Reason |
|---|---|---|
| `docs/cefflo/CEFFLO_BRAND_BRAIN.md` (root) | **ARCHIVE/HISTORICAL** (already effectively treated this way) | `06_BRAND_ASSETS_GOVERNANCE.md` already calls its §8 "historically accurate but should be read alongside" the governance doc — it's already functionally demoted, just not formally moved. |
| `previews/cefflo-logo-identity-exploration/` | **KEEP UNCHANGED** (already correctly marked) | Already explicitly labeled "SUPERSEDED / HISTORICAL / NON-CANONICAL" in `06_BRAND_ASSETS_GOVERNANCE.md` §5. No action needed. |
| `docs/cefflo/audits/CEFFLO_*` (this session's earlier Phase 03 n8n audits) | **KEEP UNCHANGED** | Unrelated domain (Marketing Engine), not part of this conflict at all. |

There is **no genuinely stale Visual-DNA-specific document** to clean up yet, because none has ever been written — the conflict isn't old-doc-vs-new-doc, it's **current explicit lock vs. a direction that hasn't been written down anywhere in the repo at all.**

## Actual Flutter implementation findings

**Branch `claude/vendor-mobile-backend-integration`** (`apps/vendor_mobile/`) — the more complete, structured implementation:
- `lib/core/theme.dart` defines real tokens: `Gap` (gutter 12, cardPadding 13, cardGap 11, section 20, xs/sm/md/lg = 4/8/12/16), `Sizes` (chrome 60, icon 22, tapTarget 44, cardRadius 14), `CefColors` with **full Light and Dark mode token sets already defined** (canvas/card/border/chrome/textPrimary/textLabel/textSecondary/attention/iconColor).
- Lime is used narrowly and deliberately: `ColorScheme.fromSeed(seedColor: CefColors.lime)`, and an explicit code comment — *"active selection, primary controls and selected outline only. Never body text, never a generic filled content card."* This is a genuinely well-disciplined existing implementation, not a naive one.
- **No `BoxShadow`/`elevation` anywhere** — the component system is flat, border-only (`CefCard` uses a 1px/1.6px border, radius 14, zero shadow). This is stricter than "subtle shadow," it's currently zero-shadow.
- Icon family: `lucide_icons_flutter`, outline style, fixed 22px visual size inside a 44px tap target, explicitly "no icon tile, badge or decorative background."
- Typography: **no custom font family is loaded** — sizes/weights only (18/650, 16/650, 15/650, 14/500, 13/500, KPI display 29/600), system/Material default typeface. This is a real gap against the new direction's implied "considered typography" (my Phase 04A proposal specified Sora/IBM Plex; none of that exists in code).
- Header/bottom nav: flat white/chrome color, 60px each, explicit comment *"no lime underline beneath the title."*
- **Brand presence today is text-only** — `"Cefflo Vendor"` (or the business name) as a plain `Text` widget in the header and on the auth screen. No logo image asset is loaded anywhere in this Flutter app. This means there's no literal "logo repeated on every screen" violation to fix, but there IS a business-name-text-in-header-on-every-screen pattern that the new "brand presence only at genuine brand moments" rule should explicitly address one way or the other.
- Attention color already defined: `#C45050` (light) / `#D87878` (dark) — **different from the `#D8402F` proposed in Phase 04A.** Flag this specifically: if Gold/Navy is approved, the semantic-red value needs one deliberate decision, not two different reds drifting in parallel.
- No Success or Info/Route semantic tokens exist in code at all today — only `attention`.

**Branch `codex/cefflo-vendor-flutter-prototype`** (`lib/main.dart`) — single-file prototype, older/simpler:
- Uses an explicit `ink/graphite/soft/line/lime/muted` naming scheme — this is close to literally the "Black/White/Graphite/Lime" pattern named in your prompt as something to search for. Confirmed present, on this branch specifically.
- Heavier use of Lime than the other branch (backgroundColor on live indicators, toggles, avatars, buttons) — less disciplined than the `vendor-mobile-backend-integration` branch's "outline/selection only" rule.

**No Rider Flutter implementation exists anywhere.** Checked every relevant branch (`main`, `staging`, all `claude/*` and `codex/*` branches) — zero `.dart` files with "rider" in the path. The only Rider client that exists in code is the pre-existing web/PWA app at `rider/` (HTML/JS), which `00_INDEX.md` itself already documents as "the current LIVE Rider PWA," distinct from the not-yet-built Rider Flutter master spec.

**Components that would survive a palette migration cleanly:** `Gap`, `Sizes`, the flat/no-shadow card philosophy, the Lucide icon system, the 60px chrome geometry, the Light/Dark structural split (`CefColors` as a `ThemeExtension`) — all of these are palette-agnostic structure, not Lime-specific, and were clearly designed to be re-themed by swapping token values, not rewritten.

**Components that would require real repair, not just a token swap:** every literal `CefColors.lime` reference (selection outlines, seed color, toggles/switches on the prototype branch), the header/nav "no lime underline" comments (intent-correct, but needs re-verification once the accent is no longer Lime), the mismatched Attention red between branches, and the complete absence of any typography-family decision (there's nothing to "migrate" there — it has to be decided for the first time).

## Design-token completeness matrix

| Item | Status | Where |
|---|---|---|
| Brand palette | **CONFLICTING** | Locked to Lime in SOT (`06_BRAND_ASSETS_GOVERNANCE.md`); Gold/Navy exists only outside the repo |
| Semantic palette | **DEFINED BUT OLD / MISSING** | Only `attention` exists in code, and with two different values across two branches; no Success/Info tokens anywhere |
| Light Mode | **DEFINED BUT OLD** | Fully specified in `theme.dart`, keyed to the Lime seed |
| Dark Mode | **DEFINED BUT OLD** | Same — fully specified, same caveat |
| Typography family | **MISSING** | No custom face loaded anywhere in code or doctrine |
| Typography scale | **DEFINED BUT OLD** | Sizes/weights exist in `theme.dart`, not documented in any SOT |
| Font weights | **DEFINED BUT OLD** | Same as above |
| Line heights | **MISSING** | Not set explicitly in the `TextStyle` definitions found |
| Spacing scale | **DEFINED BUT OLD** (really: palette-agnostic, just undocumented) | `Gap` class in `theme.dart`; not in any SOT doc |
| Screen gutters | **DEFINED BUT OLD** | `Gap.gutter = 12` in code only |
| Component spacing | **DEFINED BUT OLD** | `Gap.cardPadding/cardGap/section` in code only |
| Card radius | **DEFINED BUT OLD** | `Sizes.cardRadius = 14` in code only |
| Button radius | **MISSING** | Not found as a distinct token from card radius |
| Input radius | **MISSING** | No form/input components found in the audited files |
| Border width | **DEFINED BUT OLD** | 1px / 1.6px (selected) in `CefCard`, code only |
| Shadow/elevation | **DEFINED BUT OLD** | Explicitly zero — a real design decision ("flat"), just undocumented as doctrine |
| Icon family | **DEFINED BUT OLD** | Lucide, outline, 22px — code only, undocumented in SOT |
| Icon sizes | **DEFINED BUT OLD** | `Sizes.icon = 22`, `Sizes.tapTarget = 44` |
| Header geometry | **DEFINED BUT OLD** | 60px, code only |
| Bottom nav geometry | **DEFINED BUT OLD** | 60px, code only |
| Cards | **DEFINED BUT OLD** | `CefCard`, code only |
| List rows | **MISSING** | Not confirmed in the files audited |
| KPI blocks | **DEFINED BUT OLD** | `KpiTile` referenced in `widgets.dart`, display size 29/600 |
| Status chips | **MISSING** | Not found as a distinct reusable component in the audited files |
| Buttons | **MISSING** | No dedicated button component found distinct from `CefCard`/`IconAction` |
| Inputs | **MISSING** | Not found |
| Sheets/dialogs | **MISSING** | Not found |
| Loading / Empty / Error / Blocked / Retry / Offline states | **MISSING** | None found in the files audited (may exist in unaudited screen files — flagged, not confirmed absent) |
| Logo usage rule | **CANDIDATE** | New rule (brand moments only) stated in your prompt, not yet written anywhere; current code has no logo image use at all, only text |
| Vendor/Rider shared rules | **MISSING** | No Rider Flutter code exists to compare against |
| Vendor-specific rules | **DEFINED BUT OLD** | Everything above, Vendor-scoped |
| Rider-specific rules | **MISSING** | No implementation exists |
| Preview/evidence format | **CANDIDATE** | The 9:16/2×2/no-device-frame format used in this session's artifact is a real, usable convention, but it has never been written into SOT as the required format |

Nothing above was invented — every "DEFINED BUT OLD" traces to an exact file and line found during this audit; every "MISSING" was checked for and not found in the files inspected.

## Proposed canonical hierarchy

**Yes, one new canonical Experience System MD is needed** — `00_INDEX.md` already reserves the slot for it and says none exists.

- **Proposed path:** `docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md`
- **Authority position in `00_INDEX.md`:** a new numbered domain (currently domains run 1–17), inserted logically right after domain 8 "Brand Assets" (which it depends on) and referenced from the authority chains of domains 1 (Vendor Flutter), 2 (Rider Flutter), and 4 (Vendor Web) in place of the current "approved Visual DNA — none exist yet" placeholder text.
- **Supersedes:** nothing outright — it would need to formally **update** `06_BRAND_ASSETS_GOVERNANCE.md` §2's Lime lock (not silently override it) and **extend** `05_BRAND_BRAIN.md`'s palette section.
- **Should be referenced by:** `00_INDEX.md` §1/§2/§4, `09_VENDOR_FLUTTER_60_SCREEN_MASTER.md`, `08_RIDER_FLUTTER_33_SCREEN_MASTER.md`, `03_VENDOR_WEB_DESKTOP.md`.
- **Must contain, at minimum** (to close every MISSING/CONFLICTING row above): brand palette (with the Lime→Gold/Navy decision made explicit, not implied), semantic palette (one attention red, reconciling the two existing values), Light/Dark token pairs, a real typography decision (family + scale + weights + line-heights), the full spacing/radius/border/shadow scale (formalizing what already exists in code), icon family, header/nav geometry, card/list/KPI/chip/button/input component specs, the five missing interaction states (loading/empty/error/blocked/offline), the logo-usage rule (brand moments only), and Vendor/Rider shared-vs-specific scoping.

## Exact cleanup/update plan

| Item | Action |
|---|---|
| `docs/cefflo/sot/06_BRAND_ASSETS_GOVERNANCE.md` §2 | **UPDATE IN PLACE** (if Gold/Navy is approved) — following its own established pattern: annotate the superseded Lime-lock text in place, don't delete it, exactly as it already did for the "candidate → locked" transition on 2026-09-12. |
| `docs/cefflo/05_DECISIONS.md` | **UPDATE IN PLACE** — append a new dated decision entry recording the Founder's Lime→Gold/Navy decision explicitly, the same way D-30 recorded the Lime lock. This is the one that actually matters most: the conflict is with a *decision*, not just a doc. |
| `docs/cefflo/sot/00_INDEX.md` §8, §1, §2 | **UPDATE IN PLACE** — palette status line and the two Flutter authority chains. |
| `apps/vendor_mobile/lib/core/theme.dart` (branch `claude/vendor-mobile-backend-integration`) | **UPDATE IN PLACE**, later, as an implementation task once the palette is canonical — token values change, the well-designed `Gap`/`Sizes`/`CefColors` structure itself does not need to be rewritten. |
| `lib/main.dart` (branch `codex/cefflo-vendor-flutter-prototype`) | **ARCHIVE/HISTORICAL** — this looks like an earlier, less disciplined prototype superseded by the `vendor-mobile-backend-integration` branch's structure; recommend confirming with whoever owns that branch before any deletion. |
| `docs/cefflo/CEFFLO_BRAND_BRAIN.md` (root) | **KEEP UNCHANGED** for this task — already correctly annotated as historical elsewhere; not blocking. |
| `previews/cefflo-logo-identity-exploration/` | **KEEP UNCHANGED** — already correctly excluded/labeled. |

Nothing is recommended for outright **DELETE** — every conflicting item is either a live decision that needs a new decision to supersede it, or real working code that needs a token update, not removal.

## Files that would change (if and when approved)

`06_BRAND_ASSETS_GOVERNANCE.md`, `05_DECISIONS.md`, `00_INDEX.md`, a new `12_EXPERIENCE_SYSTEM.md`, and (as a later, separate implementation step) `apps/vendor_mobile/lib/core/theme.dart`.

## Files that should NOT change

`05_BRAND_BRAIN.md`'s non-palette content, `09_VENDOR_FLUTTER_60_SCREEN_MASTER.md` and `08_RIDER_FLUTTER_33_SCREEN_MASTER.md`'s screen inventories/behavioral content (only their authority-chain references need updating, not their substance), the logo asset files themselves (no redraw, per standing rule and per your explicit instruction here), `previews/cefflo-logo-identity-exploration/`, anything in `apps/vendor_mobile` beyond the token layer (routing, state, data models are untouched by a palette change).

## Founder decisions required

1. **Explicit supersession of D-30's Lime lock.** This needs its own decision record, not an implication from a design artifact conversation — the repo currently treats Lime as canonically locked by name, in writing, with your own prior sign-off attached.
2. **Reconcile the two different Attention-red values** already live in code (`#C45050`/`#D87878` vs. the `#D8402F` proposed in Phase 04A) into one.
3. **A real typography decision** — nothing is locked anywhere today; this blocks more of the implementation than the colour question does.
4. **Confirm which Flutter branch is the canonical starting point** (`claude/vendor-mobile-backend-integration` looks structurally the stronger candidate; `codex/cefflo-vendor-flutter-prototype` looks like an earlier, less disciplined pass) before any token migration work begins.
5. **Decide the header brand-text question** — today "Cefflo Vendor"/business name appears in the header on every screen. Your new rule bars the *logo* from internal screens; it doesn't yet say whether business-name text in the header also counts.

## Recommended next execution step

Do not start UI implementation yet. The correct next step is authoring `docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md` itself as a Founder-review draft (still not implementation) — but that requires your decisions on items 1–5 above first, since several of them change what the document should say, not just how it's phrased.

---

# BLOCKED — REPOSITORY RECONCILIATION REQUIRED
