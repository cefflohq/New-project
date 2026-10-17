import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/legal_content.dart';

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

/// "By creating an account you agree to the Terms of Service and Privacy
/// Policy" under sign-up (PDPA notice at collection, Founder 2026-10-16).
/// Each link slides up the shared text, readable before signing in.
class LegalConsentText extends StatelessWidget {
  const LegalConsentText({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodySmall;
    final link = base?.copyWith(
      color: const Color(0xFF0060FE),
      fontWeight: FontWeight.w600,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: L.legalConsentLead),
          TextSpan(
            text: L.legalTerms,
            style: link,
            recognizer: TapGestureRecognizer()
              ..onTap = () => showLegalSheet(context, privacy: false),
          ),
          TextSpan(text: L.legalConsentAnd),
          TextSpan(
            text: L.legalPrivacyPolicy,
            style: link,
            recognizer: TapGestureRecognizer()
              ..onTap = () => showLegalSheet(context, privacy: true),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// The shared Privacy Policy or Terms in a bottom sheet.
Future<void> showLegalSheet(BuildContext context, {required bool privacy}) {
  final lang = L.localeName == 'ms' ? 'ms' : 'en';
  final sections = (privacy ? legalPrivacy : legalTerms)[lang]!;
  final text = Theme.of(context).textTheme;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheet) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .85,
      maxChildSize: .95,
      builder: (_, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD4D9E2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            privacy ? L.legalPrivacyPolicy : L.legalTerms,
            style: text.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${L.legalLastUpdated}: ${legalUpdated[lang]}',
            style: text.bodySmall,
          ),
          for (final (i, s) in sections.indexed) ...[
            const SizedBox(height: 16),
            Text('${i + 1}. ${s.h}', style: text.titleSmall),
            const SizedBox(height: 4),
            Text(s.p, style: text.bodyMedium?.copyWith(height: 1.6)),
          ],
        ],
      ),
    ),
  );
}

/// Whether this device has already signed in and agreed (Founder
/// 2026-10-16): first-timers tick the agreement; returning users only see
/// Google / email sign-in and Keep me logged in.
abstract final class ConsentStore {
  static const _key = 'cefflo.terms_consented';

  static Future<bool> seen() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_key) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> mark() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, true);
    } catch (_) {}
  }
}

/// "☐ I agree to the Terms of Service and Privacy Policy" for first-timers.
class ConsentCheck extends StatelessWidget {
  const ConsentCheck({
    super.key,
    required this.value,
    required this.onChanged,
    this.onDark = false,
    this.error = false,
  });
  final bool value;
  final ValueChanged<bool> onChanged;

  /// On the navy welcome backdrop: white text.
  final bool onDark;

  /// Tapped a sign-in without ticking: the box turns red.
  final bool error;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: onDark ? Colors.white : null);
    final link = base?.copyWith(
      color: onDark ? const Color(0xFFFFC93C) : const Color(0xFF0060FE),
      fontWeight: FontWeight.w600,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: const Color(0xFF0060FE),
            side: BorderSide(
              color: error
                  ? const Color(0xFFDC2626)
                  : (onDark ? Colors.white70 : const Color(0xFF98A2B3)),
              width: 1.6,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: base,
              children: [
                TextSpan(
                  text: L.legalAgreeLead,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => onChanged(!value),
                ),
                TextSpan(
                  text: L.legalTerms,
                  style: link,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => showLegalSheet(context, privacy: false),
                ),
                TextSpan(text: L.legalConsentAnd),
                TextSpan(
                  text: L.legalPrivacyPolicy,
                  style: link,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => showLegalSheet(context, privacy: true),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A new Google account confirms the agreement once, right after its first
/// sign-in. Returns false when the user declines (the caller signs out).
Future<bool> confirmConsentSheet(BuildContext context) async {
  var agree = false;
  var error = false;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, set) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              L.legalWelcomeTitle,
              style: Theme.of(sheet).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              L.legalWelcomeBody,
              style: Theme.of(sheet).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            ConsentCheck(
              value: agree,
              error: error,
              onChanged: (v) => set(() {
                agree = v;
                error = false;
              }),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFC93C),
                foregroundColor: const Color(0xFF1B1B1B),
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
              ),
              onPressed: () => agree
                  ? Navigator.of(sheet).pop(true)
                  : set(() => error = true),
              child: Text(L.legalAgreeContinue),
            ),
            TextButton(
              onPressed: () => Navigator.of(sheet).pop(false),
              child: Text(L.legalDecline),
            ),
          ],
        ),
      ),
    ),
  );
  return ok == true;
}
