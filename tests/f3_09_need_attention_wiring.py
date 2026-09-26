"""Static acceptance for Flow 3 F3-09: Need Attention.

Master Section 19 requires a single place for operational exceptions
(unresolved address, out-of-coverage/capacity conflicts, delivery issues,
Rider unavailable, stuck/abnormal runs). No such screen existed in the
Vendor app before this change (zero prior hits for any "Need Attention"
concept).

Built only from canonical sources -- no local "attention" array is ever
synthesized. Reuses suggestedRunsState/loadSuggestedRuns() (its
unplannable_orders IS Flow 2's own server-side exception classification
from propose_delivery_plan) rather than reimplementing that
classification client-side, plus real state.issues and offline Riders.
"Stuck/abnormal run" detection is honestly omitted -- no canonical
backend signal exists for it, and inventing a client-side staleness
threshold would be exactly the kind of business logic Master Section 0
forbids duplicating locally.

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


class NeedAttentionRegistrationTests(unittest.TestCase):
    def test_registered_in_pages_map(self):
        self.assertIn("needAttention: pageNeedAttention,", INDEX_HTML)

    def test_reachable_from_settings_menu(self):
        self.assertIn("row('alert','Need Attention','needAttention')", INDEX_HTML)

    def test_bottom_nav_highlights_settings(self):
        fn = block(INDEX_HTML, r"const isSettings = active===")
        self.assertIn("'needAttention'", fn)


class NeedAttentionContentTests(unittest.TestCase):
    def setUp(self):
        self.fn = block(INDEX_HTML, r"function pageNeedAttention\(\)\{")

    def test_reuses_canonical_plan_exception_list_not_local_reclassification(self):
        self.assertIn("suggestedRunsState.plan?.unplannable_orders", self.fn)
        self.assertIn("loadSuggestedRuns()", self.fn)

    def test_includes_real_open_issues_and_offline_riders(self):
        self.assertIn("state.issues.filter(i=>i.status!=='resolved')", self.fn)
        self.assertIn("state.riders.filter(r=>r.status==='offline')", self.fn)

    def test_no_local_attention_array_fabrication(self):
        self.assertNotIn("state.attention", self.fn)
        self.assertNotIn("fakeAttention", self.fn)

    def test_honest_empty_and_loading_states(self):
        self.assertIn("Nothing needs attention", self.fn)
        self.assertIn("Loading", self.fn)

    def test_shared_fetch_rerenders_need_attention_when_open(self):
        rerender_fn = block(INDEX_HTML, r"function rerenderSuggestedRunsIfOpen\(\)\{")
        self.assertIn("'needAttention'", rerender_fn)


if __name__ == "__main__":
    unittest.main()
