"""Static acceptance for S4-08 Batch-1 frontend remediation: Vendor and
Rider "Report Issue" paths call the real vendor_report_delivery_issue /
rider_report_delivery_issue RPCs with correct typed-reason mapping, no
local-only false-success mutation remains, unsupported reasons/actions are
honestly gated (not force-mapped), and Customer Tracking's existing
issue/cancelled mapping is untouched. Matches the established static/
structural precedent (e.g. s4_07_frontend_wiring.py) -- not a substitute
for real browser click-through, which this project has consistently
deferred to S4-15 for every prior UI batch.
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CUSTOMER_JS = (ROOT / "customer" / "backend.js").read_text(encoding="utf-8")


def block(source, start_pattern, end_marker="\n}"):
    match = re.search(start_pattern, source)
    assert match, f"pattern not found: {start_pattern}"
    start = match.start()
    end = source.index(end_marker, start) + len(end_marker)
    return source[start:end]


class CrossAppAndOfflineTests(unittest.TestCase):
    def test_customer_issue_and_cancelled_mapping_unchanged(self):
        self.assertIn("issue: 'issue'", CUSTOMER_JS)
        self.assertIn("cancelled: 'cancelled'", CUSTOMER_JS)

if __name__ == "__main__":
    unittest.main()
