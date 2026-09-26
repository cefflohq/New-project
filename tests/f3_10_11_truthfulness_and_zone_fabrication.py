"""Static acceptance for Flow 3 F3-10, F3-11, F3-03, and the mapRider
zone-fabrication fix, found during the F3-08/F3-10/F3-11 re-audit pass.

F3-10: Business Logo upload showed an unqualified "Logo updated" success
claim while only ever writing to localStorage on the current browser (no
backend RPC parameter for a logo exists at all) -- now honestly disclosed
as a device-local preview, matching this codebase's existing "Preview
only" disclosure convention.

F3-11:
1. Change Password (pageChangePassword/savePasswordChange, a real Supabase
   Auth reauth+update flow) was DEAD-UNREACHABLE -- its only nav trigger
   lived inside the dead legacy pageSettings() menu. Now reachable from
   the live pageSettingsProposed() menu.
2. The granular per-category Notification Settings page was
   DEAD-UNREACHABLE and would have been undisclosed-fake if reachable (no
   backend notification-preference system exists at all) -- removed
   entirely rather than reconciled, since there is no canonical concept to
   reconcile it to.
3. The live Notifications toggle (vendorNotificationsEnabled) had zero
   effect anywhere and silently reset to true every reload -- now
   genuinely persisted to localStorage, matching the Dark Mode toggle's
   own pattern.

mapRider's hardcoded zone:'Unassigned' (riders have no real zone-assignment
concept in the Flow 2 schema) was displayed as if real per-Rider status in
four live places -- all four now show honest data without the fabricated
zone label.

F3-03: validateImportRows no longer rejects a row for a missing zone
(import_orders_batch treats zone as optional -- the preview must not be
stricter than the real backend contract), and the "Recent Imports" section
now renders from the real import.committed delivery_events ledger instead
of permanently claiming "No recent imports".

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


class BusinessLogoDisclosureTests(unittest.TestCase):
    def test_local_only_disclosure_present(self):
        fn = block(INDEX_HTML, r"function pageBusinessProfile\(\)\{")
        self.assertIn("t('logoLocalOnlyNote')", fn)

    def test_disclosure_string_defined_in_english_locale(self):
        self.assertIn("logoLocalOnlyNote:'Preview on this device only", INDEX_HTML)


class ChangePasswordReachabilityTests(unittest.TestCase):
    def test_live_settings_menu_has_change_password_row(self):
        fn = block(INDEX_HTML, r"function pageSettingsProposed\(\)\{")
        self.assertIn("row('lock',t('changePassword'),'changePassword')", fn)


class NotificationSettingsRemovalTests(unittest.TestCase):
    def test_granular_page_function_removed(self):
        self.assertNotIn("function pageNotificationSettingsPage(", INDEX_HTML)
        self.assertNotIn("const notifSettings", INDEX_HTML)
        self.assertNotIn("function toggleNotifSetting(", INDEX_HTML)

    def test_removed_from_pages_map(self):
        self.assertNotIn("notificationSettingsPage: pageNotificationSettingsPage", INDEX_HTML)

    def test_removed_from_actions_object(self):
        self.assertNotIn("toggleNotifSetting,", INDEX_HTML)

    def test_removed_from_dead_legacy_menu_reference(self):
        self.assertNotIn("nav:'notificationSettingsPage'", INDEX_HTML)


class NotificationsTogglePersistenceTests(unittest.TestCase):
    def test_reads_from_localstorage_on_init(self):
        idx = INDEX_HTML.index("let vendorNotificationsEnabled=")
        line = INDEX_HTML[idx:INDEX_HTML.index("\n", idx)]
        self.assertIn("localStorage.getItem('cefflo_notifications_enabled')", line)

    def test_toggle_persists_to_localstorage(self):
        fn = block(INDEX_HTML, r"function toggleVendorNotifications\(\)\{")
        self.assertIn("localStorage.setItem('cefflo_notifications_enabled'", fn)


class RiderZoneFabricationTests(unittest.TestCase):
    def test_riders_list_no_longer_shows_fake_zone(self):
        fn = block(INDEX_HTML, r"function renderRiderListOnly\(", end_marker="\n}")
        self.assertNotIn("r.zone", fn)

    def test_assign_rider_picker_no_longer_shows_fake_zone(self):
        fn = block(INDEX_HTML, r"function openAssignRiderForOrder\(el\)\{")
        self.assertNotIn("r.zone", fn)

    def test_dashboard_offline_alert_no_longer_shows_fake_zone(self):
        fn = block(INDEX_HTML, r"function pageDashboardProposed\(\)\{")
        self.assertNotIn("offline.zone", fn)
        self.assertIn("t('riderIsOffline')", fn)

    def test_dashboard_current_deliveries_no_longer_shows_fake_zone(self):
        fn = block(INDEX_HTML, r"function pageDashboardProposed\(\)\{")
        self.assertNotIn("${r.zone}", fn)

    def test_map_rider_documents_why_field_stays_hardcoded(self):
        fn = block(BACKEND_JS, r"function mapRider\(row\) \{")
        self.assertIn("no real zone-", fn)
        self.assertIn("assignment concept", fn)


class BulkImportTruthfulnessTests(unittest.TestCase):
    def test_zone_no_longer_required_by_frontend_validation(self):
        fn = block(INDEX_HTML, r"function validateImportRows\(rows\)\{")
        self.assertNotIn("Missing zone", fn)

    def test_recent_imports_hydrated_from_real_ledger_event(self):
        fn = block(BACKEND_JS, r"async function hydrateCanonicalWorkspace\(\) \{", end_marker="\n  }")
        self.assertIn("event.event_type === 'import.committed'", fn)
        self.assertIn("state.recentImports", fn)

    def test_recent_imports_ui_renders_real_data_with_honest_empty_state(self):
        fn = block(INDEX_HTML, r"function pageCsvImport\(\)\{", end_marker="\n  if(csvState.step===2){")
        self.assertIn("state.recentImports", fn)
        self.assertIn("No recent imports", fn)


if __name__ == "__main__":
    unittest.main()
