/// Cefflo subscription plans (V-50..V-54, D-54). Prices, delivery
/// allowances and caps are the Founder-locked Malaysia price book (locked
/// 2026-09-28, published on the Founder-approved Public Website). The live
/// app takes them from the server (`subscription_plans`, see
/// [SubscriptionPlan.withServer]); this file keeps the localised copy and
/// the demo values. Yearly billing is not approved: demo only.
library;

import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

enum BillingCycle { monthly, yearly }

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.tagline,
    required this.deliveries,
    required this.riders,
    required this.zones,
    required this.teamUsers,
    required this.features,
    this.mostPopular = false,
  });

  final String id, name, tagline;
  final int monthlyPrice;

  /// Completed deliveries per billing cycle.
  final int deliveries;

  /// Caps; null = unlimited.
  final int? riders, zones;
  final int teamUsers;
  final List<String> features;
  final bool mostPopular;

  bool get isFree => monthlyPrice == 0;

  /// This plan's localised copy with the server's authoritative numbers.
  SubscriptionPlan withServer(Map<String, dynamic> row) => SubscriptionPlan(
    id: id,
    name: (row['name'] as String?) ?? name,
    monthlyPrice: (row['monthly_price_myr'] as num?)?.round() ?? monthlyPrice,
    tagline: tagline,
    deliveries: (row['delivery_allowance'] as num?)?.toInt() ?? deliveries,
    riders: (row['driver_cap'] as num?)?.toInt(),
    zones: (row['zone_cap'] as num?)?.toInt(),
    teamUsers: (row['team_user_cap'] as num?)?.toInt() ?? teamUsers,
    features: features,
    mostPopular: row['most_popular'] == true,
  );

  /// Price for one billing period of [cycle], in RM.
  int priceFor(BillingCycle cycle) =>
      cycle == BillingCycle.yearly ? monthlyPrice * 10 : monthlyPrice;
}

List<SubscriptionPlan> get subscriptionPlans => [
  SubscriptionPlan(
    id: 'free',
    name: 'Free',
    monthlyPrice: 0,
    tagline: L.experienceCefflo,
    deliveries: 150,
    riders: 3,
    zones: 2,
    teamUsers: 1,
    features: [
      L.t150DeliveriesMonth,
      L.up3Riders2Zones,
      L.customerTrackingProofDelivery,
    ],
  ),
  SubscriptionPlan(
    id: 'grow',
    name: 'Grow',
    monthlyPrice: 99,
    tagline: L.businessesRunningLocalDeliveriesRegularly,
    deliveries: 500,
    riders: 10,
    zones: 5,
    teamUsers: 3,
    features: [
      L.t500DeliveriesMonth,
      L.up10Riders5Zones,
      L.up3TeamMembers,
      L.standardReportingSupport,
    ],
  ),
  SubscriptionPlan(
    id: 'operate',
    name: 'Operate',
    monthlyPrice: 199,
    tagline: L.runLocalDeliveryOperationOnePlace,
    deliveries: 1500,
    riders: null,
    zones: null,
    teamUsers: 10,
    mostPopular: true,
    features: [
      L.t1500DeliveriesMonth,
      L.unlimitedRidersZones,
      L.up10TeamMembers,
      L.advancedOperationalReporting,
      L.prioritySupport,
    ],
  ),
  SubscriptionPlan(
    id: 'scale',
    name: 'Scale',
    monthlyPrice: 499,
    tagline: L.highVolumeComplexOperations,
    deliveries: 5000,
    riders: null,
    zones: null,
    teamUsers: 25,
    features: [
      L.t5000DeliveriesMonth,
      L.unlimitedRidersZones,
      L.up25TeamMembers,
      L.advancedControlsIntegrations,
      L.prioritySupport,
    ],
  ),
];

SubscriptionPlan planById(String id) =>
    subscriptionPlans.firstWhere((p) => p.id == id);

/// The live subscription of the Owner's business (`my_subscription`).
class LiveSubscription {
  const LiveSubscription({
    required this.planKey,
    required this.status,
    required this.deliveriesUsed,
    required this.driversActive,
    required this.zonesActive,
    required this.teamUsers,
    this.trialEndsAt,
    this.overAllowance = false,
  });
  final String planKey, status;
  final int deliveriesUsed, driversActive, zonesActive, teamUsers;
  final DateTime? trialEndsAt;
  final bool overAllowance;

  factory LiveSubscription.fromJson(Map<String, dynamic> j) => LiveSubscription(
    planKey: (j['plan_key'] as String?) ?? 'free',
    status: (j['status'] as String?) ?? 'active',
    deliveriesUsed: (j['deliveries_used'] as num?)?.toInt() ?? 0,
    driversActive: (j['drivers_active'] as num?)?.toInt() ?? 0,
    zonesActive: (j['zones_active'] as num?)?.toInt() ?? 0,
    teamUsers: (j['team_users'] as num?)?.toInt() ?? 0,
    trialEndsAt: DateTime.tryParse('${j['trial_ends_at'] ?? ''}'),
    overAllowance: j['over_allowance'] == true,
  );
}

/// The server stopped a plan change before payment (`request_plan_change`):
/// payment_required | contact_support | contact_sales | current_plan.
class PlanChangeNotAvailable implements Exception {
  const PlanChangeNotAvailable(this.status);
  final String status;
  @override
  String toString() => L.planChangeNotAvailableBody;
}

/// One past invoice (Billing History).
class Invoice {
  const Invoice({
    required this.date,
    required this.amount,
    required this.planName,
    required this.cycle,
    this.paid = true,
  });
  final DateTime date;
  final int amount;
  final String planName;
  final BillingCycle cycle;
  final bool paid;
}
