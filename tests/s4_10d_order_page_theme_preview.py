"""Bounded static acceptance for the S4-10D Founder discovery/UI preview."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
HTML = (ROOT / "previews/s4-10d-order-page-theme/index.html").read_text()
S4_10A_HTML = (ROOT / "previews/s4-10a-product-catalog/index.html").read_text()
S4_10B_HTML = (ROOT / "previews/s4-10b-product-media/index.html").read_text()
S4_10C_HTML = (ROOT / "previews/s4-10c-food-photography/index.html").read_text()


class OrderPageThemePreviewTests(unittest.TestCase):
    def test_settings_screen_present(self):
        for text in ("Order Page", "Page identity", "Theme", "Preview", "View Full Preview"):
            self.assertIn(text, HTML)

    def test_identity_reuses_existing_business_profile_not_a_duplicate_field(self):
        self.assertIn("Uses your Business Profile name &amp; logo", HTML)
        self.assertIn("businesses.name via update_business_profile", HTML)
        # No independent "Order Page name" input field is introduced.
        self.assertNotIn('id="orderPageName"', HTML)
        self.assertNotIn('id="op_storeName"', HTML)

    def test_exactly_four_curated_themes(self):
        themes_block = HTML[HTML.index("const THEMES = ["):HTML.index("];", HTML.index("const THEMES = ["))]
        self.assertEqual(themes_block.count("{ key:"), 4)
        for name in ("Clean", "Warm", "Fresh", "Midnight"):
            self.assertIn(f"name: '{name}'", themes_block)

    def test_no_full_color_picker_or_arbitrary_css(self):
        forbidden = (
            'type="color"', "RGB", "hex input", "colorPicker", "gradient-builder",
            "contenteditable", "<style contenteditable",
        )
        for text in forbidden:
            self.assertNotIn(text, HTML)
        self.assertNotIn("gradient", HTML.lower())

    def test_theme_selection_updates_state_and_rerenders(self):
        fn = HTML[HTML.index("function bindActions"):HTML.index("    render();\n  </script>")]
        self.assertIn("selectedTheme = el.dataset.themeKey", fn)
        self.assertIn("render();", fn)

    def test_mini_preview_and_full_preview_both_present(self):
        self.assertIn('class="mini-preview"', HTML)
        self.assertIn("function renderFullPreview", HTML)
        self.assertIn('id="viewFullPreview"', HTML)

    def test_full_preview_shows_representative_catalog_structure(self):
        # Mirrors S4-10A's category -> product shape, not a duplicate model.
        self.assertIn("const catalog = [", HTML)
        self.assertIn("category:", HTML)
        self.assertIn("products:", HTML)
        for text in ("Makanan", "Minuman", "Nasi Lemak Ayam", "Teh Ais Limau"):
            self.assertIn(text, HTML)

    def test_no_cart_or_order_submission_implemented(self):
        forbidden = (
            "addToCart", "cart.push", "submitOrder", "checkout", "Add to Order",
            "View Order", "your-order", "delivery-details", "order-sent",
        )
        for text in forbidden:
            self.assertNotIn(text, HTML)

    def test_no_false_save_persistence_claim(self):
        self.assertNotIn("Saved successfully", HTML)
        self.assertNotIn("Theme saved", HTML)
        self.assertIn("Preview only", HTML)
        self.assertIn("Not saved", HTML)
        self.assertIn("No changes are sent to Cefflo yet", HTML)
        save_handler = HTML[HTML.index("const saveBtn"):HTML.index("    render();\n  </script>")]
        self.assertIn("announce('Preview only -- not saved')", save_handler)
        self.assertNotIn("toast(", save_handler)

    def test_no_backend_or_network_calls(self):
        forbidden = ("fetch(", "Supabase", "storage.objects", "navigator.clipboard", "XMLHttpRequest")
        for text in forbidden:
            self.assertNotIn(text, HTML)

    def test_full_preview_carries_honest_disclaimer(self):
        self.assertIn("Preview only -- not the live customer experience yet.", HTML)

    def test_no_out_of_scope_surface(self):
        forbidden = (
            "Payment", "COD", "checkout", "deposit", "balance", "quotation",
            "invoice", "star rating", "customer review", "leave a review",
            "marketplace", "AI-generated", "drag-and-drop", "drop-zone",
            "contenteditable",
        )
        for text in forbidden:
            self.assertNotIn(text, HTML)

    def test_reuses_established_preview_family_tokens(self):
        self.assertIn("--purple:#7C6CF0", HTML)
        self.assertIn("--purple-tint:#F2F0FF", HTML)
        self.assertIn("--line:#ECEAF0", HTML)
        # Same header/content baseline as S4-10A/B/C.
        self.assertIn("min-height:64px", HTML)
        self.assertIn(".content{padding:16px 16px 44px}", HTML)

    def test_no_horizontal_overflow_safety_nets_present(self):
        self.assertIn("overflow-x:hidden", HTML)
        self.assertIn("min-width:0", HTML)

    def test_reduced_motion_respected(self):
        self.assertIn("prefers-reduced-motion:reduce", HTML)

    def test_preview_is_local_only(self):
        self.assertIn("S4-10D UI Preview · Local Demo", HTML)
        self.assertNotIn("localStorage", HTML)
        self.assertNotIn("sessionStorage", HTML)

    def test_does_not_modify_closed_s4_10a_b_c_previews(self):
        self.assertIn("S4-10A UI Preview · Local Demo", S4_10A_HTML)
        self.assertIn("S4-10B UI Preview · Local Demo", S4_10B_HTML)
        self.assertIn("S4-10C UI Preview · Local Demo", S4_10C_HTML)
        # None of the prior packages gained an S4-10D theme/identity feature
        # (a passing incidental phrase like "live on your Order Page" is not
        # the same as implementing Order Page theming, so check for that
        # instead of the bare phrase).
        for html in (S4_10A_HTML, S4_10B_HTML, S4_10C_HTML):
            self.assertNotIn("data-theme-key", html)
            self.assertNotIn("Page identity", html)
            self.assertNotIn("View Full Preview", html)

    def test_s4_10c_canonical_prompt_untouched(self):
        start = S4_10C_HTML.index("const CANONICAL_PROMPT = `") + len("const CANONICAL_PROMPT = `")
        end = S4_10C_HTML.index("`;", start)
        prompt = S4_10C_HTML[start:end]
        import hashlib
        self.assertEqual(len(prompt), 9996)
        self.assertEqual(
            hashlib.sha256(prompt.encode("utf-8")).hexdigest(),
            "76efef39557615f17f5d4e0d88ae3b05877d9f9158169635eb55f078a0fec18e",
        )


if __name__ == "__main__":
    unittest.main()
