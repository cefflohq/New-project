# CEFFLO --- AI WORKFLOW

## AI-00 Objective

Use AI to increase execution speed without creating duplicate ownership,
context waste or conflicting code.

## AI-01 Founder

Founder: - sets product priorities; - approves protected actions; -
approves phase gates; - may direct Codex remotely from Android.

## AI-02 Codex

Primary engineering executor and canonical code integrator: - inspect
repo; - implement frontend/backend; - test/QA; - Git operations; -
deployment engineering; - technical reports.

Codex follows `00_AGENTS.md`.

## AI-03 Claude

Optional specialist, not mandatory in every sprint. Best use: - UI
concept/prototype; - visual improvement; - new interface exploration; -
architecture/product critique; - independent review.

If Claude lacks GitHub write access, do not make Founder manually
shuttle code back and forth for routine implementation. Approved
concepts/specs are passed to Codex for clean integration.

## AI-04 Handoff

When Claude is used, handoff should state: - objective; - scope; -
approved visual/product outcome; - acceptance criteria; - do-not-touch
areas. Codex implements in canonical repo and reports result.

## AI-05 No Duplicate Implementation

Do not ask Claude and Codex to independently build the same production
feature unless intentionally comparing prototypes. One canonical
executor prevents conflict and wasted usage.

## AI-06 Usage Efficiency

-   Codex: code/repo/testing/deployment.
-   Claude: only high-value specialist work when it adds value.
-   Avoid repeated full-repo prompts.
-   Use router docs and section IDs.
-   Continue current phase/sprint instead of re-explaining Cefflo every
    session.

## AI-07 VPS

Contabo Ubuntu VPS is the current persistent AI workstation. Repository
workspace: `New-project` as verified during setup; re-verify path/state
when needed.

## AI-08 Remote

ChatGPT Desktop on VPS + ChatGPT Android Remote allows Founder to steer
the connected workspace from phone. Remote does not replace
Git/source-control discipline.

## AI-09 Autonomy

Codex may autonomously execute approved normal development. Protected
actions remain Founder-gated under `00_AGENTS.md`.

## AI-10 Future Orchestration

Do not build a complex autonomous multi-agent orchestrator before Stage
4 unless Founder explicitly reprioritizes it. Principle: **Design now →
Build when needed → Automate when proven → Scale when valuable.**
