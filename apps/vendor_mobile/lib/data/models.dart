/// Typed models over the canonical Cefflo schema.
///
/// Canonical enum values are never renamed here. Presentation groupings are
/// expressed separately (see [OrderTab]) so backend status names stay intact.
library;

/// public.delivery_status
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

  String get wire =>
      _wire.entries.firstWhere((e) => e.value == this).key;

  /// Vendor-facing wording. The canonical value is still [wire].
  String get label => switch (this) {
    DeliveryStatus.created => 'Pending approval',
    DeliveryStatus.readyForPickup => 'Ready',
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
  final String? notes, publicRef, zoneId, assignedRiderId, origin;
  final List<OrderItem> items;
  final DateTime? approvedAt, completedAt;

  factory VendorOrder.fromRow(Map<String, dynamic> r) => VendorOrder(
    id: r['id'] as String,
    status: DeliveryStatus.parse(r['delivery_status'] as String?),
    customerName: (r['customer_name'] as String?) ?? '',
    customerPhone: (r['customer_phone'] as String?) ?? '',
    deliveryAddress: (r['delivery_address'] as String?) ?? '',
    createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
    notes: r['notes'] as String?,
    publicRef: r['public_ref'] as String?,
    zoneId: r['zone_id'] as String?,
    assignedRiderId: r['assigned_rider_id'] as String?,
    origin: r['origin'] as String?,
    items: OrderItem.listFrom(r['items']),
    approvedAt: r['approved_at'] == null ? null : DateTime.parse(r['approved_at'] as String).toLocal(),
    completedAt: r['completed_at'] == null ? null : DateTime.parse(r['completed_at'] as String).toLocal(),
  );

  /// Short human reference. Falls back to the id when the backend has not
  /// issued a public_ref (vendor-created orders).
  String get reference => publicRef ?? id.substring(0, 8).toUpperCase();

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
  const Zone({required this.id, required this.name, required this.status});
  final String id, name, status;

  factory Zone.fromRow(Map<String, dynamic> r) => Zone(
    id: r['id'] as String,
    name: (r['name'] as String?) ?? 'Zone',
    status: (r['status'] as String?) ?? 'active',
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
  });

  final String id, name, status;
  final String? phone, vehicleType, plate;
  final int? maxActiveOrders;

  factory RiderRow.fromRow(Map<String, dynamic> r) => RiderRow(
    id: r['id'] as String,
    name: (r['full_name'] ?? r['name'] ?? 'Rider').toString(),
    status: (r['status'] as String?) ?? 'pending',
    phone: r['phone'] as String?,
    vehicleType: r['vehicle_type'] as String?,
    plate: r['vehicle_plate'] as String?,
    maxActiveOrders: r['max_active_orders'] as int?,
  );

  bool get isActive => status == 'active';
}

class TeamMember {
  const TeamMember({required this.userId, required this.role, this.displayName});
  final String userId, role;
  final String? displayName;

  factory TeamMember.fromRow(Map<String, dynamic> r) => TeamMember(
    userId: (r['user_id'] ?? r['id']).toString(),
    role: (r['role'] as String?) ?? 'operator',
    displayName: r['display_name'] as String?,
  );
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
