// Products / catalogue (V-34-V-36, product media multi, Founder 2026-10-01).
// Same contracts as Vendor App: create_product / update_product (a category
// of this business is required; a new name is created first with
// create_product_category), status active | hidden, and up to 5 photos per
// product (create_product_media -> display copy -> mark_product_media_displayable,
// archive_product_media, reorder_product_media). Owner + Operator on the server.
import { t } from '../i18n.js';
import { api } from '../api.js';
import { ctx } from '../store.js';
import { esc, icon, chip, loadingRows, emptyState, errorState, toast, busy, modal } from '../ui.js';

const MAX_PHOTOS = 5;
const MAX_BYTES = 5 * 1024 * 1024;
const TYPES = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' };
const q = encodeURIComponent;

const fetchProducts = () => api.get(`/rest/v1/products?business_id=eq.${q(ctx.bid)}&archived_at=is.null&select=id,name,description,display_price,status,category_id&order=name`);
const fetchCategories = () => api.get(`/rest/v1/product_categories?business_id=eq.${q(ctx.bid)}&archived_at=is.null&select=id,name&order=sort_order`);
const fetchMedia = productId => api.get(`/rest/v1/product_media?product_id=eq.${q(productId)}&archived_at=is.null&status=in.(queued,processing,prepared,approved)&select=id,position,status,prepared_storage_path&order=position`);
const rm = n => `RM${Number(n || 0).toFixed(2)}`;

export default function products({ el, setHeader }) {
  setHeader(t('prod.title'));
  el.innerHTML = `<div class="card">
    <div class="bar"><div class="search">${icon('search')}<input data-q placeholder="${esc(t('prod.search'))}" aria-label="${esc(t('c.search'))}"></div>
      <button class="btn cta sm" data-add>${icon('plus')}${esc(t('prod.add'))}</button></div>
    <div data-list>${loadingRows(6)}</div></div>`;
  let all = [], cats = [], query = '';
  const list = el.querySelector('[data-list]');
  const paint = () => {
    const rows = all.filter(p => !query || p.name.toLowerCase().includes(query));
    if (!rows.length) { list.innerHTML = emptyState(t(all.length ? 'prod.noMatch' : 'prod.none')); return; }
    const catName = id => cats.find(c => c.id === id)?.name || '';
    list.innerHTML = `<table class="table"><thead><tr><th>${esc(t('prod.name'))}</th><th>${esc(t('prod.category'))}</th><th>${esc(t('prod.price'))}</th><th>${esc(t('prod.status'))}</th></tr></thead><tbody>
      ${rows.map(p => `<tr data-id="${esc(p.id)}" style="cursor:pointer"><td><b>${esc(p.name)}</b></td><td>${esc(catName(p.category_id))}</td><td>${esc(rm(p.display_price))}</td><td>${chip(p.status === 'active' ? 'active' : 'hidden')}</td></tr>`).join('')}</tbody></table>`;
  };
  const load = async () => {
    try { [all, cats] = await Promise.all([fetchProducts(), fetchCategories()]); all ||= []; cats ||= []; paint(); }
    catch (e) { list.innerHTML = errorState(e, 'products'); }
  };
  el.addEventListener('click', e => {
    if (e.target.closest('[data-add]')) { openProduct(null, cats, load); return; }
    const row = e.target.closest('tr[data-id]');
    if (row) openProduct(all.find(p => p.id === row.dataset.id), cats, load);
    if (e.target.closest('[data-retry]')) load();
  });
  el.querySelector('[data-q]').addEventListener('input', e => { query = e.target.value.trim().toLowerCase(); paint(); });
  load();
}

