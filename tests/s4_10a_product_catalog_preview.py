"""Bounded static acceptance for the S4-10A Founder preview."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
HTML = (ROOT / "previews/s4-10a-product-catalog/index.html").read_text()


class ProductCatalogPreviewTests(unittest.TestCase):
    def test_approved_structure_and_fields(self):
        for text in ("Products", "Active", "Hidden", "Makanan", "Minuman", "Add-on", "+ Add Product", "Product name", "Category", "Description", "Display price", "Visibility", "Archive"):
            self.assertIn(text, HTML)

    def test_reorder_is_direct_and_category_bounded(self):
        self.assertIn('draggable="true"', HTML)
        self.assertIn("a.category!==b.category", HTML)
        self.assertIn("within a category", HTML)
        self.assertIn("Alt + ↑ / ↓", HTML)
        self.assertIn("ArrowUp", HTML)
        self.assertIn("ArrowDown", HTML)
        self.assertNotIn(">↑<", HTML)
        self.assertNotIn(">↓<", HTML)

    def test_restrained_visual_contract(self):
        self.assertIn("--purple:#7C6CF0", HTML)
        self.assertIn("--purple-tint:#F2F0FF", HTML)
        self.assertNotIn("purple page", HTML.lower())
        self.assertNotIn("gradient", HTML.lower())

    def test_no_out_of_scope_product_surface(self):
        forbidden = ("product_media", "background removal", "Supabase", "Payment Method", "COD", "SKU", "inventory", "stock", "variant", "addon selection")
        for text in forbidden:
            self.assertNotIn(text, HTML)

    def test_preview_is_local_only(self):
        self.assertIn("S4-10A UI Preview · Local Demo", HTML)
        self.assertNotIn("fetch(", HTML)
        self.assertNotIn("localStorage", HTML)
        self.assertNotIn("sessionStorage", HTML)


if __name__ == "__main__":
    unittest.main()
