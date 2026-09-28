import { execFileSync } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

const repo = resolve(import.meta.dirname, '../../../..');
const output = resolve(
  repo,
  'docs/cefflo/engineering/baseline/branch-inventory.json',
);

const refs = {
  current: 'claude/flow-3-vendor-web-desktop-completion',
  experience: 'claude/experience-system-implementation',
};

function git(args) {
  return execFileSync('git', args, {
    cwd: repo,
    encoding: 'utf8',
    maxBuffer: 32 * 1024 * 1024,
  }).trim();
}

function lines(value) {
  return value ? value.split('\n').filter(Boolean) : [];
}

function commitInventory(base, ref) {
  const records = lines(
    git([
      'log',
      '--reverse',
      '--format=%H%x1f%P%x1f%aI%x1f%an%x1f%s',
      `${base}..${ref}`,
    ]),
  );

  return records.map((record) => {
    const [sha, parents, authoredAt, author, subject] = record.split('\x1f');
    return {
      sha,
      parents: parents ? parents.split(' ') : [],
      authoredAt,
      author,
      subject,
      files: lines(
        git(['diff-tree', '--no-commit-id', '--name-only', '-r', sha]),
      ),
    };
  });
}

function changedFiles(base, ref) {
  return lines(git(['diff', '--name-status', `${base}..${ref}`])).map(
    (line) => {
      const [status, ...paths] = line.split('\t');
      return { status, paths };
    },
  );
}

function shortStat(base, ref) {
  return git(['diff', '--shortstat', `${base}..${ref}`]);
}

const tips = {
  current: git(['rev-parse', refs.current]),
  experience: git(['rev-parse', refs.experience]),
};
const mergeBase = git(['merge-base', refs.current, refs.experience]);
const currentCommits = commitInventory(mergeBase, refs.current);
const experienceCommits = commitInventory(mergeBase, refs.experience);
const currentFiles = changedFiles(mergeBase, refs.current);
const experienceFiles = changedFiles(mergeBase, refs.experience);
const currentPaths = new Set(currentFiles.flatMap((entry) => entry.paths));
const experiencePaths = new Set(
  experienceFiles.flatMap((entry) => entry.paths),
);

const inventory = {
  schemaVersion: 1,
  evidenceDate: '2026-09-19',
  mode: 'read_only_branch_reconciliation',
  refs,
  tips,
  mergeBase,
  topology: {
    currentUniqueCommitCount: currentCommits.length,
    experienceUniqueCommitCount: experienceCommits.length,
    currentShortStat: shortStat(mergeBase, refs.current),
    experienceShortStat: shortStat(mergeBase, refs.experience),
  },
  pathOverlap: [...currentPaths]
    .filter((path) => experiencePaths.has(path))
    .sort(),
  branches: {
    current: {
      ref: refs.current,
      tip: tips.current,
      tree: git(['rev-parse', `${refs.current}^{tree}`]),
      uniqueCommits: currentCommits,
      changedFiles: currentFiles,
    },
    experience: {
      ref: refs.experience,
      tip: tips.experience,
      tree: git(['rev-parse', `${refs.experience}^{tree}`]),
      uniqueCommits: experienceCommits,
      changedFiles: experienceFiles,
    },
  },
};

mkdirSync(dirname(output), { recursive: true });
writeFileSync(output, `${JSON.stringify(inventory, null, 2)}\n`, {
  encoding: 'utf8',
  mode: 0o644,
});

process.stdout.write(`${output}\n`);
