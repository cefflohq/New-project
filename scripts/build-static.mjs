import { cp, mkdir, readdir, rm, stat, writeFile } from 'node:fs/promises';
import { resolveFrontendEnvironment, serializeRuntimeConfig } from './environment.mjs';
import { CANONICAL_SURFACES, FORBIDDEN_OUTPUT_DIRS } from './canonical-surfaces.mjs';

const environment = resolveFrontendEnvironment(process.env);

const output = new URL('../dist/', import.meta.url);
await rm(output, { recursive: true, force: true });
await mkdir(output, { recursive: true });

// Explicit canonical inputs only (D-62). Nothing outside this list is
// published, so a historical root UI left on some branch cannot ride along.
for (const directory of Object.keys(CANONICAL_SURFACES)) {
  await cp(new URL(`../${directory}/`, import.meta.url), new URL(`../dist/${directory}/`, import.meta.url), { recursive: true });
}

await writeFile(new URL('../dist/shared/config.js', import.meta.url), serializeRuntimeConfig(environment));

// Vendor Web/Desktop (apps/vendor_web) at /web/; vendor.cefflo.com redirects
// there. Same shared runtime config; its demo mode is off in Production.
await cp(new URL('../apps/vendor_web/', import.meta.url), new URL('../dist/web/', import.meta.url), { recursive: true });

// Root = the Founder-approved Public Website (www.cefflo.com / cefflo.com),
// brought in from main @ 15efffe so one branch serves the website and every
// product host (vercel.json routes the product hosts to their surfaces).
await cp(new URL('../website/index.html', import.meta.url), new URL('../dist/index.html', import.meta.url));
for (const page of ['privacy.html', 'terms.html', 'robots.txt', 'sitemap.xml']) await cp(new URL(`../website/${page}`, import.meta.url), new URL(`../dist/${page}`, import.meta.url));
await cp(new URL('../website/img/', import.meta.url), new URL('../dist/img/', import.meta.url), { recursive: true });
await cp(new URL('../website/fonts/', import.meta.url), new URL('../dist/fonts/', import.meta.url), { recursive: true });
await mkdir(new URL('../dist/server/', import.meta.url), { recursive: true });
await mkdir(new URL('../dist/.openai/', import.meta.url), { recursive: true });
await writeFile(new URL('../dist/server/index.js', import.meta.url), "export default { fetch(request, env) { return env.ASSETS.fetch(request); } };\n");
await cp(new URL('../.openai/hosting.json', import.meta.url), new URL('../dist/.openai/hosting.json', import.meta.url));

// Guard the published output itself.
const published = await readdir(output);
for (const name of FORBIDDEN_OUTPUT_DIRS) {
  if (published.includes(name)) throw new Error(`Obsolete UI "${name}" must never be published`);
}
const allowed = new Set([...Object.keys(CANONICAL_SURFACES), 'web', 'img', 'fonts', 'index.html', 'privacy.html', 'terms.html', 'robots.txt', 'sitemap.xml', 'server', '.openai']);
for (const name of published) {
  if (!allowed.has(name)) throw new Error(`Unexpected published entry "${name}" -- not a canonical surface`);
}
if (!(await stat(new URL('../dist/web/js/app.js', import.meta.url)).catch(() => null))) {
  throw new Error('New Vendor Web App (web/js/app.js) is missing');
}
if (!(await stat(new URL('../dist/customer/app.js', import.meta.url)).catch(() => null))) {
  throw new Error('Canonical Customer Tracking (customer/app.js) is missing');
}

console.log(`Built CEFFLO for ${environment.name} (${environment.projectRef}): ${Object.keys(CANONICAL_SURFACES).join(', ')}`);
