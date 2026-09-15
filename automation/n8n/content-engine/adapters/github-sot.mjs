import childProcess from 'node:child_process';

function git(repo, args) {
  return childProcess.execFileSync('git', args, { cwd: repo, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trimEnd();
}

export function resolveCanonicalSot(repo, manifest, ref = 'HEAD') {
  const sourceRevision = git(repo, ['rev-parse', '--verify', `${ref}^{commit}`]).trim();
  return manifest.map((entry) => {
    if (!entry.source || entry.source.startsWith('/') || entry.source.includes('..')) {
      throw new Error(`ERROR_SOT: invalid canonical path: ${entry.source || '<missing>'}`);
    }
    try {
      const content = git(repo, ['show', `${sourceRevision}:${entry.source}`]);
      if (!content) throw new Error('empty canonical document');
      return { ...entry, content, source_revision: sourceRevision };
    } catch (error) {
      throw new Error(`ERROR_SOT: canonical source could not be resolved: ${entry.source}`, { cause: error });
    }
  });
}
