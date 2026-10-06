import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
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
/// Cefflo Signature Notification Sound v1.2.0 (Founder-approved, candidate
/// M; NOTIFICATION_EVENT_MATRIX §6): `assets/sounds/cefflo_signature.mp3`,
/// the same asset as the Vendor App ("Cef-flo, Cef-flo", 0.98 s). Played
/// only when the Driver's Sound preference allows; a burst of alerts plays
/// once (1.5 s window), never loops or retries, and any audio failure is
/// dropped silently. OS push sounds come with the later push integration.
class NotificationAlertEffects {
  const NotificationAlertEffects();

  static const signatureAsset = 'sounds/cefflo_signature.mp3';
  static const burstWindow = Duration(milliseconds: 1500);
  static AudioPlayer? _player;
  static DateTime? _lastPlayed;

  void play({required bool sound, required bool urgent}) {
    if (sound) playSignature();
    // Urgent run events (server priority) vibrate; normal ones do not.
    if (urgent) HapticFeedback.heavyImpact();
  }

  /// True when a sound may start now (outside the burst window); records it.
  @visibleForTesting
  static bool claimPlaySlot([DateTime? now]) {
    final t = now ?? DateTime.now();
    final last = _lastPlayed;
    if (last != null && t.difference(last) < burstWindow) return false;
    _lastPlayed = t;
    return true;
  }

  @visibleForTesting
  static void resetPlaySlot() => _lastPlayed = null;

  Future<void> playSignature() async {
    if (!claimPlaySlot()) return;
    try {
      final player = _player ??= AudioPlayer()
        ..setReleaseMode(ReleaseMode.stop);
      await player.stop();
      await player.play(AssetSource(signatureAsset), volume: 1.0);
    } catch (_) {
      // Audio unavailable or blocked: the banner still shows; never retried.
    }
  }
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
