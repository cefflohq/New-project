// Founder preview harness for the 6-digit verification screen. Not shipped:
// lives in tool/ and is built only with -t for screenshots.
import 'package:flutter/material.dart';
import 'package:cefflo_rider_mobile/core/app_state.dart';
import 'package:cefflo_rider_mobile/core/theme.dart';
import 'package:cefflo_rider_mobile/data/rider_repository.dart';
import 'package:cefflo_rider_mobile/ui/screens/auth.dart';

void main() {
  final q = Uri.base.queryParameters;
  final hang = q['hang'] == '1';
  runApp(
    AppScope(
      state: AppState(RiderRepository.demo()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildRiderTheme(),
        home: VerifyEmailCodeScreen(
          email: 'owner@kopikita.my',
          resendCooldown: int.tryParse(q['cooldown'] ?? '') ?? 60,
          title: q['purpose'] == 'recovery' ? 'Reset your password' : null,
          showVerifiedState: q['purpose'] != 'recovery',
          onVerify: (code) async {
            if (hang) return Future<void>.delayed(const Duration(days: 1));
            await Future<void>.delayed(const Duration(milliseconds: 300));
            if (code == '000000') throw const OtpFailure(OtpFailureKind.expired);
            if (code != '123456') throw const OtpFailure(OtpFailureKind.incorrect);
          },
          onResend: () => Future<void>.delayed(const Duration(milliseconds: 300)),
          onContinue: () => debugPrint('continue'),
          onBack: () {},
          onBackToSignIn: () {},
        ),
      ),
    ),
  );
}
