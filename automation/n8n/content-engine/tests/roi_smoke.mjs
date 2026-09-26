import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { resolveCanonicalSot } from '../adapters/github-sot.mjs';

const root = path.resolve(import.meta.dirname, '..');
const repo = path.resolve(root, '../../..');
const workflows = new Map();
for (const file of fs.readdirSync(path.join(root, 'workflows')).filter((x) => x.endsWith('.json'))) {
  const workflow = JSON.parse(fs.readFileSync(path.join(root, 'workflows', file), 'utf8'));
  workflows.set(workflow.name, workflow);
}

function runCode(workflowName, input, nodeName = null) {
  const workflow = workflows.get(workflowName);
  assert(workflow, `workflow missing: ${workflowName}`);
  const nodes = workflow.nodes.filter((node) => node.type === 'n8n-nodes-base.code');
  const node = nodeName ? nodes.find((x) => x.name === nodeName) : nodes[0];
  assert(node, `code node missing: ${workflowName}`);
  const invoke = new Function('$input', node.parameters.jsCode);
  const output = invoke({ first: () => ({ json: structuredClone(input) }) });
  assert(Array.isArray(output) && output[0]?.json, `${workflowName} returned invalid items`);
  return output[0].json;
}

const fixture = JSON.parse(fs.readFileSync(path.join(root, 'fixtures/roi_input.json'), 'utf8'));
const manifest = JSON.parse(fs.readFileSync(path.join(root, 'fixtures/sot_manifest.json'), 'utf8'));
const sot_documents = resolveCanonicalSot(repo, manifest);
assert.throws(() => resolveCanonicalSot(repo, [{ ...manifest[0], source: 'docs/cefflo/sot/DOES_NOT_EXIST.md' }]), /ERROR_SOT/);

let state = { ...fixture, sot_documents, marketing_memory: [] };
for (const node of ['Validate Request', 'Resolve Canonical SOT Sources', 'Fetch GitHub Content', 'Select Relevant Sections', 'Build Context Pack', 'Validate Context Pack']) {
  state = runCode('CEFFLO - 01 - SOT Retrieval', state, node);
}
assert.equal(state.status, 'CONTEXT_READY');
assert.equal(state.context_pack.source_references.length, 5);

assert.throws(
  () => runCode('CEFFLO - 01 - SOT Retrieval', { ...fixture, sot_documents: [] }, 'Resolve Canonical SOT Sources'),
  /ERROR_SOT/,
  'missing SOT must fail safely',
);

state = runCode('CEFFLO - 02 - Research & Angle Miner', state);
assert.equal(state.status, 'ANGLES_READY');
assert.equal(state.selected_angles.length, 1);
assert(!('script' in state.selected_angles[0]), 'Research must not write platform scripts');

state = runCode('CEFFLO - 03 - Master Concept Builder', state);
assert.match(state.master_concept_id, /^CEFFLO-\d{4}-W\d{2}-E\d{3}$/);
assert.equal(state.status, 'CONCEPT_READY');
assert(state.source_references.length > 0, 'source references must survive into concept');
assert.throws(
  () => runCode('CEFFLO - 03 - Master Concept Builder', { ...state, master_concept_id: 'angle-roi-001' }),
  /master_concept_id/,
);

state = runCode('CEFFLO - 04 - Creative Router', state);
assert.deepEqual(state.creative_lanes.map((x) => x.lane), ['meta', 'tiktok', 'threads']);
assert.deepEqual(state.creative_lanes[0].destinations, ['instagram', 'facebook']);

state = runCode('CEFFLO - 05A - Meta Creator', state);
state = runCode('CEFFLO - 05B - TikTok Creator', state);
state = runCode('CEFFLO - 05C - Threads Writer', state);
assert.deepEqual(state.creative_packages.map((x) => x.lane), ['meta', 'tiktok', 'threads']);

state = runCode('CEFFLO - 06 - AI QA', state);
assert.equal(state.qa_status, 'PASS');
assert.equal(state.status, 'FOUNDER_REVIEW');

for (const lane of ['meta', 'tiktok', 'threads']) {
  const revised = runCode('CEFFLO - 06 - AI QA', {
    ...state,
    qa_fixture: { force_status: 'REVISE', revision_target: { stage: 'CREATIVE', lane } },
  });
  assert.deepEqual(revised.revision_target, { stage: 'CREATIVE', lane });
  assert.equal(revised.status, 'REVISION_REQUIRED');
}
assert.throws(
  () => runCode('CEFFLO - 06 - AI QA', { ...state, retry_count: 2, qa_fixture: { force_status: 'REVISE' } }),
  /retry limit exhausted/,
);

