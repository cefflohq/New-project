"""Static acceptance for Flow 3 F3-07: the live default Rider Profile
screen (pageRiderProfileProposed -- isVendorProposed() is hardcoded true)
previously read six fields mapRider() never set (r.deliveredToday,
r.successRate, r.avgTime, r.issuesCount, r.zoneExp, r.employment), so
every real Rider's profile rendered the literal text "undefined" for all
of them.

Master Section 17 requires "vehicle type; capacity... shown correctly".
Fixed by computing real derived values where a genuine canonical source
exists (today's delivered count from real completedAt timestamps, a real
completed/(completed+issue) success rate, a real open-issue count, a real
join date from riders.created_at, and the real vehicle type in place of
the fabricated employment field) and dropping the two fields with no
canonical backend source at all (avgTime, zoneExperience) rather than
inventing them.

Browser tooling is not connected in this environment, so this is a
static/structural check against the real source, matching the established
precedent (s4_06_batch_5b_vendor_run_builder_wiring.py and others).
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BACKEND_JS = (ROOT / "vendor" / "backend.js").read_text(encoding="utf-8")
INDEX_HTML = (ROOT / "vendor" / "index.html").read_text(encoding="utf-8")


def block(source, start_pattern, end_marker="\n}"):
    match = re.search(start_pattern, source)
    assert match, f"pattern not found: {start_pattern}"
    start = match.start()
    end = source.index(end_marker, start) + len(end_marker)
    return source[start:end]


class MapRiderTests(unittest.TestCase):
    def test_map_rider_carries_real_created_at(self):
        fn = block(BACKEND_JS, r"function mapRider\(row\) \{")
        self.assertIn("createdAt: row.created_at", fn)


class RiderProfileTruthfulnessTests(unittest.TestCase):
    def setUp(self):
        fn = block(INDEX_HTML, r"function pageRiderProfileProposed\(r, deliveredOrders\)\{")
        self.fn = fn[fn.index("const today="):]

    def test_no_undefined_field_reads(self):
        for field in ("r.deliveredToday", "r.successRate", "r.avgTime", "r.issuesCount", "r.zoneExp", "r.employment", "r.joined"):
            self.assertNotIn(field, self.fn)

    def test_delivered_today_computed_from_real_completed_at(self):
        self.assertIn("deliveredOrders.filter(o=>o.completedAt", self.fn)

    def test_success_rate_computed_from_real_orders(self):
        self.assertIn("deliveredOrders.length/(deliveredOrders.length+failedCount)", self.fn)

    def test_issues_count_from_real_open_issues(self):
        self.assertIn("state.issues.filter(", self.fn)

    def test_joined_from_real_created_at(self):
        self.assertIn("r.createdAt?new Date(r.createdAt)", self.fn)

    def test_vehicle_type_shown_instead_of_fabricated_employment(self):
        self.assertIn("r.vehicleType", self.fn)

    def test_no_field_with_no_canonical_source_is_fabricated(self):
        # avgTime and zoneExperience have no canonical backend source at
        # all -- must be dropped, never guessed/hardcoded.
        self.assertNotIn("avgTime", self.fn)
        self.assertNotIn("zoneExperience", self.fn)
        self.assertNotIn("zoneExp", self.fn)


if __name__ == "__main__":
    unittest.main()
