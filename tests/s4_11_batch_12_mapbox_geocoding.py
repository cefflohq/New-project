"""Grow V1 Flow 2 -- Mapbox Permanent Geocoding provider gate acceptance.

Same two-layer approach as tests/s4_04_batch_5_tracking_pod_limit.py: a
genuine Node execution of the pure, Deno-independent classification/
validation/URL-building logic in supabase/functions/geocode-order/index.ts,
plus static structural checks confirming the Permanent (never Temporary)
semantics, the canonical write path, the no-hardcoded-secret requirement,
and that Manual New Order / CSV import both enter the same geocode
pipeline (no parallel import-only geocoding system). Deno itself is not
available in this environment -- the full Deno.serve HTTP dispatch (a real
request against a live Mapbox endpoint) requires a Founder-provided
CEFFLO_MAPBOX_ACCESS_TOKEN and either `supabase functions serve` or
staging, tracked separately, not claimed here.
"""

import re
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FN_PATH = ROOT / "supabase" / "functions" / "geocode-order" / "index.ts"
SOURCE = FN_PATH.read_text(encoding="utf-8")
VENDOR_JS = (ROOT / "vendor" / "backend.js").read_text(encoding="utf-8")
VENDOR_HTML = (ROOT / "vendor" / "index.html").read_text(encoding="utf-8")


def extract_pure_logic():
    start = SOURCE.index("const MAPBOX_GEOCODE_URL")
    end = SOURCE.index("// ====", SOURCE.index("classifyMapboxResult("))
    return SOURCE[start:end]


PURE_LOGIC = extract_pure_logic()


def run_node(expression):
    script = PURE_LOGIC + "\n" + expression
    proc = subprocess.run(["node", "-e", script], capture_output=True, text=True, timeout=10)
    assert proc.returncode == 0, proc.stderr
    return proc.stdout.strip()


class AddressValidationTests(unittest.TestCase):
    def test_empty_address_rejected(self):
        out = run_node("console.log(JSON.stringify(validateAddressInput('   ')))")
        self.assertEqual(out, '{"valid":false,"reason":"empty_address"}')

    def test_too_short_address_rejected(self):
        out = run_node("console.log(JSON.stringify(validateAddressInput('ab')))")
        self.assertEqual(out, '{"valid":false,"reason":"address_too_short"}')

    def test_valid_address_trimmed(self):
        out = run_node("console.log(JSON.stringify(validateAddressInput('  12 Jalan Test  ')))")
        self.assertEqual(out, '{"valid":true,"address":"12 Jalan Test"}')

    def test_null_address_rejected(self):
        out = run_node("console.log(JSON.stringify(validateAddressInput(null)))")
        self.assertEqual(out, '{"valid":false,"reason":"empty_address"}')


class MapboxUrlConstructionTests(unittest.TestCase):
    def test_permanent_flag_always_true(self):
        out = run_node(
            "const u = buildMapboxRequestUrl('12 Jalan Test', 'pk.faketoken');"
            "console.log(new URL(u).searchParams.get('permanent'));"
        )
        self.assertEqual(out, "true")

    def test_address_and_token_encoded(self):
        out = run_node(
            "const u = buildMapboxRequestUrl('12 Jalan Test & Co', 'pk.faketoken');"
            "const p = new URL(u).searchParams;"
            "console.log(JSON.stringify({q: p.get('q'), token: p.get('access_token'), limit: p.get('limit')}));"
        )
        self.assertEqual(out, '{"q":"12 Jalan Test & Co","token":"pk.faketoken","limit":"1"}')

    def test_uses_v6_forward_endpoint_by_default(self):
        out = run_node("console.log(buildMapboxRequestUrl('X', 'Y').split('?')[0]);")
        self.assertEqual(out, "https://api.mapbox.com/search/geocode/v6/forward")


class MapboxResultClassificationTests(unittest.TestCase):
    def test_invalid_credentials_401(self):
        out = run_node("console.log(JSON.stringify(classifyMapboxResult(401, null)))")
        self.assertEqual(out, '{"status":"failed","reason":"invalid_credentials"}')

    def test_invalid_credentials_403(self):
        out = run_node("console.log(JSON.stringify(classifyMapboxResult(403, null)))")
        self.assertEqual(out, '{"status":"failed","reason":"invalid_credentials"}')

    def test_rate_limited_429(self):
        out = run_node("console.log(JSON.stringify(classifyMapboxResult(429, null)))")
        self.assertEqual(out, '{"status":"failed","reason":"rate_limited"}')

    def test_provider_unavailable_5xx(self):
        out = run_node("console.log(JSON.stringify(classifyMapboxResult(503, null)))")
        self.assertEqual(out, '{"status":"failed","reason":"provider_unavailable"}')

    def test_unexpected_status(self):
        out = run_node("console.log(JSON.stringify(classifyMapboxResult(418, null)))")
        self.assertEqual(out, '{"status":"failed","reason":"unexpected_status_418"}')

    def test_no_result_empty_features(self):
        out = run_node("console.log(JSON.stringify(classifyMapboxResult(200, {features: []})))")
        self.assertEqual(out, '{"status":"failed","reason":"no_result"}')

    def test_no_result_missing_features_key(self):
        out = run_node("console.log(JSON.stringify(classifyMapboxResult(200, {})))")
        self.assertEqual(out, '{"status":"failed","reason":"no_result"}')

    def test_malformed_provider_response(self):
        out = run_node(
            "console.log(JSON.stringify(classifyMapboxResult(200, "
            "{features:[{geometry:{coordinates:['not','numbers']}}]})))"
        )
        self.assertEqual(out, '{"status":"failed","reason":"malformed_provider_response"}')

    def test_low_confidence_is_ambiguous_not_resolved(self):
        out = run_node(
            "console.log(JSON.stringify(classifyMapboxResult(200, {features:[{"
            "geometry:{coordinates:[101.6869,3.1390]},"
            "properties:{match_code:{confidence:'low'}}"
            "}]})))"
        )
        self.assertEqual(out, '{"status":"ambiguous","reason":"low_confidence_low"}')

    def test_missing_confidence_is_ambiguous(self):
        out = run_node(
            "console.log(JSON.stringify(classifyMapboxResult(200, {features:[{"
            "geometry:{coordinates:[101.6869,3.1390]}, properties:{}"
            "}]})))"
        )
        self.assertEqual(out, '{"status":"ambiguous","reason":"low_confidence_unknown"}')

    def test_high_confidence_resolved_with_correct_axis_order(self):
        # Mapbox returns [longitude, latitude] -- this must never be swapped.
        out = run_node(
            "console.log(JSON.stringify(classifyMapboxResult(200, {features:[{"
            "geometry:{coordinates:[101.6869,3.1390]},"
            "properties:{match_code:{confidence:'exact'}}"
            "}]})))"
        )
        self.assertEqual(
            out,
            '{"status":"resolved","longitude":101.6869,"latitude":3.139,"reason":null}',
        )

    def test_medium_confidence_accepted(self):
        out = run_node(
            "console.log(JSON.stringify(classifyMapboxResult(200, {features:[{"
            "geometry:{coordinates:[101.6869,3.1390]},"
            "properties:{match_code:{confidence:'medium'}}"
            "}]}).status))"
        )
        self.assertEqual(out, '"resolved"')


