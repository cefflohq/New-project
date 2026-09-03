"""Bounded static acceptance for S4-09-REMEDIATION-03.

Vendor Settings Change Password must reauthenticate the current Supabase Auth
identity, update only that authenticated user's password, and never preserve
plaintext password state in browser storage or business data.
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VENDOR_HTML = (ROOT / "vendor" / "index.html").read_text(encoding="utf-8")
VENDOR_JS = (ROOT / "vendor" / "backend.js").read_text(encoding="utf-8")


def block(source, start_pattern, end_marker="\n}"):
    match = re.search(start_pattern, source)
    assert match, f"pattern not found: {start_pattern}"
    start = match.start()
    end = source.index(end_marker, start) + len(end_marker)
    return source[start:end]


class ChangePasswordReachabilityAndValidationTests(unittest.TestCase):
    def test_settings_entry_form_and_action_remain_reachable(self):
        self.assertIn("nav:'changePassword'", VENDOR_HTML)
        self.assertIn("function pageChangePassword(){", VENDOR_HTML)
        self.assertIn('id="pw_current" type="password"', VENDOR_HTML)
        self.assertIn('id="pw_new" type="password"', VENDOR_HTML)
        self.assertIn('id="pw_confirm" type="password"', VENDOR_HTML)
        self.assertIn('data-action="savePasswordChange"', VENDOR_HTML)

    def test_password_policy_and_confirmation_remain(self):
        fn = block(VENDOR_HTML, r"async function savePasswordChange\(el\)\{")
        self.assertIn("PASSWORD_RULE.test(newPw)", fn)
        self.assertIn("newPw!==confirmPw", fn)
        self.assertIn("passwordMismatch", fn)


class AuthenticatedPasswordUpdateTests(unittest.TestCase):
    def test_current_password_is_genuinely_reauthenticated(self):
        save = block(VENDOR_HTML, r"async function savePasswordChange\(el\)\{")
        self.assertIn("await reauthenticateCurrentUser(current)", save)
        reauth = block(VENDOR_HTML, r"async function reauthenticateCurrentUser\(currentPassword\)\{")
        self.assertIn("productionState.authSession", reauth)
        self.assertIn("existingUser.email", reauth)
        self.assertIn("password:currentPassword", reauth)
        self.assertIn("verifiedSession?.user?.id!==existingUser.id", reauth)

    def test_real_auth_update_uses_current_session_bearer(self):
        fn = block(VENDOR_HTML, r"async function updateAuthenticatedPassword\(newPassword\)\{")
        self.assertIn("productionState.authSession?.access_token", fn)
        self.assertIn("/auth/v1/user", fn)
        self.assertIn("method:'PUT'", fn)
        self.assertIn("Authorization:`Bearer ${token}`", fn)
        self.assertIn("JSON.stringify({password:newPassword})", fn)

    def test_success_occurs_only_after_reauth_and_auth_update(self):
        fn = block(VENDOR_HTML, r"async function savePasswordChange\(el\)\{")
        reauth = fn.index("await reauthenticateCurrentUser(current)")
        update = fn.index("await updateAuthenticatedPassword(newPw)")
        success = fn.index("toast(t('passwordUpdated'),'success')")
        self.assertLess(reauth, update)
        self.assertLess(update, success)

    def test_auth_failure_cannot_produce_success(self):
        fn = block(VENDOR_HTML, r"async function savePasswordChange\(el\)\{")
        catch = fn[fn.index("catch(error)"):]
        self.assertNotIn("passwordUpdated", catch)
        self.assertNotIn("'success'", catch)
        self.assertIn("'error'", catch)
        update = block(VENDOR_HTML, r"async function updateAuthenticatedPassword\(newPassword\)\{")
        self.assertIn("if(!response.ok) throw", update)

    def test_session_remains_real_and_current_user_is_preserved(self):
        fn = block(VENDOR_HTML, r"async function updateAuthenticatedPassword\(newPassword\)\{")
        self.assertIn("user.id!==currentUserId", fn)
        self.assertIn("storeAuthSession(productionState.authSession)", fn)
        self.assertNotIn("productionSignOut", fn)


class PasswordStorageAndExposureTests(unittest.TestCase):
    def test_legacy_local_password_truth_is_removed(self):
        self.assertNotIn("state.localPassword", VENDOR_HTML)
        self.assertNotIn('localPassword: "Cefflo123!"', VENDOR_HTML)
        self.assertNotIn("localStorage.setItem('cefflo_password'", VENDOR_HTML)
        self.assertNotIn("localStorage.getItem('cefflo_password'", VENDOR_HTML)
        self.assertIn("localStorage.removeItem('cefflo_password')", VENDOR_HTML)

    def test_password_is_not_written_to_session_storage(self):
        self.assertIsNone(re.search(r"sessionStorage\.setItem\([^\n]*password", VENDOR_HTML, re.I))

    def test_password_is_not_logged(self):
        self.assertIsNone(re.search(r"console\.(?:log|info|warn|error)\([^\n]*password", VENDOR_HTML, re.I))
        self.assertIsNone(re.search(r"console\.(?:log|info|warn|error)\([^\n]*password", VENDOR_JS, re.I))

    def test_no_service_role_or_custom_password_backend(self):
        changed_paths = block(VENDOR_HTML, r"async function reauthenticateCurrentUser\(currentPassword\)\{") + block(
            VENDOR_HTML, r"async function updateAuthenticatedPassword\(newPassword\)\{"
        )
        self.assertNotIn("service_role", changed_paths.lower())
        self.assertNotIn("api.rpc(", changed_paths)
        self.assertNotIn("/rest/v1/", changed_paths)

    def test_sensitive_inputs_never_enter_business_or_order_data(self):
        fn = block(VENDOR_HTML, r"async function savePasswordChange\(el\)\{")
        for forbidden in ("state.", "businessId", "state.orders", "BackendRepository", "appendAuditLog"):
            self.assertNotIn(forbidden, fn)


class AuthAndRemediationRegressionTests(unittest.TestCase):
    def test_login_restore_logout_and_recovery_remain_structurally_intact(self):
        for marker in (
            "async function signInWithPassword", "function restoreAuthSession()",
            "async function productionSignOut()", "async function submitPasswordReset",
            "async function submitNewPassword", "async function restoreProductionAuth()",
        ):
            self.assertIn(marker, VENDOR_HTML)

    def test_s4_08_vendor_issue_path_remains_authoritative(self):
        self.assertIn("api.rpc('vendor_report_delivery_issue'", VENDOR_JS)
        self.assertIn("ACTIONS.confirmReportDeliveryIssue = async function", VENDOR_JS)

    def test_s4_09_01_gates_remain(self):
        # Grow V1 Flow 2 (A6): reschedule/recovery is now genuinely wired
        # to initiate_delivery_recovery (backend.js), not a stub -- verify
        # the real RPC wiring instead of the old disconnected-stub text.
        self.assertIn("api.rpc('initiate_delivery_recovery'", VENDOR_JS)
        self.assertIn("Starting delivery for a rider is not connected in Vendor yet.", VENDOR_HTML)

    def test_s4_09_02_csv_gate_remains(self):
        csv = block(VENDOR_HTML, r"function confirmCsvImport\(\)\{")
        self.assertIn("CSV import is not connected yet.", csv)
        self.assertNotIn("state.orders", csv)


if __name__ == "__main__":
    unittest.main()
