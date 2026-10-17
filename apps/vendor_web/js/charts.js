// Small SVG charts for the dashboard (no library): a line chart with a hover
// tooltip, horizontal bars and a donut. Colours come from the caller.
import { esc } from './ui.js';

// series: [{ name, color, dashed, values: [n…] }], labels: [str…]
export function lineChart({ labels, series, height = 220, width = 640 }) {
  const W = Math.max(280, Math.round(width)), H = height, L = 32, R = 8, T = 12, B = 26;
  const max = Math.max(4, ...series.flatMap(s => s.values));
  const step = Math.ceil(max / 4);
  const top = step * 4;
  const x = i => L + (labels.length < 2 ? 0 : (i * (W - L - R)) / (labels.length - 1));
  const y = v => T + (H - T - B) * (1 - v / top);
  const grid = [0, 1, 2, 3, 4].map(k => `<line x1="${L}" x2="${W - R}" y1="${y(k * step)}" y2="${y(k * step)}" class="cg"/><text x="${L - 8}" y="${y(k * step) + 4}" text-anchor="end" class="ct">${k * step}</text>`).join('');
  const every = Math.ceil(labels.length / 7);
  const xl = labels.map((l, i) => (i % every === 0 || i === labels.length - 1) ? `<text x="${x(i)}" y="${H - 6}" text-anchor="middle" class="ct">${esc(l)}</text>` : '').join('');
  const lines = series.map(s => {
    const d = s.values.map((v, i) => `${i ? 'L' : 'M'}${x(i).toFixed(1)} ${y(v).toFixed(1)}`).join(' ');
    const area = s.fill ? `<path d="${d} L${x(s.values.length - 1)} ${y(0)} L${x(0)} ${y(0)} Z" fill="url(#cf-${s.key})"/>` : '';
    return `${s.fill ? `<defs><linearGradient id="cf-${s.key}" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="${s.color}" stop-opacity=".18"/><stop offset="1" stop-color="${s.color}" stop-opacity="0"/></linearGradient></defs>` : ''}${area}<path d="${d}" fill="none" stroke="${s.color}" stroke-width="2.4" stroke-linejoin="round" stroke-linecap="round" ${s.dashed ? 'stroke-dasharray="6 6"' : ''}/>`;
  }).join('');
  const hits = labels.map((l, i) => `<rect x="${x(i) - (W - L - R) / labels.length / 2}" y="${T}" width="${(W - L - R) / labels.length}" height="${H - T - B}" fill="transparent" data-i="${i}"/>`).join('');
  return `<div class="chart" data-chart='${esc(JSON.stringify({ labels, series: series.map(s => ({ name: s.name, color: s.color, values: s.values })) }))}'>
    <svg viewBox="0 0 ${W} ${H}" role="img" data-w="${W}" aria-label="${esc(series.map(s => s.name).join(', '))}">${grid}${xl}${lines}<line class="cx" y1="${T}" y2="${H - B}" x1="-10" x2="-10"/>${series.map((s, k) => `<circle class="cd" data-k="${k}" r="4.5" cx="-10" cy="-10" fill="#fff" stroke="${s.color}" stroke-width="2.4"/>`).join('')}${hits}</svg>
    <div class="ctip" hidden></div></div>`;
}

export function wireCharts(root) {
  root.querySelectorAll('.chart').forEach(c => {
    const data = JSON.parse(c.dataset.chart); const svg = c.querySelector('svg'); const tip = c.querySelector('.ctip');
    const W = Number(svg.dataset.w) || 640, L = 32, R = 8;
    c.addEventListener('pointermove', e => {
      const r = e.target.closest('rect[data-i]'); if (!r) return;
      const i = Number(r.dataset.i); const xi = L + (data.labels.length < 2 ? 0 : (i * (W - L - R)) / (data.labels.length - 1));
      const line = svg.querySelector('.cx'); line.setAttribute('x1', xi); line.setAttribute('x2', xi);
      const box = svg.viewBox.baseVal; const H = box.height, T = 12, B = 26;
      const top = Math.ceil(Math.max(4, ...data.series.flatMap(s => s.values)) / 4) * 4;
      svg.querySelectorAll('.cd').forEach(d => { const v = data.series[d.dataset.k].values[i]; d.setAttribute('cx', xi); d.setAttribute('cy', T + (H - T - B) * (1 - v / top)); });
      tip.hidden = false;
      tip.innerHTML = `<b>${esc(data.labels[i])}</b>${data.series.map(s => `<span><i style="background:${s.color}"></i>${esc(s.name)}<em>${s.values[i]}</em></span>`).join('')}`;
      const px = (xi / W) * c.clientWidth;
      tip.style.left = `${Math.min(Math.max(px, 90), c.clientWidth - 90)}px`;
    });
    c.addEventListener('pointerleave', () => { tip.hidden = true; svg.querySelector('.cx').setAttribute('x1', -10); svg.querySelector('.cx').setAttribute('x2', -10); svg.querySelectorAll('.cd').forEach(d => d.setAttribute('cx', -10)); });
  });
}

// rows: [{ label, value, color }]
export function barList(rows) {
  const max = Math.max(1, ...rows.map(r => r.value));
  return `<div class="bars">${rows.map(r => `<div class="bar-row"><span class="bar-l">${esc(r.label)}</span><span class="bar-t"><i style="width:${Math.max(r.value ? 4 : 0, (r.value / max) * 100)}%;--c:${r.color}"></i></span><b class="bar-v">${r.value}</b></div>`).join('')}</div>`;
}

// parts: [{ label, value, color }]
export function donut(parts, center, sub) {
  const total = parts.reduce((a, p) => a + p.value, 0);
  const R = 52, C = 2 * Math.PI * R, gap = total && parts.filter(p => p.value).length > 1 ? 6 : 0;
  let off = 0;
  const arcs = total ? parts.filter(p => p.value).map(p => { const len = (p.value / total) * C; const a = `<circle r="${R}" cx="64" cy="64" fill="none" stroke="${p.color}" stroke-width="14" stroke-linecap="round" stroke-dasharray="${Math.max(0.1, len - gap)} ${C}" stroke-dashoffset="${-off}"/>`; off += len; return a; }).join('') : '';
  return `<div class="donut"><div class="donut-c"><svg viewBox="0 0 128 128" aria-hidden="true"><circle r="${R}" cx="64" cy="64" fill="none" class="donut-bg" stroke-width="14"/><g transform="rotate(-90 64 64)">${arcs}</g><circle r="38" cx="64" cy="64" fill="none" class="donut-in"/></svg><div><b>${esc(center)}</b><small>${esc(sub)}</small></div></div>
    <ul>${parts.map(p => `<li><i style="background:${p.color}"></i><span>${esc(p.label)}</span><b>${p.value}</b></li>`).join('')}</ul></div>`;
}
