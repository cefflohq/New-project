// Production domain map (Founder 2026-10-05): builds dist/ + dist-surfaces/
// with the canonical production URLs (test identity, never Production) and
// checks each host would serve its own surface at its root, every local
// asset resolves inside its artifact, invite routing is role-aware, and the
// deploy script refuses without approval / a production build.
import { execFileSync, spawnSync } from 'node:child_process';
import { mkdtempSync, writeFileSync, readFileSync, existsSync, mkdirSync } from 'node:fs';
import { createServer } from 'node:http';
import { tmpdir } from 'node:os';
import { join, extname } from 'node:path';
import { createRequire } from 'node:module';
import { PRODUCTION_SURFACES, PRODUCTION_URLS } from '../scripts/production-surfaces.mjs';

const root = new URL('../', import.meta.url).pathname;
const results = []; let fails = 0;
const ok = (n, c, x = '') => { results.push(`${c ? 'PASS' : 'FAIL'}  ${n}${x ? '  -> ' + String(x).slice(0, 160) : ''}`); if (!c) fails++; };

// Fake Flutter web builds (markers) so the packaging is deterministic.
const tmp = mkdtempSync(join(tmpdir(), 'cefflo-surfaces-'));
for (const app of ['vendor', 'driver']) {
  mkdirSync(join(tmp, app));
  writeFileSync(join(tmp, app, 'index.html'), `<!doctype html><title>FLUTTER-${app}</title><script src="flutter_bootstrap.js"></script>`);
  writeFileSync(join(tmp, app, 'flutter_bootstrap.js'), '//');
}
const env = {
  ...process.env, CEFFLO_ENVIRONMENT: 'test', CEFFLO_SUPABASE_PROJECT_REF: 'abcdefghijklmnopqrst',
  SUPABASE_URL: 'https://abcdefghijklmnopqrst.supabase.co', SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_test',
  ...PRODUCTION_URLS, CEFFLO_VENDOR_APP_WEB_DIR: join(tmp, 'vendor'), CEFFLO_DRIVER_APP_WEB_DIR: join(tmp, 'driver'),
};
execFileSync('node', ['scripts/build-static.mjs'], { cwd: root, env, stdio: 'pipe' });
execFileSync('node', ['scripts/build-surfaces.mjs'], { cwd: root, env, stdio: 'pipe' });
const art = n => join(root, 'dist-surfaces', n);

// 1. every production host has its own root artifact
const marketing = readFileSync(join(root, 'website/index.html'), 'utf8');
const IDENT = {
  vendor: h => h.includes('src="js/app.js"'),
  operator: h => h.includes('FLUTTER-vendor'), helper: h => h.includes('FLUTTER-vendor'), driver: h => h.includes('FLUTTER-driver'),
  invite: h => h.includes('Cefflo — Invitation') && h.includes('./destination.js'),
  tracking: h => h.includes('Track your delivery'),
  order: h => h.includes('/store/store.js'),
  foundr: h => /FOUNDR|foundr|Founder/i.test(h) && h.includes('./backend.js'),
};
for (const [n, s] of Object.entries(PRODUCTION_SURFACES)) {
  const p = join(art(n), 'index.html');
  const h = existsSync(p) ? readFileSync(p, 'utf8') : '';
  ok(`1 https://${s.domain}/ -> ${s.title}`, IDENT[n](h), h.slice(0, 80));
  ok(`  ${s.domain} root is not the marketing page`, h && h !== marketing);
}

// 2. every local script/style/manifest in the static roots resolves inside the artifact
for (const n of ['vendor', 'invite', 'tracking', 'order', 'foundr']) {
  const h = readFileSync(join(art(n), 'index.html'), 'utf8');
  const refs = [...h.matchAll(/(?:src|href)="([^"]+)"/g)].map(m => m[1]).filter(u => !/^(https?:|data:|#|mailto:)/.test(u));
  const pages = n === 'invite' ? ['/', '/4326ade037113bf141fce3847593fd631a1fd8d28bbfb68c'] : ['/'];
  const missing = [];
  for (const page of pages) for (const r of refs) {
    const path = new URL(r, `https://host${page}`).pathname;
    if (!existsSync(join(art(n), decodeURIComponent(path)))) missing.push(`${page} ${r}`);
  }
  ok(`2 ${n}: all ${refs.length} local assets resolve at the root${n === 'invite' ? ' (also from /<token>)' : ''}`, !missing.length, missing.join(', '));
}

