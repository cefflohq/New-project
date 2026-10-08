// Generates the CEFFLO Content Engine V2 n8n workflows (importable JSON).
//   node automation/n8n/content-engine-v2/scripts/generate-workflows.mjs
// Prompts are read from ../prompts and embedded into Code nodes, so editing a
// prompt file and re-running this script keeps the workflows in sync.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..');
const P = n => readFileSync(join(root, 'prompts', n), 'utf8');
const PROMPTS = {
  persona: P('persona_kak_zee.md'), truth: P('product_truth.md'), planner: P('planner.md'),
  video: P('script_video.md'), text: P('script_text.md'), qa: P('qa.md'),
};

// Stable workflow ids so Execute Workflow nodes resolve after import.
const ID = {
  plan: 'ce2WF01DailyPlan', video: 'ce2WF02VideoProd', shot: 'ce2WF02bRenderSh', send: 'ce2WF03SendAppro',
  inbox: 'ce2WF04ApproveIn', revise: 'ce2WF05ReviseCon', publish: 'ce2WF06Publisher', learn: 'ce2WF07MetricsLe',
  error: 'ce2WF99ErrorAlrt',
};

// Credentials are referenced by NAME; create them in n8n with these names.
const CRED = {
  pg: { postgres: { id: 'CE2_PG', name: 'CE2 Postgres' } },
  tg: { telegramApi: { id: 'CE2_TG', name: 'CE2 Telegram Bot' } },
  h: n => ({ httpHeaderAuth: { id: `CE2_${n.toUpperCase()}`, name: `CE2 ${n}` } }),
};

// ------------------------------------------------------------- shared code
const CONFIG_JS = `// ===== CEFFLO Content Engine V2 — CONFIG (edit here; secrets live in Credentials) =====
return [{ json: { config: {
  tz: 'Asia/Kuala_Lumpur',
  founderChatId: '1140338735',          // your Telegram user/chat id (numbers)
  dailyBudgetUsd: 25,                              // generation stops when today's cost reaches this
  deepseek: { url: 'https://api.deepseek.com/chat/completions', model: 'deepseek-v4-flash', temperature: 0.8 },
  image: { url: 'SET_IMAGE_API_URL', model: 'SET_IMAGE_MODEL',
           // Kak Zee references (persona/kak_zee), served by the render worker under /files/persona/kak_zee/
           personaRefs: ['01_front_portrait.jpg', '05_three_quarter_right.jpg', '07_three_quarter_left.jpg', '02_full_body.jpg'],
           wardrobe: 'denim-blue cotton tudung bawal, beige linen overshirt over a white t-shirt, black wide-leg trousers, white sneakers, black smartwatch, black shoulder bag' },
  seedance: { url: 'https://ark.ap-southeast.bytepluses.com/api/v3/contents/generations/tasks', model: 'SET_SEEDANCE_MODEL_ID' },
  kling: { url: 'https://api-singapore.klingai.com/v1/videos/image2video', model: 'kling-v2-1' },
  omni: { submitUrl: 'SET_OMNIHUMAN_SUBMIT_URL', pollUrl: 'SET_OMNIHUMAN_POLL_URL' },
  eleven: { voiceId: 'SET_KAK_ZEE_VOICE_ID', model: 'eleven_v3',
            settings: { stability: 0.4, similarity_boost: 0.75, style: 0.15, use_speaker_boost: true } },
  render: { url: 'SET_RENDER_WORKER_URL' },        // e.g. https://render.cefflo.com (render-worker/)
  screens: {                                       // real CEFFLO screen clips hosted by the render worker
    vendor_orders: '/files/screens/vendor_orders.mp4', vendor_zones: '/files/screens/vendor_zones.mp4',
    vendor_plan: '/files/screens/vendor_today.mp4', vendor_riders: '/files/screens/vendor_riders.mp4',
    vendor_today: '/files/screens/vendor_today.mp4', driver_run: '/files/screens/driver_run.mp4',
    driver_stops: '/files/screens/driver_stops.mp4', driver_pod: '/files/screens/driver_pod.mp4',
    customer_tracking: '/files/screens/customer_tracking.mp4', storefront: '/files/screens/storefront.mp4' },
  slots: { video: ['08:30', '12:30', '20:30'], text: ['10:00', '17:00'] },   // MYT publish times
  meta: { graph: 'https://graph.facebook.com/v23.0', igUserId: 'SET_IG_USER_ID', pageId: 'SET_FB_PAGE_ID' },
  threads: { graph: 'https://graph.threads.net/v1.0', userId: 'SET_THREADS_USER_ID' },
  tiktok: { initUrl: 'https://open.tiktokapis.com/v2/post/publish/video/init/', privacy: 'SELF_ONLY' }, // PUBLIC_TO_EVERYONE after TikTok audit
} } }];`;

const SQL_HELPER = `const q = v => v === null || v === undefined ? 'null' : '$ce2$' + String(typeof v === 'object' ? JSON.stringify(v) : v).replaceAll('$ce2$', '') + '$ce2$';`;
const cfg = `$('Config').first().json.config`;

// ------------------------------------------------------------- builders
function wf(id, name, build) {
  const nodes = [], connections = {};
  let n = 0;
  const api = {
    add(name, type, typeVersion, parameters, pos, extra = {}) {
      nodes.push({ id: `${id}-${++n}`, name, type, typeVersion, position: pos, parameters, ...extra });
      return name;
    },
    link(from, to, out = 0, input = 0) {
      connections[from] ??= { main: [] };
      while (connections[from].main.length <= out) connections[from].main.push([]);
      connections[from].main[out].push({ node: to, type: 'main', index: input });
    },
    chain(...names) { for (let i = 0; i < names.length - 1; i++) api.link(names[i], names[i + 1]); },
    note(content, pos, width = 420, height = 260, color = 7) {
      nodes.push({ id: `${id}-${++n}`, name: `Note ${n}`, type: 'n8n-nodes-base.stickyNote', typeVersion: 1, position: pos,
        parameters: { content, width, height, color } });
    },
    code(name, js, pos, mode = 'runOnceForAllItems', extra = {}) {
      // All-items mode has no $json; bind it to the first input item where used.
      if (mode === 'runOnceForAllItems' && /\$json\b/.test(js)) js = 'const $json = $input.first().json;\n' + js;
      return api.add(name, 'n8n-nodes-base.code', 2, { mode, jsCode: js }, pos, extra);
    },
    pg(name, sqlExpr, pos, extra = {}) {
      return api.add(name, 'n8n-nodes-base.postgres', 2.6, { operation: 'executeQuery', query: sqlExpr, options: {} }, pos,
        { credentials: CRED.pg, ...extra });
    },
    http(name, cred, { method = 'POST', url, body, query, headers, binary = false, timeout = 120000, auth = true }, pos, extra = {}) {
      const p = { method, url, options: { timeout, ...(binary ? { response: { response: { responseFormat: 'file' } } } : {}) } };
      if (auth) Object.assign(p, { authentication: 'genericCredentialType', genericAuthType: 'httpHeaderAuth' });
      if (body) Object.assign(p, { sendBody: true, specifyBody: 'json', jsonBody: body });
      if (query) Object.assign(p, { sendQuery: true, specifyQuery: 'json', jsonQuery: query });
      if (headers) Object.assign(p, { sendHeaders: true, specifyHeaders: 'json', jsonHeaders: headers });
      return api.add(name, 'n8n-nodes-base.httpRequest', 4.2, p, pos,
        { ...(auth ? { credentials: CRED.h(cred) } : {}), retryOnFail: true, maxTries: 3, waitBetweenTries: 5000, ...extra });
    },
    tg(name, params, pos, extra = {}) {
      return api.add(name, 'n8n-nodes-base.telegram', 1.2, params, pos, { credentials: CRED.tg, ...extra });
    },
    exec(name, workflowId, pos, wait = true) {
      return api.add(name, 'n8n-nodes-base.executeWorkflow', 1.2, {
        source: 'database', workflowId: { __rl: true, mode: 'id', value: workflowId },
        mode: 'each', options: { waitForSubWorkflow: wait } }, pos);
    },
    iff(name, leftExpr, pos) {
      return api.add(name, 'n8n-nodes-base.if', 2.2, { conditions: {
        options: { caseSensitive: true, typeValidation: 'loose', version: 2 }, combinator: 'and',
        conditions: [{ id: `${name}-c`, leftValue: leftExpr, rightValue: true, operator: { type: 'boolean', operation: 'true', singleValue: true } }] },
        options: {} }, pos);
    },
    sw(name, valueExpr, cases, pos) {
      return api.add(name, 'n8n-nodes-base.switch', 3.2, { rules: { values: cases.map((c, i) => ({
        conditions: { options: { caseSensitive: true, typeValidation: 'strict', version: 2 }, combinator: 'and',
          conditions: [{ id: `${name}-${i}`, leftValue: valueExpr, rightValue: c, operator: { type: 'string', operation: 'equals' } }] },
        renameOutput: true, outputKey: c })) }, options: {} }, pos);
    },
    wait(name, seconds, pos) {
      return api.add(name, 'n8n-nodes-base.wait', 1.1, { amount: seconds, unit: 'seconds' }, pos, { webhookId: `${id}-${name}`.replace(/\W/g, '') });
    },
  };
  build(api);
  return { id, name, nodes, connections, active: false, settings: { executionOrder: 'v1', timezone: 'Asia/Kuala_Lumpur',
    saveManualExecutions: true, ...(id === ID.error ? {} : { errorWorkflow: ID.error }) }, tags: [], pinData: {} };
}

