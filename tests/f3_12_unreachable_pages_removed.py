"""Static acceptance for Flow 3 F3-12: removal of the confirmed-unreachable
pageDeliveryExecution and pageCustomerTracking pages, plus their exclusive
dependencies (deliveryExecState, deliveringOrdersForRider,
openNavigateSheet, chooseMapApp, openDeliveryIssueSheet,
handleDeliveryIssue, openUnreachableGuidance, openCompleteStopSheet,
confirmMarkDelivered).

Reachability was reconfirmed before removal: zero data-nav triggers
anywhere in vendor/index.html targeted 'deliveryExecution' or
'customerTracking' (only their PAGES map registrations and inert i18n
label strings referenced the route names), and every exclusive dependency
function/state object had no call site outside pageDeliveryExecution's
own rendered HTML. Both pages internally fabricated data if ever reached
(a fake current.eta / "3 stops before you" line, a placeholder POD-photo
box) -- this is removal, not reconciliation, since no live entry point
exists to reconcile to and Active Runs/Run Detail (F3-06) already cover
the legitimate underlying need with real data.

Also proves the real, separately-live ACTIONS.confirmReportDeliveryIssue
handler (called by the now-removed dead code, but with its own real,
independent live call sites in Order Detail's issue-report flow) was not
touched by this removal.

Browser tooling is not connected in this environment, so this is a
static/structural check against the real source, matching the established
precedent (s4_06_batch_5b_vendor_run_builder_wiring.py and others).
"""

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INDEX_HTML = (ROOT / "vendor" / "index.html").read_text(encoding="utf-8")


class RemovedSymbolsGoneTests(unittest.TestCase):
    def test_page_functions_removed(self):
        self.assertNotIn("function pageDeliveryExecution(", INDEX_HTML)
        self.assertNotIn("function pageCustomerTracking(", INDEX_HTML)

    def test_exclusive_dependencies_removed(self):
        for symbol in (
            "const deliveryExecState",
            "function deliveringOrdersForRider(",
            "function openNavigateSheet(",
            "function chooseMapApp(",
            "function openDeliveryIssueSheet(",
            "function handleDeliveryIssue(",
            "function openUnreachableGuidance(",
            "function openCompleteStopSheet(",
            "function confirmMarkDelivered(",
        ):
            self.assertNotIn(symbol, INDEX_HTML, f"still present: {symbol}")

    def test_removed_from_pages_map(self):
        self.assertNotIn("deliveryExecution: pageDeliveryExecution,", INDEX_HTML)
        self.assertNotIn("customerTracking: pageCustomerTracking,", INDEX_HTML)

    def test_removed_from_actions_object(self):
        # Check executable lines only -- this test file's own docstring/
        # comments legitimately name these identifiers for documentation,
        # and the removal's own in-file explanatory comment (immediately
        # preceding the removed functions) does too.
        for line in INDEX_HTML.splitlines():
            stripped = line.strip()
            if stripped.startswith("//") or stripped.startswith("*"):
                continue
            self.assertNotIn("openNavigateSheet, chooseMapApp", line)
            self.assertNotIn("openCompleteStopSheet, confirmMarkDelivered", line)

    def test_no_dangling_nav_targets(self):
        self.assertNotIn('data-nav="deliveryExecution"', INDEX_HTML)
        self.assertNotIn('data-nav="customerTracking"', INDEX_HTML)
        self.assertNotIn("nav:'deliveryExecution'", INDEX_HTML)
        self.assertNotIn("nav:'customerTracking'", INDEX_HTML)


class SharedActionUntouchedTests(unittest.TestCase):
    def test_real_issue_report_action_still_registered_and_wired(self):
        # ACTIONS.confirmReportDeliveryIssue itself (defined in backend.js,
        # calling the real vendor_report_delivery_issue RPC) must be
        # completely unaffected -- only its dead callers inside the
        # removed pages were removed, never the handler itself or its
        # real live call sites elsewhere (Order Detail's issue-report flow).
        self.assertIn('data-action="confirmReportDeliveryIssue"', INDEX_HTML)


if __name__ == "__main__":
    unittest.main()
