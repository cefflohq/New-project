from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
RIDER_HTML = ROOT / "rider" / "index.html"


class RiderLogoutFixTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = RIDER_HTML.read_text(encoding="utf-8")

    def test_do_logout_invokes_canonical_shared_logout(self):
        match = re.search(r"async function doLogout\(\)\{(.*?)\n\}", self.source, re.DOTALL)
        self.assertIsNotNone(match, "doLogout() not found or not converted to async")
        body = match.group(1)
        self.assertIn("await window.CEFFLO.logout()", body)

    def test_do_logout_fails_safely_on_server_error(self):
        match = re.search(r"async function doLogout\(\)\{(.*?)\n\}", self.source, re.DOTALL)
        body = match.group(1)
        self.assertRegex(body, r"try\s*\{\s*await window\.CEFFLO\.logout\(\)\s*;\s*\}\s*catch")

    def test_do_logout_still_clears_local_routing_flag_and_navigates(self):
        match = re.search(r"async function doLogout\(\)\{(.*?)\n\}", self.source, re.DOTALL)
        body = match.group(1)
        self.assertIn("localStorage.removeItem('cefflo_session')", body)
        self.assertIn("showScreen('screen-login')", body)

    def test_no_second_authentication_implementation_introduced(self):
        # The fix must call the existing shared client, not fetch('/auth/v1/logout') directly.
        match = re.search(r"async function doLogout\(\)\{(.*?)\n\}", self.source, re.DOTALL)
        body = match.group(1)
        self.assertNotIn("/auth/v1/logout", body)


if __name__ == "__main__":
    unittest.main()