const TG_KEYBOARD = idExpr => ({ rows: [{ row: { buttons: [
  { text: '✅ Approve', additionalFields: { callback_data: `=ok|{{ ${idExpr} }}` } },
  { text: '✏️ Revise', additionalFields: { callback_data: `=rv|{{ ${idExpr} }}` } },
  { text: '❌ Reject', additionalFields: { callback_data: `=no|{{ ${idExpr} }}` } } ] } }] });

const deepseekBody = '={{ JSON.stringify($json.body) }}';
const parseLLM = `const raw = $json.choices?.[0]?.message?.content ?? '';
let out; try { out = JSON.parse(raw.replace(/^\`\`\`(json)?|\`\`\`$/g, '').trim()); } catch (e) { throw new Error('LLM did not return JSON: ' + raw.slice(0, 300)); }`;

// ============================================================ WF01 Daily plan
const wf01 = wf(ID.plan, 'CEFFLO CE2 · 01 · Daily Plan + Script + QA', a => {
  a.note(`## 01 · Daily Plan + Script + QA  (M1 · M2 · M3 · M5)
Runs **06:00 MYT** daily (or Manual).
1. Cost guard (daily cap in Config)
2. DeepSeek **plans 5 items**: 3 video (TikTok/FB Reels/IG Reels) + 2 Threads text, using learnings + recycle winners
3. DeepSeek **writes** each script in **Kak Zee**'s voice
4. DeepSeek **QA** (independent prompt). FAIL → 1 rewrite with findings → still FAIL = HOLD + Telegram
5. PASS → video → **02 Video Production**; text → **03 Send for Approval**`, [-80, -360], 560, 300, 4);
  a.add('Every day 06:00', 'n8n-nodes-base.scheduleTrigger', 1.2, { rule: { interval: [{ field: 'cronExpression', expression: '0 6 * * *' }] } }, [0, 0]);
  a.add('Manual run', 'n8n-nodes-base.manualTrigger', 1, {}, [0, 180]);
  a.code('Config', CONFIG_JS, [220, 80]);
  a.link('Every day 06:00', 'Config'); a.link('Manual run', 'Config');
  a.pg('Memory + cost today', `select
  coalesce((select sum(usd) from cefflo_ce2.cost where created_at >= date_trunc('day', now() at time zone 'Asia/Kuala_Lumpur') at time zone 'Asia/Kuala_Lumpur'),0) as cost_today,
  coalesce((select jsonb_agg(l order by l.id desc) from (select week, observation, confidence, action from cefflo_ce2.learning order by id desc limit 12) l),'[]') as learnings,
  coalesce((select jsonb_agg(r) from (select c.id, c.hook, c.format, c.world, c.funnel, rc.score, rc.reason from cefflo_ce2.recycle_candidate rc join cefflo_ce2.content c on c.id = rc.content_id where not rc.used order by rc.score desc limit 3) r),'[]') as recycle,
  coalesce((select jsonb_agg(h) from (select hook from cefflo_ce2.content where hook is not null order by created_at desc limit 30) h),'[]') as recent_hooks,
  ((now() at time zone 'Asia/Kuala_Lumpur')::date - date '2026-01-05') % 2 as day_parity`, [440, 80], { alwaysOutputData: true });
  a.iff('Under budget?', `={{ Number($json.cost_today) < ${cfg}.dailyBudgetUsd }}`, [660, 80]);
  a.tg('Alert: budget reached', { chatId: `={{ ${cfg}.founderChatId }}`, text: `=⛔ CE2: bajet harian dicapai (USD {{ $json.cost_today }}). Tiada content dijana hari ni.`, additionalFields: { appendAttribution: false } }, [880, 260]);
  a.code('Build plan request', `const c = ${cfg}; const m = $input.first().json;
const sys = ${JSON.stringify(PROMPTS.planner)} + '\\n\\nPERSONA:\\n' + ${JSON.stringify(PROMPTS.persona)} + '\\n\\n' + ${JSON.stringify(PROMPTS.truth)};
const user = JSON.stringify({ date: $now.setZone(c.tz).toISODate(), slot2: m.day_parity == 0 ? 'TOFU' : 'MOFU', slot3: m.day_parity == 0 ? 'MOFU' : 'BOFU',
  learnings: m.learnings, recycle_candidates: m.recycle, last_hooks: (m.recent_hooks || []).map(h => h.hook) });
return [{ json: { body: { model: c.deepseek.model, temperature: c.deepseek.temperature, response_format: { type: 'json_object' },
  messages: [{ role: 'system', content: sys }, { role: 'user', content: user }] } } }];`, [880, 60]);
  a.http('DeepSeek · plan', 'DeepSeek', { url: `={{ ${cfg}.deepseek.url }}`, body: deepseekBody }, [1100, 60]);
  a.code('Parse plan → 5 items', `${parseLLM}
const items = (out.items || []).slice(0, 5);
if (items.length !== 5) throw new Error('Planner returned ' + items.length + ' items, expected 5');
return items.map(i => ({ json: { brief: i, attempt: 0, findings: [] } }));`, [1320, 60]);
  a.code('Insert content rows', `${SQL_HELPER}
return $input.all().map(it => { const b = it.json.brief;
  return { json: { ...it.json, sql: \`insert into cefflo_ce2.content (slot,type,platforms,funnel,format,world,pain,angle,hook,recycle_of,brief,status)
  values (\${Number(b.slot)}, \${q(b.type)}, \${q('{' + (b.platforms || []).join(',') + '}')}::text[], \${q(b.funnel)}, \${q(b.format)}, \${q(b.world)}, \${q(b.pain)}, \${q(b.angle)}, \${q(b.hook_idea)},
  \${b.recycle_of ? q(b.recycle_of) + '::uuid' : 'null'}, \${q(b)}::jsonb, 'NEW')
  on conflict (run_date, slot, revisions) do update set brief = excluded.brief returning id\` } }; });`, [1540, 60]);
  a.pg('Save brief', '={{ $json.sql }}', [1760, 60]);
  a.code('Build script request', `const c = ${cfg}; const prev = $('Insert content rows').all();
return $input.all().map((it, i) => { const ctx = it.json.content_id ? it.json : { ...prev[i].json, content_id: it.json.id };
  const b = ctx.brief; const isVideo = b.type === 'video';
  const sys = (isVideo ? ${JSON.stringify(PROMPTS.video)} : ${JSON.stringify(PROMPTS.text)}) + '\\n\\nPERSONA:\\n' + ${JSON.stringify(PROMPTS.persona)} + '\\n\\n' + ${JSON.stringify(PROMPTS.truth)}
    + (isVideo ? '\\nWardrobe: ' + c.image.wardrobe : '');
  const user = JSON.stringify({ brief: b, qa_findings_to_fix: ctx.findings || [] });
  return { json: { ...ctx, body: { model: c.deepseek.model, temperature: c.deepseek.temperature, response_format: { type: 'json_object' },
    messages: [{ role: 'system', content: sys }, { role: 'user', content: user }] } } }; });`, [1980, 60]);
  a.http('DeepSeek · script', 'DeepSeek', { url: `={{ ${cfg}.deepseek.url }}`, body: deepseekBody }, [2200, 60]);
  a.code('Build QA request', `const c = ${cfg};
return $input.all().map((it, i) => { const ctx = $('Build script request').all()[i].json; const json = it.json; ${parseLLM.replace(/\n/g, ' ')}
  const sys = ${JSON.stringify(PROMPTS.qa)} + '\\n\\nPERSONA:\\n' + ${JSON.stringify(PROMPTS.persona)} + '\\n\\n' + ${JSON.stringify(PROMPTS.truth)};
  return { json: { ...ctx, body: { model: c.deepseek.model, temperature: 0.1, response_format: { type: 'json_object' },
    messages: [{ role: 'system', content: sys }, { role: 'user', content: JSON.stringify({ type: ctx.brief.type, script: out }) }] }, script: out } }; });`.replace('const raw = $json.', 'const raw = json.'), [2420, 60]);
  a.http('DeepSeek · QA', 'DeepSeek', { url: `={{ ${cfg}.deepseek.url }}`, body: deepseekBody }, [2640, 60]);
  a.code('Evaluate QA', `return $input.all().map((it, i) => { const ctx = $('Build QA request').all()[i].json; const json = it.json; ${parseLLM.replace(/\n/g, ' ')}
  const pass = out.verdict === 'PASS'; return { json: { ...ctx, body: undefined, qa: out, pass, retry: !pass && ctx.attempt < 1,
    attempt: ctx.attempt + 1, findings: out.findings || [] } }; });`.replace('const raw = $json.', 'const raw = json.'), [2860, 60]);
  a.iff('QA pass?', '={{ $json.pass }}', [3080, 60]);
  a.iff('Retry once?', '={{ $json.retry }}', [3300, 260]);
  a.code('Save script', `${SQL_HELPER}
return $input.all().map(it => ({ json: { ...it.json, sql: \`update cefflo_ce2.content set script = \${q(it.json.script)}::jsonb, qa = \${q(it.json.qa)}::jsonb,
  hook = coalesce(\${q(it.json.script.hook || it.json.script.title)}, hook), status = 'SCRIPTED', updated_at = now() where id = '\${it.json.content_id}'\` } }));`, [3300, 0]);
  a.pg('DB · scripted', '={{ $json.sql }}', [3520, 0]);
  a.code('Route by type', `return $('Save script').all().map(it => ({ json: { content_id: it.json.content_id, type: it.json.brief.type } }));`, [3740, 0]);
  a.sw('Video or text?', '={{ $json.type }}', ['video', 'text'], [3960, 0]);
  a.exec('→ 02 Video Production', ID.video, [4200, -80], false);
  a.exec('→ 03 Send for approval', ID.send, [4200, 100], false);
  a.code('Mark HOLD', `${SQL_HELPER}
return $input.all().map(it => ({ json: { ...it.json, sql: \`update cefflo_ce2.content set qa = \${q(it.json.qa)}::jsonb, script = \${q(it.json.script)}::jsonb, status = 'HOLD', updated_at = now() where id = '\${it.json.content_id}'\` } }));`, [3520, 380]);
  a.pg('DB · hold', '={{ $json.sql }}', [3740, 380]);
  a.tg('Notify HOLD', { chatId: `={{ ${cfg}.founderChatId }}`, text: `=⚠️ CE2 HOLD — slot {{ $('Mark HOLD').item.json.brief.slot }} ({{ $('Mark HOLD').item.json.brief.type }}) gagal QA 2 kali.\n{{ ($('Mark HOLD').item.json.findings || []).map(f => '• ' + f.criterion + ': ' + f.evidence).join('\\n').slice(0, 900) }}`, additionalFields: { appendAttribution: false } }, [3960, 380]);

  a.chain('Config', 'Memory + cost today', 'Under budget?');
  a.link('Under budget?', 'Build plan request', 0); a.link('Under budget?', 'Alert: budget reached', 1);
  a.chain('Build plan request', 'DeepSeek · plan', 'Parse plan → 5 items', 'Insert content rows', 'Save brief', 'Build script request',
    'DeepSeek · script', 'Build QA request', 'DeepSeek · QA', 'Evaluate QA', 'QA pass?');
  a.link('QA pass?', 'Save script', 0); a.link('QA pass?', 'Retry once?', 1);
  a.link('Retry once?', 'Build script request', 0); a.link('Retry once?', 'Mark HOLD', 1);
  a.chain('Save script', 'DB · scripted', 'Route by type', 'Video or text?');
  a.link('Video or text?', '→ 02 Video Production', 0); a.link('Video or text?', '→ 03 Send for approval', 1);
  a.chain('Mark HOLD', 'DB · hold', 'Notify HOLD');
});
// "Build script request" receives either "Save brief" rows (first pass, {id}) or QA-retry items (with content_id).
// Save brief returns rows {id}; Build script request merges them with Insert content rows by index.

