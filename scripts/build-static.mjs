import { cp, mkdir, rm, writeFile } from 'node:fs/promises';

const output = new URL('../dist/', import.meta.url);
await rm(output, { recursive: true, force: true });
await mkdir(output, { recursive: true });

for (const directory of ['vendor', 'rider', 'customer', 'shared']) {
  await cp(new URL(`../${directory}/`, import.meta.url), new URL(`../dist/${directory}/`, import.meta.url), { recursive: true });
}

await writeFile(new URL('../dist/index.html', import.meta.url), '<!doctype html><meta charset="utf-8"><meta http-equiv="refresh" content="0;url=./vendor/"><title>CEFFLO</title><a href="./vendor/">Open CEFFLO Vendor</a>\n');
