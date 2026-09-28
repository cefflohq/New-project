"""Static acceptance for S4-05 Batch-2 Vendor approval UI/backend wiring.

Browser tooling (Claude in Chrome) is not connected in this environment, so
this is a static/structural check against the real source -- not a
substitute for an eventual real click-through, which is called out
separately in the checkpoint as an open item, matching the precedent set
for the Customer Tracking on-demand-refresh verification.
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BACKEND_JS = (ROOT / "vendor" / "backend.js").read_text(encoding="utf-8")
INDEX_HTML = (ROOT / "vendor" / "index.html").read_text(encoding="utf-8")


class ApproveOrderAdapterTests(unittest.TestCase):
    def test_approve_order_exposed_through_canonical_adapter(self):
        self.assertIn("api.rpc('approve_order'", BACKEND_JS)
        self.assertIn("approveOrder", BACKEND_JS)
        self.assertRegex(BACKEND_JS, r"window\.CEFFLO_VENDOR = Object\.freeze\(\{[^}]*approveOrder[^}]*\}\)")

    def test_action_handler_registered_in_dispatcher(self):
        self.assertRegex(BACKEND_JS, r"ACTIONS\.approveOrderAction\s*=\s*approveOrderAction\s*;")

    def test_ui_state_reads_backend_authoritative_columns(self):
        self.assertIn("approvedAt: row.approved_at, approvedBy: row.approved_by", BACKEND_JS)

    def test_no_full_reload_after_approval(self):
        handler = re.search(r"approveOrderAction = async function \(el\) \{.*?\n  \};", BACKEND_JS, re.DOTALL)
        self.assertIsNotNone(handler)
        body = handler.group(0)
        self.assertNotIn("location.reload", body)
        self.assertIn("hydrateCanonicalWorkspace()", body)
        self.assertIn("render()", body)

    def test_duplicate_approval_requests_prevented(self):
        self.assertIn("approvingOrders", BACKEND_JS)
        handler = re.search(r"approveOrderAction = async function \(el\) \{.*?\n  \};", BACKEND_JS, re.DOTALL)
        body = handler.group(0)
        self.assertIn("if (approvingOrders.has(orderId)) return;", body)
        self.assertIn("approvingOrders.add(orderId);", body)
        self.assertIn("approvingOrders.delete(orderId);", body)

    def test_no_direct_orders_table_mutation_in_approval_path(self):
        handler = re.search(r"approveOrderAction = async function \(el\) \{.*?\n  \};", BACKEND_JS, re.DOTALL)
        body = handler.group(0)
        self.assertNotIn("api.request(", body)
        self.assertNotIn("/rest/v1/orders", body)


class VendorUiConditionalRenderingTests(unittest.TestCase):
    def test_unapproved_order_exposes_approve_action(self):
        self.assertIn('data-action="approveOrderAction"', INDEX_HTML)
        self.assertIn("!o.approvedAt?", INDEX_HTML)

    def test_approve_action_is_conditioned_on_approval_state_not_always_shown(self):
        # The approve button and the assign/change-rider buttons must be
        # mutually exclusive branches of the same conditional, not both
        # rendered unconditionally (which would let an approved order still
        # show an actionable duplicate approval control).
        match = re.search(
            r"\$\{!o\.approvedAt\?`<button[^`]*approveOrderAction[^`]*`:\s*"
            r"\(!o\.riderId\?`<button[^`]*openAssignRiderForOrder[^`]*`:\s*"
            r"`<button[^`]*openAssignRiderForOrder[^`]*`\)\}",
            INDEX_HTML,
        )
        self.assertIsNotNone(match, "approve vs assign/change-rider must be one mutually exclusive conditional")

    def test_assign_rider_action_untouched_otherwise(self):
        self.assertIn('data-action="openAssignRiderForOrder"', INDEX_HTML)


class ScopeBoundaryTests(unittest.TestCase):
    """Confirm this batch didn't drift into out-of-scope territory."""

    def test_no_cancel_or_void_introduced(self):
        for forbidden in ("cancelOrderAction", "voidOrderAction", "api.rpc('cancel_order'", "api.rpc('void_order'"):
            self.assertNotIn(forbidden, BACKEND_JS)

    def test_no_session_functionality_introduced(self):
        # This assertion was true at S4-05.2 authoring time and is now
        # correctly superseded: S4-06.5a (backend, staging-verified) and
        # S4-06.5b (this Vendor Run Builder UI batch) were later explicitly
        # authorized to introduce exactly this session/Wave functionality.
        # Scope-boundary coverage for S4-05.2 itself remains in
        # test_no_cancel_or_void_introduced above; session functionality is
        # covered by tests/s4_06_batch_5b_vendor_run_builder_wiring.py.
        pass

    def test_existing_visual_baseline_preserved_for_action_buttons(self):
        # Same button classes as the pre-existing assign/change-rider markup --
        # no new button styling introduced.
        self.assertIn('class="btn btn-primary" style="margin-bottom:10px" data-action="approveOrderAction"', INDEX_HTML)


if __name__ == "__main__":
    unittest.main()