for (const founder_status of ['HOLD', 'REJECT', 'REVISE']) {
  const gated = runCode('CEFFLO - 07 - Founder Approval', { ...state, founder_status });
  assert.notEqual(gated.status, 'APPROVED');
  assert.throws(() => runCode('CEFFLO - 08 - Publisher', gated), /Founder APPROVE required/);
}
const metaRevision = runCode('CEFFLO - 07 - Founder Approval', { ...state, founder_status: 'REVISE', founder_revision_target: { stage: 'CREATIVE', lane: 'meta' } });
assert.deepEqual(metaRevision.creative_packages.map((x) => x.lane), ['tiktok', 'threads'], 'lane revision must preserve passed lanes');
const conceptRevision = runCode('CEFFLO - 07 - Founder Approval', { ...state, founder_status: 'REVISE', founder_revision_target: { stage: 'MASTER_CONCEPT', lane: null } });
assert.equal(conceptRevision.creative_packages.length, 0, 'Master Concept revision must invalidate dependent creative artifacts');
assert.equal(conceptRevision.qa_status, null);

state = runCode('CEFFLO - 07 - Founder Approval', { ...state, founder_status: 'APPROVE' });
assert.equal(state.status, 'APPROVED');
state = runCode('CEFFLO - 08 - Publisher', state);
assert.equal(state.publish_records.length, 4);
assert.deepEqual(state.publish_records.map((x) => x.platform), ['instagram', 'facebook', 'tiktok', 'threads']);
assert(state.publish_records.every((x) => x.publish_status === 'STUBBED'));
const replay = runCode('CEFFLO - 08 - Publisher', state);
assert.equal(replay.publish_records.length, 4, 'publisher replay must not duplicate destinations');
assert.throws(() => runCode('CEFFLO - 08 - Publisher', { ...state, publish_mode: 'live' }), /live publishing is prohibited/);

state = runCode('CEFFLO - 09 - Analytics & Scoring', state);
assert.equal(state.analytics_records.length, 4);
assert.equal(new Set(state.analytics_records.map((x) => x.performance_score)).size, 4, 'scoring must be platform-aware');
state = runCode('CEFFLO - 10 - Marketing Memory', state);
assert.equal(state.marketing_memory_records.length, 4);
assert(state.marketing_memory_records.every((x) => x.master_concept_id === fixture.master_concept_id));

const learned = runCode('CEFFLO - 02 - Research & Angle Miner', {
  ...state,
  marketing_memory: state.marketing_memory_records,
  status: 'CONTEXT_READY',
});
assert.equal(learned.candidate_angles[0].duplication_score, 100, 'Research must retrieve/use prior Marketing Memory');
assert.equal(state.context_pack.status, 'CONTEXT_READY', 'Marketing Memory must not overwrite canonical SOT');

const weekly = runCode('CEFFLO - 11 - Weekly Winner Engine', { ...state, status: 'ANALYZED' });
assert(weekly.weekly_winners.length <= 5);
assert.equal(weekly.schedule_active, false);
const paid = runCode('CEFFLO - 12 - Paid Growth', weekly);
assert.equal(paid.paid_growth.campaign_status, 'STUBBED');
assert.equal(paid.paid_growth.spend, 0);
assert.equal(paid.paid_growth.advertising_api_called, false);
assert.equal(paid.schedule_active, false);
assert.throws(() => runCode('CEFFLO - 12 - Paid Growth', { ...weekly, paid_growth_mode: 'live' }), /paid execution is prohibited/);

const error = runCode('CEFFLO - 99 - Error & Recovery', {
  ...fixture,
  workflow_name: 'CEFFLO - 01 - SOT Retrieval',
  stage: 'SOT_RETRIEVAL',
  error_code: 'ERROR_SOT',
  error_message: 'fixture source missing',
});
assert.equal(error.error.status, 'ERROR');
assert.equal(error.error.error_code, 'ERROR_SOT');
assert.equal(error.manual_recovery.preserve_ids, true);

console.log(JSON.stringify({
  result: 'PASS',
  workflows: workflows.size,
  source_references: state.context_pack.source_references.length,
  lanes: state.creative_packages.map((x) => x.lane),
  destinations: state.publish_records.map((x) => x.platform),
  publisher_replay_records: replay.publish_records.length,
  analytics_records: state.analytics_records.length,
  memory_records: state.marketing_memory_records.length,
  weekly_winners: weekly.weekly_winners.length,
  paid_growth: paid.paid_growth,
}, null, 2));
