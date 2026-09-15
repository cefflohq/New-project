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
VENDOR_HTML = (ROOT / "vendor" / "index.html").read_text(encoding="utf-8")
VENDOR_JS = (ROOT / "vendor" / "backend.js").read_text(encoding="utf-8")
RIDER_HTML = (ROOT / "rider" / "index.html").read_text(encoding="utf-8")
RIDER_JS = (ROOT / "rider" / "backend.js").read_text(encoding="utf-8")
CUSTOMER_JS = (ROOT / "customer" / "backend.js").read_text(encoding="utf-8")


def block(source, start_pattern, end_marker="\n}"):
    match = re.search(start_pattern, source)
    assert match, f"pattern not found: {start_pattern}"
    start = match.start()
    end = source.index(end_marker, start) + len(end_marker)
    return source[start:end]


class VendorIssueWiringTests(unittest.TestCase):
    def test_real_rpc_is_called(self):
        self.assertIn("api.rpc('vendor_report_delivery_issue'", VENDOR_JS)

    def test_typed_reason_mapping_matches_canonical_backend_enum(self):
        # Single-line const object literal -- extract just that line, not
        # the block() helper (which is for multi-line function bodies
        # closed by a bare "\n}" and would otherwise over-match all the way
        # to the end of the surrounding IIFE).
        fn = next(line for line in VENDOR_JS.splitlines() if "const VENDOR_ISSUE_REASON_MAP" in line)
        for key, canonical in (
            ("unreachable", "customer_unreachable"),
            ("wrong", "address_problem"),
            ("bike", "rider_unable_to_proceed"),
            ("late", "vendor_not_ready"),
        ):
            self.assertIn(f"{key}: '{canonical}'", fn)
        # 'time' (sudden time change) and 'spill' (packaging spill) have no
        # truthful canonical match and must never be force-mapped.
        self.assertNotIn("time:", fn)
        self.assertNotIn("spill:", fn)

    def test_unmapped_reason_is_honestly_gated_not_forced(self):
        fn = block(VENDOR_JS, r"ACTIONS\.confirmReportDeliveryIssue = async function \(el\) \{")
        self.assertIn("if (!canonical)", fn)
        self.assertIn("not connected yet", fn)

    def test_no_local_only_status_mutation_remains(self):
        self.assertNotIn("o.status='issue'", VENDOR_HTML)
        self.assertNotIn('o.status="issue"', VENDOR_HTML)

    def test_fake_call_attempt_simulation_removed(self):
        self.assertNotIn("Call attempt", VENDOR_HTML)
        self.assertNotIn("runUnreachableFlow", VENDOR_HTML)

    def test_fake_whatsapp_sent_claim_removed(self):
        self.assertNotIn("WhatsApp message sent to customer", VENDOR_HTML)

    def test_success_only_after_await_and_reflects_only_real_recording(self):
        fn = block(VENDOR_JS, r"ACTIONS\.confirmReportDeliveryIssue = async function \(el\) \{")
        # success toast/state must be strictly after the awaited RPC call,
        # never before it or unconditionally.
        rpc_index = fn.index("await reportDeliveryIssue(")
        toast_index = fn.index("toast('Delivery issue reported.'")
        self.assertLess(rpc_index, toast_index)
        self.assertNotIn("customer contacted", fn.lower())
        self.assertNotIn("rider notified", fn.lower())

    def test_rpc_failure_cannot_produce_success_ui(self):
        fn = block(VENDOR_JS, r"ACTIONS\.confirmReportDeliveryIssue = async function \(el\) \{")
        self.assertIn("catch (error)", fn)
        catch_body = fn[fn.index("catch (error)"):]
        self.assertNotIn("toast('Delivery issue reported.'", catch_body)
        self.assertIn("Unable to report delivery issue", catch_body)


