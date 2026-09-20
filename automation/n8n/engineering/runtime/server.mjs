import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { ReplayStore, verifyEnvelope } from './lib/auth.mjs';
import { PolicyEngine } from './lib/policy.mjs';
import { BudgetLedger } from './lib/budget-ledger.mjs';
import { ActionRegistry } from './lib/action-registry.mjs';
import { redact } from './lib/redaction.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const packageRoot = resolve(here, '..');
const repoRoot = process.env.CEFFLO_ENGINEERING_REPO_ROOT || resolve(packageRoot, '../../..');
const configRoot = resolve(packageRoot, 'config');
const load = async (name) => JSON.parse(await readFile(resolve(configRoot, name), 'utf8'));
const [commandPolicy, roles, controls, costPolicy] = await Promise.all(['command-policy.json', 'roles.json', 'runtime-controls.json', 'cost-policy.json'].map(load));
const policy = new PolicyEngine({ commandPolicy, roles, controls });
const actions = new ActionRegistry({ root: repoRoot });
const replay = new ReplayStore();
const ledger = new BudgetLedger({ file: process.env.CEFFLO_ENGINEERING_LEDGER || resolve(packageRoot, 'state/budget-ledger.json'), hardBudgetUsd: costPolicy.hardBudget });
await ledger.init();

function respond(res, status, body) {
  res.writeHead(status, { 'content-type': 'application/json' });
  res.end(`${JSON.stringify(redact(body))}\n`);
}

async function body(req) {
  const chunks = []; let size = 0;
  for await (const chunk of req) { size += chunk.length; if (size > 1_000_000) throw new Error('body_too_large'); chunks.push(chunk); }
  return JSON.parse(Buffer.concat(chunks).toString('utf8'));
}

const server = createServer(async (req, res) => {
  try {
    if (req.method === 'GET' && req.url === '/health') return respond(res, 200, { status: 'ok', pilotEnabled: controls.pilotEnabled, qualificationEnabled: controls.qualificationEnabled });
    if (req.method !== 'POST') return respond(res, 404, { error: 'not_found' });
    const input = await body(req);
    verifyEnvelope(input, process.env.CEFFLO_ENGINEERING_RUNNER_HMAC_SECRET, replay);
    if (req.url === '/v1/budget/reserve') return respond(res, 200, await ledger.reserve(input.payload));
    if (req.url === '/v1/budget/settle') return respond(res, 200, await ledger.settle(input.payload));
    if (req.url === '/v1/budget/uncertain') return respond(res, 200, await ledger.markUncertain(input.payload.reservationId, input.payload.reason));
    if (req.url === '/v1/budget/summary') return respond(res, 200, await ledger.summary());
    if (req.url === '/v1/dispatch') {
      const { role, action, environment, mode, arguments: args, allowedPaths = [] } = input.payload;
      policy.authorize({ role, action, environment, mode });
      const result = await actions.execute(action, args || {}, { role, allowedPaths });
      return respond(res, 200, { status: 'PASS', result });
    }
    return respond(res, 404, { error: 'not_found' });
  } catch (error) { return respond(res, 400, { status: 'DENIED', error: error.message }); }
});

const port = Number(process.env.CEFFLO_ENGINEERING_RUNNER_PORT || 4317);
server.listen(port, process.env.CEFFLO_ENGINEERING_RUNNER_HOST || '127.0.0.1', () => process.stdout.write(`CEFFLO Engineering Runner listening on ${port}\n`));
