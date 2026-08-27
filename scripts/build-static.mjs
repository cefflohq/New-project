import { cp, mkdir, rm, writeFile } from 'node:fs/promises';
import { resolveFrontendEnvironment, serializeRuntimeConfig } from './environment.mjs';

const environment = resolveFrontendEnvironment(process.env);

const output = new URL('../dist/', import.meta.url);
await rm(output, { recursive: true, force: true });
await mkdir(output, { recursive: true });

for (const directory of ['vendor', 'rider', 'customer', 'shared']) {
  await cp(new URL(`../${directory}/`, import.meta.url), new URL(`../dist/${directory}/`, import.meta.url), { recursive: true });
}

await writeFile(new URL('../dist/shared/config.js', import.meta.url), serializeRuntimeConfig(environment));

await writeFile(new URL('../dist/index.html', import.meta.url), '<!doctype html><meta charset="utf-8"><meta http-equiv="refresh" content="0;url=./vendor/"><title>CEFFLO</title><a href="./vendor/">Open CEFFLO Vendor</a>\n');
await mkdir(new URL('../dist/server/', import.meta.url), { recursive: true });
await mkdir(new URL('../dist/.openai/', import.meta.url), { recursive: true });
await writeFile(new URL('../dist/server/index.js', import.meta.url), "export default { fetch(request, env) { return env.ASSETS.fetch(request); } };\n");
await cp(new URL('../.openai/hosting.json', import.meta.url), new URL('../dist/.openai/hosting.json', import.meta.url));
console.log(`Built CEFFLO for ${environment.name} (${environment.projectRef})`);
