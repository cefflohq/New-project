"""Static acceptance for Flow 3 F3-13: the shared innerHeader() helper
(used by every sub-page in the Vendor app -- Order Detail, Zone Detail,
Active Runs, Run Detail, Need Attention, Business Profile, and dozens of
others) rendered its back button and icon-only header action button with
no accessible name at all. A screen reader user had no way to know what
either control did on any screen in the app.

Also confirms the existing, already-correct :focus-visible pattern
(outline removed on plain :focus, restored with a visible ring on
:focus-visible) is still intact -- this was found already properly
implemented this session, not something this pass needed to add.

Browser tooling is not connected in this environment, so this is a
static/structural check against the real source, matching the established
precedent (s4_06_batch_5b_vendor_run_builder_wiring.py and others).
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INDEX_HTML = (ROOT / "vendor" / "index.html").read_text(encoding="utf-8")


def block(source, start_pattern, end_marker="\n}"):
    match = re.search(start_pattern, source)
    assert match, f"pattern not found: {start_pattern}"
    start = match.start()
    end = source.index(end_marker, start) + len(end_marker)
    return source[start:end]


class SharedHeaderAccessibilityTests(unittest.TestCase):
    def setUp(self):
        self.fn = block(INDEX_HTML, r"function innerHeader\(title, opts\)\{")

    def test_back_button_has_accessible_name(self):
        self.assertIn('data-action="goBack" aria-label="${t(\'back\')}"', self.fn)

    def test_icon_only_header_action_has_accessible_name(self):
        self.assertIn('aria-label="${opts.actionLabel||t(\'more\')||\'More options\'}"', self.fn)

    def test_back_translation_defined_in_all_four_launch_locales(self):
        for expected in ('back:"Back", more:"More options"', 'back:"Kembali", more:"Pilihan lanjut"', 'back:"返回", more:"更多选项"', 'back:"பின்", more:"கூடுதல் விருப்பங்கள்"'):
            self.assertIn(expected, INDEX_HTML)


class FocusVisiblePatternIntactTests(unittest.TestCase):
    def test_focus_visible_ring_still_present(self):
        self.assertIn(":focus-visible{", INDEX_HTML)
        self.assertIn("outline:2px solid var(--primary)", INDEX_HTML)


if __name__ == "__main__":
    unittest.main()
