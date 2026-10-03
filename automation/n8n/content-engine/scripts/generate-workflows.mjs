import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const root = path.resolve(import.meta.dirname, '..');
const out = path.join(root, 'workflows');
fs.mkdirSync(out, { recursive: true });

const ids = {
  master: '10000000-0000-4000-8000-000000000000',
  sot: '10000000-0000-4000-8000-000000000001',
  research: '10000000-0000-4000-8000-000000000002',
  concept: '10000000-0000-4000-8000-000000000003',
  router: '10000000-0000-4000-8000-000000000004',
  meta: '10000000-0000-4000-8000-000000000005',
  tiktok: '10000000-0000-4000-8000-000000000006',
  threads: '10000000-0000-4000-8000-000000000007',
  qa: '10000000-0000-4000-8000-000000000008',
  approval: '10000000-0000-4000-8000-000000000009',
  publisher: '10000000-0000-4000-8000-000000000010',
  analytics: '10000000-0000-4000-8000-000000000011',
  memory: '10000000-0000-4000-8000-000000000012',
  winners: '10000000-0000-4000-8000-000000000013',
  paid: '10000000-0000-4000-8000-000000000014',
  error: '10000000-0000-4000-8000-000000000099',
};

const names = {
  master: 'CEFFLO - 00 - Master Orchestrator',
  sot: 'CEFFLO - 01 - SOT Retrieval',
  research: 'CEFFLO - 02 - Research & Angle Miner',
  concept: 'CEFFLO - 03 - Master Concept Builder',
  router: 'CEFFLO - 04 - Creative Router',
  meta: 'CEFFLO - 05A - Meta Creator',
  tiktok: 'CEFFLO - 05B - TikTok Creator',
  threads: 'CEFFLO - 05C - Threads Writer',
  qa: 'CEFFLO - 06 - AI QA',
  approval: 'CEFFLO - 07 - Founder Approval',
  publisher: 'CEFFLO - 08 - Publisher',
  analytics: 'CEFFLO - 09 - Analytics & Scoring',
  memory: 'CEFFLO - 10 - Marketing Memory',
  winners: 'CEFFLO - 11 - Weekly Winner Engine',
  paid: 'CEFFLO - 12 - Paid Growth',
  error: 'CEFFLO - 99 - Error & Recovery',
};

function nodeId(key, suffix) {
  return crypto.createHash('sha256').update(`${key}:${suffix}`).digest('hex').slice(0, 8) + '-0000-4000-8000-' + crypto.createHash('sha256').update(`${suffix}:${key}`).digest('hex').slice(0, 12);
}

function trigger(key, position = [0, 0]) {
  return {
    parameters: {},
    type: 'n8n-nodes-base.executeWorkflowTrigger',
    typeVersion: 1.1,
    position,
    id: nodeId(key, 'trigger'),
    name: 'Execute Workflow Trigger',
  };
}

function codeNode(key, name, jsCode, position = [260, 0]) {
  return {
    parameters: { jsCode },
    type: 'n8n-nodes-base.code',
    typeVersion: 2,
    position,
    id: nodeId(key, name),
    name,
  };
}

function manual(key, position = [0, 0]) {
  return {
    parameters: {},
    type: 'n8n-nodes-base.manualTrigger',
    typeVersion: 1,
    position,
    id: nodeId(key, 'manual'),
    name: 'Manual ROI Trigger',
  };
}

function disabledSchedule(key, position = [0, 160]) {
  return {
    parameters: { rule: { interval: [{ field: 'days', daysInterval: 1 }] } },
    type: 'n8n-nodes-base.scheduleTrigger',
    typeVersion: 1.2,
    position,
    id: nodeId(key, 'schedule'),
    name: 'Production Schedule (DISABLED)',
    disabled: true,
  };
}

