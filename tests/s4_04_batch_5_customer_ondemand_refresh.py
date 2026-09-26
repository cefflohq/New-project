"""Static acceptance for the Customer Tracking on-demand-refresh policy.

Browser tooling (Claude in Chrome) is not connected in this environment, so
this is a static/structural check against the real source, matching the
established pattern in tests/test_rider_logout_fix.py -- not a substitute
for an eventual manual/browser smoke test, which is called out separately
in the checkpoint.
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BACKEND_JS = (ROOT / "customer" / "backend.js").read_text(encoding="utf-8")
INDEX_HTML = (ROOT / "customer" / "index.html").read_text(encoding="utf-8")
APP_JS = (ROOT / "customer" / "app.js").read_text(encoding="utf-8")
ADAPTER_JS = (ROOT / "customer" / "tracking-adapter.js").read_text(encoding="utf-8")
# The approved C1-C4 Customer screens (rendered by app.js) retired the inline
# refresh button and freshness chrome. The backend refresh/freshness contract
# is still asserted; the UI side asserts the superseded state.
CUSTOMER_UI = INDEX_HTML + APP_JS


class NoContinuousPollingTests(unittest.TestCase):
    def test_no_setinterval_calling_refresh_in_backend_js(self):
        # The old continuous-polling call must be gone entirely.
        self.assertNotIn("setInterval(() => refresh()", BACKEND_JS)
        self.assertNotIn("setInterval(() => refresh().catch", BACKEND_JS)

    def test_backend_js_setinterval_count_is_zero(self):
        # backend.js itself must contain no setInterval at all -- the only
        # UI-only ticking timer lives in index.html, not here.
        self.assertNotIn("setInterval", BACKEND_JS)


class RefreshTriggerTests(unittest.TestCase):
    def test_initial_load_refresh_preserved(self):
        self.assertIn("window.addEventListener('load', guardedRefresh)", BACKEND_JS)

    def test_visibility_return_refresh_present(self):
        self.assertIn("visibilitychange", BACKEND_JS)
        self.assertIn("document.visibilityState === 'visible'", BACKEND_JS)

    def test_pageshow_bfcache_refresh_present(self):
        self.assertIn("pageshow", BACKEND_JS)
        self.assertIn("event.persisted", BACKEND_JS)

    def test_manual_refresh_exposed_and_wired(self):
        self.assertIn("window.CEFFLO_CUSTOMER = Object.freeze({ refresh: guardedRefresh", BACKEND_JS)
        # Superseded: the approved UI has no inline manual refresh button.
        self.assertNotIn('id="refreshButton"', CUSTOMER_UI)

    def test_all_triggers_share_the_same_guarded_path(self):
        # load, visibilitychange, and pageshow must all call guardedRefresh --
        # not a bare refresh() that bypasses the shared guard.
        for trigger_snippet in (
            "window.addEventListener('load', guardedRefresh)",
            "if (document.visibilityState === 'visible') guardedRefresh();",
            "if (event.persisted) guardedRefresh();",
        ):
            self.assertIn(trigger_snippet, BACKEND_JS)


class DuplicateEventProtectionTests(unittest.TestCase):
    def test_in_flight_guard_present(self):
        self.assertIn("isRefreshing", BACKEND_JS)
        self.assertIn("if (isRefreshing) return;", BACKEND_JS)

    def test_cooldown_present_and_uniform(self):
        self.assertIn("REFRESH_COOLDOWN_MS = 3000", BACKEND_JS)
        self.assertIn("if (Date.now() - lastRefreshAt < REFRESH_COOLDOWN_MS) return;", BACKEND_JS)


class FreshnessIndicatorTests(unittest.TestCase):
    def test_freshness_text_element_present(self):
        # Superseded: the approved UI has no freshness text element.
        self.assertNotIn('id="freshnessText"', CUSTOMER_UI)

    def test_freshness_setter_wired_from_refresh(self):
        self.assertIn("window.CEFFLOTracking.setFreshness", BACKEND_JS)
        # The adapter keeps the contract callable as a UI-free no-op.
        self.assertRegex(ADAPTER_JS, r"setFreshness\(\)\s*{\s*/\*[^*]*\*/\s*}")

    def test_freshness_ticker_never_calls_network(self):
        # With the freshness chrome retired, no customer-surface timer may
        # exist that could re-trigger an RPC/fetch.
        for source in (INDEX_HTML, APP_JS, ADAPTER_JS):
            self.assertNotIn("setInterval", source)

    def test_no_countdown_to_next_poll_shown(self):
        self.assertNotIn("next update in", INDEX_HTML.lower())
        self.assertNotIn("next refresh in", INDEX_HTML.lower())


class SharedLinkAndMarkerBehaviorTests(unittest.TestCase):
    def test_no_new_account_requirement_introduced(self):
        # public_tracking is still called with only the token, no auth
        # requirement added for a shared-link recipient.
        self.assertIn("api.rpc('public_tracking', { p_token: token }, { token: null })", BACKEND_JS)

    def test_no_fabricated_coordinate_animation_introduced(self):
        # No lat/lng or coordinate-interpolation logic exists in this batch --
        # the rider marker remains static decorative markup, not a fabricated
        # live-movement simulation.
        for forbidden in ("latitude", "longitude", "lat:", "lng:", "interpolat"):
            self.assertNotIn(forbidden, BACKEND_JS.lower())


if __name__ == "__main__":
    unittest.main()