class RiderIssueWiringTests(unittest.TestCase):
    def test_real_rpc_is_called(self):
        self.assertIn("api.rpc('rider_report_delivery_issue'", RIDER_JS)

    def test_typed_reason_mapping_matches_canonical_backend_enum(self):
        fn = next(line for line in RIDER_JS.splitlines() if "const RIDER_ISSUE_REASON_MAP" in line)
        for label, canonical in (
            ("Customer not reachable", "customer_unreachable"),
            ("Wrong address", "address_problem"),
            ("Vendor issue / late", "vendor_not_ready"),
            ("Rider vehicle breakdown", "rider_unable_to_proceed"),
        ):
            self.assertIn(f"'{label}': '{canonical}'", fn)
        # 'Customer changed time' (redelivery) has no backend contract and
        # must never be force-mapped.
        self.assertNotIn("Customer changed time", fn)

    def test_false_vendor_admin_notified_claim_removed(self):
        self.assertNotIn("Vendor/admin has been notified", RIDER_HTML)
        self.assertNotIn("Vendor/admin has been notified", RIDER_JS)
        # the dead i18n key is allowed to remain unreachable, but must have
        # zero live call-sites.
        self.assertNotIn("t('issue_sent')", RIDER_HTML)

    def test_address_update_no_longer_falsely_claims_persistence(self):
        self.assertNotIn("Address updated", RIDER_HTML)
        self.assertNotIn("Vendor contacted for address approval", RIDER_HTML)
        fn = block(RIDER_HTML, r"function applyUpdatedAddress\(\)\{")
        self.assertIn("submitIssue(", fn)

    def test_redelivery_no_longer_falsely_claims_request_sent(self):
        self.assertNotIn("Re-delivery request sent for vendor approval", RIDER_HTML)

    def test_recovery_is_vendor_only_not_wired_from_rider(self):
        # Flow 2 Founder closure decision (supersedes A6's earlier Rider-
        # initiated recovery wiring, asserted by this same test file until
        # Grow V1 Flow 2's later narrowing): "reassignment/recovery
        # ownership changes are Vendor-authorized only; Rider may report an
        # issue/request assistance but must not independently release/
        # reassign the order." initiate_delivery_recovery's signature no
        # longer even accepts a Rider identity (p_rider_id was dropped
        # entirely, not merely ignored) -- the Rider app must carry no call
        # to it at all, and no createRedelivery/"Return to Planning"
        # affordance implying the Rider can trigger it.
        self.assertNotIn("api.rpc('initiate_delivery_recovery'", RIDER_JS)
        self.assertNotIn("createRedelivery", RIDER_HTML)
        self.assertNotIn("createRedelivery", RIDER_JS)
        self.assertNotIn("Return to Planning", RIDER_HTML)
        # 'Customer changed time' remains a selectable Rider issue reason
        # (the Rider's legitimate "report an issue / request assistance"
        # channel), but with no canonical backend action for it, it falls
        # through to the same honest generic-reason handling as any other
        # unmapped reason -- never a fabricated recovery affordance.
        self.assertIn("selectIssue('Customer changed time')", RIDER_HTML)
        self.assertNotIn("recov-reason", RIDER_HTML)
        self.assertNotIn("recov-note", RIDER_HTML)

    def test_breakdown_no_longer_falsely_claims_assignment_paused(self):
        self.assertNotIn("Assignment paused. Waiting for vendor", RIDER_HTML)
        fn = block(RIDER_HTML, r"function pauseForBreakdown\(\)\{")
        self.assertIn("submitIssue('Rider vehicle breakdown')", fn)
        self.assertNotIn("sessionPaused", fn)

    def test_fake_call_attempt_and_wait_simulation_removed(self):
        self.assertNotIn("recordIssueCall", RIDER_HTML)
        self.assertNotIn("startIssueWait", RIDER_HTML)
        self.assertNotIn("updateIssueGate", RIDER_HTML)
        self.assertNotIn("Wait requirement", RIDER_HTML)

    def test_success_only_after_await(self):
        fn = block(RIDER_JS, r"submitIssue = async function \(reason, note\) \{")
        rpc_index = fn.index("await reportDeliveryIssue(")
        toast_index = fn.index("showToast('Issue reported.'")
        self.assertLess(rpc_index, toast_index)

    def test_rpc_failure_cannot_produce_success_ui(self):
        fn = block(RIDER_JS, r"submitIssue = async function \(reason, note\) \{")
        self.assertIn("catch (error)", fn)
        catch_body = fn[fn.index("catch (error)"):]
        self.assertNotIn("showToast('Issue reported.'", catch_body)


class CrossAppAndOfflineTests(unittest.TestCase):
    def test_customer_issue_and_cancelled_mapping_unchanged(self):
        self.assertIn("issue: 'issue'", CUSTOMER_JS)
        self.assertIn("cancelled: 'cancelled'", CUSTOMER_JS)

    def test_no_new_direct_table_mutation_introduced(self):
        # Both new wrappers must call the RPC, never a direct PostgREST
        # table write for the order/delivery_events tables -- bounded to the
        # single declaration line itself, not a fixed-width slice that could
        # bleed into an unrelated neighboring function.
        vendor_line = next(line for line in VENDOR_JS.splitlines() if "const reportDeliveryIssue =" in line)
        rider_line = next(line for line in RIDER_JS.splitlines() if "const reportDeliveryIssue =" in line)
        self.assertIn("api.rpc(", vendor_line)
        self.assertNotIn("/rest/v1/orders", vendor_line)
        self.assertIn("api.rpc(", rider_line)
        self.assertNotIn("/rest/v1/orders", rider_line)

    def test_offline_failure_cannot_enter_false_success_state(self):
        # Both handlers' only success paths are strictly downstream of the
        # awaited RPC call inside a try block with a catch that surfaces the
        # error honestly -- confirmed structurally above (test_success_only_
        # after_await + test_rpc_failure_cannot_produce_success_ui for both
        # apps). This test additionally confirms neither handler references
        # the dead legacy offline-sync stub as a substitute success path.
        self.assertNotIn("syncOperationalStateToBackend", VENDOR_JS[VENDOR_JS.index("ACTIONS.confirmReportDeliveryIssue"):])


