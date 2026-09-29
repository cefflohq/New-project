import 'package:flutter/services.dart';

import '../data/driver_models.dart';

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

/// Events whose "sound" column is yes in the notification event matrix
/// (docs/cefflo/NOTIFICATION_EVENT_MATRIX.md §3).
const _soundEvents = {
  'run.assigned',
  'run.removed',
  'rider.approved',
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
    // Urgent run events (server priority) vibrate; normal ones do not.
    if (urgent) HapticFeedback.heavyImpact();
  }

  // PLACEHOLDER until the Founder approves the signature asset.
  void _playSound() => SystemSound.play(SystemSoundType.alert);
}

/// Localised copy for known event keys; the server's English copy is the
/// fallback and is always used for broadcasts.
({String title, String body}) notificationCopy(DriverNotification n) {
  final biz = (n.params['business'] ?? '').toString();
  final orders = n.params['orders'];
  return switch (n.eventKey) {
    'run.assigned' when orders is num => (
      title: biz.isEmpty ? L.ntNewRun : L.ntNewRunFrom(biz),
      body: L.ntRunOrdersAssigned(orders.toInt()),
    ),
    'run.assigned' => (title: L.ntRunReassigned, body: L.ntRunReassignedBody),
    'run.removed' => (title: L.ntRunRemoved, body: L.ntRunRemovedBody),
    'rider.approved' => (title: L.ntApproved, body: L.ntApprovedBody),
    'rider.deactivated' => (
      title: L.ntAccessChanged,
      body: L.ntAccessChangedBody,
    ),
    _ => (title: n.title, body: n.body),
  };
}

/// "just now" / "5 min ago" / "3 h ago" / date, for live rows.
String notificationWhen(DriverNotification n) {
  final at = n.createdAt;
  if (at == null) return n.timeLabel;
  final d = DateTime.now().difference(at);
  if (d.inMinutes < 1) return L.ntJustNow;
  if (d.inMinutes < 60) return L.ntMinutesAgo(d.inMinutes);
  if (d.inHours < 24) return L.ntHoursAgo(d.inHours);
  final l = at.toLocal();
  return '${l.day}/${l.month}/${l.year}';
}
