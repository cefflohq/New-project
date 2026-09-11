import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

/// Thrown for any backend failure the UI is expected to surface truthfully.
class RepositoryError implements Exception {
  RepositoryError(this.message, {this.isMissingContract = false});
  final String message;

  /// True when the canonical RPC does not exist on the connected backend.
  /// The UI must show a blocked state instead of pretending the action worked.
  final bool isMissingContract;

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
  RiderRepository(this._db);
  final SupabaseClient _db;

  User? get currentUser => _db.auth.currentUser;
  Stream<AuthState> get authChanges => _db.auth.onAuthStateChange;

  Future<void> signInWithPassword(String identifier, String password) => _run(
    () => _db.auth.signInWithPassword(
      email: identifier.contains('@') ? identifier.trim() : null,
      phone: identifier.contains('@') ? null : identifier.trim(),
      password: password,
    ),
  );

  Future<void> signOut() => _run(() => _db.auth.signOut());

  // -------------------------------------------------------- identity/scope

  /// Every `riders` row for the signed-in identity, unfiltered by status --
  /// this is the one read that must not be scoped to "the active
  /// relationship" since it's how a relationship gets selected in the first
  /// place. Mirrors rider/backend.js's classifyRiderRelationships() exactly.
  Future<List<RiderRelationship>> myRiderRelationships() async {
    final user = currentUser;
    if (user == null) throw RepositoryError('Not signed in.');
    final rows = await _run(
      () => _db.from('riders').select().eq('auth_user_id', user.id),
    );
    final relationships = _rows(rows).map(RiderRelationship.fromRow).toList();
    final businessIds = relationships.map((r) => r.businessId).toSet();
    if (businessIds.isEmpty) return relationships;
    final businessRows = await _run(
      () => _db.from('businesses').select('id,name').inFilter('id', businessIds.toList()),
    );
    final nameById = {for (final b in _rows(businessRows)) b['id'].toString(): (b['name'] ?? '').toString()};
    return relationships
        .map((r) => RiderRelationship.fromRow(
              {
                'id': r.id,
                'business_id': r.businessId,
                'status': r.status,
                'name': r.name,
                'phone': r.phone,
                'vehicle_type': r.vehicleType,
              },
              businessName: nameById[r.businessId],
            ))
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
          .select('*,delivery_stops(id,sequence,sequence_locked_at,assignment_id,rider_assignments(status,accepted_at))')
          .eq('assigned_rider_id', riderId)
          .order('created_at'),
    );
    return _rows(rows).map(RiderOrder.fromRow).toList();
  }

  Future<List<DeliverySession>> sessions(String businessId) async {
    final rows = await _run(
      () => _db.from('delivery_sessions').select('id,name').eq('business_id', businessId),
    );
    return _rows(rows).map(DeliverySession.fromRow).toList();
  }

  // --------------------------------------------------------- run lifecycle

  Future<void> acceptAssignment({required String riderId, required String orderId}) => _run(
    () => _db.rpc('accept_assignment', params: {'p_rider_id': riderId, 'p_order_id': orderId}),
  );

  Future<void> declineAssignment({required String riderId, required String orderId}) => _run(
    () => _db.rpc('decline_assignment', params: {'p_rider_id': riderId, 'p_order_id': orderId}),
  );

  Future<void> acceptRun({required String riderId, required String sessionId}) => _run(
    () => _db.rpc('accept_run', params: {'p_rider_id': riderId, 'p_delivery_session_id': sessionId}),
  );

  Future<void> declineRun({required String riderId, required String sessionId}) => _run(
    () => _db.rpc('decline_run', params: {'p_rider_id': riderId, 'p_delivery_session_id': sessionId}),
  );

  /// R-09 Plan Route: persist the Rider's reorder of permitted stops.
  /// Cefflo does not claim route-optimization intelligence -- this is local
  /// knowledge, backend remains canonical for allowed sequence changes.
  Future<void> saveRunSequence({
    required String riderId,
    required String sessionId,
    required List<String> orderedOrderIds,
  }) => _run(
    () => _db.rpc('save_run_sequence', params: {
      'p_rider_id': riderId,
      'p_delivery_session_id': sessionId,
      'p_ordered_order_ids': orderedOrderIds,
    }),
  );

  /// SLIDE Start Pickup (R-10).
  Future<void> startPickupRun({required String riderId, required String sessionId}) => _run(
    () => _db.rpc('start_pickup_run', params: {'p_rider_id': riderId, 'p_delivery_session_id': sessionId}),
  );

  /// SLIDE Start Delivery (R-12).
  Future<void> startRunDelivery({required String riderId, required String sessionId}) => _run(
    () => _db.rpc('start_run_delivery', params: {'p_rider_id': riderId, 'p_delivery_session_id': sessionId}),
  );

  /// SLIDE Arrive / general per-stop transitions (R-14). [next] is a
  /// canonical delivery_status wire value.
  Future<void> transition({required String riderId, required String orderId, required String next}) => _run(
    () => _db.rpc('rider_transition', params: {
      'p_rider_id': riderId,
      'p_order_id': orderId,
      'p_next': next,
      'p_idempotency_key': _idempotencyKey(),
    }),
  );

  /// R-16 Delivery Issue. Only reasons with a genuine canonical backend
  /// match are exposed to the UI -- see [issueReasons].
  Future<void> reportDeliveryIssue({
    required String riderId,
    required String orderId,
    required String reasonType,
    String? note,
  }) => _run(
    () => _db.rpc('rider_report_delivery_issue', params: {
      'p_rider_id': riderId,
      'p_order_id': orderId,
      'p_reason_type': reasonType,
      if (note != null && note.isNotEmpty) 'p_note': note,
    }),
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
      () => _db.rpc('complete_delivery', params: {
        'p_rider_id': riderId,
        'p_order_id': orderId,
        'p_pod_path': path,
        'p_note': note,
        'p_idempotency_key': _idempotencyKey(),
      }),
    );
  }

  Future<String> _uploadPod(String riderId, String orderId, List<int> bytes, String extension) async {
    final path = '$riderId/$orderId/${_idempotencyKey()}.$extension';
    await _run(
      () => _db.storage.from('cefflo-pod').uploadBinary(path, Uint8List.fromList(bytes)),
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

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      final missing = _isMissingFunction(e);
      throw RepositoryError(
        missing
            ? 'This action needs a backend contract that is not deployed here (${e.message}).'
            : e.message,
        isMissingContract: missing,
      );
    } on AuthException catch (e) {
      throw RepositoryError(e.message);
    } catch (e) {
      throw RepositoryError('$e');
    }
  }

  List<Map<String, dynamic>> _rows(dynamic raw) => raw is List
      ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : const [];
}
