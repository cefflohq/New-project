/// Typed models over the canonical Cefflo schema.
///
/// Canonical enum values are never renamed here. Presentation groupings are
/// expressed separately (see [OrderTab]) so backend status names stay intact.
library;

/// public.delivery_status
/// The one user-facing order number format (D-64): `#CF-001`, per business
/// and business-local day, issued by the backend as `order_number`. Display
/// only: ids and `public_ref` are unchanged. Rows without it (demo data)
/// derive the same format from their numeric reference.
String cefOrderRef(String? orderNumber, String? publicRef, String id) {
  if (orderNumber != null && orderNumber.isNotEmpty) return orderNumber;
  final digits = RegExp(
    r'^(?:ORD|CF)?[-_ #]*(\d+)$',
    caseSensitive: false,
  ).firstMatch(publicRef ?? '')?.group(1);
  if (digits != null) return cefOrderNumber(int.parse(digits));
  return '#CF-${id.replaceAll('-', '').substring(0, 6).toUpperCase()}';
}

/// `#CF-` plus the daily sequence, at least three digits, never capped.
String cefOrderNumber(int seq) => '#CF-${seq.toString().padLeft(3, '0')}';

enum DeliveryStatus {
  created,
  readyForPickup,
  pickedUp,
  outForDelivery,
  arrived,
  delivered,
  issue,
  cancelled;

  static const _wire = {
    'created': DeliveryStatus.created,
    'ready_for_pickup': DeliveryStatus.readyForPickup,
    'picked_up': DeliveryStatus.pickedUp,
    'out_for_delivery': DeliveryStatus.outForDelivery,
    'arrived': DeliveryStatus.arrived,
    'delivered': DeliveryStatus.delivered,
    'issue': DeliveryStatus.issue,
    'cancelled': DeliveryStatus.cancelled,
  };

  static DeliveryStatus parse(String? v) => _wire[v] ?? DeliveryStatus.created;

  String get wire => _wire.entries.firstWhere((e) => e.value == this).key;

  /// Vendor-facing wording. The canonical value is still [wire].
  String get label => switch (this) {
    DeliveryStatus.created => 'Pending approval',
    DeliveryStatus.readyForPickup => 'Pickup',
    DeliveryStatus.pickedUp => 'Picked up',
    DeliveryStatus.outForDelivery => 'On the way',
    DeliveryStatus.arrived => 'Arrived',
    DeliveryStatus.delivered => 'Delivered',
    DeliveryStatus.issue => 'Issue',
    DeliveryStatus.cancelled => 'Cancelled',
  };
}

/// Audit fix 4: the three Orders tabs group canonical statuses for
/// presentation only. Counts and lists derive from this same mapping so a KPI
/// can never disagree with the list it links to.
enum OrderTab {
  ongoing('Ongoing', {
    DeliveryStatus.created,
    DeliveryStatus.readyForPickup,
    DeliveryStatus.pickedUp,
    DeliveryStatus.outForDelivery,
    DeliveryStatus.arrived,
  }),
  issue('Issue', {DeliveryStatus.issue}),
  delivered('Delivered', {DeliveryStatus.delivered});

  const OrderTab(this.label, this.statuses);
  final String label;
  final Set<DeliveryStatus> statuses;

  bool accepts(DeliveryStatus s) => statuses.contains(s);
}

class Business {
  const Business({
    required this.id,
    required this.name,
    required this.role,
    this.timezone,
    this.currency,
  });

  final String id, name, role;
  final String? timezone, currency;

  factory Business.fromRow(Map<String, dynamic> r) => Business(
    id: r['business_id'] as String,
    name: (r['business_name'] as String?) ?? 'Business',
    role: (r['member_role'] as String?) ?? 'operator',
    timezone: r['timezone'] as String?,
    currency: r['currency'] as String?,
  );

  bool get isOwner => role == 'owner';
}

class VendorOrder {
  const VendorOrder({
    required this.id,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.createdAt,
    this.notes,
    this.publicRef,
    this.orderNumber,
    this.zoneId,
    this.assignedRiderId,
    this.items = const [],
    this.origin,
    this.approvedAt,
    this.completedAt,
  });

