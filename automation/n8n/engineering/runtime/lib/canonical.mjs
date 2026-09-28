import { createHash } from 'node:crypto';

export function canonicalize(value) {
  if (Array.isArray(value)) return `[${value.map(canonicalize).join(',')}]`;
  if (value && typeof value === 'object') {
    return `{${Object.keys(value).sort().map((key) => `${JSON.stringify(key)}:${canonicalize(value[key])}`).join(',')}}`;
  }
  return JSON.stringify(value);
}

export function sha256(value) {
  const bytes = Buffer.isBuffer(value) ? value : Buffer.from(typeof value === 'string' ? value : canonicalize(value));
  return createHash('sha256').update(bytes).digest('hex');
}

export function withoutKey(value, key) {
  const copy = structuredClone(value);
  delete copy[key];
  return copy;
}
