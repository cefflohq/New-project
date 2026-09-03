"""S4-04 Batch-5.4 tracking-pod rate-limit acceptance (static + functional).

Same two-layer approach as tests/s4_04_batch_4_edge_hardening.py: a genuine
Node execution of the pure secondsUntilWindowReset() function, plus static
structural checks confirming the rate-limit gate is wired correctly and the
existing B04 CORS/error-normalization contract is untouched. Deno itself is
not available in this environment -- the full Deno.serve HTTP dispatch
(a real 429 response over HTTP, a real RPC round-trip) requires staging
verification, tracked separately in the checkpoint.
"""

import re
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_PATH = ROOT / "supabase" / "functions" / "tracking-pod" / "index.ts"


class SecondsUntilWindowResetFunctionalTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE_PATH.read_text(encoding="utf-8")
        start = cls.source.index("function secondsUntilWindowReset")
        end = cls.source.index("async function sha256Hex")
        cls.pure_logic = cls.source[start:end]

    def _run_node(self, fixed_epoch_ms, window_seconds):
        script = (
            f"Date.now = () => {fixed_epoch_ms};\n"
            + self.pure_logic
            + f"\nconsole.log(JSON.stringify(secondsUntilWindowReset({window_seconds})));\n"
        )
        proc = subprocess.run(["node", "-e", script], capture_output=True, text=True, timeout=10)
        self.assertEqual(proc.returncode, 0, proc.stderr)
        return int(proc.stdout.strip())

    def test_reset_at_start_of_window(self):
        # epoch exactly on a 60s boundary -> a full window remains
        result = self._run_node(fixed_epoch_ms=60_000 * 1000, window_seconds=60)
        self.assertEqual(result, 60)

    def test_reset_partway_through_window(self):
        # 25s into a 60s window -> 35s remain
        result = self._run_node(fixed_epoch_ms=(60_000 + 25) * 1000, window_seconds=60)
        self.assertEqual(result, 35)

    def test_reset_never_zero(self):
        # 1ms before the boundary should round up to at least 1, never 0
        result = self._run_node(fixed_epoch_ms=(61_000 * 1000) - 1, window_seconds=60)
        self.assertGreaterEqual(result, 1)


class TrackingPodRateLimitStructuralTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE_PATH.read_text(encoding="utf-8")

    def test_limit_constants_match_founder_approval(self):
        self.assertIn("RATE_LIMIT_WINDOW_SECONDS = 60", self.source)
        self.assertIn("RATE_LIMIT_MAX_REQUESTS = 10", self.source)

    def test_rate_limit_checked_before_public_tracking_rpc(self):
        rate_limit_pos = self.source.index("check_rate_limit")
        public_tracking_pos = self.source.index("admin.rpc('public_tracking'")
        self.assertLess(rate_limit_pos, public_tracking_pos)

    def test_429_response_exact_body_and_retry_after(self):
        self.assertIn("safeError(429, 'Too many requests'", self.source)
        self.assertIn("'Retry-After': retryAfter", self.source)

    def test_rate_limit_uses_own_independent_rpc_call(self):
        # Must be its own admin.rpc call, not folded into public_tracking's
        # own statement (that's exactly what made the DB-internal counter
        # unreliable for submit_rating -- see checkpoint Section 40).
        self.assertIn("admin.rpc('check_rate_limit'", self.source)

    def test_limiter_infra_failure_fails_open(self):
        # allowed starts true and is only ever set to false by an explicit
        # rateLimitOk === false result, never by the error/exception paths.
        code_only = re.sub(r"//.*", "", self.source)
        self.assertIn("let allowed = true;", code_only)
        gate_section = code_only[code_only.index("let allowed = true;"):code_only.index("if (!allowed)")]
        self.assertNotIn("allowed = false", gate_section)
        self.assertIn("rateLimitOk !== false", gate_section)

    def test_token_hashed_before_use_as_rate_limit_key(self):
        self.assertIn("sha256Hex(token)", self.source)

    def test_b04_cors_and_contract_untouched(self):
        for marker in (
            "tracking.pod_available",
            "internal_tracking_pod_path",
            "SUPABASE_SERVICE_ROLE_KEY",
            "createSignedUrl",
            "cefflo-pod",
        ):
            self.assertIn(marker, self.source)
        self.assertNotIn("'*'", re.sub(r"//.*", "", self.source).replace('"*"', "'*'"))


if __name__ == "__main__":
    unittest.main()
