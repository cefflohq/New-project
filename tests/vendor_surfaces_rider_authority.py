"""Vendor surfaces never manufacture Rider-owned delivery lifecycle truth.

Carries the S4-09-REMEDIATION-05 invariants over to the current Vendor
surfaces (Vendor Web `apps/vendor_web`, Vendor App `apps/vendor_mobile`)
after the legacy `vendor/` page was retired on 2026-10-04: no Vendor client
calls the Rider completion/transition contracts or passes a service-role or
spoofed Rider identity, and the database contract stays Rider-authorised.
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIFECYCLE_SQL = (ROOT / "supabase" / "migrations" / "202608290004_s4_07_batch_3a_rider_multi_business_context.sql").read_text(encoding="utf-8")


def sources(folder, pattern):
    return {path: path.read_text(encoding="utf-8") for path in (ROOT / folder).rglob(pattern)}


VENDOR_SOURCES = {**sources("apps/vendor_web/js", "*.js"), **sources("apps/vendor_mobile/lib", "*.dart")}


class VendorSurfacesRiderAuthorityTests(unittest.TestCase):
    def test_sources_found(self):
        self.assertTrue(any(p.suffix == ".js" for p in VENDOR_SOURCES))
        self.assertTrue(any(p.suffix == ".dart" for p in VENDOR_SOURCES))

    def test_no_vendor_surface_calls_rider_completion_or_transition(self):
        call = re.compile(r"""rpc\(\s*['"](complete_delivery|rider_transition)['"]""")
        offenders = [str(p.relative_to(ROOT)) for p, s in VENDOR_SOURCES.items() if call.search(s)]
        self.assertEqual(offenders, [])

    def test_no_vendor_surface_uses_service_role_or_spoofed_rider_identity(self):
        offenders = [
            str(p.relative_to(ROOT))
            for p, s in VENDOR_SOURCES.items()
            if "service_role" in s or "p_rider_id: current_rider_id" in s
        ]
        self.assertEqual(offenders, [])

    def test_completion_contract_remains_rider_authorized(self):
        self.assertIn("create function public.complete_delivery(p_rider_id uuid", LIFECYCLE_SQL)
        self.assertIn("if not is_current_rider(p_rider_id)", LIFECYCLE_SQL)
        self.assertIn("o.assigned_rider_id is distinct from p_rider_id", LIFECYCLE_SQL)
        self.assertIn("'arrival and POD required'", LIFECYCLE_SQL)


if __name__ == "__main__":
    unittest.main()
