import { resolve } from 'node:path';
import { BudgetLedger } from '../runtime/lib/budget-ledger.mjs';

const [command, raw = '{}'] = process.argv.slice(2);
const input = JSON.parse(raw);
const ledger = new BudgetLedger({
  file: process.env.CEFFLO_ENGINEERING_LEDGER || resolve('artifacts/engineering/qualification/budget-ledger.json'),
  hardBudgetUsd: 3
});
await ledger.init();
let result;
if (command === 'reserve') result = await ledger.reserve(input);
else if (command === 'settle') result = await ledger.settle(input);
else if (command === 'uncertain') result = await ledger.markUncertain(input.reservationId, input.reason);
else if (command === 'summary') result = await ledger.summary();
else throw new Error('budget_command_invalid');
process.stdout.write(`${JSON.stringify(result)}\n`);
