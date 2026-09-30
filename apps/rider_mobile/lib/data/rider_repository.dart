import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'driver_models.dart';
import 'models.dart';

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

/// Thrown for any backend failure the UI is expected to surface truthfully.
/// Native auth callback (password recovery link). Registered in the
/// Android manifest and iOS Info.plist, and must be in the Supabase Auth
/// redirect allowlist for the environment.
const nativeAuthRedirectUrl = 'cefflo-driver://auth-callback';

/// Where emailed auth links (recovery, sign-up confirmation) return to.
/// Native builds use the app's deep link; a web build returns to the page
/// it is served from, since a browser cannot open the custom scheme.
String get authRedirectUrl =>
    kIsWeb ? webAuthRedirectUrl(Uri.base) : nativeAuthRedirectUrl;

/// The current page without any auth callback parameters or fragment. Only
/// the Sign-In variant (`access`) is kept, so an Operator or Helper returns
/// to the same variant. Must match a Supabase Auth Redirect URL entry.
String webAuthRedirectUrl(Uri base) {
  final access = base.queryParameters['access'];
  return Uri(
    scheme: base.scheme,
    host: base.host,
    port: base.hasPort ? base.port : null,
    path: base.path.isEmpty ? '/' : base.path,
    queryParameters: access == null ? null : {'access': access},
  ).toString();
}

class RepositoryError implements Exception {
  RepositoryError(this.message, {this.isMissingContract = false, this.code});
  final String message;

  /// True when the canonical RPC does not exist on the connected backend.
  /// The UI must show a blocked state instead of pretending the action worked.
  final bool isMissingContract;
  final String? code;

  @override
  String toString() => message;
}

/// All Rider reads/writes go through the canonical backend -- the exact same
/// tables/RPCs the live Rider PWA (rider/backend.js) already uses in
/// production, so this client can never invent a different contract. Nothing
/// in this class computes eligibility, sequencing, capacity or ETA locally;
/// the server owns those decisions (docs/cefflo/sot/
/// 08_RIDER_FLUTTER_33_SCREEN_MASTER.md S2).
class RiderRepository {
  RiderRepository(SupabaseClient db) : _client = db, isDemo = false;

  /// Prototype/preview boot mode: no Supabase client, no credentials, and
  /// every backend call short-circuits. The UI reads its content from
  /// `demo_data.dart` fixtures instead. Ported from Vendor Mobile's
  /// `VendorRepository.demo()` so this app has a runnable, screenshot-able
  /// preview build (`--dart-define=CEFFLO_UI_PROTOTYPE=true`).
  RiderRepository.demo() : _client = null, isDemo = true;

  final SupabaseClient? _client;
  final bool isDemo;

  SupabaseClient get _db {
    final db = _client;
    if (db == null) {
      throw RepositoryError(
        'This build runs in UI prototype mode and is not connected to a backend.',
      );
    }
    return db;
  }

  User? get currentUser => isDemo ? null : _db.auth.currentUser;
  Stream<AuthState> get authChanges =>
      isDemo ? const Stream<AuthState>.empty() : _db.auth.onAuthStateChange;

  Future<void> signInWithPassword(String identifier, String password) => _run(
    () => _db.auth.signInWithPassword(
      email: identifier.contains('@') ? identifier.trim() : null,
      phone: identifier.contains('@') ? null : identifier.trim(),
      password: password,
    ),
  );

  Future<bool> signUpWithPassword({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    final response = await _run(
      () => _db.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: authRedirectUrl,
        data: {
          if (fullName != null && fullName.trim().isNotEmpty)
            'full_name': fullName.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        },
      ),
    );
    return response.session == null;
  }

