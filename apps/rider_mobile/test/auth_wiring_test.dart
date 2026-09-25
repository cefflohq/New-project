import 'package:cefflo_rider_mobile/core/app_state.dart';
import 'package:cefflo_rider_mobile/core/theme.dart';
import 'package:cefflo_rider_mobile/data/rider_repository.dart';
import 'package:cefflo_rider_mobile/ui/screens/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(AppState app, Widget child) => AppScope(
    state: app,
    child: MaterialApp(theme: buildRiderTheme(), home: child),
  );

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(393 * 3, 852 * 3);
    view.devicePixelRatio = 3;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });
  });

  test('auth errors map from backend codes, not provider prose', () {
    expect(
      driverAuthErrorText(
        RepositoryError('provider wording', code: 'invalid_credentials'),
      ),
      'Email or password is incorrect. Try again.',
    );
    expect(
      driverAuthErrorText(
        RepositoryError('provider wording', code: 'over_request_rate_limit'),
      ),
      'Too many attempts. Please wait before trying again.',
    );
    expect(
      driverAuthErrorText(RepositoryError('ClientException: Failed to fetch')),
      'Unable to connect. Check your connection and try again.',
    );
  });

  testWidgets('prototype sign-in remains local and usable', (tester) async {
    final app = AppState(RiderRepository.demo());
    var authenticated = false;
    await tester.pumpWidget(
      host(
        app,
        EmailSignInScreen(
          onBack: () {},
          onSignIn: () => authenticated = true,
          onForgotPassword: () {},
          onSignUp: () {},
        ),
      ),
    );

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(authenticated, isTrue);
  });
}