class VendorOrderDetailIssueWiringTests(unittest.TestCase):
    """S4-08-EXCEPTION-ORDER-DETAIL-REMEDIATION-01: the SECOND Vendor
    "Report Issue" entry point (pageOrderDetail's openReportIssue ->
    confirmReportIssue), found unaudited/unfixed by the original S4-08
    canonical acceptance recheck. confirmReportIssue must delegate entirely
    to the already-real, already-tested confirmReportDeliveryIssue action --
    not a second parallel implementation.
    """

    def test_order_detail_report_issue_remains_reachable(self):
        self.assertIn('data-action="openReportIssue"', VENDOR_HTML)
        self.assertIn('data-action="confirmReportIssue"', VENDOR_HTML)
        self.assertIn("function openReportIssue(", VENDOR_HTML)
        self.assertIn("function confirmReportIssue(", VENDOR_HTML)

    def test_wrong_address_maps_to_address_problem(self):
        fn = next(line for line in VENDOR_HTML.splitlines() if "const ORDER_DETAIL_ISSUE_REASON_KEY" in line)
        self.assertIn("'Wrong address': 'wrong'", fn)
        # 'wrong' is the SAME key VENDOR_ISSUE_REASON_MAP (backend.js) maps
        # to 'address_problem' -- confirmed by the shared-mapping test above
        # (VendorIssueWiringTests.test_typed_reason_mapping_matches_
        # canonical_backend_enum), not duplicated here.

    def test_customer_unreachable_maps_to_customer_unreachable_key(self):
        fn = next(line for line in VENDOR_HTML.splitlines() if "const ORDER_DETAIL_ISSUE_REASON_KEY" in line)
        self.assertIn("'Customer unreachable': 'unreachable'", fn)

    def test_supported_reason_delegates_to_real_authoritative_action(self):
        fn = block(VENDOR_HTML, r"function confirmReportIssue\(el\)\{")
        self.assertIn("ACTIONS.confirmReportDeliveryIssue(", fn)

    def test_rpc_success_gate_and_failure_honesty_inherited_from_shared_action(self):
        # confirmReportIssue has no success/failure branching of its own --
        # it delegates entirely to confirmReportDeliveryIssue, whose own
        # await-gated success and honest-catch behavior is already proven
        # by VendorIssueWiringTests above. Confirm the delegation is total
        # (no local success/failure handling exists in confirmReportIssue
        # itself that could bypass that gate).
        fn = block(VENDOR_HTML, r"function confirmReportIssue\(el\)\{")
        self.assertNotIn("toast(", fn)
        self.assertNotIn("closeSheet(", fn)
        self.assertNotIn("await ", fn)

    def test_no_local_only_order_status_mutation_remains(self):
        fn = block(VENDOR_HTML, r"function confirmReportIssue\(el\)\{")
        self.assertNotIn("transitionOrderStatus", fn)

    def test_no_fake_state_issues_append_remains(self):
        fn = block(VENDOR_HTML, r"function confirmReportIssue\(el\)\{")
        self.assertNotIn("state.issues.push", fn)

    def test_unsupported_reasons_honestly_gated_not_forced(self):
        fn = next(line for line in VENDOR_HTML.splitlines() if "const ORDER_DETAIL_ISSUE_REASON_KEY" in line)
        for unsupported in ("Packaging issue", "Payment issue", "Other"):
            self.assertNotIn(f"'{unsupported}':", fn)

    def test_delivery_execution_issue_path_remains_real_and_unchanged(self):
        fn = block(VENDOR_JS, r"ACTIONS\.confirmReportDeliveryIssue = async function \(el\) \{")
        self.assertIn("await reportDeliveryIssue(", fn)
        self.assertIn("await hydrateCanonicalWorkspace();", fn)

    def test_no_new_direct_table_write_introduced(self):
        fn = block(VENDOR_HTML, r"function confirmReportIssue\(el\)\{")
        self.assertNotIn("/rest/v1/", fn)
        self.assertNotIn("api.request(", fn)

    def test_customer_issue_compatibility_unchanged(self):
        self.assertIn("issue: 'issue'", CUSTOMER_JS)


if __name__ == "__main__":
    unittest.main()
