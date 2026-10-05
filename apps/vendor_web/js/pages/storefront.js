// Storefront (V-31-V-33, D-55, Storefront V1 Founder 2026-10-01). Same
// contracts as Vendor App: get_storefront (created unpublished on first
// open), set_storefront_published, save_storefront_appearance (template +
// theme), hero image as a new object in cefflo-storefront-assets. The public
// link is {storefront base}{slug}; Owner + Operator on the server.
import { t } from '../i18n.js';
import { api } from '../api.js';
import { ctx } from '../store.js';
import { esc, icon, chip, loadingRows, errorState, toast, busy, copyText } from '../ui.js';
import qrcode from '../lib/qrcode.js';

// The App's template registry (templates/template_registry.dart), gallery order.
const TEMPLATES = [
  { id: 'arena', name: 'Arena', style: 'tpl.arena', primary: '#17233D', secondary: '#B4222E', mode: 'gradient', font: 'bold' },
  { id: 'stride', name: 'Stride', style: 'tpl.stride', primary: '#14171C', secondary: '#E23B3B', mode: 'plain', font: 'elegant' },
  { id: 'ritual', name: 'Ritual', style: 'tpl.ritual', primary: '#4C6B52', secondary: '#AFC7AE', mode: 'gradient', font: 'elegant' },
  { id: 'market', name: 'Market', style: 'tpl.market', primary: '#15A66E', secondary: '#0B7A4F', mode: 'gradient', font: 'modern' },
  { id: 'feast', name: 'Feast', style: 'tpl.feast', primary: '#7A4A21', secondary: '#C89A6C', mode: 'plain', font: 'modern' },
];
const HERO_TYPES = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' };
const base = () => window.CEFFLO_CONFIG?.storefrontBaseUrl || 'https://order.cefflo.com/';

function qrSvg(text) {
  const code = qrcode(0, 'M');
  code.addData(text);
  code.make();
  return code.createSvgTag({ cellSize: 5, margin: 2, scalable: true });
}

