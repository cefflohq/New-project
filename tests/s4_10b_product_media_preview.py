"""Bounded static acceptance for the S4-10B Founder preview."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
HTML = (ROOT / "previews/s4-10b-product-media/index.html").read_text()
S4_10A_HTML = (ROOT / "previews/s4-10a-product-catalog/index.html").read_text()


class ProductMediaPreviewTests(unittest.TestCase):
    def test_required_flow_states_present(self):
        for text in (
            "Edit Product", "Add a product photo", "Take Photo", "Upload Photo",
            "Preparing your photo", "Original", "Prepared", "Use This Photo",
            "Preparation Failed", "Retry Preparation", "Replace Photo",
        ):
            self.assertIn(text, HTML)

    def test_original_vs_prepared_comparison_present(self):
        self.assertIn('<div class="compare">', HTML)
        self.assertIn(">Original<", HTML)
        self.assertIn(">Prepared<", HTML)

    def test_failure_and_retry_reachable(self):
        self.assertIn("function failedBody", HTML)
        self.assertIn("id=\"retryPhoto\"", HTML)
        self.assertIn("function retryCurrent", HTML)
        self.assertIn("nothing has changed on your live Order Page", HTML)

    def test_approval_is_only_path_to_current_display_state(self):
        self.assertIn("function approveCurrent", HTML)
        self.assertIn("id=\"approvePhoto\"", HTML)
        self.assertIn("live on your Order Page", HTML)
        self.assertIn("stored privately and is never shown to customers", HTML)

    def test_replacement_never_shows_unapproved_as_current(self):
        # Uploading v2 must not itself flip the visible status to approved --
        # approval only happens through the explicit approve action.
        fn = HTML[HTML.index("function startUpload"):HTML.index("function advanceProcessing")]
        self.assertNotIn("status: 'approved'", fn)
        self.assertIn("status: 'queued'", fn)

    def test_no_out_of_scope_surface(self):
        forbidden = (
            "background-removal-api", "Supabase", "fetch(", "storage.objects",
            "Payment", "COD", "checkout", "SKU", "inventory", "stock", "variant",
            "modifier", "addon selection", "public order",
        )
        for text in forbidden:
            self.assertNotIn(text, HTML)

    def test_no_decorative_gradients_and_restrained_purple(self):
        self.assertNotIn("gradient", HTML.lower())
        self.assertIn("--purple:#7C6CF0", HTML)
        self.assertIn("--purple-tint:#F2F0FF", HTML)

    def test_reduced_motion_respected(self):
        self.assertIn("prefers-reduced-motion:reduce", HTML)

    def test_preview_is_local_only_mock(self):
        self.assertIn("S4-10B UI Preview · Local Demo", HTML)
        self.assertNotIn("localStorage", HTML)
        self.assertNotIn("sessionStorage", HTML)
        self.assertIn("Simulated preview only", HTML)
        self.assertIn("no processing provider is called", HTML)

    def test_does_not_modify_approved_s4_10a_preview(self):
        self.assertIn("S4-10A UI Preview · Local Demo", S4_10A_HTML)
        self.assertNotIn("product photo", S4_10A_HTML.lower())
        self.assertNotIn("prepared", S4_10A_HTML.lower())


if __name__ == "__main__":
    unittest.main()
