"""Phase 2B.4 (D-66): Customer Tracking fetch coalescing and visibility.
Runs customer/backend.js in a Node vm with fake timers, a fake API and a fake
live channel. Proves: never two parallel public_tracking reads, bursts of
`loc` hints collapse into one follow-up, >= 10 s between fetch starts, hidden
tabs make no reads and leave the channel, finished orders leave the channel,
and coordinates only ever come from public_tracking."""

import json
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

SCRIPT = r"""
const fs = require('fs'); const vm = require('vm');
const src = fs.readFileSync(process.argv[1], 'utf8');
let now = 0; const timers = [];
const setTimeout_ = (fn, ms) => { const t = { fn, at: now + ms, id: timers.length }; timers.push(t); return t; };
const clearTimeout_ = (t) => { if (t) t.fn = null; };
async function advance(ms) {
  const end = now + ms;
  for (;;) {
    const due = timers.filter(t => t.fn && t.at <= end).sort((a, b) => a.at - b.at)[0];
    if (!due) break;
    now = due.at; const fn = due.fn; due.fn = null; fn(); await flush();
  }
  now = end;
}
const flush = () => new Promise(r => setImmediate(r));
let inFlight = 0, maxParallel = 0, calls = 0, resolvers = [];
let status = 'out_for_delivery';
const snapshot = () => ({ status, order_number: '#CF-001', store_name: 'S', rider_name: 'R', eta: null,
  completed_at: null, pod_available: false, rating_submitted: false,
  rider_location: { lat: 3.1, lng: 101.6, accuracy_m: 10, recorded_at: new Date().toISOString() },
  stops_ahead: 2, live: status === 'delivered' ? undefined : { topic: 'trk:x', key: 'k1' } });
const api = { config: { supabaseUrl: 'https://x.supabase.co', supabaseAnonKey: 'pk' },
  rpc: (name) => { calls++; inFlight++; maxParallel = Math.max(maxParallel, inFlight);
    return new Promise(r => resolvers.push(() => { inFlight--; r(snapshot()); })); } };
const liveLog = []; let hint = null;
const listeners = {};
const doc = { visibilityState: 'visible', addEventListener: (e, f) => (listeners['d:' + e] = f), getElementById: () => null };
const statuses = [];
const win = { CEFFLO: api, addEventListener: (e, f) => (listeners['w:' + e] = f),
  CEFFLOTracking: { setStatus: (s, p) => statuses.push([s, p]), getSnapshot: () => ({ phase: 'ready' }), fail() {} },
  CEFFLOLive: { createLiveChannel: (o) => { hint = o.onHint; return { join: (t, k) => liveLog.push(['join', t, k]), leave: () => liveLog.push(['leave']) }; } } };
const ctx = { window: win, document: doc, location: { search: '?token=tok' }, URLSearchParams, setTimeout: setTimeout_, clearTimeout: clearTimeout_,
  Date: { now: () => now }, fetch: async () => ({ ok: false }), console, Number, Math, JSON, Promise };
ctx.window.window = win; vm.createContext(ctx); vm.runInContext(src, ctx);
const done = async () => { while (resolvers.length) { resolvers.shift()(); await flush(); } };
(async () => {
  const out = {};
  listeners['w:load'](); await flush(); await done();          // initial snapshot
  for (let i = 0; i < 5; i++) hint(); await flush();             // burst right after
  out.callsAfterBurst = calls;                                    // waits for the 10 s gap
  await advance(9999); out.callsBefore10s = calls;
  await advance(2); out.callsAt10s = calls;                       // one fetch now in flight
  for (let i = 0; i < 5; i++) hint(); await flush();             // burst during the fetch
  out.parallelDuringBurst = maxParallel;
  await done(); out.callsAfterInflight = calls;                   // one pending follow-up, spaced
  await advance(10001); await done(); out.callsAfterFollowUp = calls;
  out.joined = liveLog.filter(l => l[0] === 'join').length > 0;
  doc.visibilityState = 'hidden'; listeners['d:visibilitychange'](); hint(); await advance(600000);
  out.callsWhileHidden = calls - out.callsAfterFollowUp; out.leftOnHide = liveLog.at(-1)[0] === 'leave';
  doc.visibilityState = 'visible'; status = 'delivered'; listeners['d:visibilitychange'](); await flush(); await done();
  out.leftWhenDelivered = liveLog.at(-1)[0] === 'leave';
  out.maxParallel = maxParallel;
  out.location = statuses[0][1].riderLocation; if ('stopsAhead' in statuses[0][1]) out.stopsAhead = statuses[0][1].stopsAhead;
  console.log(JSON.stringify(out));
})();
"""


class CustomerLiveGateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        r = subprocess.run(["node", "-e", SCRIPT, str(ROOT / "customer/backend.js")],
                           capture_output=True, text=True, check=True, cwd=ROOT)
        cls.out = json.loads(r.stdout.strip().splitlines()[-1])

    def test_never_parallel_reads(self):
        self.assertEqual(self.out["parallelDuringBurst"], 1)
        self.assertEqual(self.out["maxParallel"], 1)

    def test_burst_collapses_and_respects_min_gap(self):
        self.assertEqual(self.out["callsAfterBurst"], 1)
        self.assertEqual(self.out["callsBefore10s"], 1)
        self.assertEqual(self.out["callsAt10s"], 2)
        self.assertEqual(self.out["callsAfterInflight"], 2)
        self.assertEqual(self.out["callsAfterFollowUp"], 3)

    def test_hidden_tab_makes_no_reads_and_leaves(self):
        self.assertTrue(self.out["joined"])
        self.assertEqual(self.out["callsWhileHidden"], 0)
        self.assertTrue(self.out["leftOnHide"])

    def test_finished_order_leaves_channel(self):
        self.assertTrue(self.out["leftWhenDelivered"])

    def test_location_comes_from_snapshot(self):
        self.assertEqual(self.out["location"]["lat"], 3.1)
        # Multi-drop privacy (2026-10-04): no stop count reaches the customer UI.
        self.assertNotIn("stopsAhead", self.out)


if __name__ == "__main__":
    unittest.main()
