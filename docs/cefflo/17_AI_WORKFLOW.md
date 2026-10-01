# CEFFLO --- AI WORKFLOW

## AI-00 Objective

Use AI to increase execution speed without creating duplicate ownership,
context waste or conflicting code.

## AI-01 Founder

Founder: - sets product priorities; - approves protected actions; -
approves phase gates; - may direct Codex remotely from Android.

## AI-02 through AI-04 --- SUPERSEDED

**STATUS: SUPERSEDED.** These sections previously fixed Codex as sole
primary executor and Claude as an occasional optional specialist. That
single-executor model is superseded by the current multi-agent Agent
OS, which routes substantial work (repo-wide audits,
architecture/reconciliation, multi-file implementation, large UI/product
rollouts) to Claude as primary heavy implementer, and small/bounded
finishing work to Codex — see `docs/cefflo/agent-os/CEFFLO_AGENT_OS_CORE.md`
§3, §6 and the relevant `docs/cefflo/agent-os/*_OPERATING.md` file for
the assigned agent. Founder instruction overrides normal routing.

Still valid from the superseded sections: avoid asking two agents to
duplicate the same heavy analysis without reason; use a compact handoff
rather than re-explaining Cefflo context every session (Agent OS Core
§8, §18).

## AI-05 No Duplicate Implementation

Do not ask two agents to independently build the same production
feature unless intentionally comparing prototypes. One assigned
implementer per task prevents conflict and wasted usage (Agent OS Core
§6).

## AI-06 Usage Efficiency

-   Route substantial work to Claude, bounded finishing to Codex (Agent
    OS Core §6), unless Founder instructs otherwise.
-   Avoid repeated full-repo prompts.
-   Use canonical MDs (Brand Brain, Agent OS Core, role Operating MD,
    Task MD) and section IDs rather than re-deriving context.
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
