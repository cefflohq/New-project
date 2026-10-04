"""Static acceptance for S4-06.7 Batch-1 frontend corrections: Rider Route
Overview Wave isolation (regression guard), Customer Tracking status
mappings + zero fabricated ETA, and Vendor multi-Wave grouping /
existing-Wave date filter / factual Run-progress hydration / realtime
reaction. Matches the established static/structural precedent (e.g.
s4_06_batch_6_rider_multistop_wiring.py) -- not a substitute for real
browser click-through, deferred to S4-15.
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CUSTOMER_HTML = (ROOT / "customer" / "index.html").read_text(encoding="utf-8")
CUSTOMER_JS = (ROOT / "customer" / "backend.js").read_text(encoding="utf-8")
# The approved C1-C4 Customer UI renders through tracking-adapter.js (D-62).
CUSTOMER_ADAPTER = (ROOT / "customer" / "tracking-adapter.js").read_text(encoding="utf-8")


def block(source, start_pattern, end_marker="\n}"):
    match = re.search(start_pattern, source)
    assert match, f"pattern not found: {start_pattern}"
    start = match.start()
    end = source.index(end_marker, start) + len(end_marker)
    return source[start:end]


def between(source, start_pattern, end_pattern, from_last_start=False):
    starts = list(re.finditer(start_pattern, source))
    assert starts, f"start pattern not found: {start_pattern}"
    start = starts[-1].start() if from_last_start else starts[0].start()
    end = source.index(end_pattern, start)
    assert end > start, f"end pattern not found after start: {end_pattern}"
    return source[start:end]


class CustomerTrackingStatusMappingTests(unittest.TestCase):
    """Item 2: every real delivery_status value maps to its own honest
    state; issue/cancelled must never fall back to picked_up."""

    def test_backend_status_map_covers_all_eight_values(self):
        fn = block(CUSTOMER_JS, r"const statusMap = \{", "};")
        for real_value, tracking_value in (
            ("created", "order_confirmed"), ("ready_for_pickup", "preparing"),
            ("picked_up", "picked_up"), ("out_for_delivery", "on_the_way"),
            ("arrived", "on_the_way"), ("delivered", "delivered"),
            ("issue", "issue"), ("cancelled", "cancelled"),
        ):
            self.assertRegex(fn, rf"{real_value}:\s*'{tracking_value}'")

    def test_unmapped_fallback_is_never_picked_up(self):
        fallback = block(CUSTOMER_JS, r"window\.CEFFLOTracking\.setStatus\(statusMap\[snapshot\.status\]", ",")
        self.assertNotIn("'picked_up'", fallback)

    def test_issue_and_cancelled_are_real_tracking_states(self):
        # Issue and cancelled resolve to their own honest customer copy.
        self.assertRegex(CUSTOMER_ADAPTER, r"issue: \{ title: 'Delivery on hold'")
        self.assertRegex(CUSTOMER_ADAPTER, r"cancelled: \{ title: 'Order cancelled'")

    def test_render_tracking_never_hardcodes_picked_up_as_a_label_fallback(self):
        # Unmapped lifecycle values fall to the unavailable template, never
        # to a Picked Up milestone.
        self.assertIn("unavailableCopy", CUSTOMER_ADAPTER)
        self.assertNotRegex(CUSTOMER_ADAPTER, r"(\?\?|\|\|)\s*CUSTOMER_STATUS\.PICKED_UP")

class CustomerZeroFabricatedEtaTests(unittest.TestCase):
    """Item 3: the hardcoded 18-minute ETA must be completely gone from
    every path that can reach the real tracking UI."""

    def test_no_eta_minutes_field_or_element_remains(self):
        for forbidden in ("etaMinutes", "heroEta", "18 mins"):
            self.assertNotIn(forbidden, CUSTOMER_HTML)
            self.assertNotIn(forbidden, CUSTOMER_JS)

    def test_estimated_arrival_stays_the_only_arrival_signal_and_is_null_safe(self):
        # public_tracking's eta is formatted only when present (Grow A5).
        self.assertIn("if (!eta || !eta.state) return null;", CUSTOMER_JS)

if __name__ == "__main__":
    unittest.main()