  /// Driver Verify Email (D04.1) and the invalid-link screen (D09): a new
  /// sign-up confirmation email, returning to the same auth callback.
  Future<void> resendSignUpVerification(String email) => _run(
    () => _db.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: authRedirectUrl,
    ),
  );

  Future<void> sendPasswordReset(String email) => _run(
    () => _db.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: authRedirectUrl,
    ),
  );

  /// 6-digit code from the sign-up email (Supabase Email OTP). On success
  /// GoTrue confirms the address and returns a session.
  Future<void> verifySignUpCode({
    required String email,
    required String code,
  }) => _run(
    () => _db.auth.verifyOTP(
      email: email.trim(),
      token: code,
      type: OtpType.signup,
    ),
  );

  /// 6-digit code from the password-recovery email: a recovery session for
  /// Set New Password.
  Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  }) => _run(
    () => _db.auth.verifyOTP(
      email: email.trim(),
      token: code,
      type: OtpType.recovery,
    ),
  );

  Future<void> updatePassword(String password) =>
      _run(() => _db.auth.updateUser(UserAttributes(password: password)));

  /// Per-user UI language (en / ms), kept in the user's own auth metadata.
  /// Best-effort: the device choice still applies if this fails.
  Future<void> saveUiLocale(String code) async {
    if (isDemo) return;
    try {
      await _db.auth.updateUser(UserAttributes(data: {'ui_locale': code}));
    } catch (_) {}
  }

  Future<void> signOut() => _run(() => _db.auth.signOut());

  // -------------------------------------------------------- identity/scope

  /// Every `riders` row for the signed-in identity, unfiltered by status --
  /// this is the one read that must not be scoped to "the active
  /// relationship" since it's how a relationship gets selected in the first
  /// place. Mirrors rider/backend.js's classifyRiderRelationships() exactly.
  Future<List<RiderRelationship>> myRiderRelationships() async {
    final user = currentUser;
    if (user == null) throw RepositoryError(L.notSigned);
    final rows = await _run(
      // Ordered, so a multi-business Driver always resolves the same first
      // active relationship until explicit selection exists (D-63).
      () => _db
          .from('riders')
          .select()
          .eq('auth_user_id', user.id)
          .order('created_at', ascending: true),
    );
    final relationships = _rows(rows).map(RiderRelationship.fromRow).toList();
    final businessIds = relationships.map((r) => r.businessId).toSet();
    if (businessIds.isEmpty) return relationships;
    final businessRows = await _run(
      () => _db
          .from('businesses')
          .select('id,name,address')
          .inFilter('id', businessIds.toList()),
    );
    final nameById = {
      for (final b in _rows(businessRows))
        b['id'].toString(): (b['name'] ?? '').toString(),
    };
    final addressById = {
      for (final b in _rows(businessRows))
        b['id'].toString(): b['address']?.toString(),
    };
    return relationships
        .map(
          (r) => RiderRelationship.fromRow(
            {
              'id': r.id,
              'business_id': r.businessId,
              'status': r.status,
              'name': r.name,
              'phone': r.phone,
              'vehicle_type': r.vehicleType,
              'vehicle_plate': r.plate,
            },
            businessName: nameById[r.businessId],
            businessAddress: addressById[r.businessId],
          ),
        )
        .toList();
  }

  // ----------------------------------------------------------------- reads

  /// Explicitly scoped to one active Rider relationship -- RLS remains an
  /// identity-wide ownership ceiling only, not active-context workflow
  /// scoping (same reasoning the PWA's orders() carries). Nested embed
  /// (orders -> delivery_stops -> rider_assignments) matches the PWA's read
  /// exactly, so no local assumption is ever made about assignment status.
  Future<List<RiderOrder>> myOrders(String riderId) async {
    final rows = await _run(
      () => _db
          .from('orders')
          .select(
            '*,delivery_stops(id,sequence,sequence_locked_at,assignment_id,rider_assignments(status,accepted_at))',
          )
          .eq('assigned_rider_id', riderId)
          .order('created_at'),
    );
    return _rows(rows).map(RiderOrder.fromRow).toList();
  }

  Future<List<DeliverySession>> sessions(String businessId) async {
    final rows = await _run(
      () => _db
          .from('delivery_sessions')
          .select('id,name')
          .eq('business_id', businessId),
    );
    return _rows(rows).map(DeliverySession.fromRow).toList();
  }

  // --------------------------------------------------------- run lifecycle

  Future<void> acceptAssignment({
    required String riderId,
    required String orderId,
  }) => _run(
    () => _db.rpc(
      'accept_assignment',
      params: {'p_rider_id': riderId, 'p_order_id': orderId},
    ),
  );

  Future<void> declineAssignment({
    required String riderId,
    required String orderId,
  }) => _run(
    () => _db.rpc(
      'decline_assignment',
      params: {'p_rider_id': riderId, 'p_order_id': orderId},
    ),
  );

  Future<void> acceptRun({
    required String riderId,
    required String sessionId,
  }) => _run(
    () => _db.rpc(
      'accept_run',
      params: {'p_rider_id': riderId, 'p_delivery_session_id': sessionId},
    ),
  );

  Future<void> declineRun({
    required String riderId,
    required String sessionId,
  }) => _run(
    () => _db.rpc(
      'decline_run',
      params: {'p_rider_id': riderId, 'p_delivery_session_id': sessionId},
    ),
  );

  /// R-09 Plan Route: persist the Rider's reorder of permitted stops.
  /// Cefflo does not claim route-optimization intelligence -- this is local
  /// knowledge, backend remains canonical for allowed sequence changes.
  Future<void> saveRunSequence({
    required String riderId,
    required String sessionId,
    required List<String> orderedOrderIds,
  }) => _run(
    () => _db.rpc(
      'save_run_sequence',
      params: {
        'p_rider_id': riderId,
        'p_delivery_session_id': sessionId,
        'p_ordered_order_ids': orderedOrderIds,
      },
    ),
  );

  /// SLIDE Start Pickup (R-10).
  Future<void> startPickupRun({
    required String riderId,
    required String sessionId,
  }) => _run(
    () => _db.rpc(
      'start_pickup_run',
      params: {'p_rider_id': riderId, 'p_delivery_session_id': sessionId},
    ),
  );

  /// Phase 2B.4: the only rider-location write path (F2-08, unchanged).
  Future<void> recordLocation({
    required String riderId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? heading,
    double? speed,
  }) => _run(
    () => _db.rpc(
      'record_rider_location',
      params: {
        'p_rider_id': riderId,
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_accuracy': accuracy,
        'p_heading': heading,
        'p_speed': speed,
      },
    ),
  );

  /// Phase 2B.4: presence keys for this rider's own trackable orders.
  Future<List<({String orderId, String topic, String key})>> liveKeys(
    String riderId,
  ) async {
    final rows = await _run(
      () => _db.rpc('rider_live_keys', params: {'p_rider_id': riderId}),
    );
    return [
      for (final r in (rows as List).cast<Map>())
        (
          orderId: r['order_id'].toString(),
          topic: 'trk:${r['live_topic']}',
          key: r['live_key'].toString(),
        ),
    ];
  }

  /// Realtime client for the live-location channel (routing only).
  SupabaseClient get realtimeClient => _db;

  /// SLIDE Start Delivery (R-12).
  Future<void> startRunDelivery({
    required String riderId,
    required String sessionId,
  }) => _run(
    () => _db.rpc(
      'start_run_delivery',
      params: {'p_rider_id': riderId, 'p_delivery_session_id': sessionId},
    ),
  );

  /// SLIDE Arrive / general per-stop transitions (R-14). [next] is a
  /// canonical delivery_status wire value.
  Future<void> transition({
    required String riderId,
    required String orderId,
    required String next,
  }) => _run(
    () => _db.rpc(
      'rider_transition',
      params: {
        'p_rider_id': riderId,
        'p_order_id': orderId,
        'p_next': next,
        'p_idempotency_key': _idempotencyKey(),
      },
    ),
  );

  /// R-16 Delivery Issue. Only reasons with a genuine canonical backend
  /// match are exposed to the UI -- see [issueReasons].
  Future<void> reportDeliveryIssue({
    required String riderId,
    required String orderId,
    required String reasonType,
    String? note,
  }) => _run(
    () => _db.rpc(
      'rider_report_delivery_issue',
      params: {
        'p_rider_id': riderId,
        'p_order_id': orderId,
        'p_reason_type': reasonType,
        if (note != null && note.isNotEmpty) 'p_note': note,
      },
    ),
  );

  /// Rider-facing label -> canonical reason_type. Kept in the repository,
  /// not the screen, so the screen can never drift from what the backend
  /// actually accepts. Matches rider/backend.js's RIDER_ISSUE_REASON_MAP
  /// exactly -- 'Customer changed time' has no backend contract and is
  /// deliberately left out, not force-mapped.
  static const issueReasons = <String, String>{
    'Customer not reachable': 'customer_unreachable',
    'Wrong address': 'address_problem',
    'Vendor issue / late': 'vendor_not_ready',
    'Rider vehicle breakdown': 'rider_unable_to_proceed',
  };

  /// R-15 Proof of Delivery: upload the photo, then SLIDE Complete Order.
  /// Same activeRiderId threaded through both calls, never independently
  /// derived, so the upload's path-embedded context and the completion
  /// RPC's explicit context can never disagree.
  Future<void> completeDelivery({
    required String riderId,
    required String orderId,
    required List<int> photoBytes,
    required String photoExtension,
    String note = '',
  }) async {
    final path = await _uploadPod(riderId, orderId, photoBytes, photoExtension);
    await _run(
      () => _db.rpc(
        'complete_delivery',
        params: {
          'p_rider_id': riderId,
          'p_order_id': orderId,
          'p_pod_path': path,
          'p_note': note,
          'p_idempotency_key': _idempotencyKey(),
        },
      ),
    );
  }

  Future<String> _uploadPod(
    String riderId,
    String orderId,
    List<int> bytes,
    String extension,
  ) async {
    final path = '$riderId/$orderId/${_idempotencyKey()}.$extension';
    await _run(
      () => _db.storage
          .from('cefflo-pod')
          .uploadBinary(path, Uint8List.fromList(bytes)),
    );
    return path;
  }

  String _idempotencyKey() => DateTime.now().microsecondsSinceEpoch.toString();

  /// PostgREST reports a missing routine as PGRST202 (not in the schema cache)
  /// and Postgres reports it as 42883 (undefined_function). Same convention
  /// as VendorRepository.
  static bool _isMissingFunction(PostgrestException e) =>
      e.code == '42883' ||
      e.code == 'PGRST202' ||
      e.message.contains('does not exist') ||
      e.message.contains('Could not find the function');

  /// Accepts a Rider invitation (the same accept_rider_invitation contract
  /// the invite page uses). Creates this user's rider row as pending; the
  /// business approves it. The token is used once and never stored.
  Future<void> acceptRiderInvitation(String token) => _run(
    () => _db.rpc('accept_rider_invitation', params: {'p_token': token}),
  );

  /// Joins a business through its permanent rider invite link. Always
  /// lands as a pending rider until the business approves.
  /// Returns the server's answer: status 'pending' for a new request, or
  /// this rider's existing status at that business ('active', 'pending',
  /// 'inactive') when already joined.
  Future<Map<String, dynamic>> joinViaInviteLink({
    required String token,
    required String name,
    required String phone,
  }) async {
    final res = await _run(
      () => _db.rpc(
        'join_via_invite_link',
        params: {'p_token': token, 'p_name': name, 'p_phone': phone},
      ),
    );
    return Map<String, dynamic>.from(res as Map);
  }

  /// Business name and state of a permanent invite link (anonymous-safe).
  Future<Map<String, dynamic>?> resolveInviteLink(String token) async {
    final res = await _run(
      () => _db.rpc('resolve_invite_link', params: {'p_token': token}),
    );
    return res == null ? null : Map<String, dynamic>.from(res as Map);
  }

  /// Claims every invitation this account consented to in the Invitation
  /// PWA, bound server-side to the caller's own confirmed email (never an
  /// email sent from the client). Creates the pending rider membership.
  /// Idempotent: returns an empty list once nothing is left to claim.
  Future<List<Map<String, dynamic>>> claimMyRiderInvitations() async {
    final result = await _run(() => _db.rpc('claim_my_rider_invitations'));
    return _rows(result);
  }

  // ---- Notification centre (docs/cefflo/NOTIFICATION_EVENT_MATRIX.md).
  // Rows are written only by the server; RLS returns the user's own rows.
  static const _notifSelect =
      'id,app,business_id,event_key,category,priority,title,body,target,params,created_at,read_at';

  Future<List<DriverNotification>> notifications() async {
    final rows = await _run(
      () => _db
          .from('notifications')
          .select(_notifSelect)
          .eq('app', 'rider')
          .order('created_at', ascending: false)
          .limit(50),
    );
    return _rows(rows).map(DriverNotification.fromRow).toList();
  }

  Future<int> unreadNotificationCount() async {
    final rows = await _run(
      () => _db
          .from('notifications')
          .select('id')
          .eq('app', 'rider')
          .isFilter('read_at', null)
          .limit(100),
    );
    return _rows(rows).length;
  }

  /// Marks [ids] read, or every rider notification when null.
  Future<void> markNotificationsRead({List<String>? ids}) => _run(
    () => _db.rpc(
      'mark_notifications_read',
      params: {'p_ids': ids, 'p_app': 'rider'},
    ),
  );

  Future<void> markNotificationUnread(String id) =>
      _run(() => _db.rpc('mark_notification_unread', params: {'p_id': id}));

  Future<NotificationPrefs> notificationPrefs() async {
    final uid = currentUser?.id;
    if (uid == null) return const NotificationPrefs();
    final rows = _rows(
      await _run(
        () => _db
            .from('notification_preferences')
            .select('enabled,sound')
            .eq('user_id', uid)
            .limit(1),
      ),
    );
    if (rows.isEmpty) return const NotificationPrefs();
    return NotificationPrefs(
      enabled: rows.first['enabled'] != false,
      sound: rows.first['sound'] != false,
    );
  }

  Future<void> saveNotificationPrefs(NotificationPrefs prefs) => _run(
    () => _db.from('notification_preferences').upsert({
      'user_id': _db.auth.currentUser!.id,
      'enabled': prefs.enabled,
      'sound': prefs.sound,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id'),
  );

  /// Realtime feed of the signed-in user's notification rows. [onStatus]
  /// receives true each time the channel is (re)subscribed. Returns a
  /// cancel function, or null without a live session.
  void Function()? watchNotifications({
    required void Function(String type, Map<String, dynamic> row) onChange,
    required void Function(bool subscribed) onStatus,
  }) {
    final db = _client;
    final uid = db?.auth.currentUser?.id;
    if (db == null || uid == null) return null;
    final channel = db
        .channel('notifications:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_user_id',
            value: uid,
          ),
          callback: (payload) => onChange(
            payload.eventType.name.toUpperCase(),
            payload.eventType == PostgresChangeEvent.delete
                ? payload.oldRecord
                : payload.newRecord,
          ),
        )
        .subscribe(
          (status, _) => onStatus(status == RealtimeSubscribeStatus.subscribed),
        );
    return () => db.removeChannel(channel);
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      final missing = _isMissingFunction(e);
      throw RepositoryError(
        missing ? L.actionNeedsBackendContractThatNot(e.message) : e.message,
        isMissingContract: missing,
      );
    } on AuthException catch (e) {
      throw RepositoryError(e.message, code: e.code);
    } catch (e) {
      throw RepositoryError('$e');
    }
  }

  List<Map<String, dynamic>> _rows(dynamic raw) => raw is List
      ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : const [];
}
