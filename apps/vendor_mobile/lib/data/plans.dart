/// Cefflo subscription plans (V-50..V-54, D-54). Values come from the
/// pricing direction in docs/cefflo/sot/10_PRICING.md §4-8 -- a CANDIDATE,
/// not a Founder-locked price list -- so they live in one place and change
/// here only. Yearly billing follows §Annual: pay ~10 months, get 12.
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
    deliveries: 100,
    riders: 3,
    zones: 2,
    teamUsers: 1,
    features: [
      L.t100DeliveriesMonth,
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
