"""Canonical CEFFLO UI baseline guard (D-62).

Canonical UI products: Vendor (Mobile + Web/Desktop), Driver (Flutter Mobile),
Customer Tracking (PWA), Founder (Web/PWA). Public Website: NOT IMPLEMENTED.
Invitation is a temporary supporting route, not a product.

These checks stop a removed UI from quietly returning to the active baseline,
the static build output, or host routing.
"""

import json
import os
import re
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REMOVED_DIRS = ("rider", "marketing", "previews", "storefront")
WELCOME_MARKERS = (
    'id="welcome"',
    "welcome-hero-photo",
    "welcome-actions",
    "showAuthWelcome",
    "switchScreen('welcome')",
    "pressWelcomeButton",
    "welcomeButtonPress",
)


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


class CanonicalSurfaceTests(unittest.TestCase):
    def test_canonical_product_entry_points_exist(self):
        for rel in (
            "apps/vendor_mobile/pubspec.yaml",
            "vendor/index.html",
            "apps/rider_mobile/pubspec.yaml",
            "customer/index.html",
            "customer/app.js",
            "foundr/index.html",
            "foundr/app.js",
            "invite/index.html",
            "invite/backend.js",
        ):
            self.assertTrue((ROOT / rel).is_file(), rel)

    def test_removed_ui_is_absent_from_the_active_baseline(self):
        for name in REMOVED_DIRS:
            self.assertFalse((ROOT / name).exists(), f"{name}/ must not return")

    def test_build_copies_only_the_explicit_canonical_list(self):
        build = read("scripts/build-static.mjs")
        self.assertIn("Object.keys(CANONICAL_SURFACES)", build)
        self.assertNotRegex(build, r"\[\s*'vendor'")
        surfaces = read("scripts/canonical-surfaces.mjs")
        listed = re.findall(r"^\s+(\w+): '", surfaces.split("FORBIDDEN_OUTPUT_DIRS")[0], re.M)
        self.assertEqual(sorted(listed), sorted(["vendor", "customer", "foundr", "invite", "retired", "shared"]))
        self.assertNotIn("marketing", read("scripts/build-static.mjs").split("FORBIDDEN")[0].replace("marketing site", ""))


class RoutingTests(unittest.TestCase):
    def setUp(self):
        self.rewrites = json.loads(read("vercel.json"))["rewrites"]

    def _host(self, rule):
        return (rule.get("has") or [{}])[0].get("value")

    def test_no_route_serves_a_removed_ui(self):
        for rule in self.rewrites:
            for name in REMOVED_DIRS:
                self.assertFalse(rule["destination"].startswith(f"/{name}/"), rule)

    def test_public_website_host_has_no_product_ui(self):
        self.assertFalse([r for r in self.rewrites if self._host(r) == "www.cefflo.com"])

    def test_retired_rider_host_only_serves_the_retirement_worker(self):
        rider = [r for r in self.rewrites if self._host(r) == "rider.cefflo.com"]
        self.assertTrue(rider)
        self.assertTrue(all(r["destination"].startswith("/retired/") for r in rider))
        self.assertIn({"/sw.js": "/retired/sw.js"}, [{r["source"]: r["destination"]} for r in rider])

    def test_invitation_host_reaches_the_supporting_route(self):
        invite = [r for r in self.rewrites if self._host(r) == "invite.cefflo.com"]
        self.assertEqual([r["destination"] for r in invite], ["/invite/:path*"])


class VendorWebAuthEntryTests(unittest.TestCase):
    def test_obsolete_welcome_presentation_cannot_return(self):
        html = read("vendor/index.html")
        for marker in WELCOME_MARKERS:
            self.assertNotIn(marker, html)
        self.assertNotIn("data:image/jpeg", html)

    def test_unauthenticated_startup_is_the_login_entry(self):
        html = read("vendor/index.html")
        self.assertIn('<div class="screen" id="emailLogin">', html)
        entry = html.split("function showAuthEntry(){", 1)[1].split("}", 1)[0]
        self.assertIn("switchScreen('emailLogin')", entry)
        self.assertIn("if(!restored){showAuthEntry();", html)
        self.assertIn("switchScreen('language')", html.split('id="emailLogin"', 1)[1][:600])

    def test_vendor_shell_cache_was_rotated(self):
        self.assertNotIn("cefflo-vendor-shell-v1'", read("vendor/sw.js"))


class ServiceWorkerRetirementTests(unittest.TestCase):
    def test_retirement_worker_clears_caches_and_unregisters(self):
        sw = read("retired/sw.js")
        self.assertIn("caches.delete", sw)
        self.assertIn("registration.unregister()", sw)
        self.assertIn("skipWaiting", sw)


class SharedClientContractTests(unittest.TestCase):
    # Migrated from the removed static-Rider test suite: the shared client
    # contract is still the canonical POD storage path.
    def test_upload_pod_path_is_rider_then_order(self):
        client = read("shared/client.js")
        fn = client.split("async function uploadPod(riderId, orderId, file) {", 1)[1][:400]
        self.assertIn("`${riderId}/${orderId}/", fn)


class BuildOutputTests(unittest.TestCase):
    def test_static_build_publishes_only_canonical_surfaces(self):
        env = {
            "PATH": os.environ.get("PATH", ""),
            "CEFFLO_ENVIRONMENT": "local",
            "CEFFLO_SUPABASE_PROJECT_REF": "local",
            "SUPABASE_URL": "http://127.0.0.1:54321",
            "SUPABASE_PUBLISHABLE_KEY": "local-test-publishable-key",
        }
        subprocess.run(["node", "scripts/build-static.mjs"], cwd=ROOT, env=env, check=True, capture_output=True)
        dist = ROOT / "dist"
        published = sorted(p.name for p in dist.iterdir())
        self.assertEqual(published, sorted([".openai", "customer", "foundr", "index.html", "invite", "retired", "server", "shared", "vendor"]))
        self.assertNotIn("marketing", (dist / "index.html").read_text(encoding="utf-8"))
        vendor = (dist / "vendor" / "index.html").read_text(encoding="utf-8")
        for marker in WELCOME_MARKERS:
            self.assertNotIn(marker, vendor)


if __name__ == "__main__":
    unittest.main()
