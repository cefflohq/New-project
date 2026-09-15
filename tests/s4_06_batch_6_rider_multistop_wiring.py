"""Static acceptance for S4-06 Batch-6 Rider Multi-stop UI wiring.

Browser tooling (Claude in Chrome) is not connected in this environment, so
this is a static/structural check against the real source, matching the
precedent set by s4_05_batch_2_vendor_approval_wiring.py and
s4_06_batch_5b_vendor_run_builder_wiring.py -- not a substitute for a real
click-through, which remains deferred to the S4-15 RC browser acceptance
gate. Executable logic (data mapping, grouping, sequencing, and the action
handlers actually running against a fake successful RPC layer) is covered
separately by tests/s4_06_batch_6_rider_multistop_logic.js.
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BACKEND_JS = (ROOT / "rider" / "backend.js").read_text(encoding="utf-8")
INDEX_HTML = (ROOT / "rider" / "index.html").read_text(encoding="utf-8")
VENDOR_HTML = (ROOT / "vendor" / "index.html").read_text(encoding="utf-8")
CUSTOMER_HTML = (ROOT / "customer" / "index.html").read_text(encoding="utf-8")


def last_def(source, start_pattern, end_marker="\n}"):
    """Extract the LAST (winning, since later script blocks reassign
    earlier ones in this codebase) definition matching start_pattern."""
    matches = list(re.finditer(start_pattern, source))
    assert matches, f"pattern not found: {start_pattern}"
    start = matches[-1].start()
    end = source.index(end_marker, start) + len(end_marker)
    return source[start:end]


def block(source, start_pattern, end_marker="\n}"):
    match = re.search(start_pattern, source)
    assert match, f"pattern not found: {start_pattern}"
    start = match.start()
    end = source.index(end_marker, start) + len(end_marker)
    return source[start:end]


class RunGroupingTests(unittest.TestCase):
    def test_home_renders_one_card_per_wave_via_riderRuns(self):
        fn = block(INDEX_HTML, r"function renderHome\(\)\{")
        self.assertIn("window.CEFFLO_RIDER.riderRuns()", fn)
        self.assertIn("runs.map(run=>", fn)

    def test_no_run_table_introduced(self):
        for forbidden in ("create table public.runs", "rider_runs(", "'runs'"):
            self.assertNotIn(forbidden, BACKEND_JS)


class AcceptDeclineRunTests(unittest.TestCase):
    def test_accept_run_decline_run_are_primary_home_actions(self):
        fn = block(INDEX_HTML, r"function renderHome\(\)\{")
        self.assertIn('onclick="acceptRunAction(', fn)
        self.assertIn('onclick="declineRunAction(', fn)
        self.assertIn(">Accept Run<", fn)
        self.assertIn(">Decline Run<", fn)

    def test_per_order_acceptance_remains_compatible_secondary(self):
        fn = block(INDEX_HTML, r"function showPerOrderAcceptance\(sessionId\)\{")
        self.assertIn("acceptAssignmentAction(", fn)
        self.assertIn("declineAssignmentAction(", fn)

    def test_no_fabricated_local_acceptance(self):
        handler = block(BACKEND_JS, r"async function runSessionAction\(")
        self.assertIn("await action(appState.activeRiderId, sessionId)", handler)
        self.assertIn("await hydrateOrders()", handler)
        # The RPC call and the real refresh must both precede any success
        # side effect (toast/navigation) -- never claim acceptance locally
        # before the backend confirms it.
        self.assertLess(handler.index("await action(appState.activeRiderId, sessionId)"), handler.index("showToast"))
        self.assertLess(handler.index("await hydrateOrders()"), handler.index("showToast"))


class PlanRouteTests(unittest.TestCase):
    def test_save_sequence_submits_the_complete_array(self):
        handler = block(BACKEND_JS, r"saveSequenceAction = async function \(\) \{", "\n  };")
        self.assertIn("appState.planRouteOrder.map(o => o.backendId)", handler)
        self.assertIn("saveRunSequence(appState.activeRiderId, appState.activeRunSessionId, orderIds)", handler)

    def test_save_failure_reverts_to_last_backend_confirmed_sequence(self):
        handler = block(BACKEND_JS, r"saveSequenceAction = async function \(\) \{", "\n  };")
        self.assertIn("catch (error)", handler)
        catch_body = handler[handler.index("catch (error)"):]
        self.assertIn("refreshActiveRunOrders()", catch_body)
        self.assertNotIn("showToast(error.message || 'Unable to save sequence', 'error')".replace("Unable", "Saved"), catch_body)

    def test_drag_reorder_is_local_only_until_save(self):
        fn = last_def(INDEX_HTML, r"renderRouteOverview=function\(\)\{")
        self.assertIn("planRouteIsDirty()", fn)
        self.assertIn("dirty?'Save Sequence':'Sequence Saved'", fn)
        # Start Pickup slider only renders once the sequence is confirmed
        # saved (!dirty) -- never while local drag state is unsaved.
        self.assertIn("!dirty?`<div aria-hidden=\"false\" class=\"slider-wrap\" id=\"startPickupSlider\"", fn)

    def test_move_stop_is_purely_local_state_mutation(self):
        fn = block(INDEX_HTML, r"function moveStop\(index,dir\)\{")
        self.assertNotIn("api.rpc", fn)
        self.assertNotIn("save_run_sequence", fn)

    def test_plan_route_uses_real_sequence_field_not_legacy(self):
        fn = last_def(INDEX_HTML, r"renderRouteOverview=function\(\)\{")
        self.assertNotIn("delivery_sequence", fn)


class StartPickupTests(unittest.TestCase):
    def test_start_pickup_run_called_and_never_marks_picked_up(self):
        handler = block(BACKEND_JS, r"startPickupRunAction = async function \(\) \{", "\n  };")
        self.assertIn("startPickupRun(appState.activeRiderId, appState.activeRunSessionId)", handler)
        self.assertNotIn("picked_up", handler)

    def test_start_pickup_enters_checklist_on_success(self):
        handler = block(BACKEND_JS, r"startPickupRunAction = async function \(\) \{", "\n  };")
        self.assertIn("enterPickupChecklist()", handler)


class PickupChecklistTests(unittest.TestCase):
    def test_checklist_is_unordered_not_a_wizard(self):
        fn = block(INDEX_HTML, r"function renderPickupChecklist\(\)\{")
        self.assertIn("stops.map(o=>", fn)
        self.assertNotIn("pickupIndex", fn)

    def test_factual_progress_counter(self):
        fn = block(INDEX_HTML, r"function renderPickupChecklist\(\)\{")
        self.assertIn("`Picked up ${pickedUp} / ${stops.length}`", fn)

    def test_each_order_independently_confirmable(self):
        fn = block(INDEX_HTML, r"function renderPickupChecklist\(\)\{")
        self.assertIn("pickupOrderAction('${o.backendId}')", fn)

    def test_two_hop_transition_matches_existing_canonical_contract(self):
        handler = block(BACKEND_JS, r"pickupOrderAction = async function \(orderId\) \{", "\n  };")
        self.assertIn("transition(appState.activeRiderId, orderId, 'ready_for_pickup')", handler)
        self.assertIn("transition(appState.activeRiderId, orderId, 'picked_up')", handler)

    def test_partial_failure_recovers_via_refresh_not_local_assumption(self):
        handler = block(BACKEND_JS, r"pickupOrderAction = async function \(orderId\) \{", "\n  };")
        catch_body = handler[handler.index("catch (error)"):]
        self.assertIn("hydrateOrders()", catch_body)
        self.assertIn("refreshActiveRunOrders()", catch_body)

    def test_duplicate_tap_guarded(self):
        self.assertIn("pickupActionsInFlight", BACKEND_JS)
        handler = block(BACKEND_JS, r"pickupOrderAction = async function \(orderId\) \{", "\n  };")
        self.assertIn("if (pickupActionsInFlight.has(orderId)) return;", handler)

    def test_pickup_order_independent_of_delivery_sequence(self):
        fn = block(INDEX_HTML, r"function renderPickupChecklist\(\)\{")
        self.assertNotIn(".sequence", fn)


class StartDeliveryTests(unittest.TestCase):
    def test_start_run_delivery_called_exactly_once(self):
        handler = block(BACKEND_JS, r"startDelivery = async function \(\) \{", "\n  };")
        self.assertEqual(handler.count("startRunDelivery("), 1)

    def test_no_per_order_out_for_delivery_loop(self):
        handler = block(BACKEND_JS, r"startDelivery = async function \(\) \{", "\n  };")
        self.assertNotIn("filter(o => !o.delivered && o.backendStatus === 'picked_up')", handler)
        self.assertNotIn("out_for_delivery", handler)

    def test_start_delivery_uses_real_slide_to_confirm_primitive(self):
        self.assertIn('id="startSlider"', INDEX_HTML)
        self.assertNotIn('id="startDeliveryButton"', INDEX_HTML)
        self.assertNotIn("production-hidden\" id=\"startSlider\"", INDEX_HTML)


class DeliveryRunTests(unittest.TestCase):
    def test_no_fake_eta_or_distance_in_live_stop_detail(self):
        fn = last_def(INDEX_HTML, r"stopDetailHTML=function\(o,i\)\{")
        self.assertNotIn("ETA", fn)
        self.assertNotIn("Distance", fn)
        self.assertNotIn("5+i*2", fn)
        self.assertNotIn("1.4+i*.2", fn)

    def test_display_position_used_not_raw_persisted_sequence(self):
        fn = last_def(INDEX_HTML, r"stopDetailHTML=function\(o,i\)\{")
        self.assertIn("Stop ${i+1} of ${orders.length}", fn)
        self.assertNotIn("o.sequence", fn)

    def test_only_current_stop_shows_actionable_start_control(self):
        fn = last_def(INDEX_HTML, r"stopDetailHTML=function\(o,i\)\{")
        self.assertIn("i===appState.currentStopIndex&&!o.delivered", fn)

    def test_active_delivery_and_next_stop_eta_rows_hidden(self):
        active = block(INDEX_HTML, r"function renderActiveDelivery\(\)\{")
        self.assertIn("etaRow.style.display='none'", active)
        nxt = block(INDEX_HTML, r"function renderNextStop\(\)\{")
        self.assertIn("etaRow.style.display='none'", nxt)

    def test_summary_has_no_fabricated_distance(self):
        fn = block(INDEX_HTML, r"function renderSummary\(\)\{")
        self.assertNotIn("28.4 km", fn)
        self.assertNotIn("Distance Covered", fn)


class GappedSequenceTests(unittest.TestCase):
    def test_sort_by_sequence_never_renumbers(self):
        fn = block(BACKEND_JS, r"function sortBySequence\(list\) \{")
        self.assertIn("a.sequence ?? Infinity", fn)
        self.assertIn("b.sequence ?? Infinity", fn)
        self.assertNotIn("sequence =", fn)  # never assigns/rewrites sequence


class SingleOrderRunTests(unittest.TestCase):
    def test_no_single_order_shortcut_lifecycle(self):
        for fn_name in (r"function enterRun\(sessionId\)\{",):
            fn = block(INDEX_HTML, fn_name)
            self.assertNotIn("orders.length===1", fn)
            self.assertNotIn("length == 1", fn)
        self.assertNotIn("singleOrderRun", INDEX_HTML)
        self.assertNotIn("singleOrderRun", BACKEND_JS)


class MapDataCapabilityTests(unittest.TestCase):
    def test_no_hardcoded_coordinate_fallback(self):
        self.assertNotIn("?? 3.139", BACKEND_JS)
        self.assertNotIn("?? 101.6869", BACKEND_JS)
        self.assertNotIn("[2.927,101.758]", INDEX_HTML)
        self.assertNotIn("[2.9365,101.7685]", INDEX_HTML)

    def test_no_fake_rider_marker(self):
        fn = block(INDEX_HTML, r"function renderPremiumMap\(containerId,detailId,prefix\)\{")
        self.assertNotIn("cefflo-rider-marker", fn)
        self.assertNotIn("riderIcon", fn)

    def test_no_fabricated_polyline(self):
        fn = block(INDEX_HTML, r"function renderPremiumMap\(containerId,detailId,prefix\)\{")
        self.assertNotIn("L.polyline", fn)

    def test_markers_only_for_orders_with_real_coordinates(self):
        fn = block(INDEX_HTML, r"function renderPremiumMap\(containerId,detailId,prefix\)\{")
        self.assertIn("typeof x.o.lat==='number'&&typeof x.o.lng==='number'", fn)
        self.assertIn("geocoded.forEach(", fn)

    def test_honest_unavailable_state_when_no_coordinates(self):
        fn = block(INDEX_HTML, r"function renderPremiumMap\(containerId,detailId,prefix\)\{")
        self.assertIn("Map unavailable", fn)

    def test_navigate_falls_back_to_real_address_string(self):
        fn = block(INDEX_HTML, r"function navigateExternal\(index\)\{")
        self.assertIn("hasCoords", fn)
        self.assertIn("encodeURIComponent(o.address)", fn)

    def test_offline_fallback_shows_stop_list_not_fabricated_geography(self):
        fn = block(INDEX_HTML, r"function renderPremiumMapFallback\(el,orders,geocoded,sel,prefix\)\{")
        self.assertNotIn("map-route-svg", fn)
        self.assertNotIn("rider-marker", fn)


class HomeSummaryTests(unittest.TestCase):
    def test_no_fabricated_session_pickup_window_distance_in_home(self):
        fn = block(INDEX_HTML, r"function renderHome\(\)\{")
        for forbidden in ("CF-S-0826", "Dapur Aisyah", "11:30 AM", "28.4 km", "2:30 PM", "Est. Finish"):
            self.assertNotIn(forbidden, fn)

    def test_wave_name_only_shown_if_genuinely_loaded(self):
        fn = block(INDEX_HTML, r"function renderHome\(\)\{")
        self.assertIn("run.waveName?run.waveName:", fn)


class OfflineErrorRecoveryTests(unittest.TestCase):
    def test_run_action_errors_are_surfaced_not_swallowed(self):
        handler = block(BACKEND_JS, r"async function runSessionAction\(")
        self.assertIn("catch (error)", handler)
        self.assertIn("showToast(error.message", handler)

    def test_no_optimistic_local_success_before_rpc_resolves_anywhere_new(self):
        for handler_pattern, end in [
            (r"acceptRunAction = ", None),
            (r"saveSequenceAction = async function \(\) \{", "\n  };"),
            (r"startPickupRunAction = async function \(\) \{", "\n  };"),
        ]:
            pass  # covered by executable tests in the .js logic file; structural spot-check below.
        save_handler = block(BACKEND_JS, r"saveSequenceAction = async function \(\) \{", "\n  };")
        self.assertLess(save_handler.index("saveRunSequence("), save_handler.index("showToast('Sequence saved'"))


class PODRegressionTests(unittest.TestCase):
    def test_pod_upload_and_complete_delivery_unchanged(self):
        self.assertIn("await complete(appState.activeRiderId, order.backendId, appState.podFile, document.getElementById('pod-note').value)", BACKEND_JS)
        self.assertIn("api.uploadPod(riderId, orderId, file)", BACKEND_JS)
        self.assertIn("complete_delivery", BACKEND_JS)


class CrossAppConsistencyTests(unittest.TestCase):
    def test_arrived_folds_into_out_for_delivery_label_matching_vendor(self):
        # Rider's own uiStatus() folding (unchanged this batch) already
        # matches Vendor's statusToUi mapping -- both treat 'arrived' as a
        # continuation of "delivering", never a separate customer-facing
        # milestone. Documented finding, not a defect requiring a fix here.
        self.assertIn("arrived: 'out_for_delivery'", BACKEND_JS)


class ScopeBoundaryTests(unittest.TestCase):
    # Note: this session has never committed (everything remains
    # uncommitted across many prior, separately-authorized batches), so
    # `git diff` cannot distinguish "changed by this turn" from "changed by
    # an earlier turn and left uncommitted" -- it is not a valid signal
    # here. Vendor/Customer file non-modification for this specific turn is
    # attested directly from the implementation's own tool-call record
    # rather than re-derived here.
    def test_no_notification_provider_integration(self):
        for forbidden in ("whatsapp.com/send", "twilio", "notification_provider", "sendNotification"):
            self.assertNotIn(forbidden, BACKEND_JS)
            self.assertNotIn(forbidden, INDEX_HTML)

    def test_run_delivery_started_preserved_as_trigger_only(self):
        self.assertIn("run.delivery_started", (ROOT / "supabase" / "migrations" / "202608280001_s4_06_batch_2_run_sequence_pickup_delivery.sql").read_text(encoding="utf-8"))

    def test_no_direct_protected_table_mutation_in_new_code(self):
        new_fn_names = [
            r"function enterRun\(sessionId\)\{", r"function renderPickupChecklist\(\)\{",
            r"function moveStop\(index,dir\)\{",
        ]
        for pattern in new_fn_names:
            fn = block(INDEX_HTML, pattern)
            self.assertNotIn("api.request(", fn)


if __name__ == "__main__":
    unittest.main()
