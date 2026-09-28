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
    // n8n 2.36 defaults an omitted input mode to "Define using fields
    // below", which rejects an empty field list. The CEFFLO envelope is a
    // versioned object, so subworkflows intentionally accept and validate the
    // complete upstream item in their first Code node.
    parameters: { inputSource: 'passthrough' },
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

// --- Phase 03 real-engine embedding ---------------------------------------
// n8n Code nodes run isolated JS with no filesystem/module resolution, so the
// only way for a workflow's Code node to run the REAL, tested Phase 03 logic
// (not a hand-copied re-implementation that can drift from it) is to embed
// the actual scripts/*.mjs source verbatim at generation time. This reads
// each file fresh on every `node scripts/generate-workflows.mjs` run, so the
// workflow JSON can never silently go stale relative to the module it embeds.
function stripFunction(src, name) {
  const marker = new RegExp(`^(export )?(async )?function ${name}\\(`, 'm');
  const m = marker.exec(src);
  if (!m) return src;
  const start = m.index;
  let i = src.indexOf('{', start);
  let depth = 0;
  for (; i < src.length; i += 1) {
    if (src[i] === '{') depth += 1;
    else if (src[i] === '}') { depth -= 1; if (depth === 0) { i += 1; break; } }
  }
  while (src[i] === '\n') i += 1;
  return src.slice(0, start) + src.slice(i);
}

function embedFile(relPath, { dropLinePatterns = [], stripFunctions = [] } = {}) {
  let src = fs.readFileSync(path.join(root, 'scripts', relPath), 'utf8');
  src = src.split('\n').filter((l) => !/^import /.test(l) && !dropLinePatterns.some((p) => p.test(l))).join('\n');
  for (const name of stripFunctions) src = stripFunction(src, name);
  src = src.replace(/^export (async function|function|const)/gm, '$1');
  return src.trim();
}

// loadTaxonomy() is excluded -- it reads the fixture files from disk, which a
// live n8n Code node cannot do. The same fixture content is embedded below as
// a plain object literal (TAXONOMY) instead; every other function in the file
// (proposeVehicleMix, resolveWorkforceLabel, buildScenario) is pure and is
// embedded unchanged.
const cilScenarioEmbed = embedFile('cil-scenario-engine.mjs', {
  dropLinePatterns: [/^const CIL_DIR = /],
  stripFunctions: ['loadTaxonomy'],
});
const cilValidateEmbed = embedFile('cil-validate.mjs');
const contentScriptEmbed = embedFile('content-script-engine.mjs');
const qaEngineEmbed = embedFile('qa-engine.mjs');

const cilFixturesDir = path.join(root, 'fixtures/cil');
const readFixture = (name) => JSON.parse(fs.readFileSync(path.join(cilFixturesDir, name), 'utf8'));
const taxonomy = {
  vehicleTypes: readFixture('vehicle_types.json'),
  businessArchetypes: readFixture('business_archetypes.json'),
  personas: readFixture('personas.json'),
  operationalSituations: readFixture('operational_situations.json'),
  emotionalTensions: readFixture('emotional_tensions.json'),
  creativeFormats: readFixture('creative_formats.json'),
};
const taxonomyLiteral = `const TAXONOMY = ${JSON.stringify(taxonomy)};`;