function executeNode(key, target, position) {
  return {
    parameters: {
      workflowId: { __rl: true, value: ids[target], mode: 'id' },
      options: { waitForSubWorkflow: true },
    },
    type: 'n8n-nodes-base.executeWorkflow',
    typeVersion: 1.3,
    position,
    id: nodeId(key, `execute-${target}`),
    name: `Execute ${names[target]}`,
  };
}

function postgresNode(key, name, query, queryReplacement, position = [520, 0]) {
  return {
    parameters: { operation: 'executeQuery', query, options: { queryReplacement } },
    type: 'n8n-nodes-base.postgres',
    typeVersion: 2.6,
    position,
    id: nodeId(key, name),
    name,
    credentials: {
      postgres: {
        id: 'CEFFLO_CONTENT_ENGINE_POSTGRES',
        name: 'CEFFLO Content Engine PostgreSQL',
      },
    },
  };
}

function workflow(key, nodes, connections, description) {
  const artifact = {
    id: ids[key],
    name: names[key],
    description,
    active: false,
    isArchived: false,
    nodes,
    connections,
    settings: { executionOrder: 'v1', binaryMode: 'separate' },
    staticData: null,
    meta: { ceffloRoi: true, providerMode: 'stub', activationProhibited: true },
    pinData: {},
    tags: [],
  };
  const file = `${names[key].replaceAll('CEFFLO - ', '').replaceAll(' ', '_').replaceAll('&', 'and')}.json`;
  fs.writeFileSync(path.join(out, file), JSON.stringify(artifact, null, 2) + '\n');
}

function linear(key, name, jsCode, description) {
  workflow(key, [trigger(key), codeNode(key, name, jsCode)], {
    'Execute Workflow Trigger': { main: [[{ node: name, type: 'main', index: 0 }]] },
  }, description);
}

const envelopeGuard = `
const input = $input.first().json;
const required = ['run_id','task_id','stage','status','market','language','objective','retry_count','created_at','updated_at'];
const missingEnvelopeFields = required.filter((key) => input[key] === undefined || input[key] === null || input[key] === '');
if (missingEnvelopeFields.length) throw new Error('ERROR_VALIDATION: missing envelope fields: ' + missingEnvelopeFields.join(','));
`;

const sotSteps = [
  codeNode('sot', 'Validate Request', `${envelopeGuard}return [{ json: input }];`, [240,0]),
  codeNode('sot', 'Resolve Canonical SOT Sources', `const input = $input.first().json;
if (!Array.isArray(input.sot_documents) || input.sot_documents.length === 0) throw new Error('ERROR_SOT: canonical GitHub SOT source list is missing');
return [{ json: input }];`, [480,0]),
  codeNode('sot', 'Fetch GitHub Content', `const input = $input.first().json;
const invalid = input.sot_documents.filter((doc) => !doc.source || !doc.content || !doc.source_revision);
if (invalid.length) throw new Error('ERROR_SOT: canonical source could not be resolved');
return [{ json: input }];`, [720,0]),
  codeNode('sot', 'Select Relevant Sections', `const input = $input.first().json;
const selected = input.sot_documents.filter((doc) => doc.section && ['product','brand','audience','content','claims'].includes(doc.domain));
if (!selected.length) throw new Error('ERROR_SOT: no relevant canonical sections resolved');
return [{ json: { ...input, sot_documents: selected } }];`, [960,0]),
  codeNode('sot', 'Build Context Pack', `const input = $input.first().json;
return [{ json: { ...input, context_pack: {
  product_truth_context: input.sot_documents.filter((d) => d.domain === 'product'),
  brand_context: input.sot_documents.filter((d) => d.domain === 'brand'),
  audience_context: input.sot_documents.filter((d) => d.domain === 'audience'),
  content_rules: input.sot_documents.filter((d) => d.domain === 'content'),
  claim_guardrails: input.sot_documents.filter((d) => d.domain === 'claims'),
  source_references: input.sot_documents.map((d) => ({ source: d.source, section: d.section, source_revision: d.source_revision })),
  retrieved_at: new Date().toISOString(), status: 'CONTEXT_READY'
}, stage: 'SOT_RETRIEVAL', status: 'CONTEXT_READY', updated_at: new Date().toISOString() } }];`, [1200,0]),
  codeNode('sot', 'Validate Context Pack', `const input = $input.first().json;
if (input.context_pack?.status !== 'CONTEXT_READY' || !input.context_pack.source_references?.length) throw new Error('ERROR_SOT: Context Pack validation failed');
return [{ json: input }];`, [1440,0]),
];
const sotConnections = { 'Execute Workflow Trigger': { main: [[{ node: 'Validate Request', type: 'main', index: 0 }]] } };
for (let i = 0; i < sotSteps.length - 1; i += 1) sotConnections[sotSteps[i].name] = { main: [[{ node: sotSteps[i + 1].name, type: 'main', index: 0 }]] };
workflow('sot', [trigger('sot'), ...sotSteps], sotConnections,
'Builds a task-specific Context Pack through the explicit GitHub adapter boundary. The offline fixture resolves canonical repository files at a Git revision; missing sources fail with ERROR_SOT.');