// ============================================================ WF02 Video production
const wf02 = wf(ID.video, 'CEFFLO CE2 · 02 · Video Production', a => {
  a.note(`## 02 · Video Production  (M4 STUDIO)
Input: \`content_id\`. For every shot → **02b Render Shot** (keyframe → Seedance/Kling or OmniHuman lip-sync, ElevenLabs VO), then the **render worker** assembles:
1080×1920 · 30 fps · H.264 ~7 Mbps · subtitles · room tone · **phone look** (light grain, soft sharpen, handheld micro-shake, WB drift) · −14 LUFS.
Then → **03 Send for approval**. Any failure → status PRODUCE_FAIL + Telegram.`, [-80, -360], 620, 280, 4);
  a.add('From 01 / 05', 'n8n-nodes-base.executeWorkflowTrigger', 1.1, { inputSource: 'passthrough' }, [0, 0]);
  a.code('Config', CONFIG_JS, [220, 0]);
  a.pg('Load content', `={{ "select id, script, brief from cefflo_ce2.content where id = '" + $('From 01 / 05').first().json.content_id + "'" }}`, [440, 0]);
  a.pg('Mark PRODUCING', `={{ "update cefflo_ce2.content set status = 'PRODUCING', updated_at = now() where id = '" + $json.id + "' returning id" }}`, [660, 0]);
  a.code('Expand shots', `const row = $('Load content').first().json;
return (row.script.shots || []).map(s => ({ json: { content_id: row.id, shot: s } }));`, [880, 0]);
  a.exec('02b Render shot (each)', ID.shot, [1100, 0], true);
  a.code('Build render manifest', `const c = ${cfg}; const row = $('Load content').first().json;
const shots = $input.all().map(i => i.json).sort((x, y) => x.n - y.n);
const bad = shots.filter(s => !s.video_url);
if (bad.length) throw new Error('Shots without video: ' + bad.map(s => s.n).join(','));
return [{ json: { content_id: row.id, manifest: { content_id: row.id, preset: 'phone_look_v1', width: 1080, height: 1920, fps: 30,
  shots: shots.map(s => ({ n: s.n, video_url: s.video_url, audio_url: s.audio_url || null, seconds: s.seconds, subtitle: s.subtitle || '' })),
  music: { url: null, gain_db: -22 }, room_tone: true } } }];`, [1320, 0]);
  a.http('Render worker · assemble', 'Render', { url: `={{ ${cfg}.render.url + '/render' }}`, body: '={{ JSON.stringify($json.manifest) }}', timeout: 600000 }, [1540, 0]);
  a.pg('Save final video', `={{ "update cefflo_ce2.content set media_url = '" + $json.url.replaceAll("'", "") + "', status = 'READY', updated_at = now() where id = '" + $('Build render manifest').first().json.content_id + "'; insert into cefflo_ce2.asset (content_id, kind, provider, url, status, meta) values ('" + $('Build render manifest').first().json.content_id + "', 'final', 'render-worker', '" + $json.url.replaceAll("'", "") + "', 'DONE', '{\\"duration\\":" + Number($json.duration || 0) + "}')" }}`, [1760, 0]);
  a.code('Pass id', `return [{ json: { content_id: $('Build render manifest').first().json.content_id } }];`, [1980, 0]);
  a.exec('→ 03 Send for approval', ID.send, [2200, 0], false);
  a.chain('From 01 / 05', 'Config', 'Load content', 'Mark PRODUCING', 'Expand shots', '02b Render shot (each)', 'Build render manifest',
    'Render worker · assemble', 'Save final video', 'Pass id', '→ 03 Send for approval');
});

