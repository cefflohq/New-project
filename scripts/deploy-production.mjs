// Production deploy of the product hosts (Founder domain map 2026-10-05).
// PREPARED, NOT RUN. Refuses unless ALL of:
//   * dist-surfaces/ exists and its runtime config is a production build
//     (environment "production", the approved Production project ref);
//   * the Flutter surfaces (operator, helper, driver) are packaged;
//   * --founder-approved is passed explicitly.
// Each surface deploys as a Cloudflare Worker with static assets
// (deploy/cloudflare/<surface>.jsonc); attaching the custom domain creates
// its DNS record, so this IS a production + DNS change.
import { readFile, stat } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import { PRODUCTION_SURFACES } from './production-surfaces.mjs';
import { PRODUCTION_PROJECT_REF } from './environment.mjs';

if (!process.argv.includes('--founder-approved')) {
  console.error('Refusing: production deploy needs explicit Founder approval (--founder-approved).');
  process.exit(2);
}
const root = new URL('../', import.meta.url);
for (const name of Object.keys(PRODUCTION_SURFACES)) {
  const dir = new URL(`dist-surfaces/${name}/index.html`, root);
  if (!(await stat(dir).catch(() => null))) { console.error(`Refusing: dist-surfaces/${name} is not packaged.`); process.exit(2); }
}
for (const name of ['vendor', 'invite', 'tracking', 'order', 'foundr']) {
  const cfg = await readFile(new URL(`dist-surfaces/${name}/shared/config.js`, root), 'utf8');
  if (!/"environment":\s*"production"/.test(cfg) || !cfg.includes(`"supabaseProjectRef": "${PRODUCTION_PROJECT_REF}"`)) {
    console.error(`Refusing: dist-surfaces/${name} is not a production build.`); process.exit(2);
  }
}
for (const name of Object.keys(PRODUCTION_SURFACES)) {
  console.log(`deploying ${name} -> https://${PRODUCTION_SURFACES[name].domain}/`);
  execFileSync('npx', ['wrangler', 'deploy', '-c', `deploy/cloudflare/${name}.jsonc`], { cwd: root, stdio: 'inherit' });
}
