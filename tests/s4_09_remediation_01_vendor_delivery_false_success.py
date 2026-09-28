"""Bounded static acceptance for S4-09-REMEDIATION-01.

The two reachable Vendor controls remain present but cannot manufacture
reschedule or Rider lifecycle success. Existing S4-08 issue wiring and the
assignment/Run Builder paths are guarded as regressions. This follows the
project's established static frontend-wiring test precedent; browser E2E is
outside this narrowly authorized remediation.
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


class RescheduleGateTests(unittest.TestCase):
    def test_trigger_and_confirm_action_remain_reachable(self):
        self.assertIn('data-action="openReschedule"', VENDOR_HTML)
        self.assertIn('data-action="confirmReschedule"', VENDOR_HTML)
        self.assertIn("function confirmReschedule(el){", VENDOR_HTML)

    def test_confirm_does_not_mutate_operational_state(self):
        fn = block(VENDOR_HTML, r"function confirmReschedule\(el\)\{")
        for forbidden in (
            "transitionOrderStatus", "state.", ".activity.push", "deliveryExecState",
            "orderStatusHistory", "deliveryEvents", "api.rpc", "api.request",
        ):
            self.assertNotIn(forbidden, fn)

    def test_confirm_is_honestly_gated_without_success_claim(self):
        # Grow V1 Flow 2 (A6): the index.html pre-declaration is now the
        # standard "Backend not connected." stub text (matching every other
        # real action's pre-backend.js-load fallback), not the older
        # feature-specific "not connected yet" wording -- backend.js
        # overrides this with the real initiate_delivery_recovery wiring.
        fn = block(VENDOR_HTML, r"function confirmReschedule\(el\)\{")
        self.assertIn("not connected", fn)
        self.assertIn("'error'", fn)
        self.assertNotIn("Re-delivery scheduled", fn)
        self.assertNotIn("notified", fn.lower())
        self.assertNotIn("'success'", fn)


class VendorStartDeliveryGateTests(unittest.TestCase):
    def test_completed_verification_slider_remains_reachable(self):
        self.assertIn('data-oncomplete="startDeliveryForRider"', VENDOR_HTML)
        self.assertIn("ACTIONS.startDeliveryForRider = startDeliveryForRider", VENDOR_HTML)

    def test_handler_does_not_mutate_or_advance_vendor_state(self):
        fn = block(VENDOR_HTML, r"function startDeliveryForRider\(riderId\)\{")
        for forbidden in (
            "transitionOrderStatus", "state.", ".activity.push", "deliveryExecState",
            "deliveringStatus", "navigate(", "render(", "api.rpc", "api.request",
        ):
            self.assertNotIn(forbidden, fn)

    def test_handler_does_not_impersonate_rider_or_call_rider_rpc(self):
        fn = block(VENDOR_HTML, r"function startDeliveryForRider\(riderId\)\{")
        self.assertNotIn("api.rpc('start_run_delivery'", fn)
        self.assertNotIn("startRunDelivery(", fn)
        self.assertNotIn("p_rider_id", fn)
        self.assertNotIn("Rider picked up", fn)
        self.assertNotIn("Delivery started", fn)

    def test_handler_is_honestly_gated(self):
        fn = block(VENDOR_HTML, r"function startDeliveryForRider\(riderId\)\{")
        self.assertIn("not connected", fn)
        self.assertIn("'error'", fn)
        self.assertNotIn("'success'", fn)


class PreservedAuthoritativePathsTests(unittest.TestCase):
    def test_both_vendor_s4_08_issue_surfaces_remain_authoritative(self):
        detail = block(VENDOR_HTML, r"function confirmReportIssue\(el\)\{")
        self.assertIn("ACTIONS.confirmReportDeliveryIssue(", detail)
        delivery = block(VENDOR_JS, r"ACTIONS\.confirmReportDeliveryIssue = async function \(el\) \{")
        self.assertIn("await reportDeliveryIssue(", delivery)
        self.assertIn("await hydrateCanonicalWorkspace();", delivery)
        self.assertIn("api.rpc('vendor_report_delivery_issue'", VENDOR_JS)

    def test_assignment_and_run_builder_paths_remain_present(self):
        for rpc in ("assign_rider", "reassign_rider", "build_rider_run"):
            self.assertIn(f"api.rpc('{rpc}'", VENDOR_JS)
        self.assertIn("ACTIONS.confirmRunBuilder = confirmRunBuilder", VENDOR_JS)
        self.assertIn("confirmAssignRiderOrder = async function", VENDOR_JS)

    def test_no_direct_table_mutation_added_to_remediated_handlers(self):
        for pattern in (
            r"function confirmReschedule\(el\)\{",
            r"function startDeliveryForRider\(riderId\)\{",
        ):
            fn = block(VENDOR_HTML, pattern)
            self.assertNotIn("/rest/v1/", fn)
            self.assertNotIn("fetch(", fn)
            self.assertNotIn("api.request(", fn)


if __name__ == "__main__":
    unittest.main()