linear('research', 'Mine Deterministic Angles', `${envelopeGuard}
if (!input.context_pack || input.context_pack.status !== 'CONTEXT_READY') throw new Error('ERROR_SOT: Context Pack required');
const memory = Array.isArray(input.marketing_memory) ? input.marketing_memory : [];
const angle = { angle_id: 'angle-roi-001', topic: 'Local delivery operational clarity', audience: input.target_audience || 'Local business operator', pain_or_desire: 'Multiple local orders become hard to coordinate', angle: 'Turn scattered delivery activity into one visible operating flow', hook_direction: 'Show the operational contrast without unsupported claims', priority_score: 90, duplication_score: memory.some((m) => m.angle === 'Turn scattered delivery activity into one visible operating flow') ? 100 : 0, source_basis: input.context_pack.source_references };
return [{ json: { ...input, candidate_angles: [angle], selected_angles: [angle], stage: 'RESEARCH', status: 'ANGLES_READY', updated_at: new Date().toISOString() } }];`,
'Research-only boundary. Produces ranked angle contracts and checks Marketing Memory; it does not write platform copy.');

linear('concept', 'Build Core Experiment', `${envelopeGuard}
const angle = input.selected_angle || input.selected_angles?.[0];
if (!angle?.angle_id) throw new Error('ERROR_VALIDATION: selected internal angle required');
const id = input.master_concept_id;
if (!/^CEFFLO-\\d{4}-W\\d{2}-E\\d{3}$/.test(id || '')) throw new Error('ERROR_VALIDATION: master_concept_id must be CEFFLO-YYYY-Wxx-E###');
const concept = { master_concept_id: id, angle_id: angle.angle_id, core_message: 'Cefflo helps operators see and coordinate today’s local delivery operation.', problem: angle.pain_or_desire, insight: 'The coordination problem is operational visibility, not merely rider availability.', cefflo_relevance: 'Cefflo structures orders, coverage, zones, delivery planning, runs and delivery completion.', truth_basis: angle.source_basis, hook_direction: angle.hook_direction, cta: 'See how the delivery operation fits together.', creative_direction: 'Use only real product UI or clearly labelled illustration.', allowed_claims: ['Cefflo is built for businesses operating their own local same-day delivery.'], prohibited_claims: ['automatic route optimization','live GPS','guaranteed savings'], source_references: input.context_pack.source_references, status: 'CONCEPT_READY' };
return [{ json: { ...input, ...concept, stage: 'MASTER_CONCEPT', status: 'CONCEPT_READY', updated_at: new Date().toISOString() } }];`,
'Transforms one selected Research angle into a Core Experiment. master_concept_id is the canonical Core Experiment ID.');

