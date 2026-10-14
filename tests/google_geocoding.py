"""Phase 1 (Auto Zone + Google Maps master guideline §B3): the Google
Geocoding classifier, request URL and provider choice in
supabase/functions/geocode-order/index.ts, run with plain Node (Deno is not
available here). A live request needs CEFFLO_GOOGLE_MAPS_SERVER_KEY on
staging and is not claimed here."""

import json
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / "supabase" / "functions" / "geocode-order" / "index.ts").read_text(encoding="utf-8")
PURE = SOURCE[SOURCE.index("const MAPBOX_GEOCODE_URL"):SOURCE.index("// ====", SOURCE.index("function safeError("))]


def run(expr):
    proc = subprocess.run(["node", "-e", PURE + "\nconsole.log(JSON.stringify(" + expr + "))"],
                          capture_output=True, text=True, timeout=10)
    assert proc.returncode == 0, proc.stderr
    return json.loads(proc.stdout)


def body(location_type="ROOFTOP", partial=False, status="OK", place_id="ChIJ1"):
    r = {"geometry": {"location": {"lat": 3.15, "lng": 101.7}, "location_type": location_type}, "place_id": place_id}
    if partial:
        r["partial_match"] = True
    return json.dumps({"status": status, "results": [r]})


class GoogleClassifierTests(unittest.TestCase):
    def test_rooftop_resolved_with_place_id(self):
        self.assertEqual(run(f"classifyGoogleResult(200, {body()})"),
                         {"status": "resolved", "latitude": 3.15, "longitude": 101.7, "placeId": "ChIJ1", "reason": None})

    def test_range_interpolated_resolved(self):
        self.assertEqual(run(f"classifyGoogleResult(200, {body('RANGE_INTERPOLATED')}).status"), "resolved")

    def test_approximate_is_ambiguous_keeps_place_id(self):
        self.assertEqual(run(f"classifyGoogleResult(200, {body('APPROXIMATE')})"),
                         {"status": "ambiguous", "reason": "low_precision_approximate", "placeId": "ChIJ1"})

    def test_geometric_center_is_ambiguous(self):
        self.assertEqual(run(f"classifyGoogleResult(200, {body('GEOMETRIC_CENTER')}).status"), "ambiguous")

    def test_partial_match_is_ambiguous_even_if_rooftop(self):
        self.assertEqual(run(f"classifyGoogleResult(200, {body(partial=True)}).reason"), "partial_match")

    def test_api_statuses(self):
        cases = {"ZERO_RESULTS": "no_result", "REQUEST_DENIED": "invalid_credentials",
                 "OVER_QUERY_LIMIT": "rate_limited", "OVER_DAILY_LIMIT": "rate_limited",
                 "INVALID_REQUEST": "invalid_request", "UNKNOWN_ERROR": "provider_unavailable",
                 "WEIRD": "malformed_provider_response"}
        for api, reason in cases.items():
            self.assertEqual(run(f"classifyGoogleResult(200, {{status: '{api}'}})"),
                             {"status": "failed", "reason": reason}, api)

    def test_http_errors(self):
        self.assertEqual(run("classifyGoogleResult(429, null).reason"), "rate_limited")
        self.assertEqual(run("classifyGoogleResult(503, null).reason"), "provider_unavailable")
        self.assertEqual(run("classifyGoogleResult(404, null).reason"), "unexpected_status_404")

    def test_ok_without_results_or_location(self):
        self.assertEqual(run("classifyGoogleResult(200, {status: 'OK', results: []}).reason"), "no_result")
        self.assertEqual(run("classifyGoogleResult(200, {status: 'OK', results: [{geometry: {}}]}).reason"),
                         "malformed_provider_response")


class GoogleRequestTests(unittest.TestCase):
    def test_url_restricted_to_business_country(self):
        q = run("Object.fromEntries(new URL(buildGoogleRequestUrl('12 Jalan Test & Co', 'KEY', 'sg')).searchParams)")
        self.assertEqual(q, {"address": "12 Jalan Test & Co", "region": "sg", "components": "country:SG", "key": "KEY"})

    def test_bad_country_falls_back_to_malaysia(self):
        self.assertEqual(run("new URL(buildGoogleRequestUrl('x y z', 'K', null)).searchParams.get('components')"), "country:MY")

    def test_provider_choice(self):
        self.assertEqual(run("[pickProvider('g', 'm'), pickProvider('', 'm'), pickProvider('', '')]"),
                         ["google", "mapbox_permanent", None])


class StructureTests(unittest.TestCase):
    def test_server_key_is_env_only(self):
        self.assertIn("Deno.env.get('CEFFLO_GOOGLE_MAPS_SERVER_KEY')", SOURCE)
        self.assertNotRegex(SOURCE, r"AIza[0-9A-Za-z_-]{20,}")

    def test_place_id_is_stored(self):
        self.assertIn("p_place_id: result.placeId", SOURCE)

    def test_integration_orders_are_geocoded(self):
        inbound = (ROOT / "supabase" / "functions" / "integrations-inbound" / "index.ts").read_text(encoding="utf-8")
        self.assertIn("/functions/v1/geocode-order", inbound)

    def test_imports_queue_pending_geocode(self):
        web = (ROOT / "apps" / "vendor_web" / "js" / "pages" / "order_actions.js").read_text(encoding="utf-8")
        app = (ROOT / "apps" / "vendor_mobile" / "lib" / "data" / "vendor_repository.dart").read_text(encoding="utf-8")
        self.assertIn("pending: true", web)
        self.assertIn("'pending': true", app)


if __name__ == "__main__":
    unittest.main()
