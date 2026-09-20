const SENSITIVE_KEY = /(authorization|api[-_]?key|credential|password|secret|token|cookie|signature)/i;
const BEARER = /Bearer\s+[A-Za-z0-9._~+\/-]+/gi;
const KEY_LIKE = /\b(?:sk|ds)-[A-Za-z0-9_-]{12,}\b/g;

export function redact(value) {
  if (Array.isArray(value)) return value.map(redact);
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, SENSITIVE_KEY.test(key) ? '[REDACTED]' : redact(item)]));
  }
  if (typeof value === 'string') return value.replace(BEARER, 'Bearer [REDACTED]').replace(KEY_LIKE, '[REDACTED]');
  return value;
}
