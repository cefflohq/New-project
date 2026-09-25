import { cp, mkdir, readdir, readFile, rm, stat, writeFile } from 'node:fs/promises';
import { resolveFrontendEnvironment, serializeRuntimeConfig } from './environment.mjs';
import { CANONICAL_SURFACES, FORBIDDEN_OUTPUT_DIRS, OBSOLETE_VENDOR_WELCOME_MARKERS } from './canonical-surfaces.mjs';

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

// Root fallback for a hostname vercel.json does not route (or a direct hit on
// the deployment URL). There is no Public Website product (NOT IMPLEMENTED),
// so this is a neutral notice -- never a product UI and never the old site.
await writeFile(new URL('../dist/index.html', import.meta.url), '<!doctype html><meta charset="utf-8"><meta name="robots" content="noindex"><title>CEFFLO</title><p>No CEFFLO product is served at this address.</p>\n');
await mkdir(new URL('../dist/server/', import.meta.url), { recursive: true });
await mkdir(new URL('../dist/.openai/', import.meta.url), { recursive: true });
await writeFile(new URL('../dist/server/index.js', import.meta.url), "export default { fetch(request, env) { return env.ASSETS.fetch(request); } };\n");
await cp(new URL('../.openai/hosting.json', import.meta.url), new URL('../dist/.openai/hosting.json', import.meta.url));

// Guard the published output itself.
const published = await readdir(output);
for (const name of FORBIDDEN_OUTPUT_DIRS) {
  if (published.includes(name)) throw new Error(`Obsolete UI "${name}" must never be published`);
}
const allowed = new Set([...Object.keys(CANONICAL_SURFACES), 'index.html', 'server', '.openai']);
for (const name of published) {
  if (!allowed.has(name)) throw new Error(`Unexpected published entry "${name}" -- not a canonical surface`);
}
const vendorHtml = await readFile(new URL('../dist/vendor/index.html', import.meta.url), 'utf8');
for (const marker of OBSOLETE_VENDOR_WELCOME_MARKERS) {
  if (vendorHtml.includes(marker)) throw new Error(`Obsolete Vendor welcome presentation returned: ${marker}`);
}
if (!(await stat(new URL('../dist/customer/app.js', import.meta.url)).catch(() => null))) {
  throw new Error('Canonical Customer Tracking (customer/app.js) is missing');
}

console.log(`Built CEFFLO for ${environment.name} (${environment.projectRef}): ${Object.keys(CANONICAL_SURFACES).join(', ')}`);
