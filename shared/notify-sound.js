// Cefflo Signature Notification Sound -- web player (contract:
// docs/cefflo/NOTIFICATION_EVENT_MATRIX.md §6).
//
// Plays the approved signature asset only when shared/sounds/manifest.json
// says `approved: true`. Until the Founder approves the final audio identity:
//   * production  -> no custom sound at all (never a random placeholder);
//   * other envs  -> a clearly labelled DEV tone synthesised in the browser,
//                    so the behaviour can be tested. It is not an asset and
//                    is never shipped as the Cefflo sound.
// Browsers block audio until the user has interacted with the page; a blocked
// play is dropped silently and never retried or looped.
(function () {
  const base = '/shared/sounds/';
  let manifest = null;
  let lastAt = 0;
  const env = () => window.CEFFLO_CONFIG?.environment || 'production';
  const ready = fetch(`${base}manifest.json`, { cache: 'no-cache' }).then(r => (r.ok ? r.json() : null)).catch(() => null).then(m => { manifest = m; });

  function devTone() {
    const Ctx = window.AudioContext || window.webkitAudioContext;
    if (!Ctx) return false;
    const ctx = new Ctx();
    if (ctx.state === 'suspended') { ctx.close(); return false; }
    const t0 = ctx.currentTime;
    // DEV ONLY: two short sine notes. Not the Cefflo signature.
    [[660, 0], [880, 0.12]].forEach(([f, at]) => {
      const o = ctx.createOscillator(), g = ctx.createGain();
      o.type = 'sine'; o.frequency.value = f;
      g.gain.setValueAtTime(0.0001, t0 + at);
      g.gain.exponentialRampToValueAtTime(0.18, t0 + at + 0.02);
      g.gain.exponentialRampToValueAtTime(0.0001, t0 + at + 0.22);
      o.connect(g).connect(ctx.destination); o.start(t0 + at); o.stop(t0 + at + 0.25);
    });
    setTimeout(() => ctx.close(), 600);
    return true;
  }

  async function play() {
    const now = Date.now();
    if (now - lastAt < 1500) return 'throttled'; // a burst of events plays once
    lastAt = now;
    await ready;
    if (manifest?.approved && manifest.files?.web?.length) {
      const src = manifest.files.web.find(f => new Audio().canPlayType(f.endsWith('.ogg') ? 'audio/ogg' : 'audio/mpeg')) || manifest.files.web[0];
      try { await new Audio(`${base}${src}?v=${encodeURIComponent(manifest.version || '')}`).play(); return 'signature'; } catch { return 'blocked'; }
    }
    if (env() === 'production') return 'none';
    return devTone() ? 'dev-tone' : 'blocked';
  }

  window.CEFFLO_SOUND = Object.freeze({
    play,
    status: async () => { await ready; return manifest?.approved ? 'signature' : env() === 'production' ? 'none' : 'dev-tone'; },
  });
})();
