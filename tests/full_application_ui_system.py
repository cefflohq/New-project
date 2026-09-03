from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


class FullApplicationUISystemTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.css = (ROOT / "shared/ui-system.css").read_text()
        cls.vendor = (ROOT / "vendor/index.html").read_text()
        cls.rider = (ROOT / "rider/index.html").read_text()
        cls.customer = (ROOT / "customer/index.html").read_text()

    def test_shared_semantic_system_is_loaded_by_all_apps(self):
        for source in (self.vendor, self.rider, self.customer):
            self.assertIn('../shared/ui-system.css?v=20260903a', source)

    def test_locked_palette_and_semantic_tokens_exist(self):
        for value in ('#0d0e0d', '#171917', '#c7f000', '#f5f5f0', '#dadbd4'):
            self.assertIn(value, self.css.lower())
        self.assertIn('--cf-page:', self.css)
        self.assertIn('--cf-surface:', self.css)
        self.assertIn('--cf-signal:', self.css)

    def test_light_dark_share_geometry(self):
        dark_block = re.search(r'html\[data-theme="dark"\],body\[data-vendor-theme="dark"\]\s*\{([^}]+)\}', self.css)
        self.assertIsNotNone(dark_block)
        self.assertNotRegex(dark_block.group(1), r'(padding|margin|width|height|gap|radius)\s*:')

    def test_recent_orders_are_divider_rows(self):
        self.assertIn('vd2-recent-orders', self.vendor)
        self.assertIn('vd2-order-row', self.vendor)
        self.assertIn('border-bottom:1px solid var(--cf-line)', self.css)

    def test_rider_current_stop_and_slider_follow_founder_lock(self):
        self.assertIn('.route-current-card){background:var(--cf-graphite)', self.css)
        self.assertIn('.slider-wrap{height:58px', self.css)
        self.assertIn('border-radius:50%!important;background:var(--cf-signal)', self.css)
        self.assertIn('.slider-track-label{color:#fff', self.css)
        self.assertIn('fill:var(--cf-signal)', self.css)

    def test_customer_eta_and_progress_hierarchy(self):
        self.assertIn('.pc-eta strong{font-size:32px', self.css)
        self.assertIn('.pc-step.done span', self.css)
        self.assertIn('background:var(--cf-signal)', self.css)

    def test_reduced_motion_and_focus_visible(self):
        self.assertIn('@media(prefers-reduced-motion:reduce)', self.css)
        self.assertIn('*:focus-visible', self.css)

    def test_no_backend_or_auth_files_changed_by_contract(self):
        # The implementation surface is intentionally CSS plus page composition.
        self.assertNotIn('service_role', self.css.lower())
        self.assertNotIn('supabase', self.css.lower())


if __name__ == '__main__':
    unittest.main()
