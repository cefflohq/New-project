import { mkdir, readFile, unlink, writeFile } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import { dirname, relative } from 'node:path';
import { randomUUID } from 'node:crypto';
import { resolveInside, assertAllowedPath } from './path-policy.mjs';
import { enforceExactTree } from './exact-tree.mjs';
import { enforceTwoImageVisualRequest } from './visual-guard.mjs';

const fixedCommands = {
  'build.run': { executable: 'flutter', args: ['build', 'web', '--no-wasm-dry-run', '--dart-define=CEFFLO_UI_PROTOTYPE=true'], cwd: 'apps/vendor_mobile', timeoutMs: 180_000 },
  'test.run': { executable: 'flutter', args: ['test'], cwd: 'apps/vendor_mobile', timeoutMs: 180_000 },
  'build.verify': { executable: 'flutter', args: ['build', 'web', '--no-wasm-dry-run', '--dart-define=CEFFLO_UI_PROTOTYPE=true'], cwd: 'apps/vendor_mobile', timeoutMs: 180_000 },
  'test.verify': { executable: 'flutter', args: ['test'], cwd: 'apps/vendor_mobile', timeoutMs: 180_000 }
};

function runFixed(command, root, outputLimit = 100_000) {
  return new Promise(async (resolve, reject) => {
    const cwd = await resolveInside(root, command.cwd);
    const child = spawn(command.executable, command.args, { cwd, shell: false, env: { PATH: process.env.PATH, LANG: 'C.UTF-8' } });
    let output = '';
    const append = (chunk) => { if (output.length < outputLimit) output += chunk.toString().slice(0, outputLimit - output.length); };
    child.stdout.on('data', append); child.stderr.on('data', append);
    const timer = setTimeout(() => child.kill('SIGKILL'), command.timeoutMs);
    child.once('error', reject);
    child.once('close', (code, signal) => { clearTimeout(timer); resolve({ code, signal, output, command: [command.executable, ...command.args] }); });
  });
}

function patchPaths(patch) {
  if (typeof patch !== 'string' || patch.length === 0 || patch.length > 250_000) throw new Error('patch_invalid');
  if (patch.includes('\0') || /(^|\n)(GIT binary patch|Binary files )/.test(patch)) throw new Error('binary_patch_denied');
  const paths = [];
  for (const line of patch.split('\n')) {
    const match = line.match(/^\+\+\+ b\/(.+)$/);
    if (match && match[1] !== '/dev/null') paths.push(match[1]);
  }
  if (paths.length === 0) throw new Error('patch_has_no_paths');
  return [...new Set(paths)];
}

async function applyPatch(patch, root, allowedPaths) {
  for (const path of patchPaths(patch)) assertAllowedPath(path, allowedPaths);
  const patchFile = `/tmp/cefflo-engineering-${randomUUID()}.patch`;
  await writeFile(patchFile, patch, { mode: 0o600 });
  try {
    const check = await runFixed({ executable: 'git', args: ['apply', '--check', '--whitespace=error-all', patchFile], cwd: '.', timeoutMs: 15_000 }, root);
    if (check.code !== 0) return { applied: false, stage: 'check', ...check };
    const result = await runFixed({ executable: 'git', args: ['apply', '--whitespace=error-all', patchFile], cwd: '.', timeoutMs: 15_000 }, root);
    return { applied: result.code === 0, stage: 'apply', ...result };
  } finally {
    await unlink(patchFile).catch(() => {});
  }
}

async function captureRender(args, root) {
  const url = new URL(args.url);
  if (!['127.0.0.1', 'localhost'].includes(url.hostname) || !['http:', 'https:'].includes(url.protocol)) throw new Error('render_url_denied');
  const width = Number(args.width); const height = Number(args.height);
  if (!Number.isInteger(width) || !Number.isInteger(height) || width < 320 || width > 1600 || height < 480 || height > 2400) throw new Error('render_viewport_invalid');
  assertAllowedPath(args.outputPath, ['artifacts/engineering/']);
  const output = await resolveInside(root, args.outputPath);
  await mkdir(dirname(output), { recursive: true });
  return runFixed({
    executable: 'google-chrome',
    args: ['--headless=new', '--disable-gpu', '--hide-scrollbars', '--no-first-run', '--no-default-browser-check', `--window-size=${width},${height}`, `--screenshot=${output}`, url.toString()],
    cwd: '.', timeoutMs: 30_000
  }, root);
}

export class ActionRegistry {
  constructor({ root }) { this.root = root; }
  async execute(action, args, context) {
    if (action === 'repo.read') {
      assertAllowedPath(args.path, context.allowedPaths);
      const path = await resolveInside(this.root, args.path);
      return { path: relative(this.root, path), content: (await readFile(path, 'utf8')).slice(0, 100_000) };
    }
    if (action === 'repo.search') {
      if (!args.pattern || args.pattern.length > 200) throw new Error('search_pattern_invalid');
      const command = { executable: 'rg', args: ['--line-number', '--fixed-strings', '--', args.pattern, ...context.allowedPaths], cwd: '.', timeoutMs: 15_000 };
      return runFixed(command, this.root);
    }
    if (fixedCommands[action]) return runFixed(fixedCommands[action], this.root);
    if (action === 'visual.compare' || action === 'visual.verify') return { accepted: enforceTwoImageVisualRequest({ role: context.role, ...args }) };
    if (action === 'tree.verify') return { accepted: enforceExactTree(args) };
    if (['source.patch', 'source.patch_ui'].includes(action)) return applyPatch(args.patch, this.root, context.allowedPaths);
    if (['render.capture', 'render.verify'].includes(action)) return captureRender(args, this.root);
    throw new Error('action_not_implemented');
  }
}
