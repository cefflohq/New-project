import { createHmac, timingSafeEqual } from 'node:crypto';
import { canonicalize } from './canonical.mjs';

export class ReplayStore {
  constructor({ maxAgeMs = 300_000, now = () => Date.now() } = {}) {
    this.maxAgeMs = maxAgeMs;
    this.now = now;
    this.nonces = new Map();
  }
  consume(nonce, timestamp) {
    const current = this.now();
    const issued = Date.parse(timestamp);
    if (!nonce || !Number.isFinite(issued) || Math.abs(current - issued) > this.maxAgeMs) throw new Error('request_expired');
    for (const [key, expiry] of this.nonces) if (expiry <= current) this.nonces.delete(key);
    if (this.nonces.has(nonce)) throw new Error('replay_detected');
    this.nonces.set(nonce, current + this.maxAgeMs);
  }
}

export function signEnvelope(envelope, secret) {
  const unsigned = structuredClone(envelope);
  delete unsigned.signature;
  return createHmac('sha256', secret).update(canonicalize(unsigned)).digest('hex');
}

export function verifyEnvelope(envelope, secret, replayStore) {
  if (!secret) throw new Error('runner_secret_missing');
  const supplied = Buffer.from(envelope.signature || '', 'hex');
  const expected = Buffer.from(signEnvelope(envelope, secret), 'hex');
  if (supplied.length !== expected.length || !timingSafeEqual(supplied, expected)) throw new Error('invalid_signature');
  replayStore.consume(envelope.nonce, envelope.timestamp);
  return true;
}