function openProduct(product, cats, onDone) {
  const isNew = !product;
  const p = product || { name: '', description: '', display_price: '', status: 'active', category_id: cats[0]?.id };
  const catName = cats.find(c => c.id === p.category_id)?.name || cats[0]?.name || '';
  const m = modal({
    title: t(isNew ? 'prod.add' : 'prod.edit'),
    body: `
      <div class="field"><label>${esc(t('prod.photos'))}</label><div data-photos style="display:flex;gap:8px;flex-wrap:wrap"></div>
        <small class="hint">${esc(t('prod.photosHint'))}</small><input type="file" accept="image/jpeg,image/png,image/webp" multiple hidden data-file></div>
      <div class="field"><label>${esc(t('prod.name'))}</label><input class="input" name="name" maxlength="120" value="${esc(p.name)}"></div>
      <div class="field"><label>${esc(t('prod.description'))}</label><textarea class="textarea" name="description" rows="3" maxlength="1000">${esc(p.description || '')}</textarea></div>
      <div class="g2">
        <div class="field"><label>${esc(t('prod.price'))} (RM)</label><input class="input" name="price" inputmode="decimal" value="${esc(p.display_price ?? '')}"></div>
        <div class="field"><label>${esc(t('prod.category'))}</label><input class="input" name="category" list="prod-cats" maxlength="80" value="${esc(catName)}">
          <datalist id="prod-cats">${cats.map(c => `<option value="${esc(c.name)}">`).join('')}</datalist></div></div>
      <label style="display:flex;gap:8px;align-items:center"><input type="checkbox" name="active" ${p.status === 'active' ? 'checked' : ''}>${esc(t('prod.visible'))}</label>
      <div class="err" data-err hidden></div>`,
    footer: `<button class="btn" data-close>${esc(t('c.cancel'))}</button><button class="btn primary" data-submit>${esc(t(isNew ? 'prod.create' : 'c.save'))}</button>`,
  });
  // Photos: saved media (id) and new files (file) in the order shown.
  // Changes apply on Save, so a new product can take photos before it exists.
  let photos = [], removed = [];
  const box = m.el.querySelector('[data-photos]'), err = m.el.querySelector('[data-err]');
  const paintPhotos = () => {
    box.innerHTML = photos.map((ph, i) => `<div style="position:relative;width:84px;height:84px;border-radius:10px;overflow:hidden;background:var(--surface-2,#eef1f5)">
        <img src="${esc(ph.url)}" alt="" style="width:100%;height:100%;object-fit:cover">
        <button class="icon-btn" data-rm="${i}" aria-label="${esc(t('prod.removePhoto'))}" style="position:absolute;top:2px;right:2px;background:#0008;color:#fff;width:24px;height:24px">${icon('x')}</button>
        ${i ? `<button class="icon-btn" data-left="${i}" aria-label="${esc(t('prod.movePhoto'))}" style="position:absolute;bottom:2px;left:2px;background:#0008;color:#fff;width:24px;height:24px">${icon('left')}</button>` : ''}</div>`).join('')
      + (photos.length < MAX_PHOTOS ? `<button class="btn" data-addphoto style="width:84px;height:84px;flex-direction:column">${icon('plus')}<small>${esc(t('prod.addPhoto'))}</small></button>` : '');
  };
  if (!isNew) {
    fetchMedia(p.id).then(rows => {
      photos = (rows || []).map(r => ({ id: r.id, url: r.prepared_storage_path ? api.publicUrl('cefflo-product-display', r.prepared_storage_path) : '' }));
      paintPhotos();
    }).catch(() => paintPhotos());
  } else paintPhotos();
  const file = m.el.querySelector('[data-file]');
  file.addEventListener('change', () => {
    for (const f of file.files) {
      if (photos.length >= MAX_PHOTOS) { toast(t('prod.max5'), 'error'); break; }
      if (!TYPES[f.type]) { toast(t('prod.badType'), 'error'); continue; }
      if (f.size > MAX_BYTES) { toast(t('prod.tooBig'), 'error'); continue; }
      photos.push({ file: f, url: URL.createObjectURL(f) });
    }
    file.value = ''; paintPhotos();
  });
  box.addEventListener('click', e => {
    if (e.target.closest('[data-addphoto]')) { file.click(); return; }
    const r = e.target.closest('[data-rm]');
    if (r) { const [ph] = photos.splice(Number(r.dataset.rm), 1); if (ph.id) removed.push(ph.id); paintPhotos(); return; }
    const l = e.target.closest('[data-left]');
    if (l) { const i = Number(l.dataset.left); [photos[i - 1], photos[i]] = [photos[i], photos[i - 1]]; paintPhotos(); }
  });

  m.el.querySelector('[data-submit]').addEventListener('click', async e => {
    const f = n => m.el.querySelector(`[name=${n}]`);
    const name = f('name').value.trim(), price = Number(f('price').value), catText = f('category').value.trim();
    if (!name || !catText || f('price').value.trim() === '') { err.textContent = t('c.required'); err.hidden = false; return; }
    if (!Number.isFinite(price) || price < 0) { err.textContent = t('prod.badPrice'); err.hidden = false; return; }
    err.hidden = true;
    try {
      await busy(e.currentTarget, async () => {
        let categoryId = cats.find(c => c.name.toLowerCase() === catText.toLowerCase())?.id;
        if (!categoryId) {
          const c = await api.rpc('create_product_category', { p_business_id: ctx.bid, p_name: catText });
          categoryId = (Array.isArray(c) ? c[0] : c).id;
        }
        const args = { p_category_id: categoryId, p_name: name, p_description: f('description').value.trim(), p_display_price: price, p_status: f('active').checked ? 'active' : 'hidden' };
        const saved = isNew
          ? await api.rpc('create_product', { p_business_id: ctx.bid, ...args })
          : await api.rpc('update_product', { p_product_id: p.id, ...args });
        const productId = (Array.isArray(saved) ? saved[0] : saved)?.id || p.id;
        for (const id of removed) await api.rpc('archive_product_media', { p_media_id: id });
        for (const ph of photos) {
          if (ph.id) continue;
          const mediaId = crypto.randomUUID(), ext = TYPES[ph.file.type];
          await api.upload('cefflo-product-originals', `${ctx.bid}/${productId}/${mediaId}/original.${ext}`, ph.file);
          await api.rpc('create_product_media', { p_product_id: productId, p_media_id: mediaId, p_content_type: ph.file.type });
          // V1 original-as-is: the same bytes become the public display copy,
          // which the server verifies before approving.
          await api.upload('cefflo-product-display', `${ctx.bid}/${productId}/${mediaId}/display.${ext}`, ph.file);
          await api.rpc('mark_product_media_displayable', { p_media_id: mediaId });
          ph.id = mediaId;
        }
        if (photos.length > 1) await api.rpc('reorder_product_media', { p_product_id: productId, p_media_ids: photos.map(ph => ph.id) });
      });
      m.close(); toast(t(isNew ? 'prod.created' : 'c.saved')); onDone?.();
    } catch (ex) { err.textContent = ex.message; err.hidden = false; }
  });
}
