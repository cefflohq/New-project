# CEFFLO Public Website — homepage draft

Independent Public Website workstream (see
`docs/cefflo/` Gate 1 spec: CEFFLO_PUBLIC_WEBSITE_VISUAL_SPEC.md, §28–§29).

- `index.html` — self-contained homepage (no external assets beyond Google
  Fonts). Structure follows the Founder-supplied mobile-app template
  reference; copy is drawn from canonical product truth.
- Product visuals: real Vendor Mobile (Flutter) screens rendered from the
  demo repository at `claude/vendor-mobile-ui-normalization-3wvl4d`
  (7854aeb), embedded as WebP. Driver and customer-tracking visuals are
  labelled previews.
- No pricing, testimonials, metrics or logos are included (spec §20).
- Not wired into `scripts/build-static.mjs` or `vercel.json`; deployment
  routing is a separate Founder-gated step.
