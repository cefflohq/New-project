import test from 'node:test';
import assert from 'node:assert/strict';
import { ReplayStore, signEnvelope, verifyEnvelope } from '../lib/auth.mjs';

test('signed envelope verifies once and replay fails', () => {
  const now = Date.parse('2026-09-20T10:00:00Z');
  const replay = new ReplayStore({ now: () => now });
  const envelope = { request_id: 'r1', nonce: 'n1', timestamp: new Date(now).toISOString(), payload: { role: 'E1' } };
  envelope.signature = signEnvelope(envelope, 'test-secret');
  assert.equal(verifyEnvelope(envelope, 'test-secret', replay), true);
  assert.throws(() => verifyEnvelope(envelope, 'test-secret', replay), /replay_detected/);
});

test('tampering and expired requests fail', () => {
  const now = Date.parse('2026-09-20T10:00:00Z');
  const replay = new ReplayStore({ now: () => now });
  const envelope = { nonce: 'n2', timestamp: new Date(now).toISOString(), payload: { role: 'E1' } };
  envelope.signature = signEnvelope(envelope, 'test-secret');
  envelope.payload.role = 'E2';
  assert.throws(() => verifyEnvelope(envelope, 'test-secret', replay), /invalid_signature/);
  const expired = { nonce: 'n3', timestamp: new Date(now - 600_000).toISOString(), payload: {} };
  expired.signature = signEnvelope(expired, 'test-secret');
  assert.throws(() => verifyEnvelope(expired, 'test-secret', replay), /request_expired/);
});