linear('router', 'Create Three Lane Plan', `${envelopeGuard}
if (input.status !== 'CONCEPT_READY') throw new Error('ERROR_VALIDATION: concept not ready');
return [{ json: { ...input, creative_lanes: [
  { lane: 'meta', destinations: ['instagram','facebook'], workflow_id: '${ids.meta}' },
  { lane: 'tiktok', destinations: ['tiktok'], workflow_id: '${ids.tiktok}' },
  { lane: 'threads', destinations: ['threads'], workflow_id: '${ids.threads}' }
], stage: 'CREATIVE_ROUTER', status: 'CREATIVE_GENERATING', updated_at: new Date().toISOString() } }];`,
'Creates exactly three production lanes. Instagram and Facebook share one Meta package by default.');

linear('meta', 'Create Meta Stub Package', `${envelopeGuard}
const payload = { lane: 'meta', destinations: ['instagram','facebook'], format: 'reel', hook: 'When local orders multiply, delivery becomes an operation.', script: 'Show the real order-to-delivery operating flow without fabricated product proof.', scene_plan: [], on_screen_text: ['Orders','Coverage','Zones','Plan','Runs','Delivered'], visual_direction: 'Real Cefflo UI or clearly labelled illustration only.', caption: 'One operation. Everyone knows what happens next.', cta: 'See the operating flow.', duration_seconds: 20, aspect_ratio: '9:16', media_requirements: [], status: 'QA_PENDING' };
return [{ json: { ...input, creative_packages: [...(input.creative_packages || []).filter((p) => p.lane !== 'meta'), payload], stage: 'META_CREATOR', status: 'QA_PENDING', updated_at: new Date().toISOString() } }];`,
'Deterministic Meta stub package reused for Instagram and Facebook; no media provider is called.');

linear('tiktok', 'Create TikTok Stub Package', `${envelopeGuard}
const payload = { lane: 'tiktok', destinations: ['tiktok'], format: 'short_form_video', hook: 'Your riders may not be the problem. The run may be.', first_2_seconds: 'Show scattered orders becoming one visible run.', script: 'Explain the operational problem using truthful product language.', scene_plan: [], on_screen_text: ['Too many orders?','Build the delivery operation'], visual_direction: 'Fast, native, real UI where available.', caption: 'Local delivery gets harder when orders multiply.', cta: 'See how the operation fits together.', duration_seconds: 18, aspect_ratio: '9:16', media_requirements: [], status: 'QA_PENDING' };
return [{ json: { ...input, creative_packages: [...(input.creative_packages || []).filter((p) => p.lane !== 'tiktok'), payload], stage: 'TIKTOK_CREATOR', status: 'QA_PENDING', updated_at: new Date().toISOString() } }];`,
'Deterministic TikTok-native stub package; no AI or media provider is called.');

linear('threads', 'Create Threads Stub Package', `${envelopeGuard}
const payload = { lane: 'threads', destinations: ['threads'], format: 'text_post', opening_line: 'Local delivery gets complicated when orders multiply.', body: 'The real shift is treating delivery as one visible operation: orders, coverage, zones, plan, runs, riders and completion.', conversation_angle: 'Operational clarity for local business owners', cta_or_question: 'Which part of today’s delivery operation takes the most mental effort?', optional_followup_posts: [], status: 'QA_PENDING' };
return [{ json: { ...input, creative_packages: [...(input.creative_packages || []).filter((p) => p.lane !== 'threads'), payload], stage: 'THREADS_WRITER', status: 'QA_PENDING', updated_at: new Date().toISOString() } }];`,
'Deterministic Threads-native text stub; it is not an Instagram-caption copy.');

