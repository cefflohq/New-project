import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
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
/// Cefflo Signature Notification Sound (NOTIFICATION_EVENT_MATRIX §6),
/// v1: `assets/sounds/cefflo_signature.mp3` (original synthesis, source
/// `shared/sounds/cefflo-signature.wav`, 0.95 s, peak -1 dBFS). Played only
/// for foreground alerts the user's Sound preference allows; a burst of
/// events plays once (1.5 s window), never loops or retries, and any audio
/// failure (e.g. a browser blocking audio before interaction) is dropped
/// silently. OS push sounds come with the later push integration.
class NotificationAlertEffects {
  const NotificationAlertEffects();

  static const signatureAsset = 'sounds/cefflo_signature.mp3';
  static const burstWindow = Duration(milliseconds: 1500);
  static AudioPlayer? _player;
  static DateTime? _lastPlayed;

  void play({required bool sound, required bool urgent}) {
    if (sound) playSignature();
    // Urgent operational events vibrate briefly (matrix "Vibration" column).
    if (urgent) HapticFeedback.mediumImpact();
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
