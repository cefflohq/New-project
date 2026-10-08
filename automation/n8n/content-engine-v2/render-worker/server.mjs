// CEFFLO CE2 render worker: assembles shots into a TikTok/Reels-ready "phone look" MP4.
//   RENDER_TOKEN=... PUBLIC_BASE=https://render.cefflo.com PORT=8787 FONT_DIR=/usr/share/fonts/... FONT_NAME='Liberation Sans' node server.mjs
// Endpoints (Authorization: Bearer RENDER_TOKEN, except GET /files/*):
//   POST /upload?ext=mp3   raw body → { url }
//   POST /render           manifest JSON (from n8n 02) → { url, duration }
//   GET  /files/<name>     public files (TikTok/Meta pull the final video from here)
import { createServer } from 'node:http';
import { createReadStream, existsSync, mkdirSync, statSync } from 'node:fs';
import { writeFile, rm } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import { randomBytes } from 'node:crypto';
import { join, extname } from 'node:path';

const PORT = Number(process.env.PORT || 8787);
const TOKEN = process.env.RENDER_TOKEN;
const BASE = (process.env.PUBLIC_BASE || `http://localhost:${PORT}`).replace(/\/$/, '');
const FILES = process.env.FILES_DIR || join(process.cwd(), 'files');
const FFMPEG = process.env.FFMPEG || 'ffmpeg';
const FONT_DIR = process.env.FONT_DIR || '/usr/share/fonts/truetype/liberation';
const FONT_NAME = process.env.FONT_NAME || 'Liberation Sans';
if (!TOKEN) throw new Error('RENDER_TOKEN is required');
mkdirSync(join(FILES, 'screens'), { recursive: true });

const id = () => randomBytes(12).toString('hex');
const json = (res, code, body) => { res.writeHead(code, { 'content-type': 'application/json' }); res.end(JSON.stringify(body)); };
const readBody = (req, limit = 50 * 1024 * 1024) => new Promise((ok, bad) => {
  const chunks = []; let n = 0;
  req.on('data', c => { n += c.length; if (n > limit) { bad(new Error('too large')); req.destroy(); } else chunks.push(c); });
  req.on('end', () => ok(Buffer.concat(chunks))); req.on('error', bad);
});
const run = args => new Promise((ok, bad) => {
  const p = spawn(FFMPEG, ['-y', '-hide_banner', '-loglevel', 'error', ...args]); let err = '';
  p.stderr.on('data', d => { err += d; }); p.on('close', c => (c === 0 ? ok() : bad(new Error(err.slice(-800)))));
});
async function fetchTo(url, path) {
  const r = await fetch(url); if (!r.ok) throw new Error(`download ${r.status} ${url}`);
  await writeFile(path, Buffer.from(await r.arrayBuffer()));
}
// Break a subtitle into ≤ 2 lines of ~26 chars.
function wrap(t, max = 26) {
  const words = String(t || '').split(/\s+/).filter(Boolean); const lines = ['']; for (const w of words) {
    if ((lines.at(-1) + ' ' + w).trim().length > max && lines.at(-1)) lines.push(w); else lines[lines.length - 1] = (lines.at(-1) + ' ' + w).trim();
  } return lines.slice(0, 2).join('\n');
}

// Phone look: soft (not over-sharp) picture, light grain, micro handheld shake, mild WB drift, vignette.
const PHONE_LOOK = [
  'scale=1188:2112:force_original_aspect_ratio=increase', 'crop=1188:2112',
  "crop=1080:1920:'54+8*sin(t*1.7)+5*sin(t*4.3)':'96+8*cos(t*1.3)+4*sin(t*3.1)'",
  'unsharp=5:5:-0.35:5:5:0', 'eq=saturation=0.94:contrast=0.98:gamma=1.02',
  'colorbalance=rs=0.02:bs=-0.015', 'noise=alls=7:allf=t', 'vignette=PI/5', 'fps=30', 'format=yuv420p',
].join(',');

