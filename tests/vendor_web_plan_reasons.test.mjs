// Vendor Web: every planner reason and driver exclusion returned by
// propose_delivery_plan has an English and a Malay label (migrations
// 20261012120000, 20261012130000).
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const src = readFileSync(new URL('../apps/vendor_web/js/i18n.js', import.meta.url), 'utf8');
const msStart = src.indexOf("'plan.title': 'Rancang Penghantaran'");
const en = src.slice(0, msStart), ms = src.slice(msStart);
const label = (part, key) => part.match(new RegExp(`'${key.replace(/\./g, '\\.')}': '([^']*)'`))?.[1];

const reasons = ['location_unresolved', 'location_ambiguous', 'location_failed', 'in_preparation', 'sorted_before_run',
  'in_locked_run', 'insufficient_capacity', 'vehicle_incompatible', 'declined_awaiting_recovery'];
const exclusions = ['rider_has_open_run', 'no_capacity', 'not_eligible'];

test('every planner reason has distinct English and Malay labels', () => {
  for (const r of reasons) {
    const e = label(en, `plan.why.${r}`), m = label(ms, `plan.why.${r}`);
    assert.ok(e, `en plan.why.${r}`);
    assert.ok(m, `ms plan.why.${r}`);
    assert.notEqual(e, m, r);
  }
});

test('in_preparation no longer claims sorted orders', () => {
  assert.equal(label(en, 'plan.why.in_preparation'), 'Being prepared');
  assert.equal(label(ms, 'plan.why.in_preparation'), 'Sedang disediakan');
});

test('every driver exclusion has English and Malay labels naming the driver', () => {
  for (const r of exclusions) {
    assert.match(label(en, `plan.ex.${r}`) || '', /\{name\}/, `en ${r}`);
    assert.match(label(ms, `plan.ex.${r}`) || '', /\{name\}/, `ms ${r}`);
  }
});
