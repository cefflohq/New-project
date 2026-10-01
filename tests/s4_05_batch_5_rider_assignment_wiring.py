"""Static acceptance for S4-05 Batch-5 Rider assignment Accept/Decline wiring.

Browser tooling (Claude in Chrome) is not connected in this environment, so
this is a static/structural check against the real source -- not a
substitute for an eventual real click-through, matching the same explicit
gap already recorded for the Customer Tracking and Vendor approval batches.
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BACKEND_JS = (ROOT / "rider" / "backend.js").read_text(encoding="utf-8")
INDEX_HTML = (ROOT / "rider" / "index.html").read_text(encoding="utf-8")


class BackendAdapterTests(unittest.TestCase):
    def test_accept_and_decline_exposed_through_canonical_adapter(self):
        self.assertIn("api.rpc('accept_assignment'", BACKEND_JS)
        self.assertIn("api.rpc('decline_assignment'", BACKEND_JS)
        self.assertRegex(
            BACKEND_JS,
            r"window\.CEFFLO_RIDER = Object\.freeze\(\{[^}]*acceptAssignment[^}]*declineAssignment[^}]*\}\)",
        )

    def test_action_handlers_registered_as_globals(self):
        self.assertIn("acceptAssignmentAction = orderId =>", BACKEND_JS)
        self.assertIn("declineAssignmentAction = orderId =>", BACKEND_JS)

    def test_duplicate_taps_guarded(self):
        self.assertIn("assignmentActionsInFlight", BACKEND_JS)
        fn = re.search(r"async function runAssignmentAction\(orderId, action, successMessage\) \{.*?\n  \}", BACKEND_JS, re.DOTALL)
        self.assertIsNotNone(fn)
        body = fn.group(0)
        self.assertIn("if (assignmentActionsInFlight.has(orderId)) return;", body)
        self.assertIn("assignmentActionsInFlight.add(orderId);", body)
        self.assertIn("assignmentActionsInFlight.delete(orderId);", body)

    def test_actions_refresh_from_backend_not_fake_local_state(self):
        fn = re.search(r"async function runAssignmentAction\(orderId, action, successMessage\) \{.*?\n  \}", BACKEND_JS, re.DOTALL)
        body = fn.group(0)
        self.assertIn("await hydrateOrders();", body)
        self.assertIn("renderHome();", body)
        # Must not fabricate the new state client-side (e.g. order.assignmentStatus = 'accepted').
        self.assertNotIn("assignmentStatus = '", body)
        self.assertNotIn('assignmentStatus = "', body)

    def test_assignment_status_read_from_real_backend_embed_not_mock(self):
        # S4-06.6 legitimately widened this embed (adding delivery_stops.id/
        # sequence/sequence_locked_at, real fields the Plan Route/Delivery
        # Run flow needs) -- a superset of the S4-05.5 shape this test was
        # originally written against, not a regression. The substantive
        # thing this test protects -- assignment status/accepted_at read
        # from the real backend embed, never a mock -- still holds exactly.
        self.assertIn(
            "delivery_stops(id,sequence,sequence_locked_at,assignment_id,rider_assignments(status,accepted_at))",
            BACKEND_JS,
        )
        self.assertIn("assignmentStatus: assignment ? assignment.status : null", BACKEND_JS)
        self.assertIn("assignmentAcceptedAt: assignment ? assignment.accepted_at : null", BACKEND_JS)

    def test_broken_unused_assignments_accessor_removed(self):
        # The old `assignments()` function queried rider_assignments?select=*,orders(*)
        # -- there is no FK enabling that embed, so it was dead/non-functional
        # code, never called anywhere. It must be gone, not left as misleading
        # dormant state.
        self.assertNotIn("rider_assignments?select=*,orders(*)", BACKEND_JS)

    def test_no_direct_rider_assignments_mutation_introduced(self):
        mutation_request = re.compile(
            r"api\.request\([^\n]+(?:method\s*:\s*['\"](?:POST|PATCH|PUT|DELETE)['\"])",
            re.IGNORECASE,
        )
        self.assertIsNone(mutation_request.search(BACKEND_JS))


class HomeScreenGatingTests(unittest.TestCase):
    def test_pending_acceptance_computed_from_backend_field_only(self):
        # S4-06.6 replaced the single-flat-list `nextPendingAcceptance` with
        # per-Wave grouping (multiple Runs must never be silently merged) --
        # the same backend-authoritative field drives the equivalent
        # per-Wave "hasPending" gate now, never inferred locally.
        self.assertIn("o.assignmentStatus==='assigned'", INDEX_HTML)
        self.assertIn("const hasPending=runOrders.some(", INDEX_HTML)

    def test_pending_acceptance_exposes_accept_and_decline(self):
        self.assertIn('onclick="declineAssignmentAction(', INDEX_HTML)
        self.assertIn('onclick="acceptAssignmentAction(', INDEX_HTML)

    def test_accept_decline_branch_is_distinct_from_normal_pickup_cta(self):
        # The Accept/Decline row must not be the same direct-child `.btn`
        # the legacy wrapper scripts rewrite the text of -- it must live in
        # its own container so that unrelated wrapper logic can't corrupt it.
        self.assertIn('class="mission-action-row"', INDEX_HTML)

    def test_declined_orders_excluded_from_active_workload(self):
        self.assertIn("appState.orders.filter(o=>o.assignmentStatus!=='declined')", INDEX_HTML)

    def test_view_assignment_excludes_declined_orders(self):
        # S4-06.6 replaced viewAssignment() with enterRun(sessionId), which
        # resumes into the correct real step for one Wave. Declining
        # doesn't change the order's own delivery_status, so the exclusion
        # now lives in the shared activeRunOrders() helper enterRun uses,
        # rather than a local filter inside viewAssignment itself.
        fn = re.search(r"function activeRunOrders\(\) \{.*?\n  \}", BACKEND_JS, re.DOTALL)
        self.assertIsNotNone(fn)
        self.assertIn("assignmentStatus !== 'declined'", fn.group(0))


class ScopeBoundaryTests(unittest.TestCase):
    """Confirm this batch didn't drift into out-of-scope territory."""

    def test_no_auto_reassignment_introduced(self):
        for forbidden in ("reassign_rider(", "autoReassign", "api.rpc('reassign_rider'"):
            self.assertNotIn(forbidden, BACKEND_JS)

    def test_no_s4_06_batching_zone_routing_introduced(self):
        for forbidden in ("create_delivery_session", "attach_order_to_session", "update_session_status", "batchOrders", "optimizeRoute"):
            self.assertNotIn(forbidden, BACKEND_JS)

    def test_no_s4_08_exception_cancelled_flow_introduced(self):
        for forbidden in ("api.rpc('report_issue'", "api.rpc('cancel_order'", "reportIssueAction"):
            self.assertNotIn(forbidden, BACKEND_JS)

    def test_existing_visual_baseline_preserved(self):
        # Same .btn class/style family reused, no new button component
        # introduced beyond a plain flex row matching the existing inline-
        # style convention already used elsewhere in this file.
        self.assertIn('class="btn"', INDEX_HTML)


class DormantMockStateTests(unittest.TestCase):
    """The pre-existing mock activeAssignment.sessionId/assignmentStatus
    fields were never read anywhere (confirmed dead code) before this batch
    -- they must remain genuinely unread, not silently repurposed."""

    def test_mock_session_id_still_never_read(self):
        self.assertNotIn("activeAssignment.sessionId", INDEX_HTML)

    def test_mock_assignment_status_field_still_never_read(self):
        self.assertNotIn("activeAssignment.assignmentStatus", INDEX_HTML)


if __name__ == "__main__":
    unittest.main()
