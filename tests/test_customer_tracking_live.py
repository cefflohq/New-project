"""Phase 2B.3 (D-65): Customer Tracking token mode projects ONLY the
public_tracking snapshot -- no prototype fixture value may reach a real
order -- and maps lifecycle states truthfully. Runs the real ES modules in
Node with a minimal window shim; no network, no database."""

import json
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

SCRIPT = r"""
globalThis.window = {};
const m = await import(process.argv[1]);
const f = await import(process.argv[2]);
const provider = { store: m.createTrackingStore(m.buildLoadingViewModel()) };
const bridge = m.installBackendBridge(provider, { source: f.TRACKING_FIXTURE, live: true });
const snap = (status, extra = {}) => {
  bridge.setStatus(status, { orderId: '#CF-001', storeName: 'Kedai A', riderName: 'Aiman',
    estimatedArrival: '—', deliveredAt: '—', podPhoto: null, ...extra });
  return provider.store.getState();
};
const out = {};
for (const s of ['order_confirmed', 'preparing', 'picked_up', 'on_the_way', 'delivered', 'issue', 'cancelled']) out[s] = snap(s);
out.delivered_pod = snap('delivered', { deliveredAt: '09:15 PM', podPhoto: 'https://signed.example/pod' });
bridge.fail(); out.fail = provider.store.getState();
out.fixtureStrings = [f.TRACKING_FIXTURE.vendor.tagline, f.TRACKING_FIXTURE.vendor.address, f.TRACKING_FIXTURE.rider.name,
  f.TRACKING_FIXTURE.rider.vehicle, f.TRACKING_FIXTURE.rider.plate, f.TRACKING_FIXTURE.delivery.address,
  f.TRACKING_FIXTURE.delivery.receivedBy, f.TRACKING_FIXTURE.order.itemsLabel, f.TRACKING_FIXTURE.order.note,
  f.TRACKING_FIXTURE.pickup.atLabel, f.TRACKING_FIXTURE.reference, f.TRACKING_FIXTURE.pod.riderNote,
  f.TRACKING_FIXTURE.vendor.storefrontPhoto, f.TRACKING_FIXTURE.rider.photo, f.TRACKING_FIXTURE.eta.valueLabel];
console.log(JSON.stringify(out));
"""


def run_bridge():
    result = subprocess.run(
        ["node", "--input-type=module", "-e", SCRIPT,
         (ROOT / "customer/tracking-adapter.js").as_uri(), (ROOT / "customer/fixtures.js").as_uri()],
        capture_output=True, text=True, check=True, cwd=ROOT)
    return json.loads(result.stdout)


class CustomerTrackingLiveTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.out = run_bridge()

    def test_pre_activation_is_neutral_no_order_yet(self):
        for status in ("order_confirmed", "preparing"):
            vm = self.out[status]
            self.assertEqual(vm["phase"], "unavailable")
            self.assertEqual(vm["statusTitle"], "No order yet")
            self.assertEqual(vm["statusBody"], "Tracking starts when your rider collects the order.")
            self.assertTrue(vm["quiet"])

    def test_activation_and_progress_follow_backend_status(self):
        reached = lambda vm: [m["reached"] for m in vm["milestones"]]
        self.assertEqual(reached(self.out["picked_up"]), [True, False, False])
        self.assertEqual(reached(self.out["on_the_way"]), [True, True, False])
        self.assertEqual(reached(self.out["delivered"]), [True, True, True])
        self.assertEqual(self.out["on_the_way"]["rider"]["name"], "Aiman")

    def test_order_number_and_store_come_from_snapshot(self):
        vm = self.out["picked_up"]
        self.assertEqual(vm["reference"], "#CF-001")
        self.assertEqual(vm["vendor"]["name"], "Kedai A")

    def test_no_fixture_value_reaches_a_real_order(self):
        blob = json.dumps({k: v for k, v in self.out.items() if k != "fixtureStrings"})
        for value in self.out["fixtureStrings"]:
            self.assertNotIn(value, blob)
        self.assertIsNone(self.out["on_the_way"]["route"])
        self.assertIsNone(self.out["on_the_way"]["eta"])
        self.assertIsNone(self.out["delivered"]["pod"])

    def test_delivered_uses_real_time_and_pod_only_when_present(self):
        vm = self.out["delivered_pod"]
        self.assertEqual(vm["delivery"]["atLabel"], "09:15 PM")
        self.assertEqual(vm["pod"]["url"], "https://signed.example/pod")

    def test_issue_cancelled_and_invalid_are_truthful(self):
        self.assertEqual(self.out["issue"]["statusTitle"], "Delivery on hold")
        self.assertEqual(self.out["cancelled"]["statusTitle"], "Order cancelled")
        self.assertEqual(self.out["fail"]["statusTitle"], "Tracking unavailable")
        self.assertNotIn("Brew", json.dumps(self.out["fail"]))

    def test_customer_backend_uses_token_only(self):
        backend = (ROOT / "customer/backend.js").read_text()
        self.assertIn("get('token')", backend)
        self.assertIn("rpc('public_tracking', { p_token: token }", backend)
        self.assertNotIn("order_number, p_", backend)


if __name__ == "__main__":
    unittest.main()
