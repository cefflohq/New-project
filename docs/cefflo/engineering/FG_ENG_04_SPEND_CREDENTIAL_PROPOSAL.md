# FG-ENG-04 — Spend/Credential Envelope Preparation

Status: PROPOSED, NOT AUTHORIZED. Audit date: 2026-09-19.
Baseline branch: claude/engineering-baseline-phase-01.
Reference registration parent: 8119f5553e953438e9bdddbfd4a466c83c253aa0.
Product baseline: 2f3e49af1d649a79fcd7d6e7b1894cd56de6f378.
Reference: UI-VENDOR-V11-TODAY-v1, ACTIVE; D-42 resolves its fifth tab to Menu.

## Required capabilities

| Role | Required capability | Proposed primary | Proposed fallback |
|---|---|---|---|
| E1 Lead | Scoped SOT reasoning, planning, structured task output | OpenAI API gpt-5.4-mini | DeepSeek API deepseek-flash, after qualification |
| E2 Build | Dart/Flutter reasoning, bounded patch generation, typed action requests | OpenAI API gpt-5.4-mini | DeepSeek API deepseek-flash, after qualification |
| E3 Pixel | Genuine multi-image understanding, reference/render comparison, localized findings | OpenAI API gpt-5.4-mini | DeepSeek API deepseek-flash only after multi-image qualification |
| E4 Verify | Independent source/build/test/render verification and structured verdict tied to exact tree | Fresh isolated OpenAI API gpt-5.4-mini session | Fresh isolated qualified DeepSeek session |
| E5 Ship | Validate hashes, E4 PASS, approved destination, publish exact artifact | Deterministic runner, no model | Stop if deterministic checks fail |

These are initial pilot candidates, not a permanent provider lock. Quality is
not established by modality documentation. A failed qualification blocks that
route. A stronger or differently priced model requires a new reviewed price
entry within the approved envelope; no silent model escalation.

E4 receives independent read-only candidate inputs, recaptures the render and
reruns checks. It does not resume E2/E3 conversation or trust their PASS. A
different model is optional; independent execution, evidence and no repair
permission are mandatory. E4 must also inspect both images for visual checks.

E3 receives the hashed original JPEG and actual rendered PNG bytes in the same
multimodal request, encoded as image inputs through the adapter. The original
is a composite: identify the centre V11 panel explicitly, with the D-42 Menu
exception. A provenance-linked crop may supplement the original later; it
cannot replace it. No OCR-only or source-only visual PASS. Image decoding,
token budget and comparison quality must be qualified before activation.

## Actual local evidence

| Route | Evidence | Readiness and billing |
|---|---|---|
| Codex CLI 0.149.1 | `codex login status`: ChatGPT login; stored auth mode chatgpt; no stored OpenAI API key. CLI help supports multiple `--image` inputs, JSON events and output schema | Existing subscription access reported. No inference probe run. Not a configured n8n route |
| Codex local model cache | gpt-6-astra, gpt-5.6-sol, gpt-5.6-terra, gpt-5.6-luna, gpt-5.5 advertise text/image input | Cached capability metadata, not proof of current per-model entitlement or quota |
| Claude Code 2.1.267 | `claude auth status`: logged in, claude.ai, firstParty, Pro | Existing native CLI subscription access reported; no inference or model entitlement probe run |
| OpenAI n8n credential | ID BLg2BvJMiBBd9gw8; name OpenAI account; type openAiApi | Encrypted record exists. Key validity, endpoint, credit balance, restrictions and model access unverified |
| DeepSeek n8n credential | ID 52e3f617-3565-4c58-8405-93e2d4f1a980; name DeepSeek; type deepSeekApi | Encrypted record exists. Same unverified items; no Engineering model selection registered |
| Process environment | OPENAI_API_KEY, ANTHROPIC_API_KEY, DEEPSEEK_API_KEY, OPENROUTER_API_KEY, GEMINI_API_KEY absent | Does not imply absence from encrypted stores |
| Engineering config | model-routes routes=[]; egress allowlist=[]; hardBudget=null | No callable or activated Engineering model route; runner wiring and policy enforcement still required |

n8n metadata was read using SELECT queries limited to credential ID/name/type
and relevant workflow/model metadata. Credential payloads were not selected or
decrypted. Running containers identify n8n 2.36.8 and PostgreSQL 16; this audit
performed no upgrade. No Engineering/T5 workflow matched the metadata search;
the Marketing Weekly Winner Engine was inactive and unchanged. A search for
native DeepSeek/OpenAI chat model nodes returned no rows; this does not prove
that custom HTTP nodes never call those providers.

## Subscription versus API access

Native Codex/Claude Code work may use existing signed-in subscriptions subject
to quota and product rules. That access is not an OpenAI/Anthropic API key,
and stored OAuth tokens must never be extracted into n8n HTTP credentials.
Subscription usage consumes plan allowance; zero incremental API billing does
not mean unlimited or cost-free service. No extra-usage purchasing is proposed.

