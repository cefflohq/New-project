"""Bounded acceptance for S4-09-REMEDIATION-05.

Vendor must not manufacture Rider-owned delivery lifecycle truth locally.
The remaining local order/stop transition engine and dead readiness action
must be absent while authoritative Vendor actions remain intact.
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VENDOR_HTML = (ROOT / "vendor" / "index.html").read_text(encoding="utf-8")
VENDOR_JS = (ROOT / "vendor" / "backend.js").read_text(encoding="utf-8")
LIFECYCLE_SQL = (ROOT / "supabase" / "migrations" / "202608290004_s4_07_batch_3a_rider_multi_business_context.sql").read_text(encoding="utf-8")


def block(source, start_pattern, end_marker="\n}"):
    match = re.search(start_pattern, source)
    assert match, f"pattern not found: {start_pattern}"
    start = match.start()
    end = source.index(end_marker, start) + len(end_marker)
    return source[start:end]


CONFIRM_DELIVERED = block(VENDOR_HTML, r"function confirmMarkDelivered\(el\)\{")
COMPLETE_SHEET = block(VENDOR_HTML, r"function openCompleteStopSheet\(el\)\{")
DELIVERY_PAGE = block(VENDOR_HTML, r"function pageDeliveryExecution\(params\)\{")


class ConfirmDeliveredGateTests(unittest.TestCase):
    def test_confirm_mark_delivered_remains_reachable(self):
        self.assertIn('data-action="confirmMarkDelivered"', COMPLETE_SHEET)
        self.assertIn("confirmMarkDelivered,", VENDOR_HTML)

    def test_confirm_mark_delivered_is_an_honest_gate(self):
        self.assertIn("Marking delivery as completed is not connected in Vendor yet.", CONFIRM_DELIVERED)
        self.assertIn("'error'", CONFIRM_DELIVERED)

    def test_confirm_mark_delivered_has_no_local_operational_mutation(self):
        for forbidden in (
            "transitionOrderStatus", "state.", "deliveryExecState", ".status=", ".status =",
            "completedAt", "deliveredAt", "activity.push", "orderStatusHistory", "persistOperationalStore",
        ):
            self.assertNotIn(forbidden, CONFIRM_DELIVERED)

    def test_confirm_mark_delivered_has_no_fake_success(self):
        for forbidden in ("'success'", "marked as delivered", "Delivery session completed", "Customer notified"):
            self.assertNotIn(forbidden, CONFIRM_DELIVERED)

    def test_vendor_pod_simulation_is_removed(self):
        self.assertNotIn("function simulatePodPhoto", VENDOR_HTML)
        self.assertNotIn('data-action="simulatePodPhoto"', VENDOR_HTML)
        self.assertNotIn("o.podPhoto = true", CONFIRM_DELIVERED)
        self.assertIn("must be submitted by the assigned Rider", COMPLETE_SHEET)

    def test_empty_execution_state_does_not_claim_everything_completed(self):
        self.assertIn("No delivery stops available", DELIVERY_PAGE)
        self.assertNotIn("Every order for", DELIVERY_PAGE)


class DeadReadinessAndTransitionRemovalTests(unittest.TestCase):
    def test_mark_ready_for_pickup_runtime_surface_is_removed(self):
        self.assertNotIn("function markReadyForPickup", VENDOR_HTML)
        self.assertNotIn('data-action="markReadyForPickup"', VENDOR_HTML)
        self.assertNotRegex(VENDOR_HTML, r"\bmarkReadyForPickup\b")

    def test_transition_order_status_has_no_runtime_reference(self):
        self.assertNotRegex(VENDOR_HTML, r"\btransitionOrderStatus\b")
        self.assertNotRegex(VENDOR_JS, r"\btransitionOrderStatus\b")

    def test_order_transitions_has_no_runtime_reference(self):
        self.assertNotRegex(VENDOR_HTML, r"\bORDER_TRANSITIONS\b")
        self.assertNotRegex(VENDOR_JS, r"\bORDER_TRANSITIONS\b")

    def test_delivery_stop_local_transition_command_is_removed(self):
        self.assertNotRegex(VENDOR_HTML, r"\btransitionDeliveryStop\b")
        self.assertNotIn("commands.transitionDeliveryStop", VENDOR_HTML)
        self.assertNotIn("stop.status=nextStatus", VENDOR_HTML)

    def test_local_issue_transition_engine_is_removed(self):
        for symbol in ("milestone1TransitionOrderStatus", "reportOperationalIssue", "resolveOperationalIssue"):
            self.assertNotIn(symbol, VENDOR_HTML)

    def test_fake_session_completion_action_is_removed(self):
        self.assertNotIn("function finalizeCompleteDelivery", VENDOR_HTML)
        self.assertNotIn('data-oncomplete="finalizeCompleteDelivery"', VENDOR_HTML)
        self.assertNotIn("ACTIONS.finalizeCompleteDelivery", VENDOR_HTML)


class ActorAuthorityAndArchitectureTests(unittest.TestCase):
    def test_vendor_does_not_call_rider_completion_contract(self):
        vendor_runtime = VENDOR_HTML + VENDOR_JS
        self.assertNotRegex(vendor_runtime, r"(?:api|window\.CEFFLO)\.rpc\(['\"]complete_delivery")
        self.assertNotRegex(vendor_runtime, r"(?:api|window\.CEFFLO)\.rpc\(['\"]rider_transition")

    def test_vendor_does_not_fabricate_rider_identity_for_completion(self):
        for marker in ("p_rider_id", "current_rider_id", "service_role"):
            self.assertNotIn(marker, CONFIRM_DELIVERED)

    def test_existing_completion_contract_remains_rider_authorized(self):
        self.assertIn("create function public.complete_delivery(p_rider_id uuid", LIFECYCLE_SQL)
        self.assertIn("if not is_current_rider(p_rider_id)", LIFECYCLE_SQL)
        self.assertIn("o.assigned_rider_id is distinct from p_rider_id", LIFECYCLE_SQL)
        self.assertIn("'arrival and POD required'", LIFECYCLE_SQL)

    def test_no_new_direct_table_or_backend_mutation(self):
        remediation = CONFIRM_DELIVERED + COMPLETE_SHEET
        for forbidden in ("/rest/v1/", "api.rpc(", "BackendRepository", ".insert(", ".update(", "fetch("):
            self.assertNotIn(forbidden, remediation)


class AuthoritativeFlowRegressionTests(unittest.TestCase):
    def test_manual_create_approval_assignment_and_run_builder_remain(self):
        for marker in (
            "wizSubmit = async function ()", "ACTIONS.approveOrderAction = approveOrderAction",
            "ACTIONS.confirmAssignRiderOrder = confirmAssignRiderOrder", "ACTIONS.confirmRunBuilder = confirmRunBuilder",
        ):
            self.assertIn(marker, VENDOR_JS)

    def test_s4_08_issue_reporting_remains_authoritative(self):
        self.assertIn("api.rpc('vendor_report_delivery_issue'", VENDOR_JS)
        self.assertIn("ACTIONS.confirmReportDeliveryIssue = async function", VENDOR_JS)
        self.assertIn("await hydrateCanonicalWorkspace()", VENDOR_JS)

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

    def test_s4_09_04_reports_remain_truthful(self):
        self.assertIn("function getReportsSnapshot", VENDOR_HTML)
        self.assertNotIn("[80,95,70,110,90,128,105]", VENDOR_HTML)
        reports = block(VENDOR_HTML, r"function pageReports\(\)\{")
        self.assertNotIn("24 min", reports)


if __name__ == "__main__":
    unittest.main()