linear('qa', 'Run Deterministic QA', `${envelopeGuard}
const packages = input.creative_packages || [];
const expected = ['meta','tiktok','threads'];
const missing = expected.filter((lane) => !packages.some((p) => p.lane === lane));
const fake = packages.some((p) => JSON.stringify(p).match(/guaranteed|live gps|automatic route optimization/i));
let qa_status = missing.length || fake ? 'REVISE' : 'PASS';
const revision = input.qa_fixture?.revision_target || (missing.length ? { stage: 'CREATIVE', lane: missing[0] } : { stage: null, lane: null });
if (input.qa_fixture?.force_status) qa_status = input.qa_fixture.force_status;
const retry = Number(input.retry_count || 0);
if (qa_status === 'REVISE' && retry >= Number(input.max_retries ?? 2)) throw new Error('ERROR_VALIDATION: targeted retry limit exhausted');
return [{ json: { ...input, qa_status, qa_score: qa_status === 'PASS' ? 100 : 60, failed_rules: missing.map((x) => 'missing_' + x), qa_feedback: fake ? ['Unsupported claim detected'] : [], revision_target: revision, stage: 'AI_QA', status: qa_status === 'PASS' ? 'FOUNDER_REVIEW' : qa_status === 'REJECT' ? 'REJECTED' : 'REVISION_REQUIRED', updated_at: new Date().toISOString() } }];`,
'Automated Product Truth, brand, claim and platform-fit gate with bounded targeted revision.');

linear('approval', 'Apply Founder Decision', `${envelopeGuard}
const decision = input.founder_status || 'HOLD';
if (!['APPROVE','REVISE','REJECT','HOLD'].includes(decision)) throw new Error('ERROR_VALIDATION: invalid Founder decision');
if (input.qa_status !== 'PASS' && decision === 'APPROVE') throw new Error('ERROR_VALIDATION: Founder approval cannot bypass failed QA');
const status = { APPROVE: 'APPROVED', REVISE: 'REVISION_REQUIRED', REJECT: 'REJECTED', HOLD: 'HOLD' }[decision];
const revision_target = input.founder_revision_target ?? input.revision_target ?? { stage: null, lane: null };
let next = { ...input };
if (decision === 'REVISE' && revision_target.stage === 'MASTER_CONCEPT') {
  next = { ...next, creative_packages: [], qa_status: null, qa_score: null, publish_records: [], analytics_records: [], marketing_memory_records: [] };
} else if (decision === 'REVISE' && revision_target.lane) {
  next = { ...next, creative_packages: (next.creative_packages || []).filter((p) => p.lane !== revision_target.lane), publish_records: [], analytics_records: [], marketing_memory_records: [] };
}
return [{ json: { ...next, founder_status: decision, founder_feedback: input.founder_feedback ?? null, revision_target, approved_at: decision === 'APPROVE' ? new Date().toISOString() : null, stage: 'FOUNDER_APPROVAL', status, updated_at: new Date().toISOString() } }];`,
'Separate human gate. APPROVE, REVISE, REJECT and HOLD are explicit; only APPROVE can continue to Publisher.');

linear('publisher', 'Create Stub Publish Records', `${envelopeGuard}
if (input.founder_status !== 'APPROVE' || !['APPROVED','PUBLISHED'].includes(input.status)) throw new Error('ERROR_VALIDATION: Founder APPROVE required before publishing');
if ((input.publish_mode || 'stub') !== 'stub') throw new Error('ERROR_PUBLISH: live publishing is prohibited in ROI');
const platforms = ['instagram','facebook','tiktok','threads'];
const previous = input.publish_records || [];
const records = [...previous];
for (const platform of platforms) if (!records.some((r) => r.master_concept_id === input.master_concept_id && r.platform === platform && ['STUBBED','PUBLISHED'].includes(r.publish_status))) records.push({ content_id: input.master_concept_id + '-' + platform, master_concept_id: input.master_concept_id, platform, scheduled_time: null, published_time: null, publish_status: 'STUBBED', external_post_id: null, error_code: null });
return [{ json: { ...input, publish_records: records, stage: 'PUBLISHER', status: 'PUBLISHED', updated_at: new Date().toISOString() } }];`,
'Idempotent ROI publisher boundary. It creates four STUBBED destination records and cannot call live social APIs.');

