"""Bounded static acceptance for the S4-10C Founder preview."""

import hashlib
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
HTML = (ROOT / "previews/s4-10c-food-photography/index.html").read_text()
S4_10A_HTML = (ROOT / "previews/s4-10a-product-catalog/index.html").read_text()
S4_10B_HTML = (ROOT / "previews/s4-10b-product-media/index.html").read_text()


def _canonical_prompt(html):
    start = html.index("const CANONICAL_PROMPT = `") + len("const CANONICAL_PROMPT = `")
    end = html.index("`;", start)
    return html[start:end]


PROMPT = _canonical_prompt(HTML)
CANONICAL_PROMPT_SHA256 = "76efef39557615f17f5d4e0d88ae3b05877d9f9158169635eb55f078a0fec18e"


class FoodPhotographyPreviewTests(unittest.TestCase):
    def test_flow_entry_points_present(self):
        for text in (
            "Product Photo", "Upload Photo", "Improve Photo", "Copy Prompt",
            "Got your finished photo?", "Upload Finished Photo", "Use This Photo",
        ):
            self.assertIn(text, HTML)

    def test_five_step_sequence_present_in_requested_order(self):
        steps = ["Copy Prompt", "Add your food photo", "Choose your vibe", "Generate", "Return &amp; upload"]
        for text in steps:
            self.assertIn(text, HTML)
        positions = [HTML.index(f'>{s}<') for s in steps]
        self.assertEqual(positions, sorted(positions))

    def test_step_list_is_compact_not_giant_cards(self):
        # Five compact rows, not five bordered/padded card blocks.
        self.assertEqual(HTML.count('class="step-row"'), 5)
        steps_block = HTML[HTML.index('class="steps-list"'):HTML.index('id="copyPromptBtn"')]
        self.assertNotIn("border:1px solid", steps_block)

    def test_canonical_prompt_present_and_not_truncated(self):
        self.assertTrue(PROMPT.startswith("CEFFLO FOOD PHOTOGRAPHY"))
        self.assertTrue(PROMPT.rstrip().endswith("NOT AI-GENERATED."))
        for marker in (
            "1. FOOD FIDELITY", "2. ANTI-AI FOOD APPEARANCE", "3. PRIMARY SERVING VESSEL",
            "4. CAMERA & COMPOSITION", "5. USER-SELECTED THEME", "6. MINIMAL PROPS",
            "7. PROFESSIONAL PHOTOGRAPHIC LIGHTING", "8. NATURAL COLOUR",
            "9. PHYSICAL GROUNDING", "10. REALISTIC DEPTH OF FIELD",
            "11. FINAL OUTPUT", "FINAL REALISM TEST", "ABSOLUTE FINAL PRINCIPLE",
        ):
            self.assertIn(marker, PROMPT)
        self.assertGreater(len(PROMPT), 9000)

    def test_prompt_is_not_rewritten(self):
        # Spot-check exact phrasing from the canonical text survives verbatim.
        self.assertIn("PRODUCT TRUTH OVERRIDES BEAUTY.", PROMPT)
        self.assertIn("Improve the PHOTOGRAPHY.", PROMPT)
        self.assertIn("DO NOT improve the physical food.", PROMPT)
        self.assertIn("THE FINAL RESULT MUST LOOK PHOTOGRAPHED,\nNOT AI-GENERATED.", PROMPT)

    def test_canonical_prompt_byte_identical_sha256(self):
        self.assertEqual(len(PROMPT), 9996)
        digest = hashlib.sha256(PROMPT.encode("utf-8")).hexdigest()
        self.assertEqual(digest, CANONICAL_PROMPT_SHA256)

    def test_clipboard_copy_is_genuine_and_truthful(self):
        self.assertIn("navigator.clipboard.writeText(CANONICAL_PROMPT)", HTML)
        fn = HTML[HTML.index("async function writePromptToClipboard"):HTML.index("async function copyPrompt")]
        # Success state only set inside the try block after the await resolves.
        try_block = fn[fn.index("try{"):fn.index("}catch")]
        self.assertIn("promptCopyState = 'ok'", try_block)
        self.assertIn("return true", try_block)
        catch_block = fn[fn.index("}catch"):]
        self.assertIn("promptCopyState = 'fail'", catch_block)
        self.assertIn("return false", catch_block)
        self.assertNotIn("promptCopyState = 'ok'", catch_block)

    def test_failed_copy_offers_truthful_manual_fallback(self):
        self.assertIn("fallback", HTML)
        self.assertIn("escapeHtml(CANONICAL_PROMPT)", HTML)
        self.assertIn("Couldn't copy automatically", HTML)

    def test_no_fabricated_generation_or_processing_state(self):
        forbidden = (
            "Generating", "generating your photo", "AI is creating",
            "Preparing your photo", "spinner", "processing-preview",
            "step.done", "advanceProcessing",
        )
        for text in forbidden:
            self.assertNotIn(text, HTML)

    def test_no_generation_backend_or_api_integration(self):
        forbidden = (
            "openai", "OpenAI", "api.openai.com", "anthropic.com/v1",
            "rembg", "background-removal", "segmentation", "inference",
            "fetch(", "Supabase", "storage.objects", "generation_id",
        )
        for text in forbidden:
            self.assertNotIn(text, HTML)

    def test_real_local_image_picker_and_safe_cancel(self):
        self.assertIn('id="resultInput" type="file" accept="image/*"', HTML)
        self.assertIn("resultInput.click()", HTML)
        listener = HTML[HTML.index("resultInput.addEventListener"):HTML.index("function useSelectedResult")]
        self.assertIn("if(!file) return", listener)
        self.assertIn("URL.createObjectURL(file)", listener)
        self.assertIn("file.type.startsWith('image/')", listener)

    def test_selected_result_preview_uses_real_local_image(self):
        self.assertIn('<img src="${selectedResult.url}" alt="Selected generated photo">', HTML)
        self.assertIn('<img src="${approvedPhoto.url}" alt="Approved product photo">', HTML)

    def test_use_this_photo_requires_real_selection(self):
        fn = HTML[HTML.index("function useSelectedResult"):HTML.index("render();\n  </script>")]
        self.assertIn("if(!selectedResult?.url) return", fn)

    def test_replacement_selection_updates_preview(self):
        listener = HTML[HTML.index("resultInput.addEventListener"):HTML.index("function useSelectedResult")]
        self.assertIn("URL.revokeObjectURL(selectedResult.url)", listener)
        self.assertIn("selectedResult = { url: URL.createObjectURL(file)", listener)

    def test_no_false_success_after_use_this_photo(self):
        self.assertNotIn("Photo updated", HTML)
        self.assertNotIn("Live on your Order Page", HTML)
        fn = HTML[HTML.index("function useSelectedResult"):HTML.index("render();\n  </script>")]
        for claim in ("uploaded", "saved", "published", "live on"):
            self.assertNotIn(claim, fn.lower())
        self.assertIn("Photo selected for preview", HTML)

    def test_product_photo_card_is_truthfully_local_only(self):
        self.assertIn("Preview only", HTML)
        self.assertNotIn("Live on your Order Page", HTML)

    def test_abandon_candidate_revokes_and_clears_state(self):
        self.assertIn("function abandonCandidate()", HTML)
        fn = HTML[HTML.index("function abandonCandidate()"):HTML.index("window.addEventListener('beforeunload'")]
        self.assertIn("URL.revokeObjectURL(selectedResult.url)", fn)
        self.assertIn("selectedResult = null", fn)
        back_handler = HTML[HTML.index("const backBtn"):HTML.index("const openFP")]
        self.assertIn("abandonCandidate()", back_handler)
        self.assertIn("resultPreview", back_handler)

    def test_abandon_does_not_fire_while_candidate_still_needed(self):
        # abandonCandidate must only be wired to the explicit back-out path,
        # never to replacement (openResultPicker) or approval (useSelectedResult).
        replace_paths = HTML[HTML.index("function openResultPicker"):HTML.index("resultInput.addEventListener")]
        self.assertNotIn("abandonCandidate", replace_paths)
        use_fn = HTML[HTML.index("function useSelectedResult"):HTML.index("render();\n  </script>")]
        self.assertNotIn("abandonCandidate", use_fn)

    def test_page_unload_cleanup_present(self):
        self.assertIn("beforeunload", HTML)
        fn = HTML[HTML.index("window.addEventListener('beforeunload'"):HTML.index("function useSelectedResult")]
        self.assertIn("URL.revokeObjectURL(selectedResult.url)", fn)
        self.assertIn("URL.revokeObjectURL(approvedPhoto.url)", fn)

    def test_no_out_of_scope_surface(self):
        forbidden = (
            "Payment", "COD", "checkout", "SKU", "inventory", "stock", "variant",
            "modifier", "addon selection", "public order", "Interactive Canvas",
            "theme preset", "order page theme",
        )
        for text in forbidden:
            self.assertNotIn(text, HTML)

    def test_avoids_technical_jargon_in_vendor_copy(self):
        vendor_copy = HTML[HTML.index("<body>"):HTML.index("<script>")]
        for jargon in ("API", "generative model", "image pipeline", "segmentation", "inference"):
            self.assertNotIn(jargon, vendor_copy)

    def test_no_decorative_gradients_and_restrained_purple(self):
        self.assertNotIn("gradient", HTML.lower())
        self.assertIn("--purple:#7C6CF0", HTML)
        self.assertIn("--purple-tint:#F2F0FF", HTML)

    def test_reduced_motion_respected(self):
        self.assertIn("prefers-reduced-motion:reduce", HTML)

    def test_preview_is_local_only(self):
        self.assertIn("S4-10C UI Preview · Local Demo", HTML)
        self.assertNotIn("localStorage", HTML)
        self.assertNotIn("sessionStorage", HTML)

    def test_product_photo_is_hero_scale_not_a_settings_row(self):
        product_photo_fn = HTML[HTML.index("function renderProductPhoto"):HTML.index("function renderFoodPhotography")]
        self.assertIn('class="hero-visual"', product_photo_fn)
        # The old tiny thumbnail + chevron settings-row treatment must be gone.
        self.assertNotIn("photo-thumb", HTML)
        self.assertNotIn("action-btn", HTML)
        self.assertNotIn("More options", HTML)
        self.assertIn(".hero-visual{width:100%;aspect-ratio:1", HTML.replace(" ", ""))

    def test_product_photo_has_upload_and_improve_actions(self):
        product_photo_fn = HTML[HTML.index("function renderProductPhoto"):HTML.index("function howItWorksBlock")]
        self.assertIn('id="uploadPhotoDirect"', product_photo_fn)
        self.assertIn(">Upload Photo<", product_photo_fn)
        self.assertIn('id="openFoodPhotography"', product_photo_fn)
        self.assertIn(">Improve Photo<", product_photo_fn)
        # No long Food Photography explanation on this screen any more.
        self.assertNotIn("Create a professional menu photo using your existing food photo.", product_photo_fn)

    def test_only_improve_photo_enters_food_photography_flow(self):
        bind_fn = HTML[HTML.index("function bindScreenActions"):HTML.index("async function copyPrompt")]
        upload_handler = bind_fn[bind_fn.index("uploadPhotoDirect"):bind_fn.index("const openFP")]
        self.assertNotIn("go('foodPhotography')", upload_handler)
        self.assertIn("openResultPicker('direct')", upload_handler)
        improve_handler = bind_fn[bind_fn.index("const openFP"):bind_fn.index("const howToggle")]
        self.assertIn("go('foodPhotography')", improve_handler)

    def test_improve_photo_page_title_is_short(self):
        fp_fn = HTML[HTML.index("function renderFoodPhotography"):HTML.index("function renderResultPreview")]
        self.assertIn("header('Improve Photo', true)", fp_fn)
        # The long "Food Photography" page title is gone from this screen's
        # own header/body (it may still legitimately appear inside the
        # collapsed how-it-works step copy and the prompt text elsewhere).
        self.assertNotIn("header('Food Photography'", HTML)

    def test_comparison_concept_completely_removed(self):
        # Founder-rejected Original -> Finished / Before -> After concept,
        # and any component/class that implemented it, must be fully gone --
        # not renamed, not relabeled, not reintroduced under another name.
        forbidden = (
            ">Original<", ">Finished<", "Original →", "Original ->",
            "Before →", "Before ->", "Before/After", "Before / After",
            "class=\"compare\"", "compare .tile", "tile-wrap", "tile-label",
            "class=\"arrow\"", "transformation", "before/after",
        )
        for text in forbidden:
            self.assertNotIn(text, HTML)

    def test_product_photo_entry_has_no_comparison_markup(self):
        product_photo_fn = HTML[HTML.index("function renderProductPhoto"):HTML.index("function renderFoodPhotography")]
        for text in ("compare", "tile-wrap", "tile-label", ">Original<", ">Finished<"):
            self.assertNotIn(text, product_photo_fn)
        # Exactly one CTA on the entry feature section.
        self.assertEqual(product_photo_fn.count('id="openFoodPhotography"'), 1)

    def test_internal_preview_commentary_removed_from_vendor_ui(self):
        self.assertNotIn("Structure/behavior preview only", HTML)
        self.assertNotIn("already reviewed separately", HTML)

    def test_how_it_works_collapsed_by_default(self):
        self.assertIn("let howItWorksOpen = false", HTML)
        self.assertIn('id="howItWorksToggle"', HTML)
        self.assertIn(">How it works<", HTML)

    def test_how_it_works_expand_and_collapse_toggle(self):
        bind_fn = HTML[HTML.index("function bindScreenActions"):HTML.index("async function copyPrompt")]
        toggle_handler = bind_fn[bind_fn.index("howToggle"):]
        self.assertIn("howItWorksOpen = !howItWorksOpen", toggle_handler)
        self.assertIn("render()", toggle_handler)
        # The steps only render into the DOM when the block is expanded.
        block_fn = HTML[HTML.index("function howItWorksBlock"):HTML.index("function renderFoodPhotography")]
        self.assertIn("howItWorksOpen ? `<div class=\"steps-list\">", block_fn)

    def test_copy_prompt_label_is_short_with_icon(self):
        fp_fn = HTML[HTML.index("function renderFoodPhotography"):HTML.index("function renderResultPreview")]
        self.assertIn('<button class="btn" id="copyPromptBtn">${icon.copy}<span>Copy Prompt</span></button>', fp_fn)
        self.assertNotIn("Copy Food Photography Prompt", HTML)

    def test_successful_copy_opens_chatgpt(self):
        fn = HTML[HTML.index("async function copyPrompt"):HTML.index("async function copyPromptAgain")]
        self.assertIn("const ok = await writePromptToClipboard()", fn)
        success_block = fn[fn.index("if(ok){"):fn.index("}else{")]
        self.assertIn("window.open(CHATGPT_URL, '_blank', 'noopener')", success_block)
        self.assertIn("handoffState = 'pending'", success_block)
        self.assertIn("const CHATGPT_URL = 'https://chatgpt.com/'", HTML)

    def test_failed_initial_copy_does_not_open_chatgpt_or_falsely_hand_off(self):
        fn = HTML[HTML.index("async function copyPrompt"):HTML.index("async function copyPromptAgain")]
        else_block = fn[fn.index("}else{"):]
        self.assertNotIn("window.open", else_block)
        self.assertNotIn("handoffState = 'pending'", else_block)

    def test_no_claim_of_automatic_paste_or_photo_upload_to_chatgpt(self):
        forbidden = (
            "automatically paste", "auto-paste", "pastes the prompt for you",
            "uploads your photo to ChatGPT", "automatically upload", "auto-upload",
        )
        for text in forbidden:
            self.assertNotIn(text.lower(), HTML.lower())

    def test_return_transition_guarded_against_initial_load(self):
        fn = HTML[HTML.index("function handleReturnFocus"):HTML.index("document.addEventListener('visibilitychange'")]
        self.assertIn("if(handoffState === 'pending')", fn)
        self.assertIn("handoffState = 'returned'", fn)
        self.assertIn("let handoffState = 'idle'", HTML)
        # Both signals funnel through the same guarded function -- no
        # separate unguarded transition path exists.
        self.assertIn("document.visibilityState === 'visible') handleReturnFocus()", HTML)
        self.assertIn("window.addEventListener('focus', handleReturnFocus)", HTML)
        self.assertNotIn("setTimeout(() => { handoffState", HTML)

    def test_return_state_focuses_on_upload_not_copy_prompt(self):
        fp_fn = HTML[HTML.index("function renderFoodPhotography"):HTML.index("function renderResultPreview")]
        returned_block = fp_fn[fp_fn.index("const returnedBody"):fp_fn.index("return `")]
        self.assertIn("Got your finished photo?", returned_block)
        self.assertIn("Upload your finished menu photo to continue.", returned_block)
        self.assertIn("Upload Finished Photo", returned_block)
        self.assertNotIn("copyPromptBtn", returned_block)
        pre_handoff_block = fp_fn[fp_fn.index("const preHandoffBody"):fp_fn.index("const returnedBody")]
        self.assertIn("copyPromptBtn", pre_handoff_block)
        self.assertNotIn("continueToUpload", pre_handoff_block)
        self.assertIn("handoffState==='returned' ? returnedBody : preHandoffBody", fp_fn)

    def test_return_state_does_not_show_expanded_five_step_workflow(self):
        fp_fn = HTML[HTML.index("function renderFoodPhotography"):HTML.index("function renderResultPreview")]
        returned_block = fp_fn[fp_fn.index("const returnedBody"):fp_fn.index("return `")]
        self.assertNotIn("howItWorksBlock()", returned_block)
        self.assertNotIn("steps-list", returned_block)
        self.assertNotIn("hero-visual compact", returned_block)

    def test_recovery_actions_present_and_visually_secondary(self):
        fp_fn = HTML[HTML.index("function renderFoodPhotography"):HTML.index("function renderResultPreview")]
        returned_block = fp_fn[fp_fn.index("const returnedBody"):fp_fn.index("return `")]
        self.assertIn('id="openChatGptAgain"', returned_block)
        self.assertIn(">Open ChatGPT again<", returned_block)
        self.assertIn('id="copyPromptAgain"', returned_block)
        self.assertIn(">Copy Prompt again<", returned_block)
        # Quiet text-link treatment, not another primary/secondary button.
        self.assertIn(".recovery-actions button{background:transparent;border:0", HTML)

    def test_open_chatgpt_again_opens_only_and_stays_in_return_state(self):
        fn = HTML[HTML.index("function openChatGptAgain"):HTML.index("function openResultPicker")]
        self.assertIn("window.open(CHATGPT_URL, '_blank', 'noopener')", fn)
        self.assertNotIn("writePromptToClipboard", fn)
        self.assertNotIn("handoffState =", fn)
        self.assertNotIn("promptCopyState", fn)

    def test_copy_prompt_again_copies_only_and_stays_in_return_state(self):
        fn = HTML[HTML.index("async function copyPromptAgain"):HTML.index("function openChatGptAgain")]
        self.assertIn("await writePromptToClipboard()", fn)
        self.assertNotIn("window.open", fn)
        self.assertNotIn("handoffState =", fn)
        self.assertNotIn("go(", fn)

    def test_return_state_guard_prevents_re_transition_on_repeat_focus(self):
        # openChatGptAgain never sets handoffState back to 'pending', so a
        # second real return (visibilitychange/focus) cannot re-trigger the
        # State2->State3 transition or reset any Return State content.
        fn = HTML[HTML.index("function openChatGptAgain"):HTML.index("function openResultPicker")]
        self.assertNotIn("handoffState = 'pending'", fn)

    def test_purple_reserved_for_primary_action_only(self):
        self.assertIn(".btn{width:100%;height:52px;margin-top:18px;border:0;border-radius:12px;background:var(--purple)", HTML)
        self.assertIn(".btn.secondary{background:#fff;color:var(--text);border:1.5px solid var(--line)}", HTML)
        self.assertNotIn(".btn.secondary{background:var(--purple)", HTML)

    def test_secondary_button_has_clear_clickable_affordance(self):
        # Founder feedback: the grey secondary treatment looked disabled --
        # it must now be a real bordered, near-white, clearly-actionable button.
        self.assertIn("border:1.5px solid var(--line)", HTML)
        self.assertNotIn(".btn.secondary{background:#F4F3F6", HTML)

    def test_upload_finished_photo_is_now_the_primary_return_state_action(self):
        # Founder direction: Upload Finished Photo must be the strongest
        # action on the Return State screen -- it is now the primary purple
        # button, not the bordered secondary treatment.
        fp_fn = HTML[HTML.index("function renderFoodPhotography"):HTML.index("function renderResultPreview")]
        self.assertIn('<button class="btn" id="continueToUpload">${icon.upload}<span>Upload Finished Photo</span></button>', fp_fn)
        self.assertNotIn('<button class="btn secondary" id="continueToUpload"', fp_fn)

    def test_hero_photo_is_compact_on_food_photography_screen(self):
        self.assertIn(".hero-visual.compact{aspect-ratio:auto;height:240px}", HTML.replace(" ", ""))
        # Explicitly not the same near-full-height treatment as the entry hero.
        self.assertNotIn(".hero-visual.compact{aspect-ratio:4/3}", HTML.replace(" ", ""))

    def test_long_intro_paragraph_removed(self):
        self.assertNotIn(
            "Use the Cefflo Food Photography prompt with your food photo in an image-capable AI chat, choose your preferred vibe, then upload the finished photo here.",
            HTML,
        )
        self.assertIn("Make your food photo stand out.", HTML)

    def test_ai_support_warning_card_removed(self):
        self.assertNotIn("Not every AI chat supports this", HTML)
        self.assertNotIn("Results vary between tools", HTML)
        self.assertNotIn('class="guidance"', HTML)

    def test_only_one_compact_safety_note_style_remains(self):
        # No large purple panel treatment for the integrity reminder.
        self.assertNotIn(".safety-note{margin-top:14px;padding:11px 13px;border-radius:11px;background:var(--purple-tint)", HTML)
        self.assertEqual(HTML.count("Check that the generated photo still matches your actual food and portion."), 2)
        self.assertNotIn("Check the generated photo before using it to make sure your food and portion still match the original.", HTML)

    def test_copy_success_feedback_is_compact(self):
        fp_fn = HTML[HTML.index("function renderFoodPhotography"):HTML.index("function renderResultPreview")]
        self.assertIn("<b>Prompt copied</b>", fp_fn)
        self.assertNotIn("Prompt copied. Paste it together with your original food photo in your AI chat.", HTML)

    def test_preview_badge_is_in_normal_document_flow(self):
        # Must not be a fixed overlay that can cover the sticky header while
        # scrolling -- moved into normal flow inside the shell instead.
        self.assertNotIn("position:fixed;z-index:20", HTML)
        self.assertIn(".preview-label{display:block", HTML)
        self.assertIn('<div class="preview-label">S4-10C UI Preview · Local Demo</div>', HTML)

    def test_upload_result_intermediate_screen_removed(self):
        self.assertNotIn("renderUploadResult", HTML)
        self.assertNotIn("'uploadResult'", HTML)
        self.assertNotIn("pickResult", HTML)

    def test_result_shown_large_with_change_and_use_actions(self):
        result_fn = HTML[HTML.index("function renderResultPreview"):HTML.index("function bindScreenActions")]
        self.assertIn('class="hero-visual"', result_fn)
        self.assertIn(">Change Photo<", result_fn)
        self.assertIn('id="useThisPhoto"', result_fn)

    def test_no_horizontal_overflow_safety_nets_present(self):
        self.assertIn("overflow-x:hidden", HTML)
        self.assertIn("min-width:0", HTML)

    def test_does_not_modify_approved_s4_10a_or_s4_10b_previews(self):
        self.assertIn("S4-10A UI Preview · Local Demo", S4_10A_HTML)
        self.assertIn("S4-10B UI Preview · Local Demo", S4_10B_HTML)
        self.assertNotIn("Food Photography", S4_10A_HTML)
        self.assertNotIn("Food Photography", S4_10B_HTML)
        self.assertNotIn("CEFFLO FOOD PHOTOGRAPHY", S4_10A_HTML)
        self.assertNotIn("CEFFLO FOOD PHOTOGRAPHY", S4_10B_HTML)


if __name__ == "__main__":
    unittest.main()