  final String id;
  final DeliveryStatus status;
  final String customerName, customerPhone, deliveryAddress;
  final DateTime createdAt;
  final String? notes, publicRef, orderNumber, zoneId, assignedRiderId, origin;
  final List<OrderItem> items;
  final DateTime? approvedAt, completedAt;

  /// Approval is recorded in `approved_at`, not in `delivery_status`
  /// (still `created` until pickup), so an approved order must not read as
  /// awaiting approval.
  bool get isApproved => approvedAt != null;
  String get statusLabel => status == DeliveryStatus.created && isApproved
      ? 'Approved'
      : status.label;

  factory VendorOrder.fromRow(Map<String, dynamic> r) => VendorOrder(
    id: r['id'] as String,
    status: DeliveryStatus.parse(r['delivery_status'] as String?),
    customerName: (r['customer_name'] as String?) ?? '',
    customerPhone: (r['customer_phone'] as String?) ?? '',
    deliveryAddress: (r['delivery_address'] as String?) ?? '',
    createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
    notes: r['notes'] as String?,
    publicRef: r['public_ref'] as String?,
    orderNumber: r['order_number'] as String?,
    zoneId: r['zone_id'] as String?,
    assignedRiderId: r['assigned_rider_id'] as String?,
    origin: r['origin'] as String?,
    items: OrderItem.listFrom(r['items']),
    approvedAt: r['approved_at'] == null
        ? null
        : DateTime.parse(r['approved_at'] as String).toLocal(),
    completedAt: r['completed_at'] == null
        ? null
        : DateTime.parse(r['completed_at'] as String).toLocal(),
  );

  /// Short human reference. Falls back to the id when the backend has not
  /// issued a public_ref (vendor-created orders).
  /// User-facing order number, e.g. #CF-001 (D-64).
  String get reference => cefOrderRef(orderNumber, publicRef, id);

  bool get isTerminal =>
      status == DeliveryStatus.delivered || status == DeliveryStatus.cancelled;

  /// Audit fix 3: a completed order must not offer a planning CTA.
  bool get canPlan =>
      status == DeliveryStatus.readyForPickup && assignedRiderId == null;

  bool get canApprove => status == DeliveryStatus.created;
  bool get canEdit => !isTerminal;
}