linear('analytics', 'Create Platform-Aware Stub Metrics', `${envelopeGuard}
const baselines = { instagram: 72, facebook: 68, tiktok: 75, threads: 64 };
const analytics_records = (input.publish_records || []).map((r) => ({ content_id: r.content_id, platform: r.platform, views: 0, reach: 0, watch_time: 0, completion_rate: 0, likes: 0, comments: 0, shares: 0, saves: 0, clicks: 0, performance_score: baselines[r.platform], scoring_basis: 'deterministic_roi_platform_baseline', collected_at: new Date().toISOString() }));
return [{ json: { ...input, analytics_records, stage: 'ANALYTICS', status: 'ANALYZED', updated_at: new Date().toISOString() } }];`,
'Deterministic platform-aware analytics/scoring stub; no live analytics credential is required.');

linear('memory', 'Build Marketing Memory Records', `${envelopeGuard}
const angle = input.selected_angle || input.selected_angles?.[0] || {};
const byLane = Object.fromEntries((input.creative_packages || []).map((p) => [p.lane,p]));
const memories = (input.analytics_records || []).map((a) => { const lane = ['instagram','facebook'].includes(a.platform) ? 'meta' : a.platform; const p = byLane[lane] || {}; return { content_id: a.content_id, master_concept_id: input.master_concept_id, angle: angle.angle, hook: p.hook || p.opening_line || '', audience: angle.audience, content_pillar: null, platform: a.platform, format: p.format, publish_date: null, performance_score: a.performance_score, qa_feedback: input.qa_feedback || [], founder_feedback: input.founder_feedback ?? null, winner_or_loser: null, lessons: [], reuse_recommendation: null }; });
return [{ json: { ...input, marketing_memory_records: memories, stage: 'MARKETING_MEMORY', status: 'ARCHIVED', updated_at: new Date().toISOString() } }];`,
'Builds dynamic evidence records for PostgreSQL. Marketing Memory remains subordinate to canonical SOT.');

linear('winners', 'Select Weekly Winners Stub', `${envelopeGuard}
const memory = Array.isArray(input.marketing_memory_records) ? input.marketing_memory_records : [];
const top = [...memory].sort((a,b) => Number(b.performance_score || 0) - Number(a.performance_score || 0)).slice(0, 5);
return [{ json: { ...input, weekly_winners: top, stage: 'WEEKLY_WINNER_ENGINE', status: 'HOLD', schedule_active: false, updated_at: new Date().toISOString() } }];`,
'Weekly Winner boundary reads Marketing Memory and returns up to five deterministic candidates. No schedule is active in ROI.');

linear('paid', 'Return Paid Growth Stub Boundary', `${envelopeGuard}
if ((input.paid_growth_mode || 'stub') !== 'stub') throw new Error('ERROR_PUBLISH: paid execution is prohibited in ROI');
return [{ json: { ...input, paid_growth: { mode: 'stub', campaign_status: 'STUBBED', spend: 0, currency: null, advertising_api_called: false, founder_budget_gate: 'REQUIRED' }, stage: 'PAID_GROWTH', status: 'HOLD', schedule_active: false, updated_at: new Date().toISOString() } }];`,
'Disabled/stubbed Paid Growth production boundary. No spend, campaign activation, live advertising API or active schedule is possible.');

linear('error', 'Build Standard Error Envelope', `const input = $input.first().json; const now = new Date().toISOString();
const error = { run_id: input.run_id ?? null, workflow_name: input.workflow_name || '${names.error}', stage: input.stage || 'UNKNOWN', status: 'ERROR', retry_count: Number(input.retry_count || 0), error_code: input.error_code || 'ERROR_VALIDATION', error_message: input.error_message || 'Unspecified recoverable error', timestamp: now };
return [{ json: { ...input, error, manual_recovery: { permitted: true, retry_stage: input.stage || null, preserve_ids: true }, content_engine_event: { ...error, payload: input.event_payload || null }, updated_at: now } }];`,
'Standard error envelope, event contract and deterministic manual recovery route.');

