"""Static acceptance for S4-07.3a frontend wiring: multi-business Rider
active-context selection (Choose Team / Switch Team), explicit p_rider_id
threading on every Rider mutation, explicit read scoping, and the canonical
POD upload path. Matches the established static/structural precedent (e.g.
s4_07_frontend_wiring.py, s4_06_7_batch_1_frontend_wiring.py) -- not a
substitute for real browser click-through, which this project has
consistently deferred to S4-15 for every prior UI batch.
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RIDER_JS = (ROOT / "rider" / "backend.js").read_text(encoding="utf-8")
RIDER_HTML = (ROOT / "rider" / "index.html").read_text(encoding="utf-8")
CLIENT_JS = (ROOT / "shared" / "client.js").read_text(encoding="utf-8")


def block(source, start_pattern, end_marker="\n  }"):
    match = re.search(start_pattern, source)
    assert match, f"pattern not found: {start_pattern}"
    start = match.start()
    end = source.index(end_marker, start) + len(end_marker)
    return source[start:end]


class ActiveContextResolutionTests(unittest.TestCase):
    def test_classify_fetches_every_relationship_unfiltered_by_status(self):
        fn = block(RIDER_JS, r"async function classifyRiderRelationships\(\) \{")
        self.assertIn("/rest/v1/riders?auth_user_id=eq.", fn)
        self.assertNotIn("&status=eq.", fn)

    def test_zero_active_relationships_is_account_not_approved(self):
        fn = block(RIDER_JS, r"async function classifyRiderRelationships\(\) \{")
        self.assertIn("if (!active.length)", fn)
        self.assertIn("ACCOUNT_NOT_APPROVED", fn)

    def test_exactly_one_active_auto_selects_no_picker(self):
        fn = block(RIDER_JS, r"async function resolveActiveRiderContext\(\) \{")
        self.assertIn("identity.active.length === 1", fn)
        self.assertIn("needsSelection: false", fn)

    def test_multiple_active_without_valid_persisted_selection_requires_picker(self):
        fn = block(RIDER_JS, r"async function resolveActiveRiderContext\(\) \{")
        self.assertIn("needsSelection: true", fn)
        self.assertIn("clearActiveRiderContext()", fn)

    def test_stale_persisted_selection_is_discarded_not_trusted(self):
        fn = block(RIDER_JS, r"function findPersistedActiveRider\(active\) \{")
        self.assertIn("active.find(r => r.id === savedId) || null", fn)

    def test_pending_relationships_never_treated_as_selectable(self):
        fn = block(RIDER_JS, r"async function classifyRiderRelationships\(\) \{")
        self.assertIn("r.status === 'pending'", fn)
        resolve_fn = block(RIDER_JS, r"async function resolveActiveRiderContext\(\) \{")
        self.assertNotIn("pending", resolve_fn)

    def test_logout_clears_active_rider_context(self):
        self.assertIn("clearActiveRiderContext();", RIDER_HTML)
        do_logout = block(RIDER_HTML, r"function doLogout\(\)\s*\{")
        self.assertIn("clearActiveRiderContext", do_logout)


class TeamPickerRenderingTests(unittest.TestCase):
    def test_choose_team_modal_present_in_markup(self):
        self.assertIn('id="modal-chooseTeam"', RIDER_HTML)
        self.assertIn('id="choose-team-content"', RIDER_HTML)

    def test_active_rows_rendered_selectable(self):
        fn = block(RIDER_JS, r"function renderChooseTeamModal\(identity, opts = \{\}\) \{")
        self.assertIn("identity.active.map(", fn)

    def test_pending_rows_rendered_informationally_not_selectable(self):
        fn = block(RIDER_JS, r"function renderChooseTeamModal\(identity, opts = \{\}\) \{")
        self.assertIn("identity.pending.map(", fn)
        self.assertIn("Pending approval", fn)
        self.assertIn("cursor:default;", fn)

    def test_inactive_relationships_never_rendered_in_picker(self):
        fn = block(RIDER_JS, r"function renderChooseTeamModal\(identity, opts = \{\}\) \{")
        self.assertNotIn("identity.all.map(", fn)
        self.assertNotIn("inactive", fn.lower())


class SwitchTeamTests(unittest.TestCase):
    def test_switch_team_control_only_shown_for_more_than_one_active(self):
        self.assertIn("activeCount>1?'flex':'none'", RIDER_HTML)

    def test_switch_team_row_lives_in_profile_account_area(self):
        profile_card = RIDER_HTML[RIDER_HTML.index('class="profile-menu-card"'):]
        self.assertIn('id="pf-switch-team-row"', profile_card[:400])

    def test_open_switch_team_refuses_when_not_multi_business(self):
        fn = block(RIDER_JS, r"openSwitchTeam = async function \(\) \{")
        self.assertIn("identity.active.length < 2", fn)

    def test_switch_clears_stale_run_and_order_state_before_rehydrate(self):
        fn = block(RIDER_JS, r"switchToRiderContext = async function \(riderId\) \{")
        self.assertIn("appState.activeRunSessionId = null", fn)
        self.assertIn("appState.planRouteOrder = []", fn)
        self.assertIn("appState.orders = []", fn)
        self.assertIn("hydrateOrders()", fn)

    def test_switch_updates_active_rider_and_business_id(self):
        fn = block(RIDER_JS, r"function setActiveRiderContext\(riderRow\) \{")
        self.assertIn("appState.activeRiderId = riderRow.id", fn)
        self.assertIn("appState.activeBusinessId = riderRow.business_id", fn)


class ExplicitPRiderIdWiringTests(unittest.TestCase):
    RPC_NAMES = [
        "accept_assignment", "decline_assignment", "accept_run", "decline_run",
        "save_run_sequence", "start_pickup_run", "start_run_delivery",
        "rider_transition", "complete_delivery",
    ]

    def test_every_rider_rpc_wrapper_sends_p_rider_id_first(self):
        for name in self.RPC_NAMES:
            match = re.search(r"api\.rpc\('" + name + r"',\s*\{\s*p_rider_id:", RIDER_JS)
            self.assertTrue(match, f"{name} does not send p_rider_id as first param")

    def test_no_old_context_free_rpc_calls_remain(self):
        for name in self.RPC_NAMES:
            for stale in (f"api.rpc('{name}', {{ p_order_id", f"api.rpc('{name}', {{ p_delivery_session_id"):
                self.assertNotIn(stale, RIDER_JS)

    def test_action_handlers_pass_active_rider_id(self):
        # Per-assignment/per-Run actions go through the shared
        # runAssignmentAction/runSessionAction wrappers, which forward
        # appState.activeRiderId into whichever RPC wrapper they were given.
        run_assignment_fn = block(RIDER_JS, r"async function runAssignmentAction\(orderId, action, successMessage\) \{")
        self.assertIn("action(appState.activeRiderId, orderId)", run_assignment_fn)
        run_session_fn = block(RIDER_JS, r"async function runSessionAction\(sessionId, action, successMessage, onSuccess\) \{")
        self.assertIn("action(appState.activeRiderId, sessionId)", run_session_fn)
        for fn_name in ("saveRunSequence(", "startPickupRun(", "startRunDelivery(", "transition("):
            self.assertIn(f"{fn_name}appState.activeRiderId", RIDER_JS)


class ExplicitReadScopingTests(unittest.TestCase):
    def test_orders_read_filtered_by_active_rider_id(self):
        fn = block(RIDER_JS, r"const orders = riderId =>", ");")
        self.assertIn("assigned_rider_id=eq.", fn)

    def test_sessions_read_filtered_by_active_business_id(self):
        fn = block(RIDER_JS, r"const sessions = businessId =>", ");")
        self.assertIn("business_id=eq.", fn)

    def test_hydrate_orders_guards_on_active_rider_id(self):
        fn = block(RIDER_JS, r"async function hydrateOrders\(\) \{")
        self.assertIn("if (!appState.activeRiderId)", fn)
        self.assertIn("orders(appState.activeRiderId)", fn)


class PodUploadCanonicalPathTests(unittest.TestCase):
    def test_upload_pod_signature_takes_rider_id_first(self):
        fn = block(CLIENT_JS, r"async function uploadPod\(riderId, orderId, file\) \{")
        self.assertIn("`${riderId}/${orderId}/", fn)

    def test_complete_threads_same_rider_id_through_upload_and_rpc(self):
        fn = block(RIDER_JS, r"async function complete\(riderId, orderId, file, note\) \{")
        self.assertIn("api.uploadPod(riderId, orderId, file)", fn)
        self.assertIn("p_rider_id: riderId", fn)


if __name__ == "__main__":
    unittest.main()
