**Status:** CANONICAL — Founder-approved, merged into repo 2026-09-04
**Repo-reconciliation note:** Net-new canonical domain; no equivalent asset-governance doc existed in the repo before this reconciliation. Complements `docs/cefflo/CEFFLO_BRAND_BRAIN.md` §8 (Visual Identity), which remains historically accurate but should be read alongside this file for the fuller asset-registry/logo-lock governance model.
**Reconciliation update (2026-09-12, Founder baseline closeout — see `docs/cefflo/05_DECISIONS.md` D-30):** §2 and §5 below described the logo as unlocked and Signal Lime as a candidate. Both are now Founder-locked. §2 and §5 are corrected in place; the original text is annotated, not deleted, so the history of what changed and when remains traceable. Canonical logo asset: `docs/cefflo/brand/assets/logo/cefflo-logo-official.png` (plus transparent/wordmark variants in the same folder) — see §5.
**Reconciliation update (2026-09-11, Experience System canonicalization — see `docs/cefflo/05_DECISIONS.md` D-33):** §2's Signal Lime lock is superseded as current colour authority — CEFFLO Yellow `#FEC819` is now the locked primary accent. §2 is annotated in place, not deleted. The logo lock from D-30 is unaffected. Full current palette authority: `docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md`.
**Reconciliation update (2026-09-11, master logo asset set updated — see `docs/cefflo/05_DECISIONS.md` D-35):** §5's canonical production asset list below is superseded by four new Founder-supplied files with the mark's colour treatment brought in line with D-33 (Signal Lime arrow → CEFFLO Yellow, black/background → Navy). The D-30 geometry lock itself is unchanged — this is a production-asset-set update, not a redesign. §5 is corrected in place; the original D-30 file list is retained below as historical, not deleted.

---

# CEFFLO — BRAND ASSETS & IDENTITY GOVERNANCE SOT
**Status:** Canonical Asset Governance
**Version:** 1.0 — 2026-09-04
**Owner:** Founder

## 1. Purpose
Separate what is already locked about Cefflo identity from what is still under exploration, so generated logos/mockups cannot accidentally become canonical brand assets.

## 2. Locked Brand Foundation
Structural identity/primary core colours:
**Fresh White / Black** — major structural identity colours depending on theme/context.

Signature operational signal:
**Signal Lime — locked at `#C7F000`** (2026-09-12, Founder baseline closeout — see `docs/cefflo/05_DECISIONS.md` D-30). Signal Lime is a signal/accent colour, not a default surface treatment — do not turn UI into lime-heavy surfaces or introduce Signal Lime cards as a default.

**Superseded 2026-09-11 (see `docs/cefflo/05_DECISIONS.md` D-33, `docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md`):** the Signal Lime lock above is no longer current visual authority. **CEFFLO Yellow `#FEC819` is the current locked primary/signature accent.** This line and the D-30 record above are preserved unedited for history — Signal Lime's D-30 lock was genuine and accurate at the time — but must no longer be read as current implementation instruction. `12_EXPERIENCE_SYSTEM.md` is canonical for all current palette authority; this section is historical from this point forward.

Supporting neutrals:
**Graphite greys** and **very light cool grey**.

**Superseded 2026-09-12:** the previous line here — *"the exact Signal Lime HEX remains a candidate until Founder locks it after real cross-surface visual validation"* — is no longer current. `#C7F000` is locked, not a candidate. (Historical note: it was correctly described as candidate from 2026-09-04 through 2026-09-11; every place in this repo that said "Signal Lime candidate" during that window was accurate at the time.)

Purple and blue were superseded as Cefflo primary/signature colors as of the D-30 baseline. **Note (2026-09-11):** the current locked dark anchor, Navy `#12213E` per D-33/`12_EXPERIENCE_SYSTEM.md`, is a blue. This supersedes the blanket "purple and blue are superseded" line above for Navy specifically — Navy is now locked, selective-use brand doctrine, not a rejected colour. Purple remains superseded; blue is superseded only as a *primary/signature* colour, not as Navy's selective anchor role.

## 3. Signal Lime Meaning
Use for:
- active;
- moving;
- ready;
- selected;
- live;
- dispatchable;
- progressing;
- primary operational signal/action where appropriate.

Principle:
**Cefflo is black and white until something moves. Then it becomes Signal Lime.**

Lime is not a generic decoration or universal success color.

## 4. Accessibility
Signal Lime is light.

Use black/near-black foreground on Signal Lime for normal controls.

Do not default to white text on Signal Lime.

Semantic success/warning/danger/info remain separate from brand signal.

## 5. Logo Status
The text name is **Cefflo**.

**LOCKED 2026-09-12 (Founder baseline closeout — see `docs/cefflo/05_DECISIONS.md` D-30).** The official master logo/brand mark is Founder-approved: a white folded-ribbon "C" mark with a directional/navigation arrow at the left-center junction. **Geometry locked by D-30 and unchanged since.**

