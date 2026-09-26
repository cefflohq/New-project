"""Static acceptance for Flow 3 F3-06: Active Runs / Run Detail.

Master Section 16 requires Run Detail to consume canonical run/session
identity, assigned Rider, ordered stops, completed/current/remaining
stops, delivery events, issues, and "latest Rider location only if real
location data exists". This screen did not exist in the Vendor app at
all before this change (confirmed: zero nav/page-name hits for any
"Active Runs"/"Run Detail" concept prior to this work).

A "Run" in this data model is one Rider's assignment set within one
delivery_session (Wave) -- computeRunProgress() already grouped
state.riderAssignments this way; this is the first real UI consumer of
that grouping (its only prior call site was inside the dead classic
pageDashboard() branch, unreachable since isVendorProposed() is
hardcoded true).

Two things this file deliberately proves are ABSENT, not present:
- No re-introduction of the removed local route/GPS engine.
- No Vendor-side manual stop-reorder action wired to save_run_sequence --
  that RPC gates on is_current_rider(p_rider_id), i.e. it is Rider-
  authorized only by Flow 2 design, not a Vendor gap; inventing a
  Vendor-side reorder UI would call an RPC that can never succeed for a
  Vendor caller.

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


class RiderLocationRpcTests(unittest.TestCase):
    def test_latest_rider_locations_wrapper_calls_real_rpc(self):
        fn = next(line for line in BACKEND_JS.splitlines() if "const latestRiderLocations" in line)
        self.assertIn("api.rpc('latest_rider_locations'", fn)

    def test_latest_rider_locations_exported(self):
        self.assertIn("latestRiderLocations", block(BACKEND_JS, r"window\.CEFFLO_VENDOR = Object\.freeze\(\{", end_marker="\n  });"))


class ActiveRunsPageTests(unittest.TestCase):
    def test_active_runs_registered_in_pages_map(self):
        self.assertIn("activeRuns: pageActiveRuns,", INDEX_HTML)
        self.assertIn("runDetail: pageRunDetail,", INDEX_HTML)

    def test_active_runs_built_from_real_assignment_grouping(self):
        fn = block(INDEX_HTML, r"function pageActiveRuns\(\)\{")
        self.assertIn("computeRunProgress()", INDEX_HTML[INDEX_HTML.index("function activeRuns()"):INDEX_HTML.index("function activeRuns()")+200])
        self.assertIn("data-nav=\"runDetail\"", fn)
        self.assertIn("No active runs", fn)

    def test_reachable_from_dashboard_current_deliveries(self):
        fn = block(INDEX_HTML, r"function pageDashboardProposed\(\)\{")
        self.assertIn('data-nav="activeRuns"', fn)
        self.assertIn("sessionId?'runDetail':'riderProfile'", fn)

    def test_reachable_from_settings_menu(self):
        self.assertIn("row('orders','Active Runs','activeRuns')", INDEX_HTML)

    def test_bottom_nav_highlights_settings_for_active_runs_and_run_detail(self):
        fn = block(INDEX_HTML, r"const isSettings = active===")
        self.assertIn("'activeRuns'", fn)
        self.assertIn("'runDetail'", fn)


class RunDetailPageTests(unittest.TestCase):
    def setUp(self):
        self.fn = block(INDEX_HTML, r"function pageRunDetail\(params\)\{")

    def test_shows_real_stops_events_and_issues(self):
        self.assertIn("state.riderAssignments.filter(", self.fn)
        self.assertIn("state.orderStatusHistory.filter(", self.fn)
        self.assertIn("state.issues.filter(", self.fn)

    def test_declined_and_cancelled_assignments_excluded_from_stops(self):
        self.assertIn("a.status!=='declined'", self.fn)
        self.assertIn("a.status!=='cancelled'", self.fn)

    def test_stops_ordered_by_real_sequence(self):
        self.assertIn("(a.sequence||0)-(b.sequence||0)", self.fn)

    def test_no_fabricated_eta(self):
        # Deliberately absent: compute_order_eta is internal-only since
        # Flow 2 F2-11 (no tenant check); no canonical Vendor-facing ETA
        # source exists, so none is shown -- never invented.
        self.assertNotIn("etaMinutes", self.fn)
        self.assertNotIn("estimatedArrivalAt", self.fn)
        self.assertNotIn(">ETA<", self.fn)

    def test_rider_location_shows_real_row_or_honest_absence_never_fabricated(self):
        self.assertIn("latestRiderLocations", INDEX_HTML[INDEX_HTML.index("function loadRunDetailLocation"):INDEX_HTML.index("function loadRunDetailLocation")+400])
        self.assertIn("No location reported yet.", self.fn)
        self.assertNotIn("Math.random", self.fn)


class NoReorderRpcMisuseTests(unittest.TestCase):
    def test_vendor_app_never_calls_save_run_sequence(self):
        # save_run_sequence(p_rider_id, ...) is gated on is_current_rider --
        # a Vendor caller can never pass that check. No Vendor call-site
        # must exist for it; the gap is Flow 2's intentional design
        # (Rider owns mid-run resequencing), not something to route around.
        self.assertNotIn("save_run_sequence", BACKEND_JS)
        self.assertNotIn("saveRunSequence", BACKEND_JS)

    def test_no_reintroduced_local_route_engine(self):
        for symbol in (
            "CEFFLO_ENGINE.route", "sequenceOrdersNearestNeighbor",
            "recalculateAssignmentRoute", "startRiderGps(riderId)",
        ):
            self.assertNotIn(symbol, INDEX_HTML)


if __name__ == "__main__":
    unittest.main()