async function render(m) {
  const work = join(FILES, 'tmp-' + id()); mkdirSync(work, { recursive: true });
  try {
    const parts = [];
    for (const [i, s] of m.shots.entries()) {
      const v = join(work, `v${i}${extname(new URL(s.video_url).pathname) || '.mp4'}`); await fetchTo(s.video_url, v);
      const a = s.audio_url ? join(work, `a${i}.mp3`) : null; if (a) await fetchTo(s.audio_url, a);
      const dur = Math.max(1.5, Number(s.seconds) || 4);
      const sub = wrap(s.subtitle);
      let draw = '';
      if (sub) { // TikTok-style caption via libass (bold white, black outline, lower third)
        const ass = join(work, `s${i}.ass`);
        await writeFile(ass, `[Script Info]\nScriptType: v4.00+\nPlayResX: 1080\nPlayResY: 1920\n\n[V4+ Styles]\nFormat: Name, Fontname, Fontsize, PrimaryColour, OutlineColour, BackColour, Bold, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV\nStyle: Cap,${FONT_NAME},64,&H00FFFFFF,&H00000000,&H64000000,-1,1,5,1,2,80,80,520\n\n[Events]\nFormat: Layer, Start, End, Style, Text\nDialogue: 0,0:00:00.10,0:01:00.00,Cap,${sub.replace(/\n/g, '\\N')}\n`);
        draw = `,subtitles='${ass}':fontsdir='${FONT_DIR}'`;
      }
      const out = join(work, `p${i}.mp4`);
      // Each part: video looped/trimmed to the line length; its own VO (or silence) as audio.
      await run(['-stream_loop', '-1', '-i', v, ...(a ? ['-i', a] : ['-f', 'lavfi', '-i', 'anullsrc=r=44100:cl=mono']),
        '-t', String(a ? dur + 0.25 : dur), '-filter_complex', `[0:v]${PHONE_LOOK}${draw}[v];[1:a]aresample=44100,apad[a]`,
        '-map', '[v]', '-map', '[a]', '-shortest', '-c:v', 'libx264', '-preset', 'medium', '-b:v', '7M', '-maxrate', '8M', '-bufsize', '12M',
        '-c:a', 'aac', '-b:a', '128k', '-ac', '1', out]);
      parts.push(out);
    }
    const list = join(work, 'list.txt'); await writeFile(list, parts.map(p => `file '${p}'`).join('\n'));
    const name = `${m.content_id || 'video'}-${id()}.mp4`; const final = join(FILES, name);
    const tone = m.room_tone !== false ? 'anoisesrc=color=brown:amplitude=0.012:r=44100' : 'anullsrc=r=44100:cl=mono';
    const music = m.music?.url ? join(work, 'music.mp3') : null; if (music) await fetchTo(m.music.url, music);
    const inputs = ['-f', 'concat', '-safe', '0', '-i', list, '-f', 'lavfi', '-i', tone, ...(music ? ['-stream_loop', '-1', '-i', music] : [])];
    const mix = music
      ? `[2:a]volume=${Math.pow(10, (m.music.gain_db ?? -22) / 20)}[m];[0:a][1:a][m]amix=inputs=3:duration=first:normalize=0,highpass=f=80,acompressor=threshold=-20dB:ratio=3,loudnorm=I=-14:TP=-1.5:LRA=11,aresample=44100[a]`
      : '[0:a][1:a]amix=inputs=2:duration=first:normalize=0,highpass=f=80,acompressor=threshold=-20dB:ratio=3,loudnorm=I=-14:TP=-1.5:LRA=11,aresample=44100[a]';
    await run([...inputs, '-filter_complex', mix, '-map', '0:v', '-map', '[a]', '-c:v', 'copy', '-c:a', 'aac', '-b:a', '160k', '-movflags', '+faststart', final]);
    const duration = await new Promise(ok => { const p = spawn(FFMPEG, ['-i', final]); let e = ''; p.stderr.on('data', d => { e += d; }); p.on('close', () => { const mm = e.match(/Duration: (\d+):(\d+):([\d.]+)/); ok(mm ? (+mm[1]) * 3600 + (+mm[2]) * 60 + (+mm[3]) : 0); }); });
    return { url: `${BASE}/files/${name}`, duration };
  } finally { await rm(work, { recursive: true, force: true }); }
}

createServer(async (req, res) => {
  try {
    const url = new URL(req.url, BASE);
    if (req.method === 'GET' && url.pathname.startsWith('/files/')) {
      const p = join(FILES, decodeURIComponent(url.pathname.slice(7)).replace(/\.\.+/g, ''));
      if (!p.startsWith(FILES) || !existsSync(p) || p.includes('/tmp-')) return json(res, 404, { error: 'not found' });
      const type = { '.mp4': 'video/mp4', '.mp3': 'audio/mpeg', '.png': 'image/png', '.jpg': 'image/jpeg' }[extname(p)] || 'application/octet-stream';
      res.writeHead(200, { 'content-type': type, 'content-length': statSync(p).size }); return createReadStream(p).pipe(res);
    }
    if (req.headers.authorization !== `Bearer ${TOKEN}`) return json(res, 401, { error: 'unauthorized' });
    if (req.method === 'POST' && url.pathname === '/upload') {
      const ext = (url.searchParams.get('ext') || 'bin').replace(/\W/g, '').slice(0, 5);
      const name = `up-${id()}.${ext}`; await writeFile(join(FILES, name), await readBody(req));
      return json(res, 200, { url: `${BASE}/files/${name}` });
    }
    if (req.method === 'POST' && url.pathname === '/render') {
      const m = JSON.parse((await readBody(req, 1024 * 1024)).toString());
      if (!Array.isArray(m.shots) || !m.shots.length) return json(res, 400, { error: 'no shots' });
      return json(res, 200, await render(m));
    }
    json(res, 404, { error: 'not found' });
  } catch (e) { json(res, 500, { error: String(e.message || e).slice(0, 500) }); }
}).listen(PORT, () => console.log(`render worker on :${PORT}, public ${BASE}`));
