# CEFFLO ENGINEERING BOOTSTRAP — PILOT READINESS GATE

**Status:** NOT READY — PROVIDER CREDENTIAL BLOCKER  
**Gate evaluated:** FG-ENG-04  
**Next permitted gate:** Founder credential remediation decision; FG-ENG-07 is not yet requestable  
**Environment:** DEV/STAGING only

## 1. Engineering Runner Status

The deterministic Node runner is implemented. It binds to loopback by default,
requires signed HMAC envelopes, rejects replayed nonces and stale timestamps,
redacts sensitive output, enforces the role/action matrix, and exposes no
free-form shell. Fixed adapters cover scoped repository reads/search, validated
unified patches, Flutter build/test, localhost render capture, two-image visual
guards, and exact-tree verification.

## 2. n8n Workflow Status

The minimum four workflows were generated, imported into n8n 2.36.8, and
verified inactive:

- `CEFFLO ENG - 00 - Control Plane`
- `CEFFLO ENG - 01 - Context Builder`
- `CEFFLO ENG - 02 - Role Executor`
- `CEFFLO ENG - 99 - Failure & Escalation`

The Control Plane was executed once with empty input on an isolated task-runner
port. It stopped at `PILOT_GATE_CLOSED`. No Engineering workflow is active.

## 3. Authentication And Authorization Results

Runner HMAC validation, timestamp expiry, tamper rejection, and nonce replay
rejection passed automated tests. Role/action tests passed for allowed
qualification actions and denied cross-role, production, and closed-pilot
requests. Credential values remain inside n8n encrypted credential records.

## 4. E1–E5 Permission Enforcement Results

- E1 can read scoped context and cannot patch source.
- E2 can submit a validated patch only inside assigned paths.
- E3 requires exactly the Founder reference and current render for visual work.
- E4 is read-only and cannot request source repair.
- E5 has deterministic exact-tree verification; commit, push, and preview
  publication remain disabled pending FG-ENG-07 and later release authority.

## 5. OpenAI Qualification Result

`gpt-5.4-mini` was dispatched through the existing encrypted n8n OpenAI
credential with the registered reference and actual render in one request. The
provider returned HTTP 429 `insufficient_quota` before inference. Result:
**NOT QUALIFIED**. No model output or token usage was produced.

## 6. DeepSeek Qualification Result

`deepseek-flash` was dispatched through the existing encrypted n8n DeepSeek
credential with both images in one request. The provider returned HTTP 401
authentication failure before inference. Result: **NOT QUALIFIED**. No model
output or token usage was produced.

## 7. Optional CLI Qualification Result

Codex CLI is authenticated through ChatGPT and Claude Code through Claude Pro.
Neither was promoted to an operational route: subscription access is not an API
credential, unattended n8n compatibility is not established, and per-request
cost cannot be deterministically priced. Result: **NOT QUALIFIED**.

## 8. Selected Model Route For Each Role

No E1–E4 route can be selected because no candidate completed capability
qualification. E5 is selected as `deterministic-e5`, with no model on its normal
path. Route selection correctly fails closed rather than treating documentation
claims as operational capability.

## 9. E3 Two-Image Proof

The request construction and n8n transport included, in the same request:

1. Founder reference `UI-VENDOR-V11-TODAY-v1`, SHA-256
   `0940081867837b1a51c18d7917cfba4cbff493f130cce9e0de730cedfea86bcb`.
2. Actual `/audit/V11` DEV render at 390×844, SHA-256
   `8b9b4d2cf74491201793d5a268265444dbb6944978a29c5eb292b1708d4ea5e4`.

Both providers rejected the request before inference. Therefore genuine model
visual comparison is **NOT PROVEN** and E3 cannot PASS.

## 10. E4 Independence Proof

The deterministic E4 policy denies patch/write actions and requires exact-tree
and two-image evidence. Those controls passed. Independent model reasoning is
**NOT PROVEN** because no provider completed inference.

## 11. E5 Exact-Tree Enforcement Proof

Automated tests passed for exact candidate-tree, immutable task-pack, evidence
manifest, and E4 verdict hashes. Hash mismatch and E4 write capability are
rejected. E5 remains deterministic and makes no model call.

## 12. Kill-Switch Results

Engineering, qualification, pilot, role, provider, Git push, and preview
publication controls are separate. Tests prove the Engineering kill switch
overrides role permissions. `pilotEnabled`, Git push, and preview publication
remain false.

## 13. Prompt-Injection And Security Test Results

Tests passed for untrusted content attempting to change role authority,
credential-field redaction, path traversal and symlink escape, out-of-scope
patch rejection, arbitrary render URL rejection, HMAC tampering, stale request,
and replay rejection. The temporary qualification workflows and raw execution
records were removed after sanitized evidence was recorded, preventing retained
session headers and workflow sprawl.

## 14. Cost-Control Test Results

Tests passed for pre-dispatch worst-case reservation, a cumulative ledger across
retry and fallback, unknown-cost fail closed, USD 3.00 hard stop, and uncertain
request reservation retention. The ledger never resets.

## 15. Actual Qualification Spend

**USD 0.00.** Both provider requests were rejected before inference and reported
zero input/output tokens. The pre-dispatch workflow-import failure was also
recorded as a zero-cost, no-provider-dispatch entry rather than discarded.

## 16. Remaining USD 3.00 Pilot Budget

**USD 3.00.** The cumulative ledger contains all attempts and has no open
reservations.

## 17. Unresolved Blockers

1. The existing OpenAI API account has no remaining API credits.
2. The existing DeepSeek credential does not authenticate correctly.
3. Consequently E1, E2, genuine multimodal E3, and independent multimodal E4
   remain unqualified.
4. n8n reports PostgreSQL 16 compatibility support only; the prohibited database
   upgrade was not performed.

## 18. Exact Actions FG-ENG-07 Would Authorize

If requested after provider remediation and successful requalification,
FG-ENG-07 would authorize one DEV/STAGING V11 acceptance-pilot run against the
registered reference and exact approved baseline: E1 task-pack generation, E2
targeted implementation, build/render, E3 two-image comparison with at most
three targeted repair attempts, read-only E4 verification, and deterministic E5
preview preparation for Founder review. It would not authorize production,
protected-branch merge, production deployment, database upgrade, credential
expansion, or any other department.

FG-ENG-07 is not requested in this report. The exact Founder decision now
required is authorization to repair or replace one non-production paid API
credential while retaining the same cumulative USD 3.00 ceiling, followed by
requalification. No credential should be posted in chat or committed to Git.
