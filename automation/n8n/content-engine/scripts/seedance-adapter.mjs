// CEFFLO Phase 03 Batch 03G -- Seedance video adapter.
// Source: CEFFLO_PHASE_03_MARKETING_ENGINE_CONTENT_PILOT_MASTER.md §10, §11, §12.
//
// RE-VERIFIED 2026-09-11 against current third-party documentation of the
// Volcano Engine ARK API (apidog.com/blog/seedance-2-0-api, cross-checked
// against general ARK API-key-auth pattern used by other ARK-hosted models --
// do not treat as final; confirm once more against the official Volcengine
// ARK console/docs at the moment a real credential is issued, per this
// repo's "verify, don't invent" pattern for provider APIs):
//
// CORRECTION to the earlier (2026-09-13) draft of this file: ARK's content-
// generation task API is authenticated with a simple `Authorization: Bearer
// <ARK_API_KEY>` header, NOT Volcano Engine's classic AK/SK request-signing
// scheme (that scheme applies to other, older Volcengine OpenAPI services,
// not to ARK model inference/generation).
//
// Verified contract:
//   POST https://ark.{region}.volces.com/api/v3/contents/generations/tasks
//     headers: Authorization: Bearer <ARK_API_KEY>, Content-Type: application/json
//     body: { model, content: [{ type: 'text', text }], resolution, ratio, duration, watermark, generate_audio }
//     response: { id: 'cgt-...' }
//   GET  https://ark.{region}.volces.com/api/v3/contents/generations/tasks/{id}
//     response: { status: 'queued'|'running'|'succeeded'|'failed'|'expired'|'cancelled', content: { video_url }, error? }
//   video_url points at Volcengine object storage and expires ~24h after success --
//   a real caller must download/persist it, not just store the URL.

export const VIDEO_PROVIDER_PRIMARY = 'seedance'; // §10.3 -- replaceable, not hardwired elsewhere.
export const VIDEO_PROVIDER_FALLBACK = null; // Veo is HOLD/OPTIONAL/FUTURE per §10.2 -- never auto-escalated (§12).

const MAX_TARGETED_RETRIES = 1; // §12: "one targeted retry" only.
const ARK_MODEL = 'doubao-seedance-2-0-260128';
const ARK_DEFAULT_REGION = 'cn-beijing';

function fingerprint(scenario) {
  return `seedance-stub-${scenario.scenario_id}`;
}

function arkBaseUrl() {
  const region = process.env.CEFFLO_SEEDANCE_ARK_REGION || ARK_DEFAULT_REGION;
  return `https://ark.${region}.volces.com/api/v3/contents/generations/tasks`;
}

function arkApiKey() {
  const key = process.env.CEFFLO_SEEDANCE_ARK_API_KEY;
  if (!key) throw new Error('ERROR_SEEDANCE_CREDENTIALS: CEFFLO_SEEDANCE_ARK_API_KEY is not set. Configure it in n8n\'s encrypted credential store / this process\'s environment -- never hardcode it here.');
  return key;
}

// Stub submit -- deterministic, offline, zero cost. Default path throughout
// Phase 03 (SAFE / NON-PUBLISHING MODE, §32). Unchanged from the original
// Batch 03G contract -- see submitVideoJob() below, which still throws
// ERROR_SEEDANCE for any non-stub mode exactly as it always has.
export function submitVideoJob(scenario, contentPackage, { mode = 'stub' } = {}) {
  if (mode !== 'stub') throw new Error('ERROR_SEEDANCE: live Seedance calls are not enabled in Phase 03 -- Founder Gate 2 (paid activation) has not been granted.');
  return {
    job_id: fingerprint(scenario),
    provider: VIDEO_PROVIDER_PRIMARY,
    status: 'SUBMITTED',
    request: { scenario_id: scenario.scenario_id, hook: contentPackage.hook?.hook_bm, vehicle_mix: scenario.vehicle_mix, duration_seconds: 20, aspect_ratio: '9:16' },
    submitted_at: new Date().toISOString(),
    estimated_cost: 0,
  };
}

