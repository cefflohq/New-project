"""Static acceptance for Flow 3 F3-12's legacy "Milestone 3/4/6" apparatus
cleanup in vendor/index.html.

A dedicated Explore-agent reachability trace this session overturned the
working assumption from earlier in the session that this whole labeled
apparatus was dead legacy code shadowed by backend.js. It is not: Sprint
1.3 and most of Milestone 6 are the actual, sole, live authentication
system (login/signup/logout/password-reset/session-restore), wired
directly via onclick on real buttons and via initializeSprint13() being
the app's literal boot statement. Removal therefore proceeded as several
narrow, verified-dead symbol removals, not a blanket deletion:

- Milestone 3 (the entire local sessions/orders/assignments/stops command
  engine, its own event bus, transaction wrapper) removed in full --
  confirmed zero call sites anywhere outside itself.
- Milestone 4's dead command-layer remnants (ensureActiveSessionForUi,
  updateBusinessProfileCommand, its window.CEFFLO_ENGINE.commands/.frontend
  writes, its own ACTIONS.saveBusinessProfile override, a dead event-
  registration forEach) removed -- its live render-path cluster
  (hydrateFrontendReadModel/orderUiView/riderUiView/FRONTEND_SELECTORS,
  called by render() on every render) is explicitly NOT touched.
- Milestone 6's dead periphery (the offline-sync-queue apparatus,
  signInWithPassword, uploadProductionFile, customerTrackingSnapshot,
  productionHealth, appendAuditLog/restoreAuditLogs and their event
  registration) removed -- its live auth/config plumbing
  (CEFFLO_RUNTIME_CONFIG, productionState, productionConfigured, the
  backendConfigured/backendHeaders/backendRequest reassignments,
  authRequest, storeAuthSession, restoreAuthSession, signUpWithPassword,
  refreshAuthSession, productionSignOut, reauthenticateCurrentUser,
  updateAuthenticatedPassword, initializeProductionIntegration) is
  explicitly NOT touched -- this is the real production auth system.
- A pre-existing local-only fake-success landmine in saveBusinessProfile
  (the pre-Milestone-4 baseline the ACTIONS object falls back to before
  backend.js loads) was also replaced with the standard honest stub, the
  same class of bug as the already-fixed confirmAssignRiderOrder.

Also proves the object-literal properties that referenced now-removed
symbols were cleaned up alongside them (window.CEFFLO_ENGINE.production's
audit/storage/tracking/monitoring/sync keys, the online listener's dead
flushOfflineQueue call, initializeProductionIntegration's dead
restoreOfflineQueue/restoreAuditLogs/flushOfflineQueue calls) -- these are
exactly the class of dangling-reference bug this test suite exists to
catch before it reaches a real browser.

Browser tooling is not connected in this environment, so this is a
static/structural check against the real source, matching the established
precedent (s4_06_batch_5b_vendor_run_builder_wiring.py and others).
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INDEX_HTML = (ROOT / "vendor" / "index.html").read_text(encoding="utf-8")


def block(source, start_pattern, end_marker="\n}"):
    match = re.search(start_pattern, source)
    assert match, f"pattern not found: {start_pattern}"
    start = match.start()
    end = source.index(end_marker, start) + len(end_marker)
    return source[start:end]


DEAD_SYMBOLS = (
    "CEFFLO_ENGINE_VERSION", "SESSION_TRANSITIONS", "ASSIGNMENT_TRANSITIONS",
    "ACTIVE_ASSIGNMENT_STATES", "TERMINAL_ORDER_STATES", "ENGINE_EVENT_HANDLERS",
    "function engineId(", "function nowIso(", "function assertEngine(",
    "function onEngineEvent(", "function emitEngineEvent(", "function runEngineTransaction(",
    "function findSession(", "function findAssignment(", "function findStop(",
    "function findOpenIssueByOrder(", "function assignmentOrders(", "function assignmentStops(",
    "function addOperationalNotification(", "function createProductionOrder(",
    "function transitionDeliverySession(", "function assignZoneToRider(",
    "function transitionAssignment(", "function recalculateStopSequence(",
    "function getOperationalSnapshot(", "function validateOperationalIntegrity(",
    "function ensureActiveSessionForUi(", "function updateBusinessProfileCommand(",
    "const OFFLINE_QUEUE_KEY", "function restoreOfflineQueue(", "function saveOfflineQueue(",
    "function queueOfflineSync(", "async function flushOfflineQueue(", "milestone6BaseSync",
    "async function signInWithPassword(", "async function uploadProductionFile(",
    "function customerTrackingSnapshot(", "function productionHealth(",
    "function appendAuditLog(", "function restoreAuditLogs(",
)

LIVE_SYMBOLS = (
    "const CEFFLO_RUNTIME_CONFIG", "const productionState", "function productionConfigured(",
    "backendConfigured=function", "backendHeaders=function", "backendRequest=async function",
    "async function authRequest(", "function storeAuthSession(", "function restoreAuthSession(",
    "async function signUpWithPassword(", "async function refreshAuthSession(",
    "async function productionSignOut(", "async function reauthenticateCurrentUser(",
    "async function updateAuthenticatedPassword(", "async function initializeProductionIntegration(",
    "function hydrateFrontendReadModel(", "function orderUiView(", "function riderUiView(",
    "const FRONTEND_SELECTORS",
)


class DeadSymbolsRemovedTests(unittest.TestCase):
    def test_every_confirmed_dead_symbol_is_gone(self):
        for symbol in DEAD_SYMBOLS:
            self.assertNotIn(symbol, INDEX_HTML, f"dead symbol still present: {symbol}")


class LiveSymbolsPreservedTests(unittest.TestCase):
    def test_every_confirmed_live_symbol_still_present(self):
        for symbol in LIVE_SYMBOLS:
            self.assertIn(symbol, INDEX_HTML, f"live symbol was incorrectly removed: {symbol}")

    def test_real_login_button_still_wired(self):
        self.assertIn('onclick="submitProductionLogin(this)"', INDEX_HTML)

    def test_real_signup_button_still_wired(self):
        self.assertIn('onclick="submitProductionSignup(this)"', INDEX_HTML)

    def test_boot_call_still_present(self):
        self.assertIn("initializeSprint13().catch(", INDEX_HTML)


class NoDanglingReferencesTests(unittest.TestCase):
    def test_no_reference_to_removed_engine_command_or_selector_api(self):
        # Executable references only -- prose comments explaining the
        # removal legitimately name these strings for documentation.
        for pattern in ("window.CEFFLO_ENGINE.on(", "window.CEFFLO_ENGINE.commands.updateBusinessProfile=", "window.CEFFLO_ENGINE.emit("):
            for line in INDEX_HTML.splitlines():
                stripped = line.strip()
                if stripped.startswith("//") or stripped.startswith("*"):
                    continue
                self.assertNotIn(pattern, line, f"executable reference to removed API: {pattern!r} in {line!r}")

    def test_production_object_only_references_live_symbols(self):
        fn = block(INDEX_HTML, r"async function initializeProductionIntegration\(\)\{")
        self.assertNotIn("appendAuditLog", fn)
        self.assertNotIn("uploadProductionFile", fn)
        self.assertNotIn("customerTrackingSnapshot", fn)
        self.assertNotIn("productionHealth", fn)
        self.assertNotIn("restoreOfflineQueue", fn)
        self.assertNotIn("flushOfflineQueue", fn)
        self.assertNotIn("restoreAuditLogs", fn)
        self.assertIn("signUpWithPassword", fn)
        self.assertIn("restoreAuthSession", fn)

    def test_online_listener_no_longer_calls_removed_flush(self):
        idx = INDEX_HTML.index("window.addEventListener('online'")
        line = INDEX_HTML[idx:INDEX_HTML.index("\n", idx)]
        self.assertNotIn("flushOfflineQueue", line)

    def test_save_business_profile_landmine_fixed(self):
        # The pre-Milestone-4 baseline saveBusinessProfile (what
        # ACTIONS.saveBusinessProfile falls back to before backend.js
        # loads) was a local-only mutation claiming success with no RPC
        # call at all -- same class of bug as confirmAssignRiderOrder.
        fn = block(INDEX_HTML, r"\nfunction saveBusinessProfile\(\)\{", end_marker="}")
        self.assertIn("Backend not connected.", fn)
        self.assertNotIn("businessProfileSaved", fn)
        self.assertNotIn("state.storeName = values.storeName", fn)


if __name__ == "__main__":
    unittest.main()
