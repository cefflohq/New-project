import { cp, mkdir, rm, writeFile } from 'node:fs/promises';

// The public root serves the Founder-approved CEFFLO homepage. Legacy Vendor,
// Rider and Customer hosts remain routed to the retirement page and worker so
// their old service workers and caches cannot return superseded product UI.
const output = new URL('../dist/', import.meta.url);
await rm(output, { recursive: true, force: true });
await mkdir(output, { recursive: true });
await cp(new URL('../retired/', import.meta.url), new URL('../dist/retired/', import.meta.url), { recursive: true });
await cp(new URL('../index.html', import.meta.url), new URL('../dist/index.html', import.meta.url));
for (const page of ['privacy.html', 'terms.html', 'robots.txt', 'sitemap.xml', 'favicon.ico']) await cp(new URL(`../${page}`, import.meta.url), new URL(`../dist/${page}`, import.meta.url));
for (const dir of ['img', 'fonts']) await cp(new URL(`../${dir}/`, import.meta.url), new URL(`../dist/${dir}/`, import.meta.url), { recursive: true });
await mkdir(new URL('../dist/server/', import.meta.url), { recursive: true });
await mkdir(new URL('../dist/.openai/', import.meta.url), { recursive: true });
await writeFile(new URL('../dist/server/index.js', import.meta.url), "export default { fetch(request, env) { return env.ASSETS.fetch(request); } };\n");
await cp(new URL('../.openai/hosting.json', import.meta.url), new URL('../dist/.openai/hosting.json', import.meta.url));
