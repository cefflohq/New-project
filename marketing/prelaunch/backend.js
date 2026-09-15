// CEFFLO Phase 03 -- pre-launch waitlist submission.
// Source: CEFFLO_PHASE_03_MARKETING_ENGINE_CONTENT_PILOT_MASTER.md §18-19.
//
// Truth rule (matches every other CEFFLO client this session touched --
// docs/cefflo/sot/03_VENDOR_WEB_DESKTOP.md §17, 04_CUSTOMER_TRACKING.md §15):
// never show a fake success state. window.CEFFLO only exists once
// shared/config.js has been generated for a real environment by the
// environment-aware build (scripts/build-static.mjs); until then this fails
// honestly instead of lying about being on a waitlist that doesn't exist.
// The RPC itself (cefflo_content_engine.submit_waitlist_entry) is applied
// and HTTP-verified against local (migrations/202609130001 + 202609130002,
// verified 2026-09-11 -- see docs/cefflo/tasks/CEFFLO_PHASE_03_N8N_CODEX_HANDOFF.md
// for staging/production application, owned by Codex per the Phase 03 handoff).
(function () {
  const form = document.getElementById('waitlistForm');
  const statusEl = document.getElementById('wl-status');
  const submitBtn = document.getElementById('wl-submit');

  const params = new URLSearchParams(location.search);
  const attribution = {
    source_platform: params.get('utm_source') || params.get('source') || 'direct',
    campaign_content_id: params.get('utm_content') || params.get('content_id') || null,
  };

  function showStatus(kind, message) {
    statusEl.className = `status ${kind}`;
    statusEl.textContent = message;
    statusEl.classList.remove('hidden');
  }

  async function submitWaitlist(payload) {
    // window.CEFFLO only exists once shared/config.js has been generated for a
    // real environment (local/staging/production) by the environment-aware
    // build -- see shared/config.js's own placeholder error. In this repo
    // state, window.CEFFLO is intentionally undefined.
    if (!window.CEFFLO) {
      throw new Error('CONFIG_NOT_GENERATED: pre-launch waitlist is not yet connected to a live environment.');
    }
    // cefflo_content_engine.submit_waitlist_entry(p_payload jsonb) -> uuid.
    // Lives outside the 'public' schema PostgREST defaults to, so the call
    // must name its profile explicitly (see shared/client.js request()).
    return window.CEFFLO.rpc('submit_waitlist_entry', { p_payload: payload }, { profile: 'cefflo_content_engine' });
  }

  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    statusEl.classList.add('hidden');

    const data = new FormData(form);
    const email = String(data.get('contact_email') || '').trim();
    const phone = String(data.get('contact_phone') || '').trim();
    const consent = document.getElementById('wl-consent').checked;

    if (!email && !phone) return showStatus('error', 'Please enter an email or phone number so we can reach you.');
    if (!consent) return showStatus('error', 'Please confirm you agree to be contacted about early access.');

    const payload = {
      name: String(data.get('name') || '').trim() || null,
      business_name: String(data.get('business_name') || '').trim() || null,
      contact_email: email || null,
      contact_phone: phone || null,
      business_type: String(data.get('business_type') || '').trim() || null,
      approximate_delivery_volume: String(data.get('approximate_delivery_volume') || '').trim() || null,
      preferred_contact: email ? 'email' : 'phone',
      source_platform: attribution.source_platform,
      campaign_content_id: attribution.campaign_content_id,
      consent_given: true,
    };

    submitBtn.disabled = true;
    try {
      await submitWaitlist(payload);
      showStatus('success', "You're on the list. We'll reach out as early access opens.");
      form.reset();
    } catch (error) {
      if (String(error.message || '').startsWith('CONFIG_NOT_GENERATED')) {
        showStatus('error', "Early access signup isn't connected yet -- thanks for your interest, please check back soon.");
      } else {
        showStatus('error', error.message || 'Something went wrong. Please try again.');
      }
      console.error('[cefflo-prelaunch-waitlist]', error, { attempted_payload: payload });
    } finally {
      submitBtn.disabled = false;
    }
  });
})();
