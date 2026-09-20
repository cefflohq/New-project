import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, '..');
const output = resolve(root, 'workflows');
const trigger = (id) => ({ parameters: { inputSource: 'passthrough' }, type: 'n8n-nodes-base.executeWorkflowTrigger', typeVersion: 1.1, position: [0, 0], id, name: 'Execute Workflow Trigger' });
const code = (id, name, jsCode, x) => ({ parameters: { jsCode }, type: 'n8n-nodes-base.code', typeVersion: 2, position: [x, 0], id, name });
const link = (node) => ({ main: [[{ node, type: 'main', index: 0 }]] });
const base = (id, name, description, nodes, connections, meta = {}) => ({
  id, name, description, active: false, isArchived: false, nodes, connections,
  settings: { executionOrder: 'v1', binaryMode: 'separate', saveDataErrorExecution: 'all', saveDataSuccessExecution: 'none' },
  staticData: null,
  meta: { ceffloEngineering: true, environment: 'DEV_STAGING', activationProhibitedUntil: 'FG-ENG-07', pilotEnabled: false, ...meta },
  pinData: {}, tags: []
});

const executeWorkflow = (id, name, workflowId, x) => ({
  parameters: { workflowId: { __rl: true, value: workflowId, mode: 'id' }, options: { waitForSubWorkflow: true } },
  type: 'n8n-nodes-base.executeWorkflow', typeVersion: 1.3, position: [x, 0], id, name
});

const control = base('20000000-0000-4000-8000-000000000000', 'CEFFLO ENG - 00 - Control Plane',
  'Inactive Engineering entrypoint. It fails closed until FG-ENG-07 and then chains scoped context and role execution.', [
    trigger('20000000-0000-4000-8000-000000000100'),
    code('20000000-0000-4000-8000-000000000101', 'Enforce Founder Gate', `const i=$input.first().json;
if(i.mode!=='qualification' && i.founder_gate!=='FG-ENG-07_APPROVED') throw new Error('PILOT_GATE_CLOSED');
if(i.environment==='production'||!['local','development','staging'].includes(i.environment)) throw new Error('ENVIRONMENT_DENIED');
if(!i.task_id||!i.baseline_sha||!i.task_pack_hash) throw new Error('TASK_ENVELOPE_INVALID');
return [{json:{...i,pilot_enabled:false,control_status:'GATE_ACCEPTED'}}];`, 240),
    executeWorkflow('20000000-0000-4000-8000-000000000102', 'Build Scoped Context', '20000000-0000-4000-8000-000000000001', 500),
    executeWorkflow('20000000-0000-4000-8000-000000000103', 'Execute Qualified Role', '20000000-0000-4000-8000-000000000002', 760)
  ], {
    'Execute Workflow Trigger': link('Enforce Founder Gate'),
    'Enforce Founder Gate': link('Build Scoped Context'),
    'Build Scoped Context': link('Execute Qualified Role')
  });

const context = base('20000000-0000-4000-8000-000000000001', 'CEFFLO ENG - 01 - Context Builder',
  'Validates a pre-hashed, git-pinned task pack and removes non-scoped context before model execution.', [
    trigger('20000000-0000-4000-8000-000000000110'),
    code('20000000-0000-4000-8000-000000000111', 'Validate Canonical Sources', `const i=$input.first().json;
const required=['product_truth','engineering_master','cyber_security_master','founder_decisions','repo_truth'];
if(!Array.isArray(i.context_manifest)||required.some(id=>!i.context_manifest.some(s=>s.source_id===id&&s.sha256&&s.git_sha_or_version))) throw new Error('CONTEXT_MANIFEST_INVALID');
if(i.context_manifest.some(s=>['superseded','deprecated','quarantined'].includes(s.status))) throw new Error('OBSOLETE_CONTEXT_DENIED');
return [{json:{...i,context_status:'SCOPED_AND_PINNED'}}];`, 260),
    code('20000000-0000-4000-8000-000000000112', 'Enforce Reference Contract', `const i=$input.first().json;
if(['E3','E4'].includes(i.role)){const a=i.visual_artifacts||[]; if(a.length!==2||!a.some(x=>x.kind==='founder_reference')||!a.some(x=>x.kind==='current_render')||a.some(x=>!x.sha256)) throw new Error('TWO_IMAGE_CONTRACT_REQUIRED');}
return [{json:i}];`, 520)
  ], {
    'Execute Workflow Trigger': link('Validate Canonical Sources'),
    'Validate Canonical Sources': link('Enforce Reference Contract')
  });