// ============================================================ WF02b Render one shot
const wf02b = wf(ID.shot, 'CEFFLO CE2 · 02b · Render Shot', a => {
  a.note(`## 02b · Render one shot
- **vo** → ElevenLabs (Kak Zee voice) → upload to render worker → \`audio_url\`
- **screen** → real CEFFLO screen clip from the library (never AI-generated UI)
- **broll** → keyframe (image model + Kak Zee references) → **Seedance** (poll ≤ 10 min) → fallback **Kling**
- **talking** → keyframe → **OmniHuman** lip-sync with the VO audio
Prompt style is enforced: handheld phone, natural light, no cinematic/4K.
⚠️ Kling needs a JWT from AK/SK: set env \`NODE_FUNCTION_ALLOW_BUILTIN=crypto\` on n8n.
⚠️ Image + OmniHuman request bodies are adapters — adjust to the provider you sign up with.`, [-80, -420], 620, 320, 4);
  a.add('From 02', 'n8n-nodes-base.executeWorkflowTrigger', 1.1, { inputSource: 'passthrough' }, [0, 0]);
  a.code('Config', CONFIG_JS, [200, 0]);
  a.code('Shot context', `const i = $('From 02').first().json; return [{ json: { content_id: i.content_id, ...i.shot, has_vo: !!(i.shot.vo || '').trim() } }];`, [400, 0]);
  a.iff('Has VO?', '={{ $json.has_vo }}', [600, 0]);
  a.http('ElevenLabs · VO', 'ElevenLabs', { url: `={{ 'https://api.elevenlabs.io/v1/text-to-speech/' + ${cfg}.eleven.voiceId + '?output_format=mp3_44100_128' }}`,
    body: `={{ JSON.stringify({ text: $json.vo, model_id: ${cfg}.eleven.model, language_code: 'ms', voice_settings: ${cfg}.eleven.settings }) }}`, binary: true }, [820, -120]);
  a.add('Upload VO to worker', 'n8n-nodes-base.httpRequest', 4.2, { method: 'POST', url: `={{ ${cfg}.render.url + '/upload?ext=mp3' }}`,
    authentication: 'genericCredentialType', genericAuthType: 'httpHeaderAuth', sendBody: true, contentType: 'binaryData', inputDataFieldName: 'data', options: {} }, [1040, -120], { credentials: CRED.h('Render') });
  a.code('Attach audio', `const s = $('Shot context').first().json; return [{ json: { ...s, audio_url: $json.url } }];`, [1260, -120]);
  a.code('No audio', `return [{ json: { ...$('Shot context').first().json, audio_url: null } }];`, [820, 120]);
  a.sw('Shot kind', '={{ $json.kind }}', ['screen', 'broll', 'talking'], [1480, 0]);
  // screen
  a.code('Screen clip', `const c = ${cfg}; const path = c.screens[$json.screen_id] || c.screens.vendor_orders;
return [{ json: { n: $json.n, seconds: $json.seconds, subtitle: $json.subtitle, audio_url: $json.audio_url, video_url: c.render.url + path, provider: 'screen-library' } }];`, [1720, -260]);
  // keyframe (broll + talking)
  a.code('Keyframe request', `const c = ${cfg};
const prompt = 'Vertical 9:16 photo taken on a phone, handheld, natural indoor light, candid, everyday Malaysian setting. Kak Zee (exactly the same woman as the reference images: round face, warm brown eyes, light natural makeup, soft smile), Malay woman mid-30s, wearing ' + c.image.wardrobe + '. ' + $json.visual_prompt + '. Not cinematic, not studio, natural skin texture, no text, no logos.';
return [{ json: { ...$json, kf: { model: c.image.model, prompt, reference_images: c.image.personaRefs.map(f => c.render.url + '/files/persona/kak_zee/' + f), size: '1080x1920', n: 1 } } }];`, [1720, 60]);
  a.http('Image · keyframe', 'Image', { url: `={{ ${cfg}.image.url }}`, body: '={{ JSON.stringify($json.kf) }}' }, [1940, 60]);
  a.code('Keyframe URL', `const s = $('Keyframe request').first().json; const r = $json;
const url = r.data?.[0]?.url || r.images?.[0]?.url || r.output?.[0] || r.url; if (!url) throw new Error('Image API: no URL in response');
return [{ json: { ...s, keyframe_url: url } }];`, [2160, 60]);
  a.sw('Talking or b-roll?', '={{ $json.kind }}', ['broll', 'talking'], [2380, 60]);
  // broll → Seedance
  a.http('Seedance · submit', 'Seedance', { url: `={{ ${cfg}.seedance.url }}`, body: `={{ JSON.stringify({ model: ${cfg}.seedance.model, content: [
    { type: 'text', text: $json.visual_prompt + ', handheld smartphone video, natural light, subtle camera shake, realistic, not cinematic --ratio 9:16 --resolution 1080p --duration ' + Math.min(10, Math.max(5, Math.round($json.seconds))) + ' --camerafixed false' },
    { type: 'image_url', image_url: { url: $json.keyframe_url } } ] }) }}` }, [2620, -60], { onError: 'continueErrorOutput' });
  a.code('Seedance task', `const s = $('Keyframe URL').first().json; return [{ json: { ...s, task_id: $json.id, tries: 0 } }];`, [2840, -60]);
  a.wait('Wait 20s (Seedance)', 20, [3060, -60]);
  a.http('Seedance · poll', 'Seedance', { method: 'GET', url: `={{ ${cfg}.seedance.url + '/' + $json.task_id }}` }, [3280, -60]);
  a.code('Seedance status', `const prev = $('Wait 20s (Seedance)').first().json; const st = $json.status;
return [{ json: { ...prev, tries: prev.tries + 1, status: st, done: st === 'succeeded', failed: st === 'failed' || st === 'cancelled' || prev.tries >= 30,
  video_url: $json.content?.video_url || null } }];`, [3500, -60]);
  a.iff('Seedance done?', '={{ $json.done }}', [3720, -60]);
  a.iff('Seedance failed?', '={{ $json.failed }}', [3940, 60]);
  a.code('B-roll result', `const s = $json; return [{ json: { n: s.n, seconds: s.seconds, subtitle: s.subtitle, audio_url: s.audio_url, video_url: s.video_url, provider: 'seedance' } }];`, [3940, -160]);
  // Kling fallback
  a.code('Kling JWT + body', `const c = ${cfg}; const s = $('Keyframe URL').first().json;
// Kling auth: JWT HS256 signed with your Access Key / Secret Key (store in credential "CE2 Kling" as header Authorization: Bearer <JWT>,
// or let this node sign it when NODE_FUNCTION_ALLOW_BUILTIN=crypto and the keys are set below).
const AK = 'SET_KLING_ACCESS_KEY', SK = 'SET_KLING_SECRET_KEY'; let bearer = null;
try { const crypto = require('crypto'); const b64 = o => Buffer.from(JSON.stringify(o)).toString('base64url'); const now = Math.floor(Date.now() / 1000);
  const h = b64({ alg: 'HS256', typ: 'JWT' }), p = b64({ iss: AK, exp: now + 1800, nbf: now - 5 });
  bearer = h + '.' + p + '.' + crypto.createHmac('sha256', SK).update(h + '.' + p).digest('base64url'); } catch (e) { bearer = null; }
return [{ json: { ...s, tries: 0, bearer, kbody: { model_name: c.kling.model, image: s.keyframe_url, prompt: s.visual_prompt + ', handheld phone video, natural light, realistic', duration: s.seconds > 5 ? '10' : '5', aspect_ratio: '9:16', mode: 'std' } } }];`, [4160, 160]);
  a.http('Kling · submit', 'Kling', { url: `={{ ${cfg}.kling.url }}`, body: '={{ JSON.stringify($json.kbody) }}', auth: false,
    headers: `={{ JSON.stringify({ Authorization: 'Bearer ' + $json.bearer }) }}` }, [4380, 160]);
  a.code('Kling task', `const s = $('Kling JWT + body').first().json; return [{ json: { ...s, task_id: $json.data?.task_id } }];`, [4600, 160]);
  a.wait('Wait 30s (Kling)', 30, [4820, 160]);
  a.http('Kling · poll', 'Kling', { method: 'GET', url: `={{ ${cfg}.kling.url + '/' + $json.task_id }}`, auth: false,
    headers: `={{ JSON.stringify({ Authorization: 'Bearer ' + $json.bearer }) }}` }, [5040, 160]);
  a.code('Kling status', `const prev = $('Wait 30s (Kling)').first().json; const st = $json.data?.task_status;
if (st === 'failed' || prev.tries >= 20) throw new Error('Kling failed for shot ' + prev.n + ': ' + ($json.data?.task_status_msg || 'timeout'));
return [{ json: { ...prev, tries: prev.tries + 1, done: st === 'succeed', video_url: $json.data?.task_result?.videos?.[0]?.url || null } }];`, [5260, 160]);
  a.iff('Kling done?', '={{ $json.done }}', [5480, 160]);
  a.code('Kling result', `const s = $json; return [{ json: { n: s.n, seconds: s.seconds, subtitle: s.subtitle, audio_url: s.audio_url, video_url: s.video_url, provider: 'kling' } }];`, [5700, 80]);
  // talking → OmniHuman
  a.iff('Has audio for lip-sync?', '={{ !!$json.audio_url }}', [2620, 300]);
  a.http('OmniHuman · submit', 'OmniHuman', { url: `={{ ${cfg}.omni.submitUrl }}`, body: '={{ JSON.stringify({ image_url: $json.keyframe_url, audio_url: $json.audio_url, prompt: "natural talking to phone camera, small head movement, blinking, relaxed" }) }}' }, [2840, 300]);
  a.code('Omni task', `const s = $('Has audio for lip-sync?').first().json; const r = $json; return [{ json: { ...s, task_id: r.task_id || r.data?.task_id || r.id, tries: 0 } }];`, [3060, 300]);
  a.wait('Wait 20s (Omni)', 20, [3280, 300]);
  a.http('OmniHuman · poll', 'OmniHuman', { method: 'GET', url: `={{ ${cfg}.omni.pollUrl.replace('{task_id}', $json.task_id) }}` }, [3500, 300]);
  a.code('Omni status', `const prev = $('Wait 20s (Omni)').first().json; const r = $json; const st = (r.status || r.data?.status || '').toLowerCase();
if (/fail|error|cancel/.test(st) || prev.tries >= 30) throw new Error('OmniHuman failed for shot ' + prev.n);
return [{ json: { ...prev, tries: prev.tries + 1, done: /succe|done|complete/.test(st), video_url: r.video_url || r.data?.video_url || r.output?.video_url || null } }];`, [3720, 300]);
  a.iff('Omni done?', '={{ $json.done && !!$json.video_url }}', [3940, 300]);
  a.code('Talking result', `const s = $json; return [{ json: { n: s.n, seconds: s.seconds, subtitle: s.subtitle, audio_url: null, video_url: s.video_url, provider: 'omnihuman' } }];`, [4160, 400]);
  a.code('Talking without audio = b-roll', `return [{ json: { ...$json, kind: 'broll' } }];`, [2840, 480]);

  a.chain('From 02', 'Config', 'Shot context', 'Has VO?');
  a.link('Has VO?', 'ElevenLabs · VO', 0); a.link('Has VO?', 'No audio', 1);
  a.chain('ElevenLabs · VO', 'Upload VO to worker', 'Attach audio', 'Shot kind'); a.link('No audio', 'Shot kind');
  a.link('Shot kind', 'Screen clip', 0); a.link('Shot kind', 'Keyframe request', 1); a.link('Shot kind', 'Keyframe request', 2);
  a.chain('Keyframe request', 'Image · keyframe', 'Keyframe URL', 'Talking or b-roll?');
  a.link('Talking or b-roll?', 'Seedance · submit', 0); a.link('Talking or b-roll?', 'Has audio for lip-sync?', 1);
  a.link('Seedance · submit', 'Seedance task', 0); a.link('Seedance · submit', 'Kling JWT + body', 1);
  a.chain('Seedance task', 'Wait 20s (Seedance)', 'Seedance · poll', 'Seedance status', 'Seedance done?');
  a.link('Seedance done?', 'B-roll result', 0); a.link('Seedance done?', 'Seedance failed?', 1);
  a.link('Seedance failed?', 'Kling JWT + body', 0); a.link('Seedance failed?', 'Wait 20s (Seedance)', 1);
  a.chain('Kling JWT + body', 'Kling · submit', 'Kling task', 'Wait 30s (Kling)', 'Kling · poll', 'Kling status', 'Kling done?');
  a.link('Kling done?', 'Kling result', 0); a.link('Kling done?', 'Wait 30s (Kling)', 1);
  a.link('Has audio for lip-sync?', 'OmniHuman · submit', 0); a.link('Has audio for lip-sync?', 'Talking without audio = b-roll', 1);
  a.link('Talking without audio = b-roll', 'Seedance · submit');
  a.chain('OmniHuman · submit', 'Omni task', 'Wait 20s (Omni)', 'OmniHuman · poll', 'Omni status', 'Omni done?');
  a.link('Omni done?', 'Talking result', 0); a.link('Omni done?', 'Wait 20s (Omni)', 1);
});

