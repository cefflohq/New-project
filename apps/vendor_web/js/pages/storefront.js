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

// The Storefront V1 template library, in gallery order. Ids, names and
// default colours match store/templates.js and the Vendor App registry
// (templates/web/web_templates.dart); `hero: false` templates have no
// banner image.
const TEMPLATES = [
  { id: 'care', name: 'Care', primary: '#1677D8', secondary: '#E8F2FD' },
  { id: 'capsule', name: 'Capsule', primary: '#C8234F', secondary: '#F7C531' },
  { id: 'kit', name: 'Kit', primary: '#253D6B', secondary: '#E1293F' },
  { id: 'brew', name: 'Brew', primary: '#4B2A15', secondary: '#D3A06A' },
  { id: 'crimson', name: 'Crimson', primary: '#B82838', secondary: '#2A2A2A' },
  { id: 'lift', name: 'Lift', primary: '#111111', secondary: '#E5332A' },
  { id: 'harvest', name: 'Harvest', primary: '#111111', secondary: '#3BAA4A' },
  { id: 'botanic', name: 'Botanic', primary: '#86A98F', secondary: '#2F4A3A' },
  { id: 'combo', name: 'Combo', primary: '#F26B2C', secondary: '#8E9BF5', hero: false },
  { id: 'discover', name: 'Discover', primary: '#22C55E', secondary: '#16A34A' },
  { id: 'atelier', name: 'Atelier', primary: '#111111', secondary: '#E35B2C' },
  { id: 'pour', name: 'Pour', primary: '#111111', secondary: '#E6E7E9', hero: false },
  { id: 'tailor', name: 'Tailor', primary: '#111111', secondary: '#F59E6B' },
  { id: 'sprint', name: 'Sprint', primary: '#6B3BE0', secondary: '#FF7A1A' },
  { id: 'splash', name: 'Splash', primary: '#2563EB', secondary: '#FACC15' },
  { id: 'service', name: 'Service', primary: '#5B7CF6', secondary: '#FACC15' },
  { id: 'warung', name: 'Warung', primary: '#169A49', secondary: '#E11D2E', hero: false },
  { id: 'collector', name: 'Collector', primary: '#111111', secondary: '#F2F2F4', hero: false },
];
const PREVIEW_SCREENS = [['', 'sf.pvHome'], ['p/first', 'sf.pvProduct'], ['cart', 'sf.pvCart']];
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
  let sf = null, tpl = 'care', theme = {}, heroFile = null, heroData = null, pv = null, screen = '';
  let frame = null, frameReady = false;
  const def = () => TEMPLATES.find(x => x.id === tpl) || TEMPLATES[0];
  const sfOrigin = () => new URL(base(), location.href).origin;

  // The live preview is the real storefront renderer (store/?embed=1), fed
  // this business's storefront_preview payload plus the unsaved edits, as
  // in the Vendor App. Ordering is disabled inside the preview.
  const payload = () => {
    const d = def(), cur = readForm();
    const store = { ...(pv || { slug: sf?.slug || 'preview', business: { name: ctx.business?.business_name || '' }, categories: [], products: [] }) };
    store.theme = { ...(store.theme || {}), accent: cur.accent || d.primary, secondary: cur.secondary || d.secondary, ...(cur.tagline ? { tagline: cur.tagline } : {}) };
    store.template_key = tpl;
    if (heroData) store.hero_url = heroData;
    return store;
  };
  const post = () => { if (frame?.contentWindow && frameReady) frame.contentWindow.postMessage({ type: 'cefflo-storefront-preview', store: payload() }, sfOrigin()); };
  const route = () => {
    if (screen !== 'p/first') return screen;
    const first = pv?.products?.[0]?.id; return first ? `p/${first}` : '';
  };
  const src = () => `${new URL('preview', base()).href}?embed=1&template=${encodeURIComponent(tpl)}${route() ? `#/${route()}` : ''}`;
  const onMessage = e => {
    if (!el.isConnected) { window.removeEventListener('message', onMessage); return; }
    if (e.origin !== sfOrigin() || !frame || e.source !== frame.contentWindow) return;
    if (e.data?.type === 'cefflo-storefront-ready') { frameReady = true; post(); }
  };
  window.addEventListener('message', onMessage);

  const readForm = () => {
    const v = s => el.querySelector(s);
    return v('[data-accent]') ? { accent: v('[data-accent]').value.toUpperCase(), secondary: v('[data-secondary]').value.toUpperCase(), tagline: v('[data-tagline]').value.trim() }
      : { accent: theme.accent, secondary: theme.secondary, tagline: theme.tagline || '' };
  };

  const paint = () => {
    const link = base() + sf.slug;
    const cur = def();
    el.innerHTML = `<div style="display:grid;gap:16px;max-width:1180px">
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
      <div style="display:grid;grid-template-columns:minmax(0,1fr) 340px;gap:16px;align-items:start" class="sf-split">
        <div style="display:grid;gap:16px;min-width:0">
          <div class="card" style="padding:20px"><h3 style="margin:0 0 4px">${esc(t('sf.template'))}</h3><p class="desc">${esc(t('sf.templateLead'))}</p>
            <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:10px">${TEMPLATES.map(x => `<button class="opt ${x.id === tpl ? 'on' : ''}" data-tpl="${x.id}" style="display:flex;flex-direction:column;align-items:flex-start;gap:4px;text-align:left;min-width:0">
              <span style="display:flex;gap:4px"><i style="width:18px;height:18px;border-radius:50%;background:${x.primary};border:1px solid var(--line)"></i><i style="width:18px;height:18px;border-radius:50%;background:${x.secondary};border:1px solid var(--line)"></i></span>
              <b>${esc(x.name)}</b><small>${esc(t(`tpl.${x.id}`))}</small></button>`).join('')}</div></div>
          <div class="card" style="padding:20px"><h3 style="margin:0 0 4px">${esc(t('sf.appearance'))}</h3><p class="desc">${esc(t('sf.appearanceLead'))}</p>
            <div class="g4" style="align-items:end">
              <div class="field"><label>${esc(t('sf.accent'))}</label><input class="input" type="color" data-accent value="${esc(theme.accent || cur.primary)}"></div>
              <div class="field"><label>${esc(t('sf.secondary'))}</label><input class="input" type="color" data-secondary value="${esc(theme.secondary || cur.secondary)}"></div></div>
            <div class="field"><label>${esc(t('sf.tagline'))}</label><input class="input" data-tagline maxlength="120" value="${esc(theme.tagline || '')}"></div>
            ${cur.hero === false ? '' : `<div class="field"><label>${esc(t('sf.hero'))}</label>
              <div style="display:flex;gap:12px;align-items:center">${theme.hero_path || heroFile ? `<img data-heroimg src="${esc(heroData || api.publicUrl('cefflo-storefront-assets', theme.hero_path))}" alt="" style="width:160px;height:90px;object-fit:cover;border-radius:8px">` : ''}
                <button class="btn sm" data-hero>${esc(t(theme.hero_path || heroFile ? 'sf.heroChange' : 'sf.heroAdd'))}</button>
                <input type="file" accept="image/jpeg,image/png,image/webp" hidden data-herofile></div>
              <small class="hint">${esc(t('sf.heroHint'))}</small></div>`}
            <div class="err" data-err hidden></div>
            <div style="display:flex;justify-content:flex-end"><button class="btn primary" data-save>${esc(t('c.save'))}</button></div></div></div>
        <div class="card" style="padding:16px;position:sticky;top:16px"><h3 style="margin:0 0 4px">${esc(t('sf.preview'))}</h3><p class="desc" style="margin-bottom:10px">${esc(t('sf.previewLead'))}</p>
          <div class="tabs" style="margin-bottom:12px">${PREVIEW_SCREENS.map(([r, k]) => `<button class="tab ${screen === r ? 'on' : ''}" data-screen="${r}">${esc(t(k))}</button>`).join('')}</div>
          <div style="width:308px;height:667px;margin:0 auto;border-radius:28px;overflow:hidden;border:6px solid #111;background:#fff">
            <iframe data-frame title="${esc(t('sf.preview'))}" style="width:390px;height:844px;border:0;transform:scale(.7744);transform-origin:0 0" src="${esc(src())}"></iframe></div></div></div></div>`;
    frame = el.querySelector('[data-frame]'); frameReady = false;
  };

  const load = async () => {
    try {
      const [res, p] = await Promise.all([
        api.rpc('get_storefront', { p_business_id: ctx.bid }),
        api.rpc('storefront_preview', { p_business_id: ctx.bid }).catch(() => null),
      ]);
      sf = Array.isArray(res) ? res[0] : res;
      pv = p && typeof p === 'object' ? p : null;
      tpl = TEMPLATES.some(x => x.id === sf.template_key) ? sf.template_key : 'care';
      theme = { ...(sf.theme || {}) };
      paint();
    } catch (e) { el.innerHTML = errorState(e, 'storefront'); }
  };

  el.addEventListener('input', e => { if (e.target.closest('[data-accent],[data-secondary],[data-tagline]')) post(); });
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
    const sc = e.target.closest('[data-screen]');
    if (sc) { theme = { ...theme, ...readForm() }; screen = sc.dataset.screen; paint(); return; }
    const x = e.target.closest('[data-tpl]');
    if (x && x.dataset.tpl !== tpl) {
      // A new template starts from its own colours, as in the App.
      tpl = x.dataset.tpl; const d = def();
      theme = { ...theme, tagline: readForm().tagline, accent: d.primary, secondary: d.secondary };
      paint(); return;
    }
    if (e.target.closest('[data-hero]')) { el.querySelector('[data-herofile]').click(); return; }
    const save = e.target.closest('[data-save]');
    if (save) {
      const err = el.querySelector('[data-err]'); err.hidden = true;
      const f = readForm();
      const next = { ...theme, accent: f.accent, secondary: f.secondary };
      delete next.style; delete next.font;
      if (f.tagline) next.tagline = f.tagline; else delete next.tagline;
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
    theme = { ...theme, ...readForm() };
    heroFile = file;
    const r = new FileReader(); r.onload = () => { heroData = String(r.result); paint(); }; r.readAsDataURL(file);
  });
  load();
}
