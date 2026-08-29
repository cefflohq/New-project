"""Static acceptance for S4-06 Batch-5b Vendor Run Builder UI/backend wiring.

Browser tooling (Claude in Chrome) is not connected in this environment, so
this is a static/structural check against the real source -- not a
substitute for an eventual real click-through, which is called out
separately in the checkpoint as an open item, matching the precedent set
by s4_05_batch_2_vendor_approval_wiring.py and the S4-15 RC browser
acceptance gate.
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BACKEND_JS = (ROOT / "vendor" / "backend.js").read_text(encoding="utf-8")
INDEX_HTML = (ROOT / "vendor" / "index.html").read_text(encoding="utf-8")


def block(source, start_pattern, end_marker="\n}"):
    match = re.search(start_pattern, source)
    assert match, f"pattern not found: {start_pattern}"
    start = match.start()
    end = source.index(end_marker, start) + len(end_marker)
    return source[start:end]


class RealHydrationTests(unittest.TestCase):
    def test_zones_and_sessions_hydrated_from_real_endpoints(self):
        self.assertIn("listZones = businessId => api.request(`/rest/v1/zones", BACKEND_JS)
        self.assertIn("listDeliverySessions = businessId => api.request(`/rest/v1/delivery_sessions", BACKEND_JS)
        self.assertIn("state.zones = zones.map(mapZone)", BACKEND_JS)
        self.assertIn("state.deliverySessions = sessions.map(mapSession)", BACKEND_JS)

    def test_hydration_no_longer_unconditionally_wipes_zones_or_sessions(self):
        hydrate_fn = block(BACKEND_JS, r"async function hydrateCanonicalWorkspace\(\) \{", "\n  }")
        self.assertNotIn("state.zones = [];", hydrate_fn)
        self.assertNotIn("state.deliverySessions = [];", hydrate_fn)

    def test_no_fabricated_fallback_values_for_zone_or_session_fields(self):
        self.assertIn("function mapZone(row) {\n    return { id: row.id, name: row.name, status: row.status };", BACKEND_JS)
        self.assertIn(
            "function mapSession(row) {\n    return { id: row.id, name: row.name, status: row.status, deliveryDate: row.delivery_date };",
            BACKEND_JS,
        )

    def test_order_mapping_carries_real_zone_and_session_ids(self):
        self.assertIn("zoneId: row.zone_id, deliverySessionId: row.delivery_session_id", BACKEND_JS)

    def test_hydration_triggers_run_builder_reconciliation_hook(self):
        hydrate_fn = block(BACKEND_JS, r"async function hydrateCanonicalWorkspace\(\) \{", "\n  }")
        self.assertIn("reconcileRunBuilderAfterHydrate", hydrate_fn)


class BackendRpcWiringTests(unittest.TestCase):
    def test_create_delivery_session_and_build_rider_run_exposed(self):
        self.assertIn("createDeliverySession", BACKEND_JS)
        self.assertIn("buildRiderRun", BACKEND_JS)
        self.assertRegex(BACKEND_JS, r"window\.CEFFLO_VENDOR = Object\.freeze\(\{[^}]*createDeliverySession[^}]*buildRiderRun[^}]*\}\)")

    def test_confirm_run_builder_calls_build_rider_run_exactly_once(self):
        handler = block(BACKEND_JS, r"confirmRunBuilder = async function \(\) \{", "\n  };")
        self.assertEqual(handler.count("api.rpc('build_rider_run'"), 1)
        self.assertEqual(handler.count("api.rpc('create_delivery_session'"), 1)

    def test_confirm_run_builder_registered_in_dispatcher(self):
        self.assertIn("ACTIONS.confirmRunBuilder = confirmRunBuilder;", BACKEND_JS)

    def test_no_old_client_side_2n_loop(self):
        handler = block(BACKEND_JS, r"confirmRunBuilder = async function \(\) \{", "\n  };")
        self.assertNotIn("attach_order_to_session", handler)
        self.assertNotIn("assign_rider'", handler)

    def test_no_optimistic_local_success_before_rpc_resolves(self):
        handler = block(BACKEND_JS, r"confirmRunBuilder = async function \(\) \{", "\n  };")
        build_call_pos = handler.index("api.rpc('build_rider_run'")
        toast_pos = handler.index("toast(")
        self.assertLess(build_call_pos, toast_pos, "success toast must come after the RPC call, not before")
        hydrate_pos = handler.index("hydrateCanonicalWorkspace()")
        self.assertLess(build_call_pos, hydrate_pos)
        self.assertLess(hydrate_pos, toast_pos)


class IdempotencyKeyTests(unittest.TestCase):
    def test_key_generated_once_per_signature_not_every_call(self):
        handler = block(BACKEND_JS, r"confirmRunBuilder = async function \(\) \{", "\n  };")
        self.assertIn("runBuilderPayloadSignature(sessionId, rider.id, orderIds)", handler)
        self.assertIn("if (runBuilderState.pendingSignature !== signature)", handler)
        self.assertIn("randomUUID", handler)

    def test_session_creation_cached_for_retry_not_repeated(self):
        handler = block(BACKEND_JS, r"confirmRunBuilder = async function \(\) \{", "\n  };")
        self.assertIn("runBuilderState.resolvedNewSessionId = sessionId;", handler)
        self.assertIn("let sessionId = runBuilderState.waveMode === 'existing' ? runBuilderState.waveId : runBuilderState.resolvedNewSessionId;", handler)

    def test_new_wave_name_edit_invalidates_cached_session(self):
        self.assertIn("runBuilderState.newWaveName=this.value; runBuilderState.resolvedNewSessionId=null;", INDEX_HTML)

    def test_wave_mode_switch_invalidates_cached_session(self):
        fn = block(INDEX_HTML, r"function runBuilderSetWaveMode\(el\)\{")
        self.assertIn("runBuilderState.resolvedNewSessionId = null;", fn)

    def test_signature_includes_session_rider_and_sorted_order_ids(self):
        self.assertIn(
            "function runBuilderPayloadSignature(sessionId, riderId, orderIds) {\n    return JSON.stringify({ sessionId, riderId, orderIds: [...orderIds].sort() });",
            BACKEND_JS,
        )


class ErrorAndConflictHandlingTests(unittest.TestCase):
    def test_eligibility_conflict_triggers_refresh_and_reconciliation(self):
        fn = block(INDEX_HTML, r"async function handleRunBuilderError\(error\)\{")
        self.assertIn("orders no longer eligible", fn)
        self.assertIn("hydrateCanonicalWorkspace", fn)

    def test_idempotency_conflict_does_not_auto_retry_with_new_key(self):
        fn = block(INDEX_HTML, r"async function handleRunBuilderError\(error\)\{")
        self.assertIn("idempotency key conflict", fn)
        conflict_branch_start = fn.index("idempotency key conflict")
        conflict_branch = fn[conflict_branch_start:conflict_branch_start + 200]
        self.assertNotIn("randomUUID", conflict_branch)
        self.assertNotIn("confirmRunBuilder()", conflict_branch)

    def test_reconcile_after_hydrate_removes_ineligible_selections_and_invalidates_key(self):
        fn = block(INDEX_HTML, r"async function reconcileRunBuilderAfterHydrate\(\)\{")
        self.assertIn("stillEligible", fn)
        self.assertIn("runBuilderState.pendingKey=null", fn)

    def test_offline_disables_confirm(self):
        self.assertIn("navigator.onLine===false", INDEX_HTML)
        render_fn = block(INDEX_HTML, r"function renderRunBuilderBody\(\)\{")
        self.assertIn("!offline &&", render_fn)


class EligibilityTests(unittest.TestCase):
    def test_eligibility_rule_matches_backend_contract(self):
        self.assertIn(
            "function isRunBuilderEligible(o){\n  return Boolean(o.approvedAt) && !o.riderId && o.backendStatus==='created';",
            INDEX_HTML,
        )

    def test_zone_is_not_an_eligibility_gate(self):
        fn = block(INDEX_HTML, r"function isRunBuilderEligible\(o\)\{")
        self.assertNotIn("zoneId", fn)

    def test_unzoned_orders_remain_selectable(self):
        self.assertIn("Unzoned", INDEX_HTML)
        self.assertIn("'__unzoned__'", INDEX_HTML)


class ZoneFilterTests(unittest.TestCase):
    def test_zone_filter_is_multi_toggle_not_single_select(self):
        fn = block(INDEX_HTML, r"function runBuilderToggleZone\(el\)\{")
        self.assertIn("zoneFilters.has(zone)) runBuilderState.zoneFilters.delete(zone)", fn)
        self.assertIn("else runBuilderState.zoneFilters.add(zone)", fn)

    def test_selecting_zone_never_auto_selects_orders(self):
        fn = block(INDEX_HTML, r"function runBuilderToggleZone\(el\)\{")
        self.assertNotIn("selectedOrderIds", fn)

    def test_zone_counts_reflect_eligible_orders_only(self):
        fn = block(INDEX_HTML, r"function runBuilderZoneCounts\(\)\{")
        self.assertIn("runBuilderEligibleOrders()", fn)


class RunBuilderSharedComponentTests(unittest.TestCase):
    def test_single_shared_render_function_backs_both_entry_points(self):
        self.assertEqual(INDEX_HTML.count("function renderRunBuilderBody()"), 1)
        self.assertEqual(INDEX_HTML.count("function openRunBuilder(opts)"), 1)

    def test_rider_first_entry_replaces_old_mock_zone_assign(self):
        fn = block(INDEX_HTML, r"function openAssignOrdersToRider\(el\)\{")
        self.assertIn("openRunBuilder({ riderId: rid })", fn)
        self.assertNotIn("syncZonesFromOrders", fn)
        self.assertNotIn("selectZone", fn)

    def test_orders_first_entry_converges_on_same_run_builder(self):
        fn = block(INDEX_HTML, r"function openRunBuilderFromOrdersSelection\(\)\{")
        self.assertIn("openRunBuilder({ orderIds", fn)

    def test_no_second_independent_confirm_path(self):
        self.assertEqual(INDEX_HTML.count('data-action="confirmRunBuilder"'), 1)


class DormantMockPreservedTests(unittest.TestCase):
    """Old mock behavior must not be called from any live Run Builder path,
    but per the Founder's explicit instruction it may remain dormant rather
    than being deleted."""

    def test_old_mock_functions_still_defined_but_unreferenced_by_new_code(self):
        for name in ("syncZonesFromOrders", "assignZoneToRiderFromProfile"):
            self.assertIn(f"function {name}", INDEX_HTML)

        new_code_functions = [
            "openRunBuilder", "renderRunBuilderBody", "confirmRunBuilder",
            "runBuilderToggleZone", "runBuilderToggleOrder", "runBuilderSelectRider",
            "runBuilderSetWaveMode", "runBuilderSelectWave", "reconcileRunBuilderAfterHydrate",
            "handleRunBuilderError", "toggleOrdersSelectMode", "openRunBuilderFromOrdersSelection",
        ]
        for fn_name in new_code_functions:
            pattern = rf"(async )?function {fn_name}\("
            fn_src = block(INDEX_HTML, pattern) if not fn_name.startswith("confirmRunBuilder") else None
            if fn_src is None:
                continue
            self.assertNotIn("syncZonesFromOrders", fn_src, fn_name)
            self.assertNotIn("assignZoneToRiderFromProfile", fn_src, fn_name)

    def test_dispatch_planner_and_zone_detail_remain_unreferenced(self):
        # Confirmed dead in the S4-06.5 design-reconciliation audit; must
        # stay that way -- no new data-nav/data-action may target them.
        self.assertNotIn('data-nav="dispatchPlanner"', INDEX_HTML)
        self.assertNotIn('data-action="pageDispatchPlanner"', INDEX_HTML)

    def test_no_geographic_or_route_intelligence_introduced(self):
        new_block_start = INDEX_HTML.index("/* ===================== RUN BUILDER (S4-06.5b)")
        new_block_end = INDEX_HTML.index("function openDeactivateRider", new_block_start)
        run_builder_source = INDEX_HTML[new_block_start:new_block_end]
        for forbidden in ("haversine", "pointInPolygon", "recalculateAssignmentRoute", "etaMinutes", "zoneCentroid"):
            self.assertNotIn(forbidden, run_builder_source)


class WaveUxTests(unittest.TestCase):
    def test_existing_wave_filtered_to_planned_or_active(self):
        fn = block(INDEX_HTML, r"function runBuilderExistingWaves\(\)\{")
        self.assertIn("'planned'", fn)
        self.assertIn("'active'", fn)

    def test_wave_counts_are_real_not_fabricated(self):
        order_count_fn = block(INDEX_HTML, r"function runBuilderWaveOrderCount\(sessionId\)\{")
        self.assertIn("state.orders.filter", order_count_fn)
        rider_count_fn = block(INDEX_HTML, r"function runBuilderWaveRiderCount\(sessionId\)\{")
        self.assertIn("state.orders.filter", rider_count_fn)

    def test_multiple_same_day_waves_supported_no_per_day_restriction(self):
        self.assertNotIn("oneSessionPerDay", BACKEND_JS)
        self.assertNotIn("delivery_date=eq.", BACKEND_JS)

    def test_vendor_facing_terminology_is_wave_in_new_ui_copy(self):
        self.assertIn(">Wave<", INDEX_HTML)
        self.assertIn("Add to Existing Wave", INDEX_HTML)
        self.assertIn("Start New Wave", INDEX_HTML)


class SingleOrderRegressionTests(unittest.TestCase):
    def test_single_order_assign_flow_untouched(self):
        self.assertIn('data-action="openAssignRiderForOrder"', INDEX_HTML)
        fn = block(INDEX_HTML, r"function openAssignRiderForOrder\(el\)\{")
        self.assertIn("confirmAssignRiderOrder", fn)

    def test_reassign_path_untouched(self):
        self.assertIn("reassignRider", BACKEND_JS)
        self.assertIn("api.rpc('reassign_rider'", BACKEND_JS)


class ScopeBoundaryTests(unittest.TestCase):
    def test_no_direct_protected_table_mutation_in_run_builder(self):
        new_block_start = INDEX_HTML.index("/* ===================== RUN BUILDER (S4-06.5b)")
        new_block_end = INDEX_HTML.index("function openDeactivateRider", new_block_start)
        run_builder_source = INDEX_HTML[new_block_start:new_block_end]
        self.assertNotIn("api.request(", run_builder_source)
        for table in ("/rest/v1/orders", "/rest/v1/rider_assignments", "/rest/v1/delivery_stops"):
            self.assertNotIn(table, run_builder_source)

    def test_no_s4_06_6_or_rider_ui_files_touched(self):
        self.assertFalse((ROOT / "rider" / "index.html").read_text(encoding="utf-8").find("runBuilderState") != -1)
        self.assertFalse((ROOT / "rider" / "backend.js").read_text(encoding="utf-8").find("build_rider_run") != -1)

    def test_no_customer_ui_touched(self):
        self.assertFalse((ROOT / "customer" / "index.html").read_text(encoding="utf-8").find("runBuilderState") != -1)


if __name__ == "__main__":
    unittest.main()
