import { realpath, stat } from 'node:fs/promises';
import { resolve, relative, isAbsolute } from 'node:path';

export async function resolveInside(root, requested = '.') {
  const canonicalRoot = await realpath(root);
  const candidate = resolve(canonicalRoot, requested);
  const rel = relative(canonicalRoot, candidate);
  if (rel.startsWith('..') || isAbsolute(rel)) throw new Error('path_escape');
  const canonicalCandidate = await realpath(candidate);
  const canonicalRel = relative(canonicalRoot, canonicalCandidate);
  if (canonicalRel.startsWith('..') || isAbsolute(canonicalRel)) throw new Error('symlink_escape');
  await stat(canonicalCandidate);
  return canonicalCandidate;
}

export function assertAllowedPath(relativePath, allowedPaths = []) {
  if (!allowedPaths.length) throw new Error('no_allowed_paths');
  const normalized = relativePath.replaceAll('\\', '/').replace(/^\.\//, '');
  if (!allowedPaths.some((prefix) => normalized === prefix || normalized.startsWith(`${prefix.replace(/\/$/, '')}/`))) {
    throw new Error('path_not_allowed');
  }
}
