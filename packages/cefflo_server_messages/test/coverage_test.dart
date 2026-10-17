import 'dart:io';

import 'package:cefflo_server_messages/cefflo_server_messages.dart';
import 'package:test/test.dart';

/// Every message the migrations raise has friendly EN and BM text.
void main() {
  final raised = <String>{
    for (final f in Directory('../../supabase/migrations').listSync())
      if (f is File && f.path.endsWith('.sql'))
        for (final m in RegExp(
          r"raise exception '([^']+)'",
          caseSensitive: false,
        ).allMatches(f.readAsStringSync()))
          m.group(1)!,
  }..remove('%'); // a message built at runtime: the generic fallback

  test('migrations were found', () => expect(raised.length, greaterThan(100)));

  for (final raw in raised) {
    test(raw, () {
      final sample = raw.replaceAll('%', '3');
      expect(knownServerMessage(sample, 'en'), isNotNull, reason: raw);
      expect(knownServerMessage(sample, 'ms'), isNotNull, reason: raw);
    });
  }

  test('unknown text falls back, per language', () {
    expect(serverMessage('boom', 'en'), fallback.en);
    expect(serverMessage('boom', 'ms'), fallback.ms);
  });

  test('placeholders and the more specific pattern win', () {
    expect(
      serverMessage('invalid transition picked_up -> issue', 'en'),
      'This order can no longer be reported.',
    );
    expect(
      serverMessage('zone name already exists', 'ms'),
      'Zon dengan nama ini sudah wujud.',
    );
  });
}
