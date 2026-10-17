import 'package:cefflo_rider_mobile/core/theme.dart';
import 'package:cefflo_rider_mobile/l10n/l10n.dart';
import 'package:cefflo_rider_mobile/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A screen whose body ends in an empty state shows it centred in the
/// space under the screen's own controls, not pinned under the header.
void main() {
  setUp(() => applyUiLocale(const Locale('en')));

  testWidgets('trailing empty state is centred in the sheet', (t) async {
    await t.binding.setSurfaceSize(const Size(400, 800));
    await t.pumpWidget(
      MaterialApp(
        theme: buildRiderTheme(),
        home: Scaffold(
          body: CeffloNavySheetScaffold(
            header: const SizedBox(height: 100),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                SizedBox(height: 40, child: Text('tabs')),
                StateBlock.empty('No runs yet'),
              ],
            ),
          ),
        ),
      ),
    );
    final sheetTop = 100.0 + 40;
    final y = t.getCenter(find.text('No runs yet')).dy;
    // Well below the controls, around the middle of the space left.
    expect(y, greaterThan(sheetTop + 200));
    expect(y, closeTo((sheetTop + 800) / 2, 60));
  });
}
