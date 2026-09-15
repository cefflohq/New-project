import 'driver_models.dart';

/// In-memory fixture data for the prototype/preview boot mode
/// (`--dart-define=CEFFLO_UI_PROTOTYPE=true`), so the app is runnable and
/// screenshot-able without Supabase credentials. Same idea as Vendor
/// Mobile's `VendorRepository.demo()`, ported rather than imported.
///
/// Every value here is a value the locked reference images actually print.
/// Nothing is extrapolated beyond what a reference shows.
class DemoData {
  const DemoData._();

  static const business = DriverBusiness(
    name: 'Bakes & Co.',
    category: 'Bakery',
    location: 'Kuala Lumpur',
    phone: '+60 12-345 6789',
  );

  /// D09/D10 show the *invitation* from a different business than D18/D19's
  /// connected one, so both are kept.
  static const invitingBusiness = DriverBusiness(
    name: 'Daily Bites',
    category: 'Food & Beverages',
    location: 'Kuala Lumpur, MY',
    invitationMessage: 'We’d love to have you on our delivery team!',
  );

  /// D40-B contacts the vendor that owns the run.
  static const supportVendor = DriverBusiness(
    name: 'Kopi Kita Café',
    category: 'Vendor',
    location: 'Kuala Lumpur',
    phone: '+60 12-345 6789',
  );

  static const profile = DriverProfile(
    fullName: 'Ali Rahman',
    phone: '+60 12 345 6789',
    email: 'ali.rahman@email.com',
    dateOfBirth: '12 Jan 1990',
    address: 'Kuala Lumpur, Malaysia',
    vehicleType: 'Motorbike',
    vehicleModel: 'Yamaha Y15ZR',
    plateNumber: 'WYX 1234',
  );

  /// D34/D35 render a different signed-in identity than the onboarding
  /// screens do; both names appear across the locked set.
  static const activeProfile = DriverProfile(
    fullName: 'Ahmad Rizky',
    phone: '+60 12 345 6789',
    email: 'ahmadrizky@gmail.com',
    dateOfBirth: '12 Jan 1990',
    address: 'Kuala Lumpur, Malaysia',
    vehicleType: 'Motorbike',
    vehicleModel: 'Yamaha Y15ZR',
    plateNumber: 'WYX 1234',
  );

  static const onboardingDocuments = <DriverDocument>[
    DriverDocument(
      id: 'licence',
      title: 'Driving Licence',
      helper: 'Upload a clear photo of your driving licence.',
      state: DocumentState.uploaded,
    ),
    DriverDocument(
      id: 'roadtax',
      title: 'Vehicle Registration (Roadtax)',
      helper: 'Upload a clear photo of your vehicle registration.',
      state: DocumentState.uploaded,
    ),
  ];

  static const documents = <DriverDocument>[
    DriverDocument(
      id: 'licence',
      title: 'Driving License',
      helper: 'Expires 12 Sep 2028',
      state: DocumentState.verified,
      expiryLabel: 'Expires 12 Sep 2028',
    ),
    DriverDocument(
      id: 'roadtax',
      title: 'Vehicle Registration (Roadtax)',
      helper: 'Expires 28 Feb 2027',
      state: DocumentState.verified,
      expiryLabel: 'Expires 28 Feb 2027',
    ),
    DriverDocument(
      id: 'ic',
      title: 'Identity Card (IC)',
      helper: '',
      state: DocumentState.verified,
    ),
  ];

  static const notifications = <DriverNotification>[
    DriverNotification(
      kind: NotificationKind.runAssigned,
      title: 'New run assigned',
      body: 'Run #CF1004 has been assigned to you.',
      timeLabel: '10:24 AM',
      unread: true,
    ),
    DriverNotification(
      kind: NotificationKind.deliveryIssue,
      title: 'Delivery issue reported',
      body: 'Customer not available at stop #5.',
      timeLabel: '09:18 AM',
      unread: true,
    ),
    DriverNotification(
      kind: NotificationKind.customerUpdate,
      title: 'Customer updated',
      body: 'Customer requested to reschedule delivery.',
      timeLabel: '08:52 AM',
      unread: true,
    ),
    DriverNotification(
      kind: NotificationKind.runCompleted,
      title: 'Run completed',
      body: 'Great job! You have completed run #CF1003.',
      timeLabel: 'Yesterday',
      unread: false,
    ),
    DriverNotification(
      kind: NotificationKind.documentApproved,
      title: 'Document approved',
      body: 'Your driving license has been approved.',
      timeLabel: 'Yesterday',
      unread: false,
    ),
    DriverNotification(
      kind: NotificationKind.appUpdate,
      title: 'App update',
      body: 'A new version of the app is available on the Play Store.',
      timeLabel: '12 Sep 2026',
      unread: false,
    ),
  ];