// ============================================================ WF03 Send for approval
const wf03 = wf(ID.send, 'CEFFLO CE2 · 03 · Send for Approval (Telegram)', a => {
  a.note(`## 03 · Send for approval (Telegram)
Sends the preview to the Founder with **Approve / Revise / Reject**.
Video → sendVideo (URL from render worker) + caption, claims and QA summary. Text → sendMessage.
Nothing is published without **Approve** (handled in 04).`, [-80, -320], 560, 240, 4);
  a.add('From 01 / 02 / 05', 'n8n-nodes-base.executeWorkflowTrigger', 1.1, { inputSource: 'passthrough' }, [0, 0]);
  a.code('Config', CONFIG_JS, [220, 0]);
  a.pg('Load content', `={{ "select id, type, funnel, format, world, slot, script, media_url, revisions from cefflo_ce2.content where id = '" + $('From 01 / 02 / 05').first().json.content_id + "'" }}`, [440, 0]);
  a.code('Compose preview', `const r = $json; const s = r.script || {}; const tag = '#' + r.id.slice(0, 8);
const head = (r.type === 'video' ? '🎬 VIDEO' : '✍️ THREADS') + ' · slot ' + r.slot + ' · ' + r.funnel + ' · ' + (r.format || '') + ' · ' + (r.world || '') + (r.revisions ? ' · rev ' + r.revisions : '');
const body = r.type === 'video'
  ? 'Hook: ' + (s.hook || '') + '\\n\\nTikTok: ' + (s.caption?.tiktok || '') + '\\nMeta: ' + (s.caption?.meta || '') + '\\n' + (s.hashtags || []).join(' ')
  : (s.text || '');
const claims = (s.claims || []).length ? '\\n\\nClaims: ' + s.claims.join(' | ') : '';
return [{ json: { ...r, tag, text: (head + '\\n' + tag + '\\n\\n' + body + claims).slice(0, 1000) } }];`, [660, 0]);
  a.sw('Video or text?', '={{ $json.type }}', ['video', 'text'], [880, 0]);
  a.tg('Telegram · video preview', { operation: 'sendVideo', chatId: `={{ ${cfg}.founderChatId }}`, file: '={{ $json.media_url }}',
    replyMarkup: 'inlineKeyboard', inlineKeyboard: TG_KEYBOARD('$json.id'), additionalFields: { caption: '={{ $json.text }}' } }, [1120, -80]);
  a.tg('Telegram · text preview', { chatId: `={{ ${cfg}.founderChatId }}`, text: '={{ $json.text }}',
    replyMarkup: 'inlineKeyboard', inlineKeyboard: TG_KEYBOARD('$json.id'), additionalFields: { appendAttribution: false } }, [1120, 100]);
  a.pg('Mark AWAITING_APPROVAL', `={{ "update cefflo_ce2.content set status = 'AWAITING_APPROVAL', tg_message_id = " + Number($json.result?.message_id || $json.message_id || 0) + ", updated_at = now() where id = '" + $('Compose preview').first().json.id + "'" }}`, [1360, 0]);
  a.chain('From 01 / 02 / 05', 'Config', 'Load content', 'Compose preview', 'Video or text?');
  a.link('Video or text?', 'Telegram · video preview', 0); a.link('Video or text?', 'Telegram · text preview', 1);
  a.link('Telegram · video preview', 'Mark AWAITING_APPROVAL'); a.link('Telegram · text preview', 'Mark AWAITING_APPROVAL');
});

// ============================================================ WF04 Approval inbox
const wf04 = wf(ID.inbox, 'CEFFLO CE2 · 04 · Approval Inbox (Telegram)', a => {
  a.note(`## 04 · Approval inbox
Telegram buttons + replies from the **Founder chat only** (other chats ignored).
- ✅ Approve → schedule in the next free slot (video 08:30/12:30/20:30, Threads 10:00/17:00 MYT) → 06 publishes
- ❌ Reject → REJECTED (feeds learning)
- ✏️ Revise → bot asks for a note; **reply to that message** with the note → 05 Revise (max 2 revisions)`, [-80, -360], 620, 280, 4);
  a.add('Telegram updates', 'n8n-nodes-base.telegramTrigger', 1.2, { updates: ['callback_query', 'message'], additionalFields: {} }, [0, 0],
    { credentials: CRED.tg, webhookId: 'ce2-telegram-inbox' });
  a.code('Config', CONFIG_JS, [220, 0]);
  a.code('Parse update', `const c = ${cfg}; const u = $('Telegram updates').first().json;
const cb = u.callback_query, msg = u.message;
const chat = String(cb?.message?.chat?.id ?? msg?.chat?.id ?? '');
if (chat !== String(c.founderChatId)) return [];                      // ignore everyone else
if (cb) { const [act, id] = String(cb.data || '').split('|');
  return [{ json: { action: act, content_id: id, callback_id: cb.id, chat, message_id: cb.message?.message_id } }]; }
const replied = msg?.reply_to_message?.text || '';
const m = replied.match(/REVISE #([0-9a-f-]{36})/);
if (m && msg.text) return [{ json: { action: 'note', content_id: m[1], note: msg.text.slice(0, 800), chat } }];
return [];`, [440, 0]);
  a.sw('Action', '={{ $json.action }}', ['ok', 'no', 'rv', 'note'], [660, 0]);
  a.pg('Approve + schedule', `={{ "with c as (select id, type from cefflo_ce2.content where id = '" + $json.content_id + "' and status in ('AWAITING_APPROVAL','READY','SCRIPTED')),
slots as (select (d + t::time) at time zone 'Asia/Kuala_Lumpur' as at from c,
  generate_series((now() at time zone 'Asia/Kuala_Lumpur')::date, (now() at time zone 'Asia/Kuala_Lumpur')::date + 7, interval '1 day') d,
  unnest(case when c.type = 'video' then array" + JSON.stringify(${cfg}.slots.video).replaceAll('\\"', "'") + " else array" + JSON.stringify(${cfg}.slots.text).replaceAll('\\"', "'") + " end) t),
free as (select s.at from slots s where s.at > now() + interval '10 minutes' and not exists (select 1 from cefflo_ce2.content x, c where x.scheduled_at = s.at and x.type = c.type and x.status in ('APPROVED','PUBLISHING','PUBLISHED')) order by s.at limit 1)
update cefflo_ce2.content set status = 'APPROVED', scheduled_at = (select at from free), updated_at = now() where id = (select id from c) returning id, scheduled_at" }}`, [900, -240], { alwaysOutputData: true });
  a.tg('Ack approve', { operation: 'sendMessage', chatId: `={{ $('Parse update').first().json.chat }}`,
    text: `={{ $json.scheduled_at ? '✅ Diluluskan. Dijadual: ' + DateTime.fromISO(new Date($json.scheduled_at).toISOString()).setZone('Asia/Kuala_Lumpur').toFormat('ccc d LLL, HH:mm') + ' MYT' : 'ℹ️ Content ni dah diproses sebelum ni.' }}`, additionalFields: { appendAttribution: false } }, [1120, -240]);
  a.pg('Reject', `={{ "update cefflo_ce2.content set status = 'REJECTED', updated_at = now() where id = '" + $json.content_id + "' returning id" }}`, [900, -60]);
  a.tg('Ack reject', { chatId: `={{ $('Parse update').first().json.chat }}`, text: '❌ Ditolak. Akan diambil kira dalam learning mingguan.', additionalFields: { appendAttribution: false } }, [1120, -60]);
  a.pg('Mark REVISE', `={{ "update cefflo_ce2.content set status = 'REVISE', updated_at = now() where id = '" + $json.content_id + "' and revisions < 2 returning id" }}`, [900, 120], { alwaysOutputData: true });
  a.tg('Ask for note', { chatId: `={{ $('Parse update').first().json.chat }}`,
    text: `={{ $json.id ? '✏️ REVISE #' + $json.id + '\\nBalas (reply) mesej ni dengan apa yang nak diubah.' : '⚠️ Dah 2 kali revise. Sila Approve atau Reject.' }}`,
    additionalFields: { appendAttribution: false } }, [1120, 120]);
  a.pg('Save note', `={{ "update cefflo_ce2.content set revise_note = $ce2$" + $json.note.replaceAll('$ce2$', '') + "$ce2$, revisions = revisions + 1, updated_at = now() where id = '" + $json.content_id + "' and status = 'REVISE' returning id as content_id" }}`, [900, 300]);
  a.exec('→ 05 Revise', ID.revise, [1120, 300], false);
  a.chain('Telegram updates', 'Config', 'Parse update', 'Action');
  a.link('Action', 'Approve + schedule', 0); a.link('Action', 'Reject', 1); a.link('Action', 'Mark REVISE', 2); a.link('Action', 'Save note', 3);
  a.link('Approve + schedule', 'Ack approve'); a.link('Reject', 'Ack reject'); a.link('Mark REVISE', 'Ask for note'); a.link('Save note', '→ 05 Revise');
});

