/// Presentation models for the surfaces the locked Cefflo Driver references
/// show but the canonical backend contract in `rider_repository.dart` does
/// not yet expose a read for (notifications feed, document verification
/// state, support tickets, per-run history rollups).
///
/// They live in their own file, separate from `models.dart`, precisely so it
/// stays obvious which types map to a real canonical row today and which are
/// UI-shaped types waiting on a backend contract. Nothing here invents a
/// screen; every field corresponds to something a reference renders.
library;

enum StopStatus { pending, delivered, issue }

/// One delivery stop inside a run, as D21/D21.1/D21.2/D22/D23/D32 draw it.
class DriverStop {
  const DriverStop({
    required this.id,
    required this.reference,
    required this.customerName,
    required this.addressLine1,
    this.addressLine2,
    this.phone,
    this.status = StopStatus.pending,
    this.items = const [],
    this.deliveredAt,
    this.etaMinutes,
    this.distanceMetres,
    this.deliveryStatus,
  });

  final String id;
  final String reference; // "#S001"
  final String customerName;
  final String addressLine1;
  final String? addressLine2;
  final String? phone;
  final StopStatus status;
  final List<DriverOrderItem> items;
  final String? deliveredAt; // "09:15 AM"
  final int? etaMinutes;
  final int? distanceMetres;

  /// Canonical `delivery_status` of the backing order in the real build
  /// (null in the prototype). Drives which execution step is next.
  final String? deliveryStatus;

  DriverStop copyWith({StopStatus? status, String? deliveredAt}) => DriverStop(
    id: id,
    reference: reference,
    customerName: customerName,
    addressLine1: addressLine1,
    addressLine2: addressLine2,
    phone: phone,
    status: status ?? this.status,
    items: items,
    deliveredAt: deliveredAt ?? this.deliveredAt,
    etaMinutes: etaMinutes,
    distanceMetres: distanceMetres,
    deliveryStatus: deliveryStatus,
  );
}

class DriverOrderItem {
  const DriverOrderItem({required this.quantity, required this.name});
  final int quantity;
  final String name;
}

enum RunState { assigned, onTheWay, completed }

/// One run (delivery session) — D19's Current Run card, D20 Run Details,
/// D30 Run Completed, D31 Delivery History, D32 History Detail.
class DriverRun {
  const DriverRun({
    required this.id,
    required this.reference,
    required this.dateLabel,
    required this.zone,
    required this.pickupBusinessName,
    required this.pickupAddress,
    required this.distanceKm,
    required this.state,
    required this.stops,
    this.startedAtLabel,
    this.completedAtLabel,
    this.durationLabel,
    this.estimateLabel,
    this.vehicleLabel,
  });

  final String id;
  final String reference; // "#CF1003"
  final String dateLabel; // "Mon, 14 Sep 2026"
  final String zone; // "Setapak"
  final String pickupBusinessName;
  final String pickupAddress;

  /// Null in the real build: no backend route distance exists yet.
  final double? distanceKm;
  final RunState state;
  final List<DriverStop> stops;
  final String? startedAtLabel;
  final String? completedAtLabel;
  final String? durationLabel; // "2h 18m"
  final String? estimateLabel; // "Estimated 1h 20m"
  final String? vehicleLabel; // "Motorbike (WYX 1234)"

  int get orderCount => stops.length;
  String get distanceText => distanceKm == null ? '—' : '$distanceKm km';
  int get deliveredCount =>
      stops.where((s) => s.status == StopStatus.delivered).length;
  int get pendingCount =>
      stops.where((s) => s.status == StopStatus.pending).length;
  int get issueCount => stops.where((s) => s.status == StopStatus.issue).length;

  String get statusLabel => switch (state) {
    RunState.assigned => 'Assigned',
    RunState.onTheWay => 'On the way',
    RunState.completed => 'Completed',
  };

  DriverRun copyWith({List<DriverStop>? stops, RunState? state}) => DriverRun(
    id: id,
    reference: reference,
    dateLabel: dateLabel,
    zone: zone,
    pickupBusinessName: pickupBusinessName,
    pickupAddress: pickupAddress,
    distanceKm: distanceKm,
    state: state ?? this.state,
    stops: stops ?? this.stops,
    startedAtLabel: startedAtLabel,
    completedAtLabel: completedAtLabel,
    durationLabel: durationLabel,
    estimateLabel: estimateLabel,
    vehicleLabel: vehicleLabel,
  );
}

enum NotificationKind {
  runAssigned,
  deliveryIssue,
  customerUpdate,
  runCompleted,
  documentApproved,
  appUpdate,
}

/// D33 Notifications.
class DriverNotification {
  const DriverNotification({
    required this.kind,
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.unread,
    this.archived = false,
  });

  final NotificationKind kind;
  final String title;
  final String body;
  final String timeLabel;
  final bool unread;
  final bool archived;