  static const _currentStops = <DriverStop>[
    DriverStop(
      id: 's001',
      reference: '#S001',
      customerName: 'Farah Ibrahim',
      addressLine1: 'Jalan Danau Kota 1,',
      addressLine2: 'Setapak',
      phone: '+60 12-345 6789',
      etaMinutes: 2,
      distanceMetres: 650,
      items: [
        DriverOrderItem(quantity: 1, name: 'Chocolate Cake (6")'),
        DriverOrderItem(quantity: 1, name: 'Blueberry Tart'),
        DriverOrderItem(quantity: 1, name: 'Cookies Box'),
      ],
    ),
    DriverStop(
      id: 's002',
      reference: '#S002',
      customerName: 'Lee Chin Wei',
      addressLine1: 'Jalan Setapak Indah',
      items: [DriverOrderItem(quantity: 2, name: 'Butter Croissant')],
    ),
    DriverStop(
      id: 's003',
      reference: '#S003',
      customerName: 'Aisyah Rahman',
      addressLine1: 'Jalan 2/27A, Setapak',
      items: [DriverOrderItem(quantity: 1, name: 'Cheese Tart Box')],
    ),
    DriverStop(
      id: 's004',
      reference: '#S004',
      customerName: 'Kumaravelu',
      addressLine1: 'Jalan Usahawan 4',
      items: [DriverOrderItem(quantity: 1, name: 'Sourdough Loaf')],
    ),
    DriverStop(
      id: 's005',
      reference: '#S005',
      customerName: 'Siti Norazimah',
      addressLine1: 'Jalan Genting Kelang',
      items: [DriverOrderItem(quantity: 3, name: 'Kuih Platter')],
    ),
    DriverStop(
      id: 's006',
      reference: '#S006',
      customerName: 'Daniel Tan',
      addressLine1: 'Jalan Taman Ibu Kota',
      items: [DriverOrderItem(quantity: 1, name: 'Coffee Beans 250g')],
    ),
    DriverStop(id: 's007', reference: '#S007', customerName: 'Nurul Huda', addressLine1: 'Jalan Danau Kota 3'),
    DriverStop(id: 's008', reference: '#S008', customerName: 'Rajesh Kumar', addressLine1: 'Jalan Setapak Jaya'),
    DriverStop(id: 's009', reference: '#S009', customerName: 'Wong Mei Ling', addressLine1: 'Jalan Usahawan 2'),
    DriverStop(id: 's010', reference: '#S010', customerName: 'Hafiz Zulkifli', addressLine1: 'Jalan Genting Kelang 4'),
    DriverStop(id: 's011', reference: '#S011', customerName: 'Chong Wei Han', addressLine1: 'Taman Setapak'),
    DriverStop(id: 's012', reference: '#S012', customerName: 'Amirah Yusof', addressLine1: 'Jalan Danau Kota 5'),
  ];

  static const currentRun = DriverRun(
    id: 'run-cf1003',
    reference: '#CF1003',
    dateLabel: 'Mon, 14 Sep 2026',
    zone: 'Setapak',
    pickupBusinessName: 'Bakes & Co.',
    pickupAddress: 'Jalan Setapak, Kuala Lumpur',
    distanceKm: 3.2,
    state: RunState.onTheWay,
    stops: _currentStops,
    startedAtLabel: '10:20 AM',
    estimateLabel: 'Estimated 1h 20m',
    vehicleLabel: 'Motorbike (WYX 1234)',
  );