// ============================================================ WF05 Revise
const wf05 = wf(ID.revise, 'CEFFLO CE2 · 05 · Revise with Founder note', a => {
  a.note(`## 05 · Revise
DeepSeek rewrites the script using the Founder's note (keeps persona + claims rules), QA once, then
video → 02 (re-render) · text → 03 (new preview). QA FAIL → HOLD + Telegram.`, [-80, -300], 560, 200, 4);
  a.add('From 04', 'n8n-nodes-base.executeWorkflowTrigger', 1.1, { inputSource: 'passthrough' }, [0, 0]);
  a.code('Config', CONFIG_JS, [220, 0]);
  a.pg('Load content', `={{ "select id, type, brief, script, revise_note from cefflo_ce2.content where id = '" + $('From 04').first().json.content_id + "'" }}`, [440, 0]);
  a.code('Build rewrite request', `const c = ${cfg}; const r = $json; const isVideo = r.type === 'video';
const sys = (isVideo ? ${JSON.stringify(PROMPTS.video)} : ${JSON.stringify(PROMPTS.text)}) + '\\n\\nPERSONA:\\n' + ${JSON.stringify(PROMPTS.persona)} + '\\n\\n' + ${JSON.stringify(PROMPTS.truth)};
return [{ json: { ...r, body: { model: c.deepseek.model, temperature: 0.7, response_format: { type: 'json_object' }, messages: [
  { role: 'system', content: sys },
  { role: 'user', content: JSON.stringify({ brief: r.brief, previous_script: r.script, founder_note: r.revise_note, instruction: 'Rewrite applying the founder note. Keep everything that the note does not ask to change.' }) }] } } }];`, [660, 0]);
  a.http('DeepSeek · rewrite', 'DeepSeek', { url: `={{ ${cfg}.deepseek.url }}`, body: deepseekBody }, [880, 0]);
  a.code('Build QA request', `const c = ${cfg}; const ctx = $('Build rewrite request').first().json; ${parseLLM}
const sys = ${JSON.stringify(PROMPTS.qa)} + '\\n\\nPERSONA:\\n' + ${JSON.stringify(PROMPTS.persona)} + '\\n\\n' + ${JSON.stringify(PROMPTS.truth)};
return [{ json: { ...ctx, script: out, body: { model: c.deepseek.model, temperature: 0.1, response_format: { type: 'json_object' },
  messages: [{ role: 'system', content: sys }, { role: 'user', content: JSON.stringify({ type: ctx.type, script: out }) }] } } }];`, [1100, 0]);
  a.http('DeepSeek · QA', 'DeepSeek', { url: `={{ ${cfg}.deepseek.url }}`, body: deepseekBody }, [1320, 0]);
  a.code('Evaluate + SQL', `${SQL_HELPER} const ctx = $('Build QA request').first().json; ${parseLLM}
const pass = out.verdict === 'PASS';
return [{ json: { content_id: ctx.id, type: ctx.type, pass, findings: out.findings || [], sql: \`update cefflo_ce2.content set script = \${q(ctx.script)}::jsonb, qa = \${q(out)}::jsonb,
  status = '\${pass ? 'SCRIPTED' : 'HOLD'}', media_url = case when '\${ctx.type}' = 'video' then null else media_url end, updated_at = now() where id = '\${ctx.id}'\` } }];`, [1540, 0]);
  a.pg('Save revision', '={{ $json.sql }}', [1760, 0]);
  a.code('Carry', `return [{ json: $('Evaluate + SQL').first().json }];`, [1980, 0]);
  a.iff('QA pass?', '={{ $json.pass }}', [2200, 0]);
  a.sw('Video or text?', '={{ $json.type }}', ['video', 'text'], [2420, -80]);
  a.exec('→ 02 Video Production', ID.video, [2660, -160], false);
  a.exec('→ 03 Send for approval', ID.send, [2660, 0], false);
  a.tg('Notify HOLD', { chatId: `={{ ${cfg}.founderChatId }}`, text: `=⚠️ Revise gagal QA — content #{{ $json.content_id }} kini HOLD.\n{{ $json.findings.map(f => '• ' + f.criterion + ': ' + f.evidence).join('\\n').slice(0, 900) }}`, additionalFields: { appendAttribution: false } }, [2420, 160]);
  a.chain('From 04', 'Config', 'Load content', 'Build rewrite request', 'DeepSeek · rewrite', 'Build QA request', 'DeepSeek · QA', 'Evaluate + SQL', 'Save revision', 'Carry', 'QA pass?');
  a.link('QA pass?', 'Video or text?', 0); a.link('QA pass?', 'Notify HOLD', 1);
  a.link('Video or text?', '→ 02 Video Production', 0); a.link('Video or text?', '→ 03 Send for approval', 1);
});