**Production asset set updated 2026-09-11 (see `docs/cefflo/05_DECISIONS.md` D-35)** — colour treatment only, matching the D-33 palette supersession: the arrow is now CEFFLO Yellow `#FEC819` (was Signal Lime), and the icon's container is the canonical Navy family `#12213E` (was black).

**Current canonical asset (Founder-supplied, stored unaltered — do not redraw/regenerate/retrace):**
- `docs/cefflo/brand/assets/logo/cefflo-logo-icon-navy.png` — **primary master reference**, mark inside a Navy rounded-square container (app/icon presentation).
- `docs/cefflo/brand/assets/logo/cefflo-logo-mark.png` — standalone mark (ribbon "C" + Yellow arrow), transparent background.
- `docs/cefflo/brand/assets/logo/cefflo-logo-primary.png` — primary lockup (mark + "Cefflo" wordmark), transparent background.
- `docs/cefflo/brand/assets/logo/cefflo-logo-wordmark.png` — wordmark-only, transparent background.

All four are 4375×4375 RGBA, alpha preserved as supplied, SHA-256-verified byte-identical to the Founder's original upload. No redrawing, retracing, regeneration, or "cleanup" performed, same standard as D-30.

**Superseded 2026-09-11 (D-35)** — the original D-30 file set:
- `docs/cefflo/brand/assets/logo/cefflo-logo-official.png` (was primary master reference, black-background)
- `docs/cefflo/brand/assets/logo/cefflo-logo-official-transparent.png`
- `docs/cefflo/brand/assets/logo/cefflo-logo-official-wordmark.png`
- `docs/cefflo/brand/assets/logo/cefflo-logo-official-wordmark-white.png`

**Removed from the working tree 2026-09-11 (D-36, legacy visual baseline cleanup)** — all four carried the Signal Lime arrow / black background exactly as originally supplied, no longer the current production reference, and their presence risked reading as a competing valid baseline. Git history preserves them exactly (last present at commit `29038a6`, `git show 29038a6:docs/cefflo/brand/assets/logo/cefflo-logo-official.png` etc.) — nothing was lost, only removed from the active tree. The transparent and wordmark variants carried visible extraction/matting artifacts around the edges and the wordmark-only variant was very low-contrast, noted here for anyone who inspects the git history, not corrected there since it was historical record rather than current production source.

**Superseded 2026-09-12:** the previous line here — *"The official master logo/brand mark is NOT YET FOUNDER-LOCKED"* — is no longer current.

Generated logo boards, old purple logos, prior wordmarks/icons/explorations not listed above (including `previews/cefflo-logo-identity-exploration/`) are **SUPERSEDED / HISTORICAL / NON-CANONICAL** — retained for lineage, not to be treated as current or reused as a source. Logo redesign/exploration must not resume without a new, explicit Founder decision.

## 6. Logo Direction
Future master mark should be:
- proprietary;
- simple;
- memorable;
- scalable;
- strong in monochrome;
- recognizable at app-icon/favicon size;
- usable across product, web, social and print.

Avoid:
- generic typed wordmark as the only idea;
- random dot without proprietary logic;
- obvious speed lines;
- truck/road/location-pin clichés;
- generic logistics arrows;
- heavy gradient/glow;
- marks that require Signal Lime to remain recognizable.

## 7. Fleet-Impression Rule
Never place Cefflo branding on bags, rider uniforms, motorcycles, vans or trucks in a way that implies Cefflo owns a delivery fleet/network.

Marketing scenarios must preserve the vendor-owned rider model.

## 8. Wordmark
Canonical written name:
**Cefflo**
(C capital, remaining lowercase) unless Founder later locks a stylized logo treatment.

Do not infer official typography from a generated image.

## 9. Typography Status
A final proprietary/brand type system is not automatically locked by mockups.

Until Founder locks it:
- use clean modern sans-serif direction consistent with Brand Brain;
- prioritize legibility and operational density;
- avoid novelty display fonts in product UI;
- record any production font choice and licensing.

## 10. Iconography Status
Final icon family must be deliberately selected/approved.

Rules:
- clear at small size;
- consistent stroke/geometry;
- operational semantics before decoration;
- do not mix unrelated icon families casually;
- navigation/status/action icons must remain distinguishable;
- Rider navigation/dispatch direction follows approved interaction design when locked.

## 11. Photography
Cefflo photography should feel:
- real;
- local;
- premium;
- crisp;
- operational;
- commercially believable.

Use natural skin/product/food colors and real operating context.

Avoid:
- yellow AI tint;
- purple/lime wash;
- freight/container imagery as core identity;
- fake Cefflo fleet;
- random stock office;
- over-smoothed AI faces.

