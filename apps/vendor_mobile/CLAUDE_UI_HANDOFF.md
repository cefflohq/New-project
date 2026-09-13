# Cefflo Vendor Mobile UI — Claude Handoff

## Current status

- Surface: Vendor Flutter mobile UI prototype, rendered as Flutter Web for review.
- Implementation branch: `claude/experience-system-implementation`.
- Current scope is UI-only. Do not connect backend, live authentication, billing, support submission, or production services during the polish pass.
- Do not merge to a protected branch and do not deploy to Production.

## Authorities and references

1. Founder-approved Vendor Flutter UI images V1–V60 are the visual source of truth. Match their mobile hierarchy, spacing, typography, colors, navigation, card treatment, and interaction states as closely as practical at a 9:16 phone viewport.
2. `CEFFLO_VENDOR_FLUTTER_FINAL_UI_IMPLEMENTATION_MASTER_v1.1.md` supplies Vendor mobile capability/product context.
3. `CEFFLO_VENDOR_WEB_PWA_DESKTOP_NATIVE_CONVERSION_MASTER_v1.1.md` is the primary authority only for the later desktop/PWA conversion. Never use it as a mobile layout template.
4. Preserve canonical Cefflo brand assets already in the Flutter app.

The two Master files and original Founder reference images were supplied outside this repository. The Founder should attach them directly to the Claude task so image quality and full document context are preserved.

## Implemented prototype coverage

- Auth-first demo flow and authentication-state visuals.
- Global navigation: Today, Orders, Products, Customers, More.
- Today dashboard, Orders list/detail/create/edit, Zones, Riders, Products, Customers.
- Business and settings surfaces V37–V49.
- Subscription, plan selection, checkout, payment success, subscription details, support, FAQ, contact, privacy, terms, and About surfaces V50–V60.
- Demo/static data and local navigation are intentional. No prototype CTA may create a real payment or external request.

## Founder UI constraints

- Keep output mobile-first and 9:16.
- No visual improvisation where a Founder reference exists.
- Keep layouts minimalist, compact, and operationally clear.
- Use the approved navy/blue Cefflo visual language and yellow primary CTA treatment shown in the references.
- Keep logo and button sizing consistent across screens.
- Auth uses the blue background and canonical blurred-logo direction already implemented.
- Error copy is red text only; do not introduce pale error badges, icon badges, or light-grey status pills.
- Preserve the current bottom-navigation decision. Zones and Riders are accessed through More.

## Validation command

Run from `apps/vendor_mobile`:

```bash
flutter analyze
flutter build web --no-wasm-dry-run --dart-define=CEFFLO_UI_PROTOTYPE=true
```

Before reporting completion, visually inspect at a real phone viewport and compare screen-by-screen with the Founder references. Report mismatches honestly rather than claiming 1:1 prematurely.

## Known boundaries

- The current quick Cloudflare preview is temporary and is not staging.
- The current state is a local UI prototype with a temporary remote preview.
- Backend/auth/payment integrations are explicitly deferred.
- `apps/vendor_mobile/android/` and `apps/vendor_auth_prototype/` are unrelated untracked local directories and are intentionally excluded from this UI handoff commit.