class StructuralAndSecrecyTests(unittest.TestCase):
    """Guards the requirements that can only be checked by reading the
    actual source: never hardcode a token, always request permanent
    geocoding, persist only through the existing canonical RPC, and never
    silently invent a resolved location on failure."""

    def test_token_is_env_driven_never_hardcoded(self):
        self.assertIn("Deno.env.get('CEFFLO_MAPBOX_ACCESS_TOKEN')", SOURCE)
        # A real Mapbox public/secret token always starts with "pk." or
        # "sk." -- neither literal prefix may appear anywhere in the
        # committed source.
        self.assertNotRegex(SOURCE, r"['\"](pk|sk)\.[A-Za-z0-9]")

    def test_permanent_true_is_unconditional(self):
        # There must be exactly one place this function sets `permanent`,
        # and it must be the literal string 'true' -- no variable, no
        # conditional, no alternate code path that could omit it.
        occurrences = re.findall(r"searchParams\.set\('permanent',\s*'([^']+)'\)", SOURCE)
        self.assertEqual(occurrences, ["true"])

    def test_persists_only_via_canonical_set_order_location_rpc(self):
        # Every persistence call in this function must go through the one
        # canonical RPC the A1 migration already built -- no direct table
        # write, no second location-writing path.
        self.assertIn("adminClient.rpc('set_order_location'", SOURCE)
        self.assertNotIn(".from('orders').update(", SOURCE)
        self.assertNotIn(".from('orders')\n    .update(", SOURCE)

    def test_geocode_once_guard_present(self):
        self.assertIn("order.location_status === 'resolved'", SOURCE)

    def test_failure_paths_never_mark_resolved(self):
        # Every set_order_location call whose p_status is a variable
        # (result.status / 'failed') must never be literally 'resolved' --
        # only the one explicit success branch may pass p_status: 'resolved'.
        resolved_literal_count = SOURCE.count("p_status: 'resolved'")
        self.assertEqual(resolved_literal_count, 1, "exactly one explicit resolved write expected")

    def test_rate_limit_applied_before_provider_call(self):
        rate_limit_pos = SOURCE.index("check_rate_limit")
        fetch_pos = SOURCE.index("await fetch(mapboxUrl)")
        self.assertLess(rate_limit_pos, fetch_pos)


class FrontendPipelineWiringTests(unittest.TestCase):
    """Manual New Order and CSV/XLSX import must both enter the same
    canonical geocode-order pipeline -- no separate import-only geocoding
    system -- and the manual correction path must remain independently
    reachable regardless of provider outcome."""

    def test_geocode_wrapper_calls_the_edge_function(self):
        self.assertIn("/functions/v1/geocode-order", VENDOR_JS)

    def test_manual_new_order_triggers_geocode(self):
        start = VENDOR_JS.index("wizSubmit = async function")
        end = VENDOR_JS.index("\n  };", start)
        fn = VENDOR_JS[start:end]
        self.assertIn("geocodeOrder(created.order.id)", fn)

    def test_csv_import_triggers_geocode_for_committed_rows_only(self):
        start = VENDOR_JS.index("confirmCsvImport = async function")
        end = VENDOR_JS.index("\n  };", start)
        fn = VENDOR_JS[start:end]
        self.assertIn("geocodeOrder(id)", fn)
        self.assertIn("result.committed", fn)

    def test_no_parallel_import_only_geocoding_system(self):
        # There must be exactly one caller of the geocode-order Edge
        # Function endpoint in the Vendor adapter (the shared wrapper) --
        # CSV import must reuse it, not define its own Mapbox call.
        self.assertEqual(VENDOR_JS.count("/functions/v1/geocode-order"), 1)
        self.assertNotIn("api.mapbox.com", VENDOR_JS)
        self.assertNotIn("api.mapbox.com", VENDOR_HTML)

    def test_manual_correction_path_independently_wired(self):
        self.assertIn("setOrderLocationManual(orderId, lat, lng)", VENDOR_JS)
        self.assertIn('data-action="confirmSetLocationManual"', VENDOR_HTML)
        self.assertIn('data-action="openSetLocationManual"', VENDOR_HTML)


if __name__ == "__main__":
    unittest.main()
