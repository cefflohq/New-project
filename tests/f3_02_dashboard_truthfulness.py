"""Static acceptance for Flow 3 F3-02/F3-12: the live default Vendor
Dashboard (pageDashboardProposed -- isVendorProposed() is hardcoded true,
so this is what every Vendor actually sees, not a preview) must never pad
a real KPI to a fabricated minimum or fall back to hardcoded fake data.

Master Section 12: "No fabricated metrics. If a metric is not supported
by canonical backend, remove/defer it rather than calculate misleading
local estimates." This was violated on the primary landing screen: KPIs
were floored with Math.max(N, real) (a brand-new business with zero real
orders still showed "12 orders"/"6 riders"/"2 issues"/"75% completed"),
the Action Required list fell back to a hardcoded fake issue ('CF-0127
has a delivery issue reported'), a hardcoded fake offline Rider ('Farid
Aziz' in 'Zone D'), and an artificially inflated payment count; and
Current Deliveries was built from an arbitrary slice of ALL riders with
a fabricated ETA table ([18,25,32,40]) and fake order ids, ignoring the
real getCurrentDeliveries() the function had already computed.

Browser tooling is not connected in this environment, so this is a
static/structural check against the real source, matching the established
precedent (s4_06_batch_5b_vendor_run_builder_wiring.py and others).
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INDEX_HTML = (ROOT / "vendor" / "index.html").read_text(encoding="utf-8")


def block(source, start_pattern, end_marker="\n}"):
    match = re.search(start_pattern, source)
    assert match, f"pattern not found: {start_pattern}"
    start = match.start()
    end = source.index(end_marker, start) + len(end_marker)
    return source[start:end]


class LiveDashboardIdentityTests(unittest.TestCase):
    def test_proposed_dashboard_is_confirmed_live_default(self):
        # If this ever flips, the whole premise of this test file (that
        # pageDashboardProposed is what a real Vendor sees) must be
        # re-verified, not silently assumed.
        self.assertIn("function isVendorProposed(){ return true; }", INDEX_HTML)


class DashboardTruthfulnessTests(unittest.TestCase):
    def setUp(self):
        fn = block(INDEX_HTML, r"function pageDashboardProposed\(\)\{")
        # Strip this file's own explanatory comment block (which
        # necessarily quotes the old fake values for documentation) before
        # asserting on the live code -- otherwise every literal-text check
        # below would trivially "pass" by matching prose about the fix
        # rather than the code itself.
        self.fn = fn[fn.index("const currentDeliveries="):]

    def test_no_fabricated_kpi_floor(self):
        self.assertNotIn("Math.max(12,totalOrders()", self.fn)
        self.assertNotIn("Math.max(6,activeRidersCount()", self.fn)
        self.assertNotIn("Math.max(2,issuesCount()", self.fn)
        self.assertNotIn("Math.max(75,completedPct()", self.fn)
        self.assertIn("<strong>${totalOrders()}</strong>", self.fn)
        self.assertIn("<strong>${activeRidersCount()}</strong>", self.fn)
        self.assertIn("<strong>${issuesCount()}</strong>", self.fn)
        self.assertIn("<strong>${completedPct()}%</strong>", self.fn)

    def test_no_hardcoded_fake_issue_fallback(self):
        self.assertNotIn("CF-0127", self.fn)
        self.assertIn("if(wrongAddr) actions.push(", self.fn)

    def test_no_hardcoded_fake_offline_rider_fallback(self):
        self.assertNotIn("Farid Aziz", self.fn)
        self.assertNotIn("Zone D", self.fn)
        self.assertIn("if(offline) actions.push(", self.fn)

    def test_no_inflated_payment_count(self):
        self.assertNotIn("Math.max(4,", self.fn)
        self.assertIn("if(pendingPayment>0)", self.fn)

    def test_no_fabricated_eta_table_or_fake_order_ids(self):
        self.assertNotIn("[18,25,32,40]", self.fn)
        self.assertNotIn("CF-${String(1024+index)", self.fn)

    def test_current_deliveries_sourced_from_real_computation(self):
        # Must be built from the real getCurrentDeliveries() list, not an
        # arbitrary slice of all riders regardless of delivery status.
        self.assertIn("currentDeliveries.slice(0,4)", self.fn)
        self.assertNotIn("state.riders.slice(0,4)", self.fn)

    def test_empty_states_are_honest_not_silently_absent(self):
        self.assertIn("No deliveries currently in progress.", self.fn)
        self.assertIn("Nothing needs attention right now.", self.fn)


if __name__ == "__main__":
    unittest.main()
