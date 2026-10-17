import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/vendor_repository.dart';
import '../async_view.dart';
import '../shell.dart' show PageBody;
import '../widgets.dart';

import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

/// V-41 Delivery settings (Founder 2026-10-17): how many orders the planner
/// puts in one run (set_business_run_size, used by propose_delivery_plan).
/// Service area and zones keep their own screens.
class DeliverySettingsScreen extends StatefulWidget {
  const DeliverySettingsScreen({super.key});

  @override
  State<DeliverySettingsScreen> createState() => _DeliverySettingsScreenState();
}

class _DeliverySettingsScreenState extends State<DeliverySettingsScreen> {
  int? _min, _max;
  bool _busy = false;

  Future<void> _save() async {
    final app = AppScope.read(context);
    setState(() => _busy = true);
    try {
      await app.repo.setRunSize(app.business!.id, _min!, _max!);
      if (!mounted) return;
      showCefToast(context, L.dsSaved);
      app.back();
    } on RepositoryError catch (e) {
      if (mounted) showCefToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _stepper(
    String label,
    int value,
    int lo,
    int hi,
    ValueChanged<int> set,
  ) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(label, style: text.bodyLarge)),
        IconButton.outlined(
          onPressed: value > lo ? () => set(value - 1) : null,
          icon: const Icon(LucideIcons.minus, size: 18),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: text.titleLarge,
          ),
        ),
        IconButton.outlined(
          onPressed: value < hi ? () => set(value + 1) : null,
          icon: const Icon(LucideIcons.plus, size: 18),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    return AsyncView<(int, int)>(
      key: ValueKey('run-size-${app.business?.id}'),
      load: () => app.repo.runSize(app.business!.id),
      builder: (context, saved, reload) {
        final min = _min ??= saved.$1;
        final max = _max ??= saved.$2;
        final dirty = min != saved.$1 || max != saved.$2;
        return PageBody(
          bottom: CefButton(
            L.saveChanges,
            busy: _busy,
            onTap: dirty && !_busy ? _save : null,
          ),
          children: [
            SectionHeading(
              L.dsRunSize,
              icon: LucideIcons.route,
              subtitle: L.dsLead,
            ),
            const SizedBox(height: Gap.md),
            _stepper(L.dsMin, min, 1, max, (v) => setState(() => _min = v)),
            const SizedBox(height: Gap.sm),
            _stepper(L.dsMax, max, min, 50, (v) => setState(() => _max = v)),
            const SizedBox(height: Gap.md),
            Text(L.dsHint, style: text.bodySmall),
          ],
        );
      },
    );
  }
}
