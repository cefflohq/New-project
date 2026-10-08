/* CEFFLO Page Loader — window.showPageLoader(label) / hidePageLoader().
   One component for every web surface; styles in loader.css (auto-linked). */
(function () {
  'use strict';
  if (window.showPageLoader) return;
  var DEFAULT = 'Memuatkan…';
  var SLOW = 'Masih memuatkan, sila tunggu sebentar';
  var DELAY = 300, SLOW_AFTER = 8000, FADE = 200;

  var me = document.currentScript;
  if (me && !document.querySelector('link[data-cf-loader]')) {
    var link = document.createElement('link');
    link.rel = 'stylesheet'; link.setAttribute('data-cf-loader', '');
    link.href = me.src.replace(/loader\.js(\?.*)?$/, 'loader.css$1');
    document.head.appendChild(link);
  }

  function esc(s) { return String(s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }

  // Inline markup for a page region (lists, panels). Fades in after 300ms by CSS.
  function markup(label, extraClass) {
    return '<div class="cf-page-loader cf-page-loader--inline' + (extraClass ? ' ' + extraClass : '') +
      '" role="status" aria-live="polite" data-cf-loader-at="' + Date.now() + '">' +
      '<div class="cf-dots" aria-hidden="true"><i></i><i></i><i></i></div>' +
      '<p class="cf-loader-label">' + esc(label || DEFAULT) + '</p></div>';
  }

  var el, showTimer, slowTimer, hideTimer, depth = 0;
  function build() {
    el = document.createElement('div');
    el.className = 'cf-page-loader cf-page-loader--global';
    el.setAttribute('role', 'status'); el.setAttribute('aria-live', 'polite');
    el.innerHTML = '<div class="cf-dots" aria-hidden="true"><i></i><i></i><i></i></div><p class="cf-loader-label"></p>';
  }
  function show(label) {
    if (!el) build();
    depth++;
    el.querySelector('.cf-loader-label').textContent = label || DEFAULT;
    clearTimeout(hideTimer);
    if (depth > 1) return;
    clearTimeout(showTimer); clearTimeout(slowTimer);
    showTimer = setTimeout(function () {
      if (!el.isConnected) document.body.appendChild(el);
      requestAnimationFrame(function () { el.classList.add('is-visible'); });
    }, DELAY);
    slowTimer = setTimeout(function () { el.querySelector('.cf-loader-label').textContent = SLOW; }, SLOW_AFTER);
  }
  function hide(force) {
    if (!el) return;
    depth = force ? 0 : Math.max(0, depth - 1);
    if (depth) return;
    clearTimeout(showTimer); clearTimeout(slowTimer);
    el.classList.remove('is-visible');
    hideTimer = setTimeout(function () { if (el.isConnected && !depth) el.remove(); }, FADE);
  }
  // Wraps a promise: loader while it runs, always hidden afterwards.
  function withLoader(label, work) {
    show(label);
    return Promise.resolve().then(typeof work === 'function' ? work : function () { return work; })
      .finally(function () { hide(); });
  }

  // Inline loaders still on screen after 8s switch to the slow label.
  setInterval(function () {
    var now = Date.now();
    document.querySelectorAll('.cf-page-loader--inline[data-cf-loader-at]').forEach(function (n) {
      if (now - Number(n.getAttribute('data-cf-loader-at')) >= SLOW_AFTER) {
        n.querySelector('.cf-loader-label').textContent = SLOW; n.removeAttribute('data-cf-loader-at');
      }
    });
  }, 1000);

  window.showPageLoader = show;
  window.hidePageLoader = hide;
  window.cfLoader = { show: show, hide: hide, wrap: withLoader, markup: markup, DEFAULT: DEFAULT, SLOW: SLOW };
})();
