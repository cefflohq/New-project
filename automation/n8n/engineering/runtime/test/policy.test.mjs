import test from 'node:test';
import assert from 'node:assert/strict';
import { PolicyEngine } from '../lib/policy.mjs';

const commandPolicy = { actions: {
  'repo.read': { enabled: true, roles: ['E1', 'E2', 'E3', 'E4'] },
  'source.patch': { enabled: true, roles: ['E2'] },
  'tree.verify': { enabled: true, roles: ['E4', 'E5'] }
} };
const roles = { environmentAllowlist: ['local', 'development', 'staging'], roles: {
  E1: { actions: ['repo.read'], denied: ['source.write', 'production.*'] },
  E2: { actions: ['repo.read', 'source.patch'], denied: ['git.commit', 'production.*'] },
  E4: { actions: ['repo.read', 'tree.verify'], denied: ['source.patch', 'production.*'] },
  E5: { actions: ['tree.verify'], denied: ['source.patch', 'production.*'] }
} };
const controls = { engineeringEnabled: true, qualificationEnabled: true, pilotEnabled: false, roles: { E1: true, E2: true, E4: true, E5: true } };

test('qualification reads allowed while pilot remains gated', () => {
  const p = new PolicyEngine({ commandPolicy, roles, controls });
  assert.doesNotThrow(() => p.authorize({ role: 'E1', action: 'repo.read', environment: 'development', mode: 'qualification' }));
  assert.throws(() => p.authorize({ role: 'E1', action: 'repo.read', environment: 'development', mode: 'pilot' }), /pilot_gate_closed/);
});

test('role boundary and production environment are denied', () => {
  const p = new PolicyEngine({ commandPolicy, roles, controls });
  assert.throws(() => p.authorize({ role: 'E1', action: 'source.patch', environment: 'development', mode: 'qualification' }), /action_denied/);
  assert.throws(() => p.authorize({ role: 'E2', action: 'source.patch', environment: 'production', mode: 'qualification' }), /environment_denied/);
  assert.throws(() => p.authorize({ role: 'E4', action: 'source.patch', environment: 'development', mode: 'qualification' }), /action_denied/);
});

test('kill switches override role permission', () => {
  const p = new PolicyEngine({ commandPolicy, roles, controls: { ...controls, engineeringEnabled: false } });
  assert.throws(() => p.authorize({ role: 'E1', action: 'repo.read', environment: 'development', mode: 'qualification' }), /engineering_killed/);
});
