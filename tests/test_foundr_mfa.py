"""Runs the FOUNDR MFA contract (tests/foundr_mfa.test.mjs).

Enrollment, challenge and verify go to GoTrue with the user token; a verified
code replaces the session with the aal2 one; a 403 never signs the admin out.
"""
import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("node"), "node is required")
class FoundrMfa(unittest.TestCase):
    def test_mfa_contract(self):
        result = subprocess.run(
            ["node", "--test", str(ROOT / "tests" / "foundr_mfa.test.mjs")],
            cwd=ROOT, capture_output=True, text=True, timeout=120,
        )
        self.assertEqual(result.returncode, 0, result.stdout[-4000:] + result.stderr[-2000:])


if __name__ == "__main__":
    unittest.main()