export default function storefront({ el, setHeader }) {
  setHeader(t('sf.title'));
  el.innerHTML = loadingRows(4);
  let sf = null, tpl = 'arena', theme = {}, heroFile = null;

  const paint = () => {
    const link = base() + sf.slug;
    const cur = TEMPLATES.find(x => x.id === tpl) || TEMPLATES[0];
    el.innerHTML = `<div style="display:grid;gap:16px;max-width:980px">
      <div class="card" style="padding:20px"><div style="display:flex;align-items:center;gap:12px"><h3 style="margin:0">${esc(t('sf.yours'))}</h3>${chip(sf.published ? 'active' : 'pending')}
          <button class="btn ${sf.published ? '' : 'primary'} sm" data-publish style="margin-left:auto">${esc(t(sf.published ? 'sf.unpublish' : 'sf.publish'))}</button></div>
        <p class="desc">${esc(t(sf.published ? 'sf.liveLead' : 'sf.draftLead'))}</p>
        <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:16px;align-items:center">
          <div style="width:200px;height:200px">${qrSvg(link)}</div>
          <div><div class="field"><label>${esc(t('sf.link'))}</label><input class="input" readonly data-link value="${esc(link)}"></div>
            <div style="display:flex;gap:8px;flex-wrap:wrap">
              <button class="btn primary sm" data-copy>${esc(t('riders.copy'))}</button>
              ${navigator.share ? `<button class="btn sm" data-share>${esc(t('invite.share'))}</button>` : ''}
              <a class="btn sm" href="${esc(link)}" target="_blank" rel="noopener">${esc(t('sf.open'))}</a></div></div></div></div>
      <div class="card" style="padding:20px"><h3 style="margin:0 0 4px">${esc(t('sf.template'))}</h3><p class="desc">${esc(t('sf.templateLead'))}</p>
        <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:12px">${TEMPLATES.map(x => `<button class="opt ${x.id === tpl ? 'on' : ''}" data-tpl="${x.id}" style="display:flex;flex-direction:column;align-items:flex-start;gap:6px;text-align:left">
          <span style="width:100%;height:56px;border-radius:8px;background:${x.mode === 'gradient' ? `linear-gradient(135deg,${x.primary},${x.secondary})` : x.primary}"></span>
          <b>${esc(x.name)}</b><small>${esc(t(x.style))}</small></button>`).join('')}</div></div>
      <div class="card" style="padding:20px"><h3 style="margin:0 0 4px">${esc(t('sf.appearance'))}</h3><p class="desc">${esc(t('sf.appearanceLead'))}</p>
        <div class="g4" style="align-items:end">
          <div class="field"><label>${esc(t('sf.accent'))}</label><input class="input" type="color" data-accent value="${esc(theme.accent || cur.primary)}"></div>
          <div class="field"><label>${esc(t('sf.secondary'))}</label><input class="input" type="color" data-secondary value="${esc(theme.secondary || cur.secondary)}"></div>
          <div class="field"><label>${esc(t('sf.style'))}</label><select class="select" data-style>
            <option value="plain" ${(theme.style || cur.mode) === 'plain' ? 'selected' : ''}>${esc(t('sf.solid'))}</option>
            <option value="gradient" ${(theme.style || cur.mode) === 'gradient' ? 'selected' : ''}>${esc(t('sf.gradient'))}</option></select></div></div>
        <div class="field"><label>${esc(t('sf.tagline'))}</label><input class="input" data-tagline maxlength="120" value="${esc(theme.tagline || '')}"></div>
        <div class="field"><label>${esc(t('sf.hero'))}</label>
          <div style="display:flex;gap:12px;align-items:center">${theme.hero_path || heroFile ? `<img data-heroimg src="${esc(heroFile ? URL.createObjectURL(heroFile) : api.publicUrl('cefflo-storefront-assets', theme.hero_path))}" alt="" style="width:160px;height:90px;object-fit:cover;border-radius:8px">` : ''}
            <button class="btn sm" data-hero>${esc(t(theme.hero_path || heroFile ? 'sf.heroChange' : 'sf.heroAdd'))}</button>
            <input type="file" accept="image/jpeg,image/png,image/webp" hidden data-herofile></div>
          <small class="hint">${esc(t('sf.heroHint'))}</small></div>
        <div class="err" data-err hidden></div>
        <div style="display:flex;justify-content:flex-end"><button class="btn primary" data-save>${esc(t('c.save'))}</button></div></div></div>`;
  };

  const load = async () => {
    try {
      const res = await api.rpc('get_storefront', { p_business_id: ctx.bid });
      sf = Array.isArray(res) ? res[0] : res;
      tpl = sf.template_key || 'arena';
      theme = { ...(sf.theme || {}) };
      paint();
    } catch (e) { el.innerHTML = errorState(e, 'storefront'); }
  };

  el.addEventListener('click', async e => {
    if (e.target.closest('[data-retry]')) { load(); return; }
    const link = () => el.querySelector('[data-link]').value;
    if (e.target.closest('[data-copy]')) { const ok = await copyText(link()); toast(ok ? t('riders.copied') : link()); return; }
    if (e.target.closest('[data-share]')) { try { await navigator.share({ title: ctx.business?.business_name, url: link() }); } catch { /* dismissed */ } return; }
    const pub = e.target.closest('[data-publish]');
    if (pub) {
      try {
        const res = await busy(pub, () => api.rpc('set_storefront_published', { p_business_id: ctx.bid, p_published: !sf.published }));
        sf.published = (Array.isArray(res) ? res[0] : res)?.published ?? !sf.published;
        toast(t(sf.published ? 'sf.published' : 'sf.unpublished')); paint();
      } catch (ex) { toast(ex.message, 'error'); }
      return;
    }
    const x = e.target.closest('[data-tpl]');
    if (x && x.dataset.tpl !== tpl) {
      // A new template starts from its own colours, as in the App.
      tpl = x.dataset.tpl; const d = TEMPLATES.find(v => v.id === tpl);
      theme = { ...theme, accent: d.primary, secondary: d.secondary, style: d.mode, font: d.font };
      paint(); return;
    }
    if (e.target.closest('[data-hero]')) { el.querySelector('[data-herofile]').click(); return; }
    const save = e.target.closest('[data-save]');
    if (save) {
      const err = el.querySelector('[data-err]'); err.hidden = true;
      const next = { ...theme, accent: el.querySelector('[data-accent]').value.toUpperCase(), secondary: el.querySelector('[data-secondary]').value.toUpperCase(), style: el.querySelector('[data-style]').value };
      const tagline = el.querySelector('[data-tagline]').value.trim();
      if (tagline) next.tagline = tagline; else delete next.tagline;
      try {
        await busy(save, async () => {
          if (heroFile) {
            const path = `${ctx.bid}/hero-${crypto.randomUUID()}.${HERO_TYPES[heroFile.type]}`;
            await api.upload('cefflo-storefront-assets', path, heroFile);
            next.hero_path = path;
          }
          await api.rpc('save_storefront_appearance', { p_business_id: ctx.bid, p_template_key: tpl, p_theme: next });
        });
        theme = next; heroFile = null; toast(t('c.saved')); paint();
      } catch (ex) { err.textContent = ex.message; err.hidden = false; }
    }
  });
  el.addEventListener('change', e => {
    const f = e.target.closest('[data-herofile]');
    if (!f || !f.files[0]) return;
    const file = f.files[0];
    if (!HERO_TYPES[file.type]) { toast(t('prod.badType'), 'error'); return; }
    if (file.size > 5 * 1024 * 1024) { toast(t('prod.tooBig'), 'error'); return; }
    // Keep typed colours/tagline while showing the new hero.
    theme = { ...theme, accent: el.querySelector('[data-accent]').value, secondary: el.querySelector('[data-secondary]').value, style: el.querySelector('[data-style]').value, tagline: el.querySelector('[data-tagline]').value.trim() };
    heroFile = file; paint();
  });
  load();
}
