import { timingSafeEqual } from 'node:crypto';

function equalString(a, b) {
  const left = Buffer.from(a || '');
  const right = Buffer.from(b || '');
  return left.length === right.length && timingSafeEqual(left, right);
}

export function enforceE4Independence(verdict) {
  if (verdict.independent_execution !== true || verdict.source_write_permitted !== false) throw new Error('e4_independence_failed');
  if (!['PASS', 'FAIL', 'BLOCKED'].includes(verdict.verdict)) throw new Error('e4_verdict_invalid');
}

export function enforceExactTree({ currentTreeHash, verdict, evidenceManifestHash, expectedTaskPackHash }) {
  enforceE4Independence(verdict);
  if (verdict.verdict !== 'PASS') throw new Error('e4_not_pass');
  if (!equalString(currentTreeHash, verdict.tree_hash)) throw new Error('tree_changed_after_verification');
  if (!equalString(evidenceManifestHash, verdict.evidence_manifest_hash)) throw new Error('evidence_manifest_mismatch');
  if (!equalString(expectedTaskPackHash, verdict.task_pack_hash)) throw new Error('task_pack_mismatch');
  return true;
}
