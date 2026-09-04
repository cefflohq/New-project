"""Static acceptance for Flow 3 F3-04: Zone edit/rename/enable-disable UI.

CEFFLO Flow 3 Vendor Web/Desktop Completion Master, Section 14 required
"list Zones; inspect Zone; create Zone; rename/edit; enable/disable" --
the F3-00 baseline audit found rename_zone/set_zone_status (Flow 2, S4-06
Batch 3) had existed with no Vendor call-site at all. This proves the new
Zone Detail screen and its two actions are wired to those real RPCs.

Browser tooling is not connected in this environment, so this is a
static/structural check against the real source, matching the established
precedent (s4_06_batch_5b_vendor_run_builder_wiring.py and others).
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


class ZoneRpcWrapperTests(unittest.TestCase):
    def test_rename_zone_wrapper_calls_real_rpc(self):
        fn = next(line for line in BACKEND_JS.splitlines() if "const renameZone" in line)
        self.assertIn("api.rpc('rename_zone'", fn)

    def test_set_zone_status_wrapper_calls_real_rpc(self):
        fn = next(line for line in BACKEND_JS.splitlines() if "const setZoneStatus" in line)
        self.assertIn("api.rpc('set_zone_status'", fn)


class ZoneActionWiringTests(unittest.TestCase):
    def test_confirm_rename_zone_calls_real_rpc_and_refreshes(self):
        fn = block(BACKEND_JS, r"ACTIONS\.confirmRenameZone = async function \(el\) \{", end_marker="\n  };")
        self.assertIn("await renameZone(", fn)
        self.assertIn("await hydrateCanonicalWorkspace()", fn)
        rpc_index = fn.index("await renameZone(")
        toast_index = fn.index("toast('Zone renamed'")
        self.assertLess(rpc_index, toast_index, "success toast must follow the awaited RPC, never precede it")

    def test_confirm_toggle_zone_status_calls_real_rpc_and_refreshes(self):
        fn = block(BACKEND_JS, r"ACTIONS\.confirmToggleZoneStatus = async function \(el\) \{", end_marker="\n  };")
        self.assertIn("await setZoneStatus(", fn)
        self.assertIn("await hydrateCanonicalWorkspace()", fn)
        self.assertIn("el.dataset.nextStatus", fn)

    def test_rename_zone_failure_cannot_produce_success_ui(self):
        fn = block(BACKEND_JS, r"ACTIONS\.confirmRenameZone = async function \(el\) \{", end_marker="\n  };")
        self.assertIn("catch (error)", fn)
        catch_body = fn[fn.index("catch (error)"):]
        self.assertNotIn("toast('Zone renamed'", catch_body)

    def test_toggle_zone_status_failure_cannot_produce_success_ui(self):
        fn = block(BACKEND_JS, r"ACTIONS\.confirmToggleZoneStatus = async function \(el\) \{", end_marker="\n  };")
        self.assertIn("catch (error)", fn)
        catch_body = fn[fn.index("catch (error)"):]
        self.assertNotIn("Zone enabled", catch_body)
        self.assertNotIn("Zone disabled", catch_body)


class ZoneDetailUiWiringTests(unittest.TestCase):
    def test_zone_rows_navigate_to_zone_detail(self):
        fn = block(INDEX_HTML, r"function pageZones\(\)\{")
        self.assertIn('data-nav="zoneDetail"', fn)
        self.assertIn('data-navparams=\'{"id":"${zone.id}"}\'', fn)

    def test_zone_detail_page_registered_in_pages_map(self):
        self.assertIn("zoneDetail: pageZoneDetail,", INDEX_HTML)

    def test_zone_detail_page_offers_rename_and_toggle(self):
        fn = block(INDEX_HTML, r"function pageZoneDetail\(params\)\{")
        self.assertIn('data-action="openRenameZone"', fn)
        self.assertIn('data-action="confirmToggleZoneStatus"', fn)
        self.assertIn("data-next-status", fn)

    def test_rename_sheet_targets_confirm_rename_zone(self):
        fn = block(INDEX_HTML, r"function openRenameZone\(el\)\{")
        self.assertIn('data-action="confirmRenameZone"', fn)
        self.assertIn('id="rz_name"', fn)

    def test_index_html_stubs_are_honest_pre_backend_load_fallbacks(self):
        # These must exist as the standard "Backend not connected." stub so
        # a click before backend.js finishes loading never fakes success --
        # backend.js's ACTIONS.confirmRenameZone/confirmToggleZoneStatus
        # override them once loaded (same established pattern as
        # confirmCreateZone/confirmEditServiceArea above them).
        self.assertIn(
            "function confirmRenameZone(){ toast('Backend not connected.', 'error'); }", INDEX_HTML
        )
        self.assertIn(
            "function confirmToggleZoneStatus(){ toast('Backend not connected.', 'error'); }", INDEX_HTML
        )

    def test_new_actions_registered_in_actions_object(self):
        self.assertIn(
            "openCreateZone, confirmCreateZone, openRenameZone, confirmRenameZone, confirmToggleZoneStatus,",
            INDEX_HTML,
        )


if __name__ == "__main__":
    unittest.main()
