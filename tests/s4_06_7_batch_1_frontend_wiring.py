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
RIDER_HTML = (ROOT / "rider" / "index.html").read_text(encoding="utf-8")
VENDOR_HTML = (ROOT / "vendor" / "index.html").read_text(encoding="utf-8")
VENDOR_JS = (ROOT / "vendor" / "backend.js").read_text(encoding="utf-8")
CUSTOMER_HTML = (ROOT / "customer" / "index.html").read_text(encoding="utf-8")
CUSTOMER_JS = (ROOT / "customer" / "backend.js").read_text(encoding="utf-8")


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


class RiderRouteOverviewWaveIsolationTests(unittest.TestCase):
    """Item 1: the LIVE (last-defined, per this codebase's own
    later-reassignment-wins convention) renderRouteOverview must read the
    Wave-scoped Run list, never the flat cross-Wave appState.orders."""

    def test_live_definition_is_wave_scoped(self):
        live = between(RIDER_HTML, r"renderRouteOverview=function\(\)\{", "renderMapStopDetail=function(){", from_last_start=True)
        self.assertIn("activeRunOrders()", live)
        self.assertNotIn("const orders=appState.orders", live)


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
        self.assertIn("ISSUE: 'issue'", CUSTOMER_HTML)
        self.assertIn("CANCELLED: 'cancelled'", CUSTOMER_HTML)
        self.assertIn("issue: 'Delivery Issue'", CUSTOMER_HTML)
        self.assertIn("cancelled: 'Cancelled'", CUSTOMER_HTML)

    def test_render_tracking_never_hardcodes_picked_up_as_a_label_fallback(self):
        fn = between(CUSTOMER_HTML, r"function renderTracking\(status\) \{", "function restoreRating")
        self.assertIn("TRACKING_STATUS_LABEL[status]", fn)
        self.assertNotIn("heroStatus.textContent = 'Picked Up'", fn)


class CustomerZeroFabricatedEtaTests(unittest.TestCase):
    """Item 3: the hardcoded 18-minute ETA must be completely gone from
    every path that can reach the real tracking UI."""

    def test_no_eta_minutes_field_or_element_remains(self):
        for forbidden in ("etaMinutes", "heroEta", "18 mins"):
            self.assertNotIn(forbidden, CUSTOMER_HTML)
            self.assertNotIn(forbidden, CUSTOMER_JS)

    def test_estimated_arrival_stays_the_only_arrival_signal_and_is_null_safe(self):
        fn = block(CUSTOMER_JS, r"async function refresh\(\) \{")
        self.assertIn("snapshot.eta ? new Date(snapshot.eta)", fn)


class VendorMultiWaveGroupingTests(unittest.TestCase):
    """Item 4: same Rider + same Zone in two different Waves must never
    merge into one dashboard card."""

    def test_current_deliveries_group_key_includes_session(self):
        fn = block(VENDOR_HTML, r"function getCurrentDeliveries\(\)\{")
        self.assertIn("order.deliverySessionId", fn)
        self.assertRegex(fn, r"key=`\$\{order\.deliverySessionId")

    def test_today_metrics_consider_every_open_session_not_just_one(self):
        fn = block(VENDOR_HTML, r"function todaysRelevantOrders\(\)\{")
        self.assertIn("todaysOpenSessionIds", fn)
        metrics_fn = block(VENDOR_HTML, r"function getTodayDashboardMetrics\(\)\{")
        self.assertIn("todaysRelevantOrders()", metrics_fn)


class VendorExistingWaveDateFilterTests(unittest.TestCase):
    """Item 5: the existing-Wave picker must not offer a stale Wave from a
    different delivery_date as a normal assignment target."""

    def test_existing_waves_filtered_by_delivery_date(self):
        fn = block(VENDOR_HTML, r"function runBuilderExistingWaves\(\)\{")
        self.assertIn("s.deliveryDate===today", fn)
        self.assertIn("operationalDateKey()", fn)


class VendorRunProgressHydrationTests(unittest.TestCase):
    """Item 6: real assignment-state/pickup/delivery progress must be
    hydrated from the actual backend, not left permanently empty."""

    def test_hydrate_no_longer_hardcodes_empty_assignment_state(self):
        fn = block(VENDOR_JS, r"async function hydrateCanonicalWorkspace\(\) \{")
        self.assertNotIn("state.riderAssignments = [];", fn)
        self.assertNotIn("state.deliveryStops = [];", fn)
        self.assertIn("listRiderAssignments(selected.business_id)", fn)
        self.assertIn("state.riderAssignments = assignments.map(mapAssignment)", fn)

    def test_assignment_read_selects_real_status_and_embedded_stop(self):
        self.assertIn("select=id,rider_id,delivery_session_id,status,accepted_at,delivery_stops(id,order_id,status,sequence)", VENDOR_JS)

    def test_run_progress_reads_only_real_assignment_data(self):
        fn = block(VENDOR_HTML, r"function computeRunProgress\(\)\{")
        self.assertIn("state.riderAssignments.forEach", fn)
        for forbidden in ("Math.random", "etaMinutes", "fake"):
            self.assertNotIn(forbidden, fn)

    def test_dashboard_renders_run_progress_section(self):
        fn = block(VENDOR_HTML, r"function pageDashboard\(\)\{")
        self.assertIn("computeRunProgress()", fn)
        self.assertIn("Run Progress", fn)


class VendorRealtimeReactionTests(unittest.TestCase):
    """Item 7: Rider Accept/Decline and Run progress must become observable
    without the Vendor guessing from orders.assigned_rider_id alone -- and
    the subscription must actually be established, not merely defined."""

    def test_subscribe_listens_on_assignment_and_stop_tables(self):
        fn = block(VENDOR_JS, r"function subscribe\(businessId, refresh\) \{")
        self.assertIn("table: 'rider_assignments'", fn)
        self.assertIn("table: 'delivery_stops'", fn)
        self.assertIn("table: 'orders'", fn)

    def test_subscribe_is_actually_invoked(self):
        self.assertIn("subscribe(state.businessId,", VENDOR_JS)


if __name__ == "__main__":
    unittest.main()