// Deterministic default CIL scenario seed used only when no caller-supplied
// cil_scenario_input is present on the envelope. Identical to the baseInput
// already exercised and asserted PASS by tests/phase03_test.mjs, so the
// default path through the real validator/QA is a known-good one.
const defaultScenarioInput = {
  business_archetype: { business_type: 'meal_prep', scale: 'small_team', daily_order_volume: 50, delivery_window: 'lunch' },
  archetype_category: 'food_and_meal_operations',
  order_profile: { count: 50, delivery_window: 'lunch', characteristics: ['multi_drop'] },
  delivery_team: { expected: 3, available: 3 },
  vehicle_mix: [{ type: 'motorcycle', count: 2 }, { type: 'car', count: 1 }],
  trigger: { type: 'delivery_person_unavailable' },
  operational_problem: { primary: 'workload_redistribution' },
  personas: ['owner_founder', 'delivery_person'],
  human_behaviour: ['owner_reviews_orders'],
  emotional_tension: ['urgency'],
  cefflo_relevance: ['delivery_planning', 'rider_assignment'],
  desired_outcome: ['clearer_delivery_plan'],
  creative_opportunities: ['pov_owner'],
  language_context: { register: 'everyday_business', primary_language: 'ms-MY' },
};
const defaultScenarioInputLiteral = `const DEFAULT_CIL_SCENARIO_INPUT = ${JSON.stringify(defaultScenarioInput)};`;

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
${taxonomyLiteral}
${defaultScenarioInputLiteral}
${cilScenarioEmbed}
const cil_scenario = buildScenario(input.cil_scenario_input || DEFAULT_CIL_SCENARIO_INPUT, TAXONOMY);
return [{ json: { ...input, candidate_angles: [angle], selected_angles: [angle], cil_scenario, stage: 'RESEARCH', status: 'ANGLES_READY', updated_at: new Date().toISOString() } }];`,
'Research-only boundary. Produces ranked angle contracts, checks Marketing Memory, and builds the real CIL scenario (scripts/cil-scenario-engine.mjs embedded verbatim below) that the Creative Router turns into a content package. It does not write platform copy.');

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
if (!input.cil_scenario) throw new Error('ERROR_VALIDATION: cil_scenario required before Creative Router');
${taxonomyLiteral}
${cilScenarioEmbed}
${contentScriptEmbed}
const content_package = buildContentPackage(input.cil_scenario, TAXONOMY);
return [{ json: { ...input, content_package, creative_lanes: [
  { lane: 'meta', destinations: ['instagram','facebook'], workflow_id: '${ids.meta}' },
  { lane: 'tiktok', destinations: ['tiktok'], workflow_id: '${ids.tiktok}' },
  { lane: 'threads', destinations: ['threads'], workflow_id: '${ids.threads}' }
], stage: 'CREATIVE_ROUTER', status: 'CREATIVE_GENERATING', updated_at: new Date().toISOString() } }];`,
'Creates exactly three production lanes and builds the real shared content package (scripts/content-script-engine.mjs embedded verbatim below) each lane creator adapts from. Instagram and Facebook share one Meta package by default.');

linear('meta', 'Create Meta Stub Package', `${envelopeGuard}
if (!input.content_package) throw new Error('ERROR_VALIDATION: content_package required from Creative Router');
const lanePkg = input.content_package.platform_packages.find((p) => p.lane === 'meta');
if (!lanePkg) throw new Error('ERROR_VALIDATION: meta lane package missing from content_package');
const payload = { ...lanePkg, status: 'QA_PENDING' };
return [{ json: { ...input, creative_packages: [...(input.creative_packages || []).filter((p) => p.lane !== 'meta'), payload], stage: 'META_CREATOR', status: 'QA_PENDING', updated_at: new Date().toISOString() } }];`,
'Adapts the real shared content package into the Meta lane, reused for Instagram and Facebook; no media provider is called.');

linear('tiktok', 'Create TikTok Stub Package', `${envelopeGuard}
if (!input.content_package) throw new Error('ERROR_VALIDATION: content_package required from Creative Router');
const lanePkg = input.content_package.platform_packages.find((p) => p.lane === 'tiktok');
if (!lanePkg) throw new Error('ERROR_VALIDATION: tiktok lane package missing from content_package');
const payload = { ...lanePkg, status: 'QA_PENDING' };
return [{ json: { ...input, creative_packages: [...(input.creative_packages || []).filter((p) => p.lane !== 'tiktok'), payload], stage: 'TIKTOK_CREATOR', status: 'QA_PENDING', updated_at: new Date().toISOString() } }];`,
'Adapts the real shared content package into the TikTok-native lane; no AI or media provider is called.');

linear('threads', 'Create Threads Stub Package', `${envelopeGuard}
if (!input.content_package) throw new Error('ERROR_VALIDATION: content_package required from Creative Router');
const lanePkg = input.content_package.platform_packages.find((p) => p.lane === 'threads');
if (!lanePkg) throw new Error('ERROR_VALIDATION: threads lane package missing from content_package');
const payload = { ...lanePkg, status: 'QA_PENDING' };
return [{ json: { ...input, creative_packages: [...(input.creative_packages || []).filter((p) => p.lane !== 'threads'), payload], stage: 'THREADS_WRITER', status: 'QA_PENDING', updated_at: new Date().toISOString() } }];`,
'Adapts the real shared content package into the Threads-native text lane; it is not an Instagram-caption copy.');