class OrderItem {
  const OrderItem({required this.name, required this.quantity, this.unitPrice});
  final String name;
  final int quantity;
  final num? unitPrice;

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
    name: (j['name'] ?? j['product_name'] ?? 'Item').toString(),
    quantity: int.tryParse('${j['quantity'] ?? j['qty'] ?? 1}') ?? 1,
    unitPrice: j['unit_price'] is num
        ? j['unit_price'] as num
        : num.tryParse('${j['unit_price'] ?? j['price'] ?? ''}'),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    if (unitPrice != null) 'unit_price': unitPrice,
  };

  static List<OrderItem> listFrom(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

class Zone {
  const Zone({
    required this.id,
    required this.name,
    required this.status,
    this.locality,
  });
  final String id, name, status;

  /// Human place label ("Mont Kiara, Kuala Lumpur") when the row carries
  /// one; the UI omits the line otherwise rather than inventing it.
  final String? locality;

  factory Zone.fromRow(Map<String, dynamic> r) => Zone(
    id: r['id'] as String,
    name: (r['name'] as String?) ?? 'Zone',
    status: (r['status'] as String?) ?? 'active',
    locality: r['locality'] as String?,
  );

  bool get isActive => status == 'active';
}

class RiderRow {
  const RiderRow({
    required this.id,
    required this.name,
    required this.status,
    this.phone,
    this.vehicleType,
    this.plate,
    this.maxActiveOrders,
    this.totalOrders,
    this.rating,
    this.joinedAt,
  });

  final String id, name, status;
  final String? phone, vehicleType, plate;
  final int? maxActiveOrders;

  /// Rider Detail stats. Nullable: a row without them shows "—" rather
  /// than an invented figure.
  final int? totalOrders;
  final num? rating;
  final DateTime? joinedAt;

  factory RiderRow.fromRow(Map<String, dynamic> r) => RiderRow(
    id: r['id'] as String,
    name: (r['full_name'] ?? r['name'] ?? 'Rider').toString(),
    status: (r['status'] as String?) ?? 'pending',
    phone: r['phone'] as String?,
    vehicleType: r['vehicle_type'] as String?,
    plate: r['vehicle_plate'] as String?,
    maxActiveOrders: r['max_active_orders'] as int?,
    totalOrders: r['total_orders'] as int?,
    rating: r['rating'] as num?,
    joinedAt: DateTime.tryParse((r['created_at'] ?? '').toString()),
  );

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';

  /// Offline means an approved relationship that is not active; a pending
  /// rider has not been approved yet and is never Offline.
  bool get isOffline => !isActive && !isPending;
}

class TeamMember {
  const TeamMember({
    required this.userId,
    required this.role,
    this.displayName,
    this.phone,
    this.email,
  });
  final String userId, role;
  final String? displayName, phone, email;

  factory TeamMember.fromRow(Map<String, dynamic> r) => TeamMember(
    userId: (r['user_id'] ?? r['id']).toString(),
    role: (r['role'] as String?) ?? 'operator',
    displayName: r['display_name'] as String?,
    phone: r['phone'] as String?,
    email: r['email'] as String?,
  );

  /// The business owner cannot be removed from their own team.
  bool get isOwner => role.toLowerCase() == 'owner';
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.status,
    this.description,
    this.displayPrice,
    this.categoryId,
  });

  final String id, name, status;
  final String? description, categoryId;
  final num? displayPrice;

  factory Product.fromRow(Map<String, dynamic> r) => Product(
    id: r['id'] as String,
    name: (r['name'] as String?) ?? 'Product',
    status: (r['status'] as String?) ?? 'active',
    description: r['description'] as String?,
    displayPrice: r['display_price'] as num?,
    categoryId: r['category_id'] as String?,
  );
}

// --------------------------------------------------- coverage and planning

/// Server verdict from `order_coverage_status`. 'unconfigured' and
/// 'pending_location' are distinct from a real out-of-coverage answer and must
/// never be presented as one.
enum CoverageStatus {
  unconfigured,
  pendingLocation,
  covered,
  outOfCoverage,
  unknown;

  static CoverageStatus parse(String? v) => switch (v) {
    'unconfigured' => CoverageStatus.unconfigured,
    'pending_location' => CoverageStatus.pendingLocation,
    'covered' => CoverageStatus.covered,
    'out_of_coverage' => CoverageStatus.outOfCoverage,
    _ => CoverageStatus.unknown,
  };

  String get label => switch (this) {
    CoverageStatus.unconfigured => 'Service area not set',
    CoverageStatus.pendingLocation => 'Awaiting location',
    CoverageStatus.covered => 'In coverage',
    CoverageStatus.outOfCoverage => 'Outside coverage',
    CoverageStatus.unknown => 'Unknown',
  };

  bool get needsAttention =>
      this == CoverageStatus.outOfCoverage ||
      this == CoverageStatus.pendingLocation;
}

/// One row of `list_plannable_orders`.
class PlannableOrder {
  const PlannableOrder({
    required this.orderId,
    required this.customerName,
    required this.deliveryAddress,
    required this.locationStatus,
    required this.coverage,
    this.publicRef,
    this.orderNumber,
    this.zoneId,
    this.latitude,
    this.longitude,
  });

  final String orderId, customerName, deliveryAddress, locationStatus;
  final CoverageStatus coverage;
  final String? publicRef, orderNumber, zoneId;
  final double? latitude, longitude;

  factory PlannableOrder.fromRow(Map<String, dynamic> r) => PlannableOrder(
    orderId: r['order_id'] as String,
    customerName: (r['customer_name'] as String?) ?? '',
    deliveryAddress: (r['delivery_address'] as String?) ?? '',
    locationStatus: (r['location_status'] as String?) ?? 'unresolved',
    coverage: CoverageStatus.parse(r['coverage_status'] as String?),
    publicRef: r['public_ref'] as String?,
    orderNumber: r['order_number'] as String?,
    zoneId: r['zone_id'] as String?,
    latitude: (r['latitude'] as num?)?.toDouble(),
    longitude: (r['longitude'] as num?)?.toDouble(),
  );

