import { cp, mkdir, rm, writeFile } from 'node:fs/promises';

// The legacy purple Vendor, Rider and Customer web apps were removed from this
// branch. Every host serves only the retirement page and worker, which clear
// the caches and service workers those apps left on devices. The canonical
// products ship through the controlled release of claude/canonical-integration.
const output = new URL('../dist/', import.meta.url);
await rm(output, { recursive: true, force: true });
await mkdir(output, { recursive: true });
await cp(new URL('../retired/', import.meta.url), new URL('../dist/retired/', import.meta.url), { recursive: true });
await cp(new URL('../retired/index.html', import.meta.url), new URL('../dist/index.html', import.meta.url));
await mkdir(new URL('../dist/server/', import.meta.url), { recursive: true });
await mkdir(new URL('../dist/.openai/', import.meta.url), { recursive: true });
await writeFile(new URL('../dist/server/index.js', import.meta.url), "export default { fetch(request, env) { return env.ASSETS.fetch(request); } };\n");
await cp(new URL('../.openai/hosting.json', import.meta.url), new URL('../dist/.openai/hosting.json', import.meta.url));
