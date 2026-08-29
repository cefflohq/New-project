"""S4-04 Batch-4 tracking-pod Edge Function hardening acceptance.

Two layers, both real, neither substituting for the other:

1. A genuine Node.js functional test of the CORS-matching algorithm,
   extracted verbatim from the actual Deno source (see
   `_extract_pure_cors_logic`) and executed with real inputs -- this is
   actually running the real allow/deny logic, not just pattern-matching it.
2. Static structural checks on the full source confirming no raw error
   leakage, no wildcard CORS, and that the B02/B03 contract (pod_available,
   internal_tracking_pod_path, signed URL, service-role client) is preserved
   unmodified.

Deno itself is not available in this environment, so the full Deno.serve
HTTP dispatch (real OPTIONS/POST requests, real signed-URL issuance) is NOT
executed here -- see the checkpoint entry for exactly what still requires
staging/Deno runtime verification.
"""

import json
import re
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_PATH = ROOT / "supabase" / "functions" / "tracking-pod" / "index.ts"


def _extract_pure_cors_logic(source: str) -> str:
    start = source.index("const DEFAULT_ALLOWED_ORIGINS")
    end = source.index("function safeError")
    return source[start:end]


class TrackingPodCorsFunctionalTests(unittest.TestCase):
    """Executes the real CORS logic (extracted verbatim) with Node."""

    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE_PATH.read_text(encoding="utf-8")
        cls.pure_logic = _extract_pure_cors_logic(cls.source)

    def _run_node(self, scenario_js: str):
        script = (
            self.pure_logic
            + "\n"
            + scenario_js
            + "\nconsole.log(JSON.stringify(__RESULT__));\n"
        )
        proc = subprocess.run(
            ["node", "-e", script],
            capture_output=True,
            text=True,
            timeout=10,
        )
        self.assertEqual(proc.returncode, 0, proc.stderr)
        return json.loads(proc.stdout.strip().splitlines()[-1])

    def test_default_staging_origin_allowed(self):
        result = self._run_node(
            "const allowed = resolveAllowedOrigins('');"
            "const headers = buildCorsHeaders('https://new-project-git-staging-cefflohq26-6353s-projects.vercel.app', allowed);"
            "var __RESULT__ = headers;"
        )
        self.assertEqual(
            result.get("Access-Control-Allow-Origin"),
            "https://new-project-git-staging-cefflohq26-6353s-projects.vercel.app",
        )
        self.assertEqual(result.get("Vary"), "Origin")
        self.assertIn("Access-Control-Allow-Methods", result)

    def test_disallowed_origin_gets_no_permissive_header(self):
        result = self._run_node(
            "const allowed = resolveAllowedOrigins('');"
            "const headers = buildCorsHeaders('https://evil.example.com', allowed);"
            "var __RESULT__ = headers;"
        )
        self.assertNotIn("Access-Control-Allow-Origin", result)
        self.assertNotIn("Access-Control-Allow-Methods", result)
        self.assertEqual(result.get("Vary"), "Origin")

    def test_no_origin_header_gets_no_permissive_header(self):
        result = self._run_node(
            "const allowed = resolveAllowedOrigins('');"
            "const headers = buildCorsHeaders(null, allowed);"
            "var __RESULT__ = headers;"
        )
        self.assertNotIn("Access-Control-Allow-Origin", result)

    def test_env_configured_origin_list_overrides_default_and_is_isolated(self):
        result = self._run_node(
            "const allowed = resolveAllowedOrigins('https://track.cefflo.com, https://another.example.com');"
            "var __RESULT__ = {"
            "  configured: allowed,"
            "  trackAllowed: isOriginAllowed('https://track.cefflo.com', allowed),"
            "  stagingStillAllowedByAccident: isOriginAllowed('https://new-project-git-staging-cefflohq26-6353s-projects.vercel.app', allowed)"
            "};"
        )
        self.assertIn("https://track.cefflo.com", result["configured"])
        self.assertIn("https://another.example.com", result["configured"])
        self.assertTrue(result["trackAllowed"])
        self.assertFalse(
            result["stagingStillAllowedByAccident"],
            "an explicit env-configured allowlist must fully replace the default, not merge with it",
        )

    def test_empty_string_origin_never_matches(self):
        result = self._run_node(
            "const allowed = resolveAllowedOrigins('');"
            "var __RESULT__ = isOriginAllowed('', allowed);"
        )
        self.assertFalse(result)

    def test_wildcard_is_never_treated_as_allow_all(self):
        # A misconfigured env value of '*' must not be interpreted as
        # allow-any-origin; it should just be a literal (non-matching) entry.
        result = self._run_node(
            "const allowed = resolveAllowedOrigins('*');"
            "var __RESULT__ = isOriginAllowed('https://random-site.example.com', allowed);"
        )
        self.assertFalse(result)


class TrackingPodStructuralTests(unittest.TestCase):
    """Static checks on the full source for leakage and B02/B03 preservation."""

    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE_PATH.read_text(encoding="utf-8")

    def test_no_wildcard_cors_anywhere(self):
        self.assertNotIn("'*'", re.sub(r"//.*", "", self.source).replace('"*"', "'*'"))

    def test_no_raw_error_message_forwarded_to_client(self):
        # error.message (or any exception's .message) must never be placed
        # directly into a client-facing Response.json body. Strip comments
        # first so explanatory text (which itself discusses error.message)
        # doesn't produce a false positive.
        code_only = re.sub(r"//.*", "", self.source)
        self.assertNotIn("error.message", code_only)
        self.assertNotIn("signError.message", code_only)

    def test_fixed_public_safe_error_messages_only(self):
        for message in ("Invalid request", "POD unavailable", "Unexpected error"):
            self.assertIn(message, self.source)

    def test_server_side_logging_present_for_debuggability(self):
        self.assertIn("console.error(", self.source)

    def test_b02_contract_preserved(self):
        self.assertIn("tracking.pod_available", self.source)
        self.assertIn("internal_tracking_pod_path", self.source)
        # The raw JSON key from before B02 ('pod_path' as a public field) must
        # not reappear; the local variable name `podPath` is fine.
        self.assertNotIn("'pod_path'", self.source)
        self.assertNotIn('"pod_path"', self.source)

    def test_b03_lifecycle_untouched(self):
        # No token-lifecycle logic (expiry/revocation) is duplicated or
        # reimplemented here -- it must remain entirely inside public_tracking.
        for forbidden in ("expires_at", "revoked_at", "rotate_tracking_token", "revoke_tracking_token"):
            self.assertNotIn(forbidden, self.source)

    def test_service_role_client_and_private_bucket_preserved(self):
        self.assertIn("SUPABASE_SERVICE_ROLE_KEY", self.source)
        self.assertIn("createSignedUrl", self.source)
        self.assertIn("cefflo-pod", self.source)

    def test_no_hardcoded_secrets(self):
        self.assertNotIn("sb_secret_", self.source)
        self.assertNotIn("sb_publishable_", self.source)


if __name__ == "__main__":
    unittest.main()