  /// User-facing order number, e.g. #CF-001 (D-64).
  String get reference => cefOrderRef(orderNumber, publicRef, orderId);
  bool get locationResolved => locationStatus == 'resolved';
}

/// `propose_delivery_plan` result. The server decides the groups, the
/// candidate rider and the stop order; this type only carries them.
class PlanProposal {
  const PlanProposal({required this.groups, required this.unplannable});
  final List<PlanGroup> groups;
  final List<UnplannableEntry> unplannable;

  factory PlanProposal.fromJson(Map<String, dynamic> j) => PlanProposal(
    groups: (j['groups'] as List? ?? [])
        .whereType<Map>()
        .map((g) => PlanGroup.fromJson(Map<String, dynamic>.from(g)))
        .toList(),
    unplannable: (j['unplannable_orders'] as List? ?? [])
        .whereType<Map>()
        .map((g) => UnplannableEntry.fromJson(Map<String, dynamic>.from(g)))
        .toList(),
  );

  bool get isEmpty => groups.isEmpty && unplannable.isEmpty;
}

class PlanGroup {
  const PlanGroup({
    required this.groupKey,
    required this.stops,
    this.zoneId,
    this.candidateRiderId,
    this.candidateRiderName,
    this.candidateRiderVehicleType,
    this.requiredVehicle,
    this.totalDistanceKm,
  });

  final String groupKey;
  final List<PlanStop> stops;
  final String? zoneId, candidateRiderId, candidateRiderName;
  final String? candidateRiderVehicleType, requiredVehicle;
  final num? totalDistanceKm;

  factory PlanGroup.fromJson(Map<String, dynamic> j) => PlanGroup(
    groupKey: (j['group_key'] ?? 'group').toString(),
    zoneId: j['zone_id'] as String?,
    candidateRiderId: j['candidate_rider_id'] as String?,
    candidateRiderName: j['candidate_rider_name'] as String?,
    candidateRiderVehicleType: j['candidate_rider_vehicle_type'] as String?,
    requiredVehicle: j['required_vehicle'] as String?,
    totalDistanceKm: j['total_distance_km'] as num?,
    stops: (j['stops'] as List? ?? [])
        .whereType<Map>()
        .map((s) => PlanStop.fromJson(Map<String, dynamic>.from(s)))
        .toList(),
  );

  List<String> get orderIds => stops.map((s) => s.orderId).toList();
}

class PlanStop {
  const PlanStop({
    required this.orderId,
    required this.sequence,
    this.distanceKm,
    this.travelMinutes,
    this.etaAt,
  });
  final String orderId;
  final int sequence;
  final num? distanceKm;

  /// Travel time from the previous stop and the planned arrival, when the
  /// server supplies them. Never estimated client-side: the UI omits them
  /// when absent.
  final int? travelMinutes;
  final DateTime? etaAt;

  factory PlanStop.fromJson(Map<String, dynamic> j) => PlanStop(
    orderId: j['order_id'] as String,
    sequence: (j['sequence'] as num?)?.toInt() ?? 0,
    distanceKm: j['distance_from_previous_km'] as num?,
    travelMinutes: (j['travel_minutes'] as num?)?.toInt(),
    etaAt: DateTime.tryParse((j['eta_at'] ?? '').toString()),
  );
}

/// Why the server could not plan something. Surfaced verbatim rather than
/// hidden, so the vendor sees the real reason.
class UnplannableEntry {
  const UnplannableEntry({
    required this.reason,
    this.orderId,
    this.groupKey,
    this.groupSize,
  });
  final String reason;
  final String? orderId, groupKey;
  final int? groupSize;

  factory UnplannableEntry.fromJson(Map<String, dynamic> j) => UnplannableEntry(
    reason: (j['reason'] ?? 'unknown').toString(),
    orderId: j['order_id'] as String?,
    groupKey: j['group_key'] as String?,
    groupSize: (j['group_size'] as num?)?.toInt(),
  );

