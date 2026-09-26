import { mkdir, open, readFile, rename, writeFile } from 'node:fs/promises';
import { dirname } from 'node:path';
import { randomUUID } from 'node:crypto';

const toMicros = (usd) => Math.round(Number(usd) * 1_000_000);
const fromMicros = (micros) => micros / 1_000_000;

export class BudgetLedger {
  constructor({ file, hardBudgetUsd = 3, now = () => new Date().toISOString() }) {
    this.file = file;
    this.lockFile = `${file}.lock`;
    this.hardMicros = toMicros(hardBudgetUsd);
    this.now = now;
  }
  async init() {
    await mkdir(dirname(this.file), { recursive: true });
    try { await readFile(this.file); } catch { await this.#write({ version: 1, hardBudgetMicros: this.hardMicros, entries: [] }); }
  }
  async #read() { return JSON.parse(await readFile(this.file, 'utf8')); }
  async #write(data) {
    const temp = `${this.file}.${randomUUID()}.tmp`;
    await writeFile(temp, `${JSON.stringify(data, null, 2)}\n`, { mode: 0o600 });
    await rename(temp, this.file);
  }
  async #locked(callback) {
    let handle;
    try {
      handle = await open(this.lockFile, 'wx', 0o600);
      const state = await this.#read();
      const result = await callback(state);
      await this.#write(state);
      return result;
    } catch (error) {
      if (error.code === 'EEXIST') throw new Error('budget_ledger_busy');
      throw error;
    } finally {
      await handle?.close();
      if (handle) await import('node:fs/promises').then(({ unlink }) => unlink(this.lockFile).catch(() => {}));
    }
  }
  async reserve({ taskId, role, routeId, attempt, retry = 0, worstCaseUsd, kind = 'model' }) {
    if (!Number.isFinite(worstCaseUsd) || worstCaseUsd <= 0) throw new Error('unknown_or_invalid_cost');
    return this.#locked(async (state) => {
      const committed = state.entries.filter((e) => ['reserved', 'settled', 'uncertain'].includes(e.status)).reduce((sum, e) => sum + e.amountMicros, 0);
      const amountMicros = toMicros(worstCaseUsd);
      if (committed + amountMicros > state.hardBudgetMicros) throw new Error('budget_hard_stop');
      const entry = { id: randomUUID(), taskId, role, routeId, attempt, retry, kind, status: 'reserved', amountMicros, createdAt: this.now() };
      state.entries.push(entry);
      return this.#view(state, entry);
    });
  }
  async settle({ reservationId, actualUsd, usage, outcome }) {
    if (!Number.isFinite(actualUsd) || actualUsd < 0) throw new Error('actual_cost_unavailable');
    return this.#locked(async (state) => {
      const entry = state.entries.find((e) => e.id === reservationId);
      if (!entry || entry.status !== 'reserved') throw new Error('reservation_invalid');
      const actualMicros = toMicros(actualUsd);
      if (actualMicros > entry.amountMicros) throw new Error('reservation_exceeded');
      entry.amountMicros = actualMicros;
      entry.status = 'settled';
      entry.usage = usage;
      entry.outcome = outcome;
      entry.settledAt = this.now();
      return this.#view(state, entry);
    });
  }
  async markUncertain(reservationId, reason) {
    return this.#locked(async (state) => {
      const entry = state.entries.find((e) => e.id === reservationId);
      if (!entry || entry.status !== 'reserved') throw new Error('reservation_invalid');
      entry.status = 'uncertain';
      entry.reason = reason;
      return this.#view(state, entry);
    });
  }
  async summary() { const state = await this.#read(); return this.#view(state); }
  #view(state, entry = null) {
    const spent = state.entries.filter((e) => ['settled', 'uncertain'].includes(e.status)).reduce((sum, e) => sum + e.amountMicros, 0);
    const reserved = state.entries.filter((e) => e.status === 'reserved').reduce((sum, e) => sum + e.amountMicros, 0);
    return { hardBudgetUsd: fromMicros(state.hardBudgetMicros), spentUsd: fromMicros(spent), reservedUsd: fromMicros(reserved), remainingUsd: fromMicros(state.hardBudgetMicros - spent - reserved), entry };
  }
}
