import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(import.meta.dirname, '..');
for (const contract of ['global-envelope.schema.json', 'context-pack.schema.json', 'stage-contracts.json']) {
  assert.doesNotThrow(() => JSON.parse(fs.readFileSync(path.join(root, 'contracts', contract), 'utf8')), `invalid contract: ${contract}`);
}
const workflowDir = path.join(root, 'workflows');
const files = fs.readdirSync(workflowDir).filter((x) => x.endsWith('.json')).sort();
const expected = [
  'CEFFLO - 00 - Master Orchestrator', 'CEFFLO - 01 - SOT Retrieval',
  'CEFFLO - 02 - Research & Angle Miner', 'CEFFLO - 03 - Master Concept Builder',
  'CEFFLO - 04 - Creative Router', 'CEFFLO - 05A - Meta Creator',
  'CEFFLO - 05B - TikTok Creator', 'CEFFLO - 05C - Threads Writer',
  'CEFFLO - 06 - AI QA', 'CEFFLO - 07 - Founder Approval',
  'CEFFLO - 08 - Publisher', 'CEFFLO - 09 - Analytics & Scoring',
  'CEFFLO - 10 - Marketing Memory', 'CEFFLO - 11 - Weekly Winner Engine',
  'CEFFLO - 12 - Paid Growth', 'CEFFLO - 99 - Error & Recovery',
];
assert.equal(files.length, expected.length);
const workflows = files.map((file) => JSON.parse(fs.readFileSync(path.join(workflowDir, file), 'utf8')));
assert.deepEqual(workflows.map((x) => x.name).sort(), [...expected].sort());
assert.equal(new Set(workflows.map((x) => x.id)).size, expected.length);
for (const workflow of workflows) {
  assert.equal(workflow.active, false, `${workflow.name} must be inactive`);
  assert.equal(workflow.meta.activationProhibited, true);
  assert(workflow.nodes.length >= 2);
  assert(!JSON.stringify(workflow).match(/\bsk-[A-Za-z0-9]{16,}|\bservice_role\b|\bghp_[A-Za-z0-9]{16,}/), `${workflow.name} contains a secret-like value`);
}
for (const name of ['CEFFLO - 00 - Master Orchestrator', 'CEFFLO - 11 - Weekly Winner Engine', 'CEFFLO - 12 - Paid Growth']) {
  const workflow = workflows.find((x) => x.name === name);
  const schedules = workflow.nodes.filter((x) => x.type === 'n8n-nodes-base.scheduleTrigger');
  assert(schedules.length >= 1 && schedules.every((x) => x.disabled === true), `${name} schedule must be disabled`);
}
const master = workflows.find((x) => x.name === 'CEFFLO - 00 - Master Orchestrator');
assert.equal(master.nodes.filter((x) => x.type === 'n8n-nodes-base.executeWorkflow').length, 12);
const routerCode = workflows.find((x) => x.name === 'CEFFLO - 04 - Creative Router').nodes.find((x) => x.type === 'n8n-nodes-base.code').parameters.jsCode;
assert(routerCode.includes("['instagram','facebook']"));
const sot = workflows.find((x) => x.name === 'CEFFLO - 01 - SOT Retrieval');
assert.deepEqual(sot.nodes.filter((x) => x.type === 'n8n-nodes-base.code').map((x) => x.name), [
  'Validate Request', 'Resolve Canonical SOT Sources', 'Fetch GitHub Content',
  'Select Relevant Sections', 'Build Context Pack', 'Validate Context Pack',
]);
const paidText = JSON.stringify(workflows.find((x) => x.name === 'CEFFLO - 12 - Paid Growth'));
assert(paidText.includes("spend: 0"));
assert(!paidText.match(/facebook graph|ads manager|campaign_status:\s*['"]ACTIVE|advertising_api_called:\s*true/i));
console.log(JSON.stringify({ result: 'PASS', workflow_files: files.length, all_inactive: true, disabled_schedules: 3, secrets_found: 0 }, null, 2));
