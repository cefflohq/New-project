import test from 'node:test';
import assert from 'node:assert/strict';
import { enforceTwoImageVisualRequest } from '../lib/visual-guard.mjs';
import { enforceExactTree } from '../lib/exact-tree.mjs';

const hashA = 'a'.repeat(64); const hashB = 'b'.repeat(64);
test('E3/E4 require two distinct images in the same request', () => {
  assert.equal(enforceTwoImageVisualRequest({ role: 'E3', reference: { artifact_id: 'ref', sha256: hashA, mime_type: 'image/jpeg' }, render: { artifact_id: 'render', sha256: hashB, mime_type: 'image/png' }, comparisonPath: 'genuine_multimodal_same_request' }), true);
  assert.throws(() => enforceTwoImageVisualRequest({ role: 'E3', reference: { artifact_id: 'ref', sha256: hashA, mime_type: 'image/jpeg' }, render: null, comparisonPath: 'genuine_multimodal_same_request' }), /visual_image_missing/);
  assert.throws(() => enforceTwoImageVisualRequest({ role: 'E3', reference: { artifact_id: 'ref', sha256: hashA, mime_type: 'image/jpeg' }, render: { artifact_id: 'ref', sha256: hashA, mime_type: 'image/jpeg' }, comparisonPath: 'genuine_multimodal_same_request' }), /visual_images_not_distinct/);
});

test('E5 rejects changed tree or non-independent E4', () => {
  const verdict = { independent_execution: true, source_write_permitted: false, verdict: 'PASS', tree_hash: 'c'.repeat(40), evidence_manifest_hash: hashA, task_pack_hash: hashB };
  assert.equal(enforceExactTree({ currentTreeHash: 'c'.repeat(40), verdict, evidenceManifestHash: hashA, expectedTaskPackHash: hashB }), true);
  assert.throws(() => enforceExactTree({ currentTreeHash: 'd'.repeat(40), verdict, evidenceManifestHash: hashA, expectedTaskPackHash: hashB }), /tree_changed/);
  assert.throws(() => enforceExactTree({ currentTreeHash: 'c'.repeat(40), verdict: { ...verdict, source_write_permitted: true }, evidenceManifestHash: hashA, expectedTaskPackHash: hashB }), /e4_independence_failed/);
});
