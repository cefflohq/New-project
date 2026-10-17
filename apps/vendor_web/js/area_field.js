// Area / address field (Founder 2026-10-17): town suggestions while typing
// (admin areas first, instant) and a pin button at the end that opens a map
// to drag the pin. Same control wherever an area or address is entered.
import { t } from './i18n.js';
import { api } from './api.js';
import { esc, icon, modal } from './ui.js';
import { mountPicker } from './map.js';

export const areaFieldHtml = (id, placeholder = '', value = '') => `<div class="af" data-af="${id}">
  <input class="input af-in" id="${id}" autocomplete="off" maxlength="120" placeholder="${esc(placeholder)}" value="${esc(value)}">
  <button type="button" class="af-pin" data-af-pin aria-label="${esc(t('pin.pickerLabel'))}" title="${esc(t('pin.pickerLabel'))}">${icon('pin')}</button>
  <div class="af-sug" hidden></div></div>`;

// Returns { value(), pin() }.
export function wireAreaField(root, id, initialPin = null) {
  const box = root.querySelector(`[data-af="${id}"]`), input = box.querySelector('.af-in'), sug = box.querySelector('.af-sug');
  let pin = initialPin, timer = null, seq = 0, opts = [];
  const cache = new Map();
  const mark = () => box.classList.toggle('has-pin', !!pin);
  const show = list => { opts = list; sug.innerHTML = list.map((a, i) => `<button type="button" data-i="${i}">${icon('pin')}<span><b>${esc(a.label)}</b>${a.state ? `<small>${esc(a.state)}</small>` : ''}</span></button>`).join(''); sug.hidden = !list.length; };
  input.addEventListener('input', () => {
    clearTimeout(timer);
    const q = input.value.trim(), mine = ++seq, key = q.toLowerCase();
    if (q.length < 2) { sug.hidden = true; return; }
    if (cache.has(key)) { show(cache.get(key)); return; }
    timer = setTimeout(async () => {
      const rows = (await api.rpc('search_admin_areas', { p_query: q }).catch(() => [])) || [];
      if (mine !== seq) return;
      cache.set(key, rows); show(rows);
    }, 90);
  });
  input.addEventListener('blur', () => setTimeout(() => { sug.hidden = true; }, 150));
  sug.addEventListener('mousedown', e => {
    const b = e.target.closest('[data-i]'); if (!b) return;
    e.preventDefault(); const a = opts[+b.dataset.i];
    input.value = a.state ? `${a.label}, ${a.state}` : a.label; sug.hidden = true;
  });
  box.querySelector('[data-af-pin]').addEventListener('click', () => {
    let next = pin;
    const m = modal({ title: t('pin.pickerLabel'), lead: t('pin.pickerHint'), cls: 'af-modal',
      body: `<div class="af-map" data-afmap></div>`,
      footer: `<button class="btn primary" data-af-ok>${esc(t('c.save'))}</button>` });
    mountPicker(m.el.querySelector('[data-afmap]'), pin, p => { next = p; });
    m.el.querySelector('[data-af-ok]').addEventListener('click', () => { pin = next; mark(); m.close(); });
  });
  mark();
  return { value: () => input.value.trim(), pin: () => pin };
}

// Number with − / + steppers.
export const stepperHtml = (id, value, { min = 0, max = 999, step = 1, prefix = '' } = {}) => `<div class="stp" data-stp="${id}" data-min="${min}" data-max="${max}" data-step="${step}">
  <button type="button" data-stp-d="-1" aria-label="Decrease">${icon('minus')}</button>
  <span class="stp-v">${prefix ? `<i>${esc(prefix)}</i>` : ''}<input id="${id}" inputmode="decimal" value="${esc(value)}"></span>
  <button type="button" data-stp-d="1" aria-label="Increase">${icon('plus')}</button></div>`;
export function wireSteppers(root) {
  root.addEventListener('click', e => {
    const b = e.target.closest('[data-stp-d]'); if (!b) return;
    const w = b.closest('[data-stp]'), inp = w.querySelector('input');
    const st = Number(w.dataset.step), dec = String(st).includes('.') ? String(st).split('.')[1].length : 0;
    const v = Math.min(Number(w.dataset.max), Math.max(Number(w.dataset.min), (Number(String(inp.value).replace(',', '.')) || 0) + st * Number(b.dataset.stpD)));
    inp.value = v.toFixed(dec); inp.dispatchEvent(new Event('input', { bubbles: true }));
  });
}
