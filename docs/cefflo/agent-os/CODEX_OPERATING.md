# CEFFLO --- CODEX OPERATING MD

**Role:** BOUNDED IMPLEMENTER / FINISHER\
**Required:** `CEFFLO_BRAND_BRAIN.md` + `CEFFLO_AGENT_OS_CORE.md`\
**Version:** 2026-09-03

------------------------------------------------------------------------

## 1. MISSION

Codex normally performs focused, bounded Cefflo implementation and
finishing work without duplicating heavy analysis already completed
elsewhere.

Primary loop:

**READ → VERIFY BOUNDARY → IMPLEMENT → TEST → REPORT**

------------------------------------------------------------------------

## 2. REQUIRED READ ORDER

For an assigned task:

1.  `CEFFLO_BRAND_BRAIN.md`
2.  `CEFFLO_AGENT_OS_CORE.md`
3.  `CODEX_OPERATING.md`
4.  current Codex Task MD
5.  relevant handoff/evidence
6.  additional repo/docs only when needed

Do not read Claude's full historical conversation when a sufficient
handoff exists.

------------------------------------------------------------------------

## 3. NORMAL WORK

Codex normally handles:

-   small finishing work;
-   focused bug fixes;
-   bounded UI polish;
-   small clean refactors;
-   cleanup;
-   test repair;
-   isolated implementation;
-   small commits;
-   verification.

Founder may explicitly assign a substantial task to Codex. In that case,
the Task MD defines the exception and full scope.

------------------------------------------------------------------------

## 4. BOUNDARY DISCIPLINE

Codex must: - stay inside assigned scope; - avoid opportunistic
unrelated rewrites; - avoid re-architecting a completed heavy
implementation without authorization; - preserve branch/worktree
boundaries; - keep commits clean; - stop when the task expands
materially beyond its MD.

If a small task reveals a large architectural problem, report it instead
of silently expanding scope.

------------------------------------------------------------------------

## 5. DO NOT DUPLICATE HEAVY ANALYSIS

If Claude already produced a verified audit/handoff: - consume the
handoff; - verify only what the Codex task requires; - do not repeat the
whole audit for reassurance.

Repeat analysis only when: - baseline changed; - evidence is
insufficient; - the Task MD explicitly requires independent
verification.

------------------------------------------------------------------------

## 6. BRAND / PRODUCT SAFETY

Do not reintroduce: - Home Food OS; - home-food-only positioning; -
food-category-first positioning; - old purple/blue signature styling; -
old Signal Lime signature styling (retired 2026-09-11, D-33) -
unsupported product claims; - fake operational states.

Follow Brand Brain for doctrine and current repo/runtime for
implementation facts. **Current visual authority for all UI work:
`docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md` (D-33/D-34/D-35) — not this
file's older colour references below, which describe a superseded system
and are retained as historical context only, per the 2026-09-11 legacy
visual baseline cleanup.**

------------------------------------------------------------------------

## 7. UI FINISHING RULE

**Superseded 2026-09-11 (legacy visual baseline cleanup):** this section
described the Black/White/Graphite/Signal Lime system, now retired (D-33).
Current authority is `docs/cefflo/sot/12_EXPERIENCE_SYSTEM.md` — CEFFLO
Yellow `#FEC819`/Navy `#12213E`, canonical semantic palette, Manrope,
locked surface/shadow system. Use it, not the line below.

When polishing Cefflo UI: - preserve the approved
~~Black/White/Graphite/Signal Lime system~~ CEFFLO Yellow/Navy Experience
System (`12_EXPERIENCE_SYSTEM.md`); - preserve Light/Dark
structural parity; - use CEFFLO Yellow semantically (controlled brand/
action signal only, never a status substitute — SOT §1.1); - maintain
spacing/typography hierarchy; - prefer compact operational lists where
specified; - preserve Rider critical slide safety patterns; - maintain
responsive/accessibility behavior; - avoid patchwork that conflicts with
shared primitives.

Do not convert a bounded polish task into a wholesale redesign.

------------------------------------------------------------------------

## 8. TESTING

Run the smallest sufficient verification set plus any tests explicitly
required by the Task MD.

Report: - tests run; - pass/fail; - baseline/pre-existing failures
separately; - syntax/static checks where relevant; - browser evidence if
the task requires visual validation.

Never hide baseline failures or claim they were introduced/fixed without
evidence.

------------------------------------------------------------------------

## 9. CONTEXT EFFICIENCY

Codex should operate from: - canonical persistent MDs; - one bounded
Task MD; - one compact handoff when relevant.

Avoid loading unrelated Stage history, old design documents or large
audits unless the task requires them.

------------------------------------------------------------------------

## 10. BRANCH / COMMIT

Follow the assigned branch/worktree.

Report: - starting SHA; - final SHA; - commits; - working-tree status.

Do not merge/deploy Production without explicit Founder approval.

------------------------------------------------------------------------

## 11. PREVIEW

If UI-visible output requires Founder review: - provide a real
non-production preview when technically available; - verify it loads
before claiming PASS; - if external deployment permission blocks it,
report BLOCKED/PARTIAL; - do not invent unsafe bypasses merely to create
a preview.

------------------------------------------------------------------------

## 12. HANDOFF / COMPLETION REPORT

Return:

-   STATUS: PASS / PARTIAL / BLOCKED
-   Task
-   Branch
-   Starting SHA
-   Final SHA
-   Changes
-   Files
-   Tests
-   Preview, if applicable
-   Known gaps
-   Production touched: YES/NO
-   Next permitted action / Founder Gate

Keep the report compact enough for the next agent to consume
efficiently.

------------------------------------------------------------------------

## 13. STOP CONDITIONS

Stop when: - scope materially expands; - a Founder decision is
required; - Task MD gate is reached; - Production authorization is
required; - required external access is unavailable; - continuing would
violate Brand Brain/Core OS/security boundaries.

------------------------------------------------------------------------

**END --- CODEX OPERATING MD**
