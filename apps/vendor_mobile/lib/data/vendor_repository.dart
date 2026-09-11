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

/// All vendor reads/writes go through the canonical backend. Nothing in this
/// class computes eligibility, planning or capacity locally — the server owns
/// those decisions.
class VendorRepository {
  VendorRepository(this._db);
  final SupabaseClient _db;

  User? get currentUser => _db.auth.currentUser;
  Stream<AuthState> get authChanges => _db.auth.onAuthStateChange;

  Future<void> sendEmailOtp(String email) =>
      _run(() => _db.auth.signInWithOtp(email: email.trim()));

  Future<void> verifyEmailOtp(String email, String token) => _run(
    () => _db.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.email,
    ),
  );

  Future<void> signOut() => _run(() => _db.auth.signOut());

  Future<List<Business>> myBusinesses() async {
    final rows = await _run(() => _db.rpc('get_my_businesses'));
    return _rows(rows).map(Business.fromRow).toList();
  }

  // ---------------------------------------------------------------- orders

  Future<List<VendorOrder>> orders(String businessId) async {
    final rows = await _run(
      () => _db
          .from('orders')
          .select()
          .eq('business_id', businessId)
          .order('created_at', ascending: false),
    );
    return _rows(rows).map(VendorOrder.fromRow).toList();
  }

  Future<VendorOrder> order(String orderId) async {
    final row = await _run(
      () => _db.from('orders').select().eq('id', orderId).single(),
    );
    return VendorOrder.fromRow(Map<String, dynamic>.from(row as Map));
  }

  Future<String> createOrder({
    required String businessId,
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    String notes = '',
    List<OrderItem> items = const [],
    String? zoneId,
  }) async {
    final result = await _run(
      () => _db.rpc(
        'create_delivery',
        params: {
          'p_business_id': businessId,
          'p_customer_name': customerName,
          'p_customer_phone': customerPhone,
          'p_delivery_address': deliveryAddress,
          'p_notes': notes,
          'p_items': items.map((i) => i.toJson()).toList(),
          'p_zone_id': ?zoneId,
        },
      ),
    );
    final map = result is Map ? Map<String, dynamic>.from(result) : const {};
    final id = (map['order_id'] ?? map['id'])?.toString();
    if (id == null) {
      throw RepositoryError('Order was not created: backend returned no id.');
    }
    return id;
  }

  Future<VendorOrder> updateOrder({
    required String orderId,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    String? notes,
    List<OrderItem>? items,
    String? zoneId,
    bool clearZone = false,
  }) async {
    final row = await _run(
      () => _db.rpc(
        'update_order_details',
        params: {
          'p_order_id': orderId,
          'p_customer_name': ?customerName,
          'p_customer_phone': ?customerPhone,
          'p_delivery_address': ?deliveryAddress,
          'p_notes': ?notes,
          if (items != null) 'p_items': items.map((i) => i.toJson()).toList(),
          'p_zone_id': ?zoneId,
          if (clearZone) 'p_clear_zone': true,
        },
      ),
    );
    return VendorOrder.fromRow(_single(row));
  }

  Future<VendorOrder> approveOrder(String orderId) async {
    final row = await _run(
      () => _db.rpc('approve_order', params: {'p_order_id': orderId}),
    );
    return VendorOrder.fromRow(_single(row));
  }

  Future<VendorOrder> reportIssue({
    required String orderId,
    required String reasonType,
    String? note,
  }) async {
    final row = await _run(
      () => _db.rpc(
        'vendor_report_delivery_issue',
        params: {
          'p_order_id': orderId,
          'p_reason_type': reasonType,
          if (note != null && note.isNotEmpty) 'p_note': note,
        },
      ),
    );
    return VendorOrder.fromRow(_single(row));
  }

  // ----------------------------------------------------------------- zones

  Future<List<Zone>> zones(String businessId) async {
    final rows = await _run(
      () => _db.from('zones').select().eq('business_id', businessId).order('name'),
    );
    return _rows(rows).map(Zone.fromRow).toList();
  }

  Future<Zone> createZone(String businessId, String name) async {
    final row = await _run(
      () => _db.rpc(
        'create_zone',
        params: {'p_business_id': businessId, 'p_name': name},
      ),
    );
    return Zone.fromRow(_single(row));
  }

  Future<Zone> setZoneStatus(String zoneId, String status) async {
    final row = await _run(
      () => _db.rpc(
        'set_zone_status',
        params: {'p_zone_id': zoneId, 'p_status': status},
      ),
    );
    return Zone.fromRow(_single(row));
  }

  // ---------------------------------------------------------------- riders

  Future<List<RiderRow>> riders(String businessId) async {
    final rows = await _run(
      () => _db.from('riders').select().eq('business_id', businessId).order('created_at'),
    );
    return _rows(rows).map(RiderRow.fromRow).toList();
  }

  Future<Map<String, dynamic>> createRiderInvitation({
    required String businessId,
    required String email,
    required String name,
    required String phone,
  }) async {
    final row = await _run(
      () => _db.rpc(
        'create_rider_invitation',
        params: {
          'p_business_id': businessId,
          'p_invited_email': email,
          'p_invited_name': name,
          'p_invited_phone': phone,
        },
      ),
    );
    return _single(row);
  }

  // ------------------------------------------------------------------ team

  Future<List<TeamMember>> team(String businessId) async {
    final rows = await _run(
      () => _db.from('business_members').select().eq('business_id', businessId),
    );
    return _rows(rows).map(TeamMember.fromRow).toList();
  }

  Future<Map<String, dynamic>> createTeamInvitation({
    required String businessId,
    required String email,
    required String role,
  }) async {
    final row = await _run(
      () => _db.rpc(
        'create_team_invitation',
        params: {
          'p_business_id': businessId,
          'p_role': role,
          'p_invited_email': email,
        },
      ),
    );
    return _single(row);
  }

  // -------------------------------------------------------------- products

  Future<List<Product>> products(String businessId) async {
    final rows = await _run(
      () => _db.from('products').select().eq('business_id', businessId).order('name'),
    );
    return _rows(rows).map(Product.fromRow).toList();
  }

  Future<Product> createProduct({
    required String businessId,
    required String name,
    required String description,
    required num displayPrice,
    String? categoryId,
    String status = 'active',
  }) async {
    final row = await _run(
      () => _db.rpc(
        'create_product',
        params: {
          'p_business_id': businessId,
          'p_category_id': categoryId,
          'p_name': name,
          'p_description': description,
          'p_display_price': displayPrice,
          'p_status': status,
        },
      ),
    );
    return Product.fromRow(_single(row));
  }

  Future<Product> updateProduct({
    required String productId,
    required String name,
    required String description,
    required num displayPrice,
    required String status,
    String? categoryId,
  }) async {
    final row = await _run(
      () => _db.rpc(
        'update_product',
        params: {
          'p_product_id': productId,
          'p_category_id': categoryId,
          'p_name': name,
          'p_description': description,
          'p_display_price': displayPrice,
          'p_status': status,
        },
      ),
    );
    return Product.fromRow(_single(row));
  }

  // ------------------------------------------- coverage / planning / dispatch
  //
  // Every decision below is the server's. This client never computes
  // coverage, grouping, sequencing, capacity or ETA locally; it renders what
  // the canonical RPCs return.

  /// Service-area configuration (origin + radius) for one business.
  Future<Map<String, dynamic>> setServiceArea({
    required String businessId,
    required double latitude,
    required double longitude,
    required num radiusKm,
  }) async {
    final row = await _run(
      () => _db.rpc(
        'set_business_service_area',
        params: {
          'p_business_id': businessId,
          'p_origin_latitude': latitude,
          'p_origin_longitude': longitude,
          'p_radius_km': radiusKm,
        },
      ),
    );
    return _single(row);
  }

  /// Server verdict for one order: unconfigured | pending_location |
  /// covered | out_of_coverage.
  Future<String> orderCoverageStatus(String orderId) async {
    final value = await _run(
      () => _db.rpc('order_coverage_status', params: {'p_order_id': orderId}),
    );
    return value?.toString() ?? 'unknown';
  }

  /// Returns null when the business has no service area configured — that is
  /// "not decidable", not "outside coverage".
  Future<bool?> isWithinCoverage({
    required String businessId,
    required double latitude,
    required double longitude,
  }) async {
    final value = await _run(
      () => _db.rpc(
        'is_within_coverage',
        params: {
          'p_business_id': businessId,
          'p_latitude': latitude,
          'p_longitude': longitude,
        },
      ),
    );
    return value as bool?;
  }

  /// The shared definition of "what is plannable right now", used by both the
  /// planning screen and the optimizer, so the two can never disagree.
  Future<List<PlannableOrder>> plannableOrders(String businessId) async {
    final rows = await _run(
      () => _db.rpc('list_plannable_orders', params: {'p_business_id': businessId}),
    );
    return _rows(rows).map(PlannableOrder.fromRow).toList();
  }

  /// Server-computed grouping, rider candidate and stop sequence.
  Future<PlanProposal> proposePlan(String businessId) async {
    final row = await _run(
      () => _db.rpc('propose_delivery_plan', params: {'p_business_id': businessId}),
    );
    return PlanProposal.fromJson(_single(row));
  }

  Future<Map<String, dynamic>> createDeliverySession({
    required String businessId,
    String? name,
  }) async {
    final row = await _run(
      () => _db.rpc(
        'create_delivery_session',
        params: {'p_business_id': businessId, 'p_name': ?name},
      ),
    );
    return _single(row);
  }

  /// Server-side pre-check so a vehicle/capacity conflict is shown before
  /// dispatch is attempted, rather than surfacing as a raised exception.
  Future<CapacityCheck> checkRunCapacity({
    required String riderId,
    required List<String> orderIds,
  }) async {
    final row = await _run(
      () => _db.rpc(
        'check_run_vehicle_capacity',
        params: {'p_rider_id': riderId, 'p_order_ids': orderIds},
      ),
    );
    return CapacityCheck.fromJson(_single(row));
  }

  /// Dispatch. [idempotencyKey] must be stable for a retry of the same run.
  Future<Map<String, dynamic>> buildRiderRun({
    required String sessionId,
    required String riderId,
    required List<String> orderIds,
    required String idempotencyKey,
    bool overrideCapacity = false,
  }) async {
    final row = await _run(
      () => _db.rpc(
        'build_rider_run',
        params: {
          'p_delivery_session_id': sessionId,
          'p_rider_id': riderId,
          'p_order_ids': orderIds,
          'p_idempotency_key': idempotencyKey,
          'p_override_capacity': overrideCapacity,
        },
      ),
    );
    return _single(row);
  }

  // ------------------------------------------------------------- business

  Future<Map<String, dynamic>> business(String businessId) async {
    final row = await _run(
      () => _db.from('businesses').select().eq('id', businessId).single(),
    );
    return Map<String, dynamic>.from(row as Map);
  }

  Future<Map<String, dynamic>> updateBusinessProfile({
    required String businessId,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? operatingArea,
  }) async {
    final row = await _run(
      () => _db.rpc(
        'update_business_profile',
        params: {
          'p_business_id': businessId,
          'p_name': ?name,
          'p_phone': ?phone,
          'p_email': ?email,
          'p_address': ?address,
          'p_operating_area': ?operatingArea,
        },
      ),
    );
    return _single(row);
  }

  /// PostgREST reports a missing routine as PGRST202 (not in the schema cache)
  /// and Postgres reports it as 42883 (undefined_function).
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

  Map<String, dynamic> _single(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return Map<String, dynamic>.from(raw.first as Map);
    }
    throw RepositoryError('Unexpected backend response shape.');
  }
}
