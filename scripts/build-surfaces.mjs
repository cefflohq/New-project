// Package the production domain map: one root-served artifact per product
// host in dist-surfaces/<surface>/ (see scripts/production-surfaces.mjs).
//
//   npm run build                       # dist/ (unchanged; staging uses it)
//   CEFFLO_VENDOR_APP_WEB_DIR=... CEFFLO_DRIVER_APP_WEB_DIR=... \
//     node scripts/build-surfaces.mjs   # dist-surfaces/
//
// Static surfaces are lifted out of dist/ to the artifact root, with the
// shared runtime (/shared/) beside them, so https://<host>/ is the surface
// itself -- never the marketing index. Flutter surfaces are copied from their
// own web builds (Operator and Helper reuse the one Vendor app build; the
// entry host selects the entry, the server decides the role).
import { cp, mkdir, rm, stat, readFile, writeFile } from 'node:fs/promises';
import { PRODUCTION_SURFACES } from './production-surfaces.mjs';

const root = new URL('../', import.meta.url);
const dist = new URL('dist/', root);
const out = new URL('dist-surfaces/', root);
const flutterDirs = {
  vendor: process.env.CEFFLO_VENDOR_APP_WEB_DIR || '',
  driver: process.env.CEFFLO_DRIVER_APP_WEB_DIR || '',
};
const only = (process.env.CEFFLO_SURFACES || '').split(',').map(s => s.trim()).filter(Boolean);

const exists = async p => !!(await stat(p).catch(() => null));
if (!(await exists(new URL('shared/config.js', dist)))) throw new Error('Run `npm run build` first (dist/shared/config.js missing)');

await rm(out, { recursive: true, force: true });
await mkdir(out, { recursive: true });
const built = [];
for (const [name, s] of Object.entries(PRODUCTION_SURFACES)) {
  if (only.length && !only.includes(name)) continue;
  const target = new URL(`${name}/`, out);
  if (s.kind === 'static') {
    await cp(new URL(`${s.from}/`, dist), target, { recursive: true });
    await cp(new URL('shared/', dist), new URL('shared/', target), { recursive: true });
    if (name === 'order') {
      // The storefront page references /store/* absolutely: keep its assets
      // there and serve its page at the root (/{slug} falls back to it).
      await rm(target, { recursive: true, force: true });
      await mkdir(target, { recursive: true });
      await cp(new URL('store/', dist), new URL('store/', target), { recursive: true });
      await cp(new URL('store/index.html', dist), new URL('index.html', target));
      await cp(new URL('shared/', dist), new URL('shared/', target), { recursive: true });
    }
  } else {
    const dir = flutterDirs[s.app];
    if (!dir) { console.warn(`skip ${name}: set CEFFLO_${s.app.toUpperCase()}_APP_WEB_DIR to the Flutter web build`); continue; }
    if (!(await exists(new URL(`file://${dir.replace(/\/?$/, '/')}index.html`)))) throw new Error(`${dir} is not a Flutter web build (no index.html)`);
    await cp(dir, target, { recursive: true });
  }
  if (!(await exists(new URL('index.html', target)))) throw new Error(`${name}: no index.html at the artifact root`);
  built.push(`${name} -> https://${s.domain}/`);
}
await writeFile(new URL('MANIFEST.txt', out), built.join('\n') + '\n');
const env = (await readFile(new URL('shared/config.js', dist), 'utf8')).match(/"environment":\s*"([^"]+)"/)?.[1];
console.log(`Packaged ${built.length} production surfaces (runtime config: ${env}):\n  ${built.join('\n  ')}`);
