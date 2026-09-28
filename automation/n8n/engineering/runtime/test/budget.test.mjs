import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { BudgetLedger } from '../lib/budget-ledger.mjs';

test('cumulative reservations, retries and fallbacks share one hard ceiling', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'cefflo-budget-'));
  const ledger = new BudgetLedger({ file: join(dir, 'ledger.json'), hardBudgetUsd: 3 });
  await ledger.init();
  const first = await ledger.reserve({ taskId: 'T', role: 'E1', routeId: 'openai', attempt: 1, worstCaseUsd: 1 });
  await ledger.settle({ reservationId: first.entry.id, actualUsd: 0.4, usage: { input_tokens: 10, output_tokens: 2 }, outcome: 'PASS' });
  await ledger.reserve({ taskId: 'T', role: 'E3', routeId: 'deepseek', attempt: 1, retry: 1, worstCaseUsd: 2.5 });
  await assert.rejects(ledger.reserve({ taskId: 'T', role: 'E4', routeId: 'openai', attempt: 1, worstCaseUsd: 0.11 }), /budget_hard_stop/);
  const summary = await ledger.summary();
  assert.equal(summary.spentUsd, 0.4);
  assert.equal(summary.reservedUsd, 2.5);
  assert.equal(summary.remainingUsd, 0.1);
});

test('unknown cost and uncertain failed call fail closed', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'cefflo-budget-'));
  const ledger = new BudgetLedger({ file: join(dir, 'ledger.json'), hardBudgetUsd: 3 });
  await ledger.init();
  await assert.rejects(ledger.reserve({ taskId: 'T', role: 'E1', routeId: 'x', attempt: 1, worstCaseUsd: null }), /unknown_or_invalid_cost/);
  const reservation = await ledger.reserve({ taskId: 'T', role: 'E1', routeId: 'x', attempt: 1, worstCaseUsd: 1 });
  await ledger.markUncertain(reservation.entry.id, 'transport outcome unknown');
  assert.equal((await ledger.summary()).remainingUsd, 2);
});