Signal Lime may appear as a small graphic/UI signal, not blanket color grade.

## 12. Food/Product Photography
When enhancing user-supplied real product photography for Cefflo:
- preserve the actual photographed product;
- do not invent/remove ingredients/product details;
- environment/background may change only within approved creative brief;
- do not present AI recreation as the original product.

## 13. Surface Roles
Vendor: White/Graphite structure; Lime for ready/dispatch/active selection.
Rider: White/Graphite + map; Lime for current route/next action.
Customer: White-first; Lime for small active progress/brand signal.
FOUNDR: White/Graphite/Dark; Lime for live/selected/action.
Marketing: Black/White/real photography; Lime as signature signal/CTA/motion.

## 14. Light / Dark
Light and Dark are one brand, not separate visual identities.

Structure/components should remain coherent. Dark Mode may use sectional treatment while preserving hierarchy.

## 15. Asset Registry

**First registered entry (2026-09-12):**
- asset_id: `cefflo-logo-official`
- name: Cefflo primary mark (folded-ribbon "C" + Signal Lime arrow)
- type: logo, master reference
- status: **SUPERSEDED** (2026-09-11, D-35 — colour treatment only, geometry unaffected) and **REMOVED from the working tree** (2026-09-11, D-36 — files recoverable via git history at commit `29038a6`, not deleted from git)
- version: 1.0
- source: Founder-supplied PNG, 2026-09-12
- owner: Founder
- approved date: 2026-09-12
- permitted surfaces: all (product, web, social, print) — production-format exports not yet generated
- file formats: PNG only at this time (RGBA, 3438×3438 for the primary reference) — see §5 for the four files stored
- color variants: black-background (primary), transparent, wordmark, wordmark-only — as supplied
- clear-space/min-size rules: not yet specified — Founder decision pending if needed before production use
- licensing/provenance: Founder-supplied original

**Second registered entry (2026-09-11, D-35 — supersedes the entry above):**
- asset_id: `cefflo-logo-official`
- name: Cefflo primary mark (folded-ribbon "C" + CEFFLO Yellow arrow, Navy icon background)
- type: logo, master reference
- status: **LOCKED**
- version: 2.0
- source: Founder-supplied PNG, 2026-09-11
- owner: Founder
- approved date: 2026-09-11
- permitted surfaces: all (product, web, social, print) — production-format exports not yet generated
- file formats: PNG only at this time (RGBA, 4375×4375, alpha preserved) — see §5 for the four files stored
- color variants: Navy-icon (primary), transparent mark, transparent primary lockup, transparent wordmark-only — as supplied
- clear-space/min-size rules: not yet specified — Founder decision pending if needed before production use
- licensing/provenance: Founder-supplied original

Every canonical asset should record:
- asset_id;
- name;
- type;
- status EXPLORATION/CANDIDATE/LOCKED/SUPERSEDED;
- version;
- source;
- owner;
- approved date;
- permitted surfaces;
- file formats;
- color variants;
- clear-space/min-size rules where applicable;
- licensing/provenance.

## 16. Canonical Asset Folder
Recommended structure (conceptual):
`Brand Assets/`
- `01_LOGO/`
- `02_COLOR/`
- `03_TYPOGRAPHY/`
- `04_ICONS/`
- `05_PHOTOGRAPHY/`
- `06_SOCIAL_TEMPLATES/`
- `07_PRODUCT_ASSETS/`
- `99_EXPLORATION_ARCHIVE/`

**Actual repo path (2026-09-12):** realized under the repo's existing `docs/cefflo/` tree rather than a new top-level folder — `docs/cefflo/brand/assets/logo/` holds the `01_LOGO/` category (§5). Other categories (`02_COLOR/` etc.) are not yet populated with files; color/typography/icon truth lives in this document's own sections until dedicated assets exist.

Only LOCKED assets go into canonical production folders.

## 17. Required Final Logo Deliverables
When logo is Founder-locked:
- master vector;
- SVG;
- PNG transparent;
- monochrome black;
- monochrome white;
- full-color;
- horizontal/stacked only if approved;
- app icon;
- favicon;
- safe-area specification;
- minimum size;
- forbidden-use examples.

Do not expose/share font files.

## 18. Brand Change Control
Founder approval required to:
- lock/change logo;
- lock exact Signal Lime;
- change primary colors;
- change master typography;
- change icon family;
- materially alter Brand Brain.

## 19. Superseded Assets
Old purple/blue identity material remains archive/history only.

Do not delete historical assets merely to hide lineage, but clearly label them superseded so agents cannot reuse them.

## 20. Definition of Done
Brand Assets become fully solid only when logo, exact Signal Lime, typography and iconography are Founder-locked, registered and supplied in canonical production formats. Until then this SOT prevents explorations from becoming accidental truth.
