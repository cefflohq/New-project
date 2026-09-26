"""Static acceptance for Flow 3 F3-02 (final DoD reconciliation): the
"Recent Orders" Dashboard component Master Section 12 explicitly requires
("Recent Orders using approved compact treatment") was entirely absent
from pageDashboardProposed -- the live default Dashboard. "Current
Deliveries" (in-progress orders only) is a narrower, different concept
and does not satisfy this requirement.

Built from real state.orders (most-recently-created first, capped to 5),
reusing the already-proven .vd2-action row geometry/border/shadow and the
existing statusChip() component rather than inventing new, unverifiable
visual treatment -- matching the approved "Draft B" spec: compact rows,
clear Order ID, small supporting context (customer + item count),
restrained status pill, right-side chevron, minimal separators, a clean
"See all" link, and an honest empty state.

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


class RecentOrdersDashboardTests(unittest.TestCase):
    def setUp(self):
        self.fn = block(INDEX_HTML, r"function pageDashboardProposed\(\)\{")

    def test_recent_orders_sourced_from_real_state(self):
        self.assertIn("const recentOrders=[...state.orders].sort(", self.fn)
        self.assertIn(".slice(0,5)", self.fn)

    def test_recent_orders_section_present_with_see_all(self):
        self.assertIn("recentOrders.length?recentOrders.map(", self.fn)
        self.assertIn('data-nav="orders">${t(\'seeAll\')}</button>', self.fn)

    def test_each_row_shows_order_id_context_status_and_navigates_to_detail(self):
        self.assertIn('data-nav="orderDetail" data-navparams=\'{"id":"${o.id}"}\'', self.fn)
        self.assertIn("<b>${o.id}</b>", self.fn)
        self.assertIn("statusChip(o.status==='issue'?'issue':(o.status==='completed'?'completed':'ongoing'))", self.fn)

    def test_honest_empty_state(self):
        self.assertIn("No orders yet.", self.fn)

    def test_recent_orders_translation_key_defined_in_all_four_launch_locales(self):
        for expected in ('recentOrders:"Recent Orders"', 'recentOrders:"Pesanan Terkini"', 'recentOrders:"最近订单"', 'recentOrders:"சமீபத்திய ஆர்டர்கள்"'):
            self.assertIn(expected, INDEX_HTML)


if __name__ == "__main__":
    unittest.main()
