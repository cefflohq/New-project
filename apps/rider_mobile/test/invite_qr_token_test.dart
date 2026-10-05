import 'package:cefflo_rider_mobile/ui/screens/onboarding.dart';
import 'package:flutter_test/flutter_test.dart';

// A scanned invite QR holds the exact invite URL; the Driver app must read
// the same token from it as from an opened link (one join path, no QR path).
void main() {
  const token = '4326ade037113bf141fce3847593fd631a1fd8d28bbfb68c';
  test('invite URL from a QR yields the link token', () {
    expect(
      openInviteTokenFrom('https://invite.cefflo.com/?link=$token'),
      token,
    );
    expect(
      openInviteTokenFrom(
        'https://cefflo-staging-invite.pages.dev/invite/?link=$token',
      ),
      token,
    );
  });
  test('app link (?join=) and a bare token are accepted', () {
    expect(openInviteTokenFrom('https://app.example/?join=$token'), token);
    expect(openInviteTokenFrom('  $token  '), token);
  });
  test('anything else is rejected', () {
    expect(openInviteTokenFrom('https://invite.cefflo.com/?link=xyz'), isNull);
    expect(openInviteTokenFrom('${token}00'), isNull);
    expect(openInviteTokenFrom('https://evil.example/'), isNull);
  });
}
