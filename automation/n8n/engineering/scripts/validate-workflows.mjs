import { readdir, readFile } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../workflows');
const files = (await readdir(root)).filter((file) => file.endsWith('.json'));
if (files.length !== 4) throw new Error(`expected_4_workflows_got_${files.length}`);
const ids = new Set();
for (const file of files) {
  const workflow = JSON.parse(await readFile(resolve(root, file), 'utf8'));
  if (workflow.active !== false || workflow.meta?.activationProhibitedUntil !== 'FG-ENG-07' || workflow.meta?.pilotEnabled !== false) throw new Error(`${file}:activation_boundary_invalid`);
  if (ids.has(workflow.id)) throw new Error(`${file}:duplicate_id`); ids.add(workflow.id);
  const serialized = JSON.stringify(workflow);
  if (/sk-[A-Za-z0-9_-]{12,}|Bearer\s+[A-Za-z0-9._~+/-]+/.test(serialized)) throw new Error(`${file}:secret_pattern`);
  if (serialized.includes('executeCommand') || serialized.includes('shell')) throw new Error(`${file}:shell_node_denied`);
  for (const node of workflow.nodes) if (node.disabled !== true && !workflow.connections[node.name] && node !== workflow.nodes.at(-1) && !node.name.includes('Responses')) throw new Error(`${file}:unconnected_${node.name}`);
}
console.log(`validated ${files.length} inactive Engineering workflows`);