  /// D30/D32 show the same run once every stop is delivered.
  static DriverRun get completedRun => DriverRun(
    id: 'run-cf1003',
    reference: '#CF1003',
    dateLabel: 'Mon, 14 Sep 2026',
    zone: 'Petaling Jaya',
    pickupBusinessName: 'Bakes & Co.',
    pickupAddress: 'Jalan Setapak, Kuala Lumpur',
    distanceKm: 32.4,
    state: RunState.completed,
    startedAtLabel: '09:12 AM',
    completedAtLabel: '11:30 AM',
    durationLabel: '2h 18m',
    vehicleLabel: 'Motorbike (WYX 1234)',
    stops: const [
      DriverStop(id: 'c1001', reference: '#C1001', customerName: 'Farah Ibrahim', addressLine1: 'Jalan SS2/1, PJ', status: StopStatus.delivered, deliveredAt: '09:15 AM'),
      DriverStop(id: 'c1002', reference: '#C1002', customerName: 'Lee Chin Wei', addressLine1: 'Jalan SS2/3, PJ', status: StopStatus.delivered, deliveredAt: '09:28 AM'),
      DriverStop(id: 'c1003', reference: '#C1003', customerName: 'Aisyah Rahman', addressLine1: 'Jalan SS2/5, PJ', status: StopStatus.delivered, deliveredAt: '09:47 AM'),
      DriverStop(id: 'c1004', reference: '#C1004', customerName: 'Kumaravelu', addressLine1: 'Jalan SS2/8, PJ', status: StopStatus.delivered, deliveredAt: '10:12 AM'),
      DriverStop(id: 'c1005', reference: '#C1005', customerName: 'Siti Norazimah', addressLine1: 'Jalan SS2/10, PJ', status: StopStatus.delivered, deliveredAt: '10:26 AM'),
      DriverStop(id: 'c1006', reference: '#C1006', customerName: 'Daniel Tan', addressLine1: 'Jalan SS2/12, PJ', status: StopStatus.delivered, deliveredAt: '10:38 AM'),
      DriverStop(id: 'c1007', reference: '#C1007', customerName: 'Nurul Huda', addressLine1: 'Jalan SS2/14, PJ', status: StopStatus.delivered, deliveredAt: '10:49 AM'),
      DriverStop(id: 'c1008', reference: '#C1008', customerName: 'Rajesh Kumar', addressLine1: 'Jalan SS2/17, PJ', status: StopStatus.delivered, deliveredAt: '10:58 AM'),
      DriverStop(id: 'c1009', reference: '#C1009', customerName: 'Wong Mei Ling', addressLine1: 'Jalan SS2/19, PJ', status: StopStatus.delivered, deliveredAt: '11:07 AM'),
      DriverStop(id: 'c1010', reference: '#C1010', customerName: 'Hafiz Zulkifli', addressLine1: 'Jalan SS2/22, PJ', status: StopStatus.delivered, deliveredAt: '11:15 AM'),
      DriverStop(id: 'c1011', reference: '#C1011', customerName: 'Chong Wei Han', addressLine1: 'Jalan SS2/24, PJ', status: StopStatus.delivered, deliveredAt: '11:23 AM'),
      DriverStop(id: 'c1012', reference: '#C1012', customerName: 'Amirah Yusof', addressLine1: 'Jalan SS2/26, PJ', status: StopStatus.delivered, deliveredAt: '11:30 AM'),
    ],
  );

  /// D31 Delivery History.
  static List<DriverRun> get history => [
    completedRun,
    _historyRun('#CF1002', 'Sun, 13 Sep 2026', 8, 21.6, '1h 42m'),
    _historyRun('#CF1001', 'Sat, 12 Sep 2026', 10, 28.1, '2h 05m'),
    _historyRun('#CF0998', 'Fri, 11 Sep 2026', 9, 24.7, '1h 58m'),
    _historyRun('#CF0997', 'Thu, 10 Sep 2026', 11, 30.2, '2h 20m'),
  ];

  static DriverRun _historyRun(
    String reference,
    String dateLabel,
    int stops,
    double km,
    String duration,
  ) => DriverRun(
    id: 'run-${reference.substring(1).toLowerCase()}',
    reference: reference,
    dateLabel: dateLabel,
    zone: 'Petaling Jaya',
    pickupBusinessName: 'Bakes & Co.',
    pickupAddress: 'Jalan Setapak, Kuala Lumpur',
    distanceKm: km,
    state: RunState.completed,
    durationLabel: duration,
    startedAtLabel: '09:12 AM',
    completedAtLabel: '11:30 AM',
    vehicleLabel: 'Motorbike (WYX 1234)',
    stops: [
      for (var i = 1; i <= stops; i++)
        DriverStop(
          id: '$reference-$i',
          reference: '#C${1000 + i}',
          customerName: 'Customer $i',
          addressLine1: 'Jalan SS2/$i, PJ',
          status: StopStatus.delivered,
          deliveredAt: '09:${(10 + i).toString().padLeft(2, '0')} AM',
        ),
    ],
  );

  /// D19's Today's Overview counters.
  static const todayAssigned = 5;
  static const todayOngoing = 1;
  static const todayIssues = 0;
  static const todayCompleted = 4;
  static const todayDateLabel = 'Mon, 14 Sep 2026';

  /// D40's "Common Driver Topics" grid.
  static const supportTopics = <SupportTopic>[
    SupportTopic(
      title: 'Runs & Deliveries',
      body: 'Orders, navigation, delivery process',
    ),
    SupportTopic(
      title: 'Delivery Issues',
      body: 'Failed delivery, customer not available',
    ),
    SupportTopic(
      title: 'Vehicle & Documents',
      body: 'License, registration, document verification',
    ),
    SupportTopic(
      title: 'Account & Profile',
      body: 'Profile, settings, app access',
    ),
  ];

  static const languages = <String>[
    'English',
    'Bahasa Melayu',
    '中文 (简体)',
    'தமிழ்',
  ];

  static const vehicleTypes = <String>['Motorbike', 'Car', 'Van'];
}