// Real submit -- signs no request (ARK uses bearer-key auth, not AK/SK), but
// DOES make a real network call and requires a real credential. This is a
// deliberately SEPARATE function from submitVideoJob() above (which stays
// stub-only and synchronous, unchanged, so every existing Phase 03 test and
// caller keeps working exactly as before) -- a live caller must call this
// one explicitly, after its own Founder Gate 2 authorization check.
export async function submitVideoJobLive(scenario, contentPackage) {
  const apiKey = arkApiKey();
  const prompt = [contentPackage.hook?.hook_bm, contentPackage.script?.problem_beat, contentPackage.script?.product_beat, contentPackage.script?.outcome_beat].filter(Boolean).join(' ');
  const body = {
    model: ARK_MODEL,
    content: [{ type: 'text', text: prompt }],
    resolution: '1080p',
    ratio: '9:16', // §11: vertical short-form, matches the meta/tiktok lane aspect ratio.
    duration: 20,
    watermark: false,
    generate_audio: false, // caption/voiceover is a separate, not-yet-built concern -- do not fabricate audio generation as done.
  };
  const response = await fetch(arkBaseUrl(), {
    method: 'POST',
    headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const data = await response.json();
  if (!response.ok || !data.id) throw new Error(`ERROR_SEEDANCE: task creation failed (${response.status}): ${JSON.stringify(data)}`);
  return {
    job_id: data.id,
    provider: VIDEO_PROVIDER_PRIMARY,
    mode: 'live',
    status: 'SUBMITTED',
    request: { scenario_id: scenario.scenario_id, model: ARK_MODEL, prompt },
    submitted_at: new Date().toISOString(),
    estimated_cost: null, // real cost is not known until the job resolves -- never fabricate a number here.
  };
}

// Stub poll -- always resolves immediately with a deterministic pseudo-QA
// outcome derived from the scenario, so tests are reproducible without a
// live API. Unchanged from the original Batch 03G contract.
export function pollVideoJob(job, scenario) {
  const plausible = scenario.vehicle_mix.every((v) => ['motorcycle', 'car', 'van'].includes(v.type));
  return {
    ...job,
    status: 'COMPLETED',
    completed_at: new Date().toISOString(),
    asset: {
      lane: 'video',
      provider: VIDEO_PROVIDER_PRIMARY,
      vehicles_shown: scenario.vehicle_mix.map((v) => v.type),
      is_ai_generated_ui: false,
      qa_flags: plausible ? [] : ['realistic_vehicles'],
      claims: scenario.cefflo_relevance,
    },
    actual_cost: 0,
  };
}

// Real poll -- GETs the ARK task-status endpoint once. A real caller loops
// this (with backoff, per the ~30-120s generation time documented for this
// model) until status is terminal ('succeeded'/'failed'/'expired'/'cancelled');
// this function itself performs exactly one check and reports the raw status,
// it does not busy-loop or sleep, so n8n's own retry/wait node owns pacing.
export async function pollVideoJobLive(job, scenario) {
  const apiKey = arkApiKey();
  const response = await fetch(`${arkBaseUrl()}/${job.job_id}`, {
    headers: { Authorization: `Bearer ${apiKey}` },
  });
  const data = await response.json();
  if (!response.ok) throw new Error(`ERROR_SEEDANCE: task poll failed (${response.status}): ${JSON.stringify(data)}`);
  if (!['succeeded', 'failed', 'expired', 'cancelled'].includes(data.status)) {
    return { ...job, status: 'PENDING', ark_status: data.status, polled_at: new Date().toISOString() };
  }
  if (data.status !== 'succeeded') {
    return { ...job, status: 'FAILED', ark_status: data.status, error: data.error ?? null, completed_at: new Date().toISOString(), actual_cost: null };
  }
  return {
    ...job,
    status: 'COMPLETED',
    completed_at: new Date().toISOString(),
    asset: {
      lane: 'video',
      provider: VIDEO_PROVIDER_PRIMARY,
      video_url: data.content?.video_url ?? null, // expires ~24h -- caller must download/persist promptly, never re-fetch later.
      vehicles_shown: scenario.vehicle_mix.map((v) => v.type),
      is_ai_generated_ui: false,
      qa_flags: [], // real post-production QA (natural_human_motion etc.) requires human/model review of the actual video -- not inferred here.
      claims: scenario.cefflo_relevance,
    },
    actual_cost: null, // real spend must come from Volcengine's own billing/usage API, never estimated here.
  };
}

// §12 Video Retry Policy: Generation 1 -> QA -> if fixable, one targeted retry -> QA -> otherwise reject/revise.
// Never auto-escalates to a fallback provider (§10.2/§12). Unchanged from the
// original Batch 03G contract -- stub-only, synchronous.
export function generateWithRetryPolicy(scenario, contentPackage, postProductionQA, { mode = 'stub' } = {}) {
  const attempts = [];
  for (let attempt = 0; attempt <= MAX_TARGETED_RETRIES; attempt += 1) {
    const job = submitVideoJob(scenario, contentPackage, { mode });
    const resolved = pollVideoJob(job, scenario);
    const qa = postProductionQA(resolved.asset, scenario);
    attempts.push({ attempt: attempt + 1, job_id: resolved.job_id, qa_status: qa.status, failed_checks: qa.failed_checks, cost: resolved.actual_cost });
    if (qa.status === 'PASS') return { status: 'ACCEPTED', attempts, asset: resolved.asset, total_cost: attempts.reduce((s, a) => s + a.cost, 0) };
    if (qa.status === 'REJECT') break; // hard reject -- do not retry (e.g. unapproved claim, fake UI).
  }
  return { status: 'REJECTED', attempts, asset: null, total_cost: attempts.reduce((s, a) => s + a.cost, 0), reason: 'retry_policy_exhausted_or_hard_reject' };
}

// Real retry policy -- same §12 shape as generateWithRetryPolicy() above, but
// against the live submit/poll functions. A separate, additive function so
// the stub path above is never at risk of regressing; a live caller must
// pass founderGate2Authorized:true after its own Founder Gate 2 check.
export async function generateWithRetryPolicyLive(scenario, contentPackage, postProductionQA, { founderGate2Authorized = false } = {}) {
  if (!founderGate2Authorized) throw new Error('ERROR_SEEDANCE: live Seedance calls are not enabled in Phase 03 -- Founder Gate 2 (paid activation) has not been granted.');
  const attempts = [];
  for (let attempt = 0; attempt <= MAX_TARGETED_RETRIES; attempt += 1) {
    const job = await submitVideoJobLive(scenario, contentPackage);
    const resolved = await pollVideoJobLive(job, scenario);
    if (resolved.status === 'PENDING') { attempts.push({ attempt: attempt + 1, job_id: resolved.job_id, qa_status: 'PENDING', failed_checks: [], cost: 0 }); break; } // caller must poll again later; do not fabricate a QA result for an unfinished job.
    const qa = resolved.status === 'FAILED' ? { status: 'REJECT', failed_checks: ['provider_job_failed'] } : postProductionQA(resolved.asset, scenario);
    attempts.push({ attempt: attempt + 1, job_id: resolved.job_id, qa_status: qa.status, failed_checks: qa.failed_checks, cost: resolved.actual_cost ?? 0 });
    if (qa.status === 'PASS') return { status: 'ACCEPTED', attempts, asset: resolved.asset, total_cost: attempts.reduce((s, a) => s + a.cost, 0) };
    if (qa.status === 'REJECT') break; // hard reject -- do not retry (e.g. unapproved claim, fake UI, provider failure).
  }
  return { status: 'REJECTED', attempts, asset: null, total_cost: attempts.reduce((s, a) => s + a.cost, 0), reason: 'retry_policy_exhausted_or_hard_reject' };
}
