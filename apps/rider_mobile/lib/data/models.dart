/// Typed models over the canonical Cefflo schema, Rider-facing subset.
///
/// Canonical enum/status values are never renamed here -- the same
/// public.delivery_status column Vendor Mobile reads, so the two clients can
/// never disagree about what a status means.
library;

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

  /// Rider-facing wording. The canonical value is still [wire]. 'created'
  /// reads as 'Ready for pickup' to Rider -- the same collapse the live
  /// Rider PWA's uiStatus() already makes, since a Rider has no legitimate
  /// use for the Vendor-side "pending approval" distinction.
  String get label => switch (this) {
    DeliveryStatus.created => 'Ready for pickup',
    DeliveryStatus.readyForPickup => 'Ready for pickup',
    DeliveryStatus.pickedUp => 'Picked up',
    DeliveryStatus.outForDelivery => 'Out for delivery',
    DeliveryStatus.arrived => 'Out for delivery',
    DeliveryStatus.delivered => 'Delivered',
    DeliveryStatus.issue => 'Issue',
    DeliveryStatus.cancelled => 'Cancelled',
  };
}

/// One row from `riders` for the signed-in identity. A Rider may hold more
/// than one relationship (multiple businesses); [status] gates which are
/// usable ('active') vs awaiting approval ('pending').
class RiderRelationship {
  const RiderRelationship({
    required this.id,
    required this.businessId,
    required this.status,
    required this.name,
    this.businessName,
    this.phone,
    this.vehicleType,
  });

  final String id;
  final String businessId;
  final String status; // 'active' | 'pending' | other canonical values
  final String name;
  final String? businessName;
  final String? phone;
  final String? vehicleType;

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';

  static RiderRelationship fromRow(Map<String, dynamic> row, {String? businessName}) =>
      RiderRelationship(
        id: row['id'].toString(),
        businessId: row['business_id'].toString(),
        status: (row['status'] ?? '').toString(),
        name: (row['name'] ?? '').toString(),
        businessName: businessName,
        phone: row['phone']?.toString(),
        vehicleType: row['vehicle_type']?.toString(),
      );
}

/// One `delivery_sessions` row -- a Wave/run grouping orders belong to.
class DeliverySession {
  const DeliverySession({required this.id, required this.name});
  final String id;
  final String name;

  static DeliverySession fromRow(Map<String, dynamic> row) => DeliverySession(
    id: row['id'].toString(),
    name: (row['name'] ?? '').toString(),
  );
}

/// One `orders` row assigned to this Rider, with its embedded
/// delivery_stops/rider_assignments context -- the same nested read shape
/// the live Rider PWA uses (assigned_rider_id=eq.RIDER_ID, embedding
/// delivery_stops(...rider_assignments(...))), so this client and that one
/// can never disagree about what "this Rider's orders" means.
class RiderOrder {
  const RiderOrder({
    required this.id,
    required this.publicRef,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.itemCount,
    required this.note,
    required this.status,
    this.deliverySessionId,
    this.stopId,
    this.sequence,
    this.assignmentStatus,
  });

  final String id;
  final String publicRef;
  final String customerName;
  final String customerPhone;
  final String address;
  final int itemCount;
  final String note;
  final DeliveryStatus status;
  final String? deliverySessionId;
  final String? stopId;
  final int? sequence;
  final String? assignmentStatus;

  bool get isDelivered => status == DeliveryStatus.delivered;
  bool get hasIssue => status == DeliveryStatus.issue;

  static RiderOrder fromRow(Map<String, dynamic> row) {
    final stopsRaw = row['delivery_stops'];
    final stop = stopsRaw is List && stopsRaw.isNotEmpty
        ? Map<String, dynamic>.from(stopsRaw.first as Map)
        : (stopsRaw is Map ? Map<String, dynamic>.from(stopsRaw) : null);
    final assignmentsRaw = stop?['rider_assignments'];
    final assignment = assignmentsRaw is List && assignmentsRaw.isNotEmpty
        ? Map<String, dynamic>.from(assignmentsRaw.first as Map)
        : (assignmentsRaw is Map ? Map<String, dynamic>.from(assignmentsRaw) : null);
    final items = row['items'];
    return RiderOrder(
      id: row['id'].toString(),
      publicRef: (row['public_ref'] ?? row['id']).toString(),
      customerName: (row['customer_name'] ?? '').toString(),
      customerPhone: (row['customer_phone'] ?? '').toString(),
      address: (row['delivery_address'] ?? '').toString(),
      itemCount: items is List ? items.length : 0,
      note: (row['notes'] ?? '').toString(),
      status: DeliveryStatus.parse(row['delivery_status']?.toString()),
      deliverySessionId: row['delivery_session_id']?.toString(),
      stopId: stop?['id']?.toString(),
      sequence: stop?['sequence'] is int ? stop!['sequence'] as int : null,
      assignmentStatus: assignment?['status']?.toString(),
    );
  }
}

/// One assigned run: a delivery_session plus the Rider's orders within it,
/// grouped client-side for presentation only -- grouping never invents
/// membership the backend rows didn't already state.
class RiderRun {
  const RiderRun({required this.sessionId, required this.waveName, required this.orders});
  final String? sessionId;
  final String? waveName;
  final List<RiderOrder> orders;

  int get total => orders.length;
  int get delivered => orders.where((o) => o.isDelivered).length;
  int get pickedUp => orders.where((o) =>
      o.status == DeliveryStatus.pickedUp ||
      o.status == DeliveryStatus.outForDelivery ||
      o.status == DeliveryStatus.arrived ||
      o.status == DeliveryStatus.delivered).length;
}
