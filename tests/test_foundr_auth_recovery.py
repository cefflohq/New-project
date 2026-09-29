"""Runs the FOUNDR password-recovery contract (tests/foundr_auth_recovery.test.mjs).

Recovery links must return to the current deployed FOUNDR, never a hard-coded
host or localhost; the recovery session must be recognised and used to set the
new password, and the platform-admin gate still runs afterwards.
"""
import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("node"), "node is required")
class FoundrAuthRecovery(unittest.TestCase):
    def test_recovery_contract(self):
        result = subprocess.run(
            ["node", "--test", str(ROOT / "tests" / "foundr_auth_recovery.test.mjs")],
            cwd=ROOT, capture_output=True, text=True, timeout=120,
        )
        self.assertEqual(result.returncode, 0, result.stdout[-4000:] + result.stderr[-2000:])


if __name__ == "__main__":
    unittest.main()
