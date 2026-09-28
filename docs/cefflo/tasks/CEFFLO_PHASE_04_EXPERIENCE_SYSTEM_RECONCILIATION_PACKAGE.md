**Status:** APPLIED 2026-09-11 — the edits below were proposed here first, then applied for real following Founder approval (D-33). Retained as the record of what was proposed and why, per the same annotate-don't-silently-rewrite pattern this package itself follows. See `docs/cefflo/05_DECISIONS.md` D-33 for the actual applied decision text (slightly expanded from the draft below to also cover the semantic-colour accessibility adjustments and logo/header/branch decisions resolved in the interim visual-validation round).

**Depends on:** `docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md` (draft) being approved, and the open decisions listed in that document's §12 being resolved.

---

# 1. Proposed new decision record (`docs/cefflo/05_DECISIONS.md`)

To be appended as a new entry, **not yet applied**:

> ## D-33 CEFFLO Visual DNA — Signal Lime Superseded (2026-09-11)
>
> Founder decision: the Signal Lime `#C7F000` primary/signature accent lock recorded in D-30 (2026-09-12) is **superseded**. D-30 is preserved unedited and unremoved as the historical record of that decision — this entry documents the change, it does not rewrite history.
>
> New candidate primary accent: **CEFFLO Yellow, ≈ `#FEC819`** — a warm mustard-yellow, deliberately calmer than Signal Lime, clearly yellow rather than orange. Derived from a Founder-supplied visual reference, not extracted from original source design tokens — stated as an estimated visual-direction candidate pending a confirmed production value.
>
> New candidate dark anchor: **Navy `#12213E`**, used selectively (brand moments, one status surface per screen) — not permanent chrome.
>
> Workspace `#F7F8FA` and Surface `#FFFFFF` introduced as explicit tokens alongside the existing "Fresh White" structural colour.
>
> New semantic candidates (Founder-confirmed 2026-09-11): Attention/Error `#D8402F`, Success `#2FAE5E`, Route/Info `#3D7BEE` (operational meaning only — never a brand accent).
>
> Logo/header scoping (Founder-confirmed 2026-09-11): master logo/wordmark reserved for brand moments only (splash/auth/onboarding), never repeated on internal operational screens; business/store name text may still appear contextually (e.g. Dashboard) but is not mandatory global header branding.
>
> Flutter baseline (Founder-confirmed 2026-09-11): `claude/vendor-mobile-backend-integration` confirmed as the leading implementation evidence/baseline — **not** authorized for merge by this decision.
>
> Full detail: `docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md`.
>
> **Status: candidate, not locked.** This entry does not itself constitute the lock — it exists to supersede D-30's *conclusion* once the Founder confirms the new direction, matching the same two-step pattern D-30 followed (candidate → later locked). The remaining open items in `12_EXPERIENCE_SYSTEM.md` §12 must be resolved first.

# 2. Proposed edit — `docs/cefflo/sot/06_BRAND_ASSETS_GOVERNANCE.md` §2

Current text (unchanged, still in effect):
> Signature operational signal:
> **Signal Lime — locked at `#C7F000`** (2026-09-12, Founder baseline closeout — see `docs/cefflo/05_DECISIONS.md` D-30)...

Proposed addition directly beneath it, following the file's own established annotate-in-place convention (see its existing 2026-09-12 annotation of the original "candidate" language):

> **Superseded 2026-09-11 (pending D-33):** the above Signal Lime lock is proposed for supersession by CEFFLO Yellow `≈#FEC819`. See `docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md` and `docs/cefflo/05_DECISIONS.md` D-33. **Not yet in effect** — D-33 is a candidate decision, not a locked one, until the open items in `12_EXPERIENCE_SYSTEM.md` §12 are resolved and this line is updated to a real supersession date.

No other part of §2–§6 (logo lock, accessibility principle, logo direction) is proposed to change.

# 3. Proposed edit — `docs/cefflo/sot/00_INDEX.md`

**§1 Vendor Flutter**, line 37, current:
> approved Design Lab/DNA outputs when locked — none exist yet.

Proposed:
> `docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md` — status: DRAFT/CANDIDATE, not yet Founder-locked. See `docs/cefflo/05_DECISIONS.md` D-33 (candidate).

**§8 Brand Assets**, current:
> **Updated 2026-09-12 (Founder baseline closeout, D-30):** logo and Signal Lime are now Founder-locked.

Proposed addition:
> **Under revision 2026-09-11 (pending D-33):** Signal Lime's lock is proposed for supersession by CEFFLO Yellow — see `docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md`. Logo lock is unaffected and remains in force.

# 4. What is explicitly NOT proposed in this package

- No change to the master logo asset files or their geometry.
- No change to Flutter implementation (`apps/vendor_mobile` or any branch).
- No change to `05_BRAND_BRAIN.md`'s brand character, voice, or positioning content.
- No change to `08_RIDER_FLUTTER_33_SCREEN_MASTER.md` or `09_VENDOR_FLUTTER_60_SCREEN_MASTER.md`'s screen inventories.
- No token migration in code.
- No branch merge, commit, or push.

# 5. Sequencing, once approved

1. Founder resolves the items still open per `12_EXPERIENCE_SYSTEM.md` §14 (Yellow production hex, typography family, dark-mode exact values, shadow/elevation exact parameters). Semantic colours, logo/header scoping, and the Flutter baseline branch are already resolved as of 2026-09-11 and reflected in the D-33 draft text above.
2. Apply the three edits above for real (D-33 appended, §2 and §1/§8 of the governance/index docs annotated in place).
3. Update `12_EXPERIENCE_SYSTEM.md`'s own status line from DRAFT/CANDIDATE to CANONICAL.
4. Only then does token migration into `claude/vendor-mobile-backend-integration` become an authorized, separate implementation task — and only that branch's tokens, not a merge. Branch merge remains a distinct, later authorization this package does not grant.
