// Phase 2B.4 / D-66 — Customer live-location demand + change hints.
//
// A minimal Supabase Realtime (Phoenix v1.0.0) client, only while the page is
// visible and the order is trackable:
//   - Presence announces this viewer's opaque key {k} (no order/customer data);
//   - Broadcast `loc` is a coordinate-free "location changed" hint.
// The channel is routing, not security: coordinates come only from the
// token-checked public_tracking snapshot.
(function () {
  const HEARTBEAT_MS = 25000;
  const BACKOFF_MS = [5000, 15000, 60000];
  const BACKOFF_STEADY_MS = 300000;

  function createLiveChannel({ url, apiKey, onHint, onStatus }) {
    let ws = null;
    let topic = null;
    let key = null;
    let ref = 0;
    let heartbeat = null;
    let retryTimer = null;
    let attempt = 0;
    let wanted = false;

    const send = (msg) => {
      if (ws && ws.readyState === 1) ws.send(JSON.stringify({ ...msg, ref: String(++ref) }));
    };

    function open() {
      clearTimeout(retryTimer);
      if (!wanted || !topic) return;
      const wsUrl = `${url.replace(/^http/, 'ws')}/realtime/v1/websocket?apikey=${encodeURIComponent(apiKey)}&vsn=1.0.0`;
      try { ws = new WebSocket(wsUrl); } catch (_) { scheduleRetry(); return; }
      ws.onopen = () => {
        send({
          topic: `realtime:${topic}`, event: 'phx_join',
          payload: { config: { broadcast: { self: false }, presence: { key, enabled: true }, private: false }, access_token: apiKey }
        });
        heartbeat = setInterval(() => send({ topic: 'phoenix', event: 'heartbeat', payload: {} }), HEARTBEAT_MS);
      };
      ws.onmessage = (e) => {
        let m; try { m = JSON.parse(e.data); } catch (_) { return; }
        if (m.event === 'phx_reply' && m.topic === `realtime:${topic}` && m.payload && m.payload.status === 'ok') {
          if (attempt !== -1) {
            attempt = -1;
            send({ topic: `realtime:${topic}`, event: 'presence', payload: { type: 'presence', event: 'track', payload: { k: key } } });
            onStatus && onStatus('live');
          }
        }
        if (m.event === 'broadcast' && m.payload && m.payload.event === 'loc') onHint();
      };
      ws.onclose = () => { cleanup(); if (wanted) scheduleRetry(); };
      ws.onerror = () => { try { ws.close(); } catch (_) {} };
    }

    function cleanup() {
      const was = ws;
      clearInterval(heartbeat); heartbeat = null;
      ws = null;
      if (was) onStatus && onStatus('down');
    }

    function scheduleRetry() {
      attempt = attempt < 0 ? 0 : attempt;
      const delay = attempt < BACKOFF_MS.length ? BACKOFF_MS[attempt] : BACKOFF_STEADY_MS;
      attempt += 1;
      retryTimer = setTimeout(open, delay);
    }

    return {
      // Join (or switch to) a channel. No-op when already joined to it.
      join(nextTopic, nextKey) {
        if (wanted && nextTopic === topic && nextKey === key && ws) return;
        this.leave();
        topic = nextTopic; key = nextKey; wanted = true; attempt = 0;
        open();
      },
      // Leave: untrack presence and close. Hidden tabs and finished orders
      // generate no presence and no reads.
      leave() {
        wanted = false;
        clearTimeout(retryTimer);
        if (ws) {
          send({ topic: `realtime:${topic}`, event: 'presence', payload: { type: 'presence', event: 'untrack' } });
          send({ topic: `realtime:${topic}`, event: 'phx_leave', payload: {} });
          try { ws.close(); } catch (_) {}
        }
        cleanup();
      },
      get joined() { return wanted && attempt === -1; }
    };
  }

  window.CEFFLOLive = Object.freeze({ createLiveChannel });
})();
