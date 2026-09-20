import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';

const [provider, referencePath, renderPath, outputPath] = process.argv.slice(2);
if (!['openai', 'deepseek'].includes(provider) || !referencePath || !renderPath || !outputPath) throw new Error('usage: provider reference render output');
const image = async (path, mime) => `data:${mime};base64,${(await readFile(path)).toString('base64')}`;
const reference = await image(referencePath, 'image/jpeg');
const render = await image(renderPath, 'image/png');
const credentialConfig = JSON.parse(await readFile(resolve('automation/n8n/engineering/config/provider-credentials.json'), 'utf8'));
if (provider === 'openai' && (credentialConfig.openai.status !== 'CONFIGURED' || !credentialConfig.openai.n8nCredentialId || credentialConfig.openai.qualificationAuthorized !== true)) {
  throw new Error('engineering_openai_credential_or_qualification_not_authorized');
}
const route = provider === 'openai' ? {
  id: '21000000-0000-4000-8000-000000000001', model: 'gpt-5.4-mini', url: 'https://api.openai.com/v1/responses',
  credentialType: 'openAiApi', credentialId: credentialConfig.openai.n8nCredentialId, credentialName: credentialConfig.openai.intendedN8nCredentialName
} : {
  id: '21000000-0000-4000-8000-000000000002', model: 'deepseek-flash', url: 'https://api.deepseek.com/responses',
  credentialType: 'deepSeekApi', credentialId: '52e3f617-3565-4c58-8405-93e2d4f1a980', credentialName: 'DeepSeek'
};
const schema = {
  type: 'object', additionalProperties: false, required: ['e1','e2','e3','e4'], properties: {
    e1: { type: 'object', additionalProperties: false, required: ['scope','plan','contract_compliant'], properties: { scope: { type: 'string' }, plan: { type: 'array', items: { type: 'string' } }, contract_compliant: { type: 'boolean' } } },
    e2: { type: 'object', additionalProperties: false, required: ['dart_finding','tool_request'], properties: { dart_finding: { type: 'string' }, tool_request: { type: 'object', additionalProperties: false, required: ['action','arguments'], properties: { action: { type: 'string', enum: ['repo.read'] }, arguments: { type: 'object', additionalProperties: false, required: ['path'], properties: { path: { type: 'string' } } } } } } },
    e3: { type: 'object', additionalProperties: false, required: ['reference_seen','render_seen','visual_differences','menu_exception'], properties: { reference_seen: { type: 'boolean' }, render_seen: { type: 'boolean' }, visual_differences: { type: 'array', items: { type: 'string' } }, menu_exception: { type: 'string' } } },
    e4: { type: 'object', additionalProperties: false, required: ['verdict','findings','source_repair_requested'], properties: { verdict: { type: 'string', enum: ['PASS','FAIL'] }, findings: { type: 'array', items: { type: 'string' } }, source_repair_requested: { type: 'boolean' } } }
  }
};
const prompt = `Qualification only. Do not modify code and do not claim this is the real pilot. Return the required JSON object.\nE1: scope a V11 visual-match task and give a short contract-compliant plan.\nE2: inspect this supplied Dart fact: NavTab values are today, orders, zones, riders, menu; the current render visibly labels the fifth item Settings. State the implementation concern and emit exactly one typed repo.read request for apps/vendor_mobile/lib/ui/shell.dart. Do not request shell or credentials.\nE3: genuinely compare BOTH attached images: Image 1 is Founder reference UI-VENDOR-V11-TODAY-v1; Image 2 is the actual current V11 render from the exact candidate tree. Identify concrete visual differences. D-42 requires the fifth nav label semantically be Menu even though the reference says Settings.\nE4: independently verify the same evidence. Visual verification is required, so no image means no pass. Since current render says Settings and D-42 says Menu, return FAIL, include that finding, and request no source repair.`;
const request = {
  model: route.model,
  input: [{ role: 'user', content: [
    { type: 'input_text', text: prompt },
    { type: 'input_image', image_url: reference },
    { type: 'input_image', image_url: render }
  ] }],
  text: { format: { type: 'json_schema', name: 'cefflo_engineering_qualification', strict: true, schema } },
  max_output_tokens: 1400
};
const workflow = {
  id: route.id, name: `CEFFLO ENG QUAL - ${provider.toUpperCase()} - TWO IMAGE`, active: false, isArchived: false,
  nodes: [
    { parameters: {}, type: 'n8n-nodes-base.manualTrigger', typeVersion: 1, position: [0,0], id: `${route.id.slice(0,-1)}3`, name: 'Manual Qualification Trigger' },
    { parameters: { jsCode: `return [{json:{provider_request:${JSON.stringify(request)}}}];` }, type: 'n8n-nodes-base.code', typeVersion: 2, position: [240,0], id: `${route.id.slice(0,-1)}4`, name: 'Build Fixed Qualification Request' },
    { parameters: { method: 'POST', url: route.url, authentication: 'predefinedCredentialType', nodeCredentialType: route.credentialType, sendBody: true, contentType: 'raw', rawContentType: 'application/json', body: '={{ JSON.stringify($json.provider_request) }}', options: { timeout: 120000, redirect: { redirect: { followRedirects: false } }, response: { response: { fullResponse: true, neverError: true } } } }, type: 'n8n-nodes-base.httpRequest', typeVersion: 4.2, position: [500,0], id: `${route.id.slice(0,-1)}5`, name: 'Provider Qualification', credentials: { [route.credentialType]: { id: route.credentialId, name: route.credentialName } } }
  ],
  connections: { 'Manual Qualification Trigger': { main: [[{node:'Build Fixed Qualification Request',type:'main',index:0}]] }, 'Build Fixed Qualification Request': { main: [[{node:'Provider Qualification',type:'main',index:0}]] } },
  settings: { executionOrder: 'v1', saveDataErrorExecution: 'all', saveDataSuccessExecution: 'none' }, staticData: null,
  meta: { ceffloEngineeringQualification: true, activationProhibited: true, referenceId: 'UI-VENDOR-V11-TODAY-v1', twoImageRequest: true }, pinData: {}, tags: []
};
await writeFile(resolve(outputPath), `${JSON.stringify(workflow, null, 2)}\n`, { mode: 0o600 });
