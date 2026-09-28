import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, writeFile, symlink } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { redact } from '../lib/redaction.mjs';
import { resolveInside } from '../lib/path-policy.mjs';

test('credential-like content is redacted recursively', () => {
  assert.deepEqual(redact({ authorization: 'Bearer secret', nested: { value: 'Bearer abc.def', api_key: 'sk-abcdefghijklmnop' } }), { authorization: '[REDACTED]', nested: { value: 'Bearer [REDACTED]', api_key: '[REDACTED]' } });
});

test('path and symlink escapes fail', async () => {
  const root = await mkdtemp(join(tmpdir(), 'cefflo-path-'));
  await mkdir(join(root, 'safe')); await writeFile(join(root, 'safe', 'x'), 'x');
  await assert.rejects(resolveInside(root, '../outside'), /path_escape/);
  await symlink('/tmp', join(root, 'escape'));
  await assert.rejects(resolveInside(root, 'escape'), /symlink_escape/);
  assert.equal(await resolveInside(root, 'safe/x'), join(root, 'safe', 'x'));
});
