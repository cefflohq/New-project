"""Bounded static acceptance for S4-09-REMEDIATION-02.

CSV parsing and preview remain reachable, but confirmation is honestly gated
because the current CSV shape lacks the real item data required by the
canonical manual-order workflow. Existing authoritative and prior-remediation
paths are guarded as regressions.
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


class CsvReachabilityAndGateTests(unittest.TestCase):
    def test_csv_import_and_confirmation_remain_reachable(self):
        self.assertIn('data-action="startCsvImport"', VENDOR_HTML)
        self.assertIn('data-action="openImportFilePicker"', VENDOR_HTML)
        self.assertIn('data-action="confirmCsvImport"', VENDOR_HTML)
        self.assertIn("function parseCsvText(text){", VENDOR_HTML)
        self.assertIn("function confirmCsvImport(){", VENDOR_HTML)

    def test_confirmation_has_zero_operational_mutation(self):
        fn = block(VENDOR_HTML, r"function confirmCsvImport\(\)\{")
        for forbidden in (
            "state.", "state.orders", "unshift(", "push(", "genOrderId(",
            "Math.random(", "persistOperationalStore(", "syncZonesFromOrders(",
            "syncNewAccountOnboarding(", "transitionOrderStatus(", "api.rpc(",
            "api.request(", "fetch(",
        ):
            self.assertNotIn(forbidden, fn)

    def test_confirmation_is_honestly_unavailable(self):
        fn = block(VENDOR_HTML, r"function confirmCsvImport\(\)\{")
        self.assertIn("CSV import is not connected yet.", fn)
        self.assertIn("'error'", fn)
        self.assertNotIn("'success'", fn)
        self.assertNotIn("ordersImportedSuccess", fn)
        self.assertNotIn("navigate('orders'", fn)

    def test_no_fake_order_data_remains_in_live_confirmation(self):
        fn = block(VENDOR_HTML, r"function confirmCsvImport\(\)\{")
        for fabricated in (
            "Nasi Lemak Ayam", "readyForPickup", "eta:15", "payment:'Pending'",
            "Order received", "Just now", "validRows.length",
        ):
            self.assertNotIn(fabricated, fn)


class RecentImportsTruthfulnessTests(unittest.TestCase):
    def test_fake_historical_imports_are_removed(self):
        self.assertNotIn("Orders_16May.csv", VENDOR_HTML)
        self.assertNotIn("Orders_15May.csv", VENDOR_HTML)
        self.assertNotIn("128 ${t('rows')}", VENDOR_HTML)
        self.assertNotIn("96 ${t('rows')}", VENDOR_HTML)

    def test_honest_empty_state_is_visible(self):
        page = block(VENDOR_HTML, r"function pageCsvImport\(\)\{")
        self.assertIn("No recent imports", page)


class CanonicalAndRegressionTests(unittest.TestCase):
    def test_manual_create_order_remains_authoritative(self):
        handler = block(VENDOR_JS, r"wizSubmit = async function \(\) \{", "\n  };")
        self.assertIn("await createDelivery(", handler)
        self.assertIn("await hydrateCanonicalWorkspace();", handler)
        self.assertLess(handler.index("await createDelivery("), handler.index("toast(tf('orderCreatedSuccess'"))
        self.assertIn("api.rpc('create_delivery'", VENDOR_JS)

    def test_csv_cannot_supply_business_or_mutate_tables_directly(self):
        parser = block(VENDOR_HTML, r"function parseCsvText\(text\)\{")
        self.assertNotIn("business", parser.lower())
        confirm = block(VENDOR_HTML, r"function confirmCsvImport\(\)\{")
        self.assertNotIn("businessId", confirm)
        self.assertNotIn("/rest/v1/", confirm)

    def test_s4_08_vendor_issue_surfaces_remain_authoritative(self):
        detail = block(VENDOR_HTML, r"function confirmReportIssue\(el\)\{")
        self.assertIn("ACTIONS.confirmReportDeliveryIssue(", detail)
        delivery = block(VENDOR_JS, r"ACTIONS\.confirmReportDeliveryIssue = async function \(el\) \{")
        self.assertIn("await reportDeliveryIssue(", delivery)
        self.assertIn("api.rpc('vendor_report_delivery_issue'", VENDOR_JS)

    def test_remediation_01_gates_remain_intact(self):
        # Grow V1 Flow 2 (A6): confirmReschedule is now genuinely wired to
        # initiate_delivery_recovery (backend.js), not a stub -- the
        # index.html pre-declaration is the standard "Backend not
        # connected." fallback every other real action uses before
        # backend.js overrides it. This gate now verifies the real RPC
        # wiring exists and never claims local-only success, rather than
        # verifying the feature stayed disconnected.
        reschedule = block(VENDOR_HTML, r"function confirmReschedule\(el\)\{")
        start_delivery = block(VENDOR_HTML, r"function startDeliveryForRider\(riderId\)\{")
        self.assertIn("Backend not connected.", reschedule)
        self.assertNotIn("transitionOrderStatus", reschedule)
        self.assertIn("api.rpc('initiate_delivery_recovery'", VENDOR_JS)
        self.assertIn("Starting delivery for a rider is not connected in Vendor yet.", start_delivery)
        self.assertNotIn("transitionOrderStatus", start_delivery)

    def test_assignment_and_run_builder_contracts_remain_present(self):
        for rpc in ("assign_rider", "reassign_rider", "build_rider_run"):
            self.assertIn(f"api.rpc('{rpc}'", VENDOR_JS)


if __name__ == "__main__":
    unittest.main()
