import 'package:flutter/services.dart';

import '../data/models.dart';

import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

/// Events whose "sound" column is yes in the notification event matrix
/// (docs/cefflo/NOTIFICATION_EVENT_MATRIX.md §3).
const _soundEvents = {
  'order.new_customer',
  'delivery.issue',
  'run.declined',
  'rider.joined',
  'platform.announcement',
};

bool notificationPlaysSound(String? eventKey) =>
    eventKey == null || _soundEvents.contains(eventKey);

/// Sound and vibration for a foreground alert.
///
/// Cefflo Signature Notification Sound contract (§6): the approved asset
/// ships as `assets/sounds/cefflo_signature.mp3` (in-app) plus
/// `res/raw/cefflo_signature.ogg` / `cefflo_signature.caf` for the OS
/// notification channel once push exists. It is not approved yet, so this
/// deliberately plays only the platform's own alert sound -- PLACEHOLDER,
/// not the Cefflo sound -- and never a bundled random beep. When the asset
/// is approved, replace [_playSound] with the asset player; nothing else
/// changes.
class NotificationAlertEffects {
  const NotificationAlertEffects();

  void play({required bool sound, required bool urgent}) {
    if (sound) _playSound();
    // Urgent operational events vibrate briefly (matrix "Vibration" column).
    if (urgent) HapticFeedback.mediumImpact();
  }

  // PLACEHOLDER until the Founder approves the signature asset.
  void _playSound() => SystemSound.play(SystemSoundType.alert);
}

/// Localised copy for known event keys; the server's English copy is the
/// fallback and is always used for broadcasts and for a rider's own note.
({String title, String body}) notificationCopy(AppNotification n) {
  final ref = (n.params['ref'] ?? '').toString();
  return switch (n.eventKey) {
    'order.new_customer' => (
      title: L.ntNewCustomerOrder(ref).trim(),
      body: L.ntNewCustomerOrderBody,
    ),
    'delivery.issue' => (title: L.ntDeliveryIssue(ref).trim(), body: n.body),
    'run.declined' => (title: L.ntRunDeclined, body: L.ntRunDeclinedBody),
    'rider.joined' => (title: L.ntRiderJoined, body: L.ntRiderJoinedBody),
    'run.completed' => (title: L.ntRunCompleted, body: L.ntRunCompletedBody),
    _ => (title: n.title, body: n.body),
  };
}

/// "just now" / "5 min ago" / "3 h ago" / date, for live rows.
String notificationWhen(AppNotification n) {
  final at = n.createdAt;
  if (at == null) return n.timeLabel;
  final d = DateTime.now().difference(at);
  if (d.inMinutes < 1) return L.ntJustNow;
  if (d.inMinutes < 60) return L.ntMinutesAgo(d.inMinutes);
  if (d.inHours < 24) return L.ntHoursAgo(d.inHours);
  final l = at.toLocal();
  return '${l.day}/${l.month}/${l.year}';
}