For this deterministic n8n pilot, prefer a direct API adapter using the already
recorded OpenAI credential after its approved secure binding and qualification.
OpenAI's current auth documentation directs programmatic Codex CLI jobs to API
authentication. Existing native CLI access remains useful for supervised work;
it is not certified here as an unattended Engineering subscription backend.
Claude Pro similarly does not establish a paid Anthropic API route.

No new provider credential is currently proven necessary: first qualify the
two existing encrypted records. If OpenAI is invalid or lacks model/billing
access, stop and report that result. DeepSeek fallback requires its own valid
key and capability check. Anthropic API credentials are not required by this
proposal and no active Anthropic API credential was found in the inspected
environment/n8n metadata.

## DeepSeek modality finding

Current official pricing lists deepseek-flash (DeepSeek-V4.1-Flash) with vision,
JSON output and tool calls. deepseek-v4-pro is listed without vision. Therefore
do not claim all DeepSeek models are text-only, and do not infer that an old
deepseek-chat/reasoner configuration can perform E3. This audit did not find a
selected Engineering DeepSeek model and did not send images to the API.
The Flash fallback remains conditional on genuine two-image qualification.

## Proposed maximum exposure for one V11 pilot

Use standard uncached gpt-5.4-mini prices: USD 0.75 / million input tokens and
USD 4.50 / million output tokens. Include image tokens in input and reasoning
tokens in output. Do not assume cache discounts, batch discounts or free tools.

| Role | Maximum logical requests | Input tokens/request | Output tokens/request |
|---|---:|---:|---:|
| E1 | 1 | 40,000 | 8,000 |
| E2 | 3 | 60,000 | 16,000 |
| E3 | 3 | 30,000 | 8,000 |
| E4 | 3 | 40,000 | 10,000 |
| E5 | 0 | 0 | 0 |

Totals: 430,000 input + 110,000 output = **USD 0.8175** before transport retries.
Conservatively charge every request plus two retries in full: **USD 2.4525**.
Reserve at most USD 0.50 within the same envelope for qualification checks:
combined **USD 2.9525**, rounded to a proposed **USD 3.00 hard cap**.
This is a bounded planning estimate, not measured usage or a currently enforced
spend limit. Tax, existing subscriptions and pre-existing host costs excluded.

Fallback DeepSeek Flash published peak uncached rates are USD 0.30 input and
USD 1.20 output / million tokens. The same token envelope costs USD 0.261
before retries. Its tokens must be counted using its own accounting; fallback
does not reset budgets or request/attempt counters. Every billable failed or
uncertain request retains its reservation. No budget top-up is automatic.

Runner must reserve worst-case cost before dispatch, constrain all adapter
calls including tool continuations, reject over-budget image inputs, persist
usage/cost/attempt telemetry, and block on missing usage rather than record
zero. Enforce three implementation attempts total (initial plus two repairs)
per approved plan. Fallback consumes the same remaining envelope and cannot
be used as a fourth implementation attempt. If token bounds are insufficient,
stop for review. No paid hosted tools, image generation or arbitrary egress.

## Other credentials actually required

- n8n-to-runner authenticated transport reference and task-scoped artifact
  access must be bound securely before operation. They are not configured by
  this proposal; no generic shell or Docker socket goes to the runner.
- For a deterministic local UI fixture and local preview, no Supabase service
  role, production credential or new preview-platform key is required.
- If real staging data is required, use a scoped staging Vendor session and
  publishable configuration through trusted runtime injection, never model
  context. The prior 11 live staging-contract tests remain unverified.
- Local Git and artifact preparation need no new credential. Remote task-branch
  push or hosted preview publication needs a scoped repository/preview binding;
  availability for the future runner is not established by desktop access.
- Models only emit typed requests/patches. Trusted runner owns build, render,
  verification and E5 publication permission, including exact-tree gating.

## Founder approval requested

Approve or amend one-pilot USD 3.00 maximum, the OpenAI primary and conditional
DeepSeek Flash fallback, and reuse/qualification of existing non-production
credential references. No new credentials are requested. Any failed credential
qualification is reported rather than repaired by provisioning automatically.
Approval does not activate the pilot: FG-ENG-07 and operational controls remain
required, with FG-ENG-08 for acceptance. FG-ENG-05/06 exceptions remain ungranted.

## Sources and limitations

Read-only local auth/help/config and n8n metadata checks were performed.
No model inference, E1–E5 execution, purchase, credential change, V11 edit,
workflow activation or deployment occurred. Provider checks are documentary;
authenticated model and genuine multimodal qualification remain pending.

- https://developers.openai.com/api/docs/models/gpt-5.4-mini
- https://learn.chatgpt.com/docs/auth
- https://api-docs.deepseek.com/quick_start/pricing/
- https://code.claude.com/docs/en/authentication
- https://support.claude.com/en/articles/11145838-use-claude-code-with-your-pro-or-max-plan

Current prices and entitlement must be rechecked at binding time. Preserve
provider-neutral role contracts; this proposal changes no runtime model route,
credential, cost-policy or egress-policy value.