  DriverNotification copyWith({bool? unread, bool? archived}) =>
      DriverNotification(
        kind: kind,
        title: title,
        body: body,
        timeLabel: timeLabel,
        unread: unread ?? this.unread,
        archived: archived ?? this.archived,
      );
}

enum DocumentState { uploaded, verified, missing }

/// D12.2 required documents and D37 Documents.
class DriverDocument {
  const DriverDocument({
    required this.id,
    required this.title,
    required this.helper,
    required this.state,
    this.expiryLabel,
  });

  final String id;
  final String title;
  final String helper;
  final DocumentState state;
  final String? expiryLabel;

  DriverDocument copyWith({DocumentState? state}) => DriverDocument(
    id: id,
    title: title,
    helper: helper,
    state: state ?? this.state,
    expiryLabel: expiryLabel,
  );
}

/// The business a Driver is invited to / connected to (D09, D10, D18, D19,
/// D40-B).
class DriverBusiness {
  const DriverBusiness({
    required this.name,
    required this.category,
    required this.location,
    this.invitationMessage,
    this.phone,
  });

  final String name;
  final String category;
  final String location;
  final String? invitationMessage;
  final String? phone;
}

/// The signed-in Driver, as D12.1/D14.x/D34/D35/D36 render them.
class DriverProfile {
  const DriverProfile({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.dateOfBirth,
    required this.address,
    required this.vehicleType,
    required this.vehicleModel,
    required this.plateNumber,
    this.emergencyContact,
    this.statusLabel = 'Active Driver',
  });

  final String fullName;
  final String phone;
  final String email;
  final String dateOfBirth;
  final String address;
  final String vehicleType;
  final String vehicleModel;
  final String plateNumber;
  final String? emergencyContact;
  final String statusLabel;

  DriverProfile copyWith({
    String? fullName,
    String? phone,
    String? email,
    String? vehicleType,
    String? vehicleModel,
    String? plateNumber,
  }) => DriverProfile(
    fullName: fullName ?? this.fullName,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    dateOfBirth: dateOfBirth,
    address: address,
    vehicleType: vehicleType ?? this.vehicleType,
    vehicleModel: vehicleModel ?? this.vehicleModel,
    plateNumber: plateNumber ?? this.plateNumber,
    emergencyContact: emergencyContact,
    statusLabel: statusLabel,
  );
}

/// D28's reason list. Labels are exactly the ones the reference prints.
enum IssueReason {
  customerNotAvailable,
  wrongAddress,
  customerRequestedReschedule,
  itemsNotAvailable,
  safetyConcern,
  other;

  String get title => switch (this) {
    IssueReason.customerNotAvailable => 'Customer not available',
    IssueReason.wrongAddress => 'Wrong address',
    IssueReason.customerRequestedReschedule => 'Customer requested reschedule',
    IssueReason.itemsNotAvailable => 'Item(s) not available',
    IssueReason.safetyConcern => 'Safety concern',
    IssueReason.other => 'Other',
  };

  String get body => switch (this) {
    IssueReason.customerNotAvailable =>
      'Customer did not answer or not at location.',
    IssueReason.wrongAddress => 'Address not found or incorrect.',
    IssueReason.customerRequestedReschedule =>
      'Customer asked to deliver at a later time.',
    IssueReason.itemsNotAvailable => 'Item(s) not available at store.',
    IssueReason.safetyConcern => 'Unsafe to complete delivery.',
    IssueReason.other => 'Tell us more about the issue.',
  };
}

/// D40-A's routing categories. `vendorOwned` decides whether the flow goes to
/// D40-B (contact the business directly) or D40-C (a Cefflo support ticket).
enum SupportCategory {
  deliveryRunIssue,
  vendorBusinessIssue,
  ceffloAppIssue,
  accountDocuments,
  other;

  String get title => switch (this) {
    SupportCategory.deliveryRunIssue => 'Delivery / Run Issue',
    SupportCategory.vendorBusinessIssue => 'Vendor / Business Issue',
    SupportCategory.ceffloAppIssue => 'Cefflo App Issue',
    SupportCategory.accountDocuments => 'Account / Documents',
    SupportCategory.other => 'Other',
  };

  String get body => switch (this) {
    SupportCategory.deliveryRunIssue => 'Orders, pickup, delivery, customer',
    SupportCategory.vendorBusinessIssue =>
      'Assignment, payment, customer issue',
    SupportCategory.ceffloAppIssue => 'App bug, error, technical problem',
    SupportCategory.accountDocuments => 'Profile, documents, verification',
    SupportCategory.other => 'Something else',
  };

  /// D40-B exists because a vendor-owned operational issue is not Cefflo's
  /// to resolve — it routes to the business, not to a Cefflo ticket.
  bool get vendorOwned =>
      this == SupportCategory.deliveryRunIssue ||
      this == SupportCategory.vendorBusinessIssue;
}

/// D40's topic grid.
class SupportTopic {
  const SupportTopic({required this.title, required this.body});
  final String title;
  final String body;
}
