"""Static acceptance for S4-07 frontend wiring: Vendor Team screen, role
hydration, the real Rider invite path bypassing the deprecated mock engine,
and the new shared invite surface. Matches the established static/
structural precedent (e.g. s4_06_7_batch_1_frontend_wiring.py) -- not a
substitute for real browser click-through, which this project has
consistently deferred to S4-15 for every prior UI batch.
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VENDOR_HTML = (ROOT / "vendor" / "index.html").read_text(encoding="utf-8")
VENDOR_JS = (ROOT / "vendor" / "backend.js").read_text(encoding="utf-8")
INVITE_HTML = (ROOT / "invite" / "index.html").read_text(encoding="utf-8")
INVITE_JS = (ROOT / "invite" / "backend.js").read_text(encoding="utf-8")
BUILD_SCRIPT = (ROOT / "scripts" / "build-static.mjs").read_text(encoding="utf-8")


def block(source, start_pattern, end_marker="\n}"):
    match = re.search(start_pattern, source)
    assert match, f"pattern not found: {start_pattern}"
    start = match.start()
    end = source.index(end_marker, start) + len(end_marker)
    return source[start:end]


class RoleHydrationTests(unittest.TestCase):
    def test_member_role_captured_in_canonical_hydrate(self):
        fn = block(VENDOR_JS, r"async function hydrateCanonicalWorkspace\(\) \{")
        self.assertIn("state.currentMemberRole = selected.member_role", fn)

    def test_team_screen_gates_owner_only_controls_on_real_role(self):
        fn = block(VENDOR_HTML, r"function pageTeam\(\)\{")
        self.assertIn("state.currentMemberRole==='owner'", fn)
        self.assertIn("isOwner?", fn)

    def test_backend_remains_authoritative_owner_only_rpcs_unchanged(self):
        # The client-side gate is cosmetic; every Owner-only RPC re-checks
        # is_business_owner server-side regardless of what the UI shows.
        migration = (ROOT / "supabase" / "migrations" / "202608290002_s4_07_batch_1_team_invitation.sql").read_text(encoding="utf-8")
        self.assertIn("is_business_owner(p_business_id)", migration)


class MockRiderInviteRemovedTests(unittest.TestCase):
    def test_no_live_entry_point_reaches_the_mock_engine(self):
        for forbidden in ("action='openInviteRider'", 'action="openInviteRider"', 'data-action="openInviteRider">'):
            self.assertNotIn(forbidden, VENDOR_HTML)

    def test_real_invite_rider_entry_points_wired(self):
        self.assertIn("action:'openInviteRiderReal'", VENDOR_HTML)
        self.assertIn('data-action="openInviteRiderReal"', VENDOR_HTML)

    def test_real_invite_rider_calls_real_rpc_not_the_mock_engine(self):
        fn = block(VENDOR_JS, r"ACTIONS\.confirmInviteRiderReal = async function \(\) \{")
        self.assertIn("createRiderInvitation(", fn)
        self.assertNotIn("CEFFLO_ENGINE", fn)


class UpdateTeamMemberWiringTests(unittest.TestCase):
    def test_update_team_member_wired_to_real_ui(self):
        fn = block(VENDOR_JS, r"ACTIONS\.confirmManageTeamMember = async function \(el\) \{")
        self.assertIn("updateTeamMember(", fn)
        self.assertIn('data-action="openManageTeamMember"', VENDOR_HTML)
        self.assertIn('data-action="confirmManageTeamMember"', VENDOR_HTML)


class InviteLinkOneTimeDisplayTests(unittest.TestCase):
    def test_team_invite_link_built_only_from_creation_response(self):
        fn = block(VENDOR_JS, r"ACTIONS\.confirmInviteTeamMember = async function \(\) \{")
        self.assertIn("result.token", fn)
        self.assertIn("renderInviteLinkSheet", fn)

    def test_rider_invite_link_built_only_from_creation_response(self):
        fn = block(VENDOR_JS, r"ACTIONS\.confirmInviteRiderReal = async function \(\) \{")
        self.assertIn("result.token", fn)

    def test_invitation_list_reads_never_select_token_hash(self):
        for select_clause in re.findall(r"select=([a-z_,]+)", VENDOR_JS):
            self.assertNotIn("token_hash", select_clause)


class SharedInvitePageTests(unittest.TestCase):
    def test_no_marketplace_or_out_of_scope_elements(self):
        combined = INVITE_HTML + INVITE_JS
        for forbidden in ("Helper Pool", "Staff Workspace", "Direct Fill", "browse", "marketplace", "shift"):
            self.assertNotIn(forbidden.lower(), combined.lower())

    def test_no_mock_otp(self):
        combined = INVITE_HTML + INVITE_JS
        for forbidden in ("123456", "sendOtpMock", "verifyOtpMock"):
            self.assertNotIn(forbidden, combined)

    def test_real_signup_call_used(self):
        self.assertIn("/auth/v1/signup", INVITE_JS)

    def test_pending_token_cleared_on_terminal_success(self):
        fn = block(INVITE_JS, r"async function accept\(\) \{", "\n    }\n")
        self.assertIn("clearPending()", fn)

    def test_pending_token_cleared_on_terminal_invalid_resolve(self):
        # Team (staff) flow: a terminal resolve (invalid/expired/revoked/used)
        # clears any stashed token.
        fn = block(INVITE_JS, r"function teamFlow\(\) \{", "\n  }\n")
        resolve = fn[fn.index("rpc('resolve_team_invitation'"):]
        self.assertIn("clearPending(); return;", resolve[:resolve.index("$('summaryBusiness')")])

    def test_pending_token_not_cleared_while_awaiting_email_confirmation(self):
        # Team flow signup awaiting email confirmation stashes the token and
        # does not clear it in that branch (only terminal paths clear it).
        fn = block(INVITE_JS, r"function teamFlow\(\) \{", "\n  }\n")
        signup = fn[fn.index("$('signupBtn').addEventListener"):]
        waiting = signup[signup.index("else {"):signup.index("setStatus('Account created.")]
        self.assertIn("localStorage.setItem(PENDING_KEY", waiting)
        self.assertNotIn("clearPending", waiting)

    def test_rider_flow_has_no_login_or_signup(self):
        # D-72: the rider decision needs no account; the Driver app claims it.
        fn = block(INVITE_JS, r"function riderFlow\(\) \{", "\n  }\n")
        for forbidden in ("/auth/v1/signup", "api.login", "accept_rider_invitation"):
            self.assertNotIn(forbidden, fn)
        self.assertIn("consent_rider_invitation", fn)
        self.assertIn("decline_rider_invitation", fn)

    def test_raw_token_never_sent_to_a_non_invite_rpc(self):
        # Only invitation RPCs may receive the raw token.
        calls = re.findall(r"api\.rpc\(([^,]+),\s*\{\s*p_token:\s*(?:token|teamToken)", INVITE_JS)
        self.assertTrue(calls)
        allowed = ("resolve_", "accept_", "consent_", "decline_")
        for expr in calls:
            names = re.findall(r"'([a-z_]+_invitation)'", expr)
            self.assertTrue(names, expr)
            for name in names:
                self.assertTrue(name.startswith(allowed), name)


class BuildScriptTests(unittest.TestCase):
    def test_invite_surface_included_in_static_build(self):
        # The build publishes the explicit canonical list (D-62); invitation
        # stays in it as a temporary supporting route.
        self.assertIn("Object.keys(CANONICAL_SURFACES)", BUILD_SCRIPT)
        surfaces = (ROOT / "scripts" / "canonical-surfaces.mjs").read_text(encoding="utf-8")
        self.assertIn("  invite: ", surfaces)


if __name__ == "__main__":
    unittest.main()
