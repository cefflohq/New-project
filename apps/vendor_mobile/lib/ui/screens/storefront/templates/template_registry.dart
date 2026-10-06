/// The canonical Storefront template registry.
///
/// The Storefront gallery, its filters, Template Preview and Customize all
/// render from [kStorefrontTemplates]. Storefront V1 templates follow the
/// Founder's UI references (2026-10-06) and are rendered by the public
/// storefront itself (store/templates.js) -- see `web/web_templates.dart`.
/// Order here is gallery order.
library;

import '../shared/template_definition.dart';
import 'web/web_templates.dart';

final List<StorefrontTemplateDef> kStorefrontTemplates =
    kWebStorefrontTemplates;

/// The storefront a vendor starts on before choosing a template (and the
/// one the public page uses for an unknown / retired key).
const kDefaultStorefrontTemplateId = 'care';

/// Lookup by id; unknown ids fall back to the default template so a stale
/// saved id never breaks the storefront.
StorefrontTemplateDef storefrontTemplateById(String id) =>
    kStorefrontTemplates.firstWhere(
      (t) => t.id == id,
      orElse: () => kStorefrontTemplates.firstWhere(
        (t) => t.id == kDefaultStorefrontTemplateId,
      ),
    );

/// Preferred chip order for well-known tags; any other tag follows in
/// first-seen order.
const _tagOrder = ['Food', 'Fashion', 'Beauty', 'Gifts'];

/// Filter chips, derived from the registry's tags -- a new tag on a new
/// template appears automatically.
List<String> storefrontTemplateTags() {
  final seen = <String>{};
  for (final t in kStorefrontTemplates) {
    seen.addAll(t.tags);
  }
  int rank(String tag) {
    final i = _tagOrder.indexOf(tag);
    return i < 0 ? _tagOrder.length : i;
  }

  final list = seen.toList();
  final firstSeen = {for (final (i, t) in list.indexed) t: i};
  list.sort((a, b) {
    final r = rank(a).compareTo(rank(b));
    return r != 0 ? r : firstSeen[a]!.compareTo(firstSeen[b]!);
  });
  return list;
}
