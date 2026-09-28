"""Static acceptance for a Flow 3 F3-12 truthfulness sweep: two more live
"reads a field that was never set, renders the literal text undefined"
bugs found after the Dashboard (F3-02) and Rider Profile (F3-07) fixes,
using the same method (trace every field a live-reachable render function
reads back to its real canonical source).

1. Orders list (pageOrders/renderOrdersList): every ongoing-order row
   showed "ETA undefined min" -- o.eta was never set by mapOrder(), and
   no canonical Vendor-facing ETA source exists at all (compute_order_eta
   was correctly hardened to internal-only in Flow 2's F2-11). Fixed by
   showing the real order status label instead of a fabricated ETA.

2. Business Profile (pageBusinessProfile): state.businessPhone/
   businessEmail/businessAddress/operatingArea were only ever populated
   AFTER a Vendor's own first save in the current session -- a Vendor
   opening Business Profile for the first time after signup (when
   bootstrap_business had already set real values server-side) saw
   literal "undefined" in every input. Fixed two ways: the render now
   guards every field with `|| ''` (never renders "undefined" even if a
   fetch is somehow still pending), and hydrateCanonicalWorkspace() now
   actually fetches the real business row (phone/email/address/
   operating_area) via the existing businesses_read RLS-protected REST
   query, so the fields show real saved values on first load, not blank.

Browser tooling is not connected in this environment, so this is a
static/structural check against the real source, matching the established
precedent (s4_06_batch_5b_vendor_run_builder_wiring.py and others).
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BACKEND_JS = (ROOT / "vendor" / "backend.js").read_text(encoding="utf-8")
INDEX_HTML = (ROOT / "vendor" / "index.html").read_text(encoding="utf-8")


def block(source, start_pattern, end_marker="\n}"):
    match = re.search(start_pattern, source)
    assert match, f"pattern not found: {start_pattern}"
    start = match.start()
    end = source.index(end_marker, start) + len(end_marker)
    return source[start:end]


class OrdersListEtaTests(unittest.TestCase):
    def test_no_fabricated_eta_field_read(self):
        fn = block(INDEX_HTML, r"function renderOrdersList\(list\)\{")
        self.assertNotIn("o.eta", fn)

    def test_shows_real_status_label_instead(self):
        fn = block(INDEX_HTML, r"function renderOrdersList\(list\)\{")
        self.assertIn("t(o.status)||o.status", fn)


class BusinessProfileHydrationTests(unittest.TestCase):
    def test_business_details_fetch_carries_contact_fields(self):
        fn = next(line for line in BACKEND_JS.splitlines() if "const getBusinessDetails" in line)
        for field in ("phone", "email", "address", "operating_area"):
            self.assertIn(field, fn)

    def test_hydrate_populates_real_contact_fields(self):
        fn = block(BACKEND_JS, r"async function hydrateCanonicalWorkspace\(\) \{", end_marker="\n  }")
        self.assertIn("state.businessPhone = businessDetails.phone", fn)
        self.assertIn("state.businessEmail = businessDetails.email", fn)
        self.assertIn("state.businessAddress = businessDetails.address", fn)
        self.assertIn("state.operatingArea = businessDetails.operating_area", fn)

    def test_render_never_emits_literal_undefined(self):
        fn = block(INDEX_HTML, r"function pageBusinessProfile\(\)\{")
        for field in ("state.storeName", "state.businessPhone", "state.businessEmail", "state.businessAddress", "state.operatingArea"):
            self.assertIn(f"{field}||''", fn)


if __name__ == "__main__":
    unittest.main()