  String get label => switch (reason) {
    'location_unresolved' => 'Address not yet located',
    'location_ambiguous' => 'Address is ambiguous',
    'location_failed' => 'Address could not be located',
    'no_compatible_capacity_sufficient_rider' =>
      'No rider with a compatible vehicle and enough spare capacity',
    _ => reason,
  };
}

/// One persisted run: a `rider_assignments` row (one rider inside one
/// delivery session) with its `delivery_stops`. Read-only projection of
/// canonical backend state -- the same rows Vendor Web and the Driver read.
class VendorRun {
  const VendorRun({
    required this.id,
    required this.riderId,
    required this.sessionId,
    required this.status,
    required this.stops,
    this.sessionName,
    this.assignedAt,
  });

  final String id, riderId, sessionId, status;
  final String? sessionName;
  final DateTime? assignedAt;
  final List<RunStop> stops;

  factory VendorRun.fromRow(Map<String, dynamic> r) {
    final session = r['delivery_sessions'];
    final stops =
        (r['delivery_stops'] as List? ?? [])
            .whereType<Map>()
            .map((s) => RunStop.fromRow(Map<String, dynamic>.from(s)))
            .toList()
          ..sort((a, b) => a.sequence.compareTo(b.sequence));
    return VendorRun(
      id: r['id'] as String,
      riderId: r['rider_id'] as String,
      sessionId: r['delivery_session_id'] as String,
      status: (r['status'] as String?) ?? 'assigned',
      sessionName: session is Map ? session['name'] as String? : null,
      assignedAt: DateTime.tryParse((r['assigned_at'] ?? '').toString()),
      stops: stops,
    );
  }

  List<String> get orderIds => stops.map((s) => s.orderId).toList();
  int get delivered =>
      stops.where((s) => s.status == DeliveryStatus.delivered).length;

  /// A run stays on today's plan until it is completed or cancelled.
  bool get isOpen =>
      !const {'completed', 'cancelled', 'declined'}.contains(status);

  /// Vendor-facing wording for the canonical assignment status.
  String get statusLabel => switch (status) {
    'assigned' => 'Dispatched',
    'accepted' => 'Accepted',
    'picking_up' => 'Picking up',
    'delivering' => 'On the way',
    'completed' => 'Completed',
    'issue' => 'Issue',
    'declined' => 'Declined',
    'cancelled' => 'Cancelled',
    _ => status,
  };
}

class RunStop {
  const RunStop({
    required this.orderId,
    required this.sequence,
    required this.status,
  });
  final String orderId;
  final int sequence;
  final DeliveryStatus status;

  factory RunStop.fromRow(Map<String, dynamic> r) => RunStop(
    orderId: r['order_id'] as String,
    sequence: (r['sequence'] as num?)?.toInt() ?? 0,
    status: DeliveryStatus.parse(r['status'] as String?),
  );
}

/// `check_run_vehicle_capacity` result.
class CapacityCheck {
  const CapacityCheck({required this.compatible, required this.violations});
  final bool compatible;
  final List<String> violations;

  factory CapacityCheck.fromJson(Map<String, dynamic> j) => CapacityCheck(
    compatible: j['compatible'] == true,
    violations: (j['violations'] as List? ?? []).whereType<Map>().map((v) {
      final reason = (v['reason'] ?? '').toString();
      if (reason == 'capacity_exceeded') {
        return 'Capacity exceeded: ${v['current_load']} active + '
            '${v['requested']} requested exceeds ${v['effective_capacity']}.';
      }
      return 'Vehicle incompatible: needs ${v['vehicle_requirement']}, '
          'rider has ${v['rider_vehicle_type']}.';
    }).toList(),
  );
}

/// What a notification is about; decides its icon.
enum NotificationKind { attention, order, rider, system }

/// One entry in the vendor's notification centre.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.timeLabel,
    this.read = false,
  });
  final String id;
  final NotificationKind kind;
  final String title, body, timeLabel;
  final bool read;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    timeLabel: timeLabel,
    read: read ?? this.read,
  );
}
