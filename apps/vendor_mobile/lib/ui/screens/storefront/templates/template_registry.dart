/// The canonical Storefront template registry.
///
/// The Storefront gallery, its filters, Template Preview and Customize all
/// render from [kStorefrontTemplates]. Adding a template is: create
/// `templates/<id>/`, then add its definition to this list -- see
/// `STOREFRONT_TEMPLATE_GUIDE.md`. Order here is gallery order.
library;

import '../shared/template_definition.dart';
import 'arena/arena_template.dart';
import 'feast/feast_template.dart';
import 'market/market_template.dart';
import 'ritual/ritual_template.dart';
import 'stride/stride_template.dart';

final List<StorefrontTemplateDef> kStorefrontTemplates = [
  arenaTemplate,
  strideTemplate,
  ritualTemplate,
  marketTemplate,
  feastTemplate,
];

/// The storefront a vendor starts on before choosing a template.
const kDefaultStorefrontTemplateId = 'arena';

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
