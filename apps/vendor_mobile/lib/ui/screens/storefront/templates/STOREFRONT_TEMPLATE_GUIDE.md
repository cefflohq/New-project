# Storefront template guide

How to add a Storefront template to Vendor Mobile. If you follow these steps, the new template appears in Explore Templates, Template Preview and Customize without any change to those screens.

## Model

- A **template** is a reusable layout. It owns only presentation: its renderer, its default theme, the background treatments it offers, and which customizations it allows.
- **Vendor data** is injected at render time through `StorefrontRenderData`: the business name, products, categories and prices. Templates never store it, and never ship their own demo products, names or slogans.
- **Vendor customization** is kept per template id as `StorefrontBranding`: brand colour, background, hero image, store name and tagline. Customize edits a draft of it, and `AppState.applyStorefront` saves it.
- **Tags** only help vendors discover templates. They never restrict which vendor may use a template.

## Layout

```
lib/ui/screens/storefront/
  storefront_screens.dart      V-31 Storefront, X-02 Template Preview, V-32 View storefront
  storefront_customize.dart    V-33 Customize (capability-driven controls)
  shared/                      used by every template, owned by none
    template_definition.dart   StorefrontTemplateDef, StorefrontCapability, backgrounds
    storefront_surface.dart    StorefrontSurface / StorefrontMiniature / catalogue loader
    storefront_theme.dart      StorefrontThemeTokens (brand, background, hero image)
    storefront_common.dart     cart, checkout, product image, back bar, chips
    product_art.dart           neutral product illustrations
  templates/
    template_registry.dart     THE list of templates (gallery order)
    <id>/<id>_template.dart    the template's definition (metadata + defaults)
    <id>/<id>_renderer.dart    the template's layout
    <id>/assets/               optional: the template's own images
```

## Adding a template (example: `harbour`)

1. **Folder.** Create `templates/harbour/`.

2. **Renderer.** Create `templates/harbour/harbour_renderer.dart` with a widget that takes `businessName`, `items`, `categories` and `tokens` (copy the constructor from any existing renderer).
   - Paint the page with `tokens.background`.
   - Use `tokens.primary`, `tokens.secondary` and `tokens.onPrimary` for accents.
   - Headlines come from `tokens.headline(fallback)`; the fallback is the vendor's tagline or generic UI copy, never a brand slogan.
   - Show products with `StorefrontProductImage(item: ...)`.
   - Show prices as `RM`.
   - If the template has a hero or banner, pass its decoration through `tokens.withHeroImage(...)`.
   - Reuse `StorefrontCartView`, `StorefrontCheckoutView` and `StorefrontOrderCreatedView` from `shared/storefront_common.dart` for the cart → checkout → order flow.
   - Lay it out for a 390 × 800 phone. Any row with a variable number of entries (categories, variants) must scroll or wrap.

3. **Definition.** Create `templates/harbour/harbour_template.dart`:

   ```dart
   final harbourTemplate = StorefrontTemplateDef(
     id: 'harbour',                 // stable forever; never shown to vendors
     name: 'Harbour',               // display name; safe to rename
     style: 'Coastal Showcase',     // one line under the name
     description: '...',            // Template Preview copy
     highlights: const ['...'],     // Template Preview check list
     tags: const ['Food', 'Gifts'], // discovery filters
     capabilities: const {
       StorefrontCapability.brandColour,
       StorefrontCapability.background, // only if you paint tokens.background
       StorefrontCapability.heroImage,  // only if you use tokens.withHeroImage
       StorefrontCapability.identity,
     },
     defaults: const StorefrontBranding(
       primary: Color(0xFF0E4D64),
       secondary: Color(0xFFF2B134),
       mode: BrandColorMode.solid,
       font: StorefrontFontTreatment.modern,
     ),                             // leave storeName/tagline empty
     backgrounds: kLightBackgrounds, // or your own list; first = default
     renderer: (d) => HarbourPreview(
       businessName: d.businessName,
       items: d.items,
       categories: d.categories,
       tokens: d.tokens,
     ),
     // previewAsset: 'lib/.../harbour/assets/preview.png', // optional
     // availability: TemplateAvailability.comingSoon,       // optional
   );
   ```

4. **Register.** Import the definition in `templates/template_registry.dart` and add `harbourTemplate` to `kStorefrontTemplates`, at the position you want it in the gallery.

That is all. Explore Templates, its filter chips (built from `tags`), Template Preview and Customize (built from `capabilities`) pick the template up automatically. Do not add `if (id == 'harbour')` anywhere.

## Details

- **Capabilities.** Declare only what the renderer really honours. Customize shows exactly the declared controls, in a fixed order, and nothing disabled.
- **New filter tag.** Just use it in `tags`. Chips are derived from the registry in the order they are first seen.
- **Thumbnail.** By default the gallery draws a live miniature of your renderer with the vendor's own products. That is the preferred thumbnail. Set `previewAsset` only if a static image is really needed. Put it in `templates/<id>/assets/` and list that folder under `flutter: assets:` in `pubspec.yaml`.
- **Theme defaults.** `defaults` is the template's own palette and type treatment, and it is also what "Reset to template defaults" restores. `backgrounds.first` is the default page colour.
- **Retiring a template.** Set `availability: TemplateAvailability.comingSoon` to hide it from selection while keeping the id valid. Never reuse an id. An unknown saved id falls back to `kDefaultStorefrontTemplateId`.

## Testing

`test/storefront_test.dart` is registry-driven. Your template is automatically:

- checked for a complete definition (unique id, name, style, tags, highlights, empty store name, backgrounds when required);
- rendered at 390 × 800 with vendor data, failing on any overflow or layout error;
- listed in the Explore Templates gallery test.

Run `flutter analyze` and `flutter test`. Then check it visually: open Storefront, tap the new tile, go to Use This Template, change the brand colour and background, Save, and confirm the hero shows the new template with the same products.