// 3. runtime config carries the canonical production URLs (no internal paths)
const cfgText = readFileSync(join(art('invite'), 'shared/config.js'), 'utf8');
const cfg = JSON.parse(cfgText.replace(/^window\.CEFFLO_CONFIG = Object\.freeze\(/, '').replace(/\);\s*$/, ''));
ok('3 inviteBaseUrl = https://invite.cefflo.com/', cfg.inviteBaseUrl === 'https://invite.cefflo.com/', cfg.inviteBaseUrl);
ok('  trackingBaseUrl = https://tracking.cefflo.com/', cfg.trackingBaseUrl === 'https://tracking.cefflo.com/', cfg.trackingBaseUrl);
ok('  storefrontBaseUrl = https://order.cefflo.com/', cfg.storefrontBaseUrl === 'https://order.cefflo.com/', cfg.storefrontBaseUrl);
ok('  role-aware app destinations', cfg.appWebUrls.driver === 'https://driver.cefflo.com/' && cfg.appWebUrls.operator === 'https://operator.cefflo.com/' && cfg.appWebUrls.helper === 'https://helper.cefflo.com/', JSON.stringify(cfg.appWebUrls));
ok('  no internal source paths in public bases', !/\/(invite|customer|store|web|foundr)\//.test(JSON.stringify([cfg.inviteBaseUrl, cfg.trackingBaseUrl, cfg.storefrontBaseUrl, cfg.appWebUrls])));
ok('  no store.cefflo.com / rider.cefflo.com', !/store\.cefflo\.com|rider\.cefflo\.com/.test(cfgText));

// 4. invite routing: role-aware; the token (server) decides the role
const { inviteDestination, inviteTokenFrom } = createRequire(import.meta.url)('../invite/destination.js');
const T = '4326ade037113bf141fce3847593fd631a1fd8d28bbfb68c';
ok('4 Driver token -> driver.cefflo.com', inviteDestination('rider', cfg.appWebUrls, T) === `https://driver.cefflo.com/?join=${T}`);
ok('  Operator token -> operator.cefflo.com', inviteDestination('operator', cfg.appWebUrls, T) === `https://operator.cefflo.com/?access=operator&join=${T}`);
ok('  Helper token -> helper.cefflo.com', inviteDestination('helper', cfg.appWebUrls, T) === `https://helper.cefflo.com/?access=helper&join=${T}`);
ok('  staging fallback: shared Vendor app + ?access=', inviteDestination('helper', { vendor: 'https://x.pages.dev/' }, T) === `https://x.pages.dev/?access=helper&join=${T}`);
ok('  no destination for an unknown kind or bad token', inviteDestination('owner', cfg.appWebUrls, T) === null && inviteDestination('rider', cfg.appWebUrls, 'abc') === null);
ok('  gateway reads /<token> and ?link=<token>', inviteTokenFrom({ pathname: `/${T}`, search: '' }) === T && inviteTokenFrom({ pathname: '/', search: `?link=${T}` }) === T && inviteTokenFrom({ pathname: '/', search: '' }) === null);
ok('  Vendor Web builds invite links from the gateway', readFileSync(join(art('vendor'), 'js/invite_link.js'), 'utf8').includes('inviteBaseUrl'));

// 5. Cloudflare configs: host -> its own artifact, root + SPA fallback
for (const [n, s] of Object.entries(PRODUCTION_SURFACES)) {
  const c = JSON.parse(readFileSync(join(root, `deploy/cloudflare/${n}.jsonc`), 'utf8').replace(/^\s*\/\/.*$/gm, ''));
  ok(`5 deploy/cloudflare/${n}.jsonc: ${s.domain} -> dist-surfaces/${n}`, c.routes?.[0]?.pattern === s.domain && c.routes[0].custom_domain === true && c.assets?.directory === `../../dist-surfaces/${n}` && c.assets.not_found_handling === 'single-page-application', JSON.stringify(c.routes));
}

// 6. served like a static-assets Worker: root + SPA fallback per host
const types = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json' };
async function serve(dir) {
  const srv = createServer((req, res) => {
    const p = decodeURIComponent(new URL(req.url, 'http://x').pathname);
    let f = join(dir, p.endsWith('/') ? p + 'index.html' : p);
    if (!existsSync(f) || !extname(f)) f = join(dir, 'index.html'); // SPA fallback
    res.writeHead(200, { 'content-type': types[extname(f)] || 'application/octet-stream' }); res.end(readFileSync(f));
  });
  await new Promise(r => srv.listen(0, r));
  return { url: `http://127.0.0.1:${srv.address().port}`, close: () => srv.close() };
}
for (const [n, path] of [['invite', `/${T}`], ['invite', `/?link=${T}`], ['order', '/kedai-test'], ['tracking', '/?token=abc'], ['driver', `/?join=${T}`], ['helper', '/'], ['operator', '/']]) {
  const s = await serve(art(n)); const h = await (await fetch(s.url + path)).text(); s.close();
  ok(`6 ${PRODUCTION_SURFACES[n].domain}${path.slice(0, 20)} serves ${n}`, IDENT[n](h));
}

// 7. the deploy script refuses without approval and for a non-production build
const noFlag = spawnSync('node', ['scripts/deploy-production.mjs'], { cwd: root, encoding: 'utf8' });
ok('7 deploy refuses without --founder-approved', noFlag.status === 2 && /Founder approval/.test(noFlag.stderr), noFlag.stderr);
const notProd = spawnSync('node', ['scripts/deploy-production.mjs', '--founder-approved'], { cwd: root, encoding: 'utf8' });
ok('  deploy refuses a non-production build', notProd.status === 2 && /not a production build/.test(notProd.stderr), notProd.stderr);

console.log(results.join('\n')); console.log(`\n${results.length - fails}/${results.length} passed`);
process.exit(fails ? 1 : 0);
