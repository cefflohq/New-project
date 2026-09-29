// Client display preferences (theme, language). There is no canonical
// per-user preference store for the web yet, so these live on the device
// only. Business data is never stored here.
const KEY = 'cefflo.vendorweb.prefs.v1';

function read() {
  try { return JSON.parse(localStorage.getItem(KEY) || '{}'); } catch { return {}; }
}

const stored = read();
export const prefs = {
  theme: ['light', 'dark', 'system'].includes(stored.theme) ? stored.theme : 'light',
  lang: ['en', 'ms'].includes(stored.lang) ? stored.lang : 'en',
  // Notification choices, kept on this device until notification delivery exists.
  notif: { orders: true, issues: true, riders: true, runs: false, ...(stored.notif && typeof stored.notif === 'object' ? stored.notif : {}) },
};

export function savePrefs(next) {
  Object.assign(prefs, next);
  try { localStorage.setItem(KEY, JSON.stringify(prefs)); } catch { /* private mode */ }
  applyTheme();
  document.documentElement.lang = prefs.lang === 'ms' ? 'ms' : 'en';
}

const media = window.matchMedia('(prefers-color-scheme: dark)');
export function applyTheme() {
  const dark = prefs.theme === 'dark' || (prefs.theme === 'system' && media.matches);
  document.documentElement.dataset.theme = dark ? 'dark' : 'light';
}
media.addEventListener?.('change', applyTheme);
applyTheme();
document.documentElement.lang = prefs.lang === 'ms' ? 'ms' : 'en';