// ============================================================ WF06 Publisher
const wf06 = wf(ID.publish, 'CEFFLO CE2 · 06 · Publisher (TikTok · FB Reels · IG Reels · Threads)', a => {
  a.note(`## 06 · Publisher  (M6)
Every 10 min: APPROVED items whose slot is due.
- **Video** → TikTok (Content Posting API, PULL_FROM_URL, \`is_aigc: true\`) · IG Reels (container → poll → publish) · FB Reels (start → hosted file → finish)
- **Text** → Threads (create → publish)
Each platform is recorded in \`publication\`; one platform failing does not block the others.
⚠️ TikTok: app audit required before PUBLIC posting (until then \`privacy: SELF_ONLY\`), and the video URL domain must be verified in TikTok.
⚠️ Meta: Instagram/Facebook publishing permissions need Meta app review. Add the platform **AI label** where the API cannot.`, [-80, -440], 680, 320, 4);
  a.add('Every 10 min', 'n8n-nodes-base.scheduleTrigger', 1.2, { rule: { interval: [{ field: 'minutes', minutesInterval: 10 }] } }, [0, 0]);
  a.code('Config', CONFIG_JS, [200, 0]);
  a.pg('Claim due items', `update cefflo_ce2.content set status = 'PUBLISHING', updated_at = now()
where id in (select id from cefflo_ce2.content where status = 'APPROVED' and scheduled_at <= now() order by scheduled_at limit 3 for update skip locked)
returning id, type, script, media_url`, [400, 0]);
  a.sw('Video or text?', '={{ $json.type }}', ['video', 'text'], [600, 0]);
  // TikTok
  a.http('TikTok · init (pull URL)', 'TikTok', { url: `={{ ${cfg}.tiktok.initUrl }}`, body: `={{ JSON.stringify({ post_info: { title: (($json.script.caption?.tiktok || '') + ' ' + ($json.script.hashtags || []).join(' ')).slice(0, 2100), privacy_level: ${cfg}.tiktok.privacy, disable_comment: false, is_aigc: true }, source_info: { source: 'PULL_FROM_URL', video_url: $json.media_url } }) }}` }, [860, -300], { onError: 'continueRegularOutput' });
  a.code('Record TikTok', `${SQL_HELPER} const it = $('Claim due items').item.json; const r = $json; const ok = !!r.data?.publish_id;
return [{ json: { content_id: it.id, sql: \`insert into cefflo_ce2.publication (content_id, platform, platform_post_id, status, error, published_at) values ('\${it.id}', 'tiktok', \${q(r.data?.publish_id)}, '\${ok ? 'SENT' : 'FAILED'}', \${q(ok ? null : (r.error?.message || r.message || 'unknown'))}, now()) on conflict (content_id, platform) do update set status = excluded.status, error = excluded.error, platform_post_id = excluded.platform_post_id\` } }];`, [1080, -300], {}, );
  a.pg('DB · TikTok', '={{ $json.sql }}', [1300, -300]);
  // Instagram
  a.http('IG · create Reels container', 'Meta', { url: `={{ ${cfg}.meta.graph + '/' + ${cfg}.meta.igUserId + '/media' }}`, body: `={{ JSON.stringify({ media_type: 'REELS', video_url: $json.media_url, caption: (($json.script.caption?.meta || '') + '\\n' + ($json.script.hashtags || []).join(' ')).slice(0, 2200), share_to_feed: true }) }}` }, [860, -120], { onError: 'continueRegularOutput' });
  a.wait('Wait 60s (IG processing)', 60, [1080, -120]);
  a.http('IG · status', 'Meta', { method: 'GET', url: `={{ ${cfg}.meta.graph + '/' + $('IG · create Reels container').item.json.id + '?fields=status_code' }}` }, [1300, -120], { onError: 'continueRegularOutput' });
  a.http('IG · publish', 'Meta', { url: `={{ ${cfg}.meta.graph + '/' + ${cfg}.meta.igUserId + '/media_publish' }}`, body: `={{ JSON.stringify({ creation_id: $('IG · create Reels container').item.json.id }) }}` }, [1520, -120], { onError: 'continueRegularOutput' });
  a.code('Record IG', `${SQL_HELPER} const it = $('Claim due items').item.json; const r = $json; const ok = !!r.id;
return [{ json: { sql: \`insert into cefflo_ce2.publication (content_id, platform, platform_post_id, status, error, published_at) values ('\${it.id}', 'instagram', \${q(r.id)}, '\${ok ? 'PUBLISHED' : 'FAILED'}', \${q(ok ? null : (r.error?.message || 'unknown'))}, now()) on conflict (content_id, platform) do update set status = excluded.status, error = excluded.error, platform_post_id = excluded.platform_post_id\` } }];`, [1740, -120]);
  a.pg('DB · IG', '={{ $json.sql }}', [1960, -120]);
  // Facebook Reels
  a.http('FB Reels · start', 'Meta', { url: `={{ ${cfg}.meta.graph + '/' + ${cfg}.meta.pageId + '/video_reels' }}`, body: '={{ JSON.stringify({ upload_phase: "start" }) }}' }, [860, 60], { onError: 'continueRegularOutput' });
  a.http('FB Reels · upload hosted file', 'Meta', { url: '={{ $json.upload_url || ("https://rupload.facebook.com/video-upload/v23.0/" + $json.video_id) }}', headers: `={{ JSON.stringify({ file_url: $('Claim due items').item.json.media_url }) }}` }, [1080, 60], { onError: 'continueRegularOutput' });
  a.http('FB Reels · finish', 'Meta', { url: `={{ ${cfg}.meta.graph + '/' + ${cfg}.meta.pageId + '/video_reels' }}`, body: `={{ JSON.stringify({ upload_phase: 'finish', video_id: $('FB Reels · start').item.json.video_id, video_state: 'PUBLISHED', description: (($('Claim due items').item.json.script.caption?.meta || '') + '\\n' + ($('Claim due items').item.json.script.hashtags || []).join(' ')).slice(0, 2200) }) }}` }, [1300, 60], { onError: 'continueRegularOutput' });
  a.code('Record FB', `${SQL_HELPER} const it = $('Claim due items').item.json; const vid = $('FB Reels · start').item.json.video_id; const ok = !!$json.success;
return [{ json: { sql: \`insert into cefflo_ce2.publication (content_id, platform, platform_post_id, status, error, published_at) values ('\${it.id}', 'facebook', \${q(vid)}, '\${ok ? 'PUBLISHED' : 'FAILED'}', \${q(ok ? null : ($json.error?.message || 'unknown'))}, now()) on conflict (content_id, platform) do update set status = excluded.status, error = excluded.error, platform_post_id = excluded.platform_post_id\` } }];`, [1520, 60]);
  a.pg('DB · FB', '={{ $json.sql }}', [1740, 60]);
  // Threads
  a.http('Threads · create', 'Threads', { url: `={{ ${cfg}.threads.graph + '/' + ${cfg}.threads.userId + '/threads' }}`, body: '={{ JSON.stringify({ media_type: "TEXT", text: $json.script.text }) }}' }, [860, 260], { onError: 'continueRegularOutput' });
  a.wait('Wait 30s (Threads)', 30, [1080, 260]);
  a.http('Threads · publish', 'Threads', { url: `={{ ${cfg}.threads.graph + '/' + ${cfg}.threads.userId + '/threads_publish' }}`, body: `={{ JSON.stringify({ creation_id: $('Threads · create').item.json.id }) }}` }, [1300, 260], { onError: 'continueRegularOutput' });
  a.code('Record Threads', `${SQL_HELPER} const it = $('Claim due items').item.json; const ok = !!$json.id;
return [{ json: { sql: \`insert into cefflo_ce2.publication (content_id, platform, platform_post_id, status, error, published_at) values ('\${it.id}', 'threads', \${q($json.id)}, '\${ok ? 'PUBLISHED' : 'FAILED'}', \${q(ok ? null : ($json.error?.message || 'unknown'))}, now()) on conflict (content_id, platform) do update set status = excluded.status, error = excluded.error, platform_post_id = excluded.platform_post_id\` } }];`, [1520, 260]);
  a.pg('DB · Threads', '={{ $json.sql }}', [1740, 260]);
  // close + report
  a.wait('Settle 2 min', 120, [2180, 0]);
  a.pg('Close + summary', `with done as (update cefflo_ce2.content c set status = case when exists (select 1 from cefflo_ce2.publication p where p.content_id = c.id and p.status in ('PUBLISHED','SENT')) then 'PUBLISHED' else 'FAILED' end, updated_at = now()
  where c.status = 'PUBLISHING' and c.updated_at < now() - interval '90 seconds' returning c.id, c.type, c.status)
select d.id, d.type, d.status, coalesce(string_agg(p.platform || ':' || p.status || coalesce(' (' || left(p.error, 80) || ')', ''), ', '), '') as platforms
from done d left join cefflo_ce2.publication p on p.content_id = d.id group by d.id, d.type, d.status`, [2400, 0]);
  a.tg('Report', { chatId: `={{ ${cfg}.founderChatId }}`, text: `={{ ($json.status === 'PUBLISHED' ? '📣 Disiarkan' : '⚠️ Gagal siar') + ' #' + $json.id.slice(0, 8) + ' (' + $json.type + ')\\n' + $json.platforms }}`, additionalFields: { appendAttribution: false } }, [2620, 0]);
  a.chain('Every 10 min', 'Config', 'Claim due items', 'Video or text?');
  a.link('Video or text?', 'TikTok · init (pull URL)', 0); a.link('Video or text?', 'IG · create Reels container', 0); a.link('Video or text?', 'FB Reels · start', 0);
  a.link('Video or text?', 'Threads · create', 1);
  a.chain('TikTok · init (pull URL)', 'Record TikTok', 'DB · TikTok');
  a.chain('IG · create Reels container', 'Wait 60s (IG processing)', 'IG · status', 'IG · publish', 'Record IG', 'DB · IG');
  a.chain('FB Reels · start', 'FB Reels · upload hosted file', 'FB Reels · finish', 'Record FB', 'DB · FB');
  a.chain('Threads · create', 'Wait 30s (Threads)', 'Threads · publish', 'Record Threads', 'DB · Threads');
  for (const n of ['DB · TikTok', 'DB · IG', 'DB · FB', 'DB · Threads']) a.link(n, 'Settle 2 min');
  a.chain('Settle 2 min', 'Close + summary', 'Report');
});

