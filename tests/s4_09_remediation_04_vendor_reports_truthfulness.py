"""Bounded static acceptance for S4-09-REMEDIATION-04.

Vendor Reports may expose only deterministic aggregates from the canonical
hydrated workspace. Unsupported delivery-duration and accounting claims must
remain unavailable rather than being fabricated.
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VENDOR_HTML = (ROOT / "vendor" / "index.html").read_text(encoding="utf-8")
VENDOR_JS = (ROOT / "vendor" / "backend.js").read_text(encoding="utf-8")


def block(source, start_pattern, end_marker="\n}"):
    match = re.search(start_pattern, source)
    assert match, f"pattern not found: {start_pattern}"
    start = match.start()
    end = source.index(end_marker, start) + len(end_marker)
    return source[start:end]


REPORTS_PAGE = block(VENDOR_HTML, r"function pageReports\(\)\{")
REPORTS_SNAPSHOT = block(VENDOR_HTML, r"function getReportsSnapshot\(")
REPORT_PERIOD = block(VENDOR_HTML, r"function reportPeriodKeys\(")
REPORT_EXPORT = block(VENDOR_HTML, r"function exportRows\(\)\{")


class ReportsReachabilityAndSourceTests(unittest.TestCase):
    def test_reports_route_and_current_trigger_remain(self):
        self.assertIn("reports: pageReports", VENDOR_HTML)
        proposed_settings = block(VENDOR_HTML, r"function pageSettingsProposed\(\)\{")
        self.assertIn("row('report',t('reports'),'reports')", proposed_settings)
        self.assertIn('data-action="setReportRange"', REPORTS_PAGE)

    def test_reports_require_canonical_remote_hydration(self):
        self.assertIn("backendState.mode!=='remote'", REPORTS_SNAPSHOT)
        self.assertIn("backendState.mode = 'remote'", VENDOR_JS)
        self.assertIn("state.orders = orders.map(mapOrder)", VENDOR_JS)

    def test_aggregates_use_canonical_order_fields(self):
        for marker in (
            "state.orders.filter", "order.createdAt", "order.status==='completed'",
            "order.status==='issue'", "order.zoneId===zone.id", "order.riderId===rider.id",
        ):
            self.assertIn(marker, REPORTS_SNAPSHOT)

    def test_no_new_reporting_backend_contract(self):
        reports_code = REPORTS_SNAPSHOT + REPORT_PERIOD + REPORTS_PAGE + REPORT_EXPORT
        self.assertNotIn("api.rpc(", reports_code)
        self.assertNotIn("/rest/v1/", reports_code)
        self.assertNotIn("supabase", reports_code.lower())
        self.assertNotIn("service_role", reports_code.lower())


class MetricTruthfulnessTests(unittest.TestCase):
    def test_hardcoded_average_delivery_time_is_gone(self):
        self.assertNotIn("24 min", REPORTS_PAGE)
        self.assertIn("${t('avgDeliveryTime')} · ${t('notSet')}", REPORTS_PAGE)

    def test_known_hardcoded_trend_is_gone(self):
        self.assertNotIn("[80,95,70,110,90,128,105]", VENDOR_HTML)
        self.assertIn("report.dailyCounts", REPORTS_PAGE)

    def test_reports_have_no_random_analytics(self):
        reports_code = REPORTS_SNAPSHOT + REPORT_PERIOD + REPORTS_PAGE
        self.assertNotIn("Math.random", reports_code)

    def test_no_revenue_or_payment_metric_is_presented_or_exported(self):
        reports_code = REPORTS_PAGE + REPORT_EXPORT
        for forbidden in ("Revenue", "Profit", "Balance", "Payment:", "Total:o.total"):
            self.assertNotIn(forbidden, reports_code)

    def test_zero_and_unknown_have_distinct_semantics(self):
        self.assertIn("total:orders.length", REPORTS_SNAPSHOT)
        self.assertIn("issues:issues.length", REPORTS_SNAPSHOT)
        self.assertIn("completionRate:orders.length?", REPORTS_SNAPSHOT)
        self.assertIn("report.completionRate===null?'--'", REPORTS_PAGE)

    def test_unsupported_delivery_duration_is_not_derived(self):
        reports_code = REPORTS_SNAPSHOT + REPORTS_PAGE
        self.assertNotIn("completedAt", reports_code)
        self.assertNotIn("approvedAt", reports_code)
        self.assertNotIn("createdAt)-", reports_code)

    def test_zone_and_rider_values_do_not_use_mock_summary_fields(self):
        self.assertNotIn("orderIds.length", REPORTS_PAGE)
        self.assertNotIn("deliveredToday", REPORTS_PAGE)
        self.assertIn("report.zoneCounts", REPORTS_PAGE)
        self.assertIn("report.riderCounts", REPORTS_PAGE)


class TrendAndRangeTests(unittest.TestCase):
    def test_range_filter_changes_source_date_keys(self):
        self.assertIn("range==='thisWeek'", REPORT_PERIOD)
        self.assertIn("range==='thisMonth'", REPORT_PERIOD)
        self.assertIn("allowedKeys.has(reportDateKey(order.createdAt))", REPORTS_SNAPSHOT)

    def test_grouping_uses_genuine_created_timestamp(self):
        self.assertIn("reportDateKey(order.createdAt)===key", REPORTS_SNAPSHOT)
        self.assertIn("createdAt: row.created_at", VENDOR_JS)

    def test_empty_periods_are_deterministic_zero(self):
        self.assertIn("periodKeys.map(key=>orders.filter", REPORTS_SNAPSHOT)
        self.assertIn("trendMax===0?100", REPORTS_PAGE)

    def test_chart_label_describes_order_count(self):
        self.assertIn("${t('ordersTrend')}", REPORTS_PAGE)
        self.assertNotIn("revenue", REPORTS_PAGE.lower())


class ExistingRemediationRegressionTests(unittest.TestCase):
    def test_manual_order_creation_and_hydration_remain_authoritative(self):
        self.assertIn("function wizSubmit()", VENDOR_HTML)
        self.assertIn("wizSubmit = async function ()", VENDOR_JS)
        self.assertIn("await createDelivery({ businessId: state.businessId", VENDOR_JS)
        self.assertIn("return api.rpc('create_delivery'", VENDOR_JS)
        self.assertIn("async function hydrateCanonicalWorkspace()", VENDOR_JS)

    def test_s4_08_issue_reporting_remains_authoritative(self):
        self.assertIn("api.rpc('vendor_report_delivery_issue'", VENDOR_JS)
        self.assertIn("ACTIONS.confirmReportDeliveryIssue = async function", VENDOR_JS)

    def test_s4_09_01_gates_remain(self):
        self.assertIn("Re-delivery scheduling is not connected yet.", VENDOR_HTML)
        self.assertIn("Starting delivery for a rider is not connected in Vendor yet.", VENDOR_HTML)

    def test_s4_09_02_csv_gate_remains(self):
        csv = block(VENDOR_HTML, r"function confirmCsvImport\(\)\{")
        self.assertIn("CSV import is not connected yet.", csv)
        self.assertNotIn("state.orders", csv)

    def test_s4_09_03_password_update_remains_authoritative(self):
        save = block(VENDOR_HTML, r"async function savePasswordChange\(el\)\{")
        self.assertIn("await reauthenticateCurrentUser(current)", save)
        self.assertIn("await updateAuthenticatedPassword(newPw)", save)
        self.assertNotIn("state.localPassword", VENDOR_HTML)


if __name__ == "__main__":
    unittest.main()