linear('qa', 'Run Deterministic QA', `${envelopeGuard}
if (!input.cil_scenario || !input.content_package) throw new Error('ERROR_VALIDATION: cil_scenario and content_package required before AI QA');
${taxonomyLiteral}
${cilValidateEmbed}
${qaEngineEmbed}
const packages = input.creative_packages || [];
const expected = ['meta','tiktok','threads'];
const missing = expected.filter((lane) => !packages.some((p) => p.lane === lane));
const preQa = preProductionQA(input.cil_scenario, input.content_package, TAXONOMY, input.recent_hooks || []);
let qa_status = missing.length || preQa.status !== 'PASS' ? 'REVISE' : 'PASS';
const revision = input.qa_fixture?.revision_target || (missing.length ? { stage: 'CREATIVE', lane: missing[0] } : { stage: null, lane: null });
if (input.qa_fixture?.force_status) qa_status = input.qa_fixture.force_status;
const retry = Number(input.retry_count || 0);
if (qa_status === 'REVISE' && retry >= Number(input.max_retries ?? 2)) throw new Error('ERROR_VALIDATION: targeted retry limit exhausted');
return [{ json: { ...input, qa_status, qa_score: qa_status === 'PASS' ? 100 : 60, failed_rules: [...missing.map((x) => 'missing_' + x), ...preQa.failed_checks], qa_feedback: preQa.failed_checks, revision_target: revision, stage: 'AI_QA', status: qa_status === 'PASS' ? 'FOUNDER_REVIEW' : qa_status === 'REJECT' ? 'REJECTED' : 'REVISION_REQUIRED', updated_at: new Date().toISOString() } }];`,
'Automated Product Truth, brand, claim and platform-fit gate -- the real preProductionQA + validateScenario (scripts/qa-engine.mjs + cil-validate.mjs embedded verbatim below) -- with bounded targeted revision.');

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
//
// A Postgres node's output is its query result columns, not a passthrough of
// its input. That's only harmless when nothing downstream ever reads the
// workflow's return value -- true for CEFFLO - 99 (error path, nothing reads
// it afterward), but NOT true for CEFFLO - 03 (04-10 still run after it) or
// CEFFLO - 10 (the Master Orchestrator's own Run Summary node reads its
// output for roi_summary.destinations). Both of those need a restoreFrom
// step that re-emits the full envelope from the node named in restoreFrom,
// confirmed persisted via a marker flag, rather than leaving the raw
// Postgres query result as the workflow's final output.
for (const spec of [
  ['concept', '03_-_Master_Concept_Builder', 'Build Core Experiment', 'Persist Master Concept', 'SELECT cefflo_content_engine.persist_master_concept($1::jsonb) AS master_concept_id', '={{ [JSON.stringify($json)] }}', 'Build Core Experiment', 'Confirm Master Concept Persisted', 'master_concept_persisted'],
  ['memory', '10_-_Marketing_Memory', 'Build Marketing Memory Records', 'Persist Marketing Memory', 'SELECT cefflo_content_engine.persist_marketing_memory($1::jsonb) AS result', '={{ [JSON.stringify($json)] }}', 'Build Marketing Memory Records', 'Confirm Marketing Memory Persisted', 'marketing_memory_persisted'],
  ['error', '99_-_Error_and_Recovery', 'Build Standard Error Envelope', 'Persist Error Event', 'SELECT cefflo_content_engine.log_event($1::jsonb) AS event_id', '={{ [JSON.stringify($json.content_engine_event)] }}', null, null, null],
]) {
  const [key, filePrefix, previous, name, query, queryReplacement, restoreFrom, restoreName, markerField] = spec;
  const file = path.join(out, `${filePrefix}.json`);
  const artifact = JSON.parse(fs.readFileSync(file, 'utf8'));
  artifact.nodes.push(postgresNode(key, name, query, queryReplacement));
  artifact.connections[previous] = { main: [[{ node: name, type: 'main', index: 0 }]] };
  if (restoreFrom) {
    artifact.nodes.push(codeNode(key, restoreName, `return [{ json: { ...$('${restoreFrom}').item.json, ${markerField}: true } }];`, [780, 0]));
    artifact.connections[name] = { main: [[{ node: restoreName, type: 'main', index: 0 }]] };
  }
  fs.writeFileSync(file, JSON.stringify(artifact, null, 2) + '\n');
}

console.log(`Generated ${Object.keys(names).length} inactive workflows in ${out}`);
