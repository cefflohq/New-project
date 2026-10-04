import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// "Keep me logged in" (Founder, 2026-10-04; same rule as Vendor Web and
/// FOUNDR): off means the session ends with this app session, so the next
/// launch starts signed out.
const _key = 'cefflo.keep_signed_in';

Future<void> saveKeepSignedIn(bool keep) async {
  try {
    await (await SharedPreferences.getInstance()).setBool(_key, keep);
  } catch (_) {}
}

/// Called once at launch, before the app reads the session.
Future<void> endSessionIfNotKept(SupabaseClient db) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_key) == false && db.auth.currentSession != null) {
      await db.auth.signOut();
    }
  } catch (_) {}
}

/// A7: 16px circle, thin navy tick on Cefflo mustard, label beside it.
class KeepLoggedInCheck extends StatelessWidget {
  const KeepLoggedInCheck({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.color = const Color(0xFF101C33),
  });
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    checked: value,
    label: label,
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? const Color(0xFFFEC819) : Colors.transparent,
                border: Border.all(
                  color: value
                      ? const Color(0xFFFEC819)
                      : const Color(0xFFC5CEDC),
                  width: 1.4,
                ),
              ),
              child: value
                  ? const Icon(
                      Icons.check_rounded,
                      size: 11,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