const masterNodes = [manual('master', [0,0]), disabledSchedule('master', [0,180]), codeNode('master', 'Build Run Envelope', `const source = $input.first().json; const now = new Date().toISOString();
const run = source.run_id || '00000000-0000-4000-8000-000000000001';
return [{ json: { run_id: run, task_id: source.task_id || '00000000-0000-4000-8000-000000000002', campaign_id: source.campaign_id ?? null, concept_id: null, master_concept_id: source.master_concept_id || 'CEFFLO-2026-W37-E001', stage: 'ORCHESTRATOR', status: 'NEW', market: source.market || 'Malaysia', language: source.language || 'English', objective: source.objective || 'ROI architecture smoke test', target_audience: source.target_audience || 'Local business operator', priority: 'NORMAL', retry_count: Number(source.retry_count || 0), max_retries: 2, concepts_required: Number(source.concepts_required || 1), founder_status: source.founder_status || 'HOLD', publish_mode: 'stub', paid_growth_mode: 'stub', created_at: source.created_at || now, updated_at: now, sot_documents: source.sot_documents || [], marketing_memory: source.marketing_memory || [] } }];`, [240,0])];
const sequence = ['sot','research','concept','router','meta','tiktok','threads','qa','approval','publisher','analytics','memory'];
let x = 500;
for (const target of sequence) { masterNodes.push(executeNode('master', target, [x,0])); x += 250; }
masterNodes.push(codeNode('master', 'Run Summary', `const input = $input.first().json; return [{ json: { ...input, roi_summary: { status: input.status, paid_calls: 0, live_posts: 0, schedules_active: false, destinations: (input.publish_records || []).map((r) => r.platform) } } }];`, [x,0]));
const masterConnections = { 'Manual ROI Trigger': { main: [[{ node: 'Build Run Envelope', type: 'main', index: 0 }]] } };
let previous = 'Build Run Envelope';
for (const target of sequence) { const current = `Execute ${names[target]}`; masterConnections[previous] = { main: [[{ node: current, type: 'main', index: 0 }]] }; previous = current; }
masterConnections[previous] = { main: [[{ node: 'Run Summary', type: 'main', index: 0 }]] };
workflow('master', masterNodes, masterConnections, 'Inactive ROI master chain. Manual trigger only; disabled schedule is included as a visible production boundary.');

// Add disabled weekly schedule nodes to 11 and 12 without activating either workflow.
for (const [key, filePrefix] of [['winners','11_-_Weekly_Winner_Engine'], ['paid','12_-_Paid_Growth']]) {
  const file = path.join(out, `${filePrefix}.json`);
  const artifact = JSON.parse(fs.readFileSync(file, 'utf8'));
  artifact.nodes.push(disabledSchedule(key));
  fs.writeFileSync(file, JSON.stringify(artifact, null, 2) + '\n');
}

// PostgreSQL nodes are importable credential references only. The credential
// itself must be created in n8n's encrypted store by an authorized operator.
for (const spec of [
  ['memory', '10_-_Marketing_Memory', 'Build Marketing Memory Records', 'Persist Marketing Memory', 'SELECT cefflo_content_engine.persist_marketing_memory($1::jsonb) AS result', '={{ [JSON.stringify($json)] }}'],
  ['error', '99_-_Error_and_Recovery', 'Build Standard Error Envelope', 'Persist Error Event', 'SELECT cefflo_content_engine.log_event($1::jsonb) AS event_id', '={{ [JSON.stringify($json.content_engine_event)] }}'],
]) {
  const [key, filePrefix, previous, name, query, queryReplacement] = spec;
  const file = path.join(out, `${filePrefix}.json`);
  const artifact = JSON.parse(fs.readFileSync(file, 'utf8'));
  artifact.nodes.push(postgresNode(key, name, query, queryReplacement));
  artifact.connections[previous] = { main: [[{ node: name, type: 'main', index: 0 }]] };
  fs.writeFileSync(file, JSON.stringify(artifact, null, 2) + '\n');
}

console.log(`Generated ${Object.keys(names).length} inactive workflows in ${out}`);
