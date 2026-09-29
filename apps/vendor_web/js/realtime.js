// Minimal Supabase Realtime client (Phoenix channel protocol, vsn 1.0.0) for
// postgres_changes on one table. The shared REST client has no realtime, and
// the Vendor Web App deliberately has no bundler, so this is the smallest
// real subscription: RLS on the table decides which rows reach this user.
//
// Contract: subscribe({table, filter, token, onChange, onStatus}) -> {close, setToken}
//   onChange({type: 'INSERT'|'UPDATE'|'DELETE', record, old_record})
//   onStatus('connecting'|'subscribed'|'closed'|'error'); after a drop it
//   reconnects with backoff and reports 'subscribed' again, so callers can
//   re-read history and never miss rows that arrived while offline.
const cfg = window.CEFFLO_CONFIG;

export function subscribe({ table, filter, token, onChange, onStatus = () => {} }) {
  let ws = null, ref = 0, joinRef = null, heartbeat = null, retry = 0, closed = false, accessToken = token;
  const topic = `realtime:${table}:${Math.random().toString(36).slice(2, 8)}`;
  const url = `${cfg.supabaseUrl.replace(/^http/, 'ws')}/realtime/v1/websocket?apikey=${encodeURIComponent(cfg.supabaseAnonKey)}&vsn=1.0.0`;
  const send = (t, event, payload, jr = joinRef) => { if (ws?.readyState === 1) ws.send(JSON.stringify({ topic: t, event, payload, ref: String(++ref), join_ref: jr })); };

  function connect() {
    if (closed) return;
    onStatus('connecting');
    try { ws = new WebSocket(url); } catch { return schedule(); }
    ws.onopen = () => {
      joinRef = String(++ref);
      ws.send(JSON.stringify({
        topic, event: 'phx_join', ref: joinRef, join_ref: joinRef,
        payload: { config: { broadcast: { ack: false, self: false }, presence: { key: '' }, private: false, postgres_changes: [{ event: '*', schema: 'public', table, filter }] }, access_token: accessToken },
      }));
      clearInterval(heartbeat);
      heartbeat = setInterval(() => send('phoenix', 'heartbeat', {}, null), 25_000);
    };
    ws.onmessage = ev => {
      let msg; try { msg = JSON.parse(ev.data); } catch { return; }
      if (msg.topic !== topic) return;
      if (msg.event === 'phx_reply' && msg.ref === joinRef) {
        if (msg.payload?.status === 'ok') { retry = 0; onStatus('subscribed'); } else { onStatus('error'); ws.close(); }
      } else if (msg.event === 'postgres_changes') {
        const d = msg.payload?.data;
        if (d) onChange({ type: d.type, record: d.record, old_record: d.old_record });
      } else if (msg.event === 'phx_error' || msg.event === 'phx_close') {
        ws.close();
      }
    };
    ws.onclose = () => { clearInterval(heartbeat); if (!closed) { onStatus('closed'); schedule(); } };
    ws.onerror = () => { /* onclose follows */ };
  }
  function schedule() {
    if (closed) return;
    const wait = Math.min(30_000, 1000 * 2 ** retry++) + Math.random() * 500;
    setTimeout(connect, wait);
  }
  connect();
  return {
    close() { closed = true; clearInterval(heartbeat); try { ws?.close(); } catch { /* already closed */ } },
    setToken(next) { accessToken = next; send(topic, 'access_token', { access_token: next }); },
  };
}