const routeGate = code('20000000-0000-4000-8000-000000000121', 'Enforce Route And Budget Reservation', `const i=$input.first().json;
if(!['E1','E2','E3','E4'].includes(i.role)) throw new Error('MODEL_ROLE_DENIED');
if(!i.budget_reservation_id||i.budget_status!=='reserved') throw new Error('BUDGET_NOT_RESERVED');
if(i.role==='E4'&&i.requested_actions?.some(a=>a.startsWith('source.'))) throw new Error('E4_REPAIR_DENIED');
if(['E3','E4'].includes(i.role)&&i.visual_artifacts?.length!==2) throw new Error('TWO_IMAGE_CONTRACT_REQUIRED');
if(!['openai-gpt-5.4-mini','deepseek-flash'].includes(i.route_id)) throw new Error('ROUTE_NOT_QUALIFIED');
return [{json:i}];`, 240);
const providerSwitch = {
  parameters: { rules: { values: [
    { conditions: { options: { caseSensitive: true, leftValue: '', typeValidation: 'strict', version: 2 }, conditions: [{ leftValue: '={{ $json.route_id }}', rightValue: 'openai-gpt-5.4-mini', operator: { type: 'string', operation: 'equals' } }], combinator: 'and' }, renameOutput: true, outputKey: 'openai' },
    { conditions: { options: { caseSensitive: true, leftValue: '', typeValidation: 'strict', version: 2 }, conditions: [{ leftValue: '={{ $json.route_id }}', rightValue: 'deepseek-flash', operator: { type: 'string', operation: 'equals' } }], combinator: 'and' }, renameOutput: true, outputKey: 'deepseek' }
  ] }, options: { fallbackOutput: 'extra' } },
  type: 'n8n-nodes-base.switch', typeVersion: 3.2, position: [500, 0], id: '20000000-0000-4000-8000-000000000122', name: 'Route Qualified Provider'
};
const http = (id, name, url, credentialType, credentialId, credentialName, y) => ({
  parameters: { method: 'POST', url, authentication: 'predefinedCredentialType', nodeCredentialType: credentialType, sendBody: true, contentType: 'raw', rawContentType: 'application/json', body: '={{ JSON.stringify($json.provider_request) }}', options: { timeout: 120000, redirect: { redirect: { followRedirects: false } }, response: { response: { fullResponse: true, neverError: true } } } },
  type: 'n8n-nodes-base.httpRequest', typeVersion: 4.2, position: [780, y], id, name,
  credentials: { [credentialType]: { id: credentialId, name: credentialName } }
});
const roleExecutor = base('20000000-0000-4000-8000-000000000002', 'CEFFLO ENG - 02 - Role Executor',
  'Dispatches only pre-reserved, qualified E1-E4 requests through existing encrypted n8n credentials. E5 is excluded.', [
    trigger('20000000-0000-4000-8000-000000000120'), routeGate, providerSwitch,
    http('20000000-0000-4000-8000-000000000123', 'OpenAI Responses', 'https://api.openai.com/v1/responses', 'openAiApi', 'BLg2BvJMiBBd9gw8', 'OpenAI account', -100),
    http('20000000-0000-4000-8000-000000000124', 'DeepSeek Responses', 'https://api.deepseek.com/responses', 'deepSeekApi', '52e3f617-3565-4c58-8405-93e2d4f1a980', 'DeepSeek', 100),
    code('20000000-0000-4000-8000-000000000125', 'Normalize Provider Result', `const i=$input.first().json; const h=i.headers||{}; delete h.authorization; delete h['set-cookie'];
return [{json:{provider_status_code:i.statusCode,provider_body:i.body??i,budget_settlement_required:true,provider_headers:h}}];`, 1060)
  ], {
    'Execute Workflow Trigger': link('Enforce Route And Budget Reservation'),
    'Enforce Route And Budget Reservation': link('Route Qualified Provider'),
    'Route Qualified Provider': { main: [[{ node: 'OpenAI Responses', type: 'main', index: 0 }], [{ node: 'DeepSeek Responses', type: 'main', index: 0 }], []] },
    'OpenAI Responses': link('Normalize Provider Result'),
    'DeepSeek Responses': link('Normalize Provider Result')
  }, { credentialValuesInWorkflow: false, e5ModelPath: false });

const failure = base('20000000-0000-4000-8000-000000000099', 'CEFFLO ENG - 99 - Failure & Escalation',
  'Classifies failure without resetting spend or retries. Uncertain provider usage retains the reservation.', [
    trigger('20000000-0000-4000-8000-000000000190'),
    code('20000000-0000-4000-8000-000000000191', 'Classify And Escalate', `const i=$input.first().json;
const retry=Number(i.retry_count||0); const repair=Number(i.repair_attempt||0);
const classified=['capability','transport','implementation','visual','verification','security','budget'].includes(i.failure_class)?i.failure_class:'unknown';
const retryAllowed=['capability','transport'].includes(classified)&&retry<2&&i.remaining_budget_usd>0;
const repairAllowed=['implementation','visual'].includes(classified)&&repair<3;
return [{json:{...i,failure_class:classified,retry_allowed:retryAllowed,repair_allowed:repairAllowed,budget_reset:false,reservation_disposition:i.usage_known?'settle':'uncertain',founder_escalation:!retryAllowed&&!repairAllowed}}];`, 260)
  ], { 'Execute Workflow Trigger': link('Classify And Escalate') });

await mkdir(output, { recursive: true });
for (const [file, workflow] of [
  ['00_-_Control_Plane.json', control], ['01_-_Context_Builder.json', context],
  ['02_-_Role_Executor.json', roleExecutor], ['99_-_Failure_and_Escalation.json', failure]
]) await writeFile(resolve(output, file), `${JSON.stringify(workflow, null, 2)}\n`);