// ============================================================ WF07 Metrics + learning
const wf07 = wf(ID.learn, 'CEFFLO CE2 · 07 · Metrics + Weekly Learning + Recycle', a => {
  a.note(`## 07 · Metrics + Learning + Recycle  (M6 → M1)
**Hourly**: collect metrics at +24h / +72h / +7d per platform → \`metric\`.
**Sunday 21:00 MYT**: score last 14 days (3s hold, completion, shares, saves, comments, clicks; views alone never qualify),
DeepSeek writes evidence-backed learnings (confidence LOW/MEDIUM/HIGH, never "universal" from one post),
marks top performers as **recycle candidates** (01 remixes max 1 per day with a new hook + world/format),
and sends the weekly report + cost to Telegram.`, [-80, -440], 680, 300, 4);
  a.add('Every hour', 'n8n-nodes-base.scheduleTrigger', 1.2, { rule: { interval: [{ field: 'hours', hoursInterval: 1 }] } }, [0, 0]);
  a.code('Config', CONFIG_JS, [200, 0]);
  a.pg('Due checkpoints', `select p.id as publication_id, p.platform, p.platform_post_id, cp.checkpoint
from cefflo_ce2.publication p
cross join (values ('24h', interval '24 hours'), ('72h', interval '72 hours'), ('7d', interval '7 days')) as cp(checkpoint, after)
where p.status in ('PUBLISHED','SENT') and p.platform_post_id is not null and p.published_at + cp.after <= now()
  and not exists (select 1 from cefflo_ce2.metric m where m.publication_id = p.id and m.checkpoint = cp.checkpoint)
limit 40`, [400, 0]);
  a.sw('Platform', '={{ $json.platform }}', ['instagram', 'facebook', 'threads', 'tiktok'], [600, 0]);
  a.http('IG insights', 'Meta', { method: 'GET', url: `={{ ${cfg}.meta.graph + '/' + $json.platform_post_id + '/insights?metric=views,reach,likes,comments,shares,saved,ig_reels_avg_watch_time' }}` }, [840, -240], { onError: 'continueRegularOutput' });
  a.http('FB video insights', 'Meta', { method: 'GET', url: `={{ ${cfg}.meta.graph + '/' + $json.platform_post_id + '/video_insights' }}` }, [840, -80], { onError: 'continueRegularOutput' });
  a.http('Threads insights', 'Threads', { method: 'GET', url: `={{ ${cfg}.threads.graph + '/' + $json.platform_post_id + '/insights?metric=views,likes,replies,reposts,quotes,shares' }}` }, [840, 80], { onError: 'continueRegularOutput' });
  a.http('TikTok status → video id', 'TikTok', { url: 'https://open.tiktokapis.com/v2/post/publish/status/fetch/', body: '={{ JSON.stringify({ publish_id: $json.platform_post_id }) }}' }, [840, 240], { onError: 'continueRegularOutput' });
  a.http('TikTok video query', 'TikTok', { url: 'https://open.tiktokapis.com/v2/video/query/?fields=id,view_count,like_count,comment_count,share_count', body: '={{ JSON.stringify({ filters: { video_ids: [ ($json.data?.publicaly_available_post_id || [])[0] ].filter(Boolean) } }) }}' }, [1060, 240], { onError: 'continueRegularOutput' });
  a.code('Normalize metrics', `${SQL_HELPER}
const src = $('Due checkpoints').item.json; const r = $json; const m = {};
const pick = (arr) => (arr || []).forEach(x => { m[x.name] = x.values?.[0]?.value ?? x.total_value?.value ?? x.value; });
if (src.platform === 'instagram' || src.platform === 'threads' || src.platform === 'facebook') pick(r.data);
const v = r.data?.videos?.[0]; if (v) Object.assign(m, { views: v.view_count, likes: v.like_count, comments: v.comment_count, shares: v.share_count });
const n = x => x === undefined || x === null || isNaN(Number(x)) ? 'null' : Number(x);
return [{ json: { sql: \`insert into cefflo_ce2.metric (publication_id, checkpoint, views, reach, avg_watch_s, likes, comments, shares, saves, raw)
values ('\${src.publication_id}', '\${src.checkpoint}', \${n(m.views ?? m.total_video_views ?? m.blue_reels_play_count)}, \${n(m.reach ?? m.total_video_impressions_unique)}, \${n(m.ig_reels_avg_watch_time ? m.ig_reels_avg_watch_time / 1000 : m.total_video_avg_time_watched ? m.total_video_avg_time_watched / 1000 : null)},
  \${n(m.likes ?? m.total_video_reactions_by_type_total)}, \${n(m.comments ?? m.replies)}, \${n(m.shares ?? m.reposts)}, \${n(m.saved)}, \${q(r)}::jsonb)
on conflict (publication_id, checkpoint) do nothing\` } }];`, [1300, 0], 'runOnceForEachItem');
  a.pg('Save metric', '={{ $json.sql }}', [1520, 0]);
  a.chain('Every hour', 'Config', 'Due checkpoints', 'Platform');
  a.link('Platform', 'IG insights', 0); a.link('Platform', 'FB video insights', 1); a.link('Platform', 'Threads insights', 2); a.link('Platform', 'TikTok status → video id', 3);
  a.link('TikTok status → video id', 'TikTok video query');
  for (const n of ['IG insights', 'FB video insights', 'Threads insights', 'TikTok video query']) a.link(n, 'Normalize metrics');
  a.link('Normalize metrics', 'Save metric');

  // weekly learning
  a.add('Sunday 21:00', 'n8n-nodes-base.scheduleTrigger', 1.2, { rule: { interval: [{ field: 'cronExpression', expression: '0 21 * * 0' }] } }, [0, 520]);
  a.code('Config (weekly)', CONFIG_JS, [200, 520]);
  a.pg('Last 14 days performance', `select c.id, c.type, c.funnel, c.format, c.world, c.pain, c.hook, c.status, c.recycle_of,
  jsonb_object_agg(p.platform, jsonb_build_object('views', m.views, 'avg_watch_s', m.avg_watch_s, 'likes', m.likes, 'comments', m.comments, 'shares', m.shares, 'saves', m.saves)) filter (where p.platform is not null) as metrics_72h
from cefflo_ce2.content c
left join cefflo_ce2.publication p on p.content_id = c.id
left join cefflo_ce2.metric m on m.publication_id = p.id and m.checkpoint = '72h'
where c.created_at > now() - interval '14 days' group by c.id order by c.created_at`, [400, 520]);
  a.code('Build learning request', `const c = $('Config (weekly)').first().json.config; const rows = $input.all().map(i => i.json);
const sys = 'You are M6 GROWTH learning analyst for CEFFLO. From the rows, find evidence-backed patterns (hooks, formats, worlds, funnel, pains) using engagement quality (avg watch, shares, saves, comments) more than views. Never declare a universal rule from one post; give confidence LOW/MEDIUM/HIGH. Also pick up to 5 content ids worth remixing (score 0-100) and up to 5 to stop. Include REJECTED items as negative evidence. Return ONLY JSON: {"learnings":[{"observation":"...","confidence":"LOW|MEDIUM|HIGH","action":"...","evidence":["content ids"]}],"recycle":[{"content_id":"...","score":0,"reason":"..."}],"retire":["content ids"],"report_ms":"short Malay summary for the Founder (max 8 lines)"}';
return [{ json: { rows: rows.length, body: { model: c.deepseek.model, temperature: 0.2, response_format: { type: 'json_object' }, messages: [{ role: 'system', content: sys }, { role: 'user', content: JSON.stringify(rows) }] } } }];`, [600, 520]);
  a.http('DeepSeek · learn', 'DeepSeek', { url: `={{ $('Config (weekly)').first().json.config.deepseek.url }}`, body: deepseekBody }, [820, 520]);
  a.code('Save learnings SQL', `${SQL_HELPER} ${parseLLM}
const week = $now.setZone('Asia/Kuala_Lumpur').startOf('week').toISODate();
const s = [];
for (const l of out.learnings || []) s.push(\`insert into cefflo_ce2.learning (week, observation, confidence, action, evidence) values ('\${week}', \${q(l.observation)}, \${q(['LOW','MEDIUM','HIGH'].includes(l.confidence) ? l.confidence : 'LOW')}, \${q(l.action)}, \${q(l.evidence || [])}::jsonb)\`);
for (const r of out.recycle || []) if (/^[0-9a-f-]{36}$/.test(r.content_id)) s.push(\`insert into cefflo_ce2.recycle_candidate (content_id, score, reason) values ('\${r.content_id}', \${Number(r.score) || 0}, \${q(r.reason)}) on conflict (content_id) do update set score = excluded.score, reason = excluded.reason\`);
for (const id of out.retire || []) if (/^[0-9a-f-]{36}$/.test(id)) s.push(\`update cefflo_ce2.recycle_candidate set used = true where content_id = '\${id}'\`);
s.push("select coalesce(sum(usd),0) as cost_week from cefflo_ce2.cost where created_at > now() - interval '7 days'");
return [{ json: { sql: s.join(';\\n'), report: out.report_ms || '' } }];`, [1040, 520]);
  a.pg('Save learnings', '={{ $json.sql }}', [1260, 520]);
  a.tg('Weekly report', { chatId: `={{ $('Config (weekly)').first().json.config.founderChatId }}`, text: `={{ '📊 Laporan mingguan CE2\\n\\n' + $('Save learnings SQL').first().json.report + '\\n\\nKos 7 hari: USD ' + Number($json.cost_week || 0).toFixed(2) }}`, additionalFields: { appendAttribution: false } }, [1480, 520]);
  a.chain('Sunday 21:00', 'Config (weekly)', 'Last 14 days performance', 'Build learning request', 'DeepSeek · learn', 'Save learnings SQL', 'Save learnings', 'Weekly report');
});

// ============================================================ WF99 Error
const wf99 = wf(ID.error, 'CEFFLO CE2 · 99 · Error Alert', a => {
  a.note(`## 99 · Error alert
Any CE2 workflow error → Telegram with workflow, node and message.
If a content row was in PRODUCING it is set to PRODUCE_FAIL (re-run from Telegram later).`, [-80, -260], 520, 180, 4);
  a.add('On error', 'n8n-nodes-base.errorTrigger', 1, {}, [0, 0]);
  a.code('Config', CONFIG_JS, [200, 0]);
  a.pg('Fail stuck production', `update cefflo_ce2.content set status = 'PRODUCE_FAIL', updated_at = now() where status = 'PRODUCING' and updated_at < now() - interval '45 minutes' returning id`, [400, 0], { alwaysOutputData: true });
  a.tg('Alert', { chatId: `={{ ${cfg}.founderChatId }}`, text: `={{ '🚨 CE2 error\\nWorkflow: ' + $('On error').first().json.workflow.name + '\\nNode: ' + ($('On error').first().json.execution?.lastNodeExecuted || '-') + '\\n' + String($('On error').first().json.execution?.error?.message || '').slice(0, 600) + '\\n' + ($('On error').first().json.execution?.url || '') }}`, additionalFields: { appendAttribution: false } }, [600, 0]);
  a.chain('On error', 'Config', 'Fail stuck production', 'Alert');
});

// ------------------------------------------------------------- write
const out = join(root, 'workflows');
mkdirSync(out, { recursive: true });
const all = [wf01, wf02, wf02b, wf03, wf04, wf05, wf06, wf07, wf99];
for (const w of all) {
  // structural self-check: every connection points to an existing node
  const names = new Set(w.nodes.map(n => n.name));
  if (names.size !== w.nodes.length) throw new Error(`${w.name}: duplicate node names`);
  for (const [from, c] of Object.entries(w.connections)) {
    if (!names.has(from)) throw new Error(`${w.name}: unknown source ${from}`);
    for (const out of c.main) for (const l of out) if (!names.has(l.node)) throw new Error(`${w.name}: unknown target ${l.node}`);
  }
  const file = w.name.replace(/^CEFFLO CE2 · /, '').replace(/[^\w]+/g, '_').replace(/_+$/, '') + '.json';
  writeFileSync(join(out, file), JSON.stringify(w, null, 2) + '\n');
  console.log(`${file}  (${w.nodes.length} nodes)`);
}
writeFileSync(join(out, 'ALL_WORKFLOWS.json'), JSON.stringify(all, null, 2) + '\n');
console.log('ALL_WORKFLOWS.json');
